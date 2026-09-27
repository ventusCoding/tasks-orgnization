import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/goal_service.dart';
import 'package:everslot/features/goals/presentation/goal_editor.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show GoalStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "What my savings buy" (T5.3.15): rewards of a quit tracker are money-saved goals with a name
/// and a price, each with a progress ring and the date the savings should cover it at the current
/// rate. *Claim* marks the reward achieved; the money stays counted as saved.
class QuitRewardsSection extends ConsumerWidget {
  const QuitRewardsSection({required this.habitId, super.key});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(habitId)).value;
    final habit = snapshot?.quitHabit;
    if (snapshot == null || habit == null) return const SizedBox.shrink();
    final rewards = [
      for (final e in ref.watch(habitGoalEvaluationsProvider(habitId)))
        if (e.goal.isReward) e,
    ];
    final currency = habit.currency ?? ref.watch(userPreferencesProvider).currency;
    final fmt = AppFormat(context.localeName, l10n: l);
    final zone = ref.watch(habitPeriodServiceProvider).zoneOf(habit);
    final resolver = ref.watch(zoneResolverProvider);
    final hasCost = habit.unitCost != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l.quitRewardsTitle,
          padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
          trailing: hasCost
              ? IconButton(
                  tooltip: l.quitRewardAdd,
                  icon: const Icon(Icons.add),
                  onPressed: () => showGoalEditor(context, habitId: habitId, reward: true),
                )
              : null,
        ),
        if (!hasCost)
          Text(l.quitRewardNeedsCost, style: context.text.bodySmall)
        else if (rewards.isEmpty)
          Text(l.quitRewardsEmpty, style: context.text.bodySmall),
        for (final e in rewards)
          Card(
            child: ListTile(
              onTap: () => showGoalEditor(context, habitId: habitId, existing: e.goal),
              leading: ProgressRing(
                progress: e.goal.isAchieved ? 1 : e.progress.progress.clamp(0.0, 1.0),
                size: 44,
                stroke: 4,
                child: Icon(e.goal.isAchieved ? Icons.check : Icons.card_giftcard, size: 18),
              ),
              title: Text(e.goal.reward ?? ''),
              subtitle: Text(
                [
                  fmt.currency(e.goal.target, currency),
                  if (e.goal.isAchieved)
                    l.quitRewardClaimed(fmt.dateMedium(resolver.toLocal(e.goal.achievedAt!, zone).date))
                  else if (e.progress.status == GoalStatus.achieved)
                    l.quitRewardReady
                  else if (e.progress.eta != null)
                    l.quitRewardEta(fmt.dateMedium(e.progress.eta!)),
                ].join(' · '),
              ),
              trailing: !e.goal.isAchieved && e.progress.status == GoalStatus.achieved
                  ? FilledButton.tonal(
                      onPressed: () async {
                        final record = await ref.read(goalServiceProvider).claim(e.goal, ref.read(clockProvider).nowUtc());
                        if (record != null && context.mounted) {
                          showUndoSnackBar(context, ref, message: l.quitRewardClaimedSnack, record: record);
                        }
                      },
                      child: Text(l.quitRewardClaim),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
