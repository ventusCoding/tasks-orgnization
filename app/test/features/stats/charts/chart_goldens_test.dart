// Golden matrix of the P0 chart kit (T6.2.12): light/dark × LTR/RTL × text scale 1.0/2.0, one
// gallery image per variant with fixture data for every P0 chart; plus a heavy-scene render check.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show Granularity, NotApplicable, PeriodComparison, TrendDirection, Value;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

/// Fixture data of every P0 chart.
List<(String, ChartData)> p0Charts() {
  final weeks = [for (var i = 0; i < 12; i++) d('2026-06-29').plusDays(7 * i)];
  return [
    (
      'Adherence',
      TimeSeriesData(
        weeks,
        const [
          ChartSeries(TokenLabel(LabelToken.rate), [0.5, 0.6, null, 0.62, 0.65, 0.7, 0.7, 0.72, 0.74, 0.8, 0.8, 0.82]),
          ChartSeries(
            TokenLabel(LabelToken.rollingMean),
            [null, null, null, 0.57, 0.62, 0.66, 0.67, 0.7, 0.72, 0.74, 0.77, 0.79],
            color: SeriesColor(1),
            role: SeriesRole.rollingMean,
          ),
        ],
        granularity: Granularity.week,
        unit: StatUnit.percent,
        goal: 0.9,
        trend: const TrendInfo(
          slopePerBucket: 0.025,
          intercept: 0.53,
          slopePerWeek: 2.5,
          direction: TrendDirection.rising,
          significant: true,
        ),
      ),
    ),
    (
      'Done vs planned',
      BarData(
        [for (var i = 0; i < 7; i++) DateLabel(d('2026-09-14').plusDays(i))],
        const [
          BarSeries(TokenLabel(LabelToken.planned), [3, 4, 2, 5, 3, 1, 0], color: SeriesColor(1)),
          BarSeries(TokenLabel(LabelToken.done), [3, 3, 2, 4, 1, 1, 0], color: ToneColor(ChartTone.done)),
        ],
        overlays: const [
          BarOverlay(TokenLabel(LabelToken.capacity), [4]),
        ],
        isTimeAxis: true,
      ),
    ),
    (
      'Outcomes',
      BarData(
        const [TokenLabel(LabelToken.total)],
        const [
          BarSeries(TokenLabel(LabelToken.done), [24], color: ToneColor(ChartTone.done)),
          BarSeries(TokenLabel(LabelToken.partial), [3], color: ToneColor(ChartTone.partial)),
          BarSeries(TokenLabel(LabelToken.missed), [2], color: ToneColor(ChartTone.missed)),
          BarSeries(TokenLabel(LabelToken.skipped), [1], color: ToneColor(ChartTone.skipped)),
        ],
        layout: BarLayout.stacked,
      ),
    ),
    (
      'Time by category',
      DonutData(const [
        DonutSlice(TextLabel('Work'), 465, color: ArgbColor(0xFF3B82F6)),
        DonutSlice(TextLabel('Personal'), 210, color: ArgbColor(0xFF8B5CF6)),
        DonutSlice(TextLabel('Health'), 180, color: ArgbColor(0xFF10B981)),
        DonutSlice(TokenLabel(LabelToken.uncategorized), 60, color: ToneColor(ChartTone.muted)),
      ], unit: StatUnit.minutes),
    ),
    (
      'Skip reasons',
      ParetoData(const [
        (TextLabel('Tired'), 5),
        (TextLabel('Sick'), 2),
        (TextLabel('Travel'), 1),
        (TokenLabel(LabelToken.unspecified), 1),
      ]),
    ),
    (
      'Calendar',
      CalendarData(
        {
          for (var i = 0; i < 30; i++)
            d('2026-09-01').plusDays(i): CalendarCell(
              tone: [
                ChartTone.done,
                ChartTone.done,
                ChartTone.partial,
                ChartTone.missed,
                ChartTone.skipped,
                ChartTone.excused,
                ChartTone.frozen,
              ][i % 7],
              label: TokenLabel(
                [
                  LabelToken.done,
                  LabelToken.done,
                  LabelToken.partial,
                  LabelToken.missed,
                  LabelToken.skipped,
                  LabelToken.excused,
                  LabelToken.frozen,
                ][i % 7],
              ),
            ),
        },
        from: d('2026-09-01'),
        to: d('2026-09-30'),
        today: d('2026-09-26'),
      ),
    ),
    (
      'Year',
      CalendarData(
        {for (var i = 0; i < 365; i++) d('2025-09-27').plusDays(i): CalendarCell(value: ((i * 7) % 11).toDouble())},
        from: d('2025-09-27'),
        to: d('2026-09-26'),
        mode: CalendarMode.intensity,
        today: d('2026-09-26'),
      ),
    ),
    ('Rings', const RingData([(TokenLabel(LabelToken.habits), 0.75, ToneColor(ChartTone.done))], centerValue: 0.75)),
    ('Target', const BulletData(actual: 390, target: 435, previous: 350, bands: [217, 348, 435])),
    (
      'Milestones',
      MilestoneData([
        const MilestoneRow(id: 'a', label: TextLabel('20 min'), progress: 1, state: MilestoneRowState.done),
        MilestoneRow(
          id: 'b',
          label: const TextLabel('72 h'),
          progress: 0.4,
          state: MilestoneRowState.upcoming,
          eta: DateTime.utc(2026, 9, 28),
          isNext: true,
        ),
        const MilestoneRow(
          id: 'c',
          label: TextLabel('2–12 weeks'),
          progress: 0.1,
          state: MilestoneRowState.upcoming,
          rangeMarker: 0.17,
        ),
      ]),
    ),
    (
      'Streaks',
      StreakData([
        StreakBar(start: d('2026-08-01'), end: d('2026-08-20'), length: 20),
        StreakBar(start: d('2026-09-10'), end: d('2026-09-26'), length: 17, current: true, frozenUnits: 2),
        StreakBar(start: d('2026-07-01'), end: d('2026-07-08'), length: 8),
      ]),
    ),
    (
      'Busiest hours',
      PunchCardData([
        for (var w = 0; w < 7; w++)
          [for (var h = 0; h < 24; h++) (h >= 8 && h <= 18 && w < 5) ? ((h * (w + 1)) % 9).toDouble() : 0.0],
      ]),
    ),
  ];
}

