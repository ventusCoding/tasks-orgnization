// Productivity views goldens (T3.7.14, covering T3.7.01 focus, T3.7.02 backlog drawer, T3.7.03
// backlog, T3.7.04 openings, T3.7.05 table, T3.7.06 plan vs actual, T3.7.07 routine, T3.7.08
// Kanban, T3.7.09 matrix, T3.7.10 radial clock, T3.7.11 horizons, T3.7.12 countdowns, T3.7.13 map):
// each view in light LTR, dark RTL and text scale 2.0. Interaction tests live next to each view.
// Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/view_config/checklist_steps.dart';
import 'package:everslot/features/planner/application/view_config/countdowns.dart';
import 'package:everslot/features/planner/application/view_config/horizon_actions.dart';
import 'package:everslot/features/planner/application/view_config/places.dart';
import 'package:everslot/features/planner/application/view_config/screen_awake.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/backlog_drawer.dart';
import 'package:everslot/features/planner/presentation/views/first_use_hints.dart';
import 'package:everslot/features/planner/presentation/views/map_layer.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'map_view_test.dart' show fakeMapLayer;
import 'support/golden_support.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

class _NoAwake implements ScreenAwake {
  @override
  Future<void> keepOn({required bool on}) async {}
}

PlannerItem _backlog(String title, int estimate, {int priority = 0}) => PlannerItem(
  taskId: 'b-$title',
  seriesId: 'b-$title',
  occurrenceKey: '',
  title: title,
  startLocal: LocalDate(2026, 9, 23).atStartOfDay,
  durationMinutes: estimate,
  startUtc: DateTime.utc(2026, 9, 23),
  endUtc: DateTime.utc(2026, 9, 23).add(Duration(minutes: estimate)),
  status: OccurrenceStatus.scheduled,
  estimateMinutes: estimate,
  priority: priority,
);

/// The golden week plus a linked-checklist routine and back-to-back items today.
List<PlannerItem> _items() => [
  ...goldenWeek(),
  copyItem(item('Morning routine', at(2026, 9, 23, 10), 30, id: 'mr', color: 0xFF00838F), priority: 2),
  item('Plan sprint', at(2026, 9, 23, 10, 30), 45, color: 0xFF6A1B9A, priority: 4),
  item('Museum', at(2026, 9, 24, 14), 120, id: 'museum', color: 0xFFEF6C00),
];

void main() {
  Future<void> golden(
    WidgetTester tester,
    String view,
    String name, {
    required GoldenVariant variant,
    List<Override> overrides = const [],
    Future<void> Function(PlannerHarness h)? seed,
    Future<void> Function(WidgetTester tester)? act,
    bool realData = false,
  }) async {
    final h = PlannerHarness.create(
      items: realData ? const [] : _items(),
      realData: realData,
      overrides: [
        screenAwakeProvider.overrideWithValue(_NoAwake()),
        mapLayerBuilderProvider.overrideWithValue(fakeMapLayer),
        rangeTimeEntriesProvider.overrideWith(
          (ref, r) => Stream.value([
            TimeEntry(
              id: 'e1',
              taskId: goldenWeek()[6].taskId,
              startedAt: DateTime.utc(2026, 9, 23, 9, 10),
              endedAt: DateTime.utc(2026, 9, 23, 9, 30),
            ),
          ]),
        ),
        ...overrides,
      ],
    );
    addTearDown(h.dispose);
    h.backend.backlog.addAll([_backlog('Write memo', 45, priority: 3), _backlog('Call bank', 15)]);
    h.read(plannerViewStateProvider(view).notifier).update((s) => s.withExtra('hintsSeen', plannerHintIds));
    if (seed != null) await tester.runAsync(() => seed(h));
    await pumpGolden(
      tester,
      h,
      PlannerScreen(view: view, date: '2026-09-23'),
      variant: variant,
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (act != null) await act(tester);
    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(find.byType(PlannerScreen), matchesGoldenFile('goldens/productivity_${view}_$name.png'));
    await tester.pumpWidget(const SizedBox());
  }

  final checklistOverride = checklistStepsProvider.overrideWith(
    (ref, q) => const [
      ChecklistStep(id: 's1', text: 'Stretch', done: false, estimateMinutes: 5),
      ChecklistStep(id: 's2', text: 'Meditate', done: true),
    ],
  );

  final cases = <(String, String, List<Override>, Future<void> Function(PlannerHarness h)?, bool)>[
    ('focus', 'default', [checklistOverride], null, false),
    ('backlog', 'default', const [], null, false),
    ('free_slots', 'default', const [], null, false),
    ('table', 'default', const [], null, false),
    ('plan_vs_actual', 'default', const [], null, false),
    ('routine', 'picker', const [], null, false),
    ('kanban', 'default', const [], null, false),
    ('matrix', 'default', const [], null, false),
    ('radial', 'default', const [], null, false),
    (
      'map',
      'default',
      [
        placeTasksProvider.overrideWith(
          (ref) => Stream.value({
            'museum': const Task(
              id: 'museum',
              seriesId: 'museum',
              title: 'Museum',
              locationLat: 48.86,
              locationLng: 2.34,
            ),
          }),
        ),
      ],
      null,
      false,
    ),
    (
      'horizons',
      'default',
      const [],
      (h) async {
        final a = h.read(horizonActionsProvider);
        await a.create('Plan trip', 'week:2026-09-21');
        await a.create('Read 2 books', 'month:2026-09');
        await a.create('Learn piano', 'year:2026');
      },
      true,
    ),
    (
      'countdown',
      'default',
      [
        countdownEntriesProvider.overrideWith(
          (ref) => Stream.value([
            CountdownEntry(
              task: const Task(id: 'v', seriesId: 'v', title: 'Vacation', countdownMode: CountdownMode.until),
              mode: CountdownMode.until,
              target: DateTime.utc(2026, 10, 3, 9, 30),
              targetLocal: LocalDateTime.of(2026, 10, 3, 9, 30),
            ),
            CountdownEntry(
              task: const Task(id: 's', seriesId: 's', title: 'Quit sugar', countdownMode: CountdownMode.since),
              mode: CountdownMode.since,
              target: DateTime.utc(2026, 9, 13, 9, 30),
              targetLocal: LocalDateTime.of(2026, 9, 13, 9, 30),
            ),
          ]),
        ),
      ],
      null,
      false,
    ),
  ];

  for (final (view, name, overrides, seed, realData) in cases) {
    for (final v in [lightLtr, darkRtl, lightLtrLarge]) {
      testWidgets('$view $name ${variantName(v)}', (tester) async {
        await golden(
          tester,
          view,
          '${name}_${variantName(v)}',
          variant: v,
          overrides: overrides,
          seed: seed,
          realData: realData,
        );
      });
    }
  }

  // The backlog drawer open over the day list (phone: toggled from the overflow menu).
  for (final v in [lightLtr, darkRtl]) {
    testWidgets('backlog drawer ${variantName(v)}', (tester) async {
      await golden(
        tester,
        'day_list',
        'drawer_${variantName(v)}',
        variant: v,
        act: (tester) async {
          await tester.tap(find.byKey(const Key('planner-more')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(v.rtl ? 'درج قائمة الانتظار' : 'Backlog drawer').last);
          await tester.pumpAndSettle();
          expect(find.byType(BacklogDrawerPanel), findsOneWidget);
        },
      );
    });
  }
}
