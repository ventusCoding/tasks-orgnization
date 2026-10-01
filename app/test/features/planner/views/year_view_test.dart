import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Year heatmap (T3.6.10). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  final items = [
    item('Gym', at(2026, 9, 23, 7), 60, id: 'gym', status: OccurrenceStatus.done),
    item('Call', at(2026, 9, 23, 14), 90, id: 'call'),
    item('Dentist', at(2026, 9, 25, 16), 45, id: 'dentist'),
    item('Trip', at(2026, 3, 2, 9), 480, id: 'trip'),
  ];

  Future<PlannerHarness> pump(
    WidgetTester tester, {
    List<PlannerItem>? data,
    PlannerViewConfig Function(PlannerViewConfig c)? config,
  }) async {
    final h = PlannerHarness.create(items: data ?? items);
    addTearDown(h.dispose);
    if (config != null) {
      h.read(plannerViewConfigProvider('year').notifier).change(config);
    }
    await pumpPlanner(tester, h, const PlannerScreen(view: 'year', date: '2026-09-23'));
    await tester.pumpAndSettle();
    return h;
  }

  String labelOf(WidgetTester tester, String isoDay) => tester.getSemantics(find.byKey(ValueKey('heat-$isoDay'))).label;

  testWidgets('shows twelve mini-months of the year with today ringed and planned hours as the default metric', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('2026'), findsOneWidget);
    for (var m = 1; m <= 12; m++) {
      expect(find.byKey(ValueKey('year-month-title-$m')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('heat-2026-09-23')), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2026-02-28')), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2026-02-29')), findsNothing, reason: '2026 is not a leap year');
    expect(labelOf(tester, '2026-09-23'), contains('Planned: 2 h 30 min'));
    expect(labelOf(tester, '2026-09-24'), contains('No tasks'));
  });

  testWidgets('the metric follows the view config: completion and item count', (tester) async {
    await pump(tester, config: (c) => c.withOption('heatMetric', 'completion'));
    expect(labelOf(tester, '2026-09-23'), contains('Completion: 50%'), reason: 'Gym done, Call open');
    expect(labelOf(tester, '2026-09-25'), contains('Completion: 0%'));

    await tester.tap(find.byKey(const Key('year-metric')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Number of items').last);
    await tester.pumpAndSettle();
    expect(labelOf(tester, '2026-09-23'), contains('2 items'));
  });

  testWidgets(
    'tapping a day opens its day list; long-press creates an all-day task; a month title opens the month view',
    (tester) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('heat-2026-09-25')));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'view day_list 2026-09-25');

      await tester.longPress(find.byKey(const ValueKey('heat-2026-09-26')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('quick-create-title')), 'Party');
      await tester.tap(find.byKey(const Key('quick-create-submit')));
      await tester.pumpAndSettle();
      expect(h.backend.calls, ['create 2026-09-26T00:00 1440 Party allDay']);

      await tester.tap(find.byKey(const ValueKey('year-month-title-9')));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'view month 2026-09-01');
    },
  );

  testWidgets('previous / next change the year and the shared anchor; Today returns', (tester) async {
    final h = await pump(tester);
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.pumpAndSettle();
    expect(find.text('2027'), findsOneWidget);
    expect(h.read(plannerAnchorProvider), LocalDate(2027, 1, 1));
    expect(find.byKey(const ValueKey('heat-2027-02-28')), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-previous')));
    await tester.tap(find.byKey(const Key('planner-previous')));
    await tester.pumpAndSettle();
    expect(find.text('2025'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-today')));
    await tester.pumpAndSettle();
    expect(find.text('2026'), findsOneWidget);
    expect(h.read(plannerAnchorProvider), LocalDate(2026, 9, 23));
  });

  testWidgets('leap years have a 29th of February', (tester) async {
    await pump(tester, data: const []);
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.pumpAndSettle();
    expect(find.text('2028'), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-2028-02-29')), findsOneWidget);
  });
}
