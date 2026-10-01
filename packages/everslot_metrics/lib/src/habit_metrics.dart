/// Habit Insights calculators ([6.5]): per-habit metrics (HB-H-*) and Habits section metrics
/// (HB-X-*), computed from [PeriodResult]s (the [5.1] period evaluation — never re-evaluated here)
/// and `habit_logs`.
///
/// Notation: E = closed scheduled units; X = excused + paused units, plus skipped units when the
/// skip policy is `neutral`; S = done, P = partial, F = failed, M = missed (frozen units count as
/// misses for rates but are neutral for streaks). Success rate = S ÷ (E − X). v_u = achieved value,
/// t_u = target of the unit's revision, fulfilment = min(1, v_u/t_u) (limits use the Loop credit).
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/circular.dart';
import 'package:everslot_metrics/src/correlation.dart';
import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/goals.dart';
import 'package:everslot_metrics/src/group_tests.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/min_data.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/quit_calculator.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/streaks.dart';
import 'package:everslot_metrics/src/strength.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:meta/meta.dart';

/// `HabitUnitFact` of [6.5] T6.5.01 — the [5.1] period result (key, window, status, value, target,
/// revision, logs).
typedef HabitUnitFact = PeriodResult;

/// Whether a unit is excluded from rate denominators (X).
bool isExcludedUnit(PeriodResult r, {SkipPolicy skipPolicy = SkipPolicy.neutral}) =>
    r.status == PeriodStatus.excused ||
    r.status == PeriodStatus.paused ||
    r.status == PeriodStatus.notDue ||
    (r.status == PeriodStatus.skipped && skipPolicy == SkipPolicy.neutral);

/// Closed scheduled units (E): everything but `not_due` and `pending`.
bool isClosedScheduled(PeriodResult r) => r.status != PeriodStatus.notDue && r.status != PeriodStatus.pending;

Iterable<PeriodResult> _inRange(Iterable<PeriodResult> results, LocalDate? from, LocalDate? to) =>
    results.where((r) => (from == null || !r.endDate.isBefore(from)) && (to == null || !r.startDate.isAfter(to)));

/// Per-day aggregate (`HabitDayFact`, T6.5.01).
@immutable
final class const HabitDayFact(
  final LocalDate localDate, {
  required final int dueUnits,
  required final int doneUnits,
  required final double value,
  required final bool neutral,
  final DateTime? firstLogAt,
  final DateTime? lastLogAt,
  final double? mood,
});

/// Builds day facts from day/slot results (quota periods contribute their logs per day).
List<HabitDayFact> habitDayFacts(Iterable<PeriodResult> results, {SkipPolicy skipPolicy = SkipPolicy.neutral}) {
  final due = <LocalDate, int>{};
  final done = <LocalDate, int>{};
  final value = <LocalDate, double>{};
  final neutral = <LocalDate, bool>{};
  final first = <LocalDate, DateTime>{};
  final last = <LocalDate, DateTime>{};
  final moods = <LocalDate, List<int>>{};
  for (final r in results) {
    final logs = r.entries;
    if (r.kind == HabitPeriodKind.quota) {
      for (final l in logs) {
        final day = l.localDate;
        if (l.kind == HabitLogKind.progress) {
          value[day] = (value[day] ?? 0) + (l.value ?? 0);
        }
        if (l.kind == HabitLogKind.done || l.kind == HabitLogKind.progress) {
          done[day] = 1;
          due.putIfAbsent(day, () => 1);
        }
      }
    } else {
      final day = r.startDate;
      final isNeutral = isExcludedUnit(r, skipPolicy: skipPolicy) || r.status == PeriodStatus.frozen;
      neutral[day] = (neutral[day] ?? true) && isNeutral;
      if (!isNeutral) due[day] = (due[day] ?? 0) + 1;
      if (r.status == PeriodStatus.done) done[day] = (done[day] ?? 0) + 1;
      value[day] = (value[day] ?? 0) + r.achieved;
    }
    for (final l in logs) {
      final day = r.kind == HabitPeriodKind.quota ? l.localDate : r.startDate;
      if (first[day] == null || l.loggedAt.isBefore(first[day]!)) {
        first[day] = l.loggedAt;
      }
      if (last[day] == null || l.loggedAt.isAfter(last[day]!)) {
        last[day] = l.loggedAt;
      }
      if (l.mood != null) moods.putIfAbsent(day, () => []).add(l.mood!);
    }
  }
  final dates = {...due.keys, ...done.keys, ...value.keys, ...neutral.keys}.toList()..sort();
  return [
    for (final day in dates)
      HabitDayFact(
        day,
        dueUnits: due[day] ?? 0,
        doneUnits: done[day] ?? 0,
        value: value[day] ?? 0,
        neutral: (neutral[day] ?? false) && (due[day] ?? 0) == 0,
        firstLogAt: first[day],
        lastLogAt: last[day],
        mood: moods[day] == null ? null : sum(moods[day]!) / moods[day]!.length,
      ),
  ];
}

// ---------------------------------------------------------------------------------------------
// Strength, streaks, success (T6.5.02–T6.5.04)
// ---------------------------------------------------------------------------------------------

