/// Fixture data for every chart of the kit: the dev chart gallery (T6.2.24) and the golden tests
/// render these. Deterministic (fixed dates, no randomness).
library;

import 'dart:math' as math;

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Granularity, TrendDirection;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;

/// One sample: a title, its chart kind and the model.
typedef ChartSample = ({String title, ChartKind kind, ChartData data});

LocalDate _d(String iso) => LocalDate.parse(iso);

DateTime _t(String iso) => DateTime.parse(iso);

/// Samples of the P0 charts (line, bars, donut, Pareto, calendar, rings, bullet, milestones,
/// streaks, punch card).
List<ChartSample> p0ChartSamples() {
  final weeks = [for (var i = 0; i < 12; i++) _d('2026-06-29').plusDays(7 * i)];
  return [
    (
      title: 'Adherence',
      kind: ChartKind.line,
      data: TimeSeriesData(
        weeks,
        const [
          ChartSeries(TokenLabel(LabelToken.rate), [0.5, 0.6, null, 0.62, 0.65, 0.7, 0.7, 0.72, 0.74, 0.8, 0.8, 0.82]),
          ChartSeries(
            TokenLabel(LabelToken.rollingMean),
            [null, null, null, 0.57, 0.62, 0.66, 0.67, 0.7, 0.72, 0.74, 0.77, 0.79],
            color: SeriesColor(1),
            role: SeriesRole.rollingMean,
          ),
        ],
        granularity: Granularity.week,
        unit: StatUnit.percent,
        goal: 0.9,
        trend: const TrendInfo(
          slopePerBucket: 0.025,
          intercept: 0.53,
          slopePerWeek: 2.5,
          direction: TrendDirection.rising,
          significant: true,
        ),
      ),
    ),
    (
      title: 'Done vs planned',
      kind: ChartKind.groupedBars,
      data: BarData(
        [for (var i = 0; i < 7; i++) DateLabel(_d('2026-09-14').plusDays(i))],
        const [
          BarSeries(TokenLabel(LabelToken.planned), [3, 4, 2, 5, 3, 1, 0], color: SeriesColor(1)),
          BarSeries(TokenLabel(LabelToken.done), [3, 3, 2, 4, 1, 1, 0], color: ToneColor(ChartTone.done)),
        ],
        overlays: const [
          BarOverlay(TokenLabel(LabelToken.capacity), [4]),
        ],
        isTimeAxis: true,
      ),
    ),
    (
      title: 'Time by category',
      kind: ChartKind.donut,
      data: DonutData(const [
        DonutSlice(TextLabel('Work'), 465, color: ArgbColor(0xFF3B82F6)),
        DonutSlice(TextLabel('Personal'), 210, color: ArgbColor(0xFF8B5CF6)),
        DonutSlice(TextLabel('Health'), 180, color: ArgbColor(0xFF10B981)),
      ], unit: StatUnit.minutes),
    ),
    (
      title: 'Skip reasons',
      kind: ChartKind.pareto,
      data: ParetoData(const [(TextLabel('Tired'), 5), (TextLabel('Sick'), 2), (TextLabel('Travel'), 1)]),
    ),
    (
      title: 'Check-in times',
      kind: ChartKind.punchCard,
      data: PunchCardData([
        for (var w = 0; w < 7; w++)
          [for (var h = 0; h < 24; h++) (h >= 8 && h <= 18 && w < 5) ? ((h * (w + 1)) % 9).toDouble() : 0.0],
      ]),
    ),
  ];
}

