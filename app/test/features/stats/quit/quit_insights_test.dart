// Quit Insights P1/P2 metrics (T6.6.08–T6.6.12) through the registry, on the canonical quit fixtures
// and a small craving scenario; the withdrawal phase card (T6.6.11) as a widget test.
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));

Map<String, Object?> _tracker() => {
  'id': 'q',
  'kind': 'quit',
  'name': 'Smoking',
  'sort_key': 'a',
  'start_date': '2026-09-01',
  'time_zone': 'UTC',
  'quit_mode': 'abstain',
  'quit_substance': 'cigarettes',
  'quit_started_at': '2026-09-01T00:00:00.000Z',
  'baseline_per_day': 10,
  'unit_cost': 0.5,
  'currency': 'EUR',
  'created_at': '2026-09-01T00:00:00.000Z',
};

void main() {
  test('T6.6.08: 10 cravings, 2 followed by a use within 2 h → 80 % resisted', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [_tracker()],
      'habit_logs': [
        for (var i = 0; i < 10; i++)
          {
            'id': 'c$i',
            'habit_id': 'q',
            'kind': 'craving',
            'logged_at': '2026-09-${(i + 2).toString().padLeft(2, '0')}T10:00:00.000Z',
            'local_date': '2026-09-${(i + 2).toString().padLeft(2, '0')}',
            'duration_seconds': 180 + i * 10,
            'coping': i.isEven ? 'walk' : 'water',
          },
        for (final i in [3, 7])
          {
            'id': 'u$i',
            'habit_id': 'q',
            'kind': 'relapse',
            'logged_at': '2026-09-${(i + 2).toString().padLeft(2, '0')}T11:00:00.000Z',
            'local_date': '2026-09-${(i + 2).toString().padLeft(2, '0')}',
            'value': 1,
          },
      ],
    });
    final r = await h.compute(MetricScope.quit, scopeId: 'q', period: const StatsPeriod.allTime());
    expect(r['QT-15']!.value.valueOrNull, closeTo(0.8, 1e-9));
    expect(r['QT-16']!.value.valueOrNull, closeTo(225 / 60, 1e-9));
    expect(r['QT-16']!.note, 'cravingPasses');
    // Both coping tools have exactly 5 cravings: shown, none greyed out.
    expect(r['QT-27']!.args['insufficient'], isEmpty);
    expect(r['QT-28']!.value.hasValue, isTrue);
  });

  test('T6.6.09: attempt 1 relapses (days 10–16), attempt 2 only lapses (day 10)', () async {
    final h = await StatsFixture.load('quit_attempts').seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.quit, scopeId: 'attempts', period: const StatsPeriod.allTime());
    final rows = (r['QT-18']!.chart! as ListData).rows;
    // Newest first: attempt 3 clean, attempt 2 lapse, attempt 1 relapse.
    expect(rows.map((row) => row.secondary), const [
      TokenLabel(LabelToken.abstinent),
      TokenLabel(LabelToken.lapse),
      TokenLabel(LabelToken.relapse),
    ]);
    expect(r['QT-20']!.value.valueOrNull, 3);
    expect(r['QT-20']!.args['currentRank'], isNotNull);
    // Uses on days 10 and 18 fall in consecutive 7-day blocks (2 and 3): relapse.
    final start = LocalDate(2026, 3, 1);
    final k = classifyRelapse(start, [(start.plusDays(9), 1), (start.plusDays(17), 1)]);
    expect(k.isRelapse, isTrue);
    expect(k.rule, RelapseRule.twoConsecutiveBlocks);
    // KM appears from 2 attempts.
    expect(r['QT-26']!.chart, isA<KmData>());
  });

  test('T6.6.10: €748.20 saved against €1 200 at €13/day → 35 days; goal ring on the tracker', () async {
    expect(
      savingsGoalEtaDays(saved: Decimal.parse('748.20'), goal: Decimal.parse('1200'), dailySaving: Decimal.parse('13')),
      const Value<int>(35),
    );
    final f = StatsFixture.load('quit_smoking_90_days');
    final tables = f.json['tables']! as Map<String, Object?>;
    tables['goals'] = [
      {
        'id': 'g',
        'scope_type': 'habit',
        'scope_id': 'smoking',
        'metric': 'money_saved',
        'target': 1200,
        'period': 'once',
      },
    ];
    final h = await f.seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.quit, scopeId: 'smoking', period: const StatsPeriod.allTime());
    final saved = r['QT-21']!.args['saved']! as double;
    expect(r['QT-21']!.value.valueOrNull, closeTo(saved / 1200, 1e-9));
    expect(r['QT-21']!.args['etaDays'], isA<int>());
    expect(r['QT-21']!.chart, isA<RingData>());
    expect(r['QT-22']!.value.valueOrNull, greaterThan(0));
    expect(r['QT-23']!.chart, isA<BarData>());
  });

  test('T6.6.12: Kaplan–Meier is hidden with a single attempt', () async {
    final h = await StatsFixture.load('quit_smoking_90_days').seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.quit, scopeId: 'smoking', period: const StatsPeriod.allTime());
    // One lapse splits the history into two attempts here; the fixture's KM therefore shows.
    expect(r['QT-26']!.note == 'error', isFalse);
    final single = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 12));
    addTearDown(single.dispose);
    await single.seedTables({
      'habits': [_tracker()],
    });
    final s = await single.compute(MetricScope.quit, scopeId: 'q', period: const StatsPeriod.allTime());
    expect(s['QT-26']!.chart, isNull);
    expect(s['QT-26']!.value.hasValue, isFalse);
  });

  testWidgets('T6.6.11: the withdrawal phase is labelled as typical and cites its source', (tester) async {
    final f = StatsFixture.load('quit_smoking_90_days');
    final tables = f.json['tables']! as Map<String, Object?>;
    // Keep only the first craving: abstinence since June 1, now 4 days later (week 1).
    f.json['now'] = '2026-06-05T10:00:00.000Z';
    tables['habit_logs'] = (tables['habit_logs']! as List)
        .cast<Map<String, Object?>>()
        .where((l) => l['kind'] == 'craving' && (l['local_date']! as String).compareTo('2026-06-05') < 0)
        .toList();
    final h = await f.seed();
    addTearDown(h.dispose);
    await h.settle();
    tester.view.physicalSize = const Size(420, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(tester, h, const ScopeStatsScreen(scope: 'quit', scopeId: 'smoking', query: {'period': 'allTime'}));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(en.statsMetricQt25Title), findsOneWidget);
    expect(find.text(en.chartsLabelTypicalVaries), findsOneWidget);
    expect(find.text(en.chartsLabelWithdrawalFirstWeek), findsOneWidget);
    // The explain sheet cites the NCI withdrawal fact sheet.
    final info = find.descendant(
      of: find.ancestor(of: find.text(en.statsMetricQt25Title), matching: find.byType(Card)),
      matching: find.byTooltip(en.chartsExplain),
    );
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.textContaining('cancer.gov'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));
  });
}
