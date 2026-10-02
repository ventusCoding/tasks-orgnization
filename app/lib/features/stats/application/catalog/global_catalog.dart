/// Overview & reports catalog ([6.7], GL-*): cross-section numbers built from the same section facts
/// and calculators as [6.3]–[6.6], so the Overview equals the section screens exactly.
library;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/checklist_catalog.dart';
import 'package:everslot/features/stats/application/catalog/data_quality.dart';
import 'package:everslot/features/stats/application/catalog/habit_catalog.dart';
import 'package:everslot/features/stats/application/catalog/planner_catalog.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/quit_health_content.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;

/// Batch context of the global scope (Overview, reviews, reports).
final class GlobalContext extends StatsContext {
  GlobalContext(super.job, super.resolver);

  @override
  late final DayBoundaries bounds = dayBoundariesOf(resolver, env.zoneId);

  late final LocalDate thisWeekStart = today.startOfWeek(weekStart);

  /// Days covered by the section facts: the period, two weeks back, the last 120 days (GL-10's
  /// 30 days, GL-07's 28 shown days with their 28-day medians) and next week.
  late final DateRange window = DateRange(
    LocalDate.min(
      LocalDate.min(range.start, previous.start),
      LocalDate.min(thisWeekStart.minusDays(14), today.minusDays(119)),
    ),
    LocalDate.max(range.end, thisWeekStart.plusDays(13)),
  );

  /// The last 30 days (data quality, GL-10).
  late final DateRange last30 = DateRange(today.minusDays(29), today);

  StatsJob _sub(MetricScope scope, [DateRange? r]) => StatsJob(
    request: StatsRequest(
      scope,
      selection: PeriodSelection(StatsPeriod.custom((r ?? window).start, (r ?? window).end), compare: false),
    ),
    env: env,
    metricIds: const [],
    planner: job.planner,
    checklists: job.checklists,
    habits: job.habits,
    pendingOutbox: job.pendingOutbox,
    firstDataDate: job.firstDataDate,
  );

  late final PlannerContext planner = PlannerContext(_sub(MetricScope.planner), resolver);
  late final ChecklistContext lists = ChecklistContext(_sub(MetricScope.checklists), resolver);
  late final HabitContext habits = HabitContext(_sub(MetricScope.habits), resolver);

  bool get hasPlanner => job.planner?.tasks.any((t) => !t.isUnscheduled) ?? false;
  bool get hasLists => job.checklists?.items.isNotEmpty ?? false;
  bool get hasHabits => habits.buildHabits.isNotEmpty;
  bool get hasQuit => habits.quitCalculators.isNotEmpty;

  late final Map<LocalDate, double> _completions = {
    for (final p in completionsPerDay(lists.sectionFacts, range: history, bounds: bounds)) p.bucket: p.value,
  };

  late final Map<LocalDate, List<int>> _moods = () {
    final map = <LocalDate, List<int>>{};
    for (final l in job.habits?.logs ?? const <HabitLogRecord>[]) {
      if (l.mood != null) map.putIfAbsent(l.localDate, () => []).add(l.mood!);
    }
    return map;
  }();

  /// Quit days and cravings per date (all trackers).
  late final Map<LocalDate, List<QuitDayFact>> _quitDays = () {
    final map = <LocalDate, List<QuitDayFact>>{};
    for (final q in habits.quitCalculators) {
      for (final d in q.days) {
        map.putIfAbsent(d.localDate, () => []).add(d);
      }
    }
    return map;
  }();

  late final Map<LocalDate, int> _cravings = () {
    final map = <LocalDate, int>{};
    for (final q in habits.quitCalculators) {
      for (final l in q.logs) {
        if (l.kind == HabitLogKind.craving) map[l.localDate] = (map[l.localDate] ?? 0) + 1;
      }
    }
    return map;
  }();

  /// Per-day section facts over [window] (null fields = no data in that section).
  late final List<DaySectionFacts> days = window == history
      ? historyDays
      : _DayFactsBuilder(this, planner).build(window);

  late final Map<LocalDate, DaySectionFacts> byDate = {for (final d in days) d.date: d};

