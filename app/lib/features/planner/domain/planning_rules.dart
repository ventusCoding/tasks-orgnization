import 'dart:math' as math;

import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Pure planning rules shared by the planner services and editors.

// ---------------------------------------------------------------------------
// T3.1.08 — quick-create default duration rule.

/// Start and duration of a task created by tapping the grid.
@immutable
class QuickCreateSlot {
  const QuickCreateSlot(this.start, this.durationMinutes, {this.allDay = false});

  final LocalDateTime start;
  final int durationMinutes;
  final bool allDay;

  @override
  bool operator ==(Object other) =>
      other is QuickCreateSlot &&
      other.start == start &&
      other.durationMinutes == durationMinutes &&
      other.allDay == allDay;

  @override
  int get hashCode => Object.hash(start, durationMinutes, allDay);

  @override
  String toString() => 'QuickCreateSlot($start, $durationMinutes min${allDay ? ', all-day' : ''})';
}

/// Default duration rule (T3.1.08):
/// 1. a dragged range wins;
/// 2. week-list mode (1 440-min slots) creates an all-day task for that day;
/// 3. 15 ≤ slot ≤ 60 min → the slot length;
/// 4. otherwise `planner.defaultTaskDurationMinutes` (default 30).
/// The start snaps down to the slot boundary (slots start at midnight).
QuickCreateSlot quickCreateSlot({
  required LocalDateTime tapped,
  int? rangeMinutes,
  int? slotMinutes,
  int defaultDurationMinutes = 30,
}) {
  if (rangeMinutes != null && rangeMinutes > 0) return QuickCreateSlot(tapped, rangeMinutes);
  final slot = slotMinutes;
  if (slot != null && slot >= 1440) return QuickCreateSlot(tapped.date.atStartOfDay, 1440, allDay: true);
  final start = slot == null || slot <= 1
      ? tapped
      : tapped.date.atTime(LocalTime.fromMinuteOfDay(tapped.time.minuteOfDay ~/ slot * slot));
  if (slot != null && slot >= 15 && slot <= 60) return QuickCreateSlot(start, slot);
  return QuickCreateSlot(start, defaultDurationMinutes);
}

// ---------------------------------------------------------------------------
// T3.2.14 — actual-time capture on completion.

/// `planner.askActualTimeOnDone`.
enum AskActualTimeOnDone {
  never('never'),
  ifOffSchedule('if_off_schedule'),
  always('always');

  AskActualTimeOnDone(this.json);

  final String json;

  static AskActualTimeOnDone fromJson(Object? value) =>
      values.firstWhere((v) => v.json == value, orElse: () => AskActualTimeOnDone.ifOffSchedule);
}

/// Whether the Done flow asks for actual times ([thresholdMinutes] from the planned end).
bool shouldAskActualTime(
  AskActualTimeOnDone setting, {
  required DateTime plannedEnd,
  required DateTime now,
  int thresholdMinutes = 15,
}) => switch (setting) {
  AskActualTimeOnDone.never => false,
  AskActualTimeOnDone.always => true,
  AskActualTimeOnDone.ifOffSchedule => now.difference(plannedEnd).inMinutes.abs() > thresholdMinutes,
};

enum ActualTimeOption { asPlanned, justNow, custom }

/// Invalid custom actual times (end before start).
class ActualTimeException implements Exception {
  const ActualTimeException();

  @override
  String toString() => 'ActualTimeException(end before start)';
}

