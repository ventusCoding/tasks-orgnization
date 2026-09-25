import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/data/planner_mappers.dart';
import 'package:everslot/features/planner/data/planner_writes.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';

/// Occurrence-level writes (T3.2.04, T3.2.11 *this*, T3.2.17–T3.2.18, T2.1.19): each action
/// upserts the record with the deterministic id `uuidv5(task_id|occurrence_key)`, stamps
/// `status_changed_at` / `completed_at`, logs an activity event and returns the undoable
/// operation. Actions are idempotent: repeating one writes nothing.
class OccurrencesRepository {
  OccurrencesRepository(this._writer);

  final SyncWriter _writer;

  Future<Task> _task(WriteTx tx, String taskId) async =>
      await tx.readTask(taskId) ?? (throw NotFoundException('task $taskId'));

  // ---------------------------------------------------------------------------
  // Status actions

  /// Marks the occurrence done. Timer tasks close their running session and take actual times
  /// from their time entries unless explicit [actualStart]/[actualEnd] are given.
  Future<OpRecord> markDone(
    String taskId,
    String key, {
    DateTime? actualStart,
    DateTime? actualEnd,
    String source = 'sheet',
  }) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    final rec = await tx.readRecord(taskId, key);
    if (rec != null && rec.status == OccurrenceStatus.done && !rec.isCancelled) return;
    var start = actualStart;
    var end = actualEnd;
    int? tracked;
    final entries = await _closeRunning(tx, taskId, key);
    if (entries.isNotEmpty) {
      tracked = trackedSecondsOf(entries, tx.now);
      start ??= entries.first.startedAt;
      end ??= entries.map((e) => e.endedAt ?? tx.now).reduce((a, b) => a.isAfter(b) ? a : b);
    }
    await tx.upsertRecord(taskId, key, {
      'status': OccurrenceStatus.done.json,
      'is_cancelled': false,
      'status_changed_at': tx.now,
      'completed_at': tx.now,
      'actual_start_at': ?start,
      'actual_end_at': ?end,
      'tracked_seconds': ?tracked,
      'skip_reason': null,
    });
    await tx.logOccurrenceEvent(task, key, 'completed', {
      'from': rec?.status.json ?? 'scheduled',
      'actualStart': start?.toIso8601String(),
      'actualEnd': end?.toIso8601String(),
      'source': source,
    });
  });

  /// Back to *scheduled* (undo done / reopen a skipped or cancelled occurrence).
  Future<OpRecord> reopen(String taskId, String key, {String source = 'sheet'}) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    final rec = await tx.readRecord(taskId, key);
    if (rec == null || (rec.status == OccurrenceStatus.scheduled && !rec.isCancelled)) return;
    await tx.upsertRecord(taskId, key, {
      'status': OccurrenceStatus.scheduled.json,
      'is_cancelled': false,
      'status_changed_at': tx.now,
      'completed_at': null,
      'skip_reason': null,
    });
    await tx.logOccurrenceEvent(task, key, 'reopened', {'from': rec.isCancelled ? 'cancelled' : rec.status.json, 'source': source});
  });

  /// Alias of [reopen] for a done occurrence.
  Future<OpRecord> undoDone(String taskId, String key) => reopen(taskId, key);

  /// Skips with a reason key (`too_busy`, `sick`, …) or free text (≤ 200 chars).
  Future<OpRecord> skip(String taskId, String key, {String? reason, String source = 'sheet'}) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    final rec = await tx.readRecord(taskId, key);
    final text = reason?.trim();
    final stored = text == null || text.isEmpty
        ? null
        : (text.length > SkipReasons.maxLength ? text.substring(0, SkipReasons.maxLength) : text);
    if (rec != null && rec.status == OccurrenceStatus.skipped && rec.skipReason == stored) return;
    await _closeRunning(tx, taskId, key);
    await tx.upsertRecord(taskId, key, {
      'status': OccurrenceStatus.skipped.json,
      'is_cancelled': false,
      'status_changed_at': tx.now,
      'completed_at': null,
      'skip_reason': stored,
    });
    await tx.logOccurrenceEvent(task, key, 'skipped', {'from': rec?.status.json ?? 'scheduled', 'reason': stored, 'source': source});
  });

  /// Explicit status write used by the planner contract (`missed`, `in_progress` without timer).
  Future<OpRecord> setStatus(String taskId, String key, OccurrenceStatus status, {String source = 'menu'}) =>
      _writer.run((tx) async {
        final task = await _task(tx, taskId);
        final rec = await tx.readRecord(taskId, key);
        if (rec != null && rec.status == status) return;
        await tx.upsertRecord(taskId, key, {
          'status': status.json,
          'is_cancelled': status == OccurrenceStatus.cancelled,
          'status_changed_at': tx.now,
        });
        await tx.logOccurrenceEvent(task, key, 'status_changed', {
          'from': rec?.status.json ?? 'scheduled',
          'to': status.json,
          'source': source,
        });
      });

  /// Cancels one occurrence (delete scope *this*, T3.2.11).
  Future<OpRecord> cancel(String taskId, String key) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    final rec = await tx.readRecord(taskId, key);
    if (rec != null && rec.isCancelled) return;
    await tx.upsertRecord(taskId, key, {'is_cancelled': true, 'status': 'cancelled', 'status_changed_at': tx.now});
    await tx.logOccurrenceEvent(task, key, 'deleted', {'scope': 'this'});
  });

  // ---------------------------------------------------------------------------
  // Timer (T3.2.17, T3.2.19)

  /// Starts the occurrence (→ in progress). Timer tasks open a time entry; with the `single`
  /// [policy] every other running timer is paused first.
  Future<OpRecord> start(String taskId, String key, {TimerPolicy policy = TimerPolicy.single, String source = 'sheet'}) =>
      _writer.run((tx) async {
        final task = await _task(tx, taskId);
        final rec = await tx.readRecord(taskId, key);
        final running = await _running(tx);
        final alreadyRunning = running.any((e) => e.taskId == taskId && e.occurrenceKey == key);
        if (rec?.status == OccurrenceStatus.inProgress && (alreadyRunning || task.trackingMode != TrackingMode.timer)) return;
        if (task.trackingMode == TrackingMode.timer && !alreadyRunning) {
          if (policy == TimerPolicy.single) {
            for (final other in running) {
              await _closeEntry(tx, other);
              final otherTask = await tx.readTask(other.taskId);
              if (otherTask != null && other.occurrenceKey != null) {
                await _updateTracked(tx, other.taskId, other.occurrenceKey!);
                await tx.logOccurrenceEvent(otherTask, other.occurrenceKey!, 'stopped', {'pause': true, 'reason': 'timer_policy'});
              }
            }
          }
          await tx.insert('time_entries', Ids.v7(), {'task_id': taskId, 'occurrence_key': key, 'started_at': tx.now});
        }
        await tx.upsertRecord(taskId, key, {
          'status': OccurrenceStatus.inProgress.json,
          'is_cancelled': false,
          'status_changed_at': tx.now,
          'actual_start_at': rec?.actualStartAt ?? tx.now,
        });
        await tx.logOccurrenceEvent(task, key, 'started', {'from': rec?.status.json ?? 'scheduled', 'source': source});
      });

  /// Pauses the running timer (closes the entry; status stays in progress).
  Future<OpRecord> pause(String taskId, String key) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    final closed = await _closeRunning(tx, taskId, key, returnAll: false);
    if (closed.isEmpty) return;
    await _updateTracked(tx, taskId, key);
    await tx.logOccurrenceEvent(task, key, 'stopped', {'pause': true});
  });

  /// Resumes = starts a new session.
  Future<OpRecord> resume(String taskId, String key, {TimerPolicy policy = TimerPolicy.single}) =>
      start(taskId, key, policy: policy, source: 'resume');

  /// Stops the occurrence. With [complete] (default) it is marked done with actual times from
  /// its time entries; otherwise the session is just closed.
  Future<OpRecord> stop(String taskId, String key, {bool complete = true}) async {
    if (complete) return markDone(taskId, key, source: 'timer');
    return pause(taskId, key);
  }

  // ---------------------------------------------------------------------------
  // Outcome fields (T3.2.04, T3.2.14, T3.2.22)

  Future<OpRecord> setCompletionPercent(String taskId, String key, int? percent) => _setField(
    taskId,
    key,
    'completion_percent',
    percent?.clamp(0, 100),
  );

  Future<OpRecord> rate(String taskId, String key, int? rating) =>
      _setField(taskId, key, 'rating', rating?.clamp(1, 5));

  Future<OpRecord> setOutcomeNote(String taskId, String key, String? note) =>
      _setField(taskId, key, 'outcome_note', (note == null || note.trim().isEmpty) ? null : note.trim());

  Future<OpRecord> _setField(String taskId, String key, String column, Object? value) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    final rec = await tx.readRecord(taskId, key);
    final before = rec?.toJson()[column];
    if (before == value) return;
    await tx.upsertRecord(taskId, key, {column: value});
    await tx.logOccurrenceEvent(task, key, 'updated', {'fields': [column], 'from': before, 'to': value});
  });

  /// Edits actual start/end (validated end ≥ start).
  Future<OpRecord> setActualTimes(String taskId, String key, {required DateTime start, required DateTime end}) {
    if (end.isBefore(start)) throw const ActualTimeException();
    return _writer.run((tx) async {
      final task = await _task(tx, taskId);
      final rec = await tx.readRecord(taskId, key);
      if (rec?.actualStartAt == start.toUtc() && rec?.actualEndAt == end.toUtc()) return;
      await tx.upsertRecord(taskId, key, {'actual_start_at': start.toUtc(), 'actual_end_at': end.toUtc()});
      await tx.logOccurrenceEvent(task, key, 'updated', {
        'fields': ['actual_start_at', 'actual_end_at'],
        'actualStart': start.toUtc().toIso8601String(),
        'actualEnd': end.toUtc().toIso8601String(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Exceptions manager (T2.1.19)

  /// *Restore to series*: clears overrides and the cancellation. A record left without any
  /// outcome is removed.
  Future<OpRecord> restoreToSeries(String taskId, String key) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    await _restoreTx(tx, task, key);
  });

  /// Restores every cancelled/moved occurrence of the task in one operation.
  Future<OpRecord> restoreAllExceptions(String taskId) => _writer.run((tx) async {
    final task = await _task(tx, taskId);
    for (final r in await tx.readRecords(taskId)) {
      if (r.isCancelled || r.hasOverride) await _restoreTx(tx, task, r.occurrenceKey);
    }
  });

  Future<void> _restoreTx(WriteTx tx, Task task, String key) async {
    final rec = await tx.readRecord(task.id, key);
    if (rec == null || !(rec.isCancelled || rec.hasOverride)) return;
    final cleared = rec.copyWith(
      overrideStartLocal: null,
      overrideDurationMinutes: null,
      overrideTitle: null,
      overrideNotes: null,
      isCancelled: false,
      status: rec.status == OccurrenceStatus.cancelled ? OccurrenceStatus.scheduled : rec.status,
    );
    if (!cleared.hasOutcome) {
      await tx.softDelete('task_occurrences', rec.id);
    } else {
      await tx.upsertRecord(task.id, key, {
        'override_start_local': null,
        'override_duration_minutes': null,
        'override_title': null,
        'override_notes': null,
        'is_cancelled': false,
        'status': cleared.status.json,
      });
    }
    await tx.logOccurrenceEvent(task, key, 'restored', {
      'wasCancelled': rec.isCancelled,
      'wasMoved': rec.isMoved,
      'fromStart': rec.overrideStartLocal?.toIso(),
    });
  }

  // ---------------------------------------------------------------------------
  // Time entries (T3.2.18)

  /// Adds a manual entry (negative durations rejected; overlaps are the caller's warning).
  Future<OpRecord> addTimeEntry(String taskId, String key, {required DateTime start, DateTime? end, String? note}) {
    return _writer.run((tx) async {
      final error = validateTimeEntry(start, end, now: tx.now);
      if (error != null) throw ValidationException(error.name, field: 'time_entry');
      final task = await _task(tx, taskId);
      final id = Ids.v7();
      await tx.insert('time_entries', id, {
        'task_id': taskId,
        'occurrence_key': key,
        'started_at': start.toUtc(),
        'ended_at': end?.toUtc(),
        'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      });
      await _updateTracked(tx, taskId, key, touchActual: true);
      await tx.logOccurrenceEvent(task, key, 'time_entry_added', {'entryId': id});
    });
  }

  Future<OpRecord> updateTimeEntry(String entryId, {required DateTime start, DateTime? end, String? note}) =>
      _writer.run((tx) async {
        final error = validateTimeEntry(start, end, now: tx.now);
        if (error != null) throw ValidationException(error.name, field: 'time_entry');
        final raw = await tx.readRaw('time_entries', entryId) ?? (throw NotFoundException('time entry $entryId'));
        await tx.update('time_entries', entryId, {
          'started_at': start.toUtc(),
          'ended_at': end?.toUtc(),
          'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        });
        final taskId = raw['task_id']! as String;
        final key = raw['occurrence_key'] as String?;
        if (key != null) await _updateTracked(tx, taskId, key, touchActual: true);
      });

  Future<OpRecord> deleteTimeEntry(String entryId) => _writer.run((tx) async {
    final raw = await tx.readRaw('time_entries', entryId);
    if (raw == null || raw['deleted_at'] != null) return;
    await tx.softDelete('time_entries', entryId);
    final key = raw['occurrence_key'] as String?;
    if (key != null) await _updateTracked(tx, raw['task_id']! as String, key);
  });

  // ---------------------------------------------------------------------------

  Future<List<TimeEntry>> _entries(WriteTx tx, String taskId, String key) async => [
    for (final r in await tx.rows(
      'SELECT * FROM time_entries WHERE task_id = ? AND occurrence_key = ? AND deleted_at IS NULL ORDER BY started_at',
      [taskId, key],
    ))
      TimeEntry.fromJson(r),
  ];

  Future<List<TimeEntry>> _running(WriteTx tx) async => [
    for (final r in await tx.rows(
      'SELECT * FROM time_entries WHERE user_id = ? AND ended_at IS NULL AND deleted_at IS NULL ORDER BY started_at',
      [tx.userId],
    ))
      TimeEntry.fromJson(r),
  ];

  Future<void> _closeEntry(WriteTx tx, TimeEntry e) => tx.update('time_entries', e.id, {'ended_at': tx.now});

  /// Closes the running entries of the occurrence; returns all its entries (closed state) or
  /// only the closed ones when [returnAll] is false.
  Future<List<TimeEntry>> _closeRunning(WriteTx tx, String taskId, String key, {bool returnAll = true}) async {
    final entries = await _entries(tx, taskId, key);
    final closed = <TimeEntry>[];
    for (final e in entries.where((e) => e.isRunning)) {
      await _closeEntry(tx, e);
      closed.add(TimeEntry(id: e.id, taskId: e.taskId, occurrenceKey: e.occurrenceKey, startedAt: e.startedAt, endedAt: tx.now));
    }
    if (!returnAll) return closed;
    return [for (final e in entries) e.isRunning ? closed.firstWhere((c) => c.id == e.id) : e];
  }

  /// Denormalizes `tracked_seconds` (closed sessions) on the record.
  Future<void> _updateTracked(WriteTx tx, String taskId, String key, {bool touchActual = false}) async {
    final entries = await _entries(tx, taskId, key);
    final closed = entries.where((e) => !e.isRunning).toList();
    final total = trackedSecondsOf(closed, tx.now);
    final rec = await tx.readRecord(taskId, key);
    if (rec == null && total == 0) return;
    await tx.upsertRecord(taskId, key, {
      'tracked_seconds': total,
      if (touchActual && closed.isNotEmpty) ...{
        'actual_start_at': closed.first.startedAt,
        if (rec?.status == OccurrenceStatus.done) 'actual_end_at': closed.map((e) => e.endedAt!).reduce((a, b) => a.isAfter(b) ? a : b),
      },
    });
  }

  /// Raw record for tests/diagnostics.
  static TaskOccurrenceRecord recordOf(Map<String, Object?> raw) => PlannerMappers.recordFromRaw(raw);
}
