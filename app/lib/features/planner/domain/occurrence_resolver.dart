import 'dart:math' as math;

import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Settings that influence derived statuses (arch §8.5 `planner` namespace).
@immutable
class ResolverSettings {
  const ResolverSettings({
    this.missedGraceMinutes = 15,
    this.overdueLookbackDays = 7,
    this.showCancelled = false,
    this.skipAdvancesAfterCompletion = true,
    this.maxOccurrences = 20000,
  });

  /// `planner.missedGraceMinutes`: an open check/timer occurrence becomes *missed* this long
  /// after its end.
  final int missedGraceMinutes;

  /// Missed one-off occurrences are *overdue* while their end is within this look-back.
  final int overdueLookbackDays;

  /// Keep cancelled occurrences (status `cancelled`) instead of hiding them.
  final bool showCancelled;

  /// After-completion rules: a skip also schedules the next occurrence.
  final bool skipAdvancesAfterCompletion;

  /// Hard cap per resolution; hitting it sets [ResolveResult.truncated].
  final int maxOccurrences;

  @override
  bool operator ==(Object other) =>
      other is ResolverSettings &&
      other.missedGraceMinutes == missedGraceMinutes &&
      other.overdueLookbackDays == overdueLookbackDays &&
      other.showCancelled == showCancelled &&
      other.skipAdvancesAfterCompletion == skipAdvancesAfterCompletion &&
      other.maxOccurrences == maxOccurrences;

  @override
  int get hashCode =>
      Object.hash(missedGraceMinutes, overdueLookbackDays, showCancelled, skipAdvancesAfterCompletion, maxOccurrences);
}

/// One concrete occurrence of a task for display (T3.2.01).
@immutable
class ResolvedOccurrence {
  const ResolvedOccurrence({
    required this.task,
    required this.occurrenceKey,
    required this.startInstant,
    required this.endInstant,
    required this.startLocalViewer,
    required this.endLocalViewer,
    required this.isAllDay,
    required this.originalStartLocal,
    required this.effectiveStartLocal,
    required this.durationMinutes,
    required this.title,
    required this.status,
    required this.dueEnd,
    this.record,
    this.notes,
    this.isCurrent = false,
    this.isOverdue = false,
    this.isMoved = false,
    this.isOverridden = false,
    this.isQuotaSlot = false,
    this.quotaPeriodKey,
    this.resolutionKind = ResolutionKind.exact,
  });

  final Task task;
  final String occurrenceKey;
  final TaskOccurrenceRecord? record;

  final DateTime startInstant;
  final DateTime endInstant;

  /// Effective start/end on the viewer's clock (all-day: date-based, never shifted).
  final LocalDateTime startLocalViewer;
  final LocalDateTime endLocalViewer;
  final bool isAllDay;

  /// Generated start in the task's own wall clock (identity; equals the key for timed tasks).
  final LocalDateTime originalStartLocal;

  /// Effective start in the task's own wall clock (after overrides).
  final LocalDateTime effectiveStartLocal;
  final int durationMinutes;
  final String title;
  final String? notes;
  final OccurrenceStatus status;

  /// Instant after which (plus the grace period) an open occurrence counts as missed.
  final DateTime dueEnd;
  final bool isCurrent;
  final bool isOverdue;
  final bool isMoved;
  final bool isOverridden;
  final bool isQuotaSlot;
  final String? quotaPeriodKey;
  final ResolutionKind resolutionKind;

  String get taskId => task.id;
  String get seriesId => task.seriesId;
  String? get recordId => record?.id;
  TrackingMode get trackingMode => task.trackingMode;
  int get priority => task.priority;

  /// `(taskId, key)` identity.
  String get identity => '${task.id}|$occurrenceKey';

