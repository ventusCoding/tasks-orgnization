import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/domain/agenda.dart';
import 'package:everslot/features/today/domain/clean_time.dart';
import 'package:everslot/features/today/domain/day_window.dart';
import 'package:everslot/features/today/domain/now_next.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../today_test_support.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final zones = TzZoneResolver();

  group('selectNowNext (T8.1.03)', () {
    final now = DateTime.utc(2026, 9, 22, 10);

    test('the occurrence containing now is current; the next one starts after now', () {
      final r = selectNowNext([
        occ('Standup', start: at(2026, 9, 22, 9, 30)),
        occ('Lunch', start: at(2026, 9, 22, 12)),
        occ('Focus', start: at(2026, 9, 22, 11)),
      ], now);
      expect(r.current?.title, 'Standup');
      expect(r.overlapping, 0);
      expect(r.next?.title, 'Focus');
      expect(r.progressAt(now), closeTo(0.5, 1e-9));
    });

    test('a task ending exactly now is over; one starting exactly now is current', () {
      final r = selectNowNext([
        occ('Ends now', start: at(2026, 9, 22, 9)),
        occ('Starts now', start: at(2026, 9, 22, 10), minutes: 30),
      ], now);
      expect(r.current?.title, 'Starts now');
      expect(r.overlapping, 0);
      expect(r.next, isNull);
    });

    test('overlapping tasks: the one that started last wins with a count of the others', () {
      final r = selectNowNext([
        occ('Long', start: at(2026, 9, 22, 8), minutes: 240),
        occ('Late start', start: at(2026, 9, 22, 9, 45), minutes: 60),
        occ('Early', start: at(2026, 9, 22, 9), minutes: 120),
      ], now);
      expect(r.current?.title, 'Late start');
      expect(r.overlapping, 2);
    });

    test('all-day, done, skipped and missed occurrences are never now or next', () {
      final r = selectNowNext([
        occ('Holiday', start: at(2026, 9, 22), allDay: true),
        occ('Done', start: at(2026, 9, 22, 9, 30), status: OccurrenceStatus.done),
        occ('Skipped', start: at(2026, 9, 22, 11), status: OccurrenceStatus.skipped),
        occ('Missed', start: at(2026, 9, 22, 7), status: OccurrenceStatus.missed),
      ], now);
      expect(r.isEmpty, isTrue);
    });

    test('a running timer is current even outside its planned window', () {
      final r = selectNowNext([
        occ('Planned later', start: at(2026, 9, 22, 15), status: OccurrenceStatus.inProgress, mode: TrackingMode.timer),
        occ('Next', start: at(2026, 9, 22, 16)),
      ], now);
      expect(r.current?.title, 'Planned later');
      expect(r.next?.title, 'Next');
    });

    test('next ties break by priority then title', () {
      final r = selectNowNext([
        occ('b', start: at(2026, 9, 22, 11)),
        occ('a', start: at(2026, 9, 22, 11)),
        occ('z', start: at(2026, 9, 22, 11), priority: 3),
      ], now);
      expect(r.next?.title, 'z');
    });
  });

  group('agenda (T8.1.04)', () {
    final window = DayWindow.of(LocalDate(2026, 9, 22), 'UTC', zones);

    test('split keeps the day (all-day first) and the timed occurrences after it', () {
      final split = splitAgenda([
        occ('Tomorrow', start: at(2026, 9, 23, 8)),
        occ('Late', start: at(2026, 9, 22, 18)),
        occ('Early', start: at(2026, 9, 22, 7)),
        occ('Holiday', start: at(2026, 9, 22), allDay: true),
        occ('Tomorrow all-day', start: at(2026, 9, 23), allDay: true),
        occ('Overnight', start: at(2026, 9, 21, 23), minutes: 120),
        occ('Cancelled', start: at(2026, 9, 22, 12), status: OccurrenceStatus.cancelled),
      ], window);
      expect(split.agenda.map((i) => i.title), ['Holiday', 'Overnight', 'Early', 'Late']);
      expect(split.upcoming.map((i) => i.title), ['Tomorrow']);
    });

    test('a 04:00 day start keeps 01:00 in the previous logical day', () {
      final w = DayWindow.of(LocalDate(2026, 9, 22), 'UTC', zones, dayStartMinutes: 240);
      final split = splitAgenda([
        occ('Night owl', start: at(2026, 9, 23, 1)),
        occ('Too early', start: at(2026, 9, 22, 2)),
      ], w);
      expect(split.agenda.map((i) => i.title), ['Night owl']);
    });

    test('groups: open all-day, open timed, resolved collapsed', () {
      final g = groupAgenda([
        occ('A', start: at(2026, 9, 22), allDay: true),
        occ('B', start: at(2026, 9, 22, 8), status: OccurrenceStatus.done),
        occ('C', start: at(2026, 9, 22, 9), status: OccurrenceStatus.missed),
        occ('D', start: at(2026, 9, 22, 10), status: OccurrenceStatus.skipped),
        occ('E', start: at(2026, 9, 22, 11), mode: TrackingMode.event),
      ]);
      expect(g.allDay.map((i) => i.title), ['A']);
      expect(g.timed.map((i) => i.title), ['C', 'E']);
      expect(g.completed.map((i) => i.title), ['B', 'D']);
      expect(hasCheckbox(g.timed.last), isFalse);
    });
  });

  group('selectOverdue look-back (T8.1.05)', () {
    final today = LocalDate(2026, 9, 22);

    test('open check/timer occurrences of the look-back days before today, oldest first', () {
      final items = [
        occ('In range', start: at(2026, 9, 20, 9), status: OccurrenceStatus.missed),
        occ('Oldest', start: at(2026, 9, 15, 9), status: OccurrenceStatus.missed),
        occ('Too old', start: at(2026, 9, 14, 9), status: OccurrenceStatus.missed),
        occ('Today', start: at(2026, 9, 22, 6), status: OccurrenceStatus.missed),
        occ('Done', start: at(2026, 9, 21, 9), status: OccurrenceStatus.done),
        occ('Event', start: at(2026, 9, 21, 9), mode: TrackingMode.event),
        occ('Timer', start: at(2026, 9, 21, 10), mode: TrackingMode.timer, status: OccurrenceStatus.missed),
        occ('Recurring', start: at(2026, 9, 21, 7), status: OccurrenceStatus.missed, recurring: true),
        occ('Quota', start: at(2026, 9, 20), allDay: true, quotaSlot: true, status: OccurrenceStatus.missed),
      ];
      expect(
        selectOverdue(items, today: today, lookbackDays: 7).map((i) => i.title),
        ['Oldest', 'In range', 'Recurring', 'Timer'],
      );
      expect(
        selectOverdue(items, today: today, lookbackDays: 2, includeRecurring: false).map((i) => i.title),
        ['In range', 'Timer'],
      );
      expect(selectOverdue(items, today: today, lookbackDays: 0), isEmpty);
    });
  });

  group('DayWindow (T8.1.01)', () {
    test('midnight and day start boundaries in a zone', () {
      final w = DayWindow.at(DateTime.utc(2026, 9, 22, 22, 30), 'Europe/Paris', zones);
      expect(w.date, LocalDate(2026, 9, 23)); // 00:30 in Paris
      expect(w.startUtc, DateTime.utc(2026, 9, 22, 22));
      expect(w.endUtc, DateTime.utc(2026, 9, 23, 22));
      final owl = DayWindow.at(DateTime.utc(2026, 9, 22, 22, 30), 'Europe/Paris', zones, dayStartMinutes: 240);
      expect(owl.date, LocalDate(2026, 9, 22));
      expect(owl.endUtc, DateTime.utc(2026, 9, 23, 2));
    });

    test('a DST day is 23 or 25 hours long', () {
      final spring = DayWindow.of(LocalDate(2026, 3, 29), 'Europe/Paris', zones);
      expect(spring.endUtc.difference(spring.startUtc), const Duration(hours: 23));
      final fall = DayWindow.of(LocalDate(2026, 10, 25), 'Europe/Paris', zones);
      expect(fall.endUtc.difference(fall.startUtc), const Duration(hours: 25));
      expect(untilNextBoundary(DateTime.utc(2026, 10, 25, 22, 59), 'Europe/Paris', zones), const Duration(minutes: 1));
    });
  });

  group('CleanTime (T8.1.07)', () {
    test('splits the elapsed time and never goes negative', () {
      expect(CleanTime.of(const Duration(days: 3, hours: 4, minutes: 12, seconds: 9)).compact, '3d 04:12:09');
      expect(CleanTime.of(const Duration(minutes: 5, seconds: 1)).compact, '00:05:01');
      expect(CleanTime.between(DateTime.utc(2026), DateTime.utc(2025)), const CleanTime(0, 0, 0, 0));
    });

    test('is real elapsed time across DST changes', () {
      // Quit at 12:00 Paris (CEST) the day before the fall-back switch; 24 wall-clock hours later
      // (12:00 CET) 25 real hours have passed.
      final start = zones.resolve(at(2026, 10, 24, 12), 'Europe/Paris').utc;
      final now = zones.resolve(at(2026, 10, 25, 12), 'Europe/Paris').utc;
      expect(CleanTime.between(start, now), const CleanTime(1, 1, 0, 0));
      // Spring forward: 24 wall-clock hours are 23 real hours.
      final s2 = zones.resolve(at(2026, 3, 28, 12), 'Europe/Paris').utc;
      final n2 = zones.resolve(at(2026, 3, 29, 12), 'Europe/Paris').utc;
      expect(CleanTime.between(s2, n2), const CleanTime(0, 23, 0, 0));
    });
  });
}
