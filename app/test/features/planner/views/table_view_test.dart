import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/table_rows.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'planner_perf_test.dart' show perfWeek;
import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

// Table (spreadsheet) view (T3.7.05). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  final rows = [
    item('Gym', at(2026, 9, 21, 7), 60, id: 'gym', priority: 1, categoryId: 'home'),
    item('Review', at(2026, 9, 22, 10), 30, id: 'review', priority: 4, categoryId: 'work'),
    copyItem(item('Standup', at(2026, 9, 21, 9), 15, id: 'su', recurring: true), status: OccurrenceStatus.done),
  ];

  group('rows', () {
    test('columns keep title first and drop unknown names', () {
      expect(tableColumns(['start', 'nope', 'title', 'status']), [
        TableColumn.title,
        TableColumn.start,
        TableColumn.status,
      ]);
    });

    test('sorting by any column, ascending or descending (ties by start)', () {
      List<String> by(TableColumn c, {bool asc = true}) =>
          ([...rows]..sort(tableComparator(c, ascending: asc))).map((i) => i.title).toList();
      expect(by(TableColumn.start), ['Gym', 'Standup', 'Review']);
      expect(by(TableColumn.priority, asc: false), ['Review', 'Gym', 'Standup']);
      expect(by(TableColumn.title), ['Gym', 'Review', 'Standup']);
      expect(by(TableColumn.status), ['Gym', 'Review', 'Standup']);
      expect(by(TableColumn.recurrence, asc: false).first, 'Standup');
    });

    test('task rows keep one row per series; grouping by day stays chronological', () {
      final series = [
        item('Standup', at(2026, 9, 22, 9), 15, id: 'su', recurring: true),
        item('Standup', at(2026, 9, 21, 9), 15, id: 'su', recurring: true),
      ];
      expect(tableTaskRows(series).single.startLocal, at(2026, 9, 21, 9));
      final lines = tableLines([rows[1], rows[0], rows[2]], TableGroup.day);
      expect(lines.whereType<TableGroupLine>().map((g) => (g.key, g.count)), [('2026-09-21', 2), ('2026-09-22', 1)]);
      expect(tableLines(rows, TableGroup.status).whereType<TableGroupLine>().map((g) => g.key), ['scheduled', 'done']);
    });
  });

  Future<({PlannerHarness h, FakeViewActions extra})> pump(
    WidgetTester tester, {
    List<PlannerItem>? items,
    PlannerViewConfig Function(PlannerViewConfig c)? config,
  }) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(
      items: items ?? rows,
      overrides: [viewExtraActionsProvider.overrideWithValue(extra)],
    );
    addTearDown(h.dispose);
    if (config != null) h.read(plannerViewConfigProvider('table').notifier).change(config);
    await pumpPlanner(
      tester,
      h,
      const PlannerScreen(view: 'table', date: '2026-09-21'),
      size: const Size(900, 800),
    );
    await tester.pumpAndSettle();
    return (h: h, extra: extra);
  }

  testWidgets('rows sorted by start; tapping a header sorts by it and again reverses', (tester) async {
    final r = await pump(tester);
    double y(String title) => tester.getTopLeft(find.text(title)).dy;
    expect(y('Gym'), lessThan(y('Standup')));
    expect(y('Standup'), lessThan(y('Review')));
    await tester.tap(find.byKey(const ValueKey('table-header-priority')));
    await tester.pumpAndSettle();
    expect(r.h.read(plannerViewConfigProvider('table')).option<String>('sortBy', ''), 'priority');
    expect(y('Standup'), lessThan(y('Gym')), reason: 'priority 0 < 1 < 4');
    await tester.tap(find.byKey(const ValueKey('table-header-priority')));
    await tester.pumpAndSettle();
    expect(y('Review'), lessThan(y('Gym')));
  });

  testWidgets('inline edits: status, priority (scope dialog for series), time', (tester) async {
    final r = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('cell-status-gym|2026-09-21T07:00')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('status-done')));
    await tester.pumpAndSettle();
    expect(r.h.backend.calls, ['status Gym done']);

    await tester.tap(find.byKey(const ValueKey('cell-priority-su|2026-09-21T09:00')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('priority-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This occurrence'));
    await tester.pumpAndSettle();
    expect(r.extra.calls.single, 'fields Standup title=null prio=3 cat=null thisOccurrence');
  });

  testWidgets('long-press the title renames; the column chooser hides columns; headers resize', (tester) async {
    final r = await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('cell-title-gym|2026-09-21T07:00')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Gym session');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(r.extra.calls.single, 'fields Gym title=Gym session prio=null cat=null thisOccurrence');

    await tester.tap(find.byKey(const Key('table-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Columns').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('column-status')));
    await tester.tap(find.byKey(const Key('columns-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('table-header-status')), findsNothing);

    final before = tester.getSize(find.byKey(const ValueKey('table-header-date'))).width;
    await tester.drag(find.byKey(const ValueKey('table-resize-date')), const Offset(60, 0));
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const ValueKey('table-header-date'))).width;
    expect(after, greaterThan(before + 30));
    final widths = r.h.read(plannerViewConfigProvider('table')).options['columnWidths']! as Map;
    expect(widths['date'], greaterThan(130));
  });

  testWidgets('task rows and grouping by status', (tester) async {
    await pump(tester, config: (c) => c.withOption('groupBy', 'status'));
    expect(find.textContaining('Planned · 2'), findsOneWidget);
    expect(find.textContaining('Done · 1'), findsOneWidget);
  });

  testWidgets('performance: 2 000 rows build lazily and scroll', (tester) async {
    final items = perfWeek(LocalDate(2026, 9, 21));
    await pump(tester, items: items, config: (c) => c.withOption('rangeDays', 7));
    expect(tester.widgetList(find.byType(Text)).length, lessThan(800), reason: 'only visible cells are built');
    final table = find.byKey(const Key('planner-table'));
    for (var i = 0; i < 10; i++) {
      await tester.drag(table, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widgetList(find.byType(Text)).length, lessThan(800));
  });
}
