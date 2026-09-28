/// Locale- and theme-independent chart data models (T6.2.01, T6.2.10, T6.2.11).
///
/// Metrics compute these in an isolate; widgets in `presentation/charts/` render them. Labels are
/// semantic ([ChartLabel]) and colors are tokens ([ChartColor]), so switching theme or locale
/// restyles every chart without recomputing data. Every model converts to a [ChartTable] — the
/// "view as table" alternative and the CSV/JSON export source (T6.7.12).
library;

import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Granularity, TrendDirection;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;
import 'package:meta/meta.dart';

// ---------------------------------------------------------------------------------------------
// Labels, colors, drill-down references
// ---------------------------------------------------------------------------------------------

/// Semantic label tokens, localized by the presentation layer.
enum LabelToken {
  // Outcomes & statuses
  done,
  doneOnTime,
  doneLate,
  partial,
  failed,
  missed,
  skipped,
  excused,
  paused,
  frozen,
  pending,
  notDue,
  future,
  cancelled,
  notTracked,
  todo,
  ongoing,
  waiting,
  blocked,
  completed,
  // Series roles
  planned,
  actual,
  capacity,
  target,
  goal,
  pace,
  rollingMean,
  trend,
  remaining,
  scope,
  ideal,
  created,
  arrivals,
  departures,
  net,
  wip,
  previous,
  current,
  projection,
  // Groups
  event,
  task,
  recurring,
  oneOff,
  highPriority,
  lowPriority,
  uncategorized,
  other,
  unspecified,
  early,
  onTime,
  late,
  over,
  under,
  abstinent,
  used,
  withinLimit,
  overLimit,
  success,
  cravings,
  intensity,
  checkIns,
  volume,
  money,
  units,
  images,
  pdfs,
  files,
  tasks,
  habits,
  items,
  lists,
  quit,
  deepWork,
  afterHours,
  weekend,
  focus,
  free,
  overlap,
  inProgress,
  moved,
  movedIn,
  movedOut,
  unplanned,
  reopened,
  removed,
  lapse,
  relapse,
  attempt,
  streak,
  best,
  score,
  median,
  p50,
  p70,
  p85,
  p95,
  mean,
  total,
  count,
  rate,
  yes,
  no,
  overdueToday,
  overdue1,
  overdue7,
  overdue14,
  overdue30,
  archived,
  templates,
  stale,
  lifeRegained,
  timeNotSpent,
  spent,
  saved,
  week,
  month,
  year,
  projection1m,
  projection1y,
  projection5y,
  withinLimitDays,
  meanUse,
  baseline,
  limit,
  reduction,
  perDay,
  maxIntensity,
  meanIntensity,
  wins,
  attention,
  triggers,
  places,
  moods,
  whenLabel,
  agenda,
  perfectDay,
  overdue,
  nextUp,
  summary,
  mostActive,
  mostBlocked,
  stalest,
}

/// A chart label: resolved to text by the presentation layer.
@immutable
sealed class ChartLabel {
  const ChartLabel();
}

/// User content (category, task or habit name). May be anonymized when sharing.
final class TextLabel extends ChartLabel {
  const TextLabel(this.text, {this.anonymousIndex});

  final String text;

  /// 1-based index used when names are hidden ("Habit 1").
  final int? anonymousIndex;

  @override
  bool operator ==(Object other) => other is TextLabel && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

final class TokenLabel extends ChartLabel {
  const TokenLabel(this.token);

  final LabelToken token;

  @override
  bool operator ==(Object other) => other is TokenLabel && other.token == token;

  @override
  int get hashCode => token.hashCode;
}

/// A date bucket (day, week, month, quarter or year).
final class DateLabel extends ChartLabel {
  const DateLabel(this.date, [this.granularity = Granularity.day]);

  final LocalDate date;
  final Granularity granularity;

  @override
  bool operator ==(Object other) => other is DateLabel && other.date == date && other.granularity == granularity;

  @override
  int get hashCode => Object.hash(date, granularity);
}

final class WeekdayLabel extends ChartLabel {
  const WeekdayLabel(this.weekday);

  final Weekday weekday;

  @override
  bool operator ==(Object other) => other is WeekdayLabel && other.weekday == weekday;

  @override
  int get hashCode => weekday.hashCode;
}

/// Hour of the day (0–23).
final class HourLabel extends ChartLabel {
  const HourLabel(this.hour);

  final int hour;

  @override
  bool operator ==(Object other) => other is HourLabel && other.hour == hour;

  @override
  int get hashCode => hour.hashCode;
}

/// An instant (live counters, reschedule times).
final class InstantLabel extends ChartLabel {
  const InstantLabel(this.instant);

  final DateTime instant;

  @override
  bool operator ==(Object other) => other is InstantLabel && other.instant == instant;

  @override
  int get hashCode => instant.hashCode;
}

/// A formatted number (bins, thresholds).
final class NumberLabel extends ChartLabel {
  const NumberLabel(this.value, this.unit);

  final double value;
  final StatUnit unit;

  @override
  bool operator ==(Object other) => other is NumberLabel && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}

/// A numeric range "lo–hi" (histogram bins).
final class RangeLabel extends ChartLabel {
  const RangeLabel(this.lower, this.upper, this.unit);

  final double lower;
  final double upper;
  final StatUnit unit;

