/// Quit Insights calculators ([6.6], QT-01 … QT-28). All arithmetic on attempts, abstinence,
/// units and money is delegated to the [QuitCalculator] (T5.3.03 — the single implementation);
/// this file adds the craving, use, attempt and survival analytics.
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/min_data.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/quit_calculator.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/survival.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:meta/meta.dart';

/// Substance key that unlocks health content and life-regained estimates.
const String smokingSubstance = 'cigarettes';

/// Header numbers of the quit screen (QT-01 … QT-10, QT-22).
@immutable
final class const QuitSummary({
  required final Duration timeSinceQuit,
  required final Duration currentAbstinence,
  required final Duration longestAbstinence,
  required final int abstinentDays,
  required final Stat<double> abstinentDayShare,
  required final int unknownDays,
  required final double unitsAvoided,
  required final Decimal moneySaved,
  required final Decimal moneySpent,
  required final SavingsProjection? projection,
  required final Stat<double> lifeRegainedMinutes,
  required final double? timeNotSpentMinutes,
});

/// QT-01 now − qd · QT-02 now − max(qd, last use) · QT-03 longest gap · QT-04 abstinent (clean)
/// local days · QT-05 share of closed days · QT-06 units avoided · QT-07 money saved · QT-08 money
/// spent on lapses · QT-09 savings projections · QT-10 life regained (population estimate; only for
/// cigarettes unless the user set an LMU explicitly: [explicitLifeMinutesPerUnit]) · QT-22 time not
/// spent consuming.
QuitSummary quitSummary(
  QuitCalculator c, {
  bool explicitLifeMinutesPerUnit = false,
}) {
  final life = c.lifeRegainedMinutes;
  final Stat<double> lifeStat;
  if (life == null) {
    lifeStat = const NotApplicable<double>('noLifeEstimate');
  } else if (c.tracker.substance != smokingSubstance &&
      !explicitLifeMinutesPerUnit) {
    lifeStat = const NotApplicable<double>('notSmoking');
  } else {
    lifeStat = Value<double>(life);
  }
  return QuitSummary(
    timeSinceQuit: c.timeSinceQuit,
    currentAbstinence: c.currentAbstinence,
    longestAbstinence: c.longestAbstinence,
    abstinentDays: c.cleanDays,
    abstinentDayShare: c.cleanDayShare,
    unknownDays: c.unknownDays,
    unitsAvoided: c.unitsAvoided,
    moneySaved: c.moneySaved,
    moneySpent: c.moneySpent,
    projection: c.savingsProjection,
    lifeRegainedMinutes: lifeStat,
    timeNotSpentMinutes: c.timeWonBackMinutes,
  );
}

/// QT-11 — health milestones driven by the current abstinence (the clock restarts after a lapse);
/// shown only for smoking trackers.
Stat<List<MilestoneProgress>> healthMilestones(
  QuitCalculator c,
  List<QuitMilestone> table,
) {
  if (c.tracker.substance != smokingSubstance) {
    return const NotApplicable<List<MilestoneProgress>>('notSmoking');
  }
  return Value(
    milestoneProgress(
      table,
      abstinenceStart: c.currentAbstinenceStart,
      now: c.now,
    ),
  );
}

/// QT-12 result.
@immutable
final class const ReductionProgress({
  required final Stat<double> withinLimitShare,
  required final Stat<double> meanDailyUse,
  required final Stat<double> meanBase,
  required final double? limit,
  required final Stat<double> reduction,
  required final double unitsAvoided,
  required final List<double?> rolling7Use,
});

/// QT-12 — reduction progress over closed days: within-limit days (used_d ≤ limit_d) ÷ days; mean
/// daily use vs base and limit; % reduction = 1 − mean use ÷ mean base; 7-day rolling mean of use.
ReductionProgress reductionProgress(QuitCalculator c) {
  final days = c.closedDays;
  final uses = [for (final d in days) d.used];
  final bases = [for (final d in days) d.base];
  final meanUse = mean(uses);
  final meanBase = mean(bases);
  return ReductionProgress(
    withinLimitShare: rate(
      days.where((d) => d.withinLimit ?? false).length,
      days.length,
    ),
    meanDailyUse: meanUse,
    meanBase: meanBase,
    limit: days.isEmpty ? null : days.last.limit,
    reduction: Stat.combine(
      meanUse,
      meanBase,
      (u, b) => b == 0 ? 0.0 : 1 - u / b,
    ),
    unitsAvoided: c.unitsAvoided,
    rolling7Use: rollingMean(uses, 7),
  );
}

List<QuitLog> _cravings(QuitCalculator c) => [
  for (final l in c.logs)
    if (l.kind == HabitLogKind.craving && !l.loggedAt.isAfter(c.now)) l,
];

