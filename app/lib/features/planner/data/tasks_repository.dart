import 'dart:convert';

import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/planner/data/planner_queries.dart';
import 'package:everslot/features/planner/data/planner_writes.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_validation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

/// Result of a task write: the task id, the undoable operation and — after a split — the id
/// of the new series part.
@immutable
class TaskWriteResult {
  const TaskWriteResult(this.taskId, this.record, {this.newTaskId});

  final String taskId;
  final OpRecord record;

  /// Task created by a "this & following" (or implicit) split.
  final String? newTaskId;
}

/// Target of a bulk action (T3.1.18): one occurrence, or the whole series when [series].
@immutable
class BulkTarget {
  const BulkTarget(this.taskId, {this.occurrenceKey, this.series = false});

  final String taskId;
  final String? occurrenceKey;
  final bool series;
}

/// Bulk change (T3.1.18).
@immutable
sealed class BulkChange {
  const BulkChange();
}

final class BulkMove extends BulkChange {
  const BulkMove({this.days = 0, this.minutes = 0});

  final int days;
  final int minutes;
}

final class BulkSetCategory extends BulkChange {
  const BulkSetCategory(this.categoryId);

  final String? categoryId;
}

final class BulkSetPriority extends BulkChange {
  const BulkSetPriority(this.priority);

  final int priority;
}

final class BulkSetTrackingMode extends BulkChange {
  const BulkSetTrackingMode(this.mode);

  final TrackingMode mode;
}

final class BulkDuplicate extends BulkChange {
  const BulkDuplicate();
}

final class BulkDelete extends BulkChange {
  const BulkDelete();
}

/// Write side of the planner's tasks (T3.1.05 + scopes of [3.2]). Every public method is ONE
/// `SyncWriter.run` (one transaction, one operation group, one undo) writing rows, outbox
/// patches and activity events (payload contracts of arch §7.3).
class TasksRepository {
  TasksRepository(this._writer, this._queries, this._service);

  final SyncWriter _writer;
  final PlannerQueries _queries;
  final RecurrenceService Function() _service;

  RecurrenceService get _svc => _service();