  /// [categoryColor] / [categoryIcon] fill in when the task has no own color / icon (T3.1.12).
  PlannerItem toPlannerItem({int? categoryColor, String? categoryIcon}) => PlannerItem(
    taskId: task.id,
    seriesId: task.seriesId,
    occurrenceKey: occurrenceKey,
    title: title,
    startLocal: startLocalViewer,
    durationMinutes: durationMinutes,
    startUtc: startInstant,
    endUtc: endInstant,
    status: status,
    allDay: isAllDay,
    color: task.color ?? categoryColor,
    categoryId: task.categoryId,
    priority: task.priority,
    trackingMode: task.trackingMode,
    isRecurring: task.isRecurring,
    isOverridden: isOverridden,
    overdue: isOverdue,
    timeZone: task.timeZone,
    icon: task.icon ?? categoryIcon,
    location: task.location,
    linkedChecklistId: task.linkedChecklistId,
    notes: notes,
    recordId: record?.id,
    isMoved: isMoved,
    isCurrent: isCurrent,
    isQuotaSlot: isQuotaSlot,
    quotaPeriodKey: quotaPeriodKey,
    originalStartLocal: originalStartLocal,
    ownZoneStartLocal: task.isFixedZone ? effectiveStartLocal : null,
    deadlineLocal: task.deadlineLocal,
    estimateMinutes: task.estimateMinutes,
    manualSortKey: task.manualSortKey,
    completionPercent: record?.completionPercent,
    trackedSeconds: record?.trackedSeconds,
    rating: record?.rating,
    isPaused: task.isPaused,
  );

  @override
  bool operator ==(Object other) =>
      other is ResolvedOccurrence &&
      other.task == task &&
      other.occurrenceKey == occurrenceKey &&
      other.record == record &&
      other.startInstant == startInstant &&
      other.endInstant == endInstant &&
      other.startLocalViewer == startLocalViewer &&
      other.status == status &&
      other.isCurrent == isCurrent &&
      other.isOverdue == isOverdue;

  @override
  int get hashCode => Object.hash(task.id, occurrenceKey, startInstant, endInstant, status, isCurrent, isOverdue);

  @override
  String toString() =>
      'ResolvedOccurrence($title, $occurrenceKey, $startLocalViewer → $endLocalViewer, ${status.name})';
}

/// Output of [OccurrenceResolver.resolve].
@immutable
class ResolveResult {
  const ResolveResult(this.occurrences, {this.truncated = false});

  static const empty = ResolveResult([]);

  final List<ResolvedOccurrence> occurrences;

  /// The cap was hit: not every occurrence of the range is listed.
  final bool truncated;
}

/// Pure occurrence resolver (T3.2.01): expands every task over a half-open wall-clock range of
/// the viewer's zone, merges stored occurrence records (overrides, cancellations, outcomes) and
/// derives statuses. No I/O — callers pass tasks and records in.
///
/// Display rules (T3.2.03): fixed-zone tasks resolve in their own zone and are converted to the
/// viewer's clock; floating tasks keep their wall-clock time in the viewer's zone; all-day tasks
/// are date-based and never shift days; keys always stay in the task's own wall clock; DST gaps
/// shift forward, ambiguous times take the earlier offset (engine rules, arch §6.8).
class OccurrenceResolver {
  OccurrenceResolver(this.engine) : _merger = OverrideMerger(engine);

  final RecurrenceEngine engine;
  final OverrideMerger _merger;

  ZoneResolver get zones => engine.resolver;

  ResolveResult resolve({
    required Iterable<Task> tasks,
    required Iterable<TaskOccurrenceRecord> records,
    required LocalDateTime from,
    required LocalDateTime to,
    required String viewerZone,
    required DateTime now,
    ResolverSettings settings = const ResolverSettings(),
  }) {
    if (!to.isAfter(from)) return ResolveResult.empty;
    final byTask = <String, Map<String, TaskOccurrenceRecord>>{};
    for (final r in records) {
      if (r.isDeleted) continue;
      (byTask[r.taskId] ??= {})[r.occurrenceKey] = r;
    }
    final ctx = _Context(
      from: from,
      to: to,
      fromUtc: zones.resolve(from, viewerZone).utc,
      toUtc: zones.resolve(to, viewerZone).utc,
      viewerZone: viewerZone,
      now: now.toUtc(),
      today: zones.toLocal(now, viewerZone).date,
      settings: settings,
    );
    final out = <ResolvedOccurrence>[];
    var truncated = false;
    final seenTasks = <String>{};
    for (final task in tasks) {
      if (!seenTasks.add(task.id)) continue;
      if (task.isDeleted || task.isTemplate || task.isUnscheduled || task.status == TaskStatus.archived) continue;
      final recs = byTask[task.id] ?? const <String, TaskOccurrenceRecord>{};
      final remaining = settings.maxOccurrences - out.length;
      if (remaining <= 0) {
        truncated = true;
        break;
      }
      try {
        final (items, cut) = _resolveTask(task, recs, ctx, remaining);
        truncated = truncated || cut;
        out.addAll(items);
      } on InvalidRuleException {
        continue; // invalid rules produce nothing (the editor prevents saving them)
        // ignore: avoid_catching_errors, the engine throws it for unsupported rules.
      } on ArgumentError {
        continue;
      } on FormatException {
        continue;
      }
    }
    out.sort(compareResolved);
    if (out.length > settings.maxOccurrences) {
      truncated = true;
      out.removeRange(settings.maxOccurrences, out.length);
    }
    return ResolveResult(List.unmodifiable(out), truncated: truncated);
  }

