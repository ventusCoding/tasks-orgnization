/// Line & area chart over date buckets (T6.2.03) on `fl_chart`: up to 6 series, dashed rolling-mean
/// overlay, trend line with its slope, goal line and target band, gaps for `null` values (never
/// interpolated), area/cumulative modes, vertical annotation markers and LTTB downsampling beyond
/// 500 points. Time runs right-to-left in RTL and the value axis sits on the start side.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

class TimeSeriesChart extends StatelessWidget {
  const TimeSeriesChart(this.data, {super.key, this.height = 200, this.onTap, this.hidden = const {}});

  final TimeSeriesData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  /// Indices of series hidden from the legend.
  final Set<int> hidden;

  static const _dash = [6, 4];

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final n = data.buckets.length;
    if (n == 0) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final threshold = math.max(3, (constraints.maxWidth * 2).round());
          double xOf(int i) => (rtl ? n - 1 - i : i).toDouble();
          final bars = <LineChartBarData>[];
          final barSeries = <int>[];
          var lo = double.infinity;
          var hi = double.negativeInfinity;
          for (var s = 0; s < data.series.length && s < 6; s++) {
            if (hidden.contains(s)) continue;
            final series = data.series[s];
            final points = n > 500
                ? lttb(series.values, threshold)
                : [for (var i = 0; i < series.values.length; i++) (i, series.values[i])];
            final spots = <FlSpot>[for (final (i, v) in points) v == null ? FlSpot.nullSpot : FlSpot(xOf(i), v)];
            if (rtl) {
              final reversed = spots.reversed.toList();
              spots
                ..clear()
                ..addAll(reversed);
            }
            for (final (_, v) in points) {
              if (v == null) continue;
              lo = math.min(lo, v);
              hi = math.max(hi, v);
            }
            final color = theme.resolve(series.color);
            final overlay =
                series.role == SeriesRole.rollingMean ||
                series.role == SeriesRole.trend ||
                series.role == SeriesRole.pace;
            bars.add(
              LineChartBarData(
                spots: spots,
                color: color,
                barWidth: overlay ? 1.5 : theme.strokeWidth,
                dashArray: overlay || series.role == SeriesRole.previous ? _dash : null,
                isStrokeCapRound: true,
                isStepLineChart: data.step,
                dotData: FlDotData(show: n <= 16 && !overlay),
                belowBarData: BarAreaData(
                  show: (data.area || data.cumulative) && s == 0,
                  color: color.withValues(alpha: 0.15),
                ),
              ),
            );
            barSeries.add(s);
          }
          final trend = data.trend;
          if (trend != null && !hidden.contains(-1)) {
            double y(int i) => trend.intercept + trend.slopePerBucket * i;
            final a = FlSpot(xOf(0), y(0));
            final b = FlSpot(xOf(n - 1), y(n - 1));
            bars.add(
              LineChartBarData(
                spots: rtl ? [b, a] : [a, b],
                color: theme.label,
                barWidth: 1.2,
                dashArray: const [3, 3],
                dotData: const FlDotData(show: false),
              ),
            );
            barSeries.add(-1);
            lo = math.min(lo, math.min(y(0), y(n - 1)));
            hi = math.max(hi, math.max(y(0), y(n - 1)));
          }
          if (data.goal != null) {
            lo = math.min(lo, data.goal!);
            hi = math.max(hi, data.goal!);
          }
          if (data.targetBand != null) {
            lo = math.min(lo, data.targetBand!.$1);
            hi = math.max(hi, data.targetBand!.$2);
          }
          if (!lo.isFinite) {
            lo = 0;
            hi = 1;
          }
          final zeroBased = data.unit != StatUnit.clock && data.unit != StatUnit.date && lo >= 0;
          final scale = niceScale(
            lo,
            data.unit == StatUnit.percent || data.unit == StatUnit.score ? math.max(hi, lo == hi ? 1 : hi) : hi,
            zeroBased: zeroBased,
          );
          final valueTitles = AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: scale.step,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  f.value(v, data.unit),
                  style: context.text.labelSmall?.copyWith(color: theme.label),
                  maxLines: 1,
                ),
              ),
            ),
          );
          final labelEvery = math.max(1, (n / 5).ceil());
          final bottom = AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: labelEvery.toDouble(),
              getTitlesWidget: (v, meta) {
                final x = v.round();
                final i = rtl ? n - 1 - x : x;
                if (i < 0 || i >= n || (i % labelEvery != 0 && i != n - 1)) return const SizedBox.shrink();
                // The last bucket is always labeled; a regular label too close to it would collide.
                if (i != n - 1 && n - 1 - i < labelEvery) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  // Edge labels shift inside the chart instead of spilling past the card.
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    f.label(DateLabel(data.buckets[i], data.granularity)),
                    style: context.text.labelSmall?.copyWith(color: theme.label),
                  ),
                );
              },
            ),
          );
          // An end inset keeps the latest point (end side in LTR and RTL) off the card edge.
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: Space.sm),
            child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (n - 1).toDouble() == 0 ? 1 : (n - 1).toDouble(),
              minY: scale.min,
              maxY: scale.max,
              lineBarsData: bars,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: scale.step,
                getDrawingHorizontalLine: (_) => FlLine(color: theme.grid, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                leftTitles: rtl ? const AxisTitles() : valueTitles,
                rightTitles: rtl ? valueTitles : const AxisTitles(),
                bottomTitles: bottom,
              ),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  if (data.targetBand case final band?)
                    HorizontalRangeAnnotation(
                      y1: band.$1,
                      y2: band.$2,
                      color: theme.tone(ChartTone.positive).withValues(alpha: 0.12),
                    ),
                ],
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (data.goal case final goal?)
                    HorizontalLine(y: goal, color: theme.tone(ChartTone.warning), strokeWidth: 1.5, dashArray: _dash),
                ],
                verticalLines: [
                  for (final a in data.annotations)
                    if (a.index >= 0 && a.index < n)
                      VerticalLine(
                        x: xOf(a.index),
                        color: theme.muted,
                        strokeWidth: 1,
                        dashArray: const [2, 3],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
                          style: context.text.labelSmall?.copyWith(color: theme.label),
                          labelResolver: (_) => f.label(a.label),
                        ),
                      ),
                ],
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 180,
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      () {
                        final seriesIndex = barSeries[s.barIndex];
                        final name = seriesIndex < 0
                            ? f.label(const TokenLabel(LabelToken.trend))
                            : f.label(data.series[seriesIndex].label);
                        final i = rtl ? n - 1 - s.x.round() : s.x.round();
                        final head = s == spots.first && i >= 0 && i < n
                            ? '${f.label(DateLabel(data.buckets[i], data.granularity))}\n'
                            : '';
                        return LineTooltipItem(
                          '$head${context.l10n.chartsTooltip(name, f.value(s.y, data.unit))}',
                          context.text.labelSmall!.copyWith(color: context.colors.onInverseSurface),
                        );
                      }(),
                  ],
                ),
                touchCallback: onTap == null
                    ? null
                    : (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final spot = response?.lineBarSpots?.firstOrNull;
                        if (spot == null) return;
                        final i = rtl ? n - 1 - spot.x.round() : spot.x.round();
                        if (i < 0 || i >= n) return;
                        final seriesIndex = barSeries[spot.barIndex];
                        onTap!(
                          ChartTap(
                            drillKey: data.drillKeys?[i] ?? data.buckets[i].toIso(),
                            label: DateLabel(data.buckets[i], data.granularity),
                            seriesIndex: seriesIndex < 0 ? null : seriesIndex,
                            value: spot.y,
                          ),
                        );
                      },
              ),
            ),
            duration: chartAnimation(context),
            curve: Motion.curve,
          ),
          );
        },
      ),
    );
  }
}
