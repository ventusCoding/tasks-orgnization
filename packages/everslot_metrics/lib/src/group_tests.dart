/// Non-parametric group comparisons: Mann–Whitney U and Kruskal–Wallis H (T6.1.19).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/special_functions.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

/// Average ranks (1-based) of [values]; ties share the mean of their ranks.
List<double> averageRanks(List<num> values) {
  final order = List<int>.generate(values.length, (i) => i)
    ..sort((a, b) => values[a].compareTo(values[b]));
  final ranks = List<double>.filled(values.length, 0);
  var i = 0;
  while (i < order.length) {
    var j = i;
    while (j + 1 < order.length && values[order[j + 1]] == values[order[i]]) {
      j++;
    }
    final avg = (i + j) / 2 + 1;
    for (var k = i; k <= j; k++) {
      ranks[order[k]] = avg;
    }
    i = j + 1;
  }
  return ranks;
}

/// Σ(t³ − t) over tie groups of [values].
double _tieSum(List<num> values) {
  final counts = <num, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  return counts.values.fold(0, (acc, t) => acc + (t * t * t - t).toDouble());
}

/// Mann–Whitney U test result.
@immutable
final class const MannWhitneyResult({
  required final double u,
  required final int nx,
  required final int ny,
  required final double z,
  required final double pValue,
  required final double rankBiserial,
});

/// Mann–Whitney U (two-sided) with average ranks for ties and the tie-corrected normal
/// approximation with continuity correction — the same as R
/// `wilcox.test(x, y, exact = FALSE, correct = TRUE)`.
///
/// - U = R_x − n_x(n_x + 1)/2 (R's W statistic);
/// - σ² = n_x·n_y/12 · ((n + 1) − Σ(t³ − t)/(n(n − 1)));
/// - z = (U − n_x·n_y/2 − 0.5·sign)/σ, p = 2·(1 − Φ(|z|));
/// - effect size: rank-biserial r = 2U/(n_x·n_y) − 1 (> 0 when x tends to be larger).
Stat<MannWhitneyResult> mannWhitneyU(List<num> x, List<num> y) {
  if (x.isEmpty || y.isEmpty) {
    return Insufficient<MannWhitneyResult>(1, math.min(x.length, y.length));
  }
  final all = [...x, ...y];
  final ranks = averageRanks(all);
  final nx = x.length;
  final ny = y.length;
  final n = nx + ny;
  var rx = 0.0;
  for (var i = 0; i < nx; i++) {
    rx += ranks[i];
  }
  final u = rx - nx * (nx + 1) / 2;
  final sigma = math.sqrt(
    nx * ny / 12 * ((n + 1) - _tieSum(all) / (n * (n - 1))),
  );
  if (sigma == 0) {
    return const NotApplicable<MannWhitneyResult>(Reasons.noVariance);
  }
  final diff = u - nx * ny / 2;
  final correction = diff == 0 ? 0 : 0.5 * diff.sign;
  final z = (diff - correction) / sigma;
  return Value<MannWhitneyResult>(
    MannWhitneyResult(
      u: u,
      nx: nx,
      ny: ny,
      z: z,
      pValue: math.min(1, normalTwoSidedP(z)),
      rankBiserial: 2 * u / (nx * ny) - 1,
    ),
    sampleSize: n,
  );
}

/// Kruskal–Wallis H test result.
@immutable
final class const KruskalWallisResult({
  required final double h,
  required final int degreesOfFreedom,
  required final double pValue,
  required final double epsilonSquared,
  required final int n,
});

/// Kruskal–Wallis H with the tie correction; p from χ² with k − 1 degrees of freedom (R
/// `kruskal.test`); effect size ε² = H/(n − 1) (= H/((n² − 1)/(n + 1))). Empty groups are ignored;
/// needs ≥ 2 non-empty groups.
Stat<KruskalWallisResult> kruskalWallis(List<List<num>> groups) {
  final nonEmpty = groups.where((g) => g.isNotEmpty).toList();
  if (nonEmpty.length < 2) {
    return Insufficient<KruskalWallisResult>(2, nonEmpty.length);
  }
  final all = [for (final g in nonEmpty) ...g];
  final n = all.length;
  final ranks = averageRanks(all);
  var h = 0.0;
  var offset = 0;
  for (final g in nonEmpty) {
    var r = 0.0;
    for (var i = 0; i < g.length; i++) {
      r += ranks[offset + i];
    }
    h += r * r / g.length;
    offset += g.length;
  }
  h = 12 / (n * (n + 1)) * h - 3 * (n + 1);
  final correction = 1 - _tieSum(all) / (n * n * n - n);
  if (correction <= 0) {
    return const NotApplicable<KruskalWallisResult>(Reasons.noVariance);
  }
  h /= correction;
  final df = nonEmpty.length - 1;
  return Value<KruskalWallisResult>(
    KruskalWallisResult(
      h: h,
      degreesOfFreedom: df,
      pValue: chiSquareUpperTail(h, df.toDouble()),
      epsilonSquared: n > 1 ? h / (n - 1) : 0,
      n: n,
    ),
    sampleSize: n,
  );
}
