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
///
/// The large tables (task_occurrences, time_entries, habit_logs, checklist_items, activity_events)
/// are read with column-limited raw selects: drift's row classes parse every synced timestamp
/// (created/updated/server_updated) of every row, which dominated the loading time of the
/// performance suite (T6.1.23). [_instant] reads drift's ISO text with a fast UTC path.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/stats/domain/scope_entity.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPause, PlannerOccurrenceStatus, TrackingMode;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, LocalDateTime, RecurrenceRule, RuleType;

/// Loads stats rows for the current user.
class StatsDataSource {
  StatsDataSource(this._db, this._userId);

  final AppDatabase _db;
  final String Function() _userId;

  static const _chunk = 500;

  /// Rows of a raw select ([args] bind the `?` placeholders in order).
  Future<List<Map<String, Object?>>> _rows(String sql, List<String> args) async => [
    for (final r in await _db.customSelect(sql, variables: [for (final a in args) Variable.withString(a)]).get())
      r.data,
  ];

  static String _marks(int n) => List.filled(n, '?').join(', ');

  /// A `DateTimeColumn` value (text mode): `…Z` strings take a fast UTC path, anything else goes
  /// through drift's own mapping (same result as a typed read).
  DateTime? _instant(Object? v) {
    if (v == null) return null;
    if (v is String) {
      final fast = parseUtcIso(v);
      if (fast != null) return fast;
    }
    return _db.typeMapping.read(DriftSqlType.dateTime, v);
  }

  /// `YYYY-MM-DDTHH:MM:SS[.f…]Z` as a UTC instant, or null for any other shape.
  static DateTime? parseUtcIso(String v) {
    final n = v.length;
    if (n < 20 || v.codeUnitAt(n - 1) != 0x5A || v.codeUnitAt(10) != 0x54) return null;
    int digits(int from, int count) {
      var x = 0;
      for (var i = from; i < from + count; i++) {
        final c = v.codeUnitAt(i) - 0x30;
        if (c < 0 || c > 9) return -1;
        x = x * 10 + c;
      }
      return x;
    }

    final y = digits(0, 4);
    final mo = digits(5, 2);
    final d = digits(8, 2);
    final h = digits(11, 2);
    final mi = digits(14, 2);
    final sec = digits(17, 2);
    if (y < 0 || mo < 0 || d < 0 || h < 0 || mi < 0 || sec < 0) return null;
    var micros = 0;
    if (n > 20) {
      if (v.codeUnitAt(19) != 0x2E || n - 21 > 6 || n - 21 < 1) return null;
      final f = digits(20, n - 21);
      if (f < 0) return null;
      micros = f;
      for (var i = n - 21; i < 6; i++) {
        micros *= 10;
      }
    } else if (n != 20) {
      return null;
    }
    return DateTime.utc(y, mo, d, h, mi, sec, 0, micros);
  }

  static int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

  static double? _double(Object? v) => v is num ? v.toDouble() : null;

  static bool? _bool(Object? v) => v == null ? null : (v == 1 || v == true);

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

  /// Week starts with a completed guided weekly review (GL-04): `activity_events` rows with
  /// `entity_type = 'review'`, `event_type = 'completed'` and the ISO week start in `payload.week`.
  Future<List<LocalDate>> reviewedWeeks() async {
    final rows = await _rows(
      "SELECT payload FROM activity_events WHERE entity_type = 'review' AND event_type = 'completed' "
      'AND user_id = ? AND deleted_at IS NULL',
      [_userId()],
    );
    final weeks = <LocalDate>{};
    for (final r in rows) {
      final week = _decodeMap(r['payload']! as String)['week'];
      if (week is String) {
        if (LocalDate.tryParse(week) case final d?) weeks.add(d);
      }
    }
    return weeks.toList()..sort();
  }

