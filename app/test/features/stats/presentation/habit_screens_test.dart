// Habit Insights screens (T6.5.16, T6.5.17) on the habits_portfolio dataset, and the archived-habit
// rule of the section metrics (T6.5.13).
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/stats/presentation/widgets/habit_table.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));
const _period = {'period': 'custom:2026-09-14..2026-09-27'};

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

Future<StatsHarness> portfolio(WidgetTester tester) async {
  final h = await StatsFixture.load('habits_portfolio').seed();
  await h.settle();
  tester.view.physicalSize = const Size(420, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return h;
}

void main() {
  testWidgets('a measurable habit shows target progress and volume', (tester) async {
    final h = await portfolio(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'habit', scopeId: 'water', query: _period));
    await settle(tester);
    expect(find.text('Water'), findsWidgets);
    expect(find.text(en.statsMetricHbH10Title), findsOneWidget);
    expect(find.text(en.statsMetricHbH11Title), findsOneWidget);
    // Data completeness explains that an unlogged day is unknown, not failed (T6.5.11).
    expect(find.text(en.statsMetricHbH25Title), findsOneWidget);
    expect(find.text(en.statsNoteUnloggedNotFailed), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a yes/no habit hides the volume card', (tester) async {
    final h = await portfolio(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'habit', scopeId: 'read', query: _period));
    await settle(tester);
    expect(find.text(en.statsMetricHbH11Title), findsNothing);
    expect(find.text(en.statsMetricHbH01Title), findsWidgets);
    await finish(tester);
  });

  testWidgets('a limit habit hides target progress', (tester) async {
    final h = await portfolio(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'habit', scopeId: 'coffee', query: _period));
    await settle(tester);
    expect(find.text(en.statsMetricHbH10Title), findsNothing);
    expect(find.text(en.statsMetricHbH11Title), findsOneWidget);
    await finish(tester);
  });

  testWidgets('habits section: KPIs and the per-habit mini table', (tester) async {
    final h = await portfolio(tester);
    addTearDown(h.dispose);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'habits', query: _period));
    await settle(tester);
    expect(find.byType(HabitMiniTable), findsOneWidget);
    for (final name in ['Water', 'Gym', 'Meds', 'Coffee', 'Read', 'Journal']) {
      expect(
        find.descendant(of: find.byType(HabitMiniTable), matching: find.text(name)),
        findsOneWidget,
        reason: name,
      );
    }
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  test('archived habits leave today and the trend after their archive date', () async {
    final fixture = StatsFixture.load('habits_portfolio');
    final habits = ((fixture.json['tables']! as Map<String, Object?>)['habits']! as List).cast<Map<String, Object?>>();
    habits.firstWhere((x) => x['id'] == 'water')['archived_at'] = '2026-09-21T10:00:00.000Z';
    final h = await fixture.seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.habits, period: PeriodSelection.parsePeriod(_period['period'])!);
    expect(r['HB-X-01']!.args['due'], 3);
    // Week of 21 Sep without water's units after the 21st: 22 successes out of 28.
    expect(r['HB-X-04']!.value.valueOrNull, closeTo(22 / 28, 1e-9));
    // History stays.
    final water = await h.compute(
      MetricScope.habit,
      scopeId: 'water',
      period: PeriodSelection.parsePeriod('custom:2026-09-14..2026-09-20')!,
      metricIds: {'HB-H-05'},
    );
    expect(water['HB-H-05']!.value.valueOrNull, closeTo(5 / 7, 1e-9));
  });
}
