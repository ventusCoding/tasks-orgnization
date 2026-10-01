/// Planner Insights calculators ([6.3]): per-occurrence (PL-T-*), per-series (PL-S-*) and section
/// (PL-X-*) metrics over [PlannerOccurrenceFact]s.
///
/// Durations inside a single occurrence are `Duration`s; aggregates are in minutes (`double`).
/// Wall-clock values (weekday, hour, work hours) come from the facts' local fields or from a
/// [ZoneClock] for instants (sessions, done_at).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/circular.dart';
import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/min_data.dart';
import 'package:everslot_metrics/src/occurrence_ledger.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/planner_facts.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/streaks.dart';
import 'package:everslot_metrics/src/strength.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:meta/meta.dart';

// ---------------------------------------------------------------------------------------------
// Per-occurrence timing & outcome (T6.3.02)
// ---------------------------------------------------------------------------------------------

bool _isPartial(PlannerOccurrenceFact f) {
  final pct = f.completionPercent;
  if (pct != null && pct >= 1 && pct <= 99) return true;
  final linked = f.linkedChecklistProgress;
  return linked != null && linked < 1;
}

/// PL-T-06 — outcome class: doneOnTime (done_at ≤ pe + g; timer: ae ≤ pe + g), doneLate, partial
/// (completion 1–99 % or linked checklist < 100 %), skipped, missed (explicit, or a check/timer
/// occurrence unresolved after pe + missed grace), cancelled, pending, future; `event` occurrences
/// without an explicit resolution are `notTracked`.
PlannerOutcome plannerOutcome(
  PlannerOccurrenceFact f, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  switch (f.status) {
    case PlannerOccurrenceStatus.cancelled:
      return PlannerOutcome.cancelled;
    case PlannerOccurrenceStatus.skipped:
      return PlannerOutcome.skipped;
    case PlannerOccurrenceStatus.missed:
      return PlannerOutcome.missed;
    case PlannerOccurrenceStatus.done:
      if (_isPartial(f)) return PlannerOutcome.partial;
      final pe = f.plannedEnd;
      if (pe == null) return PlannerOutcome.doneOnTime;
      final sessions = f.effectiveSessions;
      final reference = f.trackingMode == TrackingMode.timer && sessions.isNotEmpty
          ? sessions.map((s) => s.end).reduce((a, b) => a.isAfter(b) ? a : b)
          : f.doneAt;
      if (reference == null) return PlannerOutcome.doneOnTime;
      return reference.isAfter(pe.add(settings.grace)) ? PlannerOutcome.doneLate : PlannerOutcome.doneOnTime;
    case PlannerOccurrenceStatus.scheduled || PlannerOccurrenceStatus.inProgress:
      final ps = f.plannedStart;
      if (ps != null && now.isBefore(ps)) return PlannerOutcome.future;
      if (!f.trackingMode.countsForCompletion) return PlannerOutcome.notTracked;
      final pe = f.plannedEnd;
      if (pe != null && !now.isBefore(pe.add(settings.missedGrace))) {
        return PlannerOutcome.missed;
      }
      return PlannerOutcome.pending;
  }
}

/// PL-T-01 — planned duration Dp = pe − ps (not applicable to all-day/unscheduled occurrences).
Stat<Duration> plannedDuration(PlannerOccurrenceFact f) {
  if (f.isAllDay) return const NotApplicable<Duration>(Reasons.allDay);
  final m = f.plannedMinutes;
  if (m == null) return const NotApplicable<Duration>(Reasons.notScheduled);
  return Value<Duration>(Duration(seconds: (m * 60).round()));
}

/// PL-T-02 — actual duration Da = Σ(ae_i − as_i), pauses excluded. "Actual time not tracked" is
/// [NotApplicable]`('notTracked')`, never 0.
Stat<Duration> actualDuration(PlannerOccurrenceFact f) {
  final s = f.effectiveSessions;
  if (s.isEmpty) return const NotApplicable<Duration>(Reasons.notTracked);
  return Value<Duration>(s.fold(Duration.zero, (acc, x) => acc + x.length), sampleSize: s.length);
}

/// Over/under label of PL-T-03.
enum DurationLabel { over, under, onPlan }

/// PL-T-03 result.
@immutable
final class const DurationVariance(
  final Duration variance, {
  required final double? ratio,
  required final DurationLabel label,
});

/// PL-T-03 — variance = Da − Dp; R = Da/Dp (defined only when Dp ≥ 5 min); "over"/"under" when
/// |variance| > max(5 min, 10 % Dp).
Stat<DurationVariance> durationVariance(PlannerOccurrenceFact f) {
  final dp = f.plannedMinutes;
  final da = f.actualMinutes;
  if (dp == null) {
    return const NotApplicable<DurationVariance>(Reasons.notScheduled);
  }
  if (da == null) {
    return const NotApplicable<DurationVariance>(Reasons.notTracked);
  }
  final variance = da - dp;
  final threshold = math.max(5, 0.1 * dp);
  return Value<DurationVariance>(
    DurationVariance(
      Duration(seconds: (variance * 60).round()),
      ratio: dp >= 5 ? da / dp : null,
      label: variance.abs() > threshold
          ? (variance > 0 ? DurationLabel.over : DurationLabel.under)
          : DurationLabel.onPlan,
    ),
  );
}

/// R = Da/Dp when both are known and Dp ≥ 5 min.
double? durationRatio(PlannerOccurrenceFact f) {
  final dp = f.plannedMinutes;
  final da = f.actualMinutes;
  if (dp == null || da == null || dp < 5) return null;
  return da / dp;
}

/// Punctuality class.
enum Punctuality { early, onTime, late }

/// A signed timing difference with its class.
@immutable
final class const TimingDelta(final Duration delta, {required final Punctuality punctuality});

/// PL-T-04 — start delay Δs = as − ps: on time if |Δs| ≤ g, early if Δs < −g, late otherwise.
Stat<TimingDelta> startDelay(PlannerOccurrenceFact f, {Duration grace = const Duration(minutes: 5)}) {
  final ps = f.plannedStart;
  if (ps == null || f.isAllDay) {
    return const NotApplicable<TimingDelta>(Reasons.notScheduled);
  }
  final s = f.effectiveSessions;
  if (s.isEmpty) return const NotApplicable<TimingDelta>(Reasons.notStarted);
  final delta = s.first.start.difference(ps);
  final Punctuality p;
  if (delta.abs() <= grace) {
    p = Punctuality.onTime;
  } else if (delta.isNegative) {
    p = Punctuality.early;
  } else {
    p = Punctuality.late;
  }
  return Value<TimingDelta>(TimingDelta(delta, punctuality: p));
}

/// PL-T-05 — finish delay Δe = ae − pe (timer) or done_at − pe (check); on time if Δe ≤ g.
Stat<TimingDelta> finishDelay(PlannerOccurrenceFact f, {Duration grace = const Duration(minutes: 5)}) {
  final pe = f.plannedEnd;
  if (pe == null || f.isAllDay) {
    return const NotApplicable<TimingDelta>(Reasons.notScheduled);
  }
  final s = f.effectiveSessions;
  final DateTime? end;
  if (f.trackingMode == TrackingMode.timer && s.isNotEmpty) {
    end = s.map((x) => x.end).reduce((a, b) => a.isAfter(b) ? a : b);
  } else {
    end = f.doneAt ?? (s.isEmpty ? null : s.last.end);
  }
  if (end == null) return const NotApplicable<TimingDelta>(Reasons.notDone);
  final delta = end.difference(pe);
  return Value<TimingDelta>(TimingDelta(delta, punctuality: delta <= grace ? Punctuality.onTime : Punctuality.late));
}

/// Aging buckets 1 / 7 / 14 / 30+ days (PL-T-07, PL-X-06).
enum OverdueBucket { underOneDay, oneDay, sevenDays, fourteenDays, thirtyPlusDays }

OverdueBucket overdueBucketFor(Duration age) {
  final days = age.inHours / 24;
  if (days >= 30) return OverdueBucket.thirtyPlusDays;
  if (days >= 14) return OverdueBucket.fourteenDays;
  if (days >= 7) return OverdueBucket.sevenDays;
  if (days >= 1) return OverdueBucket.oneDay;
  return OverdueBucket.underOneDay;
}

/// PL-T-07 result.
@immutable
final class const OverdueAge(final Duration age, {required final OverdueBucket bucket});

bool _isOpen(PlannerOccurrenceFact f) =>
    f.status == PlannerOccurrenceStatus.scheduled ||
    f.status == PlannerOccurrenceStatus.inProgress ||
    f.status == PlannerOccurrenceStatus.missed;

/// PL-T-07 — overdue age of an open check/timer occurrence: now − pe, bucketed.
Stat<OverdueAge> overdueAge(PlannerOccurrenceFact f, {required DateTime now}) {
  final pe = f.plannedEnd;
  if (!f.trackingMode.countsForCompletion || !_isOpen(f) || pe == null || !now.isAfter(pe)) {
    return const NotApplicable<OverdueAge>('notOverdue');
  }
  final age = now.difference(pe);
  return Value<OverdueAge>(OverdueAge(age, bucket: overdueBucketFor(age)));
}

// ---------------------------------------------------------------------------------------------
// Per-occurrence planning & focus (T6.3.03)
// ---------------------------------------------------------------------------------------------

/// PL-T-08 — number of `rescheduled` events of this occurrence.
int rescheduleCount(PlannerOccurrenceFact f) => f.moves.length;

