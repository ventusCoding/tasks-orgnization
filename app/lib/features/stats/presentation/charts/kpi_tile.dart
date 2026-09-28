/// KPI tile (T6.2.02): headline value with unit, delta chip colored by the metric's direction (the
/// arrow and sign are always present), a "± x pp" Wilson half-width below 20 units, a sparkline of
/// the last buckets and an optional target marker. Tap = drill-down, long-press = explain.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Insufficient, MinSampleRule, NotApplicable, Value;
import 'package:material_ui/material_ui.dart';

enum KpiSize { compact, regular }

class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.title,
    required this.result,
    super.key,
    this.direction = MetricDirection.higherIsBetter,
    this.minSample,
    this.size = KpiSize.regular,
    this.onTap,
    this.onLongPress,
    this.caption,
  });

  final String title;
  final MetricResult result;
  final MetricDirection direction;

  /// Minimum-data rule: shows the "±" half-width while n is below `intervalBelow`.
  final MinSampleRule? minSample;
  final KpiSize size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Secondary line (e.g. "Best: 12").
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final f = statFormatOf(context);
    final theme = ChartTheme.of(context);
    final value = f.headline(result);
    final delta = f.delta(result, direction);
    final v = result.value;
    final n = v is Value<double> ? v.sampleSize : null;
    final interval = minSample != null && n != null && minSample!.showsInterval(n) ? f.intervalHalfWidth(result) : null;
    final muted = v is! Value<double>;
    final note = v is NotApplicable<double> ? f.note(result.note ?? v.reasonKey) : null;
    final compact = size == KpiSize.compact;
    final valueStyle = (compact ? context.text.titleLarge : context.text.headlineSmall)?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: AppTheme.tabular,
      color: muted ? context.colors.onSurfaceVariant : null,
    );
    final semantics = context.l10n.chartsKpiSemantics(title, value, delta?.semantics ?? '');
    return Semantics(
      button: onTap != null,
      label: semantics,
      excludeSemantics: true,
      onLongPressHint: onLongPress == null ? null : context.l10n.chartsExplain,
      child: Material(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsetsDirectional.all(compact ? Space.sm : Space.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final showSpark =
                      result.spark != null &&
                      result.spark!.whereType<double>().length >= 2 &&
                      scale <= 1.5 &&
                      constraints.maxWidth >= 120;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Space.xs),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Space.sm,
                        runSpacing: Space.xxs,
                        children: [
                          Text(value, style: valueStyle),
                          if (interval != null)
                            Text(
                              interval,
                              style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          if (delta != null) DeltaChip(delta: delta),
                        ],
                      ),
                      if (note != null || caption != null) ...[
                        const SizedBox(height: Space.xxs),
                        Text(
                          caption ?? note!,
                          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (showSpark) ...[
                        const SizedBox(height: Space.sm),
                        SizedBox(
                          height: compact ? 20 : 28,
                          width: double.infinity,
                          child: Sparkline(values: result.spark!, color: theme.seriesColor(0), target: result.target),
                        ),
                      ],
                      if (v is Insufficient<double> && !compact) ...[
                        const SizedBox(height: Space.xxs),
                        LinearProgressIndicator(
                          value: v.requiredN <= 0 ? 0 : (v.haveN / v.requiredN).clamp(0, 1).toDouble(),
                          minHeight: 3,
                          color: theme.muted,
                          backgroundColor: theme.grid,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Delta chip: arrow + signed value, colored good/bad/neutral (never color alone).
class DeltaChip extends StatelessWidget {
  const DeltaChip({required this.delta, super.key});

  final DeltaView delta;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = switch (delta.good) {
      true => colors.success,
      false => colors.danger,
      null => context.colors.onSurfaceVariant,
    };
    final icon = switch (delta.arrow) {
      DeltaArrow.up => Icons.arrow_upward_rounded,
      DeltaArrow.down => Icons.arrow_downward_rounded,
      DeltaArrow.flat => Icons.remove_rounded,
    };
    return Semantics(
      label: delta.semantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.xs, 1, Space.sm, 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            // Wraps in narrow tiles at large text scales instead of overflowing.
            Flexible(
              child: Text(
                delta.text,
                style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny line (gaps break it) with an optional target line; time runs right-to-left in RTL.
class Sparkline extends StatelessWidget {
  const Sparkline({required this.values, required this.color, super.key, this.target, this.bars = false});

  final List<double?> values;
  final Color color;
  final double? target;
  final bool bars;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _SparkPainter(
        values,
        color,
        target,
        bars,
        rtl: Directionality.of(context) == TextDirection.rtl,
        grid: ChartTheme.of(context).grid,
      ),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.target, this.bars, {required this.rtl, required this.grid});

  final List<double?> values;
  final Color color;
  final double? target;
  final bool bars;
  final bool rtl;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return;
    var lo = present.reduce(math.min);
    var hi = present.reduce(math.max);
    if (target != null) {
      lo = math.min(lo, target!);
      hi = math.max(hi, target!);
    }
    if (hi - lo < 1e-9) {
      hi = lo + 1;
    }
    double x(int i) {
      final t = values.length == 1 ? 0.5 : i / (values.length - 1);
      return (rtl ? 1 - t : t) * size.width;
    }

    double y(double v) => size.height - (v - lo) / (hi - lo) * size.height;
    if (target != null) {
      canvas.drawLine(
        Offset(0, y(target!)),
        Offset(size.width, y(target!)),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (bars) {
      final w = size.width / values.length * 0.7;
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        if (v == null) continue;
        canvas.drawRect(Rect.fromLTRB(x(i) - w / 2, y(v), x(i) + w / 2, size.height), Paint()..color = color);
      }
      return;
    }
    Path? path;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        if (path != null) canvas.drawPath(path, paint);
        path = null;
        continue;
      }
      if (path == null) {
        path = Path()..moveTo(x(i), y(v));
      } else {
        path.lineTo(x(i), y(v));
      }
    }
    if (path != null) canvas.drawPath(path, paint);
    final last = values.lastIndexWhere((v) => v != null);
    if (last >= 0) canvas.drawCircle(Offset(x(last), y(values[last]!)), 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color || old.target != target || old.rtl != rtl || old.bars != bars;
}
