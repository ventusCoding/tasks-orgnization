/// The stats screen framework (T6.1.16): every Insights scope renders a [StatsLayout] through this
/// scaffold — scope header, period selector with compare toggle, optional category/tag filters, a
/// KPI row and collapsible sections of metric cards in a responsive grid (1 column on phones, 2 on
/// tablets). One batch computes every card; while a new period computes, the previous numbers stay
/// visible under a thin progress bar so the switch lands in one frame.
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/scope_entity.dart' show ScopeEntity;
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/kpi_tile.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/widgets/explain_sheet.dart';
import 'package:everslot/features/stats/presentation/widgets/metric_card.dart';
import 'package:everslot/features/stats/presentation/widgets/period_selector.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:everslot/shared/filters/presentation/filter_bar.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Key of the remembered period/compare state and of the layout customization of [scope].
String statsScopeKey(MetricScope scope) => scope.name;

/// The layout of [scope] with the user's customization (T6.1.22) applied.
StatsLayout effectiveLayout(MetricScope scope, Map<String, Map<String, Object?>> layouts, {StatsLayout? base}) {
  final layout = base ?? defaultLayoutOf(scope);
  final custom = layouts[statsScopeKey(scope)];
  if (custom == null) return layout;
  List<String> strings(Object? v) => [
    if (v is List)
      for (final e in v)
        if (e is String) e,
  ];
  return layout.customized(
    order: strings(custom['order']),
    hidden: strings(custom['hidden']).toSet(),
    pinned: strings(custom['pinned']),
  );
}

class StatsScopeView extends ConsumerStatefulWidget {
  const StatsScopeView({
    required this.scope,
    super.key,
    this.scopeId,
    this.layout,
    this.entity,
    this.showFilters = false,
    this.extra,
    this.header,
    this.defaultPeriod,
    this.showPeriod = true,
  });

  final MetricScope scope;
  final String? scopeId;

  /// Layout override (defaults to the scope's layout with the user's customization).
  final StatsLayout? layout;

  /// Header entity (name, color, icon) of an entity scope.
  final ScopeEntity? entity;

  /// Category / tag / priority filters (section screens).
  final bool showFilters;

  /// Scope-specific request extra (task scope: occurrence key).
  final String? extra;

  /// Extra widget under the header (e.g. a quit tracker picker).
  final Widget? header;

  /// Period used when nothing is remembered for this scope (else `stats.defaultPeriod`).
  final StatsPeriod? defaultPeriod;

  /// Per-entity lifetime scopes (one occurrence, one item) hide the period selector.
  final bool showPeriod;

  @override
  ConsumerState<StatsScopeView> createState() => _StatsScopeViewState();
}

class _StatsScopeViewState extends ConsumerState<StatsScopeView> {
  EntityFilter _filter = EntityFilter.empty;
  final Set<String> _toggled = {};
  StatsBatch? _last;