/// QT-13 — craving load over closed days since qd (or [range]): cravings per day (mean), mean and
/// max intensity, and the 7-day rolling mean of daily counts.
({
  Stat<double> perDay,
  Stat<double> meanIntensity,
  Stat<double> maxIntensity,
  List<SeriesPoint<double>> daily,
  List<double?> rolling7,
})
cravingLoad(QuitCalculator c, {DateRange? range}) {
  final closed = c.closedDays;
  final r =
      range ??
      (closed.isEmpty
          ? null
          : DateRange(closed.first.localDate, closed.last.localDate));
  if (r == null) {
    return (
      perDay: const NotApplicable<double>(Reasons.noData),
      meanIntensity: const Insufficient<double>(1, 0),
      maxIntensity: const Insufficient<double>(1, 0),
      daily: const <SeriesPoint<double>>[],
      rolling7: const <double?>[],
    );
  }
  final cravings = [
    for (final l in _cravings(c))
      if (r.contains(l.localDate)) l,
  ];
  final daily = bucketSum(
    [for (final l in cravings) (l.localDate, 1)],
    from: r.start,
    to: r.end,
    granularity: Granularity.day,
  );
  final intensities = [for (final l in cravings) ?l.intensity];
  return (
    perDay: safeDivide(cravings.length, r.days),
    meanIntensity: mean(intensities),
    maxIntensity: maximum(intensities),
    daily: daily,
    rolling7: rollingMean([for (final p in daily) p.value], 7),
  );
}

/// QT-14 — craving context: Pareto by trigger, place and mood (case-insensitive, "Unspecified"
/// last) and the weekday × hour matrix (rows follow [weekStart]).
({
  List<ParetoEntry> triggers,
  List<ParetoEntry> places,
  List<ParetoEntry> moods,
  List<(Weekday, List<int>)> matrix,
})
cravingContext(QuitCalculator c, {Weekday weekStart = Weekday.monday}) {
  final cravings = _cravings(c);
  final matrix = {for (final w in Weekday.values) w: List<int>.filled(24, 0)};
  for (final l in cravings) {
    final local = c.tracker.days.clock.toLocal(l.loggedAt);
    matrix[local.date.weekday]![local.hour]++;
  }
  return (
    triggers: pareto(cravings.map((l) => l.trigger)),
    places: pareto(cravings.map((l) => l.place)),
    moods: pareto(cravings.map((l) => l.mood?.toString())),
    matrix: [for (final w in Weekday.ordered(weekStart)) (w, matrix[w]!)],
  );
}

/// Whether a craving was resisted: an explicit `resisted` value wins; otherwise resisted when no use
/// follows within [window] (2 h).
bool cravingResisted(
  QuitLog craving,
  List<QuitLog> uses, {
  Duration window = const Duration(hours: 2),
}) {
  final explicit = craving.resisted;
  if (explicit != null) return explicit;
  final limit = craving.loggedAt.add(window);
  return !uses.any(
    (u) => !u.loggedAt.isBefore(craving.loggedAt) && !u.loggedAt.isAfter(limit),
  );
}

/// QT-15 — resist rate = cravings not followed by a use within 2 h ÷ cravings.
Stat<double> resistRate(QuitCalculator c, {Iterable<QuitLog>? cravings}) {
  final list = (cravings ?? _cravings(c)).toList();
  final uses = c.uses;
  return rate(list.where((l) => cravingResisted(l, uses)).length, list.length);
}

/// QT-16 — craving duration: median and P85 of `duration_seconds`, plus the histogram.
({Stat<double> medianSeconds, Stat<double> p85Seconds, Histogram histogram})
cravingDuration(QuitCalculator c) {
  final durations = [for (final l in _cravings(c)) ?l.durationSeconds];
  return (
    medianSeconds: MinDataRules.meanOrMedian.apply(median(durations)),
    p85Seconds: MinDataRules.p85.apply(p85(durations)),
    histogram: histogramFixedWidth(durations, 60, origin: 0),
  );
}