  @override
  bool operator ==(Object other) =>
      other is RangeLabel && other.lower == lower && other.upper == upper && other.unit == unit;

  @override
  int get hashCode => Object.hash(lower, upper, unit);
}

/// "Week 3", "Run 4", "Level 2", "Priority 3", "Depth 5"…
final class OrdinalLabel extends ChartLabel {
  const OrdinalLabel(this.kind, this.n);

  final OrdinalKind kind;
  final int n;

  @override
  bool operator ==(Object other) => other is OrdinalLabel && other.kind == kind && other.n == n;

  @override
  int get hashCode => Object.hash(kind, n);
}

enum OrdinalKind { week, run, level, priority, depth, attempt, month, year }

/// Semantic color tokens resolved by `ChartTheme`.
enum ChartTone {
  done,
  late,
  partial,
  failed,
  missed,
  skipped,
  excused,
  paused,
  frozen,
  pending,
  notDue,
  todo,
  ongoing,
  waiting,
  blocked,
  completed,
  cancelled,
  positive,
  negative,
  warning,
  neutral,
  muted,
  primary,
}

/// A color token: a series palette slot, a semantic tone or a stored ARGB (category colors).
@immutable
sealed class ChartColor {
  const ChartColor();
}

final class SeriesColor extends ChartColor {
  const SeriesColor(this.index);

  final int index;

  @override
  bool operator ==(Object other) => other is SeriesColor && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

final class ToneColor extends ChartColor {
  const ToneColor(this.tone);

  final ChartTone tone;

  @override
  bool operator ==(Object other) => other is ToneColor && other.tone == tone;

  @override
  int get hashCode => tone.hashCode;
}

final class ArgbColor extends ChartColor {
  const ArgbColor(this.argb);

  final int argb;

  @override
  bool operator ==(Object other) => other is ArgbColor && other.argb == argb;

  @override
  int get hashCode => argb.hashCode;
}

/// Entity kinds a chart element can drill into (T6.2.10).
enum DrillKind { task, occurrence, checklist, item, habit, quit, day, category }

/// A reference to an entity behind a chart element.
@immutable
final class DrillRef {
  const DrillRef(this.kind, this.id, {this.extra, this.title, this.subtitle});

  final DrillKind kind;
  final String id;

  /// Occurrence key, item id or ISO date.
  final String? extra;
  final String? title;
  final String? subtitle;

  @override
  bool operator ==(Object other) => other is DrillRef && other.kind == kind && other.id == id && other.extra == extra;

  @override
  int get hashCode => Object.hash(kind, id, extra);
}

/// Typed payload of a tap on a chart element (T6.2.10): which series, which bucket/category and
/// the drill key used to look up the entities behind it.
@immutable
final class ChartTap {
  const ChartTap({this.drillKey, this.label, this.seriesIndex, this.value});

  /// Key into `MetricResult.drill` (ISO date, category id, status name, `weekday:hour`…).
  final String? drillKey;
  final ChartLabel? label;
  final int? seriesIndex;
  final double? value;

  @override
  bool operator ==(Object other) =>
      other is ChartTap && other.drillKey == drillKey && other.seriesIndex == seriesIndex && other.value == value;

  @override
  int get hashCode => Object.hash(drillKey, seriesIndex, value);
}

// ---------------------------------------------------------------------------------------------
// Tabular alternative (T6.2.11)
// ---------------------------------------------------------------------------------------------

/// One cell of a [ChartTable]: a number with its unit, or a label.
@immutable
final class ChartCell {
  const ChartCell.number(this.value, this.unit) : label = null;

  const ChartCell.label(this.label) : value = null, unit = StatUnit.count;

  const ChartCell.empty() : value = null, label = null, unit = StatUnit.count;

  final double? value;
  final StatUnit unit;
  final ChartLabel? label;

  /// Sort key (numbers first, then labels by string form).
  Comparable<Object> get sortKey => value ?? double.negativeInfinity;
}

/// The same numbers as the chart, as rows × columns (sortable in the UI).
@immutable
final class ChartTable {
  const ChartTable(this.columns, this.rows);

  final List<ChartLabel> columns;
  final List<List<ChartCell>> rows;

  bool get isEmpty => rows.isEmpty;
}

// ---------------------------------------------------------------------------------------------
// Chart data variants
// ---------------------------------------------------------------------------------------------

/// Base of every chart model.
@immutable
sealed class ChartData {
  const ChartData();

  /// Tabular alternative with exactly the plotted numbers.
  ChartTable toTable();

  /// True when there is nothing to draw (the frame shows the empty state).
  bool get isEmpty;
}

/// Role of a line series (drives style: dashed overlays, goal/pace lines).
enum SeriesRole { main, rollingMean, trend, goal, pace, previous, band }

/// One series of a [TimeSeriesData] (null values leave gaps — never interpolated).
@immutable
final class ChartSeries {
  const ChartSeries(this.label, this.values, {this.color = const SeriesColor(0), this.role = SeriesRole.main});

  final ChartLabel label;
  final List<double?> values;
  final ChartColor color;
  final SeriesRole role;
}

/// A vertical annotation marker ("rule changed", "vacation", "quit date reset").
@immutable
final class ChartAnnotation {
  const ChartAnnotation(this.index, this.label, {this.kind = AnnotationKind.info});

