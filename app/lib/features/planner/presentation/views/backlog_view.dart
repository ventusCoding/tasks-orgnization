import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart' show pickCategory;
import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Backlog grouping (`options.groupBy`).
enum BacklogGroup {
  none,
  category,
  priority,
  deadline;

  static BacklogGroup parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => none);
}

/// Group key of a backlog item: category id ('' = none), priority, or the deadline day ('' = none).
String backlogGroupKey(PlannerItem i, BacklogGroup g) => switch (g) {
  BacklogGroup.none => '',
  BacklogGroup.category => i.categoryId ?? '',
  BacklogGroup.priority => '${i.priority}',
  BacklogGroup.deadline => i.deadlineLocal?.date.toIso() ?? '',
};

/// Groups in display order: categories by [categoryOrder] (none last), priorities urgent first,
/// deadlines soonest first (none last). Items keep their manual order inside a group.
List<(String, List<PlannerItem>)> groupBacklog(
  List<PlannerItem> items,
  BacklogGroup g, {
  List<String> categoryOrder = const [],
}) {
  if (g == BacklogGroup.none) return [('', items)];
  final groups = <String, List<PlannerItem>>{};
  for (final i in items) {
    groups.putIfAbsent(backlogGroupKey(i, g), () => []).add(i);
  }
  int rank(String key) => switch (g) {
    BacklogGroup.category =>
      key.isEmpty ? 1 << 30 : (categoryOrder.contains(key) ? categoryOrder.indexOf(key) : 1 << 29),
    BacklogGroup.priority => -int.parse(key),
    _ => 0,
  };
  final keys = groups.keys.toList()
    ..sort((a, b) {
      if (g == BacklogGroup.deadline) {
        if (a.isEmpty || b.isEmpty) return a.isEmpty ? (b.isEmpty ? 0 : 1) : -1;
        return a.compareTo(b);
      }
      return rank(a).compareTo(rank(b));
    });
  return [for (final k in keys) (k, groups[k]!)];
}

/// Backlog list screen (T3.7.03): unscheduled tasks in manual order (drag handles reorder through
/// `manual_sort_key`); quick add; estimate, priority, deadline and category editable inline; group by
/// category / priority / deadline; select items and *Schedule on…* a day — they are placed one after
/// another into that day's free slots (work hours, around busy blocks).
class BacklogView extends ConsumerStatefulWidget {
  const BacklogView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<BacklogView> createState() => _BacklogViewState();
}

class _BacklogViewState extends ConsumerState<BacklogView> {
  final _add = TextEditingController();
  final Set<String> _selected = {};

  String get _key => widget.args.viewKey;

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  PlannerCommands get _commands => PlannerCommands(context, ref);

  Future<void> _create() async {
    final title = _add.text.trim();
    if (title.isEmpty) return;
    _add.clear();
    await _commands.runExtra(context.l10n.pvCreatedSnack, (a) => a.createBacklog(title));
  }

  /// [to] is the final index (`onReorderItem` already accounts for the removed item).
  Future<void> _reorder(List<PlannerItem> items, int from, int to) async {
    if (to == from) return;
    final moved = items[from];
    final rest = [...items]..removeAt(from);
    final after = to == 0 ? null : rest[to - 1].manualSortKey;
    final before = to >= rest.length ? null : rest[to].manualSortKey;
    await _commands.runExtra(context.l10n.pvMoveTo, (a) => a.reorder(moved, afterKey: after, beforeKey: before));
  }

  /// The occurrences of [day] once loaded (the range provider streams).
  Future<List<PlannerItem>> _itemsOf(LocalDate day) {
    final done = Completer<List<PlannerItem>>();
    final sub = ref.listenManual(viewItemsProvider(DayRange(day, 1)), (_, next) {
      if (next.hasValue && !done.isCompleted) done.complete(next.value);
    }, fireImmediately: true);
    return done.future.whenComplete(sub.close);
  }

