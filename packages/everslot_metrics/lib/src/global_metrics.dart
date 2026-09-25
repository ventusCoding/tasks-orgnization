/// Overview, reviews & insights calculators ([6.7], GL-01 … GL-18). Everything is composed from the
/// section catalogs' outputs, passed in as small per-day facts ([DaySectionFacts]) or plain values,
/// so the Overview numbers equal the section numbers exactly.
///
/// GL-12 (export) provides a pure CSV writer; GL-16 (custom dashboards) is layout/UI only and has no
/// computation here.
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/correlation.dart';
import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/forecast.dart';
import 'package:everslot_metrics/src/goals.dart';
import 'package:everslot_metrics/src/group_tests.dart';
import 'package:everslot_metrics/src/min_data.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/streaks.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:meta/meta.dart';

/// Per-day section facts (null = the section has no data that day).
@immutable
final class const DaySectionFacts(
  final LocalDate date, {
  final int? plannerPlanned,
  final int? plannerDone,
  final int? plannerDoneOnTime,
  final double? plannedMinutes,
  final double? actualMinutes,
  final double? deepWorkMinutes,
  final int? habitsDue,
  final int? habitsDone,
  final int? itemsCompleted,
  final bool? quitAbstinent,
  final Decimal? moneySaved,
  final int? cravings,
  final double? mood,
});

double _sumOf(
  Iterable<DaySectionFacts> days,
  num? Function(DaySectionFacts d) pick,
) => days.fold(0, (a, d) => a + (pick(d) ?? 0));

bool _any(
  Iterable<DaySectionFacts> days,
  Object? Function(DaySectionFacts d) pick,
) => days.any((d) => pick(d) != null);

// ---------------------------------------------------------------------------------------------
// GL-01 Today board, GL-02 week at a glance
// ---------------------------------------------------------------------------------------------

/// GL-01 — today board. Tiles are null when their section has no data (e.g. no quit trackers).
@immutable
final class const TodayBoard({
  required final Stat<double>? agendaProgress,
  required final Stat<double>? habitsProgress,
  required final bool? perfectDay,
  required final int? cravingsToday,
  required final int? itemsCompletedToday,
  required final int? wip,
  required final int? blocked,
  required final int? overdue,
  required final String? nextUpId,
});

/// GL-01 — agenda progress (PL-X-01 for today), habits done ÷ due (HB-X-01) and perfect-day status,
/// cravings today (QT-13), items completed today, WIP/blocked (CL-X-03), overdue (PL-X-06), next up.
TodayBoard todayBoard(
  DaySectionFacts today, {
  int? wip,
  int? blocked,
  int? overdue,
  String? nextUpId,
}) => TodayBoard(
  agendaProgress: today.plannerPlanned == null
      ? null
      : rate(today.plannerDone ?? 0, today.plannerPlanned!),
  habitsProgress: today.habitsDue == null
      ? null
      : rate(today.habitsDone ?? 0, today.habitsDue!),
  perfectDay: today.habitsDue == null || today.habitsDue == 0
      ? null
      : (today.habitsDone ?? 0) >= today.habitsDue!,
  cravingsToday: today.cravings,
  itemsCompletedToday: today.itemsCompleted,
  wip: wip,
  blocked: blocked,
  overdue: overdue,
  nextUpId: nextUpId,
);

/// Week KPIs (GL-02/GL-03 headline).
@immutable
final class const WeekKpis({
  required final Stat<double> completionVsPlan,
  required final Stat<double> onTimeRate,
  required final double plannedHours,
  required final double actualHours,
  required final Stat<double> habitSuccess,
  required final int itemsCompleted,
  required final Decimal moneySaved,
  required final bool hasPlanner,
  required final bool hasHabits,
  required final bool hasLists,
  required final bool hasQuit,
});

/// Aggregates day facts into week KPIs.
WeekKpis weekKpis(Iterable<DaySectionFacts> days) {
  final list = days.toList();
  return WeekKpis(
    completionVsPlan: rate(
      _sumOf(list, (d) => d.plannerDone),
      _sumOf(list, (d) => d.plannerPlanned),
    ),
    onTimeRate: rate(
      _sumOf(list, (d) => d.plannerDoneOnTime),
      _sumOf(list, (d) => d.plannerDone),
    ),
    plannedHours: _sumOf(list, (d) => d.plannedMinutes) / 60,
    actualHours: _sumOf(list, (d) => d.actualMinutes) / 60,
    habitSuccess: rate(
      _sumOf(list, (d) => d.habitsDone),
      _sumOf(list, (d) => d.habitsDue),
    ),
    itemsCompleted: _sumOf(list, (d) => d.itemsCompleted).round(),
    moneySaved: list.fold(
      Decimal.zero,
      (a, d) => a + (d.moneySaved ?? Decimal.zero),
    ),
    hasPlanner: _any(list, (d) => d.plannerPlanned),
    hasHabits: _any(list, (d) => d.habitsDue),
    hasLists: _any(list, (d) => d.itemsCompleted),
    hasQuit: _any(list, (d) => d.moneySaved ?? d.quitAbstinent),
  );
}

/// A KPI with its delta vs the previous period.
typedef KpiDelta = ({String metricId, PeriodComparison comparison});

List<KpiDelta> _compareKpis(WeekKpis cur, WeekKpis prev) => [
  if (cur.hasPlanner)
    (
      metricId: 'PL-X-01',
      comparison: compareWithPrevious(
        cur.completionVsPlan,
        prev.completionVsPlan,
        isRate: true,
      ),
    ),
  if (cur.hasPlanner)
    (
      metricId: 'PL-X-12',
      comparison: compareWithPrevious(
        Value(cur.actualHours),
        Value(prev.actualHours),
      ),
    ),
  if (cur.hasHabits)
    (
      metricId: 'HB-X-04',
      comparison: compareWithPrevious(
        cur.habitSuccess,
        prev.habitSuccess,
        isRate: true,
      ),
    ),
  if (cur.hasLists)
    (
      metricId: 'CL-X-04',
      comparison: compareWithPrevious(
        Value(cur.itemsCompleted.toDouble()),
        Value(prev.itemsCompleted.toDouble()),
      ),
    ),
  if (cur.hasQuit)
    (
      metricId: 'QT-07',
      comparison: compareWithPrevious(
        Value(cur.moneySaved.toDouble()),
        Value(prev.moneySaved.toDouble()),
      ),
    ),
];

