import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/month_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Month view (T3.6.07) and its semantic zoom / list-below mode (T3.6.08).
void main() {
  setUpAll(initializeDateFormatting);

  group('month grid', () {
    test('6-row months, 4-row February, leap years and any week start', () {
      expect(monthWeeks(LocalDate(2026, 8, 1), Weekday.monday).length, 6, reason: 'Aug 2026 starts on a Saturday');
      expect(monthWeeks(LocalDate(2026, 2, 1), Weekday.sunday).length, 4, reason: 'Feb 2026 = Sun 1 … Sat 28');
      final feb2028 = monthWeeks(LocalDate(2028, 2, 1), Weekday.monday);
      expect(feb2028.expand((w) => w).where((d) => d.month == 2).length, 29);
      final sat = monthWeeks(LocalDate(2026, 9, 1), Weekday.saturday);
      expect(sat.first.first, LocalDate(2026, 8, 29));
      expect(sat.every((w) => w.first.weekday == Weekday.saturday), isTrue);
    });

    test('month arithmetic across years', () {
      expect(addMonths(LocalDate(2026, 11, 15), 3), LocalDate(2027, 2, 1));
      expect(addMonths(LocalDate(2026, 1, 31), -1), LocalDate(2025, 12, 1));
      expect(monthsBetween(LocalDate(2026, 9, 1), LocalDate(2027, 1, 1)), 4);
    });

    test('density steps clamp at both ends', () {
      expect(MonthDensity.dots.step(-1), MonthDensity.dots);
      expect(MonthDensity.titles.step(1), MonthDensity.titlesTimes);
      expect(MonthDensity.parse('titles_times'), MonthDensity.titlesTimes);
    });
  });

  Future<PlannerHarness> pump(WidgetTester tester, {List<PlannerItem> items = const [], PlannerViewConfig Function(PlannerViewConfig c)? config}) async {
    final h = PlannerHarness.create(items: items);
    addTearDown(h.dispose);
    if (config != null) h.read(plannerViewConfigProvider('month').notifier).change(config);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'month', date: '2026-09-23'));
    await tester.pumpAndSettle();
    return h;
  }

  final items = [
    item('Gym', at(2026, 9, 21, 7), 60, id: 'gym'),
    item('Dentist', at(2026, 9, 24, 16), 45, id: 'dentist', recurring: true),
  ];

  testWidgets('shows the month with chips; tapping a day opens its day list', (tester) async {
    final h = await pump(tester, items: items);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('month-chip-gym|2026-09-21T07:00')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('month-day-2026-09-24')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'view day_list 2026-09-24');
  });

  testWidgets('next month pages; the anchor follows', (tester) async {
    final h = await pump(tester);
    await tester.tap(find.byKey(const Key('planner-next')));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(h.read(plannerAnchorProvider), LocalDate(2026, 10, 1));
  });

  testWidgets('dragging a recurring chip to another day asks for the scope and keeps the time', (tester) async {
    final h = await pump(tester, items: items);
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('month-chip-dentist|2026-09-24T16:00'))));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('month-day-2026-09-25'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('This occurrence'));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['reschedule Dentist 2026-09-25T16:00 45 thisOccurrence']);
  });

  testWidgets('long-press on an empty day quick-creates an all-day task', (tester) async {
    final h = await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('month-day-2026-09-10')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Party');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['create 2026-09-10T00:00 1440 Party allDay']);
  });

  testWidgets('pinching out walks the densities; list-below shows the selected day', (tester) async {
    final h = await pump(tester, items: items, config: (c) => c.withOption('monthMode', 'dots'));
    final center = tester.getCenter(find.byKey(const ValueKey('month-day-2026-09-16')));
    final a = await tester.startGesture(center - const Offset(20, 0), pointer: 1);
    final b = await tester.startGesture(center + const Offset(20, 0), pointer: 2);
    for (var i = 1; i <= 8; i++) {
      await a.moveTo(center - Offset(20.0 + i * 12, 0));
      await b.moveTo(center + Offset(20.0 + i * 12, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('month')).option<String>('monthMode', ''), isNot('dots'));

    h.read(plannerViewConfigProvider('month').notifier).change((c) => c.withOption('listBelow', true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('month-day-2026-09-21')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('month-day-list-2026-09-21')), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('expand inline shows the day under its week', (tester) async {
    await pump(tester, items: items, config: (c) => c.withOption('tapAction', 'expand'));
    await tester.tap(find.byKey(const ValueKey('month-day-2026-09-24')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('month-day-list-2026-09-24')), findsOneWidget);
  });
}
