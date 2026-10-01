/// Scoped Insights screen (T6.1.17): `/insights/:scope[/:id][?period=…&occurrence=…]` for every
/// metric scope (task, series, planner, checklist, item, checklists, habit, habits, quit, global,
/// review) — each one only declares a layout; [StatsScopeView] renders it.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/glossary_screen.dart';
import 'package:everslot/features/stats/presentation/item_stats_panel.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:everslot/features/stats/presentation/task_stats_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final scope = route?.metricScope;
    if (route == null || scope == null || (scope.needsId && widget.scopeId == null) || !_supported(route)) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tabInsights)),
        body: EmptyState(icon: Icons.insights_outlined, title: l.statsUnknownScope, message: widget.scope),
      );
    }
    final id = widget.scopeId;
    final entity = id == null ? null : ref.watch(scopeEntityProvider((widget.scope, id))).value;
    final title = switch (route) {
      InsightsRoute.review => l.statsScopeReview,
      _ => entity?.name ?? scopeTitle(l, scope, isQuit: route == InsightsRoute.quit),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: switch (route) {
        InsightsRoute.task => TaskStatsPanel(taskId: id!, occurrenceKey: widget.query['occurrence'], showHeader: true),
        InsightsRoute.item => ItemStatsPanel(itemId: id!, showHeader: true),
        InsightsRoute.review => _WeeklyReview(current: widget.query['week'] == 'current'),
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
    InsightsRoute.review => true,
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
  );
}
