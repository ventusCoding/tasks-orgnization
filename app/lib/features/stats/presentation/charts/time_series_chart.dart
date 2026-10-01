/// Line & area chart over date buckets (T6.2.03) on `fl_chart`: up to 6 series, dashed rolling-mean
/// overlay, trend line with its slope, goal line and target band, gaps for `null` values (never
/// interpolated), area/cumulative modes, vertical annotation markers and LTTB downsampling beyond
/// 500 points. Time runs right-to-left in RTL and the value axis sits on the start side.
///
/// Also the burn charts (T6.2.17: step lines, scope-increase markers listing the added items under
/// the chart), the forecast cone appended after the last actual point (T6.2.26: P50–P85–P95 bands
/// labeled with their finish dates) and the advanced interactions (T6.2.22):
/// - a horizontal drag or long press scrubs with a crosshair across every series (a vertical drag
///   still scrolls the page — the scrub only wins a horizontal gesture);
/// - charts under one [ChartCrosshairScope] share that crosshair;
/// - two-finger pinch zooms and pans the time axis within the data range;
/// - long series (> 90 buckets) get a range brush under the chart.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:material_ui/material_ui.dart';

/// Shares the scrubbed date between the time charts below it (one crosshair per screen, T6.2.22).
class ChartCrosshairScope extends InheritedNotifier<ValueNotifier<LocalDate?>> {
  const ChartCrosshairScope({required ValueNotifier<LocalDate?> super.notifier, required super.child, super.key});

  static ValueNotifier<LocalDate?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChartCrosshairScope>()?.notifier;
}

/// Visible bucket window `[start, end]` (indices of the full domain) after zooming.
typedef BucketWindow = ({double start, double end});

class TimeSeriesChart extends StatefulWidget {
  const TimeSeriesChart(
    this.data, {
    super.key,
    this.height = 200,
    this.onTap,
    this.hidden = const {},
    this.brush = true,
  });

  final TimeSeriesData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  /// Indices of series hidden from the legend.
  final Set<int> hidden;

  /// Shows the range brush under long series.
  final bool brush;

  /// Buckets beyond which the range brush appears.
  static const brushThreshold = 90;

  /// The narrowest zoom (buckets).
  static const minWindow = 7.0;

  @override
  State<TimeSeriesChart> createState() => TimeSeriesChartState();
}

class TimeSeriesChartState extends State<TimeSeriesChart> {
  static const _dash = [6, 4];
  static const _axisReserved = 44.0;

  BucketWindow? _window;
  final Map<int, Offset> _pointers = {};
  ({double span, Offset focal, BucketWindow window})? _pinch;

  /// The current zoom window (null = the whole range).
  BucketWindow? get window => _window;

  TimeSeriesData get data => widget.data;

  /// Buckets plus the forecast dates after them.
  List<LocalDate> get _dates => [...data.buckets, ...?data.cone?.dates];

  int get _m => _dates.length;

  double get _maxIndex => math.max(1, _m - 1).toDouble();

  BucketWindow _clamp(BucketWindow w) {
    final full = _maxIndex;
    final minWidth = math.min(TimeSeriesChart.minWindow, full);
    var width = (w.end - w.start).clamp(minWidth, full);
    var start = w.start;
    if (start < 0) start = 0;
    if (start + width > full) start = full - width;
    if (start < 0) {
      start = 0;
      width = full;
    }
    return (start: start, end: start + width);
  }

  /// Sets the zoom window (null resets); clamped to the data range and the minimum width.
  void setWindow(BucketWindow? w) {
    final next = w == null ? null : _clamp(w);
    final isFull = next != null && next.start <= 0 && next.end >= _maxIndex;
    setState(() => _window = isFull ? null : next);
  }