  /// History covered by the multi-period metrics (records, heatmap, correlations, Wrapped): from
  /// the first data date (at most five years back) to the end of [window].
  late final DateRange history = () {
    final first = firstDataDate;
    if (first == null || !first.isBefore(window.start)) return window;
    return DateRange(LocalDate.max(first, today.minusDays(5 * 366)), window.end);
  }();

  /// Planner facts over [history] (the window's when it covers the history).
  late final PlannerContext historyPlanner = history == window
      ? planner
      : PlannerContext(_sub(MetricScope.planner, history), resolver);

  /// Per-day section facts over [history].
  late final List<DaySectionFacts> historyDays = _DayFactsBuilder(this, historyPlanner).build(history);

  /// Day facts of [r] (dates outside the history are absent); ranges inside [window] never
  /// resolve the whole history.
  List<DaySectionFacts> daysIn(DateRange r) => [
    for (final d in !r.start.isBefore(window.start) && !r.end.isAfter(window.end) ? days : historyDays)
      if (r.contains(d.date)) d,
  ];

  /// The week reviewed by GL-03: the last completed week, or this week so far (`extra: current`).
  late final LocalDate reviewWeekStart = request.extra == 'current' ? thisWeekStart : thisWeekStart.minusDays(7);

  String currency() {
    for (final q in habits.quitCalculators) {
      final c = q.tracker.currency;
      if (c != null && c.isNotEmpty) return c;
    }
    return env.currency;
  }
}

/// Builds [DaySectionFacts] for a date range. Planner facts are bucketed by every date they were
/// ever planned on (final start and each move's origin/target), so each day's plan snapshot only
/// scans its own candidates — the same result as scanning every fact, in linear time.
final class _DayFactsBuilder {
  _DayFactsBuilder(this.c, this.planner);

  final GlobalContext c;
  final PlannerContext planner;

  List<DaySectionFacts> build(DateRange r) {
    final buckets = <LocalDate, List<PlannerOccurrenceFact>>{};
    if (c.hasPlanner) {
      for (final f in planner.facts) {
        final dates = <LocalDate>{
          if (f.plannedStartLocal case final s?) s.date,
          for (final m in f.moves) ...[m.fromStart.date, m.toStart.date],
        };
        for (final d in dates) {
          buckets.putIfAbsent(d, () => []).add(f);
        }
      }
    }
    final capacity = c.hasPlanner
        ? {
            for (final d in capacityReport(
              planner.plannedIn(r),
              range: r,
              clock: planner.clock,
              settings: planner.ps,
            ).days)
              d.date: d,
          }
        : const <LocalDate, CapacityDay>{};
    final deepWork = <LocalDate, double>{};
    if (c.hasPlanner) {
      for (final b in deepWorkBlocks(planner.plannedIn(r), settings: planner.ps)) {
        final d = planner.clock.toLocal(b.start).date;
        deepWork[d] = (deepWork[d] ?? 0) + b.tracked.inSeconds / 60;
      }
    }
    return [for (final d in r.dates) _day(d, buckets[d] ?? const [], capacity[d], deepWork[d])];
  }