/// GL-02 — this week to date vs the same weekdays of last week.
({WeekKpis current, WeekKpis previous, List<KpiDelta> deltas}) weekAtAGlance(
  List<DaySectionFacts> facts, {
  required LocalDate today,
  Weekday weekStart = Weekday.monday,
}) {
  final start = today.startOfWeek(weekStart);
  final elapsed = start.daysUntil(today) + 1;
  final cur = weekKpis(
    facts.where((f) => !f.date.isBefore(start) && !f.date.isAfter(today)),
  );
  final prevStart = start.minusDays(7);
  final prev = weekKpis(
    facts.where(
      (f) =>
          !f.date.isBefore(prevStart) &&
          f.date.isBefore(prevStart.plusDays(elapsed)),
    ),
  );
  return (current: cur, previous: prev, deltas: _compareKpis(cur, prev));
}

// ---------------------------------------------------------------------------------------------
// GL-03 weekly review, GL-04 review streak, GL-05 monthly review
// ---------------------------------------------------------------------------------------------

/// Kinds of review items.
enum ReviewItemKind {
  streakMilestone,
  perfectDays,
  healthMilestone,
  newRecord,
  overdueTasks,
  blockedWaiting,
  staleLists,
  overdueFollowUps,
  habitsAtRisk,
  overbookedDay,
}

/// One win or attention item (tapping it opens [entityId] when set).
@immutable
final class const ReviewItem(
  final ReviewItemKind kind, {
  final String? entityId,
  final num? value,
  final LocalDate? date,
});

/// Streak milestones announced in reviews and the insights feed: 7, 14, 21, 30, 50, 66, 100,
/// 150, 200, 365, then every 100.
bool isStreakMilestone(int length) {
  const fixed = {7, 14, 21, 30, 50, 66, 100, 150, 200, 365};
  if (fixed.contains(length)) return true;
  return length > 365 && length % 100 == 0;
}

/// Milestones crossed when a streak moves from [previous] to [current] (exclusive, inclusive].
List<int> streakMilestonesCrossed(int previous, int current) => [
  for (var n = previous + 1; n <= current; n++)
    if (isStreakMilestone(n)) n,
];

/// Inputs of the weekly review beyond the day facts.
@immutable
final class const WeeklyReviewInput({
  final List<({String entityId, int previous, int current})> streaks = const [],
  final List<String> healthMilestonesReached = const [],
  final List<String> newRecordKeys = const [],
  final List<String> overdueTaskIds = const [],
  final List<String> blockedOrWaitingItemIds = const [],
  final List<String> staleListIds = const [],
  final List<String> overdueFollowUpItemIds = const [],
  final List<String> habitsAtRiskIds = const [],
  final List<({String? categoryId, double minutes})> timeByCategory = const [],
  final List<({String? categoryId, double minutes})> previousTimeByCategory =
      const [],
  final List<({LocalDate date, double plannedMinutes, double capacityMinutes})>
      nextWeekLoad =
      const [],
});

/// GL-03 — the weekly review report.
@immutable
final class const WeeklyReport(
  final DateRange week, {
  required final WeekKpis current,
  required final WeekKpis previous,
  required final List<KpiDelta> headline,
  required final List<ReviewItem> wins,
  required final List<ReviewItem> attention,
  required final List<
    ({String? categoryId, double minutes, Stat<double> delta})
  >
  topCategories,
  required final List<
    ({
      LocalDate date,
      double plannedMinutes,
      double capacityMinutes,
      bool overbooked,
    })
  >
  nextWeek,
});

/// GL-03 — composes the weekly review for the week starting [weekStartDate] (default: the last
/// completed week): headline KPIs with Δ vs the previous week; wins (streak milestones, perfect
/// days, health milestones, new records); attention (overdue tasks, blocked/waiting items, stale
/// lists, overdue follow-ups, habits at risk); top-3 categories with Δ; next week's load vs
/// capacity with overbooked days flagged. Sections without data are hidden, never errors.
WeeklyReport buildWeeklyReview(
  List<DaySectionFacts> facts, {
  required LocalDate weekStartDate,
  WeeklyReviewInput input = const WeeklyReviewInput(),
}) {
  final week = DateRange(weekStartDate, weekStartDate.plusDays(6));
  final prevWeek = week.shiftDays(-7);
  final cur = weekKpis(facts.where((f) => week.contains(f.date)));
  final prev = weekKpis(facts.where((f) => prevWeek.contains(f.date)));
  final perfect = [
    for (final f in facts)
      if (week.contains(f.date) &&
          (f.habitsDue ?? 0) > 0 &&
          (f.habitsDone ?? 0) >= f.habitsDue!)
        f.date,
  ];
  final wins = <ReviewItem>[
    for (final s in input.streaks)
      for (final m in streakMilestonesCrossed(s.previous, s.current))
        ReviewItem(
          ReviewItemKind.streakMilestone,
          entityId: s.entityId,
          value: m,
        ),
    if (perfect.isNotEmpty)
      ReviewItem(ReviewItemKind.perfectDays, value: perfect.length),
    for (final h in input.healthMilestonesReached)
      ReviewItem(ReviewItemKind.healthMilestone, entityId: h),
    for (final r in input.newRecordKeys)
      ReviewItem(ReviewItemKind.newRecord, entityId: r),
  ];
  final attention = <ReviewItem>[
    for (final id in input.overdueTaskIds)
      ReviewItem(ReviewItemKind.overdueTasks, entityId: id),
    for (final id in input.blockedOrWaitingItemIds)
      ReviewItem(ReviewItemKind.blockedWaiting, entityId: id),
    for (final id in input.staleListIds)
      ReviewItem(ReviewItemKind.staleLists, entityId: id),
    for (final id in input.overdueFollowUpItemIds)
      ReviewItem(ReviewItemKind.overdueFollowUps, entityId: id),
    for (final id in input.habitsAtRiskIds)
      ReviewItem(ReviewItemKind.habitsAtRisk, entityId: id),
  ];
  final previousByCategory = {
    for (final c in input.previousTimeByCategory) c.categoryId: c.minutes,
  };
  final sortedCategories = [...input.timeByCategory]
    ..sort((a, b) => b.minutes.compareTo(a.minutes));
  final nextWeek = [
    for (final d in input.nextWeekLoad)
      (
        date: d.date,
        plannedMinutes: d.plannedMinutes,
        capacityMinutes: d.capacityMinutes,
        overbooked:
            d.capacityMinutes > 0 && d.plannedMinutes > d.capacityMinutes,
      ),
  ];
  return WeeklyReport(
    week,
    current: cur,
    previous: prev,
    headline: _compareKpis(cur, prev),
    wins: wins,
    attention: [
      ...attention,
      for (final d in nextWeek)
        if (d.overbooked)
          ReviewItem(
            ReviewItemKind.overbookedDay,
            date: d.date,
            value: d.plannedMinutes - d.capacityMinutes,
          ),
    ],
    topCategories: [
      for (final c in sortedCategories.take(3))
        (
          categoryId: c.categoryId,
          minutes: c.minutes,
          delta: previousByCategory.containsKey(c.categoryId)
              ? Value<double>(c.minutes - previousByCategory[c.categoryId]!)
              : const NotApplicable<double>(Reasons.isNew),
        ),
    ],
    nextWeek: nextWeek,
  );
}

