// Calendar views goldens (T3.6.17, covering T3.6.04 N-day, T3.6.05 work week, T3.6.06 week list,
// T3.6.07 / T3.6.08 month + densities, T3.6.09 agenda, T3.6.10 year, T3.6.11 multi-week, T3.6.12
// quarter, T3.6.13 ribbon, T3.6.14 timeline, T3.6.15 swimlanes, T3.6.16 load heatmap): each view in
// light LTR, dark RTL and text scale 2.0. Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/first_use_hints.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_support.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

const _work = Category(id: 'work', name: 'Work', color: 0xFF1565C0, sortKey: 'a');
const _home = Category(id: 'home', name: 'Home', color: 0xFF2E7D32, sortKey: 'b');

/// The golden week with categories (swimlanes / timeline grouping) and a few later items (month,
/// quarter, year and agenda show more than one week).
List<PlannerItem> _calendarItems() {
  final week = [for (final (i, it) in goldenWeek().indexed) copyItem(it, categoryId: i.isEven ? 'work' : 'home')];
  return [
    ...week,
    item('Board meeting', at(2026, 10, 6, 14), 90, color: 0xFF1565C0, categoryId: 'work'),
    item('Half marathon', at(2026, 10, 18, 8), 150, color: 0xFF2E7D32, categoryId: 'home'),
    item('Release', at(2026, 11, 3, 10), 60, color: 0xFF6A1B9A, categoryId: 'work', priority: 4),
    item('Holiday', at(2026, 12, 21), 1440 * 5, allDay: true, color: 0xFF00838F),
  ];
}

void main() {
  Future<void> golden(
    WidgetTester tester,
    String view,
    String name, {
    required GoldenVariant variant,
    PlannerViewConfig Function(PlannerViewConfig c)? config,
  }) async {
    final h = PlannerHarness.create(
      items: _calendarItems(),
      overrides: [
        allCategoriesProvider.overrideWith((ref) => Stream.value(const [_work, _home])),
      ],
    );
    addTearDown(h.dispose);
    h.read(plannerViewStateProvider(view).notifier).update((s) => s.withExtra('hintsSeen', plannerHintIds));
    if (config != null) h.read(plannerViewConfigProvider(view).notifier).change(config);
    await pumpGolden(
      tester,
      h,
      PlannerScreen(view: view, date: '2026-09-23'),
      variant: variant,
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PlannerScreen), matchesGoldenFile('goldens/calendar_${view}_$name.png'));
  }

  final views = <(String, String, PlannerViewConfig Function(PlannerViewConfig c)?)>[
    ('n_day', 'default', null),
    ('work_week', 'default', null),
    ('week_list', 'default', null),
    ('month', 'titles', null),
    ('agenda', 'default', null),
    ('year', 'planned', null),
    ('multi_week', 'default', null),
    ('quarter', 'dots', null),
    ('ribbon', 'week', (c) => c.withOption('scope', 'week')),
    ('timeline', 'days', null),
    ('swimlanes', 'default', null),
    ('load_heatmap', 'default', (c) => c.withOption('weeks', 1)),
  ];

  for (final (view, name, config) in views) {
    for (final v in [lightLtr, darkRtl, lightLtrLarge]) {
      testWidgets('$view $name ${variantName(v)}', (tester) async {
        await golden(tester, view, '${name}_${variantName(v)}', variant: v, config: config);
      });
    }
  }

  // Month densities (T3.6.08) and list-below mode; the other scopes / metrics of P2 views.
  for (final (name, config) in <(String, PlannerViewConfig Function(PlannerViewConfig c))>[
    ('dots', (c) => c.withOption('monthMode', 'dots')),
    ('bars', (c) => c.withOption('monthMode', 'bars')),
    ('titles_times', (c) => c.withOption('monthMode', 'titles_times')),
    ('list_below', (c) => c.withOption('listBelow', true)),
  ]) {
    testWidgets('month $name light_ltr', (tester) async {
      await golden(tester, 'month', '${name}_light_ltr', variant: lightLtr, config: config);
    });
  }

  testWidgets('ribbon day light_ltr', (tester) async {
    await golden(tester, 'ribbon', 'day_light_ltr', variant: lightLtr);
  });

  testWidgets('timeline grouped by category light_ltr', (tester) async {
    await golden(
      tester,
      'timeline',
      'category_light_ltr',
      variant: lightLtr,
      config: (c) => c.withOption('groupBy', 'category'),
    );
  });

  testWidgets('year completion light_ltr', (tester) async {
    await golden(
      tester,
      'year',
      'completion_light_ltr',
      variant: lightLtr,
      config: (c) => c.withOption('heatMetric', 'completion'),
    );
  });

  testWidgets('quarter bars light_ltr', (tester) async {
    await golden(
      tester,
      'quarter',
      'bars_light_ltr',
      variant: lightLtr,
      config: (c) => c.withOption('monthMode', 'bars'),
    );
  });
}
