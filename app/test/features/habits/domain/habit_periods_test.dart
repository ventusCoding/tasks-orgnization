import 'dart:math';

import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPeriodKind;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/habit_fixtures.dart';

void main() {
  setUpAll(ensureTz);

  Duration window(dynamic p) => (p.windowEnd as DateTime).difference(p.windowStart as DateTime);

  group('day periods, zones & day start (T5.1.05)', () {
    test('Europe/Paris DST days are 23 h and 25 h long', () {
      final s = periodService(zone: 'Europe/Paris');
      final habit = buildHabit(start: d(2026, 1, 1));
      final spring = s.periods(habit, const [], d(2026, 3, 28), d(2026, 3, 30));
      expect(spring.map((p) => p.key), ['2026-03-28', '2026-03-29', '2026-03-30']);
      expect(spring.map(window), [const Duration(hours: 24), const Duration(hours: 23), const Duration(hours: 24)]);
      final fall = s.periods(habit, const [], d(2026, 10, 24), d(2026, 10, 26));
      expect(fall.map(window), [const Duration(hours: 24), const Duration(hours: 25), const Duration(hours: 24)]);
      expect(spring.every((p) => p.kind == HabitPeriodKind.day && p.due), isTrue);
    });

    test('dayStartsAt 04:00 moves the boundary and the DST hour to the previous day', () {
      final s = periodService(zone: 'Europe/Paris', dayStartMinutes: 240);
      final habit = buildHabit(start: d(2026, 1, 1));
      final ps = s.periods(habit, const [], d(2026, 3, 28), d(2026, 3, 29));
      expect(ps.map(window), [const Duration(hours: 23), const Duration(hours: 24)]);
      expect(ps.first.windowStart, DateTime.utc(2026, 3, 28, 3)); // 04:00 CET
      // 01:00 local on Sept 23 (23:00 UTC on the 22nd) still belongs to Sept 22.
      expect(s.dayKeyFor(habit, DateTime.utc(2026, 9, 22, 23)), '2026-09-22');
      expect(s.dayKeyFor(habit, DateTime.utc(2026, 9, 23, 2, 30)), '2026-09-23');
    });

    test('Africa/Tunis (no DST) and floating vs fixed zones', () {
      final tunis = periodService(zone: 'Africa/Tunis');
      final floating = buildHabit();
      final p = tunis.periods(floating, const [], d(2026, 9, 22), d(2026, 9, 22)).single;
      expect(p.windowStart, DateTime.utc(2026, 9, 21, 23));
      expect(window(p), const Duration(hours: 24));
      // A fixed-zone habit ignores the device zone.
      final fixed = buildHabit(zone: 'Asia/Tokyo');
      final q = tunis.periods(fixed, const [], d(2026, 9, 22), d(2026, 9, 22)).single;
      expect(q.windowStart, DateTime.utc(2026, 9, 21, 15));
      expect(tunis.zoneOf(fixed), 'Asia/Tokyo');
      expect(tunis.zoneOf(floating), 'Africa/Tunis');
    });

    test('specific weekdays, every N days anchored on the start, start/end dates', () {
      final s = periodService();
      final weekly = buildHabit(
        schedule: RecurrenceRule(
          freq: Frequency.weekly,
          byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)],
        ),
      );
      final week = s.periods(weekly, const [], d(2026, 9, 21), d(2026, 9, 27));
      expect([for (final p in week) if (p.due) p.key], ['2026-09-21', '2026-09-22']);
      expect(week, hasLength(7), reason: 'not-due days are still periods (not_due, never missed)');

      final everyOther = buildHabit(start: d(2026, 9, 2), schedule: RecurrenceRule(interval: 2));
      expect(
        [for (final p in s.periods(everyOther, const [], d(2026, 9, 1), d(2026, 9, 8))) if (p.due) p.key],
        ['2026-09-02', '2026-09-04', '2026-09-06', '2026-09-08'],
      );

      final bounded = buildHabit(start: d(2026, 9, 5), end: d(2026, 9, 7));
      expect(
        s.periods(bounded, const [], d(2026, 9, 1), d(2026, 9, 30)).map((p) => p.key),
        ['2026-09-05', '2026-09-06', '2026-09-07'],
      );
      expect(s.periods(bounded, const [], d(2026, 10, 1), d(2026, 10, 3)), isEmpty);
    });

    test('revision switch mid-range: daily → weekdays keeps the old days', () {
      final s = periodService();
      final habit = buildHabit(
        schedule: RecurrenceRule(
          freq: Frequency.weekly,
          byWeekday: [for (final w in const [Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday]) WeekdayRule(w)],
        ),
      );
      final revs = [
        revision('r1', d(2026, 9, 1), schedule: RecurrenceRule()),
        revision('r2', d(2026, 9, 23), schedule: habit.schedule),
      ];
      final ps = s.periods(habit, revs, d(2026, 9, 19), d(2026, 9, 27));
      expect({for (final p in ps) p.key: p.due}, {
        '2026-09-19': true,
        '2026-09-20': true,
        '2026-09-21': true,
        '2026-09-22': true,
        '2026-09-23': true,
        '2026-09-24': true,
        '2026-09-25': true,
        '2026-09-26': false,
        '2026-09-27': false,
      });
      expect(ps.firstWhere((p) => p.key == '2026-09-22').revisionId, 'r1');
      expect(ps.firstWhere((p) => p.key == '2026-09-23').revisionId, 'r2');
      expect(s.rulesOn(habit, revs, d(2026, 9, 20)).schedule, RecurrenceRule());
    });

    test('goal revisions change the target of later periods only', () {
      final s = periodService();
      final habit = buildHabit(goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'));
      final revs = [
        revision('r1', d(2026, 9, 1), schedule: RecurrenceRule(), goalType: HabitGoalType.count, target: 15, unit: 'reps'),
        revision('r2', d(2026, 9, 10), schedule: RecurrenceRule(), goalType: HabitGoalType.count, target: 20, unit: 'reps'),
      ];
      final ps = s.periods(habit, revs, d(2026, 9, 9), d(2026, 9, 10));
      expect(ps.map((p) => p.goal.target), [15, 20]);
    });
  });

  group('quota periods', () {
    test('week keys honour the week start (MO / SA / SU)', () {
      final habit = buildHabit(schedule: RecurrenceRule.forQuota(3, PeriodUnit.week));
      String keyFor(Weekday ws) =>
          periodService(weekStart: ws).periods(habit, const [], d(2026, 9, 23), d(2026, 9, 23)).single.key;
      expect(keyFor(Weekday.monday), 'week:2026-09-21');
      expect(keyFor(Weekday.saturday), 'week:2026-09-19');
      expect(keyFor(Weekday.sunday), 'week:2026-09-20');
    });

    test('month boundaries and pro-rated first period', () {
      final s = periodService();
      final habit = buildHabit(start: d(2026, 9, 10), schedule: RecurrenceRule.forQuota(10, PeriodUnit.month));
      final ps = s.periods(habit, const [], d(2026, 9, 1), d(2026, 10, 5));
      expect(ps.map((p) => p.key), ['month:2026-09', 'month:2026-10']);
      expect(ps.first.startDate, d(2026, 9, 10));
      expect(ps.first.endDate, d(2026, 9, 30));
      expect(ps.first.eligibleDays, hasLength(21));
      expect(ps.first.fullEligibleDays, 30);
      expect(ps.first.quotaTimes, 10);
      expect(ps.last.endDate, d(2026, 10, 31), reason: 'the current period extends into the future');
      expect(ps.last.eligibleDays, hasLength(31));
    });

    test('a weekday filter reduces eligible days', () {
      final s = periodService();
      final habit = buildHabit(
        start: d(2026, 9, 21),
        schedule: RecurrenceRule.forQuota(2, PeriodUnit.week, byWeekday: const [WeekdayRule(Weekday.saturday), WeekdayRule(Weekday.sunday)]),
      );
      final p = s.periods(habit, const [], d(2026, 9, 21), d(2026, 9, 21)).single;
      expect(p.eligibleDays, [d(2026, 9, 26), d(2026, 9, 27)]);
      expect(p.fullEligibleDays, 2);
    });

    test('a quota revision inside a week applies from the next week', () {
      final s = periodService();
      final habit = buildHabit(schedule: RecurrenceRule.forQuota(5, PeriodUnit.week));
      final revs = [
        revision('r1', d(2026, 9, 1), schedule: RecurrenceRule.forQuota(3, PeriodUnit.week)),
        revision('r2', d(2026, 9, 23), schedule: RecurrenceRule.forQuota(5, PeriodUnit.week)),
      ];
      final ps = s.periods(habit, revs, d(2026, 9, 21), d(2026, 10, 4));
      expect(ps.map((p) => (p.key, p.quotaTimes)), [('week:2026-09-21', 3), ('week:2026-09-28', 5)]);
      expect(ps.first.endDate, d(2026, 9, 27), reason: 'no split: one rule per period');
    });

    test('daily → quota switch clips the first quota week at the revision date', () {
      final s = periodService();
      final habit = buildHabit(schedule: RecurrenceRule.forQuota(3, PeriodUnit.week));
      final revs = [
        revision('r1', d(2026, 9, 1), schedule: RecurrenceRule()),
        revision('r2', d(2026, 9, 24), schedule: RecurrenceRule.forQuota(3, PeriodUnit.week)),
      ];
      final ps = s.periods(habit, revs, d(2026, 9, 21), d(2026, 9, 27));
      expect(ps.map((p) => p.key), ['2026-09-21', '2026-09-22', '2026-09-23', 'week:2026-09-21']);
      expect(ps.last.startDate, d(2026, 9, 24));
      expect(ps.last.eligibleDays, hasLength(4));
      expect(ps.last.fullEligibleDays, 7);
    });
  });

  group('slot periods (T5.1.09)', () {
    final times = RecurrenceRule(times: [LocalTime(8, 0), LocalTime(14, 0), LocalTime(20, 0)]);

    test('fixed times: keys, windows with early tolerance, check-now targeting', () {
      final s = periodService();
      final habit = buildHabit(schedule: times);
      final ps = s.periods(habit, const [], d(2026, 9, 22), d(2026, 9, 22));
      expect(ps.map((p) => p.key), ['2026-09-22T08:00', '2026-09-22T14:00', '2026-09-22T20:00']);
      expect(ps.map((p) => p.windowStart.hour), [7, 13, 19]);
      expect(ps.map((p) => p.windowStart.minute), [30, 30, 30]);
      expect(ps.map((p) => p.windowEnd), [DateTime.utc(2026, 9, 22, 14), DateTime.utc(2026, 9, 22, 20), DateTime.utc(2026, 9, 23)]);
      PeriodKey? at(int h, int m) => s.periodForInstant(habit, const [], DateTime.utc(2026, 9, 22, h, m))?.key;
      expect(at(13, 40), '2026-09-22T14:00', reason: 'tapping at 13:40 (tolerance 30) targets 14:00');
      expect(at(13, 29), '2026-09-22T08:00');
      expect(at(7, 0), isNull);
      expect(at(8, 10), '2026-09-22T08:00');
      expect(at(23, 59), '2026-09-22T20:00');
      final noTolerance = buildHabit(schedule: times, settings: const HabitSettings(earlyToleranceMinutes: 0));
      expect(s.periodForInstant(noTolerance, const [], DateTime.utc(2026, 9, 22, 13, 40))?.key, '2026-09-22T08:00');
    });

    test('every hour 09:00–18:00 gives 10 slots; minutely windows stay under the engine cap', () {
      final s = periodService();
      final hourly = buildHabit(
        schedule: RecurrenceRule(
          freq: Frequency.hourly,
          window: DailyWindow(LocalTime(9, 0), LocalTime(18, 0)),
        ),
      );
      expect(s.periods(hourly, const [], d(2026, 9, 22), d(2026, 9, 22)), hasLength(10));
      expect(s.maxSlotsPerDay(hourly, const [], d(2026, 9, 22)), 10);
      final minutely = buildHabit(
        schedule: RecurrenceRule(freq: Frequency.minutely, window: DailyWindow(LocalTime(0, 0), LocalTime.endOfDay)),
      );
      expect(s.periods(minutely, const [], d(2026, 9, 20), d(2026, 9, 27)), hasLength(8 * 1440));
    });

    test('with dayStartsAt 04:00 a 02:00 slot belongs to the previous day', () {
      final s = periodService(dayStartMinutes: 240);
      final habit = buildHabit(schedule: RecurrenceRule(times: [LocalTime(2, 0), LocalTime(22, 0)]));
      final ps = s.periods(habit, const [], d(2026, 9, 22), d(2026, 9, 22));
      expect(ps.map((p) => p.key), ['2026-09-22T22:00', '2026-09-23T02:00']);
      expect(ps.every((p) => p.startDate == d(2026, 9, 22)), isTrue);
      expect(s.periodForKey(habit, const [], '2026-09-23T02:00')?.startDate, d(2026, 9, 22));
    });
  });

  group('lookups', () {
    test('periodForKey resolves day, slot and quota keys', () {
      final s = periodService();
      expect(s.periodForKey(buildHabit(), const [], '2026-09-22')?.kind, HabitPeriodKind.day);
      final quota = buildHabit(start: d(2026, 9, 2), schedule: RecurrenceRule.forQuota(3, PeriodUnit.week));
      final first = s.periodForKey(quota, const [], 'week:2026-08-31');
      expect(first?.startDate, d(2026, 9, 2), reason: 'clipped at the habit start, keyed by the full week');
      expect(s.periodForKey(buildHabit(), const [], 'nonsense'), isNull);
    });

    test('upcoming lists the next due periods (editor preview)', () {
      final s = periodService();
      final habit = buildHabit(schedule: RecurrenceRule(interval: 3));
      final next = s.upcoming(habit, const [], d(2026, 9, 22), count: 4);
      expect(next.map((p) => p.key), ['2026-09-22', '2026-09-25', '2026-09-28', '2026-10-01']);
    });

    test('periodForInstant agrees with periods for random instants (property)', () {
      final rng = Random(7);
      final s = periodService(zone: 'Europe/Paris', dayStartMinutes: 240);
      final habits = [
        buildHabit(start: d(2026, 1, 1)),
        buildHabit(start: d(2026, 1, 1), schedule: RecurrenceRule(times: [LocalTime(8, 0), LocalTime(14, 0), LocalTime(20, 0)])),
        buildHabit(start: d(2026, 1, 1), schedule: RecurrenceRule.forQuota(3, PeriodUnit.week)),
      ];
      final base = DateTime.utc(2026, 1, 2).millisecondsSinceEpoch;
      for (var i = 0; i < 3000; i++) {
        final instant = DateTime.fromMillisecondsSinceEpoch(base + rng.nextInt(360 * 1440) * 60000 + rng.nextInt(60000), isUtc: true);
        final habit = habits[i % habits.length];
        final p = s.periodForInstant(habit, const [], instant);
        final date = s.dateOf(habit, instant);
        final day = s.periods(habit, const [], date, date);
        if (p == null) {
          expect(day.where((q) => q.kind == HabitPeriodKind.slot && !q.windowStart.isAfter(instant)), isEmpty);
          continue;
        }
        expect(day.map((q) => q.key), contains(p.key));
        expect(!p.windowStart.isAfter(instant) && p.windowEnd.isAfter(instant), isTrue, reason: '${p.key} vs $instant');
      }
    });
  });
}

typedef PeriodKey = String;
