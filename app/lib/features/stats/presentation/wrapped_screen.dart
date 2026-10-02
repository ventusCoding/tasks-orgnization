/// Year in review — "Wrapped" (T6.7.14): GL-14 story cards (year in numbers, busiest times, top
/// categories, longest streaks, deep work, quit journey, records broken, year over year, your
/// style) as pages, plus a shareable summary card ("Hide names" in the share sheet). Computed on
/// the device; offered from December 15 to January 31 for the closing year, any time for past
/// years (`?year=YYYY`).
library;

import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_share.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_view.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class WrappedView extends ConsumerStatefulWidget {
  const WrappedView({super.key, this.year});

  /// Year to show (null = the closing year in Dec 15 – Jan 31, else the current one).
  final int? year;

  @override
  ConsumerState<WrappedView> createState() => _WrappedViewState();
}

class _WrappedViewState extends ConsumerState<WrappedView> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      unawaited(_pages.animateToPage(page, duration: Motion.normal, curve: Motion.curve));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final request = StatsRequest(
      MetricScope.global,
      selection: const PeriodSelection(StatsPeriod.thisYear(), compare: false),
      metricIds: const {'GL-14'},
      extra: widget.year?.toString(),
    );
    final batch = ref.watch(metricsBatchProvider(request));
    final r = batch.value?['GL-14'];
    if (r == null) {
      return batch.hasError
          ? ErrorState(error: batch.error, onRetry: () => ref.invalidate(metricsBatchProvider(request)))
          : const Center(child: CircularProgressIndicator());
    }
    final group = r.chart;
    final year = (r.args['year'] as num?)?.toInt() ?? widget.year ?? DateTime.now().year;
    final cards = group is ChartGroup
        ? group.charts.where((c) => !c.$2.isEmpty).toList()
        : const <(ChartLabel, ChartData)>[];
    if (cards.isEmpty) {
      return EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: l.statsWrappedTitle(year),
        message: l.statsWrappedEmpty,
      );
    }
    final page = _page.clamp(0, cards.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: Text(l.statsWrappedTitle(year), style: context.text.headlineSmall),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: cards.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsetsDirectional.all(Space.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(Space.lg),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text(f.label(cards[i].$1), style: context.text.titleLarge)),
                        const SizedBox(height: Space.md),
                        ChartView(cards[i].$2, height: 260),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, 0, Space.sm, Space.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: l.statsWrappedPrevious,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: page == 0 ? null : () => _goTo(page - 1),
                ),
                Expanded(
                  child: Text(
                    '${page + 1} / ${cards.length}',
                    textAlign: TextAlign.center,
                    style: context.text.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: l.statsWrappedNext,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: page >= cards.length - 1 ? null : () => _goTo(page + 1),
                ),
                const SizedBox(width: Space.sm),
                FilledButton.tonalIcon(
                  key: const ValueKey('wrapped-share'),
                  onPressed: () =>
                      unawaited(showChartShareSheet(context, title: l.statsWrappedTitle(year), data: cards.first.$2)),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l.statsWrappedShare),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
