/// Distribution charts: histogram with percentile markers and a count/share toggle, grouped box plots
/// with outliers and n under each box (T6.2.14), the Kaplan–Meier step curve (T6.2.25) and the
/// Monte Carlo finish-date histogram (T6.2.26). Custom painters on the shared [Plot] geometry; the
/// value axis sits on the start side and RTL mirrors the horizontal axis.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/charts/plot_support.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------------------------
// Histogram (T6.2.14)
// ---------------------------------------------------------------------------------------------

class HistogramChart extends StatefulWidget {
  const HistogramChart(this.data, {super.key, this.height = 200, this.onTap});

  final HistogramData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  State<HistogramChart> createState() => _HistogramChartState();
}

class _HistogramChartState extends State<HistogramChart> {
  bool _share = false;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final data = widget.data;
    final painter = _HistogramPainter(
      data,
      theme: theme,
      format: f,
      rtl: rtl,
      share: _share,
      selected: _selected,
      labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
    );
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Space.xs,
          children: [
            for (final share in [false, true])
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(share ? context.l10n.chartsHistogramDensity : context.l10n.chartsHistogramCount),
                selected: _share == share,
                onSelected: (_) => setState(() => _share = share),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, c) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final i = painter.binAt(d.localPosition, c.biggest);
                      setState(() => _selected = i);
                      if (i == null) return;
                      chartSelectionFeedback(context);
                      final b = data.bins[i];
                      widget.onTap?.call(
                        ChartTap(drillKey: 'bin:$i', label: RangeLabel(b.$1, b.$2, data.unit), value: b.$3.toDouble()),
                      );
                    },
                    child: CustomPaint(size: c.biggest, painter: painter),
                  ),
                ),
              ),
              if (selected != null && selected < data.bins.length)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: ChartReadout(
                    lines: [
                      f.label(RangeLabel(data.bins[selected].$1, data.bins[selected].$2, data.unit)),
                      _share
                          ? f.percent(data.bins[selected].$3 / math.max(1, data.total))
                          : f.number(data.bins[selected].$3.toDouble()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter(
    this.data, {
    required this.theme,
    required this.format,
    required this.rtl,
    required this.share,
    required this.selected,
    required this.labelStyle,
  });

  final HistogramData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final bool share;
  final int? selected;
  final TextStyle labelStyle;

  double get _lo => data.bins.isEmpty ? 0 : data.bins.first.$1;
  double get _hi => data.bins.isEmpty ? 1 : data.bins.last.$2;

  double _t(double v) => _hi <= _lo ? 0 : ((v - _lo) / (_hi - _lo)).clamp(0.0, 1.0);

  double _height(int count) => share ? count / math.max(1, data.total) : count.toDouble();

  int? binAt(Offset p, Size size) {
    final plot = Plot(size, rtl: rtl);
    if (!plot.rect.inflate(2).contains(p)) return null;
    final v = _lo + plot.t(p.dx) * (_hi - _lo);
    for (var i = 0; i < data.bins.length; i++) {
      final b = data.bins[i];
      if (v >= b.$1 && (v < b.$2 || i == data.bins.length - 1)) return i;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.bins.isEmpty) return;
    final plot = Plot(size, rtl: rtl, top: 18);
    final top = data.bins.map((b) => _height(b.$3)).fold<double>(0, math.max);
    final scale = niceScale(0, share ? math.max(top, 0.01) : math.max(top, 1), maxTicks: 4);
    paintValueAxis(canvas, plot, scale, (v) => share ? format.percent(v) : format.number(v), theme, labelStyle);
    final fill = theme.seriesColor(0);
    for (var i = 0; i < data.bins.length; i++) {
      final b = data.bins[i];
      final x0 = plot.x(_t(b.$1));
      final x1 = plot.x(_t(b.$2));
      final rect = Rect.fromLTRB(
        math.min(x0, x1) + 0.5,
        plot.y(_height(b.$3), scale),
        math.max(x0, x1) - 0.5,
        plot.rect.bottom,
      );
      canvas.drawRect(rect, Paint()..color = i == selected ? fill : fill.withValues(alpha: 0.75));
    }
    // Edge labels: first, last and a few in between.
    final every = math.max(1, (data.bins.length / 4).ceil());
    for (var i = 0; i <= data.bins.length; i += every) {
      final v = i == data.bins.length ? data.bins.last.$2 : data.bins[i].$1;
      paintLabel(canvas, format.value(v, data.unit), Offset(plot.x(_t(v)), plot.rect.bottom + 11), labelStyle);
    }
    final markerPaint = Paint()
      ..color = theme.onSurface
      ..strokeWidth = 1.2;
    for (final (value, label) in data.markers) {
      final x = plot.x(_t(value));
      dashedLine(canvas, Offset(x, plot.rect.top - 6), Offset(x, plot.rect.bottom), markerPaint);
      paintLabel(
        canvas,
        '${format.label(label)} ${format.value(value, data.unit)}',
        Offset(x, 6),
        labelStyle.copyWith(color: theme.onSurface, fontWeight: FontWeight.w600),
        anchor: (x < size.width / 2) ? TextAnchor.leftEdge : TextAnchor.rightEdge,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter old) =>
      old.data != data || old.share != share || old.selected != selected || old.rtl != rtl || old.theme != theme;
}

// ---------------------------------------------------------------------------------------------
// Box plots (T6.2.14)
// ---------------------------------------------------------------------------------------------

class BoxPlotChart extends StatelessWidget {
  const BoxPlotChart(this.data, {super.key, this.height = 200, this.onTap});

  final BoxPlotData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final painter = _BoxPainter(
      data,
      theme: theme,
      format: statFormatOf(context),
      rtl: rtl,
      labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
    );
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTap == null
              ? null
              : (d) {
                  final i = painter.groupAt(d.localPosition, c.biggest);
                  if (i == null) return;
                  chartSelectionFeedback(context);
                  final (label, box) = data.groups[i];
                  onTap!(ChartTap(drillKey: 'group:$i', label: label, value: box.median));
                },
          child: CustomPaint(size: c.biggest, painter: painter),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.data, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final BoxPlotData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  Plot _plot(Size size) => Plot(size, rtl: rtl, bottom: 30);

  int? groupAt(Offset p, Size size) {
    final plot = _plot(size);
    final n = data.groups.length;
    if (n == 0 || !plot.rect.inflate(4).contains(p)) return null;
    return (plot.t(p.dx) * n).floor().clamp(0, n - 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.groups.length;
    if (n == 0) return;
    final plot = _plot(size);
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final (_, b) in data.groups) {
      lo = math.min(lo, math.min(b.whiskerLow, b.outliers.fold(b.whiskerLow, math.min)));
      hi = math.max(hi, math.max(b.whiskerHigh, b.outliers.fold(b.whiskerHigh, math.max)));
    }
    final scale = niceScale(lo, hi, maxTicks: 4, zeroBased: lo >= 0);
    paintValueAxis(canvas, plot, scale, (v) => format.value(v, data.unit), theme, labelStyle);
    final slot = plot.rect.width / n;
    final boxWidth = math.min(36, slot * 0.55);
    final color = theme.seriesColor(0);
    final stroke = Paint()
      ..color = theme.onSurface
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < n; i++) {
      final (label, b) = data.groups[i];
      final cx = plot.x((i + 0.5) / n);
      final box = Rect.fromLTRB(cx - boxWidth / 2, plot.y(b.q3, scale), cx + boxWidth / 2, plot.y(b.q1, scale));
      canvas
        ..drawLine(Offset(cx, plot.y(b.whiskerHigh, scale)), Offset(cx, box.top), stroke)
        ..drawLine(Offset(cx, box.bottom), Offset(cx, plot.y(b.whiskerLow, scale)), stroke);
      for (final w in [b.whiskerLow, b.whiskerHigh]) {
        final y = plot.y(w, scale);
        canvas.drawLine(Offset(cx - boxWidth / 4, y), Offset(cx + boxWidth / 4, y), stroke);
      }
      canvas
        ..drawRect(box, Paint()..color = color.withValues(alpha: 0.35))
        ..drawRect(box, stroke);
      final my = plot.y(b.median, scale);
      canvas.drawLine(Offset(box.left, my), Offset(box.right, my), stroke..strokeWidth = 2.2);
      stroke.strokeWidth = 1.2;
      for (final o in b.outliers) {
        canvas.drawCircle(Offset(cx, plot.y(o, scale)), 2.5, stroke);
      }
      paintLabel(canvas, format.label(label), Offset(cx, plot.rect.bottom + 9), labelStyle, maxWidth: slot);
      paintLabel(canvas, 'n = ${format.number(b.n.toDouble())}', Offset(cx, plot.rect.bottom + 22), labelStyle);
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}

// ---------------------------------------------------------------------------------------------
// Kaplan–Meier (T6.2.25)
// ---------------------------------------------------------------------------------------------

class KmChart extends StatelessWidget {
  const KmChart(this.data, {super.key, this.height = 200});

  final KmData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final median = data.median;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _KmPainter(
              data,
              theme: theme,
              format: f,
              rtl: rtl,
              labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          median == null
              ? context.l10n.chartsMedianNotReached
              : context.l10n.chartsMedianAt(f.value(median, StatUnit.hours)),
          style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _KmPainter extends CustomPainter {
  _KmPainter(this.data, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final KmData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.points.isEmpty) return;
    final plot = Plot(size, rtl: rtl);
    const scale = (min: 0.0, max: 1.0, step: 0.25);
    paintValueAxis(canvas, plot, scale, format.percent, theme, labelStyle);
    final tMax = math.max(data.points.last.t, data.median ?? 0) * 1.05;
    double tx(double t) => plot.x(tMax <= 0 ? 0 : t / tMax);
    // Confidence band (step area).
    final band = Path();
    var hasBand = false;
    for (var i = 0; i < data.points.length; i++) {
      final p = data.points[i];
      if (p.lower == null || p.upper == null) continue;
      final next = i + 1 < data.points.length ? data.points[i + 1].t : tMax;
      band.addRect(
        Rect.fromLTRB(
          math.min(tx(p.t), tx(next)),
          plot.y(p.upper!, scale),
          math.max(tx(p.t), tx(next)),
          plot.y(p.lower!, scale),
        ),
      );
      hasBand = true;
    }
    final color = theme.seriesColor(0);
    if (hasBand) canvas.drawPath(band, Paint()..color = color.withValues(alpha: 0.15));
    // Step curve from S(0) = 1.
    final curve = Path()..moveTo(tx(0), plot.y(1, scale));
    var last = 1.0;
    for (final p in data.points) {
      curve
        ..lineTo(tx(p.t), plot.y(last, scale))
        ..lineTo(tx(p.t), plot.y(p.survival, scale));
      last = p.survival;
    }
    curve.lineTo(tx(tMax), plot.y(last, scale));
    canvas.drawPath(
      curve,
      Paint()
        ..color = color
        ..strokeWidth = theme.strokeWidth
        ..style = PaintingStyle.stroke,
    );
    // Censor ticks.
    final tick = Paint()
      ..color = theme.onSurface
      ..strokeWidth = 1.2;
    for (final p in data.points) {
      if (p.censored <= 0) continue;
      final x = tx(p.t);
      final y = plot.y(p.survival, scale);
      canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), tick);
    }
    // Median guide.
    final median = data.median;
    final guide = Paint()
      ..color = theme.muted
      ..strokeWidth = 1;
    final half = plot.y(0.5, scale);
    if (median != null) {
      final x = tx(median);
      dashedLine(canvas, Offset(tx(0), half), Offset(x, half), guide);
      dashedLine(canvas, Offset(x, half), Offset(x, plot.rect.bottom), guide);
    } else {
      dashedLine(canvas, Offset(tx(0), half), Offset(tx(tMax), half), guide);
    }
    for (final t in [0.0, tMax / 2, tMax]) {
      paintLabel(canvas, format.value(t, StatUnit.hours), Offset(tx(t), plot.rect.bottom + 11), labelStyle);
    }
  }

  @override
  bool shouldRepaint(_KmPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}

// ---------------------------------------------------------------------------------------------
// Forecast histogram (T6.2.26)
// ---------------------------------------------------------------------------------------------

class ForecastChart extends StatelessWidget {
  const ForecastChart(this.data, {super.key, this.height = 200, this.onTap});

  final ForecastData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _ForecastPainter(
              data,
              theme: theme,
              format: f,
              rtl: rtl,
              labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.md,
          children: [
            for (final (token, days) in [
              (LabelToken.p50, data.p50),
              (LabelToken.p85, data.p85),
              (LabelToken.p95, data.p95),
            ])
              Text(
                '${f.label(TokenLabel(token))} ${f.date(data.from.plusDays(days))}',
                style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ],
    );
  }
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter(this.data, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final ForecastData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.histogram.isEmpty) return;
    final plot = Plot(size, rtl: rtl, top: 18);
    final keys = data.histogram.keys.toList()..sort();
    final first = keys.first;
    final last = math.max(keys.last, data.p95);
    final span = math.max(1, last - first + 1);
    final top = data.histogram.values.fold<int>(0, math.max) / math.max(1, data.trials);
    final scale = niceScale(0, math.max(top, 0.01), maxTicks: 4);
    paintValueAxis(canvas, plot, scale, format.percent, theme, labelStyle);
    double tx(num day) => (day - first) / span;
    final width = plot.rect.width / span;
    for (final k in keys) {
      final share = data.histogram[k]! / math.max(1, data.trials);
      final x0 = plot.x(tx(k));
      final x1 = plot.x(tx(k + 1));
      final tone = k <= data.p50
          ? ChartTone.positive
          : (k <= data.p85 ? ChartTone.warning : (k <= data.p95 ? ChartTone.late : ChartTone.muted));
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(x0, x1) + (width > 3 ? 0.5 : 0),
          plot.y(share, scale),
          math.max(x0, x1),
          plot.rect.bottom,
        ),
        Paint()..color = theme.tone(tone).withValues(alpha: 0.8),
      );
    }
    final marker = Paint()
      ..color = theme.onSurface
      ..strokeWidth = 1.2;
    for (final (token, day) in [(LabelToken.p50, data.p50), (LabelToken.p85, data.p85), (LabelToken.p95, data.p95)]) {
      final x = plot.x(tx(day + 0.5));
      dashedLine(canvas, Offset(x, plot.rect.top - 4), Offset(x, plot.rect.bottom), marker);
      paintLabel(canvas, format.label(TokenLabel(token)), Offset(x, 6), labelStyle.copyWith(color: theme.onSurface));
    }
    for (final day in [first, (first + last) ~/ 2, last]) {
      paintLabel(
        canvas,
        format.dayShort(data.from.plusDays(day)),
        Offset(plot.x(tx(day + 0.5)), plot.rect.bottom + 11),
        labelStyle,
      );
    }
  }

  @override
  bool shouldRepaint(_ForecastPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}