/// GL-04 — weekly review streak: consecutive weeks with a completed guided review (the current
/// week is open until reviewed).
StreakSummary weeklyReviewStreak(
  Set<LocalDate> reviewedWeekStarts, {
  required LocalDate firstWeekStart,
  required LocalDate currentWeekStart,
}) => computeStreaks([
  for (var w = firstWeekStart; !w.isAfter(currentWeekStart); w = w.plusDays(7))
    StreakUnit(
      w.toIso(),
      start: w,
      end: w.plusDays(6),
      kind: reviewedWeekStarts.contains(w)
          ? StreakUnitKind.success
          : (w == currentWeekStart
                ? StreakUnitKind.open
                : StreakUnitKind.breaks),
    ),
]);

/// GL-05 — month-over-month comparison of a sum using per-day averages (never raw sums of unequal
/// months): Δ = cur/curDays − prev/prevDays.
PeriodComparison perDayComparison({
  required num currentSum,
  required int currentDays,
  required num previousSum,
  required int previousDays,
}) => compareWithPrevious(
  safeDivide(currentSum, currentDays),
  safeDivide(previousSum, previousDays),
);

// ---------------------------------------------------------------------------------------------
// GL-06 personal records, GL-07 day score, GL-08 day-of-week effects
// ---------------------------------------------------------------------------------------------

/// A personal record of one type (GL-06).
@immutable
final class const RecordEntry(
  final String type, {
  required final double value,
  required final LocalDate date,
  required final double? previous,
  required final bool isNew,
}) {
  /// Key stored in `user_settings.stats.announcedRecords`.
  String get announceKey => '$type|$value';
}

/// GL-06 — record of one type from a bucketed series: the maximum, its date and the previous
/// record; "new" when it beats every value before [currentPeriodStart] and lies in the current
/// period (backfilling old data never creates a "new record" dated today). [minBucketDenominator]
/// filters buckets (e.g. best weekly completion vs plan needs ≥ 10 planned tasks).
Stat<RecordEntry> personalRecord(
  String type,
  List<({LocalDate date, double value, num? denominator})> series, {
  required LocalDate currentPeriodStart,
  num? minBucketDenominator,
}) {
  final eligible = [
    for (final p in series)
      if (minBucketDenominator == null ||
          (p.denominator ?? 0) >= minBucketDenominator)
        p,
  ];
  if (eligible.isEmpty) return const Insufficient<RecordEntry>(1, 0);
  var best = eligible.first;
  for (final p in eligible) {
    if (p.value > best.value) best = p;
  }
  final before = [
    for (final p in eligible)
      if (p.date.isBefore(currentPeriodStart)) p.value,
  ];
  final previous = before.isEmpty ? null : before.reduce(math.max);
  return Value(
    RecordEntry(
      type,
      value: best.value,
      date: best.date,
      previous: previous,
      isNew:
          !best.date.isBefore(currentPeriodStart) &&
          (previous == null || best.value > previous),
    ),
  );
}

/// New records not yet announced ([announced] = stored keys).
List<RecordEntry> recordsToAnnounce(
  Iterable<RecordEntry> records,
  Set<String> announced,
) => [
  for (final r in records)
    if (r.isNew && !announced.contains(r.announceKey)) r,
];

/// GL-07 day-score weights (`user_settings.stats.dayScoreWeights`, default 1).
@immutable
final class const DayScoreWeights({
  final double planner = 1,
  final double habits = 1,
  final double lists = 1,
  final double quit = 1,
});

/// GL-07 — DS_d = Σ_k w_k·s_k,d ÷ Σ_k w_k over sections with data that day (0–100):
/// s_planner = done ÷ planned (plan snapshot at day start); s_habits = done ÷ due build units;
/// s_lists = min(1, completions ÷ median completions over the prior 28 active days);
/// s_quit = 1 if abstinent (reduce: within limit) else 0. Sections without data are excluded,
/// never counted as 0.
Stat<double> dayScore(
  DaySectionFacts day, {
  double? listsMedianPrior28,
  DayScoreWeights weights = const DayScoreWeights(),
}) {
  var weighted = 0.0;
  var total = 0.0;
  void add(double? score, double w) {
    if (score == null || w <= 0) return;
    weighted += w * score;
    total += w;
  }

  final planned = day.plannerPlanned;
  add(
    planned == null || planned == 0 ? null : (day.plannerDone ?? 0) / planned,
    weights.planner,
  );
  final due = day.habitsDue;
  add(
    due == null || due == 0 ? null : (day.habitsDone ?? 0) / due,
    weights.habits,
  );
  final items = day.itemsCompleted;
  add(
    items == null || listsMedianPrior28 == null || listsMedianPrior28 <= 0
        ? null
        : math.min(1, items / listsMedianPrior28).toDouble(),
    weights.lists,
  );
  final abstinent = day.quitAbstinent;
  add(abstinent == null ? null : (abstinent ? 1.0 : 0.0), weights.quit);
  if (total == 0) return const NotApplicable<double>(Reasons.noData);
  return Value<double>(100 * weighted / total);
}

/// Median list completions over the 28 active days (days with ≥ 1 completion) before [date].
double? listsMedianBefore(List<DaySectionFacts> facts, LocalDate date) {
  final prior = [
    for (final f in [...facts]..sort((a, b) => b.date.compareTo(a.date)))
      if (f.date.isBefore(date) && (f.itemsCompleted ?? 0) > 0)
        f.itemsCompleted!,
  ].take(28).toList();
  return median(prior).valueOrNull;
}

