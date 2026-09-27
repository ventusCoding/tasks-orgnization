import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodResult, PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/habit_fixtures.dart';

void main() {
  final service = periodService(zone: 'Europe/Paris');
  // Tuesday 2026-09-22, 12:00 in Paris.
  final noon = DateTime.utc(2026, 9, 22, 10);

  HabitLogEntry doneOn(String habitId, LocalDate day) => HabitLogEntry(
    id: '$habitId-${day.toIso()}',
    habitId: habitId,
    kind: HabitLogKind.done,
    loggedAt: DateTime.utc(day.year, day.month, day.day, 10),
    localDate: day,
    occurrenceKey: day.toIso(),
  );

  group('snapshot cache (T5.2.14)', () {
    test('the minute tick reuses the evaluation until the day ends', () {
      final cache = HabitSnapshotCache();
      final habit = buildHabit(start: d(2026, 9, 1));
      final logs = <HabitLogEntry>[];
      final first = cache.snapshot(service, habit, const [], logs, const [], noon);
      expect((cache.evaluations, cache.periodExpansions), (1, 1));
      final later = cache.snapshot(service, habit, const [], logs, const [], noon.add(const Duration(minutes: 1)));
      expect((cache.evaluations, cache.periodExpansions), (1, 1));
      expect(later.now, noon.add(const Duration(minutes: 1)));
      expect(identical(later.evaluation, first.evaluation), isTrue);
      // Midnight in Paris: a new day, a new evaluation (yesterday is now missed).
      final midnight = cache.snapshot(service, habit, const [], logs, const [], DateTime.utc(2026, 9, 22, 22));
      expect(cache.evaluations, 2);
      expect(midnight.today, d(2026, 9, 23));
      expect(midnight.evaluation!.dayOn(d(2026, 9, 22))!.status, PeriodStatus.missed);
    });

    test('a check-in re-evaluates without re-expanding periods; other habits are untouched', () {
      final cache = HabitSnapshotCache();
      final a = buildHabit(id: 'a', start: d(2026, 9, 1));
      final b = buildHabit(id: 'b', start: d(2026, 9, 1));
      final none = <HabitLogEntry>[];
      cache
        ..snapshot(service, a, const [], none, const [], noon)
        ..snapshot(service, b, const [], none, const [], noon);
      expect((cache.evaluations, cache.periodExpansions), (2, 2));
      final checked = cache.snapshot(service, a, const [], [doneOn('a', d(2026, 9, 22))], const [], noon);
      expect((cache.evaluations, cache.periodExpansions), (3, 2));
      expect(checked.todayResult!.status, PeriodStatus.done);
      cache.snapshot(service, b, const [], none, const [], noon.add(const Duration(minutes: 1)));
      expect(cache.evaluations, 3, reason: 'b did not change');
    });

    test('slot habits recompute when the next slot enters its early tolerance', () {
      final cache = HabitSnapshotCache();
      final habit = buildHabit(
        start: d(2026, 9, 1),
        schedule: SchedulePreset(
          SchedulePresetKind.specificTimes,
          times: [LocalTime(8, 0), LocalTime(14, 0)],
        ).toRule(weekStart: Weekday.monday),
      );
      final logs = <HabitLogEntry>[];
      // 13:00 and 13:29 Paris: still the 08:00 slot's window.
      final at13 = cache.snapshot(service, habit, const [], logs, const [], DateTime.utc(2026, 9, 22, 11));
      cache.snapshot(service, habit, const [], logs, const [], DateTime.utc(2026, 9, 22, 11, 29));
      expect(cache.evaluations, 1);
      // 13:30 Paris = 14:00 − 30 min tolerance: "check now" now targets the 14:00 slot.
      final at1330 = cache.snapshot(service, habit, const [], logs, const [], DateTime.utc(2026, 9, 22, 11, 30));
      expect(cache.evaluations, 2);
      expect(at13.currentPeriod!.key, isNot(at1330.currentPeriod!.key));
      expect(at1330.currentPeriod!.key, '2026-09-22T14:00');
    });

    test('cached snapshots equal fresh computations', () {
      final cache = HabitSnapshotCache();
      final habit = buildHabit(start: d(2026, 9, 1));
      final logs = [for (var day = 10; day <= 21; day++) doneOn(habit.id, d(2026, 9, day))];
      cache.snapshot(service, habit, const [], logs, const [], noon);
      final later = noon.add(const Duration(hours: 3));
      final cached = cache.snapshot(service, habit, const [], logs, const [], later);
      final fresh = computeSnapshot(service, habit, const [], logs, const [], later);
      expect(cache.evaluations, 1);
      PeriodResult? r(HabitSnapshot x) => x.todayResult;
      expect((r(cached)!.key, r(cached)!.status, r(cached)!.achieved), (r(fresh)!.key, r(fresh)!.status, r(fresh)!.achieved));
      expect(cached.summary!.currentStreak, fresh.summary!.currentStreak);
      expect(cached.summary!.bestStreak, fresh.summary!.bestStreak);
      expect(cached.currentPeriod!.key, fresh.currentPeriod!.key);
    });

    test('quit trackers are always recomputed', () {
      final cache = HabitSnapshotCache();
      final tracker = QuitHabit(
        id: 'q',
        name: 'Stop smoking',
        startDate: d(2026, 9, 1),
        sortKey: 'a0',
        mode: QuitMode.abstain,
        quitStartedAt: DateTime.utc(2026, 9, 1, 8),
        substance: QuitSubstance.cigarettes,
        baselinePerDay: 10,
      );
      cache
        ..snapshot(service, tracker, const [], const [], const [], noon)
        ..snapshot(service, tracker, const [], const [], const [], noon.add(const Duration(minutes: 1)));
      expect(cache.evaluations, 0, reason: 'not memoized');
    });
  });

  test('performance scenario: 50 habits × 5 years — cold build, then free ticks (T5.2.14)', () {
    final start = d(2021, 9, 22);
    final habits = <BuildHabit>[];
    final logs = <String, List<HabitLogEntry>>{};
    for (var i = 0; i < 50; i++) {
      final habit = buildHabit(id: 'h$i', start: start);
      habits.add(habit);
      logs[habit.id] = [
        for (var day = start, n = 0; day.isBefore(d(2026, 9, 22)); day = day.plusDays(1), n++)
          if (n % 10 < 7) doneOn(habit.id, day),
      ];
    }
    final cache = HabitSnapshotCache();
    final cold = Stopwatch()..start();
    for (final h in habits) {
      cache.snapshot(service, h, const [], logs[h.id]!, const [], noon);
    }
    cold.stop();
    final tick = Stopwatch()..start();
    for (final h in habits) {
      cache.snapshot(service, h, const [], logs[h.id]!, const [], noon.add(const Duration(minutes: 1)));
    }
    tick.stop();
    expect(cache.evaluations, 50, reason: 'the tick re-evaluates nothing');
    final checkIn = Stopwatch()..start();
    cache.snapshot(service, habits.first, const [], [...logs['h0']!, doneOn('h0', d(2026, 9, 22))], const [], noon);
    checkIn.stop();
    expect((cache.evaluations, cache.periodExpansions), (51, 50));
    // ignore: avoid_print
    print(
      'habits perf (debug JIT): cold ${cold.elapsedMilliseconds} ms, tick ${tick.elapsedMicroseconds} µs, '
      'check-in ${checkIn.elapsedMilliseconds} ms',
    );
  });
}
