import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitLogKind, PeriodResult, PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';

const _resolved = {PeriodStatus.done, PeriodStatus.skipped, PeriodStatus.excused};
const _logged = {PeriodStatus.done, PeriodStatus.failed, PeriodStatus.skipped, PeriodStatus.excused};

/// The Today entry of a build habit, or null when it is not due today (T8.1.06).
///
/// Due-today rules (pure, unit-tested):
/// - archived habits, days without a period (`notDue`) and paused days are never due;
/// - day and slot habits are due when today has a period;
/// - quota habits ("3× per week") are due while the current period's quota is not met, and stay
///   listed on a day something was logged for them (so the check-in can be undone);
/// - the one-tap check-in targets today's day key, or the current slot (none before the first
///   slot opens).
TodayHabitEntry? todayHabitEntry({
  required BuildHabit habit,
  required HabitEvaluation evaluation,
  required LocalDate today,
  required DateTime now,
  int currentStreak = 0,
  HabitLogKind? Function(String key)? stateOf,
}) {
  if (habit.isArchived) return null;
  final day = evaluation.dayOn(today);
  final quota = evaluation.quotaOn(today);
  if (day?.status == PeriodStatus.paused) return null;

  if (quota != null) {
    final loggedToday = day != null && _logged.contains(day.status);
    final open = quota.status == PeriodStatus.pending || quota.status == PeriodStatus.partial;
    if (!open && !loggedToday) return null;
    final key = today.toIso();
    return TodayHabitEntry(
      habit: habit,
      day: day,
      quota: quota,
      checkInKey: key,
      explicitState: stateOf?.call(key),
      progress: _ratio(quota.achieved, quota.target),
      resolved: quota.status == PeriodStatus.done || (day != null && _resolved.contains(day.status)),
      currentStreak: currentStreak,
    );
  }

  if (day == null || day.status == PeriodStatus.notDue) return null;
  final slots = evaluation.slotsOn(today);
  if (slots.isNotEmpty) {
    PeriodResult? current;
    PeriodResult? next;
    for (final s in slots) {
      if (!s.windowStart.isAfter(now)) {
        current = s;
      } else {
        next ??= s;
      }
    }
    final doneSlots = slots.where((s) => s.status == PeriodStatus.done).length;
    final key = current?.key;
    return TodayHabitEntry(
      habit: habit,
      day: day,
      slots: slots,
      currentSlot: current,
      nextSlot: next,
      checkInKey: key,
      explicitState: key == null ? null : stateOf?.call(key),
      progress: _ratio(doneSlots.toDouble(), slots.length.toDouble()),
      resolved: _resolved.contains(day.status) || slots.every((s) => _resolved.contains(s.status)),
      currentStreak: currentStreak,
    );
  }

  final key = day.key;
  final measurable = habit.goal.isMeasurable;
  return TodayHabitEntry(
    habit: habit,
    day: day,
    checkInKey: key,
    explicitState: stateOf?.call(key),
    progress: measurable ? _ratio(day.achieved, day.target) : (day.status == PeriodStatus.done ? 1 : 0),
    resolved: habit.goal.isLimit ? day.status != PeriodStatus.failed : _resolved.contains(day.status),
    currentStreak: currentStreak,
  );
}

double _ratio(double achieved, double target) {
  if (target <= 0) return achieved > 0 ? 1 : 0;
  return (achieved / target).clamp(0, 1).toDouble();
}

/// "All habits done" (T8.1.06): something was due and everything is resolved.
bool allHabitsDone(List<TodayHabitEntry> entries) => entries.isNotEmpty && entries.every((e) => e.resolved);
