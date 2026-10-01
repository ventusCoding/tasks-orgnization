import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Kanban grouping (`options.groupBy`).
enum KanbanGroup {
  status,
  category,
  priority,
  day;

  static KanbanGroup parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => status);
}

/// Status columns: planned (scheduled and missed), in progress, done, skipped.
const kanbanStatuses = [
  OccurrenceStatus.scheduled,
  OccurrenceStatus.inProgress,
  OccurrenceStatus.done,
  OccurrenceStatus.skipped,
];

/// Column key of [item] for [group]: status name, category id ('' = none), priority, ISO day.
String kanbanKey(PlannerItem item, KanbanGroup group) => switch (group) {
  KanbanGroup.status => (item.status == OccurrenceStatus.missed ? OccurrenceStatus.scheduled : item.status).name,
  KanbanGroup.category => item.categoryId ?? '',
  KanbanGroup.priority => '${item.priority}',
  KanbanGroup.day => item.startLocal.date.toIso(),
};

/// Column keys in display order.
List<String> kanbanColumns(KanbanGroup group, {required List<String> categoryIds, required List<LocalDate> days}) =>
    switch (group) {
      KanbanGroup.status => [for (final s in kanbanStatuses) s.name],
      KanbanGroup.category => [...categoryIds, ''],
      KanbanGroup.priority => ['4', '3', '2', '1', '0'],
      KanbanGroup.day => [for (final d in days) d.toIso()],
    };

/// Kanban board (T3.7.08): occurrences of a date range (`options.rangeDays`) in columns by status,
/// category, priority or day (`options.groupBy`), each with its count. Dragging a card to another
/// column changes the matching field: status → occurrence action; category / priority → task
/// update (scope dialog for series); day → reschedule (keeps the time).
class KanbanView extends ConsumerStatefulWidget {
  const KanbanView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends ConsumerState<KanbanView> {
  late LocalDate _start;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _start =
        widget.args.date ??
        ref.read(plannerAnchorProvider) ??
        ref.read(plannerViewStateProvider(_key))?.anchor ??
        ref.read<LocalDate>(plannerTodayProvider);
  }

