import 'package:decimal/decimal.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:test/test.dart';

import '../support/habit_fixtures.dart';

void main() {
  final service = periodService(zone: 'Europe/Paris');
  // Quit on Tuesday 2026-09-15 at 00:00 Paris; now = Tuesday 2026-09-22 12:00 Paris → 7 closed days.
  QuitHabit tracker({required bool autoSuccess}) => QuitHabit(
    id: 'q1',
    name: 'Stop smoking',
    startDate: d(2026, 9, 15),
    sortKey: 'a0',
    mode: QuitMode.abstain,
    quitStartedAt: DateTime.utc(2026, 9, 14, 22),
    substance: QuitSubstance.cigarettes,
    baselinePerDay: 10,
    unitCost: Decimal.parse('0.5'),
    currency: 'EUR',
    autoSuccess: autoSuccess,
  );
  final now = DateTime.utc(2026, 9, 22, 10);
  HabitLogEntry entry(HabitLogKind kind, LocalDateLike day, {double? value, String id = 'l'}) => HabitLogEntry(
    id: '$id-${day.iso}',
    habitId: 'q1',
    kind: kind,
    loggedAt: DateTime.utc(2026, 9, day.day, 18),
    localDate: d(2026, 9, day.day),
    occurrenceKey: kind == HabitLogKind.clean ? day.iso : null,
    value: value,
  );
  final logs = [
    entry(HabitLogKind.clean, const LocalDateLike(16)),
    entry(HabitLogKind.clean, const LocalDateLike(17)),
    entry(HabitLogKind.relapse, const LocalDateLike(18), value: 2),
  ];

  group('daily status rules (T5.3.09)', () {
    test('auto-success counts closed days without a relapse as clean', () {
      final t = tracker(autoSuccess: true);
      final calc = quitCalculatorOf(t, revisions: const [], logs: logs, days: service.boundariesOf(t), now: now);
      expect(calc.closedDays, hasLength(7));
      expect(calc.cleanDays, 6, reason: 'every closed day but the relapse day');
      expect(calc.unknownDays, 0);
    });

    test('explicit mode needs a clean log; other days stay unknown, never a relapse', () {
      final t = tracker(autoSuccess: false);
      final calc = quitCalculatorOf(t, revisions: const [], logs: logs, days: service.boundariesOf(t), now: now);
      expect(calc.cleanDays, 2);
      expect(calc.unknownDays, 4);
      expect(calc.closedDays.length - calc.cleanDays - calc.unknownDays, 1, reason: 'only the relapse day is a lapse');
    });

    test('switching the setting re-evaluates history from the same logs', () {
      final auto = tracker(autoSuccess: true);
      final explicit = tracker(autoSuccess: false);
      final a = quitCalculatorOf(auto, revisions: const [], logs: logs, days: service.boundariesOf(auto), now: now);
      final e = quitCalculatorOf(explicit, revisions: const [], logs: logs, days: service.boundariesOf(explicit), now: now);
      expect(a.cleanDays, e.cleanDays + e.unknownDays);
      // Money and streaks do not depend on the confirmation mode.
      expect(a.moneySaved, e.moneySaved);
      expect(a.currentAbstinence, e.currentAbstinence);
    });
  });

  test('pledge streak counts consecutive pledged days up to today (T5.3.13)', () {
    HabitLogEntry pledge(int day) => HabitLogEntry(
      id: 'p$day',
      habitId: 'q1',
      kind: HabitLogKind.pledge,
      loggedAt: DateTime.utc(2026, 9, day, 7),
      localDate: d(2026, 9, day),
      occurrenceKey: '2026-09-$day',
    );
    final pledges = [pledge(19), pledge(20), pledge(21)];
    expect(pledgeStreak(pledges, 'q1', d(2026, 9, 22)), 3, reason: 'today not pledged yet');
    expect(pledgeStreak([...pledges, pledge(22)], 'q1', d(2026, 9, 22)), 4);
    expect(pledgeStreak([pledge(19), pledge(21)], 'q1', d(2026, 9, 22)), 1);
  });
}

/// Tiny helper for day-of-September-2026 fixtures.
class LocalDateLike {
  const LocalDateLike(this.day);

  final int day;

  String get iso => '2026-09-${day.toString().padLeft(2, '0')}';
}
