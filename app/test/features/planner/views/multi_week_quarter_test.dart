import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/multi_week_view.dart';
import 'package:everslot/features/planner/presentation/views/quarter_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Multi-week (T3.6.11) and quarter (T3.6.12) views. Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  Future<PlannerHarness> pump(
    WidgetTester tester,
    String view, {
    List<PlannerItem> items = const [],
    String date = '2026-09-23',
    Size size = const Size(420, 860),
    PlannerViewConfig Function(PlannerViewConfig c)? config,
  }) async {
    final h = PlannerHarness.create(items: items);
    addTearDown(h.dispose);
    if (config != null) h.read(plannerViewConfigProvider(view).notifier).change(config);
    await pumpPlanner(
      tester,
      h,
      PlannerScreen(view: view, date: date),
      size: size,
    );
    await tester.pumpAndSettle();
    return h;
  }

  group('multi-week (T3.6.11)', () {
    final items = [
      item('Gym', at(2026, 9, 21, 7), 60, id: 'gym'),
      item('Review', at(2026, 10, 8, 14), 30, id: 'review'),
    ];

    test('the week count option clamps to 2–6 (default 4)', () {
      final d = PlannerViewConfig.defaultsFor(PlannerViewType.multiWeek);
      expect(multiWeekCount(d), 4);
      expect(multiWeekCount(d.withOption('weeks', 9)), 6);
      expect(multiWeekCount(d.withOption('weeks', 1)), 2);
    });

    testWidgets('rolling rows from this week with chips; the 1st of a month is labelled', (tester) async {
      await pump(tester, 'multi_week', items: items);
      expect(find.text('Sep 21 – Oct 18, 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('month-day-2026-09-21')), findsOneWidget);
      expect(find.byKey(const ValueKey('month-day-2026-10-18')), findsOneWidget);
      expect(find.byKey(const ValueKey('month-day-2026-10-19')), findsNothing);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Oct 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('planner-next')));
      await tester.pumpAndSettle();
      expect(find.text('Sep 28 – Oct 25, 2026'), findsOneWidget, reason: 'rolls by one week');
    });

    testWidgets('the week menu and a vertical pinch change the number of rows', (tester) async {
      final h = await pump(tester, 'multi_week');
      await tester.tap(find.byKey(const Key('multi-week-count')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 weeks').last);
      await tester.pumpAndSettle();
      expect(multiWeekCount(h.read(plannerViewConfigProvider('multi_week'))), 2);
      expect(find.text('Sep 21 – Oct 4, 2026'), findsOneWidget);

      // Pinch (fingers move closer vertically) → more weeks.
      final center = tester.getCenter(find.byKey(const ValueKey('month-day-2026-09-23')));
      final a = await tester.startGesture(center.translate(0, -150), pointer: 1);
      final b = await tester.startGesture(center.translate(0, 150), pointer: 2);
      await tester.pump();
      for (var i = 1; i <= 10; i++) {
        await a.moveTo(center.translate(0, -150 + i * 10.0));
        await b.moveTo(center.translate(0, 150 - i * 10.0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(multiWeekCount(h.read(plannerViewConfigProvider('multi_week'))), greaterThan(2));
    });

    testWidgets('tap opens the day; dragging a chip to another day keeps its time', (tester) async {
      final h = await pump(tester, 'multi_week', items: items);
      await tester.tap(find.byKey(const ValueKey('month-day-2026-09-24')));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'view day_list 2026-09-24');

      final gesture = await tester.startGesture(tester.getCenter(find.text('Gym')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('month-day-2026-09-30'))));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(h.backend.calls, ['reschedule Gym 2026-09-30T07:00 60 thisOccurrence']);
    });
  });

  group('quarter (T3.6.12)', () {
    test('quarter start', () {
      expect(quarterStart(LocalDate(2026, 9, 23)), LocalDate(2026, 7, 1));
      expect(quarterStart(LocalDate(2026, 10, 1)), LocalDate(2026, 10, 1));
      expect(quarterStart(LocalDate(2027, 3, 31)), LocalDate(2027, 1, 1));
    });

    final items = [item('Gym', at(2026, 7, 6, 7), 60, id: 'gym'), item('Trip', at(2026, 9, 23, 9), 60, id: 'trip')];

    testWidgets('three months stacked on a phone; tap opens the day, a month name opens the month', (tester) async {
      final h = await pump(tester, 'quarter', items: items);
      expect(find.text('Q3 2026'), findsOneWidget);
      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      final july = tester.getTopLeft(find.text('July 2026'));
      final august = tester.getTopLeft(find.text('August 2026'));
      expect(august.dy, greaterThan(july.dy), reason: 'stacked');
      expect(tester.getSemantics(find.byKey(const ValueKey('quarter-day-2026-07-06'))).label, contains('1 item'));
      await tester.tap(find.byKey(const ValueKey('quarter-month-2026-08-01')));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'view month 2026-08-01');
      await tester.tap(find.byKey(const Key('planner-next')));
      await tester.pumpAndSettle();
      expect(find.text('Q4 2026'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('quarter-day-2026-12-24')), 200);
      await tester.tap(find.byKey(const ValueKey('quarter-day-2026-12-24')));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'view day_list 2026-12-24');
    });

    testWidgets('side by side on a tablet; long-press creates an all-day task', (tester) async {
      final h = await pump(tester, 'quarter', items: items, size: const Size(1100, 800));
      final july = tester.getTopLeft(find.text('July 2026'));
      final august = tester.getTopLeft(find.text('August 2026'));
      expect(august.dy, july.dy);
      expect(august.dx, greaterThan(july.dx));
      await tester.longPress(find.byKey(const ValueKey('quarter-day-2026-08-12')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('quick-create-title')), 'Holiday');
      await tester.tap(find.byKey(const Key('quick-create-submit')));
      await tester.pumpAndSettle();
      expect(h.backend.calls, ['create 2026-08-12T00:00 1440 Holiday allDay']);
    });
  });
}