/// GL-07 series: day scores with the Δ vs the median DS of the prior 28 days.
List<({LocalDate date, Stat<double> score, Stat<double> deltaVsMedian})>
dayScoreSeries(
  List<DaySectionFacts> facts, {
  DayScoreWeights weights = const DayScoreWeights(),
}) {
  final sorted = [...facts]..sort((a, b) => a.date.compareTo(b.date));
  final scores = <LocalDate, double>{};
  final result =
      <({LocalDate date, Stat<double> score, Stat<double> deltaVsMedian})>[];
  for (final f in sorted) {
    final s = dayScore(
      f,
      listsMedianPrior28: listsMedianBefore(sorted, f.date),
      weights: weights,
    );
    final prior = [
      for (final e in scores.entries)
        if (e.key.isBefore(f.date) && !e.key.isBefore(f.date.minusDays(28)))
          e.value,
    ];
    final med = median(prior).valueOrNull;
    result.add((
      date: f.date,
      score: s,
      deltaVsMedian: s.valueOrNull == null || med == null
          ? const NotApplicable<double>(Reasons.noData)
          : Value<double>(s.valueOrNull! - med),
    ));
    final v = s.valueOrNull;
    if (v != null) scores[f.date] = v;
  }
  return result;
}

/// GL-08 — day-of-week effect of a daily metric.
@immutable
final class const WeekdayEffect(
  final Map<Weekday, double> means, {
  required final Weekday best,
  required final Weekday worst,
  required final KruskalWallisResult test,
  required final bool significant,
});

/// GL-08 — mean by weekday over ≥ 4 weeks (insufficient otherwise), Kruskal–Wallis across weekdays
/// (p < 0.05 → "significant", otherwise "no clear weekday pattern"), best/worst weekday, ε².
Stat<WeekdayEffect> dayOfWeekEffect(
  Map<LocalDate, double> daily, {
  double alpha = 0.05,
}) {
  if (daily.isEmpty) return const Insufficient<WeekdayEffect>(4, 0);
  final dates = daily.keys.toList()..sort();
  final weeks = (dates.first.daysUntil(dates.last) + 1) / 7;
  const rule = MinDataRules.dayOfWeekWeeks;
  if (weeks < rule.hiddenBelow) {
    return Insufficient<WeekdayEffect>(rule.hiddenBelow, weeks.floor());
  }
  final groups = <Weekday, List<double>>{};
  for (final e in daily.entries) {
    groups.putIfAbsent(e.key.weekday, () => []).add(e.value);
  }
  final means = {
    for (final e in groups.entries) e.key: sum(e.value) / e.value.length,
  };
  final ordered = Weekday.values.where(groups.containsKey).toList();
  final best = ordered.reduce((a, b) => means[b]! > means[a]! ? b : a);
  final worst = ordered.reduce((a, b) => means[b]! < means[a]! ? b : a);
  return kruskalWallis([for (final w in ordered) groups[w]!]).map(
    (kw) => WeekdayEffect(
      means,
      best: best,
      worst: worst,
      test: kw,
      significant: kw.pValue < alpha,
    ),
  );
}

// ---------------------------------------------------------------------------------------------
// GL-08 (T6.7.08) insights feed
// ---------------------------------------------------------------------------------------------

/// Insight triggers (T6.7.08 table) with their cooldowns (null = once per dedupe value).
enum InsightTrigger {
  newRecord(null),
  streakMilestone(null),
  significantTrend(Duration(days: 14)),
  estimationBias(Duration(days: 30)),
  risingOverdue(Duration(days: 7)),
  overbookedNextWeek(Duration(days: 7)),
  blockerCluster(Duration(days: 14)),
  followUpsDue(Duration(days: 3)),
  staleList(Duration(days: 14)),
  fallingCravings(Duration(days: 7)),
  healthMilestone(null),
  moneyMilestone(null),
  perfectWeek(Duration(days: 7)),
  bestWeekday(Duration(days: 30)),
  habitAtRisk(Duration(days: 1)),
  strengthThreshold(null),
  comeback(null),
  correlation(Duration(days: 30));

  new(this.cooldown);

  /// Per-entity cooldown after firing; null = never again for the same dedupe value.
  final Duration? cooldown;
}

/// A candidate insight: trigger, entity and value (dedupe = trigger|entity|value).
@immutable
final class const Insight(
  final InsightTrigger trigger, {
  required final String entityId,
  required final String valueKey,
  final Map<String, Object?> args = const {},
}) {
  String get dedupeKey => '${trigger.name}|$entityId|$valueKey';

  String get cooldownKey => '${trigger.name}|$entityId';
}

/// Local `insight_state` (dedupe key → fired at) plus muted trigger types.
@immutable
final class const InsightState({
  final Map<String, DateTime> firedAt = const {},
  final Set<InsightTrigger> muted = const {},
});

/// Filters candidates: muted triggers are dropped; a dedupe key fires once; a trigger with a
/// cooldown does not fire again for the same entity within the cooldown.
List<Insight> filterInsights(
  Iterable<Insight> candidates, {
  required InsightState state,
  required DateTime now,
}) {
  final lastByEntity = <String, DateTime>{};
  for (final e in state.firedAt.entries) {
    final parts = e.key.split('|');
    final key = '${parts[0]}|${parts.length > 1 ? parts[1] : ''}';
    final cur = lastByEntity[key];
    if (cur == null || e.value.isAfter(cur)) lastByEntity[key] = e.value;
  }
  final result = <Insight>[];
  final seen = <String>{};
  for (final c in candidates) {
    if (state.muted.contains(c.trigger)) continue;
    if (state.firedAt.containsKey(c.dedupeKey) || !seen.add(c.dedupeKey)) {
      continue;
    }
    final cooldown = c.trigger.cooldown;
    final last = lastByEntity[c.cooldownKey];
    if (cooldown != null && last != null && now.difference(last) < cooldown) {
      continue;
    }
    result.add(c);
  }
  return result;
}

/// Trigger 1 — a new personal record.
Insight? newRecordInsight(RecordEntry record) => record.isNew
    ? Insight(
        InsightTrigger.newRecord,
        entityId: record.type,
        valueKey: '${record.value}',
        args: {'value': record.value, 'previous': record.previous},
      )
    : null;