  @override
  void didUpdateWidget(TimeSeriesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.buckets.length != data.buckets.length ||
        oldWidget.data.cone?.dates.length != data.cone?.dates.length) {
      _window = null;
    }
  }

  // Two-finger pinch & pan (raw pointers, so single-finger gestures keep their meaning).
  void _pointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2) _startPinch();
  }

  void _pointerMove(PointerMoveEvent e, double plotWidth, bool rtl) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    final pinch = _pinch;
    if (pinch == null || _pointers.length < 2) return;
    final pts = _pointers.values.take(2).toList();
    final span = math.max(8, (pts[0].dx - pts[1].dx).abs()).toDouble();
    final focal = (pts[0] + pts[1]) / 2;
    final w0 = pinch.window;
    final width0 = w0.end - w0.start;
    final width = width0 * pinch.span / span;
    // Keep the bucket under the starting focal point under the fingers, then pan by the focal shift.
    final f0 = ((pinch.focal.dx - (rtl ? 0 : _axisReserved)) / plotWidth).clamp(0.0, 1.0);
    final anchor = w0.start + (rtl ? 1 - f0 : f0) * width0;
    final shift = (focal.dx - pinch.focal.dx) / plotWidth * width * (rtl ? 1 : -1);
    final ratio = rtl ? 1 - f0 : f0;
    final start = anchor - ratio * width + shift;
    setWindow((start: start, end: start + width));
  }

  void _pointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinch = null;
  }

  void _startPinch() {
    final pts = _pointers.values.take(2).toList();
    _pinch = (
      span: math.max(8, (pts[0].dx - pts[1].dx).abs()).toDouble(),
      focal: (pts[0] + pts[1]) / 2,
      window: _window ?? (start: 0, end: _maxIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final n = data.buckets.length;
    if (n == 0) return SizedBox(height: widget.height);
    final crosshair = ChartCrosshairScope.maybeOf(context);
    final scopeChanges = [
      for (final a in data.annotations)
        if (a.details.isNotEmpty && a.index >= 0 && a.index < n) a,
    ];
    final showBrush = widget.brush && _m > TimeSeriesChart.brushThreshold;
    final cone = data.cone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final plotWidth = math.max(1, constraints.maxWidth - _axisReserved - Space.sm).toDouble();
              final chart = crosshair == null
                  ? _chart(context, theme, f, rtl, constraints, null)
                  : ValueListenableBuilder<LocalDate?>(
                      valueListenable: crosshair,
                      builder: (context, date, _) => _chart(context, theme, f, rtl, constraints, date),
                    );
              return Listener(
                onPointerDown: _pointerDown,
                onPointerMove: (e) => _pointerMove(e, plotWidth, rtl),
                onPointerUp: _pointerUp,
                onPointerCancel: _pointerUp,
                child: chart,
              );
            },
          ),
        ),
        if (cone != null && cone.dates.isNotEmpty) ...[
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.md,
            children: [
              for (final (token, values) in [
                (LabelToken.p50, cone.p50),
                (LabelToken.p85, cone.p85),
                (LabelToken.p95, cone.p95),
              ])
                Text(
                  context.l10n.chartsCrosshair(f.label(TokenLabel(token)), f.date(_finishDate(cone, values))),
                  style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
        if (showBrush) ...[
          const SizedBox(height: Space.xs),
          _RangeBrush(
            values: data.series.isEmpty ? const [] : data.series.first.values,
            total: _m,
            window: _window ?? (start: 0, end: _maxIndex),
            onChanged: setWindow,
            semanticsLabel: () {
              final w = _window ?? (start: 0, end: _maxIndex);
              return context.l10n.chartsRangeBrush(
                f.label(DateLabel(_dates[w.start.round().clamp(0, _m - 1)], data.granularity)),
                f.label(DateLabel(_dates[w.end.round().clamp(0, _m - 1)], data.granularity)),
              );
            }(),
          ),
        ],
        if (_window != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => setWindow(null), child: Text(context.l10n.chartsZoomReset)),
          ),
        for (final a in scopeChanges)
          Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_drop_up, size: 18, color: theme.tone(ChartTone.warning)),
                  Expanded(
                    child: Text(
                      context.l10n.chartsScopeAdded(
                        f.label(DateLabel(data.buckets[a.index], data.granularity)),
                        f.number(a.details.length.toDouble()),
                        a.details.map(f.label).join(', '),
                      ),
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// First cone date at which the percentile line reaches its final level (0 for a burn-down).
  LocalDate _finishDate(ForecastCone cone, List<double> values) {
    if (values.isEmpty) return cone.dates.last;
    final target = values.reduce(math.min);
    for (var i = 0; i < values.length && i < cone.dates.length; i++) {
      if (values[i] <= target + 1e-9) return cone.dates[i];
    }
    return cone.dates.last;
  }

  Widget _chart(
    BuildContext context,
    ChartTheme theme,
    StatFormat f,
    bool rtl,
    BoxConstraints constraints,
    LocalDate? crosshairDate,
  ) {
    final n = data.buckets.length;
    final m = _m;
    final dates = _dates;
    final threshold = math.max(3, (constraints.maxWidth * 2).round());
    double xOf(num i) => (rtl ? m - 1 - i : i).toDouble();
    final bars = <LineChartBarData>[];
    final barSeries = <int>[];
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (var s = 0; s < data.series.length && s < 6; s++) {
      if (widget.hidden.contains(s)) continue;
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
          series.role == SeriesRole.rollingMean || series.role == SeriesRole.trend || series.role == SeriesRole.pace;
      bars.add(
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: overlay ? 1.5 : theme.strokeWidth,
          dashArray: overlay || series.role == SeriesRole.previous || series.role == SeriesRole.goal ? _dash : null,
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
    if (trend != null && !widget.hidden.contains(-1)) {
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
    // Forecast cone from the last actual point of the main series (T6.2.26).
    final cone = data.cone;
    final coneBars = <int>[];
    if (cone != null && cone.dates.isNotEmpty && data.series.isNotEmpty) {
      final main = data.series.first.values;
      double? anchor;
      for (var i = main.length - 1; i >= 0 && anchor == null; i--) {
        anchor = main[i];
      }
      final start = anchor ?? 0;
      final color = theme.seriesColor(0);
      for (final (k, values) in [(-2, cone.p50), (-3, cone.p85), (-4, cone.p95)]) {
        final spots = [
          FlSpot(xOf(n - 1), start),
          for (var i = 0; i < values.length && i < cone.dates.length; i++) FlSpot(xOf(n + i), values[i]),
        ];
        for (final s in spots) {
          lo = math.min(lo, s.y);
          hi = math.max(hi, s.y);
        }
        coneBars.add(bars.length);
        bars.add(
          LineChartBarData(
            spots: rtl ? spots.reversed.toList() : spots,
            color: color.withValues(alpha: k == -2 ? 0.9 : 0.45),
            barWidth: k == -2 ? 1.6 : 1,
            dashArray: _dash,
            dotData: const FlDotData(show: false),
          ),
        );
        barSeries.add(k);
      }
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
        reservedSize: _axisReserved,
        interval: scale.step,
        getTitlesWidget: (v, meta) => SideTitleWidget(
          meta: meta,
          child: Text(f.value(v, data.unit), style: context.text.labelSmall?.copyWith(color: theme.label), maxLines: 1),
        ),
      ),
    );
    final window = _window;
    final visible = window == null ? m.toDouble() : window.end - window.start + 1;
    final labelEvery = math.max(1, (visible / 5).ceil());
    final bottom = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        interval: labelEvery.toDouble(),
        getTitlesWidget: (v, meta) {
          final x = v.round();
          final i = rtl ? m - 1 - x : x;
          if (i < 0 || i >= m || (i % labelEvery != 0 && i != m - 1)) return const SizedBox.shrink();
          // The last bucket is always labeled; a regular label too close to it would collide.
          if (i != m - 1 && m - 1 - i < labelEvery) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            // Edge labels shift inside the chart instead of spilling past the card.
            fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
            child: Text(
              f.label(DateLabel(dates[i], data.granularity)),
              style: context.text.labelSmall?.copyWith(color: theme.label),
            ),
          );
        },
      ),
    );
    final crosshairIndex = crosshairDate == null ? -1 : dates.indexOf(crosshairDate);
    final crosshair = ChartCrosshairScope.maybeOf(context);
    final minX = window == null ? 0.0 : (rtl ? m - 1 - window.end : window.start);
    final maxX = window == null ? (m - 1 == 0 ? 1.0 : (m - 1).toDouble()) : (rtl ? m - 1 - window.start : window.end);
    // An end inset keeps the latest point (end side in LTR and RTL) off the card edge.
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Space.sm),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: scale.min,
          maxY: scale.max,
          lineBarsData: bars,
          betweenBarsData: [
            if (coneBars.length == 3) ...[
              BetweenBarsData(
                fromIndex: coneBars[0],
                toIndex: coneBars[1],
                color: theme.seriesColor(0).withValues(alpha: 0.18),
              ),
              BetweenBarsData(
                fromIndex: coneBars[1],
                toIndex: coneBars[2],
                color: theme.seriesColor(0).withValues(alpha: 0.08),
              ),
            ],
          ],
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
                    color: a.kind == AnnotationKind.scopeChange ? theme.tone(ChartTone.warning) : theme.muted,
                    strokeWidth: 1,
                    dashArray: const [2, 3],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
                      style: context.text.labelSmall?.copyWith(color: theme.label),
                      labelResolver: (_) =>
                          a.details.isEmpty ? f.label(a.label) : '+${f.number(a.details.length.toDouble())}',
                    ),
                  ),
              if (crosshairIndex >= 0) VerticalLine(x: xOf(crosshairIndex), color: theme.onSurface, strokeWidth: 1),
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
                    final name = switch (seriesIndex) {
                      -1 => f.label(const TokenLabel(LabelToken.trend)),
                      -2 => f.label(const TokenLabel(LabelToken.p50)),
                      -3 => f.label(const TokenLabel(LabelToken.p85)),
                      -4 => f.label(const TokenLabel(LabelToken.p95)),
                      _ => f.label(data.series[seriesIndex].label),
                    };
                    final i = rtl ? m - 1 - s.x.round() : s.x.round();
                    final head = s == spots.first && i >= 0 && i < m
                        ? '${f.label(DateLabel(dates[i], data.granularity))}\n'
                        : '';
                    return LineTooltipItem(
                      '$head${context.l10n.chartsTooltip(name, f.value(s.y, data.unit))}',
                      context.text.labelSmall!.copyWith(color: context.colors.onInverseSurface),
                    );
                  }(),
              ],
            ),
            touchCallback: (event, response) {
              final spot = response?.lineBarSpots?.firstOrNull;
              final i = spot == null ? -1 : (rtl ? m - 1 - spot.x.round() : spot.x.round());
              if (crosshair != null) {
                final scrubbing =
                    event is FlPanStartEvent ||
                    event is FlPanUpdateEvent ||
                    event is FlLongPressStart ||
                    event is FlLongPressMoveUpdate;
                if (scrubbing && i >= 0 && i < m) {
                  crosshair.value = dates[i];
                } else if (!event.isInterestedForInteractions) {
                  crosshair.value = null;
                }
              }
              if (event is! FlTapUpEvent || spot == null || widget.onTap == null) return;
              if (i < 0 || i >= n) return;
              final seriesIndex = barSeries[spot.barIndex];
              widget.onTap!(
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
  }
}