  static bool isValidZone(String zone) {
    if (zone == 'UTC') return true;
    try {
      tz.getLocation(zone);
      return true;
    } on Object {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Create

  /// Validates and inserts [draft] (empty `id`/`seriesId` get fresh ids). [inTx] runs in the same
  /// transaction right after the insert (e.g. the editor's pending reminders, T7.1.09).
  Future<TaskWriteResult> create(
    Task draft, {
    String source = 'editor',
    Map<String, Object?> payload = const {},
    Future<void> Function(WriteTx tx, Task task)? inTx,
  }) async {
    final task = prepare(draft);
    final record = await _writer.run((tx) async {
      await _insertTask(tx, task, source: source, payload: payload);
      if (inTx != null) await inTx(tx, task);
    });
    return TaskWriteResult(task.id, record);
  }

  /// Normalizes, validates and derives `recurrence_until_local` (throws [TaskValidationException]).
  Task prepare(Task draft) {
    final errors = validateTask(draft, isValidZone: isValidZone);
    if (errors.isNotEmpty) throw TaskValidationException(errors);
    final id = draft.id.isEmpty ? Ids.v7() : draft.id;
    String? blank(String? s) => (s == null || s.trim().isEmpty) ? null : s;
    final t = draft.copyWith(
      id: id,
      seriesId: draft.seriesId.isEmpty ? id : draft.seriesId,
      title: draft.title.trim(),
      url: TaskUrl.normalize(draft.url),
      notes: blank(draft.notes),
      location: blank(draft.location)?.trim(),
    );
    return t.copyWith(recurrenceUntilLocal: TaskSchedule.of(t).recurrenceUntilLocal(_svc.engine));
  }

  Future<void> _insertTask(WriteTx tx, Task t, {required String source, Map<String, Object?> payload = const {}}) async {
    var task = t;
    if (task.isUnscheduled && task.manualSortKey == null && !task.isTemplate) {
      task = task.copyWith(manualSortKey: await tx.nextBacklogKey());
    }
    await tx.insert('tasks', task.id, task.toColumns());
    await tx.logTaskEvent(task, 'created', {'source': source, ...taskTimeFields(task), ...payload});
  }

  // ---------------------------------------------------------------------------
  // Update with scopes (T3.1.05, T3.2.06–T3.2.09)

  /// Orphaned records an edit would leave (T3.2.09), for the confirmation dialog.
  Future<OrphanReport> previewOrphans(
    Task edited, {
    EditScope scope = EditScope.allOccurrences,
    String? occurrenceKey,
    bool rewritePast = false,
  }) async {
    final current = await _queries.task(edited.id);
    if (current == null || !current.isRecurring) return OrphanReport.none;
    final changed = changedColumns(current, edited);
    if (!changed.any(timingColumns.contains)) return OrphanReport.none;
    final records = await _queries.records([current.id]);
    switch (scope) {
      case EditScope.thisOccurrence:
        return OrphanReport.none;
      case EditScope.thisAndFollowing:
        final k = occurrenceKey!;
        final split = _safeSplit(current, k);
        final unchangedStart = edited.startLocal == null || edited.startLocal == current.startLocal;
        final target = edited.copyWith(
          recurrence: edited.recurrence == current.recurrence ? split?.newRule ?? edited.recurrence : edited.recurrence,
          startLocal: unchangedStart ? (split?.newAnchor.start ?? edited.startLocal) : edited.startLocal,
        );
        return _orphansFor(current, target, records.where((r) => r.occurrenceKey.compareTo(k) >= 0), shiftFrom: _originalStart(current, k));
      case EditScope.allOccurrences:
        final k0 = rewritePast ? null : _firstNonPastKey(current);
        if (k0 == null || _safeSplit(current, k0)?.truncatedRule == null) {
          return _orphansFor(current, edited, records, shiftFrom: null);
        }
        return OrphanReport.none;
    }
  }

  /// Applies [edited] (full task state, same id) with the chosen scope.
  ///
  /// * One-off tasks: direct edit (a done record follows the task to its new start).
  /// * [EditScope.thisOccurrence]: start/duration/title/notes overrides on [occurrenceKey].
  /// * [EditScope.thisAndFollowing]: series split at [occurrenceKey] (T3.2.07).
  /// * [EditScope.allOccurrences]: non-timing fields update the master; timing/rule changes
  ///   apply from the first non-past occurrence through an implicit split unless [rewritePast]
  ///   (T3.2.08). Orphaned records follow [orphanPolicy] (T3.2.09).
  Future<TaskWriteResult> update(
    Task edited, {
    EditScope scope = EditScope.allOccurrences,
    String? occurrenceKey,
    bool rewritePast = false,
    OrphanPolicy orphanPolicy = OrphanPolicy.keepAsOneOff,
    String source = 'editor',
  }) async {
    final current = await _queries.task(edited.id);
    if (current == null) throw NotFoundException('task ${edited.id}');
    final errors = validateTask(edited, isValidZone: isValidZone);
    if (errors.isNotEmpty) throw TaskValidationException(errors);
    final normalized = edited.copyWith(title: edited.title.trim(), url: TaskUrl.normalize(edited.url));
    String? newId;
    final record = await _writer.run((tx) async {
      newId = await _applyEdit(
        tx,
        current,
        normalized,
        scope: scope,
        key: occurrenceKey,
        rewritePast: rewritePast,
        policy: orphanPolicy,
        source: source,
      );
    });
    return TaskWriteResult(edited.id, record, newTaskId: newId);
  }

  Future<String?> _applyEdit(
    WriteTx tx,
    Task current,
    Task edited, {
    required EditScope scope,
    String? key,
    bool rewritePast = false,
    OrphanPolicy policy = OrphanPolicy.keepAsOneOff,
    String source = 'editor',
  }) async {
    final changed = changedColumns(current, edited);
    if (changed.isEmpty) return null;
    if (!current.isRecurring) {
      await _directEdit(tx, current, edited, policy: policy, source: source);
      return null;
    }
    final timing = changed.any(timingColumns.contains);
    switch (scope) {
      case EditScope.thisOccurrence:
        final k = key ?? (throw ArgumentError('occurrenceKey required for thisOccurrence'));
        const allowed = {'start_local', 'duration_minutes', 'title', 'notes'};
        final seriesLevel = changed.where((c) => !allowed.contains(c)).toList();
        if (seriesLevel.isNotEmpty) {
          throw ValidationException('Series-level fields ${seriesLevel.join(', ')} cannot change for one occurrence');
        }
        await _editOccurrenceTx(
          tx,
          current,
          k,
          start: changed.contains('start_local') ? edited.startLocal : null,
          duration: changed.contains('duration_minutes') ? edited.durationMinutes : null,
          title: changed.contains('title') ? edited.title : null,
          notes: changed.contains('notes') ? (edited.notes ?? '') : null,
          source: source,
        );
        return null;
      case EditScope.thisAndFollowing:
        final k = key ?? (throw ArgumentError('occurrenceKey required for thisAndFollowing'));
        return _splitEdit(tx, current, edited, k, policy: policy, source: source, scopeName: 'following');
      case EditScope.allOccurrences:
        if (!timing || rewritePast || current.recurrence!.type != RuleType.fixed) {
          await _directEdit(tx, current, edited, policy: policy, source: source);
          return null;
        }
        final k0 = _firstNonPastKey(current);
        final split = k0 == null ? null : _safeSplit(current, k0);
        if (k0 == null || split == null || split.truncatedRule == null) {
          await _directEdit(tx, current, edited, policy: policy, source: source);
          return null;
        }
        // Past occurrences keep their times: the edit applies from k0 on. The user's shift of
        // the series start is re-applied to k0's own start.
        final delta = current.startLocal!.minutesUntil(edited.startLocal ?? current.startLocal!);
        final fromK0 = edited.copyWith(startLocal: _originalStart(current, k0)!.plusMinutes(delta));
        return _splitEdit(tx, current, fromK0, k0, policy: policy, source: source, scopeName: 'all');
    }
  }

  /// Direct edit of the master row (+ record re-keying and orphan handling).
  Future<void> _directEdit(
    WriteTx tx,
    Task current,
    Task edited, {
    OrphanPolicy policy = OrphanPolicy.keepAsOneOff,
    String source = 'editor',
    String? rescheduleEventId,
    bool logUpdated = true,
  }) async {
    final changed = changedColumns(current, edited);
    if (changed.isEmpty) return;
    var next = edited.copyWith(recurrenceUntilLocal: TaskSchedule.of(edited).recurrenceUntilLocal(_svc.engine));
    if (next.isUnscheduled && !current.isUnscheduled && next.manualSortKey == null) {
      next = next.copyWith(manualSortKey: await tx.nextBacklogKey());
    }
    final columns = next.toColumns();
    final values = <String, Object?>{
      for (final c in changed) c: columns[c],
      'recurrence_until_local': columns['recurrence_until_local'],
      if (next.manualSortKey != current.manualSortKey) 'manual_sort_key': next.manualSortKey,
    };
    await tx.update('tasks', current.id, values);

    final timing = changed.any(timingColumns.contains);
    if (timing && !next.isUnscheduled) {
      if (!next.isRecurring) {
        final newKey = next.oneOffKey!;
        if (!current.isRecurring && !current.isUnscheduled) {
          final oldKey = current.oneOffKey!;
          if (oldKey != newKey) {
            final rec = await tx.readRecord(current.id, oldKey);
            if (rec != null) await _moveRecord(tx, rec, current.id, newKey, clearOverrides: true);
          }
        } else if (current.isRecurring) {
          final records = await tx.readRecords(current.id);
          await _handleOrphans(tx, current, records.where((r) => r.occurrenceKey != newKey).toList(), policy);
        }
      } else {
        final records = await tx.readRecords(current.id);
        final report = _orphansFor(current, next, records, shiftFrom: null);
        await _handleOrphans(tx, current, [...report.withOutcome, ...report.overridesOnly, ...report.cancelledOnly], policy);
      }
    }

    // Events (arch §7.3 payload contracts).
    final zone = next.timeZone ?? current.timeZone ?? _svc.currentZone;
    if (current.isUnscheduled && !next.isUnscheduled) {
      await tx.logTaskEvent(next, 'scheduled', {
        'toStart': next.startLocal!.toIso(),
        'toDuration': next.durationMinutes,
        'zone': zone,
        'source': source,
      });
    } else if (!current.isUnscheduled && next.isUnscheduled) {
      await tx.logTaskEvent(next, 'unscheduled', {
        'fromStart': current.startLocal!.toIso(),
        'fromDuration': current.durationMinutes,
        'zone': zone,
        'source': source,
      });
    } else if (!next.isUnscheduled && (changed.contains('start_local') || changed.contains('duration_minutes') || changed.contains('is_all_day'))) {
      await tx.logTaskEvent(
        next,
        'rescheduled',
        {
          if (current.isRecurring) 'scope': 'series' else 'occurrenceKey': current.oneOffKey,
          'fromStart': current.startLocal!.toIso(),
          'toStart': next.startLocal!.toIso(),
          'fromDuration': current.effectiveDurationMinutes,
          'toDuration': next.effectiveDurationMinutes,
          'zone': zone,
          'source': source,
        },
        rescheduleEventId,
      );
    }
    final other = changed.where((c) => c != 'start_local' && c != 'duration_minutes').toList();
    if (logUpdated && other.isNotEmpty) {
      await tx.logTaskEvent(next, 'updated', {
        'fields': other,
        'before': taskTimeFields(current),
        'after': taskTimeFields(next),
        'source': source,
      });
    }
  }

  /// "This & following" split at [k] (T3.2.07). Returns the new task id (or null when the
  /// edit fell back to a direct edit because [k] is the first occurrence).
  Future<String?> _splitEdit(
    WriteTx tx,
    Task current,
    Task edited,
    String k, {
    required OrphanPolicy policy,
    required String source,
    required String scopeName,
  }) async {
    final rule = current.recurrence!;
    final split = rule.type == RuleType.fixed ? _svc.split(rule, current.anchor!, k) : null;
    if (split == null || split.truncatedRule == null) {
      await _directEdit(tx, current, edited, policy: policy, source: source);
      return null;
    }
    final originalK = _originalStart(current, k)!;
    final truncated = current.copyWith(recurrence: split.truncatedRule);
    await tx.update('tasks', current.id, {
      'recurrence': split.truncatedRule!.toJson(),
      'recurrence_until_local': TaskSchedule.of(truncated).recurrenceUntilLocal(_svc.engine)?.toIso(),
    });

    final newId = Ids.v7();
    final ruleUnchanged = edited.recurrence == rule;
    // [edited.startLocal] is the new start of occurrence k. An unchanged *series* start means the
    // caller edited other fields only: the new part then starts at k's own start (never before
    // the split, which would duplicate the truncated part's occurrences).
    final editedStart = edited.startLocal;
    final newStart = editedStart == null || editedStart == current.startLocal ? split.newAnchor.start : editedStart;
    var newTask = edited.copyWith(
      id: newId,
      seriesId: current.seriesId,
      recurrence: ruleUnchanged ? split.newRule : edited.recurrence,
      startLocal: newStart,
      status: TaskStatus.active,
    );
    newTask = newTask.copyWith(recurrenceUntilLocal: TaskSchedule.of(newTask).recurrenceUntilLocal(_svc.engine));
    await tx.insert('tasks', newId, newTask.toColumns());

    // Re-key records ≥ k to the new task (new deterministic ids, old rows tombstoned).
    final records = (await tx.readRecords(current.id)).where((r) => r.occurrenceKey.compareTo(k) >= 0).toList();
    final report = _orphansFor(current, newTask, records, shiftFrom: originalK);
    final orphanIds = {
      for (final r in [...report.withOutcome, ...report.overridesOnly, ...report.cancelledOnly]) r.id,
    };
    for (final r in records) {
      if (orphanIds.contains(r.id)) continue;
      await _moveRecord(tx, r, newId, _targetKey(newTask, r.occurrenceKey, originalK)!);
    }
    await _handleOrphans(tx, newTask, [...report.withOutcome, ...report.overridesOnly, ...report.cancelledOnly], policy);

    // Copy the attachment rows and notification rules of the series ([7.1] hook).
    await tx.copyOwnedRows('attachments', 'owner_id', current.id, newId, typeColumn: 'owner_type', typeValue: 'task');
    await tx.copyOwnedRows('notification_rules', 'target_id', current.id, newId, typeColumn: 'target_type', typeValue: 'task');

    await tx.logTaskEvent(current, 'series_split', {'fromTaskId': current.id, 'toTaskId': newId, 'atKey': k});
    await tx.logTaskEvent(newTask, 'created', {'source': source, 'splitFrom': current.id, 'atKey': k, ...taskTimeFields(newTask)});
    final fromDuration = current.effectiveDurationMinutes;
    if (newTask.startLocal != originalK || newTask.effectiveDurationMinutes != fromDuration) {
      await tx.logTaskEvent(newTask, 'rescheduled', {
        'scope': scopeName,
        'occurrenceKey': k,
        'fromStart': originalK.toIso(),
        'toStart': newTask.startLocal!.toIso(),
        'fromDuration': fromDuration,
        'toDuration': newTask.effectiveDurationMinutes,
        'zone': newTask.timeZone ?? _svc.currentZone,
        'source': source,
      });
    }
    final other = changedColumns(current, newTask).where((c) => c != 'start_local' && c != 'duration_minutes').toList();
    if (other.isNotEmpty) {
      await tx.logTaskEvent(newTask, 'updated', {
        'fields': other,
        'before': taskTimeFields(current),
        'after': taskTimeFields(newTask),
        'source': source,
      });
    }
    return newId;
  }

  /// Key of [key]'s occurrence in [target] (same key, or shifted by the start delta).
  String? _targetKey(Task target, String key, LocalDateTime? shiftFrom) {
    final rule = target.recurrence;
    final anchor = target.anchor;
    if (anchor == null) return null;
    if (rule == null) {
      final start = _parseKey(key);
      return start != null && shiftFrom != null && start == shiftFrom ? target.oneOffKey : null;
    }
    if (rule.type == RuleType.afterCompletion) return key;
    if (_occurs(rule, anchor, key)) return key;
    if (shiftFrom == null) return null;
    final start = _parseKey(key);
    if (start == null) return null;
    final delta = shiftFrom.minutesUntil(anchor.start);
    final shifted = start.plusMinutes(delta);
    final shiftedKey = target.isAllDay ? shifted.date.toIso() : shifted.toIso();
    return _occurs(rule, anchor, shiftedKey) ? shiftedKey : null;
  }

  bool _occurs(RecurrenceRule rule, RecurrenceAnchor anchor, String key) {
    try {
      return _svc.engine.occurs(rule, anchor, key);
    } on Object {
      return false;
    }
  }

  OrphanReport _orphansFor(Task current, Task target, Iterable<TaskOccurrenceRecord> records, {required LocalDateTime? shiftFrom}) =>
      findOrphans(records, (key) => _targetKey(target, key, shiftFrom) != null);

  /// Moves a record to `(taskId, key)`: copies its data, tombstones the old row and re-points
  /// its time entries.
  Future<void> _moveRecord(WriteTx tx, TaskOccurrenceRecord r, String taskId, String key, {bool clearOverrides = false}) async {
    if (r.taskId == taskId && r.occurrenceKey == key) return;
    final json = r.toJson();
    await tx.upsertRecord(taskId, key, {
      for (final c in recordDataColumns)
        if (!(clearOverrides && c.startsWith('override_'))) c: json[c],
    });
    await tx.softDelete('task_occurrences', r.id);
    await _repointEntries(tx, r.taskId, r.occurrenceKey, taskId, key);
  }

  Future<void> _repointEntries(WriteTx tx, String fromTask, String fromKey, String toTask, String toKey) async {
    final entries = await tx.rows(
      'SELECT id FROM time_entries WHERE task_id = ? AND occurrence_key = ? AND deleted_at IS NULL',
      [fromTask, fromKey],
    );
    for (final e in entries) {
      await tx.update('time_entries', e['id']! as String, {'task_id': toTask, 'occurrence_key': toKey});
    }
  }

  /// Orphan handling (T3.2.09): records with an outcome always become one-off tasks; moved/edited
  /// ones follow [policy]; bare cancellations are dropped.
  Future<void> _handleOrphans(WriteTx tx, Task template, List<TaskOccurrenceRecord> orphans, OrphanPolicy policy) async {
    for (final r in orphans) {
      final keep = r.hasOutcome || (r.hasOverride && policy == OrphanPolicy.keepAsOneOff);
      if (!keep || r.isCancelled && !r.hasOutcome) {
        await tx.softDelete('task_occurrences', r.id);
        continue;
      }
      var start = r.overrideStartLocal ?? _parseKey(r.occurrenceKey);
      var allDay = template.isAllDay && r.overrideStartLocal == null;
      if (start == null) {
        final hash = r.occurrenceKey.lastIndexOf('#');
        final period = hash < 0 ? null : QuotaPeriodKey.parse(r.occurrenceKey.substring(0, hash));
        if (period == null) {
          await tx.softDelete('task_occurrences', r.id);
          continue;
        }
        start = period.startDate.atStartOfDay;
        allDay = true;
      }
      final duration = allDay ? 1440 : (r.overrideDurationMinutes ?? template.effectiveDurationMinutes);
      final id = Ids.v7();
      final oneOff = template.copyWith(
        id: id,
        recurrence: null,
        recurrenceUntilLocal: null,
        startLocal: allDay ? start.date.atStartOfDay : start,
        durationMinutes: duration,
        isAllDay: allDay,
        title: r.overrideTitle ?? template.title,
        notes: r.overrideNotes ?? template.notes,
        manualSortKey: null,
        status: TaskStatus.active,
      );
      await tx.insert('tasks', id, oneOff.toColumns());
      final json = r.toJson();
      await tx.upsertRecord(id, oneOff.oneOffKey!, {for (final c in recordOutcomeColumns) c: json[c]});
      await tx.softDelete('task_occurrences', r.id);
      await _repointEntries(tx, r.taskId, r.occurrenceKey, id, oneOff.oneOffKey!);
      await tx.logTaskEvent(oneOff, 'created', {
        'source': 'orphan',
        'fromTaskId': template.id,
        'fromKey': r.occurrenceKey,
        ...taskTimeFields(oneOff),
      });
    }
  }

  /// First occurrence starting at or after now (null when the series is over).
  String? _firstNonPastKey(Task task) {
    try {
      return _svc.engine
          .nextAfter(task.recurrence!, task.anchor!, _svc.nowUtc, evalZone: _svc.currentZone, inclusive: true)
          ?.key;
    } on Object {
      return null;
    }
  }

  SeriesSplit? _safeSplit(Task task, String key) {
    try {
      return _svc.split(task.recurrence!, task.anchor!, key);
    } on Object {
      return null;
    }
  }

  /// Generated start of [key] in the task's wall clock (null for quota slots).
  LocalDateTime? _originalStart(Task task, String key) => _parseKey(key);

  static LocalDateTime? _parseKey(String key) =>
      LocalDateTime.tryParse(key) ?? LocalDate.tryParse(key)?.atStartOfDay;

  // ---------------------------------------------------------------------------
  // "This occurrence" overrides (T3.2.06) and one-off reschedules (T3.2.10)

  /// Override start/duration/title/notes of one occurrence ([start] in the task's wall clock).
  /// Values equal to the series' clear the override (*Restore to series*).
  Future<OpRecord> editOccurrence(
    String taskId,
    String key, {
    LocalDateTime? start,
    int? duration,
    String? title,
    String? notes,
    String source = 'menu',
  }) => _writer.run((tx) async {
    final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    await _editOccurrenceTx(tx, task, key, start: start, duration: duration, title: title, notes: notes, source: source);
  });

  Future<void> _editOccurrenceTx(
    WriteTx tx,
    Task task,
    String key, {
    LocalDateTime? start,
    int? duration,
    String? title,
    String? notes,
    required String source,
  }) async {
    final rec = await tx.readRecord(task.id, key);
    final original = _originalStart(task, key);
    final before = rec?.overrideStartLocal ?? original;
    final durationBefore = rec?.overrideDurationMinutes ?? task.effectiveDurationMinutes;
    final values = <String, Object?>{
      if (start != null) 'override_start_local': start == original ? null : start.toIso(),
      if (duration != null) 'override_duration_minutes': duration == task.effectiveDurationMinutes ? null : duration,
      if (title != null) 'override_title': title.trim() == task.title || title.trim().isEmpty ? null : title.trim(),
      if (notes != null) 'override_notes': notes == (task.notes ?? '') ? null : notes,
    };
    if (values.isEmpty) return;
    if (rec == null && values.values.every((v) => v == null)) return;
    await tx.upsertRecord(task.id, key, values);
    final newStart = start ?? before;
    final newDuration = duration ?? durationBefore;
    if (newStart != before || newDuration != durationBefore) {
      await tx.logTaskEvent(task, 'rescheduled', {
        'occurrenceKey': key,
        'scope': 'this',
        'fromStart': before?.toIso(),
        'toStart': newStart?.toIso(),
        'fromDuration': durationBefore,
        'toDuration': newDuration,
        'zone': task.timeZone ?? _svc.currentZone,
        'source': source,
      });
    }
    final fields = [
      if (title != null && title.trim() != (rec?.overrideTitle ?? task.title)) 'title',
      if (notes != null && notes != (rec?.overrideNotes ?? task.notes ?? '')) 'notes',
    ];
    if (fields.isNotEmpty) await tx.logOccurrenceEvent(task, key, 'updated', {'fields': fields, 'source': source});
  }

  /// Moves a one-off task (master start; its record follows) — [start] in the task's wall clock.
  Future<OpRecord> rescheduleTask(
    String taskId, {
    required LocalDateTime start,
    int? durationMinutes,
    bool? allDay,
    String source = 'drag',
  }) => _writer.run((tx) async {
    final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    final isAllDay = allDay ?? task.isAllDay;
    var duration = durationMinutes ?? task.durationMinutes;
    if (isAllDay && !task.isAllDay) duration = 1440;
    if (!isAllDay && task.isAllDay && durationMinutes == null) duration = 60;
    final edited = task.copyWith(
      startLocal: isAllDay ? start.date.atStartOfDay : start,
      durationMinutes: duration,
      isAllDay: isAllDay,
    );
    _validateOrThrow(edited);
    await _directEdit(tx, task, edited, source: source);
  });

  void _validateOrThrow(Task task) {
    final errors = validateTask(task, isValidZone: isValidZone);
    if (errors.isNotEmpty) throw TaskValidationException(errors);
  }

  /// Series-level move (all occurrences, implicit split) from a gesture or menu.
  Future<TaskWriteResult> rescheduleSeries(
    String taskId, {
    required LocalDateTime anchorStart,
    int? durationMinutes,
    bool rewritePast = false,
    String source = 'drag',
  }) async {
    final task = await _queries.task(taskId) ?? (throw NotFoundException('task $taskId'));
    return update(
      task.copyWith(startLocal: anchorStart, durationMinutes: durationMinutes ?? task.durationMinutes),
      rewritePast: rewritePast,
      source: source,
    );
  }

  // ---------------------------------------------------------------------------
  // Delete / restore (T3.1.05, T3.1.10, T3.2.11)

  /// Deletes with a scope: *this* cancels one occurrence, *this & following* truncates the rule
  /// and tombstones later records, *all* soft-deletes the task with its cascade.
  Future<OpRecord> delete(String taskId, {EditScope scope = EditScope.allOccurrences, String? occurrenceKey}) =>
      _writer.run((tx) async {
        final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
        await _deleteTx(tx, task, scope: scope, key: occurrenceKey);
      });

  Future<void> _deleteTx(WriteTx tx, Task task, {required EditScope scope, String? key}) async {
    if (!task.isRecurring || scope == EditScope.allOccurrences || key == null) {
      await _cascadeDelete(tx, task);
      return;
    }
    switch (scope) {
      case EditScope.thisOccurrence:
        await tx.upsertRecord(task.id, key, {'is_cancelled': true, 'status': 'cancelled', 'status_changed_at': tx.now});
        await tx.logOccurrenceEvent(task, key, 'deleted', {'scope': 'this'});
      case EditScope.thisAndFollowing:
        final split = task.recurrence!.type == RuleType.fixed ? _safeSplit(task, key) : null;
        if (split == null || split.truncatedRule == null) {
          await _cascadeDelete(tx, task);
          return;
        }
        final truncated = task.copyWith(recurrence: split.truncatedRule);
        await tx.update('tasks', task.id, {
          'recurrence': split.truncatedRule!.toJson(),
          'recurrence_until_local': TaskSchedule.of(truncated).recurrenceUntilLocal(_svc.engine)?.toIso(),
        });
        final removed = <String>[];
        final removedEntries = <String>[];
        for (final r in await tx.readRecords(task.id)) {
          if (r.occurrenceKey.compareTo(key) < 0 || r.occurrenceKey.contains('#')) continue;
          await tx.softDelete('task_occurrences', r.id);
          removed.add(r.id);
          for (final e in await tx.rows(
            'SELECT id FROM time_entries WHERE task_id = ? AND occurrence_key = ? AND deleted_at IS NULL',
            [task.id, r.occurrenceKey],
          )) {
            await tx.softDelete('time_entries', e['id']! as String);
            removedEntries.add(e['id']! as String);
          }
        }
        await tx.logTaskEvent(task, 'deleted', {
          'scope': 'following',
          'atKey': key,
          'cascade': {'task_occurrences': removed, 'time_entries': removedEntries},
        });
      case EditScope.allOccurrences:
        await _cascadeDelete(tx, task);
    }
  }

  /// Soft-deletes the task and everything it owns in the same transaction; the ids go into the
  /// `deleted` event so [restoreTask] brings back exactly these rows.
  Future<void> _cascadeDelete(WriteTx tx, Task task) async {
    Future<List<String>> ids(String sql, List<Object?> args) async =>
        [for (final r in await tx.rows(sql, args)) r['id']! as String];
    final records = await ids('SELECT id FROM task_occurrences WHERE task_id = ? AND deleted_at IS NULL', [task.id]);
    final entries = await ids('SELECT id FROM time_entries WHERE task_id = ? AND deleted_at IS NULL', [task.id]);
    final owners = [task.id, ...records];
    final attachments = await ids(
      'SELECT id FROM attachments WHERE deleted_at IS NULL AND owner_type IN (\'task\', \'task_occurrence\') '
      'AND owner_id IN (${List.filled(owners.length, '?').join(', ')})',
      owners,
    );
    final rules = await ids(
      "SELECT id FROM notification_rules WHERE deleted_at IS NULL AND target_type = 'task' AND target_id = ?",
      [task.id],
    );
    final mutes = await ids(
      "SELECT id FROM notification_mutes WHERE deleted_at IS NULL AND target_type = 'task' AND target_id = ?",
      [task.id],
    );
    final tags = await ids(
      "SELECT id FROM entity_tags WHERE deleted_at IS NULL AND entity_type = 'task' AND entity_id = ?",
      [task.id],
    );
    final cascade = {
      'task_occurrences': records,
      'time_entries': entries,
      'attachments': attachments,
      'notification_rules': rules,
      'notification_mutes': mutes,
      'entity_tags': tags,
    };
    for (final e in cascade.entries) {
      for (final id in e.value) {
        await tx.softDelete(e.key, id);
      }
    }
    await tx.softDelete('tasks', task.id);
    await tx.logTaskEvent(task, 'deleted', {'scope': 'all', 'cascade': cascade});
  }

  /// Restores a deleted task and exactly the rows its latest cascade tombstoned (Trash, T3.1.10).
  Future<OpRecord> restoreTask(String taskId) => _writer.run((tx) async {
    final raw = await tx.readRaw('tasks', taskId);
    if (raw == null || raw['deleted_at'] == null) return;
    final events = await tx.rows(
      "SELECT payload FROM activity_events WHERE entity_type = 'task' AND entity_id = ? AND event_type = 'deleted' "
      'AND deleted_at IS NULL ORDER BY occurred_at DESC, id DESC',
      [taskId],
    );
    for (final e in events) {
      final payload = _decode(e['payload']);
      if (payload['scope'] != 'all') continue;
      await _restoreCascade(tx, payload);
      break;
    }
    await tx.restore('tasks', taskId);
    final task = await tx.readTask(taskId);
    if (task != null) await tx.logTaskEvent(task, 'restored');
  });

  /// Restores exactly the rows tombstoned by operation [opId] (T3.1.05).
  Future<OpRecord> restoreOperation(String opId) => _writer.run((tx) async {
    final events = await tx.rows(
      "SELECT entity_id, payload FROM activity_events WHERE entity_type = 'task' AND event_type = 'deleted' "
      "AND deleted_at IS NULL AND json_extract(payload, '\$.opId') = ?",
      [opId],
    );
    for (final e in events) {
      final payload = _decode(e['payload']);
      await _restoreCascade(tx, payload);
      if (payload['scope'] == 'all') await tx.restore('tasks', e['entity_id']! as String);
      final task = await tx.readTask(e['entity_id']! as String);
      if (task != null) await tx.logTaskEvent(task, 'restored', {'restoredOp': opId});
    }
  });

  Future<void> _restoreCascade(WriteTx tx, Map<String, Object?> payload) async {
    final cascade = payload['cascade'];
    if (cascade is! Map) return;
    for (final e in cascade.entries) {
      final list = e.value;
      if (list is! List) continue;
      for (final id in list) {
        if (id is String && await tx.exists('${e.key}', id)) await tx.restore('${e.key}', id);
      }
    }
  }

  static Map<String, Object?> _decode(Object? json) {
    if (json is! String) return const {};
    try {
      final d = jsonDecode(json);
      return d is Map ? Map<String, Object?>.from(d) : const {};
    } on FormatException {
      return const {};
    }
  }

  // ---------------------------------------------------------------------------
  // Duplicate & copy (T3.1.05, T3.1.19)

  /// Copies a task with new ids and a fresh `series_id`; attachment rows point at the same
  /// storage objects. [occurrenceKey] copies one occurrence (as a one-off at its effective time).
  Future<TaskWriteResult> duplicate(
    String taskId, {
    bool asOneOff = false,
    LocalDateTime? targetStartLocal,
    String? occurrenceKey,
  }) async {
    late String newId;
    final record = await _writer.run((tx) async {
      newId = await _duplicateTx(tx, taskId, asOneOff: asOneOff, targetStart: targetStartLocal, occurrenceKey: occurrenceKey);
    });
    return TaskWriteResult(taskId, record, newTaskId: newId);
  }

  /// *Duplicate to…* (T3.1.19): one-off copies on each date, at the same time.
  Future<OpRecord> duplicateToDates(String taskId, List<LocalDate> dates, {String? occurrenceKey}) =>
      _writer.run((tx) async {
        final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
        final source = await _effectiveStart(tx, task, occurrenceKey) ?? task.startLocal;
        for (final date in dates) {
          final start = source == null ? date.atTime(LocalTime(9, 0)) : date.atTime(source.time);
          await _duplicateTx(tx, taskId, asOneOff: true, targetStart: start, occurrenceKey: occurrenceKey);
        }
      });

  Future<LocalDateTime?> _effectiveStart(WriteTx tx, Task task, String? key) async {
    if (key == null) return null;
    final rec = await tx.readRecord(task.id, key);
    return rec?.overrideStartLocal ?? _parseKey(key);
  }

  Future<String> _duplicateTx(
    WriteTx tx,
    String taskId, {
    required bool asOneOff,
    LocalDateTime? targetStart,
    String? occurrenceKey,
  }) async {
    final src = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    final oneOff = asOneOff || occurrenceKey != null;
    final rec = occurrenceKey == null ? null : await tx.readRecord(src.id, occurrenceKey);
    final start = targetStart ?? await _effectiveStart(tx, src, occurrenceKey) ?? src.startLocal;
    final id = Ids.v7();
    var copy = src.copyWith(
      id: id,
      seriesId: id,
      startLocal: start == null ? null : (src.isAllDay ? start.date.atStartOfDay : start),
      recurrence: oneOff ? null : src.recurrence,
      durationMinutes: rec?.overrideDurationMinutes ?? src.durationMinutes,
      title: rec?.overrideTitle ?? src.title,
      notes: rec?.overrideNotes ?? src.notes,
      status: TaskStatus.active,
      manualSortKey: null,
    );
    copy = copy.copyWith(recurrenceUntilLocal: TaskSchedule.of(copy).recurrenceUntilLocal(_svc.engine));
    await _insertTask(tx, copy, source: 'duplicate', payload: {'duplicatedFrom': src.id, 'occurrenceKey': ?occurrenceKey});
    await tx.copyOwnedRows('attachments', 'owner_id', src.id, id, typeColumn: 'owner_type', typeValue: 'task');
    // The copy keeps its own reminders (T7.1.15 "duplicate item").
    await tx.copyOwnedRows('notification_rules', 'target_id', src.id, id, typeColumn: 'target_type', typeValue: 'task');
    return id;
  }

  // ---------------------------------------------------------------------------
  // Templates (T3.1.20)

  /// Saves [task] (without dates or recurrence) as a template.
  Future<TaskWriteResult> saveAsTemplate(Task task) => create(
    task.copyWith(
      id: '',
      seriesId: '',
      isTemplate: true,
      startLocal: null,
      recurrence: null,
      recurrenceUntilLocal: null,
      deadlineLocal: null,
      manualSortKey: null,
      status: TaskStatus.active,
      durationMinutes: task.isAllDay ? 1440 : task.durationMinutes,
    ),
    source: 'template',
  );

  Future<OpRecord> deleteTemplate(String id) => _writer.run((tx) async {
    final t = await tx.readTask(id);
    if (t != null) await _cascadeDelete(tx, t);
  });

  // ---------------------------------------------------------------------------
  // Backlog (T3.1.11)

  /// Schedules a backlog task at [start] for [durationMinutes] (default: estimate, then the
  /// task's duration, then [fallbackDuration]).
  Future<OpRecord> schedule(
    String taskId,
    LocalDateTime start, {
    int? durationMinutes,
    bool allDay = false,
    int fallbackDuration = 30,
    String source = 'backlog',
  }) => _writer.run((tx) async {
    final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    final duration = allDay ? 1440 : (durationMinutes ?? task.estimateMinutes ?? task.durationMinutes ?? fallbackDuration);
    final edited = task.copyWith(startLocal: allDay ? start.date.atStartOfDay : start, durationMinutes: duration, isAllDay: allDay);
    _validateOrThrow(edited);
    await _directEdit(tx, task, edited, source: source, logUpdated: false);
  });

  /// Moves a one-off task to the backlog (recurring tasks can't be unscheduled).
  Future<OpRecord> unschedule(String taskId) => _writer.run((tx) async {
    final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    if (task.isRecurring) throw const ValidationException('Recurring tasks cannot be unscheduled', field: 'recurrence');
    if (task.isUnscheduled) return;
    await _directEdit(tx, task, task.copyWith(startLocal: null, isAllDay: false), source: 'menu', logUpdated: false);
  });

  /// Manual order in the backlog / within a day (fractional index between neighbours).
  Future<OpRecord> moveInBacklog(String taskId, {String? afterKey, String? beforeKey}) => _writer.run(
    (tx) => tx.update('tasks', taskId, {'manual_sort_key': FractionalIndex.between(afterKey, beforeKey)}),
  );

  // ---------------------------------------------------------------------------
  // Pause / resume (T3.2.21)

  Future<OpRecord> pauseSeries(String taskId) => _writer.run((tx) async {
    final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    if (task.isPaused) return;
    await tx.update('tasks', taskId, {'status': TaskStatus.paused.json});
    await tx.logTaskEvent(task, 'paused', {'from': task.status.json});
  });

  Future<OpRecord> resumeSeries(String taskId) => _writer.run((tx) async {
    final task = await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));
    if (!task.isPaused) return;
    await tx.update('tasks', taskId, {'status': TaskStatus.active.json});
    await tx.logTaskEvent(task, 'resumed');
  });

