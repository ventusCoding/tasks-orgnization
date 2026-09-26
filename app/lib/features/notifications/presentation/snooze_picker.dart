import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Snooze presets sheet (T7.2.15): presets from the notification / settings, "this evening",
/// "tomorrow morning" and a custom duration. Returns minutes from now.
Future<int?> pickSnooze(
  BuildContext context,
  WidgetRef ref, {
  List<int> options = const [],
}) {
  final l = context.l10n;
  final settings = ref.read(notificationSettingsProvider);
  final presets = {
    ...(options.isEmpty ? settings.snoozePresets : options),
    5,
    10,
    15,
    30,
    60,
  }.toList()..sort();
  final now = ref.read(clockProvider).nowUtc();
  final zone = ref.read(deviceZoneProvider);
  final zones = ref.read(zoneResolverProvider);
  final local = zones.toLocal(now, zone);
  int minutesUntil(LocalDateTime target) =>
      zones.resolve(target, zone).utc.difference(now).inMinutes;
  var evening = LocalDateTime(local.date, LocalTime(19, 0));
  if (!evening.isAfter(local)) evening = evening.plusDays(1);
  final morning = LocalDateTime(local.date.plusDays(1), LocalTime(8, 0));
  return showAppSheet<int>(
    context,
    title: l.notifActionSnooze,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final m in presets)
            ActionChip(
              label: Text(
                m >= 60 && m % 60 == 0
                    ? l.notifSnoozeHours(m ~/ 60)
                    : l.notifSnoozeMinutes(m),
              ),
              onPressed: () => Navigator.pop(ctx, m),
            ),
          ActionChip(
            avatar: const Icon(Icons.nights_stay_outlined, size: 18),
            label: Text(l.notifSnoozeEvening),
            onPressed: () => Navigator.pop(ctx, minutesUntil(evening)),
          ),
          ActionChip(
            avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
            label: Text(l.notifSnoozeTomorrow),
            onPressed: () => Navigator.pop(ctx, minutesUntil(morning)),
          ),
          ActionChip(
            avatar: const Icon(Icons.more_time, size: 18),
            label: Text(l.notifSnoozeCustom),
            onPressed: () async {
              final minutes = await pickDuration(
                ctx,
                initialMinutes: 20,
                maxMinutes: 7 * 1440,
              );
              if (minutes != null && ctx.mounted) Navigator.pop(ctx, minutes);
            },
          ),
        ],
      ),
    ),
  );
}