  /// Bucket index the marker sits on.
  final int index;
  final ChartLabel label;
  final AnnotationKind kind;
}

enum AnnotationKind { info, ruleChange, vacation, reset, record, scopeChange }

/// Trend overlay info (slope per week, T6.1.04).
@immutable
final class TrendInfo {
  const TrendInfo({
    required this.slopePerBucket,
    required this.intercept,
    required this.slopePerWeek,
    required this.direction,
    required this.significant,
  });

  final double slopePerBucket;
  final double intercept;
  final double slopePerWeek;
  final TrendDirection direction;
  final bool significant;
}

/// Line / area chart over date buckets (T6.2.03), also used by burn charts, KM-like step series
/// and forecast cones.
final class TimeSeriesData extends ChartData {
  const TimeSeriesData(
    this.buckets,
    this.series, {
    this.granularity = Granularity.day,
    this.unit = StatUnit.count,
    this.annotations = const [],
    this.trend,
    this.goal,
    this.targetBand,
    this.area = false,
    this.cumulative = false,
    this.step = false,
    this.cone,
    this.drillKeys,
  });

  final List<LocalDate> buckets;
  final List<ChartSeries> series;
  final Granularity granularity;
  final StatUnit unit;
  final List<ChartAnnotation> annotations;
  final TrendInfo? trend;

  /// Constant goal line value.
  final double? goal;

  /// Target band (lower, upper).
  final (double, double)? targetBand;
  final bool area;
  final bool cumulative;
  final bool step;

  /// Forecast cone from the last actual point: per future bucket (p50, p85, p95).
  final ForecastCone? cone;

  /// Drill key per bucket (defaults to the ISO date).
  final List<String?>? drillKeys;

  @override
  bool get isEmpty => buckets.isEmpty || series.every((s) => s.values.every((v) => v == null));

  @override
  ChartTable toTable() => ChartTable(
    [const TokenLabel(LabelToken.current), for (final s in series) s.label],
    [
      for (var i = 0; i < buckets.length; i++)
        [
          ChartCell.label(DateLabel(buckets[i], granularity)),
          for (final s in series)
            i < s.values.length && s.values[i] != null ? ChartCell.number(s.values[i], unit) : const ChartCell.empty(),
        ],
    ],
  );
}

/// A forecast cone appended after the actual series (T6.2.26).
@immutable
final class ForecastCone {
  const ForecastCone(this.dates, this.p50, this.p85, this.p95);

  final List<LocalDate> dates;
  final List<double> p50;
  final List<double> p85;
  final List<double> p95;
}

/// Bar layout variants (T6.2.04).
enum BarLayout { grouped, stacked, percent, horizontal, diverging }

/// One bar series.
@immutable
final class BarSeries {
  const BarSeries(this.label, this.values, {this.color = const SeriesColor(0)});

  final ChartLabel label;
  final List<double> values;
  final ChartColor color;
}

/// A line drawn over bars (capacity, rolling mean, target).
@immutable
final class BarOverlay {
  const BarOverlay(this.label, this.values, {this.color = const ToneColor(ChartTone.warning)});

  /// One value per category (null = gap), or a single value for a constant line.
  final List<double?> values;
  final ChartLabel label;
  final ChartColor color;
}

/// Categorical bars (vertical, horizontal, stacked, grouped, 100 %) — T6.2.04, also histograms.
final class BarData extends ChartData {
  const BarData(
    this.categories,
    this.series, {
    this.layout = BarLayout.grouped,
    this.unit = StatUnit.count,
    this.overlays = const [],
    this.drillKeys,
    this.markers = const [],
    this.isTimeAxis = false,
  });

  final List<ChartLabel> categories;
  final List<BarSeries> series;
  final BarLayout layout;
  final StatUnit unit;
  final List<BarOverlay> overlays;
  final List<String?>? drillKeys;

  /// Vertical markers at category positions (histogram P50/P85, T6.2.14): (position, label).
  final List<(double, ChartLabel)> markers;

  /// Categories are time buckets (mirrored in RTL like time axes).
  final bool isTimeAxis;

  @override
  bool get isEmpty => categories.isEmpty || series.every((s) => s.values.every((v) => v == 0));

  @override
  ChartTable toTable() => ChartTable(
    [const TokenLabel(LabelToken.current), for (final s in series) s.label, for (final o in overlays) o.label],
    [
      for (var i = 0; i < categories.length; i++)
        [
          ChartCell.label(categories[i]),
          for (final s in series) ChartCell.number(i < s.values.length ? s.values[i] : null, unit),
          for (final o in overlays)
            ChartCell.number(o.values.length == 1 ? o.values.first : (i < o.values.length ? o.values[i] : null), unit),
        ],
    ],
  );
}

/// One slice of a donut.
@immutable
final class DonutSlice {
  const DonutSlice(this.label, this.value, {required this.color, this.drillKey});

  final ChartLabel label;
  final double value;
  final ChartColor color;
  final String? drillKey;
}

/// Composition donut (T6.2.05): ≤ 7 slices plus "Other"; slices under 2 % merge into "Other".
final class DonutData extends ChartData {
  DonutData(List<DonutSlice> slices, {this.unit = StatUnit.count, this.centerValue})
    : slices = groupDonutSlices(slices);

  final List<DonutSlice> slices;
  final StatUnit unit;