/// QT-17 — cravings per day for each week since qd (week 1 starts on qd's local date; the current
/// partial week uses its elapsed closed days) and the % change of the last full week vs week 1.
({List<(int week, double perDay)> weekly, Stat<double> changeVsWeek1})
cravingsDecline(QuitCalculator c) {
  final closed = c.closedDays;
  if (closed.isEmpty) {
    return (
      weekly: const <(int, double)>[],
      changeVsWeek1: const NotApplicable<double>(Reasons.noData),
    );
  }
  final start = closed.first.localDate;
  final counts = <int, int>{};
  final dayCounts = <int, int>{};
  for (final d in closed) {
    final w = start.daysUntil(d.localDate) ~/ 7 + 1;
    dayCounts[w] = (dayCounts[w] ?? 0) + 1;
  }
  for (final l in _cravings(c)) {
    final w = start.daysUntil(l.localDate) ~/ 7 + 1;
    if (dayCounts.containsKey(w)) counts[w] = (counts[w] ?? 0) + 1;
  }
  final weeks = dayCounts.keys.toList()..sort();
  final weekly = [for (final w in weeks) (w, (counts[w] ?? 0) / dayCounts[w]!)];
  final full = [
    for (final (w, v) in weekly)
      if (dayCounts[w] == 7) (w, v),
  ];
  return (
    weekly: weekly,
    changeVsWeek1: full.length < 2
        ? const Insufficient<double>(2, 1)
        : relativeDelta(full.last.$2, full.first.$2),
  );
}

/// QT-18 — lapse vs relapse per attempt (SRNT rules; Russell Standard after a 2-week grace).
List<(QuitAttempt, RelapseClassification)> lapseRelapse(QuitCalculator c) => [
  for (final a in c.attempts)
    (
      a,
      classifyRelapse(c.tracker.days.dateOf(a.start), [
        for (final u in a.uses) (u.localDate, u.amount),
      ]),
    ),
];

/// QT-19 — use analytics.
@immutable
final class const UseAnalytics({
  required final int episodes,
  required final Stat<double> meanAmount,
  required final Stat<double> meanDaysBetweenLapses,
  required final Map<Weekday, List<int>> matrix,
  required final List<ParetoEntry> precedingTriggers,
});

/// QT-19 — use episodes, mean amount per episode, mean days between use days, weekday × hour
/// matrix, and the Pareto of triggers of cravings logged ≤ 2 h before a use.
UseAnalytics useAnalytics(
  QuitCalculator c, {
  Duration window = const Duration(hours: 2),
}) {
  final uses = c.uses;
  final useDays = {for (final u in uses) u.localDate}.toList()..sort();
  final gaps = [
    for (var i = 1; i < useDays.length; i++)
      useDays[i - 1].daysUntil(useDays[i]).toDouble(),
  ];
  final matrix = {for (final w in Weekday.values) w: List<int>.filled(24, 0)};
  for (final u in uses) {
    final local = c.tracker.days.clock.toLocal(u.loggedAt);
    matrix[local.date.weekday]![local.hour]++;
  }
  final cravings = _cravings(c);
  return UseAnalytics(
    episodes: uses.length,
    meanAmount: mean(uses.map((u) => u.amount)),
    meanDaysBetweenLapses: mean(gaps),
    matrix: matrix,
    precedingTriggers: pareto([
      for (final cr in cravings)
        if (uses.any(
          (u) =>
              !u.loggedAt.isBefore(cr.loggedAt) &&
              u.loggedAt.difference(cr.loggedAt) <= window,
        ))
          cr.trigger,
    ]),
  );
}

/// QT-20 — attempts: number, mean and longest duration, and the rank of the current attempt by
/// duration (1 = longest).
({int count, Duration mean, Duration longest, int currentRank}) quitAttempts(
  QuitCalculator c,
) {
  final durations = [for (final a in c.attempts) a.durationAt(c.now)];
  final current = durations.last;
  final total = durations.fold(Duration.zero, (a, b) => a + b);
  return (
    count: durations.length,
    mean: Duration(microseconds: total.inMicroseconds ~/ durations.length),
    longest: durations.reduce((a, b) => a > b ? a : b),
    currentRank: 1 + durations.where((d) => d > current).length,
  );
}

/// QT-21 — savings goal: saved ÷ goal price and the ETA in days at the current daily saving
/// (baseline × unit cost in force today, or [dailySaving]).
({Stat<double> progress, Stat<int> etaDays}) savingsGoal(
  QuitCalculator c, {
  required Decimal goal,
  Decimal? dailySaving,
}) {
  final saved = c.moneySaved;
  final daily = dailySaving ?? c.savingsProjection?.perDay ?? Decimal.zero;
  return (
    progress: goal <= Decimal.zero
        ? const NotApplicable<double>(Reasons.zeroDenominator)
        : Value<double>(saved.toDouble() / goal.toDouble()),
    etaDays: savingsGoalEtaDays(saved: saved, goal: goal, dailySaving: daily),
  );
}

