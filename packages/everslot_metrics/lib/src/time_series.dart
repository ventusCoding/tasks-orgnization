/// Time-series utilities: bucketing, gap filling, rolling windows and EWMA (T6.1.04).
///
/// Buckets are keyed by their first local date. Week buckets honour the user's week start
/// (MO/SA/SU…); quarter buckets start in Jan/Apr/Jul/Oct. Count series fill gaps with 0; rate and
/// mean series fill gaps with `null` (no denominator, so there is no point).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// Bucket size of a series.
enum Granularity {
  day,
  week,
  month,
  quarter,
  year;

  /// Nominal length in days (used to express slopes per week): 1, 7, 30.4375, 91.3125, 365.25.
  double get nominalDays => switch (this) {
    Granularity.day => 1,
    Granularity.week => 7,
    Granularity.month => 365.25 / 12,
    Granularity.quarter => 365.25 / 4,
    Granularity.year => 365.25,
  };
}

/// One point of a bucketed series.
@immutable
final class const SeriesPoint<T>(final LocalDate bucket, final T value) {
  @override
  bool operator ==(Object other) =>
      other is SeriesPoint<T> && other.bucket == bucket && other.value == value;

  @override
  int get hashCode => Object.hash(bucket, value);

  @override
  String toString() => '$bucket: $value';
}

/// First date of the bucket containing [date].
LocalDate bucketStart(
  LocalDate date,
  Granularity granularity, {
  Weekday weekStart = Weekday.monday,
}) => switch (granularity) {
  Granularity.day => date,
  Granularity.week => date.startOfWeek(weekStart),
  Granularity.month => date.firstDayOfMonth,
  Granularity.quarter => LocalDate(date.year, ((date.month - 1) ~/ 3) * 3 + 1, 1),
  Granularity.year => LocalDate(date.year, 1, 1),
};

/// First date of the bucket after the one starting at [start].
LocalDate nextBucketStart(LocalDate start, Granularity granularity) =>
    switch (granularity) {
      Granularity.day => start.plusDays(1),
      Granularity.week => start.plusDays(7),
      Granularity.month => start.plusMonths(1),
      Granularity.quarter => start.plusMonths(3),
      Granularity.year => start.plusYears(1),
    };

/// Starts of every bucket overlapping `[from, to]` (inclusive).
List<LocalDate> bucketStarts(
  LocalDate from,
  LocalDate to,
  Granularity granularity, {
  Weekday weekStart = Weekday.monday,
}) {
  final result = <LocalDate>[];
  for (
    var b = bucketStart(from, granularity, weekStart: weekStart);
    !b.isAfter(to);
    b = nextBucketStart(b, granularity)
  ) {
    result.add(b);
  }
  return result;
}

/// Sums values per bucket over `[from, to]`, filling empty buckets with 0 (count series).
/// Values outside the range are ignored.
List<SeriesPoint<double>> bucketSum(
  Iterable<(LocalDate, num)> values, {
  required LocalDate from,
  required LocalDate to,
  required Granularity granularity,
  Weekday weekStart = Weekday.monday,
}) {
  final totals = <LocalDate, double>{};
  for (final (date, v) in values) {
    if (date.isBefore(from) || date.isAfter(to)) continue;
    final key = bucketStart(date, granularity, weekStart: weekStart);
    totals[key] = (totals[key] ?? 0) + v;
  }
  return [
    for (final b in bucketStarts(from, to, granularity, weekStart: weekStart))
      SeriesPoint(b, totals[b] ?? 0),
  ];
}

/// Rate per bucket Σnumerator/Σdenominator; buckets without a denominator are `null`.
List<SeriesPoint<double?>> bucketRate(
  Iterable<(LocalDate, num numerator, num denominator)> values, {
  required LocalDate from,
  required LocalDate to,
  required Granularity granularity,
  Weekday weekStart = Weekday.monday,
}) {
  final nums = <LocalDate, double>{};
  final dens = <LocalDate, double>{};
  for (final (date, n, d) in values) {
    if (date.isBefore(from) || date.isAfter(to)) continue;
    final key = bucketStart(date, granularity, weekStart: weekStart);
    nums[key] = (nums[key] ?? 0) + n;
    dens[key] = (dens[key] ?? 0) + d;
  }
  return [
    for (final b in bucketStarts(from, to, granularity, weekStart: weekStart))
      SeriesPoint(
        b,
        (dens[b] ?? 0) > 0 ? nums[b]! / dens[b]! : null,
      ),
  ];
}

