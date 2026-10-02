import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/domain/agenda.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:meta/meta.dart';

/// The day progress header (T8.1.11). Counting rules follow the stats engine: tasks are the day's
/// checkbox occurrences (events never count, T3.2.13) and done = `done`; habits are the habits due
/// today and done = resolved (done, skipped or excused); focus = tracked time of today's tasks.
@immutable
class TodayProgress {
  const TodayProgress({
    this.tasksDone = 0,
    this.tasksPlanned = 0,
    this.habitsDone = 0,
    this.habitsDue = 0,
    this.itemsCompleted = 0,
    this.focusMinutes = 0,
  });

  factory TodayProgress.of(TodayOverview o, {int itemsCompleted = 0}) {
    var done = 0;
    var planned = 0;
    var focus = 0;
    for (final i in o.agenda ?? const <PlannerItem>[]) {
      focus += (i.trackedSeconds ?? 0) ~/ 60;
      if (!hasCheckbox(i) || i.status == OccurrenceStatus.cancelled) continue;
      planned++;
      if (i.status == OccurrenceStatus.done) done++;
    }
    final habits = o.habits ?? const <TodayHabitEntry>[];
    return TodayProgress(
      tasksDone: done,
      tasksPlanned: planned,
      habitsDone: habits.where((h) => h.resolved).length,
      habitsDue: habits.length,
      itemsCompleted: itemsCompleted,
      focusMinutes: focus,
    );
  }

  final int tasksDone;
  final int tasksPlanned;
  final int habitsDone;
  final int habitsDue;
  final int itemsCompleted;
  final int focusMinutes;

  /// Share of the day's tasks and habits that are done (0…1; 0 when there is nothing).
  double get ratio {
    final total = tasksPlanned + habitsDue;
    return total == 0 ? 0 : (tasksDone + habitsDone) / total;
  }

  @override
  bool operator ==(Object other) =>
      other is TodayProgress &&
      other.tasksDone == tasksDone &&
      other.tasksPlanned == tasksPlanned &&
      other.habitsDone == habitsDone &&
      other.habitsDue == habitsDue &&
      other.itemsCompleted == itemsCompleted &&
      other.focusMinutes == focusMinutes;

  @override
  int get hashCode => Object.hash(tasksDone, tasksPlanned, habitsDone, habitsDue, itemsCompleted, focusMinutes);
}
