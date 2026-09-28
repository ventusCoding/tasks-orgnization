import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/record_moments.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Text of a record moment.
String recordText(BuildContext context, RecordMoment m, Habit habit) {
  final l = context.l10n;
  final unit = habit is BuildHabit ? habit.goal.unit : null;
  return switch (m.kind) {
    RecordKind.bestDay => l.habitsRecordBestDay(formatAmount(context, m.value, unit)),
    RecordKind.bestWeek => l.habitsRecordBestWeek(formatAmount(context, m.value, unit)),
    RecordKind.longestStreak => l.habitsRecordStreak(l.habitsDays(m.value.toInt())),
    RecordKind.longestAbstinence => l.habitsRecordAbstinence(AppFormat(context.localeName, l10n: l).duration(m.value.toInt())),
    RecordKind.mostCravingsResisted => l.habitsRecordCravings(m.value.toInt()),
  };
}

/// Record moments of one habit (T5.4.10): "New record!" with what was beaten — on the habit detail
/// and the quit dashboard.
class RecordBanner extends ConsumerWidget {
  const RecordBanner({required this.habitId, super.key});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(habitSnapshotProvider(habitId)).value;
    if (snapshot == null) return const SizedBox.shrink();
    final moments = recordMoments(snapshot, weekStart: ref.watch(userPreferencesProvider).weekStart);
    if (moments.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Card(
        color: context.colors.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.emoji_events, color: context.colors.onTertiaryContainer),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.habitsRecordNew, style: context.text.titleSmall?.copyWith(color: context.colors.onTertiaryContainer)),
                    for (final m in moments)
                      Text(
                        recordText(context, m, snapshot.habit),
                        style: context.text.bodyMedium?.copyWith(color: context.colors.onTertiaryContainer),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
