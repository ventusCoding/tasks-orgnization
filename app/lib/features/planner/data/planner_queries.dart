import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/planner/data/planner_mappers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Checklist summary for the linked-checklist picker and progress (T3.1.16).
@immutable
class LinkedChecklistInfo {
  const LinkedChecklistInfo({required this.id, required this.title, required this.total, required this.completed});

  final String id;
  final String title;

  /// Countable leaves (cancelled excluded) and completed ones.
  final int total;
  final int completed;

  double get progress => total == 0 ? 0 : completed / total;

  @override
  bool operator ==(Object other) =>
      other is LinkedChecklistInfo &&
      other.id == id &&
      other.title == title &&
      other.total == total &&
      other.completed == completed;

  @override
  int get hashCode => Object.hash(id, title, total, completed);
}

/// Inputs of a range resolution: pre-filtered tasks, their records and category colors.
@immutable
class RangeData {
  const RangeData({
    required this.tasks,
    required this.records,
    required this.categoryColors,
    this.categoryIcons = const {},
  });

  final List<Task> tasks;
  final List<TaskOccurrenceRecord> records;
  final Map<String, int> categoryColors;

  /// Icon keys of the categories that have one (default task icon, T3.1.12).
  final Map<String, String> categoryIcons;
}

/// Read side of the planner (DAO role, T3.1.03): Drift streams and range pre-filters.
class PlannerQueries {
  PlannerQueries(this._db, this._userId);

  final AppDatabase _db;
  final String Function() _userId;

  /// Margin covering the largest zone offset difference (arch: ±14 h).
  static const zoneMarginMinutes = 14 * 60;

  // ---------------------------------------------------------------------------
  // Tasks

  SimpleSelectStatement<$TasksTable, TaskRow> _tasks() =>
      _db.select(_db.tasks)..where((t) => t.deletedAt.isNull() & t.userId.equals(_userId()));

  Stream<Task?> watchTask(String id) => (_tasks()..where((t) => t.id.equals(id))).watchSingleOrNull().map(
    (r) => r == null ? null : PlannerMappers.task(r),
  );

