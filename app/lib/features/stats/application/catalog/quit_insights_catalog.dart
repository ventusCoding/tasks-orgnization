/// Quit Insights catalog, P1/P2 part ([6.6]): craving resistance and decline (T6.6.08), lapse/relapse,
/// use analytics and attempts (T6.6.09), savings goal and money by period (T6.6.10), pledge streak
/// and withdrawal phase (T6.6.11) and advanced analytics (T6.6.12). Supportive wording only: slips
/// are part of many quit journeys.
library;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/quit_catalog.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';

const _tables = {StatsTable.habits, StatsTable.habitLogs, StatsTable.habitRevisions};

MetricResult _quit(QuitContext c, String id, MetricResult Function(QuitCalculator q) f) {
  final q = c.calc;
  return q == null ? MetricResult.notApplicable(id, 'noTracker') : f(q);
}

double _minutes(Duration d) => d.inSeconds / 60;

/// Every QT-* metric of milestones M2/M3.
final List<MetricDefinition> quitInsightMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Cravings (T6.6.08)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-15',
    scope: MetricScope.quit,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-15', (q) {
      final period = c.instantsToNow(c.range);
      final previous = c.instantsToNow(c.previous);
      List<QuitLog> cravingsIn(InstantRange r) => [
        for (final l in q.logs)
          if (l.kind == HabitLogKind.craving && r.contains(l.loggedAt)) l,
      ];
      return result(
        'QT-15',
        resistRate(q, cravings: cravingsIn(period)),
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? resistRate(q, cravings: cravingsIn(previous)) : null,
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-16',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.histogram,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    hasSources: true,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-16', (q) {
      final d = cravingDuration(q);
      return result(
        'QT-16',
        d.medianSeconds.map((s) => s / 60),
        unit: StatUnit.minutes,
        chart: d.histogram.bins.isEmpty
            ? null
            : HistogramData(
                [for (final b in d.histogram.bins) (b.lower / 60, b.upper / 60, b.count)],
                unit: StatUnit.minutes,
                markers: [
                  if (d.medianSeconds.valueOrNull case final m?) (m / 60, const TokenLabel(LabelToken.p50)),
                  if (d.p85Seconds.valueOrNull case final p?) (p / 60, const TokenLabel(LabelToken.p85)),
                ],
              ),
        note: 'cravingPasses',
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-17',
    scope: MetricScope.quit,
    unit: StatUnit.percent,
    chart: ChartKind.line,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-17', (q) {
      final d = cravingsDecline(q);
      if (d.weekly.isEmpty) return const MetricResult.notApplicable('QT-17', Reasons.noData);
      return result(
        'QT-17',
        d.changeVsWeek1,
        unit: StatUnit.percent,
        chart: BarData(
          [for (final (w, _) in d.weekly) OrdinalLabel(OrdinalKind.week, w)],
          [
            BarSeries(const TokenLabel(LabelToken.perDay), [for (final (_, v) in d.weekly) v]),
          ],
          overlays: [
            BarOverlay(const TokenLabel(LabelToken.trend), [
              for (final (_, v) in d.weekly) v,
            ], color: const SeriesColor(1)),
          ],
        ),
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Lapses, uses & attempts (T6.6.09)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-18',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-18', (q) {
      final rows = lapseRelapse(q);
      final current = rows.isEmpty ? null : rows.last.$2;
      final clean = cleanOfTotal(q);
      return chartResult(
        'QT-18',
        ListData([
          for (final (a, k) in rows.reversed.take(10))
            ListRow(
              InstantLabel(a.start),
              secondary: TokenLabel(
                k.isRelapse ? LabelToken.relapse : (k.lapseDays > 0 ? LabelToken.lapse : LabelToken.abstinent),
              ),
              tone: k.isRelapse ? ChartTone.warning : (k.lapseDays > 0 ? ChartTone.pending : ChartTone.positive),
              value: k.lapseDays.toDouble(),
              unit: StatUnit.days,
            ),
        ]),
        value: Value<double>((current?.lapseDays ?? 0).toDouble()),
        args: {
          'cleanDays': clean.clean,
          'totalDays': clean.total,
          if (current != null) 'relapse': current.isRelapse,
          if (current?.rule case final r?) 'rule': r.name,
          if (current != null) 'russellSustained': current.russellSustained,
        },
        note: (current?.lapseDays ?? 0) > 0 ? 'slipSupport' : null,
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-19',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.punchCard,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-19', (q) {
      final u = useAnalytics(q);
      if (u.episodes == 0) return const MetricResult.notApplicable('QT-19', 'noUses');
      return result(
        'QT-19',
        countOf(u.episodes),
        chart: ChartGroup([
          (
            const TokenLabel(LabelToken.used),
            punchCardOf({
              for (final e in u.matrix.entries) e.key: [for (final v in e.value) v.toDouble()],
            }),
          ),
          if (u.precedingTriggers.isNotEmpty) (const TokenLabel(LabelToken.triggers), paretoOf(u.precedingTriggers)),
          (
            const TokenLabel(LabelToken.summary),
            TilesData([
              ValueTile(const TokenLabel(LabelToken.count), u.episodes.toDouble(), StatUnit.count),
              ValueTile(const TokenLabel(LabelToken.mean), u.meanAmount.valueOrNull, StatUnit.count),
              ValueTile(const TokenLabel(LabelToken.daysBetween), u.meanDaysBetweenLapses.valueOrNull, StatUnit.days),
            ]),
          ),
        ]),
        args: {if (u.meanAmount.valueOrNull case final m?) 'meanAmount': m},
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-20',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-20', (q) {
      final a = quitAttempts(q);
      final durations = [for (final x in q.attempts) x.durationAt(q.now)];
      return result(
        'QT-20',
        countOf(a.count),
        chart: BarData(
          [for (var i = 0; i < durations.length; i++) OrdinalLabel(OrdinalKind.attempt, i + 1)],
          [
            BarSeries(const TokenLabel(LabelToken.attempt), [for (final d in durations) d.inMinutes / 1440]),
          ],
          unit: StatUnit.days,
        ),
        args: {
          'meanDays': a.mean.inMinutes / 1440,
          'longestDays': a.longest.inMinutes / 1440,
          'currentRank': a.currentRank,
        },
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Money & time (T6.6.10)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-21',
    scope: MetricScope.quit,
    unit: StatUnit.percent,
    chart: ChartKind.ring,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: {..._tables, StatsTable.goals},
    compute: (c) => _quit(c, 'QT-21', (q) {
      final goal = c.input.goals.firstWhereOrNull(
        (g) => g.scopeType == 'habit' && g.scopeId == c.scopeId && g.metric == 'money_saved',
      );
      if (goal == null) return const MetricResult.notApplicable('QT-21', 'noGoal');
      final s = savingsGoal(q, goal: Decimal.parse(goal.target.toString()));
      final p = s.progress.valueOrNull;
      return result(
        'QT-21',
        s.progress,
        unit: StatUnit.percent,
        isRate: true,
        currency: c.currency,
        chart: p == null
            ? null
            : RingData([(const TokenLabel(LabelToken.saved), p, const ToneColor(ChartTone.positive))]),
        args: {
          'goal': goal.target,
          'saved': q.moneySaved.toDouble(),
          if (s.etaDays.valueOrNull case final d?) 'etaDays': d,
          if (s.etaDays.valueOrNull case final d?) 'etaDate': c.today.plusDays(d).toIso(),
        },
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-22',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    estimate: true,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-22', (q) {
      final m = q.timeWonBackMinutes;
      if (m == null) return const MetricResult.notApplicable('QT-22', 'noTimePerUnit');
      return result('QT-22', Value<double>(m), unit: StatUnit.minutes, estimate: true);
    }),
  ),
  metric<QuitContext>(
    id: 'QT-23',
    scope: MetricScope.quit,
    unit: StatUnit.currency,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-23', (q) {
      final g = c.range.days > 90 ? Granularity.month : Granularity.week;
      final m = moneySavedPerPeriod(q, granularity: g, weekStart: c.weekStart);
      final keys = m.buckets.keys.where((k) => !k.isAfter(c.range.end)).toList()..sort();
      if (keys.isEmpty) return const MetricResult.notApplicable('QT-23', Reasons.noData);
      return result(
        'QT-23',
        m.meanPerDay,
        unit: StatUnit.currency,
        currency: c.currency,
        chart: BarData(
          [for (final k in keys) DateLabel(k, g)],
          [
            BarSeries(const TokenLabel(LabelToken.saved), [
              for (final k in keys) m.buckets[k]!.toDouble(),
            ], color: const ToneColor(ChartTone.positive)),
          ],
          unit: StatUnit.currency,
          isTimeAxis: true,
        ),
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Pledges & withdrawal (T6.6.11)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-24',
    scope: MetricScope.quit,
    unit: StatUnit.days,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-24', (q) => result('QT-24', countOf(pledgeStreak(q)), unit: StatUnit.days)),
  ),
  metric<QuitContext>(
    id: 'QT-25',
    scope: MetricScope.quit,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    hasSources: true,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-25', (q) {
      final p = withdrawalPhase(q);
      final phase = p.valueOrNull;
      if (phase == null) return MetricResult.notApplicable('QT-25', (p as NotApplicable<WithdrawalPhase>).reasonKey);
      const order = [
        (WithdrawalPhase.peak, LabelToken.withdrawalPeak),
        (WithdrawalPhase.firstWeek, LabelToken.withdrawalFirstWeek),
        (WithdrawalPhase.easing, LabelToken.withdrawalEasing),
        (WithdrawalPhase.beyond, LabelToken.withdrawalBeyond),
      ];
      return chartResult(
        'QT-25',
        ListData([
          for (final (ph, token) in order)
            ListRow(
              TokenLabel(token),
              tone: ph == phase ? ChartTone.primary : ChartTone.muted,
              secondary: ph == phase ? const TokenLabel(LabelToken.typicalVaries) : null,
            ),
        ]),
        value: Value<double>(phase.index.toDouble()),
        args: {'phase': phase.name},
        note: 'typicalVaries',
      );
    }),
  ),

  // ---------------------------------------------------------------------------------------------
  // Advanced (T6.6.12)
  // ---------------------------------------------------------------------------------------------
  metric<QuitContext>(
    id: 'QT-26',
    scope: MetricScope.quit,
    unit: StatUnit.hours,
    chart: ChartKind.km,
    direction: MetricDirection.higherIsBetter,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-26', (q) {
      final km = timeToLapseSurvival(q);
      final v = km.valueOrNull;
      if (v == null) return result('QT-26', km.map((x) => x.medianSurvival ?? 0), unit: StatUnit.hours);
      return result(
        'QT-26',
        v.medianSurvival == null ? const NotApplicable<double>(Reasons.notReached) : Value<double>(v.medianSurvival!),
        unit: StatUnit.hours,
        chart: KmData(
          [for (final s in v.steps) KmPoint(s.time, s.survival, lower: s.lower, upper: s.upper, censored: s.censored)],
          median: v.medianSurvival,
          n: v.n,
        ),
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-27',
    scope: MetricScope.quit,
    unit: StatUnit.percent,
    chart: ChartKind.horizontalBars,
    priority: MetricPriority.p2,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-27', (q) {
      final by = copingEffectiveness(q);
      if (by.isEmpty) return const MetricResult.notApplicable('QT-27', 'noCoping');
      final tools = by.keys.toList()..sort((a, b) => (by[b]!.valueOrNull ?? -1).compareTo(by[a]!.valueOrNull ?? -1));
      return chartResult(
        'QT-27',
        BarData(
          [for (final t in tools) TextLabel(t)],
          [
            BarSeries(const TokenLabel(LabelToken.rate), [for (final t in tools) by[t]!.valueOrNull ?? 0]),
          ],
          layout: BarLayout.horizontal,
          unit: StatUnit.percent,
        ),
        unit: StatUnit.percent,
        args: {
          'insufficient': [
            for (final t in tools)
              if (by[t] is Insufficient<double>) t,
          ],
        },
      );
    }),
  ),
  metric<QuitContext>(
    id: 'QT-28',
    scope: MetricScope.quit,
    unit: StatUnit.minutes,
    chart: ChartKind.tiles,
    priority: MetricPriority.p2,
    requires: _tables,
    compute: (c) => _quit(c, 'QT-28', (q) {
      final f = cravingFreeTime(q);
      return result(
        'QT-28',
        Value<double>(_minutes(f.sinceLast)),
        unit: StatUnit.minutes,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.current), _minutes(f.sinceLast), StatUnit.minutes),
          ValueTile(const TokenLabel(LabelToken.best), _minutes(f.longest), StatUnit.minutes),
        ]),
        args: {'longestMinutes': _minutes(f.longest)},
      );
    }),
  ),
];
