import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/challenge.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The challenge outcome of a snapshot (null when the habit is not a challenge).
ChallengeOutcome? challengeOf(HabitSnapshot snapshot) {
  final habit = snapshot.build;
  final evaluation = snapshot.evaluation;
  if (habit == null || evaluation == null) return null;
  return challengeOutcome(habit, evaluation, today: snapshot.today, bestStreak: snapshot.summary?.bestStreak ?? 0);
}

/// "Day 12 of 30 · 18 days left", the success rule and done vs due days (T5.4.05).
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({required this.outcome, super.key});

  final ChallengeOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = outcome;
    final rule = o.settings.rule == ChallengeRule.everyDay
        ? l.habitsChallengeEveryDay
        : l.habitsChallengeMinRatio(AppFormat(context.localeName).percent(o.settings.minRatio));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: context.colors.primary),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(l.habitsChallengeTitle, style: context.text.titleSmall)),
                Text(
                  o.finished ? l.habitsChallengeMissedTitle : l.habitsChallengeDaysLeft(o.daysLeft),
                  style: context.text.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(l.habitsChallengeDay(o.dayNumber, o.totalDays), style: context.text.titleMedium),
            const SizedBox(height: Space.xs),
            LinearProgressIndicator(value: o.dayNumber / o.totalDays, semanticsLabel: l.habitsChallengeDay(o.dayNumber, o.totalDays)),
            const SizedBox(height: Space.xs),
            Text('${l.habitsChallengeProgress(o.doneDays, o.dueDays)} · ${l.habitsChallengeRuleTitle}: $rule', style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Shows the result of every finished challenge once per device (T5.4.05): summary, *Keep going*
/// (the habit continues without an end date, history kept) and *Close*.
Future<void> showFinishedChallenges(BuildContext context, WidgetRef ref) async {
  final habits = ref.read(habitsProvider).value ?? const <Habit>[];
  final store = ref.read(habitUiStoreProvider);
  for (final h in habits) {
    if (h is! BuildHabit || !h.isChallenge) continue;
    if (!h.endDate!.isBefore(ref.read(habitTodayProvider))) continue;
    final key = 'challenge_result.${h.id}';
    if (await store.read(key) != null) continue;
    final snapshot = await loadHabitSnapshot(ref.read, h, ref.read(clockProvider).nowUtc());
    final outcome = challengeOf(snapshot);
    if (outcome == null || !outcome.finished) continue;
    await store.write(key, 'shown');
    if (!context.mounted) return;
    await showAppSheet<void>(
      context,
      title: outcome.success ? context.l10n.habitsChallengeSuccessTitle : context.l10n.habitsChallengeMissedTitle,
      builder: (ctx) => _ChallengeResult(habit: h, outcome: outcome, host: context),
    );
    if (!context.mounted) return;
  }
}

class _ChallengeResult extends ConsumerWidget {
  const _ChallengeResult({required this.habit, required this.outcome, required this.host});

  final BuildHabit habit;
  final ChallengeOutcome outcome;
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final o = outcome;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(habit.name, style: context.text.titleMedium),
          if (!o.success) Text(l.habitsChallengeMissedBody, style: context.text.bodyMedium),
          const SizedBox(height: Space.sm),
          Text(l.habitsChallengeProgress(o.doneDays, o.dueDays)),
          Text(l.habitsChallengeBestStreak(l.habitsDays(o.bestStreak))),
          if (habit.goal.isMeasurable) Text(l.habitsChallengeVolume(formatAmount(context, o.volume, habit.goal.unit))),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () async {
              final record = await ref.read(habitServiceProvider).keepGoing(habit);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (host.mounted) showUndoSnackBar(host, ref, message: l.habitsChallengeContinued, record: record);
            },
            child: Text(l.habitsChallengeKeepGoing),
          ),
          Text(l.habitsChallengeKeepGoingHint, style: context.text.bodySmall, textAlign: TextAlign.center),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.habitsChallengeClose)),
        ],
      ),
    );
  }
}

/// Runs [showFinishedChallenges] after the first frame of a screen (once per screen visit).
void scheduleFinishedChallenges(BuildContext context, WidgetRef ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) unawaited(showFinishedChallenges(context, ref));
  });
}
