import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/domain/planner/recurrence_adapter.dart';
import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a reminder schedule (`schedule` / `digest` triggers) with the shared recurrence picker
/// ([2.1], `RecurrencePickerMode.reminder`). Returns the schedule JSON (§8.1 rule + the additive
/// `start` anchor), or null when dismissed or *Does not repeat* is chosen.
Future<Map<String, Object?>?> pickReminderSchedule(
  BuildContext context,
  WidgetRef ref, {
  Map<String, Object?>? initial,
}) async {
  final parsed = initial == null
      ? null
      : EngineRecurrenceExpander.parse(initial);
  final anchor = parsed?.$2 ?? RecurrenceAnchor(_defaultStart(ref), null);
  final result = await showRecurrencePickerDetailed(
    context,
    anchor: anchor,
    initial: parsed?.$1,
    mode: RecurrencePickerMode.reminder,
  );
  final rule = result?.rule;
  if (result == null || rule == null) return null;
  return EngineRecurrenceExpander.encode(rule, result.anchor.start);
}

/// Today 09:00 in the device zone.
LocalDateTime _defaultStart(WidgetRef ref) {
  final now = ref.read(clockProvider).nowUtc();
  final local = ref
      .read(zoneResolverProvider)
      .toLocal(now, ref.read(deviceZoneProvider));
  return LocalDateTime(local.date, LocalTime(9, 0));
}
