/// Habit Insights catalog, P1/P2 part ([6.5]): volume analytics and records (T6.5.06), limit habits
/// (T6.5.07), consistency (T6.5.08), timing patterns (T6.5.09), recovery, freezes and momentum
/// (T6.5.10), goal pace (T6.5.12), Habits section extended metrics (T6.5.14) and advanced analytics
/// (T6.5.15). The math lives in `everslot_metrics`; these definitions shape results and charts.
library;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/habit_catalog.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/habit_resolution.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;

const _tables = {StatsTable.habits, StatsTable.habitLogs, StatsTable.habitPauses, StatsTable.habitRevisions};

MetricResult _noHabit(String id) => MetricResult.notApplicable(id, 'noHabit');

MetricResult _habit(HabitContext c, String id, MetricResult Function(HabitEvaluation e) f) {
  final e = c.eval;
  return e == null ? _noHabit(id) : f(e);
}

/// Units of [e] inside the selected period.
List<PeriodResult> _inPeriod(HabitContext c, Iterable<PeriodResult> units) => [
  for (final u in units)
    if (c.range.contains(u.startDate)) u,
];

ChartLabel _habitLabel(HabitContext c, String id) => TextLabel(c.byId[id]?.name ?? '');

DrillRef _habitRef(HabitContext c, String id) => DrillRef(DrillKind.habit, id, title: c.byId[id]?.name);

