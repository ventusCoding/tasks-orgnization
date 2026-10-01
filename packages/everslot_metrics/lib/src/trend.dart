/// Trends: OLS slope with a Student-t p-value, Theil–Sen slope with a bootstrap CI, and the
/// rising/falling trend flag (T6.1.04).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/special_functions.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

/// Ordinary least squares fit y = a + b·x.
@immutable
final class const OlsResult(
  final int n, {
  required final double slope,
  required final double intercept,
  required final double standardError,
  required final double t,
  required final double pValue,
  required final double rSquared,
});

/// OLS slope (T6.1.04):
/// - b = Σ(x−x̄)(y−ȳ)/Σ(x−x̄)²
/// - SE = √(Σres²/(n−2)) / √Σ(x−x̄)²
/// - t = b/SE, two-sided p from Student-t with n−2 degrees of freedom.
///
/// Needs n ≥ 3 points and non-constant x. A perfect fit gives SE = 0 and p = 0.
Stat<OlsResult> ols(List<num> xs, List<num> ys) {
  if (xs.length != ys.length) {
    throw ArgumentError('xs and ys differ in length');
  }
  final n = xs.length;
  if (n < 3) return Insufficient<OlsResult>(3, n);
  final mx = sum(xs) / n;
  final my = sum(ys) / n;
  var sxx = 0.0;
  var sxy = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    final dy = ys[i] - my;
    sxx += dx * dx;
    sxy += dx * dy;
    syy += dy * dy;
  }
  if (sxx == 0) return const NotApplicable<OlsResult>(Reasons.noVariance);
  final b = sxy / sxx;
  final a = my - b * mx;
  var ssRes = 0.0;
  for (var i = 0; i < n; i++) {
    final r = ys[i] - (a + b * xs[i]);
    ssRes += r * r;
  }
  final se = math.sqrt(ssRes / (n - 2)) / math.sqrt(sxx);
  final double t;
  final double p;
  if (se == 0 || se < 1e-12 * b.abs()) {
    t = b == 0 ? 0 : (b > 0 ? double.maxFinite : -double.maxFinite);
    p = b == 0 ? 1 : 0;
  } else {
    t = b / se;
    p = studentTTwoSidedP(t, n - 2.0);
  }
  return Value<OlsResult>(
    OlsResult(n, slope: b, intercept: a, standardError: se, t: t, pValue: p, rSquared: syy == 0 ? 1 : 1 - ssRes / syy),
    sampleSize: n,
  );
}

/// Theil–Sen fit: slope = median of pairwise slopes, intercept = median(y − slope·x).
@immutable
final class const TheilSenResult(
  final int n, {
  required final double slope,
  required final double intercept,
  final ConfidenceInterval? interval,
});

/// Theil–Sen slope: the median of (y_j − y_i)/(x_j − x_i) over pairs i < j with x_i ≠ x_j.
///
/// Above [maxExactPoints] (1 000) points, a seeded subsample of [sampledPairs] (200 000) pairs is
/// used; [random] must then be supplied. With [bootstrapIterations] > 0 a percentile bootstrap
/// 95 % CI is attached (resampling points with replacement, seeded by [random]).
Stat<TheilSenResult> theilSen(
  List<num> xs,
  List<num> ys, {
  math.Random? random,
  int maxExactPoints = 1000,
  int sampledPairs = 200000,
  int bootstrapIterations = 0,
}) {
  if (xs.length != ys.length) {
    throw ArgumentError('xs and ys differ in length');
  }
  final n = xs.length;
  if (n < 2) return Insufficient<TheilSenResult>(2, n);
  final slope = _theilSenSlope(xs, ys, random, maxExactPoints, sampledPairs);
  if (slope == null) {
    return const NotApplicable<TheilSenResult>(Reasons.noVariance);
  }
  final intercept = quantileSorted([for (var i = 0; i < n; i++) ys[i] - slope * xs[i]]..sort(), 0.5);
  ConfidenceInterval? interval;
  if (bootstrapIterations > 0) {
    if (random == null) {
      throw ArgumentError('bootstrap needs a seeded Random');
    }
    final slopes = <double>[];
    for (var b = 0; b < bootstrapIterations; b++) {
      final bx = <num>[];
      final by = <num>[];
      for (var i = 0; i < n; i++) {
        final k = random.nextInt(n);
        bx.add(xs[k]);
        by.add(ys[k]);
      }
      final s = _theilSenSlope(bx, by, random, maxExactPoints, sampledPairs);
      if (s != null) slopes.add(s);
    }
    if (slopes.isNotEmpty) {
      slopes.sort();
      interval = ConfidenceInterval(quantileSorted(slopes, 0.025), quantileSorted(slopes, 0.975));
    }
  }
  return Value<TheilSenResult>(
    TheilSenResult(n, slope: slope, intercept: intercept, interval: interval),
    sampleSize: n,
  );
}

