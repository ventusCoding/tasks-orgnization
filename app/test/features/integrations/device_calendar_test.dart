import 'package:everslot/core/providers.dart';
import 'package:everslot/features/integrations/application/device_calendar_providers.dart';
import 'package:everslot/features/integrations/data/device_calendar_source.dart';
import 'package:everslot/features/integrations/domain/device_calendar.dart';
import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

class FakeCalendars implements DeviceCalendarSource {
  bool access = false;
  List<DeviceEventInfo> stored = [];
  List<String>? askedFor;

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<bool> requestAccess() async => access = true;

  @override
  Future<List<DeviceCalendarInfo>> calendars() async => const [
    DeviceCalendarInfo(id: 'work', name: 'Work', color: 0xFF3366CC),
    DeviceCalendarInfo(id: 'family', name: 'Family'),
  ];

  @override
  Future<List<DeviceEventInfo>> events(List<String> calendarIds, DateTime from, DateTime to) async {
    askedFor = calendarIds;
    return [
      for (final e in stored)
        if (calendarIds.contains(e.calendarId)) e,
    ];
  }
}

/// T8.2.13: device-calendar overlay — mapping, selection, busy time.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final from = LocalDate(2026, 9, 21);
  final to = LocalDate(2026, 9, 27);
  LocalDateTime utcAsLocal(DateTime utc) => LocalDateTime.of(utc.year, utc.month, utc.day, utc.hour, utc.minute);

  test('timed events split at midnight in the viewer zone; out-of-range days dropped', () {
    final spans = DeviceCalendarMapping.spans(
      [
        DeviceEventInfo(
          id: 'late',
          calendarId: 'c',
          title: 'Flight',
          start: DateTime.utc(2026, 9, 22, 22),
          end: DateTime.utc(2026, 9, 23, 2),
        ),
        DeviceEventInfo(
          id: 'before',
          calendarId: 'c',
          title: 'Old',
          start: DateTime.utc(2026, 9, 1, 9),
          end: DateTime.utc(2026, 9, 1, 10),
        ),
      ],
      toLocal: utcAsLocal,
      from: from,
      to: to,
    );
    expect(
      [for (final s in spans) '${s.day} ${s.start.time.toIso()}-${s.end.time.toIso()}'],
      ['2026-09-22 22:00-00:00', '2026-09-23 00:00-02:00'],
    );
  });

  test('all-day events: exclusive or inclusive ends, never busy', () {
    final spans = DeviceCalendarMapping.spans(
      [
        DeviceEventInfo(
          id: 'a',
          calendarId: 'c',
          title: 'Trip',
          start: DateTime(2026, 9, 24),
          end: DateTime(2026, 9, 26),
          allDay: true,
        ),
        DeviceEventInfo(
          id: 'b',
          calendarId: 'c',
          title: 'Holiday',
          start: DateTime(2026, 9, 27),
          end: DateTime(2026, 9, 27, 23, 59),
          allDay: true,
        ),
      ],
      toLocal: utcAsLocal,
      from: from,
      to: to,
    );
    expect(
      [for (final s in spans) '${s.title} ${s.day}'],
      ['Trip 2026-09-24', 'Trip 2026-09-25', 'Holiday 2026-09-27'],
    );
    expect(spans.every((s) => s.allDay && !s.busy), isTrue);
    expect(DeviceCalendarMapping.parseColor('#3366CC'), 0xFF3366CC);
    expect(DeviceCalendarMapping.parseColor('#803366CC'), 0xFF3366CC);
    expect(DeviceCalendarMapping.parseColor('nope'), isNull);
  });

  test('busy events close free slots', () {
    final day = LocalDate(2026, 9, 22);
    final free = freeIntervals(
      items: const [],
      days: [day],
      options: const FreeSlotOptions(window: DayWindow(540, 1020)),
      extraBusy: [(LocalDateTime.of(2026, 9, 22, 10), LocalDateTime.of(2026, 9, 22, 12))],
    );
    expect([for (final f in free) '${f.start.time.toIso()}-${f.end.time.toIso()}'], ['09:00-10:00', '12:00-17:00']);
  });

  test('selection is local; only selected calendars are read, after access is granted', () async {
    final fake = FakeCalendars()
      ..stored = [
        DeviceEventInfo(
          id: 'e1',
          calendarId: 'work',
          title: 'Review',
          start: DateTime.utc(2026, 9, 22, 8),
          end: DateTime.utc(2026, 9, 22, 9),
        ),
        DeviceEventInfo(
          id: 'e2',
          calendarId: 'family',
          title: 'Dinner',
          start: DateTime.utc(2026, 9, 22, 18),
          end: DateTime.utc(2026, 9, 22, 20),
        ),
      ];
    final h = TestHarness.create(
      now: DateTime.utc(2026, 9, 21),
      overrides: [deviceCalendarSourceProvider.overrideWithValue(fake)],
    );
    addTearDown(h.dispose);
    expect(await h.container.read(deviceEventSpansProvider((from, 7)).future), isEmpty, reason: 'no access yet');
    expect(await h.read(deviceCalendarSelectionProvider.notifier).requestAccess(), isTrue);
    await h.read(deviceCalendarSelectionProvider.notifier).toggle('work', selected: true);
    expect((await h.container.read(deviceCalendarsProvider.future)).map((c) => c.name), ['Work', 'Family']);
    final spans = await h.container.read(deviceEventSpansProvider((from, 7)).future);
    expect(spans.map((s) => s.title), ['Review']);
    expect(fake.askedFor, ['work']);
    final kv = await h.db
        .customSelect("SELECT value FROM local_kv WHERE key = 'integrations.device_calendars'")
        .getSingle();
    expect(kv.read<String>('value'), contains('work'));
    expect(h.read(deviceZoneProvider), isNotEmpty);
  });
}
