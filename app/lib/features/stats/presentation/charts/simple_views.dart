/// Small chart views: value tiles, ranked lists, an item's status timeline and tabbed chart groups.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/charts/kpi_tile.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show NotApplicable, PeriodComparison, Value;
import 'package:material_ui/material_ui.dart';

/// A group of value tiles (optionally with deltas).
class ValueTilesView extends StatelessWidget {
  const ValueTilesView(this.data, {super.key, this.onTap});

  final TilesData data;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final f = statFormatOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 520 ? 3 : 2;
        final width = (c.maxWidth - Space.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final t in data.tiles)
              SizedBox(
                width: width,
                child: KpiTile(
                  title: f.label(t.label),
                  size: KpiSize.compact,
                  direction: t.direction,
                  caption: t.secondary == null ? null : f.label(t.secondary!),
                  onTap: onTap == null || t.drillKey == null
                      ? null
                      : () => onTap!(ChartTap(drillKey: t.drillKey, label: t.label, value: t.value)),
                  result: MetricResult(
                    t.metricId ?? '',
                    value: t.value == null ? const NotApplicable<double>('noData') : Value<double>(t.value!),
                    unit: t.unit,
                    currency: t.currency,
                    estimate: t.estimate,
                    comparison: t.delta == null || t.value == null
                        ? null
                        : PeriodComparison(
                            Value<double>(t.value!),
                            Value<double>(t.value! - (t.deltaIsPp ? t.delta! / 100 : t.delta!)),
                            delta: Value<double>(t.delta!),
                            deltaPct: const NotApplicable<double>('rateUsesPp'),
                            isRate: t.deltaIsPp,
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Ranked list rows (stale items, records, integrity flags…).
class RankedList extends StatelessWidget {
  const RankedList(this.data, {super.key, this.onRef, this.maxRows = 10});

  final ListData data;
  final void Function(DrillRef ref)? onRef;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in data.rows.take(maxRows))
          InkWell(
            onTap: r.ref == null || onRef == null ? null : () => onRef!(r.ref!),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: Space.xs),
                child: Row(
                  children: [
                    if (r.tone != null) ...[ColorDot(theme.tone(r.tone!)), const SizedBox(width: Space.sm)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f.label(r.label),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium,
                          ),
                          if (r.secondary != null)
                            Text(
                              f.label(r.secondary!),
                              style: context.text.bodySmall?.copyWith(color: theme.label),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (r.value != null) ...[
                      const SizedBox(width: Space.sm),
                      Text(
                        f.value(r.value!, r.unit),
                        style: context.text.labelMedium?.copyWith(fontFeatures: AppTheme.tabular),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One item's status history as colored segments (CL-I-07).
class StatusTimelineBar extends StatelessWidget {
  const StatusTimelineBar(this.data, {super.key});

  final StatusTimelineData data;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 18,
          width: double.infinity,
          child: CustomPaint(painter: _SegmentsPainter(data, theme, rtl: rtl)),
        ),
        const SizedBox(height: Space.sm),
        for (final s in data.segments)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 2),
            child: Row(
              children: [
                ColorDot(theme.tone(s.tone), size: 8),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    '${s.label == null ? '' : f.label(s.label!)} · ${f.dateTime(s.start)} · ${f.duration(s.end.difference(s.start).inSeconds / 60)}',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SegmentsPainter extends CustomPainter {
  _SegmentsPainter(this.data, this.theme, {required this.rtl});

  final StatusTimelineData data;
  final ChartTheme theme;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.segments.isEmpty) return;
    final start = data.segments.first.start;
    final end = data.segments.last.end.isAfter(data.now) ? data.segments.last.end : data.now;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return;
    for (final s in data.segments) {
      final a = s.start.difference(start).inSeconds / total;
      final b = s.end.difference(start).inSeconds / total;
      final rect = rtl
          ? Rect.fromLTRB(size.width * (1 - b), 0, size.width * (1 - a), size.height)
          : Rect.fromLTRB(size.width * a, 0, size.width * b, size.height);
      final color = theme.tone(s.tone);
      canvas.drawRect(rect, Paint()..color = color);
      paintPattern(canvas, rect, theme.patternOf(s.tone), onColor(color).withValues(alpha: 0.45));
    }
  }

  @override
  bool shouldRepaint(_SegmentsPainter old) => old.data != data || old.rtl != rtl;
}
