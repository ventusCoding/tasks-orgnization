/// Planner stats adapter (T6.3.01): resolves task rows, occurrence records, time entries and
/// reschedule events into one canonical [PlannerOccurrenceFact] per occurrence. Pure Dart — runs in
/// the stats isolate with the recurrence engine and a zone snapshot.
///
/// - Recurring series expand with the recurrence engine and the stored overrides (moved/edited
///   occurrences keep their original key); cancelled occurrences stay as `cancelled` facts.
/// - One-off tasks have a single occurrence keyed by their start (the key follows the task when it
///   moves, so every `rescheduled` event of a one-off task belongs to that occurrence).
/// - Series-scope moves (`scope: series`) are expanded per affected occurrence (those planned after
///   the move), as required by PL-T-08.
/// - Sessions come from `time_entries` (open entries are clipped at now); the fallback
///   `actual_start_at`…`actual_end_at` is handled by the fact itself.
library;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show PlannerOccurrenceFact, PlannerOccurrenceStatus, RescheduleFact, TimeSessionFact;
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Result of a resolution: the facts plus backlog information.
final class PlannerFacts {
  const PlannerFacts(this.facts, {required this.unscheduledOpen, required this.taskCreatedAt});

  final List<PlannerOccurrenceFact> facts;

  /// Unscheduled (backlog) active tasks.
  final int unscheduledOpen;

  /// Creation instants of every task (backlog flow, PL-X-04).
  final List<DateTime> taskCreatedAt;
}

final class PlannerResolver {
  PlannerResolver(
    this.input, {
    required this.resolver,
    required this.viewerZone,
    required this.now,
    this.maxPerTask = 4000,
  }) : engine = RecurrenceEngine(resolver) {
    for (final r in input.occurrences) {
      _records.putIfAbsent(r.taskId, () => {})[r.key] = r;
    }
    for (final e in input.timeEntries) {
      _entries.putIfAbsent(e.taskId, () => []).add(e);
    }
    for (final e in input.events) {
      if (e.entityType == 'task' && e.eventType == 'rescheduled') {
        _moves.putIfAbsent(e.entityId, () => []).add(e);
      }
    }
    for (final l in input.tagLinks) {
      if (l.entityType == 'task') _tags.putIfAbsent(l.entityId, () => []).add(l.tagId);
    }
  }

  final PlannerInput input;
  final ZoneResolver resolver;

  /// Zone of the viewer (floating tasks resolve here).
  final String viewerZone;
  final DateTime now;

  /// Safety cap of occurrences per task per resolution.
  final int maxPerTask;
  final RecurrenceEngine engine;

  final Map<String, Map<String, OccurrenceRecord>> _records = {};
  final Map<String, List<TimeEntryRecord>> _entries = {};
  final Map<String, List<ActivityRecord>> _moves = {};
  final Map<String, List<String>> _tags = {};

  /// Facts whose planned (or originally planned) local date falls in `[from, to]`, optionally
  /// limited to some series or tasks.
  PlannerFacts resolve({required LocalDate from, required LocalDate to, Set<String>? seriesIds, Set<String>? taskIds}) {
    final facts = <PlannerOccurrenceFact>[];
    var unscheduled = 0;
    final created = <DateTime>[];
    for (final task in input.tasks) {
      if (seriesIds != null && !seriesIds.contains(task.seriesId)) continue;
      if (taskIds != null && !taskIds.contains(task.id)) continue;
      created.add(task.createdAt);
      if (task.isUnscheduled) {
        if (task.status == 'active') unscheduled++;
        continue;
      }
      try {
        if (task.isRecurring) {
          facts.addAll(_resolveSeries(task, from, to));
        } else {
          final f = _resolveOneOff(task, from, to);
          if (f != null) facts.add(f);
        }
      } on Object {
        // A broken rule must never break a whole batch: the task is skipped.
        continue;
      }
    }
    facts.sort((a, b) {
      final sa = a.plannedStart ?? now;
      final sb = b.plannedStart ?? now;
      final c = sa.compareTo(sb);
      return c != 0 ? c : a.occurrenceKey.compareTo(b.occurrenceKey);
    });
    return PlannerFacts(facts, unscheduledOpen: unscheduled, taskCreatedAt: created);
  }