  /// Headline shown in the center (defaults to the total).
  final double? centerValue;

  double get total => slices.fold(0, (a, s) => a + s.value);

  @override
  bool get isEmpty => total <= 0;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.total), TokenLabel(LabelToken.rate)],
    [
      for (final s in slices)
        [
          ChartCell.label(s.label),
          ChartCell.number(s.value, unit),
          ChartCell.number(total == 0 ? 0 : s.value / total, StatUnit.percent),
        ],
    ],
  );
}

/// Groups donut slices: sorted by value, slices < 2 % and beyond the 7th merge into "Other".
List<DonutSlice> groupDonutSlices(List<DonutSlice> slices, {int maxSlices = 7, double minShare = 0.02}) {
  final positive = [
    for (final s in slices)
      if (s.value > 0) s,
  ]..sort((a, b) => b.value.compareTo(a.value));
  final total = positive.fold<double>(0, (a, s) => a + s.value);
  if (total <= 0) return const [];
  final kept = <DonutSlice>[];
  var other = 0.0;
  for (final s in positive) {
    if (kept.length < maxSlices && s.value / total >= minShare) {
      kept.add(s);
    } else {
      other += s.value;
    }
  }
  if (other > 0) {
    kept.add(DonutSlice(const TokenLabel(LabelToken.other), other, color: const ToneColor(ChartTone.muted)));
  }
  return kept;
}

/// Pareto bars with a cumulative-% line and an 80 % reference (T6.2.05).
final class ParetoData extends ChartData {
  ParetoData(List<(ChartLabel, double)> entries, {this.unit = StatUnit.count, this.drillKeys})
    : entries = _groupPareto(entries);

  final List<(ChartLabel, double)> entries;
  final StatUnit unit;
  final List<String?>? drillKeys;

  double get total => entries.fold(0, (a, e) => a + e.$2);

  /// Cumulative share after each bar (ends at 1.0).
  List<double> get cumulative {
    var run = 0.0;
    final t = total;
    return [for (final e in entries) t == 0 ? 0 : (run += e.$2) / t];
  }

  @override
  bool get isEmpty => total <= 0;

  @override
  ChartTable toTable() {
    final cum = cumulative;
    return ChartTable(
      const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.count), TokenLabel(LabelToken.total)],
      [
        for (var i = 0; i < entries.length; i++)
          [
            ChartCell.label(entries[i].$1),
            ChartCell.number(entries[i].$2, unit),
            ChartCell.number(cum[i], StatUnit.percent),
          ],
      ],
    );
  }
}

/// ≤ 12 bars plus "Other" (the "Unspecified" group stays last).
List<(ChartLabel, double)> _groupPareto(List<(ChartLabel, double)> entries) {
  final unspecified = [
    for (final e in entries)
      if (e.$1 case TokenLabel(token: LabelToken.unspecified)) e,
  ];
  final rest = [
    for (final e in entries)
      if (!unspecified.contains(e) && e.$2 > 0) e,
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  if (rest.length <= 12) return [...rest, ...unspecified];
  final other = rest.skip(12).fold<double>(0, (a, e) => a + e.$2);
  return [...rest.take(12), (const TokenLabel(LabelToken.other), other), ...unspecified];
}

/// Calendar cell: a discrete status or a continuous intensity.
@immutable
final class CalendarCell {
  const CalendarCell({this.tone, this.value, this.label});

  /// Discrete status (status mode).
  final ChartTone? tone;

  /// Continuous value (intensity mode).
  final double? value;

  /// Tooltip / table label (status name).
  final ChartLabel? label;
}

enum CalendarMode { status, intensity }

/// Month calendars / GitHub-style year grids (T6.2.06).
final class CalendarData extends ChartData {
  const CalendarData(
    this.cells, {
    required this.from,
    required this.to,
    this.mode = CalendarMode.status,
    this.unit = StatUnit.count,
    this.today,
    this.thresholds,
  });

  final Map<LocalDate, CalendarCell> cells;
  final LocalDate from;
  final LocalDate to;
  final CalendarMode mode;
  final StatUnit unit;
  final LocalDate? today;

  /// Fixed intensity thresholds (5 bins); quantile bins when null.
  final List<double>? thresholds;

  @override
  bool get isEmpty => cells.isEmpty;

  @override
  ChartTable toTable() {
    final dates = cells.keys.toList()..sort();
    return ChartTable(
      const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.count)],
      [
        for (final d in dates)
          [
            ChartCell.label(DateLabel(d)),
            if (mode == CalendarMode.intensity)
              ChartCell.number(cells[d]!.value, unit)
            else
              cells[d]!.label == null ? const ChartCell.empty() : ChartCell.label(cells[d]!.label),
          ],
      ],
    );
  }
}

/// Weekday × hour punch card (T6.2.09): 7 rows (ISO weekday order in [values]) × 24 columns.
final class PunchCardData extends ChartData {
  const PunchCardData(this.values, {this.unit = StatUnit.count, this.bubbles = false});

  /// `values[weekday.iso - 1][hour]`.
  final List<List<double>> values;
  final StatUnit unit;
  final bool bubbles;

  double get max => values.fold(0, (m, r) => r.fold(m, (a, v) => v > a ? v : a));

  @override
  bool get isEmpty => max <= 0;