  /// Convenience: occurrences of a single task.
  List<ResolvedOccurrence> resolveTask(
    Task task,
    Iterable<TaskOccurrenceRecord> records, {
    required LocalDateTime from,
    required LocalDateTime to,
    required String viewerZone,
    required DateTime now,
    ResolverSettings settings = const ResolverSettings(),
  }) => resolve(
    tasks: [task],
    records: records,
    from: from,
    to: to,
    viewerZone: viewerZone,
    now: now,
    settings: settings,
  ).occurrences;

  (List<ResolvedOccurrence>, bool) _resolveTask(
    Task task,
    Map<String, TaskOccurrenceRecord> recs,
    _Context ctx,
    int remaining,
  ) {
    final rule = task.recurrence;
    final List<ResolvedOccurrence> items;
    var truncated = false;
    if (rule == null) {
      items = _oneOff(task, recs, ctx);
    } else {
      switch (rule.type) {
        case RuleType.fixed:
          (items, truncated) = _fixed(task, rule, recs, ctx, remaining);
        case RuleType.afterCompletion:
          items = _afterCompletion(task, rule, recs, ctx);
        case RuleType.quota:
          items = _quota(task, rule, recs, ctx, remaining);
      }
    }
    if (!task.isPaused) return (items, truncated);
    final cutoff = task.pausedAt ?? ctx.now;
    return (
      [
        for (final o in items)
          if (o.startInstant.isBefore(cutoff) || (o.record?.hasOutcome ?? false)) o,
      ],
      truncated,
    );
  }

  // ---------------------------------------------------------------------------

  List<ResolvedOccurrence> _oneOff(Task task, Map<String, TaskOccurrenceRecord> recs, _Context ctx) {
    final anchor = task.anchor!;
    final key = task.oneOffKey!;
    var record = recs[key];
    if (record == null && recs.isNotEmpty) {
      // A record written under a previous start (e.g. rescheduled on another device).
      record = recs.values.reduce((a, b) => (a.updatedAt ?? DateTime(0)).isAfter(b.updatedAt ?? DateTime(0)) ? a : b);
    }
    if (record != null && record.isCancelled && !ctx.settings.showCancelled) return const [];
    final start = record?.overrideStartLocal ?? anchor.start;
    final duration = record?.overrideDurationMinutes ?? task.effectiveDurationMinutes;
    final occ = engine.occurrenceAt(anchor, start, evalZone: ctx.viewerZone, durationMinutes: duration, key: key);
    if (!_overlaps(anchor.allDay, occ, duration, ctx)) return const [];
    return [
      _build(
        task: task,
        key: key,
        record: record,
        occ: occ,
        durationMinutes: duration,
        originalStart: anchor.start,
        ctx: ctx,
      ),
    ];
  }

