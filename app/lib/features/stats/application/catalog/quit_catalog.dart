/// Quit tracker Insights catalog ([6.6], QT-*): every figure delegates to the [5.3] quit calculator
/// of `everslot_metrics`; this file only shapes results and charts.
library;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/habit_resolution.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/quit_health_content.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;

/// Batch context of the quit scope.
final class QuitContext extends StatsContext {
  QuitContext(super.job, super.resolver) : input = job.habits ?? const HabitInput();

  final HabitInput input;

  late final HabitResolver habits = HabitResolver(
    input,
    resolver: resolver,
    viewerZone: env.zoneId,
    now: now,
    dayStartMinutes: env.dayStartMinutes,
    weekStart: weekStart,
  );

  late final HabitRecord? tracker = input.habits.where((h) => h.id == scopeId && h.isQuit).firstOrNull;

  @override
  late final DayBoundaries bounds = tracker == null
      ? dayBoundariesOf(resolver, env.zoneId, dayStartMinutes: env.dayStartMinutes)
      : habits.boundsOf(tracker!);

  late final QuitCalculator? calc = tracker == null ? null : habits.quit(tracker!);

  late final QuitSummary? summary = calc == null
      ? null
      : quitSummary(
          calc!,
          explicitLifeMinutesPerUnit: tracker!.lifeMinutesPerUnit != null && tracker!.quitSubstance != smokingSubstance,
        );

  String get currency => tracker?.currency ?? env.currency;

  bool get isSmoking => tracker?.quitSubstance == smokingSubstance;

  bool get isReduce => tracker?.quitMode == 'reduce';

  @override
  LocalDate? get firstDataDate => calc == null ? job.firstDataDate : bounds.dateOf(calc!.quitStartedAt);
}

MetricResult _noTracker(String id) => MetricResult.notApplicable(id, 'noTracker');

T _withQuit<T>(QuitContext c, T Function(QuitCalculator q, QuitSummary s) f, T Function() none) {
  final q = c.calc;
  final s = c.summary;
  return q == null || s == null ? none() : f(q, s);
}

const _quitTables = {StatsTable.habits, StatsTable.habitLogs, StatsTable.habitRevisions};

double _minutes(Duration d) => d.inSeconds / 60;

