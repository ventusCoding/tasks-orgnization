// Overview report screens and services (T6.7.03, T6.7.08, T6.7.12, T6.7.14, T6.7.16): the guided
// review flow (resume + completion event), the insights feed (dedupe, mute, dismiss, records
// announced once), exports (CSV values as on screen) and share card golden, Wrapped, dashboards.
import 'dart:convert';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/dashboards.dart';
import 'package:everslot/features/stats/application/guided_review.dart';
import 'package:everslot/features/stats/application/insights_feed.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/dashboard.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_share.dart';
import 'package:everslot/features/stats/presentation/dashboards_view.dart';
import 'package:everslot/features/stats/presentation/export/stats_export.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot/features/stats/presentation/guided_review_screen.dart';
import 'package:everslot/features/stats/presentation/insights_feed_view.dart';
import 'package:everslot/features/stats/presentation/wrapped_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show InsightTrigger;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));

const _daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';

/// A habit done every day for the last 7 days (a 7-day streak milestone and a first record).
Map<String, List<Map<String, Object?>>> _streakTables() => {
  'habits': [
    {
      'id': 'a',
      'kind': 'build',
      'name': 'Reading',
      'sort_key': 'a',
      'goal_type': 'check',
      'target_op': 'gte',
      'schedule': _daily,
      'start_date': '2026-09-14',
      'time_zone': 'UTC',
      'created_at': '2026-09-14T06:00:00.000Z',
    },
  ],
  'habit_logs': [
    for (var d = 14; d <= 20; d++)
      {
        'id': 'l$d',
        'habit_id': 'a',
        'kind': 'done',
        'logged_at': '2026-09-${d}T08:00:00.000Z',
        'local_date': '2026-09-$d',
        'created_at': '2026-09-${d}T08:00:00.000Z',
      },
  ],
};

class _FakeFiles implements StatsFileSharer {
  final shared = <List<ExportFile>>[];

  @override
  Future<void> share(List<ExportFile> files, {required String title}) async => shared.add(files);
}

Future<void> _settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 61));
}