/// Overview strip under a long series with a draggable window (T6.2.22): drag the window to pan,
/// drag one of its edges to resize it.
class _RangeBrush extends StatefulWidget {
  const _RangeBrush({
    required this.values,
    required this.total,
    required this.window,
    required this.onChanged,
    required this.semanticsLabel,
  });

  final List<double?> values;
  final int total;
  final BucketWindow window;
  final ValueChanged<BucketWindow> onChanged;
  final String semanticsLabel;

  @override
  State<_RangeBrush> createState() => _RangeBrushState();
}

enum _BrushDrag { move, start, end }

class _RangeBrushState extends State<_RangeBrush> {
  /// The drag in progress: what it moves, the window when it started and the start position.
  ({_BrushDrag mode, BucketWindow from, double origin})? _active;

  double get _max => math.max(1, widget.total - 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: widget.semanticsLabel,
      child: SizedBox(
        height: 36,
        child: LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            double px(double index) => rtl ? width - index / _max * width : index / _max * width;
            return GestureDetector(
              key: const ValueKey('range-brush'),
              behavior: HitTestBehavior.opaque,
              // Edges are picked where the finger went down, not where the drag was recognized.
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: (d) {
                final x = d.localPosition.dx;
                final a = px(widget.window.start);
                final b = px(widget.window.end);
                final startEdge = (x - a).abs() < 14;
                final endEdge = (x - b).abs() < 14;
                _active = (
                  mode: startEdge ? _BrushDrag.start : (endEdge ? _BrushDrag.end : _BrushDrag.move),
                  from: widget.window,
                  origin: x,
                );
              },
              onHorizontalDragUpdate: (d) {
                final active = _active;
                if (active == null) return;
                final from = active.from;
                final delta = (d.localPosition.dx - active.origin) / width * _max * (rtl ? -1 : 1);
                widget.onChanged(switch (active.mode) {
                  _BrushDrag.move => (start: from.start + delta, end: from.end + delta),
                  _BrushDrag.start => (start: math.min(from.start + delta, from.end - 1), end: from.end),
                  _BrushDrag.end => (start: from.start, end: math.max(from.end + delta, from.start + 1)),
                });
              },
              onHorizontalDragEnd: (_) => _active = null,
              child: CustomPaint(
                size: Size(width, 36),
                painter: _BrushPainter(widget.values, widget.window, _max, theme, rtl: rtl),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrushPainter extends CustomPainter {
  _BrushPainter(this.values, this.window, this.max, this.theme, {required this.rtl});

  final List<double?> values;
  final BucketWindow window;
  final double max;
  final ChartTheme theme;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    double px(double index) => rtl ? size.width - index / max * size.width : index / max * size.width;
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final v in values) {
      if (v == null) continue;
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Radii.sm)),
      Paint()..color = theme.grid.withValues(alpha: 0.35),
    );
    if (lo.isFinite) {
      final span = hi - lo <= 0 ? 1 : hi - lo;
      final path = Path();
      var pen = false;
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        if (v == null) {
          pen = false;
          continue;
        }
        final p = Offset(px(i.toDouble()), size.height - 4 - (v - lo) / span * (size.height - 8));
        if (pen) {
          path.lineTo(p.dx, p.dy);
        } else {
          path.moveTo(p.dx, p.dy);
          pen = true;
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = theme.seriesColor(0).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke,
      );
    }
    final a = px(window.start);
    final b = px(window.end);
    final rect = Rect.fromLTRB(math.min(a, b), 0, math.max(a, b), size.height);
    canvas
      ..drawRect(rect, Paint()..color = theme.seriesColor(0).withValues(alpha: 0.15))
      ..drawRect(
        rect,
        Paint()
          ..color = theme.seriesColor(0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    final handle = Paint()..color = theme.seriesColor(0);
    for (final x in [rect.left, rect.right]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, size.height / 2), width: 5, height: 18),
          const Radius.circular(2),
        ),
        handle,
      );
    }
  }

  @override
  bool shouldRepaint(_BrushPainter old) => old.window != window || old.values != values || old.rtl != rtl;
}