  Future<List<ActivityRecord>> _events(String entityType, Iterable<String> entityIds, {Set<String>? types}) async {
    final ids = entityIds.toSet().toList();
    final result = <ActivityRecord>[];
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
      final typeList = types?.toList() ?? const <String>[];
      final rows = await _rows(
        'SELECT $_eventColumns FROM activity_events WHERE entity_type = ? AND entity_id IN (${_marks(part.length)}) '
        'AND user_id = ? AND deleted_at IS NULL'
        '${types == null ? '' : ' AND event_type IN (${_marks(typeList.length)})'}',
        [entityType, ...part, _userId(), ...typeList],
      );
      result.addAll(rows.map(_event));
    }
    return result;
  }

  static const _eventColumns = 'entity_type, entity_id, parent_id, event_type, payload, occurred_at, rev';

  ActivityRecord _event(Map<String, Object?> r) => ActivityRecord(
    entityType: r['entity_type']! as String,
    entityId: r['entity_id']! as String,
    parentId: r['parent_id'] as String?,
    eventType: r['event_type']! as String,
    payload: _decodeMap(r['payload']! as String),
    occurredAt: _instant(r['occurred_at'])!,
    rev: _int(r['rev']) ?? 0,
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
  ///
  /// With [from] and [to] (the section's resolution window), recurring series only load the
  /// occurrence records and sessions keyed — or moved — inside the window; one-off tasks and
  /// after-completion series keep their whole history (their resolution reads every record).
  Future<PlannerInput> loadPlanner({String? taskId, String? seriesId, LocalDate? from, LocalDate? to}) async {
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
    final occurrences = <OccurrenceRecord>[];
    final entries = <TimeEntryRecord>[];
    final bounded = from != null && to != null
        ? {
            for (final t in tasks)
              if (t.recurrence != null && !_isAfterCompletion(t.recurrence!)) t.id,
          }
        : const <String>{};
    if (bounded.isNotEmpty) {
      await _loadWindow(
        [
          for (final id in ids)
            if (bounded.contains(id)) id,
        ],
        from: from!,
        to: to!,
        occurrences: occurrences,
        entries: entries,
      );
    }
    final unbounded = bounded.isEmpty
        ? ids
        : [
            for (final id in ids)
              if (!bounded.contains(id)) id,
          ];
    for (var i = 0; i < unbounded.length; i += _chunk) {
      final part = unbounded.sublist(i, i + _chunk > unbounded.length ? unbounded.length : i + _chunk);
      occurrences.addAll(
        (await _rows(
          'SELECT $_occurrenceColumns FROM task_occurrences '
          'WHERE task_id IN (${_marks(part.length)}) AND deleted_at IS NULL',
          part,
        )).map(_occurrence),
      );
      entries.addAll(
        (await _rows(
          'SELECT task_id, occurrence_key, started_at, ended_at FROM time_entries '
          'WHERE task_id IN (${_marks(part.length)}) AND deleted_at IS NULL',
          part,
        )).map(
          (e) => TimeEntryRecord(
            taskId: e['task_id']! as String,
            occurrenceKey: e['occurrence_key'] as String?,
            startedAt: _instant(e['started_at'])!,
            endedAt: _instant(e['ended_at']),
          ),
        ),
      );
    }
    final events = await _events('task', ids, types: const {'rescheduled', 'created', 'updated'});
    return PlannerInput(
      tasks: [for (final t in tasks) taskRecordOf(t)],
      occurrences: occurrences,
      timeEntries: entries,
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

  static bool _isAfterCompletion(String recurrence) {
    try {
      return RecurrenceRule.decode(recurrence).type == RuleType.afterCompletion;
    } on Object {
      return false;
    }
  }

  /// Records and sessions of the recurring tasks [ids] for the window [from]…[to]: occurrence keys
  /// in the window plus occurrences moved into it (their sessions keep the original key).
  Future<void> _loadWindow(
    List<String> ids, {
    required LocalDate from,
    required LocalDate to,
    required List<OccurrenceRecord> occurrences,
    required List<TimeEntryRecord> entries,
  }) async {
    final lo = from.toIso();
    final hi = to.plusDays(1).toIso();
    TimeEntryRecord entry(Map<String, Object?> e) => TimeEntryRecord(
      taskId: e['task_id']! as String,
      occurrenceKey: e['occurrence_key'] as String?,
      startedAt: _instant(e['started_at'])!,
      endedAt: _instant(e['ended_at']),
    );
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
      final rows = (await _rows(
        'SELECT $_occurrenceColumns FROM task_occurrences '
        'WHERE task_id IN (${_marks(part.length)}) AND deleted_at IS NULL '
        'AND ((occurrence_key >= ? AND occurrence_key < ?) OR (override_start_local >= ? AND override_start_local < ?))',
        [...part, lo, hi, lo, hi],
      )).map(_occurrence).toList();
      occurrences.addAll(rows);
      entries.addAll(
        (await _rows(
          'SELECT task_id, occurrence_key, started_at, ended_at FROM time_entries '
          'WHERE task_id IN (${_marks(part.length)}) AND deleted_at IS NULL '
          'AND occurrence_key >= ? AND occurrence_key < ?',
          [...part, lo, hi],
        )).map(entry),
      );
      final movedIn = [
        for (final r in rows)
          if (r.key.compareTo(lo) < 0 || r.key.compareTo(hi) >= 0) (r.taskId, r.key),
      ];
      for (final (taskId, key) in movedIn) {
        entries.addAll(
          (await _rows(
            'SELECT task_id, occurrence_key, started_at, ended_at FROM time_entries '
            'WHERE task_id = ? AND occurrence_key = ? AND deleted_at IS NULL',
            [taskId, key],
          )).map(entry),
        );
      }
    }
  }

  static const _occurrenceColumns =
      'task_id, occurrence_key, override_start_local, override_duration_minutes, override_title, is_cancelled, '
      'status, status_changed_at, completed_at, actual_start_at, actual_end_at, tracked_seconds, '
      'completion_percent, skip_reason, rating, outcome_note';

  /// Maps a `task_occurrences` row ([_occurrenceColumns]).
  OccurrenceRecord _occurrence(Map<String, Object?> o) => OccurrenceRecord(
    taskId: o['task_id']! as String,
    key: o['occurrence_key']! as String,
    overrideStartLocal: o['override_start_local'] == null ? null : _ldt(o['override_start_local']! as String),
    overrideDurationMinutes: _int(o['override_duration_minutes']),
    overrideTitle: o['override_title'] as String?,
    isCancelled: _bool(o['is_cancelled']) ?? false,
    status: switch (o['status']) {
      'in_progress' => PlannerOccurrenceStatus.inProgress,
      'done' => PlannerOccurrenceStatus.done,
      'skipped' => PlannerOccurrenceStatus.skipped,
      'missed' => PlannerOccurrenceStatus.missed,
      'cancelled' => PlannerOccurrenceStatus.cancelled,
      _ => PlannerOccurrenceStatus.scheduled,
    },
    statusChangedAt: _instant(o['status_changed_at']),
    completedAt: _instant(o['completed_at']),
    actualStartAt: _instant(o['actual_start_at']),
    actualEndAt: _instant(o['actual_end_at']),
    trackedSeconds: _int(o['tracked_seconds']),
    completionPercent: _int(o['completion_percent']),
    skipReason: o['skip_reason'] as String?,
    rating: _int(o['rating']),
    outcomeNote: o['outcome_note'] as String?,
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
    final items = <ItemRecord>[];
    for (var i = 0; i < listIds.length; i += _chunk) {
      final part = listIds.sublist(i, i + _chunk > listIds.length ? listIds.length : i + _chunk);
      // Stats count originals only (mirrors, T4.5.16).
      items.addAll(
        (await _rows(
          'SELECT $_itemColumns FROM checklist_items '
          'WHERE checklist_id IN (${_marks(part.length)}) AND user_id = ? AND mirror_of_id IS NULL',
          [...part, user],
        )).map(_item),
      );
    }
    if (listId != null) {
      // Items that were in this list before moving elsewhere keep their history here (burn-up,
      // arrivals): their earlier events carry this list as `parent_id`.
      final here = {for (final i in items) i.id};
      final movedOut =
          await (_db.selectOnly(_db.activityEvents, distinct: true)
                ..addColumns([_db.activityEvents.entityId])
                ..where(
                  _db.activityEvents.entityType.equals('checklist_item') &
                      _db.activityEvents.parentId.equals(listId) &
                      _db.activityEvents.userId.equals(user) &
                      _db.activityEvents.deletedAt.isNull(),
                ))
              .map((r) => r.read(_db.activityEvents.entityId)!)
              .get();
      final extra = [
        for (final id in movedOut)
          if (!here.contains(id)) id,
      ];
      for (var i = 0; i < extra.length; i += _chunk) {
        final part = extra.sublist(i, i + _chunk > extra.length ? extra.length : i + _chunk);
        items.addAll(
          (await _rows(
            'SELECT $_itemColumns FROM checklist_items '
            'WHERE id IN (${_marks(part.length)}) AND user_id = ? AND mirror_of_id IS NULL',
            [...part, user],
          )).map(_item),
        );
      }
    }
    final events = listId == null
        ? [
            for (final r in await _rows(
              'SELECT $_eventColumns FROM activity_events '
              "WHERE entity_type = 'checklist_item' AND user_id = ? AND deleted_at IS NULL",
              [user],
            ))
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
      items: items,
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

  static const _itemColumns =
      'id, checklist_id, parent_id, text, status, status_note, created_at, completed_at, deleted_at, due_local, '
      'time_zone, follow_up_at, waiting_on, updated_at';

  /// Maps a `checklist_items` row ([_itemColumns]).
  ItemRecord _item(Map<String, Object?> i) => ItemRecord(
    id: i['id']! as String,
    checklistId: i['checklist_id']! as String,
    parentId: i['parent_id'] as String?,
    text: i['text']! as String,
    status: i['status']! as String,
    statusNote: i['status_note'] as String?,
    createdAt: _instant(i['created_at'])!,
    completedAt: _instant(i['completed_at']),
    deletedAt: _instant(i['deleted_at']),
    dueLocal: i['due_local'] == null ? null : _ldt(i['due_local']! as String),
    timeZone: i['time_zone'] as String?,
    followUpAt: _instant(i['follow_up_at']),
    waitingOn: i['waiting_on'] as String?,
    updatedAt: _instant(i['updated_at']),
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
    final logs = <HabitLogRecord>[];
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
      logs.addAll(
        (await _rows(
          'SELECT $_logColumns FROM habit_logs WHERE habit_id IN (${_marks(part.length)}) AND deleted_at IS NULL',
          part,
        )).map(_log),
      );
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
      logs: logs,
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

  static const _logColumns =
      'id, habit_id, kind, logged_at, local_date, occurrence_key, value, mood, intensity, resisted, trigger, place, '
      'coping, duration_seconds, note, source, created_at';

  /// Maps a `habit_logs` row ([_logColumns]).
  HabitLogRecord _log(Map<String, Object?> l) {
    final loggedAt = _instant(l['logged_at'])!;
    return HabitLogRecord(
      id: l['id']! as String,
      habitId: l['habit_id']! as String,
      kind: l['kind']! as String,
      loggedAt: loggedAt,
      localDate: LocalDate.tryParse(l['local_date']! as String) ?? LocalDate.fromDateTime(loggedAt),
      occurrenceKey: l['occurrence_key'] as String?,
      value: _double(l['value']),
      mood: _int(l['mood']),
      intensity: _int(l['intensity']),
      resisted: _bool(l['resisted']),
      trigger: l['trigger'] as String?,
      place: l['place'] as String?,
      coping: l['coping'] as String?,
      durationSeconds: _int(l['duration_seconds']),
      note: l['note'] as String?,
      source: l['source']! as String,
      createdAt: _instant(l['created_at']),
    );
  }

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
            : ScopeEntity(
                t.id,
                t.title,
                color: t.color,
                icon: t.icon,
                parentId: t.seriesId,
                recurring: t.recurrence != null,
              );
      case 'series':
        final t =
            await (_db.select(_db.tasks)
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
    return query.watch().map(
      (rows) => [for (final h in rows) ScopeEntity(h.id, h.name, color: h.color, icon: h.icon, isQuit: true)],
    );
  }

  /// Filter options: live categories and tags.
  Future<List<FilterOption>> categoryOptions() async => [
    for (final c in await loadCategories())
      if (!c.archived) FilterOption(c.id, c.name, color: c.color),
  ];

  Future<List<FilterOption>> tagOptions() async => [
    for (final t in await loadTags()) FilterOption(t.id, t.name, color: t.color),
  ];

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
