/// Stats data loaders over Drift (T6.1.12): typed, range-bounded queries that load the minimum rows
/// each scope needs and map them into the isolate-sendable records of `stats_inputs.dart` (never Drift
/// row classes). Tombstones are excluded except where history needs them (deleted checklist items
/// feed burn-up/CFD).
///
/// Query plans (`EXPLAIN QUERY PLAN`, asserted by `test/features/stats/data/stats_data_source_test.dart`; the local database is
/// single-user, so `user_id` is a residual filter on the per-feature indexes):
/// - tasks (section): `SEARCH tasks USING INDEX idx_tasks_start (start_local<?)` + unscheduled
///   `SEARCH tasks USING INDEX idx_tasks_start (start_local=?)` (IS NULL); series:
///   `SEARCH tasks USING INDEX idx_tasks_series (series_id=?)`; task: `SEARCH tasks USING INDEX
///   sqlite_autoindex_tasks_1 (id=?)`.
/// - task_occurrences: `SEARCH task_occurrences USING INDEX idx_occ_task_key (task_id=?)`.
/// - time_entries: `SEARCH time_entries USING INDEX idx_time_entries_task (task_id=?)`.
/// - activity_events: `SEARCH activity_events USING INDEX idx_activity_entity (entity_type=? AND
///   entity_id=?)` (planner) / `(entity_type=?)` (checklist section).
/// - checklist_items: `SEARCH checklist_items USING INDEX idx_items_checklist (checklist_id=?)`.
/// - habit_logs: `SEARCH habit_logs USING INDEX idx_habit_logs_habit_date (habit_id=?)`.
/// - attachments: `SEARCH attachments USING INDEX idx_attachments_owner (owner_type=?)`.
/// - notifications: `SEARCH notifications USING INDEX idx_notifications_fire (fire_at>?)`.
/// - Small per-user tables (categories, tags, checklists, habits, pauses, revisions, goals,
///   checklist_runs) are scanned.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/stats/domain/scope_entity.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPause, PlannerOccurrenceStatus, TrackingMode;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, LocalDateTime;

/// Loads stats rows for the current user.
class StatsDataSource {
  StatsDataSource(this._db, this._userId);

  final AppDatabase _db;
  final String Function() _userId;

  static const _chunk = 500;

  // ------------------------------------------------------------------------------------------
  // Shared

  Future<List<CategoryInfo>> loadCategories() async {
    final rows = await (_db.select(
      _db.categories,
    )..where((c) => c.userId.equals(_userId()) & c.deletedAt.isNull())).get();
    return [
      for (final r in rows)
        CategoryInfo(r.id, r.name, color: r.color, unavailable: r.countsAsUnavailable, archived: r.archivedAt != null),
    ];
  }

  Future<List<TagInfo>> loadTags() async {
    final rows = await (_db.select(_db.tags)..where((t) => t.userId.equals(_userId()) & t.deletedAt.isNull())).get();
    return [for (final r in rows) TagInfo(r.id, r.name, color: r.color)];
  }

  Future<List<TagLink>> loadTagLinks(String entityType) async {
    final rows = await (_db.select(
      _db.entityTags,
    )..where((t) => t.entityType.equals(entityType) & t.userId.equals(_userId()) & t.deletedAt.isNull())).get();
    return [for (final r in rows) TagLink(r.tagId, r.entityType, r.entityId)];
  }

  Future<List<GoalRecord>> loadGoals() async {
    final rows = await (_db.select(_db.goals)..where((g) => g.userId.equals(_userId()) & g.deletedAt.isNull())).get();
    return [
      for (final r in rows)
        GoalRecord(
          id: r.id,
          scopeType: r.scopeType,
          scopeId: r.scopeId,
          metric: r.metric,
          target: r.target,
          period: r.period,
          startDate: r.startDate == null ? null : LocalDate.tryParse(r.startDate!),
          endDate: r.endDate == null ? null : LocalDate.tryParse(r.endDate!),
          title: r.title,
          achievedAt: r.achievedAt,
          createdAt: r.createdAt,
        ),
    ];
  }

