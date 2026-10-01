import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart' show allItemsProvider;
import 'package:everslot/features/checklists/domain/board.dart' show SmartItem;
import 'package:everslot/features/planner/application/planner_providers.dart' show itemTasksProvider;
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Sections of the backlog drawer (T3.7.02).
enum DrawerSection { unscheduled, untimed, overdue, quota, checklist }

/// One draggable drawer row: a planner item (backlog, untimed, overdue, quota slot) or a checklist
/// item with a due date.
@immutable
sealed class DrawerEntry {
  const DrawerEntry(this.section);

  final DrawerSection section;
  String get title;
  String get key;
}

final class PlannerDrawerEntry extends DrawerEntry {
  const PlannerDrawerEntry(super.section, this.item, {this.label});

  final PlannerItem item;

  /// Row text when it differs from the title (quota progress).
  final String? label;

  @override
  String get title => item.title;

  @override
  String get key => item.key;
}

final class ChecklistDrawerEntry extends DrawerEntry {
  const ChecklistDrawerEntry(this.smart) : super(DrawerSection.checklist);

  final SmartItem smart;

  @override
  String get title => smart.item.text.trim().split('\n').first;

  @override
  String get key => 'item:${smart.item.id}';
}

/// Duration given to an entry dropped on the grid: its estimate, else its own duration for timed
/// items, else 30 min.
int drawerDropDuration(DrawerEntry e) => switch (e) {
  PlannerDrawerEntry(:final item) =>
    item.estimateMinutes ?? (item.allDay || item.isBacklog || item.isQuotaSlot ? 30 : item.durationMinutes),
  ChecklistDrawerEntry() => 30,
};

/// Open state of the drawer and the rect check for grid → drawer drops.
class BacklogDrawerController extends ChangeNotifier {
  bool _open = false;
  final GlobalKey panelKey = GlobalKey();

  bool get isOpen => _open;

  void toggle() {
    _open = !_open;
    notifyListeners();
  }

  void close() {
    if (!_open) return;
    _open = false;
    notifyListeners();
  }

  /// True when [global] is over the open drawer panel.
  bool contains(Offset global) {
    if (!_open) return false;
    final box = panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    return (box.localToGlobal(Offset.zero) & box.size).contains(global);
  }
}

/// Toolbar toggle of the drawer.
class BacklogDrawerButton extends StatelessWidget {
  const BacklogDrawerButton({required this.controller, super.key});

  final BacklogDrawerController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => IconButton(
      key: const Key('backlog-drawer-toggle'),
      tooltip: context.l10n.pvToggleBacklog,
      isSelected: controller.isOpen,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.inbox_outlined),
      selectedIcon: const Icon(Icons.inbox),
      onPressed: controller.toggle,
    ),
  );
}

/// Schedules [entry] at a grid slot (drawer → grid): backlog tasks get scheduled (`source`
/// backlog), untimed / overdue / quota occurrences move (scope dialog for series), checklist items
/// become a task linked to them. One undoable command.
Future<void> scheduleDrawerEntry(
  BuildContext context,
  WidgetRef ref,
  DrawerEntry entry, {
  required LocalDateTime start,
  required bool allDay,
}) async {
  final l = context.l10n;
  final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
  final commands = PlannerCommands(context, ref);
  final when = allDay ? '${f.dayShort(start.date)} · ${l.pvAllDay}' : '${f.dayShort(start.date)} ${f.timeOf(start)}';
  final duration = allDay ? 1440 : drawerDropDuration(entry);
  switch (entry) {
    case PlannerDrawerEntry(:final item) when item.isBacklog:
      await commands.run(
        l.pvMovedSnack(when),
        (a) => a.reschedule(item, newStart: start, newDurationMinutes: duration, allDay: allDay),
      );
    case PlannerDrawerEntry(:final item):
      await commands.reschedule(item, start: start, duration: duration, allDay: allDay, message: l.pvMovedSnack(when));
    case ChecklistDrawerEntry(:final smart):
      await commands.track(
        l.pvMovedSnack(when),
        () => ref
            .read(plannerServiceProvider)
            .scheduleChecklistItem(smart.item.id, title: entry.title, start: start, durationMinutes: duration),
      );
  }
}