  @override
  ChartTable toTable() => ChartTable(
    [const TokenLabel(LabelToken.current), for (var h = 0; h < 24; h++) HourLabel(h)],
    [
      for (var w = 0; w < 7; w++)
        [
          ChartCell.label(WeekdayLabel(Weekday.fromIso(w + 1))),
          for (var h = 0; h < 24; h++) ChartCell.number(values[w][h], unit),
        ],
    ],
  );
}

/// One streak bar (T6.2.08).
@immutable
final class StreakBar {
  const StreakBar({
    required this.start,
    required this.end,
    required this.length,
    this.current = false,
    this.frozenUnits = 0,
  });

  final LocalDate start;
  final LocalDate end;
  final int length;
  final bool current;
  final int frozenUnits;
}

/// Top streaks (ordered by length, then recency) and the streak timeline lane.
final class StreakData extends ChartData {
  StreakData(List<StreakBar> streaks, {this.unit = StatUnit.days, this.timeline = false})
    : streaks = [...streaks]
        ..sort((a, b) {
          final c = b.length.compareTo(a.length);
          return c != 0 ? c : b.end.compareTo(a.end);
        });

  final List<StreakBar> streaks;
  final StatUnit unit;

  /// Draw the calendar lane instead of ranked bars.
  final bool timeline;

  @override
  bool get isEmpty => streaks.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.streak), TokenLabel(LabelToken.count), TokenLabel(LabelToken.frozen)],
    [
      for (final s in streaks)
        [
          ChartCell.label(DateLabel(s.start)),
          ChartCell.number(s.length.toDouble(), unit),
          ChartCell.number(s.frozenUnits.toDouble(), StatUnit.count),
        ],
    ],
  );
}

/// Histogram (T6.2.14) with percentile markers.
final class HistogramData extends ChartData {
  const HistogramData(this.bins, {required this.unit, this.markers = const []});

  /// (lower, upper, count).
  final List<(double, double, int)> bins;
  final StatUnit unit;

  /// (value, label) e.g. P50/P85.
  final List<(double, ChartLabel)> markers;

  int get total => bins.fold(0, (a, b) => a + b.$3);

  @override
  bool get isEmpty => total == 0;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.count)],
    [
      for (final b in bins)
        [ChartCell.label(RangeLabel(b.$1, b.$2, unit)), ChartCell.number(b.$3.toDouble(), StatUnit.count)],
      for (final m in markers) [ChartCell.label(m.$2), ChartCell.number(m.$1, unit)],
    ],
  );
}

/// Five-number summary of one group.
@immutable
final class BoxStats {
  const BoxStats({
    required this.n,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.whiskerLow,
    required this.whiskerHigh,
    this.outliers = const [],
  });

  final int n;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final double whiskerLow;
  final double whiskerHigh;
  final List<double> outliers;
}

/// Grouped box plots (by month / weekday) with n under each box (T6.2.14).
final class BoxPlotData extends ChartData {
  const BoxPlotData(this.groups, {required this.unit});

  final List<(ChartLabel, BoxStats)> groups;
  final StatUnit unit;

  @override
  bool get isEmpty => groups.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [
      TokenLabel(LabelToken.current),
      TokenLabel(LabelToken.count),
      TokenLabel(LabelToken.median),
      TokenLabel(LabelToken.p50),
      TokenLabel(LabelToken.p85),
    ],
    [
      for (final (label, b) in groups)
        [
          ChartCell.label(label),
          ChartCell.number(b.n.toDouble(), StatUnit.count),
          ChartCell.number(b.median, unit),
          ChartCell.number(b.q1, unit),
          ChartCell.number(b.q3, unit),
        ],
    ],
  );
}

/// Scatter variants (T6.2.15).
enum ScatterVariant { planVsActual, byDate, agingWip }

/// One scatter point.
@immutable
final class ScatterPoint {
  const ScatterPoint(this.x, this.y, {this.ref, this.color, this.highlight = false, this.column});

  final double x;
  final double y;
  final DrillRef? ref;
  final ChartColor? color;
  final bool highlight;

  /// Aging WIP: status column index.
  final int? column;
}

/// Scatter data: plan vs actual (y = x and ±20 % band), CT by completion date (percentile lines)
/// or aging WIP (status columns with CT percentile bands).
final class ScatterData extends ChartData {
  const ScatterData(
    this.points, {
    required this.variant,
    required this.xUnit,
    required this.yUnit,
    this.lines = const [],
    this.columns = const [],
  });

  final List<ScatterPoint> points;
  final ScatterVariant variant;
  final StatUnit xUnit;
  final StatUnit yUnit;

  /// Horizontal reference lines (value, label).
  final List<(double, ChartLabel)> lines;

  /// Aging WIP column labels (statuses).
  final List<ChartLabel> columns;

  @override
  bool get isEmpty => points.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    [
      if (variant == ScatterVariant.agingWip)
        const TokenLabel(LabelToken.current)
      else
        const TokenLabel(LabelToken.planned),
      const TokenLabel(LabelToken.actual),
    ],
    [
      for (final p in points)
        [
          if (variant == ScatterVariant.agingWip && p.column != null && p.column! < columns.length)
            ChartCell.label(columns[p.column!])
          else if (variant == ScatterVariant.byDate)
            ChartCell.number(p.x, StatUnit.date)
          else
            ChartCell.number(p.x, xUnit),
          ChartCell.number(p.y, yUnit),
        ],
    ],
  );
}

