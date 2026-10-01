/// Scatter plots (T6.2.15): planned vs actual with the y = x line and a ±20 % band, cycle time by
/// completion date with labeled percentile lines, and aging WIP (status columns, jittered points,
/// background bands at the cycle-time percentiles). Every point is tappable (it opens its item or
/// occurrence); dense plots fade points to translucent so overlaps stay visible. Custom painter —
/// 2 000 points stay responsive (one pass to paint, one to hit-test).
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/charts/plot_support.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:material_ui/material_ui.dart';

class ScatterChart extends StatefulWidget {
  const ScatterChart(this.data, {super.key, this.height = 220, this.onTap, this.onRef});

  final ScatterData data;
  final double height;
  final void Function(ChartTap tap)? onTap;
  final void Function(DrillRef ref)? onRef;

  @override
  State<ScatterChart> createState() => _ScatterChartState();
}

class _ScatterChartState extends State<ScatterChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final data = widget.data;
    final selected = _selected;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final painter = ScatterPainter(
            data,
            theme: theme,
            format: f,
            rtl: rtl,
            selected: selected,
            labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final i = painter.pointAt(d.localPosition, c.biggest);
                    setState(() => _selected = i);
                    if (i == null) return;
                    chartSelectionFeedback(context);
                    final p = data.points[i];
                    if (p.ref != null && widget.onRef != null) {
                      widget.onRef!(p.ref!);
                    } else {
                      widget.onTap?.call(ChartTap(drillKey: p.ref?.id, value: p.y, seriesIndex: p.column));
                    }
                  },
                  child: CustomPaint(size: c.biggest, painter: painter),
                ),
              ),
              if (selected != null && selected < data.points.length)
                PositionedDirectional(top: 0, end: 0, child: ChartReadout(lines: _readout(f, data.points[selected]))),
            ],
          );
        },
      ),
    );
  }

  List<String> _readout(StatFormat f, ScatterPoint p) {
    final data = widget.data;
    return [
      if (p.ref?.title case final title?) title,
      switch (data.variant) {
        ScatterVariant.planVsActual => '${f.label(const TokenLabel(LabelToken.planned))}: ${f.value(p.x, data.xUnit)}',
        ScatterVariant.byDate => f.date(LocalDate.fromEpochDay(p.x.round())),
        ScatterVariant.agingWip =>
          p.column != null && p.column! < data.columns.length ? f.label(data.columns[p.column!]) : '',
      },
      '${f.label(const TokenLabel(LabelToken.actual))}: ${f.value(p.y, data.yUnit)}',
    ];
  }
}

/// Painter of [ScatterChart] (exposed for hit-test tests).
class ScatterPainter extends CustomPainter {
  ScatterPainter(
    this.data, {
    required this.theme,
    required this.format,
    required this.rtl,
    required this.labelStyle,
    this.selected,
  });

  final ScatterData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final int? selected;
  final TextStyle labelStyle;

  bool get _wip => data.variant == ScatterVariant.agingWip;

  /// Deterministic jitter of point [i] in a WIP column (± 0.3 of the column width).
  static double jitter(int i) {
    final h = (i * 2654435761) & 0xFFFF;
    return (h / 0xFFFF - 0.5) * 0.6;
  }

  ({double xMin, double xMax, ValueScale y}) _domain() {
    var xMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMax = 0.0;
    var yMin = 0.0;
    for (final p in data.points) {
      xMin = math.min(xMin, p.x);
      xMax = math.max(xMax, p.x);
      yMax = math.max(yMax, p.y);
      yMin = math.min(yMin, p.y);
    }
    for (final (v, _) in data.lines) {
      yMax = math.max(yMax, v);
    }
    if (data.variant == ScatterVariant.planVsActual) {
      // Same scale on both axes so y = x is the diagonal.
      final m = math.max(xMax, yMax);
      final s = niceScale(0, m <= 0 ? 1 : m, maxTicks: 4);
      return (xMin: s.min, xMax: s.max, y: s);
    }
    if (!xMin.isFinite) {
      xMin = 0;
      xMax = 1;
    }
    if (xMax <= xMin) xMax = xMin + 1;
    return (xMin: xMin, xMax: xMax, y: niceScale(yMin, yMax <= 0 ? 1 : yMax, maxTicks: 4));
  }

  Plot _plot(Size size) => Plot(size, rtl: rtl, top: 10);

  double _tx(ScatterPoint p, int i, ({double xMin, double xMax, ValueScale y}) d) {
    if (_wip) {
      final cols = math.max(1, data.columns.length);
      return ((p.column ?? 0) + 0.5 + jitter(i)) / cols;
    }
    return (p.x - d.xMin) / (d.xMax - d.xMin);
  }

  Offset _position(int i, Plot plot, ({double xMin, double xMax, ValueScale y}) d) {
    final p = data.points[i];
    return Offset(plot.x(_tx(p, i, d)), plot.y(p.y, d.y));
  }

