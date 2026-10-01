import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/goals/application/goal_progress.dart';
import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/data/goals_repository.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show GoalStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Goal commands (T5.4.02, T5.4.04, T5.3.15): every command validates with the same rules as the
/// server and is one undoable operation.
class GoalService {
  GoalService(this._goals);

  final GoalsRepository _goals;

  Future<OpRecord> save(Goal goal, {GoalHabitKind? habitKind, bool isNew = true}) {
    goal.validate(habitKind: habitKind);
    return isNew ? _goals.create(goal) : _goals.update(goal);
  }

  Future<OpRecord> delete(String id) => _goals.delete(id);

  /// A reward is claimed by hand (the money stays counted as saved).
  Future<OpRecord?> claim(Goal goal, DateTime at) => _goals.markAchieved(goal.id, at, automatic: false);

  Future<OpRecord> unclaim(Goal goal) => _goals.clearAchieved(goal.id);

  /// Records `achieved_at` once for goals whose progress reached the target (rewards are claimed
  /// by hand instead). The instant is the start of the day it was reached in the habit's zone, so
  /// two devices detecting it offline write the same value. Returns the newly achieved goals.
  Future<List<Goal>> syncAchievements(
    List<GoalEvaluation> evaluations,
    DateTime Function(GoalEvaluation) reachedAt,
  ) async {
    final achieved = <Goal>[];
    for (final e in evaluations) {
      if (e.goal.isAchieved || e.goal.isReward || e.progress.status != GoalStatus.achieved) continue;
      if (await _goals.markAchieved(e.goal.id, reachedAt(e)) != null) achieved.add(e.goal);
    }
    return achieved;
  }
}

final goalServiceProvider = Provider<GoalService>((ref) => GoalService(ref.watch(goalsRepositoryProvider)));

/// Goals of one habit with their progress (T5.4.04), recomputed with the habit's snapshot.
final habitGoalEvaluationsProvider = Provider.family<List<GoalEvaluation>, String>((ref, habitId) {
  final goals = ref.watch(habitGoalsProvider(habitId)).value ?? const <Goal>[];
  final snapshot = ref.watch(habitSnapshotProvider(habitId)).value;
  if (snapshot == null || goals.isEmpty) return const [];
  final weekStart = ref.watch(userPreferencesProvider).weekStart;
  return [for (final g in goals) evaluateHabitGoal(g, snapshot, weekStart: weekStart)];
});
