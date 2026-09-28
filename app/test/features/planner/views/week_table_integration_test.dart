import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/planner_harness.dart';

// T3.4.13 on the real planner data layer: create with a long-press-drag, make it repeat on
// Mon & Tue, move Tuesday's occurrence to Wednesday 10:00 (this occurrence), resize it, then undo
// twice and find the original Tuesday occurrence back.
void main() {
  final mon = LocalDate(2026, 9, 21);
  final tue = LocalDate(2026, 9, 22);
  final wed = LocalDate(2026, 9, 23);

  Future<List<PlannerItem>> items(PlannerHarness h, LocalDate day) async =>
      (await h.read(occurrenceRangeServiceProvider).resolveRange(day.atStartOfDay, day.plusDays(1).atStartOfDay)).items;

  Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('create, repeat, move one occurrence, resize, undo twice', (tester) async {
    final h = PlannerHarness.create(realData: true);
    addTearDown(h.dispose);
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(tester, h, Scaffold(body: TimeGrid(viewKey: 'week_table', controller: controller)));
    await tester.pumpAndSettle();
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    await controller.jumpTo(mon, animate: false, minute: 6 * 60);
    await tester.pumpAndSettle();

    // 1. Long-press-drag Monday 07:00–08:30 and create "Gym".
    await drag(tester, grid.globalPositionOf(mon, 7 * 60 + 3)!, grid.globalPositionOf(mon, 8 * 60 + 29)!);
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Gym');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    final created = (await items(h, mon)).single;
    expect((created.title, created.startLocal, created.durationMinutes), ('Gym', mon.atTime(LocalTime(7, 0)), 90));

    // … repeating weekly on Mon & Tue (the editor's job — done through the data layer here).
    final task = (await h.read(plannerQueriesProvider).task(created.taskId))!;
    await h.read(tasksRepositoryProvider).update(
      task.copyWith(recurrence: RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)])),
    );
    await tester.pumpAndSettle();
    final tuesday = (await items(h, tue)).single;
    expect(tuesday.isRecurring, isTrue);

    // 2. Drag Tuesday's occurrence to Wednesday 10:00 — this occurrence.
    await drag(tester, grid.globalPositionOf(tue, 7 * 60 + 45)!, grid.globalPositionOf(wed, 10 * 60 + 46)!);
    await tester.tap(find.text('This occurrence'));
    await tester.pumpAndSettle();
    final moved = (await items(h, wed)).single;
    expect((moved.startLocal, moved.durationMinutes, moved.occurrenceKey), (wed.atTime(LocalTime(10, 0)), 90, tuesday.occurrenceKey));
    expect(await items(h, tue), isEmpty);

    // 3. Resize it (bottom edge 11:30 → 12:00).
    await drag(tester, grid.globalPositionOf(wed, 11 * 60 + 28)!, grid.globalPositionOf(wed, 12 * 60 + 1)!);
    await tester.tap(find.text('This occurrence'));
    await tester.pumpAndSettle();
    expect((await items(h, wed)).single.durationMinutes, 120);

    // 4. Undo twice → the original Tuesday occurrence is back.
    expect(await h.read(undoStackProvider).undo(), isTrue);
    expect(await h.read(undoStackProvider).undo(), isTrue);
    await tester.pumpAndSettle();
    final restored = (await items(h, tue)).single;
    expect((restored.startLocal, restored.durationMinutes), (tue.atTime(LocalTime(7, 0)), 90));
    expect(await items(h, wed), isEmpty);
  });

  testWidgets('day header menu: mark remaining done in one undoable operation (T3.2.23)', (tester) async {
    final h = PlannerHarness.create(realData: true);
    addTearDown(h.dispose);
    final actions = h.read(plannerActionsProvider);
    await actions.createAt(wed.atTime(LocalTime(14, 0)), 30, title: 'Write');
    await actions.createAt(wed.atTime(LocalTime(16, 0)), 30, title: 'Call');
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(tester, h, Scaffold(body: TimeGrid(viewKey: 'week_table', controller: controller)));
    await tester.pumpAndSettle();
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));

    await tester.longPressAt(grid.globalHeaderOf(wed)!);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all remaining as done'));
    await tester.pumpAndSettle();
    expect([for (final i in await items(h, wed)) i.status], [OccurrenceStatus.done, OccurrenceStatus.done]);
    expect(find.text('2 tasks marked as done'), findsOneWidget);

    expect(await h.read(undoStackProvider).undo(), isTrue);
    await tester.pumpAndSettle();
    expect([for (final i in await items(h, wed)) i.status], [OccurrenceStatus.scheduled, OccurrenceStatus.scheduled]);
  });
}
