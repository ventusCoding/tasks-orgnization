/// Descriptive statistics & distributions (T6.1.02).
///
/// Conventions:
/// - Percentiles use **Hyndman–Fan type 7** (linear interpolation between closest ranks; NumPy's
///   default, Excel `PERCENTILE.INC`): h = (n − 1)·q, Q(q) = x⌊h⌋ + (h − ⌊h⌋)(x⌊h⌋+1 − x⌊h⌋).
/// - Variance/SD are computed with Welford's online algorithm, in sample (n − 1) and population (n)
///   forms.
/// - Empty input yields [Insufficient]; nothing returns `NaN`.
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

List<double> _sorted(Iterable<num> xs) =>
    [for (final x in xs) x.toDouble()]..sort();

Stat<double> _emptyGuard(int n, int required) => Insufficient<double>(
  required,
  n,
  n == 0 ? Reasons.empty : Reasons.needsMoreData,
);

/// Welford's online mean/variance accumulator.
final class Welford {
  int _n = 0;
  double _mean = 0;
  double _m2 = 0;

  int get n => _n;

  /// Running mean (0 before the first value).
  double get mean => _mean;

  void add(num x) {
    _n++;
    final delta = x - _mean;
    _mean += delta / _n;
    _m2 += delta * (x - _mean);
  }

  void addAll(Iterable<num> xs) => xs.forEach(add);

  /// Sample variance Σ(x − x̄)²/(n − 1); needs n ≥ 2.
  Stat<double> get sampleVariance => _n < 2
      ? _emptyGuard(_n, 2)
      : Stat.ofDouble(_m2 / (_n - 1), sampleSize: _n);

  /// Population variance Σ(x − x̄)²/n; needs n ≥ 1.
  Stat<double> get populationVariance =>
      _n < 1 ? _emptyGuard(_n, 1) : Stat.ofDouble(_m2 / _n, sampleSize: _n);
}


/// Σx (0 for empty input).
double sum(Iterable<num> xs) =>
    xs.fold<double>(0, (acc, x) => acc + x.toDouble());

/// Arithmetic mean x̄ = Σx/n.
Stat<double> mean(Iterable<num> xs) {
  final list = xs.toList();
  if (list.isEmpty) return _emptyGuard(0, 1);
  return Stat.ofDouble(sum(list) / list.length, sampleSize: list.length);
}

/// Type-7 quantile for q ∈ [0, 1].
Stat<double> quantile(Iterable<num> xs, double q) {
  if (q < 0 || q > 1) {
    throw ArgumentError.value(q, 'q', 'must be within [0, 1]');
  }
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return _emptyGuard(0, 1);
  return Value<double>(quantileSorted(sorted, q), sampleSize: sorted.length);
}

/// Type-7 quantile of an already sorted, non-empty list.
double quantileSorted(List<double> sorted, double q) {
  final h = (sorted.length - 1) * q;
  final lo = h.floor();
  final hi = h.ceil();
  if (lo == hi) return sorted[lo];
  return sorted[lo] + (h - lo) * (sorted[hi] - sorted[lo]);
}

/// Type-7 percentile for p ∈ [0, 100].
Stat<double> percentile(Iterable<num> xs, double p) => quantile(xs, p / 100);

/// Median (P50).
Stat<double> median(Iterable<num> xs) => quantile(xs, 0.5);

Stat<double> p50(Iterable<num> xs) => quantile(xs, 0.5);
Stat<double> p70(Iterable<num> xs) => quantile(xs, 0.7);
Stat<double> p80(Iterable<num> xs) => quantile(xs, 0.8);
Stat<double> p85(Iterable<num> xs) => quantile(xs, 0.85);
Stat<double> p90(Iterable<num> xs) => quantile(xs, 0.9);
Stat<double> p95(Iterable<num> xs) => quantile(xs, 0.95);

