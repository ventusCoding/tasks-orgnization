import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:flutter_test/flutter_test.dart';

import '../support/habit_fixtures.dart';

void main() {
  final service = periodService();
  // 30-day push-up challenge from Sept 1: 10 reps, +2 every 3 days, up to 16.
  final habit = buildHabit(
    start: d(2026, 9, 1),
    end: d(2026, 9, 30),
    goal: const HabitTarget(type: HabitGoalType.count, target: 10, unit: 'reps'),
    settings: HabitSettings.defaults.copyWith(
      challenge: const ChallengeSettings(),
      targetProgression: const TargetProgression(start: 10, step: 2, everyDays: 3, max: 16),
    ),
  );

  HabitLogEntry reps(int day, double value) => HabitLogEntry(
    id: 'p$day',
    habitId: 'h1',
    kind: HabitLogKind.progress,
    loggedAt: DateTime.utc(2026, 9, day, 9),
    localDate: d(2026, 9, day),
    occurrenceKey: d(2026, 9, day).toIso(),
    value: value,
  );

  test('the target grows by the step every N days and stops at the max (T5.4.07)', () {
    final e = computeSnapshot(service, habit, const [], const [], const [], DateTime.utc(2026, 9, 20, 10)).evaluation!;
    double target(int day) => e.dayOn(d(2026, 9, day))!.target;
    expect(
      [
        for (final day in [1, 3, 4, 6, 7, 10, 20]) target(day),
      ],
      [10, 10, 12, 12, 14, 16, 16],
    );
  });

  test('each day is evaluated against its own target', () {
    final e = computeSnapshot(
      service,
      habit,
      const [],
      [reps(2, 10), reps(4, 12), reps(7, 12)],
      const [],
      DateTime.utc(2026, 9, 20, 10),
    ).evaluation!;
    expect(e.dayOn(d(2026, 9, 2))!.status, PeriodStatus.done);
    expect(e.dayOn(d(2026, 9, 4))!.status, PeriodStatus.done);
    expect(e.dayOn(d(2026, 9, 7))!.status, PeriodStatus.partial, reason: '12 of 14');
  });

  test('progression JSON round-trips in the settings', () {
    final json = habit.settings.toJson();
    expect(HabitSettings.fromJson(json).targetProgression, habit.settings.targetProgression);
  });
}