  /// The single fact of occurrence [key] of task [taskId] (task stats sheet).
  PlannerOccurrenceFact? occurrence(String taskId, String? key) {
    final task = input.tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task == null || task.isUnscheduled) return null;
    if (!task.isRecurring || key == null) {
      return _resolveOneOff(task, null, null, requestedKey: key);
    }
    final start = _keyStart(key);
    if (start == null) return null;
    final day = start.date;
    return _resolveSeries(task, day.minusDays(1), day.plusDays(1)).firstWhereOrNull((f) => f.occurrenceKey == key) ??
        // Moved far away: widen the search around the override start.
        () {
          final rec = _records[task.id]?[key];
          final o = rec?.overrideStartLocal?.date;
          if (o == null) return null;
          return _resolveSeries(task, o.minusDays(1), o.plusDays(1)).firstWhereOrNull((f) => f.occurrenceKey == key);
        }();
  }

  // ------------------------------------------------------------------------------------------

  String _zoneOf(TaskRecord t) => t.timeZone ?? viewerZone;

  int _durationOf(TaskRecord t) => t.durationMinutes ?? (t.isAllDay ? 1440 : 0);

  static LocalDateTime? _keyStart(String key) => LocalDateTime.tryParse(key) ?? LocalDate.tryParse(key)?.atStartOfDay;

  PlannerOccurrenceFact? _resolveOneOff(TaskRecord task, LocalDate? from, LocalDate? to, {String? requestedKey}) {
    final key = task.oneOffKey!;
    final records = _records[task.id];
    final rec = records?[key] ?? (requestedKey == null ? null : records?[requestedKey]) ?? _latest(records);
    final start = rec?.overrideStartLocal ?? task.startLocal!;
    final duration = rec?.overrideDurationMinutes ?? _durationOf(task);
    final moves = [
      for (final e in _moves[task.id] ?? const <ActivityRecord>[])
        if (_move(e) case final m?) m,
    ];
    if (from != null && to != null) {
      bool inRange(LocalDate d) => !d.isBefore(from) && !d.isAfter(to);
      final touches = inRange(start.date) || moves.any((m) => inRange(m.fromStart.date) || inRange(m.toStart.date));
      if (!touches) return null;
    }
    return _fact(task, key, start: start, duration: duration, record: rec, moves: moves, anyKeySessions: true);
  }

  OccurrenceRecord? _latest(Map<String, OccurrenceRecord>? records) {
    if (records == null || records.isEmpty) return null;
    return records.values.reduce(
      (a, b) =>
          (a.statusChangedAt ?? a.completedAt ?? DateTime(0)).isAfter(b.statusChangedAt ?? b.completedAt ?? DateTime(0))
          ? a
          : b,
    );
  }

  List<PlannerOccurrenceFact> _resolveSeries(TaskRecord task, LocalDate from, LocalDate to) {
    final rule = RecurrenceRule.decode(task.recurrence!);
    final duration = _durationOf(task);
    final anchor = RecurrenceAnchor(task.startLocal!, task.timeZone, durationMinutes: duration, allDay: task.isAllDay);
    final records = _records[task.id] ?? const <String, OccurrenceRecord>{};
    final events = _moves[task.id] ?? const <ActivityRecord>[];
    final seriesMoves = [
      for (final e in events)
        if (e.payloadString('scope') == 'series') e,
    ];
    final result = <PlannerOccurrenceFact>[];

    List<RescheduleFact> movesFor(String key, LocalDateTime plannedStart) => [
      for (final e in events)
        if (e.payloadString('scope') != 'series' && e.payloadString('occurrenceKey') == key)
          if (_move(e) case final m?) m,
      for (final e in seriesMoves)
        if (_seriesMove(e, plannedStart) case final m?) m,
    ];

    if (rule.type == RuleType.afterCompletion) {
      // Completed/touched occurrences are the records; the next due follows the last completion.
      DateTime? last;
      for (final rec in records.values) {
        final start = rec.overrideStartLocal ?? _keyStart(rec.key);
        if (start == null) continue;
        final d = start.date;
        if (!d.isBefore(from) && !d.isAfter(to)) {
          result.add(
            _fact(
              task,
              rec.key,
              start: start,
              duration: rec.overrideDurationMinutes ?? duration,
              record: rec,
              moves: movesFor(rec.key, start),
            ),
          );
        }
        final done = rec.completedAt;
        if (done != null && (last == null || done.isAfter(last))) last = done;
      }
      final next = engine.nextDue(rule, anchor, last, evalZone: viewerZone, durationMinutes: duration);
      if (next != null && !records.containsKey(next.key)) {
        final d = next.startLocal.date;
        if (!d.isBefore(from) && !d.isAfter(to)) {
          result.add(_fact(task, next.key, start: next.startLocal, duration: duration, record: null, moves: const []));
        }
      }
      return result;
    }

    final overrides = [
      for (final r in records.values)
        if (r.overrideStartLocal != null || r.overrideDurationMinutes != null)
          OccurrenceOverride<OccurrenceRecord>(
            r.key,
            newStartLocal: r.overrideStartLocal,
            newDurationMinutes: r.overrideDurationMinutes,
            payload: r,
          ),
    ];
    final fromLocal = from.atStartOfDay;
    final toLocal = to.plusDays(1).atStartOfDay;
    List<({String key, LocalDateTime start, int minutes})> occurrences;
    try {
      occurrences = [
        for (final m
            in OverrideMerger(engine)
                .merge<OccurrenceRecord>(
                  rule,
                  anchor,
                  fromLocal,
                  toLocal,
                  overrides,
                  evalZone: viewerZone,
                  durationMinutes: duration,
                )
                .take(maxPerTask))
          (key: m.key, start: m.startLocal, minutes: m.durationMinutes),
      ];
    } on RecurrenceLimitExceeded {
      occurrences = [
        for (final o in engine.between(
          rule,
          anchor,
          fromLocal,
          toLocal,
          evalZone: viewerZone,
          limit: maxPerTask,
          durationMinutes: duration,
        ))
          (key: o.key, start: o.startLocal, minutes: duration),
      ];
    }
    for (final o in occurrences) {
      // Occurrences that started before the window only overlap it: keep them when they start in it.
      if (o.start.date.isBefore(from) && _keyStart(o.key)?.date.isBefore(from) != false) continue;
      result.add(
        _fact(
          task,
          o.key,
          start: o.start,
          duration: o.minutes,
          record: records[o.key],
          moves: movesFor(o.key, o.start),
        ),
      );
    }
    return result;
  }

  RescheduleFact? _move(ActivityRecord e) {
    final from = _ldt(e.payload['fromStart'] ?? e.payload['fromStartLocal'] ?? e.payload['from']);
    final to = _ldt(e.payload['toStart'] ?? e.payload['toStartLocal'] ?? e.payload['to']);
    if (from == null || to == null) return null;
    return RescheduleFact(
      e.occurredAt,
      fromStart: from,
      toStart: to,
      fromDurationMinutes: e.payloadInt('fromDuration') ?? e.payloadInt('fromDurationMinutes'),
      toDurationMinutes: e.payloadInt('toDuration') ?? e.payloadInt('toDurationMinutes'),
      source: e.payloadString('source'),
    );
  }

  /// A series-scope move applied to one occurrence planned after the move.
  RescheduleFact? _seriesMove(ActivityRecord e, LocalDateTime plannedStart) {
    final base = _move(e);
    if (base == null) return null;
    final delta = base.deltaMinutes;
    if (delta == 0) return null;
    final plannedInstant = resolver.resolve(plannedStart, viewerZone).utc;
    if (plannedInstant.isBefore(e.occurredAt)) return null;
    return RescheduleFact(
      e.occurredAt,
      fromStart: plannedStart.plusMinutes(-delta),
      toStart: plannedStart,
      fromDurationMinutes: base.fromDurationMinutes,
      toDurationMinutes: base.toDurationMinutes,
      seriesScope: true,
      source: base.source,
    );
  }

  static LocalDateTime? _ldt(Object? v) {
    if (v is! String) return null;
    return LocalDateTime.tryParse(v) ?? LocalDate.tryParse(v)?.atStartOfDay;
  }

  PlannerOccurrenceFact _fact(
    TaskRecord task,
    String key, {
    required LocalDateTime start,
    required int duration,
    required OccurrenceRecord? record,
    required List<RescheduleFact> moves,
    bool anyKeySessions = false,
  }) {
    final zone = _zoneOf(task);
    final DateTime ps;
    final DateTime pe;
    if (task.isAllDay) {
      final days = duration <= 0 ? 1 : (duration + 1439) ~/ 1440;
      ps = resolver.resolve(start.date.atStartOfDay, zone).utc;
      pe = resolver.resolve(start.date.plusDays(days).atStartOfDay, zone).utc;
    } else {
      ps = resolver.resolve(start, zone).utc;
      pe = ps.add(Duration(minutes: duration));
    }
    final entries = [
      for (final e in _entries[task.id] ?? const <TimeEntryRecord>[])
        if (anyKeySessions || e.occurrenceKey == key)
          if (!(e.endedAt ?? now).isBefore(e.startedAt))
            TimeSessionFact(
              e.startedAt,
              e.endedAt ?? now,
              startLocal: resolver.toLocal(e.startedAt, zone),
              endLocal: resolver.toLocal(e.endedAt ?? now, zone),
              taskId: task.id,
              occurrenceKey: key,
              categoryId: task.categoryId,
            ),
    ];
    final cancelled = record?.cancelled ?? false;
    return PlannerOccurrenceFact(
      task.id,
      key,
      seriesId: task.seriesId,
      taskCreatedAt: task.createdAt,
      isRecurring: task.isRecurring,
      plannedStartLocal: start,
      plannedDurationMinutes: duration,
      plannedStart: ps,
      plannedEnd: pe,
      isAllDay: task.isAllDay,
      status: cancelled ? PlannerOccurrenceStatus.cancelled : (record?.status ?? PlannerOccurrenceStatus.scheduled),
      trackingMode: task.trackingMode,
      sessions: entries,
      actualStart: record?.actualStartAt,
      actualEnd: record?.actualEndAt,
      doneAt: record?.status == PlannerOccurrenceStatus.done ? (record?.completedAt ?? record?.statusChangedAt) : null,
      cancelledAt: cancelled ? record?.statusChangedAt : null,
      categoryId: task.categoryId,
      priority: task.priority,
      tagIds: _tags[task.id] ?? const [],
      moves: moves,
      skipReason: record?.skipReason,
      rating: record?.rating,
      outcomeNote: record?.outcomeNote,
      completionPercent: record?.completionPercent,
      seriesPaused: task.status == 'paused',
      title: record?.overrideTitle ?? task.title,
    );
  }
}
