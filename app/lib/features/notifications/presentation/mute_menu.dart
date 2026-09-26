import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _MuteFor { hour, today, tomorrow, week, forever }

/// "Mute until…" (T7.5.16) for a rule, task, checklist, item subtree, habit or section.
class MuteMenuButton extends ConsumerWidget {
  const MuteMenuButton({
    required this.targetType,
    this.targetId,
    this.section,
    super.key,
  });

  /// rule | task | checklist | checklist_item | habit | section
  final String targetType;
  final String? targetId;
  final NotificationSection? section;

  DateTime? _until(WidgetRef ref, _MuteFor choice) {
    final now = ref.read(clockProvider).nowUtc();
    final zone = ref.read(deviceZoneProvider);
    final zones = ref.read(zoneResolverProvider);
    final today = zones.toLocal(now, zone).date;
    DateTime at(LocalDate d, LocalTime t) =>
        zones.resolve(LocalDateTime(d, t), zone).utc;
    return switch (choice) {
      _MuteFor.hour => now.add(const Duration(hours: 1)),
      _MuteFor.today => at(today.plusDays(1), LocalTime.midnight),
      _MuteFor.tomorrow => at(today.plusDays(1), LocalTime(8, 0)),
      _MuteFor.week => at(today.plusDays(7), LocalTime.midnight),
      _MuteFor.forever => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PopupMenuButton<_MuteFor>(
      tooltip: l.notifMuteFor,
      icon: const Icon(Icons.notifications_paused_outlined),
      onSelected: (choice) => unawaited(
        ref
            .read(notificationMutesRepositoryProvider)
            .mute(
              targetType: targetType,
              targetId: targetId,
              section: section?.wire,
              until: _until(ref, choice),
              reason: 'user',
            ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(value: _MuteFor.hour, child: Text(l.notifMute1h)),
        PopupMenuItem(value: _MuteFor.today, child: Text(l.notifMuteToday)),
        PopupMenuItem(
          value: _MuteFor.tomorrow,
          child: Text(l.notifMuteTomorrow),
        ),
        PopupMenuItem(value: _MuteFor.week, child: Text(l.notifMuteWeek)),
        PopupMenuItem(value: _MuteFor.forever, child: Text(l.notifMuteForever)),
      ],
    );
  }
}

/// Visible mute badge with *Unmute* (shown while a mute is active).
class MuteBadge extends ConsumerWidget {
  const MuteBadge({
    required this.targetType,
    this.targetId,
    this.section,
    super.key,
  });

  final String targetType;
  final String? targetId;
  final String? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).nowUtc();
    final mutes = [
      for (final m
          in ref.watch(notificationMutesProvider).value ??
              const <NotificationMute>[])
        if (m.targetType == targetType &&
            m.targetId == targetId &&
            (section == null || m.section == section) &&
            m.activeAt(now))
          m,
    ];
    if (mutes.isEmpty) return const SizedBox.shrink();
    return MuteTile(mute: mutes.first, dense: true);
  }
}

/// One mute with its expiry and an *Unmute* button (settings page list, badges).
class MuteTile extends ConsumerWidget {
  const MuteTile({
    required this.mute,
    this.title,
    this.dense = false,
    super.key,
  });

  final NotificationMute mute;
  final String? title;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final format = AppFormat(
      context.localeName,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
      l10n: l,
    );
    final until = mute.until;
    final label = until == null
        ? l.notifMutedForever
        : l.notifMutedUntil(format.dateTime(zones.toLocal(until, zone)));
    return ListTile(
      dense: dense,
      leading: const Icon(Icons.notifications_off_outlined),
      title: Text(title ?? label),
      subtitle: title == null ? null : Text(label),
      trailing: TextButton(
        onPressed: () => unawaited(
          ref.read(notificationMutesRepositoryProvider).unmute(mute.id),
        ),
        child: Text(l.notifUnmute),
      ),
    );
  }
}
