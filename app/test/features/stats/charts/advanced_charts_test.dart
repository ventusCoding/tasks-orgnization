// P1/P2 chart kit (T6.2.13–T6.2.21, T6.2.25, T6.2.26): layout algorithms, scales and the behavior
// of each chart (taps, read-outs, labels). Goldens live in advanced_chart_goldens_test.dart.
import 'dart:math' as math;

import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show histogramFixedWidth, percentile;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'chart_kit_test.dart' show pumpChart;

LocalDate d(String iso) => LocalDate.parse(iso);

ChartData sample(String title) => allChartSamples().firstWhere((s) => s.title == title).data;

void main() {
  group('treemap (T6.2.20)', () {
    test('squarify: areas proportional to values (±1 %), inside the bounds, no overlap', () {
      const bounds = Rect.fromLTWH(0, 0, 360, 220);
      for (final values in <List<double>>[
        [600, 240, 160],
        [5, 4, 3, 2, 1, 1, 0.5],
        [1],
        [100, 0, 50],
      ]) {
        final rects = squarify(values, bounds);
        final total = values.fold<double>(0, (a, v) => a + v);
        for (var i = 0; i < values.length; i++) {
          final expected = values[i] / total * bounds.width * bounds.height;
          final area = rects[i].width * rects[i].height;
          expect((area - expected).abs(), lessThanOrEqualTo(expected * 0.01 + 1e-6), reason: '$values[$i]');
          if (values[i] > 0) expect(bounds.inflate(1e-6).contains(rects[i].center), isTrue);
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final o = rects[i].intersect(rects[j]);
            expect(o.width <= 1e-6 || o.height <= 1e-6, isTrue, reason: 'overlap $i/$j');
          }
        }
      }
      expect(squarify(const [], const Rect.fromLTWH(0, 0, 10, 10)), isEmpty);
    });

    testWidgets('tapping a block drills into it', (tester) async {
      ChartTap? tap;
      await pumpChart(tester, TreemapChart(sample('Time allocation') as TreemapData, onTap: (t) => tap = t));
      // The largest block (Work) starts at the top start corner; its first child is Reports.
      final box = tester.getRect(find.byType(TreemapChart));
      await tester.tapAt(box.topLeft + const Offset(20, 40));
      expect(tap?.label, const TextLabel('Reports'));
    });
  });

  group('Gantt (T6.2.13)', () {
    test('overlapping sessions get separate lanes; variance tones', () {
      final t = DateTime.utc(2026, 9, 14, 9);
      TimeSpan s(int a, int b) => TimeSpan(t.add(Duration(minutes: a)), t.add(Duration(minutes: b)));
      expect(assignLanes([s(0, 30), s(20, 50), s(40, 60), s(60, 70)]), [0, 1, 0, 0]);
      expect(assignLanes([s(0, 60), s(10, 20), s(15, 25)]), [0, 1, 2]);
      final planned = s(0, 60);
      expect(sessionTone(s(0, 55), planned), ChartTone.done);
      expect(sessionTone(s(10, 50), planned), ChartTone.late);
      expect(sessionTone(s(-20, 40), planned), ChartTone.pending);
      expect(sessionTone(s(0, 80), planned), ChartTone.negative);
    });

    testWidgets('a row tap reads out planned and actual minutes and opens its entity', (tester) async {
      DrillRef? opened;
      final data = sample('Planned vs actual') as GanttData;
      final withRefs = GanttData(
        [
          for (final r in data.rows)
            GanttRow(r.label, planned: r.planned, actual: r.actual, ref: const DrillRef(DrillKind.day, 'x')),
        ],
        from: data.from,
        to: data.to,
      );
      await pumpChart(tester, GanttChart(withRefs, onRef: (r) => opened = r));
      await tester.tapAt(tester.getTopLeft(find.byType(GanttChart)) + const Offset(30, 10));
      await tester.pump();
      expect(opened?.id, 'x');
      expect(find.textContaining('2 h'), findsWidgets); // planned 120 min
    });

    testWidgets('move timeline paints one row per move', (tester) async {
      await pumpChart(tester, MoveTimelineChart(sample('Reschedules') as MoveTimelineData));
      expect(tester.getSize(find.byType(MoveTimelineChart)).height, 16.0 * 2 + 24);
    });
  });

  group('histogram & box plot (T6.2.14)', () {
    testWidgets('markers are the [6.1] percentiles; count/share toggle; bin tap', (tester) async {
      final values = [for (var i = 0; i < 40; i++) 10.0 + (i * 7) % 60];
      final p50 = percentile(values, 50).valueOrNull!;
      final p85 = percentile(values, 85).valueOrNull!;
      final bins = histogramFixedWidth(values, 10).bins;
      final data = HistogramData(
        [for (final b in bins) (b.lower, b.upper, b.count)],
        unit: StatUnit.minutes,
        markers: [(p50, const TokenLabel(LabelToken.p50)), (p85, const TokenLabel(LabelToken.p85))],
      );
      expect(data.toTable().rows.reversed.take(2).map((r) => r[1].value), [p85, p50]);
      ChartTap? tap;
      await pumpChart(tester, HistogramChart(data, onTap: (t) => tap = t));
      expect(find.text('Count'), findsOneWidget);
      await tester.tap(find.text('Share'));
      await tester.pump();
      final chart = tester.getRect(find.byType(CustomPaint).last);
      await tester.tapAt(chart.bottomCenter + const Offset(0, -40));
      await tester.pump();
      expect(tap?.drillKey, startsWith('bin:'));
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('box plots tap to a group', (tester) async {
      ChartTap? tap;
      await pumpChart(tester, BoxPlotChart(sample('Cycle time by month') as BoxPlotData, onTap: (t) => tap = t));
      final r = tester.getRect(find.byType(BoxPlotChart));
      await tester.tapAt(Offset(r.left + 44 + (r.width - 52) * 0.5, r.top + 80));
      expect(tap?.drillKey, 'group:1');
      expect(tap?.label, const TextLabel('Aug'));
    });
  });

  group('scatter (T6.2.15)', () {
    testWidgets('tapping a point opens its entity; 2 000 points stay responsive', (tester) async {
      DrillRef? opened;
      final data = sample('Planned vs actual duration') as ScatterData;
      await pumpChart(tester, ScatterChart(data, onRef: (r) => opened = r));
      final box = tester.getRect(find.byType(ScatterChart));
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(of: find.byType(ScatterChart), matching: find.byType(CustomPaint)).first,
                  )
                  .painter!
              as ScatterPainter;
      // Find the screen position of point 0 by probing the painter's hit test.
      Offset? at;
      for (var x = 0.0; x < box.width && at == null; x += 2) {
        for (var y = 0.0; y < box.height && at == null; y += 2) {
          if (painter.pointAt(Offset(x, y), box.size) == 0) at = Offset(x, y);
        }
      }
      expect(at, isNotNull);
      await tester.tapAt(box.topLeft + at!);
      await tester.pump();
      expect(opened?.id, isNotNull);

      final many = ScatterData(
        [for (var i = 0; i < 2000; i++) ScatterPoint(i % 97 + 1.0, (i * 13) % 89 + 1.0)],
        variant: ScatterVariant.planVsActual,
        xUnit: StatUnit.minutes,
        yUnit: StatUnit.minutes,
      );
      final watch = Stopwatch()..start();
      await pumpChart(tester, ScatterChart(many));
      await tester.tapAt(tester.getCenter(find.byType(ScatterChart)));
      await tester.pump();
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });

    test('aging WIP jitter stays inside its column', () {
      for (var i = 0; i < 500; i++) {
        expect(ScatterPainter.jitter(i).abs(), lessThanOrEqualTo(0.3));
      }
    });
  });

  group('cumulative flow (T6.2.16)', () {
    test('bands never cross, a reopen lowers the completed band, WIP and cycle time', () {
      final data = sample('Cumulative flow') as StackedAreaData;
      final bands = StackedBands(data);
      for (var i = 0; i < data.buckets.length; i++) {
        for (var k = 1; k < bands.tops.length; k++) {
          expect(bands.tops[k][i], greaterThanOrEqualTo(bands.tops[k - 1][i]));
        }
      }
      expect(bands.tops[0][12], lessThan(bands.tops[0][11] + 1)); // the reopen on day 12
      expect(bands.isCfd, isTrue);
      // Day 0: completed 0, waiting 1, ongoing 2 → WIP 3, cycle time until completed ≥ 3 (day 4).
      expect(bands.wipAt(0), 3);
      expect(bands.cycleTimeAt(0), 4);
      expect(StackedBands(data, hidden: {0}).isCfd, isFalse);
    });

    testWidgets('scrubbing reads out every band, the WIP and the cycle time', (tester) async {
      await pumpChart(tester, StackedAreaChart(sample('Cumulative flow') as StackedAreaData));
      final r = tester.getRect(find.byType(StackedAreaChart));
      await tester.dragFrom(Offset(r.left + 50, r.center.dy), const Offset(-4, 0));
      await tester.pump();
      for (final label in ['Completed', 'Ongoing', 'To do', 'In progress']) {
        expect(find.textContaining(label), findsWidgets, reason: label);
      }
      expect(find.textContaining('Cycle time'), findsOneWidget);
    });
  });

  group('burn & forecast (T6.2.17, T6.2.26)', () {
    testWidgets('scope increases are steps with a marker listing the added items', (tester) async {
      await pumpChart(tester, ChartView(sample('Burn-up')));
      expect(find.textContaining('+4 — Buy paint, Call plumber, Fix door, Order tiles'), findsOneWidget);
      expect(find.textContaining('+2 — Clean garage, Sell bike'), findsOneWidget);
    });

    testWidgets('the cone starts at the last actual point and labels P50/P85/P95 with dates', (tester) async {
      final data = sample('Burn-down with forecast') as TimeSeriesData;
      await pumpChart(tester, ChartView(data));
      // P50 reaches 0 after 11 days (13.1 − 11 × 1.3 < 0), P85 after 14, P95 after 16.
      expect(find.textContaining('P50: Sep 25, 2026'), findsOneWidget);
      expect(find.textContaining('P85: Sep 28, 2026'), findsOneWidget);
      expect(find.textContaining('P95: Sep 30, 2026'), findsOneWidget);
    });

    testWidgets('finish-date histogram labels the percentiles with dates', (tester) async {
      await pumpChart(tester, ChartView(sample('Finish date forecast')));
      expect(find.textContaining('P50 Sep 25, 2026'), findsOneWidget);
      expect(find.textContaining('P95 Sep 28, 2026'), findsOneWidget);
    });
  });

  group('radar, rose, matrix, KM (T6.2.18, T6.2.19, T6.2.21, T6.2.25)', () {
    test('radar table lists every axis', () {
      final data = sample('Weekday profile') as RadarData;
      expect(data.toTable().rows, hasLength(7));
    });

    test('rose: a cluster around midnight is one lobe (adjacent sectors around the top)', () {
      final data = sample('Check-in clock') as RoseData;
      final painter = RosePainter(
        data,
        theme: ChartTheme.fallback(ThemeData()),
        format: StatFormatForTests.en(),
        labelStyle: const TextStyle(),
      );
      // 23:30 and 00:30 sit symmetrically on both sides of the top (day start 00:00).
      final a = painter.angleOf(1410);
      final b = painter.angleOf(30);
      expect((a - (-math.pi / 2)).abs() - 2 * math.pi, closeTo(-(b - (-math.pi / 2)).abs(), 1e-9));
      const size = Size(200, 200);
      expect(painter.sectorAt(const Offset(95, 30), size), 23);
      expect(painter.sectorAt(const Offset(105, 30), size), 0);
    });

    test('matrix: a diverging scale is symmetric around 0', () {
      final painter = MatrixPainter(
        sample('Habit co-occurrence') as MatrixData,
        theme: ChartTheme.fallback(ThemeData()),
        format: StatFormatForTests.en(),
        rtl: false,
        cell: 30,
        labelWidth: 72,
        header: 22,
        labelStyle: const TextStyle(),
      );
      expect(painter.bound, 1);
      expect(painter.colorOf(0.5).a, painter.colorOf(-0.5).a);
      expect(painter.colorOf(0.5), isNot(painter.colorOf(-0.5)));
      expect(painter.colorOf(null), isNot(painter.colorOf(0)));
    });

    testWidgets('matrix tap shows the full row × column names', (tester) async {
      await pumpChart(tester, MatrixHeatmap(sample('Habit co-occurrence') as MatrixData));
      final r = tester.getRect(find.byType(MatrixHeatmap));
      await tester.tapAt(r.topLeft + const Offset(72 + 44 + 10, 22 + 10));
      await tester.pump();
      expect(find.text('Run × Read'), findsOneWidget);
    });

    testWidgets('KM: "median not reached" is explicit', (tester) async {
      await pumpChart(tester, const KmChart(KmData([KmPoint(24, 0.8), KmPoint(48, 0.7, censored: 2)])));
      expect(find.text('Median not reached'), findsOneWidget);
      await pumpChart(tester, KmChart(sample('Time to first lapse') as KmData));
      expect(find.textContaining('Median 7 days'), findsOneWidget);
    });
  });

  testWidgets('every P1/P2 sample renders through ChartView (LTR and RTL, no overflow)', (tester) async {
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      for (final s in advancedChartSamples()) {
        await pumpChart(
          tester,
          ChartFrame(title: s.title, data: s.data),
          direction: direction,
        );
        expect(tester.takeException(), isNull, reason: '${s.title} $direction');
        expect(find.byType(ChartDataTable), findsNothing, reason: '${s.title} still falls back to its table');
      }
    }
  });
}

/// A plain English formatter for painter unit tests.
abstract final class StatFormatForTests {
  static StatFormat en() => StatFormat(lookupAppLocalizations(const Locale('en')), 'en');
}
