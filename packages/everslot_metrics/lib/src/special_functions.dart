/// Special functions used by the statistical tests: log-gamma, regularized incomplete beta and
/// gamma functions, and the normal, Student-t and χ² distributions derived from them.
///
/// Implemented from the classic continued-fraction / series expansions (Numerical Recipes §6.1–6.4,
/// Lanczos approximation with g = 7, n = 9); accuracy is ~1e-14 in the ranges used here.
library;

import 'dart:math' as math;

const double _eps = 1e-16;
const double _fpMin = 1e-300;
const int _maxIterations = 10000;

const List<double> _lanczos = [
  0.99999999999980993,
  676.5203681218851,
  -1259.1392167224028,
  771.32342877765313,
  -176.61502916214059,
  12.507343278686905,
  -0.13857109526572012,
  9.9843695780195716e-6,
  1.5056327351493116e-7,
];

/// ln Γ(x) for x > 0.
double lnGamma(double x) {
  if (x < 0.5) {
    // Reflection: Γ(x)Γ(1−x) = π / sin(πx).
    return math.log(math.pi / math.sin(math.pi * x).abs()) - lnGamma(1 - x);
  }
  final z = x - 1;
  var a = _lanczos[0];
  final t = z + 7.5;
  for (var i = 1; i < 9; i++) {
    a += _lanczos[i] / (z + i);
  }
  return 0.5 * math.log(2 * math.pi) + (z + 0.5) * math.log(t) - t + math.log(a);
}

/// Regularized lower incomplete gamma P(a, x).
double regularizedGammaP(double a, double x) {
  if (x <= 0) return 0;
  if (x < a + 1) return _gammaSeries(a, x);
  return 1 - _gammaContinuedFraction(a, x);
}

/// Regularized upper incomplete gamma Q(a, x) = 1 − P(a, x).
double regularizedGammaQ(double a, double x) {
  if (x <= 0) return 1;
  if (x < a + 1) return 1 - _gammaSeries(a, x);
  return _gammaContinuedFraction(a, x);
}

double _gammaSeries(double a, double x) {
  var ap = a;
  var sum = 1 / a;
  var del = sum;
  for (var n = 0; n < _maxIterations; n++) {
    ap += 1;
    del *= x / ap;
    sum += del;
    if (del.abs() < sum.abs() * _eps) break;
  }
  return sum * math.exp(-x + a * math.log(x) - lnGamma(a));
}

double _gammaContinuedFraction(double a, double x) {
  var b = x + 1 - a;
  var c = 1 / _fpMin;
  var d = 1 / b;
  var h = d;
  for (var i = 1; i < _maxIterations; i++) {
    final an = -i * (i - a);
    b += 2;
    d = an * d + b;
    if (d.abs() < _fpMin) d = _fpMin;
    c = b + an / c;
    if (c.abs() < _fpMin) c = _fpMin;
    d = 1 / d;
    final del = d * c;
    h *= del;
    if ((del - 1).abs() < _eps) break;
  }
  return math.exp(-x + a * math.log(x) - lnGamma(a)) * h;
}

/// Regularized incomplete beta I_x(a, b).
double regularizedIncompleteBeta(double a, double b, double x) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  final lnFront = lnGamma(a + b) - lnGamma(a) - lnGamma(b) + a * math.log(x) + b * math.log(1 - x);
  final front = math.exp(lnFront);
  if (x < (a + 1) / (a + b + 2)) {
    return front * _betaContinuedFraction(a, b, x) / a;
  }
  return 1 - front * _betaContinuedFraction(b, a, 1 - x) / b;
}

double _betaContinuedFraction(double a, double b, double x) {
  final qab = a + b;
  final qap = a + 1;
  final qam = a - 1;
  var c = 1.0;
  var d = 1 - qab * x / qap;
  if (d.abs() < _fpMin) d = _fpMin;
  d = 1 / d;
  var h = d;
  for (var m = 1; m <= _maxIterations; m++) {
    final m2 = 2 * m;
    var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
    d = 1 + aa * d;
    if (d.abs() < _fpMin) d = _fpMin;
    c = 1 + aa / c;
    if (c.abs() < _fpMin) c = _fpMin;
    d = 1 / d;
    h *= d * c;
    aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
    d = 1 + aa * d;
    if (d.abs() < _fpMin) d = _fpMin;
    c = 1 + aa / c;
    if (c.abs() < _fpMin) c = _fpMin;
    d = 1 / d;
    final del = d * c;
    h *= del;
    if ((del - 1).abs() < _eps) break;
  }
  return h;
}

/// Complementary error function erfc(x).
double erfc(double x) => x >= 0 ? regularizedGammaQ(0.5, x * x) : 1 + regularizedGammaP(0.5, x * x);

/// Standard normal CDF Φ(z).
double normalCdf(double z) => 0.5 * erfc(-z / math.sqrt2);

/// Two-sided p-value of a standard normal statistic: 2·(1 − Φ(|z|)).
double normalTwoSidedP(double z) => erfc(z.abs() / math.sqrt2);

/// Student-t CDF with [df] degrees of freedom.
double studentTCdf(double t, double df) {
  final x = df / (df + t * t);
  final tail = 0.5 * regularizedIncompleteBeta(df / 2, 0.5, x);
  return t >= 0 ? 1 - tail : tail;
}

/// Two-sided p-value of a Student-t statistic: I_{df/(df+t²)}(df/2, 1/2).
double studentTTwoSidedP(double t, double df) {
  if (t.isInfinite) return 0;
  return regularizedIncompleteBeta(df / 2, 0.5, df / (df + t * t));
}

/// Upper tail of the χ² distribution: P(X ≥ x) with [df] degrees of freedom.
double chiSquareUpperTail(double x, double df) => regularizedGammaQ(df / 2, x / 2);