  (List<ResolvedOccurrence>, bool) _fixed(
    Task task,
    RecurrenceRule rule,
    Map<String, TaskOccurrenceRecord> recs,
    _Context ctx,
    int remaining,
  ) {
    final anchor = task.anchor!;
    final showCancelled = ctx.settings.showCancelled;
    final out = <ResolvedOccurrence>[];
    var truncated = false;
    try {
      final merged = _merger.merge<TaskOccurrenceRecord>(rule, anchor, ctx.from, ctx.to, [
        for (final r in recs.values)
          OccurrenceOverride<TaskOccurrenceRecord>(
            r.occurrenceKey,
            cancelled: r.isCancelled && !showCancelled,
            newStartLocal: r.overrideStartLocal,
            newDurationMinutes: r.overrideDurationMinutes,
            payload: r,
          ),
      ], evalZone: ctx.viewerZone);
      for (final m in merged) {
        final effective = Occurrence(
          key: m.key,
          startLocal: m.startLocal,
          startUtc: m.startUtc,
          endUtc: m.endUtc,
          isAllDay: m.isAllDay,
          resolutionKind: m.original.resolutionKind,
          zoneId: m.original.zoneId,
        );
        out.add(
          _build(
            task: task,
            key: m.key,
            record: recs[m.key],
            occ: effective,
            durationMinutes: m.durationMinutes,
            originalStart: m.original.startLocal,
            ctx: ctx,
          ),
        );
      }
    } on RecurrenceLimitExceeded {
      // Too dense for one call: keep the earliest occurrences and flag the range.
      truncated = true;
      out.clear();
      for (final o in engine.between(
        rule,
        anchor,
        ctx.from,
        ctx.to,
        evalZone: ctx.viewerZone,
        limit: math.max(1, remaining),
      )) {
        final r = recs[o.key];
        if (r != null && r.isCancelled && !showCancelled) continue;
        out.add(
          _build(
            task: task,
            key: o.key,
            record: r,
            occ: o,
            durationMinutes: task.effectiveDurationMinutes,
            originalStart: o.startLocal,
            ctx: ctx,
          ),
        );
      }
    }
    // countMode = completions: the series ends with its N-th completion.
    final count = rule.count;
    if (count != null && rule.countMode == CountMode.completions) {
      final doneKeys = [
        for (final r in recs.values)
          if (!r.isCancelled && r.status == OccurrenceStatus.done) r.occurrenceKey,
      ]..sort();
      if (doneKeys.length >= count) {
        final lastKey = doneKeys[count - 1];
        out.removeWhere((o) => o.occurrenceKey.compareTo(lastKey) > 0 && !(o.record?.hasOutcome ?? false));
      }
    }
    return (out, truncated);
  }

  List<ResolvedOccurrence> _afterCompletion(
    Task task,
    RecurrenceRule rule,
    Map<String, TaskOccurrenceRecord> recs,
    _Context ctx,
  ) {
    final anchor = task.anchor!;
    final advancing = [
      for (final r in recs.values)
        if (r.isCancelled ||
            r.status == OccurrenceStatus.done ||
            (ctx.settings.skipAdvancesAfterCompletion && r.status == OccurrenceStatus.skipped))
          r,
    ]..sort((a, b) => (a.completionInstant ?? DateTime(0)).compareTo(b.completionInstant ?? DateTime(0)));
    final completions = advancing.where((r) => r.status == OccurrenceStatus.done).length;
    final count = rule.count;
    Occurrence? pending;
    if (count == null || completions < count) {
      final last = advancing.isEmpty ? null : advancing.last.completionInstant;
      pending = engine.nextDue(rule, anchor, last, evalZone: ctx.viewerZone);
      // Completed early at the same due key: move on to the following due time.
      for (var guard = 0; pending != null && guard < 16; guard++) {
        final existing = recs[pending.key];
        if (existing == null || !advancing.contains(existing)) break;
        pending = engine.nextDue(rule, anchor, pending.startUtc, evalZone: ctx.viewerZone);
      }
    }
    final keys = <String>{
      for (final r in recs.values)
        if (r.hasOutcome || (r.isCancelled && ctx.settings.showCancelled)) r.occurrenceKey,
      ?pending?.key,
    };
    final out = <ResolvedOccurrence>[];
    for (final key in keys) {
      final original = _parseKey(key, anchor);
      if (original == null) continue;
      final r = recs[key];
      if (r != null && r.isCancelled && !ctx.settings.showCancelled) continue;
      final start = r?.overrideStartLocal ?? original;
      final duration = r?.overrideDurationMinutes ?? task.effectiveDurationMinutes;
      final occ = engine.occurrenceAt(anchor, start, evalZone: ctx.viewerZone, durationMinutes: duration, key: key);
      if (!_overlaps(anchor.allDay, occ, duration, ctx)) continue;
      out.add(
        _build(task: task, key: key, record: r, occ: occ, durationMinutes: duration, originalStart: original, ctx: ctx),
      );
    }
    return out;
  }