/// Ordered stacked bands (time allocation over time, cumulative flow — T6.2.16). Bands are listed
/// bottom → top.
final class StackedAreaData extends ChartData {
  const StackedAreaData(
    this.buckets,
    this.bands, {
    this.unit = StatUnit.count,
    this.granularity = Granularity.day,
    this.markers = const [],
  });

  final List<LocalDate> buckets;
  final List<ChartSeries> bands;
  final StatUnit unit;
  final Granularity granularity;

  /// Bucket indices with a marker (e.g. reopens).
  final List<ChartAnnotation> markers;

  @override
  bool get isEmpty => buckets.isEmpty || bands.isEmpty;

  @override
  ChartTable toTable() => TimeSeriesData(buckets, bands, unit: unit, granularity: granularity).toTable();
}

/// Radar chart (T6.2.18): 3–12 axes, 1–2 series; null = no data on that axis (dashed).
final class RadarData extends ChartData {
  const RadarData(this.axes, this.series, {this.unit = StatUnit.percent});

  final List<ChartLabel> axes;
  final List<(ChartLabel, List<double?>)> series;
  final StatUnit unit;

  @override
  bool get isEmpty => axes.length < 3 || series.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    [const TokenLabel(LabelToken.current), for (final s in series) s.$1],
    [
      for (var i = 0; i < axes.length; i++)
        [ChartCell.label(axes[i]), for (final s in series) ChartCell.number(s.$2[i], unit)],
    ],
  );
}

/// 24-hour rose (T6.2.19): counts per sector, circular mean and SD.
final class RoseData extends ChartData {
  const RoseData(this.sectors, {this.meanMinute, this.sdMinutes, this.dayStartMinute = 0, this.consistent = true});

  /// 24 or 48 sector counts starting at 00:00 (civil time).
  final List<double> sectors;
  final double? meanMinute;
  final double? sdMinutes;
  final int dayStartMinute;
  final bool consistent;

  @override
  bool get isEmpty => sectors.every((s) => s <= 0);

  @override
  ChartTable toTable() {
    final minutesPer = 1440 ~/ sectors.length;
    return ChartTable(
      const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.count)],
      [
        for (var i = 0; i < sectors.length; i++)
          [ChartCell.number((i * minutesPer).toDouble(), StatUnit.clock), ChartCell.number(sectors[i], StatUnit.count)],
        if (meanMinute != null)
          [const ChartCell.label(TokenLabel(LabelToken.mean)), ChartCell.number(meanMinute, StatUnit.clock)],
      ],
    );
  }
}

/// A treemap node (T6.2.20).
@immutable
final class TreemapNode {
  const TreemapNode(
    this.label,
    this.value, {
    this.color = const SeriesColor(0),
    this.children = const [],
    this.drillKey,
  });

  final ChartLabel label;
  final double value;
  final ChartColor color;
  final List<TreemapNode> children;
  final String? drillKey;
}

/// Squarified treemap (category → task minutes).
final class TreemapData extends ChartData {
  const TreemapData(this.nodes, {this.unit = StatUnit.minutes});

  final List<TreemapNode> nodes;
  final StatUnit unit;

  @override
  bool get isEmpty => nodes.every((n) => n.value <= 0);

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.total)],
    [
      for (final n in nodes) ...[
        [ChartCell.label(n.label), ChartCell.number(n.value, unit)],
        for (final c in n.children) [ChartCell.label(c.label), ChartCell.number(c.value, unit)],
      ],
    ],
  );
}

enum MatrixScale { sequential, diverging }

/// Generic N × M heatmap (T6.2.21): slot occupancy, phi co-occurrence.
final class MatrixData extends ChartData {
  const MatrixData(
    this.rows,
    this.columns,
    this.values, {
    this.scale = MatrixScale.sequential,
    this.unit = StatUnit.percent,
    this.marks,
  });

  final List<ChartLabel> rows;
  final List<ChartLabel> columns;

  /// `values[row][column]` (null = no data).
  final List<List<double?>> values;
  final MatrixScale scale;
  final StatUnit unit;

  /// Optional significance marks per cell.
  final List<List<bool>>? marks;

  @override
  bool get isEmpty => values.every((r) => r.every((v) => v == null));

  @override
  ChartTable toTable() => ChartTable(
    [const TokenLabel(LabelToken.current), ...columns],
    [
      for (var r = 0; r < rows.length; r++)
        [ChartCell.label(rows[r]), for (final v in values[r]) ChartCell.number(v, unit)],
    ],
  );
}

/// One step of a Kaplan–Meier curve.
@immutable
final class KmPoint {
  const KmPoint(this.t, this.survival, {this.lower, this.upper, this.censored = 0});

  final double t;
  final double survival;
  final double? lower;
  final double? upper;
  final int censored;
}

/// Kaplan–Meier step curve (T6.2.25); time in hours.
final class KmData extends ChartData {
  const KmData(this.points, {this.median, this.n = 0});

  final List<KmPoint> points;

  /// Median survival (null = "median not reached").
  final double? median;
  final int n;

  @override
  bool get isEmpty => points.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.rate)],
    [
      for (final p in points) [ChartCell.number(p.t, StatUnit.hours), ChartCell.number(p.survival, StatUnit.percent)],
    ],
  );
}

