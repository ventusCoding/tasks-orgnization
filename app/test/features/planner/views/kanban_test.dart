import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart' show viewExtraActionsProvider;
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/kanban_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

// Kanban board (T3.7.08). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  final items = [
    item('Gym', at(2026, 9, 23, 7), 60, id: 'gym', priority: 1),
    copyItem(item('Report', at(2026, 9, 23, 10), 60, id: 'report', priority: 4), status: OccurrenceStatus.inProgress),
    copyItem(item('Lunch', at(2026, 9, 24, 12), 60, id: 'lunch'), status: OccurrenceStatus.done),
    copyItem(item('Late', at(2026, 9, 22, 9), 30, id: 'late'), status: OccurrenceStatus.missed),
  ];

  test('keys and columns: missed counts as planned; priorities urgent first', () {
    expect(kanbanKey(items[3], KanbanGroup.status), 'scheduled');
    expect(kanbanKey(items[0], KanbanGroup.priority), '1');
    expect(kanbanColumns(KanbanGroup.priority, categoryIds: const [], days: const []), ['4', '3', '2', '1', '0']);
    expect(kanbanColumns(KanbanGroup.category, categoryIds: const ['a'], days: const []), ['a', '']);
    expect(kanbanColumns(KanbanGroup.day, categoryIds: const [], days: [LocalDate(2026, 9, 23)]), ['2026-09-23']);
  });

  Future<({PlannerHarness h, FakeViewActions extra})> pump(WidgetTester tester, {String group = 'status'}) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(items: items, overrides: [viewExtraActionsProvider.overrideWithValue(extra)]);
    addTearDown(h.dispose);
    h.read(plannerViewConfigProvider('kanban').notifier).change((c) => c.withOption('groupBy', group));
    await pumpPlanner(
      tester,
      h,
      const PlannerScreen(view: 'kanban', date: '2026-09-22'),
      size: const Size(1200, 800),
    );
    await tester.pumpAndSettle();
    return (h: h, extra: extra);
  }

  Future<void> drag(WidgetTester tester, Finder card, Finder column) async {
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(column));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('status columns with counts; dragging a card to Done marks it done', (tester) async {
    final r = await pump(tester);
    expect(find.bySemanticsLabel('Planned, 2 items'), findsOneWidget);
    expect(find.bySemanticsLabel('In progress, 1 item'), findsOneWidget);
    await drag(
      tester,
      find.byKey(const ValueKey('kanban-card-gym|2026-09-23T07:00')),
      find.byKey(const ValueKey('kanban-col-done')),
    );
    expect(r.h.backend.calls, ['status Gym done']);
  });

  testWidgets('priority columns update the task (scope dialog for series)', (tester) async {
    final r = await pump(tester, group: 'priority');
    await drag(
      tester,
      find.byKey(const ValueKey('kanban-card-gym|2026-09-23T07:00')),
      find.byKey(const ValueKey('kanban-col-3')),
    );
    expect(r.extra.calls, ['fields Gym title=null prio=3 cat=null thisOccurrence']);
  });

  testWidgets('day columns reschedule keeping the time', (tester) async {
    final r = await pump(tester, group: 'day');
    await drag(
      tester,
      find.byKey(const ValueKey('kanban-card-gym|2026-09-23T07:00')),
      find.byKey(const ValueKey('kanban-col-2026-09-25')),
    );
    expect(r.h.backend.calls, ['reschedule Gym 2026-09-25T07:00 60 thisOccurrence']);
  });
}