  /// The nearest point within 18 px of [p].
  int? pointAt(Offset p, Size size) {
    final plot = _plot(size);
    final d = _domain();
    int? best;
    var bestDistance = 18.0 * 18.0;
    for (var i = 0; i < data.points.length; i++) {
      final q = _position(i, plot, d);
      final dist = (q - p).distanceSquared;
      if (dist <= bestDistance) {
        bestDistance = dist;
        best = i;
      }
    }
    return best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.points.isEmpty) return;
    final plot = _plot(size);
    final d = _domain();
    paintValueAxis(canvas, plot, d.y, (v) => format.value(v, data.yUnit), theme, labelStyle);
    final guide = Paint()
      ..color = theme.muted
      ..strokeWidth = 1.2;
    switch (data.variant) {
      case ScatterVariant.planVsActual:
        // ±20 % band around y = x, then the diagonal.
        double px(double v) => plot.x((v - d.xMin) / (d.xMax - d.xMin));
        final band = Path()
          ..moveTo(px(0), plot.y(0, d.y))
          ..lineTo(px(d.xMax), plot.y(math.min(d.y.max, d.xMax * 1.2), d.y))
          ..lineTo(px(d.xMax), plot.y(d.xMax * 0.8, d.y))
          ..close();
        canvas
          ..save()
          ..clipRect(plot.rect)
          ..drawPath(band, Paint()..color = theme.tone(ChartTone.positive).withValues(alpha: 0.12))
          ..restore();
        dashedLine(canvas, Offset(px(0), plot.y(0, d.y)), Offset(px(d.xMax), plot.y(d.xMax, d.y)), guide);
        for (final v in [d.xMin, (d.xMin + d.xMax) / 2, d.xMax]) {
          paintLabel(canvas, format.value(v, data.xUnit), Offset(px(v), plot.rect.bottom + 11), labelStyle);
        }
      case ScatterVariant.byDate:
        for (final v in [d.xMin, (d.xMin + d.xMax) / 2, d.xMax]) {
          paintLabel(
            canvas,
            format.dayShort(LocalDate.fromEpochDay(v.round())),
            Offset(plot.x((v - d.xMin) / (d.xMax - d.xMin)), plot.rect.bottom + 11),
            labelStyle,
          );
        }
      case ScatterVariant.agingWip:
        // Background bands between the cycle-time percentiles (green → red).
        final lines = [...data.lines]..sort((a, b) => a.$1.compareTo(b.$1));
        const tones = [ChartTone.positive, ChartTone.warning, ChartTone.late, ChartTone.negative];
        var lower = d.y.min;
        for (var k = 0; k <= lines.length; k++) {
          final upper = k < lines.length ? lines[k].$1 : d.y.max;
          canvas.drawRect(
            Rect.fromLTRB(plot.rect.left, plot.y(upper, d.y), plot.rect.right, plot.y(lower, d.y)),
            Paint()..color = theme.tone(tones[math.min(k, tones.length - 1)]).withValues(alpha: 0.08),
          );
          lower = upper;
        }
        final cols = math.max(1, data.columns.length);
        for (var c = 0; c < data.columns.length; c++) {
          paintLabel(
            canvas,
            format.label(data.columns[c]),
            Offset(plot.x((c + 0.5) / cols), plot.rect.bottom + 11),
            labelStyle,
            maxWidth: plot.rect.width / cols,
          );
        }
    }
    // Labeled horizontal reference lines (percentiles).
    if (data.variant != ScatterVariant.planVsActual) {
      for (final (v, label) in data.lines) {
        final y = plot.y(v, d.y);
        dashedLine(canvas, Offset(plot.rect.left, y), Offset(plot.rect.right, y), guide);
        paintLabel(
          canvas,
          '${format.label(label)} ${format.value(v, data.yUnit)}',
          Offset(rtl ? plot.rect.left + 2 : plot.rect.right - 2, y - 7),
          labelStyle.copyWith(color: theme.onSurface),
          anchor: rtl ? TextAnchor.leftEdge : TextAnchor.rightEdge,
        );
      }
    }
    final dense = data.points.length > 150;
    for (var i = 0; i < data.points.length; i++) {
      final p = data.points[i];
      final color = p.color == null ? theme.seriesColor(0) : theme.resolve(p.color!);
      final at = _position(i, plot, d);
      final radius = p.highlight || i == selected ? 5.0 : 3.5;
      canvas.drawCircle(at, radius, Paint()..color = color.withValues(alpha: dense && i != selected ? 0.45 : 0.9));
      if (i == selected || p.highlight) {
        canvas.drawCircle(
          at,
          radius + 1.5,
          Paint()
            ..color = theme.onSurface
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScatterPainter old) =>
      old.data != data || old.selected != selected || old.rtl != rtl || old.theme != theme;
}