/// Every quit metric.
final List<MetricDefinition> quitMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Abstinence time (T6.6.02)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-01',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.counter,
    requires: _quitTables,
    compute: (c) => _withQuit(
      c,
      (q, s) => result(
        'QT-01',
        Value<double>(_minutes(s.timeSinceQuit)),
        unit: StatUnit.minutes,
        chart: CounterData(q.quitStartedAt, label: const TokenLabel(LabelToken.quit)),
        args: {'since': q.quitStartedAt.toIso8601String()},
      ),
      () => _noTracker('QT-01'),
    ),
  ),
  metric<QuitContext>(
    id: 'QT-02',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.counter,
    requires: _quitTables,
    compute: (c) => _withQuit(
      c,
      (q, s) => result(
        'QT-02',
        Value<double>(_minutes(s.currentAbstinence)),
        unit: StatUnit.minutes,
        chart: CounterData(q.currentAbstinenceStart, label: const TokenLabel(LabelToken.abstinent)),
        args: {
          'since': q.currentAbstinenceStart.toIso8601String(),
          'restarted': q.currentAbstinenceStart != q.quitStartedAt,
        },
      ),
      () => _noTracker('QT-02'),
    ),
  ),
  metric<QuitContext>(
    id: 'QT-03',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    requires: _quitTables,
    compute: (c) => _withQuit(
      c,
      (q, s) => result('QT-03', Value<double>(_minutes(s.longestAbstinence)), unit: StatUnit.minutes),
      () => _noTracker('QT-03'),
    ),
  ),
  metric<QuitContext>(
    id: 'QT-04',
    scope: MetricScope.quit,
    unit: StatUnit.days,
    chart: ChartKind.kpi,
    requires: _quitTables,
    compute: (c) => _withQuit(
      c,
      (q, s) => result(
        'QT-04',
        Value<double>(s.abstinentDays.toDouble()),
        unit: StatUnit.days,
        exclusions: {'unknown': s.unknownDays},
      ),
      () => _noTracker('QT-04'),
    ),
  ),
  metric<QuitContext>(
    id: 'QT-05',
    scope: MetricScope.quit,
    unit: StatUnit.percent,
    chart: ChartKind.ring,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      final closed = q.closedDays;
      return result(
        'QT-05',
        s.abstinentDayShare,
        unit: StatUnit.percent,
        chart: RingData([
          (const TokenLabel(LabelToken.abstinent), s.abstinentDayShare.valueOr(0), const ToneColor(ChartTone.done)),
        ], centerValue: s.abstinentDayShare.valueOrNull),
        args: {'abstinent': s.abstinentDays, 'days': closed.length},
        spark: sparkOf([for (final d in closed) d.abstinent ? 1.0 : 0.0], n: 30),
      );
    }, () => _noTracker('QT-05')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Units & money (T6.6.03, T6.6.04)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-06',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.line,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      var run = 0.0;
      final byDay = q.unitsAvoidedByDay;
      return result(
        'QT-06',
        Value<double>(s.unitsAvoided),
        chart: TimeSeriesData(
          [for (final p in byDay) p.$1],
          [
            ChartSeries(const TokenLabel(LabelToken.units), [for (final p in byDay) run += p.$2]),
          ],
          cumulative: true,
          area: true,
        ),
      );
    }, () => _noTracker('QT-06')),
  ),
  metric<QuitContext>(
    id: 'QT-07',
    scope: MetricScope.quit,
    unit: StatUnit.currency,
    chart: ChartKind.area,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      var run = Decimal.zero;
      final byDay = q.moneySavedByDay;
      final inPeriod = [
        for (final p in byDay)
          if (c.range.contains(p.$1)) p.$2,
      ].fold<Decimal>(Decimal.zero, (a, b) => a + b);
      final prevPeriod = [
        for (final p in byDay)
          if (c.previous.contains(p.$1)) p.$2,
      ].fold<Decimal>(Decimal.zero, (a, b) => a + b);
      return result(
        'QT-07',
        Value<double>(s.moneySaved.toDouble()),
        unit: StatUnit.currency,
        currency: c.currency,
        chart: TimeSeriesData(
          [for (final p in byDay) p.$1],
          [
            ChartSeries(const TokenLabel(LabelToken.money), [for (final p in byDay) (run += p.$2).toDouble()]),
          ],
          unit: StatUnit.currency,
          cumulative: true,
          area: true,
        ),
        args: {'inPeriod': inPeriod.toDouble(), 'previousPeriod': prevPeriod.toDouble()},
      );
    }, () => _noTracker('QT-07')),
  ),
  metric<QuitContext>(
    id: 'QT-08',
    scope: MetricScope.quit,
    unit: StatUnit.currency,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _quitTables,
    compute: (c) => _withQuit(
      c,
      (q, s) => result(
        'QT-08',
        Value<double>(s.moneySpent.toDouble()),
        unit: StatUnit.currency,
        currency: c.currency,
        args: {'lapses': q.uses.length},
      ),
      () => _noTracker('QT-08'),
    ),
  ),
  metric<QuitContext>(
    id: 'QT-09',
    scope: MetricScope.quit,
    unit: StatUnit.currency,
    chart: ChartKind.tiles,
    estimate: true,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      final p = s.projection;
      if (p == null) return const MetricResult.notApplicable('QT-09', 'noUnitCost');
      return result(
        'QT-09',
        Value<double>(p.nextYear.toDouble()),
        unit: StatUnit.currency,
        currency: c.currency,
        estimate: true,
        chart: TilesData([
          ValueTile(
            const TokenLabel(LabelToken.projection1m),
            p.nextMonth.toDouble(),
            StatUnit.currency,
            estimate: true,
          ),
          ValueTile(
            const TokenLabel(LabelToken.projection1y),
            p.nextYear.toDouble(),
            StatUnit.currency,
            estimate: true,
          ),
          ValueTile(
            const TokenLabel(LabelToken.projection5y),
            p.nextFiveYears.toDouble(),
            StatUnit.currency,
            estimate: true,
          ),
        ]),
        args: {'perDay': p.perDay.toDouble()},
      );
    }, () => _noTracker('QT-09')),
  ),
  metric<QuitContext>(
    id: 'QT-10',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.counter,
    estimate: true,
    hasSources: true,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      final v = s.lifeRegainedMinutes;
      return result(
        'QT-10',
        v,
        unit: StatUnit.minutes,
        estimate: true,
        note: v is NotApplicable<double> ? v.reasonKey : 'populationEstimate',
        args: {'lmu': q.tracker.lifeMinutesPerUnit, 'units': s.unitsAvoided},
      );
    }, () => _noTracker('QT-10')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Health milestones (T6.6.05)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-11',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.milestones,
    hasSources: true,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      final table = [for (final m in smokingHealthMilestones) m.milestone];
      final progress = healthMilestones(q, table);
      final rows = progress.valueOrNull;
      if (rows == null) return const MetricResult.notApplicable('QT-11', 'notSmoking');
      final byId = {for (final m in smokingHealthMilestones) m.id: m};
      final restarted = q.currentAbstinenceStart != q.quitStartedAt;
      return chartResult(
        'QT-11',
        MilestoneData([
          for (final p in rows)
            MilestoneRow(
              id: p.milestone.id,
              label: TextLabel(p.milestone.id),
              progress: p.progress,
              state: switch (p.state) {
                MilestoneState.done => MilestoneRowState.done,
                MilestoneState.inWindow => MilestoneRowState.inWindow,
                MilestoneState.upcoming => MilestoneRowState.upcoming,
              },
              eta: p.state == MilestoneState.done ? null : p.eta,
              isNext: p.isNext,
              rangeMarker: p.milestone.isRange ? p.milestone.tMin.inSeconds / p.milestone.tMax!.inSeconds : null,
              sources: [for (final src in byId[p.milestone.id]?.sources ?? const <HealthSource>[]) src.name],
            ),
        ], restarted: restarted),
        value: Value<double>(rows.where((r) => r.state == MilestoneState.done).length.toDouble()),
        args: {'total': rows.length, 'restarted': restarted},
      );
    }, () => _noTracker('QT-11')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Reduce mode (T6.6.06)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-12',
    scope: MetricScope.quit,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      if (!c.isReduce) return const MetricResult.notApplicable('QT-12', 'abstainMode');
      final r = reductionProgress(q);
      final days = q.closedDays;
      return result(
        'QT-12',
        r.withinLimitShare,
        unit: StatUnit.percent,
        chart: BarData(
          [for (final d in days) DateLabel(d.localDate)],
          [
            BarSeries(const TokenLabel(LabelToken.used), [for (final d in days) d.used], color: const SeriesColor(0)),
          ],
          overlays: [
            if (r.limit != null)
              BarOverlay(const TokenLabel(LabelToken.limit), [
                for (final d in days) d.limit,
              ], color: const ToneColor(ChartTone.warning)),
            BarOverlay(const TokenLabel(LabelToken.baseline), [
              for (final d in days) d.base,
            ], color: const ToneColor(ChartTone.muted)),
            BarOverlay(const TokenLabel(LabelToken.rollingMean), r.rolling7Use, color: const SeriesColor(1)),
          ],
          isTimeAxis: true,
        ),
        args: {
          if (r.meanDailyUse.valueOrNull case final v?) 'meanUse': v,
          if (r.meanBase.valueOrNull case final v?) 'base': v,
          if (r.reduction.valueOrNull case final v?) 'reduction': v,
          if (r.limit case final v?) 'limit': v,
          'unitsAvoided': r.unitsAvoided,
        },
      );
    }, () => _noTracker('QT-12')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Cravings (T6.6.07)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-13',
    scope: MetricScope.quit,
    unit: StatUnit.perDay,
    chart: ChartKind.line,
    direction: MetricDirection.lowerIsBetter,
    requires: _quitTables,
    compute: (c) => _withQuit(c, (q, s) {
      final range = _closedRange(c);
      final load = cravingLoad(q, range: range);
      final prevRange = c.previous;
      final prev = cravingLoad(q, range: prevRange);
      return result(
        'QT-13',
        load.perDay,
        unit: StatUnit.perDay,
        previous: c.compare ? prev.perDay : null,
        chart: BarData(
          [for (final p in load.daily) DateLabel(p.bucket)],
          [
            BarSeries(const TokenLabel(LabelToken.cravings), [
              for (final p in load.daily) p.value,
            ], color: const SeriesColor(0)),
          ],
          overlays: [BarOverlay(const TokenLabel(LabelToken.rollingMean), load.rolling7, color: const SeriesColor(1))],
          isTimeAxis: true,
        ),
        args: {
          if (load.meanIntensity.valueOrNull case final v?) 'meanIntensity': v,
          if (load.maxIntensity.valueOrNull case final v?) 'maxIntensity': v,
        },
        spark: sparkOf(load.rolling7),
      );
    }, () => _noTracker('QT-13')),
  ),
  metric<QuitContext>(
    id: 'QT-14',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.pareto,
    direction: MetricDirection.neutral,
    requires: {..._quitTables},
    compute: (c) => _withQuit(c, (q, s) {
      final ctx = cravingContext(q, weekStart: c.weekStart);
      final total = ctx.triggers.fold<int>(0, (a, e) => a + e.count);
      return chartResult(
        'QT-14',
        ChartGroup([
          (const TokenLabel(LabelToken.triggers), paretoOf(ctx.triggers)),
          (const TokenLabel(LabelToken.places), paretoOf(ctx.places)),
          (const TokenLabel(LabelToken.moods), paretoOf(ctx.moods)),
          (
            const TokenLabel(LabelToken.whenLabel),
            punchCardOf({
              for (final (w, row) in ctx.matrix) w: [for (final v in row) v.toDouble()],
            }),
          ),
        ]),
        value: Value<double>(total.toDouble()),
      );
    }, () => _noTracker('QT-14')),
  ),
];

/// The period clipped to the tracker's closed days (quit date … yesterday/today).
/// Closed local days of the period since the quit date (today is still open); a period that only
/// covers today falls back to today so "Today" still shows its partial load.
DateRange _closedRange(QuitContext c) {
  final q = c.calc!;
  final first = c.bounds.dateOf(q.quitStartedAt);
  final start = LocalDate.max(first, c.range.start);
  final end = LocalDate.min(c.today.minusDays(1), c.range.end);
  if (!end.isBefore(start)) return DateRange(start, end);
  final today = LocalDate.min(c.today, c.range.end);
  return DateRange(today, today);
}
