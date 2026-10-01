/// Monte Carlo forecasting (T6.1.26): "when will it be done" and "how many by date X".
///
/// Daily throughput is resampled (with replacement) from a history pool — by default the last
/// 6 weeks of *active* days, including active days with zero throughput (inactive days such as
/// days off or pauses are left out of the pool and skipped when mapping forecast days to dates).
/// 10 000 trials with an injected seeded [math.Random].
///
/// Percentiles are read from the empirical distribution of the trials (inverse CDF, no
/// interpolation): "P85 = d" means 85 % of the trials finished within d days.
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// Default number of trials.
const int monteCarloTrials = 10000;

/// Safety cap on simulated days per trial.
const int monteCarloMaxDays = 3650;

/// Builds the resampling pool: completions per active day between [from] and [to] (inclusive).
/// Days for which [isActive] returns false are excluded; missing days count as 0.
List<int> throughputPool(
  Map<LocalDate, int> completionsPerDay, {
  required LocalDate from,
  required LocalDate to,
  bool Function(LocalDate date)? isActive,
}) => [
  for (var d = from; !d.isAfter(to); d = d.plusDays(1))
    if (isActive == null || isActive(d)) completionsPerDay[d] ?? 0,
];

/// Distribution of the number of (active) days needed to finish.
@immutable
final class const ForecastWhen(
  final num remaining, {
  required final int p50Days,
  required final int p85Days,
  required final int p95Days,
  required final Map<int, int> histogram,
  required final int trials,
  required final int unfinishedTrials,
}) {
  /// Probability (0–1) of finishing within [days].
  double probabilityWithin(int days) {
    var hit = 0;
    histogram.forEach((d, c) {
      if (d <= days) hit += c;
    });
    return trials == 0 ? 0 : hit / trials;
  }
}

/// Distribution of the number of items completed within a horizon.
@immutable
final class const ForecastHowMany(
  final int days, {
  required final int atLeastP50,
  required final int atLeastP85,
  required final int atLeastP95,
  required final Map<int, int> histogram,
  required final int trials,
});

Insufficient<T>? _checkPool<T>(List<num> pool, int minPoolDays, num minCompletions) {
  if (pool.length < minPoolDays) {
    return Insufficient<T>(minPoolDays, pool.length, 'monteCarloHistory');
  }
  final completions = pool.fold<num>(0, (a, b) => a + b);
  if (completions < minCompletions || completions <= 0) {
    return Insufficient<T>(math.max(minCompletions, 1), completions, 'monteCarloCompletions');
  }
  return null;
}

int _percentileFromHistogram(Map<int, int> histogram, int trials, double p) {
  final keys = histogram.keys.toList()..sort();
  final target = (p * trials).ceil();
  var cumulative = 0;
  for (final k in keys) {
    cumulative += histogram[k]!;
    if (cumulative >= target) return k;
  }
  return keys.isEmpty ? 0 : keys.last;
}

/// "When": days needed to complete [remaining] (items, or any fractional progress such as money for
/// goal forecasts), P50/P85/P95 (CL-L-28, GL-18).
///
/// Needs ≥ [minPoolDays] pool days (default 30) and a pool total ≥ [minCompletions] (default 10);
/// a zero-throughput history is [Insufficient]. `remaining = 0` finishes on day 0.
Stat<ForecastWhen> monteCarloWhen({
  required List<num> pool,
  required num remaining,
  required math.Random random,
  int trials = monteCarloTrials,
  int minPoolDays = 30,
  num minCompletions = 10,
}) {
  final insufficient = _checkPool<ForecastWhen>(pool, minPoolDays, minCompletions);
  if (insufficient != null) return insufficient;
  final histogram = <int, int>{};
  var unfinished = 0;
  for (var t = 0; t < trials; t++) {
    num done = 0;
    var day = 0;
    while (done < remaining && day < monteCarloMaxDays) {
      done += pool[random.nextInt(pool.length)];
      day++;
    }
    if (done < remaining) unfinished++;
    histogram[day] = (histogram[day] ?? 0) + 1;
  }
  return Value<ForecastWhen>(
    ForecastWhen(
      remaining,
      p50Days: _percentileFromHistogram(histogram, trials, 0.5),
      p85Days: _percentileFromHistogram(histogram, trials, 0.85),
      p95Days: _percentileFromHistogram(histogram, trials, 0.95),
      histogram: histogram,
      trials: trials,
      unfinishedTrials: unfinished,
    ),
    sampleSize: pool.length,
  );
}

/// "How many by date X": items completed within [days] active days. The reported numbers are the
/// counts reached **at least** with 50/85/95 % probability (the 50th/15th/5th percentiles).
Stat<ForecastHowMany> monteCarloHowMany({
  required List<int> pool,
  required int days,
  required math.Random random,
  int trials = monteCarloTrials,
  int minPoolDays = 30,
  int minCompletions = 10,
}) {
  final insufficient = _checkPool<ForecastHowMany>(pool, minPoolDays, minCompletions);
  if (insufficient != null) return insufficient;
  final histogram = <int, int>{};
  for (var t = 0; t < trials; t++) {
    var done = 0;
    for (var d = 0; d < days; d++) {
      done += pool[random.nextInt(pool.length)];
    }
    histogram[done] = (histogram[done] ?? 0) + 1;
  }
  int atLeast(double p) {
    // Largest count c such that P(X ≥ c) ≥ p.
    final keys = histogram.keys.toList()..sort((a, b) => b.compareTo(a));
    var cumulative = 0;
    for (final k in keys) {
      cumulative += histogram[k]!;
      if (cumulative >= p * trials - 1e-9) return k;
    }
    return 0;
  }

  return Value<ForecastHowMany>(
    ForecastHowMany(
      days,
      atLeastP50: atLeast(0.5),
      atLeastP85: atLeast(0.85),
      atLeastP95: atLeast(0.95),
      histogram: histogram,
      trials: trials,
    ),
    sampleSize: pool.length,
  );
}

/// Maps a number of active forecast days to a calendar date, starting the day after [from] and
/// skipping inactive days.
LocalDate forecastDate(LocalDate from, int activeDays, {bool Function(LocalDate date)? isActive}) {
  var date = from;
  var counted = 0;
  var guard = 0;
  while (counted < activeDays && guard < monteCarloMaxDays * 2) {
    date = date.plusDays(1);
    guard++;
    if (isActive == null || isActive(date)) counted++;
  }
  return date;
}
