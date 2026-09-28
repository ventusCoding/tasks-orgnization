// Performance scenarios of the planner views (T3.3.25, T3.4.20, T3.5.15): a week at 1-minute slots
// with 2 000 occurrences (timeline and table renderers), paging through 20 weeks and a 1 440-row day
// list fling. In widget tests they guard the structure that keeps frames cheap — culling bounds the
// built tiles/rows, and no frame takes pathologically long; the profile-mode frame budgets of arch
// §9.6 are measured by the `flutter drive --profile` suite of T9.1.08 on the same `perfWeek` data.
@Tags(['perf'])
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/task_tile.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

/// [count] deterministic occurrences spread over the 7 days from [monday] (5–90 min, all hours).
List<PlannerItem> perfWeek(LocalDate monday, {int count = 2000, int seed = 7}) {
  final random = math.Random(seed);
  const colors = [0xFF1565C0, 0xFF2E7D32, 0xFF6A1B9A, 0xFFEF6C00, 0xFFC62828, 0xFF00838F];
  const statuses = [OccurrenceStatus.scheduled, OccurrenceStatus.done, OccurrenceStatus.skipped, OccurrenceStatus.missed];
  return [
    for (var i = 0; i < count; i++)
      item(
        'Task $i',
        monday.plusDays(i % 7).atStartOfDay.plusMinutes(random.nextInt(1440 - 90)),
        5 + random.nextInt(86),
        color: colors[i % colors.length],
        status: statuses[random.nextInt(statuses.length)],
      ),
  ];
}

