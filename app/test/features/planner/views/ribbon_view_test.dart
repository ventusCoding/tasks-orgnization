import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Ribbon view (T3.6.13): day ribbon as a view type and the week ribbon. Clock: Wed 23 Sep 09:30.
void main() {
  setUpAll(initializeDateFormatting);

  final items = [
    item('Gym', at(2026, 9, 23, 7), 60, id: 'gym', status: OccurrenceStatus.done),
    item('Focus', at(2026, 9, 23, 10), 90, id: 'focus'),
    item('Pay rent', at(2026, 9, 23), 1440, allDay: true, id: 'rent'),
    item('Dentist', at(2026, 9, 25, 16), 45, id: 'dentist'),
  ];

  Future<PlannerHarness> pump(WidgetTester tester, {String scope = 'day'}) async {
    final h = PlannerHarness.create(items: items);
    addTearDown(h.dispose);
    h.read(plannerViewConfigProvider('ribbon').notifier).change((c) => c.withOption('scope', scope));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'ribbon', date: '2026-09-23'));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('day scope: blocks with free gaps, paged by day', (tester) async {
    await pump(tester);
    expect(find.text('Wednesday, September 23'), findsOneWidget);
    expect(find.byKey(const Key('day-ribbon')), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.textContaining('free 2 h'), findsOneWidget, reason: '08:00–10:00 between Gym and Focus');
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, September 24'), findsOneWidget);
  });

  testWidgets('week scope: icons in order per day; a header opens the day ribbon', (tester) async {
    final h = await pump(tester, scope: 'week');
    expect(find.text('Sep 21–27, 2026'), findsOneWidget);
    final wed = find.byKey(const ValueKey('ribbon-week-day-2026-09-23'));
    final rent = tester.getCenter(
      find.descendant(of: wed, matching: find.byKey(const ValueKey('ribbon-icon-rent|2026-09-23T00:00'))),
    );
    final gym = tester.getCenter(
      find.descendant(of: wed, matching: find.byKey(const ValueKey('ribbon-icon-gym|2026-09-23T07:00'))),
    );
    final focus = tester.getCenter(find.byKey(const ValueKey('ribbon-icon-focus|2026-09-23T10:00')));
    expect(rent.dy, lessThan(gym.dy), reason: 'all-day first');
    expect(gym.dy, lessThan(focus.dy), reason: 'then by start');
    expect(find.byKey(const ValueKey('ribbon-icon-dentist|2026-09-25T16:00')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Focus, 10:00 – 11:30')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ribbon-icon-focus|2026-09-23T10:00')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'task focus 2026-09-23T10:00');

    await tester.tap(find.bySemanticsLabel(RegExp('^Friday, September 25')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('ribbon')).option<String>('scope', 'day'), 'day');
    expect(find.text('Friday, September 25'), findsOneWidget);
  });

  testWidgets('the scope toggle switches between day and week', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Week').last);
    await tester.pumpAndSettle();
    expect(find.text('Sep 21–27, 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 28 – Oct 4, 2026'), findsOneWidget, reason: 'weeks page by 7 days');
  });
}