/// PL-T-09 — reschedule distance Σ |toStart − fromStart| (wall clock).
Duration rescheduleDistance(PlannerOccurrenceFact f) =>
    Duration(minutes: f.moves.fold<int>(0, (acc, m) => acc + m.deltaMinutes.abs()));

/// PL-T-10 — net drift = final ps − first planned ps (wall clock).
Duration netDrift(PlannerOccurrenceFact f) {
  final moves = f.sortedMoves;
  if (moves.isEmpty) return Duration.zero;
  final last = f.plannedStartLocal ?? moves.last.toStart;
  return Duration(minutes: moves.first.fromStart.minutesUntil(last));
}

/// PL-T-11 — "snowballing" badge when moved ≥ 3 times.
bool isSnowballing(PlannerOccurrenceFact f, {int threshold = 3}) => f.moves.length >= threshold;

/// PL-T-12 — lead time = done_at − task created_at.
Stat<Duration> leadTime(PlannerOccurrenceFact f) {
  final done = f.doneAt;
  if (done == null) return const NotApplicable<Duration>(Reasons.notDone);
  return Value<Duration>(done.difference(f.taskCreatedAt));
}

/// PL-T-13 — start latency = as − task created_at.
Stat<Duration> startLatency(PlannerOccurrenceFact f) {
  final s = f.effectiveSessions;
  if (s.isEmpty) return const NotApplicable<Duration>(Reasons.notStarted);
  return Value<Duration>(s.first.start.difference(f.taskCreatedAt));
}

/// PL-T-14 — planning horizon = first planned ps − task created_at (how far ahead it was planned),
/// in wall-clock time of [clock].
Stat<Duration> planningHorizon(PlannerOccurrenceFact f, {required ZoneClock clock}) {
  final first = f.firstPlannedStartLocal;
  if (first == null) return const NotApplicable<Duration>(Reasons.notScheduled);
  return Value<Duration>(Duration(minutes: clock.toLocal(f.taskCreatedAt).minutesUntil(first)));
}

/// PL-T-15 result: share of Da inside [ps, pe] and minutes spilled before/after.
@immutable
final class const SlotFit(
  final double fitShare, {
  required final Duration spilledBefore,
  required final Duration spilledAfter,
});

/// PL-T-15 — slot fit = overlap(sessions, [ps, pe]) / Da; minutes spilled before ps and after pe.
Stat<SlotFit> slotFit(PlannerOccurrenceFact f) {
  final ps = f.plannedStart;
  final pe = f.plannedEnd;
  if (ps == null || pe == null || f.isAllDay) {
    return const NotApplicable<SlotFit>(Reasons.notScheduled);
  }
  final s = f.effectiveSessions;
  if (s.isEmpty) return const NotApplicable<SlotFit>(Reasons.notTracked);
  final slot = InstantRange(ps, pe);
  var inside = Duration.zero;
  var before = Duration.zero;
  var after = Duration.zero;
  var total = Duration.zero;
  for (final x in s) {
    total += x.length;
    inside += slot.overlap(x.start, x.end);
    before += InstantRange(x.start, ps).overlap(x.start, x.end);
    after += InstantRange(pe, x.end).overlap(x.start, x.end);
  }
  if (total == Duration.zero) {
    return const NotApplicable<SlotFit>(Reasons.notTracked);
  }
  return Value<SlotFit>(
    SlotFit(inside.inMicroseconds / total.inMicroseconds, spilledBefore: before, spilledAfter: after),
  );
}

/// PL-T-16 result.
@immutable
final class const FocusSessions(
  final int count, {
  required final Duration total,
  required final Duration mean,
  required final int pauses,
  required final Duration longestBlock,
});

/// A block of merged sessions spanning [start]…[end]; [tracked] excludes the short gaps.
@immutable
final class const SessionBlock(
  final DateTime start,
  final DateTime end, {
  required final Duration tracked,
  final String? taskId,
}) {
  /// Tracked minutes (gaps excluded).
  double get minutes => tracked.inSeconds / 60;
}

/// Merges sessions separated by gaps shorter than [maxGap] (default 2 min) into blocks whose
/// length is the tracked time (a 50-min session, a 1-min gap and a 20-min session → one 70-min
/// block).
List<SessionBlock> mergeSessions(List<TimeSessionFact> sessions, {Duration maxGap = const Duration(minutes: 2)}) {
  final sorted = [...sessions]..sort((a, b) => a.start.compareTo(b.start));
  final blocks = <SessionBlock>[];
  for (final s in sorted) {
    if (blocks.isNotEmpty) {
      final last = blocks.last;
      if (s.start.difference(last.end) < maxGap) {
        blocks[blocks.length - 1] = SessionBlock(
          last.start,
          s.end.isAfter(last.end) ? s.end : last.end,
          tracked: last.tracked + s.length,
          taskId: last.taskId,
        );
        continue;
      }
    }
    blocks.add(SessionBlock(s.start, s.end, tracked: s.length, taskId: s.taskId));
  }
  return blocks;
}

/// PL-T-16 — focus sessions: count, total, mean length, pauses (gaps ≥ 2 min) and the longest
/// uninterrupted block (sessions separated by < 2 min merged).
Stat<FocusSessions> focusSessions(PlannerOccurrenceFact f) {
  final s = f.effectiveSessions;
  if (s.isEmpty) return const NotApplicable<FocusSessions>(Reasons.notTracked);
  final total = s.fold(Duration.zero, (acc, x) => acc + x.length);
  var pauses = 0;
  for (var i = 1; i < s.length; i++) {
    if (s[i].start.difference(s[i - 1].end) >= const Duration(minutes: 2)) {
      pauses++;
    }
  }
  final longest = mergeSessions(s).map((b) => b.tracked).reduce((a, b) => a > b ? a : b);
  return Value<FocusSessions>(
    FocusSessions(
      s.length,
      total: total,
      mean: Duration(microseconds: total.inMicroseconds ~/ s.length),
      pauses: pauses,
      longestBlock: longest,
    ),
    sampleSize: s.length,
  );
}

/// PL-T-17 — partial completion: completion_percent (0–1), or the linked checklist progress at done
/// time.
Stat<double> partialCompletion(PlannerOccurrenceFact f) {
  final pct = f.completionPercent;
  if (pct != null) return Value<double>(pct / 100);
  final linked = f.linkedChecklistProgress;
  if (linked != null) return Value<double>(linked);
  return const NotApplicable<double>(Reasons.noData);
}

/// PL-T-18 — self-rating (1–5) and outcome note.
({int? rating, String? note}) selfRating(PlannerOccurrenceFact f) => (rating: f.rating, note: f.outcomeNote);

// ---------------------------------------------------------------------------------------------
// Series execution (T6.3.04–T6.3.06)
// ---------------------------------------------------------------------------------------------

/// Ledger units of occurrences (check/timer only; `event` occurrences are excluded).
List<LedgerUnit> plannerLedgerUnits(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) => [
  for (final f in facts)
    if (f.trackingMode.countsForCompletion && f.plannedStart != null)
      LedgerUnit(
        f.occurrenceKey,
        start: f.plannedStart!,
        end: (f.plannedEnd ?? f.plannedStart!).add(settings.missedGrace),
        dueAt: (f.plannedEnd ?? f.plannedStart!).add(settings.grace),
        date: f.plannedDate,
        completedAt: f.doneAt,
        state: f.seriesPaused
            ? LedgerState.paused
            : switch (plannerOutcome(f, now: now, settings: settings)) {
                PlannerOutcome.doneOnTime || PlannerOutcome.doneLate => LedgerState.done,
                PlannerOutcome.partial => LedgerState.partial,
                PlannerOutcome.skipped => LedgerState.skipped,
                PlannerOutcome.missed => LedgerState.missed,
                PlannerOutcome.cancelled => LedgerState.cancelled,
                _ => LedgerState.open,
              },
      ),
];

/// PL-S-01…04 — the series ledger: E (closed/open), D/M/K/X, adherence D/(E − X), miss rate
/// (M + F)/(E − X). Group facts by `series_id` across "this & following" splits before calling.
Ledger seriesLedger(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) => buildLedger(
  plannerLedgerUnits(facts, now: now, settings: settings),
  now: now,
  skipPolicy: settings.skipPolicy,
);

/// Weekly adherence series with a rolling 4-week line and an OLS/Theil–Sen trend per week
/// (PL-S-03).
@immutable
final class const AdherenceTrend(
  final List<SeriesPoint<double?>> weekly, {
  required final List<double?> rolling4Weeks,
  required final Stat<TrendResult> trend,
});

/// PL-S-03 — adherence per week (buckets honour [weekStart]), rolling 4-week mean and trend.
AdherenceTrend seriesAdherenceTrend(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  required LocalDate from,
  required LocalDate to,
  required math.Random random,
  Weekday weekStart = Weekday.monday,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final ledger = seriesLedger(facts, now: now, settings: settings);
  final rows = <(LocalDate, num, num)>[];
  for (final e in ledger.entries) {
    final date = e.unit.date;
    if (date == null) continue;
    final excluded = switch (e.classification) {
      LedgerClass.excused || LedgerClass.cancelled || LedgerClass.pending || LedgerClass.future => true,
      LedgerClass.skipped => settings.skipPolicy == SkipPolicy.neutral,
      _ => false,
    };
    if (excluded) continue;
    rows.add((date, e.done, e.unit.weight));
  }
  final weekly = bucketRate(rows, from: from, to: to, granularity: Granularity.week, weekStart: weekStart);
  final values = [for (final p in weekly) p.value];
  return AdherenceTrend(
    weekly,
    rolling4Weeks: rollingMean(values, 4),
    trend: trend(values, bucketDays: 7, random: random),
  );
}

