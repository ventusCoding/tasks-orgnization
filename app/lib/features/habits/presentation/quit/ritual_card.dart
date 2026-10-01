import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Daily pledge & evening review (T5.3.13) on the quit dashboard: the morning pledge (one row per
/// day, so pledging on two devices converges) with its streak, and — from the evening time, or at
/// any time for trackers that need explicit confirmations — "Did you stay clean today?": *Yes*
/// writes the day's `clean` state, *No* opens the kind relapse flow. Trackers without automatic
/// success also ask about an unconfirmed yesterday.
class QuitRitualCard extends ConsumerWidget {
  const QuitRitualCard({required this.snapshot, super.key});

  final HabitSnapshot snapshot;

  static final defaultEvening = LocalTime(21, 0);

  /// Whether the dashboard shows the card.
  static bool shownFor(QuitHabit habit) => habit.settings.pledge.enabled || !habit.autoSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final habit = snapshot.quitHabit!;
    final today = snapshot.today;
    final logs = snapshot.logs;
    final pledge = habit.settings.pledge;
    bool loggedOn(LocalDate day, Set<HabitLogKind> kinds) =>
        logs.any((e) => e.localDate == day && kinds.contains(e.kind));
    final pledged = loggedOn(today, const {HabitLogKind.pledge});
    final streak = pledgeStreak(logs, habit.id, today);
    final lapsedToday = loggedOn(today, const {HabitLogKind.relapse});
    // `clean` is the quit day-state row (`v5(habit|day|state)`), not a build-habit state.
    bool cleanOn(LocalDate day) => logs.any((e) => e.kind == HabitLogKind.clean && e.occurrenceKey == day.toIso());
    final cleanToday = cleanOn(today);
    final zone = ref.watch(habitPeriodServiceProvider).zoneOf(habit);
    final localNow = ref.watch(zoneResolverProvider).toLocal(ref.read(clockProvider).nowUtc(), zone);
    final evening = pledge.evening ?? defaultEvening;
    final reviewTime = !habit.autoSuccess || localNow.time.compareTo(evening) >= 0;
    final yesterday = today.minusDays(1);
    final askYesterday =
        !habit.autoSuccess &&
        !yesterday.isBefore(habit.startDate) &&
        !cleanOn(yesterday) &&
        !loggedOn(yesterday, const {HabitLogKind.relapse, HabitLogKind.use});
    final service = ref.read(quitServiceProvider);

    Future<void> markClean(LocalDate day) async {
      final record = await service.markClean(habit, day);
      if (context.mounted) showUndoSnackBar(context, ref, message: l.quitCleanSaved, record: record);
    }

    Widget question(String text, LocalDate day) => Padding(
      padding: const EdgeInsetsDirectional.only(top: Space.sm),
      child: Row(
        children: [
          Expanded(child: Text(text, style: context.text.bodyLarge)),
          TextButton(onPressed: () => markClean(day), child: Text(l.quitYes)),
          TextButton(onPressed: () => showRelapseSheet(context, ref, habit), child: Text(l.quitNo)),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.quitRitualTitle, style: context.text.titleSmall),
            if (pledge.enabled) ...[
              const SizedBox(height: Space.xs),
              if (pledged)
                Row(
                  children: [
                    Icon(Icons.handshake, color: context.appColors.success),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text(l.quitPledged, style: context.text.bodyLarge)),
                  ],
                )
              else ...[
                Text(l.quitPledgeText, style: context.text.bodyLarge),
                const SizedBox(height: Space.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final record = await service.pledge(habit);
                      if (context.mounted) showUndoSnackBar(context, ref, message: l.quitPledgeSaved, record: record);
                    },
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text(l.quitPledgeAction),
                  ),
                ),
              ],
              if (streak > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: Space.xs),
                  child: Text(l.quitPledgeStreak(streak), style: context.text.labelMedium),
                ),
            ],
            if (askYesterday) question(l.quitReviewYesterdayQuestion, yesterday),
            if (cleanToday)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.sm),
                child: Text(l.quitReviewedClean, style: context.text.bodyLarge),
              )
            else if (reviewTime && !lapsedToday)
              question(l.quitReviewQuestion, today),
          ],
        ),
      ),
    );
  }
}