  // ---------------------------------------------------------------------------
  // Bulk (T3.1.18)

  /// Applies [change] to every target in ONE transaction (one undo).
  Future<OpRecord> bulk(List<BulkTarget> targets, BulkChange change) => _writer.run((tx) async {
    final seen = <String>{};
    for (final target in targets) {
      final task = await tx.readTask(target.taskId);
      if (task == null) continue;
      final occurrenceLevel = task.isRecurring && !target.series && target.occurrenceKey != null;
      final dedupeKey = occurrenceLevel ? '${task.id}|${target.occurrenceKey}' : task.id;
      if (!seen.add(dedupeKey)) continue;
      switch (change) {
        case BulkMove(:final days, :final minutes):
          final delta = days * 1440 + minutes;
          if (delta == 0 || task.isUnscheduled) continue;
          if (occurrenceLevel) {
            final key = target.occurrenceKey!;
            final rec = await tx.readRecord(task.id, key);
            final start = rec?.overrideStartLocal ?? _parseKey(key);
            if (start == null) continue;
            await _editOccurrenceTx(tx, task, key, start: start.plusMinutes(delta), source: 'bulk');
          } else if (task.isRecurring) {
            await _applyEdit(
              tx,
              task,
              task.copyWith(startLocal: task.startLocal!.plusMinutes(delta)),
              scope: EditScope.allOccurrences,
              source: 'bulk',
            );
          } else {
            await _directEdit(tx, task, task.copyWith(startLocal: task.startLocal!.plusMinutes(delta)), source: 'bulk');
          }
        case BulkSetCategory(:final categoryId):
          await _directEdit(tx, task, task.copyWith(categoryId: categoryId), source: 'bulk');
        case BulkSetPriority(:final priority):
          await _directEdit(tx, task, task.copyWith(priority: priority.clamp(0, 4)), source: 'bulk');
        case BulkSetTrackingMode(:final mode):
          await _directEdit(tx, task, task.copyWith(trackingMode: mode), source: 'bulk');
        case BulkDuplicate():
          await _duplicateTx(tx, task.id, asOneOff: occurrenceLevel, occurrenceKey: occurrenceLevel ? target.occurrenceKey : null);
        case BulkDelete():
          await _deleteTx(
            tx,
            task,
            scope: occurrenceLevel ? EditScope.thisOccurrence : EditScope.allOccurrences,
            key: target.occurrenceKey,
          );
      }
    }
  }, cause: 'bulk');

  // ---------------------------------------------------------------------------
  // Roll-over (T3.2.12)

  /// Moves unresolved one-off tasks to [today]: same time if still ahead of [nowLocal],
  /// otherwise all-day. Deterministic event ids make two devices converge.
  Future<OpRecord> rollOver(List<Task> tasks, {required LocalDate today, required LocalDateTime nowLocal, DateTime? scheduledAt}) =>
      _writer.run((tx) async {
        for (final t in tasks) {
          final task = await tx.readTask(t.id);
          if (task == null || task.isRecurring || task.isUnscheduled) continue;
          if (!task.startLocal!.date.isBefore(today)) continue;
          final sameTime = sameTimeTodayIfAhead(task.startLocal!, nowLocal);
          final edited = sameTime != null && !task.isAllDay
              ? task.copyWith(startLocal: sameTime)
              : task.copyWith(startLocal: today.atStartOfDay, isAllDay: true, durationMinutes: 1440);
          await _directEdit(
            tx,
            task,
            edited,
            source: 'rollover',
            rescheduleEventId: Ids.rollover(task.id, today.toIso()),
            logUpdated: false,
          );
        }
      }, cause: 'auto', scheduledAt: scheduledAt);
}