/// PL-S-05 / PL-S-13 — streaks with unit = occurrence; skips neutral per policy.
StreakSummary seriesStreaks(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final units = <StreakUnit>[];
  for (final f in facts) {
    final date = f.plannedDate;
    if (date == null || !f.trackingMode.countsForCompletion) continue;
    final o = f.seriesPaused ? null : plannerOutcome(f, now: now, settings: settings);
    units.add(
      StreakUnit(
        f.occurrenceKey,
        start: date,
        end: date,
        kind: switch (o) {
          null => StreakUnitKind.neutral,
          PlannerOutcome.doneOnTime || PlannerOutcome.doneLate => StreakUnitKind.success,
          PlannerOutcome.partial || PlannerOutcome.missed => StreakUnitKind.breaks,
          PlannerOutcome.skipped =>
            settings.skipPolicy == SkipPolicy.breaks ? StreakUnitKind.breaks : StreakUnitKind.neutral,
          PlannerOutcome.cancelled || PlannerOutcome.notTracked => StreakUnitKind.neutral,
          PlannerOutcome.pending || PlannerOutcome.future => StreakUnitKind.open,
        },
        freezable: o == PlannerOutcome.missed,
      ),
    );
  }
  return computeStreaks(units);
}

/// PL-S-06 — time invested: cumulative Σ Da (actual) and Σ Dp (planned) by planned date.
({List<(LocalDate, double)> actual, List<(LocalDate, double)> planned}) seriesTimeInvested(
  Iterable<PlannerOccurrenceFact> facts,
) {
  final actual = <LocalDate, double>{};
  final planned = <LocalDate, double>{};
  for (final f in facts) {
    final date = f.plannedDate;
    if (date == null || f.status == PlannerOccurrenceStatus.cancelled) continue;
    planned[date] = (planned[date] ?? 0) + (f.plannedMinutes ?? 0);
    actual[date] = (actual[date] ?? 0) + (f.actualMinutes ?? 0);
  }
  List<(LocalDate, double)> cumulate(Map<LocalDate, double> m) {
    final keys = m.keys.toList()..sort();
    var total = 0.0;
    return [for (final k in keys) (k, total += m[k]!)];
  }

  return (actual: cumulate(actual), planned: cumulate(planned));
}

/// PL-S-07 — all-time count of done occurrences (partial included as done).
int seriesTotalDone(Iterable<PlannerOccurrenceFact> facts) =>
    facts.where((f) => f.status == PlannerOccurrenceStatus.done).length;

/// PL-S-08 — date of the last done occurrence and days since then.
Stat<({LocalDate date, int daysSince})> seriesLastDone(
  Iterable<PlannerOccurrenceFact> facts, {
  required ZoneClock clock,
  required LocalDate today,
}) {
  DateTime? last;
  for (final f in facts) {
    final t = f.doneAt;
    if (f.status == PlannerOccurrenceStatus.done && t != null) {
      if (last == null || t.isAfter(last)) last = t;
    }
  }
  if (last == null) {
    return const NotApplicable<({LocalDate date, int daysSince})>(Reasons.noData);
  }
  final date = clock.toLocal(last).date;
  return Value((date: date, daysSince: date.daysUntil(today)));
}

/// Calendar cell of the series outcome calendar.
enum CalendarOutcome { done, late, partial, missed, skipped, excused, pending }

/// PL-S-09 — per-day outcome of the series (worst outcome wins when several occurrences share a
/// day: missed > partial > late > skipped > done > excused > pending).
Map<LocalDate, CalendarOutcome> seriesOutcomeCalendar(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  const rank = {
    CalendarOutcome.missed: 6,
    CalendarOutcome.partial: 5,
    CalendarOutcome.late: 4,
    CalendarOutcome.skipped: 3,
    CalendarOutcome.done: 2,
    CalendarOutcome.excused: 1,
    CalendarOutcome.pending: 0,
  };
  final result = <LocalDate, CalendarOutcome>{};
  for (final f in facts) {
    final date = f.plannedDate;
    if (date == null) continue;
    final o = plannerOutcome(f, now: now, settings: settings);
    final cell = switch (o) {
      PlannerOutcome.doneOnTime => CalendarOutcome.done,
      PlannerOutcome.doneLate => CalendarOutcome.late,
      PlannerOutcome.partial => CalendarOutcome.partial,
      PlannerOutcome.missed => CalendarOutcome.missed,
      PlannerOutcome.skipped => CalendarOutcome.skipped,
      PlannerOutcome.cancelled || PlannerOutcome.notTracked => CalendarOutcome.excused,
      PlannerOutcome.pending || PlannerOutcome.future => CalendarOutcome.pending,
    };
    final existing = result[date];
    if (existing == null || rank[cell]! > rank[existing]!) result[date] = cell;
  }
  return result;
}

/// PL-S-10 / PL-X-32 — skip rate K/E and the Pareto of skip reasons.
({Stat<double> rate, List<ParetoEntry> reasons}) skipRateAndReasons(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final list = [
    for (final f in facts)
      if (f.trackingMode.countsForCompletion && f.status != PlannerOccurrenceStatus.cancelled) f,
  ];
  final scheduled = list.where((f) {
    final o = plannerOutcome(f, now: now, settings: settings);
    return o != PlannerOutcome.future && o != PlannerOutcome.pending;
  }).toList();
  final skipped = scheduled.where((f) => f.status == PlannerOccurrenceStatus.skipped).toList();
  return (rate: rate(skipped.length, scheduled.length), reasons: pareto(skipped.map((f) => f.skipReason)));
}

/// Start-delay statistics (PL-S-11, PL-X-27, PL-X-28).
@immutable
final class const StartTimeliness(
  final Stat<double> onTimeRate, {
  required final Stat<double> meanDelayMinutes,
  required final Stat<double> medianDelayMinutes,
  required final Stat<double> p85DelayMinutes,
  required final int started,
});

/// PL-S-11 / PL-X-27 / PL-X-28 — on-time starts ÷ started; mean, median and P85 of Δs (minutes;
/// P85 hidden below 10 samples, means/medians below 3).
StartTimeliness startTimeliness(Iterable<PlannerOccurrenceFact> facts, {Duration grace = const Duration(minutes: 5)}) {
  final delays = <double>[];
  var onTime = 0;
  for (final f in facts) {
    final d = startDelay(f, grace: grace).valueOrNull;
    if (d == null) continue;
    delays.add(d.delta.inSeconds / 60);
    if (d.punctuality == Punctuality.onTime) onTime++;
  }
  return StartTimeliness(
    MinDataRules.rate.apply(rate(onTime, delays.length)),
    meanDelayMinutes: MinDataRules.meanOrMedian.apply(mean(delays)),
    medianDelayMinutes: MinDataRules.meanOrMedian.apply(median(delays)),
    p85DelayMinutes: MinDataRules.p85.apply(p85(delays)),
    started: delays.length,
  );
}

/// PL-S-11 box plots: start delays (minutes) per month of the planned date.
Map<LocalDate, Stat<BoxPlotSummary>> startDelayBoxPlotsByMonth(
  Iterable<PlannerOccurrenceFact> facts, {
  Duration grace = const Duration(minutes: 5),
}) {
  final byMonth = <LocalDate, List<double>>{};
  for (final f in facts) {
    final d = startDelay(f, grace: grace).valueOrNull;
    final date = f.plannedDate;
    if (d == null || date == null) continue;
    byMonth.putIfAbsent(date.firstDayOfMonth, () => []).add(d.delta.inSeconds / 60);
  }
  return {for (final e in byMonth.entries) e.key: boxPlot(e.value)};
}

/// PL-S-12 / PL-X-05 — on-time completion rate doneOnTime ÷ done (check/timer; partial excluded).
Stat<double> onTimeCompletionRate(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  var onTime = 0;
  var done = 0;
  for (final f in facts) {
    if (!f.trackingMode.countsForCompletion) continue;
    final o = plannerOutcome(f, now: now, settings: settings);
    if (o == PlannerOutcome.doneOnTime) onTime++;
    if (o == PlannerOutcome.doneOnTime || o == PlannerOutcome.doneLate) done++;
  }
  return rate(onTime, done);
}