  DaySectionFacts _day(LocalDate d, List<PlannerOccurrenceFact> candidates, CapacityDay? cap, double? deepWork) {
    final today = c.today;
    final now = c.now;
    int? planned;
    int? done;
    int? onTime;
    if (c.hasPlanner && !d.isAfter(today)) {
      final snap = planSnapshot(candidates, period: DateRange(d, d), bounds: c.bounds, now: now);
      planned = snap.planned.length;
      done = snap.plannedDone.length;
      onTime = snap.plannedDone
          .where((f) => plannerOutcome(f, now: now, settings: planner.ps) == PlannerOutcome.doneOnTime)
          .length;
    }
    int? due;
    int? habitsDone;
    if (c.hasHabits && !d.isAfter(today)) {
      due = 0;
      habitsDone = 0;
      for (final h in c.habits.series) {
        for (final r in h.dayUnitsOn(d)) {
          if (!h.isDue(r)) continue;
          due = due! + 1;
          if (r.status == PeriodStatus.done) habitsDone = habitsDone! + 1;
        }
      }
    }
    bool? abstinent;
    Decimal? money;
    int? cravings;
    if (c.hasQuit && !d.isAfter(today)) {
      abstinent = true;
      money = Decimal.zero;
      for (final day in c._quitDays[d] ?? const <QuitDayFact>[]) {
        if (!day.abstinent) abstinent = false;
        if (day.cpu != null) money = money! + Decimal.parse(day.avoided.toString()) * day.cpu!;
      }
      cravings = c._cravings[d] ?? 0;
    }
    final moods = c._moods[d];
    return DaySectionFacts(
      d,
      plannerPlanned: planned,
      plannerDone: done,
      plannerDoneOnTime: onTime,
      plannedMinutes: c.hasPlanner ? cap?.plannedMinutes ?? 0 : null,
      actualMinutes: c.hasPlanner ? cap?.actualMinutes ?? 0 : null,
      deepWorkMinutes: c.hasPlanner ? deepWork ?? 0 : null,
      habitsDue: due,
      habitsDone: habitsDone,
      itemsCompleted: c.hasLists && !d.isAfter(today) ? (c._completions[d] ?? 0).round() : null,
      quitAbstinent: abstinent,
      moneySaved: money,
      cravings: cravings,
      mood: moods == null || moods.isEmpty ? null : moods.reduce((a, b) => a + b) / moods.length,
    );
  }
}

const globalTables = {
  StatsTable.tasks,
  StatsTable.taskOccurrences,
  StatsTable.checklistItems,
  StatsTable.habits,
  StatsTable.habitLogs,
};

ValueTile globalKpiTile(KpiDelta k, {required String currency}) {
  final c = k.comparison;
  final (LabelToken token, StatUnit unit, MetricDirection dir) = switch (k.metricId) {
    'PL-X-01' => (LabelToken.agenda, StatUnit.percent, MetricDirection.higherIsBetter),
    'PL-X-12' => (LabelToken.actual, StatUnit.hours, MetricDirection.neutral),
    'HB-X-04' => (LabelToken.habits, StatUnit.percent, MetricDirection.higherIsBetter),
    'CL-X-04' => (LabelToken.items, StatUnit.count, MetricDirection.higherIsBetter),
    'QT-07' => (LabelToken.money, StatUnit.currency, MetricDirection.higherIsBetter),
    _ => (LabelToken.current, StatUnit.count, MetricDirection.neutral),
  };
  return ValueTile(
    TokenLabel(token),
    c.current.valueOrNull,
    unit,
    delta: c.delta.valueOrNull,
    deltaIsPp: c.isRate,
    direction: dir,
    metricId: k.metricId,
    currency: unit == StatUnit.currency ? currency : null,
  );
}

/// Habit adherence over [r] exactly as HB-X-04 defines it (closed scheduled units — quota periods
/// included — minus excluded units, archived habits dropped after their archive date), so the
/// Overview and review tiles equal the Habits screen.
Stat<double> habitAdherenceIn(GlobalContext c, DateRange r) {
  var done = 0;
  var total = 0;
  for (final h in c.habits.series) {
    for (final u in h.results) {
      if (!isClosedScheduled(u) || isExcludedUnit(u, skipPolicy: h.skipPolicy)) continue;
      if (h.archivedOn != null && u.startDate.isAfter(h.archivedOn!)) continue;
      if (!r.contains(u.endDate)) continue;
      total++;
      if (u.status == PeriodStatus.done) done++;
    }
  }
  return rate(done, total);
}

/// Replaces the day-fact habit KPI of [kpis] with [_habitAdherence] over [current] vs [previous].
List<KpiDelta> _withHabitAdherence(GlobalContext c, List<KpiDelta> kpis, DateRange current, DateRange previous) => [
  for (final k in kpis)
    if (k.metricId == 'HB-X-04')
      (
        metricId: k.metricId,
        comparison: compareWithPrevious(habitAdherenceIn(c, current), habitAdherenceIn(c, previous), isRate: true),
      )
    else
      k,
];