  /// The filter bar's "status" criterion carries the planner tracking modes.
  StatsFilters get _filters => StatsFilters(
    categoryIds: _filter.categoryIds,
    tagIds: _filter.tagIds,
    priorities: _filter.priorities,
    trackingModes: widget.scope == MetricScope.planner ? _filter.statuses : const {},
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final settings = ref.watch(statsSettingsProvider);
    ref.watch(statsUiStateProvider);
    final ui = ref.read(statsUiStateProvider.notifier);
    final key = statsScopeKey(widget.scope);
    final selection = ui.selectionFor(key, settings, fallback: widget.defaultPeriod);
    final layout = effectiveLayout(widget.scope, settings.layouts, base: widget.layout);
    final request = StatsRequest(
      widget.scope,
      scopeId: widget.scopeId,
      selection: selection,
      filters: widget.showFilters ? _filters : StatsFilters.none,
      metricIds: layout.metricIds,
      extra: widget.extra,
    );
    final batch = ref.watch(metricsBatchProvider(request));
    if (batch.value case final value?) _last = value;
    final results = batch.value?.results ?? _last?.results ?? const <String, MetricResult>{};
    final loading = batch.isLoading;
    // Per-entity lifetime scopes have no period, so cards carry no period subtitle.
    final periodText = widget.showPeriod ? periodLabel(l, selection.period, locale: context.localeName) : null;

    void setSelection(PeriodSelection next) {
      if (next.period.key != selection.period.key) ui.setPeriod(key, next.period);
      if (next.compare != selection.compare) ui.setCompare(key, next.compare);
    }

    final slivers = <Widget>[
      if (widget.entity != null) SliverToBoxAdapter(child: _ScopeHeader(entity: widget.entity!, scope: widget.scope)),
      if (widget.header != null) SliverToBoxAdapter(child: widget.header),
      if (widget.showPeriod)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.sm),
            child: PeriodSelector(selection: selection, onChanged: setSelection),
          ),
        ),
      if (widget.showFilters)
        SliverToBoxAdapter(
          child: FilterBar(
            value: _filter,
            fields: [
              FilterField.category,
              FilterField.tag,
              FilterField.priority,
              if (widget.scope == MetricScope.planner) FilterField.status,
            ],
            statusOptions: [
              if (widget.scope == MetricScope.planner) ...[
                FilterOption('check', l.statsFilterTrackingCheck, icon: Icons.check_circle_outline),
                FilterOption('event', l.statsFilterTrackingEvent, icon: Icons.event_outlined),
                FilterOption('timer', l.statsFilterTrackingTimer, icon: Icons.timer_outlined),
              ],
            ],
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 3,
          child: loading && results.isNotEmpty
              ? LinearProgressIndicator(semanticsLabel: l.statsLoading, minHeight: 3)
              : null,
        ),
      ),
      if (batch.hasError && results.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            error: batch.error,
            onRetry: () => ref.invalidate(metricsBatchProvider(request)),
          ),
        )
      else ...[
        if (layout.kpis.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            sliver: SliverToBoxAdapter(
              child: _KpiRow(ids: layout.kpis, results: results, loading: loading, periodText: periodText),
            ),
          ),
        if (!loading && results.isNotEmpty && _allEmpty(results))
          SliverToBoxAdapter(child: _EmptyBanner(scope: widget.scope)),
        for (final section in layout.sections) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(
              id: section.id,
              collapsed: _collapsed(section),
              onToggle: () => setState(() => _toggled.contains(section.id) ? _toggled.remove(section.id) : _toggled.add(section.id)),
            ),
          ),
          if (!_collapsed(section))
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              sliver: SliverToBoxAdapter(
                child: _CardGrid(items: section.items, results: results, loading: loading, periodText: periodText),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
      ],
    ];

    return ChartPrefs(
      use24h: prefs.use24h,
      arabicDigits: prefs.useArabicDigits,
      weekStart: settings.weekStartOverride ?? prefs.weekStart,
      dayStartMinutes: prefs.dayStartMinutes,
      child: CustomScrollView(slivers: slivers),
    );
  }

  bool _collapsed(StatsLayoutSection s) => s.collapsedByDefault != _toggled.contains(s.id);

  /// True when no card has anything to show (fresh install, empty scope).
  static bool _allEmpty(Map<String, MetricResult> results) => results.values.every(
    (r) => r.value is! Value<double> && (r.chart == null || r.chart!.isEmpty) && r.note != 'error',
  );
}

class _ScopeHeader extends StatelessWidget {
  const _ScopeHeader({required this.entity, required this.scope});