Widget gallery({required bool dark, required bool rtl, required double scale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: ChartPrefs(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                KpiTile(
                  title: 'Adherence',
                  result: MetricResult(
                    'PL-S-03',
                    value: const Value<double>(0.8, sampleSize: 5),
                    unit: StatUnit.percent,
                    comparison: PeriodComparison(
                      const Value<double>(0.8),
                      const Value<double>(0.75),
                      delta: const Value<double>(5),
                      deltaPct: const NotApplicable<double>('rateUsesPp'),
                      isRate: true,
                    ),
                    spark: const [0.5, 0.6, 0.7, 0.8],
                  ),
                ),
                for (final (title, data) in p0Charts())
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ChartFrame(title: title, data: data, chartHeight: 160, onExplain: () {}),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}_${scale == 1 ? '1x' : '2x'}';
        testWidgets('P0 charts golden $name', (tester) async {
          tester.view.physicalSize = Size(420, scale == 1 ? 3200 : 5200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(gallery(dark: dark, rtl: rtl, scale: scale));
          await tester.pumpAndSettle();
          await expectLater(find.byType(ListView), matchesGoldenFile('goldens/p0_charts_$name.png'));
        });
      }
    }
  }

  testWidgets('heavy scene: year heatmap + 1 825-point line + 60 bars builds and paints', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final line = TimeSeriesData(
      [for (var i = 0; i < 1825; i++) d('2021-09-27').plusDays(i)],
      [
        ChartSeries(const TokenLabel(LabelToken.score), [for (var i = 0; i < 1825; i++) (i % 97) / 97]),
      ],
      unit: StatUnit.score,
    );
    final bars = BarData(
      [for (var i = 0; i < 60; i++) DateLabel(d('2026-01-01').plusDays(i))],
      [
        BarSeries(const TokenLabel(LabelToken.count), [for (var i = 0; i < 60; i++) (i % 13).toDouble()]),
      ],
      isTimeAxis: true,
    );
    final year = p0Charts().firstWhere((c) => c.$1 == 'Year').$2;
    final watch = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(body: ListView(children: [ChartView(year), ChartView(line), ChartView(bars)])),
      ),
    );
    await tester.pumpAndSettle();
    watch.stop();
    // Debug-mode smoke budget; frame-time budgets (≤ 8 ms build + raster) are measured in profile
    // mode by the device performance suite ([9.1]).
    expect(watch.elapsedMilliseconds, lessThan(3000));
    expect(find.byType(TimeSeriesChart), findsOneWidget);
    expect(find.byType(BarsChart), findsOneWidget);
  });
}
