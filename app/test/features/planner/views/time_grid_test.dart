import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Clock: Wed 23 Sep 2026 09:30 UTC (zone UTC) → the current week is Mon 21 – Sun 27.
final _mon = LocalDate(2026, 9, 21);
final _wed = LocalDate(2026, 9, 23);

Future<(PlannerHarness, PlannerGridController)> _pump(
  WidgetTester tester, {
  List<PlannerItem> items = const [],
  PlannerViewConfig Function(PlannerViewConfig c)? config,
  Locale locale = const Locale('en'),
}) async {
  final h = PlannerHarness.create(items: items);
  addTearDown(h.dispose);
  if (config != null) {
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    notifier.update(config(h.read(plannerViewConfigProvider('week_table'))));
  }
  final controller = PlannerGridController();
  addTearDown(controller.dispose);
  await pumpPlanner(tester, h, Scaffold(body: TimeGrid(viewKey: 'week_table', controller: controller)), locale: locale);
  await tester.pumpAndSettle();
  return (h, controller);
}

TimeGridState _grid(WidgetTester tester) => tester.state<TimeGridState>(find.byType(TimeGrid));

void main() {
  testWidgets('week table: 7 day columns of the current week, scrolled to now', (tester) async {
    final (h, controller) = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    expect(controller.visibleDays, [for (var i = 0; i < 7; i++) _mon.plusDays(i)]);
    expect(find.text('Gym'), findsOneWidget);
    final (ppm, topMinute) = _grid(tester).debugZoom;
    expect(ppm, closeTo(1.6, 1e-9)); // 48 px per 30-min row
    // Now (09:30) sits in the upper third of the body.
    expect(topMinute, lessThan(9 * 60 + 30));
    expect(topMinute, greaterThan(5 * 60));
    expect(h.backend.resolved.map((r) => r.start), contains(_mon));
  });

  testWidgets('tapping a tile opens it; tapping its check area marks it done', (tester) async {
    final gym = item('Gym', at(2026, 9, 21, 7), 60, id: 'gym');
    final (h, _) = await _pump(tester, items: [gym]);
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(h.nav.log, ['task gym ${gym.occurrenceKey}']);

    final grid = _grid(tester);
    final center = grid.globalPositionOf(_mon, 7 * 60 + 30)!;
    final colLeft = center.dx - 26; // phone week columns are ~53 px wide
    await tester.tapAt(Offset(colLeft + 8, center.dy));
    await tester.pumpAndSettle();
    expect(h.backend.calls.last, 'status Gym done');
  });

  testWidgets('tap on an empty slot quick-creates at the slot start with the slot duration', (tester) async {
    final (h, _) = await _pump(tester);
    final p = _grid(tester).globalPositionOf(_wed, 14 * 60 + 10)!;
    await tester.tapAt(p);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Dentist');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['create 2026-09-23T14:00 30 Dentist']);
  });

  testWidgets('long-press + drag on empty space creates a snapped range', (tester) async {
    final (h, _) = await _pump(tester);
    final grid = _grid(tester);
    final start = grid.globalPositionOf(_wed, 10 * 60 + 5)!;
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    final end = grid.globalPositionOf(_wed, 11 * 60 + 32)!;
    await gesture.moveTo(end);
    await tester.pump();
    expect(find.byKey(const Key('time-bubble')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Focus');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    // 10:00 (slot floor) → 11:30 (snap 15).
    expect(h.backend.calls, ['create 2026-09-23T10:00 90 Focus']);
  });

  testWidgets('long-press a tile and drag: moves it to another day and time (one undoable command)', (tester) async {
    final (h, _) = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    final grid = _grid(tester);
    final from = grid.globalPositionOf(_mon, 7 * 60 + 30)!;
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(grid.globalPositionOf(_wed, 10 * 60 + 47)!);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // Grabbed 30 min into the tile: 10:47 − 30 → 10:17 → snapped to 10:15.
    expect(h.backend.calls, ['reschedule Gym 2026-09-23T10:15 60 thisOccurrence']);
    expect(find.text('Undo'), findsNothing); // the fake backend has no undo stack; demo/real modes do
  });

  testWidgets('long-press release without moving selects the tile and opens the quick menu', (tester) async {
    final (h, _) = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    final grid = _grid(tester);
    final gesture = await tester.startGesture(grid.globalPositionOf(_mon, 7 * 60 + 30)!);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Mark done'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['status Gym skipped']);
  });

  testWidgets('resizing the bottom edge keeps the start and snaps the end', (tester) async {
    final (h, _) = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    final grid = _grid(tester);
    final edge = grid.globalPositionOf(_mon, 7 * 60 + 58)!;
    final gesture = await tester.startGesture(edge);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(grid.globalPositionOf(_mon, 9 * 60 + 2)!);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['reschedule Gym 2026-09-21T07:00 120 thisOccurrence']);
  });

  testWidgets('dragging a timed tile into the all-day lane makes it all-day', (tester) async {
    final (h, _) = await _pump(tester, items: [item('Trip', at(2026, 9, 22, 0), 1440, allDay: true), item('Gym', at(2026, 9, 21, 7), 60)]);
    final grid = _grid(tester);
    final gesture = await tester.startGesture(grid.globalPositionOf(_mon, 7 * 60 + 30)!);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(grid.globalHeaderOf(_wed, lane: true)!);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['reschedule Gym 2026-09-23T00:00 1440 allDay=true thisOccurrence']);
  });

  testWidgets('swiping pages whole weeks; 52 weeks forward and back returns to the same week', (tester) async {
    final (_, controller) = await _pump(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(controller.firstVisibleDay, LocalDate(2026, 9, 28));
    await controller.jumpTo(LocalDate(2027, 9, 22), animate: false);
    await tester.pumpAndSettle();
    expect(controller.firstVisibleDay, LocalDate(2027, 9, 20));
    await controller.jumpTo(_wed, animate: false);
    await tester.pumpAndSettle();
    expect(controller.firstVisibleDay, _mon);
  });

  testWidgets('a Saturday week start pages Sat–Fri weeks', (tester) async {
    final (_, controller) = await _pump(tester, config: (c) => c.copyWith(firstDay: 'SA'));
    expect(controller.firstVisibleDay, LocalDate(2026, 9, 19));
    expect(controller.visibleDays.last, LocalDate(2026, 9, 25));
  });

  testWidgets('hide weekends shows a 5-day week', (tester) async {
    final (_, controller) = await _pump(tester, config: (c) => c.copyWith(showWeekends: false));
    expect(controller.visibleDays, [for (var i = 0; i < 5; i++) _mon.plusDays(i)]);
  });

  testWidgets('2-hour slots render the bucketed table with start times', (tester) async {
    await _pump(tester, items: [item('Gym', at(2026, 9, 21, 9, 15), 135)], config: (c) => c.withSlot(120));
    expect(find.text('09:15 Gym'), findsOneWidget); // chip in 08:00–10:00
    expect(find.text('Gym'), findsOneWidget); // continuation in 10:00–12:00
  });

  testWidgets('24-hour slots turn the week into seven lists', (tester) async {
    await _pump(
      tester,
      items: [item('Gym', at(2026, 9, 21, 7), 60), item('Birthday', at(2026, 9, 21, 0), 1440, allDay: true)],
      config: (c) => c.withSlot(1440),
    );
    expect(find.text('All day · Birthday'), findsOneWidget);
    expect(find.text('07:00 · Gym'), findsOneWidget);
    final birthday = tester.getTopLeft(find.text('All day · Birthday'));
    final gym = tester.getTopLeft(find.text('07:00 · Gym'));
    expect(birthday.dy, lessThan(gym.dy), reason: 'all-day items come first');
  });

  testWidgets('RTL puts the ruler on the right and mirrors the columns', (tester) async {
    await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)], locale: const Locale('ar'));
    final grid = _grid(tester);
    final mon = grid.globalPositionOf(_mon, 600)!;
    final sun = grid.globalPositionOf(LocalDate(2026, 9, 27), 600)!;
    expect(mon.dx, greaterThan(sun.dx), reason: 'Monday is at the reading start (right) in RTL');
    expect(tester.getCenter(find.text('Gym')).dx, closeTo(mon.dx, 30));
  });

  testWidgets('vertical pinch zooms around the focal time (fixed slot keeps the slot size)', (tester) async {
    final (h, _) = await _pump(tester);
    final grid = _grid(tester);
    final (ppm0, _) = grid.debugZoom;
    final focus = grid.globalPositionOf(_wed, 10 * 60)!;
    final a = await tester.startGesture(focus - const Offset(0, 40), pointer: 1);
    final b = await tester.startGesture(focus + const Offset(0, 40), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(focus - Offset(0, 40.0 + i * 8));
      await b.moveTo(focus + Offset(0, 40.0 + i * 8));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    final (ppm1, _) = grid.debugZoom;
    expect(ppm1, greaterThan(ppm0 * 1.5));
    expect(h.read(plannerViewConfigProvider('week_table')).slotMinutes, 30);
    final after = grid.globalPositionOf(_wed, 10 * 60)!;
    expect(after.dy, closeTo(focus.dy, 6), reason: '10:00 stays under the fingers');
    expect(h.read(plannerViewStateProvider('week_table'))!.pxPerMinute, closeTo(ppm1, 1e-6));
  });

  testWidgets('semantic pinch walks the slot presets', (tester) async {
    final (h, _) = await _pump(tester, config: (c) => c.copyWith(zoomMode: ZoomMode.semantic));
    final grid = _grid(tester);
    final focus = grid.globalPositionOf(_wed, 9 * 60)!;
    final a = await tester.startGesture(focus - const Offset(0, 30), pointer: 1);
    final b = await tester.startGesture(focus + const Offset(0, 30), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 16; i++) {
      await a.moveTo(focus - Offset(0, 30.0 + i * 14));
      await b.moveTo(focus + Offset(0, 30.0 + i * 14));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    final slot = h.read(plannerViewConfigProvider('week_table')).slotMinutes;
    expect(slot, lessThan(30));
    final after = grid.globalPositionOf(_wed, 9 * 60)!;
    expect(after.dy, closeTo(focus.dy, 8), reason: '09:00 stays under the fingers');
  });

  testWidgets('horizontal pinch changes the number of visible days', (tester) async {
    final (h, controller) = await _pump(tester);
    final grid = _grid(tester);
    final focus = grid.globalPositionOf(_wed, 12 * 60)!;
    final a = await tester.startGesture(focus - const Offset(40, 0), pointer: 1);
    final b = await tester.startGesture(focus + const Offset(40, 0), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 8; i++) {
      await a.moveTo(focus - Offset(40.0 + i * 12, 0));
      await b.moveTo(focus + Offset(40.0 + i * 12, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(controller.visibleDays.length, lessThan(7));
    expect(h.read(plannerViewStateProvider('week_table'))!.daysPortrait, controller.visibleDays.length);
  });

  testWidgets('the view state restores week and time after a restart', (tester) async {
    final h = PlannerHarness.create();
    addTearDown(h.dispose);
    await h.read(plannerViewStateProvider('week_table').notifier).ready;
    h.read(plannerViewStateProvider('week_table').notifier).update((s) => s.copyWith(anchor: LocalDate(2026, 10, 14), scrollMinute: 12 * 60));
    await h.read(plannerViewStateProvider('week_table').notifier).flush();
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(tester, h, Scaffold(body: TimeGrid(viewKey: 'week_table', controller: controller)));
    await tester.pumpAndSettle();
    expect(controller.firstVisibleDay, LocalDate(2026, 10, 12));
    expect(_grid(tester).debugZoom.$2, closeTo(12 * 60, 1));
  });

  testWidgets('tapping a day header opens its day list', (tester) async {
    final (h, _) = await _pump(tester);
    await tester.tapAt(_grid(tester).globalHeaderOf(_wed)!);
    await tester.pumpAndSettle();
    expect(h.nav.log, ['view day_list 2026-09-23']);
  });

  testWidgets('five overlapping items on a phone show two lanes and a "+N" chip', (tester) async {
    final (h, _) = await _pump(tester, items: [for (var i = 0; i < 5; i++) item('T$i', at(2026, 9, 23, 10), 60)]);
    expect(find.text('+3'), findsOneWidget);
    await tester.tap(find.text('+3'));
    await tester.pumpAndSettle();
    expect(find.text('3 items'), findsOneWidget);
    await tester.tap(find.text('Open day'));
    await tester.pumpAndSettle();
    expect(h.nav.log, ['view day_list 2026-09-23']);
  });
}