/// Most frequent value; ties resolve to the smallest value.
Stat<double> mode(Iterable<num> xs) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return _emptyGuard(0, 1);
  var best = sorted.first;
  var bestCount = 0;
  var i = 0;
  while (i < sorted.length) {
    var j = i;
    while (j < sorted.length && sorted[j] == sorted[i]) {
      j++;
    }
    if (j - i > bestCount) {
      bestCount = j - i;
      best = sorted[i];
    }
    i = j;
  }
  return Value<double>(best, sampleSize: sorted.length);
}

Stat<double> minimum(Iterable<num> xs) {
  final sorted = _sorted(xs);
  return sorted.isEmpty
      ? _emptyGuard(0, 1)
      : Value<double>(sorted.first, sampleSize: sorted.length);
}

Stat<double> maximum(Iterable<num> xs) {
  final sorted = _sorted(xs);
  return sorted.isEmpty
      ? _emptyGuard(0, 1)
      : Value<double>(sorted.last, sampleSize: sorted.length);
}

/// max − min.
Stat<double> valueRange(Iterable<num> xs) {
  final sorted = _sorted(xs);
  return sorted.isEmpty
      ? _emptyGuard(0, 1)
      : Value<double>(sorted.last - sorted.first, sampleSize: sorted.length);
}

/// Variance: sample (n − 1, needs n ≥ 2) or population (n).
Stat<double> variance(Iterable<num> xs, {bool sample = true}) {
  final w = Welford()..addAll(xs);
  return sample ? w.sampleVariance : w.populationVariance;
}

/// Standard deviation √variance.
Stat<double> standardDeviation(Iterable<num> xs, {bool sample = true}) =>
    variance(xs, sample: sample).map(math.sqrt);

/// Coefficient of variation CV = SD/mean; [NotApplicable]`('zeroMean')` when the mean is 0.
Stat<double> coefficientOfVariation(Iterable<num> xs, {bool sample = true}) {
  final list = xs.toList();
  final sd = standardDeviation(list, sample: sample);
  if (sd is! Value<double>) return sd;
  final m = sum(list) / list.length;
  if (m == 0) return const NotApplicable<double>(Reasons.zeroMean);
  return Stat.ofDouble(sd.value / m, sampleSize: list.length);
}

/// Interquartile range Q3 − Q1 (type 7).
Stat<double> interquartileRange(Iterable<num> xs) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return _emptyGuard(0, 1);
  return Value<double>(
    quantileSorted(sorted, 0.75) - quantileSorted(sorted, 0.25),
    sampleSize: sorted.length,
  );
}

/// Median absolute deviation median(|x − median(x)|)·[scale] (unscaled by default; pass 1.4826
/// for the normal-consistent estimator used by R's `mad`).
Stat<double> medianAbsoluteDeviation(Iterable<num> xs, {double scale = 1}) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return _emptyGuard(0, 1);
  final med = quantileSorted(sorted, 0.5);
  final deviations = _sorted(sorted.map((x) => (x - med).abs()));
  return Value<double>(
    quantileSorted(deviations, 0.5) * scale,
    sampleSize: sorted.length,
  );
}

/// Trimmed mean: drops ⌊proportion·n⌋ values from each end (SciPy `trim_mean` semantics; default
/// 10 %).
Stat<double> trimmedMean(Iterable<num> xs, {double proportion = 0.1}) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return _emptyGuard(0, 1);
  final cut = (proportion * sorted.length).floor();
  final kept = sorted.sublist(cut, sorted.length - cut);
  if (kept.isEmpty) return _emptyGuard(sorted.length, sorted.length + 1);
  return Value<double>(sum(kept) / kept.length, sampleSize: sorted.length);
}

/// Geometric mean exp(mean(ln x)); every value must be > 0.
Stat<double> geometricMean(Iterable<num> xs) {
  final list = xs.toList();
  if (list.isEmpty) return _emptyGuard(0, 1);
  if (list.any((x) => x <= 0)) {
    return const NotApplicable<double>(Reasons.nonPositive);
  }
  return Stat.ofDouble(
    math.exp(sum(list.map(math.log)) / list.length),
    sampleSize: list.length,
  );
}

