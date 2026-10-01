import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/engine/load_matrix.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Load heatmap (T3.6.16). Week of Mon 21 Sep 2026.
void main() {
  setUpAll(initializeDateFormatting);
  final monday = LocalDate(2026, 9, 21);

  group('aggregation', () {
    test('timed items split at hour boundaries into weekday × hour cells', () {
      final m = loadMatrix([item('Deep work', at(2026, 9, 21, 9, 30), 90)], start: monday, days: 7);
      expect(m.cells[0][9], 30);
      expect(m.cells[0][10], 60);
      expect(m.cells[0][11], 0);
      expect(m.days[monday], 90);
      expect(m.itemsByCell[(1, 10)]!.single.title, 'Deep work');
      expect(m.cellLoad(Weekday.monday, 10), 1, reason: '60 min of a 60-min weekly cell');
    });

    test('all-day, cancelled, skipped and backlog items do not count; ranges clip', () {
      final m = loadMatrix(
        [
          item('Trip', at(2026, 9, 22), 1440, allDay: true),
          item('Off', at(2026, 9, 22, 9), 60, status: OccurrenceStatus.cancelled),
          item('Lunch', at(2026, 9, 22, 12), 60, status: OccurrenceStatus.skipped),
          item('Night', at(2026, 9, 27, 23), 120),
        ],
        start: monday,
        days: 7,
      );
      expect(m.days.keys, [LocalDate(2026, 9, 27)]);
      expect(m.cells[6][23], 60, reason: 'clipped at the end of the range');
    });

    test('same weekday-hour adds across weeks; capacity grows with weeks', () {
      final m = loadMatrix(
        [item('Run', at(2026, 9, 21, 7), 60), item('Run', at(2026, 9, 28, 7), 30)],
        start: monday,
        days: 14,
      );
      expect(m.cells[0][7], 90);
      expect(m.weeks, 2);
      expect(m.cellLoad(Weekday.monday, 7), 0.75);
      expect(loadLevel(0.75), 3);
      expect(loadLevel(1.2), 5);
      expect(loadLevel(0), 0);
    });

    test('tracked metric uses tracked seconds spread over the planned interval', () {
      final tracked = copyItem(item('Focus', at(2026, 9, 21, 9), 120), trackedSeconds: 60 * 60);
      final m = loadMatrix([tracked], start: monday, days: 7, metric: LoadMetric.tracked);
      expect(m.cells[0][9], 30);
      expect(m.cells[0][10], 30);
      expect(
        loadMatrix([item('X', at(2026, 9, 21, 9), 60)], start: monday, days: 7, metric: LoadMetric.tracked).days,
        isEmpty,
      );
    });
  });

  testWidgets('cells color by load; tap lists the items behind a cell; days open the day list', (tester) async {
    final h = PlannerHarness.create(
      items: [
        item('Deep work', at(2026, 9, 21, 9), 60, id: 'dw'),
        item('Review', at(2026, 9, 21, 9, 30), 30, id: 'rv'),
      ],
    );
    addTearDown(h.dispose);
    h.read(plannerViewConfigProvider('load_heatmap').notifier).change((c) => c.withOption('weeks', 1));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'load_heatmap', date: '2026-09-23'));
    await tester.pumpAndSettle();
    expect(find.text('Sep 21–27, 2026'), findsOneWidget);
    expect(find.byKey(const Key('load-grid')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('load-cell-1-9')));
    await tester.pumpAndSettle();
    expect(find.text('Deep work'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(const ValueKey('load-day-2026-09-21')), 100);
    await tester.tap(find.byKey(const ValueKey('load-day-2026-09-21')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'view day_list 2026-09-21');

    await tester.tap(find.byKey(const Key('load-weeks')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 weeks').last);
    await tester.pumpAndSettle();
    expect(find.text('Sep 21 – Oct 18, 2026'), findsOneWidget);
  });
}
