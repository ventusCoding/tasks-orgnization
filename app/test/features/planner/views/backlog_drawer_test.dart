import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/backlog_drawer.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

// Backlog drawer & timeboxing (T3.7.02). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);
  final wed = LocalDate(2026, 9, 23);

  PlannerItem backlogItem(String title, String id, {int? estimate}) => PlannerItem(
    taskId: id,
    seriesId: id,
    occurrenceKey: '',
    title: title,
    startLocal: wed.atStartOfDay,
    durationMinutes: 30,
    startUtc: DateTime.utc(2026, 9, 23),
    endUtc: DateTime.utc(2026, 9, 23, 0, 30),
    status: OccurrenceStatus.scheduled,
    estimateMinutes: estimate,
  );

  test('drop duration: estimate, else own duration for timed items, else 30 min', () {
    expect(drawerDropDuration(PlannerDrawerEntry(DrawerSection.unscheduled, backlogItem('A', 'a', estimate: 50))), 50);
    expect(drawerDropDuration(PlannerDrawerEntry(DrawerSection.unscheduled, backlogItem('A', 'a'))), 30);
    expect(drawerDropDuration(PlannerDrawerEntry(DrawerSection.overdue, item('Late', at(2026, 9, 22, 9), 45))), 45);
    expect(
      drawerDropDuration(PlannerDrawerEntry(DrawerSection.untimed, item('Rent', at(2026, 9, 23), 1440, allDay: true))),
      30,
    );
  });

  Future<({PlannerHarness h, FakeViewActions extra})> pump(
    WidgetTester tester, {
    String view = 'week_table',
    List<PlannerItem> items = const [],
    List<PlannerItem> backlog = const [],
  }) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(items: items, overrides: [viewExtraActionsProvider.overrideWithValue(extra)]);
    addTearDown(h.dispose);
    h.backend.backlog.addAll(backlog);
    await pumpPlanner(
      tester,
      h,
      PlannerScreen(view: view, date: '2026-09-23'),
      size: const Size(800, 900),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backlog-drawer-toggle')));
    await tester.pumpAndSettle();
    return (h: h, extra: extra);
  }

  TimeGridState grid(WidgetTester tester) => tester.state<TimeGridState>(find.byType(TimeGrid));

  Future<void> dragTo(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('the drawer lists backlog, untimed, overdue items; search and sections filter', (tester) async {
    await pump(
      tester,
      items: [
        item('Pay rent', at(2026, 9, 23), 1440, allDay: true, id: 'rent'),
        copyItem(item('Late report', at(2026, 9, 22, 9), 60, id: 'late'), status: OccurrenceStatus.missed),
      ],
      backlog: [backlogItem('Write memo', 'memo', estimate: 45)],
    );
    final drawer = find.byType(BacklogDrawerPanel);
    expect(drawer, findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('Write memo')), findsOneWidget);
    expect(find.descendant(of: drawer, matching: find.text('Pay rent')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('backlog-drawer-search')), 'memo');
    await tester.pumpAndSettle();
    expect(find.descendant(of: drawer, matching: find.text('Pay rent')), findsNothing);
    await tester.enterText(find.byKey(const Key('backlog-drawer-search')), '');
    await tester.tap(find.byKey(const ValueKey('drawer-section-unscheduled')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: drawer, matching: find.text('Write memo')), findsNothing);
  });

  testWidgets('drawer → grid schedules a backlog task at the drop slot with its estimate', (tester) async {
    final r = await pump(tester, backlog: [backlogItem('Write memo', 'memo', estimate: 45)]);
    final from = tester.getCenter(
      find.descendant(of: find.byType(BacklogDrawerPanel), matching: find.text('Write memo')),
    );
    final to = grid(tester).globalPositionOf(LocalDate(2026, 9, 21), 11 * 60 + 2)!;
    await dragTo(tester, from, to);
    expect(r.h.backend.calls, ['reschedule Write memo 2026-09-21T11:00 45 allDay=false thisOccurrence']);
  });

  testWidgets('grid → drawer moves a one-off task back to the backlog (source backlog)', (tester) async {
    final r = await pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60, id: 'gym')]);
    final from = grid(tester).globalPositionOf(LocalDate(2026, 9, 21), 7 * 60 + 30)!;
    final to = tester.getCenter(find.byType(BacklogDrawerPanel));
    await dragTo(tester, from, to);
    expect(r.extra.calls, ['unschedule Gym backlog']);
    expect(r.h.backend.calls, isEmpty, reason: 'not rescheduled on the grid');
  });

  testWidgets('recurring occurrences refuse to go to the backlog with a toast', (tester) async {
    final r = await pump(tester, items: [item('Standup', at(2026, 9, 21, 9), 30, id: 'su', recurring: true)]);
    final from = grid(tester).globalPositionOf(LocalDate(2026, 9, 21), 9 * 60 + 10)!;
    await dragTo(tester, from, tester.getCenter(find.byType(BacklogDrawerPanel)));
    expect(r.extra.calls, isEmpty);
    expect(find.text("Recurring occurrences can't be moved to the backlog"), findsOneWidget);
  });

  testWidgets('the day list takes drawer drops too', (tester) async {
    final r = await pump(tester, view: 'day_list', backlog: [backlogItem('Call bank', 'bank')]);
    expect(find.byType(BacklogDrawerPanel), findsOneWidget);
    final from = tester.getCenter(
      find.descendant(of: find.byType(BacklogDrawerPanel), matching: find.text('Call bank')),
    );
    // Drop on the list area left of the drawer.
    final list = tester.getRect(find.byKey(const Key('day-pages')));
    await dragTo(tester, from, Offset(list.left + 60, list.top + 200));
    expect(r.h.backend.calls.single, startsWith('reschedule Call bank 2026-09-23T'));
  });
}