void main() {
  group('T6.7.08 insights feed', () {
    test('fires once, announces records once, honours dismiss and mute', () async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(h.dispose);
      await h.seedTables(_streakTables());
      await h.settle();
      final service = h.read(insightsFeedServiceProvider);
      final first = await service.generate(dataVersion: 'v1', statsSettings: h.read(statsSettingsProvider));
      final triggers = first.map((i) => i.trigger).toSet();
      expect(triggers, containsAll([InsightTrigger.streakMilestone, InsightTrigger.newRecord]));
      final streak = first.firstWhere((i) => i.trigger == InsightTrigger.streakMilestone);
      expect(insightText(en, StatFormat(en, 'en'), streak), 'Reading: 7-day streak!');
      // The same candidates never fire twice.
      expect(await service.generate(dataVersion: 'v2', statsSettings: h.read(statsSettingsProvider)), isEmpty);
      // The record is stored as announced.
      final stats = await h.read(settingsRepositoryProvider).read(SettingsNs.stats);
      expect(stats['announcedRecords'], contains('habitStreak:a|7.0'));

      final rows = await h.read(insightStateStoreProvider).all();
      final now = DateTime.utc(2026, 9, 20, 21);
      expect(InsightsFeedService.feedOf(rows, now: now, muted: const {}), hasLength(first.length));
      await service.dismiss(streak.key);
      final afterDismiss = InsightsFeedService.feedOf(
        await h.read(insightStateStoreProvider).all(),
        now: now,
        muted: const {},
      );
      expect(afterDismiss.any((i) => i.key == streak.key), isFalse);
      await service.setMuted(InsightTrigger.newRecord, muted: true);
      final muted = (await h.read(settingsRepositoryProvider).read(SettingsNs.stats))['mutedInsightTypes'];
      expect(muted, ['newRecord']);
      expect(
        InsightsFeedService.feedOf(await h.read(insightStateStoreProvider).all(), now: now, muted: {'newRecord'}),
        isEmpty,
      );
    });

    testWidgets('the feed shows the sentence and explains why', (tester) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(h.dispose);
      await tester.runAsync(() async {
        await h.seedTables(_streakTables());
        await h.settle();
      });
      await pumpStats(tester, h, const Scaffold(body: InsightsFeedView()));
      await _settle(tester);
      expect(find.text('Reading: 7-day streak!'), findsOneWidget);
      await tester.tap(find.byTooltip(en.actionMore).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.statsFeedWhy).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Once per'), findsWidgets);
      await _teardown(tester);
    });
  });

  testWidgets('T6.7.03: the guided review resumes at its step and records its completion', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 21, 9));
    addTearDown(h.dispose);
    await tester.runAsync(h.settle);
    await pumpStats(tester, h, const Scaffold(body: GuidedReviewScreen()));
    await _settle(tester);
    expect(find.text(en.statsGuidedStepOf(1, 6)), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(en.statsGuidedNext));
      await _settle(tester, rounds: 3);
    }
    expect(find.text(en.statsGuidedStepOf(4, 6)), findsOneWidget);
    // "Kill" the screen and open it again: it resumes at step 4.
    await tester.pumpWidget(const SizedBox());
    await pumpStats(tester, h, const Scaffold(body: GuidedReviewScreen()));
    await _settle(tester);
    expect(find.text(en.statsGuidedStepOf(4, 6)), findsOneWidget);
    expect(await tester.runAsync(() => h.read(guidedReviewServiceProvider).savedStep(LocalDate(2026, 9, 14))), 3);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text(en.statsGuidedNext));
      await _settle(tester, rounds: 3);
    }
    await tester.tap(find.byKey(const ValueKey('guided-finish')));
    await _settle(tester);
    final rows = await tester.runAsync(
      () => h.db
          .customSelect("SELECT entity_type, event_type, payload FROM activity_events WHERE entity_type = 'review'")
          .get(),
    );
    expect(rows, hasLength(1));
    expect(rows!.single.read<String>('event_type'), 'completed');
    expect((jsonDecode(rows.single.read<String>('payload')) as Map)['week'], '2026-09-14');
    final r = await tester.runAsync(() => h.compute(MetricScope.global, metricIds: {'GL-04'}));
    expect(r!['GL-04']!.value.valueOrNull, 1);
    await _teardown(tester);
  });

  group('T6.7.12 export & share', () {
    test('CSV values equal the on-screen values: ISO dates, dot decimals, BOM, RTL text kept', () {
      final f = StatFormat(en, 'en');
      final table = TimeSeriesData(
        [LocalDate(2026, 9, 14), LocalDate(2026, 9, 15)],
        const [
          ChartSeries(TextLabel('قراءة'), [0.755, null]),
        ],
        unit: StatUnit.percent,
      ).toTable();
      final csv = chartCsv(table, f, header: const ['GL-07 — Day score'], options: const ExportOptions(bom: true));
      final lines = csv.split('\r\n');
      expect(csv.startsWith('﻿# GL-07 — Day score'), isTrue);
      expect(lines[1], 'Current,قراءة');
      expect(lines[2], '2026-09-14,75.5');
      expect(lines[3], '2026-09-15,');
      final local = chartCsv(table, f, options: const ExportOptions(localeFormatted: true));
      expect(local.split('\r\n')[1].endsWith(f.value(0.755, StatUnit.percent)), isTrue);
    });

    testWidgets('a chart exports as CSV from its share sheet', (tester) async {
      final files = _FakeFiles();
      statsFileSharer = files;
      addTearDown(() => statsFileSharer = const PlatformStatsFileSharer());
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: const Scaffold(
            body: ChartShareSheet(
              title: 'Week',
              metricId: 'GL-03',
              data: TilesData([
                ValueTile(TokenLabel(LabelToken.habits), 0.5, StatUnit.percent),
                ValueTile(TokenLabel(LabelToken.items), 3, StatUnit.count),
              ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-csv')));
      await tester.pumpAndSettle();
      final csv = files.shared.single.single;
      expect(csv.name, 'everslot_gl-03.csv');
      expect(csv.text, contains('Habits,50.0'));
      expect(csv.text, contains('Items,3.0'));
    });

    testWidgets('week summary share card golden', (tester) async {
      tester.view.physicalSize = const Size(420, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: ChartShareCard(
                title: 'Sep 14 – Sep 20, 2026',
                data: TilesData([
                  ValueTile(TokenLabel(LabelToken.agenda), 17 / 21, StatUnit.percent, delta: 0.05, deltaIsPp: true),
                  ValueTile(TokenLabel(LabelToken.actual), 250 / 60, StatUnit.hours, delta: -0.5),
                  ValueTile(TokenLabel(LabelToken.habits), 27 / 34, StatUnit.percent, delta: -0.024, deltaIsPp: true),
                  ValueTile(TokenLabel(LabelToken.money), 91, StatUnit.currency, currency: 'EUR'),
                ]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(ChartShareCard), matchesGoldenFile('goldens/week_summary_card.png'));
    });
  });

  testWidgets('T6.7.14: Wrapped pages through the story cards', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await tester.runAsync(() => StatsFixture.load('overview_week').seed());
    addTearDown(h!.dispose);
    await pumpStats(tester, h, const Scaffold(body: WrappedView(year: 2026)));
    await _settle(tester);
    expect(find.text(en.statsWrappedTitle(2026)), findsOneWidget);
    expect(find.text(en.chartsLabelYearInNumbers), findsOneWidget);
    await tester.tap(find.byTooltip(en.statsWrappedNext));
    await tester.pumpAndSettle();
    expect(find.text(en.chartsLabelYearInNumbers), findsNothing);
    expect(find.byKey(const ValueKey('wrapped-share')), findsOneWidget);
    await _teardown(tester);
  });

  group('T6.7.16 custom dashboards', () {
    test('a dashboard round-trips through the synced table and the outbox', () async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(h.dispose);
      final repo = h.read(dashboardsRepositoryProvider);
      final (id, _) = await repo.create('Morning');
      const cards = [
        DashboardCard(metricId: 'HB-X-01', scope: MetricScope.habits),
        DashboardCard(metricId: 'GL-01', scope: MetricScope.global, period: 'rolling:7', span: 2),
      ];
      await repo.setCards(id, cards);
      final all = await repo.watchAll().first;
      expect(all.single.name, 'Morning');
      expect(all.single.cards, cards);
      final outbox = await h.db.customSelect("SELECT * FROM sync_outbox WHERE table_name = 'dashboards'").get();
      expect(outbox, isNotEmpty);
      expect(outbox.map((r) => '${r.data}').join(), contains('rolling:7'));
      // A row arriving from another device (sync apply) parses back to the same cards.
      final remote = Dashboard.cardsOf(jsonDecode(jsonEncode([for (final c in cards) c.toJson()])));
      expect(remote, cards);
      await repo.delete(id);
      expect(await repo.watchAll().first, isEmpty);
    });

    testWidgets('a dashboard renders its cards and can be edited', (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await tester.runAsync(() => StatsFixture.load('overview_week').seed());
      addTearDown(h!.dispose);
      final id = await tester.runAsync(() async {
        final repo = h.read(dashboardsRepositoryProvider);
        final (id, _) = await repo.create('Morning');
        await repo.setCards(id, const [
          DashboardCard(metricId: 'GL-02', scope: MetricScope.global),
          DashboardCard(metricId: 'GL-07', scope: MetricScope.global, span: 2),
        ]);
        return id;
      });
      await pumpStats(tester, h, Scaffold(body: DashboardView(id: id!)));
      await _settle(tester);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text(en.statsMetricGl07Title), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dashboard-edit')));
      await tester.pump();
      await tester.tap(find.byTooltip(en.statsDashboardRemoveCard).first);
      await _settle(tester);
      final d = await tester.runAsync(() => h.read(dashboardsRepositoryProvider).watch(id).first);
      expect(d!.cards.map((c) => c.metricId), ['GL-07']);
      await _teardown(tester);
    });
  });
}
