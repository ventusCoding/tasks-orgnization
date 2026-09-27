import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Where a time-boxed challenge stands (T5.4.05): "Day 12 of 30", days left, done vs due days and
/// — once the end date has passed — whether the success rule was met.
@immutable
class ChallengeOutcome {
  const ChallengeOutcome({
    required this.dayNumber,
    required this.totalDays,
    required this.doneDays,
    required this.dueDays,
    required this.finished,
    required this.success,
    required this.bestStreak,
    required this.volume,
    required this.settings,
  });

  /// 1-based day of the challenge (clamped to its length).
  final int dayNumber;
  final int totalDays;

  /// Due days done so far (excused, paused and not-due days are not due).
  final int doneDays;
  final int dueDays;

  /// The end date has passed: the challenge is closed.
  final bool finished;

  /// The success rule is met (so far, while running).
  final bool success;
  final int bestStreak;

  /// Σ achieved over the challenge (measurable habits).
  final double volume;
  final ChallengeSettings settings;

  int get daysLeft => finished ? 0 : totalDays - dayNumber;
  double get ratio => dueDays == 0 ? 0 : doneDays / dueDays;
}

/// Evaluates [habit]'s challenge from its [evaluation] as of [today] (null when it isn't one).
ChallengeOutcome? challengeOutcome(BuildHabit habit, HabitEvaluation evaluation, {required LocalDate today, int bestStreak = 0}) {
  final settings = habit.settings.challenge;
  final end = habit.endDate;
  if (settings == null || end == null) return null;
  final start = habit.startDate;
  final total = start.daysUntil(end) + 1;
  final finished = today.isAfter(end);
  final last = finished ? end : today;
  var due = 0;
  var done = 0;
  var volume = 0.0;
  for (var d = start; !d.isAfter(last); d = d.plusDays(1)) {
    final r = evaluation.dayOn(d);
    if (r == null) continue;
    volume += r.achieved;
    final status = r.status;
    if (status == PeriodStatus.notDue || status == PeriodStatus.paused || status == PeriodStatus.excused) continue;
    // Today still open does not count against the challenge yet.
    if (status == PeriodStatus.pending) continue;
    due++;
    if (status == PeriodStatus.done) done++;
  }
  final success = switch (settings.rule) {
    ChallengeRule.everyDay => done == due,
    ChallengeRule.minRatio => due == 0 || done / due >= settings.minRatio - 1e-9,
  };
  return ChallengeOutcome(
    dayNumber: (start.daysUntil(last) + 1).clamp(1, total),
    totalDays: total,
    doneDays: done,
    dueDays: due,
    finished: finished,
    success: success,
    bestStreak: bestStreak,
    volume: volume,
    settings: settings,
  );
}
