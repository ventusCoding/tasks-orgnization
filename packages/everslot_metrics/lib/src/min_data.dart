/// Minimum-data, confidence & honesty rules (T6.1.14).
///
/// | Metric kind | Hidden below | Shown with a Wilson "±" below |
/// |---|---|---|
/// | Rates | 3 closed units | 20 units |
/// | Means and medians | n = 3 | — |
/// | P85 | n = 10 | — |
/// | P95 | n = 20 | — |
///
/// Trend: 6 buckets (significance label: 8) · Day-of-week effects: 4 weeks · Correlations: 21
/// paired days and 7 days per group · Monte Carlo: 30 days of history and 10 completions ·
/// Kaplan–Meier: 2 attempts.
library;

import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

/// A minimum-sample rule: hidden below [hiddenBelow]; shown with an interval below
/// [intervalBelow] (when set).
@immutable
final class const MinSampleRule(
  final num hiddenBelow, {
  final num? intervalBelow,
  final String reasonKey = Reasons.needsMoreData,
}) {
  /// Whether the "±" interval should be shown for a sample of size [n].
  bool showsInterval(num n) =>
      intervalBelow != null && n >= hiddenBelow && n < intervalBelow!;

  /// Applies the rule: a [Value] with fewer than [hiddenBelow] observations becomes
  /// [Insufficient] (the sample size defaults to the value's own `sampleSize`).
  Stat<T> apply<T>(Stat<T> stat, {num? haveN}) {
    if (stat is! Value<T>) return stat;
    final n = haveN ?? stat.sampleSize ?? 0;
    if (n < hiddenBelow) return Insufficient<T>(hiddenBelow, n, reasonKey);
    return stat;
  }
}

/// Default rules (a metric may override them).
abstract final class MinDataRules {
  static const rate = MinSampleRule(3, intervalBelow: 20);
  static const meanOrMedian = MinSampleRule(3);
  static const p85 = MinSampleRule(10);
  static const p95 = MinSampleRule(20);
  static const trend = MinSampleRule(6);
  static const trendSignificance = MinSampleRule(8);

  /// Day-of-week effects: number of weeks.
  static const dayOfWeekWeeks = MinSampleRule(4);

  /// Correlations: paired days (and [correlationPerGroup] days per binary group).
  static const correlationPairs = MinSampleRule(21);
  static const correlationPerGroup = MinSampleRule(7);

  /// Monte Carlo: days of history and completions.
  static const monteCarloDays = MinSampleRule(30);
  static const monteCarloCompletions = MinSampleRule(10);

  static const kaplanMeierAttempts = MinSampleRule(2);

  /// Estimation accuracy (PL-X-21…23): occurrences with a defined R.
  static const estimation = MinSampleRule(10);
}