/// PL-S-14 — series strength: Loop EWMA with f = expected occurrences per day ([frequency], e.g.
/// MO/WE/FR → 3/7; every 90 min in 08–20 → 9/1). Days run from the first occurrence to [today];
/// for f > 1 the credit is done ÷ expected per day. Skipped (neutral), cancelled and paused days
/// are not scored.
StrengthResult seriesStrength(
  Iterable<PlannerOccurrenceFact> facts, {
  required StrengthFrequency frequency,
  required LocalDate today,
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final done = <LocalDate, double>{};
  final expected = <LocalDate, double>{};
  final neutral = <LocalDate>{};
  LocalDate? first;
  for (final f in facts) {
    final date = f.plannedDate;
    if (date == null || !f.trackingMode.countsForCompletion || date.isAfter(today)) {
      continue;
    }
    if (first == null || date.isBefore(first)) first = date;
    final o = plannerOutcome(f, now: now, settings: settings);
    final isNeutral =
        f.seriesPaused ||
        o == PlannerOutcome.cancelled ||
        (o == PlannerOutcome.skipped && settings.skipPolicy == SkipPolicy.neutral);
    if (isNeutral) {
      neutral.add(date);
      continue;
    }
    expected[date] = (expected[date] ?? 0) + 1;
    if (o == PlannerOutcome.doneOnTime || o == PlannerOutcome.doneLate) {
      done[date] = (done[date] ?? 0) + 1;
    }
  }
  if (first == null) return const StrengthResult([], initialScore: 0);
  final days = [
    for (var d = first; !d.isAfter(today); d = d.plusDays(1))
      StrengthDay(
        d,
        value: done[d] ?? 0,
        frequency: frequency,
        skipped: neutral.contains(d) && !expected.containsKey(d),
        expectedInDay: expected[d] ?? math.max(1, frequency.f).toDouble(),
      ),
  ];
  return computeStrength(days);
}

/// PL-S-15 result.
@immutable
final class const DurationStability(
  final Stat<double> meanMinutes, {
  required final Stat<double> medianMinutes,
  required final Stat<double> sdMinutes,
  required final Stat<double> cv,
  required final Stat<double> medianRatio,
  required final Stat<BoxPlotSummary> boxPlot,
});

/// PL-S-15 — mean, median, SD, CV of Da; median R as the estimation bias ("usually takes 1.3×").
DurationStability durationStability(Iterable<PlannerOccurrenceFact> facts) {
  final da = [for (final f in facts) ?f.actualMinutes];
  final ratios = [for (final f in facts) ?durationRatio(f)];
  return DurationStability(
    MinDataRules.meanOrMedian.apply(mean(da)),
    medianMinutes: MinDataRules.meanOrMedian.apply(median(da)),
    sdMinutes: standardDeviation(da),
    cv: coefficientOfVariation(da),
    medianRatio: MinDataRules.meanOrMedian.apply(median(ratios)),
    boxPlot: boxPlot(da),
  );
}

/// PL-S-16 / PL-X-34 — adherence (D ÷ closed non-excused units) per weekday; weekdays the rule never
/// schedules are absent from the map.
Map<Weekday, Stat<double>> weekdayAdherence(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final done = <Weekday, int>{};
  final total = <Weekday, int>{};
  for (final f in facts) {
    final date = f.plannedDate;
    if (date == null || !f.trackingMode.countsForCompletion || f.seriesPaused) {
      continue;
    }
    final o = plannerOutcome(f, now: now, settings: settings);
    final excluded = switch (o) {
      PlannerOutcome.cancelled || PlannerOutcome.pending || PlannerOutcome.future || PlannerOutcome.notTracked => true,
      PlannerOutcome.skipped => settings.skipPolicy == SkipPolicy.neutral,
      _ => false,
    };
    final w = date.weekday;
    total.putIfAbsent(w, () => 0);
    if (excluded) continue;
    total[w] = total[w]! + 1;
    if (o == PlannerOutcome.doneOnTime || o == PlannerOutcome.doneLate) {
      done[w] = (done[w] ?? 0) + 1;
    }
  }
  return {for (final w in total.keys) w: rate(done[w] ?? 0, total[w]!)};
}

/// PL-S-17 — completion hour profile: done occurrences per local hour of done_at (or `as` when
/// [useStart]).
List<int> completionHourProfile(
  Iterable<PlannerOccurrenceFact> facts, {
  required ZoneClock clock,
  bool useStart = false,
}) {
  final hours = List<int>.filled(24, 0);
  for (final f in facts) {
    if (f.status != PlannerOccurrenceStatus.done) continue;
    final s = f.effectiveSessions;
    final t = useStart ? (s.isEmpty ? null : s.first.start) : f.doneAt;
    if (t == null) continue;
    hours[clock.toLocal(t).hour]++;
  }
  return hours;
}

/// PL-S-18 / PL-X-29 / PL-X-30 / PL-X-31 — reschedule behaviour.
@immutable
final class const RescheduleBehaviour(
  final int occurrences, {
  required final Stat<double> movedShare,
  required final Stat<double> meanMovesPerOccurrence,
  required final Stat<double> meanMovesPerMovedOccurrence,
  required final Stat<double> meanPostponeMinutes,
  required final double hoursPostponed,
  required final Stat<double> procrastinationIndex,
});

/// Reschedule behaviour over [facts]: share moved ≥ 1× (PL-X-29, earlier moves count), mean moves,
/// forward postponement only for hours postponed (PL-X-30), procrastination index = share whose
/// final ps > first planned ps (PL-X-31).
RescheduleBehaviour rescheduleBehaviour(Iterable<PlannerOccurrenceFact> facts) {
  final list = [
    for (final f in facts)
      if (f.status != PlannerOccurrenceStatus.cancelled) f,
  ];
  final moved = list.where((f) => f.moves.isNotEmpty).toList();
  final totalMoves = list.fold<int>(0, (a, f) => a + f.moves.length);
  final forward = [
    for (final f in list)
      for (final m in f.moves)
        if (m.deltaMinutes > 0) m.deltaMinutes.toDouble(),
  ];
  final procrastinated = moved.where((f) => netDrift(f) > Duration.zero).length;
  return RescheduleBehaviour(
    list.length,
    movedShare: rate(moved.length, list.length),
    meanMovesPerOccurrence: safeDivide(totalMoves, list.length),
    meanMovesPerMovedOccurrence: safeDivide(totalMoves, moved.length),
    meanPostponeMinutes: mean(forward),
    hoursPostponed: sum(forward) / 60,
    procrastinationIndex: rate(procrastinated, list.length),
  );
}

/// PL-S-19 — a rule-change marker with adherence before and after the change.
@immutable
final class const RuleChangeMarker(
  final LocalDate date, {
  required final Stat<double> adherenceBefore,
  required final Stat<double> adherenceAfter,
});

/// PL-S-19 — adherence in the [windowDays] before and after each split / rule change date.
List<RuleChangeMarker> ruleChangeMarkers(
  Iterable<PlannerOccurrenceFact> facts, {
  required List<LocalDate> changeDates,
  required DateTime now,
  int windowDays = 28,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final list = facts.toList();
  Stat<double> adherenceIn(LocalDate from, LocalDate to) => seriesLedger(
    list.where((f) {
      final d = f.plannedDate;
      return d != null && !d.isBefore(from) && !d.isAfter(to);
    }),
    now: now,
    settings: settings,
  ).adherence;
  return [
    for (final c in changeDates)
      RuleChangeMarker(
        c,
        adherenceBefore: adherenceIn(c.minusDays(windowDays), c.minusDays(1)),
        adherenceAfter: adherenceIn(c, c.plusDays(windowDays - 1)),
      ),
  ];
}

/// PL-S-20 — time-of-day consistency: circular mean/SD of `as` (or done_at when not tracked).
Stat<CircularSummary> seriesTimeOfDay(Iterable<PlannerOccurrenceFact> facts, {required ZoneClock clock}) {
  final minutes = <int>[];
  for (final f in facts) {
    final s = f.effectiveSessions;
    final t = s.isNotEmpty ? s.first.start : f.doneAt;
    if (t == null) continue;
    minutes.add(clock.toLocal(t).time.minuteOfDay);
  }
  return circularTimeSummary(minutes);
}

/// PL-S-21 — start drift: circular mean of signed (as − ps), wrapped to ±12 h (minutes).
Stat<double> seriesStartDrift(Iterable<PlannerOccurrenceFact> facts) => circularDrift([
  for (final f in facts)
    if (f.plannedStart != null && f.effectiveSessions.isNotEmpty)
      f.effectiveSessions.first.start.difference(f.plannedStart!).inSeconds / 60,
]);

// ---------------------------------------------------------------------------------------------
// Section execution & flow — plan snapshot (T6.3.07)
// ---------------------------------------------------------------------------------------------

/// Planned start of [f] as of instant [at]: the last move with occurred_at ≤ at, else the first
/// move's origin, else the final planned start.
LocalDateTime? snapshotStartAt(PlannerOccurrenceFact f, DateTime at) {
  final moves = f.sortedMoves;
  if (moves.isEmpty) return f.plannedStartLocal;
  RescheduleFact? last;
  for (final m in moves) {
    if (!m.occurredAt.isAfter(at)) last = m;
  }
  return last?.toStart ?? moves.first.fromStart;
}

/// The plan as it stood at the start of a period (TickTick's definition).
@immutable
final class const PlanSnapshot(
  final DateRange period, {
  required final List<PlannerOccurrenceFact> planned,
  required final List<PlannerOccurrenceFact> plannedDone,
  required final List<PlannerOccurrenceFact> unplanned,
  required final List<PlannerOccurrenceFact> movedOut,
  required final List<PlannerOccurrenceFact> movedIn,
}) {
  /// PL-X-01 — |planned(P) ∩ done in P| ÷ |planned(P)|.
  Stat<double> get completionRate => rate(plannedDone.length, planned.length);
}

/// Plan snapshot for [period] (local dates of [bounds]):
/// 1. candidates = occurrences currently in P plus those in P as of P.start that later moved out;
/// 2. each candidate's planned start as of P.start replays moves with occurred_at ≤ P.start;
/// 3. planned(P) = candidates whose snapshot start falls in P, excluding occurrences cancelled
///    before P.start and tasks created after P.start (reported as unplanned additions).
/// While the period is in progress ([now] inside it) only snapshot starts ≤ now count ("to date").
/// Only check/timer occurrences take part (events are excluded).
PlanSnapshot planSnapshot(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateRange period,
  required DayBoundaries bounds,
  required DateTime now,
}) {
  final pStart = bounds.startOf(period.start);
  final pEnd = bounds.endOf(period.end);
  final nowLocal = bounds.clock.toLocal(now);
  final planned = <PlannerOccurrenceFact>[];
  final done = <PlannerOccurrenceFact>[];
  final unplanned = <PlannerOccurrenceFact>[];
  final movedOut = <PlannerOccurrenceFact>[];
  final movedIn = <PlannerOccurrenceFact>[];
  for (final f in facts) {
    if (!f.trackingMode.countsForCompletion) continue;
    final finalStart = f.plannedStartLocal;
    final finalIn = finalStart != null && period.contains(finalStart.date);
    final createdAfter = f.taskCreatedAt.isAfter(pStart);
    if (createdAfter) {
      if (finalIn && f.status != PlannerOccurrenceStatus.cancelled) {
        unplanned.add(f);
      }
      continue;
    }
    final cancelledBefore = f.cancelledAt != null && !f.cancelledAt!.isAfter(pStart);
    if (cancelledBefore) continue;
    final snap = snapshotStartAt(f, pStart);
    final snapIn = snap != null && period.contains(snap.date);
    if (snapIn && (now.isBefore(pStart) || now.isAfter(pEnd) || !snap.isAfter(nowLocal))) {
      planned.add(f);
      final doneAt = f.doneAt;
      if (f.status == PlannerOccurrenceStatus.done &&
          doneAt != null &&
          !doneAt.isBefore(pStart) &&
          doneAt.isBefore(pEnd)) {
        done.add(f);
      }
      if (!finalIn) movedOut.add(f);
    } else if (!snapIn && finalIn) {
      movedIn.add(f);
    }
  }
  return PlanSnapshot(
    period,
    planned: planned,
    plannedDone: done,
    unplanned: unplanned,
    movedOut: movedOut,
    movedIn: movedIn,
  );
}

/// PL-X-02 — per-day planned (by snapshot date) and done (by done_at date) counts.
Map<LocalDate, ({int planned, int done})> donePlannedPerDay(PlanSnapshot snapshot, {required DayBoundaries bounds}) {
  final pStart = bounds.startOf(snapshot.period.start);
  final result = <LocalDate, ({int planned, int done})>{
    for (final d in snapshot.period.dates) d: (planned: 0, done: 0),
  };
  for (final f in snapshot.planned) {
    final day = snapshotStartAt(f, pStart)!.date;
    final cur = result[day]!;
    result[day] = (planned: cur.planned + 1, done: cur.done);
  }
  for (final f in snapshot.plannedDone) {
    final day = bounds.dateOf(f.doneAt!);
    final cur = result[day];
    if (cur != null) result[day] = (planned: cur.planned, done: cur.done + 1);
  }
  return result;
}

/// PL-X-04 — backlog flow per week: tasks created vs occurrences completed; open backlog =
/// unscheduled open tasks + open overdue occurrences.
({List<SeriesPoint<double>> created, List<SeriesPoint<double>> completed, int openBacklog}) backlogFlow({
  required Iterable<DateTime> taskCreatedAt,
  required Iterable<PlannerOccurrenceFact> facts,
  required int unscheduledOpenTasks,
  required DayBoundaries bounds,
  required DateRange range,
  required DateTime now,
  Weekday weekStart = Weekday.monday,
}) {
  final created = bucketSum(
    [for (final t in taskCreatedAt) (bounds.dateOf(t), 1)],
    from: range.start,
    to: range.end,
    granularity: Granularity.week,
    weekStart: weekStart,
  );
  final completed = bucketSum(
    [
      for (final f in facts)
        if (f.status == PlannerOccurrenceStatus.done && f.doneAt != null) (bounds.dateOf(f.doneAt!), 1),
    ],
    from: range.start,
    to: range.end,
    granularity: Granularity.week,
    weekStart: weekStart,
  );
  final overdue = facts.where((f) => overdueAge(f, now: now).hasValue).length;
  return (created: created, completed: completed, openBacklog: unscheduledOpenTasks + overdue);
}

/// PL-X-06 — overdue now.
@immutable
final class const OverdueSummary(
  final int count, {
  required final Map<OverdueBucket, int> byBucket,
  required final List<SeriesPoint<double>> newlyOverduePerWeek,
});

/// PL-X-06 — open overdue count, aging buckets and newly overdue occurrences per week (by pe).
OverdueSummary overdueNow(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  required DayBoundaries bounds,
  required DateRange range,
  Weekday weekStart = Weekday.monday,
}) {
  final buckets = {for (final b in OverdueBucket.values) b: 0};
  final newly = <(LocalDate, num)>[];
  var count = 0;
  for (final f in facts) {
    final age = overdueAge(f, now: now).valueOrNull;
    if (age == null) continue;
    count++;
    buckets[age.bucket] = buckets[age.bucket]! + 1;
    newly.add((bounds.dateOf(f.plannedEnd!), 1));
  }
  return OverdueSummary(
    count,
    byBucket: buckets,
    newlyOverduePerWeek: bucketSum(
      newly,
      from: range.start,
      to: range.end,
      granularity: Granularity.week,
      weekStart: weekStart,
    ),
  );
}