  /// Bulk *Schedule on…*: picks a day, places the selected items in order into its openings.
  Future<void> _scheduleOn(List<PlannerItem> backlog) async {
    final l = context.l10n;
    final today = ref.read(plannerTodayProvider);
    final day = await pickDate(context, initial: today);
    if (day == null || !mounted) return;
    final chosen = [
      for (final b in backlog)
        if (_selected.contains(b.key)) b,
    ];
    final work = ref.read(plannerWorkSettingsProvider);
    final dayItems = await _itemsOf(day);
    if (!mounted) return;
    final starts = scheduleOnDay(
      day: day,
      items: dayItems,
      durations: [for (final b in chosen) b.estimateMinutes ?? b.durationMinutes],
      options: FreeSlotOptions(window: work.hours, workDays: work.days),
      notBefore: day == today ? ref.read(plannerNowProvider) : null,
    );
    final placed = [
      for (final (i, s) in starts.indexed)
        if (s != null) (chosen[i], s),
    ];
    final missed = starts.where((s) => s == null).length;
    await _commands.run(
      missed == 0 ? l.pvScheduledCount(placed.length) : '${l.pvScheduledCount(placed.length)} · ${l.pvNoRoom(missed)}',
      (a) async {
        for (final (b, s) in placed) {
          await a.scheduleBacklogItem(b, s, b.estimateMinutes ?? b.durationMinutes);
        }
      },
    );
    if (mounted) setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final group = BacklogGroup.parse(config.option<String>('groupBy', 'none'));
    final backlog = ref.watch(viewBacklogProvider);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    final list = viewItemFilter(ref, config).apply(backlog.value ?? const []);
    _selected.removeWhere((k) => !list.any((i) => i.key == k));
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  _selected.isEmpty ? '${l.pvViewBacklog} · ${list.length}' : l.pvSelected(_selected.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (_selected.isNotEmpty) ...[
                TextButton.icon(
                  key: const Key('backlog-schedule-on'),
                  icon: const Icon(Icons.event_available),
                  label: Text(l.pvScheduleOn),
                  onPressed: () => unawaited(_scheduleOn(list)),
                ),
                IconButton(
                  tooltip: l.actionCancel,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_selected.clear),
                ),
              ] else ...[
                PopupMenuButton<BacklogGroup>(
                  key: const Key('backlog-group'),
                  tooltip: l.pvGroupBy,
                  icon: const Icon(Icons.segment),
                  onSelected: (g) => notifier.change((c) => c.withOption('groupBy', g.name)),
                  itemBuilder: (_) => [
                    for (final (g, label) in [
                      (BacklogGroup.none, l.pvGroupNone),
                      (BacklogGroup.category, l.pvGroupCategory),
                      (BacklogGroup.priority, l.pvGroupPriority),
                      (BacklogGroup.deadline, l.pvGroupDeadline),
                    ])
                      CheckedPopupMenuItem(value: g, checked: g == group, child: Text(label)),
                  ],
                ),
                PlannerFilterButton(viewKey: _key),
                PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
              ],
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          ActiveFilterBar(viewKey: _key),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, Space.md, Space.xs),
            child: TextField(
              key: const Key('backlog-add'),
              controller: _add,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l.pvAddToBacklog,
                prefixIcon: const Icon(Icons.add),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => unawaited(_create()),
            ),
          ),
          Expanded(
            child: AsyncValueView<List<PlannerItem>>(
              value: backlog,
              data: (_) {
                if (list.isEmpty) return EmptyState(icon: Icons.inbox_outlined, title: l.pvBacklogEmpty);
                Widget row(PlannerItem i, {int? index}) => _BacklogRow(
                  key: ValueKey('backlog-${i.taskId}'),
                  item: i,
                  categories: categories,
                  selected: _selected.contains(i.key),
                  onSelect: (v) => setState(() => v ? _selected.add(i.key) : _selected.remove(i.key)),
                  dragIndex: index,
                );
                if (group == BacklogGroup.none) {
                  return ReorderableListView.builder(
                    key: const Key('backlog-list'),
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm).copyWith(bottom: 96),
                    itemCount: list.length,
                    onReorderItem: (from, to) => unawaited(_reorder(list, from, to)),
                    itemBuilder: (context, i) => row(list[i], index: i),
                  );
                }
                final groups = groupBacklog(list, group, categoryOrder: [for (final c in categories) c.id]);
                final byId = {for (final c in categories) c.id: c};
                final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
                String title(String key) => switch (group) {
                  BacklogGroup.category => key.isEmpty ? l.pvNoCategory : (byId[key]?.name ?? l.pvNoCategory),
                  BacklogGroup.priority => PriorityStyle.label(context, int.parse(key)),
                  BacklogGroup.deadline => key.isEmpty ? l.pvNoDeadline : f.dayLong(LocalDate.parse(key)),
                  BacklogGroup.none => '',
                };
                return ListView(
                  key: const Key('backlog-groups'),
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, 0, Space.sm, 96),
                  children: [
                    for (final (key, items) in groups) ...[
                      SectionHeader(
                        '${title(key)} · ${items.length}',
                        padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.md, Space.sm, Space.xs),
                      ),
                      for (final i in items) row(i),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      fab: PlannerFab(start: () => null),
    );
  }
}

