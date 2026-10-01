/// Correlation toolkit & false-discovery control (T6.1.24).
///
/// - phi for two binary daily series (2×2 table);
/// - point-biserial (Pearson between a binary and a numeric series);
/// - Spearman ρ with average ranks;
/// - p-values from the t-approximation t = r·√((n − 2)/(1 − r²)), df = n − 2 (R `cor.test`, with
///   `exact = FALSE` for Spearman);
/// - lag alignment (0–7 days) and Benjamini–Hochberg FDR (q = 0.10).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/group_tests.dart';
import 'package:everslot_metrics/src/special_functions.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// A correlation coefficient with its p-value.
@immutable
final class const CorrelationResult(final double r, {required final int n, required final double pValue});

/// Minimum effect sizes worth reporting.
const double phiEffectThreshold = 0.2;
const double rhoEffectThreshold = 0.3;

/// Default FDR level for the correlations explorer.
const double defaultFdrQ = 0.10;

List<int> _bits(List<bool> flags) => flags.map((f) => f ? 1 : 0).toList();

Stat<CorrelationResult> _withTTest(double r, int n) {
  final clamped = r.clamp(-1.0, 1.0);
  final double p;
  if (n <= 2) {
    p = 1;
  } else if (clamped.abs() >= 1 - 1e-15) {
    p = 0;
  } else {
    final t = clamped * math.sqrt((n - 2) / (1 - clamped * clamped));
    p = studentTTwoSidedP(t, n - 2.0);
  }
  return Value<CorrelationResult>(
    CorrelationResult(clamped, n: n, pValue: p),
    sampleSize: n,
  );
}

/// Pearson r with a two-sided t-test p-value. Needs n ≥ 3 and variance in both series.
Stat<CorrelationResult> pearson(List<num> xs, List<num> ys) {
  if (xs.length != ys.length) {
    throw ArgumentError('xs and ys differ in length');
  }
  final n = xs.length;
  if (n < 3) return Insufficient<CorrelationResult>(3, n);
  var mx = 0.0;
  var my = 0.0;
  for (var i = 0; i < n; i++) {
    mx += xs[i];
    my += ys[i];
  }
  mx /= n;
  my /= n;
  var sxy = 0.0;
  var sxx = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    final dy = ys[i] - my;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }
  if (sxx == 0 || syy == 0) {
    return const NotApplicable<CorrelationResult>(Reasons.noVariance);
  }
  return _withTTest(sxy / math.sqrt(sxx * syy), n);
}

/// phi = (n11·n00 − n10·n01)/√(n1•·n0•·n•1·n•0) for two binary series (equal to Pearson r on
/// 0/1 data; the p-value is the Pearson t-test, i.e. R `cor.test` on the 0/1 vectors).
Stat<CorrelationResult> phiCoefficient(List<bool> a, List<bool> b) => pearson(_bits(a), _bits(b));

/// Point-biserial correlation between a binary [group] and numeric [values] (Pearson on 0/1).
Stat<CorrelationResult> pointBiserial(List<bool> group, List<num> values) => pearson(_bits(group), values);

/// Spearman ρ (Pearson on average ranks) with the t-approximation p-value.
Stat<CorrelationResult> spearman(List<num> xs, List<num> ys) {
  if (xs.length != ys.length) {
    throw ArgumentError('xs and ys differ in length');
  }
  return pearson(averageRanks(xs), averageRanks(ys));
}

/// Pairs `a(d)` with `b(d + lag)` for every date present in both (lag 0–7 days).
({List<double> a, List<double> b, List<LocalDate> dates}) alignWithLag(
  Map<LocalDate, num> a,
  Map<LocalDate, num> b, {
  int lag = 0,
}) {
  final dates = a.keys.where((d) => b.containsKey(d.plusDays(lag))).toList()..sort();
  return (
    a: [for (final d in dates) a[d]!.toDouble()],
    b: [for (final d in dates) b[d.plusDays(lag)]!.toDouble()],
    dates: dates,
  );
}

/// Benjamini–Hochberg adjusted p-values (R `p.adjust(p, method = "BH")`), in input order.
List<double> benjaminiHochberg(List<double> pValues) {
  final m = pValues.length;
  if (m == 0) return const [];
  final order = List<int>.generate(m, (i) => i)..sort((a, b) => pValues[b].compareTo(pValues[a]));
  final adjusted = List<double>.filled(m, 0);
  var running = 1.0;
  for (var k = 0; k < m; k++) {
    final i = order[k];
    final rank = m - k;
    running = math.min(running, pValues[i] * m / rank);
    adjusted[i] = math.min(1, running);
  }
  return adjusted;
}

/// Indices of the discoveries at FDR level [q] (adjusted p ≤ q).
List<int> benjaminiHochbergDiscoveries(List<double> pValues, {double q = defaultFdrQ}) {
  final adjusted = benjaminiHochberg(pValues);
  return [
    for (var i = 0; i < adjusted.length; i++)
      if (adjusted[i] <= q) i,
  ];
}

/// Whether a coefficient is large enough to report (|phi| ≥ 0.2 for binary pairs, |ρ| ≥ 0.3
/// otherwise).
bool meetsEffectThreshold(double coefficient, {required bool binaryPair}) =>
    coefficient.abs() >= (binaryPair ? phiEffectThreshold : rhoEffectThreshold);
