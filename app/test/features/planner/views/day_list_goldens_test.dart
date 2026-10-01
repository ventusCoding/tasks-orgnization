// Day list goldens (T3.5.15, covering T3.5.03 rows, T3.5.05 now, T3.5.08 free runs, T3.5.10 all-day,
// T3.5.11 agenda, T3.5.14 ribbon): 1, 30, 120 and 1 440-minute slots, dark RTL, text scale 2.0,
// collapsed empty runs, the ribbon style and the Paris DST days. Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/first_use_hints.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

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
    String date = '2026-09-23',
    List<PlannerItem>? items,
  }) async {
    final h = PlannerHarness.create(items: items ?? goldenWeek(), zone: zone);
    addTearDown(h.dispose);
    h.read(plannerViewStateProvider('day_list').notifier).update((s) => s.withExtra('hintsSeen', plannerHintIds));
    final notifier = h.read(plannerViewConfigProvider('day_list').notifier);
    var c = h.read(plannerViewConfigProvider('day_list')).withSlot(slot);
    if (config != null) c = config(c);
    notifier.update(c);
    await pumpGolden(
      tester,
      h,
      PlannerScreen(view: 'day_list', date: date),
      variant: variant,
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PlannerScreen), matchesGoldenFile('goldens/day_list_$name.png'));
  }

  for (final slot in [1, 30, 120, 1440]) {
    testWidgets('day list $slot min light_ltr', (tester) async {
      await golden(tester, '${slot}min_light_ltr', variant: lightLtr, slot: slot);
    });
  }

  for (final v in [darkRtl, lightLtrLarge]) {
    testWidgets('day list 30 min ${variantName(v)}', (tester) async {
      await golden(tester, '30min_${variantName(v)}', variant: v);
    });
  }

  testWidgets('day list 5 min with collapsed empty runs', (tester) async {
    await golden(tester, '5min_free_runs', variant: lightLtr, slot: 5, config: (c) => c.copyWith(hideEmptySlots: true));
  });

  for (final v in [lightLtr, darkRtl]) {
    testWidgets('day list ribbon ${variantName(v)}', (tester) async {
      await golden(tester, 'ribbon_${variantName(v)}', variant: v, config: (c) => c.withOption('style', 'ribbon'));
    });
  }

  for (final (name, day) in [('dst_march', LocalDate(2026, 3, 29)), ('dst_october', LocalDate(2026, 10, 25))]) {
    testWidgets('day list Paris $name', (tester) async {
      await golden(
        tester,
        '60min_$name',
        variant: lightLtr,
        slot: 60,
        zone: 'Europe/Paris',
        date: day.toIso(),
        items: goldenDstDay(day, 'Europe/Paris'),
      );
    });
  }
}
