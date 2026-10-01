/// Radial charts: the radar (T6.2.18: 3–12 axes, current vs previous, value labels, axes without data
/// drawn dashed) and the 24-hour rose (T6.2.19: a circular histogram of times of day, area-true
/// wedges, the circular-mean arrow and a ±1 circular SD arc; the ring rotates to the day start and a
/// cluster around midnight stays one lobe because the dial wraps).
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
// Radar (T6.2.18)
// ---------------------------------------------------------------------------------------------

class RadarChart extends StatelessWidget {
  const RadarChart(this.data, {super.key, this.height = 240});

  final RadarData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RadarPainter(
          data,
          theme: theme,
          format: statFormatOf(context),
          rtl: Directionality.of(context) == TextDirection.rtl,
          labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.data, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final RadarData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.axes.length;
    if (n < 3 || data.series.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = math.max(10, math.min(size.width, size.height) / 2 - 28).toDouble();
    var top = 0.0;
    for (final (_, values) in data.series) {
      for (final v in values) {
        if (v != null) top = math.max(top, v);
      }
    }
    final max = data.unit == StatUnit.percent ? math.max(1, top) : niceScale(0, math.max(top, 1), maxTicks: 4).max;
    // Clockwise from the top in LTR, counter-clockwise in RTL.
    double angle(int i) => -math.pi / 2 + (rtl ? -1 : 1) * 2 * math.pi * i / n;
    Offset at(int i, double r) => center + Offset(math.cos(angle(i)), math.sin(angle(i))) * r;
    final grid = Paint()
      ..color = theme.grid
      ..style = PaintingStyle.stroke;
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      final ring = Path()..moveTo(at(0, radius * f).dx, at(0, radius * f).dy);
      for (var i = 1; i <= n; i++) {
        final p = at(i % n, radius * f);
        ring.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(ring, grid);
    }
    final noData = <int>{
      for (var i = 0; i < n; i++)
        if (data.series.every((s) => i >= s.$2.length || s.$2[i] == null)) i,
    };
    for (var i = 0; i < n; i++) {
      final axisPaint = Paint()
        ..color = noData.contains(i) ? theme.muted : theme.axis.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      if (noData.contains(i)) {
        dashedLine(canvas, center, at(i, radius), axisPaint);
      } else {
        canvas.drawLine(center, at(i, radius), axisPaint);
      }
      final label = at(i, radius + 14);
      final cos = math.cos(angle(i));
      paintLabel(
        canvas,
        format.label(data.axes[i]),
        label,
        labelStyle,
        anchor: cos.abs() < 0.2 ? TextAnchor.center : (cos > 0 ? TextAnchor.leftEdge : TextAnchor.rightEdge),
        maxWidth: 72,
      );
    }
    for (var s = data.series.length - 1; s >= 0; s--) {
      final (_, values) = data.series[s];
      final color = theme.seriesColor(s);
      final path = Path();
      var started = false;
      for (var i = 0; i <= n; i++) {
        final k = i % n;
        final v = k < values.length ? values[k] : null;
        final p = at(k, radius * ((v ?? 0) / max).clamp(0.0, 1.0));
        if (!started) {
          path.moveTo(p.dx, p.dy);
          started = true;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      final stroke = Paint()
        ..color = color
        ..strokeWidth = s == 0 ? 2 : 1.4
        ..style = PaintingStyle.stroke;
      if (s == 0) {
        canvas
          ..drawPath(path, Paint()..color = color.withValues(alpha: 0.22))
          ..drawPath(path, stroke);
        for (var k = 0; k < n; k++) {
          final v = k < values.length ? values[k] : null;
          if (v == null) continue;
          final p = at(k, radius * (v / max).clamp(0.0, 1.0));
          canvas.drawCircle(p, 2.5, Paint()..color = color);
          paintLabel(
            canvas,
            format.value(v, data.unit),
            p + const Offset(0, -9),
            labelStyle.copyWith(color: theme.onSurface),
          );
        }
      } else {
        // The previous period is a dashed outline.
        final metrics = path.computeMetrics();
        for (final m in metrics) {
          for (var d = 0.0; d < m.length; d += 7) {
            canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), stroke);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}

// ---------------------------------------------------------------------------------------------
// 24-hour rose (T6.2.19)
// ---------------------------------------------------------------------------------------------

class RoseChart extends StatelessWidget {
  const RoseChart(this.data, {super.key, this.height = 240, this.onTap});

  final RoseData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final painter = RosePainter(
      data,
      theme: theme,
      format: f,
      labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              onTapUp: onTap == null
                  ? null
                  : (d) {
                      final s = painter.sectorAt(d.localPosition, c.biggest);
                      if (s == null) return;
                      chartSelectionFeedback(context);
                      final minutes = 1440 ~/ data.sectors.length;
                      onTap!(
                        ChartTap(
                          drillKey: 'minute:${s * minutes}',
                          label: NumberLabel((s * minutes).toDouble(), StatUnit.clock),
                          value: data.sectors[s],
                        ),
                      );
                    },
              child: CustomPaint(size: c.biggest, painter: painter),
            ),
          ),
        ),
        if (!data.consistent)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.xs),
            child: Text(context.l10n.chartsNoConsistentTime, style: context.text.labelMedium),
          )
        else if (data.meanMinute != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.xs),
            child: Text(
              '${f.label(const TokenLabel(LabelToken.mean))} ${f.clock(data.meanMinute!)}'
              '${data.sdMinutes == null ? '' : ' ${context.l10n.chartsPlusMinus(f.duration(data.sdMinutes!))}'}',
              style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Painter of [RoseChart]: angle 0 (top) is the day start; time runs clockwise.
class RosePainter extends CustomPainter {
  RosePainter(this.data, {required this.theme, required this.format, required this.labelStyle});

  final RoseData data;
  final ChartTheme theme;
  final StatFormat format;
  final TextStyle labelStyle;

  double _radius(Size size) => math.max(10, math.min(size.width, size.height) / 2 - 18).toDouble();

  /// Angle of [minuteOfDay] (radians from the top, clockwise).
  double angleOf(double minuteOfDay) =>
      -math.pi / 2 + 2 * math.pi * (((minuteOfDay - data.dayStartMinute) % 1440 + 1440) % 1440) / 1440;

  int? sectorAt(Offset p, Size size) {
    final v = p - size.center(Offset.zero);
    if (v.distance > _radius(size) || data.sectors.isEmpty) return null;
    var a = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (a < 0) a += 2 * math.pi;
    final minute = (a / (2 * math.pi) * 1440 + data.dayStartMinute) % 1440;
    return (minute / (1440 / data.sectors.length)).floor() % data.sectors.length;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.sectors.length;
    if (n == 0) return;
    final center = size.center(Offset.zero);
    final radius = _radius(size);
    final max = data.sectors.fold<double>(0, math.max);
    final grid = Paint()
      ..color = theme.grid
      ..style = PaintingStyle.stroke;
    for (final f in [0.5, 1.0]) {
      canvas.drawCircle(center, radius * f, grid);
    }
    final per = 1440 / n;
    final color = theme.seriesColor(0);
    for (var s = 0; s < n; s++) {
      final v = data.sectors[s];
      if (v <= 0 || max <= 0) continue;
      // Area-true wedges: radius ∝ √count.
      final r = radius * math.sqrt(v / max);
      final a0 = angleOf(s * per);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        a0,
        2 * math.pi / n,
        true,
        Paint()..color = color.withValues(alpha: 0.75),
      );
    }
    for (var h = 0; h < 24; h += 6) {
      final minute = (data.dayStartMinute + h * 60) % 1440;
      final a = angleOf(minute.toDouble());
      paintLabel(
        canvas,
        format.clock(minute.toDouble()),
        center + Offset(math.cos(a), math.sin(a)) * (radius + 10),
        labelStyle,
      );
    }
    final mean = data.meanMinute;
    if (data.consistent && mean != null) {
      final accent = Paint()
        ..color = theme.onSurface
        ..strokeWidth = 2;
      final a = angleOf(mean);
      final tip = center + Offset(math.cos(a), math.sin(a)) * radius * 0.9;
      canvas.drawLine(center, tip, accent);
      arrowHead(canvas, tip, a, Paint()..color = theme.onSurface);
      final sd = data.sdMinutes;
      if (sd != null && sd > 0) {
        final sweep = 2 * math.pi * math.min(sd, 720) / 1440;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius + 3),
          a - sweep,
          2 * sweep,
          false,
          Paint()
            ..color = theme.onSurface
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RosePainter old) => old.data != data || old.theme != theme;
}
