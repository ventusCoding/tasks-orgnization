/// Result types shared by every metric (T6.1.01).
///
/// Every public computation returns a [Stat] so that `NaN`, `Infinity`, divide-by-zero and
/// "not enough data" never leak into the UI:
/// - [Value] — a finite value, optionally with its sample size and a confidence interval;
/// - [Insufficient] — the metric exists but needs more data (`requiredN` vs `haveN`);
/// - [NotApplicable] — the metric does not apply (zero denominator, no previous period, …).
library;

import 'package:meta/meta.dart';

/// A two-sided confidence interval `[lower, upper]` at [level] (default 95 %).
@immutable
final class const ConfidenceInterval(final double lower, final double upper, {final double level = 0.95}) {
  double get width => upper - lower;

  bool contains(double x) => x >= lower && x <= upper;

  /// True when 0 lies outside the interval (used by trend significance).
  bool get excludesZero => lower > 0 || upper < 0;

  @override
  bool operator ==(Object other) =>
      other is ConfidenceInterval && other.lower == lower && other.upper == upper && other.level == level;

  @override
  int get hashCode => Object.hash(lower, upper, level);

  @override
  String toString() => '[$lower, $upper]@$level';
}

/// The outcome of a metric computation.
@immutable
sealed class Stat<T> {
  const new();

  /// Wraps a double, turning non-finite values into [NotApplicable]`('nonFinite')`.
  static Stat<double> ofDouble(double value, {num? sampleSize, ConfidenceInterval? interval}) => value.isFinite
      ? Value<double>(value, sampleSize: sampleSize, interval: interval)
      : const NotApplicable<double>('nonFinite');

  /// Combines two stats; the first non-[Value] (left to right) wins.
  static Stat<R> combine<A, B, R>(Stat<A> a, Stat<B> b, R Function(A a, B b) combiner) => switch (a) {
    Value<A>(value: final va) => switch (b) {
      Value<B>(value: final vb) => Value<R>(combiner(va, vb)),
      Insufficient<B>() => b.retype<R>(),
      NotApplicable<B>() => b.retype<R>(),
    },
    Insufficient<A>() => a.retype<R>(),
    NotApplicable<A>() => a.retype<R>(),
  };

  bool get hasValue => this is Value<T>;

  T? get valueOrNull => switch (this) {
    Value<T>(:final value) => value,
    _ => null,
  };

  T valueOr(T fallback) => switch (this) {
    Value<T>(:final value) => value,
    _ => fallback,
  };

  Stat<R> map<R>(R Function(T value) transform) => switch (this) {
    final Value<T> v => Value<R>(transform(v.value), sampleSize: v.sampleSize),
    final Insufficient<T> i => i.retype<R>(),
    final NotApplicable<T> n => n.retype<R>(),
  };

  Stat<R> flatMap<R>(Stat<R> Function(T value) transform) => switch (this) {
    final Value<T> v => transform(v.value),
    final Insufficient<T> i => i.retype<R>(),
    final NotApplicable<T> n => n.retype<R>(),
  };

  R fold<R>({
    required R Function(Value<T> value) value,
    required R Function(Insufficient<T> insufficient) insufficient,
    required R Function(NotApplicable<T> notApplicable) notApplicable,
  }) => switch (this) {
    final Value<T> v => value(v),
    final Insufficient<T> i => insufficient(i),
    final NotApplicable<T> n => notApplicable(n),
  };
}

/// A computed value.
final class Value<T> extends Stat<T> {
  const new(this.value, {this.sampleSize, this.interval});

  final T value;

  /// Number of units/observations behind the value (fractional for pro-rated denominators).
  final num? sampleSize;

  /// Optional confidence interval (e.g. Wilson for rates).
  final ConfidenceInterval? interval;

  @override
  bool operator ==(Object other) =>
      other is Value<T> && other.value == value && other.sampleSize == sampleSize && other.interval == interval;

  @override
  int get hashCode => Object.hash(value, sampleSize, interval);

  @override
  String toString() =>
      'Value($value${sampleSize == null ? '' : ', n=$sampleSize'}'
      '${interval == null ? '' : ', $interval'})';
}

/// Not enough data: [haveN] observations where [requiredN] are needed.
final class Insufficient<T> extends Stat<T> {
  const new(this.requiredN, this.haveN, [this.reasonKey = 'needsMoreData']);

