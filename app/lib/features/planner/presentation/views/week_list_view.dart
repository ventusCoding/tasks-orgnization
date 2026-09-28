import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Week list view (T3.6.06): the week's days stacked vertically as sections (Tweek / Things
/// "Upcoming" style) — all-day first, timed by start. Drag an item onto another day (keeps its
/// time) or onto an untimed item of the same day (manual order); release on its own day opens the
/// item menu. Swipe sideways or use the arrows to change week.
class WeekListView extends ConsumerStatefulWidget {
  const WeekListView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<WeekListView> createState() => _WeekListViewState();
}

class _WeekListViewState extends ConsumerState<WeekListView> {
  late LocalDate _anchor;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _anchor = widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read(plannerViewStateProvider(_key))?.anchor ?? ref.read(plannerTodayProvider);
  }

  Weekday get _weekStart => weekStartFor(ref.read(plannerViewConfigProvider(_key)), ref.read(userPreferencesProvider).weekStart);

  void _go(LocalDate date) {
    final start = date.startOfWeek(_weekStart);
    setState(() => _anchor = start);
    ref.read(plannerAnchorProvider.notifier).set(start);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: start));
  }

  Future<void> _pick() async {
    final start = _anchor.startOfWeek(_weekStart);
    final picked = await showMiniMonth(
      context,
      initial: start,
      weekStart: _weekStart,
      highlight: [for (var i = 0; i < 7; i++) start.plusDays(i)],
    );
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final weekStart = weekStartFor(config, prefs.weekStart);
    final start = _anchor.startOfWeek(weekStart);
    final days = [
      for (var i = 0; i < 7; i++)
        if (config.showWeekends || !start.plusDays(i).weekday.isWeekend) start.plusDays(i),
    ];
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = ref.watch(plannerTodayProvider);
    final items = filteredItems(ref, DayRange(start, 7), config);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: rangeTitle(locale, start, start.plusDays(6)),
        onPrevious: () => _go(start.plusDays(-7)),
        onNext: () => _go(start.plusDays(7)),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPreviousWeek,
        nextLabel: l.pvNextWeek,
        trailing: [
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(start.plusDays(-7)),
        onNext: () => _go(start.plusDays(7)),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: GestureDetector(
                // Horizontal swipe changes week (mirrored in RTL).
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  final forward = rtl ? v > 0 : v < 0;
                  _go(start.plusDays(forward ? 7 : -7));
                },
                child: AsyncValueView<List<PlannerItem>>(
                  value: items,
                  data: (list) => ListView(
                    key: const Key('week-list'),
                    padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.xs, Space.sm, 88),
                    children: [
                      for (final d in days)
                        _DaySection(viewKey: _key, day: d, isToday: d == today, items: dayListOrder(itemsOnDay(list, d)), config: config),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(days.contains(today) ? today : start, ref.read(plannerNowProvider))),
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.viewKey, required this.day, required this.isToday, required this.items, required this.config});

  final String viewKey;
  final LocalDate day;
  final bool isToday;
  final List<PlannerItem> items;
  final PlannerViewConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final colors = viewColors(context, ref, config);
    final commands = PlannerCommands(context, ref);
    final nav = ref.read(plannerNavProvider);
    final c = context.colors;
    Future<void> dropOnDay(PlannerItem item) async {
      if (item.startLocal.date == day && !item.isMultiDay) {
        await commands.showTileMenu(item);
        return;
      }
      final start = item.allDay ? day.atStartOfDay : day.atTime(item.startLocal.time);
      await commands.reschedule(item, start: start, message: l.pvMovedSnack(f.dayShort(day)));
    }

    Future<void> dropBefore(PlannerItem item, PlannerItem target) async {
      if (item.key == target.key) {
        await commands.showTileMenu(item);
        return;
      }
      final untimed = [for (final i in items) if (i.allDay && i.key != item.key) i];
      final at = untimed.indexWhere((i) => i.key == target.key);
      final after = at <= 0 ? null : untimed[at - 1].manualSortKey;
      await commands.runExtra(l.pvMovedSnack(f.dayShort(day)), (a) => a.reorder(item, afterKey: after, beforeKey: target.manualSortKey));
    }

    return DragTarget<PlannerItem>(
      onAcceptWithDetails: (d) => unawaited(dropOnDay(d.data)),
      builder: (context, candidates, _) => Container(
        key: ValueKey('week-list-day-${day.toIso()}'),
        margin: const EdgeInsets.only(bottom: Space.sm),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? c.primaryContainer.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              button: true,
              label: '${f.dayLong(day)}, ${l.pvItemsCount(items.length)}',
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.sm),
                onTap: () => nav.openView(context, 'day_list', date: day),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.xs, Space.sm, 0, Space.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: isToday
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
                                  decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(Radii.pill)),
                                  child: Text(
                                    f.dayLong(day),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.labelLarge?.copyWith(color: c.onPrimary),
                                  ),
                                )
                              : Text(
                                  f.dayLong(day),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      Text(l.pvItemsCount(items.length), style: context.text.labelSmall?.copyWith(color: c.onSurfaceVariant)),
                      IconButton(
                        tooltip: l.pvAddTask,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add),
                        onPressed: () => unawaited(commands.quickCreate(start: day.atStartOfDay, duration: 1440, allDay: true)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: Space.sm, bottom: Space.sm),
                child: Text(l.pvEmptyDay, style: context.text.bodySmall?.copyWith(color: c.onSurfaceVariant)),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: _DraggableChip(
                  viewKey: viewKey,
                  item: item,
                  colors: colors.of(item),
                  onDropBefore: item.allDay ? (dragged) => dropBefore(dragged, item) : null,
                  acceptsBefore: (dragged) => item.allDay && dragged.allDay && dragged.startLocal.date == day,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A chip that can be dragged (long-press) and, for untimed items, accepts a drop in front of it.
class _DraggableChip extends StatelessWidget {
  const _DraggableChip({
    required this.viewKey,
    required this.item,
    required this.colors,
    required this.acceptsBefore,
    this.onDropBefore,
  });

  final String viewKey;
  final PlannerItem item;
  final TileColors colors;
  final bool Function(PlannerItem dragged) acceptsBefore;
  final Future<void> Function(PlannerItem dragged)? onDropBefore;

  @override
  Widget build(BuildContext context) {
    final chip = PlannerItemChip(viewKey: viewKey, item: item, colors: colors, longPressMenu: false);
    final draggable = LongPressDraggable<PlannerItem>(
      data: item,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: SizedBox(width: MediaQuery.sizeOf(context).width - 2 * Space.lg, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: chip,
    );
    if (onDropBefore == null) return draggable;
    return DragTarget<PlannerItem>(
      onWillAcceptWithDetails: (d) => acceptsBefore(d.data),
      onAcceptWithDetails: (d) => unawaited(onDropBefore!(d.data)),
      builder: (context, candidates, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (candidates.isNotEmpty && candidates.first?.key != item.key)
            Container(height: 3, margin: const EdgeInsets.only(bottom: 2), color: context.colors.primary),
          draggable,
        ],
      ),
    );
  }
}
