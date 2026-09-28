// Checklist Insights screens: item panel (T6.4.15), checklist (T6.4.16) and lists (T6.4.17).
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/simple_views.dart';
import 'package:everslot/features/stats/presentation/item_stats_panel.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/stats/presentation/widgets/metric_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 61));
}

Future<StatsHarness> seeded(WidgetTester tester) async {
  final h = await StatsFixture.load('checklist_flow_small').seed();
  await h.settle();
  tester.view.physicalSize = const Size(420, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return h;
}

void main() {
  testWidgets('item panel: status timeline with the actual reason notes, no period selector', (tester) async {
    final h = await seeded(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const Scaffold(body: ItemStatsPanel(itemId: 'X')));
    await settle(tester);
    expect(find.byType(StatusTimelineBar), findsWidgets);
    expect(find.textContaining('waiting for Sam'), findsWidgets);
    expect(find.textContaining('supplier invoice missing'), findsWidgets);
    expect(find.byType(ChoiceChip), findsNothing);
    await finish(tester);
  });

  testWidgets('checklist screen: KPIs and sections for one list', (tester) async {
    final h = await seeded(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'checklist', scopeId: 'L1', query: {'period': 'custom:2026-09-01..2026-09-07'}));
    await settle(tester);
    expect(find.text('Sprint'), findsWidgets);
    expect(find.byType(MetricCard), findsWidgets);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('lists screen: overview with the ranking tabs', (tester) async {
    final h = await seeded(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'checklists', query: {'period': 'custom:2026-09-01..2026-09-07'}));
    await settle(tester);
    expect(find.text('Most active'), findsOneWidget);
    await tester.tap(find.text('Most active'));
    await settle(tester);
    expect(find.text('Sprint'), findsWidgets);
    await finish(tester);
  });

  test('flow charts carry drill references to their items', () async {
    final h = await StatsFixture.load('checklist_flow_small').seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.checklist, scopeId: 'L1', period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-07')!);
    for (final id in ['CL-L-01', 'CL-L-03', 'CL-L-04']) {
      expect(r[id]!.drill.values.expand((refs) => refs), isNotEmpty, reason: id);
    }
  });
}