  void _go(LocalDate d) {
    setState(() => _start = d);
    ref.read(plannerAnchorProvider.notifier).set(d);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: d));
  }

  Future<void> _pick() async {
    final weekStart = ref.read(userPreferencesProvider).weekStart;
    final picked = await showMiniMonth(context, initial: _start, weekStart: weekStart, highlight: [_start]);
    if (picked != null) _go(picked);
  }

  /// Moves [item] into column [key] of [group] (one undoable command).
  Future<void> _drop(PlannerItem item, KanbanGroup group, String key) async {
    if (kanbanKey(item, group) == key) return;
    final l = context.l10n;
    final commands = PlannerCommands(context, ref);
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    Future<void> fields(BacklogEdit edit) async {
      final scope = await commands.askScope(item);
      if (scope == null || !mounted) return;
      await commands.runExtra(l.tasksUpdated, (a) => a.editFields(item, edit, scope: scope));
    }

    switch (group) {
      case KanbanGroup.status:
        await commands.setStatus(item, OccurrenceStatus.values.byName(key));
      case KanbanGroup.category:
        await fields(key.isEmpty ? const BacklogEdit(clearCategory: true) : BacklogEdit(categoryId: key));
      case KanbanGroup.priority:
        await fields(BacklogEdit(priority: int.parse(key)));
      case KanbanGroup.day:
        final day = LocalDate.parse(key);
        await commands.reschedule(
          item,
          start: item.allDay ? day.atStartOfDay : day.atTime(item.startLocal.time),
          message: l.pvMovedSnack(f.dayShort(day)),
        );
    }
  }

  String _label(KanbanGroup group, String key, Map<String, Category> categories, AppFormat f) {
    final l = context.l10n;
    return switch (group) {
      KanbanGroup.status => context.statusLabel(OccurrenceStatus.values.byName(key)),
      KanbanGroup.category => key.isEmpty ? l.pvNoCategory : (categories[key]?.name ?? l.pvNoCategory),
      KanbanGroup.priority => PriorityStyle.label(context, int.parse(key)),
      KanbanGroup.day => f.dayLong(LocalDate.parse(key)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final group = KanbanGroup.parse(config.option<String>('groupBy', 'status'));
    final days = config.option<int>('rangeDays', 7).clamp(1, 31);
    final range = DayRange(_start, days);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final byId = {for (final c in categories) c.id: c};
    final items = filteredItems(ref, range, config).value ?? const <PlannerItem>[];
    final columns = kanbanColumns(
      group,
      categoryIds: [for (final c in categories) c.id],
      days: [for (var i = 0; i < days; i++) _start.plusDays(i)],
    );
    final byColumn = <String, List<PlannerItem>>{for (final c in columns) c: []};
    for (final i in dayListOrder(items)) {
      if (i.isQuotaSlot && i.allDay) continue;
      byColumn[kanbanKey(i, group)]?.add(i);
    }
    final colors = viewColors(context, ref, config);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: rangeTitle(locale, _start, _start.plusDays(days - 1)),
        onPrevious: () => _go(_start.plusDays(-days)),
        onNext: () => _go(_start.plusDays(days)),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<KanbanGroup>(
            key: const Key('kanban-group'),
            tooltip: l.pvGroupBy,
            icon: const Icon(Icons.view_kanban_outlined),
            onSelected: (g) => notifier.change((c) => c.withOption('groupBy', g.name)),
            itemBuilder: (_) => [
              for (final (g, label) in [
                (KanbanGroup.status, l.pvGroupStatus),
                (KanbanGroup.category, l.pvGroupCategory),
                (KanbanGroup.priority, l.pvGroupPriority),
                (KanbanGroup.day, l.pvGroupDay),
              ])
                CheckedPopupMenuItem(value: g, checked: g == group, child: Text(label)),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(_start.plusDays(-days)),
        onNext: () => _go(_start.plusDays(days)),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: ListView(
                key: const Key('kanban-board'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(Space.sm),
                children: [
                  for (final key in columns)
                    _KanbanColumn(
                      key: ValueKey('kanban-col-$key'),
                      viewKey: _key,
                      title: _label(group, key, byId, f),
                      items: byColumn[key]!,
                      colors: colors,
                      onDrop: (item) => unawaited(_drop(item, group, key)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(today, ref.read(plannerNowProvider))),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.viewKey,
    required this.title,
    required this.items,
    required this.colors,
    required this.onDrop,
    super.key,
  });

  final String viewKey;
  final String title;
  final List<PlannerItem> items;
  final ItemColorResolver colors;
  final ValueChanged<PlannerItem> onDrop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DragTarget<PlannerItem>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Container(
        width: 260,
        margin: const EdgeInsetsDirectional.only(end: Space.sm),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? c.primaryContainer.withValues(alpha: 0.5) : c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: '$title, ${context.l10n.pvItemsCount(items.length)}',
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall,
                        ),
                      ),
                      Badge(
                        label: Text('${items.length}'),
                        backgroundColor: c.secondaryContainer,
                        textColor: c.onSecondaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                children: [
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: LongPressDraggable<PlannerItem>(
                        data: i,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          child: SizedBox(
                            width: 240,
                            child: PlannerItemChip(viewKey: viewKey, item: i, colors: colors.of(i), showDate: true),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: PlannerItemChip(viewKey: viewKey, item: i, colors: colors.of(i), showDate: true),
                        ),
                        child: PlannerItemChip(
                          key: ValueKey('kanban-card-${i.key}'),
                          viewKey: viewKey,
                          item: i,
                          colors: colors.of(i),
                          showDate: true,
                          longPressMenu: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