/// Samples of the P1/P2 charts (T6.2.13–T6.2.26).
List<ChartSample> advancedChartSamples() {
  final days = [for (var i = 0; i < 21; i++) _d('2026-09-01').plusDays(i)];
  return [
    (
      title: 'Planned vs actual',
      kind: ChartKind.gantt,
      data: GanttData(
        [
          GanttRow(
            const TextLabel('Mon 14'),
            planned: TimeSpan(_t('2026-09-14T09:00:00Z'), _t('2026-09-14T11:00:00Z')),
            actual: [
              TimeSpan(_t('2026-09-14T09:10:00Z'), _t('2026-09-14T10:00:00Z')),
              TimeSpan(_t('2026-09-14T09:40:00Z'), _t('2026-09-14T11:30:00Z')),
            ],
          ),
          GanttRow(
            const TextLabel('Tue 15'),
            planned: TimeSpan(_t('2026-09-14T13:00:00Z'), _t('2026-09-14T14:00:00Z')),
            actual: [TimeSpan(_t('2026-09-14T12:30:00Z'), _t('2026-09-14T13:50:00Z'))],
          ),
          GanttRow(
            const TextLabel('Wed 16'),
            planned: TimeSpan(_t('2026-09-14T15:00:00Z'), _t('2026-09-14T16:00:00Z')),
            actual: [TimeSpan(_t('2026-09-14T15:00:00Z'), _t('2026-09-14T15:55:00Z'))],
          ),
        ],
        from: _t('2026-09-14T08:00:00Z'),
        to: _t('2026-09-14T18:00:00Z'),
      ),
    ),
    (
      title: 'Reschedules',
      kind: ChartKind.moveTimeline,
      data: MoveTimelineData([
        MoveEvent(
          _t('2026-09-10T08:00:00Z'),
          fromEpochMinute: _d('2026-09-12').atStartOfDay.epochMinute + 540,
          toEpochMinute: _d('2026-09-14').atStartOfDay.epochMinute + 600,
        ),
        MoveEvent(
          _t('2026-09-13T08:00:00Z'),
          fromEpochMinute: _d('2026-09-14').atStartOfDay.epochMinute + 600,
          toEpochMinute: _d('2026-09-13').atStartOfDay.epochMinute + 900,
        ),
      ]),
    ),
    (
      title: 'Duration distribution',
      kind: ChartKind.histogram,
      data: const HistogramData(
        [(0, 15, 3), (15, 30, 9), (30, 45, 14), (45, 60, 8), (60, 75, 4), (75, 90, 1)],
        unit: StatUnit.minutes,
        markers: [(38, TokenLabel(LabelToken.p50)), (58, TokenLabel(LabelToken.p85))],
      ),
    ),
    (
      title: 'Cycle time by month',
      kind: ChartKind.boxPlot,
      data: const BoxPlotData([
        (
          TextLabel('Jul'),
          BoxStats(n: 14, min: 1, q1: 2, median: 3, q3: 5, max: 12, whiskerLow: 1, whiskerHigh: 8, outliers: [12]),
        ),
        (TextLabel('Aug'), BoxStats(n: 20, min: 1, q1: 1.5, median: 2.5, q3: 4, max: 7, whiskerLow: 1, whiskerHigh: 7)),
        (
          TextLabel('Sep'),
          BoxStats(n: 9, min: 2, q1: 3, median: 4, q3: 6, max: 15, whiskerLow: 2, whiskerHigh: 9, outliers: [15]),
        ),
      ], unit: StatUnit.days),
    ),
    (
      title: 'Planned vs actual duration',
      kind: ChartKind.scatter,
      data: ScatterData(
        [
          for (var i = 0; i < 40; i++)
            ScatterPoint(
              15.0 + (i % 8) * 10,
              (15.0 + (i % 8) * 10) * (0.7 + (i % 7) * 0.1),
              ref: DrillRef(DrillKind.occurrence, 't$i', title: 'Occurrence $i'),
            ),
        ],
        variant: ScatterVariant.planVsActual,
        xUnit: StatUnit.minutes,
        yUnit: StatUnit.minutes,
      ),
    ),
    (
      title: 'Cycle time',
      kind: ChartKind.scatter,
      data: ScatterData(
        [
          for (var i = 0; i < 30; i++)
            ScatterPoint(_d('2026-08-01').plusDays(i).epochDay.toDouble(), 1.0 + (i * 7) % 11),
        ],
        variant: ScatterVariant.byDate,
        xUnit: StatUnit.date,
        yUnit: StatUnit.days,
        lines: const [
          (4, TokenLabel(LabelToken.p50)),
          (7, TokenLabel(LabelToken.p70)),
          (9, TokenLabel(LabelToken.p85)),
          (10.5, TokenLabel(LabelToken.p95)),
        ],
      ),
    ),
    (
      title: 'Aging WIP',
      kind: ChartKind.scatter,
      data: ScatterData(
        [for (var i = 0; i < 18; i++) ScatterPoint(0, 1.0 + (i * 5) % 13, column: i % 3)],
        variant: ScatterVariant.agingWip,
        xUnit: StatUnit.count,
        yUnit: StatUnit.days,
        columns: const [TokenLabel(LabelToken.ongoing), TokenLabel(LabelToken.waiting), TokenLabel(LabelToken.blocked)],
        lines: const [(4, TokenLabel(LabelToken.p50)), (9, TokenLabel(LabelToken.p85))],
      ),
    ),
    (
      title: 'Cumulative flow',
      kind: ChartKind.cfd,
      data: StackedAreaData(
        days,
        [
          ChartSeries(const TokenLabel(LabelToken.completed), [
            for (var i = 0; i < 21; i++) (i * 0.8).floorToDouble() - (i == 12 ? 1 : 0),
          ], color: const ToneColor(ChartTone.completed)),
          ChartSeries(const TokenLabel(LabelToken.blocked), [
            for (var i = 0; i < 21; i++) i > 5 && i < 12 ? 1 : 0,
          ], color: const ToneColor(ChartTone.blocked)),
          ChartSeries(const TokenLabel(LabelToken.waiting), [
            for (var i = 0; i < 21; i++) i % 4 == 0 ? 1 : 0,
          ], color: const ToneColor(ChartTone.waiting)),
          ChartSeries(const TokenLabel(LabelToken.ongoing), [
            for (var i = 0; i < 21; i++) 2 + (i % 3).toDouble(),
          ], color: const ToneColor(ChartTone.ongoing)),
          ChartSeries(const TokenLabel(LabelToken.todo), [
            for (var i = 0; i < 21; i++) math.max(0, 14 - i * 0.5),
          ], color: const ToneColor(ChartTone.todo)),
        ],
        markers: const [ChartAnnotation(12, TokenLabel(LabelToken.reopened))],
      ),
    ),
    (
      title: 'Burn-up',
      kind: ChartKind.burn,
      data: TimeSeriesData(
        days,
        [
          ChartSeries(const TokenLabel(LabelToken.scope), [
            for (var i = 0; i < 21; i++) i < 8 ? 20 : (i < 15 ? 24 : 26),
          ], color: const ToneColor(ChartTone.warning)),
          ChartSeries(const TokenLabel(LabelToken.done), [
            for (var i = 0; i < 21; i++) (i * 1.1).floorToDouble(),
          ], color: const ToneColor(ChartTone.done)),
        ],
        step: true,
        annotations: const [
          ChartAnnotation(
            8,
            TokenLabel(LabelToken.scope),
            kind: AnnotationKind.scopeChange,
            details: [
              TextLabel('Buy paint'),
              TextLabel('Call plumber'),
              TextLabel('Fix door'),
              TextLabel('Order tiles'),
            ],
          ),
          ChartAnnotation(
            15,
            TokenLabel(LabelToken.scope),
            kind: AnnotationKind.scopeChange,
            details: [TextLabel('Clean garage'), TextLabel('Sell bike')],
          ),
        ],
      ),
    ),
    (
      title: 'Burn-down with forecast',
      kind: ChartKind.burn,
      data: TimeSeriesData(
        days.take(14).toList(),
        [
          ChartSeries(const TokenLabel(LabelToken.remaining), [for (var i = 0; i < 14; i++) 30 - i * 1.3]),
          ChartSeries(
            const TokenLabel(LabelToken.ideal),
            [for (var i = 0; i < 14; i++) 30 - i * 30 / 20],
            color: const SeriesColor(1),
            role: SeriesRole.pace,
          ),
        ],
        cone: ForecastCone(
          [for (var i = 1; i <= 16; i++) _d('2026-09-14').plusDays(i)],
          [for (var i = 1; i <= 16; i++) math.max(0, 13.1 - i * 1.3)],
          [for (var i = 1; i <= 16; i++) math.max(0, 13.1 - i * 1.0)],
          [for (var i = 1; i <= 16; i++) math.max(0, 13.1 - i * 0.85)],
        ),
      ),
    ),
    (
      title: 'Weekday profile',
      kind: ChartKind.radar,
      data: RadarData(
        [for (final w in Weekday.values) WeekdayLabel(w)],
        const [
          (TokenLabel(LabelToken.current), [0.9, 0.85, 0.8, 0.75, 0.6, 0.4, null]),
          (TokenLabel(LabelToken.previous), [0.8, 0.8, 0.7, 0.7, 0.65, 0.5, null]),
        ],
      ),
    ),
    (
      title: 'Check-in clock',
      kind: ChartKind.rose,
      data: const RoseData(
        [5, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 4, 7],
        meanMinute: 1410,
        sdMinutes: 75,
      ),
    ),
    (
      title: 'Time allocation',
      kind: ChartKind.treemap,
      data: const TreemapData([
        TreemapNode(
          TextLabel('Work'),
          600,
          color: ArgbColor(0xFF3B82F6),
          children: [
            TreemapNode(TextLabel('Reports'), 300, color: ArgbColor(0xFF3B82F6)),
            TreemapNode(TextLabel('Meetings'), 200, color: ArgbColor(0xFF3B82F6)),
            TreemapNode(TextLabel('Email'), 100, color: ArgbColor(0xFF3B82F6)),
          ],
        ),
        TreemapNode(TextLabel('Health'), 240, color: ArgbColor(0xFF10B981)),
        TreemapNode(TextLabel('Personal'), 160, color: ArgbColor(0xFF8B5CF6)),
      ]),
    ),
    (
      title: 'Habit co-occurrence',
      kind: ChartKind.matrix,
      data: const MatrixData(
        [TextLabel('Run'), TextLabel('Read'), TextLabel('Water')],
        [TextLabel('Run'), TextLabel('Read'), TextLabel('Water')],
        [
          [1, 0.32, -0.21],
          [0.32, 1, null],
          [-0.21, null, 1],
        ],
        scale: MatrixScale.diverging,
        unit: StatUnit.ratio,
        marks: [
          [false, true, false],
          [true, false, false],
          [false, false, false],
        ],
      ),
    ),
    (
      title: 'Time to first lapse',
      kind: ChartKind.km,
      data: const KmData(
        [
          KmPoint(24, 0.8, lower: 0.6, upper: 0.95),
          KmPoint(72, 0.6, lower: 0.38, upper: 0.82, censored: 1),
          KmPoint(168, 0.45, lower: 0.22, upper: 0.7),
          KmPoint(400, 0.45, lower: 0.22, upper: 0.7, censored: 1),
        ],
        median: 168,
        n: 5,
      ),
    ),
    (
      title: 'Finish date forecast',
      kind: ChartKind.forecast,
      data: ForecastData(
        _d('2026-09-14'),
        const {8: 300, 9: 1400, 10: 2600, 11: 2500, 12: 1700, 13: 900, 14: 400, 15: 150, 16: 50},
        p50: 11,
        p85: 13,
        p95: 14,
        trials: 10000,
      ),
    ),
  ];
}

/// Every sample (P0 first).
List<ChartSample> allChartSamples() => [...p0ChartSamples(), ...advancedChartSamples()];