// ---------------------------------------------------------------------------------------------
// Capacity & utilization (T6.3.08)
// ---------------------------------------------------------------------------------------------

/// Minutes of [a, b) (minutes of day, possibly beyond 1440 for tasks crossing midnight) inside the
/// windows.
double _overlapWithWindows(double a, double b, List<LocalTimeWindow> windows) {
  var total = 0.0;
  for (final w in windows) {
    final s = math.max(a, w.startMinute.toDouble());
    final e = math.min(b, w.endMinute.toDouble());
    if (e > s) total += e - s;
  }
  return total;
}

/// Union length of intervals (minutes).
double _unionLength(List<(double, double)> intervals) {
  final sorted = [...intervals]..sort((x, y) => x.$1.compareTo(y.$1));
  var total = 0.0;
  double? curS;
  double? curE;
  for (final (s, e) in sorted) {
    if (curE == null || s > curE) {
      if (curS != null) total += curE! - curS;
      curS = s;
      curE = e;
    } else if (e > curE) {
      curE = e;
    }
  }
  if (curS != null) total += curE! - curS;
  return total;
}

/// One day of the capacity report.
@immutable
final class const CapacityDay(
  final LocalDate date, {
  required final double capacityMinutes,
  required final double plannedMinutes,
  required final double plannedClippedMinutes,
  required final double actualClippedMinutes,
  required final double actualMinutes,
}) {
  /// PL-X-10 — overbooked when L_d > cap_d. Days without capacity (days off) are never flagged.
  bool get overbooked => capacityMinutes > 0 && plannedMinutes > capacityMinutes + 1e-9;

  double get overbookedMinutes => math.max(0, plannedMinutes - capacityMinutes);
}

/// Capacity report over a range (PL-X-07 … PL-X-12).
@immutable
final class const CapacityReport(final List<CapacityDay> days, {required final double actualTimeCoverage}) {
  /// PL-X-07 — Σ cap_d.
  double get capacityMinutes => days.fold(0, (a, d) => a + d.capacityMinutes);

  double get plannedMinutes => days.fold(0, (a, d) => a + d.plannedMinutes);

  double get actualMinutes => days.fold(0, (a, d) => a + d.actualMinutes);

  /// PL-X-08 — Σ Dp (clipped to capacity windows) ÷ capacity (can exceed 100 % with overlaps).
  Stat<double> get plannedUtilization =>
      safeDivide(days.fold<double>(0, (a, d) => a + d.plannedClippedMinutes), capacityMinutes);

  /// PL-X-09 — Σ Da (clipped) ÷ capacity; insufficient when actual-time coverage < 60 %.
  Stat<double> get actualUtilization {
    if (actualTimeCoverage < 0.6) {
      return Insufficient<double>(0.6, actualTimeCoverage, 'lowActualTimeCoverage');
    }
    return safeDivide(days.fold<double>(0, (a, d) => a + d.actualClippedMinutes), capacityMinutes);
  }

  /// PL-X-10 — overbooked days.
  List<CapacityDay> get overbookedDays => [
    for (final d in days)
      if (d.overbooked) d,
  ];
}

List<LocalTimeWindow> _windowsFor(LocalDate date, PlannerStatsSettings settings) =>
    (settings.workHours.isEmpty ? defaultWorkHours : settings.workHours)[date.weekday] ?? const [];

bool _isUnavailable(PlannerOccurrenceFact f, PlannerStatsSettings s) =>
    f.trackingMode == TrackingMode.event && f.categoryId != null && s.unavailableCategoryIds.contains(f.categoryId);

/// Capacity per day: cap_d = window minutes of the capacity basis on that weekday minus
/// unavailable blocks (`event` tasks in unavailable categories, clipped to the windows).
/// Planned load L_d = Σ Dp of the day's timed occurrences (unclipped; overlaps counted separately;
/// all-day and unavailable blocks excluded). Actual minutes come from sessions by local start date.
CapacityReport capacityReport(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateRange range,
  required ZoneClock clock,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final list = [
    for (final f in facts)
      if (f.status != PlannerOccurrenceStatus.cancelled) f,
  ];
  final days = <CapacityDay>[];
  var doneCount = 0;
  var doneWithSessions = 0;
  for (final f in list) {
    final date = f.plannedDate;
    if (date == null || !range.contains(date)) continue;
    if (f.status == PlannerOccurrenceStatus.done) {
      doneCount++;
      if (f.hasActualTime) doneWithSessions++;
    }
  }
  for (final date in range.dates) {
    final windows = _windowsFor(date, settings);
    final windowMinutes = windows.fold<double>(0, (a, w) => a + w.minutes);
    final blocks = <(double, double)>[];
    var planned = 0.0;
    var clipped = 0.0;
    var actual = 0.0;
    var actualClipped = 0.0;
    for (final f in list) {
      final start = f.plannedStartLocal;
      if (f.isAllDay || start == null || start.date != date) continue;
      final a = start.time.minuteOfDay.toDouble();
      final b = a + (f.plannedMinutes ?? 0);
      if (_isUnavailable(f, settings)) {
        for (final w in windows) {
          final s = math.max(a, w.startMinute.toDouble());
          final e = math.min(b, w.endMinute.toDouble());
          if (e > s) blocks.add((s, e));
        }
        continue;
      }
      planned += b - a;
      clipped += _overlapWithWindows(a, b, windows);
    }
    for (final f in list) {
      for (final s in f.effectiveSessions) {
        final local = clock.toLocal(s.start);
        if (local.date != date) continue;
        final a = local.time.minuteOfDay.toDouble();
        final b = a + s.minutes;
        actual += s.minutes;
        actualClipped += _overlapWithWindows(a, b, windows);
      }
    }
    days.add(
      CapacityDay(
        date,
        capacityMinutes: math.max(0, windowMinutes - _unionLength(blocks)),
        plannedMinutes: planned,
        plannedClippedMinutes: clipped,
        actualClippedMinutes: actualClipped,
        actualMinutes: actual,
      ),
    );
  }
  return CapacityReport(days, actualTimeCoverage: doneCount == 0 ? 0 : doneWithSessions / doneCount);
}

