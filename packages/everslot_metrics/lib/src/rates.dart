/// Rates, proportions, Wilson intervals and period-over-period deltas (T6.1.03).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

/// z for a two-sided 95 % interval.
const double z95 = 1.96;

/// Wilson score interval for [successes] out of [trials] (fractional trials allowed):
/// - center = (p̂ + z²/2n) / (1 + z²/n)
/// - half-width = z/(1 + z²/n) · √(p̂(1 − p̂)/n + z²/4n²)
///
/// Returns null when `trials ≤ 0`. The bounds are clamped to [0, 1].
ConfidenceInterval? wilsonInterval(num successes, num trials, {double z = z95}) {
  if (trials <= 0) return null;
  final n = trials.toDouble();
  final p = (successes / n).clamp(0.0, 1.0);
  final z2 = z * z;
  final denominator = 1 + z2 / n;
  final center = (p + z2 / (2 * n)) / denominator;
  final half = z / denominator * math.sqrt(p * (1 - p) / n + z2 / (4 * n * n));
  return ConfidenceInterval(math.max(0, center - half), math.min(1, center + half));
}

/// `successes ÷ trials` in [0, 1] with a Wilson 95 % interval; 0/0 gives
/// [NotApplicable]`('zeroDenominator')`. Fractional (pro-rated) denominators are allowed.
Stat<double> rate(num successes, num trials) {
  if (trials <= 0) return const NotApplicable<double>(Reasons.zeroDenominator);
  final value = successes / trials;
  if (!value.isFinite) return const NotApplicable<double>(Reasons.nonFinite);
  return Value<double>(value, sampleSize: trials, interval: wilsonInterval(successes, trials));
}

/// Weighted rate Σ wᵢ·sᵢ / Σ wᵢ where each sᵢ ∈ [0, 1] (e.g. partial credit).
Stat<double> weightedRate(Iterable<({num score, num weight})> items) {
  var numerator = 0.0;
  var denominator = 0.0;
  for (final item in items) {
    numerator += item.score * item.weight;
    denominator += item.weight;
  }
  return safeDivide(numerator, denominator, sampleSize: denominator);
}

/// Absolute Δ = cur − prev.
double absoluteDelta(num current, num previous) => (current - previous).toDouble();

/// Relative %Δ = (cur − prev)/|prev| as a fraction; prev = 0 gives [NotApplicable]`('new')`.
Stat<double> relativeDelta(num current, num previous) {
  if (previous == 0) return const NotApplicable<double>(Reasons.isNew);
  return Stat.ofDouble((current - previous) / previous.abs());
}

/// Rate delta in percentage points: (cur − prev)·100 for rates in [0, 1].
double percentagePointDelta(double currentRate, double previousRate) => (currentRate - previousRate) * 100;

/// A current value compared with the previous equivalent period.
///
/// For rates ([isRate]) [delta] is in percentage points and [deltaPct] is not applicable (rates are
/// compared in pp); otherwise [delta] is absolute and [deltaPct] relative.
@immutable
final class const PeriodComparison(
  final Stat<double> current,
  final Stat<double> previous, {
  required final Stat<double> delta,
  required final Stat<double> deltaPct,
  required final bool isRate,
});

/// Compares two stats of the same metric (T6.1.03, T6.1.05).
PeriodComparison compareWithPrevious(Stat<double> current, Stat<double> previous, {bool isRate = false}) {
  final cur = current.valueOrNull;
  final prev = previous.valueOrNull;
  if (cur == null || prev == null) {
    final missing = cur == null ? current : previous;
    final reason = switch (missing) {
      Insufficient<double>(:final reasonKey) => reasonKey,
      NotApplicable<double>(:final reasonKey) => reasonKey,
      Value<double>() => Reasons.noData,
    };
    return PeriodComparison(
      current,
      previous,
      delta: NotApplicable<double>(reason),
      deltaPct: NotApplicable<double>(reason),
      isRate: isRate,
    );
  }
  return PeriodComparison(
    current,
    previous,
    delta: Value<double>(isRate ? percentagePointDelta(cur, prev) : absoluteDelta(cur, prev)),
    deltaPct: isRate ? const NotApplicable<double>('rateUsesPp') : relativeDelta(cur, prev),
    isRate: isRate,
  );
}

/// Pro-rated expectation `n · part / whole` (e.g. a quota over a partial period). Fractional;
/// rounding happens only in the UI.
double proRate(num n, num part, num whole) => whole <= 0 ? 0 : n * part / whole;
