import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Items of [days] grouped by day: all-day first, then by start (Today / agenda ordering).
Map<LocalDate, List<PlannerItem>> groupByDay(List<PlannerItem> items, List<LocalDate> days) {
  final result = {for (final d in days) d: <PlannerItem>[]};
  for (final i in items) {
    final first = i.startLocal.date;
    final last = i.allDay
        ? first.plusDays((i.durationMinutes <= 0 ? 1 : (i.durationMinutes + 1439) ~/ 1440) - 1)
        : (i.endLocal.time.minuteOfDay == 0 && i.endLocal.date.isAfter(first)
              ? i.endLocal.date.minusDays(1)
              : i.endLocal.date);
    for (final d in days) {
      if (!d.isBefore(first) && !d.isAfter(last)) result[d]!.add(i);
    }
  }
  for (final list in result.values) {
    list.sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      final c = a.startLocal.compareTo(b.startLocal);
      return c != 0 ? c : a.title.compareTo(b.title);
    });
  }
  return result;
}

/// Linear list of a date range for screen-reader users (T3.3.24): every task is a list row with
/// *open*, *mark done* and *move earlier / later* actions; each day offers *Add task*. It plugs
/// into the same [PlannerGridController] as the grid, so the toolbar keeps working.
class AccessibleRangeList extends ConsumerStatefulWidget {
  const AccessibleRangeList({required this.controller, required this.start, this.days = 7, this.step = 7, super.key});

  final PlannerGridController controller;
  final LocalDate start;
  final int days;

  /// Days moved by previous / next.
  final int step;

  @override
  ConsumerState<AccessibleRangeList> createState() => _AccessibleRangeListState();
}

class _AccessibleRangeListState extends ConsumerState<AccessibleRangeList> implements GridNavigator {
  late LocalDate _start = widget.start;

  List<LocalDate> get _days => [for (var i = 0; i < widget.days; i++) _start.plusDays(i)];

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.updateVisibleDays(_days);
    });
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    super.dispose();
  }

  void _show(LocalDate start) {
    setState(() => _start = start);
    widget.controller.updateVisibleDays(_days);
  }

  @override
  Future<void> jumpToDate(LocalDate date, {bool animate = true, double? minute, double anchorFraction = 0}) async =>
      _show(widget.step == 7 ? date.startOfWeek(ref.read(userPreferencesProvider).weekStart) : date);

  @override
  Future<void> step(int pages) async => _show(_start.plusDays(pages * widget.step));

  @override
  void scrollToMinute(double minute, {bool animate = true, double anchorFraction = 0}) {}

  @override
  void zoomBy(double factor) {}

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final range = DayRange(_start, widget.days);
    final items = ref.watch(viewItemsProvider(range)).value ?? const <PlannerItem>[];
    final byDay = groupByDay(items, _days);
    final today = ref.watch(plannerTodayProvider);
    final commands = PlannerCommands(context, ref);
    return ListView(
      key: const Key('accessible-list'),
      children: [
        for (final d in _days) ...[
          Semantics(
            header: true,
            child: ListTile(
              title: Text(
                f.dayLong(d),
                style: context.text.titleSmall?.copyWith(color: d == today ? context.colors.primary : null),
              ),
              subtitle: Text(l.pvItemsCount(byDay[d]!.length)),
              trailing: IconButton(
                tooltip: l.pvAddTask,
                icon: const Icon(Icons.add),
                onPressed: () =>
                    ref.read(plannerNavProvider).newTask(context, start: d.atTime(LocalTime(9, 0)), duration: 30),
              ),
            ),
          ),
          for (final item in byDay[d]!)
            Semantics(
              customSemanticsActions: {
                CustomSemanticsAction(label: l.pvMoveEarlier(15)): () => unawaited(
                  commands.reschedule(
                    item,
                    start: item.startLocal.plusMinutes(-15),
                    message: l.pvMovedSnack(f.timeOf(item.startLocal.plusMinutes(-15))),
                  ),
                ),
                CustomSemanticsAction(label: l.pvMoveLater(15)): () => unawaited(
                  commands.reschedule(
                    item,
                    start: item.startLocal.plusMinutes(15),
                    message: l.pvMovedSnack(f.timeOf(item.startLocal.plusMinutes(15))),
                  ),
                ),
              },
              child: ListTile(
                leading: item.trackingMode == TrackingMode.check
                    ? Checkbox(
                        value: item.isDone,
                        semanticLabel: item.isDone ? l.pvMarkNotDone : l.pvMarkDone,
                        onChanged: (_) => unawaited(commands.toggleDone(item)),
                      )
                    : Icon(item.trackingMode == TrackingMode.timer ? Icons.timer_outlined : Icons.event_outlined),
                title: Text(item.title, style: TextStyle(decoration: item.isDone ? TextDecoration.lineThrough : null)),
                subtitle: Text(
                  '${item.allDay ? l.pvAllDay : f.timeRange(item.startLocal, item.endLocal)} · ${context.statusLabel(item.status)}'
                  '${item.isRecurring ? ' · ${l.pvRepeats}' : ''}',
                ),
                onTap: () => ref.read(plannerNavProvider).openTask(context, item),
                onLongPress: () => unawaited(commands.showTileMenu(item)),
              ),
            ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}
