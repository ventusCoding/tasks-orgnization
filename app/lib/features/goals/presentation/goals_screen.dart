import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/goal_progress.dart';
import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/application/goal_service.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/goals/presentation/goal_card.dart';
import 'package:everslot/features/goals/presentation/goal_editor.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show GoalStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Every goal of the user's habits and quit trackers (T5.4.04): active, achieved and ended
/// (a custom period that closed short of its target). Tap to edit; *New goal* picks a habit first.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Future<void> _new(BuildContext context, List<Habit> habits) async {
    if (habits.isEmpty) return;
    final habit = habits.length == 1
        ? habits.single
        : await showAppSheet<Habit>(
            context,
            title: context.l10n.goalsHabit,
            builder: (ctx) => ListView(
              shrinkWrap: true,
              children: [
                for (final h in habits) ListTile(title: Text(h.name), onTap: () => Navigator.pop(ctx, h)),
              ],
            ),
          );
    if (habit != null && context.mounted) await showGoalEditor(context, habitId: habit.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    final byId = {for (final h in habits) h.id: h};
    final active = <(GoalEvaluation, Habit)>[];
    final achieved = <(GoalEvaluation, Habit)>[];
    final ended = <(GoalEvaluation, Habit)>[];
    final seen = <String>{};
    for (final g in goals) {
      final habit = byId[g.scopeId];
      if (g.scopeType != GoalScopeType.habit || habit == null || !seen.add(habit.id)) continue;
      final today = ref.watch(habitSnapshotProvider(habit.id)).value?.today;
      for (final e in ref.watch(habitGoalEvaluationsProvider(habit.id))) {
        final entry = (e, habit);
        if (e.goal.isAchieved || e.progress.status == GoalStatus.achieved) {
          achieved.add(entry);
        } else if (!e.openEnded && today != null && e.goal.period == GoalPeriod.custom && today.isAfter(e.end)) {
          ended.add(entry);
        } else {
          active.add(entry);
        }
      }
    }
    Widget group(String title, List<(GoalEvaluation, Habit)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title),
        for (final (e, h) in items)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
            child: GoalCard(
              evaluation: e,
              habit: h,
              showHabit: true,
              onTap: () => showGoalEditor(context, habitId: h.id, existing: e.goal),
            ),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.goalsTitle)),
      floatingActionButton: habits.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _new(context, habits),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l.goalsNew),
            ),
      body: active.isEmpty && achieved.isEmpty && ended.isEmpty
          ? EmptyState(icon: Icons.flag_outlined, title: l.goalsEmpty, message: l.goalsEmptyBody)
          : ListView(
              padding: const EdgeInsetsDirectional.only(bottom: 96),
              children: [
                if (active.isNotEmpty) group(l.goalsActive, active),
                if (achieved.isNotEmpty) group(l.goalsAchieved, achieved),
                if (ended.isNotEmpty) group(l.goalsEnded, ended),
              ],
            ),
    );
  }
}
