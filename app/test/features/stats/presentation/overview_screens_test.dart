// Overview segment (T6.7.01) and weekly review screen (T6.7.02) on the overview_week dataset.
import 'package:everslot/features/stats/presentation/insights_screen.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/stats/presentation/widgets/review_view.dart';
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

Future<StatsHarness> seed(WidgetTester tester, String fixture) async {
  final h = await StatsFixture.load(fixture).seed();
  await h.settle();
  tester.view.physicalSize = const Size(420, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return h;
}

void main() {
  testWidgets('overview: today board and week at a glance with every section', (tester) async {
    final h = await seed(tester, 'overview_week');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const InsightsScreen());
    await settle(tester);
    expect(find.text(en.statsMetricGl01Title), findsWidgets);
    expect(find.text(en.statsMetricGl02Title), findsWidgets);
    expect(find.text(en.chartsLabelCravings), findsWidgets);
    expect(find.text(en.statsOverviewOpenReview), findsOneWidget);
    // Data quality with its guidance (T6.7.10).
    expect(find.text(en.statsMetricGl10Title), findsWidgets);
    expect(find.text(en.statsGuidanceTrackTime), findsOneWidget);
    expect(find.text(en.statsGuidanceLogFromNotifications), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('overview adapts to empty sections: no habit or quit tiles without data', (tester) async {
    final h = await seed(tester, 'planner_two_weeks');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const InsightsScreen());
    await settle(tester);
    expect(find.text(en.chartsLabelCravings), findsNothing);
    expect(find.text(en.chartsLabelOverdue), findsWidgets);
    await finish(tester);
  });

  testWidgets('weekly review: last week by default, this week so far on toggle', (tester) async {
    final h = await seed(tester, 'overview_week');
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'review'));
    await settle(tester);
    expect(find.byType(ReviewView), findsOneWidget);
    expect(find.textContaining('Item C'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text(en.statsReviewThisWeek));
    await settle(tester);
    final view = tester.widget<ReviewView>(find.byType(ReviewView));
    expect(view.current, isTrue);
    expect(view.data.from.toIso(), '2026-09-21');
    await finish(tester);
  });
}