/// Every HB-* metric of milestones M2/M3.
final List<MetricDefinition> habitInsightMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Volume analytics & records (T6.5.06)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-12',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.higherIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-12', (e) {
      if (!e.isMeasurable) return const MetricResult.notApplicable('HB-H-12', 'yesNoHabit');
      final a = volumeAverages(_inPeriod(c, e.dayResults), skipPolicy: e.skipPolicy);
      return result(
        'HB-H-12',
        a.perScheduledDay,
        previous: c.compare
            ? volumeAverages([
                for (final u in e.dayResults)
                  if (c.previous.contains(u.startDate)) u,
              ], skipPolicy: e.skipPolicy).perScheduledDay
            : null,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.perScheduledDay), a.perScheduledDay.valueOrNull, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.perActiveDay), a.perActiveDay.valueOrNull, StatUnit.count),
        ]),
        args: {'unit': e.habit.unit},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-13',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.list,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-13', (e) {
      final first = e.dayResults.isEmpty ? c.today : e.dayResults.first.startDate;
      final rec = habitRecords(
        e.dayResults,
        from: first,
        to: c.today,
        currentPeriodStart: c.range.start,
        byCompletions: !e.isMeasurable,
        weekStart: c.weekStart,
      );
      final rows = [
        for (final (stat, token, g) in [
          (rec.day, LabelToken.bestDay, Granularity.day),
          (rec.week, LabelToken.bestWeek, Granularity.week),
          (rec.month, LabelToken.bestMonth, Granularity.month),
        ])
          if (stat.valueOrNull case final r? when r.value > 0)
            ListRow(
              TokenLabel(token),
              value: r.value,
              secondary: DateLabel(r.bucket, g),
              tone: r.isNew ? ChartTone.positive : null,
            ),
      ];
      if (rows.isEmpty) return const MetricResult.notApplicable('HB-H-13', Reasons.noData);
      final day = rec.day.valueOrNull;
      return chartResult(
        'HB-H-13',
        ListData(rows),
        value: day == null ? null : Value<double>(day.value),
        args: {
          'newRecord': [rec.day, rec.week, rec.month].any((s) => s.valueOrNull?.isNew ?? false),
          if (day != null) 'bestDay': day.bucket.toIso(),
        },
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-14',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.histogram,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-14', (e) {
      if (!e.isMeasurable) return const MetricResult.notApplicable('HB-H-14', 'yesNoHabit');
      final d = valueDistribution(_inPeriod(c, e.dayResults), skipPolicy: e.skipPolicy);
      return result(
        'HB-H-14',
        d.median,
        chart: d.histogram.bins.isEmpty
            ? null
            : histogramOf(
                d.histogram,
                unit: StatUnit.count,
                markers: [
                  if (d.median.valueOrNull case final m?) (m, const TokenLabel(LabelToken.p50)),
                  if (d.p85.valueOrNull case final p?) (p, const TokenLabel(LabelToken.p85)),
                ],
              ),
        args: {if (d.p85.valueOrNull case final p?) 'p85': p},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-15',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.tiles,
    direction: MetricDirection.higherIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-15', (e) {
      if (!e.isMeasurable) return const MetricResult.notApplicable('HB-H-15', 'yesNoHabit');
      final p = partialAndFulfilment(_inPeriod(c, e.outcomeUnits), skipPolicy: e.skipPolicy);
      return result(
        'HB-H-15',
        p.meanFulfilment,
        unit: StatUnit.percent,
        isRate: true,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.fulfilment), p.meanFulfilment.valueOrNull, StatUnit.percent),
          ValueTile(const TokenLabel(LabelToken.partial), p.partialShare.valueOrNull, StatUnit.percent),
        ]),
        args: {if (p.partialShare.valueOrNull case final s?) 'partialShare': s},
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Limit habits (T6.5.07)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-16',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-16', (e) {
      if (!e.isLimit) return const MetricResult.notApplicable('HB-H-16', 'notLimitHabit');
      final units = _inPeriod(c, e.dayResults);
      final m = limitMetricsOf(units, skipPolicy: e.skipPolicy);
      final closed = [
        for (final u in units)
          if (isClosedScheduled(u) && !isExcludedUnit(u, skipPolicy: e.skipPolicy)) u,
      ];
      return result(
        'HB-H-16',
        m.withinLimitShare,
        unit: StatUnit.percent,
        isRate: true,
        chart: closed.isEmpty
            ? null
            : BarData(
                [for (final u in closed) DateLabel(u.startDate)],
                [
                  BarSeries(const TokenLabel(LabelToken.used), [for (final u in closed) u.achieved]),
                ],
                overlays: [
                  BarOverlay(const TokenLabel(LabelToken.limit), [closed.first.target]),
                ],
                isTimeAxis: true,
              ),
        args: {'excess': m.excess, 'credits': m.credits},
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Consistency (T6.5.08)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-17',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.line,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-17', (e) {
      final window = switch (c.request.extra) {
        'window:60' => 60,
        'window:90' => 90,
        'window:180' => 180,
        _ => 30,
      };
      final to = LocalDate.min(c.range.end, c.today);
      if (to.isBefore(c.range.start)) return const MetricResult.notApplicable('HB-H-17', Reasons.noData);
      final idx = consistencyIndex(
        e.outcomeUnits,
        from: c.range.start,
        to: to,
        windowDays: window,
        skipPolicy: e.skipPolicy,
      );
      return result(
        'HB-H-17',
        idx.index,
        unit: StatUnit.percent,
        isRate: true,
        chart: timeSeries(idx.l2, label: const TokenLabel(LabelToken.consistency), unit: StatUnit.percent),
        spark: sparkOf([for (final p in idx.l2) p.value]),
        args: {'windowDays': window},
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Timing patterns (T6.5.09)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-18',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-18', (e) {
      final w = habitWeekdayProfile(e.outcomeUnits, skipPolicy: e.skipPolicy);
      if (w.isEmpty) return const MetricResult.notApplicable('HB-H-18', Reasons.noData);
      return chartResult(
        'HB-H-18',
        weekdayBars(
          {for (final x in w.entries) x.key: x.value.valueOrNull},
          weekStart: c.weekStart,
          seriesLabel: const TokenLabel(LabelToken.rate),
        ),
        unit: StatUnit.percent,
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-19',
    scope: MetricScope.habit,
    unit: StatUnit.clock,
    chart: ChartKind.rose,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: {StatsTable.habitLogs},
    compute: (c) => _habit(c, 'HB-H-19', (e) {
      final t = checkInTimes(e.logs, bounds: c.bounds);
      final s = t.circular.valueOrNull;
      if (s == null) return result('HB-H-19', t.circular.map((x) => x.meanMinuteOfDay), unit: StatUnit.clock);
      final sectors = List<double>.filled(24, 0);
      for (final row in t.matrix.values) {
        for (var h = 0; h < 24; h++) {
          sectors[h] += row[h];
        }
      }
      return result(
        'HB-H-19',
        s.consistent ? Value<double>(s.meanMinuteRounded.toDouble()) : const NotApplicable<double>('noConsistentTime'),
        unit: StatUnit.clock,
        chart: ChartGroup([
          (
            const TokenLabel(LabelToken.whenLabel),
            RoseData(
              sectors,
              meanMinute: s.meanMinuteOfDay,
              sdMinutes: s.sdMinutes,
              dayStartMinute: c.env.dayStartMinutes,
              consistent: s.consistent,
            ),
          ),
          (
            const TokenLabel(LabelToken.checkIns),
            punchCardOf({
              for (final x in t.matrix.entries) x.key: [for (final v in x.value) v.toDouble()],
            }),
          ),
        ]),
        args: {'sd': ?s.sdMinutes, 'n': s.n},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-20',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-20', (e) {
      if (!e.isIntraday) return const MetricResult.notApplicable('HB-H-20', 'notIntraday');
      return result(
        'HB-H-20',
        slotPunctuality(_inPeriod(c, e.units), tolerance: Duration(minutes: c.settings.slotToleranceMinutes)),
        unit: StatUnit.percent,
        isRate: true,
        args: {'toleranceMinutes': c.settings.slotToleranceMinutes},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-21',
    scope: MetricScope.habit,
    unit: StatUnit.minutes,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: {StatsTable.habitLogs},
    compute: (c) => _habit(c, 'HB-H-21', (e) {
      final m = multiTimesPerDay(_inPeriod(c, e.dayResults));
      final today = m.perDay[c.today];
      if (m.perDay.values.every((x) => x.$2 <= 1)) return const MetricResult.notApplicable('HB-H-21', 'oncePerDay');
      return result(
        'HB-H-21',
        m.meanSpacing,
        unit: StatUnit.minutes,
        chart: TilesData([
          if (today != null)
            ValueTile(
              const TokenLabel(LabelToken.today),
              today.$1.toDouble(),
              StatUnit.count,
              secondary: NumberLabel(today.$2, StatUnit.count),
            ),
          ValueTile(const TokenLabel(LabelToken.mean), m.meanSpacing.valueOrNull, StatUnit.minutes),
          ValueTile(const TokenLabel(LabelToken.median), m.medianSpacing.valueOrNull, StatUnit.minutes),
        ]),
        args: {if (today != null) 'todayCount': today.$1, if (today != null) 'todayTarget': today.$2},
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Recovery, freezes & momentum (T6.5.10)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-22',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.tiles,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-22', (e) {
      final r = recovery(e.streakUnits, skipPolicy: e.skipPolicy);
      return result(
        'HB-H-22',
        r.recoveryRate,
        unit: StatUnit.percent,
        isRate: true,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.longestGap), r.longestGap.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.meanGap), r.meanGap.valueOrNull, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.comebacks), r.comebacks.toDouble(), StatUnit.count),
        ]),
        args: {'longestGap': r.longestGap, 'comebacks': r.comebacks},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-23',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-23', (e) {
      if (e.habit.freezesPerMonth <= 0) return const MetricResult.notApplicable('HB-H-23', 'noFreezes');
      final f = freezeUsage(
        e.streaks,
        freezesPerMonth: e.habit.freezesPerMonth,
        today: c.today,
        habitStart: e.habit.startDate,
      );
      return result(
        'HB-H-23',
        countOf(f.usedThisMonth),
        chart: TilesData([
          ValueTile(
            const TokenLabel(LabelToken.month),
            f.usedThisMonth.toDouble(),
            StatUnit.count,
            secondary: NumberLabel(f.grantedThisMonth.toDouble(), StatUnit.count),
          ),
          ValueTile(
            const TokenLabel(LabelToken.total),
            f.usedAllTime.toDouble(),
            StatUnit.count,
            secondary: NumberLabel(f.grantedAllTime.toDouble(), StatUnit.count),
          ),
        ]),
        args: {'protected': f.protectedKeys, 'granted': f.grantedThisMonth},
        drill: {
          'protected': [
            for (final k in f.protectedKeys)
              if (LocalDate.tryParse(k.length >= 10 ? k.substring(0, 10) : k) case final d?) c.dayRef(e.habit.id, d),
          ],
        },
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-24',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.higherIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-24', (e) {
      final m = scoreMomentum(e.strength);
      final v = m.valueOrNull;
      if (v == null) return result('HB-H-24', m.map((x) => x.slopePointsPerDay));
      return result(
        'HB-H-24',
        Value<double>(v.slopePointsPerDay),
        chart: ListData([
          ListRow(
            TokenLabel(switch (v.momentum) {
              Momentum.rising => LabelToken.rising,
              Momentum.stable => LabelToken.stable,
              Momentum.falling => LabelToken.falling,
            }),
            tone: switch (v.momentum) {
              Momentum.rising => ChartTone.positive,
              Momentum.stable => ChartTone.neutral,
              Momentum.falling => ChartTone.negative,
            },
          ),
        ]),
        args: {'momentum': v.momentum.name},
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Goal pace & projection (T6.5.12)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-26',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.line,
    priority: MetricPriority.p1,
    requires: {..._tables, StatsTable.goals},
    compute: (c) => _habit(c, 'HB-H-26', (e) {
      final goal = c.input.goals.firstWhereOrNull(
        (g) => g.scopeType == 'habit' && g.scopeId == e.habit.id && (g.metric == 'volume' || g.metric == 'completions'),
      );
      if (goal == null) return const MetricResult.notApplicable('HB-H-26', 'noGoal');
      final (start, end) = _goalWindow(goal.period, goal.startDate, goal.endDate, c.today, c.weekStart);
      final spec = GoalSpec(goal.target, start: start, end: end);
      final asOf = LocalDate.min(c.today, end);
      final p = habitGoalPace(spec, e.dayResults, asOf: asOf, byCompletions: goal.metric == 'completions');
      final daily = <LocalDate, double>{};
      for (final r in e.dayResults) {
        if (r.startDate.isBefore(start) || r.startDate.isAfter(asOf)) continue;
        final v = goal.metric == 'completions' ? (r.status == PeriodStatus.done ? 1.0 : 0.0) : r.achieved;
        daily[r.startDate] = (daily[r.startDate] ?? 0) + v;
      }
      final days = DateRange(start, asOf).dates.toList();
      var run = 0.0;
      final total = start.daysUntil(end) + 1;
      return result(
        'HB-H-26',
        Value<double>(p.actual),
        chart: TimeSeriesData(days, [
          ChartSeries(const TokenLabel(LabelToken.actual), [for (final d in days) run += daily[d] ?? 0]),
          ChartSeries(
            const TokenLabel(LabelToken.pace),
            [for (final d in days) goal.target * (start.daysUntil(d) + 1) / total],
            color: const SeriesColor(1),
            role: SeriesRole.pace,
          ),
        ], goal: goal.target),
        args: {
          'pace': p.pace,
          'status': p.status.name,
          'projectedEnd': p.projectedEnd,
          if (p.eta case final d?) 'eta': d.toIso(),
          'target': goal.target,
        },
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Advanced (T6.5.15)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-27',
    scope: MetricScope.habit,
    unit: StatUnit.days,
    chart: ChartKind.line,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    hasSources: true,
    requires: _tables,
    compute: (c) => _habit(c, 'HB-H-27', (e) {
      final days = formationDays(e.outcomeUnits, today: c.today);
      final first = e.outcomeUnits.isEmpty ? null : e.outcomeUnits.first.startDate;
      final line = first == null
          ? const <SeriesPoint<double?>>[]
          : [
              for (var d = first; !d.isAfter(c.today); d = d.plusDays(7))
                SeriesPoint<double?>(
                  d,
                  successRate(e.outcomeUnits, from: d.minusDays(29), to: d, skipPolicy: e.skipPolicy).valueOrNull,
                ),
            ];
      return result(
        'HB-H-27',
        days.map((d) => d.toDouble()),
        unit: StatUnit.days,
        chart: line.isEmpty
            ? null
            : TimeSeriesData(
                [for (final p in line) p.bucket],
                [
                  ChartSeries(const TokenLabel(LabelToken.rate), [for (final p in line) p.value]),
                ],
                granularity: Granularity.week,
                unit: StatUnit.percent,
                targetBand: const (0.8, 1.0),
              ),
        args: {'lallyMin': lallyMinDays, 'lallyMax': lallyMaxDays, 'lallyMedian': lallyMedianDays},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-28',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p2,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: {StatsTable.habitLogs, StatsTable.notifications},
    compute: (c) => _habit(c, 'HB-H-28', (e) {
      final reminders = [
        for (final n in c.input.notifications)
          if (n.sourceType == 'habit' && n.sourceId == e.habit.id) n.fireAt,
      ];
      if (reminders.isEmpty) return const MetricResult.notApplicable('HB-H-28', 'noReminders');
      final checkIns = [
        for (final l in e.logs)
          if (l.kind == HabitLogKind.done || l.kind == HabitLogKind.progress) l.loggedAt,
      ];
      final r = reminderEffectiveness(reminders: reminders, checkIns: checkIns);
      return result(
        'HB-H-28',
        r.share,
        unit: StatUnit.percent,
        isRate: true,
        args: {if (r.medianLatencyMinutes.valueOrNull case final m?) 'medianLatencyMinutes': m},
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-29',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: {StatsTable.habitLogs},
    compute: (c) => _habit(c, 'HB-H-29', (e) {
      final m = moodByOutcome(e.dayFacts);
      final done = m.doneMean.valueOrNull;
      final notDone = m.notDoneMean.valueOrNull;
      if (done == null || notDone == null) return const MetricResult.notApplicable('HB-H-29', 'noMood');
      final test = m.test.valueOrNull;
      return result(
        'HB-H-29',
        Value<double>(done - notDone),
        chart: BarData(
          const [TokenLabel(LabelToken.done), TokenLabel(LabelToken.missed)],
          [
            BarSeries(const TokenLabel(LabelToken.moods), [done, notDone]),
          ],
        ),
        args: {
          'doneMean': done,
          'notDoneMean': notDone,
          if (test != null) 'pValue': test.pValue,
          'significant': test != null && test.pValue < 0.05,
        },
        note: 'nonCausal',
      );
    }),
  ),
  metric<HabitContext>(
    id: 'HB-H-30',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.pareto,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: {StatsTable.habitLogs},
    compute: (c) => _habit(c, 'HB-H-30', (e) {
      final reasons = skipExcuseReasons(e.logs.where((l) => c.range.contains(l.localDate)));
      if (reasons.isEmpty) return const MetricResult.notApplicable('HB-H-30', Reasons.noData);
      return chartResult('HB-H-30', paretoOf(reasons));
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Habits section, extended (T6.5.14)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-X-06',
    scope: MetricScope.habits,
    unit: StatUnit.score,
    chart: ChartKind.horizontalBars,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final d = strengthDistribution(c.series);
      if (d.ranked.isEmpty) return const MetricResult.notApplicable('HB-X-06', Reasons.noData);
      return result(
        'HB-X-06',
        d.mean,
        unit: StatUnit.score,
        chart: barsOf(
          [for (final (id, v) in d.ranked) (_habitLabel(c, id), v)],
          seriesLabel: const TokenLabel(LabelToken.score),
          unit: StatUnit.score,
          layout: BarLayout.horizontal,
          drillKeys: [for (final (id, _) in d.ranked) id],
        ),
        args: {if (d.median.valueOrNull case final m?) 'median': m, 'rising': d.rising, 'falling': d.falling},
        drill: {
          for (final (id, _) in d.ranked) id: [_habitRef(c, id)],
        },
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-07',
    scope: MetricScope.habits,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final risks = atRiskHabits(c.series, today: c.today);
      return chartResult(
        'HB-X-07',
        ListData([
          for (final (id, risk) in risks)
            ListRow(
              _habitLabel(c, id),
              secondary: TokenLabel(switch (risk) {
                HabitRisk.quotaBehind => LabelToken.riskQuota,
                HabitRisk.dueToday => LabelToken.riskDueToday,
                HabitRisk.scoreDrop => LabelToken.riskScoreDrop,
              }),
              tone: ChartTone.warning,
              ref: _habitRef(c, id),
            ),
        ]),
        value: countOf(risks.map((r) => r.$1).toSet().length),
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-08',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.radar,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: {..._tables, StatsTable.categories},
    compute: (c) {
      final areas = habitAreas(c.series, from: c.range.start, to: c.range.end);
      if (areas.isEmpty) return const MetricResult.notApplicable('HB-X-08', Reasons.noData);
      final names = {for (final cat in c.input.categories) cat.id: cat.name};
      final keys = areas.keys.toList();
      ChartLabel label(String? id) =>
          id == null || names[id] == null ? const TokenLabel(LabelToken.uncategorized) : TextLabel(names[id]!);
      final chart = keys.length >= 3
          ? RadarData(
              [for (final k in keys) label(k)],
              [
                (const TokenLabel(LabelToken.rate), [for (final k in keys) areas[k]!.successRate.valueOrNull]),
              ],
            ) as ChartData
          : barsOf(
              [for (final k in keys) (label(k), areas[k]!.successRate.valueOrNull ?? 0)],
              seriesLabel: const TokenLabel(LabelToken.rate),
              unit: StatUnit.percent,
            );
      return chartResult(
        'HB-X-08',
        chart,
        unit: StatUnit.percent,
        args: {
          'volume': {for (final k in keys) k ?? '': areas[k]!.volume},
        },
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-09',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.horizontalBars,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final ranked = bestAndWorstHabits(c.series, from: c.range.start, to: LocalDate.min(c.range.end, c.today));
      if (ranked.isEmpty) return const MetricResult.notApplicable('HB-X-09', Reasons.needsMoreData);
      return chartResult(
        'HB-X-09',
        barsOf(
          [for (final (id, v) in ranked) (_habitLabel(c, id), v)],
          seriesLabel: const TokenLabel(LabelToken.rate),
          unit: StatUnit.percent,
          layout: BarLayout.horizontal,
          drillKeys: [for (final (id, _) in ranked) id],
        ),
        unit: StatUnit.percent,
        drill: {
          for (final (id, _) in ranked) id: [_habitRef(c, id)],
        },
        args: {'best': ranked.first.$1, 'worst': ranked.last.$1},
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-10',
    scope: MetricScope.habits,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    requires: {StatsTable.habitLogs},
    compute: (c) {
      final g = c.range.days > 45 ? Granularity.week : Granularity.day;
      final v = checkInVolume(c.series, range: c.range, granularity: g, weekStart: c.weekStart);
      final total = v.fold<double>(0, (a, p) => a + p.value);
      return result(
        'HB-X-10',
        Value<double>(total),
        previous: c.compare
            ? Value<double>(
                checkInVolume(
                  c.series,
                  range: c.previous,
                  weekStart: c.weekStart,
                ).fold<double>(0, (a, p) => a + p.value),
              )
            : null,
        chart: BarData(
          [for (final p in v) DateLabel(p.bucket, g)],
          [
            BarSeries(const TokenLabel(LabelToken.checkIns), [for (final p in v) p.value]),
          ],
          isTimeAxis: true,
        ),
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-11',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final w = habitWeekdayProfile([for (final h in c.series) ...h.results]);
      if (w.isEmpty) return const MetricResult.notApplicable('HB-X-11', Reasons.noData);
      return chartResult(
        'HB-X-11',
        weekdayBars(
          {for (final x in w.entries) x.key: x.value.valueOrNull},
          weekStart: c.weekStart,
          seriesLabel: const TokenLabel(LabelToken.rate),
        ),
        unit: StatUnit.percent,
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Habits section, advanced (T6.5.15)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-X-13',
    scope: MetricScope.habits,
    unit: StatUnit.ratio,
    chart: ChartKind.matrix,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final pairs = habitCoOccurrence(c.series);
      final significant = pairs.where((p) => p.significant).toList();
      if (significant.isEmpty) {
        return MetricResult.notApplicable('HB-X-13', pairs.isEmpty ? Reasons.needsMoreData : 'noSignificantPairs');
      }
      final ids = {
        for (final p in significant) ...[p.a, p.b],
      }.toList();
      double? phi(String a, String b) {
        if (a == b) return null;
        final p = significant.firstWhereOrNull((x) => (x.a == a && x.b == b) || (x.a == b && x.b == a));
        return p?.phi;
      }

      return chartResult(
        'HB-X-13',
        MatrixData(
          [for (final id in ids) _habitLabel(c, id)],
          [for (final id in ids) _habitLabel(c, id)],
          [
            for (final a in ids) [for (final b in ids) phi(a, b)],
          ],
          scale: MatrixScale.diverging,
          unit: StatUnit.ratio,
          marks: [
            for (final a in ids) [for (final b in ids) phi(a, b) != null],
          ],
        ),
        value: countOf(significant.length),
        note: 'oftenTogether',
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-14',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.higherIsBetter,
    priority: MetricPriority.p2,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: {StatsTable.habits},
    compute: (c) {
      final from = DateRange(LocalDate.min(c.range.start, c.today.minusDays(364)), c.today);
      final all = [
        for (final h in c.input.habits)
          if (!h.isQuit) c.evaluation(h).series,
      ];
      final p = habitPortfolio(all, range: from, today: c.today);
      return result(
        'HB-X-14',
        p.activeAt90,
        unit: StatUnit.percent,
        isRate: true,
        chart: BarData(
          [for (final x in p.created) DateLabel(x.bucket, Granularity.month)],
          [
            BarSeries(const TokenLabel(LabelToken.created), [for (final x in p.created) x.value]),
            BarSeries(const TokenLabel(LabelToken.archived), [
              for (final x in p.archived) x.value,
            ], color: const ToneColor(ChartTone.muted)),
          ],
          isTimeAxis: true,
        ),
        args: {if (p.activeAt30.valueOrNull case final v?) 'activeAt30': v},
      );
    },
  ),
];

/// Inclusive window of a goal row: explicit dates, else the current week / month / year.
(LocalDate, LocalDate) _goalWindow(
  String period,
  LocalDate? start,
  LocalDate? end,
  LocalDate today,
  Weekday weekStart,
) {
  if (start != null && end != null) return (start, end);
  switch (period) {
    case 'week':
      final s = today.startOfWeek(weekStart);
      return (s, s.plusDays(6));
    case 'month':
      final s = LocalDate(today.year, today.month, 1);
      final next = today.month == 12 ? LocalDate(today.year + 1, 1, 1) : LocalDate(today.year, today.month + 1, 1);
      return (s, next.minusDays(1));
    default:
      final s = start ?? LocalDate(today.year, 1, 1);
      return (s, end ?? LocalDate(s.year, 12, 31));
  }
}
