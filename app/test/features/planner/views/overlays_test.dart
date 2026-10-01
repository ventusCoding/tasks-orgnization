import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/overlays.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Overlays framework (T3.3.23) with fake overlay providers.
void main() {
  final wed = LocalDate(2026, 9, 23);
  final queries = <OverlayQuery>[];

  Future<PlannerHarness> pump(
    WidgetTester tester,
    Map<String, bool> overlays, {
    Locale locale = const Locale('en'),
  }) async {
    queries.clear();
    final h = PlannerHarness.create(
      items: [item('Standup', at(2026, 9, 23, 9), 30), item('Last week', at(2026, 9, 16, 14), 60)],
      overrides: [
        plannerOverlayMarkersProvider.overrideWith((ref, q) {
          queries.add(q);
          return [
            if (q.habits)
              OverlayMarker(
                kind: OverlayMarkerKind.habit,
                id: 'habit|h1|2026-09-23T08:00',
                targetId: 'h1',
                periodKey: '2026-09-23T08:00',
                day: wed,
                minute: 8 * 60,
                label: 'Stretch',
              ),
            if (q.checklistDue)
              OverlayMarker(
                kind: OverlayMarkerKind.checklistDue,
                id: 'item|i1',
                targetId: 'list-1',
                itemId: 'i1',
                day: wed,
                minute: 11 * 60,
                label: 'Send report',
              ),
          ];
        }),
      ],
    );
    addTearDown(h.dispose);
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    notifier.update(h.read(plannerViewConfigProvider('week_table')).copyWith(overlays: overlays));
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(
      tester,
      h,
      Scaffold(
        body: TimeGrid(viewKey: 'week_table', controller: controller),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
    controller.scrollToMinute(7 * 60, animate: false);
    await tester.pumpAndSettle();
    return h;
  }

  bool painted<T>() => find.byWidgetPredicate((w) => w is CustomPaint && w.painter is T).evaluate().isNotEmpty;

  testWidgets('habit and checklist markers appear at their time; a due item opens its list', (tester) async {
    final h = await pump(tester, {'habits': true, 'checklistDue': true});
    expect(queries.any((q) => q.habits && q.checklistDue && q.range.contains(wed)), isTrue);
    expect(find.byKey(const ValueKey('overlay-habit|h1|2026-09-23T08:00')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-item|i1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('overlay-item|i1')));
    await tester.pump();
    expect(h.nav.log, contains('checklist list-1 i1'));
  });

  testWidgets('markers follow the mirrored day columns in RTL', (tester) async {
    await pump(tester, {'checklistDue': true}, locale: const Locale('ar'));
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    final inColumn = grid.globalPositionOf(wed, 11 * 60 + 5)!;
    final rect = tester.getRect(find.byKey(const ValueKey('overlay-item|i1')));
    expect(rect.left <= inColumn.dx && inColumn.dx <= rect.right, isTrue, reason: '$rect vs $inColumn');
  });

  testWidgets('turning an overlay off removes its layer', (tester) async {
    await pump(tester, {'habits': false, 'checklistDue': false});
    expect(find.byType(OverlayMarkerChip), findsNothing);
    expect(painted<FreeSlotsPainter>(), isFalse);
    expect(painted<HeatTintPainter>(), isFalse);
  });

  testWidgets('free-slot shading and the heat tint are painted when enabled', (tester) async {
    await pump(tester, {'freeSlots': true, 'heat': true});
    expect(painted<FreeSlotsPainter>(), isTrue);
    expect(painted<HeatTintPainter>(), isTrue);
    final heat =
        tester
                .widgetList<CustomPaint>(
                  find.byWidgetPredicate((w) => w is CustomPaint && w.painter is HeatTintPainter),
                )
                .first
                .painter!
            as HeatTintPainter;
    expect(heat.grid.minutes(3, 14), 60, reason: 'last Wednesday 14:00 is in the four weeks before the page');
  });
}
