// Stats screen framework (T6.1.16): the scope scaffold with fake metric results — values,
// insufficient, error and empty states, period switching, collapsible sections, the explain sheet
// and the Arabic (RTL) layout.
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:everslot/features/stats/presentation/widgets/explain_sheet.dart';
import 'package:everslot/features/stats/presentation/widgets/metric_card.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_executor.dart';
import '../support/stats_harness.dart';

Map<String, MetricResult> plannerResults() => {
  'PL-X-01': MetricResult(
    'PL-X-01',
    value: const Value<double>(0.8, sampleSize: 25),
    unit: StatUnit.percent,
    previous: const Value<double>(0.7),
    comparison: PeriodComparison(
      const Value<double>(0.8),
      const Value<double>(0.7),
      delta: const Value<double>(10),
      deltaPct: const NotApplicable<double>('rateUsesPp'),
      isRate: true,
    ),
    exclusions: const {'skipped': 3},
  ),
  'PL-X-05': const MetricResult('PL-X-05', value: Insufficient<double>(3, 1), unit: StatUnit.percent),
  'PL-X-02': metricError('PL-X-02', StateError('boom')),
  'PL-X-06': MetricResult(
    'PL-X-06',
    value: const Value<double>(2),
    chart: BarData(
      [DateLabel(LocalDate(2026, 9, 21)), DateLabel(LocalDate(2026, 9, 22))],
      const [
        BarSeries(TokenLabel(LabelToken.overdue), [1, 1]),
      ],
    ),
  ),
};

Future<StatsHarness> harness(FakeStatsExecutor executor) async {
  final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9), executor: executor);
  await h.settle();
  return h;
}

/// Unmounts the tree and lets the batch keep-alive timer (60 s) expire.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 61));
}

Future<void> pumpView(WidgetTester tester, StatsHarness h, {Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpStats(tester, h, const Scaffold(body: StatsScopeView(scope: MetricScope.planner)), locale: locale);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('renders values, insufficient, error and empty cards from one batch', (tester) async {
    final executor = FakeStatsExecutor(plannerResults());
    final h = await harness(executor);
    addTearDown(h.dispose);
    await pumpView(tester, h);
    expect(executor.jobs, hasLength(1));
    expect(executor.jobs.single.metricIds.toSet(), containsAll(['PL-X-01', 'PL-X-02', 'PL-X-15']));
    expect(find.text('80%'), findsWidgets);
    expect(find.textContaining('Needs 2 more'), findsWidgets);
    expect(find.text('This chart couldn’t be computed'), findsOneWidget);
    expect(find.text('No data for this period'), findsWidgets);
    expect(find.byType(MetricCard), findsWidgets);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('changing the period recomputes and updates every card', (tester) async {
    final executor = FakeStatsExecutor(plannerResults())
      ..byPeriod['thisMonth'] = {
        'PL-X-01': const MetricResult('PL-X-01', value: Value<double>(0.55, sampleSize: 40), unit: StatUnit.percent),
      };
    final h = await harness(executor);
    addTearDown(h.dispose);
    await pumpView(tester, h);
    expect(find.text('55%'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Month'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(executor.jobs.last.request.selection.period.key, 'thisMonth');
    expect(find.text('55%'), findsWidgets);
    // The period is remembered for the scope.
    expect(h.read(statsUiStateProvider).periods['planner'], 'thisMonth');
    await finish(tester);
  });

  testWidgets('sections collapse and expand', (tester) async {
    final h = await harness(FakeStatsExecutor(plannerResults()));
    addTearDown(h.dispose);
    await pumpView(tester, h);
    final errors = find.text('This chart couldn’t be computed');
    expect(errors, findsOneWidget);
    await tester.tap(find.byTooltip('Collapse Execution'));
    await tester.pump();
    expect(errors, findsNothing);
    await tester.tap(find.byTooltip('Expand Execution'));
    await tester.pump();
    expect(errors, findsOneWidget);
    await finish(tester);
  });

  testWidgets('a KPI opens the explain sheet with the actual exclusions', (tester) async {
    final h = await harness(FakeStatsExecutor(plannerResults()));
    addTearDown(h.dispose);
    await pumpView(tester, h);
    await tester.tap(find.text('80%').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ExplainSheet), findsOneWidget);
    expect(find.textContaining('3 skipped units'), findsOneWidget);
    expect(find.textContaining('PL-X-01'), findsWidgets);
    await finish(tester);
  });

  testWidgets('everything empty shows the empty banner', (tester) async {
    final h = await harness(FakeStatsExecutor());
    addTearDown(h.dispose);
    await pumpView(tester, h);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Arabic renders right-to-left without overflow', (tester) async {
    final h = await harness(FakeStatsExecutor(plannerResults()));
    addTearDown(h.dispose);
    await pumpView(tester, h, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    final dir = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(dir.textDirection, TextDirection.rtl);
    expect(find.byType(MetricCard), findsWidgets);
    await finish(tester);
  });
}
