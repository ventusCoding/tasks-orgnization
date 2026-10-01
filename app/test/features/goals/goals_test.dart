import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../habits/support/habit_fixtures.dart';

void main() {
  Goal goal({
    GoalScopeType scope = GoalScopeType.habit,
    String? scopeId = 'h1',
    GoalMetric metric = GoalMetric.totalValue,
    double target = 10000,
    GoalPeriod period = GoalPeriod.year,
    LocalDate? start,
    LocalDate? end,
    String? title,
  }) => Goal(
    id: 'g1',
    scopeType: scope,
    scopeId: scopeId,
    metric: metric,
    target: target,
    period: period,
    startDate: start,
    endDate: end,
    title: title,
  );

  GoalValidationCode? codeOf(Goal g, {GoalHabitKind? kind}) {
    try {
      g.validate(habitKind: kind);
      return null;
    } on GoalValidationException catch (e) {
      return e.code;
    }
  }

  group('validation (T5.4.01)', () {
    test('metrics per scope and habit kind', () {
      expect(codeOf(goal(), kind: GoalHabitKind.measurable), isNull);
      expect(
        codeOf(goal(), kind: GoalHabitKind.yesNo),
        GoalValidationCode.metricNotAllowed,
        reason: 'totals need a measurable goal',
      );
      expect(codeOf(goal(metric: GoalMetric.moneySaved), kind: GoalHabitKind.quit), isNull);
      expect(
        codeOf(goal(metric: GoalMetric.moneySaved), kind: GoalHabitKind.measurable),
        GoalValidationCode.metricNotAllowed,
      );
      expect(
        codeOf(goal(scope: GoalScopeType.checklist, metric: GoalMetric.streakDays)),
        GoalValidationCode.metricNotAllowed,
      );
      expect(codeOf(goal(scope: GoalScopeType.checklist, metric: GoalMetric.itemsCompleted)), isNull);
      expect(codeOf(goal(scope: GoalScopeType.category, metric: GoalMetric.trackedMinutes)), isNull);
    });

    test('targets, custom periods, dates, scope ids and titles', () {
      expect(codeOf(goal(target: 0)), GoalValidationCode.targetNotPositive);
      expect(codeOf(goal(period: GoalPeriod.custom, start: d(2026, 9, 1))), GoalValidationCode.customPeriodNeedsDates);
      expect(
        codeOf(goal(period: GoalPeriod.custom, start: d(2026, 9, 10), end: d(2026, 9, 1))),
        GoalValidationCode.endBeforeStart,
      );
      expect(
        codeOf(goal(scope: GoalScopeType.global, metric: GoalMetric.completions)),
        GoalValidationCode.scopeIdMissing,
      );
      expect(codeOf(goal(scope: GoalScopeType.global, scopeId: null, metric: GoalMetric.completions)), isNull);
      expect(codeOf(goal(title: 'x' * 81)), GoalValidationCode.titleTooLong);
    });
  });

  group('windows', () {
    final asOf = d(2026, 9, 22); // a Tuesday
    ({LocalDate start, LocalDate? end}) w(Goal g, {Weekday weekStart = Weekday.monday}) =>
        g.window(asOf, weekStart: weekStart, origin: d(2026, 3, 1));

    test('calendar periods contain the date; a later start date clips them', () {
      expect(w(goal()), (start: d(2026, 1, 1), end: d(2026, 12, 31)));
      expect(w(goal(period: GoalPeriod.quarter)), (start: d(2026, 7, 1), end: d(2026, 9, 30)));
      expect(w(goal(period: GoalPeriod.month)), (start: d(2026, 9, 1), end: d(2026, 9, 30)));
      expect(w(goal(period: GoalPeriod.week)), (start: d(2026, 9, 21), end: d(2026, 9, 27)));
      expect(w(goal(period: GoalPeriod.week), weekStart: Weekday.sunday), (start: d(2026, 9, 20), end: d(2026, 9, 26)));
      expect(w(goal(start: d(2026, 6, 15))), (start: d(2026, 6, 15), end: d(2026, 12, 31)));
    });

    test('custom and all-time windows', () {
      expect(w(goal(period: GoalPeriod.custom, start: d(2026, 9, 1), end: d(2026, 10, 1))), (
        start: d(2026, 9, 1),
        end: d(2026, 10, 1),
      ));
      expect(w(goal(period: GoalPeriod.allTime)), (
        start: d(2026, 3, 1),
        end: null,
      ), reason: 'from the origin, open-ended');
    });
  });

  group('repository', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10)));
    tearDown(() => h.dispose());

    test('round-trips, watches by scope and records the achievement once', () async {
      final repo = h.read(goalsRepositoryProvider);
      final g = Goal(
        id: Ids.v7(),
        scopeType: GoalScopeType.habit,
        scopeId: 'habit-1',
        metric: GoalMetric.moneySaved,
        target: 120,
        period: GoalPeriod.allTime,
        title: ' Concert ticket ',
        reward: 'Concert ticket',
      );
      await repo.create(g);
      final stored = (await repo.byId(g.id))!;
      expect(stored.copyWith(), g.copyWith(title: 'Concert ticket'));
      expect(await repo.watchForScope(GoalScopeType.habit, 'habit-1').first, [stored]);
      expect(await repo.watchForScope(GoalScopeType.habit, 'other').first, isEmpty);

      final at = DateTime.utc(2026, 9, 21, 18);
      expect(await repo.markAchieved(g.id, at), isNotNull);
      expect(await repo.markAchieved(g.id, DateTime.utc(2026, 9, 22, 9)), isNull, reason: 'set once');
      expect((await repo.byId(g.id))!.achievedAt, at);
      await repo.clearAchieved(g.id);
      expect((await repo.byId(g.id))!.isAchieved, isFalse);
    });

    test('deleting a habit deletes its goals in the same operation', () async {
      final habit = buildHabit(id: Ids.v7(), start: d(2026, 9, 1));
      await h.read(habitsRepositoryProvider).create(habit);
      final g = goal(scopeId: habit.id);
      await h
          .read(goalsRepositoryProvider)
          .create(
            Goal(
              id: Ids.v7(),
              scopeType: g.scopeType,
              scopeId: g.scopeId,
              metric: GoalMetric.completions,
              target: 30,
              period: GoalPeriod.month,
            ),
          );
      await h.read(habitsRepositoryProvider).delete(habit.id);
      expect(await h.read(goalsRepositoryProvider).all(), isEmpty);
    });
  });
}