/// Trigger 2 — streak milestones crossed.
List<Insight> streakMilestoneInsights(
  String entityId,
  int previous,
  int current,
) => [
  for (final m in streakMilestonesCrossed(previous, current))
    Insight(
      InsightTrigger.streakMilestone,
      entityId: entityId,
      valueKey: '$m',
      args: {'streak': m},
    ),
];

/// Trigger 3 — adherence trend over ≥ 8 weeks with p < 0.05 and |slope| ≥ 2 pp/week (slope of a
/// rate series is converted to pp).
Insight? significantTrendInsight(
  String entityId,
  TrendResult trend, {
  required LocalDate today,
}) {
  final pp = trend.slopePerWeek * 100;
  if (!trend.significant || trend.n < 8 || pp.abs() < 2) return null;
  return Insight(
    InsightTrigger.significantTrend,
    entityId: entityId,
    valueKey: today.toIso(),
    args: {'ppPerWeek': pp},
  );
}

/// Trigger 4 — estimation bias > +20 % with n ≥ 10 in the last 30 days.
Insight? estimationBiasInsight(Stat<double> bias, {required LocalDate today}) {
  if (bias case Value<double>(:final value, :final sampleSize)) {
    if (value > 0.2 && (sampleSize ?? 0) >= 10) {
      return Insight(
        InsightTrigger.estimationBias,
        entityId: 'planner',
        valueKey: today.toIso(),
        args: {'bias': value},
      );
    }
  }
  return null;
}

/// Trigger 5 — overdue up ≥ 30 % vs 4 weeks ago and ≥ 5.
Insight? risingOverdueInsight(
  int now_,
  int fourWeeksAgo, {
  required LocalDate today,
}) {
  if (now_ < 5 || now_ < fourWeeksAgo * 1.3 || now_ <= fourWeeksAgo) {
    return null;
  }
  return Insight(
    InsightTrigger.risingOverdue,
    entityId: 'planner',
    valueKey: today.toIso(),
    args: {'count': now_, 'previous': fourWeeksAgo},
  );
}

/// Trigger 6 — ≥ 2 overbooked days next week.
Insight? overbookedNextWeekInsight(
  List<LocalDate> overbookedDays, {
  required LocalDate weekStart,
}) => overbookedDays.length >= 2
    ? Insight(
        InsightTrigger.overbookedNextWeek,
        entityId: 'planner',
        valueKey: weekStart.toIso(),
        args: {'days': overbookedDays},
      )
    : null;

/// Trigger 7 — ≥ 3 blocked episodes with the same normalized reason in 14 days.
List<Insight> blockerClusterInsights(
  List<({String cluster, DateTime startedAt})> blockedEpisodes, {
  required DateTime now,
}) {
  final counts = <String, int>{};
  for (final e in blockedEpisodes) {
    if (now.difference(e.startedAt) <= const Duration(days: 14)) {
      counts[e.cluster] = (counts[e.cluster] ?? 0) + 1;
    }
  }
  return [
    for (final e in counts.entries)
      if (e.value >= 3)
        Insight(
          InsightTrigger.blockerCluster,
          entityId: e.key,
          valueKey: '${e.value}',
          args: {'count': e.value},
        ),
  ];
}

/// Trigger 8 — ≥ 3 waiting items past their follow-up.
Insight? followUpsDueInsight(
  int overdueFollowUps, {
  required LocalDate today,
}) => overdueFollowUps >= 3
    ? Insight(
        InsightTrigger.followUpsDue,
        entityId: 'lists',
        valueKey: today.toIso(),
        args: {'count': overdueFollowUps},
      )
    : null;

/// Trigger 9 — a list with open items and no activity for ≥ N days.
Insight? staleListInsight(
  String listId,
  int daysInactive, {
  int threshold = 14,
}) => daysInactive >= threshold
    ? Insight(
        InsightTrigger.staleList,
        entityId: listId,
        valueKey: '$daysInactive',
        args: {'days': daysInactive},
      )
    : null;

/// Trigger 10 — 7-day mean cravings/day down ≥ 25 % vs the previous 7 days (≥ 5 cravings).
Insight? fallingCravingsInsight(
  String trackerId, {
  required int last7,
  required int previous7,
  required LocalDate today,
}) {
  if (previous7 < 5 || previous7 == 0) return null;
  final change = (last7 - previous7) / previous7;
  if (change > -0.25) return null;
  return Insight(
    InsightTrigger.fallingCravings,
    entityId: trackerId,
    valueKey: today.toIso(),
    args: {'change': change},
  );
}

/// Trigger 11 — a health milestone reached (once per milestone per attempt).
Insight healthMilestoneInsight(
  String trackerId,
  String milestoneId,
  int attempt,
) => Insight(
  InsightTrigger.healthMilestone,
  entityId: trackerId,
  valueKey: '$milestoneId#$attempt',
);

/// Money thresholds of trigger 12: 10, 50, 100, 250, 500, 1 000, 2 500, 5 000, 10 000, …
List<int> moneyThresholdsCrossed(Decimal previous, Decimal current) {
  Iterable<int> thresholds() sync* {
    yield 10;
    yield 50;
    for (var scale = 100; scale <= 1000000000; scale *= 10) {
      yield scale;
      yield scale * 5 ~/ 2;
      yield scale * 5;
    }
  }

  return [
    for (final t in thresholds().takeWhile(
      (t) => Decimal.fromInt(t) <= current,
    ))
      if (Decimal.fromInt(t) > previous) t,
  ];
}

/// Trigger 12 — money saved crossing thresholds.
List<Insight> moneyMilestoneInsights(
  String trackerId,
  Decimal previous,
  Decimal current,
) => [
  for (final t in moneyThresholdsCrossed(previous, current))
    Insight(
      InsightTrigger.moneyMilestone,
      entityId: trackerId,
      valueKey: '$t',
      args: {'amount': t},
    ),
];

/// Trigger 13 — perfect week: every due build habit done on every scheduled day.
Insight? perfectWeekInsight(
  List<DaySectionFacts> week, {
  required LocalDate weekStart,
}) {
  final due = [
    for (final d in week)
      if ((d.habitsDue ?? 0) > 0) d,
  ];
  if (due.isEmpty || due.any((d) => (d.habitsDone ?? 0) < d.habitsDue!)) {
    return null;
  }
  return Insight(
    InsightTrigger.perfectWeek,
    entityId: 'habits',
    valueKey: weekStart.toIso(),
  );
}

