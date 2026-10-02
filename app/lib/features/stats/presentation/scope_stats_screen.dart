/// Scoped Insights screen (T6.1.17): `/insights/:scope[/:id][?period=…&occurrence=…]` for every
/// metric scope (task, series, planner, checklist, item, checklists, habit, habits, quit, global,
/// review) — each one only declares a layout; [StatsScopeView] renders it.
library;

import 'dart:async';

import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/dashboards_view.dart';
import 'package:everslot/features/stats/presentation/glossary_screen.dart';
import 'package:everslot/features/stats/presentation/guided_review_screen.dart';
import 'package:everslot/features/stats/presentation/insights_feed_view.dart';
import 'package:everslot/features/stats/presentation/item_stats_panel.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:everslot/features/stats/presentation/task_stats_panel.dart';
import 'package:everslot/features/stats/presentation/wrapped_screen.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class ScopeStatsScreen extends ConsumerStatefulWidget {
  const ScopeStatsScreen({required this.scope, this.scopeId, super.key, this.query = const {}});

  /// Route segment (`habit`, `planner`, `review`…; `overview` = `global`).
  final String scope;
  final String? scopeId;

  /// Query parameters: `period` (a period key such as `rolling:30`), `occurrence` (task scope).
  final Map<String, String> query;

  @override
  ConsumerState<ScopeStatsScreen> createState() => _ScopeStatsScreenState();
}

class _ScopeStatsScreenState extends ConsumerState<ScopeStatsScreen> {
  @override
  void initState() {
    super.initState();
    // A deep link's period becomes the remembered period of the scope.
    final period = PeriodSelection.parsePeriod(widget.query['period']);
    final scope = InsightsRoute.parse(widget.scope)?.metricScope;
    if (period != null && scope != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(statsUiStateProvider.notifier).setPeriod(statsScopeKey(scope), period);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final route = InsightsRoute.parse(widget.scope);
    if (route == InsightsRoute.glossary) return GlossaryScreen(initialQuery: widget.query['q']);
    final scope =
        route?.metricScope ??
        (route == InsightsRoute.dashboards || route == InsightsRoute.dashboard ? MetricScope.global : null);
    if (route == null ||
        scope == null ||
        (scope.needsId && widget.scopeId == null) ||
        (route == InsightsRoute.dashboard && widget.scopeId == null) ||
        !_supported(route)) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tabInsights)),
        body: EmptyState(icon: Icons.insights_outlined, title: l.statsUnknownScope, message: widget.scope),
      );
    }
    final id = widget.scopeId;
    final entity = id == null ? null : ref.watch(scopeEntityProvider((widget.scope, id))).value;
    final year = int.tryParse(widget.query['year'] ?? '');
    final title = switch (route) {
      InsightsRoute.review => l.statsScopeReview,
      InsightsRoute.month => l.statsScopeMonth,
      InsightsRoute.reviewFlow => l.statsScopeGuided,
      InsightsRoute.records => l.statsScopeRecords,
      InsightsRoute.goals => l.statsScopeGoals,
      InsightsRoute.correlations => l.statsScopePatterns,
      InsightsRoute.budget => l.statsScopeBudget,
      InsightsRoute.year => l.statsScopeYear,
      InsightsRoute.wrapped => l.statsScopeWrapped,
      InsightsRoute.feed => l.statsScopeFeed,
      InsightsRoute.dashboards || InsightsRoute.dashboard => l.statsScopeDashboards,
      InsightsRoute.quality => l.statsSectionDataQuality,
      _ => entity?.name ?? scopeTitle(l, scope, isQuit: route == InsightsRoute.quit),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: switch (route) {
        InsightsRoute.task => TaskStatsPanel(taskId: id!, occurrenceKey: widget.query['occurrence'], showHeader: true),
        InsightsRoute.item => ItemStatsPanel(itemId: id!, showHeader: true),
        InsightsRoute.review => _WeeklyReview(current: widget.query['week'] == 'current'),
        InsightsRoute.month => _MonthlyReview(current: widget.query['month'] == 'current'),
        InsightsRoute.reviewFlow => const GuidedReviewScreen(),
        InsightsRoute.feed => const InsightsFeedView(),
        InsightsRoute.wrapped => WrappedView(year: year),
        InsightsRoute.records => const StatsScopeView(
          key: ValueKey('records'),
          scope: MetricScope.global,
          layout: recordsLayout,
          showPeriod: false,
        ),
        InsightsRoute.goals => const StatsScopeView(
          key: ValueKey('goals'),
          scope: MetricScope.global,
          layout: goalsLayout,
          showPeriod: false,
        ),
        InsightsRoute.correlations => const StatsScopeView(
          key: ValueKey('patterns'),
          scope: MetricScope.global,
          layout: patternsLayout,
          showPeriod: false,
        ),
        InsightsRoute.quality => const StatsScopeView(
          key: ValueKey('quality'),
          scope: MetricScope.global,
          layout: StatsLayout(
            MetricScope.global,
            sections: [
              StatsLayoutSection('dataQuality', [StatsLayoutItem('GL-10')]),
            ],
          ),
          showPeriod: false,
        ),
        InsightsRoute.budget => const StatsScopeView(
          key: ValueKey('budget'),
          scope: MetricScope.global,
          layout: budgetLayout,
          defaultPeriod: StatsPeriod.rolling(30),
        ),
        InsightsRoute.year => StatsScopeView(
          key: ValueKey('year/$year'),
          scope: MetricScope.global,
          layout: yearLayout,
          showPeriod: false,
          extra: year?.toString(),
          header: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                key: const ValueKey('open-wrapped'),
                onPressed: () => unawaited(
                  context.push(
                    year == null
                        ? AppLinks.insightsScope('wrapped')
                        : '${AppLinks.insightsScope('wrapped')}?year=$year',
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(l.statsWrappedOpen),
              ),
            ),
          ),
        ),
        InsightsRoute.dashboards => const DashboardsListView(),
        InsightsRoute.dashboard => DashboardView(id: id!),
        _ => StatsScopeView(
          key: ValueKey('${widget.scope}/$id'),
          scope: scope,
          scopeId: id,
          entity: entity,
          showFilters: scope == MetricScope.planner || scope == MetricScope.checklists,
        ),
      },
    );
  }

  /// Routes whose screens exist (later milestones add the rest).
  static bool _supported(InsightsRoute r) => switch (r) {
    InsightsRoute.overview ||
    InsightsRoute.planner ||
    InsightsRoute.series ||
    InsightsRoute.task ||
    InsightsRoute.checklists ||
    InsightsRoute.checklist ||
    InsightsRoute.item ||
    InsightsRoute.habits ||
    InsightsRoute.habit ||
    InsightsRoute.quit ||
    InsightsRoute.review ||
    InsightsRoute.month ||
    InsightsRoute.reviewFlow ||
    InsightsRoute.wrapped ||
    InsightsRoute.year ||
    InsightsRoute.feed ||
    InsightsRoute.goals ||
    InsightsRoute.records ||
    InsightsRoute.quality ||
    InsightsRoute.correlations ||
    InsightsRoute.budget ||
    InsightsRoute.dashboards ||
    InsightsRoute.dashboard => true,
    _ => false,
  };
}