/// median(ln R) for ratios R > 0.
Stat<double> medianLogRatio(Iterable<num> ratios) {
  final list = ratios.toList();
  if (list.isEmpty) return _emptyGuard(0, 1);
  if (list.any((r) => r <= 0)) {
    return const NotApplicable<double>(Reasons.nonPositive);
  }
  return median(list.map(math.log));
}

/// Estimation bias b = exp(median(ln R)) − 1 (PL-X-21): > 0 means tasks take longer than planned.
Stat<double> estimationBias(Iterable<num> ratios) =>
    medianLogRatio(ratios).map((m) => math.exp(m) - 1);

/// Summary of a sample (all fields from the same data).
@immutable
final class const DescriptiveSummary(
  final int n, {
  required final double sum,
  required final double mean,
  required final double median,
  required final double min,
  required final double max,
  required final double q1,
  required final double q3,
  required final double? sampleSd,
  required final double populationSd,
});

/// One-pass summary; [Insufficient] for empty input.
Stat<DescriptiveSummary> describe(Iterable<num> xs) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return const Insufficient<DescriptiveSummary>(1, 0);
  final w = Welford()..addAll(sorted);
  return Value<DescriptiveSummary>(
    DescriptiveSummary(
      sorted.length,
      sum: sum(sorted),
      mean: w.mean,
      median: quantileSorted(sorted, 0.5),
      min: sorted.first,
      max: sorted.last,
      q1: quantileSorted(sorted, 0.25),
      q3: quantileSorted(sorted, 0.75),
      sampleSd: w.sampleVariance.valueOrNull == null
          ? null
          : math.sqrt(w.sampleVariance.valueOrNull!),
      populationSd: math.sqrt(w.populationVariance.valueOr(0)),
    ),
    sampleSize: sorted.length,
  );
}

/// A histogram bin `[lower, upper)` (the last bin is closed `[lower, upper]`).
@immutable
final class const HistogramBin(
  final double lower,
  final double upper,
  final int count,
) {
  double get width => upper - lower;

  @override
  String toString() => '[$lower, $upper): $count';
}

/// Histogram with its bins; values outside the explicit edges are counted in [underflow] /
/// [overflow].
@immutable
final class const Histogram(
  final List<HistogramBin> bins, {
  final int underflow = 0,
  final int overflow = 0,
}) {
  int get total => bins.fold(0, (acc, b) => acc + b.count);

  List<double> get edges => [
    if (bins.isNotEmpty) bins.first.lower,
    for (final b in bins) b.upper,
  ];
}

