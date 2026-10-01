import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/free_slots_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Openings (T3.7.04). Clock: Wed 23 Sep 2026 09:30 UTC; default work hours 09:00–17:00 Mon–Fri.
void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('lists openings from now inside work hours; share copies the availability text', (tester) async {
    final shared = <String>[];
    final h = PlannerHarness.create(
      items: [item('Review', at(2026, 9, 23, 11), 60), item('Gym', at(2026, 9, 24, 9), 480)],
      overrides: [availabilitySharerProvider.overrideWithValue((t) async => shared.add(t))],
    );
    addTearDown(h.dispose);
    h.read(plannerViewConfigProvider('free_slots').notifier).change((c) => c.withOption('days', 3));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'free_slots'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('opening-2026-09-23T09:30')), findsOneWidget, reason: 'starts now');
    expect(find.text('09:30 – 11:00 · 1 h 30 min'), findsOneWidget);
    expect(find.byKey(const ValueKey('opening-2026-09-23T12:00')), findsOneWidget);
    expect(find.byKey(const ValueKey('opening-2026-09-24T09:00')), findsNothing, reason: 'Thursday is fully busy');
    expect(find.byKey(const ValueKey('opening-2026-09-25T09:00')), findsOneWidget);

    await tester.tap(find.byKey(const Key('free-share')));
    await tester.pumpAndSettle();
    expect(shared.single, 'Wed 23 Sep: 09:30–11:00, 12:00–17:00\nFri 25 Sep: 09:00–17:00');
  });

  testWidgets('fill this gap schedules a fitting backlog item; create here prefills the start', (tester) async {
    final h = PlannerHarness.create(items: [item('Review', at(2026, 9, 23, 11), 60)]);
    addTearDown(h.dispose);
    h.backend.backlog.addAll([
      copyItem(item('Write memo', at(2026, 9, 23), 30, id: 'memo'), estimateMinutes: 45),
      copyItem(item('Big project', at(2026, 9, 23), 30, id: 'big'), estimateMinutes: 240),
    ]);
    h.read(plannerViewConfigProvider('free_slots').notifier).change((c) => c.withOption('days', 1));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'free_slots'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fill-gap-2026-09-23T09:30')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fill-memo')), findsOneWidget);
    expect(find.byKey(const ValueKey('fill-big')), findsNothing, reason: '4 h does not fit 1 h 30');
    await tester.tap(find.byKey(const ValueKey('fill-memo')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['schedule Write memo 2026-09-23T09:30 45']);

    await tester.tap(find.byKey(const ValueKey('create-here-2026-09-23T12:00')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quick-create-title')), 'Call');
    await tester.tap(find.byKey(const Key('quick-create-submit')));
    await tester.pumpAndSettle();
    expect(h.backend.calls.last, 'create 2026-09-23T12:00 30 Call');
  });

  testWidgets('the minimum gap filters short openings', (tester) async {
    final h = PlannerHarness.create(
      items: [item('A', at(2026, 9, 23, 9, 30), 60), item('B', at(2026, 9, 23, 10, 50), 370)],
    );
    addTearDown(h.dispose);
    h.read(plannerViewConfigProvider('free_slots').notifier).change((c) => c.withOption('days', 1));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'free_slots'));
    await tester.pumpAndSettle();
    expect(find.text('No free time found'), findsOneWidget, reason: '20-min gap < 30-min default');
    h.read(plannerViewConfigProvider('free_slots').notifier).change((c) => c.withOption('minGap', 15));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('opening-2026-09-23T10:30')), findsOneWidget);
  });
}
