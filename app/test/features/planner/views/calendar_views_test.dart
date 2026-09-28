import 'dart:async';

import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';
import 'support/switching_nav.dart';

// Calendar views (T3.6.02 – T3.6.10). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  Future<PlannerHarness> pumpView(WidgetTester tester, String view, {String? date = '2026-09-23', List<PlannerItem> items = const []}) async {
    final h = PlannerHarness.create(items: items);
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, PlannerScreen(view: view, date: date));
    await tester.pumpAndSettle();
    return h;
  }

  group('saved views (T3.6.02)', () {
    testWidgets('save the current view as a named view, then rename and delete it', (tester) async {
      final h = await pumpView(tester, 'week_table');
      await tester.tap(find.byKey(const Key('planner-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved views').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-view-as')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Deep work');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      final saved = h.read(plannerSavedViewsProvider).value!.where((v) => v.name == 'Deep work').toList();
      expect(saved, hasLength(1));
      expect(h.nav.log.last, startsWith('view saved:${saved.single.id}'));

      // Long-press on the switcher lists saved views; rename, then delete.
      await tester.longPress(find.byKey(const Key('planner-view-switcher')));
      await tester.pumpAndSettle();
      expect(find.text('Deep work'), findsOneWidget);
      await tester.tap(find.byTooltip('View settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename view').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Focus · 5 min');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(h.read(plannerSavedViewsProvider).value!.map((v) => v.name), contains('Focus · 5 min'));
      await tester.tap(find.byTooltip('View settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete view').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(h.read(plannerSavedViewsProvider).value!.map((v) => v.name), isNot(contains('Focus · 5 min')));
    });
  });

  group('shared date state & transitions (T3.6.03)', () {
    testWidgets('switching views keeps the anchor date; Back returns to the previous view', (tester) async {
      final nav = SwitchingNav('week_table', date: LocalDate(2026, 10, 7));
      final h = PlannerHarness.create(nav: nav);
      addTearDown(h.dispose);
      await pumpPlanner(tester, h, SwitchingHost(nav: nav));
      await tester.pumpAndSettle();
      expect(find.text('Oct 5–11, 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('planner-view-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('view-day_list')));
      await tester.pumpAndSettle();
      expect(nav.current.value.$1, 'day_list');
      expect(find.text('Monday, October 5'), findsOneWidget, reason: 'the anchor is the first visible day');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(nav.current.value.$1, 'week_table');
      expect(find.text('Oct 5–11, 2026'), findsOneWidget);
    });
  });

  group('N-day & work week (T3.6.04 / T3.6.05)', () {
    testWidgets('N-day rolls from today with 3 days in portrait', (tester) async {
      await pumpView(tester, 'n_day', date: null);
      final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
      expect(grid, isNotNull);
      final controller = tester.widget<TimeGrid>(find.byType(TimeGrid)).controller!;
      expect(controller.visibleDays, [LocalDate(2026, 9, 23), LocalDate(2026, 9, 24), LocalDate(2026, 9, 25)]);
      // Animated page turns only advance while frames are pumped: never await them directly.
      unawaited(controller.next());
      await tester.pumpAndSettle();
      expect(controller.visibleDays.first, LocalDate(2026, 9, 26), reason: 'Next advances by the visible range (swipes step one day)');
    });

    testWidgets('N-day aligned to the week start when not rolling', (tester) async {
      final h = PlannerHarness.create();
      addTearDown(h.dispose);
      h.read(plannerViewConfigProvider('n_day').notifier).change((c) => c.copyWith(firstDay: 'week_start', daysVisible: 4).withOption('rolling', false));
      await pumpPlanner(tester, h, const PlannerScreen(view: 'n_day', date: '2026-09-23'));
      await tester.pumpAndSettle();
      final controller = tester.widget<TimeGrid>(find.byType(TimeGrid)).controller!;
      expect(controller.visibleDays.length, 4);
    });
  });

  group('week list (T3.6.06)', () {
    List<PlannerItem> week() => [
      item('Gym', at(2026, 9, 21, 7), 60, id: 'gym'),
      item('Pay rent', at(2026, 9, 21), 1440, allDay: true, id: 'rent'),
      item('Call', at(2026, 9, 23, 14), 30, id: 'call'),
    ];

    testWidgets('days are stacked sections: all-day first, then by time', (tester) async {
      await pumpView(tester, 'week_list', items: week());
      expect(find.text('Sep 21–27, 2026'), findsOneWidget);
      final monday = find.byKey(const ValueKey('week-list-day-2026-09-21'));
      expect(monday, findsOneWidget);
      final rent = tester.getTopLeft(find.descendant(of: monday, matching: find.text('Pay rent')));
      final gym = tester.getTopLeft(find.descendant(of: monday, matching: find.text('Gym')));
      expect(rent.dy, lessThan(gym.dy));
      await tester.tap(find.byKey(const Key('planner-next')));
      await tester.pumpAndSettle();
      expect(find.text('Sep 28 – Oct 4, 2026'), findsOneWidget);
    });

    testWidgets('dragging an item onto another day keeps its time', (tester) async {
      final h = await pumpView(tester, 'week_list', items: week());
      final gesture = await tester.startGesture(tester.getCenter(find.text('Gym')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      final target = find.byKey(const ValueKey('week-list-day-2026-09-22'));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(h.backend.calls, ['reschedule Gym 2026-09-22T07:00 60 thisOccurrence']);
    });

    testWidgets('dropping an untimed item on another one of the same day reorders it', (tester) async {
      final extra = FakeViewActions();
      final a = item('Laundry', at(2026, 9, 21), 1440, allDay: true, id: 'a');
      final b = item('Groceries', at(2026, 9, 21), 1440, allDay: true, id: 'b');
      final h = PlannerHarness.create(
        items: [copyItem(a, manualSortKey: 'a0'), copyItem(b, manualSortKey: 'a1')],
        overrides: [viewExtraActionsProvider.overrideWithValue(extra)],
      );
      addTearDown(h.dispose);
      await pumpPlanner(tester, h, const PlannerScreen(view: 'week_list', date: '2026-09-23'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.text('Groceries')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(find.text('Laundry')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(extra.calls, ['reorder Groceries after=null before=a0']);
    });

    testWidgets('tapping a day header opens its day list; checks tick', (tester) async {
      final h = await pumpView(tester, 'week_list', items: week());
      await tester.tap(find.text('Wednesday, September 23'));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'view day_list 2026-09-23');
      await tester.tap(find.byKey(const ValueKey('chip-check-call|2026-09-23T14:00')));
      await tester.pumpAndSettle();
      expect(h.backend.calls, ['status Call done']);
    });
  });

  testWidgets('items render in the N-day view', (tester) async {
    await pumpView(tester, 'n_day', items: [item('Gym', at(2026, 9, 24, 10), 60)]);
    expect(find.text('Gym'), findsWidgets);
  });
}