  /// Pending outbox rows (sync caveat of the data-quality card, T6.1.20).
  Future<int> pendingOutbox() async {
    final count = _db.syncOutbox.changeId.count();
    final row =
        await (_db.selectOnly(_db.syncOutbox)
              ..addColumns([count])
              ..where(_db.syncOutbox.state.isNotValue('failed')))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<ActivityRecord>> _events(String entityType, Iterable<String> entityIds, {Set<String>? types}) async {
    final ids = entityIds.toSet().toList();
    final result = <ActivityRecord>[];
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
      final query = _db.select(_db.activityEvents)
        ..where(
          (e) =>
              e.entityType.equals(entityType) &
              e.entityId.isIn(part) &
              e.userId.equals(_userId()) &
              e.deletedAt.isNull() &
              (types == null ? const Constant(true) : e.eventType.isIn(types)),
        );
      result.addAll((await query.get()).map(_event));
    }
    return result;
  }

  static ActivityRecord _event(ActivityEventRow r) => ActivityRecord(
    entityType: r.entityType,
    entityId: r.entityId,
    parentId: r.parentId,
    eventType: r.eventType,
    payload: _decodeMap(r.payload),
    occurredAt: r.occurredAt,
    rev: r.rev,
  );

  static Map<String, Object?> _decodeMap(String text) {
    try {
      final v = jsonDecode(text);
      return v is Map ? Map<String, Object?>.from(v) : const {};
    } on FormatException {
      return const {};
    }
  }

  // ------------------------------------------------------------------------------------------
  // Planner

