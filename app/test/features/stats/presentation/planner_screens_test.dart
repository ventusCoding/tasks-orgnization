// Planner Insights screens: task stats (T6.3.17), series (T6.3.18) and the planner section screen
// (T6.3.19) on real computed data.
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/kpi_tile.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/stats/presentation/task_stats_panel.dart';
import 'package:everslot/features/stats/presentation/widgets/drill_sheet.dart';
import 'package:everslot/features/stats/presentation/widgets/explain_sheet.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../planner/planner_scenario.dart';
import '../planner/planner_series_test.dart' show splitSeries;
import '../support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));
final f = StatFormat(en, 'en');

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 61));
}

void main() {
  setUp(() {});

  testWidgets('task stats: PL-T values, no period selector, explain entry for each KPI', (tester) async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 12));
    addTearDown(h.dispose);
    await h.seedTables(plannerScenario());
    await h.settle();
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(tester, h, const Scaffold(body: TaskStatsPanel(taskId: 'a')));
    await settle(tester);
    expect(find.text(f.value(60, StatUnit.minutes)), findsWidgets);
    expect(find.byType(ChoiceChip), findsNothing);
    // Four KPIs plus the start and finish delay tiles.
    expect(find.byType(KpiTile), findsNWidgets(6));
    expect(find.text(en.statsSeeSeries), findsNothing);
    await tester.tap(find.byType(KpiTile).first);
    await settle(tester);
    expect(find.byType(ExplainSheet), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a recurring task links to its series stats', (tester) async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 12));
    addTearDown(h.dispose);
    await h.seedTables(plannerScenario());
    await h.settle();
    await pumpStats(
      tester,
      h,
      const Scaffold(
        body: TaskStatsPanel(taskId: 'g', occurrenceKey: '2026-09-21T07:00'),
      ),
    );
    await settle(tester);
    expect(find.text(en.statsSeeSeries), findsOneWidget);
    await finish(tester);
  });

  testWidgets('series screen: KPIs and a calendar day drills into its occurrence', (tester) async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 12));
    addTearDown(h.dispose);
    await h.seedTables(splitSeries());
    await h.settle();
    tester.view.physicalSize = const Size(420, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(
      tester,
      h,
      const ScopeStatsScreen(scope: 'series', scopeId: 'run', query: {'period': 'custom:2026-09-14..2026-09-23'}),
    );
    await settle(tester);
    await settle(tester);
    expect(find.text('Run'), findsWidgets);
    expect(find.text(f.percent(1)), findsWidgets);
    final day = find.bySemanticsLabel(RegExp('Sep 16, 2026'));
    expect(day, findsWidgets);
    await tester.tap(day.first);
    await settle(tester);
    expect(find.byType(DrillSheet), findsOneWidget);
    expect(find.text('Run'), findsWidgets);
    await finish(tester);
  });

  testWidgets('planner screen: the canonical fixture renders completion vs plan', (tester) async {
    final fixture = StatsFixture.load('planner_two_weeks');
    final h = await fixture.seed();
    addTearDown(h.dispose);
    await h.settle();
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(
      tester,
      h,
      const ScopeStatsScreen(scope: 'planner', query: {'period': 'custom:2026-09-14..2026-09-20'}),
    );
    await settle(tester);
    await settle(tester);
    // PL-X-01 = 17/21 for week 2 (fixture expectation).
    expect(find.text(f.percent(17 / 21)), findsWidgets);
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
