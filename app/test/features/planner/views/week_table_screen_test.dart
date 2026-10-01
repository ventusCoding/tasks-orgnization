import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/view_config/slot_size_sheet.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

Future<PlannerHarness> _pump(
  WidgetTester tester, {
  String view = 'week_table',
  String? date,
  List<PlannerItem> items = const [],
}) async {
  final h = PlannerHarness.create(items: [for (final i in items) i]);
  addTearDown(h.dispose);
  await pumpPlanner(tester, h, PlannerScreen(view: view, date: date));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUpAll(initializeDateFormatting);

  test('range titles follow the locale order', () {
    expect(rangeTitle('en', LocalDate(2026, 9, 21), LocalDate(2026, 9, 27)), 'Sep 21–27, 2026');
    expect(rangeTitle('fr', LocalDate(2026, 9, 21), LocalDate(2026, 9, 27)), '21–27 sept. 2026');
    expect(rangeTitle('en', LocalDate(2026, 9, 28), LocalDate(2026, 10, 4)), 'Sep 28 – Oct 4, 2026');
    expect(rangeTitle('en', LocalDate(2026, 12, 28), LocalDate(2027, 1, 3)), 'Dec 28, 2026 – Jan 3, 2027');
  });

  test('rows per slot size (7 min → 206 rows, the last one 5 min)', () {
    expect(rowsForSlot(7), (rows: 206, last: 5));
    expect(rowsForSlot(45), (rows: 32, last: 45));
    expect(rowsForSlot(1), (rows: 1440, last: 1));
    expect(rowsForSlot(1440), (rows: 1, last: 1440));
  });

  testWidgets('the default Plan view is the week table: range title, 30-min slot button', (tester) async {
    await _pump(tester);
    expect(find.byType(TimeGrid), findsOneWidget);
    expect(find.text('Week table'), findsOneWidget);
    expect(find.text('Sep 21–27, 2026'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
  });

  testWidgets('previous / next move by a week; Today returns', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 28 – Oct 4, 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-previous')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner-previous')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 14–20, 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-today')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 21–27, 2026'), findsOneWidget);
  });

  testWidgets('slot-size sheet: presets apply and persist; 24 h turns on week-list mode', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('slot-size-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slot-preset-120')));
    await tester.pumpAndSettle();
    expect(find.text('12 rows per day'), findsOneWidget);
    await tester.tap(find.byKey(const Key('slot-apply')));
    await tester.pumpAndSettle();
    final config = h.read(plannerViewConfigProvider('week_table'));
    expect(config.slotMinutes, 120);
    expect(config.usesTable, isTrue);
    expect(find.text('2h'), findsNothing);
    final stored = await h.read(savedViewsRepositoryProvider).all();
    expect(stored.firstWhere((v) => v.id == entryViewId('user-1', 'week_table')).config.slotMinutes, 120);
    expect(
      stored.map((v) => v.id),
      contains(entryViewId('user-1', 'day_list')),
      reason: 'first run creates the MVP views',
    );

    await tester.tap(find.byKey(const Key('slot-size-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slot-preset-1440')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slot-apply')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('week_table')).isWeekListMode, isTrue);
  });

  testWidgets('slot-size sheet: custom 7 previews 206 rows; 0, 1441 and text are rejected', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('slot-size-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('slot-custom')), '7');
    await tester.pumpAndSettle();
    expect(find.text('206 rows per day, the last one 5 min'), findsOneWidget);
    for (final bad in ['0', '1441', 'abc']) {
      await tester.enterText(find.byKey(const Key('slot-custom')), bad);
      await tester.pumpAndSettle();
      expect(find.text('Enter a size between 1 minute and 24 hours'), findsOneWidget, reason: bad);
      expect(tester.widget<FilledButton>(find.byKey(const Key('slot-apply'))).onPressed, isNull);
    }
    await tester.enterText(find.byKey(const Key('slot-custom')), '1h 30');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slot-apply')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('week_table')).slotMinutes, 90);
  });

  testWidgets('the view switcher lists views and navigates with the anchor date', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('planner-view-switcher')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('view-n_day')), findsOneWidget);
    await tester.tap(find.byKey(const Key('view-work_week')));
    await tester.pumpAndSettle();
    expect(h.nav.log.single, startsWith('view work_week 2026-09-2'));
  });

  testWidgets('work week shows five work days', (tester) async {
    await _pump(tester, view: 'work_week', date: '2026-09-23');
    expect(find.text('Sep 21–25, 2026'), findsOneWidget);
  });

  testWidgets('the FAB opens the editor at the next quarter hour today', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('planner-fab')));
    await tester.pumpAndSettle();
    expect(h.nav.log, ['new 2026-09-23T09:30 30']);
  });

  testWidgets('filters: apply a status filter, see the chip row, clear it', (tester) async {
    final h = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    await tester.tap(find.byKey(const Key('planner-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-apply')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('week_table')).filters.statuses, ['done']);
    expect(find.text('Gym'), findsNothing);
    await tester.tap(find.byKey(const Key('clear-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('mini-month: tapping a day jumps to its week', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('planner-title')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mini-month-title')), findsOneWidget);
    await tester.tap(find.byKey(Key('mini-${LocalDate(2026, 9, 9).toIso()}')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 7–13, 2026'), findsOneWidget);
  });

  testWidgets('a saved default view opens on the bare Plan tab', (tester) async {
    final h = PlannerHarness.create();
    addTearDown(h.dispose);
    final repo = h.read(savedViewsRepositoryProvider);
    final id = await repo.create(
      'Deep work · 5 min',
      PlannerViewConfig.defaultsFor(PlannerViewType.weekTable).withSlot(5),
    );
    await repo.setDefault(id);
    await pumpPlanner(tester, h, const PlannerScreen());
    await tester.pumpAndSettle();
    expect(find.text('Deep work · 5 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
  });

  testWidgets('week summary footer: planned / completion; tap opens insights; collapse is remembered', (tester) async {
    final h = await _pump(
      tester,
      items: [
        item('Gym', at(2026, 9, 21, 7), 90, status: OccurrenceStatus.done),
        item('Read', at(2026, 9, 22, 20), 30),
      ],
    );
    expect(find.byKey(const Key('week-summary')), findsOneWidget);
    expect(find.textContaining('2 h'), findsWidgets);
    expect(find.textContaining('50'), findsWidgets, reason: '1 of 2 done');
    await tester.tap(find.byKey(const Key('week-summary')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'insights 2026-09-21 7');
    await tester.tap(find.byKey(const Key('week-summary-toggle')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewStateProvider('week_table'))!.extra['summaryCollapsed'], isTrue);
    expect(find.text('Week summary'), findsOneWidget);
  });

  testWidgets('first-use hints show one at a time, once each', (tester) async {
    final h = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    expect(find.byKey(const ValueKey('hint-longPress')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hint-got-it')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hint-pinch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hint-got-it')));
    await tester.pumpAndSettle();
    expect(find.text('Tap 30 min to change the row size'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hint-got-it')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hint-got-it')), findsNothing);
    expect(h.read(plannerViewStateProvider('week_table'))!.extra['hintsSeen'], ['longPress', 'pinch', 'slotSize']);
  });

  testWidgets('an empty week offers to plan the first task', (tester) async {
    final h = await _pump(tester);
    expect(find.text('Nothing planned this week'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plan-first-task')));
    await tester.pumpAndSettle();
    expect(h.nav.log, ['new 2026-09-23T09:30 30']);
  });

  testWidgets('accessible list mode lists the range with actions', (tester) async {
    final h = await _pump(tester, items: [item('Gym', at(2026, 9, 21, 7), 60)]);
    h.read(plannerViewStateProvider('week_table').notifier).update((s) => s.withExtra('listMode', true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessible-list')), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['status Gym done']);
  });
}