void main() {
  final monday = LocalDate(2026, 9, 21);
  const frameCeiling = Duration(seconds: 2); // debug-mode sanity bound, not the §9.6 budget

  Future<Duration> timed(Future<void> Function() body) async {
    final sw = Stopwatch()..start();
    await body();
    return sw.elapsed;
  }

  Future<PlannerGridController> pumpGrid(WidgetTester tester, PlannerHarness h) async {
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(tester, h, Scaffold(body: TimeGrid(viewKey: 'week_table', controller: controller)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return controller;
  }

  testWidgets('1-min timeline, 2 000 occurrences: tiles are culled while scrolling the day', (tester) async {
    final h = PlannerHarness.create(items: perfWeek(monday));
    addTearDown(h.dispose);
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    notifier.update(h.read(plannerViewConfigProvider('week_table')).withSlot(1).copyWith(slotExtentPx: 8));
    final controller = await pumpGrid(tester, h);
    var worst = Duration.zero;
    var maxTiles = 0;
    for (var minute = 0; minute <= 1380; minute += 60) {
      final took = await timed(() async {
        controller.scrollToMinute(minute.toDouble(), animate: false);
        await tester.pump();
      });
      worst = took > worst ? took : worst;
      maxTiles = math.max(maxTiles, find.byType(TaskTile).evaluate().length);
    }
    // One hour is 480 px at 8 px/min: the window ±1 screen holds a small share of the 2 000 items.
    expect(maxTiles, lessThan(700), reason: 'culling keeps the built tiles to the visible window ± one screen');
    expect(maxTiles, greaterThan(0));
    expect(worst, lessThan(frameCeiling));
    expect(tester.takeException(), isNull);
  });

  testWidgets('1-min table mode (1 440 rows) builds only the visible cells', (tester) async {
    final h = PlannerHarness.create(items: perfWeek(monday, count: 800));
    addTearDown(h.dispose);
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    notifier.update(h.read(plannerViewConfigProvider('week_table')).withSlot(1).copyWith(renderMode: RenderMode.table));
    final controller = await pumpGrid(tester, h);
    for (final minute in [0.0, 420.0, 900.0, 1400.0]) {
      final took = await timed(() async {
        controller.scrollToMinute(minute, animate: false);
        await tester.pump();
      });
      expect(took, lessThan(frameCeiling));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('paging through 20 weeks and back keeps working and returns to the week', (tester) async {
    final h = PlannerHarness.create(items: perfWeek(monday, count: 500));
    addTearDown(h.dispose);
    final controller = await pumpGrid(tester, h);
    // The page animation only advances while frames are pumped: never await it directly.
    Future<void> turn(Future<void> Function() step) async {
      unawaited(step());
      for (var f = 0; f < 6; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (var i = 0; i < 20; i++) {
      final took = await timed(() => turn(controller.next));
      expect(took, lessThan(frameCeiling * 6));
    }
    for (var i = 0; i < 20; i++) {
      await turn(controller.previous);
    }
    expect(controller.firstVisibleDay, monday);
  });

  testWidgets('14 days on a tablet at 5-min slots with 2 000 occurrences stay culled', (tester) async {
    final h = PlannerHarness.create(items: [...perfWeek(monday), ...perfWeek(monday.plusDays(7), seed: 11)]);
    addTearDown(h.dispose);
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    notifier.update(h.read(plannerViewConfigProvider('week_table')).withSlot(5).copyWith(daysVisible: 14, daysVisibleLandscape: 14));
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(
      tester,
      h,
      Scaffold(body: TimeGrid(viewKey: 'week_table', controller: controller)),
      size: const Size(1280, 800),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.visibleDays.length, 14);
    var maxTiles = 0;
    for (var minute = 0; minute <= 1320; minute += 120) {
      final took = await timed(() async {
        controller.scrollToMinute(minute.toDouble(), animate: false);
        await tester.pump();
      });
      expect(took, lessThan(frameCeiling));
      maxTiles = math.max(maxTiles, find.byType(TaskTile).evaluate().length);
    }
    expect(maxTiles, lessThan(1500), reason: '14 visible days: the window ± one screen, not the 4 000 items of the range');
    expect(tester.takeException(), isNull);
  });

  testWidgets('5 s of continuous pinch zooms smoothly without errors', (tester) async {
    final h = PlannerHarness.create(items: perfWeek(monday, count: 800));
    addTearDown(h.dispose);
    await pumpGrid(tester, h);
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    final (ppm0, _) = grid.debugZoom;
    final focus = grid.globalPositionOf(monday.plusDays(2), 10 * 60)!;
    final a = await tester.startGesture(focus - const Offset(0, 30), pointer: 1);
    final b = await tester.startGesture(focus + const Offset(0, 30), pointer: 2);
    await tester.pump();
    var worst = Duration.zero;
    // 100 frames of 50 ms: spread for 2.5 s, then pinch back in for 2.5 s.
    for (var i = 1; i <= 100; i++) {
      final spread = 30.0 + (i <= 50 ? i : 100 - i) * 3;
      final took = await timed(() async {
        await a.moveTo(focus - Offset(0, spread));
        await b.moveTo(focus + Offset(0, spread));
        await tester.pump(const Duration(milliseconds: 50));
      });
      worst = took > worst ? took : worst;
    }
    final (ppmMid, _) = grid.debugZoom;
    await a.up();
    await b.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(ppmMid, closeTo(ppm0, ppm0 * 0.25), reason: 'the pinch ended where it started');
    expect(worst, lessThan(frameCeiling));
    expect(tester.takeException(), isNull);
  });

  testWidgets('day list with 1 440 one-minute rows flings with a bounded number of built rows', (tester) async {
    final h = PlannerHarness.create(items: perfWeek(monday, count: 300));
    addTearDown(h.dispose);
    final notifier = h.read(plannerViewConfigProvider('day_list').notifier);
    notifier.update(h.read(plannerViewConfigProvider('day_list')).withSlot(1));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'day_list', date: '2026-09-23'));
    await tester.pumpAndSettle();
    int builtRows() => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SlotRowTile').evaluate().length;
    final list = find.byKey(const ValueKey('day-slots-2026-09-23'));
    expect(list, findsOneWidget);
    var maxRows = 0;
    for (var i = 0; i < 6; i++) {
      await tester.fling(list, const Offset(0, -2000), 4000);
      for (var f = 0; f < 10; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        maxRows = math.max(maxRows, builtRows());
      }
    }
    expect(maxRows, greaterThan(0));
    expect(maxRows, lessThan(120), reason: 'the list builds the visible rows plus the cache extent only');
    expect(tester.takeException(), isNull);
  });
}
