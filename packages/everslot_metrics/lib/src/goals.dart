/// Goal progress & projection engine (T5.4.03) — the single implementation behind HB-H-26 (habit
/// pace & projection), QT-21 (savings goal) and GL-09 (goals & projections).
///
/// For a goal G over the inclusive dates [start, end], as of date `asOf`:
/// - elapsed fraction e = elapsed days ÷ total days (asOf counts as elapsed);
/// - pace = G·e; on track when actual ≥ pace;
/// - rate₂₈ = mean daily value over the last 28 days (up to asOf);
/// - projected end = actual + rate₂₈ × remaining days;
/// - ETA = the date the projection reaches G (⌈(G − actual)/rate₂₈⌉ days after asOf), with an
///   uncertainty band from rate₂₈ ± 1.96·SD/√28 of the daily values;
/// - required rate = (G − actual) ÷ remaining days;
/// - status: achieved (actual ≥ G) · on track · at risk (behind and required rate > 1.5 × rate₂₈)
///   · behind.
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// Status of a goal.
enum GoalStatus { achieved, onTrack, behind, atRisk }

/// A numeric goal over an inclusive date range (`goals` row resolved to dates).
@immutable
final class const GoalSpec(
  final double target, {
  required final LocalDate start,
  required final LocalDate end,
}) {
  int get totalDays => start.daysUntil(end) + 1;
}

/// Progress and projection of a goal at one date.
@immutable
final class const GoalProgress(
  final GoalSpec goal, {
  required final LocalDate asOf,
  required final double actual,
  required final int elapsedDays,
  required final int remainingDays,
  required final double pace,
  required final double recentDailyRate,
  required final double projectedEnd,
  required final double? requiredDailyRate,
  required final GoalStatus status,
  required final LocalDate? eta,
  required final LocalDate? etaEarliest,
  required final LocalDate? etaLatest,
  required final LocalDate? achievedOn,
}) {
  /// actual ÷ target (may exceed 1).
  double get progress => goal.target <= 0 ? 1 : actual / goal.target;

  /// Elapsed fraction e.
  double get elapsedFraction => elapsedDays / goal.totalDays;

  /// actual − pace (> 0 = ahead).
  double get aheadBy => actual - pace;

  bool get onTrack => actual >= pace - 1e-9;

  /// Required rate per week.
  double? get requiredWeeklyRate =>
      requiredDailyRate == null ? null : requiredDailyRate! * 7;
}

/// Days after [asOf] needed to add [remaining] at [dailyRate] (null when the rate is ≤ 0).
LocalDate? _etaFor(LocalDate asOf, double remaining, double dailyRate) {
  if (remaining <= 0) return asOf;
  if (dailyRate <= 0) return null;
  return asOf.plusDays((remaining / dailyRate - 1e-9).ceil());
}

/// Computes goal progress.
///
/// [dailyValues] are the per-day contributions (e.g. push-ups per day, money saved per day). The
/// actual value is their sum over `goal.start`…[asOf] unless [actual] is given (for metrics that
/// are not sums, e.g. streak days). [recentDailyRate] overrides rate₂₈.
GoalProgress goalProgress(
  GoalSpec goal, {
  required LocalDate asOf,
  Map<LocalDate, double> dailyValues = const {},
  double? actual,
  double? recentDailyRate,
  int rateWindowDays = 28,
}) {
  final clampedAsOf = asOf.isAfter(goal.end)
      ? goal.end
      : (asOf.isBefore(goal.start) ? goal.start.minusDays(1) : asOf);
  final elapsed = math.max(0, goal.start.daysUntil(clampedAsOf) + 1);
  final remaining = math.max(0, goal.totalDays - elapsed);
  var sum = 0.0;
  LocalDate? achievedOn;
  final dates = dailyValues.keys.toList()..sort();
  for (final d in dates) {
    if (d.isBefore(goal.start) || d.isAfter(clampedAsOf)) continue;
    sum += dailyValues[d]!;
    if (achievedOn == null && sum >= goal.target - 1e-9) achievedOn = d;
  }
  final value = actual ?? sum;
  if (actual != null) {
    achievedOn = value >= goal.target - 1e-9
        ? (achievedOn ?? clampedAsOf)
        : null;
  }
  final windowStart = asOf.minusDays(rateWindowDays - 1);
  final window = [
    for (var d = windowStart; !d.isAfter(asOf); d = d.plusDays(1))
      dailyValues[d] ?? 0.0,
  ];
  final mean = window.isEmpty
      ? 0.0
      : window.reduce((a, b) => a + b) / window.length;
  final rate = recentDailyRate ?? mean;
  var sd = 0.0;
  if (window.length > 1) {
    final m = mean;
    sd = math.sqrt(
      window.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) /
          (window.length - 1),
    );
  }
  final halfBand = window.isEmpty ? 0.0 : 1.96 * sd / math.sqrt(window.length);
  final pace = goal.target * elapsed / goal.totalDays;
  final left = goal.target - value;
  final requiredRate = remaining > 0
      ? math.max<double>(0, left) / remaining
      : null;
  final GoalStatus status;
  if (value >= goal.target - 1e-9) {
    status = GoalStatus.achieved;
  } else if (value >= pace - 1e-9) {
    status = GoalStatus.onTrack;
  } else if (requiredRate == null || requiredRate > 1.5 * rate) {
    status = GoalStatus.atRisk;
  } else {
    status = GoalStatus.behind;
  }
  return GoalProgress(
    goal,
    asOf: asOf,
    actual: value,
    elapsedDays: elapsed,
    remainingDays: remaining,
    pace: pace,
    recentDailyRate: rate,
    projectedEnd: value + rate * remaining,
    requiredDailyRate: requiredRate,
    status: status,
    eta: _etaFor(asOf, left, rate),
    etaEarliest: _etaFor(asOf, left, rate + halfBand),
    etaLatest: _etaFor(asOf, left, rate - halfBand),
    achievedOn: achievedOn,
  );
}