/// Trigger 14 — a weekday ≥ 15 pp above the mean over ≥ 4 weeks, with a significant GL-08 test.
Insight? bestWeekdayInsight(
  String entityId,
  WeekdayEffect effect, {
  required LocalDate today,
}) {
  if (!effect.significant) return null;
  final overall = sum(effect.means.values) / effect.means.length;
  final lead = effect.means[effect.best]! - overall;
  if (lead * 100 < 15) return null;
  return Insight(
    InsightTrigger.bestWeekday,
    entityId: entityId,
    valueKey: today.toIso(),
    args: {'weekday': effect.best.code, 'rate': effect.means[effect.best]},
  );
}

/// Trigger 15 — habit at risk (quota behind pace or score drop > 10 points in 7 days).
Insight? habitAtRiskInsight(
  String habitId, {
  required bool quotaBehind,
  required double scoreDrop7Days,
  required LocalDate today,
}) => quotaBehind || scoreDrop7Days > 0.10
    ? Insight(
        InsightTrigger.habitAtRisk,
        entityId: habitId,
        valueKey: today.toIso(),
      )
    : null;

/// Trigger 16 — strength crosses 50 % or 80 % upwards; re-arms after dropping below 70 %. Returns
/// the thresholds crossed within [scores] (chronological).
List<Insight> strengthThresholdInsights(
  String habitId,
  List<(LocalDate, double)> scores,
) {
  final result = <Insight>[];
  final armed = {0.5: true, 0.8: true};
  double? previous;
  var crossings = 0;
  for (final (date, s) in scores) {
    if (s < 0.7) armed[0.8] = true;
    if (s < 0.4) armed[0.5] = true;
    if (previous != null) {
      for (final t in armed.keys) {
        if (armed[t]! && previous < t && s >= t) {
          armed[t] = false;
          crossings++;
          result.add(
            Insight(
              InsightTrigger.strengthThreshold,
              entityId: habitId,
              valueKey: '$t#$crossings',
              args: {'threshold': t, 'date': date.toIso()},
            ),
          );
        }
      }
    }
    previous = s;
  }
  return result;
}

/// Trigger 17 — a comeback: a success after ≥ 3 consecutive misses ([outcomes]: true = success).
List<Insight> comebackInsights(
  String habitId,
  List<(LocalDate, bool)> outcomes,
) {
  final result = <Insight>[];
  var misses = 0;
  for (final (date, success) in outcomes) {
    if (success) {
      if (misses >= 3) {
        result.add(
          Insight(
            InsightTrigger.comeback,
            entityId: habitId,
            valueKey: date.toIso(),
          ),
        );
      }
      misses = 0;
    } else {
      misses++;
    }
  }
  return result;
}

/// Trigger 18 — a significant correlation pair after FDR.
Insight? correlationInsight(
  CorrelationFinding finding, {
  required LocalDate today,
}) => finding.significant
    ? Insight(
        InsightTrigger.correlation,
        entityId: '${finding.a}~${finding.b}',
        valueKey: today.toIso(),
        args: {'lag': finding.lag, 'coefficient': finding.coefficient},
      )
    : null;

// ---------------------------------------------------------------------------------------------
// GL-09 goals, GL-10 data quality, GL-11 heatmap, GL-12 CSV
// ---------------------------------------------------------------------------------------------

/// GL-09 — goals dashboard: active goals with projections (T5.4.03) and achieved goals.
({List<GoalProgress> active, List<GoalProgress> achieved}) goalsDashboard(
  List<GoalProgress> goals,
) => (
  active: [
    for (final g in goals)
      if (g.status != GoalStatus.achieved) g,
  ],
  achieved: [
    for (final g in goals)
      if (g.status == GoalStatus.achieved) g,
  ],
);

/// GL-10 — data-quality summary with guidance keys.
@immutable
final class const DataQualitySummary({
  required final Stat<double> habitLoggedRatio,
  required final int unknownUnits,
  required final Stat<double> backfillShare,
  required final Stat<double> plannerActualTimeCoverage,
  required final int pendingSyncChanges,
  required final List<String> guidanceKeys,
});

/// GL-10 — combines habit completeness (HB-X-12), planner actual-time coverage (PL-X-41) and the
/// pending outbox count, adding guidance keys (log from notifications, track time, sync caveat).
DataQualitySummary dataQuality({
  required Stat<double> habitLoggedRatio,
  required int unknownUnits,
  required Stat<double> backfillShare,
  required Stat<double> plannerActualTimeCoverage,
  required int pendingSyncChanges,
}) => DataQualitySummary(
  habitLoggedRatio: habitLoggedRatio,
  unknownUnits: unknownUnits,
  backfillShare: backfillShare,
  plannerActualTimeCoverage: plannerActualTimeCoverage,
  pendingSyncChanges: pendingSyncChanges,
  guidanceKeys: [
    if ((habitLoggedRatio.valueOrNull ?? 1) < 0.8 || unknownUnits > 0)
      'logFromNotifications',
    if ((backfillShare.valueOrNull ?? 0) > 0.2) 'logSameDay',
    if ((plannerActualTimeCoverage.valueOrNull ?? 1) < 0.6) 'trackTime',
    if (pendingSyncChanges > 0) 'syncPending',
  ],
);

/// GL-11 — year activity per day: done task occurrences + done habit units + completed items, with
/// the per-section breakdown; abstinent days are reported separately.
List<
  ({
    LocalDate date,
    int total,
    int tasks,
    int habits,
    int items,
    bool? abstinent,
  })
>
yearActivityHeatmap(List<DaySectionFacts> facts) => [
  for (final f in [...facts]..sort((a, b) => a.date.compareTo(b.date)))
    (
      date: f.date,
      total:
          (f.plannerDone ?? 0) + (f.habitsDone ?? 0) + (f.itemsCompleted ?? 0),
      tasks: f.plannerDone ?? 0,
      habits: f.habitsDone ?? 0,
      items: f.itemsCompleted ?? 0,
      abstinent: f.quitAbstinent,
    ),
];