/// Every overview metric.
final List<MetricDefinition> globalMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Overview (T6.7.01)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-01',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    requires: globalTables,
    compute: (c) {
      final today = c.byDate[c.today] ?? DaySectionFacts(c.today);
      final wip = c.hasLists
          ? globalWip(c.lists.sectionFacts, now: c.now, archivedListIds: c.lists.data.archivedListIds)
          : null;
      final overdue = c.hasPlanner
          ? [
              for (final f in c.planner.facts)
                if (overdueAge(f, now: c.now).hasValue) f,
            ]
          : null;
      final next = c.hasPlanner
          ? c.planner.facts.firstWhereOrNull(
              (f) =>
                  f.plannedStart != null &&
                  f.plannedStart!.isAfter(c.now) &&
                  c.bounds.dateOf(f.plannedStart!) == c.today &&
                  f.status == PlannerOccurrenceStatus.scheduled &&
                  f.trackingMode.countsForCompletion,
            )
          : null;
      final board = todayBoard(
        today,
        wip: wip?.wip,
        blocked: wip?.blocked,
        overdue: overdue?.length,
        nextUpId: next?.taskId,
      );
      return chartResult(
        'GL-01',
        TilesData([
          if (board.agendaProgress case final p?)
            ValueTile(
              const TokenLabel(LabelToken.agenda),
              p.valueOrNull,
              StatUnit.percent,
              metricId: 'PL-X-01',
              secondary: NumberLabel((today.plannerPlanned ?? 0).toDouble(), StatUnit.count),
            ),
          if (board.habitsProgress case final p?)
            ValueTile(
              const TokenLabel(LabelToken.habits),
              p.valueOrNull,
              StatUnit.percent,
              metricId: 'HB-X-01',
              secondary: board.perfectDay == true ? const TokenLabel(LabelToken.perfectDay) : null,
            ),
          if (board.cravingsToday case final v?)
            ValueTile(
              const TokenLabel(LabelToken.cravings),
              v.toDouble(),
              StatUnit.count,
              metricId: 'QT-13',
              direction: MetricDirection.lowerIsBetter,
            ),
          if (board.itemsCompletedToday case final v?)
            ValueTile(const TokenLabel(LabelToken.items), v.toDouble(), StatUnit.count, metricId: 'CL-X-04'),
          if (board.wip case final v?)
            ValueTile(
              const TokenLabel(LabelToken.wip),
              v.toDouble(),
              StatUnit.count,
              metricId: 'CL-X-03',
              drillKey: 'wip',
            ),
          if (board.blocked case final v?)
            ValueTile(
              const TokenLabel(LabelToken.blocked),
              v.toDouble(),
              StatUnit.count,
              metricId: 'CL-X-03',
              drillKey: 'blocked',
              direction: MetricDirection.lowerIsBetter,
            ),
          if (board.overdue case final v?)
            ValueTile(
              const TokenLabel(LabelToken.overdue),
              v.toDouble(),
              StatUnit.count,
              metricId: 'PL-X-06',
              drillKey: 'overdue',
              direction: MetricDirection.lowerIsBetter,
            ),
        ]),
        value: const Value<double>(1),
        args: {
          if (next != null) 'nextUpTitle': next.title,
          if (next?.plannedStartLocal != null) 'nextUpAt': next!.plannedStartLocal!.toIso(),
          'perfectDay': board.perfectDay,
        },
        drill: {
          if (overdue != null) 'overdue': c.planner.refs(overdue),
          if (wip != null) 'wip': c.lists.refs(c.lists.sectionFacts.where((f) => !f.isDeleted && f.status.isWip)),
          if (wip != null)
            'blocked': c.lists.refs(c.lists.sectionFacts.where((f) => !f.isDeleted && f.status == ItemStatus.blocked)),
          if (next != null) 'nextUp': c.planner.refs([next]),
        },
      );
    },
  ),
  metric<GlobalContext>(
    id: 'GL-02',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    requires: globalTables,
    compute: (c) {
      final w = weekAtAGlance(c.days, today: c.today, weekStart: c.weekStart);
      final currency = c.currency();
      final elapsed = c.thisWeekStart.daysUntil(c.today);
      final deltas = _withHabitAdherence(
        c,
        w.deltas,
        DateRange(c.thisWeekStart, c.today),
        DateRange(c.thisWeekStart.minusDays(7), c.thisWeekStart.minusDays(7).plusDays(elapsed)),
      );
      return chartResult(
        'GL-02',
        TilesData([for (final k in deltas) globalKpiTile(k, currency: currency)]),
        value: Value<double>(w.deltas.length.toDouble()),
        args: {'plannedHours': w.current.plannedHours, 'previousPlannedHours': w.previous.plannedHours},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Weekly review (T6.7.02)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-03',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    requires: globalTables,
    compute: (c) {
      final week = DateRange(c.reviewWeekStart, c.reviewWeekStart.plusDays(6));
      final prevWeek = week.shiftDays(-7);
      final nextWeek = DateRange(c.thisWeekStart.plusDays(7), c.thisWeekStart.plusDays(13));
      // Streak milestones crossed during the week (habits and planner series).
      final streaks = <({String entityId, int previous, int current})>[];
      if (c.hasHabits) {
        for (final e in c.habits.evaluations) {
          StreakSummary upTo(LocalDate d) => habitStreaks(
            [
              for (final u in e.streakUnits)
                if (!u.endDate.isAfter(d)) u,
            ],
            skipPolicy: e.skipPolicy,
            freezesPerMonth: e.habit.freezesPerMonth,
          );
          streaks.add((
            entityId: e.habit.id,
            previous: upTo(week.start.minusDays(1)).currentLength,
            current: upTo(LocalDate.min(week.end, c.today)).currentLength,
          ));
        }
      }
      final health = <String>[];
      for (final q in c.habits.quitCalculators) {
        if (q.tracker.substance != smokingSubstance) continue;
        final start = q.currentAbstinenceStart;
        for (final m in smokingHealthMilestones) {
          final at = c.bounds.dateOf(start.add(m.tMax ?? m.tMin));
          if (week.contains(at) && !start.add(m.tMax ?? m.tMin).isAfter(c.now)) health.add(m.id);
        }
      }
      final overdue = c.hasPlanner
          ? [
              for (final f in c.planner.facts)
                if (overdueAge(f, now: c.now).hasValue) f,
            ]
          : <PlannerOccurrenceFact>[];
      final blocked = c.hasLists
          ? [
              for (final f in c.lists.sectionFacts)
                if (!f.isDeleted && (f.status == ItemStatus.blocked || f.status == ItemStatus.waiting)) f,
            ]
          : <ChecklistItemFact>[];
      final stale = c.hasLists
          ? listsOverview(
              c.lists.data.lists,
              c.lists.data.facts,
              now: c.now,
              staleDays: c.settings.staleDays,
            ).staleListIds
          : const <String>[];
      List<({String? categoryId, double minutes})> byCategory(DateRange r) => [
        for (final s in timeByCategory(c.planner.plannedIn(r)).slices) (categoryId: s.key, minutes: s.minutes),
      ];
      final nextCapacity = c.hasPlanner
          ? capacityReport(
              c.planner.plannedIn(nextWeek),
              range: nextWeek,
              clock: c.planner.clock,
              settings: c.planner.ps,
            ).days
          : const <CapacityDay>[];
      final report = buildWeeklyReview(
        c.days,
        weekStartDate: week.start,
        input: WeeklyReviewInput(
          streaks: streaks,
          healthMilestonesReached: health,
          overdueTaskIds: [for (final f in overdue) f.taskId],
          blockedOrWaitingItemIds: [for (final f in blocked) f.id],
          staleListIds: stale,
          timeByCategory: c.hasPlanner ? byCategory(week) : const [],
          previousTimeByCategory: c.hasPlanner ? byCategory(prevWeek) : const [],
          nextWeekLoad: [
            for (final d in nextCapacity)
              (date: d.date, plannedMinutes: d.plannedMinutes, capacityMinutes: d.capacityMinutes),
          ],
        ),
      );
      final overdueById = {for (final f in overdue) f.taskId: f};
      final blockedById = {for (final f in blocked) f.id: f};
      DrillRef? refOf(ReviewItem i) => switch (i.kind) {
        ReviewItemKind.overdueTasks =>
          overdueById[i.entityId] == null ? null : c.planner.refs([overdueById[i.entityId]!]).first,
        ReviewItemKind.blockedWaiting =>
          blockedById[i.entityId] == null ? null : c.lists.itemRef(blockedById[i.entityId]!),
        ReviewItemKind.staleLists => DrillRef(
          DrillKind.checklist,
          i.entityId!,
          title: c.lists.data.listById(i.entityId!)?.title,
        ),
        ReviewItemKind.streakMilestone || ReviewItemKind.habitsAtRisk =>
          i.entityId == null ? null : DrillRef(DrillKind.habit, i.entityId!, title: c.habits.byId[i.entityId]?.name),
        _ => null,
      };
      String? titleOf(ReviewItem i) => switch (i.kind) {
        ReviewItemKind.overdueTasks => overdueById[i.entityId]?.title,
        ReviewItemKind.blockedWaiting => blockedById[i.entityId]?.row.text,
        ReviewItemKind.staleLists => c.lists.data.listById(i.entityId ?? '')?.title,
        ReviewItemKind.streakMilestone || ReviewItemKind.habitsAtRisk => c.habits.byId[i.entityId]?.name,
        ReviewItemKind.healthMilestone => i.entityId,
        _ => null,
      };
      ReviewEntry entry(ReviewItem i) => ReviewEntry(
        ReviewEntryKind.values.byName(i.kind.name),
        ref: refOf(i),
        title: titleOf(i),
        value: i.value?.toDouble(),
        date: i.date,
      );
      final currency = c.currency();
      return chartResult(
        'GL-03',
        ReviewData(
          from: week.start,
          to: week.end,
          headline: [
            for (final k in _withHabitAdherence(
              c,
              report.headline,
              DateRange(week.start, LocalDate.min(week.end, c.today)),
              prevWeek,
            ))
              globalKpiTile(k, currency: currency),
          ],
          wins: [for (final w in report.wins) entry(w)],
          attention: [for (final a in report.attention) entry(a)],
          topCategories: [
            for (final t in report.topCategories)
              (c.planner.categoryLabel(t.categoryId), t.minutes, t.delta.valueOrNull),
          ],
          nextWeek: [for (final d in report.nextWeek) (d.date, d.plannedMinutes, d.capacityMinutes, d.overbooked)],
        ),
        value: Value<double>(report.headline.length.toDouble()),
        args: {'week': week.start.toIso(), 'current': c.request.extra == 'current'},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Data quality (T6.7.10, plumbing T6.1.20)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-10',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: {...globalTables, StatsTable.syncOutbox},
    compute: (c) {
      final habits = c.hasHabits ? habitCompletenessIn(c.habits.evaluations, c.last30) : null;
      final coverage = c.hasPlanner ? actualTimeCoverage(c.planner.plannedIn(c.last30)) : null;
      const none = NotApplicable<double>(Reasons.noData);
      final q = dataQuality(
        habitLoggedRatio: habits?.loggedRatio ?? none,
        unknownUnits: habits?.unknownUnits ?? 0,
        backfillShare: habits?.backfillShare ?? none,
        plannerActualTimeCoverage: coverage ?? none,
        pendingSyncChanges: c.job.pendingOutbox,
      );
      return chartResult(
        'GL-10',
        TilesData([
          if (habits != null) ...completenessTiles(habits).tiles,
          if (coverage != null)
            ValueTile(
              const TokenLabel(LabelToken.trackedTime),
              coverage.valueOrNull,
              StatUnit.percent,
              metricId: 'PL-X-41',
            ),
          ValueTile(
            const TokenLabel(LabelToken.pendingSync),
            c.job.pendingOutbox.toDouble(),
            StatUnit.count,
            direction: MetricDirection.lowerIsBetter,
          ),
        ]),
        value: Value<double>(q.guidanceKeys.length.toDouble()),
        args: {
          'guidance': q.guidanceKeys,
          'pending': c.job.pendingOutbox,
          'loggedRatio': habits?.loggedRatio.valueOrNull,
          'unknown': habits?.unknownUnits,
          'backfill': habits?.backfillShare.valueOrNull,
          'coverage': coverage?.valueOrNull,
        },
        drill: {
          if (habits != null)
            'unknown': [
              for (final e in c.habits.evaluations)
                for (final u in unloggedUnits(e, c.last30)) c.habits.dayRef(e.habit.id, u.startDate),
            ].take(200).toList(),
        },
      );
    },
  ),
];