double? _theilSenSlope(List<num> xs, List<num> ys, math.Random? random, int maxExactPoints, int sampledPairs) {
  final n = xs.length;
  final slopes = <double>[];
  if (n <= maxExactPoints) {
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final dx = xs[j] - xs[i];
        if (dx != 0) slopes.add((ys[j] - ys[i]) / dx);
      }
    }
  } else {
    if (random == null) {
      throw ArgumentError('subsampling more than $maxExactPoints points needs a seeded Random');
    }
    for (var k = 0; k < sampledPairs; k++) {
      final i = random.nextInt(n);
      final j = random.nextInt(n);
      final dx = xs[j] - xs[i];
      if (dx != 0) slopes.add((ys[j] - ys[i]) / dx);
    }
  }
  if (slopes.isEmpty) return null;
  slopes.sort();
  return quantileSorted(slopes, 0.5);
}

/// Which estimator produced a trend.
enum TrendMethod { ols, theilSen }

/// Direction label of a trend.
enum TrendDirection {
  rising,
  falling,

  /// Enough data but not significant ("no clear trend").
  stable,
}

/// A trend over a bucketed series, with the slope expressed per week.
@immutable
final class const TrendResult(
  final TrendMethod method, {
  required final double slopePerBucket,
  required final double slopePerWeek,
  required final int n,
  required final TrendDirection direction,
  required final bool significant,
  final double? pValue,
  final ConfidenceInterval? interval,
});

/// OLS residuals of (xs, ys); the values themselves when OLS is not defined.
List<double> _residuals(List<num> xs, List<double> ys) {
  final fit = ols(xs, ys).valueOrNull;
  if (fit == null) return ys;
  return [for (var i = 0; i < ys.length; i++) ys[i] - (fit.intercept + fit.slope * xs[i])];
}

/// Minimum buckets to compute a trend, and to label it significant (T6.1.14).
const int trendMinBuckets = 6;
const int trendSignificanceMinBuckets = 8;

/// Trend of a bucketed series [ys] (`null` buckets are skipped; x = bucket index).
///
/// - Theil–Sen is used when more than 5 % of the points lie beyond 1.5·IQR (outliers), else OLS
///   (override with [method]). Outliers are measured on the OLS residuals, so a steadily trending
///   series is not mistaken for one with outliers.
/// - "rising"/"falling" needs n ≥ 8 buckets and p < [alphaLevel] (OLS) or a bootstrap 95 % CI that
///   excludes 0 (Theil–Sen); otherwise "stable".
/// - The slope is reported per week: slope × 7 / [bucketDays].
Stat<TrendResult> trend(
  List<double?> ys, {
  required double bucketDays,
  required math.Random random,
  TrendMethod? method,
  double alphaLevel = 0.05,
  int bootstrapIterations = 200,
}) {
  final xs = <int>[];
  final vs = <double>[];
  for (var i = 0; i < ys.length; i++) {
    final y = ys[i];
    if (y != null) {
      xs.add(i);
      vs.add(y);
    }
  }
  if (vs.length < trendMinBuckets) {
    return Insufficient<TrendResult>(trendMinBuckets, vs.length);
  }
  final chosen = method ?? (outlierShare(_residuals(xs, vs)) > 0.05 ? TrendMethod.theilSen : TrendMethod.ols);
  final canLabel = vs.length >= trendSignificanceMinBuckets;
  final perWeek = 7 / bucketDays;
  if (chosen == TrendMethod.ols) {
    return ols(xs, vs).map((r) {
      final significant = canLabel && r.pValue < alphaLevel && r.slope != 0;
      return TrendResult(
        TrendMethod.ols,
        slopePerBucket: r.slope,
        slopePerWeek: r.slope * perWeek,
        n: r.n,
        direction: !significant
            ? TrendDirection.stable
            : (r.slope > 0 ? TrendDirection.rising : TrendDirection.falling),
        significant: significant,
        pValue: r.pValue,
      );
    });
  }
  return theilSen(xs, vs, random: random, bootstrapIterations: bootstrapIterations).map((r) {
    final ci = r.interval;
    final significant = canLabel && ci != null && ci.excludesZero;
    return TrendResult(
      TrendMethod.theilSen,
      slopePerBucket: r.slope,
      slopePerWeek: r.slope * perWeek,
      n: r.n,
      direction: !significant ? TrendDirection.stable : (r.slope > 0 ? TrendDirection.rising : TrendDirection.falling),
      significant: significant,
      interval: ci == null ? null : ConfidenceInterval(ci.lower * perWeek, ci.upper * perWeek),
    );
  });
}