/// PL-X-11 — remaining free time from [now] to the end of [range]: remaining capacity minus planned
/// remaining (both counted from now; minutes, floored at 0).
double remainingFreeMinutes(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateRange range,
  required DateTime now,
  required ZoneClock clock,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final nowLocal = clock.toLocal(now);
  var capacity = 0.0;
  var planned = 0.0;
  for (final date in range.dates) {
    if (date.isBefore(nowLocal.date)) continue;
    final from = date == nowLocal.date ? nowLocal.time.minuteOfDay.toDouble() : 0.0;
    final windows = _windowsFor(date, settings);
    capacity += _overlapWithWindows(from, 1440, windows);
    for (final f in facts) {
      final start = f.plannedStartLocal;
      if (f.isAllDay || start == null || start.date != date) continue;
      if (f.status == PlannerOccurrenceStatus.cancelled ||
          f.status == PlannerOccurrenceStatus.done ||
          f.status == PlannerOccurrenceStatus.skipped) {
        continue;
      }
      final a = math.max<double>(from, start.time.minuteOfDay.toDouble());
      final b = (start.time.minuteOfDay + (f.plannedMinutes ?? 0)).toDouble();
      if (b > a) planned += _overlapWithWindows(a, b, windows);
    }
  }
  return math.max(0, capacity - planned);
}

/// PL-X-12 — planned vs actual minutes per category (null key = uncategorized).
Map<String?, ({double planned, double actual})> plannedVsActualByCategory(Iterable<PlannerOccurrenceFact> facts) {
  final result = <String?, ({double planned, double actual})>{};
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final cur = result[f.categoryId] ?? (planned: 0.0, actual: 0.0);
    result[f.categoryId] = (
      planned: cur.planned + (f.plannedMinutes ?? 0),
      actual: cur.actual + (f.actualMinutes ?? 0),
    );
  }
  return result;
}

// ---------------------------------------------------------------------------------------------
// Time allocation (T6.3.09, T6.3.10)
// ---------------------------------------------------------------------------------------------

/// Share of one allocation key.
typedef AllocationSlice = ({String? key, double minutes, double share});

/// Actual-time coverage: done occurrences with sessions ÷ done occurrences (PL-X-41, T6.1.20).
Stat<double> actualTimeCoverage(Iterable<PlannerOccurrenceFact> facts) {
  final done = facts.where((f) => f.status == PlannerOccurrenceStatus.done).toList();
  return rate(done.where((f) => f.hasActualTime).length, done.length);
}

List<AllocationSlice> _slices(Map<String?, double> minutes) {
  final total = minutes.values.fold<double>(0, (a, b) => a + b);
  final slices = [
    for (final e in minutes.entries) (key: e.key, minutes: e.value, share: total == 0 ? 0.0 : e.value / total),
  ]..sort((a, b) => b.minutes.compareTo(a.minutes));
  return slices;
}

/// PL-X-13 — time by category: Σ Da by category, falling back to Σ Dp (`usedPlanned` = true, UI
/// label "planned") when actual-time coverage < 60 %. Uncategorized time is its own slice (null).
({List<AllocationSlice> slices, bool usedPlanned}) timeByCategory(Iterable<PlannerOccurrenceFact> facts) {
  final list = [
    for (final f in facts)
      if (f.status != PlannerOccurrenceStatus.cancelled) f,
  ];
  final coverage = actualTimeCoverage(list).valueOrNull ?? 0;
  final usePlanned = coverage < 0.6;
  final minutes = <String?, double>{};
  for (final f in list) {
    final m = usePlanned ? (f.plannedMinutes ?? 0) : (f.actualMinutes ?? 0);
    if (m == 0) continue;
    minutes[f.categoryId] = (minutes[f.categoryId] ?? 0) + m;
  }
  return (slices: _slices(minutes), usedPlanned: usePlanned);
}

/// PL-X-14 — weekly Σ minutes per category (actual when tracked, else planned).
Map<String?, List<SeriesPoint<double>>> categoryTrend(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateRange range,
  Weekday weekStart = Weekday.monday,
}) {
  final byCategory = <String?, List<(LocalDate, num)>>{};
  for (final f in facts) {
    final date = f.plannedDate;
    if (date == null || f.status == PlannerOccurrenceStatus.cancelled) continue;
    final m = f.actualMinutes ?? f.plannedMinutes ?? 0;
    byCategory.putIfAbsent(f.categoryId, () => []).add((date, m));
  }
  return {
    for (final e in byCategory.entries)
      e.key: bucketSum(e.value, from: range.start, to: range.end, granularity: Granularity.week, weekStart: weekStart),
  };
}

/// PL-X-15 — planned minutes of `event` vs `check`/`timer` occurrences.
({double event, double task}) eventVsTaskMinutes(Iterable<PlannerOccurrenceFact> facts) {
  var event = 0.0;
  var task = 0.0;
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final m = f.plannedMinutes ?? 0;
    if (f.trackingMode == TrackingMode.event) {
      event += m;
    } else {
      task += m;
    }
  }
  return (event: event, task: task);
}

double _minutesOf(PlannerOccurrenceFact f) => f.actualMinutes ?? f.plannedMinutes ?? 0;

/// PL-X-16 — Σ minutes per priority 0–4 (actual when tracked, else planned).
Map<int, double> timeByPriority(Iterable<PlannerOccurrenceFact> facts) {
  final result = {for (var p = 0; p <= 4; p++) p: 0.0};
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    result[f.priority.clamp(0, 4)] = result[f.priority.clamp(0, 4)]! + _minutesOf(f);
  }
  return result;
}

/// PL-X-17 — Σ minutes per tag (a multi-tag task counts fully for each tag); `overlapping` is true
/// whenever any task has more than one tag (the UI shows an "overlapping" note).
({Map<String, double> minutes, bool overlapping}) timeByTag(Iterable<PlannerOccurrenceFact> facts) {
  final result = <String, double>{};
  var overlapping = false;
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    if (f.tagIds.length > 1) overlapping = true;
    for (final t in f.tagIds) {
      result[t] = (result[t] ?? 0) + _minutesOf(f);
    }
  }
  return (minutes: result, overlapping: overlapping);
}

/// PL-X-18 — priority alignment: share of time and completion rate for high (3–4) vs low (0–2).
({Stat<double> highTimeShare, Stat<double> highCompletionRate, Stat<double> lowCompletionRate}) priorityAlignment(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  var highMinutes = 0.0;
  var totalMinutes = 0.0;
  final counts = {
    true: [0, 0],
    false: [0, 0],
  };
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final high = f.priority >= 3;
    final m = _minutesOf(f);
    totalMinutes += m;
    if (high) highMinutes += m;
    if (!f.trackingMode.countsForCompletion) continue;
    final o = plannerOutcome(f, now: now, settings: settings);
    if (o == PlannerOutcome.pending || o == PlannerOutcome.future || o == PlannerOutcome.skipped) {
      continue;
    }
    counts[high]![1]++;
    if (o == PlannerOutcome.doneOnTime || o == PlannerOutcome.doneLate) {
      counts[high]![0]++;
    }
  }
  return (
    highTimeShare: safeDivide(highMinutes, totalMinutes),
    highCompletionRate: rate(counts[true]![0], counts[true]![1]),
    lowCompletionRate: rate(counts[false]![0], counts[false]![1]),
  );
}

/// PL-X-19 — allocation treemap: category → task → minutes.
Map<String?, Map<String, double>> allocationTreemap(Iterable<PlannerOccurrenceFact> facts) {
  final result = <String?, Map<String, double>>{};
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final m = _minutesOf(f);
    if (m == 0) continue;
    final tasks = result.putIfAbsent(f.categoryId, () => {});
    tasks[f.taskId] = (tasks[f.taskId] ?? 0) + m;
  }
  return result;
}

/// PL-X-20 — recurring vs one-off: minutes and completions.
({double recurringMinutes, double oneOffMinutes, int recurringDone, int oneOffDone}) recurringVsOneOff(
  Iterable<PlannerOccurrenceFact> facts,
) {
  var rm = 0.0;
  var om = 0.0;
  var rd = 0;
  var od = 0;
  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final done = f.status == PlannerOccurrenceStatus.done ? 1 : 0;
    if (f.isRecurring) {
      rm += _minutesOf(f);
      rd += done;
    } else {
      om += _minutesOf(f);
      od += done;
    }
  }
  return (recurringMinutes: rm, oneOffMinutes: om, recurringDone: rd, oneOffDone: od);
}

