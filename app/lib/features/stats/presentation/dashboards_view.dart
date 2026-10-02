/// Custom dashboards (T6.7.16): a list of user dashboards and a dashboard composed of metric cards
/// from any scope, each with its own period and width; cards can be added, reordered, resized and
/// removed. Dashboards live in the synced `dashboards` table.
library;

import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/dashboards.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/dashboard.dart';
import 'package:everslot/features/stats/domain/scope_entity.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart' show scopeTitle;
import 'package:everslot/features/stats/presentation/widgets/metric_card.dart';
import 'package:everslot/features/stats/presentation/widgets/period_selector.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Scopes a dashboard card can come from (entity scopes other than quit need an entity picker of
/// their own and are opened from their screens instead).
const dashboardScopes = [
  MetricScope.global,
  MetricScope.planner,
  MetricScope.checklists,
  MetricScope.habits,
  MetricScope.quit,
];

/// Period keys offered for a card.
const dashboardPeriods = [
  'thisWeek',
  'lastWeek',
  'thisMonth',
  'lastMonth',
  'thisYear',
  'rolling:7',
  'rolling:30',
  'allTime',
];

StatsPeriod _periodOf(String key) => PeriodSelection.parsePeriod(key) ?? const StatsPeriod.thisWeek();

/// Dashboards list (route `/insights/dashboards`).
class DashboardsListView extends ConsumerWidget {
  const DashboardsListView({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final name = await promptText(context, title: l.statsDashboardNew, initial: l.statsDashboardDefaultName);
    if (name == null) return;
    final (id, _) = await ref.read(dashboardsRepositoryProvider).create(name);
    if (context.mounted) openInsights(context, 'dashboard', id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AsyncValueView<List<Dashboard>>(
      value: ref.watch(dashboardsProvider),
      data: (list) => ListView(
        padding: const EdgeInsetsDirectional.all(Space.lg),
        children: [
          if (list.isEmpty)
            EmptyState(
              icon: Icons.dashboard_customize_outlined,
              title: l.statsDashboardsEmpty,
              message: l.statsDashboardsEmptyBody,
            )
          else
            for (final d in list)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: Text(d.name),
                  subtitle: Text('${d.cards.length}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openInsights(context, 'dashboard', d.id),
                ),
              ),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: const ValueKey('dashboard-new'),
              onPressed: () => unawaited(_create(context, ref)),
              icon: const Icon(Icons.add),
              label: Text(l.statsDashboardNew),
            ),
          ),
        ],
      ),
    );
  }
}

