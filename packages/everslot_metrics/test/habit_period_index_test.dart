// The indexed matching of `evaluateHabitPeriods` (T6.1.23: O(P + L) instead of rescanning every log
// per period) must give exactly the results of evaluating each period on its own.
import 'dart:math' as math;

import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:test/test.dart';

void main() {
  final start = LocalDate(2026, 1, 1);
  final now = DateTime.utc(2026, 3, 20, 12);
  final today = LocalDate(2026, 3, 20);

  String iso(LocalDate d) => d.toIso();

  List<HabitPeriod> dayPeriods(int days, HabitGoal goal) => [
    for (var i = 0; i < days; i++)
      HabitPeriod(
        iso(start.plusDays(i)),
        kind: HabitPeriodKind.day,
        startDate: start.plusDays(i),
        endDate: start.plusDays(i),
        windowStart: DateTime.utc(2026, 1, 1 + i),
        windowEnd: DateTime.utc(2026, 1, 2 + i),
        goal: goal,
      ),
  ];

  List<HabitPeriod> slotPeriods(int days) => [
    for (var i = 0; i < days; i++)
      for (final hour in const [9, 13, 18])
        HabitPeriod(
          '${iso(start.plusDays(i))}T${hour.toString().padLeft(2, '0')}:00',
          kind: HabitPeriodKind.slot,
          startDate: start.plusDays(i),
          endDate: start.plusDays(i),
          windowStart: DateTime.utc(2026, 1, 1 + i, hour),
          windowEnd: DateTime.utc(2026, 1, 1 + i, hour + 3),
          matchStart: DateTime.utc(2026, 1, 1 + i, hour).subtract(const Duration(minutes: 30)),
          goal: const HabitGoal.check(),
        ),
  ];

  List<HabitPeriod> quotaPeriods(int weeks) => [
    for (var w = 0; w < weeks; w++)
      HabitPeriod(
        'week:${iso(start.plusDays(7 * w))}',
        kind: HabitPeriodKind.quota,
        startDate: start.plusDays(7 * w),
        endDate: start.plusDays(7 * w + 6),
        windowStart: DateTime.utc(2026, 1, 1 + 7 * w),
        windowEnd: DateTime.utc(2026, 1, 8 + 7 * w),
        goal: const HabitGoal.check(),
        quotaTimes: 3,
        fullEligibleDays: 7,
      ),
  ];

  /// Keyed, keyless and odd-keyed logs of every kind over ~11 weeks.
  List<HabitLog> logs(int seed) {
    final random = math.Random(seed);
    final kinds = [
      HabitLogKind.done,
      HabitLogKind.progress,
      HabitLogKind.progress,
      HabitLogKind.skip,
      HabitLogKind.fail,
      HabitLogKind.excuse,
    ];
    return [
      for (var n = 0; n < 400; n++)
        () {
          final day = start.plusDays(random.nextInt(78));
          final hour = 8 + random.nextInt(12);
          final at = DateTime.utc(day.year, day.month, day.day, hour, random.nextInt(60));
          final key = switch (random.nextInt(6)) {
            0 => null, // keyless: matched by local date / logged-at window
            1 => iso(day), // day key
            2 => '${iso(day)}T${(9 + 4 * random.nextInt(3)).toString().padLeft(2, '0')}:00', // slot key
            3 => '${iso(day)}T09:00',
            4 => 'week:${iso(day)}', // not date-prefixed: matches nothing but quota via localDate
            _ => iso(day),
          };
          return HabitLog(
            'l$n',
            kinds[random.nextInt(kinds.length)],
            loggedAt: at,
            localDate: day,
            value: random.nextInt(4).toDouble(),
            occurrenceKey: key,
            createdAt: at.add(Duration(minutes: random.nextInt(5))),
          );
        }(),
    ];
  }

  void expectSame(List<HabitPeriod> periods, List<HabitLog> all, {List<HabitPause> pauses = const []}) {
    final batch = evaluateHabitPeriods(periods, all, now: now, today: today, pauses: pauses, includeFuture: true);
    expect(batch, hasLength(periods.length));
    for (var i = 0; i < periods.length; i++) {
      final single = evaluateHabitPeriod(periods[i], all, now: now, today: today, pauses: pauses);
      final b = batch[i];
      final reason = 'period ${periods[i].key}';
      expect(b.status, single.status, reason: reason);
      expect(b.achieved, single.achieved, reason: reason);
      expect(b.target, single.target, reason: reason);
      expect([for (final e in b.entries) e.id], [for (final e in single.entries) e.id], reason: reason);
      expect(b.flags.activeDays, single.flags.activeDays, reason: reason);
      expect(b.flags.eligibleDays, single.flags.eligibleDays, reason: reason);
      expect(b.flags.inPause, single.flags.inPause, reason: reason);
    }
  }

  for (final seed in [1, 2, 3]) {
    test('day periods: indexed = per-period (seed $seed)', () {
      expectSame(dayPeriods(80, const HabitGoal.check()), logs(seed));
      expectSame(dayPeriods(80, const HabitGoal(HabitGoalType.count, target: 3)), logs(seed));
      expectSame(dayPeriods(80, const HabitGoal(HabitGoalType.count, target: 2, op: TargetOp.lte)), logs(seed));
    });

    test('slot periods: keyed and keyless logs (seed $seed)', () {
      expectSame(slotPeriods(40), logs(seed));
    });

    test('quota periods: weeks with pauses (seed $seed)', () {
      expectSame(
        quotaPeriods(11),
        logs(seed),
        pauses: [HabitPause(LocalDate(2026, 2, 9), end: LocalDate(2026, 2, 13))],
      );
    });
  }

  test('a fresh entries list per period: sorting one result never reorders another', () {
    final all = logs(9);
    final results = evaluateHabitPeriods(dayPeriods(30, const HabitGoal.check()), all, now: now, today: today);
    final again = evaluateHabitPeriods(dayPeriods(30, const HabitGoal.check()), all, now: now, today: today);
    for (var i = 0; i < results.length; i++) {
      expect([for (final e in results[i].entries) e.id], [for (final e in again[i].entries) e.id]);
    }
  });

  test('key dates parse like LocalDate.tryParse, including odd keys', () {
    // Odd or partial keys must fall back to the same result as the regex parser.
    final odd = [
      '2026-02-30T09:00',
      '2026-13-01',
      '2026-1-01T',
      'abcdefghij',
      '2026/02/01',
      '2026-02-01',
      '2026-02-01T09:00',
    ];
    for (final key in odd) {
      final period = HabitPeriod(
        'week:2026-01-26',
        kind: HabitPeriodKind.quota,
        startDate: LocalDate(2026, 1, 26),
        endDate: LocalDate(2026, 3, 1),
        windowStart: DateTime.utc(2026, 1, 26),
        windowEnd: DateTime.utc(2026, 3, 2),
        goal: const HabitGoal.check(),
        quotaTimes: 1,
        fullEligibleDays: 7,
      );
      final log = HabitLog(
        'x',
        HabitLogKind.done,
        loggedAt: DateTime.utc(2026, 2, 1, 9),
        localDate: LocalDate(2026, 2, 1),
        occurrenceKey: key,
      );
      final periods = [for (var i = 0; i < 9; i++) period];
      final logs17 = [for (var i = 0; i < 17; i++) log];
      final batch = evaluateHabitPeriods(periods, logs17, now: now, today: today, includeFuture: true);
      final single = evaluateHabitPeriod(period, logs17, now: now, today: today);
      expect(batch.first.status, single.status, reason: key);
      expect(batch.first.entries.length, single.entries.length, reason: key);
    }
  });
}
