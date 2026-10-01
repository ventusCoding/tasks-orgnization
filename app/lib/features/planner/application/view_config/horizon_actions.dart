import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/goals/application/goal_service.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/horizons.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unscheduled tasks that carry a horizon (T3.7.11), oldest first.
final horizonTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>(
  (ref) => ref
      .watch(backlogTasksProvider)
      .whenData(
        (tasks) => [
          for (final t in tasks)
            if (t.horizonKey != null) t,
        ],
      ),
);

/// Commands of the horizons view (T3.7.11); each is one undoable operation.
class HorizonActions {
  HorizonActions(this._ref);

  final Ref _ref;

  PlannerService get _service => _ref.read(plannerServiceProvider);

  /// A new intention in the period [key].
  Future<String> create(String title, String key) async => (await _service.createTask(
    Task(id: '', seriesId: '', title: title, horizonKey: key),
    source: 'horizons',
  )).taskId;

  /// Moves an intention to another horizon / period.
  Future<void> move(Task task, String key) async {
    if (task.horizonKey == key) return;
    await _service.updateTask(task.copyWith(horizonKey: key), source: 'horizons');
  }

  /// Puts an intention on the calendar (it leaves the horizons) in one operation.
  Future<void> schedule(Task task, LocalDateTime start, int minutes) async {
    await _service.updateTask(
      task.copyWith(horizonKey: null, startLocal: start, durationMinutes: minutes, isAllDay: false),
      source: 'horizons',
    );
  }

  /// "Make it a goal" ([5.4]): complete the series once within the horizon's period.
  Future<void> linkGoal(Task task, LocalDate today, Weekday weekStart) async {
    final horizon = Horizon.of(task.horizonKey) ?? Horizon.week;
    final period = switch (horizon) {
      Horizon.day => GoalPeriod.custom,
      Horizon.week => GoalPeriod.week,
      Horizon.month => GoalPeriod.month,
      Horizon.quarter => GoalPeriod.quarter,
      Horizon.year => GoalPeriod.year,
    };
    final day = task.horizonKey == null ? today : (LocalDate.tryParse(task.horizonKey!.substring(4)) ?? today);
    await _ref
        .read(goalServiceProvider)
        .save(
          Goal(
            id: Ids.v7(),
            scopeType: GoalScopeType.series,
            scopeId: task.seriesId,
            metric: GoalMetric.completions,
            target: 1,
            period: period,
            startDate: period == GoalPeriod.custom ? day : null,
            endDate: period == GoalPeriod.custom ? day : null,
            title: task.title,
          ),
        );
  }
}

final horizonActionsProvider = Provider<HorizonActions>(HorizonActions.new);