/// Actual start/end for a Done option (T3.2.14):
/// *As planned* → planned; *Just now* → end = now, start = now − planned duration;
/// *Custom* → validated `end ≥ start`.
({DateTime start, DateTime end}) actualTimesFor(
  ActualTimeOption option, {
  required DateTime plannedStart,
  required DateTime plannedEnd,
  required DateTime now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  switch (option) {
    case ActualTimeOption.asPlanned:
      return (start: plannedStart, end: plannedEnd);
    case ActualTimeOption.justNow:
      return (start: now.subtract(plannedEnd.difference(plannedStart)), end: now);
    case ActualTimeOption.custom:
      final start = customStart ?? plannedStart;
      final end = customEnd ?? plannedEnd;
      if (end.isBefore(start)) throw const ActualTimeException();
      return (start: start, end: end);
  }
}

// ---------------------------------------------------------------------------
// T3.2.17 / T3.2.18 — time tracking math.

/// `planner.timerPolicy`.
enum TimerPolicy {
  single,
  multiple;

  static TimerPolicy fromJson(Object? value) => value == 'multiple' ? TimerPolicy.multiple : TimerPolicy.single;
}

/// Total tracked seconds of [entries] (running entries count up to [now]).
int trackedSecondsOf(Iterable<TimeEntry> entries, DateTime now) =>
    entries.fold(0, (sum, e) => sum + math.max(0, e.durationAt(now).inSeconds));

/// Entries of [others] overlapping `[start, end)` (running entries end at [now]).
List<TimeEntry> overlappingEntries(
  DateTime start,
  DateTime end,
  Iterable<TimeEntry> others, {
  required DateTime now,
  String? excludeId,
}) => [
  for (final e in others)
    if (e.id != excludeId && e.startedAt.isBefore(end) && (e.endedAt ?? now).isAfter(start)) e,
];

/// Validation of a manual time entry (T3.2.18).
enum TimeEntryError { endBeforeStart, inFuture }

TimeEntryError? validateTimeEntry(DateTime start, DateTime? end, {required DateTime now}) {
  if (end != null && end.isBefore(start)) return TimeEntryError.endBeforeStart;
  if (start.isAfter(now.add(const Duration(minutes: 1)))) return TimeEntryError.inFuture;
  return null;
}

// ---------------------------------------------------------------------------
// T3.1.14 — overlap warning.

/// Occurrences of [items] overlapping `[startUtc, endUtc)`: timed, still open, of a
/// `check`/`timer` task (plus `event` tasks when [includeEvents]).
List<PlannerItem> findOverlaps({
  required DateTime startUtc,
  required DateTime endUtc,
  required Iterable<PlannerItem> items,
  String? excludeTaskId,
  String? excludeKey,
  bool includeEvents = false,
}) => [
  for (final i in items)
    if (!i.allDay &&
        !(i.taskId == excludeTaskId && (excludeKey == null || i.occurrenceKey == excludeKey)) &&
        i.status != OccurrenceStatus.done &&
        i.status != OccurrenceStatus.cancelled &&
        i.status != OccurrenceStatus.skipped &&
        (includeEvents || i.trackingMode != TrackingMode.event) &&
        i.startUtc.isBefore(endUtc) &&
        i.endUtc.isAfter(startUtc))
      i,
];

// ---------------------------------------------------------------------------
// T3.2.10 — postpone options.

enum PostponeOption { plus15Minutes, plus1Hour, thisEvening, tomorrowSameTime, nextWeekSameTime }

/// Target start for a postpone option. Relative options start from the planned start, or from
/// now when the occurrence is already past.
LocalDateTime postponeTarget(
  PostponeOption option, {
  required LocalDateTime currentStart,
  required LocalDateTime nowLocal,
}) {
  final base = currentStart.isBefore(nowLocal) ? nowLocal : currentStart;
  return switch (option) {
    PostponeOption.plus15Minutes => base.plusMinutes(15),
    PostponeOption.plus1Hour => base.plusMinutes(60),
    PostponeOption.thisEvening =>
      nowLocal.time.minuteOfDay < 20 * 60
          ? nowLocal.date.atTime(LocalTime(20, 0))
          : nowLocal.date.plusDays(1).atTime(LocalTime(20, 0)),
    PostponeOption.tomorrowSameTime => nowLocal.date.plusDays(1).atTime(currentStart.time),
    PostponeOption.nextWeekSameTime => LocalDate.max(
      currentStart.date,
      nowLocal.date,
    ).plusDays(7).atTime(currentStart.time),
  };
}

/// *Move to today* (T3.2.10) / roll-over target (T3.2.12): the same time today while it is still
/// ahead; otherwise null (the caller makes it all-day or picks the next quarter hour).
LocalDateTime? sameTimeTodayIfAhead(LocalDateTime currentStart, LocalDateTime nowLocal) {
  final candidate = nowLocal.date.atTime(currentStart.time);
  return candidate.isAfter(nowLocal) ? candidate : null;
}

/// Next quarter hour strictly after [nowLocal].
LocalDateTime nextQuarterHour(LocalDateTime nowLocal) {
  final minutes = nowLocal.time.minuteOfDay;
  final next = (minutes ~/ 15 + 1) * 15;
  return nowLocal.date.atStartOfDay.plusMinutes(next);
}

/// `planner.rollOverIncomplete`.
enum RollOverPolicy {
  off,
  ask,
  auto;

  static RollOverPolicy fromJson(Object? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => RollOverPolicy.off);
}

// ---------------------------------------------------------------------------
// T3.2.09 — orphaned overrides.

/// Records a rule change leaves without a generated key.
@immutable
class OrphanReport {
  const OrphanReport({this.withOutcome = const [], this.overridesOnly = const [], this.cancelledOnly = const []});

  static const none = OrphanReport();

  /// Done/skipped/started/rated/tracked records — always kept as one-off tasks.
  final List<TaskOccurrenceRecord> withOutcome;

  /// Moved or edited occurrences without an outcome — kept or discarded by the user.
  final List<TaskOccurrenceRecord> overridesOnly;

  /// Exceptions of occurrences that no longer exist — dropped silently.
  final List<TaskOccurrenceRecord> cancelledOnly;

  bool get isEmpty => withOutcome.isEmpty && overridesOnly.isEmpty;

  /// Whether the user must choose (keep or discard) — only when overrides-only records exist.
  bool get needsChoice => overridesOnly.isNotEmpty;

  int get completedCount => withOutcome.where((r) => r.status == OccurrenceStatus.done).length;
  int get skippedCount => withOutcome.where((r) => r.status == OccurrenceStatus.skipped).length;
  int get otherOutcomeCount => withOutcome.length - completedCount - skippedCount;
  int get movedCount => overridesOnly.length;
}

/// Records of [records] whose key [isGenerated] no longer produces (T3.2.09).
OrphanReport findOrphans(Iterable<TaskOccurrenceRecord> records, bool Function(String key) isGenerated) {
  final outcome = <TaskOccurrenceRecord>[];
  final overrides = <TaskOccurrenceRecord>[];
  final cancelled = <TaskOccurrenceRecord>[];
  for (final r in records) {
    if (r.isDeleted || isGenerated(r.occurrenceKey)) continue;
    if (r.hasOutcome) {
      outcome.add(r);
    } else if (r.hasOverride) {
      overrides.add(r);
    } else {
      cancelled.add(r);
    }
  }
  int byKey(TaskOccurrenceRecord a, TaskOccurrenceRecord b) => a.occurrenceKey.compareTo(b.occurrenceKey);
  return OrphanReport(
    withOutcome: outcome..sort(byKey),
    overridesOnly: overrides..sort(byKey),
    cancelledOnly: cancelled..sort(byKey),
  );
}

/// What to do with override-only orphans.
enum OrphanPolicy { keepAsOneOff, discard }

// ---------------------------------------------------------------------------
// T3.2.04 — skip reasons.

/// Quick skip reasons stored as keys in `skip_reason` (free text otherwise).
abstract final class SkipReasons {
  static const tooBusy = 'too_busy';
  static const sick = 'sick';
  static const notNeeded = 'not_needed';
  static const forgot = 'forgot';
  static const other = 'other';

  static const all = [tooBusy, sick, notNeeded, forgot, other];

  static bool isKey(String? value) => all.contains(value);

  /// Maximum length of `skip_reason` (server CHECK).
  static const maxLength = 200;
}

/// Primary actions for [item] (UI helper on top of [TrackingPolicy]).
List<OccurrencePrimaryAction> primaryActionsFor(PlannerItem item, {bool timerRunning = false}) =>
    TrackingPolicy.of(item.trackingMode).primaryActions(item.status, timerRunning: timerRunning);