/// One backlog task: selection box, title (tap → task), estimate / priority / deadline / category
/// chips that edit inline, and a drag handle when manually ordered.
class _BacklogRow extends ConsumerWidget {
  const _BacklogRow({
    required this.item,
    required this.categories,
    required this.selected,
    required this.onSelect,
    this.dragIndex,
    super.key,
  });

  final PlannerItem item;
  final List<Category> categories;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final commands = PlannerCommands(context, ref);
    Future<void> edit(BacklogEdit e) => commands.runExtra(l.tasksUpdated, (a) => a.editBacklog(item, e));
    final category = categories.where((c) => c.id == item.categoryId).firstOrNull;
    final estimate = item.estimateMinutes;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.xs),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, Space.xxs, Space.xs, Space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: ValueKey('backlog-select-${item.taskId}'),
              value: selected,
              onChanged: (v) => onSelect(v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => ref.read(plannerNavProvider).openTask(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.sm),
                      child: Text(item.title, style: context.text.bodyLarge),
                    ),
                  ),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      ActionChip(
                        key: ValueKey('backlog-estimate-${item.taskId}'),
                        avatar: const Icon(Icons.timelapse, size: 16),
                        label: Text(estimate == null ? l.pvNoEstimate : f.duration(estimate)),
                        onPressed: () async {
                          final m = await pickDuration(context, initialMinutes: estimate ?? 30, maxMinutes: 1440);
                          if (m != null) await edit(BacklogEdit(estimateMinutes: m));
                        },
                      ),
                      PopupMenuButton<int>(
                        key: ValueKey('backlog-priority-${item.taskId}'),
                        tooltip: l.tasksFieldPriority,
                        onSelected: (p) => unawaited(edit(BacklogEdit(priority: p))),
                        itemBuilder: (_) => [
                          for (var p = 0; p <= 4; p++)
                            CheckedPopupMenuItem(
                              value: p,
                              checked: p == item.priority,
                              child: Text(PriorityStyle.label(context, p)),
                            ),
                        ],
                        child: Chip(
                          avatar: Icon(Icons.flag, size: 16, color: PriorityStyle.color(item.priority)),
                          label: Text(PriorityStyle.label(context, item.priority)),
                        ),
                      ),
                      ActionChip(
                        key: ValueKey('backlog-deadline-${item.taskId}'),
                        avatar: const Icon(Icons.flag_circle_outlined, size: 16),
                        label: Text(
                          item.deadlineLocal == null ? l.pvNoDeadline : f.dateMedium(item.deadlineLocal!.date),
                        ),
                        onPressed: () async {
                          final d = await pickDate(
                            context,
                            initial: item.deadlineLocal?.date ?? ref.read(plannerTodayProvider),
                          );
                          if (d != null) await edit(BacklogEdit(deadline: d.atTime(LocalTime(23, 59))));
                        },
                      ),
                      ActionChip(
                        key: ValueKey('backlog-category-${item.taskId}'),
                        avatar: Icon(
                          Icons.circle,
                          size: 12,
                          color: category == null
                              ? context.colors.outline
                              : CategoryColors.accent(
                                  category.color,
                                  Theme.of(context).brightness,
                                  highContrast: context.a11y.highContrastCategories,
                                ),
                        ),
                        label: Text(category?.name ?? l.pvNoCategory),
                        onPressed: () async {
                          final id = await pickCategory(context, ref, selectedId: item.categoryId);
                          if (id == null) return;
                          await edit(id.isEmpty ? const BacklogEdit(clearCategory: true) : BacklogEdit(categoryId: id));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (dragIndex != null)
              ReorderableDragStartListener(
                index: dragIndex!,
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Icon(Icons.drag_handle, semanticLabel: l.pvMoveTo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