  /// Planner rows. [taskId] loads one task (task sheet), [seriesId] one series; otherwise every
  /// task that can have an occurrence on or before [to] plus the backlog.
  Future<PlannerInput> loadPlanner({String? taskId, String? seriesId, LocalDate? to}) async {
    final user = _userId();
    List<TaskRow> tasks;
    if (taskId != null) {
      tasks = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId) & t.deletedAt.isNull())).get();
    } else if (seriesId != null) {
      tasks =
          await (_db.select(_db.tasks)..where(
                (t) =>
                    t.seriesId.equals(seriesId) &
                    t.userId.equals(user) &
                    t.deletedAt.isNull() &
                    t.isTemplate.equals(false),
              ))
              .get();
    } else {
      final bound = to == null ? '9999-12-31T23:59' : to.plusDays(1).atStartOfDay.toIso();
      tasks = [
        ...await (_db.select(_db.tasks)..where(
              (t) =>
                  t.startLocal.isSmallerThanValue(bound) &
                  t.userId.equals(user) &
                  t.deletedAt.isNull() &
                  t.isTemplate.equals(false),
            ))
            .get(),
        ...await (_db.select(_db.tasks)..where(
              (t) => t.startLocal.isNull() & t.userId.equals(user) & t.deletedAt.isNull() & t.isTemplate.equals(false),
            ))
            .get(),
      ];
    }
    final ids = [for (final t in tasks) t.id];
    final occurrences = <TaskOccurrenceRow>[];
    final entries = <TimeEntryRow>[];
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
      occurrences.addAll(
        await (_db.select(_db.taskOccurrences)..where((o) => o.taskId.isIn(part) & o.deletedAt.isNull())).get(),
      );
      entries.addAll(
        await (_db.select(_db.timeEntries)..where((e) => e.taskId.isIn(part) & e.deletedAt.isNull())).get(),
      );
    }
    final events = await _events('task', ids, types: const {'rescheduled', 'created', 'updated'});
    return PlannerInput(
      tasks: [for (final t in tasks) taskRecordOf(t)],
      occurrences: [for (final o in occurrences) occurrenceRecordOf(o)],
      timeEntries: [
        for (final e in entries)
          TimeEntryRecord(taskId: e.taskId, occurrenceKey: e.occurrenceKey, startedAt: e.startedAt, endedAt: e.endedAt),
      ],
      events: events,
      categories: await loadCategories(),
      tags: await loadTags(),
      tagLinks: await loadTagLinks('task'),
      goals: await loadGoals(),
    );
  }

  /// Maps a `tasks` row.
  static TaskRecord taskRecordOf(TaskRow t) => TaskRecord(
    id: t.id,
    seriesId: t.seriesId,
    title: t.title,
    createdAt: t.createdAt,
    categoryId: t.categoryId,
    color: t.color,
    priority: t.priority,
    trackingMode: TrackingMode.values.firstWhere((m) => m.name == t.trackingMode, orElse: () => TrackingMode.check),
    isAllDay: t.isAllDay,
    startLocal: t.startLocal == null ? null : _ldt(t.startLocal!),
    durationMinutes: t.durationMinutes,
    timeZone: t.timeZone,
    recurrence: t.recurrence,
    status: t.status,
    linkedChecklistId: t.linkedChecklistId,
    icon: t.icon,
  );

  /// Maps a `task_occurrences` row.
  static OccurrenceRecord occurrenceRecordOf(TaskOccurrenceRow o) => OccurrenceRecord(
    taskId: o.taskId,
    key: o.occurrenceKey,
    overrideStartLocal: o.overrideStartLocal == null ? null : _ldt(o.overrideStartLocal!),
    overrideDurationMinutes: o.overrideDurationMinutes,
    overrideTitle: o.overrideTitle,
    isCancelled: o.isCancelled,
    status: switch (o.status) {
      'in_progress' => PlannerOccurrenceStatus.inProgress,
      'done' => PlannerOccurrenceStatus.done,
      'skipped' => PlannerOccurrenceStatus.skipped,
      'missed' => PlannerOccurrenceStatus.missed,
      'cancelled' => PlannerOccurrenceStatus.cancelled,
      _ => PlannerOccurrenceStatus.scheduled,
    },
    statusChangedAt: o.statusChangedAt,
    completedAt: o.completedAt,
    actualStartAt: o.actualStartAt,
    actualEndAt: o.actualEndAt,
    trackedSeconds: o.trackedSeconds,
    completionPercent: o.completionPercent,
    skipReason: o.skipReason,
    rating: o.rating,
    outcomeNote: o.outcomeNote,
  );

  static LocalDateTime? _ldt(String v) => LocalDateTime.tryParse(v) ?? LocalDate.tryParse(v)?.atStartOfDay;

  /// Earliest planned date (all-time periods).
  Future<LocalDate?> firstPlannerDate({String? seriesId}) async {
    final min = _db.tasks.startLocal.min();
    final q = _db.selectOnly(_db.tasks)
      ..addColumns([min])
      ..where(_db.tasks.userId.equals(_userId()) & _db.tasks.deletedAt.isNull() & _db.tasks.startLocal.isNotNull());
    if (seriesId != null) q.where(_db.tasks.seriesId.equals(seriesId));
    final v = (await q.getSingle()).read(min);
    return v == null ? null : _ldt(v)?.date;
  }

  // ------------------------------------------------------------------------------------------
  // Checklists

  /// Checklist rows: one list ([checklistId]), the list of one item ([itemId]) or every list.
  Future<ChecklistInput> loadChecklists({String? checklistId, String? itemId}) async {
    final user = _userId();
    var listId = checklistId;
    if (itemId != null) {
      final item = await (_db.select(_db.checklistItems)..where((i) => i.id.equals(itemId))).getSingleOrNull();
      listId = item?.checklistId ?? '';
    }
    final lists = await (_db.select(_db.checklists)..where((c) => c.userId.equals(user) & c.deletedAt.isNull())).get();
    final listIds = listId == null ? [for (final l in lists) l.id] : [listId];
    final items = <ChecklistItemRow>[];
    for (var i = 0; i < listIds.length; i += _chunk) {
      final part = listIds.sublist(i, i + _chunk > listIds.length ? listIds.length : i + _chunk);
      items.addAll(
        await (_db.select(_db.checklistItems)..where((it) => it.checklistId.isIn(part) & it.userId.equals(user))).get(),
      );
    }
    if (listId != null) {
      // Items that were in this list before moving elsewhere keep their history here (burn-up,
      // arrivals): their earlier events carry this list as `parent_id`.
      final here = {for (final i in items) i.id};
      final movedOut = await (_db.selectOnly(_db.activityEvents, distinct: true)
            ..addColumns([_db.activityEvents.entityId])
            ..where(
              _db.activityEvents.entityType.equals('checklist_item') &
                  _db.activityEvents.parentId.equals(listId) &
                  _db.activityEvents.userId.equals(user) &
                  _db.activityEvents.deletedAt.isNull(),
            ))
          .map((r) => r.read(_db.activityEvents.entityId)!)
          .get();
      final extra = [for (final id in movedOut) if (!here.contains(id)) id];
      for (var i = 0; i < extra.length; i += _chunk) {
        final part = extra.sublist(i, i + _chunk > extra.length ? extra.length : i + _chunk);
        items.addAll(await (_db.select(_db.checklistItems)..where((it) => it.id.isIn(part) & it.userId.equals(user))).get());
      }
    }
    final events = listId == null
        ? [
            for (final r
                in await (_db.select(_db.activityEvents)..where(
                      (e) => e.entityType.equals('checklist_item') & e.userId.equals(user) & e.deletedAt.isNull(),
                    ))
                    .get())
              _event(r),
          ]
        : await _events('checklist_item', [for (final i in items) i.id]);
    final runs =
        await (_db.select(_db.checklistRuns)..where(
              (r) =>
                  r.userId.equals(user) &
                  r.deletedAt.isNull() &
                  (listId == null ? const Constant(true) : r.checklistId.equals(listId)),
            ))
            .get();
    final attachments =
        await (_db.select(_db.attachments)..where(
              (a) =>
                  a.ownerType.isIn(const ['checklist', 'checklist_item']) &
                  a.userId.equals(user) &
                  a.deletedAt.isNull(),
            ))
            .get();
    return ChecklistInput(
      checklists: [
        for (final l in lists)
          ChecklistRecord(
            id: l.id,
            title: l.title,
            createdAt: l.createdAt,
            color: l.color,
            categoryId: l.categoryId,
            archivedAt: l.archivedAt,
            isTemplate: l.isTemplate,
            dueLocal: l.dueLocal == null ? null : _ldt(l.dueLocal!),
            timeZone: l.timeZone,
            isResettable: l.resetRule != null,
            requireReasonFor: _reasons(l.settings),
            staleAfterDays: _decodeMap(l.settings)['staleAfterDays'] is num
                ? (_decodeMap(l.settings)['staleAfterDays']! as num).toInt()
                : null,
          ),
      ],
      items: [for (final i in items) itemRecordOf(i)],
      events: events,
      runs: [
        for (final r in runs)
          RunRecord(
            checklistId: r.checklistId,
            key: r.occurrenceKey,
            startedAt: r.startedAt,
            endedAt: r.endedAt,
            totalItems: r.totalItems,
            completedItems: r.completedItems,
            snapshot: _snapshot(r.snapshot),
          ),
      ],
      attachments: [
        for (final a in attachments)
          AttachmentRecord(ownerType: a.ownerType, ownerId: a.ownerId, mimeType: a.mimeType, byteSize: a.byteSize),
      ],
      categories: await loadCategories(),
      tagLinks: await loadTagLinks('checklist'),
    );
  }

  static Set<String> _reasons(String settings) {
    final v = _decodeMap(settings)['requireReasonFor'];
    return v is List
        ? {
            for (final s in v)
              if (s is String) s,
          }
        : const {};
  }

  /// Maps a `checklist_items` row.
  static ItemRecord itemRecordOf(ChecklistItemRow i) => ItemRecord(
    id: i.id,
    checklistId: i.checklistId,
    parentId: i.parentId,
    text: i.itemText,
    status: i.status,
    statusNote: i.statusNote,
    createdAt: i.createdAt,
    completedAt: i.completedAt,
    deletedAt: i.deletedAt,
    dueLocal: i.dueLocal == null ? null : _ldt(i.dueLocal!),
    timeZone: i.timeZone,
    followUpAt: i.followUpAt,
    waitingOn: i.waitingOn,
    updatedAt: i.updatedAt,
  );

  static List<({String itemId, String status, DateTime? completedAt})> _snapshot(String? text) {
    if (text == null || text.isEmpty) return const [];
    try {
      final v = jsonDecode(text);
      if (v is! List) return const [];
      return [
        for (final e in v)
          if (e is Map && e['itemId'] is String)
            (
              itemId: e['itemId'] as String,
              status: e['status'] is String ? e['status'] as String : 'todo',
              completedAt: e['completedAt'] is String ? DateTime.tryParse(e['completedAt'] as String)?.toUtc() : null,
            ),
      ];
    } on FormatException {
      return const [];
    }
  }

  // ------------------------------------------------------------------------------------------
  // Habits & quit

  /// Habit rows: one habit ([habitId]) or every habit (build habits and quit trackers).
  Future<HabitInput> loadHabits({String? habitId, bool withNotifications = false, DateTime? notificationsSince}) async {
    final user = _userId();
    final habits =
        await (_db.select(_db.habits)..where(
              (h) =>
                  h.userId.equals(user) &
                  h.deletedAt.isNull() &
                  (habitId == null ? const Constant(true) : h.id.equals(habitId)),
            ))
            .get();
    final ids = [for (final h in habits) h.id];
    final logs = <HabitLogRow>[];
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
      logs.addAll(await (_db.select(_db.habitLogs)..where((l) => l.habitId.isIn(part) & l.deletedAt.isNull())).get());
    }
    final pauses = await (_db.select(
      _db.habitPauses,
    )..where((p) => p.userId.equals(user) & p.deletedAt.isNull())).get();
    final revisions = await (_db.select(
      _db.habitRevisions,
    )..where((r) => r.userId.equals(user) & r.deletedAt.isNull())).get();
    final notifications = withNotifications
        ? await (_db.select(_db.notifications)..where(
                (n) =>
                    // Text comparison of the ISO column keeps `idx_notifications_fire` usable
                    // (drift wraps DateTime comparisons in JULIANDAY()).
                    n.fireAt.dartCast<String>().isBiggerOrEqualValue(
                      (notificationsSince ?? DateTime.utc(1970)).toUtc().toIso8601String(),
                    ) &
                    n.userId.equals(user) &
                    n.deletedAt.isNull() &
                    n.sourceType.equals('habit'),
              ))
              .get()
        : const <NotificationRow>[];
    return HabitInput(
      habits: [for (final h in habits) habitRecordOf(h)],
      logs: [for (final l in logs) habitLogRecordOf(l)],
      pauses: [
        for (final p in pauses)
          if (LocalDate.tryParse(p.startDate) case final start?)
            HabitPause(
              start,
              end: p.endDate == null ? null : LocalDate.tryParse(p.endDate!),
              habitId: p.habitId,
              reason: p.reason,
            ),
      ],
      revisions: [
        for (final r in revisions)
          if (LocalDate.tryParse(r.effectiveFrom) case final from?)
            RevisionRecord(
              id: r.id,
              habitId: r.habitId,
              effectiveFrom: from,
              schedule: r.schedule,
              goalType: r.goalType,
              targetValue: r.targetValue,
              targetOp: r.targetOp,
              unit: r.unit,
              baselinePerDay: r.baselinePerDay,
              unitCost: r.unitCost,
              dailyLimit: r.dailyLimit,
            ),
      ],
      goals: await loadGoals(),
      notifications: [
        for (final n in notifications)
          NotificationRecord(
            fireAt: n.fireAt,
            sourceType: n.sourceType,
            sourceId: n.sourceId,
            category: n.category,
            actedAt: n.actedAt,
            action: n.action,
          ),
      ],
      categories: await loadCategories(),
    );
  }

  /// Maps a `habits` row (settings JSON is read defensively).
  static HabitRecord habitRecordOf(HabitRow h) {
    final settings = _decodeMap(h.settings);
    final rollup = settings['slotRollup'];
    return HabitRecord(
      id: h.id,
      kind: h.kind,
      name: h.name,
      startDate: LocalDate.tryParse(h.startDate) ?? LocalDate.fromDateTime(h.createdAt),
      createdAt: h.createdAt,
      icon: h.icon,
      color: h.color,
      categoryId: h.categoryId,
      goalType: h.goalType,
      targetValue: h.targetValue,
      targetOp: h.targetOp,
      unit: h.unit,
      schedule: h.schedule,
      endDate: h.endDate == null ? null : LocalDate.tryParse(h.endDate!),
      timeZone: h.timeZone,
      skipPolicy: h.skipPolicy,
      freezesPerMonth: h.freezesPerMonth,
      quitMode: h.quitMode,
      quitSubstance: h.quitSubstance,
      quitStartedAt: h.quitStartedAt,
      dailyLimit: h.dailyLimit,
      baselinePerDay: h.baselinePerDay,
      unitCost: h.unitCost,
      currency: h.currency,
      timePerUnitMinutes: h.timePerUnitMinutes,
      lifeMinutesPerUnit: h.lifeMinutesPerUnit,
      autoSuccess: h.autoSuccess,
      requireExplicitLog: settings['requireExplicitLog'] == true,
      slotMinDone: rollup is Map && rollup['minSlots'] is num ? (rollup['minSlots']! as num).toInt() : null,
      earlyToleranceMinutes: settings['earlyToleranceMinutes'] is num
          ? (settings['earlyToleranceMinutes']! as num).toInt()
          : 30,
      archivedAt: h.archivedAt,
    );
  }

  /// Maps a `habit_logs` row.
  static HabitLogRecord habitLogRecordOf(HabitLogRow l) => HabitLogRecord(
    id: l.id,
    habitId: l.habitId,
    kind: l.kind,
    loggedAt: l.loggedAt,
    localDate: LocalDate.tryParse(l.localDate) ?? LocalDate.fromDateTime(l.loggedAt),
    occurrenceKey: l.occurrenceKey,
    value: l.value,
    mood: l.mood,
    intensity: l.intensity,
    resisted: l.resisted,
    trigger: l.trigger,
    place: l.place,
    coping: l.coping,
    durationSeconds: l.durationSeconds,
    note: l.note,
    source: l.source,
    createdAt: l.createdAt,
  );

  /// Earliest habit start date (all-time periods).
  Future<LocalDate?> firstHabitDate({String? habitId}) async {
    final rows =
        await (_db.select(_db.habits)..where(
              (h) =>
                  h.userId.equals(_userId()) &
                  h.deletedAt.isNull() &
                  (habitId == null ? const Constant(true) : h.id.equals(habitId)),
            ))
            .get();
    LocalDate? first;
    for (final h in rows) {
      final d = LocalDate.tryParse(h.startDate);
      if (d != null && (first == null || d.isBefore(first))) first = d;
    }
    return first;
  }

  // ------------------------------------------------------------------------------------------
  // Scope headers & pickers

  /// The entity of a scoped screen (task, series, checklist, item, habit, quit tracker).
  Future<ScopeEntity?> entityOf(String scope, String id) async {
    switch (scope) {
      case 'task':
        final t = await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
        return t == null
            ? null
            : ScopeEntity(t.id, t.title, color: t.color, icon: t.icon, parentId: t.seriesId, recurring: t.recurrence != null);
      case 'series':
        final t = await (_db.select(_db.tasks)
              ..where((t) => t.seriesId.equals(id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        return t == null ? null : ScopeEntity(id, t.title, color: t.color, icon: t.icon);
      case 'checklist':
        final c = await (_db.select(_db.checklists)..where((c) => c.id.equals(id))).getSingleOrNull();
        return c == null ? null : ScopeEntity(c.id, c.title, color: c.color);
      case 'item':
        final i = await (_db.select(_db.checklistItems)..where((i) => i.id.equals(id))).getSingleOrNull();
        return i == null ? null : ScopeEntity(i.id, i.itemText, parentId: i.checklistId);
      case 'habit' || 'quit':
        final h = await (_db.select(_db.habits)..where((h) => h.id.equals(id))).getSingleOrNull();
        return h == null ? null : ScopeEntity(h.id, h.name, color: h.color, icon: h.icon, isQuit: h.kind == 'quit');
    }
    return null;
  }

  /// Live quit trackers (Quit segment picker).
  Stream<List<ScopeEntity>> watchQuitTrackers() {
    final query = _db.select(_db.habits)
      ..where((h) => h.kind.equals('quit') & h.userId.equals(_userId()) & h.deletedAt.isNull() & h.archivedAt.isNull())
      ..orderBy([(h) => OrderingTerm.asc(h.sortKey)]);
    return query.watch().map((rows) => [
      for (final h in rows) ScopeEntity(h.id, h.name, color: h.color, icon: h.icon, isQuit: true),
    ]);
  }

  /// Filter options: live categories and tags.
  Future<List<FilterOption>> categoryOptions() async => [
    for (final c in await loadCategories())
      if (!c.archived) FilterOption(c.id, c.name, color: c.color),
  ];

  Future<List<FilterOption>> tagOptions() async => [for (final t in await loadTags()) FilterOption(t.id, t.name, color: t.color)];

  /// Earliest checklist item creation (all-time periods).
  Future<DateTime?> firstChecklistInstant({String? checklistId}) async {
    final min = _db.checklistItems.createdAt.min();
    final q = _db.selectOnly(_db.checklistItems)
      ..addColumns([min])
      ..where(_db.checklistItems.userId.equals(_userId()));
    if (checklistId != null) q.where(_db.checklistItems.checklistId.equals(checklistId));
    return (await q.getSingle()).read(min);
  }
}
