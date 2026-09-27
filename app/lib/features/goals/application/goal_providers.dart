import 'package:everslot/core/providers.dart';
import 'package:everslot/features/goals/data/goals_repository.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Every live goal (Goals screen).
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(goalsRepositoryProvider).watchAll();
});

/// Goals and rewards of one habit or quit tracker.
final habitGoalsProvider = StreamProvider.family<List<Goal>, String>((ref, habitId) {
  ref.watch(currentUserIdProvider);
  return ref.watch(goalsRepositoryProvider).watchForScope(GoalScopeType.habit, habitId);
});