  List<ResolvedOccurrence> _quota(
    Task task,
    RecurrenceRule rule,
    Map<String, TaskOccurrenceRecord> recs,
    _Context ctx,
    int remaining,
  ) {
    final anchor = task.anchor!;
    final zone = task.timeZone ?? ctx.viewerZone;
    final out = <ResolvedOccurrence>[];
    final seen = <String>{};
    final until = rule.until?.date;

    void place(Occurrence slot, TaskOccurrenceRecord r) {
      final duration = r.overrideDurationMinutes ?? task.effectiveDurationMinutes;
      final occ = engine.occurrenceAt(
        anchor,
        r.overrideStartLocal!,
        evalZone: ctx.viewerZone,
        durationMinutes: duration,
        key: slot.key,
      );
      if (!_overlaps(anchor.allDay, occ, duration, ctx)) return;
      out.add(
        _build(
          task: task,
          key: slot.key,
          record: r,
          occ: occ,
          durationMinutes: duration,
          originalStart: slot.startLocal,
          ctx: ctx,
          quotaPeriodKey: _periodKeyOf(slot.key),
        ),
      );
    }

    for (final slot in engine.between(rule, anchor, ctx.from, ctx.to, evalZone: ctx.viewerZone, limit: remaining)) {
      seen.add(slot.key);
      final r = recs[slot.key];
      if (r != null && r.isCancelled && !ctx.settings.showCancelled) continue;
      if (r?.overrideStartLocal != null) {
        place(slot, r!);
        continue;
      }
      final period = QuotaPeriodKey.parse(_periodKeyOf(slot.key));
      if (period == null) continue;
      final activeStart = slot.startLocal.date;
      final activeEnd = until == null ? period.endDate : LocalDate.min(period.endDate, until);
      // Unplaced slot: shown as an all-day marker on today (current period), the period's last
      // day (past periods) or its first day (future periods), clamped into the range.
      var day = ctx.today.isAfter(activeEnd) ? activeEnd : (ctx.today.isBefore(activeStart) ? activeStart : ctx.today);
      if (day.isBefore(ctx.from.date)) day = ctx.from.date;
      if (day.isAfter(activeEnd) || !day.atStartOfDay.isBefore(ctx.to)) continue;
      final startUtc = zones.resolve(day.atStartOfDay, zone).utc;
      final endUtc = zones.resolve(day.plusDays(1).atStartOfDay, zone).utc;
      final dueEnd = zones.resolve(activeEnd.plusDays(1).atStartOfDay, zone).utc;
      final status = _status(task, r, dueEnd, ctx);
      out.add(
        ResolvedOccurrence(
          task: task,
          occurrenceKey: slot.key,
          record: r,
          startInstant: startUtc,
          endInstant: endUtc,
          startLocalViewer: day.atStartOfDay,
          endLocalViewer: day.plusDays(1).atStartOfDay,
          isAllDay: true,
          originalStartLocal: slot.startLocal,
          effectiveStartLocal: day.atStartOfDay,
          durationMinutes: 1440,
          title: r?.overrideTitle ?? task.title,
          notes: r?.overrideNotes ?? task.notes,
          status: status,
          dueEnd: dueEnd,
          isOverridden: r?.hasOverride ?? false,
          isQuotaSlot: true,
          quotaPeriodKey: period.key,
        ),
      );
    }
    // Slots placed into the range from a period outside it.
    for (final r in recs.values) {
      if (seen.contains(r.occurrenceKey) || r.overrideStartLocal == null || !r.occurrenceKey.contains('#')) continue;
      if (r.isCancelled && !ctx.settings.showCancelled) continue;
      final slot = engine.occurrenceForKey(rule, anchor, r.occurrenceKey, evalZone: ctx.viewerZone);
      if (slot != null) place(slot, r);
    }
    return out;
  }

  // ---------------------------------------------------------------------------

