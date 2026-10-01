/// Area and grid charts: the squarified treemap of time allocation (T6.2.20: category → task, labels
/// where the area allows, drill-down on tap, areas proportional to minutes) and the generic N × M
/// matrix heatmap (T6.2.21: sequential or diverging scale symmetric around 0, optional cell labels
/// and significance marks, truncated axis labels whose full text shows on tap).
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/charts/plot_support.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------------------------
// Squarified treemap (T6.2.20)
// ---------------------------------------------------------------------------------------------

/// Squarified treemap layout (Bruls, Huizing & van Wijk 2000): one rectangle per value (same order),
/// each with an area proportional to its value; zero or negative values get an empty rectangle.
List<Rect> squarify(List<double> values, Rect bounds) {
  final result = List<Rect>.filled(values.length, Rect.zero);
  final total = values.fold<double>(0, (a, v) => a + math.max(0, v));
  if (total <= 0 || bounds.isEmpty) return result;
  final scale = bounds.width * bounds.height / total;
  // Largest first gives the best aspect ratios; positions map back to the input order.
  final order = [
    for (var i = 0; i < values.length; i++)
      if (values[i] > 0) i,
  ]..sort((a, b) => values[b].compareTo(values[a]));
  var free = bounds;
  var row = <int>[];

  double worst(List<int> r, double side) {
    if (r.isEmpty) return double.infinity;
    final areas = [for (final i in r) values[i] * scale];
    final sum = areas.fold<double>(0, (a, b) => a + b);
    final mx = areas.reduce(math.max);
    final mn = areas.reduce(math.min);
    final s2 = side * side;
    return math.max(s2 * mx / (sum * sum), (sum * sum) / (s2 * mn));
  }

  void layoutRow(List<int> r) {
    final sum = r.fold<double>(0, (a, i) => a + values[i] * scale);
    if (free.width >= free.height) {
      // Column on the left of the free space.
      final w = free.height <= 0 ? 0.0 : sum / free.height;
      var y = free.top;
      for (final i in r) {
        final h = w <= 0 ? 0.0 : values[i] * scale / w;
        result[i] = Rect.fromLTWH(free.left, y, w, h);
        y += h;
      }
      free = Rect.fromLTRB(free.left + w, free.top, free.right, free.bottom);
    } else {
      final h = free.width <= 0 ? 0.0 : sum / free.width;
      var x = free.left;
      for (final i in r) {
        final w = h <= 0 ? 0.0 : values[i] * scale / h;
        result[i] = Rect.fromLTWH(x, free.top, w, h);
        x += w;
      }
      free = Rect.fromLTRB(free.left, free.top + h, free.right, free.bottom);
    }
  }

  for (final i in order) {
    final side = math.min(free.width, free.height);
    if (row.isEmpty || worst([...row, i], side) <= worst(row, side)) {
      row.add(i);
    } else {
      layoutRow(row);
      row = [i];
    }
  }
  if (row.isNotEmpty) layoutRow(row);
  return result;
}

class TreemapChart extends StatelessWidget {
  const TreemapChart(this.data, {super.key, this.height = 220, this.onTap});

  final TreemapData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final painter = _TreemapPainter(
      data,
      theme: theme,
      format: statFormatOf(context),
      rtl: rtl,
      labelStyle: context.text.labelSmall!.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, c) => GestureDetector(
          onTapUp: onTap == null
              ? null
              : (d) {
                  final hit = painter.nodeAt(d.localPosition, c.biggest);
                  if (hit == null) return;
                  chartSelectionFeedback(context);
                  onTap!(ChartTap(drillKey: hit.drillKey, label: hit.label, value: hit.value));
                },
          child: CustomPaint(size: c.biggest, painter: painter),
        ),
      ),
    );
  }
}

