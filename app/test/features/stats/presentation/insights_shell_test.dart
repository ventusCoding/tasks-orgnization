// Insights tab shell & navigation (T6.1.17): segments, remembered segment, scoped deep links with a
// period, unknown scopes and the quit tracker picker.
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/insights_screen.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_executor.dart';
import '../support/stats_harness.dart';

Future<void> settleFrames(WidgetTester tester) async {
  await tester.pump();
  // Drift streams deliver on real async gaps.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 61));
}

void main() {
  group('route segments', () {
    test('every canonical insights route maps to its metric scope', () {
      expect(InsightsRoute.parse('overview'), InsightsRoute.overview);
      expect(InsightsRoute.parse('global')?.metricScope, MetricScope.global);
      expect(InsightsRoute.parse('planner')?.metricScope, MetricScope.planner);
      expect(InsightsRoute.parse('series')?.metricScope, MetricScope.series);
      expect(InsightsRoute.parse('task')?.metricScope, MetricScope.task);
      expect(InsightsRoute.parse('checklists')?.metricScope, MetricScope.checklists);
      expect(InsightsRoute.parse('checklist')?.metricScope, MetricScope.checklist);
      expect(InsightsRoute.parse('item')?.metricScope, MetricScope.checklistItem);
      expect(InsightsRoute.parse('habits')?.metricScope, MetricScope.habits);
      expect(InsightsRoute.parse('habit')?.metricScope, MetricScope.habit);
      expect(InsightsRoute.parse('quit')?.metricScope, MetricScope.quit);
      expect(InsightsRoute.parse('review')?.metricScope, MetricScope.global);
      expect(InsightsRoute.parse('glossary')?.metricScope, isNull);
      expect(InsightsRoute.parse('nope'), isNull);
    });
  });

  testWidgets('segments switch the scope and the choice is remembered', (tester) async {
    final executor = FakeStatsExecutor();
    final h = StatsHarness.create(executor: executor);
    addTearDown(h.dispose);
    await h.settle();
    await pumpStats(tester, h, const InsightsScreen());
    await settleFrames(tester);
    expect(executor.jobs.last.request.scope, MetricScope.global);
    await tester.tap(find.text('Habits'));
    await settleFrames(tester);
    expect(executor.jobs.last.request.scope, MetricScope.habits);
    expect(h.read(statsUiStateProvider).segment, 'habits');
    expect((await h.read(statsLocalStoreProvider).readAll())['segment'], 'habits');
    await tester.tap(find.text('Plan'));
    await settleFrames(tester);
    expect(executor.jobs.last.request.scope, MetricScope.planner);
    // Plan and Lists offer filters.
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    await tester.tap(find.text('Quit'));
    await settleFrames(tester);
    await settleFrames(tester);
    expect(find.text('No quit trackers yet'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the remembered segment opens first', (tester) async {
    final h = StatsHarness.create(executor: FakeStatsExecutor());
    addTearDown(h.dispose);
    await h.settle();
    await h.read(statsLocalStoreProvider).write('segment', 'lists');
    h.container.invalidate(statsUiStateProvider);
    await pumpStats(tester, h, const InsightsScreen());
    await settleFrames(tester);
    expect(find.byWidgetPredicate((w) => w is StatsScopeView && w.scope == MetricScope.checklists), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a habit deep link opens the habit scope with its period and header', (tester) async {
    final executor = FakeStatsExecutor();
    final h = StatsHarness.create(executor: executor);
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [
        {'id': 'h1', 'kind': 'build', 'name': 'Meditate', 'sort_key': 'a', 'start_date': '2026-09-01'},
      ],
    });
    await h.settle();
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'habit', scopeId: 'h1', query: {'period': 'rolling:30'}));
    await settleFrames(tester);
    await settleFrames(tester);
    final job = executor.jobs.last;
    expect(job.request.scope, MetricScope.habit);
    expect(job.request.scopeId, 'h1');
    expect(job.request.selection.period.key, 'rolling:30');
    expect(find.text('Meditate'), findsWidgets);
    await finish(tester);
  });

  testWidgets('unknown or incomplete scopes show a message instead of a blank screen', (tester) async {
    final h = StatsHarness.create(executor: FakeStatsExecutor());
    addTearDown(h.dispose);
    await h.settle();
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'nonsense'));
    await settleFrames(tester);
    expect(find.text('nonsense'), findsOneWidget);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'habit'));
    await settleFrames(tester);
    expect(find.text('habit'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the weekly review route renders the review layout', (tester) async {
    final executor = FakeStatsExecutor();
    final h = StatsHarness.create(executor: executor);
    addTearDown(h.dispose);
    await h.settle();
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'review'));
    await settleFrames(tester);
    expect(executor.jobs.last.metricIds, ['GL-03', 'GL-04']);
    await finish(tester);
  });
}