  ResolvedOccurrence _build({
    required Task task,
    required String key,
    required TaskOccurrenceRecord? record,
    required Occurrence occ,
    required int durationMinutes,
    required LocalDateTime originalStart,
    required _Context ctx,
    String? quotaPeriodKey,
  }) {
    final allDay = occ.isAllDay;
    final LocalDateTime startViewer;
    final LocalDateTime endViewer;
    final int minutes;
    if (allDay) {
      final days = math.max(1, (durationMinutes + 1439) ~/ 1440);
      startViewer = occ.startLocal.date.atStartOfDay;
      endViewer = startViewer.plusDays(days);
      minutes = days * 1440;
    } else {
      startViewer = zones.toLocal(occ.startUtc, ctx.viewerZone);
      endViewer = zones.toLocal(occ.endUtc, ctx.viewerZone);
      minutes = durationMinutes;
    }
    final status = _status(task, record, occ.endUtc, ctx);
    final open = status == OccurrenceStatus.scheduled || status == OccurrenceStatus.inProgress;
    final isCurrent = open && !ctx.now.isBefore(occ.startUtc) && ctx.now.isBefore(occ.endUtc);
    final isOverdue =
        status == OccurrenceStatus.missed &&
        !task.isRecurring &&
        ctx.now.difference(occ.endUtc) <= Duration(days: ctx.settings.overdueLookbackDays);
    return ResolvedOccurrence(
      task: task,
      occurrenceKey: key,
      record: record,
      startInstant: occ.startUtc,
      endInstant: occ.endUtc,
      startLocalViewer: startViewer,
      endLocalViewer: endViewer,
      isAllDay: allDay,
      originalStartLocal: originalStart,
      effectiveStartLocal: occ.startLocal,
      durationMinutes: minutes,
      title: record?.overrideTitle ?? task.title,
      notes: record?.overrideNotes ?? task.notes,
      status: status,
      dueEnd: occ.endUtc,
      isCurrent: isCurrent,
      isOverdue: isOverdue,
      isMoved: occ.startLocal != originalStart,
      isOverridden: record?.hasOverride ?? false,
      isQuotaSlot: quotaPeriodKey != null,
      quotaPeriodKey: quotaPeriodKey,
      resolutionKind: occ.resolutionKind,
    );
  }

  /// Derived status precedence (T3.2.01): record status → missed after end + grace for
  /// check/timer tasks → scheduled.
  static OccurrenceStatus _status(Task task, TaskOccurrenceRecord? record, DateTime dueEnd, _Context ctx) =>
      deriveStatus(
        trackingMode: task.trackingMode,
        record: record,
        dueEnd: dueEnd,
        now: ctx.now,
        graceMinutes: ctx.settings.missedGraceMinutes,
      );

  bool _overlaps(bool allDay, Occurrence effective, int minutes, _Context ctx) {
    if (allDay) {
      final start = effective.startLocal.date.atStartOfDay;
      final days = math.max(1, (minutes + 1439) ~/ 1440);
      return start.isBefore(ctx.to) && start.plusDays(days).isAfter(ctx.from);
    }
    if (!effective.startUtc.isBefore(ctx.toUtc)) return false;
    return minutes == 0 ? !effective.startUtc.isBefore(ctx.fromUtc) : effective.endUtc.isAfter(ctx.fromUtc);
  }

  static LocalDateTime? _parseKey(String key, RecurrenceAnchor anchor) =>
      LocalDateTime.tryParse(key) ?? LocalDate.tryParse(key)?.atStartOfDay;

  static String _periodKeyOf(String slotKey) {
    final hash = slotKey.lastIndexOf('#');
    return hash < 0 ? slotKey : slotKey.substring(0, hash);
  }
}

/// Status derivation shared by the resolver and tests.
OccurrenceStatus deriveStatus({
  required TrackingMode trackingMode,
  required TaskOccurrenceRecord? record,
  required DateTime dueEnd,
  required DateTime now,
  required int graceMinutes,
}) {
  if (record != null) {
    if (record.isCancelled) return OccurrenceStatus.cancelled;
    if (record.status != OccurrenceStatus.scheduled) return record.status;
  }
  if (TrackingPolicy.of(trackingMode).canBeMissed && !now.isBefore(dueEnd.add(Duration(minutes: graceMinutes)))) {
    return OccurrenceStatus.missed;
  }
  return OccurrenceStatus.scheduled;
}

/// Stable ordering: day, all-day first (manual order), start, priority desc, title, id, key.
int compareResolved(ResolvedOccurrence a, ResolvedOccurrence b) {
  var c = a.startLocalViewer.date.compareTo(b.startLocalViewer.date);
  if (c != 0) return c;
  if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
  if (a.isAllDay) {
    final ka = a.task.manualSortKey;
    final kb = b.task.manualSortKey;
    if (ka != kb) {
      if (ka == null) return 1;
      if (kb == null) return -1;
      c = ka.compareTo(kb);
      if (c != 0) return c;
    }
  } else {
    c = a.startInstant.compareTo(b.startInstant);
    if (c != 0) return c;
  }
  c = b.task.priority.compareTo(a.task.priority);
  if (c != 0) return c;
  c = a.title.compareTo(b.title);
  if (c != 0) return c;
  c = a.task.id.compareTo(b.task.id);
  if (c != 0) return c;
  return a.occurrenceKey.compareTo(b.occurrenceKey);
}

