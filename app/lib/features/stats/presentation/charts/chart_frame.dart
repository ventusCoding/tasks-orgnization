/// Chart frame (T6.2.01): title, period subtitle, legend with series toggles, ⓘ (explain sheet),
/// "view as table" toggle, optional share action, and overlays for loading, empty, insufficient
/// ("Needs 4 more…") and error states. The chart itself is announced by its semantic summary.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_semantics.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_table.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/charts/chart_view.dart';
import 'package:material_ui/material_ui.dart';

/// What a frame shows.
enum ChartFrameStatus { data, loading, empty, insufficient, error }

class ChartFrame extends StatefulWidget {
  const ChartFrame({
    required this.title,
    super.key,
    this.subtitle,
    this.data,
    this.status = ChartFrameStatus.data,
    this.missing = 0,
    this.headline,
    this.footer,
    this.child,
    this.chartHeight = 200,
    this.onExplain,
    this.onShare,
    this.onTap,
    this.onRef,
    this.showLegend = true,
    this.milestoneLabel,
    this.sourceName,
    this.now,
  });

  final String title;
  final String? subtitle;

  /// The chart model (enables the table toggle, legend and semantic summary).
  final ChartData? data;
  final ChartFrameStatus status;

  /// Missing observations of the insufficient state.
  final num missing;

  /// Optional widget above the chart (headline value + delta).
  final Widget? headline;

  /// Optional widget below the chart (notes, exclusions).
  final Widget? footer;

  /// Custom body instead of [ChartView].
  final Widget? child;
  final double chartHeight;
  final VoidCallback? onExplain;
  final VoidCallback? onShare;
  final void Function(ChartTap tap)? onTap;
  final void Function(DrillRef ref)? onRef;
  final bool showLegend;
  final String Function(ChartLabel label)? milestoneLabel;
  final String Function(String id)? sourceName;
  final DateTime Function()? now;

  @override
  State<ChartFrame> createState() => _ChartFrameState();
}

class _ChartFrameState extends State<ChartFrame> {
  bool _table = false;
  final Set<int> _hidden = {};

  List<(ChartLabel, ChartColor)> _legend(ChartData data) => switch (data) {
    TimeSeriesData(:final series) when series.length > 1 => [for (final s in series) (s.label, s.color)],
    BarData(:final series) when series.length > 1 => [for (final s in series) (s.label, s.color)],
    StackedAreaData(:final bands) => [for (final s in bands) (s.label, s.color)],
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final data = widget.data;
    final canTable = data != null && widget.status == ChartFrameStatus.data && !data.isEmpty && widget.child == null;
    final legend = data == null || !widget.showLegend || _table ? const <(ChartLabel, ChartColor)>[] : _legend(data);
    final body = switch (widget.status) {
      ChartFrameStatus.loading => _Skeleton(height: widget.chartHeight),
      ChartFrameStatus.empty => _Message(icon: Icons.bar_chart_outlined, text: context.l10n.chartsEmpty),
      ChartFrameStatus.insufficient => _Message(
        icon: Icons.hourglass_empty,
        text: context.l10n.chartsNeedsMore(widget.missing.ceil()),
      ),
      ChartFrameStatus.error => _Message(icon: Icons.error_outline, text: context.l10n.chartsError),
      ChartFrameStatus.data =>
        widget.child ??
            (data == null
                ? const SizedBox.shrink()
                : data.isEmpty
                ? _Message(icon: Icons.bar_chart_outlined, text: context.l10n.chartsEmpty)
                : _table
                ? ChartDataTable(data.toTable())
                : Semantics(
                    container: true,
                    label: chartSummary(data, widget.title, f),
                    child: ChartView(
                      data,
                      height: widget.chartHeight,
                      onTap: widget.onTap,
                      onRef: widget.onRef,
                      hidden: _hidden,
                      milestoneLabel: widget.milestoneLabel,
                      sourceName: widget.sourceName,
                      now: widget.now,
                    ),
                  )),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(widget.title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!, style: context.text.labelSmall?.copyWith(color: theme.label)),
                ],
              ),
            ),
            if (widget.onExplain != null)
              IconButton(
                tooltip: context.l10n.chartsExplain,
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: widget.onExplain,
              ),
            if (canTable)
              IconButton(
                tooltip: _table ? context.l10n.chartsViewAsChart : context.l10n.chartsViewAsTable,
                icon: Icon(_table ? Icons.insert_chart_outlined : Icons.table_rows_outlined, size: 20),
                onPressed: () => setState(() => _table = !_table),
              ),
            if (widget.onShare != null && canTable)
              IconButton(
                tooltip: context.l10n.chartsShare,
                icon: const Icon(Icons.ios_share, size: 20),
                onPressed: widget.onShare,
              ),
          ],
        ),
        if (widget.headline != null) ...[const SizedBox(height: Space.xs), widget.headline!],
        const SizedBox(height: Space.sm),
        AnimatedSwitcher(
          duration: chartAnimation(context),
          child: KeyedSubtree(key: ValueKey(_table), child: body),
        ),
        if (legend.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (var i = 0; i < legend.length; i++)
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  avatar: ColorDot(theme.resolve(legend[i].$2)),
                  label: Text(f.label(legend[i].$1)),
                  selected: !_hidden.contains(i),
                  showCheckmark: false,
                  tooltip: context.l10n.chartsSeriesToggle(f.label(legend[i].$1)),
                  onSelected: (on) => setState(() => on ? _hidden.remove(i) : _hidden.add(i)),
                ),
            ],
          ),
        ],
        if (widget.footer != null) ...[const SizedBox(height: Space.sm), widget.footer!],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: Space.lg),
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.colors.outline),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        ),
      ],
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.chartsLoading,
    child: Container(
      height: height * 0.6,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
    ),
  );
}