  final ScopeEntity entity;
  final MetricScope scope;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = entity.color == null ? null : CategoryColors.accent(entity.color!, Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
      child: Row(
        children: [
          if (entity.icon != null)
            Icon(IconCatalog.iconFor(entity.icon), color: color ?? context.colors.primary)
          else
            ColorDot(color ?? context.colors.primary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entity.name, style: context.text.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  scopeTitle(l, scope, isQuit: entity.isQuit),
                  style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized name of a metric scope.
String scopeTitle(AppLocalizations l, MetricScope scope, {bool isQuit = false}) => switch (scope) {
  MetricScope.task => l.statsScopeTask,
  MetricScope.series => l.statsScopeSeries,
  MetricScope.planner => l.statsScopePlanner,
  MetricScope.checklistItem => l.statsScopeItem,
  MetricScope.checklist => l.statsScopeChecklist,
  MetricScope.checklists => l.statsScopeChecklists,
  MetricScope.habit => isQuit ? l.statsScopeQuit : l.statsScopeHabit,
  MetricScope.habits => l.statsScopeHabits,
  MetricScope.quit => l.statsScopeQuit,
  MetricScope.global => l.statsScopeGlobal,
};

class _KpiRow extends ConsumerWidget {
  const _KpiRow({required this.ids, required this.results, required this.loading, required this.periodText});

  final List<String> ids;
  final Map<String, MetricResult> results;
  final bool loading;
  final String? periodText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(metricRegistryProvider);
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= WindowSizeClass.mediumMinWidth ? 4 : 2;
        final width = (c.maxWidth - Space.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final id in ids)
              if (registry.byId(id) case final def?)
                SizedBox(
                  width: width,
                  child: results[id] == null
                      ? _KpiSkeleton(title: metricTitle(l, id) ?? id, loading: loading)
                      : KpiTile(
                          title: metricTitle(l, id) ?? id,
                          result: results[id]!,
                          direction: def.direction,
                          minSample: def.minSample,
                          size: KpiSize.compact,
                          onTap: () => showExplainSheet(context, def: def, result: results[id], periodText: periodText),
                        ),
                ),
          ],
        );
      },
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton({required this.title, required this.loading});

  final String title;
  final bool loading;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsetsDirectional.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Space.sm),
          Container(
            height: 24,
            width: 64,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(alpha: loading ? 0.8 : 0.4),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.id, required this.collapsed, required this.onToggle});

  final String id;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = sectionText(l, id) ?? id;
    return SectionHeader(
      title,
      trailing: IconButton(
        tooltip: collapsed ? l.statsSectionExpand(title) : l.statsSectionCollapse(title),
        icon: Icon(collapsed ? Icons.expand_more : Icons.expand_less),
        onPressed: onToggle,
      ),
    );
  }
}

/// Responsive grid: 1 column on phones, 2 on tablets; half-span KPI cards pair up everywhere.
class _CardGrid extends ConsumerWidget {
  const _CardGrid({required this.items, required this.results, required this.loading, required this.periodText});

  final List<StatsLayoutItem> items;
  final Map<String, MetricResult> results;
  final bool loading;
  final String? periodText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(metricRegistryProvider);
    bool compact(StatsLayoutItem i) {
      final chart = registry.byId(i.metricId)?.chart;
      return chart == ChartKind.kpi || chart == ChartKind.counter;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final twoColumns = c.maxWidth >= WindowSizeClass.mediumMinWidth;
        final rows = <Widget>[];
        var i = 0;
        while (i < items.length) {
          final a = items[i];
          final b = i + 1 < items.length ? items[i + 1] : null;
          final pair =
              b != null &&
              a.span == CardSpan.half &&
              b.span == CardSpan.half &&
              (twoColumns || (compact(a) && compact(b)));
          Widget card(StatsLayoutItem item) => MetricCard(
            item: item,
            result: results[item.metricId],
            loading: loading,
            periodText: periodText,
          );
          rows.add(
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
              child: pair
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: card(a)),
                        const SizedBox(width: Space.sm),
                        Expanded(child: card(b)),
                      ],
                    )
                  : card(a),
            ),
          );
          i += pair ? 2 : 1;
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      },
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.scope});

  final MetricScope scope;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final message = switch (scope) {
      MetricScope.planner || MetricScope.task || MetricScope.series => l.statsEmptyPlanner,
      MetricScope.checklists || MetricScope.checklist || MetricScope.checklistItem => l.statsEmptyLists,
      MetricScope.habits || MetricScope.habit => l.statsEmptyHabits,
      MetricScope.quit => l.statsEmptyQuitBody,
      MetricScope.global => l.statsEmptyPlanner,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: Text(l.statsEmptyTitle),
          subtitle: Text(message),
        ),
      ),
    );
  }
}