/// HB-H-01 — strength score (Loop EWMA) from day facts, day by day from the first day to [today].
/// [frequencyOn] gives the rule frequency in force on a date (m switches when f changes at a
/// revision); [targetOn] the numeric target per frequency window. Neutral days (skipped under the
/// neutral policy, excused, paused, frozen) are not scored; days without units score as NO.
StrengthResult habitStrength(
  List<HabitDayFact> days, {
  required LocalDate today,
  required StrengthFrequency Function(LocalDate date) frequencyOn,
  StrengthGoalKind kind = StrengthGoalKind.boolean,
  double? Function(LocalDate date)? targetOn,
}) {
  if (days.isEmpty) {
    return StrengthResult(const [], initialScore: kind == StrengthGoalKind.atMost ? 1 : 0);
  }
  final byDate = {for (final d in days) d.localDate: d};
  final first = days.map((d) => d.localDate).reduce((a, b) => a.isBefore(b) ? a : b);
  return computeStrength([
    for (var d = first; !d.isAfter(today); d = d.plusDays(1))
      () {
        final f = byDate[d];
        final freq = frequencyOn(d);
        return StrengthDay(
          d,
          value: f == null ? 0 : (kind == StrengthGoalKind.boolean ? f.doneUnits.toDouble() : f.value),
          frequency: freq,
          skipped: f?.neutral ?? false,
          target: targetOn?.call(d),
          expectedInDay: freq.f > 1 ? math.max(1, f?.dueUnits ?? freq.f).toDouble() : 1,
        );
      }(),
  ], kind: kind);
}

/// HB-H-02…04 — streaks (current, best, top-10), with freezes per month.
StreakSummary habitStreaks(
  Iterable<PeriodResult> results, {
  SkipPolicy skipPolicy = SkipPolicy.neutral,
  int freezesPerMonth = 0,
}) => computeStreaks(streakUnitsFromPeriods(results, skipPolicy: skipPolicy), freezesPerMonth: freezesPerMonth);

