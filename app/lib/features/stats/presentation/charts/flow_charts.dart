/// Stacked area & cumulative flow diagram (T6.2.16). Bands are stacked in the given order (bottom →
/// top; for a CFD: completed, blocked, waiting, ongoing, todo), so they never cross; a reopen simply
/// lowers the completed band on that day. Tapping or dragging horizontally scrubs to a date and reads
/// out every band's count; on a CFD the read-out adds the WIP (vertical distance between the
/// "started" and "completed" boundaries) and the approximate cycle time (horizontal distance until the
/// completed boundary reaches today's "started" level). RTL mirrors time.
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

/// Stack geometry of a [StackedAreaData] (pure, unit-tested): cumulative band boundaries per bucket.
final class StackedBands {
  StackedBands(this.data, {Set<int> hidden = const {}})
    : visible = [
        for (var b = 0; b < data.bands.length; b++)
          if (!hidden.contains(b)) b,
      ] {
    final n = data.buckets.length;
    tops = [for (final _ in visible) List<double>.filled(n, 0)];
    for (var i = 0; i < n; i++) {
      var acc = 0.0;
      for (var k = 0; k < visible.length; k++) {
        final values = data.bands[visible[k]].values;
        acc += math.max(0, i < values.length ? values[i] ?? 0 : 0);
        tops[k][i] = acc;
      }
    }
  }

  final StackedAreaData data;
  final List<int> visible;

  /// `tops[k][i]` = top of the k-th visible band at bucket i (bands never cross).
  late final List<List<double>> tops;

  double get maxTop => tops.isEmpty ? 0 : tops.last.fold(0, math.max);

  /// Value of band [band] (data index) at bucket [i].
  double valueAt(int band, int i) {
    final values = data.bands[band].values;
    return math.max(0, i < values.length ? values[i] ?? 0 : 0);
  }

  /// True when the bands are the checklist CFD (bottom band = completed).
  bool get isCfd =>
      data.bands.isNotEmpty && data.bands.first.label == const TokenLabel(LabelToken.completed) && visible.contains(0);

  int get _todo => data.bands.indexWhere((b) => b.label == const TokenLabel(LabelToken.todo));

  /// CFD work in progress at bucket [i]: every band except completed and todo.
  double wipAt(int i) {
    var wip = 0.0;
    for (var b = 1; b < data.bands.length; b++) {
      if (b == _todo) continue;
      wip += valueAt(b, i);
    }
    return wip;
  }

  /// Approximate cycle time (buckets) at [i]: until the completed band reaches the "started" level
  /// (completed + in progress) of bucket i; null when it never does inside the chart.
  int? cycleTimeAt(int i) {
    final started = valueAt(0, i) + wipAt(i);
    if (started <= 0) return null;
    for (var j = i; j < data.buckets.length; j++) {
      if (valueAt(0, j) >= started) return j - i;
    }
    return null;
  }
}

class StackedAreaChart extends StatefulWidget {
  const StackedAreaChart(this.data, {super.key, this.height = 200, this.onTap, this.hidden = const {}});

  final StackedAreaData data;
  final double height;
  final void Function(ChartTap tap)? onTap;
  final Set<int> hidden;

  @override
  State<StackedAreaChart> createState() => _StackedAreaChartState();
}

class _StackedAreaChartState extends State<StackedAreaChart> {
  int? _index;

  int _indexAt(Offset p, Size size, bool rtl) {
    final plot = Plot(size, rtl: rtl);
    final n = widget.data.buckets.length;
    return (plot.t(p.dx) * (n - 1)).round().clamp(0, n - 1);
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    chartSelectionFeedback(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final data = widget.data;
    final bands = StackedBands(data, hidden: widget.hidden);
    final index = _index;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final i = _indexAt(d.localPosition, c.biggest, rtl);
                  _select(i);
                  widget.onTap?.call(
                    ChartTap(drillKey: data.buckets[i].toIso(), label: DateLabel(data.buckets[i], data.granularity)),
                  );
                },
                onHorizontalDragStart: (d) => _select(_indexAt(d.localPosition, c.biggest, rtl)),
                onHorizontalDragUpdate: (d) => _select(_indexAt(d.localPosition, c.biggest, rtl)),
                child: CustomPaint(
                  size: c.biggest,
                  painter: _StackedPainter(
                    bands,
                    theme: theme,
                    format: f,
                    rtl: rtl,
                    selected: index,
                    labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
                  ),
                ),
              ),
            ),
            if (index != null && index < data.buckets.length)
              PositionedDirectional(top: 0, end: 0, child: ChartReadout(lines: _readout(context, f, bands, index))),
          ],
        ),
      ),
    );
  }

  List<String> _readout(BuildContext context, StatFormat f, StackedBands bands, int i) {
    final data = widget.data;
    return [
      f.label(DateLabel(data.buckets[i], data.granularity)),
      for (final b in bands.visible.reversed)
        context.l10n.chartsCrosshair(f.label(data.bands[b].label), f.value(bands.valueAt(b, i), data.unit)),
      if (bands.isCfd) ...[
        context.l10n.chartsCrosshair(f.label(const TokenLabel(LabelToken.wip)), f.value(bands.wipAt(i), data.unit)),
        if (bands.cycleTimeAt(i) case final ct?)
          context.l10n.chartsCrosshair(
            f.label(const TokenLabel(LabelToken.cycleTime)),
            context.l10n.chartsEstimate(f.value(ct.toDouble(), StatUnit.days)),
          ),
      ],
    ];
  }
}