  Future<Task?> task(String id, {bool includeDeleted = false}) async {
    final q = _db.select(_db.tasks)..where((t) => t.id.equals(id) & t.userId.equals(_userId()));
    if (!includeDeleted) q.where((t) => t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    return row == null ? null : PlannerMappers.task(row);
  }

  /// Every task of a series (splits share `series_id`), oldest first.
  Stream<List<Task>> watchSeries(String seriesId) =>
      (_tasks()
            ..where((t) => t.seriesId.equals(seriesId))
            ..orderBy([(t) => OrderingTerm.asc(t.startLocal), (t) => OrderingTerm.asc(t.id)]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.task).toList());

  Future<List<Task>> seriesTasks(String seriesId) async =>
      (await (_tasks()
                ..where((t) => t.seriesId.equals(seriesId))
                ..orderBy([(t) => OrderingTerm.asc(t.startLocal)]))
              .get())
          .map(PlannerMappers.task)
          .toList();

  /// Backlog: unscheduled, non-template, non-archived tasks in manual order (T3.1.11).
  Stream<List<Task>> watchUnscheduled() =>
      (_tasks()
            ..where((t) => t.startLocal.isNull() & t.isTemplate.equals(false) & t.status.isNotValue('archived'))
            ..orderBy([
              (t) => OrderingTerm(expression: t.manualSortKey, nulls: NullsOrder.last),
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.task).toList());

  Future<List<Task>> unscheduled() => watchUnscheduled().first;

  /// Tasks shown in the countdown list (T3.7.12): `countdown_mode` set, not templates / archived.
  Stream<List<Task>> watchCountdownTasks() =>
      (_tasks()
            ..where((t) => t.countdownMode.isNotNull() & t.isTemplate.equals(false) & t.status.isNotValue('archived'))
            ..orderBy([(t) => OrderingTerm.asc(t.title), (t) => OrderingTerm.asc(t.id)]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.task).toList());

  /// Tasks scheduling a checklist item (T3.1.21), oldest first.
  Stream<List<Task>> watchItemTasks() =>
      (_tasks()
            ..where((t) => t.linkedItemId.isNotNull() & t.isTemplate.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.task).toList());

  Future<List<Task>> tasksForItem(String itemId) async =>
      (await (_tasks()
                ..where((t) => t.linkedItemId.equals(itemId) & t.isTemplate.equals(false))
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get())
          .map(PlannerMappers.task)
          .toList();

  /// Task templates (T3.1.20).
  Stream<List<Task>> watchTemplates() =>
      (_tasks()
            ..where((t) => t.isTemplate.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title), (t) => OrderingTerm.asc(t.id)]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.task).toList());

  /// Range pre-filter (T3.2.02): scheduled, active, non-template tasks that may produce an
  /// occurrence overlapping `[from, to)` (viewer wall clock ± 14 h), plus tasks with a record
  /// moved into the range.
  Future<List<Task>> tasksForRange(LocalDateTime from, LocalDateTime to) async {
    final fromMinus = from.plusMinutes(-zoneMarginMinutes).toIso();
    final toPlus = to.plusMinutes(zoneMarginMinutes).toIso();
    final movedFrom = from.plusMinutes(-zoneMarginMinutes).plusDays(-31).toIso();
    const end =
        "strftime('%Y-%m-%dT%H:%M', start_local, '+' || COALESCE(duration_minutes, "
        "CASE WHEN is_all_day THEN 1440 ELSE 0 END) || ' minutes')";
    const untilEnd =
        "strftime('%Y-%m-%dT%H:%M', recurrence_until_local, '+' || COALESCE(duration_minutes, 1440) || ' minutes')";
    final rows = await _db
        .customSelect(
          'SELECT * FROM tasks WHERE user_id = ? AND deleted_at IS NULL AND is_template = 0 '
          "AND status <> 'archived' AND start_local IS NOT NULL AND ("
          ' (start_local <= ? AND ('
          '   (recurrence IS NULL AND $end >= ?)'
          '   OR (recurrence IS NOT NULL AND (recurrence_until_local IS NULL OR $untilEnd >= ?))'
          ' ))'
          ' OR id IN (SELECT task_id FROM task_occurrences WHERE deleted_at IS NULL AND override_start_local IS NOT NULL'
          '   AND override_start_local >= ? AND override_start_local < ?)'
          ') ORDER BY start_local, id',
          variables: [
            Variable<String>(_userId()),
            Variable<String>(toPlus),
            Variable<String>(fromMinus),
            Variable<String>(fromMinus),
            Variable<String>(movedFrom),
            Variable<String>(toPlus),
          ],
          readsFrom: {_db.tasks, _db.taskOccurrences},
        )
        .get();
    return [for (final r in rows) PlannerMappers.taskFromRaw(r.data)];
  }

  /// Records needed to resolve [tasks] over `[from, to)`: keys near the range, records moved
  /// into it, quota slots, and every record of one-off / after-completion / completions-count
  /// tasks (their resolution needs history).
  Future<List<TaskOccurrenceRecord>> recordsForRange(List<Task> tasks, LocalDateTime from, LocalDateTime to) async {
    if (tasks.isEmpty) return const [];
    var maxDuration = 0;
    final allRecordsFor = <String>[];
    for (final t in tasks) {
      maxDuration = math.max(maxDuration, t.effectiveDurationMinutes);
      final rule = t.recurrence;
      if (rule == null || rule.type != RuleType.fixed || rule.countMode == CountMode.completions) {
        allRecordsFor.add(t.id);
      }
    }
    final keyFrom = from.plusMinutes(-zoneMarginMinutes - maxDuration).date.minusDays(1).toIso();
    final keyTo = to.plusMinutes(zoneMarginMinutes).date.plusDays(1).toIso();
    final movedFrom = from.plusMinutes(-zoneMarginMinutes).plusDays(-31).toIso();
    final toPlus = to.plusMinutes(zoneMarginMinutes).toIso();
    final ids = tasks.map((t) => t.id).toList();
    String marks(int n) => List.filled(n, '?').join(', ');
    final rows = await _db
        .customSelect(
          'SELECT * FROM task_occurrences WHERE deleted_at IS NULL AND user_id = ? AND task_id IN (${marks(ids.length)}) AND ('
          ' (occurrence_key >= ? AND occurrence_key < ?)'
          ' OR (override_start_local IS NOT NULL AND override_start_local >= ? AND override_start_local < ?)'
          " OR instr(occurrence_key, '#') > 0"
          '${allRecordsFor.isEmpty ? '' : ' OR task_id IN (${marks(allRecordsFor.length)})'}'
          ')',
          variables: [
            Variable<String>(_userId()),
            for (final id in ids) Variable<String>(id),
            Variable<String>(keyFrom),
            Variable<String>(keyTo),
            Variable<String>(movedFrom),
            Variable<String>(toPlus),
            for (final id in allRecordsFor) Variable<String>(id),
          ],
          readsFrom: {_db.taskOccurrences},
        )
        .get();
    return [for (final r in rows) PlannerMappers.recordFromRaw(r.data)];
  }

  /// Latest `paused` event per paused task (pause moment, T3.2.21).
  Future<Map<String, DateTime>> pausedAt(Iterable<String> taskIds) async {
    final ids = taskIds.toList();
    if (ids.isEmpty) return const {};
    final rows = await _db
        .customSelect(
          'SELECT entity_id, MAX(occurred_at) AS at FROM activity_events WHERE deleted_at IS NULL '
          "AND entity_type = 'task' AND event_type = 'paused' AND entity_id IN (${List.filled(ids.length, '?').join(', ')}) "
          'GROUP BY entity_id',
          variables: [for (final id in ids) Variable<String>(id)],
          readsFrom: {_db.activityEvents},
        )
        .get();
    return {
      for (final r in rows)
        if (DateTime.tryParse('${r.data['at']}') case final at?) r.data['entity_id']! as String: at.toUtc(),
    };
  }

  Future<Map<String, int>> categoryColors() async {
    final rows = await (_db.select(
      _db.categories,
    )..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()))).get();
    return {for (final c in rows) c.id: c.color};
  }

  /// Category icon keys by id (categories without an icon are left out).
  Future<Map<String, String>> categoryIcons() async {
    final rows = await (_db.select(
      _db.categories,
    )..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()))).get();
    return {
      for (final c in rows)
        if (c.icon case final icon? when icon.isNotEmpty) c.id: icon,
    };
  }

  /// Category names by id (notification template variable `category`).
  Future<Map<String, String>> categoryNames() async {
    final rows = await (_db.select(
      _db.categories,
    )..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()))).get();
    return {for (final c in rows) c.id: c.name};
  }

  /// Everything the resolver needs for a viewer range.
  Future<RangeData> loadRange(LocalDateTime from, LocalDateTime to) async {
    var tasks = await tasksForRange(from, to);
    final paused = tasks.where((t) => t.isPaused).map((t) => t.id).toList();
    if (paused.isNotEmpty) {
      final at = await pausedAt(paused);
      tasks = [for (final t in tasks) t.isPaused ? t.copyWith(pausedAt: at[t.id]) : t];
    }
    final records = await recordsForRange(tasks, from, to);
    return RangeData(
      tasks: tasks,
      records: records,
      categoryColors: await categoryColors(),
      categoryIcons: await categoryIcons(),
    );
  }

  /// Emits whenever planner-relevant tables change (tasks, occurrences, categories).
  Stream<Set<TableUpdate>> changes() =>
      _db.tableUpdates(TableUpdateQuery.onAllTables([_db.tasks, _db.taskOccurrences, _db.categories]));

  // ---------------------------------------------------------------------------
  // Occurrence records

  Stream<List<TaskOccurrenceRecord>> watchRecords(Iterable<String> taskIds) {
    final ids = taskIds.toList();
    return (_db.select(_db.taskOccurrences)
          ..where((o) => o.deletedAt.isNull() & o.userId.equals(_userId()) & o.taskId.isIn(ids))
          ..orderBy([(o) => OrderingTerm.asc(o.occurrenceKey)]))
        .watch()
        .map((rows) => rows.map(PlannerMappers.record).toList());
  }

  Future<List<TaskOccurrenceRecord>> records(Iterable<String> taskIds) => watchRecords(taskIds).first;

  Stream<TaskOccurrenceRecord?> watchRecord(String taskId, String key) =>
      (_db.select(_db.taskOccurrences)..where(
            (o) =>
                o.deletedAt.isNull() &
                o.userId.equals(_userId()) &
                o.taskId.equals(taskId) &
                o.occurrenceKey.equals(key),
          ))
          .watchSingleOrNull()
          .map((r) => r == null ? null : PlannerMappers.record(r));

  // ---------------------------------------------------------------------------
  // Time entries

  Stream<List<TimeEntry>> watchTimeEntries(String taskId, String? occurrenceKey) {
    final q = _db.select(_db.timeEntries)
      ..where((e) => e.deletedAt.isNull() & e.userId.equals(_userId()) & e.taskId.equals(taskId))
      ..orderBy([(e) => OrderingTerm.asc(e.startedAt)]);
    if (occurrenceKey != null) q.where((e) => e.occurrenceKey.equals(occurrenceKey));
    return q.watch().map((rows) => rows.map(PlannerMappers.timeEntry).toList());
  }

  /// Time entries overlapping [fromUtc, toUtc) (plan vs actual, T3.7.06); running ones included.
  Stream<List<TimeEntry>> watchEntriesBetween(DateTime fromUtc, DateTime toUtc) =>
      (_db.select(_db.timeEntries)
            ..where(
              (e) =>
                  e.deletedAt.isNull() &
                  e.userId.equals(_userId()) &
                  e.startedAt.isSmallerThanValue(toUtc) &
                  (e.endedAt.isNull() | e.endedAt.isBiggerThanValue(fromUtc)),
            )
            ..orderBy([(e) => OrderingTerm.asc(e.startedAt)]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.timeEntry).toList());

  /// Running timers (T3.2.19).
  Stream<List<TimeEntry>> watchRunningEntries() =>
      (_db.select(_db.timeEntries)
            ..where((e) => e.deletedAt.isNull() & e.userId.equals(_userId()) & e.endedAt.isNull())
            ..orderBy([(e) => OrderingTerm.asc(e.startedAt)]))
          .watch()
          .map((rows) => rows.map(PlannerMappers.timeEntry).toList());

  // ---------------------------------------------------------------------------
  // History

  /// Activity events of the tasks (and their occurrences), newest first (T3.1.09 / T3.2.20).
  Stream<List<ActivityEvent>> watchHistory(Iterable<String> taskIds, {int limit = 50}) {
    final ids = taskIds.toList();
    return (_db.select(_db.activityEvents)
          ..where(
            (e) => e.deletedAt.isNull() & e.userId.equals(_userId()) & (e.entityId.isIn(ids) | e.parentId.isIn(ids)),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt), (e) => OrderingTerm.desc(e.id)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(PlannerMappers.event).toList());
  }

  Future<List<ActivityEvent>> history(Iterable<String> taskIds, {int limit = 500}) =>
      watchHistory(taskIds, limit: limit).first;

  // ---------------------------------------------------------------------------
  // Linked checklists (queried directly; the checklists feature owns the tables)

  static const _checklistSql =
      'SELECT c.id AS id, c.title AS title, '
      '(SELECT COUNT(*) FROM checklist_items i WHERE i.checklist_id = c.id AND i.deleted_at IS NULL '
      "  AND i.status <> 'cancelled' AND NOT EXISTS (SELECT 1 FROM checklist_items ch WHERE ch.parent_id = i.id AND ch.deleted_at IS NULL)) AS total, "
      '(SELECT COUNT(*) FROM checklist_items i WHERE i.checklist_id = c.id AND i.deleted_at IS NULL '
      "  AND i.status = 'completed' AND NOT EXISTS (SELECT 1 FROM checklist_items ch WHERE ch.parent_id = i.id AND ch.deleted_at IS NULL)) AS completed "
      'FROM checklists c WHERE c.user_id = ? AND c.deleted_at IS NULL';

  LinkedChecklistInfo _checklist(QueryRow r) => LinkedChecklistInfo(
    id: r.data['id']! as String,
    title: (r.data['title'] as String?) ?? '',
    total: (r.data['total'] as int?) ?? 0,
    completed: (r.data['completed'] as int?) ?? 0,
  );

  Stream<List<LinkedChecklistInfo>> watchChecklists() => _db
      .customSelect(
        '$_checklistSql AND c.archived_at IS NULL AND c.is_template = 0 ORDER BY c.is_pinned DESC, c.sort_key, c.id',
        variables: [Variable<String>(_userId())],
        readsFrom: {_db.checklists, _db.checklistItems},
      )
      .watch()
      .map((rows) => rows.map(_checklist).toList());

  Stream<LinkedChecklistInfo?> watchChecklist(String id) => _db
      .customSelect(
        '$_checklistSql AND c.id = ?',
        variables: [Variable<String>(_userId()), Variable<String>(id)],
        readsFrom: {_db.checklists, _db.checklistItems},
      )
      .watch()
      .map((rows) => rows.isEmpty ? null : _checklist(rows.first));
}
