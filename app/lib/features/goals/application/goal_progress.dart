import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show GoalProgress, GoalSpec, GoalStatus, PeriodStatus, QuitDayStatus, goalProgress;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Open-ended goals (all time without an end date) are projected over this horizon; their pace
/// and on-track status are not meaningful and are hidden by the UI.
const openGoalHorizonDays = 3650;

/// A goal with its progress as of a date (T5.4.03).
@immutable
class GoalEvaluation {
  const GoalEvaluation(this.goal, this.progress, {required this.openEnded, required this.start, required this.end});

  final Goal goal;
  final GoalProgress progress;

  /// No end date: show progress and ETA only.
  final bool openEnded;
  final LocalDate start;
  final LocalDate end;

  bool get achieved => progress.status == GoalStatus.achieved;
}

/// The kind of [habit] as goals see it (decides the allowed metrics).
GoalHabitKind goalHabitKindOf(Habit habit) => switch (habit) {
  QuitHabit() => GoalHabitKind.quit,
  final BuildHabit b => b.goal.isMeasurable ? GoalHabitKind.measurable : GoalHabitKind.yesNo,
};

/// Progress of a habit-scoped [goal] from the habit's [snapshot] — the per-day contributions of
/// its metric fed to `everslot_metrics` `goalProgress` (the single implementation shared with the
/// Insights goals section): totals of logged values, done days, the current streak (a level, not a
/// sum), and for quit trackers clean days, money saved and units avoided per day.
GoalEvaluation evaluateHabitGoal(Goal goal, HabitSnapshot snapshot, {required Weekday weekStart}) {
  final today = snapshot.today;
  final habit = snapshot.habit;
  final origin = habit.startDate;
  final window = goal.window(today, weekStart: weekStart, origin: origin);
  final start = window.start;
  final end = window.end ?? start.plusDays(openGoalHorizonDays - 1);
  bool inWindow(LocalDate d) => !d.isBefore(start) && !d.isAfter(end) && !d.isAfter(today);

  final daily = <LocalDate, double>{};
  void add(LocalDate d, double v) {
    if (inWindow(d) && v != 0) daily[d] = (daily[d] ?? 0) + v;
  }

  double? actual;
  double? rate;
  switch (goal.metric) {
    case GoalMetric.totalValue:
      for (final l in snapshot.logs) {
        if (l.kind == HabitLogKind.progress) add(l.localDate, l.value ?? 0);
      }
    case GoalMetric.completions:
      final days = snapshot.evaluation?.days ?? const {};
      for (final e in days.entries) {
        if (e.value.status == PeriodStatus.done) add(e.key, 1);
      }
    case GoalMetric.streakDays:
      final streak = snapshot.summary?.currentStreak ?? 0;
      actual = streak.toDouble();
      rate = streak > 0 ? 1 : 0;
    case GoalMetric.cleanDays:
      for (final d in snapshot.quit?.days ?? const []) {
        if (d.closed && d.status == QuitDayStatus.clean) add(d.localDate, 1);
      }
    case GoalMetric.moneySaved:
      final byDay = snapshot.quit?.moneySavedByDay;
      if (byDay != null) {
        for (final (d, amount) in byDay) {
          add(d, amount.toDouble());
        }
      }
    case GoalMetric.unitsAvoided:
      for (final d in snapshot.quit?.days ?? const []) {
        add(d.localDate, d.avoided);
      }
    case GoalMetric.trackedMinutes:
    case GoalMetric.itemsCompleted:
      break; // Not habit metrics (series, categories, checklists — [6.7]).
  }
  final progress = goalProgress(
    GoalSpec(goal.target, start: start, end: end),
    asOf: today,
    dailyValues: daily,
    actual: actual,
    recentDailyRate: rate,
  );
  return GoalEvaluation(goal, progress, openEnded: window.end == null, start: start, end: end);
}
