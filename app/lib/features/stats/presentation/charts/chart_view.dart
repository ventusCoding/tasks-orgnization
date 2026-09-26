/// Dispatches a [ChartData] model to its widget (screens never talk to `fl_chart` directly).
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/bars_chart.dart';
import 'package:everslot/features/stats/presentation/charts/calendar_heatmap.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_table.dart';
import 'package:everslot/features/stats/presentation/charts/composition_charts.dart';
import 'package:everslot/features/stats/presentation/charts/pattern_charts.dart';
import 'package:everslot/features/stats/presentation/charts/progress_visuals.dart';
import 'package:everslot/features/stats/presentation/charts/simple_views.dart';
import 'package:everslot/features/stats/presentation/charts/time_series_chart.dart';
import 'package:material_ui/material_ui.dart';

class ChartView extends StatelessWidget {
  const ChartView(
    this.data, {
    super.key,
    this.height = 200,
    this.onTap,
    this.onRef,
    this.hidden = const {},
    this.milestoneLabel,
    this.sourceName,
    this.now,
  });

  final ChartData data;
  final double height;
  final void Function(ChartTap tap)? onTap;

  /// Direct entity taps (list rows, milestones).
  final void Function(DrillRef ref)? onRef;

  /// Hidden series (legend toggles).
  final Set<int> hidden;
  final String Function(ChartLabel label)? milestoneLabel;
  final String Function(String id)? sourceName;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: switch (data) {
      final TimeSeriesData d => TimeSeriesChart(d, height: height, onTap: onTap, hidden: hidden),
      final BarData d => BarsChart(d, height: height, onTap: onTap, hidden: hidden),
      final DonutData d => DonutChart(d, height: height * 0.9, onTap: onTap),
      final ParetoData d => ParetoChart(d, height: height, onTap: onTap),
      final CalendarData d => CalendarHeatmap(d, onTap: onTap),
      final PunchCardData d => PunchCardChart(d, onTap: onTap),
      final StreakData d => StreakChart(d, onTap: onTap),
      final RingData d => Center(child: ProgressRings(d, size: height * 0.6)),
      final BulletData d => BulletChart(d),
      final MilestoneData d => MilestoneBars(d, labelOf: milestoneLabel, sourceName: sourceName, now: now),
      final CounterData d => LiveCounter(since: d.since, now: now),
      final TilesData d => ValueTilesView(d, onTap: onTap),
      final ListData d => RankedList(d, onRef: onRef),
      final StatusTimelineData d => StatusTimelineBar(d),
      final ChartGroup d => ChartGroupView(d, height: height, onTap: onTap, onRef: onRef),
      // Charts of later milestones fall back to their exact table until their painter lands.
      _ => ChartDataTable(data.toTable()),
    },
  );
}

/// Tabs over related charts (e.g. craving Pareto by trigger / place / mood + punch card).
class ChartGroupView extends StatefulWidget {
  const ChartGroupView(this.group, {super.key, this.height = 200, this.onTap, this.onRef});

  final ChartGroup group;
  final double height;
  final void Function(ChartTap tap)? onTap;
  final void Function(DrillRef ref)? onRef;

  @override
  State<ChartGroupView> createState() => _ChartGroupViewState();
}

class _ChartGroupViewState extends State<ChartGroupView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final f = statFormatOf(context);
    final charts = widget.group.charts;
    final index = _index.clamp(0, charts.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < charts.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: ChoiceChip(
                    label: Text(f.label(charts[i].$1)),
                    selected: i == index,
                    onSelected: (_) => setState(() => _index = i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        if (charts[index].$2.isEmpty)
          Padding(padding: const EdgeInsets.all(Space.lg), child: Text(context.l10n.chartsEmpty))
        else
          ChartView(charts[index].$2, height: widget.height, onTap: widget.onTap, onRef: widget.onRef),
      ],
    );
  }
}