// ---------------------------------------------------------------------------------------------
// Estimation accuracy (T6.3.11)
// ---------------------------------------------------------------------------------------------

/// Estimation accuracy (PL-X-21 … PL-X-23).
@immutable
final class const EstimationAccuracy(
  final int n, {
  required final Stat<double> bias,
  required final Stat<double> mape,
  required final Stat<double> suggestedBuffer,
});

/// Estimation accuracy over occurrences with a defined R (needs ≥ 10):
/// - PL-X-21 bias b = exp(median(ln R)) − 1 (> +5 % "underestimate", < −5 % "overestimate");
/// - PL-X-22 MAPE = mean(|Da − Dp| / Dp);
/// - PL-X-23 suggested buffer = P80(R) − 1.
EstimationAccuracy estimationAccuracy(Iterable<PlannerOccurrenceFact> facts) =>
    estimationAccuracyFromRatios([for (final f in facts) ?durationRatio(f)]);

/// [estimationAccuracy] from ratios R = Da/Dp directly.
EstimationAccuracy estimationAccuracyFromRatios(List<double> ratios) {
  final n = ratios.length;
  const rule = MinDataRules.estimation;
  return EstimationAccuracy(
    n,
    bias: rule.apply(estimationBias(ratios), haveN: n),
    mape: rule.apply(mean(ratios.map((r) => (r - 1).abs())), haveN: n),
    suggestedBuffer: rule.apply(p80(ratios).map((p) => p - 1), haveN: n),
  );
}

/// Bias wording of PL-X-21.
enum EstimationTendency { underestimate, overestimate, accurate }

EstimationTendency estimationTendency(double bias) {
  if (bias > 0.05) return EstimationTendency.underestimate;
  if (bias < -0.05) return EstimationTendency.overestimate;
  return EstimationTendency.accurate;
}

/// PL-X-24 — planned vs actual scatter points (Dp, Da) in minutes, with the ±20 % band flag.
List<({double planned, double actual, bool withinBand, String? categoryId})> plannedVsActualPoints(
  Iterable<PlannerOccurrenceFact> facts,
) => [
  for (final f in facts)
    if (f.plannedMinutes case final dp? when dp > 0)
      if (f.actualMinutes case final da?)
        (planned: dp, actual: da, withinBand: (da - dp).abs() <= 0.2 * dp, categoryId: f.categoryId),
];

/// PL-X-25 — planned duration distribution: Freedman–Diaconis histogram, mean and median of Dp.
({Histogram histogram, Stat<double> mean, Stat<double> median}) plannedDurationDistribution(
  Iterable<PlannerOccurrenceFact> facts,
) {
  final dp = [
    for (final f in facts)
      if (f.status != PlannerOccurrenceStatus.cancelled) ?f.plannedMinutes,
  ];
  return (histogram: histogramFreedmanDiaconis(dp), mean: mean(dp), median: median(dp));
}

/// PL-X-26 — bias and MAPE per category.
Map<String?, EstimationAccuracy> estimationByCategory(Iterable<PlannerOccurrenceFact> facts) {
  final byCategory = <String?, List<double>>{};
  for (final f in facts) {
    final r = durationRatio(f);
    if (r != null) byCategory.putIfAbsent(f.categoryId, () => []).add(r);
  }
  return {for (final e in byCategory.entries) e.key: estimationAccuracyFromRatios(e.value)};
}

// ---------------------------------------------------------------------------------------------
// Punctuality & patterns (T6.3.12, T6.3.13)
// ---------------------------------------------------------------------------------------------

/// PL-X-28 — start delay by (weekday, hour of ps): mean delay in minutes.
Map<(Weekday, int), double> startDelayPunchCard(
  Iterable<PlannerOccurrenceFact> facts, {
  Duration grace = const Duration(minutes: 5),
}) {
  final sums = <(Weekday, int), double>{};
  final counts = <(Weekday, int), int>{};
  for (final f in facts) {
    final d = startDelay(f, grace: grace).valueOrNull;
    final ps = f.plannedStartLocal;
    if (d == null || ps == null) continue;
    final key = (ps.date.weekday, ps.hour);
    sums[key] = (sums[key] ?? 0) + d.delta.inSeconds / 60;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return {for (final k in sums.keys) k: sums[k]! / counts[k]!};
}

/// What the busiest-hours matrix measures (PL-X-33 toggle).
enum BusyMeasure { plannedMinutes, actualMinutes, completions }

/// PL-X-33 — 7 × 24 matrix (weekday → 24 hours) of planned minutes, actual minutes or completions.
/// Minutes are split across the hours they cover.
Map<Weekday, List<double>> busiestHours(
  Iterable<PlannerOccurrenceFact> facts, {
  required BusyMeasure measure,
  required ZoneClock clock,
}) {
  final matrix = {for (final w in Weekday.values) w: List<double>.filled(24, 0)};
  void spread(LocalDateTime start, double minutes) {
    var cursor = start;
    var left = minutes;
    while (left > 1e-9) {
      final toNextHour = 60 - cursor.minute;
      final chunk = math.min(left, toNextHour.toDouble());
      matrix[cursor.date.weekday]![cursor.hour] += chunk;
      left -= chunk;
      cursor = cursor.plusMinutes(toNextHour);
    }
  }

  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    switch (measure) {
      case BusyMeasure.plannedMinutes:
        final ps = f.plannedStartLocal;
        if (ps != null && !f.isAllDay) spread(ps, f.plannedMinutes ?? 0);
      case BusyMeasure.actualMinutes:
        for (final s in f.effectiveSessions) {
          spread(clock.toLocal(s.start), s.minutes);
        }
      case BusyMeasure.completions:
        final t = f.doneAt;
        if (f.status == PlannerOccurrenceStatus.done && t != null) {
          final l = clock.toLocal(t);
          matrix[l.date.weekday]![l.hour] += 1;
        }
    }
  }
  return matrix;
}

/// PL-X-34 — best working days: completion rate and actual hours per weekday.
Map<Weekday, ({Stat<double> completionRate, double hours})> bestWorkingDays(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final list = facts.toList();
  final rates = weekdayAdherence(list, now: now, settings: settings);
  final hours = <Weekday, double>{};
  for (final f in list) {
    final date = f.plannedDate;
    if (date == null) continue;
    hours[date.weekday] = (hours[date.weekday] ?? 0) + (f.actualMinutes ?? 0) / 60;
  }
  return {
    for (final w in Weekday.values)
      if (rates.containsKey(w) || hours.containsKey(w))
        w: (completionRate: rates[w] ?? const NotApplicable<double>(Reasons.zeroDenominator), hours: hours[w] ?? 0),
  };
}

/// One slot of the slot-occupancy matrix.
@immutable
final class const SlotOccupancy(
  final Weekday weekday,
  final int slotStartMinute, {
  required final double plannedShare,
  required final double usedShare,
  required final int weeks,
});

/// PL-X-35 — slot occupancy per (weekday, slot of [slotMinutes]): planned% = weeks with a planned
/// task overlapping the slot ÷ weeks in P; used% likewise with sessions. Recomputable for any slot
/// size without reloading data.
List<SlotOccupancy> slotOccupancy(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateRange range,
  required int slotMinutes,
  required ZoneClock clock,
  Weekday weekStart = Weekday.monday,
}) {
  final slots = (1440 / slotMinutes).ceil();
  final plannedWeeks = <(Weekday, int), Set<LocalDate>>{};
  final usedWeeks = <(Weekday, int), Set<LocalDate>>{};
  void mark(Map<(Weekday, int), Set<LocalDate>> target, LocalDateTime start, double minutes) {
    if (!range.contains(start.date)) return;
    final a = start.time.minuteOfDay.toDouble();
    final b = a + minutes;
    for (var i = 0; i < slots; i++) {
      final s = (i * slotMinutes).toDouble();
      final e = math.min(1440, (i + 1) * slotMinutes).toDouble();
      if (math.min(b, e) > math.max(a, s)) {
        target.putIfAbsent((start.date.weekday, i * slotMinutes), () => {}).add(start.date.startOfWeek(weekStart));
      }
    }
  }

  for (final f in facts) {
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final ps = f.plannedStartLocal;
    if (ps != null && !f.isAllDay) {
      mark(plannedWeeks, ps, f.plannedMinutes ?? 0);
    }
    for (final s in f.effectiveSessions) {
      mark(usedWeeks, clock.toLocal(s.start), s.minutes);
    }
  }
  final weeks = {for (final d in range.dates) d.startOfWeek(weekStart)}.length;
  return [
    for (final w in Weekday.ordered(weekStart))
      for (var i = 0; i < slots; i++)
        SlotOccupancy(
          w,
          i * slotMinutes,
          plannedShare: weeks == 0 ? 0 : (plannedWeeks[(w, i * slotMinutes)]?.length ?? 0) / weeks,
          usedShare: weeks == 0 ? 0 : (usedWeeks[(w, i * slotMinutes)]?.length ?? 0) / weeks,
          weeks: weeks,
        ),
  ];
}

/// PL-X-36 — dead slots: slots inside work hours with planned% = 0 over ≥ [minWeeks] weeks.
List<SlotOccupancy> deadSlots(
  List<SlotOccupancy> occupancy, {
  required int slotMinutes,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
  int minWeeks = 4,
}) {
  final workHours = settings.workHours.isEmpty ? defaultWorkHours : settings.workHours;
  return [
    for (final o in occupancy)
      if (o.weeks >= minWeeks &&
          o.plannedShare == 0 &&
          (workHours[o.weekday] ?? const []).any(
            (w) => o.slotStartMinute >= w.startMinute && o.slotStartMinute + slotMinutes <= w.endMinute,
          ))
        o,
  ];
}