/// Monte Carlo finish-date histogram with P50/P85/P95 markers (T6.2.26).
final class ForecastData extends ChartData {
  const ForecastData(
    this.from,
    this.histogram, {
    required this.p50,
    required this.p85,
    required this.p95,
    required this.trials,
  });

  /// Day 0.
  final LocalDate from;

  /// Active days → trial count.
  final Map<int, int> histogram;
  final int p50;
  final int p85;
  final int p95;
  final int trials;

  @override
  bool get isEmpty => histogram.isEmpty;

  @override
  ChartTable toTable() {
    final keys = histogram.keys.toList()..sort();
    return ChartTable(
      const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.rate)],
      [
        for (final k in keys)
          [ChartCell.label(DateLabel(from.plusDays(k))), ChartCell.number(histogram[k]! / trials, StatUnit.percent)],
      ],
    );
  }
}

/// Bullet chart (T6.2.07): actual bar, target marker, previous-period ghost bar, bands.
final class BulletData extends ChartData {
  const BulletData({
    required this.actual,
    this.target,
    this.previous,
    this.max,
    this.unit = StatUnit.count,
    this.bands = const [],
    this.label,
  });

  final double actual;
  final double? target;
  final double? previous;
  final double? max;
  final StatUnit unit;

  /// Qualitative band upper bounds (e.g. poor / ok / good).
  final List<double> bands;
  final ChartLabel? label;

  @override
  bool get isEmpty => false;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.actual), TokenLabel(LabelToken.target), TokenLabel(LabelToken.previous)],
    [
      [ChartCell.number(actual, unit), ChartCell.number(target, unit), ChartCell.number(previous, unit)],
    ],
  );
}

/// Progress rings (single or concentric).
final class RingData extends ChartData {
  const RingData(this.rings, {this.centerValue, this.centerUnit = StatUnit.percent});

  /// (label, progress ≥ 0 (may exceed 1), color).
  final List<(ChartLabel, double, ChartColor)> rings;
  final double? centerValue;
  final StatUnit centerUnit;

  @override
  bool get isEmpty => rings.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.rate)],
    [
      for (final r in rings) [ChartCell.label(r.$1), ChartCell.number(r.$2, StatUnit.percent)],
    ],
  );
}

enum MilestoneRowState { done, inWindow, upcoming }

/// One milestone progress row.
@immutable
final class MilestoneRow {
  const MilestoneRow({
    required this.id,
    required this.label,
    required this.progress,
    required this.state,
    this.eta,
    this.isNext = false,
    this.rangeMarker,
    this.sources = const [],
  });

  final String id;
  final ChartLabel label;
  final double progress;
  final MilestoneRowState state;
  final DateTime? eta;
  final bool isNext;

  /// Range milestones: position (0–1) of tMin on the bar.
  final double? rangeMarker;
  final List<String> sources;
}

/// Milestone bars (T6.2.07): progress, ETA, achieved check.
final class MilestoneData extends ChartData {
  const MilestoneData(this.rows, {this.restarted = false});

  final List<MilestoneRow> rows;

  /// The clock restarted after a lapse (supportive label).
  final bool restarted;

  @override
  bool get isEmpty => rows.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.rate)],
    [
      for (final r in rows) [ChartCell.label(r.label), ChartCell.number(r.progress, StatUnit.percent)],
    ],
  );
}

/// Live counter since an instant (T6.2.07).
final class CounterData extends ChartData {
  const CounterData(this.since, {this.label});

  final DateTime since;
  final ChartLabel? label;

  @override
  bool get isEmpty => false;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current)],
    [
      [ChartCell.label(InstantLabel(since))],
    ],
  );
}

/// One small value tile.
@immutable
final class ValueTile {
  const ValueTile(
    this.label,
    this.value,
    this.unit, {
    this.secondary,
    this.drillKey,
    this.estimate = false,
    this.delta,
    this.deltaIsPp = false,
    this.direction = MetricDirection.higherIsBetter,
    this.metricId,
    this.currency,
  });

  final ChartLabel label;
  final double? value;
  final StatUnit unit;
  final ChartLabel? secondary;
  final String? drillKey;
  final bool estimate;

  /// Δ vs the previous period (pp when [deltaIsPp]).
  final double? delta;
  final bool deltaIsPp;
  final MetricDirection direction;

  /// Metric the tile summarizes (opens its explain sheet / scope).
  final String? metricId;
  final String? currency;
}

/// A group of value tiles.
final class TilesData extends ChartData {
  const TilesData(this.tiles);

  final List<ValueTile> tiles;

  @override
  bool get isEmpty => tiles.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.total)],
    [
      for (final t in tiles) [ChartCell.label(t.label), ChartCell.number(t.value, t.unit)],
    ],
  );
}

/// One ranked list row.
@immutable
final class ListRow {
  const ListRow(this.label, {this.value, this.unit = StatUnit.count, this.secondary, this.ref, this.tone});

  final ChartLabel label;
  final double? value;
  final StatUnit unit;
  final ChartLabel? secondary;
  final DrillRef? ref;
  final ChartTone? tone;
}

/// Ranked list (stale items, at-risk habits, records, integrity flags…).
final class ListData extends ChartData {
  const ListData(this.rows, {this.valueLabel});

