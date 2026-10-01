/// Geometry and text helpers shared by the custom cartesian painters of the P1/P2 chart kit
/// (T6.2.13–T6.2.26): a plot rectangle with the value axis on the start side, horizontal positions
/// mirrored in RTL (time runs right-to-left, arch §6.14), "nice" value ticks with grid lines, dashed
/// lines and canvas labels.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A value scale (nice ticks, see [niceScale]).
typedef ValueScale = ({double min, double max, double step});

/// The plot area of a painter of [size]: [axis] px for the value axis on the start side, [bottom] px
/// for the category/time labels, [top] px headroom and [endPad] px after the last point.
final class Plot {
  Plot(Size size, {required this.rtl, double axis = 44, double bottom = 22, double top = 8, double endPad = 8})
    : rect = rtl
          ? Rect.fromLTRB(endPad, top, math.max(endPad + 1, size.width - axis), math.max(top + 1, size.height - bottom))
          : Rect.fromLTRB(axis, top, math.max(axis + 1, size.width - endPad), math.max(top + 1, size.height - bottom));

  final bool rtl;
  final Rect rect;

  /// Horizontal position of the fraction [t] ∈ [0, 1] of the x domain (mirrored in RTL).
  double x(double t) => rtl ? rect.right - t * rect.width : rect.left + t * rect.width;

  /// Fraction of the x domain under the horizontal position [px].
  double t(double px) => rtl ? (rect.right - px) / rect.width : (px - rect.left) / rect.width;

  /// Vertical position of [v] on [scale].
  double y(double v, ValueScale scale) {
    final span = scale.max - scale.min;
    return rect.bottom - (span <= 0 ? 0 : (v - scale.min) / span) * rect.height;
  }

  /// Value under the vertical position [py].
  double valueAt(double py, ValueScale scale) => scale.min + (rect.bottom - py) / rect.height * (scale.max - scale.min);

  /// Start-side x of the value axis labels.
  double get axisLabelX => rtl ? rect.right + 4 : rect.left - 4;
}

/// Paints [text] with its [anchor] edge at [at] (vertically centered on `at.dy` when [middle]).
Size paintLabel(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  TextAnchor anchor = TextAnchor.center,
  double maxWidth = 120,
  bool middle = true,
  TextDirection direction = TextDirection.ltr,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  final dx = switch (anchor) {
    TextAnchor.leftEdge => at.dx,
    TextAnchor.center => at.dx - tp.width / 2,
    TextAnchor.rightEdge => at.dx - tp.width,
  };
  tp.paint(canvas, Offset(dx, middle ? at.dy - tp.height / 2 : at.dy));
  return tp.size;
}

/// Horizontal grid lines and value labels on the start side.
void paintValueAxis(
  Canvas canvas,
  Plot plot,
  ValueScale scale,
  String Function(double v) format,
  ChartTheme theme,
  TextStyle style,
) {
  final grid = Paint()
    ..color = theme.grid
    ..strokeWidth = 1;
  if (scale.step <= 0) return;
  final count = ((scale.max - scale.min) / scale.step).round();
  for (var i = 0; i <= count; i++) {
    final v = scale.min + i * scale.step;
    final y = plot.y(v, scale);
    canvas.drawLine(Offset(plot.rect.left, y), Offset(plot.rect.right, y), grid);
    paintLabel(
      canvas,
      format(v),
      Offset(plot.axisLabelX, y),
      style,
      anchor: plot.rtl ? TextAnchor.leftEdge : TextAnchor.rightEdge,
      maxWidth: 40,
    );
  }
}

/// A dashed segment from [a] to [b].
void dashedLine(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 4, double gap = 3}) {
  final length = (b - a).distance;
  if (length <= 0) return;
  final dir = (b - a) / length;
  for (var d = 0.0; d < length; d += dash + gap) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, length), paint);
  }
}

/// A small filled arrow head at [tip] pointing along [direction] (radians).
void arrowHead(Canvas canvas, Offset tip, double direction, Paint paint, {double size = 6}) {
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(tip.dx - size * math.cos(direction - 0.45), tip.dy - size * math.sin(direction - 0.45))
    ..lineTo(tip.dx - size * math.cos(direction + 0.45), tip.dy - size * math.sin(direction + 0.45))
    ..close();
  canvas.drawPath(path, paint..style = PaintingStyle.fill);
}

/// Tooltip bubble used by the custom painters' tap/scrub read-outs.
class ChartReadout extends StatelessWidget {
  const ChartReadout({required this.lines, super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.colors.inverseSurface, borderRadius: BorderRadius.circular(Radii.sm)),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm, vertical: Space.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                Text(
                  lines[i],
                  style: (i == 0 ? context.text.labelMedium : context.text.labelSmall)?.copyWith(
                    color: context.colors.onInverseSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