/// HB-H-05 — success rate S ÷ (E − X) over [from]…[to] (all time when null), with a Wilson interval
/// (shown below 20 units).
Stat<double> successRate(
  Iterable<PeriodResult> results, {
  LocalDate? from,
  LocalDate? to,
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  var s = 0;
  var n = 0;
  for (final r in _inRange(results, from, to)) {
    if (!isClosedScheduled(r) || isExcludedUnit(r, skipPolicy: skipPolicy)) {
      continue;
    }
    n++;
    if (r.status == PeriodStatus.done) s++;
  }
  return rate(s, n);
}

/// HB-H-06 — outcome counts.
@immutable
final class const OutcomeCounts({
  required final int success,
  required final int partial,
  required final int failed,
  required final int missed,
  required final int skipped,
  required final int excused,
  required final int frozen,
  required final int paused,
  required final int total,
});

/// HB-H-06 — success / partial / failed / missed / skipped / excused / total (closed scheduled
/// units; missed and failed are kept apart).
OutcomeCounts outcomeCounts(Iterable<PeriodResult> results, {LocalDate? from, LocalDate? to}) {
  final c = {for (final s in PeriodStatus.values) s: 0};
  for (final r in _inRange(results, from, to)) {
    if (!isClosedScheduled(r)) continue;
    c[r.status] = c[r.status]! + 1;
  }
  return OutcomeCounts(
    success: c[PeriodStatus.done]!,
    partial: c[PeriodStatus.partial]!,
    failed: c[PeriodStatus.failed]!,
    missed: c[PeriodStatus.missed]!,
    skipped: c[PeriodStatus.skipped]!,
    excused: c[PeriodStatus.excused]!,
    frozen: c[PeriodStatus.frozen]!,
    paused: c[PeriodStatus.paused]!,
    total: c.values.fold(0, (a, b) => a + b),
  );
}

/// HB-H-07 — successes and volume per bucket (week/month/quarter/year).
({List<SeriesPoint<double>> successes, List<SeriesPoint<double>> volume}) historyBuckets(
  Iterable<PeriodResult> results, {
  required LocalDate from,
  required LocalDate to,
  required Granularity granularity,
  Weekday weekStart = Weekday.monday,
}) {
  final list = results.toList();
  return (
    successes: bucketSum(
      [
        for (final r in list)
          if (r.status == PeriodStatus.done) (r.endDate, 1),
      ],
      from: from,
      to: to,
      granularity: granularity,
      weekStart: weekStart,
    ),
    volume: bucketSum(
      [for (final r in list) (r.startDate, r.achieved)],
      from: from,
      to: to,
      granularity: granularity,
      weekStart: weekStart,
    ),
  );
}

/// HB-H-08 — per-day status for calendar grids (slot habits pass their day roll-ups).
Map<LocalDate, PeriodStatus> habitCalendar(Iterable<PeriodResult> results) => {
  for (final r in results)
    if (r.kind != HabitPeriodKind.quota) r.startDate: r.status,
};

/// HB-H-09 — total repetitions: manual `done`/`progress` logs (source ≠ auto) — "votes for your
/// identity".
int totalRepetitions(Iterable<HabitLog> logs) =>
    logs.where((l) => (l.kind == HabitLogKind.done || l.kind == HabitLogKind.progress) && l.source != 'auto').length;

// ---------------------------------------------------------------------------------------------
// Target & volume (T6.5.05, T6.5.06)
// ---------------------------------------------------------------------------------------------

/// HB-H-10 — target progress over a period: Σ v ÷ T_P with T_P = t_day × scheduled days in P −
/// t_day × skipped days (Loop TargetCard); quota habits: completions ÷ (N × periods in P,
/// pro-rated).
Stat<double> targetProgress(Iterable<PeriodResult> results, {required LocalDate from, required LocalDate to}) {
  var achieved = 0.0;
  var target = 0.0;
  for (final r in _inRange(results, from, to)) {
    if (r.status == PeriodStatus.notDue) continue;
    if (r.kind == HabitPeriodKind.quota) {
      achieved += r.flags.activeDays?.toDouble() ?? r.achieved;
      target += r.goal.isMeasurable ? r.target : (r.flags.expected ?? r.target);
      continue;
    }
    achieved += r.achieved;
    if (r.status != PeriodStatus.skipped) target += r.target;
  }
  return safeDivide(achieved, target, sampleSize: target);
}

/// HB-H-11 — total volume Σ v over [from]…[to] (all time when null).
double totalVolume(Iterable<PeriodResult> results, {LocalDate? from, LocalDate? to}) =>
    _inRange(results, from, to).fold(0, (a, r) => a + r.achieved);

/// HB-H-12 — mean v per scheduled day (E − X) and per active day (v > 0).
({Stat<double> perScheduledDay, Stat<double> perActiveDay}) volumeAverages(
  Iterable<PeriodResult> results, {
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final scheduled = [
    for (final r in results)
      if (isClosedScheduled(r) && !isExcludedUnit(r, skipPolicy: skipPolicy)) r.achieved,
  ];
  final active = [
    for (final v in scheduled)
      if (v > 0) v,
  ];
  return (perScheduledDay: mean(scheduled), perActiveDay: mean(active));
}

/// A personal record (HB-H-13, GL-06).
@immutable
final class const PersonalRecord(
  final LocalDate bucket, {
  required final double value,
  required final double? previousBest,
  required final bool isNew,
});

/// Best bucket by value; "new" when it exceeds the maximum over all history before the bucket that
/// contains [currentPeriodStart] (backfilled old records are therefore never "new").
Stat<PersonalRecord> bestBucket(List<SeriesPoint<double>> series, {required LocalDate currentPeriodStart}) {
  if (series.isEmpty) return const Insufficient<PersonalRecord>(1, 0);
  var best = series.first;
  for (final p in series) {
    if (p.value > best.value) best = p;
  }
  final before = [
    for (final p in series)
      if (p.bucket.isBefore(currentPeriodStart)) p.value,
  ];
  final previous = before.isEmpty ? null : before.reduce(math.max);
  return Value<PersonalRecord>(
    PersonalRecord(
      best.bucket,
      value: best.value,
      previousBest: previous,
      isNew: !best.bucket.isBefore(currentPeriodStart) && (previous == null || best.value > previous),
    ),
  );
}

/// HB-H-13 — records: best day, week and month by volume (or completions with [byCompletions]).
({Stat<PersonalRecord> day, Stat<PersonalRecord> week, Stat<PersonalRecord> month}) habitRecords(
  Iterable<PeriodResult> results, {
  required LocalDate from,
  required LocalDate to,
  required LocalDate currentPeriodStart,
  bool byCompletions = false,
  Weekday weekStart = Weekday.monday,
}) {
  final rows = [
    for (final r in results)
      if (!byCompletions || r.status == PeriodStatus.done) (r.startDate, byCompletions ? 1.0 : r.achieved),
  ];
  Stat<PersonalRecord> best(Granularity g) => bestBucket(
    bucketSum(rows, from: from, to: to, granularity: g, weekStart: weekStart),
    currentPeriodStart: bucketStart(currentPeriodStart, g, weekStart: weekStart),
  );
  return (day: best(Granularity.day), week: best(Granularity.week), month: best(Granularity.month));
}

/// HB-H-14 — distribution of daily values of scheduled units: histogram, median, P85.
({Histogram histogram, Stat<double> median, Stat<double> p85}) valueDistribution(
  Iterable<PeriodResult> results, {
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final values = [
    for (final r in results)
      if (isClosedScheduled(r) && !isExcludedUnit(r, skipPolicy: skipPolicy)) r.achieved,
  ];
  return (
    histogram: histogramFreedmanDiaconis(values),
    median: MinDataRules.meanOrMedian.apply(median(values)),
    p85: MinDataRules.p85.apply(p85(values)),
  );
}

/// HB-H-15 — partial share P ÷ (E − X) and mean fulfilment mean(min(1, v_u/t_u)) over non-excused
/// units.
({Stat<double> partialShare, Stat<double> meanFulfilment}) partialAndFulfilment(
  Iterable<PeriodResult> results, {
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final units = [
    for (final r in results)
      if (isClosedScheduled(r) && !isExcludedUnit(r, skipPolicy: skipPolicy)) r,
  ];
  return (
    partialShare: rate(units.where((r) => r.status == PeriodStatus.partial).length, units.length),
    meanFulfilment: mean(units.map(_unitFulfilment)),
  );
}

double _unitFulfilment(PeriodResult r) =>
    r.status == PeriodStatus.skipped || r.status == PeriodStatus.frozen ? 0 : r.fulfilment;

/// HB-H-16 — limit habits: within-limit days (v ≤ limit) ÷ (E − X), excess Σ max(0, v − limit)
/// and Loop credits clamp(1 − (v − limit)/limit, 0, 1).
({Stat<double> withinLimitShare, double excess, List<double> credits}) limitMetrics(List<double> values, double limit) {
  var within = 0;
  var excess = 0.0;
  for (final v in values) {
    if (v <= limit) within++;
    excess += math.max(0, v - limit);
  }
  return (
    withinLimitShare: rate(within, values.length),
    excess: excess,
    credits: [for (final v in values) limitCredit(v, limit)],
  );
}

/// HB-H-16 from period results (closed, non-excluded units of an `lte` habit).
({Stat<double> withinLimitShare, double excess, List<double> credits}) limitMetricsOf(
  Iterable<PeriodResult> results, {
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final units = [
    for (final r in results)
      if (isClosedScheduled(r) && !isExcludedUnit(r, skipPolicy: skipPolicy)) r,
  ];
  if (units.isEmpty) return limitMetrics(const [], 0);
  return limitMetrics([for (final r in units) r.achieved], units.first.target);
}

// ---------------------------------------------------------------------------------------------
// Consistency, timing, recovery (T6.5.08–T6.5.10)
// ---------------------------------------------------------------------------------------------

/// HB-H-17 — Habitify-style consistency index.
@immutable
final class const ConsistencyIndex(final List<SeriesPoint<double?>> l2, {required final Stat<double> index});

/// HB-H-17 — L1 per scheduled unit: 1 done, 0 failed/missed (frozen counts as a miss), v/t partial;
/// skipped units count 0 only when the skip policy is `breaks`; excused, paused and non-scheduled
/// units are excluded. L2 = trailing mean of L1 over [windowDays] (30/60/90/180) days, evaluated per
/// day of [from]…[to]. L3 = mean of L2 over the period (the `index`). Independent of how many
/// non-scheduled days fall in the window.
ConsistencyIndex consistencyIndex(
  Iterable<PeriodResult> results, {
  required LocalDate from,
  required LocalDate to,
  int windowDays = 30,
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final l1 = <(LocalDate, double)>[];
  for (final r in results) {
    if (!isClosedScheduled(r) || isExcludedUnit(r, skipPolicy: skipPolicy)) {
      continue;
    }
    final v = switch (r.status) {
      PeriodStatus.done => 1.0,
      PeriodStatus.partial => r.fulfilment,
      _ => 0.0,
    };
    l1.add((r.endDate, v));
  }
  final l2 = <SeriesPoint<double?>>[];
  for (var d = from; !d.isAfter(to); d = d.plusDays(1)) {
    final start = d.minusDays(windowDays - 1);
    final window = [
      for (final (date, v) in l1)
        if (!date.isBefore(start) && !date.isAfter(d)) v,
    ];
    l2.add(SeriesPoint(d, window.isEmpty ? null : sum(window) / window.length));
  }
  final defined = [for (final p in l2) ?p.value];
  return ConsistencyIndex(l2, index: mean(defined));
}

/// HB-H-18 / HB-X-11 — success rate per weekday.
Map<Weekday, Stat<double>> habitWeekdayProfile(
  Iterable<PeriodResult> results, {
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final s = <Weekday, int>{};
  final n = <Weekday, int>{};
  for (final r in results) {
    if (r.kind == HabitPeriodKind.quota) continue;
    if (!isClosedScheduled(r) || isExcludedUnit(r, skipPolicy: skipPolicy)) {
      continue;
    }
    final w = r.startDate.weekday;
    n[w] = (n[w] ?? 0) + 1;
    if (r.status == PeriodStatus.done) s[w] = (s[w] ?? 0) + 1;
  }
  return {for (final w in n.keys) w: rate(s[w] ?? 0, n[w]!)};
}

/// HB-H-19 — check-in time: circular mean/SD of `logged_at` (minutes counted from the day start of
/// [bounds]) and the weekday × hour matrix of check-ins (by habit date).
({Stat<CircularSummary> circular, Map<Weekday, List<int>> matrix}) checkInTimes(
  Iterable<HabitLog> logs, {
  required DayBoundaries bounds,
}) {
  final minutes = <int>[];
  final matrix = {for (final w in Weekday.values) w: List<int>.filled(24, 0)};
  for (final l in logs) {
    if (l.kind != HabitLogKind.done && l.kind != HabitLogKind.progress) {
      continue;
    }
    final local = bounds.clock.toLocal(l.loggedAt);
    minutes.add(local.time.minuteOfDay);
    matrix[bounds.dateOf(l.loggedAt).weekday]![local.hour]++;
  }
  return (circular: circularTimeSummary(minutes, dayStartMinute: bounds.dayStartsAt.minuteOfDay), matrix: matrix);
}

/// HB-H-20 — slot punctuality: share of slot check-ins within ±[tolerance] (default 30 min) of the
/// slot time (the slot result's window start).
Stat<double> slotPunctuality(Iterable<PeriodResult> slotResults, {Duration tolerance = const Duration(minutes: 30)}) {
  var within = 0;
  var total = 0;
  for (final r in slotResults) {
    if (r.kind != HabitPeriodKind.slot) continue;
    for (final l in r.entries) {
      if (l.kind != HabitLogKind.done && l.kind != HabitLogKind.progress) {
        continue;
      }
      total++;
      if (l.loggedAt.difference(r.windowStart).abs() <= tolerance) within++;
    }
  }
  return rate(within, total);
}

/// HB-H-21 — multi-times per day: per-day count vs target and the mean/median spacing (minutes)
/// between consecutive check-ins of a day.
({Map<LocalDate, (int count, double target)> perDay, Stat<double> meanSpacing, Stat<double> medianSpacing})
multiTimesPerDay(Iterable<PeriodResult> dayResults) {
  final perDay = <LocalDate, (int, double)>{};
  final spacing = <double>[];
  for (final r in dayResults) {
    final checkIns = [
      for (final l in r.entries)
        if (l.kind == HabitLogKind.done || l.kind == HabitLogKind.progress) l.loggedAt,
    ]..sort();
    perDay[r.startDate] = (r.goal.isMeasurable ? r.achieved.round() : checkIns.length, r.target);
    for (var i = 1; i < checkIns.length; i++) {
      spacing.add(checkIns[i].difference(checkIns[i - 1]).inSeconds / 60);
    }
  }
  return (perDay: perDay, meanSpacing: mean(spacing), medianSpacing: median(spacing));
}

/// HB-H-22 result.
@immutable
final class const Recovery(
  final Stat<double> recoveryRate, {
  required final int longestGap,
  required final Stat<double> meanGap,
  required final int comebacks,
});

/// HB-H-22 — "never miss twice": recovery rate = misses whose next scheduled unit is a success ÷
/// misses with a closed next unit; longest and mean gap (runs of consecutive failed/missed units);
/// comebacks = successes after ≥ [comebackAfter] consecutive misses. Neutral units are skipped;
/// partial units end a gap without being a success.
Recovery recovery(Iterable<PeriodResult> results, {SkipPolicy skipPolicy = SkipPolicy.neutral, int comebackAfter = 3}) {
  final seq = [
    for (final r in [...results]..sort((a, b) => a.startDate.compareTo(b.startDate)))
      if (isClosedScheduled(r) && !isExcludedUnit(r, skipPolicy: skipPolicy))
        switch (r.status) {
          PeriodStatus.done => 1,
          PeriodStatus.failed || PeriodStatus.missed || PeriodStatus.frozen => -1,
          PeriodStatus.skipped => -1,
          _ => 0,
        },
  ];
  var misses = 0;
  var recovered = 0;
  final gaps = <int>[];
  var run = 0;
  var comebacks = 0;
  for (var i = 0; i < seq.length; i++) {
    if (seq[i] == -1) {
      run++;
      if (i + 1 < seq.length) {
        misses++;
        if (seq[i + 1] == 1) recovered++;
      }
    } else {
      if (run > 0) gaps.add(run);
      if (seq[i] == 1 && run >= comebackAfter) comebacks++;
      run = 0;
    }
  }
  if (run > 0) gaps.add(run);
  return Recovery(
    rate(recovered, misses),
    longestGap: gaps.isEmpty ? 0 : gaps.reduce(math.max),
    meanGap: mean(gaps),
    comebacks: comebacks,
  );
}

/// HB-H-23 — freezes used / granted this month and all time, with the protected units.
({int usedThisMonth, int grantedThisMonth, int usedAllTime, int grantedAllTime, List<String> protectedKeys})
freezeUsage(
  StreakSummary streaks, {
  required int freezesPerMonth,
  required LocalDate today,
  required LocalDate habitStart,
}) {
  final month = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}';
  final months = (today.year - habitStart.year) * 12 + today.month - habitStart.month + 1;
  return (
    usedThisMonth: streaks.freezesUsedByMonth[month] ?? 0,
    grantedThisMonth: freezesPerMonth,
    usedAllTime: streaks.freezesUsedByMonth.values.fold(0, (a, b) => a + b),
    grantedAllTime: freezesPerMonth * math.max(0, months),
    protectedKeys: streaks.frozenKeys,
  );
}

/// Momentum label (HB-H-24).
enum Momentum { rising, stable, falling }

/// HB-H-24 — OLS slope of the strength score over the last [days] days (score points per day, 0–100
/// scale): |slope| < 0.1 pt/day → stable.
Stat<({double slopePointsPerDay, Momentum momentum})> scoreMomentum(StrengthResult strength, {int days = 30}) {
  final series = strength.series;
  final tail = series.length <= days ? series : series.sublist(series.length - days);
  return ols([for (var i = 0; i < tail.length; i++) i], [for (final p in tail) p.score * 100]).map((r) {
    final m = r.slope.abs() < 0.1 ? Momentum.stable : (r.slope > 0 ? Momentum.rising : Momentum.falling);
    return (slopePointsPerDay: r.slope, momentum: m);
  });
}

/// HB-H-25 / HB-X-12 / GL-10 — data completeness.
@immutable
final class const DataCompleteness(
  final Stat<double> loggedRatio, {
  required final int unknownUnits,
  required final Stat<double> backfillShare,
  required final int closedUnits,
});

/// HB-H-25 — logged ratio = units with any log ÷ closed scheduled units; unknown units = `missed`
/// without any log ("unlogged" ≠ "failed"); backfill share = logs created > 24 h after their unit
/// ended.
DataCompleteness dataCompleteness(Iterable<PeriodResult> results) {
  var closed = 0;
  var logged = 0;
  var unknown = 0;
  var logs = 0;
  var backfilled = 0;
  for (final r in results) {
    if (!isClosedScheduled(r)) continue;
    closed++;
    if (r.entries.isNotEmpty) logged++;
    if (r.status == PeriodStatus.missed && r.entries.isEmpty) unknown++;
    for (final l in r.entries) {
      logs++;
      final created = l.createdAt;
      if (created != null && created.difference(r.windowEnd) > const Duration(hours: 24)) {
        backfilled++;
      }
    }
  }
  return DataCompleteness(
    rate(logged, closed),
    unknownUnits: unknown,
    backfillShare: rate(backfilled, logs),
    closedUnits: closed,
  );
}

/// HB-H-26 — pace & projection of a habit goal (volume or completions): delegates to the goal
/// engine (T5.4.03) with the per-day values of the results.
GoalProgress habitGoalPace(
  GoalSpec goal,
  Iterable<PeriodResult> results, {
  required LocalDate asOf,
  bool byCompletions = false,
}) {
  final daily = <LocalDate, double>{};
  for (final r in results) {
    final v = byCompletions ? (r.status == PeriodStatus.done ? 1.0 : 0.0) : r.achieved;
    daily[r.startDate] = (daily[r.startDate] ?? 0) + v;
  }
  return goalProgress(goal, asOf: asOf, dailyValues: daily);
}

// ---------------------------------------------------------------------------------------------
// Advanced (T6.5.15)
// ---------------------------------------------------------------------------------------------

/// Lally et al. 2010: 18–254 days to reach 95 % of the automaticity plateau (~66-day median).
const int lallyMinDays = 18;
const int lallyMaxDays = 254;
const int lallyMedianDays = 66;

/// HB-H-27 — formation: days from the first unit until the rolling-30 success rate first stays
/// ≥ [threshold] (80 %) for [holdDays] (14) consecutive days; `NotApplicable('notReached')` when it
/// never does.
Stat<int> formationDays(
  Iterable<PeriodResult> results, {
  required LocalDate today,
  double threshold = 0.8,
  int holdDays = 14,
  int windowDays = 30,
}) {
  final list = [
    for (final r in results)
      if (isClosedScheduled(r) && !isExcludedUnit(r)) r,
  ];
  if (list.isEmpty) return const NotApplicable<int>(Reasons.noData);
  final first = list.map((r) => r.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
  var streak = 0;
  for (var d = first; !d.isAfter(today); d = d.plusDays(1)) {
    final rate = successRate(list, from: d.minusDays(windowDays - 1), to: d).valueOrNull;
    if (rate != null && rate >= threshold) {
      streak++;
      if (streak >= holdDays) {
        return Value<int>(first.daysUntil(d.minusDays(holdDays - 1)) + 1);
      }
    } else {
      streak = 0;
    }
  }
  return const NotApplicable<int>(Reasons.notReached);
}

/// HB-H-28 — reminder effectiveness: share of check-ins within [window] (60 min) after a reminder
/// for the habit, and the median latency reminder → check-in (minutes).
({Stat<double> share, Stat<double> medianLatencyMinutes}) reminderEffectiveness({
  required List<DateTime> reminders,
  required List<DateTime> checkIns,
  Duration window = const Duration(minutes: 60),
}) {
  final sortedReminders = [...reminders]..sort();
  var within = 0;
  final latencies = <double>[];
  for (final c in checkIns) {
    DateTime? last;
    for (final r in sortedReminders) {
      if (r.isAfter(c)) break;
      last = r;
    }
    if (last != null && c.difference(last) <= window) {
      within++;
      latencies.add(c.difference(last).inSeconds / 60);
    }
  }
  return (share: rate(within, checkIns.length), medianLatencyMinutes: median(latencies));
}

/// HB-H-29 — mean mood on done vs not-done days with a Mann–Whitney test (non-causal wording).
({Stat<double> doneMean, Stat<double> notDoneMean, Stat<MannWhitneyResult> test}) moodByOutcome(
  List<HabitDayFact> days,
) {
  final done = [
    for (final d in days)
      if (d.mood != null && d.dueUnits > 0 && d.doneUnits >= d.dueUnits) d.mood!,
  ];
  final notDone = [
    for (final d in days)
      if (d.mood != null && d.dueUnits > 0 && d.doneUnits < d.dueUnits) d.mood!,
  ];
  return (doneMean: mean(done), notDoneMean: mean(notDone), test: mannWhitneyU(done, notDone));
}

/// HB-H-30 — Pareto of skip/excuse reasons (normalized note text).
List<ParetoEntry> skipExcuseReasons(Iterable<HabitLog> logs) => pareto([
  for (final l in logs)
    if (l.kind == HabitLogKind.skip || l.kind == HabitLogKind.excuse) l.note?.trim().toLowerCase(),
]);

// ---------------------------------------------------------------------------------------------
// Habits section (T6.5.13–T6.5.15)
// ---------------------------------------------------------------------------------------------

/// One habit's inputs for section metrics.
@immutable
final class const HabitSeries(
  final String habitId, {
  required final List<PeriodResult> results,
  final List<HabitLog> logs = const [],
  final String? categoryId,
  final LocalDate? createdOn,
  final LocalDate? archivedOn,
  final SkipPolicy skipPolicy = SkipPolicy.neutral,
  final StrengthResult? strength,
}) {
  /// Day-level units still counted on [date] (archived habits drop out after their archive date).
  Iterable<PeriodResult> dayUnitsOn(LocalDate date) => results.where(
    (r) => r.kind != HabitPeriodKind.quota && r.startDate == date && (archivedOn == null || !date.isAfter(archivedOn!)),
  );

  bool isDue(PeriodResult r) =>
      r.status != PeriodStatus.notDue && r.status != PeriodStatus.frozen && !isExcludedUnit(r, skipPolicy: skipPolicy);
}

/// HB-X-01 — today progress: done ÷ due day units today across build habits.
Stat<double> todayProgress(List<HabitSeries> habits, {required LocalDate today}) {
  var due = 0;
  var done = 0;
  for (final h in habits) {
    for (final r in h.dayUnitsOn(today)) {
      if (!h.isDue(r)) continue;
      due++;
      if (r.status == PeriodStatus.done) done++;
    }
  }
  return rate(done, due);
}

/// HB-X-03 — per-day done ÷ due across habits (null on days with nothing due).
List<SeriesPoint<double?>> dailyCompletionHeatmap(List<HabitSeries> habits, {required DateRange range}) => [
  for (final date in range.dates)
    () {
      var due = 0;
      var done = 0;
      for (final h in habits) {
        for (final r in h.dayUnitsOn(date)) {
          if (!h.isDue(r)) continue;
          due++;
          if (r.status == PeriodStatus.done) done++;
        }
      }
      return SeriesPoint<double?>(date, due == 0 ? null : done / due);
    }(),
];

/// HB-X-02 — perfect days (every due build unit done) and the perfect-day streak; days with nothing
/// due are neutral; [today] is open until it is perfect.
({List<LocalDate> perfectDays, StreakSummary streak}) perfectDays(
  List<HabitSeries> habits, {
  required DateRange range,
  required LocalDate today,
}) {
  final heat = dailyCompletionHeatmap(habits, range: range);
  final perfect = [
    for (final p in heat)
      if (p.value == 1) p.bucket,
  ];
  return (
    perfectDays: perfect,
    streak: computeStreaks([
      for (final p in heat)
        StreakUnit(
          p.bucket.toIso(),
          start: p.bucket,
          end: p.bucket,
          kind: switch (p.value) {
            null => StreakUnitKind.neutral,
            1.0 => StreakUnitKind.success,
            _ => p.bucket == today ? StreakUnitKind.open : StreakUnitKind.breaks,
          },
        ),
    ]),
  );
}

/// HB-X-04 — overall weekly success rate, Δ vs the previous week (pp) and the rolling 4-week line.
({List<SeriesPoint<double?>> weekly, List<double?> rolling4, PeriodComparison lastVsPrevious}) adherenceTrend(
  List<HabitSeries> habits, {
  required DateRange range,
  Weekday weekStart = Weekday.monday,
}) {
  final rows = <(LocalDate, num, num)>[];
  for (final h in habits) {
    for (final r in h.results) {
      if (!isClosedScheduled(r) || isExcludedUnit(r, skipPolicy: h.skipPolicy)) {
        continue;
      }
      if (h.archivedOn != null && r.startDate.isAfter(h.archivedOn!)) continue;
      rows.add((r.endDate, r.status == PeriodStatus.done ? 1 : 0, 1));
    }
  }
  final weekly = bucketRate(
    rows,
    from: range.start,
    to: range.end,
    granularity: Granularity.week,
    weekStart: weekStart,
  );
  Stat<double> at(int i) {
    if (i < 0 || i >= weekly.length || weekly[i].value == null) {
      return const NotApplicable<double>(Reasons.noData);
    }
    return Value<double>(weekly[i].value!);
  }

  return (
    weekly: weekly,
    rolling4: rollingMean([for (final p in weekly) p.value], 4),
    lastVsPrevious: compareWithPrevious(at(weekly.length - 1), at(weekly.length - 2), isRate: true),
  );
}

/// HB-X-05 — quit roll-up across trackers: Σ money saved per currency, Σ units avoided, Σ life
/// regained minutes (population estimate), Σ abstinent (clean) days.
({Map<String, Decimal> moneySaved, double unitsAvoided, double lifeRegainedMinutes, int cleanDays}) quitRollUp(
  List<QuitCalculator> trackers,
) {
  final money = <String, Decimal>{};
  var units = 0.0;
  var life = 0.0;
  var clean = 0;
  for (final t in trackers) {
    final currency = t.tracker.currency ?? '';
    money[currency] = (money[currency] ?? Decimal.zero) + t.moneySaved;
    units += t.unitsAvoided;
    life += t.lifeRegainedMinutes ?? 0;
    clean += t.cleanDays;
  }
  return (moneySaved: money, unitsAvoided: units, lifeRegainedMinutes: life, cleanDays: clean);
}

/// HB-X-06 — strength distribution: mean and median current score, ranking, and habits rising /
/// falling over the last 30 days.
({Stat<double> mean, Stat<double> median, List<(String, double)> ranked, List<String> rising, List<String> falling})
strengthDistribution(List<HabitSeries> habits, {double changeThreshold = 0.05}) {
  final scores = <(String, double)>[];
  final rising = <String>[];
  final falling = <String>[];
  for (final h in habits) {
    final s = h.strength;
    if (s == null) continue;
    scores.add((h.habitId, s.current));
    final delta = s.deltaVsDaysAgo(30).valueOrNull ?? 0;
    if (delta > changeThreshold) rising.add(h.habitId);
    if (delta < -changeThreshold) falling.add(h.habitId);
  }
  final values = [for (final (_, v) in scores) v];
  return (
    mean: mean(values),
    median: median(values),
    ranked: scores..sort((a, b) => b.$2.compareTo(a.$2)),
    rising: rising,
    falling: falling,
  );
}

/// Why a habit is at risk (HB-X-07).
enum HabitRisk { quotaBehind, dueToday, scoreDrop }

/// HB-X-07 — at-risk list: quota streak at risk (needed > eligible days left), a pending unit due
/// today with a live streak, or a score drop > 10 points in 7 days.
List<(String habitId, HabitRisk risk)> atRiskHabits(List<HabitSeries> habits, {required LocalDate today}) {
  final result = <(String, HabitRisk)>[];
  for (final h in habits) {
    if (h.archivedOn != null && today.isAfter(h.archivedOn!)) continue;
    final open = h.results.where((r) => r.status == PeriodStatus.pending && !r.flags.future);
    if (open.any((r) => r.kind == HabitPeriodKind.quota && r.flags.atRisk)) {
      result.add((h.habitId, HabitRisk.quotaBehind));
    } else if (open.any((r) => r.kind != HabitPeriodKind.quota && r.startDate == today) &&
        habitStreaks(h.results, skipPolicy: h.skipPolicy).currentLength > 0) {
      result.add((h.habitId, HabitRisk.dueToday));
    }
    final s = h.strength;
    if (s != null && (s.deltaVsDaysAgo(7).valueOrNull ?? 0) < -0.10) {
      result.add((h.habitId, HabitRisk.scoreDrop));
    }
  }
  return result;
}

/// HB-X-08 — success rate and volume by category (life area).
Map<String?, ({Stat<double> successRate, double volume})> habitAreas(
  List<HabitSeries> habits, {
  LocalDate? from,
  LocalDate? to,
}) {
  final byCategory = <String?, List<HabitSeries>>{};
  for (final h in habits) {
    byCategory.putIfAbsent(h.categoryId, () => []).add(h);
  }
  return {
    for (final e in byCategory.entries)
      e.key: (
        successRate: successRate([for (final h in e.value) ...h.results], from: from, to: to),
        volume: e.value.fold(0, (a, h) => a + totalVolume(h.results, from: from, to: to)),
      ),
  };
}

/// HB-X-09 — ranking by success rate in P (habits with ≥ [minUnits] closed units), best first.
List<(String habitId, double rate)> bestAndWorstHabits(
  List<HabitSeries> habits, {
  required LocalDate from,
  required LocalDate to,
  int minUnits = 5,
}) {
  final ranked = <(String, double)>[];
  for (final h in habits) {
    final r = successRate(h.results, from: from, to: to, skipPolicy: h.skipPolicy);
    if (r is Value<double> && (r.sampleSize ?? 0) >= minUnits) {
      ranked.add((h.habitId, r.value));
    }
  }
  return ranked..sort((a, b) => b.$2.compareTo(a.$2));
}

/// HB-X-10 — check-in volume (logs per day or week).
List<SeriesPoint<double>> checkInVolume(
  List<HabitSeries> habits, {
  required DateRange range,
  Granularity granularity = Granularity.day,
  Weekday weekStart = Weekday.monday,
}) => bucketSum(
  [
    for (final h in habits)
      for (final l in h.logs)
        if (l.kind == HabitLogKind.done || l.kind == HabitLogKind.progress) (l.localDate, 1),
  ],
  from: range.start,
  to: range.end,
  granularity: granularity,
  weekStart: weekStart,
);

/// HB-X-12 — section data completeness (the HB-H-25 measures over all habits).
DataCompleteness sectionDataCompleteness(List<HabitSeries> habits) =>
    dataCompleteness([for (final h in habits) ...h.results]);

/// HB-X-13 — one habit pair of the co-occurrence matrix.
@immutable
final class const CoOccurrence(
  final String a,
  final String b, {
  required final double phi,
  required final int overlappingDays,
  required final double pValue,
  required final double adjustedP,
  required final bool significant,
});

/// HB-X-13 — phi between the daily done flags of each habit pair over their overlapping due days
/// (≥ 21), with Benjamini–Hochberg FDR marks at [q].
List<CoOccurrence> habitCoOccurrence(List<HabitSeries> habits, {int minDays = 21, double q = defaultFdrQ}) {
  Map<LocalDate, bool> flags(HabitSeries h) => {
    for (final r in h.results)
      if (r.kind != HabitPeriodKind.quota && isClosedScheduled(r) && h.isDue(r))
        r.startDate: r.status == PeriodStatus.done,
  };
  final all = [for (final h in habits) (h.habitId, flags(h))];
  final pairs = <(String, String, double, int, double)>[];
  for (var i = 0; i < all.length; i++) {
    for (var j = i + 1; j < all.length; j++) {
      final (ia, fa) = all[i];
      final (ib, fb) = all[j];
      final days = [
        for (final d in fa.keys)
          if (fb.containsKey(d)) d,
      ];
      if (days.length < minDays) continue;
      final r = phiCoefficient([for (final d in days) fa[d]!], [for (final d in days) fb[d]!]);
      if (r case Value<CorrelationResult>(:final value)) {
        pairs.add((ia, ib, value.r, days.length, value.pValue));
      }
    }
  }
  final adjusted = benjaminiHochberg([for (final p in pairs) p.$5]);
  return [
    for (var k = 0; k < pairs.length; k++)
      CoOccurrence(
        pairs[k].$1,
        pairs[k].$2,
        phi: pairs[k].$3,
        overlappingDays: pairs[k].$4,
        pValue: pairs[k].$5,
        adjustedP: adjusted[k],
        significant: adjusted[k] <= q && meetsEffectThreshold(pairs[k].$3, binaryPair: true),
      ),
  ];
}

/// HB-X-14 — portfolio: habits created and archived per month; share still active 30 and 90 days
/// after creation (among habits old enough to tell).
({
  List<SeriesPoint<double>> created,
  List<SeriesPoint<double>> archived,
  Stat<double> activeAt30,
  Stat<double> activeAt90,
})
habitPortfolio(List<HabitSeries> habits, {required DateRange range, required LocalDate today}) {
  Stat<double> activeAt(int days) {
    var eligible = 0;
    var active = 0;
    for (final h in habits) {
      final created = h.createdOn;
      if (created == null || created.plusDays(days).isAfter(today)) continue;
      eligible++;
      if (h.archivedOn == null || h.archivedOn!.isAfter(created.plusDays(days))) {
        active++;
      }
    }
    return rate(active, eligible);
  }

  return (
    created: bucketSum(
      [
        for (final h in habits)
          if (h.createdOn != null) (h.createdOn!, 1),
      ],
      from: range.start,
      to: range.end,
      granularity: Granularity.month,
    ),
    archived: bucketSum(
      [
        for (final h in habits)
          if (h.archivedOn != null) (h.archivedOn!, 1),
      ],
      from: range.start,
      to: range.end,
      granularity: Granularity.month,
    ),
    activeAt30: activeAt(30),
    activeAt90: activeAt(90),
  );
}
