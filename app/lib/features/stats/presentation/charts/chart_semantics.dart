/// Auto-generated semantic summaries of charts (T6.2.11): range, min/max, trend and latest value —
/// e.g. "Adherence, last 12 weeks: from 62 % to 71 %. Rising 0.8 pp per week."
library;

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show TrendDirection;
import 'package:everslot_recurrence/everslot_recurrence.dart' show Weekday;

/// One sentence describing [data] for screen readers.
String chartSummary(ChartData data, String title, StatFormat f) {
  final l = f.l10n;
  if (data.isEmpty) return l.chartsSummaryValue(title, l.chartsEmpty);
  switch (data) {
    case TimeSeriesData():
      final main = data.series.isEmpty ? null : data.series.first;
      final values = [
        for (var i = 0; i < (main?.values.length ?? 0); i++)
          if (main!.values[i] != null) (i, main.values[i]!),
      ];
      if (values.isEmpty) return l.chartsSummaryValue(title, l.chartsEmpty);
      final first = values.first;
      final last = values.last;
      final lo = values.map((v) => v.$2).reduce((a, b) => a < b ? a : b);
      final hi = values.map((v) => v.$2).reduce((a, b) => a > b ? a : b);
      final range = l.chartsRange(
        f.label(DateLabel(data.buckets.first, data.granularity)),
        f.label(DateLabel(data.buckets.last, data.granularity)),
      );
      final t = data.trend;
      final slopeUnit = data.unit == StatUnit.percent ? StatUnit.pp : data.unit;
      final trend = t == null || !t.significant || t.direction == TrendDirection.stable
          ? l.chartsTrendStable
          : (t.direction == TrendDirection.rising
                ? l.chartsTrendRising(f.value(t.slopePerWeek.abs(), slopeUnit))
                : l.chartsTrendFalling(f.value(t.slopePerWeek.abs(), slopeUnit)));
      return '${l.chartsSummaryLine(title, range, f.value(first.$2, data.unit), f.value(last.$2, data.unit), trend)} '
          '${l.chartsSummaryMinMax(f.value(lo, data.unit), f.value(hi, data.unit))}';
    case StackedAreaData():
      return chartSummary(
        TimeSeriesData(data.buckets, data.bands, unit: data.unit, granularity: data.granularity),
        title,
        f,
      );
    case BarData():
      var best = -1;
      var bestValue = double.negativeInfinity;
      for (var i = 0; i < data.categories.length; i++) {
        final total = data.series.fold<double>(0, (a, s) => a + (i < s.values.length ? s.values[i] : 0));
        if (total > bestValue) {
          bestValue = total;
          best = i;
        }
      }
      return l.chartsSummaryBars(
        title,
        '${data.categories.length}',
        f.label(data.categories[best]),
        f.value(bestValue, data.unit),
      );
    case DonutData():
      final top = data.slices.first;
      return l.chartsSummaryShare(title, f.label(top.label), f.percent(top.value / data.total));
    case ParetoData():
      final top = data.entries.first;
      return l.chartsSummaryShare(title, f.label(top.$1), f.percent(top.$2 / data.total));
    case CalendarData():
      return l.chartsSummaryCalendar(title, '${data.cells.length}');
    case PunchCardData():
      var bw = 0;
      var bh = 0;
      var best = -1.0;
      for (var w = 0; w < 7; w++) {
        for (var h = 0; h < 24; h++) {
          if (data.values[w][h] > best) {
            best = data.values[w][h];
            bw = w;
            bh = h;
          }
        }
      }
      return l.chartsSummaryPunchCard(title, f.label(WeekdayLabel(Weekday.fromIso(bw + 1))), f.hour(bh));
    case StreakData():
      final longest = data.streaks.first;
      return l.chartsSummaryStreaks(title, f.value(longest.length.toDouble(), data.unit));
    case MilestoneData():
      final done = data.rows.where((r) => r.state == MilestoneRowState.done).length;
      return l.chartsSummaryMilestones(title, '$done', '${data.rows.length}');
    case ListData():
      return l.chartsSummaryList(title, '${data.rows.length}');
    case TilesData():
      return [
        for (final t in data.tiles)
          '${f.label(t.label)}: ${t.value == null ? l.chartsNotApplicable : f.value(t.value!, t.unit, currency: t.currency)}',
      ].join('. ');
    case RingData():
      return [for (final r in data.rings) '${f.label(r.$1)}: ${f.percent(r.$2)}'].join('. ');
    case BulletData():
      return l.chartsSummaryValue(title, f.value(data.actual, data.unit));
    case HistogramData():
      var best = 0;
      for (var i = 1; i < data.bins.length; i++) {
        if (data.bins[i].$3 > data.bins[best].$3) best = i;
      }
      final b = data.bins[best];
      return l.chartsSummaryBars(
        title,
        '${data.bins.length}',
        f.label(RangeLabel(b.$1, b.$2, data.unit)),
        f.number(b.$3.toDouble()),
      );
    case KmData(:final median):
      return l.chartsSummaryValue(
        title,
        median == null ? l.chartsMedianNotReached : l.chartsMedianAt(f.value(median, StatUnit.hours)),
      );
    case ForecastData():
      return l.chartsSummaryValue(
        title,
        [
          for (final (token, days) in [
            (LabelToken.p50, data.p50),
            (LabelToken.p85, data.p85),
            (LabelToken.p95, data.p95),
          ])
            l.chartsCrosshair(f.label(TokenLabel(token)), f.date(data.from.plusDays(days))),
        ].join(', '),
      );
    case RoseData(:final meanMinute):
      return l.chartsSummaryValue(
        title,
        !data.consistent || meanMinute == null
            ? l.chartsNoConsistentTime
            : l.chartsCrosshair(f.label(const TokenLabel(LabelToken.mean)), f.clock(meanMinute)),
      );
    case ChartGroup():
      return chartSummary(data.charts.firstWhere((c) => !c.$2.isEmpty, orElse: () => data.charts.first).$2, title, f);
    default:
      return l.chartsSummaryList(title, '${data.toTable().rows.length}');
  }
}
