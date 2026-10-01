import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/item_filter.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/items.dart';

void main() {
  final days = [for (var i = 0; i < 7; i++) LocalDate(2026, 9, 21).plusDays(i)];
  DayTimeline regular(LocalDate d) => DayTimeline.regular(d);

  test('timed items land on their day with elapsed minutes', () {
    final s = sliceItems(items: [item('Gym', at(2026, 9, 22, 7), 60)], days: days, timelineOf: regular);
    expect(s[1].timed.single.tStart, 420);
    expect(s[1].timed.single.tEnd, 480);
    expect(s[0].isEmpty, isTrue);
  });

  test('items crossing midnight split into two segments', () {
    final s = sliceItems(items: [item('Night', at(2026, 9, 22, 23), 120)], days: days, timelineOf: regular);
    final a = s[1].timed.single;
    final b = s[2].timed.single;
    expect((a.tStart, a.tEnd, a.continuesAfter), (1380, 1440, true));
    expect((b.tStart, b.tEnd, b.continuesBefore), (0, 60, true));
  });

  test('items that started before the range continue on the first day', () {
    final s = sliceItems(items: [item('Late', at(2026, 9, 20, 22), 240)], days: days, timelineOf: regular);
    expect(s[0].timed.single.tEnd, 120);
    expect(s[0].timed.single.continuesBefore, isTrue);
  });

  test('all-day and ≥ 24 h items go to the lane (excluded from the grid)', () {
    final trip = item('Trip', at(2026, 9, 23), 3 * 1440, allDay: true);
    final long = item('Conference', at(2026, 9, 25, 9), 1440 + 60);
    final s = sliceItems(items: [trip, long], days: days, timelineOf: regular);
    expect([for (final d in s) d.lane.length], [0, 0, 1, 1, 2, 1, 0]);
    expect(s.every((d) => d.timed.isEmpty), isTrue);
    expect(laneEndDate(trip), LocalDate(2026, 9, 25));
  });

  test('unchanged days keep their slice instance', () {
    final a = item('A', at(2026, 9, 21, 9), 30);
    final b = item('B', at(2026, 9, 22, 9), 30);
    final first = sliceItems(items: [a, b], days: days, timelineOf: regular);
    final prev = {for (final s in first) s.date: s};
    final moved = PlannerItem(
      taskId: b.taskId,
      seriesId: b.seriesId,
      occurrenceKey: b.occurrenceKey,
      title: b.title,
      startLocal: at(2026, 9, 22, 10),
      durationMinutes: 30,
      startUtc: b.startUtc,
      endUtc: b.endUtc,
      status: b.status,
    );
    final second = sliceItems(items: [a, moved], days: days, timelineOf: regular, previous: prev);
    expect(identical(second[0], first[0]), isTrue);
    expect(identical(second[1], first[1]), isFalse);
    expect(identical(second[3], first[3]), isTrue);
  });

  group('DST', () {
    late ZoneResolver resolver;
    setUpAll(() {
      tzdata.initializeTimeZones();
      resolver = TzZoneResolver();
    });

    test('second pass of the repeated hour is picked from startUtc', () {
      final date = LocalDate(2026, 10, 25);
      final tl = DayTimeline.build(date, 'Europe/Paris', resolver);
      final firstPass = resolver.resolve(at(2026, 10, 25, 2, 30), 'Europe/Paris').utc;
      final secondPass = firstPass.add(const Duration(hours: 1));
      final s = sliceItems(
        items: [
          item('First', at(2026, 10, 25, 2, 30), 30, startUtc: firstPass),
          item('Second', at(2026, 10, 25, 2, 30), 30, startUtc: secondPass),
        ],
        days: [date],
        timelineOf: (_) => tl,
      ).single;
      expect(s.timed.map((e) => (e.tStart, e.repeatStart)), [(150, 0), (210, 1)]);
      expect(s.timed.last.wallEnd, 180);
      expect(s.timed.last.repeatEnd, 1);
    });
  });

  group('filters', () {
    final done = item('Done', at(2026, 9, 21, 9), 30, status: OccurrenceStatus.done, categoryId: 'work', priority: 3);
    final cancelled = item('Cancelled', at(2026, 9, 21, 10), 30, status: OccurrenceStatus.cancelled);
    final open = item('Read book', at(2026, 9, 21, 11), 30, notes: 'chapter 3', trackingMode: TrackingMode.timer);

    test('completed/cancelled toggles', () {
      expect(const ItemFilter().apply([done, cancelled, open]), [done, open]);
      expect(const ItemFilter(showCompleted: false).apply([done, cancelled, open]), [open]);
      expect(ItemFilter.none.apply([done, cancelled, open]), hasLength(3));
    });

    test('category, priority, status, tracking and text', () {
      final items = [done, cancelled, open];
      expect(const ItemFilter(categories: {'work'}).apply(items), [done]);
      expect(const ItemFilter(categories: {''}).apply(items), [open]);
      expect(const ItemFilter(priorities: {3}).apply(items), [done]);
      expect(const ItemFilter(statuses: {OccurrenceStatus.scheduled}).apply(items), [open]);
      expect(const ItemFilter(trackingModes: {TrackingMode.timer}).apply(items), [open]);
      expect(const ItemFilter(text: 'CHAPTER').apply(items), [open]);
      expect(const ItemFilter(text: 'chapter').isActive, isTrue);
    });
  });
}
