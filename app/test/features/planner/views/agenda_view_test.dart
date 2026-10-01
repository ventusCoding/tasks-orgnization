import 'dart:math' as math;

import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Agenda / schedule view (T3.6.09). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  Future<PlannerHarness> pump(
    WidgetTester tester, {
    List<PlannerItem> items = const [],
    PlannerViewConfig Function(PlannerViewConfig c)? config,
  }) async {
    final h = PlannerHarness.create(items: items);
    addTearDown(h.dispose);
    if (config != null) {
      h.read(plannerViewConfigProvider('agenda').notifier).change(config);
    }
    await pumpPlanner(tester, h, const PlannerScreen(view: 'agenda', date: '2026-09-23'));
    await tester.pumpAndSettle();
    return h;
  }

  final items = [
    item('Gym', at(2026, 9, 23, 7), 60, id: 'gym'),
    item('Call', at(2026, 9, 23, 14), 30, id: 'call', notes: 'Bring the contract'),
    item('Dentist', at(2026, 9, 25, 16), 45, id: 'dentist'),
    item('Trip', at(2026, 10, 20, 9), 60, id: 'trip'),
    item('Old report', at(2026, 9, 10, 9), 60, id: 'old'),
  ];

  testWidgets('opens on the date; days with items are grouped; empty days collapse', (tester) async {
    await pump(tester, items: items);
    expect(find.text('Wednesday, September 23'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Friday, September 25'), findsOneWidget);
    expect(find.text('Thursday, September 24'), findsNothing, reason: 'empty days collapse');
    expect(find.byKey(const Key('day-ticker')), findsOneWidget);
  });

  testWidgets('show empty days and notes preview', (tester) async {
    await pump(tester, items: items, config: (c) => c.withOption('showEmptyDays', true).withOption('showNotes', true));
    expect(find.text('Thursday, September 24'), findsOneWidget);
    expect(find.text('Bring the contract'), findsOneWidget);
  });

  testWidgets('checks tick inline; edits update the rows in place', (tester) async {
    final h = await pump(tester, items: items);
    await tester.tap(find.byKey(const ValueKey('chip-check-gym|2026-09-23T07:00')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['status Gym done']);
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('scrolling forward loads the next ranges and the anchor follows the day at the top', (tester) async {
    final dense = [
      for (var d = 0; d < 45; d++)
        for (var k = 0; k < 3; k++)
          item('D$d-$k', LocalDate(2026, 9, 23).plusDays(d).atTime(LocalTime(8 + k * 3, 0)), 30),
    ];
    final h = await pump(tester, items: dense);
    await tester.dragUntilVisible(find.text('D30-1'), find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('D30-1'), findsOneWidget);
    final anchor = h.read(plannerAnchorProvider)!;
    expect(anchor.isAfter(LocalDate(2026, 10, 15)), isTrue);
    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('scrolling back in time reaches earlier days without moving the anchor content', (tester) async {
    final h = await pump(tester, items: items);
    await tester.dragUntilVisible(find.text('Old report'), find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Old report'), findsOneWidget);
    expect(find.text('Thursday, September 10'), findsOneWidget);
    expect(h.read(plannerAnchorProvider)!.isBefore(LocalDate(2026, 9, 23)), isTrue);
  });

  testWidgets('the day ticker jumps to a day; tapping a header opens its day list', (tester) async {
    final h = await pump(tester, items: items);
    await tester.tap(find.byKey(const ValueKey('ticker-2026-09-25')));
    await tester.pumpAndSettle();
    expect(h.read(plannerAnchorProvider), LocalDate(2026, 9, 25));
    await tester.tap(find.byKey(const ValueKey('agenda-header-2026-09-25')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'view day_list 2026-09-25');
  });

  testWidgets('performance: 5 000 occurrences over six months scroll without errors', (tester) async {
    final random = math.Random(3);
    final many = [
      for (var i = 0; i < 5000; i++)
        item('Item $i', LocalDate(2026, 9, 23).plusDays(i % 180).atStartOfDay.plusMinutes(random.nextInt(1380)), 30),
    ];
    await pump(tester, items: many);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 40; i++) {
      await tester.fling(find.byType(CustomScrollView), const Offset(0, -3000), 6000);
      for (var f = 0; f < 6; f++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    expect(sw.elapsed, lessThan(const Duration(seconds: 50)), reason: 'debug-mode sanity bound');
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Item'), findsWidgets);
  });
}
