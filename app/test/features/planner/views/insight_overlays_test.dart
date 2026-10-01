// In-view insights overlays (T6.3.20): the week-table slot-occupancy layer (PL-X-35/36) at the
// view's slot size, day-header utilization bars with the overbooked badge and its explanation, and
// the long-press series preview of recurring tiles.
import 'dart:ui' show PictureRecorder;

import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/overlays.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/grid/timeline_page.dart';
import 'package:everslot/features/stats/application/planner_overlays.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

void main() {
  final slotRequests = <int>[];
  final occupancy = SlotOccupancyOverlay(
    60,
    {for (var h = 9; h < 12; h++) (3, h * 60): 0.75, (1, 600): 0.25},
    const {(2, 840)},
  );

  Future<PlannerHarness> pump(WidgetTester tester, Map<String, bool> overlays, {int? slotMinutes}) async {
    slotRequests.clear();
    final h = PlannerHarness.create(
      items: [
        item('Standup', at(2026, 9, 23, 9), 30, id: 'standup', recurring: true),
        // 10 h on Tuesday: more than the 8 h of default work hours.
        item('Workshop', at(2026, 9, 22, 8), 600, id: 'workshop'),
      ],
      overrides: [
        slotOccupancyOverlayProvider.overrideWith((ref, size) async {
          slotRequests.add(size);
          return SlotOccupancyOverlay(size, occupancy.planned, occupancy.dead);
        }),
        seriesMiniStatsProvider.overrideWith((ref, id) async => const SeriesMiniStats(adherence: 0.8, streak: 5)),
      ],
    );
    addTearDown(h.dispose);
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    var config = h.read(plannerViewConfigProvider('week_table')).copyWith(overlays: overlays);
    if (slotMinutes != null) config = config.copyWith(slotMinutes: slotMinutes);
    notifier.update(config);
    final controller = PlannerGridController();
    addTearDown(controller.dispose);
    await pumpPlanner(
      tester,
      h,
      Scaffold(
        body: TimeGrid(viewKey: 'week_table', controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    controller.scrollToMinute(8 * 60, animate: false);
    await tester.pumpAndSettle();
    return h;
  }

  /// Disposes the grid and runs its pending timers before the test ends.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  Iterable<SlotOccupancyPainter> occupancyPainters(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is SlotOccupancyPainter))
      .map((w) => w.painter! as SlotOccupancyPainter);

  testWidgets('the occupancy layer follows the slot size of the view and its toggle', (tester) async {
    await pump(tester, {'occupancy': false});
    expect(occupancyPainters(tester), isEmpty);

    await pump(tester, {'occupancy': true}, slotMinutes: 60);
    expect(slotRequests, contains(60));
    expect(occupancyPainters(tester).first.overlay.slotMinutes, 60);

    await pump(tester, {'occupancy': true}, slotMinutes: 30);
    expect(slotRequests, contains(30));
    expect(occupancyPainters(tester).first.overlay.slotMinutes, 30);
    await finish(tester);
  });

  testWidgets('the occupancy layer paints a week of 15-minute slots within the frame budget', (tester) async {
    final days = [for (var i = 0; i < 7; i++) LocalDate(2026, 9, 21).plusDays(i)];
    await pump(tester, {'occupancy': true}, slotMinutes: 15);
    final painter = occupancyPainters(tester).first;
    final page = PageOverlayContext(
      days: days,
      slices: const {},
      axis: painter.page.axis,
      ppm: painter.page.ppm,
      rtl: false,
      style: painter.page.style,
    );
    final full = SlotOccupancyPainter(
      page: page,
      overlay: SlotOccupancyOverlay(15, {for (var m = 0; m < 1440; m += 15) (3, m): (m % 120) / 120}, const {(3, 600)}),
      color: Colors.blue,
      deadColor: Colors.orange,
    );
    final watch = Stopwatch()..start();
    for (var i = 0; i < 10; i++) {
      final recorder = PictureRecorder();
      full.paint(Canvas(recorder), const Size(360, 2400));
      recorder.endRecording().dispose();
    }
    // Debug-mode smoke budget per paint (profile timings: [9.1] device suite).
    expect(watch.elapsedMicroseconds / 10, lessThan(8000));
    await finish(tester);
  });

  testWidgets('utilization bars, the overbooked badge and its explanation in the day menu', (tester) async {
    final h = await pump(tester, {'utilization': true});
    expect(find.byKey(const ValueKey('day-utilization-bar')), findsWidgets);
    expect(find.byKey(const ValueKey('day-overbooked-badge')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Overbooked by 2 h')), findsOneWidget);

    await tester.longPress(find.byKey(const ValueKey('day-overbooked-badge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('day-utilization-explain')), findsOneWidget);
    expect(find.textContaining('10 h planned for 8 h of work hours'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-utilization-explain')));
    await tester.pumpAndSettle();
    expect(h.nav.log.any((e) => e.startsWith('insights')), isTrue);
    await finish(tester);
  });

  testWidgets('without the toggle the headers have no utilization bar', (tester) async {
    await pump(tester, {'utilization': false});
    expect(find.byKey(const ValueKey('day-utilization-bar')), findsNothing);
    await finish(tester);
  });

  testWidgets('holding a recurring tile previews its series; moving hides the preview', (tester) async {
    await pump(tester, {});
    final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
    final at0 = grid.globalPositionOf(LocalDate(2026, 9, 23), 9 * 60 + 10)!;
    final gesture = await tester.startGesture(at0);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byKey(const ValueKey('series-preview')), findsOneWidget);
    expect(find.text('80% done · streak 5'), findsOneWidget);
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(find.byKey(const ValueKey('series-preview')), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
    await finish(tester);
  });
}