/// Bins [xs] with explicit ascending [edges]. A value on a boundary goes into the upper bin,
/// except a value equal to the last edge, which goes into the last bin.
Histogram histogramWithEdges(Iterable<num> xs, List<double> edges) {
  if (edges.length < 2) {
    throw ArgumentError.value(edges, 'edges', 'needs at least two edges');
  }
  for (var i = 1; i < edges.length; i++) {
    if (!(edges[i] > edges[i - 1])) {
      throw ArgumentError.value(edges, 'edges', 'must be strictly ascending');
    }
  }
  final counts = List<int>.filled(edges.length - 1, 0);
  var under = 0;
  var over = 0;
  for (final raw in xs) {
    final x = raw.toDouble();
    if (x < edges.first) {
      under++;
    } else if (x > edges.last) {
      over++;
    } else if (x == edges.last) {
      counts[counts.length - 1]++;
    } else {
      // Binary search for the bin with edges[i] ≤ x < edges[i + 1].
      var lo = 0;
      var hi = edges.length - 1;
      while (hi - lo > 1) {
        final mid = (lo + hi) >> 1;
        if (edges[mid] <= x) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      counts[lo]++;
    }
  }
  return Histogram(
    [
      for (var i = 0; i < counts.length; i++)
        HistogramBin(edges[i], edges[i + 1], counts[i]),
    ],
    underflow: under,
    overflow: over,
  );
}

/// Fixed-width bins (e.g. 5-minute bins). Edges start at [origin] (default ⌊min/width⌋·width) and
/// cover the maximum.
Histogram histogramFixedWidth(
  Iterable<num> xs,
  double width, {
  double? origin,
}) {
  if (width <= 0) throw ArgumentError.value(width, 'width', 'must be > 0');
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return const Histogram([]);
  final start = origin ?? (sorted.first / width).floor() * width;
  final binCount = math.max(1, ((sorted.last - start) / width).ceil());
  final edges = [for (var i = 0; i <= binCount; i++) start + i * width];
  return histogramWithEdges(sorted, edges);
}

/// Freedman–Diaconis binning: width = 2·IQR·n^(−1/3), bin count clamped to [minBins, maxBins]
/// (5–40 by default); equal-width bins between min and max. A constant sample gives one bin.
Histogram histogramFreedmanDiaconis(
  Iterable<num> xs, {
  int minBins = 5,
  int maxBins = 40,
}) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return const Histogram([]);
  final lo = sorted.first;
  final hi = sorted.last;
  if (hi == lo) return Histogram([HistogramBin(lo, hi, sorted.length)]);
  final iqr = quantileSorted(sorted, 0.75) - quantileSorted(sorted, 0.25);
  final fdWidth = 2 * iqr * math.pow(sorted.length, -1 / 3);
  final rawBins = fdWidth <= 0 ? maxBins : ((hi - lo) / fdWidth).ceil();
  final bins = rawBins.clamp(minBins, maxBins);
  final width = (hi - lo) / bins;
  final edges = [
    for (var i = 0; i < bins; i++) lo + i * width,
    hi,
  ];
  return histogramWithEdges(sorted, edges);
}

/// Box-plot summary: five numbers (type-7 quartiles), whiskers at the most extreme values within
/// 1.5·IQR of the quartiles, and the outliers beyond.
@immutable
final class const BoxPlotSummary(
  final int n, {
  required final double min,
  required final double q1,
  required final double median,
  required final double q3,
  required final double max,
  required final double whiskerLow,
  required final double whiskerHigh,
  required final List<double> outliers,
}) {
  double get iqr => q3 - q1;
}

Stat<BoxPlotSummary> boxPlot(Iterable<num> xs) {
  final sorted = _sorted(xs);
  if (sorted.isEmpty) return const Insufficient<BoxPlotSummary>(1, 0);
  final q1 = quantileSorted(sorted, 0.25);
  final q3 = quantileSorted(sorted, 0.75);
  final iqr = q3 - q1;
  final lowFence = q1 - 1.5 * iqr;
  final highFence = q3 + 1.5 * iqr;
  final inside = sorted.where((x) => x >= lowFence && x <= highFence).toList();
  return Value<BoxPlotSummary>(
    BoxPlotSummary(
      sorted.length,
      min: sorted.first,
      q1: q1,
      median: quantileSorted(sorted, 0.5),
      q3: q3,
      max: sorted.last,
      whiskerLow: inside.first,
      whiskerHigh: inside.last,
      outliers: sorted.where((x) => x < lowFence || x > highFence).toList(),
    ),
    sampleSize: sorted.length,
  );
}

/// Share of values beyond 1.5·IQR of the quartiles (used to pick Theil–Sen over OLS).
double outlierShare(Iterable<num> xs) {
  final sorted = _sorted(xs);
  if (sorted.length < 4) return 0;
  final q1 = quantileSorted(sorted, 0.25);
  final q3 = quantileSorted(sorted, 0.75);
  final iqr = q3 - q1;
  final outliers = sorted
      .where((x) => x < q1 - 1.5 * iqr || x > q3 + 1.5 * iqr)
      .length;
  return outliers / sorted.length;
}
