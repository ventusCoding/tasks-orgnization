// Quit Insights screen (T6.6.13): smoking trackers show the health milestones with the disclaimer
// and the "population estimate" label (T6.6.04/05); other substances never show them; reduce mode
// shows reduction progress (T6.6.06).
import 'package:everslot/features/stats/charts.dart' show LiveCounter;
import 'package:everslot/features/stats/presentation/insights_screen.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));

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

Future<StatsHarness> seed(WidgetTester tester, String fixture, {String? substance}) async {
  final f = StatsFixture.load(fixture);
  if (substance != null) {
    final habits = ((f.json['tables']! as Map<String, Object?>)['habits']! as List).cast<Map<String, Object?>>();
    habits.single['quit_substance'] = substance;
    habits.single.remove('life_minutes_per_unit');
  }
  final h = await f.seed();
  await h.settle();
  tester.view.physicalSize = const Size(420, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return h;
}

void main() {
  testWidgets('smoking: milestones with the disclaimer; life regained labeled as an estimate', (tester) async {
    final h = await seed(tester, 'quit_smoking_90_days');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'quit', scopeId: 'smoking', query: {'period': 'allTime'}));
    await settle(tester);
    expect(find.text(en.statsMetricQt11Title), findsWidgets);
    expect(find.text(en.statsHealthDisclaimer), findsOneWidget);
    // Live abstinence counters in the header (and the abstinence section).
    expect(find.byType(LiveCounter), findsWidgets);
    expect(find.text(en.statsMetricQt10Title), findsWidgets);
    expect(find.text(en.statsNotePopulationEstimate), findsWidgets);
    // Reduce-mode cards never show on an abstain tracker.
    expect(find.text(en.statsMetricQt12Title), findsNothing);
    await finish(tester);
  });

  testWidgets('another substance never shows health milestones or life regained', (tester) async {
    final h = await seed(tester, 'quit_smoking_90_days', substance: 'alcohol');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'quit', scopeId: 'smoking', query: {'period': 'allTime'}));
    await settle(tester);
    expect(find.text(en.statsMetricQt11Title), findsNothing);
    expect(find.text(en.statsHealthDisclaimer), findsNothing);
    expect(find.text(en.statsMetricQt10Title), findsNothing);
    expect(find.text(en.statsMetricQt07Title), findsWidgets);
    await finish(tester);
  });

  testWidgets('reduce mode shows reduction progress', (tester) async {
    final h = await seed(tester, 'quit_reduce_week');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'quit', scopeId: 'cutdown', query: {'period': 'allTime'}));
    await settle(tester);
    await tester.scrollUntilVisible(find.text(en.statsMetricQt12Title), 500, scrollable: find.byType(Scrollable).first);
    await settle(tester);
    expect(find.text(en.statsMetricQt12Title), findsWidgets);
    await finish(tester);
  });

  testWidgets('the Quit segment picks a tracker', (tester) async {
    final h = await seed(tester, 'quit_smoking_90_days');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const InsightsScreen());
    await settle(tester);
    // The scrollable tab bar may hide the last tab on a phone.
    await tester.ensureVisible(find.text(en.statsSegmentQuit));
    await tester.pump();
    await tester.tap(find.text(en.statsSegmentQuit));
    await settle(tester);
    await settle(tester);
    expect(find.text('Smoking'), findsWidgets);
    expect(find.text(en.statsMetricQt02Title), findsWidgets);
    await finish(tester);
  });
}
