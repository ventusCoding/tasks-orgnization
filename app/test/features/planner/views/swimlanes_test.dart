import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/engine/swimlanes.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/swimlanes_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Category swimlanes (T3.6.15).
void main() {
  setUpAll(initializeDateFormatting);

  const work = Category(id: 'work', name: 'Work', color: 0xFF1565C0, sortKey: 'a');
  const home = Category(id: 'home', name: 'Home', color: 0xFF2E7D32, sortKey: 'b');

  group('layout', () {
    test('each item sits in its category lane; uncategorized go to Other', () {
      final layout = layoutSwimlanes(
        const [SwimlaneInput(0, 0, 60, 'work'), SwimlaneInput(1, 0, 60, 'home'), SwimlaneInput(2, 30, 90, null)],
        ['work', 'home'],
      );
      final byIndex = {for (final t in layout.tiles) t.index: t};
      expect(byIndex[0]!.columns, 3 * swimlaneUnits);
      expect(byIndex[0]!.column, 0);
      expect(byIndex[0]!.span, swimlaneUnits);
      expect(byIndex[1]!.column, swimlaneUnits);
      expect(byIndex[2]!.column, 2 * swimlaneUnits, reason: 'Other lane');
    });

    test('overlaps share their lane; the cap spills to +N', () {
      final layout = layoutSwimlanes(
        const [SwimlaneInput(0, 0, 60, 'work'), SwimlaneInput(1, 0, 60, 'work'), SwimlaneInput(2, 0, 60, 'work')],
        ['work'],
        laneCap: 2,
      );
      expect(layout.tiles, hasLength(2));
      expect(layout.tiles.map((t) => (t.column, t.span)), [(0, 6), (6, 6)]);
      expect(layout.overflow.single.indices, [2]);
    });

    test('lanes default to the categories in order; picked lanes win', () {
      final d = PlannerViewConfig.defaultsFor(PlannerViewType.swimlanes);
      expect(swimlaneIds(d, const [work, home]), ['work', 'home']);
      expect(swimlaneIds(d.withOption('lanes', ['home']), const [work, home]), ['home']);
    });
  });

  testWidgets('the grid shows a lane legend; the picker changes lanes', (tester) async {
    final h = PlannerHarness.create(
      items: [
        item('Report', at(2026, 9, 23, 10), 60, categoryId: 'work', id: 'r'),
        item('Laundry', at(2026, 9, 23, 10), 60, categoryId: 'home', id: 'l'),
      ],
      overrides: [
        allCategoriesProvider.overrideWith((ref) => Stream.value(const [work, home])),
      ],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'swimlanes', date: '2026-09-23'));
    await tester.pumpAndSettle();
    final legend = find.byKey(const Key('swimlane-legend'));
    expect(find.descendant(of: legend, matching: find.text('Work')), findsOneWidget);
    expect(find.descendant(of: legend, matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: legend, matching: find.text('Other')), findsOneWidget);
    final report = tester.getCenter(find.text('Report').first);
    final laundry = tester.getCenter(find.text('Laundry').first);
    expect(report.dx, lessThan(laundry.dx), reason: 'work lane before home lane');
    expect((report.dy - laundry.dy).abs(), lessThan(1), reason: 'side by side at the same time');

    await tester.tap(find.byKey(const Key('planner-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work').last); // turn Work off
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lanes-save')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('swimlanes')).options['lanes'], ['home']);
    expect(find.descendant(of: legend, matching: find.text('Work')), findsNothing);
  });

  testWidgets('"Show as timeline rows" opens the timeline grouped by category', (tester) async {
    final h = PlannerHarness.create(
      overrides: [
        allCategoriesProvider.overrideWith((ref) => Stream.value(const [work, home])),
      ],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'swimlanes', date: '2026-09-23'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show as timeline rows').last);
    await tester.pumpAndSettle();
    expect(h.nav.log.last, startsWith('view timeline'));
    expect(h.read(plannerViewConfigProvider('timeline')).option<String>('groupBy', ''), 'category');
  });
}