  final num requiredN;
  final num haveN;
  final String reasonKey;

  /// How many more observations are needed (≥ 0).
  num get missing => requiredN - haveN < 0 ? 0 : requiredN - haveN;

  Insufficient<R> retype<R>() => Insufficient<R>(requiredN, haveN, reasonKey);

  @override
  bool operator ==(Object other) =>
      other is Insufficient<T> && other.requiredN == requiredN && other.haveN == haveN && other.reasonKey == reasonKey;

  @override
  int get hashCode => Object.hash(requiredN, haveN, reasonKey);

  @override
  String toString() => 'Insufficient($haveN/$requiredN, $reasonKey)';
}

/// The metric does not apply; [reasonKey] explains why (e.g. `zeroDenominator`, `new`).
final class NotApplicable<T> extends Stat<T> {
  const new(this.reasonKey);

  final String reasonKey;

  NotApplicable<R> retype<R>() => NotApplicable<R>(reasonKey);

  @override
  bool operator ==(Object other) => other is NotApplicable<T> && other.reasonKey == reasonKey;

  @override
  int get hashCode => reasonKey.hashCode;

  @override
  String toString() => 'NotApplicable($reasonKey)';
}

/// Reason keys used across the package.
abstract final class Reasons {
  static const zeroDenominator = 'zeroDenominator';
  static const empty = 'empty';
  static const nonFinite = 'nonFinite';
  static const isNew = 'new';
  static const zeroMean = 'zeroMean';
  static const nonPositive = 'nonPositive';
  static const notTracked = 'notTracked';
  static const notScheduled = 'notScheduled';
  static const noPreviousPeriod = 'noPreviousPeriod';
  static const needsMoreData = 'needsMoreData';
  static const notReached = 'notReached';
  static const noVariance = 'noVariance';
  static const allDay = 'allDay';
  static const notStarted = 'notStarted';
  static const notDone = 'notDone';
  static const noData = 'noData';
  static const hidden = 'hidden';
}

/// `numerator ÷ denominator`, or [NotApplicable]`('zeroDenominator')` when the denominator is 0.
Stat<double> safeDivide(num numerator, num denominator, {num? sampleSize}) {
  if (denominator == 0) {
    return const NotApplicable<double>(Reasons.zeroDenominator);
  }
  return Stat.ofDouble(numerator / denominator, sampleSize: sampleSize);
}

/// Units a metric value is expressed in (drives formatting in the app).
enum MetricUnit {
  count,
  duration,
  minutes,
  hours,
  days,
  percent,
  percentagePoints,
  ratio,
  currency,
  score,
  perDay,
  perWeek,
}

/// A flattened, presentation-ready metric value: value, unit, sample size, insufficient flag and
/// interval. Built from a [Stat] with [MetricValue.fromStat].
@immutable
final class const MetricValue(
  final String metricId, {
  required final MetricUnit unit,
  final double? value,
  final num? sampleSize,
  final bool insufficient = false,
  final bool notApplicable = false,
  final ConfidenceInterval? interval,
  final String? reasonKey,
  final num? requiredN,
  final num? haveN,
  final bool estimate = false,
}) {
  /// Converts a numeric [Stat]; durations become minutes.
  factory fromStat(String metricId, Stat<Object> stat, {required MetricUnit unit, bool estimate = false}) =>
      switch (stat) {
        Value<Object>(:final value, :final sampleSize, :final interval) => MetricValue(
          metricId,
          unit: unit,
          value: switch (value) {
            final num n => n.toDouble(),
            final Duration d => d.inMicroseconds / Duration.microsecondsPerMinute,
            _ => null,
          },
          sampleSize: sampleSize,
          interval: interval,
          estimate: estimate,
        ),
        Insufficient<Object>(:final requiredN, :final haveN, :final reasonKey) => MetricValue(
          metricId,
          unit: unit,
          insufficient: true,
          reasonKey: reasonKey,
          requiredN: requiredN,
          haveN: haveN,
          estimate: estimate,
        ),
        NotApplicable<Object>(:final reasonKey) => MetricValue(
          metricId,
          unit: unit,
          notApplicable: true,
          reasonKey: reasonKey,
          estimate: estimate,
        ),
      };

  bool get hasValue => value != null;
}
