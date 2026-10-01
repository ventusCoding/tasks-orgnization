import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/application/view_config/horizon_actions.dart';
import 'package:everslot/features/planner/domain/horizons.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/planner_harness.dart';

// Horizons (T3.7.11). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);
  final wed = LocalDate(2026, 9, 23);

  test('period keys per horizon; past periods are carried over', () {
    expect(Horizon.day.keyFor(wed, Weekday.monday), 'day:2026-09-23');
    expect(Horizon.week.keyFor(wed, Weekday.monday), 'week:2026-09-21');
    expect(Horizon.week.keyFor(wed, Weekday.sunday), 'week:2026-09-20');
    expect(Horizon.month.keyFor(wed, Weekday.monday), 'month:2026-09');
    expect(Horizon.quarter.keyFor(wed, Weekday.monday), 'quarter:2026-Q3');
    expect(Horizon.year.keyFor(wed, Weekday.monday), 'year:2026');
    expect(Horizon.of('quarter:2026-Q3'), Horizon.quarter);
    expect(Horizon.of('nope'), isNull);
    expect(horizonIsPast('week:2026-09-14', wed, Weekday.monday), isTrue);
    expect(horizonIsPast('month:2026-09', wed, Weekday.monday), isFalse);
    expect(horizonIsPast('year:2027', wed, Weekday.monday), isFalse);
  });

  Future<PlannerHarness> pump(WidgetTester tester) async {
    final h = PlannerHarness.create(realData: true);
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      final a = h.read(horizonActionsProvider);
      await a.create('Plan trip', 'week:2026-09-21');
      await a.create('Read 2 books', 'month:2026-09');
      await a.create('Learn piano', 'year:2026');
    });
    await pumpPlanner(tester, h, const PlannerScreen(view: 'horizons'), size: const Size(1400, 800));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    return h;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> drag(WidgetTester tester, Finder from, Finder to) async {
    final gesture = await tester.startGesture(tester.getCenter(from));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump();
    await gesture.up();
    await settle(tester);
  }

  testWidgets('intentions sit in their horizon; dragging moves them to another horizon', (tester) async {
    final h = await pump(tester);
    expect(
      find.descendant(of: find.byKey(const ValueKey('horizon-week')), matching: find.text('Plan trip')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('horizon-year')), matching: find.text('Learn piano')),
      findsOneWidget,
    );
    await drag(tester, find.text('Plan trip'), find.byKey(const ValueKey('horizon-month')));
    late List<String?> keys;
    await tester.runAsync(() async {
      keys = [for (final t in await h.read(plannerServiceProvider).queries.unscheduled()) t.horizonKey];
    });
    expect(keys.where((k) => k == 'month:2026-09'), hasLength(2));
    expect(
      find.descendant(of: find.byKey(const ValueKey('horizon-month')), matching: find.text('Plan trip')),
      findsOneWidget,
    );
  });

  testWidgets('dropping on a day schedules it into a free slot; Make it a goal links a goal', (tester) async {
    final h = await pump(tester);
    await drag(tester, find.text('Plan trip'), find.byKey(const ValueKey('horizon-day-2026-09-24')));
    late List<String> unscheduled;
    await tester.runAsync(() async {
      unscheduled = [for (final t in await h.read(plannerServiceProvider).queries.unscheduled()) t.title];
    });
    expect(unscheduled, isNot(contains('Plan trip')));
    expect(find.text('Plan trip'), findsNothing);

    await tester.tap(find.byTooltip('Make it a goal').first);
    await settle(tester);
    late List<Goal> goals;
    await tester.runAsync(() async => goals = await h.read(goalsRepositoryProvider).watchAll().first);
    expect(goals.single.scopeType, GoalScopeType.series);
    expect(goals.single.metric, GoalMetric.completions);
  });
}
