import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show
        ConfidenceInterval,
        Granularity,
        Insufficient,
        MinDataRules,
        NotApplicable,
        PeriodComparison,
        TrendDirection,
        Value;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpChart(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  TextDirection? direction,
  double textScale = 1,
  Weekday weekStart = Weekday.monday,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: theme ?? AppTheme.light(),
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: true),
          child: Directionality(
            textDirection: direction ?? Directionality.of(context),
            child: ChartPrefs(
              weekStart: weekStart,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(padding: const EdgeInsets.all(16), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

LocalDate d(String iso) => LocalDate.parse(iso);

void main() {
  group('ChartFrame states (T6.2.01)', () {
    testWidgets('loading, empty, insufficient, error and data', (tester) async {
      for (final (status, text) in [
        (ChartFrameStatus.empty, 'No data for this period'),
        (ChartFrameStatus.insufficient, 'Needs 4 more data points'),
        (ChartFrameStatus.error, 'This chart couldn’t be computed'),
      ]) {
        await pumpChart(tester, ChartFrame(title: 'Adherence', status: status, missing: 4));
        expect(find.text(text), findsOneWidget, reason: '$status');
      }
      await pumpChart(tester, const ChartFrame(title: 'Adherence', status: ChartFrameStatus.loading));
      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    });

    testWidgets('view as table shows the plotted numbers and toggles back', (tester) async {
      const data = BarData(
        [TokenLabel(LabelToken.done), TokenLabel(LabelToken.missed)],
        [
          BarSeries(TokenLabel(LabelToken.count), [4, 1]),
        ],
      );
      await pumpChart(tester, const ChartFrame(title: 'Outcomes', data: data));
      await tester.tap(find.byTooltip('View as table'));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byTooltip('View as chart'));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('legend chips toggle series', (tester) async {
      final data = BarData(
        [DateLabel(d('2026-09-14')), DateLabel(d('2026-09-15'))],
        const [
          BarSeries(TokenLabel(LabelToken.planned), [3, 2]),
          BarSeries(TokenLabel(LabelToken.done), [2, 2], color: SeriesColor(1)),
        ],
      );
      await pumpChart(tester, ChartFrame(title: 'Done vs planned', data: data));
      expect(find.byType(FilterChip), findsNWidgets(2));
      await tester.tap(find.widgetWithText(FilterChip, 'Planned'));
      await tester.pump();
      final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Planned'));
      expect(chip.selected, isFalse);
    });
  });

  group('KPI tile (T6.2.02)', () {
    MetricResult rate(double cur, double prev, {int n = 10}) => MetricResult(
      'X',
      value: Value<double>(cur, sampleSize: n, interval: const ConfidenceInterval(0.6, 0.9)),
      unit: StatUnit.percent,
      comparison: PeriodComparison(
        Value<double>(cur),
        Value<double>(prev),
        delta: Value<double>((cur - prev) * 100),
        deltaPct: const NotApplicable<double>('rateUsesPp'),
        isRate: true,
      ),
      spark: const [0.5, 0.6, null, 0.7, 0.8],
    );

    testWidgets('announces the delta in percentage points', (tester) async {
      await pumpChart(tester, KpiTile(title: 'Adherence', result: rate(0.8, 0.75)));
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('+5.0 pp'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('up 5.0 percentage points')), findsWidgets);
      expect(find.byType(Sparkline), findsOneWidget);
    });

    testWidgets('lowerIsBetter shows a green down arrow', (tester) async {
      await pumpChart(
        tester,
        KpiTile(title: 'Miss rate', result: rate(0.1, 0.2), direction: MetricDirection.lowerIsBetter),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward_rounded));
      expect(icon.color, AppColors.light.success);
    });

    testWidgets('interval ± below 20 units, hidden above', (tester) async {
      await pumpChart(tester, KpiTile(title: 'A', result: rate(0.8, 0.75, n: 10), minSample: MinDataRules.rate));
      expect(find.textContaining('±'), findsOneWidget);
      await pumpChart(tester, KpiTile(title: 'A', result: rate(0.8, 0.75, n: 40), minSample: MinDataRules.rate));
      expect(find.textContaining('±'), findsNothing);
    });

    testWidgets('insufficient and not-applicable states', (tester) async {
      await pumpChart(
        tester,
        const KpiTile(
          title: 'A',
          result: MetricResult('X', value: Insufficient<double>(3, 1)),
        ),
      );
      expect(find.text('Needs 2 more data points'), findsOneWidget);
      await pumpChart(
        tester,
        const KpiTile(
          title: 'A',
          result: MetricResult('X', value: NotApplicable<double>('zeroDenominator')),
        ),
      );
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Nothing was due in this period.'), findsOneWidget);
    });

    testWidgets('sparkline hides at text scale 2.0 before text truncates', (tester) async {
      await pumpChart(tester, KpiTile(title: 'Adherence', result: rate(0.8, 0.75)), textScale: 2);
      expect(find.byType(Sparkline), findsNothing);
      expect(find.text('80%'), findsOneWidget);
    });
  });

  group('time series (T6.2.03)', () {
    test('LTTB keeps extrema and gaps', () {
      final values = <double?>[for (var i = 0; i < 1000; i++) i == 500 ? 1000 : (i % 7).toDouble()];
      values[700] = null;
      final out = lttb(values, 100);
      expect(out.length, lessThan(130));
      expect(out.any((p) => p.$2 == 1000), isTrue);
      expect(out.any((p) => p.$2 == null), isTrue);
      expect(out.first.$1, 0);
    });

    testWidgets('renders series with gaps, goal and trend', (tester) async {
      final data = TimeSeriesData(
        [for (var i = 0; i < 12; i++) d('2026-01-05').plusDays(7 * i)],
        const [
          ChartSeries(TokenLabel(LabelToken.rate), [0.5, 0.6, null, 0.62, 0.65, 0.7, 0.7, 0.72, 0.74, 0.8, 0.8, 0.82]),
        ],
        granularity: Granularity.week,
        unit: StatUnit.percent,
        goal: 0.9,
        trend: const TrendInfo(
          slopePerBucket: 0.02,
          intercept: 0.55,
          slopePerWeek: 2,
          direction: TrendDirection.rising,
          significant: true,
        ),
      );
      await pumpChart(tester, ChartFrame(title: 'Adherence', data: data));
      expect(find.byType(TimeSeriesChart), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Adherence.*from 50% to 82%.*Rising')), findsOneWidget);
    });
  });

  group('bars (T6.2.04)', () {
    final data = BarData(
      [DateLabel(d('2026-09-14')), DateLabel(d('2026-09-15')), DateLabel(d('2026-09-16'))],
      const [
        BarSeries(TokenLabel(LabelToken.done), [2, 3, 1], color: ToneColor(ChartTone.done)),
        BarSeries(TokenLabel(LabelToken.missed), [1, 1, 3], color: ToneColor(ChartTone.missed)),
      ],
      layout: BarLayout.stacked,
      drillKeys: const ['2026-09-14', '2026-09-15', '2026-09-16'],
      isTimeAxis: true,
    );

    testWidgets('tap returns the drill payload and a tooltip with shares', (tester) async {
      ChartTap? tap;
      await pumpChart(tester, SizedBox(width: 300, child: BarsChart(data, onTap: (t) => tap = t)));
      final box = tester.getRect(find.byType(BarsChart));
      // First category sits at the start (left in LTR).
      await tester.tapAt(Offset(box.left + 44 + (300 - 48) / 6, box.center.dy));
      await tester.pump();
      expect(tap?.drillKey, '2026-09-14');
      expect(find.textContaining('Done: 2 (67%)'), findsOneWidget);
    });

    testWidgets('RTL mirrors the category order', (tester) async {
      ChartTap? tap;
      await pumpChart(
        tester,
        SizedBox(width: 300, child: BarsChart(data, onTap: (t) => tap = t)),
        direction: TextDirection.rtl,
      );
      final box = tester.getRect(find.byType(BarsChart));
      await tester.tapAt(Offset(box.left + 4 + (300 - 48) / 6, box.center.dy));
      await tester.pump();
      expect(tap?.drillKey, '2026-09-16');
    });
  });

  group('composition (T6.2.05)', () {
    test('donut merges slices under 2 % and beyond 7 into Other', () {
      final slices = [
        for (var i = 0; i < 9; i++) DonutSlice(TextLabel('c$i'), 100.0 - i, color: SeriesColor(i)),
        const DonutSlice(TextLabel('tiny'), 1, color: SeriesColor(0)),
      ];
      final donut = DonutData(slices);
      expect(donut.slices.length, 8);
      expect((donut.slices.last.label as TokenLabel).token, LabelToken.other);
      expect(donut.slices.last.value, closeTo(92 + 93 + 1, 1e-9));
    });

    test('Pareto: ≤ 12 bars + Other, cumulative ends at 100 %, Unspecified last', () {
      final pareto = ParetoData([
        for (var i = 0; i < 15; i++) (TextLabel('r$i'), (20 - i).toDouble()),
        (const TokenLabel(LabelToken.unspecified), 30),
      ]);
      expect(pareto.entries.length, 14);
      expect((pareto.entries[12].$1 as TokenLabel).token, LabelToken.other);
      expect((pareto.entries.last.$1 as TokenLabel).token, LabelToken.unspecified);
      expect(pareto.cumulative.last, closeTo(1, 1e-9));
    });

    testWidgets('donut legend lists values and shares', (tester) async {
      final donut = DonutData(const [
        DonutSlice(TextLabel('Work'), 300, color: SeriesColor(0), drillKey: 'work'),
        DonutSlice(TextLabel('Health'), 100, color: SeriesColor(1), drillKey: 'health'),
      ], unit: StatUnit.minutes);
      ChartTap? tap;
      await pumpChart(tester, DonutChart(donut, onTap: (t) => tap = t));
      expect(find.textContaining('Work · 5 h · 75%'), findsOneWidget);
      await tester.tap(find.textContaining('Health ·'));
      expect(tap?.drillKey, 'health');
    });
  });

  group('calendar (T6.2.06)', () {
    CalendarData month() => CalendarData(
      {
        d('2026-09-01'): const CalendarCell(tone: ChartTone.done, label: TokenLabel(LabelToken.done)),
        d('2026-09-02'): const CalendarCell(tone: ChartTone.missed, label: TokenLabel(LabelToken.missed)),
        d('2026-09-03'): const CalendarCell(tone: ChartTone.skipped, label: TokenLabel(LabelToken.skipped)),
      },
      from: d('2026-09-01'),
      to: d('2026-09-30'),
      today: d('2026-09-03'),
    );

    testWidgets('month grid honours the week start and returns the tapped date', (tester) async {
      ChartTap? tap;
      await pumpChart(tester, CalendarHeatmap(month(), onTap: (t) => tap = t), weekStart: Weekday.sunday);
      final headers = tester
          .widgetList<Text>(find.descendant(of: find.byType(Row), matching: find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(headers.indexOf('Sun'), lessThan(headers.indexOf('Mon')));
      await tester.tap(find.bySemanticsLabel(RegExp('Sep 2, 2026, Missed')));
      expect(tap?.drillKey, '2026-09-02');
      expect(find.text('Skipped'), findsOneWidget);
    });

    testWidgets('long ranges use the year grid', (tester) async {
      final year = CalendarData(
        {for (var i = 0; i < 300; i++) d('2025-10-01').plusDays(i): CalendarCell(value: (i % 5).toDouble())},
        from: d('2025-10-01'),
        to: d('2026-09-30'),
        mode: CalendarMode.intensity,
      );
      await pumpChart(tester, CalendarHeatmap(year));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Sep 2026'), findsNothing);
    });
  });

  group('progress (T6.2.07)', () {
    testWidgets('rings cap at 100 % and show over-achievement text', (tester) async {
      await pumpChart(
        tester,
        const ProgressRings(
          RingData([(TokenLabel(LabelToken.habits), 1.2, ToneColor(ChartTone.done))], centerValue: 1.2),
        ),
      );
      expect(find.text('+20%'), findsOneWidget);
    });

    testWidgets('live counter ticks only while visible and uses instants', (tester) async {
      var now = DateTime.utc(2026, 7, 31);
      await pumpChart(tester, LiveCounter(since: DateTime.utc(2026, 6, 1), now: () => now));
      expect(find.text('60d 00:00:00'), findsOneWidget);
      expect(CounterTicker.shared.isRunning, isTrue);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('60d 00:00:01'), findsOneWidget);
      await pumpChart(
        tester,
        TickerMode(
          enabled: false,
          child: LiveCounter(since: DateTime.utc(2026, 6, 1), now: () => now),
        ),
      );
      expect(CounterTicker.shared.isRunning, isFalse);
    });

    testWidgets('milestone bars show ETA, reached and the restart note', (tester) async {
      final now = DateTime.utc(2026, 7, 1);
      await pumpChart(
        tester,
        MilestoneBars(
          MilestoneData([
            const MilestoneRow(id: 'a', label: TextLabel('20 min'), progress: 1, state: MilestoneRowState.done),
            MilestoneRow(
              id: 'b',
              label: const TextLabel('72 h'),
              progress: 0.5,
              state: MilestoneRowState.upcoming,
              eta: now.add(const Duration(hours: 36)),
              isNext: true,
              sources: const ['nhs'],
            ),
          ], restarted: true),
          now: () => now,
        ),
      );
      expect(find.text('Reached'), findsOneWidget);
      expect(find.text('in 1 d 12 h'), findsOneWidget);
      expect(find.textContaining('every day you already did still counts'), findsOneWidget);
      expect(find.text('Sources: nhs'), findsOneWidget);
    });
  });

  group('streaks & punch card (T6.2.08, T6.2.09)', () {
    test('streak bars are ordered by length, then recency', () {
      final data = StreakData([
        StreakBar(start: d('2026-01-01'), end: d('2026-01-05'), length: 5),
        StreakBar(start: d('2026-03-01'), end: d('2026-03-05'), length: 5),
        StreakBar(start: d('2026-02-01'), end: d('2026-02-09'), length: 9),
      ]);
      expect([for (final s in data.streaks) s.start], [d('2026-02-01'), d('2026-03-01'), d('2026-01-01')]);
    });

    testWidgets('punch card taps return weekday and hour; empty shows the empty state', (tester) async {
      final values = [for (var w = 0; w < 7; w++) List<double>.filled(24, 0)];
      values[0][9] = 4;
      ChartTap? tap;
      await pumpChart(
        tester,
        SizedBox(
          width: 36 + 24 * 12.0,
          child: PunchCardChart(PunchCardData(values), onTap: (t) => tap = t),
        ),
      );
      final box = tester.getRect(find.byType(PunchCardChart));
      await tester.tapAt(Offset(box.left + 36 + 9 * 12 + 6, box.top + 16 + 6));
      expect(tap?.drillKey, 'weekday:1:9');
      await pumpChart(tester, PunchCardChart(PunchCardData([for (var w = 0; w < 7; w++) List<double>.filled(24, 0)])));
      expect(find.text('No data for this period'), findsOneWidget);
    });
  });
}
