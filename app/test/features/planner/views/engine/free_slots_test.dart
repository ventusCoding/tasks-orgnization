import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/items.dart';

// T3.7.04 interval algebra: merge busy blocks, subtract, clip to work hours, min gap, DST days.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  final mon = LocalDate(2026, 9, 21);
  WallInterval w(int h1, int m1, int h2, int m2) =>
      WallInterval(mon.atTime(LocalTime(h1, m1)), mon.atTime(LocalTime(h2, m2)));
  const work = FreeSlotOptions(window: DayWindow(9 * 60, 17 * 60), minGapMinutes: 15);

  test('merge joins overlapping and touching blocks and drops empty ones', () {
    expect(mergeIntervals([w(10, 0, 11, 0), w(9, 0, 9, 30), w(10, 30, 12, 0), w(12, 0, 12, 15), w(13, 0, 13, 0)]), [
      w(9, 0, 9, 30),
      w(10, 0, 12, 15),
    ]);
  });

  test('subtract leaves the gaps of the window', () {
    expect(subtractIntervals(w(9, 0, 17, 0), [w(8, 0, 9, 30), w(12, 0, 13, 0), w(16, 30, 18, 0)]), [
      w(9, 30, 12, 0),
      w(13, 0, 16, 30),
    ]);
    expect(subtractIntervals(w(9, 0, 17, 0), [w(8, 0, 18, 0)]), isEmpty);
    expect(subtractIntervals(w(9, 0, 17, 0), const []), [w(9, 0, 17, 0)]);
  });

  test('openings: work hours, gaps below the minimum dropped, zero-length excluded', () {
    final items = [
      item('Standup', at(2026, 9, 21, 9), 20),
      item('Deep work', at(2026, 9, 21, 9, 30), 120),
      item('Lunch', at(2026, 9, 21, 12), 60),
      item('Back to back', at(2026, 9, 21, 13), 60),
      item('Late', at(2026, 9, 21, 16, 50), 60),
    ];
    final free = freeIntervals(items: items, days: [mon], options: work);
    expect(
      [for (final f in free) '${f.start.time.toIso()}–${f.end.time.toIso()} ${f.minutes}'],
      ['11:30–12:00 30', '14:00–16:50 170'],
    );
  });

  test('skipped, cancelled and all-day items are not busy; low priority can be ignored', () {
    final items = [
      item('Skipped', at(2026, 9, 21, 9), 480, status: OccurrenceStatus.skipped),
      item('Cancelled', at(2026, 9, 21, 9), 480, status: OccurrenceStatus.cancelled),
      item('Trip', at(2026, 9, 21), 1440, allDay: true),
      item('Optional', at(2026, 9, 21, 10), 60, priority: 1),
    ];
    expect(freeIntervals(items: items, days: [mon], options: work).length, 2);
    final ignoring = FreeSlotOptions(window: work.window, minGapMinutes: 15, ignoreBelowPriority: 2);
    expect(freeIntervals(items: items, days: [mon], options: ignoring).single.minutes, 480);
  });

  test('only work days count; items crossing midnight block the next morning', () {
    final items = [item('Night', at(2026, 9, 21, 22), 13 * 60)]; // Mon 22:00 → Tue 11:00
    final days = [for (var i = 0; i < 7; i++) mon.plusDays(i)];
    final free = freeIntervals(items: items, days: days, options: work);
    expect({for (final f in free) f.day.weekday.iso}, {1, 2, 3, 4, 5});
    final tuesday = free.firstWhere((f) => f.day == mon.plusDays(1));
    expect(tuesday.start, at(2026, 9, 22, 11));
  });

  test('DST days count real elapsed minutes (Europe/Paris)', () {
    final zones = TzZoneResolver();
    int elapsed(LocalDateTime a, LocalDateTime b) => elapsedMinutes(zones, 'Europe/Paris', a, b);
    const night = FreeSlotOptions(window: DayWindow(60, 300), workDays: {7}, minGapMinutes: 1);
    final spring = freeIntervals(items: const [], days: [LocalDate(2026, 3, 29)], options: night, elapsed: elapsed);
    expect(spring.single.minutes, 180, reason: '01:00–05:00 on a 23-hour day');
    final autumn = freeIntervals(items: const [], days: [LocalDate(2026, 10, 25)], options: night, elapsed: elapsed);
    expect(autumn.single.minutes, 300, reason: '01:00–05:00 on a 25-hour day');
    const tight = FreeSlotOptions(window: DayWindow(120, 180), workDays: {7}, minGapMinutes: 30);
    expect(
      freeIntervals(items: const [], days: [LocalDate(2026, 3, 29)], options: tight, elapsed: elapsed),
      isEmpty,
      reason: 'the skipped hour is no opening',
    );
  });

  test('sequential placement fills openings in order and skips items that do not fit', () {
    final openings = [
      FreeInterval(day: mon, start: at(2026, 9, 21, 10), end: at(2026, 9, 21, 11), minutes: 60),
      FreeInterval(day: mon, start: at(2026, 9, 21, 14), end: at(2026, 9, 21, 16), minutes: 120),
    ];
    expect(placeSequentially(openings, [45, 30, 90, 180]), [
      at(2026, 9, 21, 10),
      at(2026, 9, 21, 14),
      at(2026, 9, 21, 14, 30),
      null,
    ]);
    expect(placeSequentially(openings, [15, 45, 60]), [
      at(2026, 9, 21, 10),
      at(2026, 9, 21, 10, 15),
      at(2026, 9, 21, 14),
    ]);
  });
}
