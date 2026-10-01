/// Habit-strength score, Loop-compatible EWMA (T6.1.10, HB-H-01, PL-S-14).
///
/// Clean-room implementation of the documented Loop Habit Tracker formula:
/// - m = 0.5^(√f/13), score_t = score_{t−1}·m + c_t·(1 − m); half-life 13/√f days;
/// - f = repetitions ÷ interval length (daily 1; 3 per 8 days 0.375; weekly MO,TU 2/7; 3×/week
///   quota 3/7; 9 slots a day 9);
/// - iterated day by day from the first scheduled day to today.
///
/// c_t variants:
/// - boolean: c_t = min(1, YES units in the last `den` days ÷ `num`); for non-daily habits (f < 1)
///   num and den are doubled to smooth irregular schedules (Loop behaviour);
/// - several units per day (f > 1): c_t = done_in_day ÷ expected_in_day;
/// - numeric at least: c_t = min(1, rolling sum over the `den`-day window ÷ target);
/// - numeric at most: c_t = clamp(1 − (sum − target)/target, 0, 1), initial score 1.0;
/// - skipped, excused or paused days are not scored: score_t = score_{t−1}.
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// How c_t is computed.
enum StrengthGoalKind { boolean, atLeast, atMost }

/// Frequency num/den of the rule in force (f = num/den).
@immutable
final class const StrengthFrequency(final int numerator, final int denominator) {
  const new daily() : this(1, 1);

  double get f => numerator / denominator;

  @override
  bool operator ==(Object other) =>
      other is StrengthFrequency && other.numerator == numerator && other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);
}

/// One day of input.
///
/// [value]: boolean → number of YES units that day (0/1, or done slots when f > 1); numeric → the
/// day's total. [expectedInDay] is the number of units due that day when f > 1. [target] is the
/// numeric target per frequency window.
@immutable
final class const StrengthDay(
  final LocalDate date, {
  required final double value,
  required final StrengthFrequency frequency,
  final bool skipped = false,
  final double? target,
  final double expectedInDay = 1,
});

/// One point of the strength series.
@immutable
final class const StrengthPoint(
  final LocalDate date,
  final double score, {
  final bool scored = true,
  final double? credit,
});

/// Multiplier m = 0.5^(√f/13).
double strengthMultiplier(double f) => math.pow(0.5, math.sqrt(f) / 13).toDouble();

/// One update: score·m + c·(1 − m).
double strengthStep(double previous, double credit, double f) {
  final m = strengthMultiplier(f);
  return previous * m + credit * (1 - m);
}

/// Full daily strength series.
@immutable
final class const StrengthResult(final List<StrengthPoint> series, {required final double initialScore}) {
  /// Score of the last day (the initial score when empty).
  double get current => series.isEmpty ? initialScore : series.last.score;

  /// Score at the end of [date]; the initial score before the series, the last score after it.
  double scoreAt(LocalDate date) {
    if (series.isEmpty || date.isBefore(series.first.date)) return initialScore;
    if (!date.isBefore(series.last.date)) return series.last.score;
    final index = series.first.date.daysUntil(date);
    return series[index].score;
  }

  /// current − score N days before the last day (30 and 365 in the UI).
  Stat<double> deltaVsDaysAgo(int days) {
    if (series.isEmpty) return const NotApplicable<double>(Reasons.noData);
    return Value<double>(current - scoreAt(series.last.date.minusDays(days)));
  }
}

/// Computes the strength series. [days] may be in any order; missing dates between the first and
/// last date are treated as scored days with value 0 (using the previous day's frequency).
StrengthResult computeStrength(
  List<StrengthDay> days, {
  StrengthGoalKind kind = StrengthGoalKind.boolean,
  double? initialScore,
}) {
  final start = initialScore ?? (kind == StrengthGoalKind.atMost ? 1.0 : 0.0);
  if (days.isEmpty) return StrengthResult(const [], initialScore: start);
  final byDate = {for (final d in days) d.date: d};
  final sortedDates = byDate.keys.toList()..sort();
  final first = sortedDates.first;
  final last = sortedDates.last;
  final filled = <StrengthDay>[];
  StrengthDay? previous;
  for (var d = first; !d.isAfter(last); d = d.plusDays(1)) {
    final day =
        byDate[d] ??
        StrengthDay(
          d,
          value: 0,
          frequency: previous!.frequency,
          target: previous.target,
          expectedInDay: previous.expectedInDay,
        );
    filled.add(day);
    previous = day;
  }
  var score = start;
  final series = <StrengthPoint>[];
  for (var i = 0; i < filled.length; i++) {
    final day = filled[i];
    final f = day.frequency.f;
    if (day.skipped) {
      series.add(StrengthPoint(day.date, score, scored: false));
      continue;
    }
    final double credit;
    if (kind == StrengthGoalKind.boolean) {
      if (f > 1) {
        credit = day.expectedInDay <= 0 ? 0 : math.min(1, day.value / day.expectedInDay).toDouble();
      } else {
        var num = day.frequency.numerator;
        var den = day.frequency.denominator;
        if (f < 1) {
          num *= 2;
          den *= 2;
        }
        credit = math.min(1, _windowSum(filled, i, den, boolean: true) / num).toDouble();
      }
    } else {
      final sum = _windowSum(filled, i, day.frequency.denominator, boolean: false);
      final target = day.target ?? 0;
      if (kind == StrengthGoalKind.atLeast) {
        credit = target > 0 ? math.min(1, sum / target).toDouble() : 1;
      } else {
        credit = target > 0 ? (1 - (sum - target) / target).clamp(0.0, 1.0) : (sum > 0 ? 0 : 1);
      }
    }
    score = strengthStep(score, credit, f);
    series.add(StrengthPoint(day.date, score, credit: credit));
  }
  return StrengthResult(series, initialScore: start);
}

double _windowSum(List<StrengthDay> days, int index, int window, {required bool boolean}) {
  var total = 0.0;
  for (var j = math.max(0, index - window + 1); j <= index; j++) {
    // Skipped days are not YES entries (Loop SKIP) and add nothing to the window.
    if (days[j].skipped) continue;
    final v = days[j].value;
    total += boolean ? (v > 0 ? 1 : 0) : math.max(0, v);
  }
  return total;
}

/// Projection of the score if the current completion rate is maintained for [days] days
/// (optional "maintenance" projection): c = [completionRate] each day.
List<double> projectStrength(double currentScore, double f, double completionRate, {int days = 30}) {
  var s = currentScore;
  return [for (var i = 0; i < days; i++) s = strengthStep(s, completionRate, f)];
}