/// Grid → drawer (T3.7.02): a one-off timed task goes back to the backlog; recurring occurrences
/// refuse with a toast. Returns true when the drop was consumed.
Future<bool> unscheduleToDrawer(BuildContext context, WidgetRef ref, PlannerItem item) async {
  final l = context.l10n;
  if (item.isRecurring || item.isQuotaSlot) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.pvCannotUnschedule)));
    return true;
  }
  await PlannerCommands(context, ref).runExtra(l.pvUnscheduledSnack, (a) => a.unschedule(item, source: 'backlog'));
  return true;
}

/// Hosts a date view with the backlog drawer sliding in from the trailing edge (non-modal, so rows
/// drag straight onto the grid underneath). The body is a drop target converting the pointer to
/// a slot through [dropSource].
class BacklogDrawerHost extends ConsumerWidget {
  const BacklogDrawerHost({
    required this.viewKey,
    required this.controller,
    required this.visibleDays,
    required this.dropSource,
    required this.child,
    super.key,
  });

  final String viewKey;
  final BacklogDrawerController controller;
  final List<LocalDate> visibleDays;
  final DropSlotSource? Function() dropSource;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DragTarget<DrawerEntry>(
    // Always "will accept": the drag starts over the drawer (inside this target), and a rejection
    // there would stick until the pointer leaves the target. Drops on the drawer itself are ignored.
    onWillAcceptWithDetails: (_) => true,
    onAcceptWithDetails: (d) {
      if (controller.contains(d.offset)) return;
      final slot = dropSource()?.dropSlotAt(d.offset);
      if (slot == null) return;
      unawaited(scheduleDrawerEntry(context, ref, d.data, start: slot.start, allDay: slot.allDay));
    },
    builder: (context, candidates, _) => LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => !controller.isOpen
                ? const SizedBox.shrink()
                : PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: math.min(320, box.maxWidth * 0.85),
                    child: BacklogDrawerPanel(
                      key: controller.panelKey,
                      viewKey: viewKey,
                      visibleDays: visibleDays,
                      onClose: controller.close,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

/// The drawer's content: search, section filters and draggable rows.
class BacklogDrawerPanel extends ConsumerStatefulWidget {
  const BacklogDrawerPanel({required this.viewKey, required this.visibleDays, required this.onClose, super.key});

  final String viewKey;
  final List<LocalDate> visibleDays;
  final VoidCallback onClose;

  @override
  ConsumerState<BacklogDrawerPanel> createState() => _BacklogDrawerPanelState();
}

class _BacklogDrawerPanelState extends ConsumerState<BacklogDrawerPanel> {
  String _query = '';
  Set<DrawerSection> _sections = DrawerSection.values.toSet();

  String _sectionLabel(DrawerSection s) {
    final l = context.l10n;
    return switch (s) {
      DrawerSection.unscheduled => l.pvUnscheduled,
      DrawerSection.untimed => l.pvUntimed,
      DrawerSection.overdue => l.pvOverdue,
      DrawerSection.quota => l.pvQuotaSlots,
      DrawerSection.checklist => l.pvChecklistDue,
    };
  }

  List<DrawerEntry> _entries() {
    final l = context.l10n;
    final today = ref.watch(plannerTodayProvider);
    final days = widget.visibleDays.isEmpty ? [today] : widget.visibleDays;
    final first = days.reduce((a, b) => a.isBefore(b) ? a : b);
    final last = days.reduce((a, b) => a.isAfter(b) ? a : b);
    final visible = ref.watch(viewItemsProvider(DayRange(first, first.daysUntil(last) + 1))).value ?? const [];
    final recent = ref.watch(viewItemsProvider(DayRange(today.plusDays(-7), 8))).value ?? const [];
    final backlog = ref.watch(viewBacklogProvider).value ?? const <PlannerItem>[];
    final demo = ref.watch(plannerDemoModeProvider);
    final scheduledItems = demo ? const <String>{} : (ref.watch(itemTasksProvider).value?.keys.toSet() ?? const {});
    final checklist = demo ? const <SmartItem>[] : (ref.watch(allItemsProvider).value ?? const <SmartItem>[]);
    final quotaByTask = <String, List<PlannerItem>>{};
    for (final i in visible) {
      if (i.isQuotaSlot) quotaByTask.putIfAbsent('${i.taskId}|${i.quotaPeriodKey}', () => []).add(i);
    }
    final seen = <String>{};
    final out = <DrawerEntry>[
      for (final b in backlog) PlannerDrawerEntry(DrawerSection.unscheduled, b),
      for (final i in visible)
        if (i.allDay && !i.isQuotaSlot && i.isOpen && seen.add(i.key)) PlannerDrawerEntry(DrawerSection.untimed, i),
      for (final i in recent)
        if (i.overdue && !i.allDay && seen.add(i.key)) PlannerDrawerEntry(DrawerSection.overdue, i),
      for (final group in quotaByTask.values)
        for (final i in group)
          if (i.allDay && seen.add(i.key))
            PlannerDrawerEntry(
              DrawerSection.quota,
              i,
              label: l.pvQuotaProgress(i.title, group.where((g) => !g.allDay).length, group.length),
            ),
      for (final s in checklist)
        if (s.item.dueLocal != null && s.item.status.isOpen && !scheduledItems.contains(s.item.id))
          ChecklistDrawerEntry(s),
    ];
    final q = _query.trim().toLowerCase();
    return [
      for (final e in out)
        if (_sections.contains(e.section) && (q.isEmpty || e.title.toLowerCase().contains(q))) e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final entries = _entries();
    final config = ref.watch(plannerViewConfigProvider(widget.viewKey));
    final colors = viewColors(context, ref, config);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    return Material(
      elevation: 8,
      color: c.surfaceContainerLow,
      child: SafeArea(
        left: false,
        right: false,
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.xs, Space.xxs, 0),
              child: Row(
                children: [
                  Expanded(child: Text(l.pvViewBacklog, style: context.text.titleMedium)),
                  IconButton(
                    key: const Key('backlog-drawer-close'),
                    tooltip: l.actionClose,
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              child: TextField(
                key: const Key('backlog-drawer-search'),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.actionSearch,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                children: [
                  for (final s in DrawerSection.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.xs),
                      child: FilterChip(
                        key: ValueKey('drawer-section-${s.name}'),
                        label: Text(_sectionLabel(s)),
                        selected: _sections.contains(s),
                        onSelected: (on) =>
                            setState(() => _sections = on ? {..._sections, s} : ({..._sections}..remove(s))),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Text(l.pvDragToSchedule, style: context.text.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(child: Text(l.pvBacklogEmpty, style: context.text.bodyMedium))
                  : ListView(
                      key: const Key('backlog-drawer-list'),
                      padding: const EdgeInsets.all(Space.sm),
                      children: [
                        for (final s in DrawerSection.values)
                          if (entries.any((e) => e.section == s)) ...[
                            SectionHeader(
                              _sectionLabel(s),
                              padding: const EdgeInsetsDirectional.only(top: Space.sm, bottom: Space.xs),
                            ),
                            for (final e in entries.where((e) => e.section == s))
                              _DraggableEntry(
                                entry: e,
                                child: switch (e) {
                                  PlannerDrawerEntry(:final item, :final label) => _EntryCard(
                                    title: label ?? item.title,
                                    subtitle: item.isBacklog
                                        ? (item.estimateMinutes == null ? null : f.duration(item.estimateMinutes!))
                                        : (item.allDay
                                              ? f.dayShort(item.startLocal.date)
                                              : '${f.dayShort(item.startLocal.date)} ${f.timeOf(item.startLocal)}'),
                                    accent: colors.of(item).accent,
                                  ),
                                  ChecklistDrawerEntry(:final smart) => _EntryCard(
                                    title: e.title,
                                    subtitle: '${smart.checklistTitle} · ${f.dayShort(smart.item.dueLocal!.date)}',
                                    accent: c.tertiary,
                                  ),
                                },
                              ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableEntry extends StatelessWidget {
  const _DraggableEntry({required this.entry, required this.child});

  final DrawerEntry entry;
  final Widget child;

  @override
  Widget build(BuildContext context) => LongPressDraggable<DrawerEntry>(
    key: ValueKey('drawer-${entry.key}'),
    data: entry,
    dragAnchorStrategy: pointerDragAnchorStrategy,
    feedback: Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: SizedBox(width: 200, child: child),
    ),
    childWhenDragging: Opacity(opacity: 0.35, child: child),
    child: child,
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.title, required this.accent, this.subtitle});

  final String title;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) => Semantics(
    label: [title, ?subtitle, context.l10n.pvDragToSchedule].join(', '),
    child: ExcludeSemantics(
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.xs, Space.sm, Space.xs),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: BorderDirectional(start: BorderSide(color: accent, width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
            if (subtitle != null)
              Text(subtitle!, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    ),
  );
}
