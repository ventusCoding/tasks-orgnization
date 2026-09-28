import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/achievement_service.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:everslot/features/goals/presentation/badge_share_card.dart';
import 'package:everslot/features/goals/presentation/badge_ui.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Best current values toward every badge (progress hints), recomputed when the screen opens.
final badgeValuesProvider = FutureProvider.autoDispose<Map<AchievementCode, num>>((ref) async {
  final f = await ref.read(achievementServiceProvider).facts(scanPerfectDays: false, scanBackfills: false);
  return badgeValues(global: f.global, habits: f.habits, quits: f.quits);
});

/// Earned and locked badges (T5.4.09): earned ones with the habit and the date, locked ones with
/// a progress hint; tap an earned badge to share it as an image card.
class BadgeGalleryScreen extends ConsumerWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unlocked = ref.watch(unlockedBadgesProvider).value ?? const <UnlockedBadge>[];
    final values = ref.watch(badgeValuesProvider).value ?? const <AchievementCode, num>{};
    final habits = {for (final h in ref.watch(allHabitsProvider).value ?? const <Habit>[]) h.id: h};
    final earnedCodes = {for (final b in unlocked) b.code};
    final locked = [for (final c in AchievementCode.values) if (!earnedCodes.contains(c)) c];
    final fmt = AppFormat(context.localeName, l10n: l);
    String? currencyOf(String? habitId) {
      final h = habits[habitId];
      return h is QuitHabit ? h.currency : null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.goalsBadgesTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
        children: [
          SectionHeader(l.goalsBadgesEarned),
          if (unlocked.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              child: Text(l.goalsBadgesEmpty, style: context.text.bodyMedium),
            ),
          for (final b in unlocked)
            ListTile(
              leading: CircleAvatar(child: Icon(badgeIcon(b.code))),
              title: Text(badgeName(context, b.code, currency: currencyOf(b.habitId))),
              subtitle: Text(
                [
                  if (habits[b.habitId] case final h?) h.name,
                  l.goalsBadgeEarnedOn(fmt.dateMedium(ref.watch(zoneResolverProvider).toLocal(b.unlockedAt, ref.watch(deviceZoneProvider)).date)),
                ].join(' · '),
              ),
              trailing: IconButton(
                tooltip: l.goalsBadgeShare,
                icon: const Icon(Icons.ios_share),
                onPressed: () => showBadgeShareSheet(context, ref, b, habitName: habits[b.habitId]?.name, currency: currencyOf(b.habitId)),
              ),
            ),
          SectionHeader(l.goalsBadgesLocked),
          for (final c in locked)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colors.surfaceContainerHighest,
                child: Icon(badgeIcon(c), color: context.colors.outline),
              ),
              title: Text(badgeName(context, c)),
              subtitle: c.threshold > 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Space.xs),
                        LinearProgressIndicator(value: badgeProgress(c, values[c] ?? 0)),
                        Text(l.goalsBadgeProgress(fmt.number((values[c] ?? 0).floor()), fmt.number(c.threshold))),
                      ],
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Share a badge as an image card with only what the user chooses (habit name, date).
Future<void> showBadgeShareSheet(
  BuildContext context,
  WidgetRef ref,
  UnlockedBadge badge, {
  String? habitName,
  String? currency,
}) => showAppSheet<void>(
  context,
  title: context.l10n.goalsBadgeShareTitle,
  builder: (_) => _ShareSheet(badge: badge, habitName: habitName, currency: currency),
);

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.badge, this.habitName, this.currency});

  final UnlockedBadge badge;
  final String? habitName;
  final String? currency;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final _boundary = GlobalKey();
  bool _withHabit = false;
  bool _withDate = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final date = AppFormat(context.localeName, l10n: l).dateMedium(
      ref.watch(zoneResolverProvider).toLocal(widget.badge.unlockedAt, ref.watch(deviceZoneProvider)).date,
    );
    final name = badgeName(context, widget.badge.code, currency: widget.currency);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: RepaintBoundary(
              key: _boundary,
              child: BadgeShareCard(
                code: widget.badge.code,
                habitName: _withHabit ? widget.habitName : null,
                dateText: _withDate ? date : null,
                currency: widget.currency,
              ),
            ),
          ),
          if (widget.habitName != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.goalsBadgeShareHabit),
              value: _withHabit,
              onChanged: (v) => setState(() => _withHabit = v),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.goalsBadgeShareDate),
            value: _withDate,
            onChanged: (v) => setState(() => _withDate = v),
          ),
          FilledButton.icon(
            onPressed: () => unawaited(shareBadgeCard(_boundary, text: l.goalsBadgeShareText(name))),
            icon: const Icon(Icons.ios_share),
            label: Text(l.goalsBadgeShare),
          ),
        ],
      ),
    );
  }
}