/// Weekly review (T6.7.02): the last completed week by default, or this week so far.
class _WeeklyReview extends StatefulWidget {
  const _WeeklyReview({required this.current});

  final bool current;

  @override
  State<_WeeklyReview> createState() => _WeeklyReviewState();
}

class _WeeklyReviewState extends State<_WeeklyReview> {
  late bool _current = widget.current;

  @override
  Widget build(BuildContext context) => StatsScopeView(
    key: ValueKey('review/$_current'),
    scope: MetricScope.global,
    layout: reviewLayout,
    showPeriod: false,
    extra: _current ? 'current' : null,
    onReviewToggle: (current) => setState(() => _current = current),
    header: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton.tonalIcon(
          key: const ValueKey('start-guided'),
          onPressed: () => openInsights(context, 'review-flow'),
          icon: const Icon(Icons.checklist_rtl),
          label: Text(context.l10n.statsOverviewStartGuided),
        ),
      ),
    ),
  );
}

/// Monthly review (T6.7.04): the last completed month by default, or this month so far.
class _MonthlyReview extends StatefulWidget {
  const _MonthlyReview({required this.current});

  final bool current;

  @override
  State<_MonthlyReview> createState() => _MonthlyReviewState();
}

class _MonthlyReviewState extends State<_MonthlyReview> {
  late bool _current = widget.current;

  @override
  Widget build(BuildContext context) => StatsScopeView(
    key: ValueKey('month/$_current'),
    scope: MetricScope.global,
    layout: monthLayout,
    showPeriod: false,
    extra: _current ? 'current' : null,
    onReviewToggle: (current) => setState(() => _current = current),
  );
}