/// PL-X-37 — completion rate by the hour of ps (0–23).
Map<int, Stat<double>> completionRateByHour(
  Iterable<PlannerOccurrenceFact> facts, {
  required DateTime now,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final done = <int, int>{};
  final total = <int, int>{};
  for (final f in facts) {
    final ps = f.plannedStartLocal;
    if (ps == null || f.isAllDay || !f.trackingMode.countsForCompletion) {
      continue;
    }
    final o = plannerOutcome(f, now: now, settings: settings);
    if (o == PlannerOutcome.cancelled ||
        o == PlannerOutcome.pending ||
        o == PlannerOutcome.future ||
        (o == PlannerOutcome.skipped && settings.skipPolicy == SkipPolicy.neutral)) {
      continue;
    }
    total[ps.hour] = (total[ps.hour] ?? 0) + 1;
    if (o == PlannerOutcome.doneOnTime || o == PlannerOutcome.doneLate) {
      done[ps.hour] = (done[ps.hour] ?? 0) + 1;
    }
  }
  return {for (final h in total.keys) h: rate(done[h] ?? 0, total[h]!)};
}

// ---------------------------------------------------------------------------------------------
// Focus & balance (T6.3.14) and goal streak (T6.3.15)
// ---------------------------------------------------------------------------------------------

/// PL-X-38 — deep-work blocks: uninterrupted actual blocks ≥ `deepWorkMinutes` (default 60);
/// same-task sessions with gaps < 2 min are merged.
List<SessionBlock> deepWorkBlocks(
  Iterable<PlannerOccurrenceFact> facts, {
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final byTask = <String, List<TimeSessionFact>>{};
  for (final f in facts) {
    byTask.putIfAbsent(f.taskId, () => []).addAll(f.effectiveSessions);
  }
  final blocks = <SessionBlock>[];
  for (final e in byTask.entries) {
    for (final b in mergeSessions(e.value)) {
      if (b.minutes >= settings.deepWorkMinutes) {
        blocks.add(SessionBlock(b.start, b.end, tracked: b.tracked, taskId: e.key));
      }
    }
  }
  return blocks..sort((a, b) => a.start.compareTo(b.start));
}

/// PL-X-39 — after-hours minutes (Σ Da outside work hours) and weekend work minutes.
({double afterHoursMinutes, double weekendMinutes}) afterHours(
  Iterable<PlannerOccurrenceFact> facts, {
  required ZoneClock clock,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  var outside = 0.0;
  var weekend = 0.0;
  for (final f in facts) {
    for (final s in f.effectiveSessions) {
      final local = clock.toLocal(s.start);
      final a = local.time.minuteOfDay.toDouble();
      final b = a + s.minutes;
      outside += s.minutes - _overlapWithWindows(a, b, _windowsFor(local.date, settings));
      if (local.date.weekday.isWeekend) weekend += s.minutes;
    }
  }
  return (afterHoursMinutes: outside, weekendMinutes: weekend);
}

/// PL-X-40 — timer usage: timed sessions count, mean session length and the share of done
/// occurrences with sessions.
({int sessions, Stat<double> meanSessionMinutes, Stat<double> doneWithSessionsShare}) timerUsage(
  Iterable<PlannerOccurrenceFact> facts,
) {
  final list = facts.toList();
  final lengths = [
    for (final f in list)
      for (final s in f.sessions) s.minutes,
  ];
  return (sessions: lengths.length, meanSessionMinutes: mean(lengths), doneWithSessionsShare: actualTimeCoverage(list));
}

/// PL-X-42 — completion goal streak: consecutive days reaching [target] completions; days
/// without capacity ([isDayOff]) and vacation days are neutral; today is open.
StreakSummary completionGoalStreak(
  Iterable<PlannerOccurrenceFact> facts, {
  required int target,
  required DateRange range,
  required DayBoundaries bounds,
  required LocalDate today,
  bool Function(LocalDate date)? isDayOff,
}) {
  final counts = <LocalDate, int>{};
  for (final f in facts) {
    final t = f.doneAt;
    if (f.status != PlannerOccurrenceStatus.done || t == null) continue;
    final d = bounds.dateOf(t);
    counts[d] = (counts[d] ?? 0) + 1;
  }
  return computeStreaks([
    for (final d in range.dates)
      StreakUnit(
        d.toIso(),
        start: d,
        end: d,
        kind: (counts[d] ?? 0) >= target
            ? StreakUnitKind.success
            : (isDayOff?.call(d) ?? false)
            ? StreakUnitKind.neutral
            : (d == today ? StreakUnitKind.open : StreakUnitKind.breaks),
      ),
  ]);
}

// ---------------------------------------------------------------------------------------------
// Advanced (T6.3.16)
// ---------------------------------------------------------------------------------------------

/// PL-X-43 result.
@immutable
final class const Fragmentation(
  final double index, {
  required final double freeMinutes,
  required final double largestFreeBlock,
  required final int gapsOver15,
  required final Stat<double> meanGapOver15,
});

/// PL-X-43 — fragmentation within work hours of [date]: free gaps = work hours minus planned
/// blocks; index = 1 − largest free block ÷ total free time (0 for a single free block); count and
/// mean length of gaps ≥ 15 min.
Stat<Fragmentation> fragmentation(
  Iterable<PlannerOccurrenceFact> facts, {
  required LocalDate date,
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final windows = _windowsFor(date, settings);
  if (windows.isEmpty) return const NotApplicable<Fragmentation>('noCapacity');
  final busy = <(double, double)>[];
  for (final f in facts) {
    final ps = f.plannedStartLocal;
    if (ps == null || f.isAllDay || ps.date != date) continue;
    if (f.status == PlannerOccurrenceStatus.cancelled) continue;
    final a = ps.time.minuteOfDay.toDouble();
    busy.add((a, a + (f.plannedMinutes ?? 0)));
  }
  busy.sort((x, y) => x.$1.compareTo(y.$1));
  final gaps = <double>[];
  for (final w in windows) {
    var cursor = w.startMinute.toDouble();
    for (final (s, e) in busy) {
      if (e <= cursor) continue;
      if (s >= w.endMinute) break;
      if (s > cursor) gaps.add(math.min(s, w.endMinute.toDouble()) - cursor);
      cursor = math.max(cursor, e);
    }
    if (cursor < w.endMinute) gaps.add(w.endMinute - cursor);
  }
  final free = gaps.fold<double>(0, (a, b) => a + b);
  if (free == 0) return const NotApplicable<Fragmentation>('noFreeTime');
  final largest = gaps.reduce(math.max);
  final big = [
    for (final g in gaps)
      if (g >= 15) g,
  ];
  return Value<Fragmentation>(
    Fragmentation(
      1 - largest / free,
      freeMinutes: free,
      largestFreeBlock: largest,
      gapsOver15: big.length,
      meanGapOver15: mean(big),
    ),
  );
}

/// PL-X-44 — context switches per local day (category changes between consecutive sessions) and
/// switches per tracked hour.
({Map<LocalDate, int> perDay, Stat<double> perTrackedHour}) contextSwitches(
  Iterable<PlannerOccurrenceFact> facts, {
  required ZoneClock clock,
}) {
  final sessions = <TimeSessionFact>[];
  for (final f in facts) {
    for (final s in f.effectiveSessions) {
      sessions.add(TimeSessionFact(s.start, s.end, taskId: f.taskId, categoryId: s.categoryId ?? f.categoryId));
    }
  }
  sessions.sort((a, b) => a.start.compareTo(b.start));
  final perDay = <LocalDate, int>{};
  var minutes = 0.0;
  for (var i = 0; i < sessions.length; i++) {
    minutes += sessions[i].minutes;
    final day = clock.toLocal(sessions[i].start).date;
    perDay.putIfAbsent(day, () => 0);
    if (i > 0 &&
        clock.toLocal(sessions[i - 1].start).date == day &&
        sessions[i - 1].categoryId != sessions[i].categoryId) {
      perDay[day] = perDay[day]! + 1;
    }
  }
  final total = perDay.values.fold<int>(0, (a, b) => a + b);
  return (perDay: perDay, perTrackedHour: safeDivide(total, minutes / 60));
}

/// PL-X-45 — productivity score 100·Σ_c(w_c·minutes_c) / (4·Σ_c minutes_c), user weights
/// w_c ∈ {0…4}; unweighted categories are excluded; hidden until one category is weighted.
Stat<double> productivityScore(
  Iterable<PlannerOccurrenceFact> facts, {
  PlannerStatsSettings settings = const PlannerStatsSettings(),
}) {
  final weights = settings.categoryWeights;
  if (weights.isEmpty) return const NotApplicable<double>('noCategoryWeights');
  var weighted = 0.0;
  var total = 0.0;
  for (final f in facts) {
    final w = weights[f.categoryId];
    if (w == null || f.status == PlannerOccurrenceStatus.cancelled) continue;
    final m = _minutesOf(f);
    weighted += w.clamp(0, 4) * m;
    total += m;
  }
  return safeDivide(100 * weighted, 4 * total);
}

/// PL-X-46 — planning horizon distribution (hours between task creation and the first planned
/// start), as a Freedman–Diaconis histogram.
Histogram planningHorizonDistribution(Iterable<PlannerOccurrenceFact> facts, {required ZoneClock clock}) =>
    histogramFreedmanDiaconis([
      for (final f in facts)
        if (planningHorizon(f, clock: clock).valueOrNull case final h?) h.inMinutes / 60,
    ]);
