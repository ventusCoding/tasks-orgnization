// Per-scope card layout customization (T6.1.22): the LayoutPrefs model (order, hidden, pinned), the
// `user_settings.stats.layouts` round trip, and the "Customize cards" editor (hide, pin, reorder,
// reset; EN and AR).
import 'dart:convert';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_layout_store.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_settings.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:everslot/features/stats/presentation/widgets/layout_editor_sheet.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_executor.dart';
import '../support/stats_harness.dart';

const _base = StatsLayout(
  MetricScope.planner,
  kpis: ['A', 'B'],
  sections: [
    StatsLayoutSection('execution', [StatsLayoutItem('A'), StatsLayoutItem('B'), StatsLayoutItem('C')]),
    StatsLayoutSection('capacity', [StatsLayoutItem('D'), StatsLayoutItem('E')]),
  ],
);

List<String> ids(StatsLayoutSection s) => [for (final i in s.items) i.metricId];

Map<String, MetricResult> results() => {
  for (final id in const ['PL-X-01', 'PL-X-02', 'PL-X-05', 'PL-X-06'])
    id: MetricResult(id, value: const Value<double>(0.5, sampleSize: 20), unit: StatUnit.percent),
};

void main() {
  group('LayoutPrefs', () {
    test('json round trip ignores malformed entries and sorts hidden', () {
      final prefs = LayoutPrefs.fromJson(const {
        'order': ['C', 'A', 7, 'B'],
        'hidden': ['Z', 'B', null],
        'pinned': ['E', 1],
      });
      expect(prefs.order, ['C', 'A', 'B']);
      expect(prefs.hidden, {'B', 'Z'});
      expect(prefs.pinned, ['E']);
      expect(LayoutPrefs.fromJson(prefs.toJson()), prefs);
      expect(prefs.toJson()['hidden'], ['B', 'Z']);
      expect(LayoutPrefs.fromJson(null).isDefault, isTrue);
      expect(LayoutPrefs.fromJson(const {}).isDefault, isTrue);
    });

    test('order, hidden and pinned shape the layout', () {
      final custom = _base.withPrefs(const LayoutPrefs(order: ['C', 'B', 'A', 'E', 'D'], hidden: {'B'}, pinned: ['E']));
      expect(custom.sections.map((s) => s.id), ['pinned', 'execution', 'capacity']);
      expect(ids(custom.sections[0]), ['E']);
      expect(ids(custom.sections[1]), ['C', 'A']);
      expect(ids(custom.sections[2]), ['D']);
      // Hidden cards leave the KPI row too.
      expect(custom.kpis, ['A']);
      expect(_base.withPrefs(LayoutPrefs.none), same(_base));
    });

    test('cards missing from the order keep their default position after the ordered ones', () {
      // 40 cards: a non-stable sort would reshuffle the unranked ones.
      final layout = StatsLayout(
        MetricScope.planner,
        sections: [
          StatsLayoutSection('execution', [for (var i = 0; i < 40; i++) StatsLayoutItem('M$i')]),
        ],
      );
      final custom = layout.withPrefs(const LayoutPrefs(order: ['M39']));
      expect(ids(custom.sections.single), ['M39', for (var i = 0; i < 39; i++) 'M$i']);
    });

    test('moving inside a section rewrites the complete order and keeps pinned slots', () {
      var prefs = LayoutPrefs.none;
      prefs = prefs.togglePinned('B'); // B leaves the execution list but keeps its slot
      expect(prefs.visibleOrder(_base, 'execution'), ['A', 'C']);
      prefs = prefs.moveInSection(_base, 'execution', 1, 0); // C above A
      expect(prefs.visibleOrder(_base, 'execution'), ['C', 'A']);
      expect(prefs.order, ['C', 'B', 'A', 'D', 'E']);
      prefs = prefs.togglePinned('B'); // unpinning returns B to its slot
      expect(_base.withPrefs(prefs).sections.first.items.map((i) => i.metricId), ['C', 'B', 'A']);
      // Out-of-range moves and unknown sections are ignored.
      expect(prefs.moveInSection(_base, 'execution', 9, 0), prefs);
      expect(prefs.moveInSection(_base, 'nope', 0, 1), prefs);
    });

    test('pinned cards reorder within the pinned group', () {
      final prefs = const LayoutPrefs(pinned: ['A', 'D', 'E']).movePinned(2, 0);
      expect(prefs.pinned, ['E', 'A', 'D']);
      expect(_base.withPrefs(prefs).sections.first.items.map((i) => i.metricId), ['E', 'A', 'D']);
    });

    test('equality is by value', () {
      expect(const LayoutPrefs(order: ['A'], hidden: {'B', 'C'}), const LayoutPrefs(order: ['A'], hidden: {'C', 'B'}));
      expect(const LayoutPrefs(order: ['A']) == const LayoutPrefs(order: ['B']), isFalse);
      expect(const LayoutPrefs(pinned: ['A']).hashCode, const LayoutPrefs(pinned: ['A']).hashCode);
    });
  });

  group('StatsLayoutStore', () {
    test('saves per scope, keeps other scopes and unknown keys, and resets', () async {
      final h = StatsHarness.create();
      addTearDown(h.dispose);
      await h.seedSettings({
        'stats': {'graceMinutes': 7},
      });
      final store = h.read(statsLayoutStoreProvider);
      final repo = h.read(settingsRepositoryProvider);

      await store.save(
        MetricScope.planner,
        const LayoutPrefs(order: ['PL-X-02', 'PL-X-01'], hidden: {'PL-X-03'}, pinned: ['PL-X-06']),
      );
      await store.save(MetricScope.habits, const LayoutPrefs(hidden: {'HB-X-05'}));
      var stats = await repo.read('stats');
      expect(stats['graceMinutes'], 7, reason: 'unknown keys survive');
      expect((stats['layouts'] as Map).keys, unorderedEquals(['planner', 'habits']));
      expect(
        await store.read(MetricScope.planner),
        const LayoutPrefs(order: ['PL-X-02', 'PL-X-01'], hidden: {'PL-X-03'}, pinned: ['PL-X-06']),
      );
      expect(await store.read(MetricScope.checklists), LayoutPrefs.none);

      // The stats settings see it and the effective layout applies it.
      final settings = StatsSettings.fromMaps(stats: stats);
      final layout = effectiveLayout(MetricScope.planner, settings.layouts);
      expect(layout.sections.first.id, 'pinned');
      expect(layout.metricIds, isNot(contains('PL-X-03')));

      await store.reset(MetricScope.planner);
      stats = await repo.read('stats');
      expect((stats['layouts'] as Map).keys, ['habits']);
      await store.reset(MetricScope.habits);
      stats = await repo.read('stats');
      expect(stats.containsKey('layouts'), isFalse);
      expect(stats['graceMinutes'], 7);
    });

    test('a saved layout is queued for sync', () async {
      final h = StatsHarness.create();
      addTearDown(h.dispose);
      await h.read(statsLayoutStoreProvider).save(MetricScope.planner, const LayoutPrefs(hidden: {'PL-X-03'}));
      final rows = await h.db.customSelect("SELECT fields FROM sync_outbox WHERE table_name = 'user_settings'").get();
      expect(rows, isNotEmpty);
      final fields = jsonDecode(rows.last.read<String>('fields')) as Map<String, Object?>;
      expect(jsonEncode(fields), contains('PL-X-03'));
    });
  });

  group('editor', () {
    Future<StatsHarness> open(WidgetTester tester, {Locale locale = const Locale('en')}) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9), executor: FakeStatsExecutor(results()));
      addTearDown(h.dispose);
      await h.settle();
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpStats(
        tester,
        h,
        const Scaffold(body: StatsScopeView(scope: MetricScope.planner)),
        locale: locale,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return h;
    }

    Future<void> openEditor(WidgetTester tester, String tooltip) async {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// Lets real async work (the settings write on close) finish, then reads `stats`.
    Future<Map<String, dynamic>> storedStats(WidgetTester tester, StatsHarness h) async {
      await tester.pump(const Duration(milliseconds: 100));
      return (await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return h.read(settingsRepositoryProvider).read('stats');
      }))!;
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 61));
    }

    testWidgets('hide and pin cards, then save on Done', (tester) async {
      final h = await open(tester);
      expect(find.text('Overdue now'), findsWidgets);
      expect(find.text('Pinned'), findsNothing);

      await openEditor(tester, 'Customize cards');
      expect(find.byType(LayoutEditorSheet), findsOneWidget);
      // Sections and cards are listed.
      expect(find.text('Execution'), findsWidgets);
      expect(find.text('Done vs planned per day'), findsWidgets);

      await tester.tap(find.byTooltip('Hide Done vs planned per day'));
      await tester.pump();
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.byTooltip('Show Done vs planned per day'), findsOneWidget);

      await tester.tap(find.byTooltip('Pin Overdue now'));
      await tester.pump();
      expect(find.byTooltip('Unpin Overdue now'), findsOneWidget);
      expect(find.text('Pinned'), findsWidgets);

      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LayoutEditorSheet), findsNothing);

      final stats = await storedStats(tester, h);
      final planner = (stats['layouts'] as Map)['planner'] as Map;
      expect(planner['hidden'], ['PL-X-02']);
      expect(planner['pinned'], ['PL-X-06']);

      // The screen reflects it: no "Done vs planned per day" card, a Pinned section on top.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Done vs planned per day'), findsNothing);
      expect(find.text('Pinned'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('dismissing the sheet saves the edits too', (tester) async {
      final h = await open(tester);
      await openEditor(tester, 'Customize cards');
      await tester.tap(find.byTooltip('Hide Overdue now'));
      await tester.pump();
      // Dismiss without Done (system back; the long planner layout covers the barrier).
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LayoutEditorSheet), findsNothing);
      final stats = await storedStats(tester, h);
      expect(((stats['layouts'] as Map)['planner'] as Map)['hidden'], ['PL-X-06']);
      await finish(tester);
    });

    testWidgets('dragging a card reorders its section', (tester) async {
      final h = await open(tester);
      await openEditor(tester, 'Customize cards');
      final handles = find.descendant(of: find.byType(LayoutEditorSheet), matching: find.byIcon(Icons.drag_indicator));
      expect(handles, findsWidgets);
      final gesture = await tester.startGesture(tester.getCenter(handles.first));
      // The first move starts the drag (touch slop); the second one carries it past the next row.
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      // The drop animation starts on the first frame and calls back a few frames later.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final stats = await storedStats(tester, h);
      final order = (((stats['layouts'] as Map)['planner'] as Map)['order'] as List).cast<String>();
      // The first execution card moved one place down; every card is ranked.
      expect(order.take(4), ['PL-X-03', 'PL-X-02', 'PL-X-04', 'PL-X-06']);
      expect(order, containsAll(['PL-X-08', 'PL-X-15']));
      await finish(tester);
    });

    testWidgets('reset to default clears the customization', (tester) async {
      final h = await open(tester);
      await openEditor(tester, 'Customize cards');
      final reset = find.widgetWithText(TextButton, 'Reset to default');
      expect(tester.widget<TextButton>(reset).onPressed, isNull, reason: 'nothing to reset yet');
      await tester.tap(find.byTooltip('Hide Overdue now'));
      await tester.pump();
      expect(tester.widget<TextButton>(reset).onPressed, isNotNull);
      await tester.tap(reset);
      await tester.pump();
      expect(find.text('Hidden'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final stats = await storedStats(tester, h);
      expect(stats.containsKey('layouts'), isFalse);
      await finish(tester);
    });

    testWidgets('a stored customization is applied on open and edits start from it', (tester) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9), executor: FakeStatsExecutor(results()));
      addTearDown(h.dispose);
      await h.seedSettings({
        'stats': {
          'layouts': {
            'planner': {
              'hidden': ['PL-X-02'],
              'pinned': ['PL-X-06'],
            },
          },
        },
      });
      await h.settle();
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpStats(tester, h, const Scaffold(body: StatsScopeView(scope: MetricScope.planner)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Done vs planned per day'), findsNothing);
      expect(find.text('Pinned'), findsOneWidget);
      await openEditor(tester, 'Customize cards');
      expect(find.byTooltip('Show Done vs planned per day'), findsOneWidget);
      expect(find.byTooltip('Unpin Overdue now'), findsOneWidget);
      await tester.tap(find.byTooltip('Show Done vs planned per day'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final stats = await storedStats(tester, h);
      final planner = (stats['layouts'] as Map)['planner'] as Map;
      expect(planner['hidden'], isEmpty);
      expect(planner['pinned'], ['PL-X-06']);
      await finish(tester);
    });

    testWidgets('screens on a custom layout have no customize button', (tester) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9), executor: FakeStatsExecutor(results()));
      addTearDown(h.dispose);
      await h.settle();
      await pumpStats(
        tester,
        h,
        const Scaffold(
          body: StatsScopeView(scope: MetricScope.global, layout: reviewLayout),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('Customize cards'), findsNothing);
      await finish(tester);
    });

    testWidgets('Arabic (RTL): labels are localized and nothing overflows at text scale 2', (tester) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9), executor: FakeStatsExecutor(results()));
      addTearDown(h.dispose);
      await h.settle();
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpStats(
        tester,
        h,
        const Scaffold(body: StatsScopeView(scope: MetricScope.planner)),
        locale: const Locale('ar'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await openEditor(tester, 'تخصيص البطاقات');
      expect(find.byType(LayoutEditorSheet), findsOneWidget);
      expect(find.text('إعادة الضبط إلى الافتراضي'), findsOneWidget);
      expect(find.text('تم'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The drag handle sits at the start (right) edge in RTL.
      final handle = tester.getCenter(find.byIcon(Icons.drag_indicator).first);
      expect(handle.dx, greaterThan(200));
      await finish(tester);
    });
  });
}
