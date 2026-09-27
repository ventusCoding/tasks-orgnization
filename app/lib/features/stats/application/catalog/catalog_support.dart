/// Shared plumbing of the metric catalogs (T6.1.06): the scope context base and small builders that
/// turn `everslot_metrics` results into [MetricResult]s and chart models.
///
/// Contexts are built once per batch in the stats isolate; expensive intermediate values are
/// `late final` so every metric of the batch shares them.
library;

import 'dart:math' as math;

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_settings.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday, ZoneResolver;

/// Base of every scope context.
abstract base class StatsContext {
  StatsContext(this.job, this.resolver);

  final StatsJob job;
  final ZoneResolver resolver;

  StatsEnvironment get env => job.env;
  StatsSettings get settings => env.settings;
  DateTime get now => env.now;
  StatsRequest get request => job.request;
  PeriodSelection get selection => request.selection;
  String? get scopeId => request.scopeId;
  Weekday get weekStart => settings.weekStartOverride ?? env.weekStart;

  /// Day boundaries of the scope (civil midnight for planner/lists, `dayStartsAt` for habits).
  DayBoundaries get bounds;

  /// Earliest date with data in the scope (all-time periods).
  LocalDate? get firstDataDate => job.firstDataDate;

  late final LocalDate today = bounds.dateOf(now);

  late final ResolvedPeriod period = selection.period.resolve(
    today: today,
    weekStart: weekStart,
    firstDataDate: firstDataDate,
  );

  /// Full range of the selected period.
  DateRange get range => period.range;

  /// The selected period up to today (the whole range when it is in the past).
  DateRange get elapsed {
    if (range.start.isAfter(today)) return range;
    return period.toDate;
  }

  /// Previous equivalent range (to-date mode while in progress).
  late final DateRange previous = period.previous(mode: selection.mode);

  bool get compare => selection.compare;

  Granularity get granularity => selection.granularity ?? period.autoGranularity;

  InstantRange instants(DateRange r) => bounds.instantsOf(r);

  /// Instant range from the start of [r] to min(now, end of [r]).
  InstantRange instantsToNow(DateRange r) {
    final full = instants(r);
    return InstantRange(full.start, full.end.isAfter(now) ? now : full.end);
  }
}

// ---------------------------------------------------------------------------------------------
// Result builders
// ---------------------------------------------------------------------------------------------

/// A [MetricResult] with an optional previous-period value and Δ.
MetricResult result(
  String id,
  Stat<double> value, {
  StatUnit unit = StatUnit.count,
  Stat<double>? previous,
  bool isRate = false,
  ChartData? chart,
  List<double?>? spark,
  Map<String, num> exclusions = const {},
  Map<String, Object?> args = const {},
  Map<String, List<DrillRef>> drill = const {},
  String? currency,
  bool estimate = false,
  double? target,
  String? note,
  bool headline = true,
}) => MetricResult(
  id,
  value: value,
  unit: unit,
  previous: previous,
  comparison: previous == null ? null : compareWithPrevious(value, previous, isRate: isRate),
  chart: chart,
  spark: spark,
  exclusions: {
    for (final e in exclusions.entries)
      if (e.value != 0) e.key: e.value,
  },
  args: {...args, if (value case Value<double>(:final sampleSize?)) 'n': sampleSize},
  drill: drill,
  currency: currency,
  estimate: estimate,
  target: target,
  note: note,
  headline: headline,
);

/// A value-less result that only carries a chart (charts, lists, calendars).
MetricResult chartResult(
  String id,
  ChartData chart, {
  StatUnit unit = StatUnit.count,
  Stat<double>? value,
  Map<String, num> exclusions = const {},
  Map<String, Object?> args = const {},
  Map<String, List<DrillRef>> drill = const {},
  String? note,
  String? currency,
  bool estimate = false,
}) => result(
  id,
  value ?? (chart.isEmpty ? const NotApplicable<double>(Reasons.noData) : Value<double>(chartSize(chart))),
  unit: unit,
  chart: chart,
  exclusions: exclusions,
  args: args,
  drill: drill,
  note: note,
  currency: currency,
  estimate: estimate,
  headline: value != null,
);

/// A size figure for value-less charts (rows, points…) so "has data" is visible in the card.
double chartSize(ChartData chart) => switch (chart) {
  TimeSeriesData(:final buckets) => buckets.length.toDouble(),
  BarData(:final categories) => categories.length.toDouble(),
  DonutData(:final total) => total,
  ParetoData(:final total) => total,
  CalendarData(:final cells) => cells.length.toDouble(),
  ListData(:final rows) => rows.length.toDouble(),
  TilesData(:final tiles) => tiles.length.toDouble(),
  ScatterData(:final points) => points.length.toDouble(),
  StreakData(:final streaks) => streaks.length.toDouble(),
  _ => 1,
};

/// Duration → minutes.
Stat<double> minutesOf(Stat<Duration> d) => d.map((x) => x.inSeconds / 60);

/// Duration → hours.
Stat<double> hoursOf(Stat<Duration> d) => d.map((x) => x.inSeconds / 3600);

/// An int count as a value.
Stat<double> countOf(num n, {num? sampleSize}) => Value<double>(n.toDouble(), sampleSize: sampleSize ?? n);

/// Nullable double → stat.
Stat<double> maybe(double? v, [String reason = Reasons.noData]) =>
    v == null || !v.isFinite ? NotApplicable<double>(reason) : Value<double>(v);

/// The last [n] non-null values of a series (KPI sparklines).
List<double?> sparkOf(Iterable<double?> values, {int n = 12}) {
  final list = values.toList();
  return list.length <= n ? list : list.sublist(list.length - n);
}

