/// Overview & reports catalog ([6.7], GL-*): cross-section numbers built from the same section facts
/// and calculators as [6.3]–[6.6], so the Overview equals the section screens exactly.
library;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/checklist_catalog.dart';
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

  /// Days covered by the section facts: the period plus two weeks back and next week.
  late final DateRange window = DateRange(
    LocalDate.min(LocalDate.min(range.start, previous.start), thisWeekStart.minusDays(14)),
    LocalDate.max(range.end, thisWeekStart.plusDays(13)),
  );

  StatsJob _sub(MetricScope scope) => StatsJob(
    request: StatsRequest(
      scope,
      selection: PeriodSelection(StatsPeriod.custom(window.start, window.end), compare: false),
    ),
    env: env,
    metricIds: const [],
    planner: job.planner,
    checklists: job.checklists,
    habits: job.habits,
    pendingOutbox: job.pendingOutbox,
  );

  late final PlannerContext planner = PlannerContext(_sub(MetricScope.planner), resolver);
  late final ChecklistContext lists = ChecklistContext(_sub(MetricScope.checklists), resolver);
  late final HabitContext habits = HabitContext(_sub(MetricScope.habits), resolver);

  bool get hasPlanner => job.planner?.tasks.any((t) => !t.isUnscheduled) ?? false;
  bool get hasLists => job.checklists?.items.isNotEmpty ?? false;
  bool get hasHabits => habits.buildHabits.isNotEmpty;
  bool get hasQuit => habits.quitCalculators.isNotEmpty;

  late final Map<LocalDate, CapacityDay> _capacityDays = {
    for (final d in capacityReport(
      planner.plannedIn(window),
      range: window,
      clock: planner.clock,
      settings: planner.ps,
    ).days)
      d.date: d,
  };

  late final Map<LocalDate, double> _completions = {
    for (final p in completionsPerDay(lists.sectionFacts, range: window, bounds: bounds)) p.bucket: p.value,
  };

  late final Map<LocalDate, List<int>> _moods = () {
    final map = <LocalDate, List<int>>{};
    for (final l in job.habits?.logs ?? const <HabitLogRecord>[]) {
      if (l.mood != null) map.putIfAbsent(l.localDate, () => []).add(l.mood!);
    }
    return map;
  }();

  /// Per-day section facts over [window] (null fields = no data in that section).
  late final List<DaySectionFacts> days = [for (final d in window.dates) _day(d)];

  late final Map<LocalDate, DaySectionFacts> byDate = {for (final d in days) d.date: d};

  DaySectionFacts _day(LocalDate d) {
    int? planned;
    int? done;
    int? onTime;
    double? plannedMinutes;
    double? actualMinutes;
    if (hasPlanner && !d.isAfter(today)) {
      final snap = planSnapshot(planner.facts, period: DateRange(d, d), bounds: bounds, now: now);
      planned = snap.planned.length;
      done = snap.plannedDone.length;
      onTime = snap.plannedDone
          .where((f) => plannerOutcome(f, now: now, settings: planner.ps) == PlannerOutcome.doneOnTime)
          .length;
    }
    if (hasPlanner) {
      final cap = _capacityDays[d];
      plannedMinutes = cap?.plannedMinutes ?? 0;
      actualMinutes = cap?.actualMinutes ?? 0;
    }
    int? due;
    int? habitsDone;
    if (hasHabits && !d.isAfter(today)) {
      due = 0;
      habitsDone = 0;
      for (final h in habits.series) {
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
    if (hasQuit && !d.isAfter(today)) {
      abstinent = true;
      money = Decimal.zero;
      cravings = 0;
      for (final q in habits.quitCalculators) {
        final day = q.days.firstWhereOrNull((x) => x.localDate == d);
        if (day == null) continue;
        if (!day.abstinent) abstinent = false;
        if (day.cpu != null) money = money! + Decimal.parse(day.avoided.toString()) * day.cpu!;
        cravings = cravings! + q.logs.where((l) => l.kind == HabitLogKind.craving && l.localDate == d).length;
      }
    }
    final moods = _moods[d];
    return DaySectionFacts(
      d,
      plannerPlanned: planned,
      plannerDone: done,
      plannerDoneOnTime: onTime,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
      habitsDue: due,
      habitsDone: habitsDone,
      itemsCompleted: hasLists && !d.isAfter(today) ? (_completions[d] ?? 0).round() : null,
      quitAbstinent: abstinent,
      moneySaved: money,
      cravings: cravings,
      mood: moods == null || moods.isEmpty ? null : moods.reduce((a, b) => a + b) / moods.length,
    );
  }

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

const _allTables = {
  StatsTable.tasks,
  StatsTable.taskOccurrences,
  StatsTable.checklistItems,
  StatsTable.habits,
  StatsTable.habitLogs,
};

ValueTile _kpiTile(KpiDelta k, {required String currency}) {
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
    requires: _allTables,
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
    requires: _allTables,
    compute: (c) {
      final w = weekAtAGlance(c.days, today: c.today, weekStart: c.weekStart);
      final currency = c.currency();
      return chartResult(
        'GL-02',
        TilesData([for (final k in w.deltas) _kpiTile(k, currency: currency)]),
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
    requires: _allTables,
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
          headline: [for (final k in report.headline) _kpiTile(k, currency: currency)],
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
];