/// One dashboard (route `/insights/dashboard/<id>`).
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({required this.id, super.key});

  final String id;

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  bool _editing = false;

  Future<void> _save(Dashboard d, List<DashboardCard> cards) =>
      ref.read(dashboardsRepositoryProvider).setCards(d.id, cards);

  Future<void> _menu(Dashboard d, String action) async {
    final l = context.l10n;
    final repo = ref.read(dashboardsRepositoryProvider);
    switch (action) {
      case 'rename':
        final name = await promptText(context, title: l.statsDashboardRename, initial: d.name);
        if (name != null) await repo.rename(d.id, name);
      case 'delete':
        final ok = await confirmDialog(context, title: l.statsDashboardDelete, destructive: true);
        if (!ok) return;
        final record = await repo.delete(d.id);
        if (!mounted) return;
        showUndoSnackBar(context, ref, message: l.statsDashboardDeleted, record: record);
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AsyncValueView<Dashboard?>(
      value: ref.watch(dashboardProvider(widget.id)),
      data: (d) {
        if (d == null) return EmptyState(icon: Icons.dashboard_outlined, title: l.statsDashboardsEmpty);
        final cards = d.cards;
        return ListView(
          padding: const EdgeInsetsDirectional.all(Space.lg),
          children: [
            Row(
              children: [
                Expanded(child: Text(d.name, style: context.text.titleLarge)),
                IconButton(
                  key: const ValueKey('dashboard-edit'),
                  tooltip: l.actionEdit,
                  isSelected: _editing,
                  icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
                PopupMenuButton<String>(
                  tooltip: l.actionMore,
                  onSelected: (v) => unawaited(_menu(d, v)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rename', child: Text(l.statsDashboardRename)),
                    PopupMenuItem(value: 'delete', child: Text(l.statsDashboardDelete)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            if (cards.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: Space.lg),
                child: Text(l.statsDashboardEmptyCards, style: context.text.bodyMedium),
              ),
            LayoutBuilder(
              builder: (context, c) {
                final half = c.maxWidth >= 600 ? (c.maxWidth - Space.sm) / 2 : c.maxWidth;
                return Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      SizedBox(
                        width: cards[i].span == 2 ? c.maxWidth : half,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_editing)
                              _CardControls(
                                card: cards[i],
                                index: i,
                                count: cards.length,
                                onChanged: (next) => unawaited(_save(d, next)),
                                cards: cards,
                              ),
                            _DashboardCardView(card: cards[i]),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: Space.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                key: const ValueKey('dashboard-add-card'),
                onPressed: () async {
                  final card = await showModalBottomSheet<DashboardCard>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const AddDashboardCardSheet(),
                  );
                  if (card != null) await _save(d, [...cards, card]);
                },
                icon: const Icon(Icons.add),
                label: Text(l.statsDashboardAddCard),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CardControls extends StatelessWidget {
  const _CardControls({
    required this.card,
    required this.index,
    required this.count,
    required this.cards,
    required this.onChanged,
  });

  final DashboardCard card;
  final int index;
  final int count;
  final List<DashboardCard> cards;
  final ValueChanged<List<DashboardCard>> onChanged;

  List<DashboardCard> _replace(DashboardCard next) => [
    for (var i = 0; i < cards.length; i++) i == index ? next : cards[i],
  ];

  List<DashboardCard> _move(int to) {
    final list = [...cards];
    final c = list.removeAt(index);
    list.insert(to, c);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: l.statsDashboardMoveUp,
          icon: const Icon(Icons.arrow_upward),
          onPressed: index == 0 ? null : () => onChanged(_move(index - 1)),
        ),
        IconButton(
          tooltip: l.statsDashboardMoveDown,
          icon: const Icon(Icons.arrow_downward),
          onPressed: index == count - 1 ? null : () => onChanged(_move(index + 1)),
        ),
        IconButton(
          tooltip: card.span == 2 ? l.statsDashboardNarrow : l.statsDashboardWide,
          icon: Icon(card.span == 2 ? Icons.view_column_outlined : Icons.view_stream_outlined),
          onPressed: () => onChanged(_replace(card.copyWith(span: card.span == 2 ? 1 : 2))),
        ),
        PopupMenuButton<String>(
          tooltip: l.statsDashboardPeriod,
          icon: const Icon(Icons.date_range),
          onSelected: (p) => onChanged(_replace(card.copyWith(period: p))),
          itemBuilder: (_) => [
            for (final p in dashboardPeriods)
              CheckedPopupMenuItem(value: p, checked: p == card.period, child: Text(periodLabel(l, _periodOf(p)))),
          ],
        ),
        IconButton(
          tooltip: l.statsDashboardRemoveCard,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onChanged([
            for (var i = 0; i < cards.length; i++)
              if (i != index) cards[i],
          ]),
        ),
      ],
    );
  }
}

class _DashboardCardView extends ConsumerWidget {
  const _DashboardCardView({required this.card});

  final DashboardCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final period = _periodOf(card.period);
    final request = StatsRequest(
      card.scope,
      scopeId: card.scopeId,
      selection: PeriodSelection(period),
      metricIds: {card.metricId},
    );
    final batch = ref.watch(metricsBatchProvider(request));
    return MetricCard(
      item: StatsLayoutItem(card.metricId),
      result: batch.value?[card.metricId],
      loading: batch.isLoading,
      periodText: '${scopeTitle(l, card.scope)} · ${periodLabel(l, period, locale: context.localeName)}',
    );
  }
}

/// Picks a scope (and tracker), a metric and a period for a new card.
class AddDashboardCardSheet extends ConsumerStatefulWidget {
  const AddDashboardCardSheet({super.key});

  @override
  ConsumerState<AddDashboardCardSheet> createState() => _AddDashboardCardSheetState();
}

class _AddDashboardCardSheetState extends ConsumerState<AddDashboardCardSheet> {
  MetricScope _scope = MetricScope.global;
  String? _scopeId;
  String? _metricId;
  String _period = 'thisWeek';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final registry = ref.watch(metricRegistryProvider);
    final metrics = [
      for (final d in registry.byScope(_scope))
        if (d.id != 'GL-19' && metricTitle(l, d.id) != null) d.id,
    ];
    final trackers = _scope == MetricScope.quit
        ? ref.watch(quitTrackersProvider).value ?? const <ScopeEntity>[]
        : const <ScopeEntity>[];
    final ready = _metricId != null && (_scope != MetricScope.quit || _scopeId != null);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          Space.lg,
          0,
          Space.lg,
          Space.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.statsDashboardAddCard, style: context.text.titleMedium),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<MetricScope>(
                key: const ValueKey('card-scope'),
                initialValue: _scope,
                decoration: InputDecoration(labelText: l.statsDashboardScope),
                items: [for (final s in dashboardScopes) DropdownMenuItem(value: s, child: Text(scopeTitle(l, s)))],
                onChanged: (s) => setState(() {
                  _scope = s ?? MetricScope.global;
                  _scopeId = null;
                  _metricId = null;
                }),
              ),
              if (_scope == MetricScope.quit) ...[
                const SizedBox(height: Space.sm),
                DropdownButtonFormField<String>(
                  initialValue: _scopeId,
                  decoration: InputDecoration(labelText: l.statsDashboardTracker),
                  items: [for (final t in trackers) DropdownMenuItem(value: t.id, child: Text(t.name))],
                  onChanged: (v) => setState(() => _scopeId = v),
                ),
              ],
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('card-metric-${_scope.name}'),
                initialValue: _metricId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.statsDashboardMetric),
                items: [
                  for (final id in metrics)
                    DropdownMenuItem(
                      value: id,
                      child: Text(metricTitle(l, id)!, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _metricId = v),
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: InputDecoration(labelText: l.statsDashboardPeriod),
                items: [
                  for (final p in dashboardPeriods)
                    DropdownMenuItem(value: p, child: Text(periodLabel(l, _periodOf(p)))),
                ],
                onChanged: (v) => setState(() => _period = v ?? 'thisWeek'),
              ),
              const SizedBox(height: Space.md),
              FilledButton(
                key: const ValueKey('card-add'),
                onPressed: ready
                    ? () => Navigator.of(context)
                          .pop(DashboardCard(metricId: _metricId!, scope: _scope, scopeId: _scopeId, period: _period))
                    : null,
                child: Text(l.statsDashboardAddCard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