/// A quota period key (`day:2026-09-21`, `week:2026-09-21`, `month:2026-09`, `year:2026`).
@immutable
class QuotaPeriodKey {
  const QuotaPeriodKey(this.key, this.unit, this.startDate, this.endDate);

  final String key;
  final PeriodUnit unit;
  final LocalDate startDate;
  final LocalDate endDate;

  static QuotaPeriodKey? parse(String key) {
    final colon = key.indexOf(':');
    if (colon < 0) return null;
    final value = key.substring(colon + 1);
    switch (key.substring(0, colon)) {
      case 'day':
        final d = LocalDate.tryParse(value);
        return d == null ? null : QuotaPeriodKey(key, PeriodUnit.day, d, d);
      case 'week':
        final d = LocalDate.tryParse(value);
        return d == null ? null : QuotaPeriodKey(key, PeriodUnit.week, d, d.plusDays(6));
      case 'month':
        final d = LocalDate.tryParse('$value-01');
        return d == null ? null : QuotaPeriodKey(key, PeriodUnit.month, d, d.lastDayOfMonth);
      case 'year':
        final d = LocalDate.tryParse('$value-01-01');
        return d == null ? null : QuotaPeriodKey(key, PeriodUnit.year, d, LocalDate(d.year, 12, 31));
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is QuotaPeriodKey && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class _Context {
  _Context({
    required this.from,
    required this.to,
    required this.fromUtc,
    required this.toUtc,
    required this.viewerZone,
    required this.now,
    required this.today,
    required this.settings,
  });

  final LocalDateTime from;
  final LocalDateTime to;
  final DateTime fromUtc;
  final DateTime toUtc;
  final String viewerZone;
  final DateTime now;
  final LocalDate today;
  final ResolverSettings settings;
}

/// Rough number of occurrences the tasks produce over `[from, to)` (isolate decision, T3.2.02).
int estimateOccurrenceCount(Iterable<Task> tasks, LocalDateTime from, LocalDateTime to) {
  final days = math.max(1, (from.minutesUntil(to) / 1440).ceil());
  var total = 0;
  for (final t in tasks) {
    final rule = t.recurrence;
    if (rule == null) {
      total += 1;
      continue;
    }
    switch (rule.type) {
      case RuleType.afterCompletion:
        total += 1;
      case RuleType.quota:
        final q = rule.quota;
        final perDay = q == null
            ? 1.0
            : q.times /
                  switch (q.per) {
                    PeriodUnit.day => 1,
                    PeriodUnit.week => 7,
                    PeriodUnit.month => 30,
                    PeriodUnit.year => 365,
                  };
        total += (perDay * days).ceil() + (q?.times ?? 1);
      case RuleType.fixed:
        final interval = math.max(1, rule.interval);
        final times = math.max(1, rule.times.length);
        final weekdays = rule.byWeekday == null ? 7 : math.max(1, rule.byWeekday!.length);
        final double perDay;
        switch (rule.freq) {
          case Frequency.minutely:
          case Frequency.hourly:
            final w = rule.window;
            final span = w == null ? 1440 : math.max(1, (w.end.minuteOfDay) - w.start.minuteOfDay + 1);
            final step = interval * (rule.freq == Frequency.hourly ? 60 : 1);
            perDay = (span / step).ceilToDouble() * weekdays / 7;
          case Frequency.daily:
            perDay = times * weekdays / 7 / interval;
          case Frequency.weekly:
            perDay = times * weekdays / 7 / interval;
          case Frequency.monthly:
            perDay = times * math.max(1, rule.byMonthDay.length + (rule.byWeekday?.length ?? 0)) / 30 / interval;
          case Frequency.yearly:
            perDay = times * math.max(1, rule.byMonth.length) / 365 / interval;
        }
        total += (perDay * days).ceil() + 1;
    }
  }
  return total;
}
