import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/data/device_calendar_source.dart';
import 'package:everslot/features/integrations/domain/device_calendar.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Device-calendar overlay (T8.2.13): read-only, the selection stays on the device (local_kv).

final deviceCalendarSourceProvider = Provider<DeviceCalendarSource?>(
  (ref) => Platform.isAndroid || Platform.isIOS ? PluginDeviceCalendarSource() : null,
);

/// Whether the app may read calendars (re-read after asking).
final deviceCalendarAccessProvider = FutureProvider<bool>((ref) async {
  final source = ref.watch(deviceCalendarSourceProvider);
  if (source == null) return false;
  try {
    return await source.hasAccess();
  } on Object {
    return false;
  }
});

final deviceCalendarsProvider = FutureProvider<List<DeviceCalendarInfo>>((ref) async {
  final source = ref.watch(deviceCalendarSourceProvider);
  if (source == null || !await ref.watch(deviceCalendarAccessProvider.future)) return const [];
  try {
    return await source.calendars();
  } on Object {
    return const [];
  }
});

/// Selected calendar ids (local only — the overlay is not stored server-side).
final deviceCalendarSelectionProvider = AsyncNotifierProvider<DeviceCalendarSelection, Set<String>>(
  DeviceCalendarSelection.new,
);

class DeviceCalendarSelection extends AsyncNotifier<Set<String>> {
  static const key = 'integrations.device_calendars';

  @override
  Future<Set<String>> build() async {
    final json = await ref.watch(integrationQueriesProvider).readLocalJson(key);
    return {for (final id in (json['selected'] as List<Object?>?) ?? const []) ?id as String?};
  }

  Future<void> toggle(String calendarId, {required bool selected}) async {
    final next = {...await future};
    selected ? next.add(calendarId) : next.remove(calendarId);
    state = AsyncData(next);
    await ref.read(integrationQueriesProvider).writeLocalJson(key, {'selected': next.toList()..sort()});
  }

  Future<bool> requestAccess() async {
    final source = ref.read(deviceCalendarSourceProvider);
    if (source == null) return false;
    final granted = await source.requestAccess();
    ref
      ..invalidate(deviceCalendarAccessProvider)
      ..invalidate(deviceCalendarsProvider);
    return granted;
  }
}

/// Spans of the selected calendars for [days] days from a start date, in the device zone. Cached
/// per visible range while watched.
final deviceEventSpansProvider = FutureProvider.autoDispose.family<List<DeviceEventSpan>, (LocalDate, int)>((
  ref,
  range,
) async {
  final (from, days) = range;
  final source = ref.watch(deviceCalendarSourceProvider);
  final selected = await ref.watch(deviceCalendarSelectionProvider.future);
  if (source == null || selected.isEmpty || !await ref.watch(deviceCalendarAccessProvider.future)) return const [];
  final zones = ref.watch(zoneResolverProvider);
  final zone = ref.watch(deviceZoneProvider);
  final to = from.plusDays(days - 1);
  // A day of margin on both sides: events crossing midnight in other zones.
  final fromUtc = zones.resolve(from.plusDays(-1).atStartOfDay, zone).utc;
  final toUtc = zones.resolve(to.plusDays(2).atStartOfDay, zone).utc;
  try {
    final events = await source.events(selected.toList(), fromUtc, toUtc);
    return DeviceCalendarMapping.spans(events, toLocal: (utc) => zones.toLocal(utc, zone), from: from, to: to);
  } on Object {
    return const [];
  }
});
