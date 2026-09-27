/// One metric card of a scope screen (T6.1.16): KPI tile or framed chart with headline value,
/// delta, notes, exclusions, the explain sheet and drill-down. Minimum-data rules are applied by
/// the engine; the card renders the resulting states (greyed "Needs N more", "—", "≈").
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_frame.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/kpi_tile.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/features/stats/presentation/widgets/drill_sheet.dart';
import 'package:everslot/features/stats/presentation/widgets/explain_sheet.dart';
import 'package:everslot/features/stats/presentation/widgets/habit_table.dart';
import 'package:everslot/features/stats/presentation/widgets/review_view.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Insufficient, NotApplicable, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class MetricCard extends ConsumerWidget {
  const MetricCard({
    required this.item,
    required this.result,
    super.key,
    this.loading = false,
    this.periodText,
    this.onReviewToggle,
    this.reviewCurrent = false,
  });

  final StatsLayoutItem item;
  final MetricResult? result;
  final bool loading;
  final String? periodText;

  /// Weekly review: switch between last week and this week so far.
  final ValueChanged<bool>? onReviewToggle;
  final bool reviewCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = ref.watch(metricRegistryProvider).byId(item.metricId);
    if (def == null) return const SizedBox.shrink();
    final l = context.l10n;
    final f = statFormatOf(context);
    final title = metricTitle(l, def.id) ?? def.id;
    final r = result;
    void explain() => showExplainSheet(context, def: def, result: r, periodText: periodText);
    DateTime now() => ref.read(clockProvider).nowUtc();

    if (item.variant == 'habitTable' && r != null) {
      return _Card(child: HabitMiniTable(rows: (r.args['habits'] as List?)?.cast<Map<String, Object?>>() ?? const []));
    }
    if (r?.chart case final ReviewData review) {
      return ReviewView(data: review, current: reviewCurrent, onToggle: onReviewToggle);
    }
    final isKpi = r != null && (def.chart == ChartKind.kpi || r.chart == null) && r.note != 'error';
    if (isKpi) {
      final allRefs = [for (final refs in r.drill.values) ...refs];
      return KpiTile(
        title: title,
        result: r,
        direction: def.direction,
        minSample: def.minSample,
        onLongPress: explain,
        onTap: allRefs.isEmpty ? explain : () => showDrillSheet(context, title: title, refs: allRefs),
      );
    }
    final v = r?.value;
    final chart = r?.chart;
    final status = switch (r) {
      null => loading ? ChartFrameStatus.loading : ChartFrameStatus.error,
      MetricResult(note: 'error') => ChartFrameStatus.error,
      _ when v is Insufficient<double> && (chart == null || chart.isEmpty) => ChartFrameStatus.insufficient,
      _ when chart == null || chart.isEmpty => ChartFrameStatus.empty,
      _ => ChartFrameStatus.data,
    };
    final delta = r == null ? null : f.delta(r, def.direction);
    final headline = r != null && r.headline && status == ChartFrameStatus.data && (v is Value<double> || v is Insufficient<double>)
        ? Wrap(
            spacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                f.headline(r),
                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: v is Value<double> ? null : context.colors.onSurfaceVariant),
              ),
              if (def.minSample != null && v is Value<double> && v.sampleSize != null && def.minSample!.showsInterval(v.sampleSize!))
                if (f.intervalHalfWidth(r) case final ci?) Text(ci, style: context.text.labelSmall),
              if (delta != null) DeltaChip(delta: delta),
            ],
          )
        : null;
    final notes = <String>[
      if (def.id == 'QT-11') ...[l.statsHealthDisclaimer],
      if (r?.note != null && r!.note != 'error')
        if (f.note(r.note) case final n?) n,
      if (v is NotApplicable<double> && r?.note == null)
        if (f.note(v.reasonKey) case final n?) n,
      for (final e in (r?.exclusions ?? const <String, num>{}).entries)
        if (exclusionText(l, e.key, e.value.round()) case final t?) t,
      if (def.id == 'QT-11' && status == ChartFrameStatus.data) ...[l.statsHealthClockNote, l.statsHealthElapsedNote],
    ];
    return _Card(
      child: ChartFrame(
        title: title,
        subtitle: periodText,
        data: chart,
        status: status,
        missing: v is Insufficient<double> ? v.missing : 0,
        headline: def.id == 'QT-11' ? _Disclaimer(text: l.statsHealthDisclaimer) : headline,
        footer: notes.where((n) => n != l.statsHealthDisclaimer).isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final n in notes)
                    if (n != l.statsHealthDisclaimer)
                      Text(n, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
              ),
        onExplain: explain,
        onTap: (tap) {
          final refs = tap.drillKey == null ? null : r?.drill[tap.drillKey];
          if (refs == null || refs.isEmpty) return;
          showDrillSheet(context, title: tap.label == null ? title : f.label(tap.label!), refs: refs);
        },
        onRef: (ref) => openDrillRef(context, ref),
        milestoneLabel: (label) => label is TextLabel
            ? (milestoneText(l, label.text.isEmpty ? label.text : label.text[0].toLowerCase() + label.text.substring(1)) ?? label.text)
            : f.label(label),
        sourceName: (id) => sourceName(l, id) ?? id,
        now: now,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsetsDirectional.all(Space.md), child: child),
  );
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.all(Space.sm),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(Radii.sm),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.health_and_safety_outlined, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: context.text.bodySmall)),
      ],
    ),
  );
}
