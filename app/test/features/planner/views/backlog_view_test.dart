import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/backlog_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

// Backlog list screen (T3.7.03). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  PlannerItem backlogItem(String title, String id, {int? estimate, int priority = 0, String? category, String? sort}) =>
      PlannerItem(
        taskId: id,
        seriesId: id,
        occurrenceKey: '',
        title: title,
        startLocal: at(2026, 9, 23),
        durationMinutes: 30,
        startUtc: DateTime.utc(2026, 9, 23),
        endUtc: DateTime.utc(2026, 9, 23, 0, 30),
        status: OccurrenceStatus.scheduled,
        estimateMinutes: estimate,
        priority: priority,
        categoryId: category,
        manualSortKey: sort,
      );

  group('sequential placement on a day', () {
    final wed = LocalDate(2026, 9, 23);
    const options = FreeSlotOptions(window: DayWindow(9 * 60, 17 * 60));

    test('fills free slots in order, respects work hours and skips busy blocks', () {
      final starts = scheduleOnDay(
        day: wed,
        items: [item('Meeting', at(2026, 9, 23, 10), 60), item('Lunch', at(2026, 9, 23, 12), 60)],
        durations: [45, 30, 90, 300],
        options: options,
      );
      expect(starts, [at(2026, 9, 23, 9), at(2026, 9, 23, 11), at(2026, 9, 23, 13), null]);
    });

    test('today starts at now; non-work days still work when picked explicitly', () {
      expect(
        scheduleOnDay(day: wed, items: const [], durations: [30], options: options, notBefore: at(2026, 9, 23, 15, 10)),
        [at(2026, 9, 23, 15, 10)],
      );
      expect(scheduleOnDay(day: LocalDate(2026, 9, 26), items: const [], durations: [30], options: options), [
        at(2026, 9, 26, 9),
      ]);
    });
  });

  test('grouping: categories in order (none last), priorities urgent first, deadlines soonest', () {
    final items = [
      backlogItem('A', 'a', category: 'home', priority: 1),
      backlogItem('B', 'b', priority: 4),
      copyItem(backlogItem('C', 'c', category: 'work'), deadlineLocal: at(2026, 9, 30)),
      copyItem(backlogItem('D', 'd'), deadlineLocal: at(2026, 9, 25)),
    ];
    expect(groupBacklog(items, BacklogGroup.category, categoryOrder: ['work', 'home']).map((g) => g.$1), [
      'work',
      'home',
      '',
    ]);
    expect(groupBacklog(items, BacklogGroup.priority).map((g) => g.$1), ['4', '1', '0']);
    expect(groupBacklog(items, BacklogGroup.deadline).map((g) => g.$1), ['2026-09-25', '2026-09-30', '']);
    expect(groupBacklog(items, BacklogGroup.none).single.$2, hasLength(4));
  });

  Future<({PlannerHarness h, FakeViewActions extra})> pump(WidgetTester tester, List<PlannerItem> backlog) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(
      items: [item('Meeting', at(2026, 9, 25, 9), 60)],
      overrides: [viewExtraActionsProvider.overrideWithValue(extra)],
    );
    addTearDown(h.dispose);
    h.backend.backlog.addAll(backlog);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'backlog'));
    await tester.pumpAndSettle();
    return (h: h, extra: extra);
  }

  testWidgets('quick add creates a backlog task; chips edit estimate and priority', (tester) async {
    final r = await pump(tester, [backlogItem('Write memo', 'memo', estimate: 45, sort: 'a0')]);
    expect(find.text('Backlog · 1'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('backlog-add')), 'Call bank');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(r.extra.calls, ['createBacklog Call bank']);

    await tester.tap(find.byKey(const ValueKey('backlog-priority-memo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();
    expect(r.extra.calls.last, 'edit Write memo est=null prio=3 deadline=null cat=null');
  });

  testWidgets('drag handles reorder through the neighbours sort keys', (tester) async {
    final r = await pump(tester, [
      backlogItem('First', 'one', sort: 'a0'),
      backlogItem('Second', 'two', sort: 'a1'),
      backlogItem('Third', 'three', sort: 'a2'),
    ]);
    final handle = find.descendant(
      of: find.byKey(const ValueKey('backlog-three')),
      matching: find.byIcon(Icons.drag_handle),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(r.extra.calls.single, 'reorder Third after=null before=a0');
  });

  testWidgets('select items and Schedule on… places them into the free slots of the day', (tester) async {
    final r = await pump(tester, [
      backlogItem('Write memo', 'memo', estimate: 45, sort: 'a0'),
      backlogItem('Huge', 'huge', estimate: 600, sort: 'a1'),
      backlogItem('Call', 'call', estimate: 30, sort: 'a2'),
    ]);
    for (final id in ['memo', 'huge', 'call']) {
      await tester.tap(find.byKey(ValueKey('backlog-select-$id')));
      await tester.pump();
    }
    expect(find.text('3 selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('backlog-schedule-on')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25').last); // tapping a day returns it
    await tester.pumpAndSettle();
    expect(r.h.backend.calls, ['schedule Write memo 2026-09-25T10:00 45', 'schedule Call 2026-09-25T10:45 30']);
    expect(find.textContaining("1 item didn't fit"), findsOneWidget);
  });

  testWidgets('group by priority shows sections', (tester) async {
    final r = await pump(tester, [
      backlogItem('Low', 'low', priority: 1, sort: 'a0'),
      backlogItem('Urgent', 'urgent', priority: 4, sort: 'a1'),
    ]);
    r.h.read(plannerViewConfigProvider('backlog').notifier).change((c) => c.withOption('groupBy', 'priority'));
    await tester.pumpAndSettle();
    final urgent = tester.getTopLeft(find.text('Urgent · 1'));
    final low = tester.getTopLeft(find.text('Low · 1'));
    expect(urgent.dy, lessThan(low.dy));
  });
}
