import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/bulk_actions_sheet.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/task_tile.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/planner_selection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

// Keyboard, selection mode, copy / paste and screen-reader support of the grid (T3.3.24,
// T3.1.18 / T3.1.19 wiring). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  List<PlannerItem> week() => [
    item('Alpha', at(2026, 9, 21, 9), 60, id: 'a'),
    item('Bravo', at(2026, 9, 21, 11), 60, id: 'b'),
    item('Charlie', at(2026, 9, 22, 10), 60, id: 'c'),
  ];

  Future<(PlannerHarness, FakeViewActions)> pumpGrid(WidgetTester tester, {bool accessible = false}) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(items: week(), overrides: [viewExtraActionsProvider.overrideWithValue(extra)]);
    addTearDown(h.dispose);
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(
      tester,
      h,
      Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: accessible),
            child: TimeGrid(viewKey: 'week_table', controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.scrollToMinute(8 * 60, animate: false);
    await tester.pumpAndSettle();
    return (h, extra);
  }

  bool selected(WidgetTester tester, String title) =>
      tester.widgetList<TaskTile>(find.byType(TaskTile)).any((t) => t.item.title == title && t.selected);

  Future<void> key(WidgetTester tester, LogicalKeyboardKey key, {bool shift = false, bool control = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('arrows move the selection, Enter opens, Shift+arrows move the task', (tester) async {
    final (h, _) = await pumpGrid(tester);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(selected(tester, 'Alpha'), isTrue);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(selected(tester, 'Bravo'), isTrue);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(selected(tester, 'Charlie'), isTrue, reason: 'the nearest item of the next day');

    await key(tester, LogicalKeyboardKey.enter);
    expect(h.nav.log.last, startsWith('task c '));

    await key(tester, LogicalKeyboardKey.arrowDown, shift: true);
    expect(h.backend.calls.last, 'reschedule Charlie 2026-09-22T10:15 60 thisOccurrence');
    await key(tester, LogicalKeyboardKey.arrowRight, shift: true);
    expect(h.backend.calls.last, 'reschedule Charlie 2026-09-23T10:15 60 thisOccurrence');

    await key(tester, LogicalKeyboardKey.escape);
    expect(selected(tester, 'Charlie'), isFalse);
  });

  testWidgets('+ and - zoom; Page Down turns the page', (tester) async {
    await pumpGrid(tester);
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    final before = grid.debugZoom.$1;
    await key(tester, LogicalKeyboardKey.equal);
    expect(grid.debugZoom.$1, greaterThan(before));
    await key(tester, LogicalKeyboardKey.minus);
    await key(tester, LogicalKeyboardKey.minus);
    expect(grid.debugZoom.$1, lessThan(before));
    await key(tester, LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(find.byType(TaskTile), findsNothing, reason: 'next week is empty');
  });

  testWidgets('Ctrl+C copies the selected task, Ctrl+V pastes it at the hovered slot', (tester) async {
    final (h, extra) = await pumpGrid(tester);
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.keyC, control: true);
    expect(h.read(plannerClipboardProvider)?.title, 'Alpha');
    expect(find.text('Copied “Alpha”'), findsOneWidget);

    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: grid.globalPositionOf(LocalDate(2026, 9, 24), 11 * 60 + 10));
    await mouse.moveTo(grid.globalPositionOf(LocalDate(2026, 9, 24), 11 * 60 + 12)!);
    await tester.pump();
    await key(tester, LogicalKeyboardKey.keyV, control: true);
    expect(extra.calls, ['paste Alpha 2026-09-24T11:00']);
  });

  testWidgets('selection mode: Select from the tile menu, taps toggle, Actions opens the bulk sheet', (tester) async {
    final h = PlannerHarness.create(items: week());
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(date: '2026-09-21'));
    await tester.pumpAndSettle();
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    grid.scrollToMinute(8 * 60, animate: false);
    await tester.pumpAndSettle();

    await tester.longPressAt(grid.globalPositionOf(LocalDate(2026, 9, 21), 9 * 60 + 30)!);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tile-menu-select')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selection-toolbar')), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(const Key('planner-fab')), findsNothing);

    await tester.tapAt(grid.globalPositionOf(LocalDate(2026, 9, 22), 10 * 60 + 30)!);
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(h.nav.log, isEmpty, reason: 'taps select instead of opening');

    await tester.tap(find.byKey(const Key('selection-actions')));
    await tester.pumpAndSettle();
    expect(find.byType(BulkActionsSheet), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('selection-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selection-toolbar')), findsNothing);
  });

  testWidgets('screen readers get empty-slot nodes and move / select actions on tiles', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpGrid(tester, accessible: true);
    expect(find.bySemanticsLabel(RegExp('Wednesday, September 23 08:00, empty')), findsWidgets);
    final tile = tester.getSemantics(find.byWidgetPredicate((w) => w is TaskTile && w.item.title == 'Alpha'));
    final labels = [
      for (final id in tile.getSemanticsData().customSemanticsActionIds ?? const <int>[])
        CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(labels, containsAll(['Move to the next day', 'Move to the previous day', 'Select']));
    semantics.dispose();
  });
}
