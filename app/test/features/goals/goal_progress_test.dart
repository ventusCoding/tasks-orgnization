import 'package:decimal/decimal.dart';
import 'package:everslot/features/goals/application/goal_progress.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show GoalStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../habits/support/habit_fixtures.dart';

void main() {
  final service = periodService();
  // Tuesday 2026-09-22 10:00 UTC; September goals span 30 days, 22 of them elapsed.
  final now = DateTime.utc(2026, 9, 22, 10);

  HabitLogEntry progress(LocalDate day, double value) => HabitLogEntry(
    id: 'p-${day.toIso()}',
    habitId: 'h1',
    kind: HabitLogKind.progress,
    loggedAt: DateTime.utc(day.year, day.month, day.day, 9),
    localDate: day,
    occurrenceKey: day.toIso(),
    value: value,
  );

  HabitLogEntry done(LocalDate day) => HabitLogEntry(
    id: 'd-${day.toIso()}',
    habitId: 'h1',
    kind: HabitLogKind.done,
    loggedAt: DateTime.utc(day.year, day.month, day.day, 9),
    localDate: day,
    occurrenceKey: day.toIso(),
  );

  List<LocalDate> days(int from, int to) => [for (var i = from; i <= to; i++) d(2026, 9, i)];

  final pushUps = buildHabit(start: d(2026, 9, 1), goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'));
  final yesNo = buildHabit(start: d(2026, 9, 1));

  GoalEvaluation eval(Goal goal, Habit habit, List<HabitLogEntry> logs) =>
      evaluateHabitGoal(goal, computeSnapshot(service, habit, const [], logs, const [], now), weekStart: Weekday.monday);

  Goal goal(GoalMetric metric, double target, {GoalPeriod period = GoalPeriod.month, LocalDate? start, LocalDate? end}) => Goal(
    id: 'g',
    scopeType: GoalScopeType.habit,
    scopeId: 'h1',
    metric: metric,
    target: target,
    period: period,
    startDate: start,
    endDate: end,
  );

  group('habit goals (T5.4.03)', () {
    test('steady: 20 push-ups a day is exactly on pace for 600 in September', () {
      final e = eval(goal(GoalMetric.totalValue, 600), pushUps, [for (final day in days(1, 22)) progress(day, 20)]);
      expect((e.start, e.end, e.openEnded), (d(2026, 9, 1), d(2026, 9, 30), false));
      expect(e.progress.actual, 440);
      expect(e.progress.pace, closeTo(440, 1e-9));
      expect(e.progress.status, GoalStatus.onTrack);
      expect(e.progress.requiredDailyRate, 20);
    });

    test('stalled: five days then nothing is at risk with a distant ETA', () {
      final e = eval(goal(GoalMetric.totalValue, 600), pushUps, [for (final day in days(1, 5)) progress(day, 20)]);
      expect(e.progress.actual, 100);
      expect(e.progress.status, GoalStatus.atRisk);
      expect(e.progress.recentDailyRate, closeTo(100 / 28, 1e-9));
      expect(e.progress.eta, d(2026, 9, 22).plusDays((500 / (100 / 28)).ceil()));
    });

    test('achieved: completions reach the target on the tenth done day', () {
      final e = eval(goal(GoalMetric.completions, 10), yesNo, [for (final day in days(3, 14)) done(day)]);
      expect(e.achieved, isTrue);
      expect(e.progress.achievedOn, d(2026, 9, 12));
    });

    test('custom period counts only its own days and closes at its end', () {
      final e = eval(
        goal(GoalMetric.totalValue, 300, period: GoalPeriod.custom, start: d(2026, 9, 10), end: d(2026, 9, 20)),
        pushUps,
        [for (final day in days(1, 22)) progress(day, 20)],
      );
      expect(e.progress.actual, 220);
      expect(e.progress.remainingDays, 0);
      expect(e.progress.status, GoalStatus.atRisk, reason: 'missed and no time left');
    });

    test('streak goals use the current streak as the level', () {
      final e = eval(goal(GoalMetric.streakDays, 7, period: GoalPeriod.allTime), yesNo, [for (final day in days(18, 22)) done(day)]);
      expect(e.openEnded, isTrue);
      expect(e.progress.actual, 5);
      expect(e.progress.eta, d(2026, 9, 24));
    });
  });

  group('quit goals', () {
    final tracker = QuitHabit(
      id: 'h1',
      name: 'Stop smoking',
      startDate: d(2026, 9, 1),
      sortKey: 'a0',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 1),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 20,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
    );

    test('money saved (10 €/day) toward a 300 € reward', () {
      final e = eval(goal(GoalMetric.moneySaved, 300, period: GoalPeriod.allTime), tracker, const []);
      // 21 full days + 10 h of today.
      expect(e.progress.actual, closeTo(210 + 10 * 10 / 24, 1e-6));
      expect(e.openEnded, isTrue);
      expect(e.achieved, isFalse);
      expect(e.progress.eta, isNotNull);
    });

    test('clean days count closed clean days since the quit', () {
      final e = eval(goal(GoalMetric.cleanDays, 30, period: GoalPeriod.allTime), tracker, const []);
      expect(e.progress.actual, 21);
    });
  });
}
