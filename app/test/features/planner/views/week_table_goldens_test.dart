// Week table goldens (T3.4.20, covering the painter T3.3.07, ruler T3.3.08, header T3.3.09, tiles
// T3.3.10, table T3.3.12, lane T3.3.18, DST T3.3.04 / T3.4.15): 1, 5, 30, 120 and 1 440-minute
// slots × light LTR / dark RTL, plus dark LTR, light RTL and text scale 2.0 at 30 min, compact
// density and both Paris DST weeks. Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/views/first_use_hints.dart';
import 'package:everslot/features/planner/presentation/views/time_grid_view.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot/features/stats/application/planner_overlays.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/golden_support.dart';
import 'support/planner_harness.dart';

void main() {
  Future<void> golden(
    WidgetTester tester,
    String name, {
    required GoldenVariant variant,
    int slot = 30,
    PlannerViewConfig Function(PlannerViewConfig c)? config,
    String zone = 'UTC',
    LocalDate? date,
    List<PlannerItem>? items,
    double? minute,
    Size size = const Size(420, 860),
    List<Override> overrides = const [],
  }) async {
    final h = PlannerHarness.create(items: items ?? goldenWeek(), zone: zone, overrides: overrides);
    addTearDown(h.dispose);
    h.read(plannerViewStateProvider('week_table').notifier).update((s) => s.withExtra('hintsSeen', plannerHintIds));
    final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
    var c = h.read(plannerViewConfigProvider('week_table')).withSlot(slot);
    if (config != null) c = config(c);
    notifier.update(c);
    await pumpGolden(
      tester,
      h,
      TimeGridView(
        args: PlannerViewArgs(viewKey: 'week_table', type: PlannerViewType.weekTable, date: date),
      ),
      variant: variant,
      size: size,
    );
    await tester.pumpAndSettle();
    if (minute != null) {
      final grid = tester.state<TimeGridState>(find.byType(TimeGrid));
      grid.scrollToMinute(minute, animate: false);
      await tester.pumpAndSettle();
    }
    await expectLater(find.byType(TimeGridView), matchesGoldenFile('goldens/week_table_$name.png'));
  }

  for (final slot in [1, 5, 30, 120, 1440]) {
    for (final v in [lightLtr, darkRtl]) {
      testWidgets('week table $slot min ${variantName(v)}', (tester) async {
        await golden(tester, '${slot}min_${variantName(v)}', variant: v, slot: slot);
      });
    }
  }

  // In-view insights (T6.3.20): slot occupancy layer + day utilization bars.
  for (final v in [lightLtr, darkRtl]) {
    testWidgets('week table insights overlays ${variantName(v)}', (tester) async {
      await golden(
        tester,
        'insights_${variantName(v)}',
        variant: v,
        slot: 60,
        minute: 7 * 60,
        config: (c) => c.copyWith(overlays: {'occupancy': true, 'utilization': true}),
        overrides: [
          slotOccupancyOverlayProvider.overrideWith(
            (ref, size) async => SlotOccupancyOverlay(
              size,
              {
                for (final d in [1, 2, 3, 4, 5])
                  for (var h = 8; h < 12; h++) (d, h * 60): (d + h) % 4 / 3,
              },
              const {(2, 15 * 60), (4, 16 * 60)},
            ),
          ),
        ],
      );
    });
  }

  for (final v in [darkLtr, lightRtl, lightLtrLarge]) {
    testWidgets('week table 30 min ${variantName(v)}', (tester) async {
      await golden(tester, '30min_${variantName(v)}', variant: v);
    });
  }

  // T3.4.16: landscape phone (7 wider columns, lane cap 3) and tablet (lane cap 4).
  for (final (name, size) in [('landscape', const Size(860, 420)), ('tablet', const Size(1280, 800))]) {
    testWidgets('week table 30 min $name', (tester) async {
      await golden(tester, '30min_$name', variant: lightLtr, size: size, minute: 7 * 60);
    });
  }

  testWidgets('week table compact density, colored by status', (tester) async {
    await golden(
      tester,
      '30min_compact_status',
      variant: lightLtr,
      config: (c) => c.copyWith(density: Density.compact, colorBy: ColorBy.status),
    );
  });

  // Europe/Paris: Sun 29 Mar 2026 has 23 hours, Sun 25 Oct 2026 has 25 (02:00–03:00 twice).
  for (final (name, day) in [('dst_march', LocalDate(2026, 3, 29)), ('dst_october', LocalDate(2026, 10, 25))]) {
    testWidgets('week table Paris $name', (tester) async {
      await golden(
        tester,
        '60min_$name',
        variant: lightLtr,
        slot: 60,
        zone: 'Europe/Paris',
        date: day,
        items: goldenDstDay(day, 'Europe/Paris'),
        minute: 0,
      );
    });
  }

  // T3.3.26 / T3.4.19: cascade overlap style, extra time-zone rulers and week numbers.
  testWidgets('week table cascade, two extra zones and week numbers', (tester) async {
    await golden(
      tester,
      '30min_cascade_zones_weeks',
      variant: lightLtr,
      minute: 7 * 60,
      config: (c) => c.copyWith(
        overlapStyle: OverlapStyle.cascade,
        extraTimeZones: ['America/New_York', 'Asia/Tokyo'],
        showWeekNumbers: true,
      ),
    );
  });

  testWidgets('week table extra zones dark RTL', (tester) async {
    await golden(
      tester,
      '30min_zones_dark_rtl',
      variant: darkRtl,
      minute: 7 * 60,
      config: (c) => c.copyWith(extraTimeZones: ['Asia/Tokyo'], showWeekNumbers: true),
    );
  });
}