/// Mean per bucket; empty buckets are `null`.
List<SeriesPoint<double?>> bucketMean(
  Iterable<(LocalDate, num)> values, {
  required LocalDate from,
  required LocalDate to,
  required Granularity granularity,
  Weekday weekStart = Weekday.monday,
}) => bucketRate(
  [for (final (d, v) in values) (d, v, 1)],
  from: from,
  to: to,
  granularity: granularity,
  weekStart: weekStart,
);

/// Trailing rolling mean over [window] points ending at each point. Emits `null` when fewer than
/// [minCoverage] (default 50 %) of the window's slots hold a value.
List<double?> rollingMean(
  List<double?> xs,
  int window, {
  double minCoverage = 0.5,
}) => rollingRate(
  [for (final x in xs) x],
  xs.map((x) => x == null ? null : 1).toList(),
  window,
  minCoverage: minCoverage,
);

/// Trailing rolling sum over [window] points (nulls count as 0); `null` when coverage is too low.
List<double?> rollingSum(
  List<double?> xs,
  int window, {
  double minCoverage = 0.5,
}) {
  final result = <double?>[];
  for (var i = 0; i < xs.length; i++) {
    var total = 0.0;
    var have = 0;
    for (var j = math.max(0, i - window + 1); j <= i; j++) {
      final x = xs[j];
      if (x != null) {
        total += x;
        have++;
      }
    }
    result.add(have >= window * minCoverage ? total : null);
  }
  return result;
}

/// Trailing rolling rate Σnumerator/Σdenominator over [window] points (7/28/30/90/180/365).
/// Emits `null` when fewer than [minCoverage] of the window's slots have a denominator > 0.
List<double?> rollingRate(
  List<num?> numerators,
  List<num?> denominators,
  int window, {
  double minCoverage = 0.5,
}) {
  if (numerators.length != denominators.length) {
    throw ArgumentError('numerators and denominators differ in length');
  }
  if (window < 1) throw ArgumentError.value(window, 'window', 'must be ≥ 1');
  final result = <double?>[];
  for (var i = 0; i < numerators.length; i++) {
    var n = 0.0;
    var d = 0.0;
    var covered = 0;
    for (var j = math.max(0, i - window + 1); j <= i; j++) {
      final den = denominators[j];
      if (den != null && den > 0) {
        covered++;
        d += den;
        n += numerators[j] ?? 0;
      }
    }
    result.add(covered >= window * minCoverage && d > 0 ? n / d : null);
  }
  return result;
}

/// α from a half-life h (in points): α = 1 − 0.5^(1/h).
double alphaFromHalfLife(double halfLife) {
  if (halfLife <= 0) {
    throw ArgumentError.value(halfLife, 'halfLife', 'must be > 0');
  }
  return 1 - math.pow(0.5, 1 / halfLife).toDouble();
}

/// Exponentially weighted moving average s_t = α·x_t + (1 − α)·s_{t−1}.
///
/// Give either [alpha] or [halfLife]. The series starts at [initial] (default: the first non-null
/// value); `null` inputs carry the previous smoothed value forward (leading nulls stay `null`).
List<double?> ewma(
  List<double?> xs, {
  double? alpha,
  double? halfLife,
  double? initial,
}) {
  final a = alpha ?? (halfLife != null ? alphaFromHalfLife(halfLife) : null);
  if (a == null || a <= 0 || a > 1) {
    throw ArgumentError('give alpha in (0, 1] or a positive halfLife');
  }
  var s = initial;
  final result = <double?>[];
  for (final x in xs) {
    if (x != null) {
      s = s == null ? x : a * x + (1 - a) * s;
    }
    result.add(s);
  }
  return result;
}

/// Running total; nulls add 0.
List<double> cumulative(List<num?> xs) {
  var total = 0.0;
  return [for (final x in xs) total += x ?? 0];
}
