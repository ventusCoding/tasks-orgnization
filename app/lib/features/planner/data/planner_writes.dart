import 'package:drift/drift.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/data/planner_mappers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/task.dart';

/// Transaction-level write helpers shared by the planner repositories. Everything here runs
/// inside a `SyncWriter.run` body (one operation, one undo).

/// Resettable fields of a `task_occurrences` row (written when a tombstone is revived).
const blankRecordFields = <String, Object?>{
  'override_start_local': null,
  'override_duration_minutes': null,
  'override_title': null,
  'override_notes': null,
  'is_cancelled': false,
  'status': 'scheduled',
  'status_changed_at': null,
  'completed_at': null,
  'actual_start_at': null,
  'actual_end_at': null,
  'tracked_seconds': null,
  'completion_percent': null,
  'skip_reason': null,
  'rating': null,
  'outcome_note': null,
};

/// Outcome columns carried over when a record is re-keyed or converted.
const recordOutcomeColumns = [
  'status',
  'status_changed_at',
  'completed_at',
  'actual_start_at',
  'actual_end_at',
  'tracked_seconds',
  'completion_percent',
  'skip_reason',
  'rating',
  'outcome_note',
];

/// Every non-common column of a record.
const recordDataColumns = [
  'override_start_local',
  'override_duration_minutes',
  'override_title',
  'override_notes',
  'is_cancelled',
  ...recordOutcomeColumns,
];

extension PlannerWriteTx on WriteTx {
  /// The live task [id] (null when missing or deleted).
  Future<Task?> readTask(String id) async {
    final raw = await readRaw('tasks', id);
    if (raw == null || raw['deleted_at'] != null) return null;
    return PlannerMappers.taskFromRaw(raw);
  }

  /// The live record of `(taskId, key)` (null when missing or tombstoned).
  Future<TaskOccurrenceRecord?> readRecord(String taskId, String key) async {
    final raw = await readRaw('task_occurrences', Ids.taskOccurrence(taskId, key));
    if (raw == null || raw['deleted_at'] != null) return null;
    return PlannerMappers.recordFromRaw(raw);
  }

  /// Live records of a task, by key.
  Future<List<TaskOccurrenceRecord>> readRecords(String taskId) async {
    final rows = await db.customSelect(
      'SELECT * FROM task_occurrences WHERE task_id = ? AND deleted_at IS NULL ORDER BY occurrence_key',
      variables: [Variable<String>(taskId)],
    ).get();
    return [for (final r in rows) PlannerMappers.recordFromRaw(r.data)];
  }

  /// Raw rows of [sql].
  Future<List<Map<String, Object?>>> rows(String sql, List<Object?> args) async {
    final result = await db.customSelect(sql, variables: [for (final a in args) Variable<Object>(a)]).get();
    return [for (final r in result) r.data];
  }

  /// Inserts or patches the deterministic record of `(taskId, key)`; a tombstoned row is revived
  /// with blank fields first. Returns the record id.
  Future<String> upsertRecord(String taskId, String key, Map<String, Object?> values) async {
    final id = Ids.taskOccurrence(taskId, key);
    final current = await readRaw('task_occurrences', id);
    if (current == null) {
      await insert('task_occurrences', id, {'task_id': taskId, 'occurrence_key': key, ...values});
    } else if (current['deleted_at'] != null) {
      await update('task_occurrences', id, {...blankRecordFields, 'deleted_at': null, ...values});
    } else {
      await update('task_occurrences', id, values);
    }
    return id;
  }

  /// Activity event on the task (`entity_type = task`, parent = series).
  Future<void> logTaskEvent(Task task, String type, [Map<String, Object?> payload = const {}, String? id]) => logEvent(
    entityType: 'task',
    entityId: task.id,
    parentId: task.seriesId,
    eventType: type,
    payload: {'seriesId': task.seriesId, ...payload},
    id: id,
  );

  /// Activity event on one occurrence (`entity_type = task_occurrence`, parent = task).
  Future<void> logOccurrenceEvent(Task task, String key, String type, [Map<String, Object?> payload = const {}]) => logEvent(
    entityType: 'task_occurrence',
    entityId: Ids.taskOccurrence(task.id, key),
    parentId: task.id,
    eventType: type,
    payload: {'taskId': task.id, 'seriesId': task.seriesId, 'occurrenceKey': key, ...payload},
  );

  /// Next backlog order key (end of the list).
  Future<String> nextBacklogKey() async {
    final r = await rows(
      'SELECT MAX(manual_sort_key) AS k FROM tasks WHERE user_id = ? AND deleted_at IS NULL AND start_local IS NULL',
      [userId],
    );
    return FractionalIndex.between(r.first['k'] as String?, null);
  }

  /// Copies the rows of [table] where [column] = [fromId] to [toId] (new ids). Used for
  /// attachments and notification rules when duplicating/splitting a task.
  Future<int> copyOwnedRows(String table, String column, String fromId, String toId, {String? typeColumn, String? typeValue}) async {
    final filter = typeColumn == null ? '' : ' AND $typeColumn = ?';
    final source = await rows(
      'SELECT * FROM $table WHERE $column = ? AND deleted_at IS NULL$filter',
      [fromId, ?typeValue],
    );
    const skip = {'id', 'user_id', 'created_at', 'updated_at', 'deleted_at', 'rev', 'field_clock', 'server_updated_at', 'origin_device_id'};
    for (final row in source) {
      await insert(table, Ids.v7(), {
        for (final e in row.entries)
          if (!skip.contains(e.key)) e.key: e.value,
        column: toId,
      });
    }
    return source.length;
  }
}

/// Time fields of a task for `updated`/`created` payloads (arch §7.3: before/after time fields).
Map<String, Object?> taskTimeFields(Task t) => {
  'start': t.startLocal?.toIso(),
  'duration': t.durationMinutes,
  'allDay': t.isAllDay,
  'zone': t.timeZone,
  'recurrence': t.recurrence?.toJson(),
};

/// Names of the columns that differ between [a] and [b] (editable columns only).
List<String> changedColumns(Task a, Task b) {
  final ca = a.toColumns();
  final cb = b.toColumns();
  return [
    for (final k in ca.keys)
      if (k != 'recurrence_until_local' && k != 'series_id' && !_deepEq(ca[k], cb[k])) k,
  ];
}

bool _deepEq(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_deepEq(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEq(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Columns that define *when* a task happens (their change re-keys occurrences).
const timingColumns = {'start_local', 'duration_minutes', 'is_all_day', 'time_zone', 'recurrence'};