/// QT-23 — money saved per week or month (Decimal) and the mean saved per day.
({Map<LocalDate, Decimal> buckets, Stat<double> meanPerDay})
moneySavedPerPeriod(
  QuitCalculator c, {
  Granularity granularity = Granularity.week,
  Weekday weekStart = Weekday.monday,
}) {
  final buckets = <LocalDate, Decimal>{};
  for (final (date, amount) in c.moneySavedByDay) {
    final key = bucketStart(date, granularity, weekStart: weekStart);
    buckets[key] = (buckets[key] ?? Decimal.zero) + amount;
  }
  final closed = c.closedDays.length;
  return (
    buckets: buckets,
    meanPerDay: safeDivide(c.moneySaved.toDouble(), closed),
  );
}

/// QT-24 — pledge streak: consecutive local days with a pledge/review log (`clean` or `pledge`),
/// counted back from today (today counts once logged; an unlogged today does not break it).
int pledgeStreak(
  QuitCalculator c, {
  Set<HabitLogKind> kinds = const {HabitLogKind.clean, HabitLogKind.pledge},
}) {
  final days = {
    for (final l in c.logs)
      if (kinds.contains(l.kind)) l.localDate,
  };
  var day = c.tracker.days.dateOf(c.now);
  if (!days.contains(day)) day = day.minusDays(1);
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = day.minusDays(1);
  }
  return streak;
}

/// Withdrawal phase of the current abstinence (QT-25, NCI fact sheet; informational).
enum WithdrawalPhase { peak, firstWeek, easing, beyond }

/// QT-25 — days 1–3 peak, rest of week 1 worst, weeks 2–4 easing, then beyond; smoking only.
Stat<WithdrawalPhase> withdrawalPhase(QuitCalculator c) {
  if (c.tracker.substance != smokingSubstance) {
    return const NotApplicable<WithdrawalPhase>('notSmoking');
  }
  final days = c.currentAbstinence.inHours / 24;
  if (days < 3) return const Value(WithdrawalPhase.peak);
  if (days < 7) return const Value(WithdrawalPhase.firstWeek);
  if (days < 28) return const Value(WithdrawalPhase.easing);
  return const Value(WithdrawalPhase.beyond);
}

/// QT-26 — time-to-lapse survival across attempts (event = first lapse in an attempt, in hours;
/// attempts without a lapse are censored at their end — the current one at now). Hidden with
/// fewer than 2 attempts.
Stat<KaplanMeierResult> timeToLapseSurvival(QuitCalculator c) {
  SurvivalObservation observe(QuitAttempt a) => a.uses.isEmpty
      ? SurvivalObservation(a.durationAt(c.now).inMinutes / 60, event: false)
      : SurvivalObservation(
          a.uses.first.loggedAt.difference(a.start).inMinutes / 60,
          event: true,
        );
  return kaplanMeier(
    c.attempts.map(observe).toList(),
    minSubjects: MinDataRules.kaplanMeierAttempts.hiddenBelow.toInt(),
  );
}

/// QT-27 — resist rate by coping tool; tools with fewer than [minPerTool] (5) cravings are
/// [Insufficient] (greyed out).
Map<String, Stat<double>> copingEffectiveness(
  QuitCalculator c, {
  int minPerTool = 5,
}) {
  final byTool = <String, List<QuitLog>>{};
  for (final l in _cravings(c)) {
    final tool = l.coping?.trim().toLowerCase();
    if (tool == null || tool.isEmpty) continue;
    byTool.putIfAbsent(tool, () => []).add(l);
  }
  return {
    for (final e in byTool.entries)
      e.key: MinSampleRule(minPerTool).apply(resistRate(c, cravings: e.value)),
  };
}

/// QT-28 — craving-free time: time since the last craving (since qd without cravings) and the
/// longest craving-free stretch between qd, consecutive cravings and now.
({Duration sinceLast, Duration longest}) cravingFreeTime(QuitCalculator c) {
  final instants = [
    for (final l in _cravings(c))
      if (!l.loggedAt.isBefore(c.quitStartedAt)) l.loggedAt,
  ]..sort();
  var previous = c.quitStartedAt;
  var longest = Duration.zero;
  for (final t in [...instants, c.now]) {
    final gap = t.difference(previous);
    if (gap > longest) longest = gap;
    previous = t;
  }
  return (
    sinceLast: c.now.difference(
      instants.isEmpty ? c.quitStartedAt : instants.last,
    ),
    longest: longest,
  );
}

/// Day-milestone helper for the dashboard ring: the next day milestone and its ETA.
MilestoneProgress? nextDayMilestone(QuitCalculator c) {
  for (final m in milestoneProgress(
    defaultDayMilestones,
    abstinenceStart: c.currentAbstinenceStart,
    now: c.now,
  )) {
    if (m.isNext) return m;
  }
  return null;
}

/// Share helper for "you've been smoke-free 58 of 60 days" wording.
({int clean, int total}) cleanOfTotal(QuitCalculator c) =>
    (clean: c.cleanDays, total: math.max(0, c.closedDays.length));