  final List<ListRow> rows;
  final ChartLabel? valueLabel;

  @override
  bool get isEmpty => rows.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    [const TokenLabel(LabelToken.current), valueLabel ?? const TokenLabel(LabelToken.total)],
    [
      for (final r in rows) [ChartCell.label(r.label), ChartCell.number(r.value, r.unit)],
    ],
  );
}

/// A time span with a tone (Gantt bars, status timeline segments).
@immutable
final class TimeSpan {
  const TimeSpan(this.start, this.end, {this.tone = ChartTone.primary, this.label});

  final DateTime start;
  final DateTime end;
  final ChartTone tone;
  final ChartLabel? label;
}

/// One Gantt row: planned outline and actual sessions (T6.2.13).
@immutable
final class GanttRow {
  const GanttRow(this.label, {this.planned, this.actual = const [], this.ref});

  final ChartLabel label;
  final TimeSpan? planned;
  final List<TimeSpan> actual;
  final DrillRef? ref;
}

/// Planned vs actual Gantt.
final class GanttData extends ChartData {
  const GanttData(this.rows, {required this.from, required this.to});

  final List<GanttRow> rows;
  final DateTime from;
  final DateTime to;

  @override
  bool get isEmpty => rows.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.planned), TokenLabel(LabelToken.actual)],
    [
      for (final r in rows)
        [
          ChartCell.label(r.label),
          ChartCell.number(
            r.planned == null ? null : r.planned!.end.difference(r.planned!.start).inSeconds / 60,
            StatUnit.minutes,
          ),
          ChartCell.number(
            r.actual.fold<double>(0, (a, s) => a + s.end.difference(s.start).inSeconds / 60),
            StatUnit.minutes,
          ),
        ],
    ],
  );
}

/// Status timeline of one item (CL-I-07): colored segments with notes.
final class StatusTimelineData extends ChartData {
  const StatusTimelineData(this.segments, {required this.now});

  final List<TimeSpan> segments;
  final DateTime now;

  @override
  bool get isEmpty => segments.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.current), TokenLabel(LabelToken.total)],
    [
      for (final s in segments)
        [
          ChartCell.label(s.label ?? const TokenLabel(LabelToken.other)),
          ChartCell.number(s.end.difference(s.start).inSeconds / 60, StatUnit.minutes),
        ],
    ],
  );
}

/// One reschedule (PL-T-08 move timeline).
@immutable
final class MoveEvent {
  const MoveEvent(this.at, {required this.fromEpochMinute, required this.toEpochMinute});

  final DateTime at;
  final int fromEpochMinute;
  final int toEpochMinute;

  int get deltaMinutes => toEpochMinute - fromEpochMinute;
}

/// Kinds of review entries (wins and attention items, T6.7.02).
enum ReviewEntryKind {
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

/// One win or attention entry (tapping it opens [ref]).
@immutable
final class ReviewEntry {
  const ReviewEntry(this.kind, {this.ref, this.title, this.value, this.date});

  final ReviewEntryKind kind;
  final DrillRef? ref;
  final String? title;
  final double? value;
  final LocalDate? date;
}

/// A report layout (weekly / monthly review, T6.7.02/T6.7.04).
final class ReviewData extends ChartData {
  const ReviewData({
    required this.from,
    required this.to,
    required this.headline,
    this.wins = const [],
    this.attention = const [],
    this.topCategories = const [],
    this.nextWeek = const [],
    this.perDay = false,
  });

  final LocalDate from;
  final LocalDate to;

  /// Headline KPI tiles with their Δ.
  final List<ValueTile> headline;
  final List<ReviewEntry> wins;
  final List<ReviewEntry> attention;

  /// (category, minutes, Δ minutes or null when new).
  final List<(ChartLabel, double, double?)> topCategories;

  /// Next week's load: (date, planned minutes, capacity minutes, overbooked).
  final List<(LocalDate, double, double, bool)> nextWeek;

  /// Comparisons use per-day averages (monthly reviews of unequal months).
  final bool perDay;

  @override
  bool get isEmpty => headline.isEmpty && wins.isEmpty && attention.isEmpty;

  @override
  ChartTable toTable() => TilesData(headline).toTable();
}

/// Several related charts shown as tabs in one card (e.g. craving Pareto + punch card).
final class ChartGroup extends ChartData {
  const ChartGroup(this.charts);

  /// (tab label, chart).
  final List<(ChartLabel, ChartData)> charts;

  @override
  bool get isEmpty => charts.every((c) => c.$2.isEmpty);

  @override
  ChartTable toTable() {
    final first = charts.firstWhere((c) => !c.$2.isEmpty, orElse: () => charts.first);
    return first.$2.toTable();
  }
}

/// Move timeline: one dot per reschedule with an arrow old → new.
final class MoveTimelineData extends ChartData {
  const MoveTimelineData(this.moves);

  final List<MoveEvent> moves;

  @override
  bool get isEmpty => moves.isEmpty;

  @override
  ChartTable toTable() => ChartTable(
    const [TokenLabel(LabelToken.moved), TokenLabel(LabelToken.total)],
    [
      for (final m in moves)
        [ChartCell.label(InstantLabel(m.at)), ChartCell.number(m.deltaMinutes.toDouble(), StatUnit.minutes)],
    ],
  );
}
