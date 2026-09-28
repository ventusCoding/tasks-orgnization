import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

Future<PlannerHarness> _pump(
  WidgetTester tester, {
  List<PlannerItem> items = const [],
  PlannerViewConfig Function(PlannerViewConfig c)? config,
  String? date = '2026-09-23',
}) async {
  final h = PlannerHarness.create(items: items);
  addTearDown(h.dispose);
  if (config != null) {
    h.read(plannerViewConfigProvider('day_list').notifier).update(config(h.read(plannerViewConfigProvider('day_list'))));
  }
  await pumpPlanner(tester, h, PlannerScreen(view: 'day_list', date: date));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('opens on the date with the week strip and the 30-min slots', (tester) async {
    await _pump(tester, items: [item('Gym', at(2026, 9, 23, 9, 15), 60)]);
    expect(find.text('Wednesday, September 23'), findsOneWidget);
    for (var d = 21; d <= 27; d++) {
      expect(find.byKey(Key('strip-2026-09-$d')), findsOneWidget);
    }
    expect(find.text('Gym'), findsOneWidget, reason: 'an item appears once, in its start row');
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('tapping the check marks done; tapping the chip opens the task', (tester) async {
    final gym = item('Gym', at(2026, 9, 23, 9, 15), 60, id: 'gym');
    final h = await _pump(tester, items: [gym]);
    await tester.tap(find.byKey(Key('check-${gym.key}')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['status Gym done']);
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(h.nav.log, ['task gym ${gym.occurrenceKey}']);
  });

  testWidgets('swipe right marks done, swipe left skips', (tester) async {
    final h = await _pump(tester, items: [item('Gym', at(2026, 9, 23, 9, 15), 60)]);
    await tester.drag(find.text('Gym'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(h.backend.calls.last, 'status Gym done');
    await tester.drag(find.text('Gym'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(h.backend.calls.last, isNot('status Gym skipped'), reason: 'done items only swipe back to open');
  });

  testWidgets('tapping an empty row quick-creates at its start', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Call');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['create 2026-09-23T10:00 30 Call']);
  });

  testWidgets('selecting a strip day changes the day', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('strip-2026-09-25')));
    await tester.pumpAndSettle();
    expect(find.text('Friday, September 25'), findsOneWidget);
  });

  testWidgets('swiping the list moves to the next day', (tester) async {
    await _pump(tester);
    await tester.fling(find.byKey(const Key('day-pages')), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Thursday, September 24'), findsOneWidget);
  });

  testWidgets('the now divider sits in the current slot on today', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('now-divider')), findsOneWidget);
  });

  testWidgets('collapsing empty slots shows free runs with actions', (tester) async {
    await _pump(tester, items: [item('Gym', at(2026, 9, 23, 9), 60)], config: (c) => c.copyWith(hideEmptySlots: true));
    expect(find.textContaining('Free 00:00–09:00'), findsOneWidget);
    await tester.tap(find.textContaining('Free 10:00–24:00'));
    await tester.pumpAndSettle();
    expect(find.text('Create here'), findsOneWidget);
    expect(find.text('Expand'), findsOneWidget);
  });

  testWidgets('24-hour slots show the day as an agenda, all-day first', (tester) async {
    await _pump(
      tester,
      items: [item('Gym', at(2026, 9, 23, 7), 60), item('Birthday', at(2026, 9, 23), 1440, allDay: true)],
      config: (c) => c.withSlot(1440),
    );
    expect(find.byKey(const Key('day-agenda')), findsOneWidget);
    final birthday = tester.getTopLeft(find.text('Birthday'));
    final gym = tester.getTopLeft(find.text('Gym'));
    expect(birthday.dy, lessThan(gym.dy));
  });

  testWidgets('all-day items are listed in the collapsible section', (tester) async {
    await _pump(tester, items: [item('Trip', at(2026, 9, 22), 3 * 1440, allDay: true)]);
    expect(find.text('Trip'), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-day-header')));
    await tester.pumpAndSettle();
    expect(find.text('Trip'), findsNothing);
  });

  testWidgets('long-press an item and drag it to another row reschedules it', (tester) async {
    final h = await _pump(tester, items: [item('Gym', at(2026, 9, 23, 9), 60)]);
    final from = tester.getCenter(find.text('Gym'));
    final to = tester.getCenter(find.text('11:00'));
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(Offset(from.dx, to.dy + 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['reschedule Gym 2026-09-23T11:00 60 thisOccurrence']);
  });

  testWidgets('long-press on empty rows and drag creates a range', (tester) async {
    final h = await _pump(tester);
    final from = tester.getCenter(find.text('10:00'));
    final to = tester.getCenter(find.text('11:00'));
    final gesture = await tester.startGesture(from + const Offset(150, 0));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(Offset(from.dx + 150, to.dy + 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Focus');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['create 2026-09-23T10:00 90 Focus']);
  });

  testWidgets('selection mode: Select from the item menu, then taps toggle items', (tester) async {
    final h = await _pump(tester, items: [item('Gym', at(2026, 9, 23, 9, 15), 60), item('Read', at(2026, 9, 23, 11), 30)]);
    await tester.longPress(find.text('Gym'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tile-menu-select')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Gym'));
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selection-toolbar')), findsNothing, reason: 'the last toggle ends selection mode');
    expect(h.nav.log, isEmpty);
  });

  testWidgets('day actions in the menu run through planner-core (one operation)', (tester) async {
    await _pump(tester, items: [item('Gym', at(2026, 9, 23, 18), 60)]);
    await tester.tap(find.byKey(const Key('planner-more')));
    await tester.pumpAndSettle();
    expect(find.text('Mark all remaining as done'), findsOneWidget);
    expect(find.text('Skip the rest of the day'), findsOneWidget);
    expect(find.text('Move unfinished to tomorrow'), findsOneWidget);
  });

  testWidgets('day summary: planned, free in work hours, done/total; tap opens insights', (tester) async {
    final h = await _pump(
      tester,
      items: [item('Gym', at(2026, 9, 23, 9), 60, status: OccurrenceStatus.done), item('Read', at(2026, 9, 23, 13), 30)],
    );
    expect(find.byKey(const Key('day-summary')), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('6 h 30 min'), findsOneWidget, reason: '09:00–17:00 minus 1 h 30 planned');
    await tester.tap(find.byKey(const Key('day-summary')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'insights 2026-09-23 1');
  });

  testWidgets('ribbon style shows blocks and free connectors', (tester) async {
    await _pump(
      tester,
      items: [item('Gym', at(2026, 9, 23, 7), 60), item('Read', at(2026, 9, 23, 9), 30)],
      config: (c) => c.withOption('style', 'ribbon'),
    );
    expect(find.byKey(const Key('day-ribbon')), findsOneWidget);
    expect(find.text('free 1 h'), findsOneWidget);
    expect(find.byKey(const Key('ribbon-now')), findsOneWidget);
  });
}
