/// Insights tab root (T6.1.17): segments Overview · Plan · Lists · Habits · Quit. The last segment
/// and each scope's period are remembered on the device; scoped screens open through
/// `/insights/:scope/:id` deep links.
library;

import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/scope_entity.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/insights_feed_view.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Segments of the Insights tab (ids are stored in the local UI state).
enum InsightsSegment {
  overview,
  plan,
  lists,
  habits,
  quit;

  static InsightsSegment parse(String? id) =>
      InsightsSegment.values.firstWhere((s) => s.name == id, orElse: () => InsightsSegment.overview);
}

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: InsightsSegment.values.length,
    vsync: this,
    initialIndex: InsightsSegment.parse(ref.read(statsUiStateProvider).segment).index,
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      final segment = InsightsSegment.values[_tabs.index];
      if (ref.read(statsUiStateProvider).segment != segment.name) {
        ref.read(statsUiStateProvider.notifier).setSegment(segment.name);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // The remembered segment loads asynchronously from the device store.
    ref.listen(statsUiStateProvider.select((s) => s.segment), (_, next) {
      final index = InsightsSegment.parse(next).index;
      if (index != _tabs.index) _tabs.index = index;
    });
    final segment = InsightsSegment.values[_tabs.index];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabInsights),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l.statsSegmentOverview),
            Tab(text: l.statsSegmentPlan),
            Tab(text: l.statsSegmentLists),
            Tab(text: l.statsSegmentHabits),
            Tab(text: l.statsSegmentQuit),
          ],
        ),
      ),
      body: switch (segment) {
        InsightsSegment.overview => const _OverviewSegment(key: ValueKey('overview')),
        InsightsSegment.plan => const StatsScopeView(
          key: ValueKey('plan'),
          scope: MetricScope.planner,
          showFilters: true,
        ),
        InsightsSegment.lists => const StatsScopeView(
          key: ValueKey('lists'),
          scope: MetricScope.checklists,
          showFilters: true,
        ),
        InsightsSegment.habits => const StatsScopeView(key: ValueKey('habits'), scope: MetricScope.habits),
        InsightsSegment.quit => const _QuitSegment(key: ValueKey('quit')),
      },
    );
  }
}

/// Overview: today board, day score and week at a glance (T6.7.01/06) with the weekly review entry,
/// the latest insights (T6.7.08) and links to the other reports.
class _OverviewSegment extends StatelessWidget {
  const _OverviewSegment({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final links = <(String, IconData, String)>[
      ('month', Icons.calendar_month_outlined, l.statsScopeMonth),
      ('records', Icons.emoji_events_outlined, l.statsScopeRecords),
      ('goals', Icons.flag_outlined, l.statsScopeGoals),
      ('correlations', Icons.insights_outlined, l.statsScopePatterns),
      ('budget', Icons.hourglass_empty, l.statsScopeBudget),
      ('year', Icons.grid_on_outlined, l.statsScopeYear),
      ('feed', Icons.lightbulb_outline, l.statsScopeFeed),
      ('dashboards', Icons.dashboard_customize_outlined, l.statsScopeDashboards),
    ];
    return StatsScopeView(
      scope: MetricScope.global,
      header: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => openInsights(context, 'review'),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l.statsOverviewOpenReview),
                ),
                OutlinedButton.icon(
                  onPressed: () => openInsights(context, 'review-flow'),
                  icon: const Icon(Icons.checklist_rtl),
                  label: Text(l.statsOverviewStartGuided),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            const InsightsFeedPreview(),
            Semantics(header: true, child: Text(l.statsOverviewMore, style: context.text.titleSmall)),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final (route, icon, label) in links)
                  ActionChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    onPressed: () => openInsights(context, route),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quit: one tracker at a time, picked with chips.
class _QuitSegment extends ConsumerStatefulWidget {
  const _QuitSegment({super.key});

  @override
  ConsumerState<_QuitSegment> createState() => _QuitSegmentState();
}

class _QuitSegmentState extends ConsumerState<_QuitSegment> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final trackers = ref.watch(quitTrackersProvider);
    return AsyncValueView<List<ScopeEntity>>(
      value: trackers,
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(icon: Icons.smoke_free, title: l.statsEmptyQuit, message: l.statsEmptyQuitBody);
        }
        final current = list.firstWhere((t) => t.id == _selected, orElse: () => list.first);
        return StatsScopeView(
          key: ValueKey('quit/${current.id}'),
          scope: MetricScope.quit,
          scopeId: current.id,
          entity: current,
          header: list.length < 2
              ? null
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
                  child: Row(
                    children: [
                      for (final t in list)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: Space.xs),
                          child: ChoiceChip(
                            label: Text(t.name),
                            selected: t.id == current.id,
                            onSelected: (_) => setState(() => _selected = t.id),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
