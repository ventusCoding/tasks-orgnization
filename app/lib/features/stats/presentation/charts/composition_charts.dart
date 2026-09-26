/// Composition charts (T6.2.05): a donut on `fl_chart` (≤ 7 slices + "Other", center headline,
/// legend with values and shares) and a Pareto chart (descending bars, cumulative-% line on a
/// secondary axis and an 80 % reference line; ≤ 12 bars + "Other", "Unspecified" last).
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

class DonutChart extends StatefulWidget {
  const DonutChart(this.data, {super.key, this.height = 180, this.onTap});

  final DonutData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final data = widget.data;
    final total = data.total;
    final center = data.centerValue ?? total;
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < data.slices.length; i++)
          InkWell(
            onTap: widget.onTap == null ? null : () => _tap(i),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorDot(theme.resolve(data.slices[i].color), size: 10),
                  const SizedBox(width: Space.sm),
                  Flexible(
                    child: Text(
                      '${f.label(data.slices[i].label)} · ${f.value(data.slices[i].value, data.unit)} · ${f.percent(total == 0 ? 0 : data.slices[i].value / total)}',
                      style: context.text.bodySmall?.copyWith(fontWeight: _touched == i ? FontWeight.w700 : null),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    final donut = SizedBox(
      width: widget.height,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: widget.height * 0.28,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < data.slices.length; i++)
                  PieChartSectionData(
                    value: data.slices[i].value,
                    color: theme.resolve(data.slices[i].color),
                    radius: widget.height * (_touched == i ? 0.2 : 0.17),
                    showTitle: false,
                  ),
              ],
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final i = response?.touchedSection?.touchedSectionIndex;
                  if (event is FlTapUpEvent && i != null && i >= 0) _tap(i);
                },
              ),
            ),
            duration: chartAnimation(context),
          ),
          ExcludeSemantics(
            child: Text(
              f.value(center, data.unit),
              style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= widget.height * 2
          ? Row(
              children: [
                donut,
                const SizedBox(width: Space.lg),
                Expanded(child: legend),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: donut),
                const SizedBox(height: Space.sm),
                legend,
              ],
            ),
    );
  }

  void _tap(int i) {
    setState(() => _touched = i);
    chartSelectionFeedback(context);
    final s = widget.data.slices[i];
    widget.onTap?.call(ChartTap(drillKey: s.drillKey, label: s.label, seriesIndex: i, value: s.value));
  }
}

class ParetoChart extends StatelessWidget {
  const ParetoChart(this.data, {super.key, this.height = 200, this.onTap});

  final ParetoData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final painter = _ParetoPainter(
      data,
      theme: theme,
      format: f,
      rtl: rtl,
      labelStyle: context.text.labelSmall!.copyWith(color: theme.label),
    );
    return SizedBox(
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTap == null
            ? null
            : (d) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final i = painter.indexAt(d.localPosition, box.size);
                if (i == null) return;
                chartSelectionFeedback(context);
                onTap!(ChartTap(drillKey: data.drillKeys?[i], label: data.entries[i].$1, value: data.entries[i].$2));
              },
        child: CustomPaint(size: Size.infinite, painter: painter),
      ),
    );
  }
}

class _ParetoPainter extends CustomPainter {
  _ParetoPainter(this.data, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final ParetoData data;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  Rect _plot(Size s) => Rect.fromLTRB(36, 8, s.width - 36, s.height - 34);

  int? indexAt(Offset p, Size size) {
    final plot = _plot(size);
    final n = data.entries.length;
    if (n == 0 || !plot.inflate(6).contains(p)) return null;
    final slot = ((p.dx - plot.left) / (plot.width / n)).floor().clamp(0, n - 1);
    return visualIndex(slot, n, rtl: rtl);
  }

  void _text(Canvas canvas, String t, Offset at, {double maxWidth = 60, TextAnchor align = TextAnchor.center}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: labelStyle),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
      textAlign: TextAlign.center,
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
    final n = data.entries.length;
    if (n == 0) return;
    final plot = _plot(size);
    final maxV = data.entries.map((e) => e.$2).reduce(math.max);
    final scale = niceScale(0, maxV, maxTicks: 4);
    final band = plot.width / n;
    final cum = data.cumulative;
    final grid = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;
    for (var v = scale.min; v <= scale.max + 1e-9; v += scale.step) {
      final y = plot.bottom - (v - scale.min) / (scale.max - scale.min) * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, format.value(v, data.unit), Offset(rtl ? plot.right + 18 : plot.left - 18, y), maxWidth: 34);
    }
    // 80 % reference on the secondary axis.
    final y80 = plot.bottom - 0.8 * plot.height;
    canvas.drawLine(
      Offset(plot.left, y80),
      Offset(plot.right, y80),
      Paint()
        ..color = theme.tone(ChartTone.warning)
        ..strokeWidth = 1,
    );
    _text(canvas, format.percent(0.8), Offset(rtl ? plot.left - 18 : plot.right + 18, y80), maxWidth: 34);
    final line = Path();
    for (var i = 0; i < n; i++) {
      final slot = visualIndex(i, n, rtl: rtl);
      final x0 = plot.left + slot * band + band * 0.15;
      final x1 = x0 + band * 0.7;
      final y = plot.bottom - (data.entries[i].$2 - scale.min) / (scale.max - scale.min) * plot.height;
      final color = data.entries[i].$1 is TokenLabel && (data.entries[i].$1 as TokenLabel).token == LabelToken.other
          ? theme.muted
          : theme.seriesColor(0);
      canvas.drawRect(Rect.fromLTRB(x0, y, x1, plot.bottom), Paint()..color = color);
      final cx = (x0 + x1) / 2;
      final cy = plot.bottom - cum[i] * plot.height;
      if (i == 0) {
        line.moveTo(cx, cy);
      } else {
        line.lineTo(cx, cy);
      }
      canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = theme.seriesColor(1));
      if (band >= 30 || i % math.max(1, (40 / band).ceil()) == 0) {
        _text(canvas, format.label(data.entries[i].$1), Offset(cx, plot.bottom + 16), maxWidth: math.max(band, 40));
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = theme.seriesColor(1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ParetoPainter old) => old.data != data || old.rtl != rtl || old.theme != theme;
}
