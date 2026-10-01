import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/planner_selection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Shared pieces of the list-style planner views (week list, agenda, month list-below, backlog…).

/// Order of a day's items in list views (T3.4.07 / T3.6.06): all-day and untimed first by manual
/// order, then timed items by start, then priority.
List<PlannerItem> dayListOrder(Iterable<PlannerItem> items) {
  final list = [...items];
  list.sort((a, b) {
    if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
    if (a.allDay) {
      final ka = a.manualSortKey ?? '';
      final kb = b.manualSortKey ?? '';
      final c = ka.compareTo(kb);
      if (c != 0) return c;
    }
    final s = a.startLocal.compareTo(b.startLocal);
    if (s != 0) return s;
    return b.priority.compareTo(a.priority);
  });
  return list;
}

/// Items of [items] on [day] (start date, or spanning it for multi-day all-day items).
List<PlannerItem> itemsOnDay(Iterable<PlannerItem> items, LocalDate day) => [
  for (final i in items)
    if (i.startLocal.date == day ||
        (i.allDay && i.startLocal.date.isBefore(day) && i.endLocal.isAfter(day.atStartOfDay)))
      i,
];

/// Color resolver of a view (its `colorBy`) for the current theme.
ItemColorResolver viewColors(BuildContext context, WidgetRef ref, PlannerViewConfig config) => ItemColorResolver(
  colorBy: config.colorBy,
  brightness: Theme.of(context).brightness,
  categoryColor: ref.watch(categoryColorLookupProvider),
  statusColor: context.statusColor,
);

/// Items of a range after the view's filters (T3.3.22).
AsyncValue<List<PlannerItem>> filteredItems(WidgetRef ref, DayRange range, PlannerViewConfig config) {
  final filter = viewItemFilter(ref, config);
  return ref.watch(viewItemsProvider(range)).whenData(filter.apply);
}

/// A compact item row: check (for `check` items), time, title, icons and status styling. Tap opens
/// (or toggles in selection mode), long-press opens the tile menu (with *Select*).
class PlannerItemChip extends ConsumerWidget {
  const PlannerItemChip({
    required this.viewKey,
    required this.item,
    required this.colors,
    this.showDate = false,
    this.showNotes = false,
    this.dense = false,
    this.trailing,
    this.longPressMenu = true,
    super.key,
  });

  /// False when a draggable wrapper owns the long-press (the menu stays a semantics action).
  final bool longPressMenu;

  final String viewKey;
  final PlannerItem item;
  final TileColors colors;
  final bool showDate;
  final bool showNotes;
  final bool dense;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final now = ref.watch(plannerNowProvider);
    final commands = PlannerCommands(context, ref);
    final selected = ref.watch(plannerSelectionProvider(viewKey).select((s) => s.containsKey(item.key)));
    final done = item.isDone;
    final faded = done || item.status == OccurrenceStatus.skipped || item.status == OccurrenceStatus.cancelled;
    final time = item.allDay ? l.pvAllDay : f.timeRange(item.startLocal, item.endLocal);
    final when = showDate ? '${f.dayShort(item.startLocal.date)} · $time' : time;
    final fg = colors.foreground;
    void open() => tapOrToggle(ref, viewKey, item, () => ref.read(plannerNavProvider).openTask(context, item));
    void menu() => unawaited(
      commands.showTileMenu(item, onSelect: () => ref.read(plannerSelectionProvider(viewKey).notifier).select(item)),
    );
    final label =
        '${item.title}, $when, ${context.statusLabel(item.status)}${item.isRecurring ? ', ${l.pvRepeats}' : ''}';
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: open,
      onLongPress: menu,
      child: Opacity(
        opacity: faded ? 0.6 : (item.endLocal.isBefore(now) && !done ? 0.85 : 1),
        child: Material(
          key: ValueKey('chip-${item.key}'),
          color: colors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
            side: selected ? BorderSide(color: context.colors.primary, width: 2) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            onLongPress: longPressMenu ? menu : null,
            child: Container(
              constraints: BoxConstraints(minHeight: dense ? 36 : 48),
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(
                    color: item.status == OccurrenceStatus.missed ? context.appColors.missed : colors.accent,
                    width: item.status == OccurrenceStatus.missed ? 4 : 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (item.trackingMode == TrackingMode.check)
                    Semantics(
                      checked: done,
                      label: done ? l.pvMarkNotDone : l.pvMarkDone,
                      child: InkResponse(
                        key: ValueKey('chip-check-${item.key}'),
                        radius: 22,
                        onTap: () => unawaited(commands.toggleDone(item)),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xs, vertical: Space.xs),
                          child: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: fg),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xs),
                      child: Icon(
                        item.trackingMode == TrackingMode.timer ? Icons.timer_outlined : Icons.event_outlined,
                        size: 18,
                        color: fg,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.xs, top: Space.xxs, bottom: Space.xxs),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                              decoration: done ? TextDecoration.lineThrough : null,
                              decorationColor: fg,
                            ),
                          ),
                          Text(
                            [when, if (item.location != null) item.location!].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall?.copyWith(color: fg.withValues(alpha: 0.85)),
                          ),
                          if (showNotes && (item.notes?.isNotEmpty ?? false))
                            Text(
                              item.notes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (item.isRecurring) Icon(Icons.repeat, size: 14, color: fg),
                  if (item.timeZone != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 2),
                      child: Icon(Icons.public, size: 14, color: fg),
                    ),
                  ?trailing,
                  const SizedBox(width: Space.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
