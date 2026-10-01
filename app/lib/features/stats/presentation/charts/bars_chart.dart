/// Bar charts (T6.2.04): vertical grouped/stacked/100 %, horizontal and diverging variants with
/// optional overlay lines (capacity, rolling mean, target) drawn above the bars, pattern fills for
/// status tones, value labels that hide when crowded, horizontal scrolling beyond 60 bars, typed tap
/// payloads and a tooltip that lists every segment with its share. RTL mirrors the category order.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:material_ui/material_ui.dart';

class BarsChart extends StatefulWidget {
  const BarsChart(this.data, {super.key, this.height = 200, this.onTap, this.hidden = const {}});

  final BarData data;
  final double height;
  final void Function(ChartTap tap)? onTap;
  final Set<int> hidden;

  @override
  State<BarsChart> createState() => _BarsChartState();
}

class _BarsChartState extends State<BarsChart> {
  int? _selected;

  BarData get data => widget.data;

  List<int> get _visibleSeries => [
    for (var s = 0; s < data.series.length; s++)
      if (!widget.hidden.contains(s)) s,
  ];

  double _v(int s, int i) => i < data.series[s].values.length ? data.series[s].values[i] : 0;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final n = data.categories.length;
    if (n == 0) return SizedBox(height: widget.height);
    final horizontal = data.layout == BarLayout.horizontal;
    final height = horizontal ? math.max(widget.height, n * 28.0 + 24) : widget.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = horizontal ? constraints.maxWidth : math.max(constraints.maxWidth, n > 60 ? n * 10.0 : 0.0);
        final painter = _BarsPainter(
          data: data,
          visible: _visibleSeries,
          theme: theme,
          format: f,
          rtl: rtl,
          selected: _selected,
          labelStyle: context.text.labelSmall!.copyWith(color: theme.label),
          valueStyle: context.text.labelSmall!.copyWith(color: theme.onSurface, fontSize: 10),
        );
        Widget chart = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final hit = painter.cellAt(d.localPosition, Size(minWidth, height));
            if (hit == null) {
              setState(() => _selected = null);
              return;
            }
            setState(() => _selected = hit.$1);
            chartSelectionFeedback(context);
            widget.onTap?.call(
              ChartTap(
                drillKey: data.drillKeys?[hit.$1],
                label: data.categories[hit.$1],
                seriesIndex: hit.$2,
                value: hit.$2 == null ? null : _v(hit.$2!, hit.$1),
              ),
            );
          },
          child: CustomPaint(size: Size(minWidth, height), painter: painter),
        );
        if (minWidth > constraints.maxWidth) {
          chart = SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: rtl, child: chart);
        }
        final selected = _selected;
        return SizedBox(
          height: height + (selected == null ? 0 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: chart),
              if (selected != null && selected < n)
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: _Tooltip(lines: _tooltipLines(f, selected)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<String> _tooltipLines(StatFormat f, int i) {
    final total = _visibleSeries.fold<double>(0, (a, s) => a + _v(s, i).abs());
    final stacked = data.layout == BarLayout.stacked || data.layout == BarLayout.percent;
    return [
      f.label(data.categories[i]),
      for (final s in _visibleSeries)
        if (_v(s, i) != 0 || !stacked)
          '${f.label(data.series[s].label)}: ${f.value(_v(s, i), data.unit)}${stacked && total > 0 ? ' (${f.percent(_v(s, i).abs() / total)})' : ''}',
      for (final o in data.overlays)
        if (_overlayAt(o, i) case final v?) '${f.label(o.label)}: ${f.value(v, data.unit)}',
    ];
  }

  double? _overlayAt(BarOverlay o, int i) =>
      o.values.length == 1 ? o.values.first : (i < o.values.length ? o.values[i] : null);
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.lines});

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

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.data,
    required this.visible,
    required this.theme,
    required this.format,
    required this.rtl,
    required this.selected,
    required this.labelStyle,
    required this.valueStyle,
  });

  final BarData data;
  final List<int> visible;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final int? selected;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  static const _axisWidth = 44.0;
  static const _labelHeight = 22.0;

  bool get _horizontal => data.layout == BarLayout.horizontal;
  bool get _stacked => data.layout == BarLayout.stacked || data.layout == BarLayout.percent;
  int get _n => data.categories.length;

  double _v(int s, int i) => i < data.series[s].values.length ? data.series[s].values[i] : 0;

  /// Visual slot of category [i] (RTL mirrors the order).
  int _slot(int i) => visualIndex(i, _n, rtl: rtl && !_horizontal);

  ({double lo, double hi, double step}) _scale() {
    var lo = 0.0;
    var hi = 0.0;
    for (var i = 0; i < _n; i++) {
      if (data.layout == BarLayout.percent) {
        hi = 1;
        break;
      }
      if (_stacked) {
        var pos = 0.0;
        var neg = 0.0;
        for (final s in visible) {
          final v = _v(s, i);
          if (v >= 0) {
            pos += v;
          } else {
            neg += v;
          }
        }
        hi = math.max(hi, pos);
        lo = math.min(lo, neg);
      } else {
        for (final s in visible) {
          hi = math.max(hi, _v(s, i));
          lo = math.min(lo, _v(s, i));
        }
      }
      for (final o in data.overlays) {
        final v = o.values.length == 1 ? o.values.first : (i < o.values.length ? o.values[i] : null);
        if (v != null) {
          hi = math.max(hi, v);
          lo = math.min(lo, v);
        }
      }
    }
    final s = niceScale(lo, hi == lo ? lo + 1 : hi, maxTicks: 4);
    return (lo: s.min, hi: s.max, step: s.step);
  }

  Rect _plot(Size size) {
    if (_horizontal) {
      final labelWidth = math.min<double>(size.width * 0.38, 140);
      return rtl
          ? Rect.fromLTRB(4, 4, size.width - labelWidth, size.height - 18)
          : Rect.fromLTRB(labelWidth, 4, size.width - 4, size.height - 18);
    }
    return rtl
        ? Rect.fromLTRB(4, 8, size.width - _axisWidth, size.height - _labelHeight)
        : Rect.fromLTRB(_axisWidth, 8, size.width - 4, size.height - _labelHeight);
  }

  /// (category index, series index) under [p].
  (int, int?)? cellAt(Offset p, Size size) {
    final plot = _plot(size);
    if (!plot.inflate(8).contains(p)) return null;
    final band = (_horizontal ? plot.height : plot.width) / _n;
    final pos = _horizontal ? p.dy - plot.top : p.dx - plot.left;
    final slot = (pos / band).floor().clamp(0, _n - 1);
    final i = _horizontal ? slot : visualIndex(slot, _n, rtl: rtl);
    if (visible.isEmpty) return (i, null);
    if (!_stacked && visible.length > 1 && !_horizontal) {
      final within = pos - slot * band;
      final inner = band * 0.8;
      final idx = ((within - band * 0.1) / (inner / visible.length)).floor().clamp(0, visible.length - 1);
      return (i, visible[idx]);
    }
    return (i, visible.first);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    TextAnchor align = TextAnchor.center,
    double maxWidth = 80,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = switch (align) {
      TextAnchor.center => at.dx - tp.width / 2,
      TextAnchor.rightEdge => at.dx - tp.width,
      TextAnchor.leftEdge => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_n == 0) return;
    final plot = _plot(size);
    final scale = _scale();
    double valuePos(double v) {
      final t = (v - scale.lo) / (scale.hi - scale.lo);
      if (_horizontal) return rtl ? plot.right - t * plot.width : plot.left + t * plot.width;
      return plot.bottom - t * plot.height;
    }

    final grid = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;
    for (var v = scale.lo; v <= scale.hi + 1e-9; v += scale.step) {
      final p = valuePos(v);
      if (_horizontal) {
        canvas.drawLine(Offset(p, plot.top), Offset(p, plot.bottom), grid);
        _text(canvas, format.value(v, data.unit), Offset(p, size.height - 8), labelStyle, maxWidth: 60);
      } else {
        canvas.drawLine(Offset(plot.left, p), Offset(plot.right, p), grid);
        _text(
          canvas,
          format.value(v, data.layout == BarLayout.percent ? data.unit : data.unit),
          Offset(rtl ? plot.right + 4 : plot.left - 4, p),
          labelStyle,
          align: rtl ? TextAnchor.leftEdge : TextAnchor.rightEdge,
          maxWidth: _axisWidth - 6,
        );
      }
    }
    final band = (_horizontal ? plot.height : plot.width) / _n;
    final showLabels = band >= 28;
    final labelEvery = _horizontal ? 1 : math.max(1, (48 / band).ceil());
    final zero = valuePos(0);
    for (var i = 0; i < _n; i++) {
      final slot = _horizontal ? i : _slot(i);
      final bandStart = (_horizontal ? plot.top : plot.left) + slot * band;
      final inner = band * (_horizontal ? 0.7 : 0.8);
      final start = bandStart + (band - inner) / 2;
      final total = visible.fold<double>(0, (a, s) => a + _v(s, i).abs());
      var posAcc = 0.0;
      var negAcc = 0.0;
      for (var k = 0; k < visible.length; k++) {
        final s = visible[k];
        var v = _v(s, i);
        if (data.layout == BarLayout.percent) v = total == 0 ? 0 : v.abs() / total;
        if (v == 0) continue;
        double from;
        double to;
        double a;
        double b;
        if (_stacked) {
          if (v >= 0) {
            from = posAcc;
            posAcc += v;
            to = posAcc;
          } else {
            from = negAcc;
            negAcc += v;
            to = negAcc;
          }
          a = start;
          b = start + inner;
        } else {
          from = 0;
          to = v;
          final w = inner / visible.length;
          a = start + k * w;
          b = a + w;
        }
        final p1 = valuePos(from);
        final p2 = valuePos(to);
        final rect = _horizontal
            ? Rect.fromLTRB(math.min(p1, p2), a, math.max(p1, p2), b)
            : Rect.fromLTRB(a, math.min(p1, p2), b, math.max(p1, p2));
        final color = theme.resolve(data.series[s].color);
        final dim = selected != null && selected != i;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()..color = dim ? color.withValues(alpha: 0.45) : color,
        );
        paintPattern(canvas, rect, theme.patternOfColor(data.series[s].color), onColor(color).withValues(alpha: 0.45));
        if (!_stacked && showLabels && (_horizontal ? rect.height >= 12 : rect.width >= 22)) {
          final text = format.value(_v(s, i), data.unit);
          if (_horizontal) {
            _text(
              canvas,
              text,
              Offset(rtl ? rect.left - 4 : rect.right + 4, rect.center.dy),
              valueStyle,
              align: rtl ? TextAnchor.rightEdge : TextAnchor.leftEdge,
              maxWidth: 70,
            );
          } else if (rect.width >= text.length * 5.5) {
            _text(canvas, text, Offset(rect.center.dx, rect.top - 6), valueStyle, maxWidth: rect.width + 8);
          }
        }
      }
      if (_horizontal) {
        _text(
          canvas,
          format.label(data.categories[i]),
          Offset(rtl ? plot.right + 6 : plot.left - 6, bandStart + band / 2),
          labelStyle,
          align: rtl ? TextAnchor.leftEdge : TextAnchor.rightEdge,
          maxWidth: math.min(size.width * 0.38, 140) - 8,
        );
      } else if (i % labelEvery == 0) {
        _text(
          canvas,
          format.label(data.categories[i]),
          Offset(bandStart + band / 2, plot.bottom + 11),
          labelStyle,
          maxWidth: math.max(band * labelEvery, 36),
        );
      }
    }
    // Baseline for diverging values.
    if (scale.lo < 0) {
      final axis = Paint()
        ..color = theme.axis
        ..strokeWidth = 1;
      if (_horizontal) {
        canvas.drawLine(Offset(zero, plot.top), Offset(zero, plot.bottom), axis);
      } else {
        canvas.drawLine(Offset(plot.left, zero), Offset(plot.right, zero), axis);
      }
    }
    // Overlays above bars.
    for (final o in data.overlays) {
      final paint = Paint()
        ..color = theme.resolve(o.color)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      if (o.values.length == 1 && o.values.first != null) {
        final p = valuePos(o.values.first!);
        if (_horizontal) {
          canvas.drawLine(Offset(p, plot.top), Offset(p, plot.bottom), paint);
        } else {
          canvas.drawLine(Offset(plot.left, p), Offset(plot.right, p), paint);
        }
        continue;
      }
      Path? path;
      for (var i = 0; i < _n; i++) {
        final v = i < o.values.length ? o.values[i] : null;
        if (v == null) {
          if (path != null) canvas.drawPath(path, paint);
          path = null;
          continue;
        }
        final slot = _horizontal ? i : _slot(i);
        final c = (_horizontal ? plot.top : plot.left) + slot * band + band / 2;
        final pt = _horizontal ? Offset(valuePos(v), c) : Offset(c, valuePos(v));
        if (path == null) {
          path = Path()..moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawCircle(pt, 2, Paint()..color = paint.color);
      }
      if (path != null) canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.data != data ||
      old.selected != selected ||
      old.rtl != rtl ||
      old.theme != theme ||
      old.visible.length != visible.length;
}