/// A single-series time chart from bucketed points.
TimeSeriesData timeSeries(
  List<SeriesPoint<double?>> points, {
  required ChartLabel label,
  StatUnit unit = StatUnit.count,
  Granularity granularity = Granularity.day,
  bool rolling = false,
  int rollingWindow = 4,
  bool withTrend = false,
  double? goal,
  bool area = false,
  bool cumulative = false,
  List<ChartAnnotation> annotations = const [],
}) {
  final values = [for (final p in points) p.value];
  final rollingValues = rolling ? rollingMean(values, rollingWindow) : null;
  return TimeSeriesData(
    [for (final p in points) p.bucket],
    [
      ChartSeries(label, values),
      if (rollingValues != null)
        ChartSeries(
          const TokenLabel(LabelToken.rollingMean),
          rollingValues,
          color: const SeriesColor(1),
          role: SeriesRole.rollingMean,
        ),
    ],
    granularity: granularity,
    unit: unit,
    trend: withTrend ? trendOf(values, granularity: granularity, isRate: unit == StatUnit.percent) : null,
    goal: goal,
    area: area,
    cumulative: cumulative,
    annotations: annotations,
  );
}

/// OLS / Theil–Sen trend info of a bucketed series (T6.1.04, seeded): null below 6 buckets. The
/// slope per week of a rate series is expressed in percentage points.
TrendInfo? trendOf(List<double?> values, {required Granularity granularity, bool isRate = false}) {
  final fit = trend(values, bucketDays: granularity.nominalDays, random: math.Random(42)).valueOrNull;
  if (fit == null) return null;
  // Intercept (for drawing): median of y − b·x, robust for both estimators.
  final offsets = <double>[
    for (var i = 0; i < values.length; i++)
      if (values[i] != null) values[i]! - fit.slopePerBucket * i,
  ];
  return TrendInfo(
    slopePerBucket: fit.slopePerBucket,
    intercept: median(offsets).valueOr(0),
    slopePerWeek: isRate ? fit.slopePerWeek * 100 : fit.slopePerWeek,
    direction: fit.direction,
    significant: fit.significant,
  );
}

/// Bar data from a label → value map, sorted by value (desc) when [sort].
BarData barsOf(
  List<(ChartLabel, double)> entries, {
  required ChartLabel seriesLabel,
  StatUnit unit = StatUnit.count,
  BarLayout layout = BarLayout.grouped,
  bool sort = false,
  List<String?>? drillKeys,
  ChartColor color = const SeriesColor(0),
  List<BarOverlay> overlays = const [],
  bool isTimeAxis = false,
}) {
  final list = [...entries];
  if (sort) list.sort((a, b) => b.$2.compareTo(a.$2));
  return BarData(
    [for (final e in list) e.$1],
    [
      BarSeries(seriesLabel, [for (final e in list) e.$2], color: color),
    ],
    unit: unit,
    layout: layout,
    drillKeys: drillKeys,
    overlays: overlays,
    isTimeAxis: isTimeAxis,
  );
}

/// Weekday bars in week-start order.
BarData weekdayBars(
  Map<Weekday, double?> values, {
  required Weekday weekStart,
  required ChartLabel seriesLabel,
  StatUnit unit = StatUnit.percent,
}) {
  final order = Weekday.ordered(weekStart);
  return BarData(
    [for (final w in order) WeekdayLabel(w)],
    [
      BarSeries(seriesLabel, [for (final w in order) values[w] ?? 0]),
    ],
    unit: unit,
    drillKeys: [for (final w in order) 'weekday:${w.iso}'],
  );
}

/// Punch card from a weekday → 24 hours map.
PunchCardData punchCardOf(
  Map<Weekday, List<double>> byWeekday, {
  StatUnit unit = StatUnit.count,
  bool bubbles = false,
}) => PunchCardData(
  [
    for (var iso = 1; iso <= 7; iso++)
      List<double>.generate(24, (h) {
        final row = byWeekday[Weekday.fromIso(iso)];
        return row == null || h >= row.length ? 0 : row[h];
      }),
  ],
  unit: unit,
  bubbles: bubbles,
);

/// Histogram chart from a metrics histogram with optional markers.
HistogramData histogramOf(Histogram h, {required StatUnit unit, List<(double, ChartLabel)> markers = const []}) =>
    HistogramData([for (final b in h.bins) (b.lower, b.upper, b.count)], unit: unit, markers: markers);

/// Box stats from a metrics box-plot summary.
BoxStats boxOf(BoxPlotSummary s) => BoxStats(
  n: s.n,
  min: s.min,
  q1: s.q1,
  median: s.median,
  q3: s.q3,
  max: s.max,
  whiskerLow: s.whiskerLow,
  whiskerHigh: s.whiskerHigh,
  outliers: s.outliers,
);

/// Streak bars from a streak summary (top 10).
StreakData streaksOf(StreakSummary s, {StatUnit unit = StatUnit.days, bool timeline = false}) => StreakData(
  [
    for (final st in timeline ? s.streaks : s.top10)
      StreakBar(
        start: st.startDate,
        end: st.endDate,
        length: st.length,
        current: st.isCurrent,
        frozenUnits: st.frozenUnits,
      ),
  ],
  unit: unit,
  timeline: timeline,
);

/// Pareto chart from counted text labels (Unspecified stays last).
ParetoData paretoOf(Iterable<ParetoEntry> entries, {StatUnit unit = StatUnit.count}) => ParetoData([
  for (final e in entries)
    (e.label.isEmpty ? const TokenLabel(LabelToken.unspecified) : TextLabel(e.label), e.count.toDouble()),
], unit: unit);

/// Clamp helper for fractional progress.
double clamp01(double v) => math.max(0, math.min(1, v));