class _TreemapPainter extends CustomPainter {
  _TreemapPainter(this.data, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final TreemapData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  static const _header = 16.0;

  /// Mirrors a layout rectangle in RTL (the largest block starts on the start side).
  Rect _mirror(Rect r, Size size) =>
      rtl ? Rect.fromLTRB(size.width - r.right, r.top, size.width - r.left, r.bottom) : r;

  List<(TreemapNode, Rect, bool)> _layout(Size size) {
    final out = <(TreemapNode, Rect, bool)>[];
    final parents = squarify([for (final n in data.nodes) n.value], Offset.zero & size);
    for (var i = 0; i < data.nodes.length; i++) {
      final node = data.nodes[i];
      final rect = _mirror(parents[i], size);
      if (rect.isEmpty) continue;
      out.add((node, rect, true));
      final inner = rect.height > _header * 2.5 && rect.width > 40
          ? Rect.fromLTRB(rect.left + 1, rect.top + _header, rect.right - 1, rect.bottom - 1)
          : null;
      if (inner == null || node.children.isEmpty) continue;
      final kids = squarify([for (final c in node.children) c.value], Rect.fromLTWH(0, 0, inner.width, inner.height));
      for (var k = 0; k < node.children.length; k++) {
        final r = kids[k];
        if (r.isEmpty) continue;
        final local = rtl ? Rect.fromLTRB(inner.width - r.right, r.top, inner.width - r.left, r.bottom) : r;
        out.add((node.children[k], local.shift(inner.topLeft), false));
      }
    }
    return out;
  }

  TreemapNode? nodeAt(Offset p, Size size) {
    TreemapNode? hit;
    for (final (node, rect, _) in _layout(size)) {
      if (rect.contains(p)) hit = node; // children come after their parent: the innermost wins
    }
    return hit;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = theme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    for (final (node, rect, top) in _layout(size)) {
      final base = theme.resolve(node.color);
      final color = top ? base.withValues(alpha: 0.9) : base.withValues(alpha: 0.6);
      canvas
        ..drawRect(rect, Paint()..color = color)
        ..drawRect(rect, border);
      if (rect.width < 40 || rect.height < 16) continue;
      final text = '${format.label(node.label)} · ${format.value(node.value, data.unit)}';
      paintLabel(
        canvas,
        text,
        Offset(rtl ? rect.right - 4 : rect.left + 4, rect.top + 3),
        labelStyle.copyWith(color: onColor(color)),
        anchor: rtl ? TextAnchor.rightEdge : TextAnchor.leftEdge,
        maxWidth: rect.width - 8,
        middle: false,
        direction: direction,
      );
    }
  }

  @override
  bool shouldRepaint(_TreemapPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}

// ---------------------------------------------------------------------------------------------
// Matrix heatmap (T6.2.21)
// ---------------------------------------------------------------------------------------------

class MatrixHeatmap extends StatefulWidget {
  const MatrixHeatmap(this.data, {super.key, this.onTap});

  final MatrixData data;
  final void Function(ChartTap tap)? onTap;

  @override
  State<MatrixHeatmap> createState() => _MatrixHeatmapState();
}

class _MatrixHeatmapState extends State<MatrixHeatmap> {
  (int, int)? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final data = widget.data;
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, c) {
        const labelWidth = 72.0;
        const header = 22.0;
        final cols = math.max(1, data.columns.length);
        final cell = math.max<double>(16, math.min(44, (c.maxWidth - labelWidth) / cols));
        final width = labelWidth + cell * cols;
        final painter = MatrixPainter(
          data,
          theme: theme,
          format: f,
          rtl: rtl,
          cell: cell,
          labelWidth: labelWidth,
          header: header,
          selected: selected,
          labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
        );
        Widget grid = GestureDetector(
          onTapUp: (d) {
            final hit = painter.cellAt(d.localPosition, width);
            setState(() => _selected = hit);
            if (hit == null) return;
            chartSelectionFeedback(context);
            widget.onTap?.call(
              ChartTap(
                drillKey: 'cell:${hit.$1}:${hit.$2}',
                label: data.rows[hit.$1],
                value: data.values[hit.$1][hit.$2],
              ),
            );
          },
          child: CustomPaint(size: Size(width, header + cell * data.rows.length), painter: painter),
        );
        if (width > c.maxWidth) {
          grid = SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: rtl, child: grid);
        }
        return Stack(
          children: [
            grid,
            if (selected != null)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: ChartReadout(
                  lines: [
                    '${f.label(data.rows[selected.$1])} × ${f.label(data.columns[selected.$2])}',
                    switch (data.values[selected.$1][selected.$2]) {
                      final v? => f.value(v, data.unit),
                      null => context.l10n.chartsNotApplicable,
                    },
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Painter of [MatrixHeatmap] (exposed for the color-scale tests).
class MatrixPainter extends CustomPainter {
  MatrixPainter(
    this.data, {
    required this.theme,
    required this.format,
    required this.rtl,
    required this.cell,
    required this.labelWidth,
    required this.header,
    required this.labelStyle,
    this.selected,
  });

  final MatrixData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final double cell;
  final double labelWidth;
  final double header;
  final TextStyle labelStyle;
  final (int, int)? selected;

  /// The scale bound: the largest value, or the largest |value| for a diverging scale (symmetric
  /// around 0).
  double get bound {
    var m = 0.0;
    for (final row in data.values) {
      for (final v in row) {
        if (v != null) m = math.max(m, data.scale == MatrixScale.diverging ? v.abs() : v);
      }
    }
    return m;
  }

  /// Fill of [v] (null = no data).
  Color colorOf(double? v) {
    if (v == null) return theme.grid.withValues(alpha: 0.25);
    final b = bound;
    if (b <= 0) return theme.grid.withValues(alpha: 0.35);
    if (data.scale == MatrixScale.diverging) {
      final t = (v.abs() / b).clamp(0.0, 1.0);
      final base = theme.tone(v >= 0 ? ChartTone.positive : ChartTone.negative);
      return base.withValues(alpha: 0.1 + 0.85 * t);
    }
    return theme.seriesColor(0).withValues(alpha: 0.12 + 0.86 * (v / b).clamp(0.0, 1.0));
  }

  double _x(int col, double width) => rtl ? width - labelWidth - (col + 1) * cell : labelWidth + col * cell;

  (int, int)? cellAt(Offset p, double width) {
    final row = ((p.dy - header) / cell).floor();
    if (row < 0 || row >= data.rows.length) return null;
    final col = rtl ? ((width - labelWidth - p.dx) / cell).floor() : ((p.dx - labelWidth) / cell).floor();
    if (col < 0 || col >= data.columns.length) return null;
    return (row, col);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    for (var c = 0; c < data.columns.length; c++) {
      paintLabel(
        canvas,
        format.label(data.columns[c]),
        Offset(_x(c, size.width) + cell / 2, header / 2),
        labelStyle,
        maxWidth: cell,
        direction: direction,
      );
    }
    final showValues = cell >= 30;
    for (var r = 0; r < data.rows.length; r++) {
      final y = header + r * cell;
      paintLabel(
        canvas,
        format.label(data.rows[r]),
        Offset(rtl ? size.width - 2 : 2, y + cell / 2),
        labelStyle,
        anchor: rtl ? TextAnchor.rightEdge : TextAnchor.leftEdge,
        maxWidth: labelWidth - 6,
        direction: direction,
      );
      for (var c = 0; c < data.columns.length; c++) {
        final v = c < data.values[r].length ? data.values[r][c] : null;
        final rect = Rect.fromLTWH(_x(c, size.width) + 1, y + 1, cell - 2, cell - 2);
        final fill = colorOf(v);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = fill);
        if (selected == (r, c)) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = theme.onSurface
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
        if (showValues && v != null) {
          paintLabel(
            canvas,
            format.value(v, data.unit),
            rect.center,
            labelStyle.copyWith(color: onColor(Color.alphaBlend(fill, theme.surface)), fontSize: 9),
            maxWidth: cell,
          );
        }
        if (data.marks != null && r < data.marks!.length && c < data.marks![r].length && data.marks![r][c]) {
          canvas.drawCircle(rect.topRight + const Offset(-4, 4), 2, Paint()..color = theme.onSurface);
        }
      }
    }
  }

  @override
  bool shouldRepaint(MatrixPainter old) =>
      old.data != data || old.selected != selected || old.cell != cell || old.rtl != rtl || old.theme != theme;
}
