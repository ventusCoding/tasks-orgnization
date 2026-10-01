import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/focus_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/items.dart';

// Which occurrence the focus view shows (T3.7.01).
void main() {
  final now = at(2026, 9, 23, 9, 30);

  test('the item covering now is current; the next one to start is next', () {
    final items = [
      item('Standup', at(2026, 9, 23, 9), 60, id: 'a'),
      item('Lunch', at(2026, 9, 23, 12), 60, id: 'b'),
      item('Review', at(2026, 9, 23, 15), 30, id: 'c'),
    ];
    final s = selectFocus(items, now);
    expect(s.current?.title, 'Standup');
    expect(s.next?.title, 'Lunch');
    expect(s.upcoming.map((i) => i.title), ['Lunch', 'Review']);
  });

  test('overlapping items: the latest started wins, then priority; a running one wins over both', () {
    final a = item('A', at(2026, 9, 23, 9), 120, id: 'a');
    final b = item('B', at(2026, 9, 23, 9, 15), 60, id: 'b');
    final c = item('C', at(2026, 9, 23, 9, 15), 60, id: 'c', priority: 3);
    expect(selectFocus([a, b], now).current?.title, 'B');
    expect(selectFocus([a, b, c], now).current?.title, 'C');
    final running = item(
      'Timer',
      at(2026, 9, 23, 8),
      60,
      id: 'r',
      status: OccurrenceStatus.inProgress,
      trackingMode: TrackingMode.timer,
    );
    expect(
      selectFocus([a, b, c, running], now).current?.title,
      'Timer',
      reason: 'a running timer keeps the focus even past its planned end',
    );
  });

  test('nothing covers now: no current item, the next upcoming item is offered', () {
    final s = selectFocus([item('Later', at(2026, 9, 23, 14), 30, id: 'a')], now);
    expect(s.current, isNull);
    expect(s.next?.title, 'Later');
  });

  test('done, skipped, cancelled, missed, all-day and backlog items are never focused', () {
    final s = selectFocus([
      item('Done', at(2026, 9, 23, 9), 60, id: 'a', status: OccurrenceStatus.done),
      item('Skipped', at(2026, 9, 23, 9), 60, id: 'b', status: OccurrenceStatus.skipped),
      item('Cancelled', at(2026, 9, 23, 9), 60, id: 'c', status: OccurrenceStatus.cancelled),
      item('Missed', at(2026, 9, 23, 9), 60, id: 'd', status: OccurrenceStatus.missed),
      item('Holiday', at(2026, 9, 23), 1440, id: 'e', allDay: true),
    ], now);
    expect(s.current, isNull);
    expect(s.next, isNull);
  });

  test('a pinned item (the Next button) becomes current, and next moves past it', () {
    final items = [
      item('Now', at(2026, 9, 23, 9), 60, id: 'a'),
      item('Lunch', at(2026, 9, 23, 12), 60, id: 'b'),
      item('Review', at(2026, 9, 23, 15), 30, id: 'c'),
    ];
    final s = selectFocus(items, now, pinnedKey: items[1].key);
    expect(s.current?.title, 'Lunch');
    expect(s.next?.title, 'Review');
    expect(
      selectFocus(items, now, pinnedKey: 'gone|x').current?.title,
      'Now',
      reason: 'an unknown pin falls back to the automatic choice',
    );
  });

  test('an item crossing midnight stays current after midnight', () {
    final night = item('Night shift', at(2026, 9, 22, 22), 480, id: 'n');
    final s = selectFocus([night], at(2026, 9, 23, 3));
    expect(s.current?.title, 'Night shift');
  });

  group('ring maths', () {
    final start = DateTime.utc(2026, 9, 23, 9);
    final end = DateTime.utc(2026, 9, 23, 10);
    test('remaining fraction runs from 1 to 0 and never goes negative', () {
      expect(remainingFraction(start, end, DateTime.utc(2026, 9, 23, 8)), 1);
      expect(remainingFraction(start, end, DateTime.utc(2026, 9, 23, 9)), 1);
      expect(remainingFraction(start, end, DateTime.utc(2026, 9, 23, 9, 45)), closeTo(0.25, 1e-9));
      expect(remainingFraction(start, end, DateTime.utc(2026, 9, 23, 11)), 0);
      expect(remainingFraction(start, start, start), 0);
    });

    test('time left is negative once the end has passed', () {
      expect(timeLeft(end, DateTime.utc(2026, 9, 23, 9, 50)), const Duration(minutes: 10));
      expect(timeLeft(end, DateTime.utc(2026, 9, 23, 10, 5)), const Duration(minutes: -5));
    });
  });
}