class _StackedPainter extends CustomPainter {
  _StackedPainter(
    this.bands, {
    required this.theme,
    required this.format,
    required this.rtl,
    required this.selected,
    required this.labelStyle,
  });

  final StackedBands bands;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final int? selected;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final data = bands.data;
    final n = data.buckets.length;
    if (n == 0 || bands.visible.isEmpty) return;
    final plot = Plot(size, rtl: rtl);
    final scale = niceScale(0, math.max(1, bands.maxTop), maxTicks: 4);
    paintValueAxis(canvas, plot, scale, (v) => format.value(v, data.unit), theme, labelStyle);
    double tx(int i) => plot.x(n == 1 ? 0.5 : i / (n - 1));
    for (var k = bands.visible.length - 1; k >= 0; k--) {
      final band = data.bands[bands.visible[k]];
      final path = Path()..moveTo(tx(0), plot.y(bands.tops[k][0], scale));
      for (var i = 1; i < n; i++) {
        path.lineTo(tx(i), plot.y(bands.tops[k][i], scale));
      }
      for (var i = n - 1; i >= 0; i--) {
        path.lineTo(tx(i), plot.y(k == 0 ? 0 : bands.tops[k - 1][i], scale));
      }
      path.close();
      final color = theme.resolve(band.color);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
      final pattern = theme.patternOfColor(band.color);
      if (pattern != ChartPattern.none) {
        canvas
          ..save()
          ..clipPath(path);
        paintPattern(canvas, path.getBounds(), pattern, onColor(color).withValues(alpha: 0.4));
        canvas.restore();
      }
    }
    final marker = Paint()..color = theme.onSurface;
    for (final m in data.markers) {
      if (m.index < 0 || m.index >= n) continue;
      final x = tx(m.index);
      final path = Path()
        ..moveTo(x, plot.rect.top)
        ..lineTo(x - 4, plot.rect.top - 6)
        ..lineTo(x + 4, plot.rect.top - 6)
        ..close();
      canvas.drawPath(path, marker);
    }
    final every = math.max(1, (n / 4).ceil());
    for (var i = 0; i < n; i += every) {
      paintLabel(
        canvas,
        format.label(DateLabel(data.buckets[i], data.granularity)),
        Offset(tx(i), plot.rect.bottom + 11),
        labelStyle,
      );
    }
    final s = selected;
    if (s != null && s < n) {
      final x = tx(s);
      canvas.drawLine(
        Offset(x, plot.rect.top),
        Offset(x, plot.rect.bottom),
        Paint()
          ..color = theme.onSurface
          ..strokeWidth = 1,
      );
      if (bands.isCfd) {
        // WIP: vertical distance between the completed and "started" boundaries.
        final done = plot.y(bands.valueAt(0, s), scale);
        final started = plot.y(bands.valueAt(0, s) + bands.wipAt(s), scale);
        final accent = Paint()
          ..color = theme.onSurface
          ..strokeWidth = 2.5;
        canvas.drawLine(Offset(x + (rtl ? -3 : 3), done), Offset(x + (rtl ? -3 : 3), started), accent);
        // Cycle time: horizontal distance until the completed boundary reaches that level.
        if (bands.cycleTimeAt(s) case final ct? when ct > 0) {
          dashedLine(canvas, Offset(x, started), Offset(tx(s + ct), started), accent..strokeWidth = 1.5);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StackedPainter old) =>
      old.bands.data != bands.data ||
      old.bands.visible.length != bands.visible.length ||
      old.selected != selected ||
      old.rtl != rtl ||
      old.theme != theme;
}
