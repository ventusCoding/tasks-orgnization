import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/goal_progress.dart';
import 'package:everslot/features/goals/application/goal_service.dart';
import 'package:everslot/features/goals/presentation/goal_editor.dart';
import 'package:everslot/features/goals/presentation/goal_ui.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show GoalStatus;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One goal (T5.4.04): title, a progress bar with a pace marker (where you should be today), the
/// value against the target, the status (text + color) and the ETA, or the day it was achieved.
class GoalCard extends ConsumerWidget {
  const GoalCard({required this.evaluation, required this.habit, super.key, this.onTap, this.showHabit = false});

  final GoalEvaluation evaluation;
  final Habit habit;
  final VoidCallback? onTap;

  /// Show the habit's name (Goals screen).
  final bool showHabit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final e = evaluation;
    final p = e.progress;
    final goal = e.goal;
    final fmt = AppFormat(context.localeName, l10n: l);
    final achieved = goal.isAchieved || p.status == GoalStatus.achieved;
    final status = achieved ? GoalStatus.achieved : p.status;
    final color = goalStatusColor(context, status);
    final paceFraction = e.openEnded ? null : (p.pace / goal.target).clamp(0.0, 1.0);
    final value = l.goalsProgressOf(
      goalValueText(context, ref, goal.metric, p.actual, habit),
      goalValueText(context, ref, goal.metric, goal.target, habit),
    );
    final detail = <String>[
      if (goal.achievedAt != null)
        l.goalsAchievedOn(
          fmt.dateMedium(
            ref
                .watch(zoneResolverProvider)
                .toLocal(goal.achievedAt!, ref.watch(habitPeriodServiceProvider).zoneOf(habit))
                .date,
          ),
        )
      else if (p.achievedOn != null && achieved)
        l.goalsAchievedOn(fmt.dateMedium(p.achievedOn!))
      else ...[
        if (p.eta != null) l.goalsEta(fmt.dateMedium(p.eta!)),
        if (!e.openEnded && status != GoalStatus.onTrack && p.requiredDailyRate != null)
          l.goalsNeedPerDay(goalValueText(context, ref, goal.metric, p.requiredDailyRate!, habit)),
      ],
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHabit) Text(habit.name, style: context.text.labelMedium),
                        Text(goalDisplayTitle(context, ref, goal, habit), style: context.text.titleSmall),
                        Text(l.goalPeriodLabel(goal.period), style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  if (!e.openEnded || achieved) StatusPill(label: l.goalStatusLabel(status), color: color, dense: true),
                ],
              ),
              const SizedBox(height: Space.sm),
              Semantics(
                label: '$value, ${l.goalStatusLabel(status)}',
                excludeSemantics: true,
                child: SizedBox(
                  height: 14,
                  child: LayoutBuilder(
                    builder: (context, c) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          top: 3,
                          bottom: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.sm),
                            child: LinearProgressIndicator(value: p.progress.clamp(0.0, 1.0), color: color),
                          ),
                        ),
                        if (paceFraction != null && !achieved)
                          PositionedDirectional(
                            start: (c.maxWidth - 2) * paceFraction,
                            top: 0,
                            bottom: 0,
                            child: Tooltip(
                              message: l.goalsPaceMarker,
                              child: Container(width: 2, color: context.colors.onSurface),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(value, style: context.text.bodyMedium),
              if (detail.isNotEmpty) Text(detail.join(' · '), style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Goals of a habit on its detail screen or quit dashboard (T5.4.04), with *Add a goal*. When a
/// goal's progress reaches the target, `achieved_at` is recorded once and a short confirmation
/// appears (rewards are claimed by hand instead, T5.3.15).
class HabitGoalsSection extends ConsumerStatefulWidget {
  const HabitGoalsSection({required this.habitId, super.key});

  final String habitId;

  @override
  ConsumerState<HabitGoalsSection> createState() => _HabitGoalsSectionState();
}

class _HabitGoalsSectionState extends ConsumerState<HabitGoalsSection> {
  Future<void> _sync(List<GoalEvaluation> evaluations) async {
    final snapshot = ref.read(habitSnapshotProvider(widget.habitId)).value;
    if (snapshot == null) return;
    final reached = await ref
        .read(goalServiceProvider)
        .syncAchievements(evaluations, (e) => snapshot.boundaries.startOf(e.progress.achievedOn ?? snapshot.today));
    if (!mounted || reached.isEmpty) return;
    unawaited(HapticFeedback.heavyImpact());
    final l = context.l10n;
    for (final g in reached) {
      showInfoSnackBar(context, l.goalsCelebrate(goalDisplayTitle(context, ref, g, snapshot.habit)));
    }
    // TODO(integration): call the [7.5] goal-achieved notification hook once the notifications
    // feature exposes one (no event API on main yet).
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_sync(ref.read(habitGoalEvaluationsProvider(widget.habitId))));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    ref.listen(habitGoalEvaluationsProvider(widget.habitId), (_, next) => unawaited(_sync(next)));
    final habit = ref.watch(habitSnapshotProvider(widget.habitId)).value?.habit;
    final evaluations = [
      for (final e in ref.watch(habitGoalEvaluationsProvider(widget.habitId)))
        if (!e.goal.isReward) e,
    ];
    if (habit == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l.goalsTitle,
          trailing: IconButton(
            tooltip: l.goalsAdd,
            icon: const Icon(Icons.add),
            onPressed: () => showGoalEditor(context, habitId: widget.habitId),
          ),
        ),
        for (final e in evaluations)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
            child: GoalCard(
              evaluation: e,
              habit: habit,
              onTap: () => showGoalEditor(context, habitId: widget.habitId, existing: e.goal),
            ),
          ),
      ],
    );
  }
}
