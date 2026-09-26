/// Metric registry definition format and computed results (T6.1.06, T6.1.14). Pure Dart.
library;

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:meta/meta.dart';

/// Computes one metric from its scope context (a `…ComputeContext` of the catalog).
typedef MetricCompute = MetricResult Function(Object context);

/// A metric declared once with everything needed to compute, format, chart, explain and test it.
///
/// Text keys are derived from the id: `statsMetric<Stem>Title|Desc|Formula` (e.g. `PL-X-01` →
/// `statsMetricPlX01Title`) and live in `app/lib/l10n/parts/stats_*.arb`.
@immutable
final class MetricDefinition {
  const MetricDefinition({
    required this.id,
    required this.scope,
    required this.unit,
    required this.chart,
    required this.compute,
    this.direction = MetricDirection.higherIsBetter,
    this.priority = MetricPriority.p0,
    this.minSample,
    this.requires = const {},
    this.isRate = false,
    this.hasSources = false,
    this.estimate = false,
  });

  /// Stable id (`PL-S-03`, `HB-H-01`…).
  final String id;
  final MetricScope scope;
  final StatUnit unit;

  /// Default [6.2] visualization.
  final ChartKind chart;
  final MetricDirection direction;
  final MetricPriority priority;

  /// Minimum-data rule (T6.1.14); null = the metric returns `Insufficient` itself or is a
  /// count/listing that is never hidden.
  final MinSampleRule? minSample;

  /// Tables and settings the metric reads.
  final Set<StatsTable> requires;

  /// Rates are compared in percentage points.
  final bool isRate;

  /// Health metrics cite sources in the explain sheet.
  final bool hasSources;

  /// Estimates carry "≈" (population-based numbers carry a "population estimate" label).
  final bool estimate;

  final MetricCompute compute;

  /// l10n key stem (`PlX01`).
  String get keyStem => metricKeyStem(id);

  String get titleKey => 'statsMetric${keyStem}Title';

  String get descriptionKey => 'statsMetric${keyStem}Desc';

  String get formulaKey => 'statsMetric${keyStem}Formula';
}

/// Builds a [MetricDefinition] whose compute function is typed on its context.
MetricDefinition metric<C>({
  required String id,
  required MetricScope scope,
  required StatUnit unit,
  required ChartKind chart,
  required MetricResult Function(C context) compute,
  MetricDirection direction = MetricDirection.higherIsBetter,
  MetricPriority priority = MetricPriority.p0,
  MinSampleRule? minSample,
  Set<StatsTable> requires = const {},
  bool isRate = false,
  bool hasSources = false,
  bool estimate = false,
}) => MetricDefinition(
  id: id,
  scope: scope,
  unit: unit,
  chart: chart,
  compute: (context) => compute(context as C),
  direction: direction,
  priority: priority,
  minSample: minSample,
  requires: requires,
  isRate: isRate,
  hasSources: hasSources,
  estimate: estimate,
);

/// The computed result of one metric for one scope and period.
@immutable
final class MetricResult {
  const MetricResult(
    this.metricId, {
    required this.value,
    this.unit = StatUnit.count,
    this.previous,
    this.comparison,
    this.chart,
    this.spark,
    this.exclusions = const {},
    this.args = const {},
    this.drill = const {},
    this.currency,
    this.estimate = false,
    this.target,
    this.note,
  });

  /// A result that does not apply to this entity (e.g. volume cards of a yes/no habit).
  const MetricResult.notApplicable(this.metricId, [String reason = 'notApplicable'])
    : value = const NotApplicable<double>('notApplicable'),
      unit = StatUnit.count,
      previous = null,
      comparison = null,
      chart = null,
      spark = null,
      exclusions = const {},
      args = const {},
      drill = const {},
      currency = null,
      estimate = false,
      target = null,
      note = reason;

  final String metricId;

  /// Headline value (rates in [0, 1]; strength in [0, 1]; durations in minutes).
  final Stat<double> value;
  final StatUnit unit;

  /// Value over the previous equivalent period.
  final Stat<double>? previous;

  /// Δ vs the previous period (pp for rates).
  final PeriodComparison? comparison;

  /// Chart model (null = value only).
  final ChartData? chart;

  /// Sparkline of the last buckets (≤ 12).
  final List<double?>? spark;

  /// Exclusions explained in the card and the explain sheet (`{skipped: 3, paused: 2}`).
  final Map<String, num> exclusions;

  /// Arguments for the explain sheet (`n`, `required`, `method`…).
  final Map<String, Object?> args;

  /// Entities behind chart elements, by drill key (T6.2.10).
  final Map<String, List<DrillRef>> drill;

  /// ISO currency code for money metrics.
  final String? currency;

  /// Shown with "≈".
  final bool estimate;

  /// Target marker for KPI tiles.
  final double? target;

  /// Extra message key suffix (e.g. `usedPlanned`, `notSmoking`).
  final String? note;

  bool get hasValue => value is Value<double>;

  /// Returns a copy with a minimum-data rule applied (T6.1.14).
  MetricResult withRule(MinSampleRule? rule, {num? haveN}) {
    if (rule == null) return this;
    final applied = rule.apply(value, haveN: haveN);
    if (identical(applied, value)) return this;
    return MetricResult(
      metricId,
      value: applied,
      unit: unit,
      previous: previous,
      comparison: null,
      chart: chart,
      spark: spark,
      exclusions: exclusions,
      args: args,
      drill: drill,
      currency: currency,
      estimate: estimate,
      target: target,
      note: note,
    );
  }
}

/// Error placeholder when a metric's compute throws (the card shows the error state).
MetricResult metricError(String id, Object error) => MetricResult(
  id,
  value: const NotApplicable<double>('error'),
  note: 'error',
  args: {'error': error.toString()},
);