/// GL-12 — CSV writer for exported series: machine-friendly (ISO dates, dot decimals), RFC 4180
/// quoting, optional UTF-8 BOM for Excel; RTL text is kept as is. A `#` header block lists the
/// metric definitions and the period.
String toCsv(
  List<String> columns,
  List<List<Object?>> rows, {
  List<String> headerComments = const [],
  bool bom = false,
}) {
  String cell(Object? v) {
    final s = switch (v) {
      null => '',
      final LocalDate d => d.toIso(),
      final DateTime t => t.toUtc().toIso8601String(),
      final double x => x.isFinite ? x.toString() : '',
      _ => v.toString(),
    };
    final needsQuotes = s.contains(RegExp(r'[",\n\r]'));
    return needsQuotes ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final buffer = StringBuffer();
  if (bom) buffer.write('﻿');
  for (final c in headerComments) {
    buffer.write('# $c\r\n');
  }
  buffer.write('${columns.map(cell).join(',')}\r\n');
  for (final r in rows) {
    buffer.write('${r.map(cell).join(',')}\r\n');
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------------------------
// GL-13 correlations explorer
// ---------------------------------------------------------------------------------------------

/// A candidate daily series for the correlations explorer.
@immutable
final class const DailySeries(
  final String id, {
  required final Map<LocalDate, double> values,
  required final bool binary,
  final String? groupKey,
});

/// Test used for a pair.
enum CorrelationMethod { phi, pointBiserial, spearman }

/// One tested pair.
@immutable
final class const CorrelationFinding(
  final String a,
  final String b, {
  required final int lag,
  required final CorrelationMethod method,
  required final double coefficient,
  required final int n,
  required final double pValue,
  required final double adjustedP,
  required final bool significant,
  required final int stars,
});

/// 1–5 stars from effect-size and significance bins.
int correlationStars(double coefficient, double adjustedP) {
  final r = coefficient.abs();
  var stars = r >= 0.7 ? 3 : (r >= 0.5 ? 2 : 1);
  if (adjustedP < 0.01) stars++;
  if (adjustedP < 0.001) stars++;
  return stars.clamp(1, 5);
}

/// GL-13 — tests every pair (and lag 0…[maxLag], a(d) vs b(d + lag)) of [series]: phi for binary ×
/// binary, point-biserial (with Mann–Whitney robustness) for binary × numeric, Spearman for numeric
/// × numeric. Guards: ≥ 21 paired days and ≥ 7 days per binary group; pairs sharing a `groupKey`
/// (same habit / derived metrics) are skipped; BH-FDR at [q] across all tests of the run; minimum
/// effect |phi| ≥ 0.2 or |ρ| ≥ 0.3. Results are ranked (significant first, then |coefficient|).
List<CorrelationFinding> correlationExplorer(
  List<DailySeries> series, {
  int maxLag = 3,
  double q = defaultFdrQ,
  int minPairs = 21,
  int minPerGroup = 7,
}) {
  final raw = <(String, String, int, CorrelationMethod, double, int, double)>[];
  for (var i = 0; i < series.length; i++) {
    for (var j = 0; j < series.length; j++) {
      if (i == j) continue;
      final a = series[i];
      final b = series[j];
      if (a.groupKey != null && a.groupKey == b.groupKey) continue;
      for (var lag = 0; lag <= maxLag; lag++) {
        if (lag == 0 && j < i) continue;
        final aligned = alignWithLag(a.values, b.values, lag: lag);
        if (aligned.a.length < minPairs) continue;
        final CorrelationMethod method;
        final Stat<CorrelationResult> result;
        if (a.binary && b.binary) {
          method = CorrelationMethod.phi;
          result = phiCoefficient(
            [for (final v in aligned.a) v > 0],
            [for (final v in aligned.b) v > 0],
          );
        } else if (a.binary || b.binary) {
          final flags = a.binary ? aligned.a : aligned.b;
          final values = a.binary ? aligned.b : aligned.a;
          final ones = flags.where((v) => v > 0).length;
          if (ones < minPerGroup || flags.length - ones < minPerGroup) continue;
          method = CorrelationMethod.pointBiserial;
          result = pointBiserial([for (final v in flags) v > 0], values);
        } else {
          method = CorrelationMethod.spearman;
          result = spearman(aligned.a, aligned.b);
        }
        if (result case Value<CorrelationResult>(:final value)) {
          raw.add((a.id, b.id, lag, method, value.r, value.n, value.pValue));
        }
      }
    }
  }
  final adjusted = benjaminiHochberg([for (final r in raw) r.$7]);
  final findings =
      [
        for (var k = 0; k < raw.length; k++)
          CorrelationFinding(
            raw[k].$1,
            raw[k].$2,
            lag: raw[k].$3,
            method: raw[k].$4,
            coefficient: raw[k].$5,
            n: raw[k].$6,
            pValue: raw[k].$7,
            adjustedP: adjusted[k],
            significant:
                adjusted[k] <= q &&
                meetsEffectThreshold(
                  raw[k].$5,
                  binaryPair: raw[k].$4 == CorrelationMethod.phi,
                ),
            stars: correlationStars(raw[k].$5, adjusted[k]),
          ),
      ]..sort((x, y) {
        if (x.significant != y.significant) return x.significant ? -1 : 1;
        return y.coefficient.abs().compareTo(x.coefficient.abs());
      });
  return findings;
}

// ---------------------------------------------------------------------------------------------
// GL-14 year in review, GL-15 XP, GL-17 time budget, GL-18 goal forecast
// ---------------------------------------------------------------------------------------------

/// Year-in-review archetypes (GL-14, rule-based).
enum Archetype { earlyBird, nightOwl, marathoner, consistent, finisher }

/// GL-14 — archetype labels: Early Bird (median first task start < 08:00), Night Owl (median last
/// check-in ≥ 22:00), Marathoner (≥ 200 deep-work hours), Consistent (habit success ≥ 85 %),
/// Finisher (≥ [finisherItems] items completed in the year; default 365).
List<Archetype> archetypes({
  double? medianFirstTaskStartMinute,
  double? medianLastCheckInMinute,
  double deepWorkHours = 0,
  double? habitSuccess,
  int itemsCompleted = 0,
  int finisherItems = 365,
}) => [
  if (medianFirstTaskStartMinute != null && medianFirstTaskStartMinute < 8 * 60)
    Archetype.earlyBird,
  if (medianLastCheckInMinute != null && medianLastCheckInMinute >= 22 * 60)
    Archetype.nightOwl,
  if (deepWorkHours >= 200) Archetype.marathoner,
  if (habitSuccess != null && habitSuccess >= 0.85) Archetype.consistent,
  if (itemsCompleted >= finisherItems) Archetype.finisher,
];

/// GL-14 — yearly aggregates of day facts: totals, busiest month and weekday (by total activity).
({
  int tasksDone,
  double plannedHours,
  double actualHours,
  int habitCheckIns,
  int itemsCompleted,
  Decimal moneySaved,
  int abstinentDays,
  int? busiestMonth,
  Weekday? busiestWeekday,
})
yearInNumbers(List<DaySectionFacts> facts) {
  final byMonth = <int, int>{};
  final byWeekday = <Weekday, int>{};
  for (final f in yearActivityHeatmap(facts)) {
    byMonth[f.date.month] = (byMonth[f.date.month] ?? 0) + f.total;
    byWeekday[f.date.weekday] = (byWeekday[f.date.weekday] ?? 0) + f.total;
  }
  K? argMax<K>(Map<K, int> m) => m.isEmpty
      ? null
      : m.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  return (
    tasksDone: _sumOf(facts, (d) => d.plannerDone).round(),
    plannedHours: _sumOf(facts, (d) => d.plannedMinutes) / 60,
    actualHours: _sumOf(facts, (d) => d.actualMinutes) / 60,
    habitCheckIns: _sumOf(facts, (d) => d.habitsDone).round(),
    itemsCompleted: _sumOf(facts, (d) => d.itemsCompleted).round(),
    moneySaved: facts.fold(
      Decimal.zero,
      (a, d) => a + (d.moneySaved ?? Decimal.zero),
    ),
    abstinentDays: facts.where((d) => d.quitAbstinent ?? false).length,
    busiestMonth: argMax(byMonth),
    busiestWeekday: argMax(byWeekday),
  );
}

/// Kinds of XP events (GL-15).
enum XpSource { taskCompletion, habitCheckIn, checklistLeaf, abstinentDay }

/// One XP event; [undone] removes its XP.
@immutable
final class const XpEvent(
  final DateTime at,
  final XpSource source, {
  final int priority = 0,
  final bool onTime = false,
  final int streak = 0,
  final bool undone = false,
});

/// GL-15 — XP of one event: task 10 × priority multiplier (none/low 1.0, medium 1.2, high 1.5,
/// urgent 2.0) × 1.1 when on time; habit check-in 10 × (1 + min(streak, 100)/100); checklist leaf
/// 5; abstinent day 20.
double xpFor(XpEvent e) => switch (e.source) {
  XpSource.taskCompletion =>
    10 *
        (switch (e.priority) {
          >= 4 => 2.0,
          3 => 1.5,
          2 => 1.2,
          _ => 1.0,
        }) *
        (e.onTime ? 1.1 : 1),
  XpSource.habitCheckIn => 10 * (1 + math.min(e.streak, 100) / 100),
  XpSource.checklistLeaf => 5,
  XpSource.abstinentDay => 20,
};

/// GL-15 — XP per local day with the daily cap (500) and undo removing XP; total and level
/// (cumulative threshold 100·n^1.5 for level n).
({Map<LocalDate, double> perDay, double total, int level, double toNextLevel})
xpSummary(
  List<XpEvent> events, {
  required DayBoundaries bounds,
  double dailyCap = 500,
}) {
  final raw = <LocalDate, double>{};
  for (final e in events) {
    final d = bounds.dateOf(e.at);
    raw[d] = (raw[d] ?? 0) + (e.undone ? -xpFor(e) : xpFor(e));
  }
  final perDay = {
    for (final e in raw.entries) e.key: e.value.clamp(0.0, dailyCap),
  };
  final total = perDay.values.fold<double>(0, (a, b) => a + b);
  var level = 0;
  while (100 * math.pow(level + 1, 1.5) <= total) {
    level++;
  }
  return (
    perDay: perDay,
    total: total,
    level: level,
    toNextLevel: 100 * math.pow(level + 1, 1.5) - total,
  );
}

/// GL-17 — time budget for one day: planned task minutes, duration-habit minutes, tracked focus
/// (with habit/session overlaps de-duplicated) and the remaining free time vs waking minutes.
({
  double plannedTasks,
  double habitMinutes,
  double trackedFocus,
  double overlap,
  double free,
})
timeBudget({
  required double plannedTaskMinutes,
  required List<(DateTime, DateTime)> habitIntervals,
  required List<(DateTime, DateTime)> sessionIntervals,
  double wakingMinutes = 16 * 60,
}) {
  double length(List<(DateTime, DateTime)> xs) {
    final sorted = [...xs]..sort((a, b) => a.$1.compareTo(b.$1));
    var total = 0.0;
    DateTime? s;
    DateTime? e;
    for (final (a, b) in sorted) {
      if (e == null || a.isAfter(e)) {
        if (s != null) total += e!.difference(s).inSeconds / 60;
        s = a;
        e = b;
      } else if (b.isAfter(e)) {
        e = b;
      }
    }
    if (s != null) total += e!.difference(s).inSeconds / 60;
    return total;
  }

  final habits = length(habitIntervals);
  final focus = length(sessionIntervals);
  final union = length([...habitIntervals, ...sessionIntervals]);
  final overlap = habits + focus - union;
  final used = math.max(plannedTaskMinutes, focus) + habits - overlap;
  return (
    plannedTasks: plannedTaskMinutes,
    habitMinutes: habits,
    trackedFocus: focus,
    overlap: overlap,
    free: math.max(0, wakingMinutes - used),
  );
}

/// GL-18 — Monte Carlo goal forecast: resamples daily progress over the last [historyDays] days
/// (default 6 weeks; ≥ 30 days required) to give the completion date at P50/P85/P95.
Stat<({LocalDate p50, LocalDate p85, LocalDate p95, ForecastWhen forecast})>
goalForecast(
  GoalProgress progress, {
  required Map<LocalDate, double> dailyValues,
  required math.Random random,
  int historyDays = 42,
  int trials = monteCarloTrials,
}) {
  final asOf = progress.asOf;
  final pool = [
    for (
      var d = asOf.minusDays(historyDays - 1);
      !d.isAfter(asOf);
      d = d.plusDays(1)
    )
      dailyValues[d] ?? 0.0,
  ];
  final remaining = math.max(0, progress.goal.target - progress.actual);
  return monteCarloWhen(
    pool: pool,
    remaining: remaining,
    random: random,
    trials: trials,
    minCompletions: 0,
  ).map(
    (f) => (
      p50: asOf.plusDays(f.p50Days),
      p85: asOf.plusDays(f.p85Days),
      p95: asOf.plusDays(f.p95Days),
      forecast: f,
    ),
  );
}
