import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/sync/sync_writer.dart' show OpRecord;
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/quit/live_counter.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:everslot/features/notifications/presentation/inbox_screen.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart' show showPlannerUndoSnack;
import 'package:everslot/features/today/application/day_boundary_ticker.dart';
import 'package:everslot/features/today/application/today_overview_provider.dart';
import 'package:everslot/features/today/domain/agenda.dart';
import 'package:everslot/features/today/domain/now_next.dart';
import 'package:everslot/features/today/domain/today_layout.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitLogKind;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

AppFormat todayFormat(BuildContext context, WidgetRef ref) =>
    AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: context.l10n);

/// A block of the Today screen (T8.1.02): title, empty / loading rules and its body.
abstract class TodayBlock {
  const TodayBlock();

  TodayBlockId get id;
  String title(AppLocalizations l);
  bool isLoading(TodayOverview o);
  bool isEmpty(TodayOverview o);
  Widget build(BuildContext context, TodayOverview o);

  /// Friendly empty state with a primary action (T8.1.13).
  Widget empty(BuildContext context);

  static const all = <TodayBlock>[
    NowNextBlock(),
    AgendaBlock(),
    OverdueBlock(),
    HabitsBlock(),
    QuitBlock(),
    ChecklistsBlock(),
    InboxBlock(),
  ];

  static TodayBlock of(TodayBlockId id) => all.firstWhere((b) => b.id == id);
}

String blockTitle(AppLocalizations l, TodayBlockId id) => switch (id) {
  TodayBlockId.nowNext => l.todayBlockNowNext,
  TodayBlockId.agenda => l.todayBlockAgenda,
  TodayBlockId.overdue => l.todayBlockOverdue,
  TodayBlockId.habits => l.todayBlockHabits,
  TodayBlockId.quit => l.todayBlockQuit,
  TodayBlockId.checklists => l.todayBlockChecklists,
  TodayBlockId.inbox => l.todayBlockInbox,
};

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
    child: Row(
      children: [
        Icon(icon, color: context.colors.onSurfaceVariant),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(title, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

// ------------------------------------------------------------------------------------- now/next --

class NowNextBlock extends TodayBlock {
  const NowNextBlock();

  @override
  TodayBlockId get id => TodayBlockId.nowNext;

  @override
  String title(AppLocalizations l) => l.todayBlockNowNext;

  @override
  bool isLoading(TodayOverview o) => o.agenda == null;

  @override
  bool isEmpty(TodayOverview o) => selectNowNext([...?o.agenda, ...?o.upcoming], o.now).isEmpty;

  @override
  Widget build(BuildContext context, TodayOverview o) => const NowNextCard();

  @override
  Widget empty(BuildContext context) =>
      _Empty(icon: Icons.free_breakfast_outlined, title: context.l10n.todayNothingNow);
}

/// Now / Next (T8.1.03): the running occurrence with its remaining time, the next one with a
/// countdown; refreshed every 30 s while shown.
class NowNextCard extends ConsumerStatefulWidget {
  const NowNextCard({super.key});

  @override
  ConsumerState<NowNextCard> createState() => _NowNextCardState();
}

class _NowNextCardState extends ConsumerState<NowNextCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (ref.read(todayAutoTickProvider)) {
      _tick = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = ref.watch(todayOverviewProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final nn = selectNowNext([...?o.agenda, ...?o.upcoming], now);
    final fmt = todayFormat(context, ref);
    String minutes(Duration d) => fmt.duration(d.inMinutes.clamp(1, 100000));
    final running = ref.watch(runningTimersProvider).value?.isNotEmpty ?? false;
    final current = nn.current;
    final next = nn.next;
    return Card(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (current != null) ...[
              Row(
                children: [
                  Text(l.todayNow, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
                  if (nn.overlapping > 0) ...[
                    const SizedBox(width: Space.sm),
                    StatusPill(label: l.todayOverlapping(nn.overlapping), color: context.colors.tertiary, dense: true),
                  ],
                ],
              ),
              _ItemLine(item: current, trailing: l.todayTimeLeft(minutes(current.endUtc.difference(now)))),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: Space.xs),
                child: LinearProgressIndicator(value: nn.progressAt(now)),
              ),
              _ItemActions(item: current, timerRunning: running),
            ],
            if (current != null && next != null) const Divider(),
            if (next != null) ...[
              Text(l.todayNext, style: context.text.labelLarge?.copyWith(color: context.colors.secondary)),
              _ItemLine(item: next, trailing: l.todayStartsIn(minutes(next.startUtc.difference(now)))),
              _ItemActions(item: next, timerRunning: running),
            ] else if (current != null)
              Text(l.todayNothingNext, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ItemLine extends ConsumerWidget {
  const _ItemLine({required this.item, this.trailing});

  final PlannerItem item;
  final String? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = todayFormat(context, ref);
    return InkWell(
      onTap: () => unawaited(showOccurrenceSheet(context, item)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            if (item.color != null) ...[ColorDot(Color(item.color!)), const SizedBox(width: Space.sm)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: context.text.titleMedium),
                  Text(
                    [if (!item.allDay) fmt.timeRange(item.startLocal, item.endLocal), ?trailing].join(' · '),
                    style: context.text.bodySmall,
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

class _ItemActions extends ConsumerWidget {
  const _ItemActions({required this.item, required this.timerRunning});

  final PlannerItem item;
  final bool timerRunning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final actions = primaryActionsFor(item, timerRunning: timerRunning);
    String label(OccurrencePrimaryAction a) => switch (a) {
      OccurrencePrimaryAction.done => l.actionDone,
      OccurrencePrimaryAction.skip => l.actionSkip,
      OccurrencePrimaryAction.start => l.tasksActionStart,
      OccurrencePrimaryAction.pause => l.tasksActionPauseTimer,
      OccurrencePrimaryAction.resume => l.tasksActionResumeTimer,
      OccurrencePrimaryAction.stop => l.tasksActionStop,
      OccurrencePrimaryAction.reopen => l.tasksActionReopen,
    };
    return Wrap(
      spacing: Space.sm,
      children: [
        for (final a in actions)
          ActionChip(
            key: ValueKey('now-${item.key}-${a.name}'),
            label: Text(label(a)),
            onPressed: () => unawaited(runPrimaryAction(context, ref, item, a)),
          ),
        ActionChip(label: Text(l.actionOpen), onPressed: () => unawaited(showOccurrenceSheet(context, item))),
      ],
    );
  }
}

// --------------------------------------------------------------------------------------- agenda --

class AgendaBlock extends TodayBlock {
  const AgendaBlock();

  @override
  TodayBlockId get id => TodayBlockId.agenda;

  @override
  String title(AppLocalizations l) => l.todayBlockAgenda;

  @override
  bool isLoading(TodayOverview o) => o.agenda == null;

  @override
  bool isEmpty(TodayOverview o) => o.agenda?.isEmpty ?? true;

  @override
  Widget build(BuildContext context, TodayOverview o) => AgendaList(items: o.agenda ?? const []);

  @override
  Widget empty(BuildContext context) => _Empty(
    icon: Icons.event_available_outlined,
    title: context.l10n.todayEmptyAgenda,
    action: context.l10n.todayEmptyAgendaAction,
    onAction: () => unawaited(context.push(AppLinks.taskNew())),
  );
}

/// Today's tasks (T8.1.04): all-day first, swipe done / skip (configurable), a collapsed
/// "Done (n)" group.
class AgendaList extends ConsumerStatefulWidget {
  const AgendaList({required this.items, super.key});

  final List<PlannerItem> items;

  @override
  ConsumerState<AgendaList> createState() => _AgendaListState();
}

class _AgendaListState extends ConsumerState<AgendaList> {
  bool _showDone = false;

  Future<void> _swipe(PlannerItem item, SwipeAction action) async {
    switch (action) {
      case SwipeAction.done:
        await completeOccurrence(context, ref, item);
      case SwipeAction.skip:
        await ref.read(plannerServiceProvider).skip(item);
        if (mounted) showPlannerUndoSnack(context, ref, context.l10n.tasksMarkedSkipped);
      case SwipeAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final layout = ref.watch(todayLayoutProvider);
    final groups = groupAgenda(widget.items);
    Widget row(PlannerItem i) {
      final tile = AgendaRow(item: i);
      if (!hasCheckbox(i) || !i.isOpen) return tile;
      final start = layout.swipeStart;
      final end = layout.swipeEnd;
      return Dismissible(
        key: ValueKey('agenda-${i.key}'),
        direction: switch ((start, end)) {
          (SwipeAction.none, SwipeAction.none) => DismissDirection.none,
          (SwipeAction.none, _) => DismissDirection.endToStart,
          (_, SwipeAction.none) => DismissDirection.startToEnd,
          _ => DismissDirection.horizontal,
        },
        background: _swipeBg(context, start, AlignmentDirectional.centerStart),
        secondaryBackground: _swipeBg(context, end, AlignmentDirectional.centerEnd),
        confirmDismiss: (dir) async {
          await _swipe(i, dir == DismissDirection.startToEnd ? start : end);
          return false; // the live list updates itself
        },
        child: tile,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in groups.allDay) row(i),
        for (final i in groups.timed) row(i),
        if (groups.completed.isNotEmpty && layout.agendaShowCompleted) ...[
          TextButton.icon(
            key: const ValueKey('agenda-done-toggle'),
            icon: Icon(_showDone ? Icons.expand_less : Icons.expand_more),
            label: Text(l.todayDoneGroup(groups.completed.length)),
            onPressed: () => setState(() => _showDone = !_showDone),
          ),
          if (_showDone)
            for (final i in groups.completed) AgendaRow(item: i),
        ],
      ],
    );
  }

  Widget _swipeBg(BuildContext context, SwipeAction a, AlignmentGeometry align) => ColoredBox(
    color: a == SwipeAction.done ? context.colors.primaryContainer : context.colors.secondaryContainer,
    child: Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xl),
        child: Icon(a == SwipeAction.done ? Icons.check : Icons.redo),
      ),
    ),
  );
}

/// One agenda row: time, category color, title, status, inline done (events have no checkbox).
class AgendaRow extends ConsumerWidget {
  const AgendaRow({required this.item, super.key});

  final PlannerItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = todayFormat(context, ref);
    final visual = occurrenceStatusVisual(context, item.status, overdue: item.overdue);
    final done = item.status == OccurrenceStatus.done;
    return ListTile(
      key: ValueKey('agenda-row-${item.key}'),
      dense: true,
      leading: hasCheckbox(item)
          ? Checkbox(
              value: done,
              semanticLabel: item.title,
              onChanged: (v) => unawaited(
                v ?? false
                    ? completeOccurrence(context, ref, item)
                    : runPrimaryAction(context, ref, item, OccurrencePrimaryAction.reopen),
              ),
            )
          : Icon(Icons.event_outlined, color: item.color == null ? null : Color(item.color!)),
      title: Text(
        item.title,
        style: done ? TextStyle(decoration: TextDecoration.lineThrough, color: context.colors.onSurfaceVariant) : null,
      ),
      subtitle: Text(
        [item.allDay ? l.todayAllDay : fmt.timeRange(item.startLocal, item.endLocal), visual.label].join(' · '),
      ),
      trailing: item.color == null ? null : ColorDot(Color(item.color!)),
      onTap: () => unawaited(showOccurrenceSheet(context, item)),
      onLongPress: () => unawaited(postponeOccurrence(context, ref, item)),
    );
  }
}

// -------------------------------------------------------------------------------------- overdue --

class OverdueBlock extends TodayBlock {
  const OverdueBlock();

  @override
  TodayBlockId get id => TodayBlockId.overdue;

  @override
  String title(AppLocalizations l) => l.todayBlockOverdue;

  @override
  bool isLoading(TodayOverview o) => o.overdue == null;

  @override
  bool isEmpty(TodayOverview o) => o.overdue?.isEmpty ?? true;

  @override
  Widget build(BuildContext context, TodayOverview o) => OverdueList(items: o.overdue ?? const []);

  @override
  Widget empty(BuildContext context) => _Empty(icon: Icons.task_alt, title: context.l10n.todayEmptyOverdue);
}

/// Unresolved past occurrences (T8.1.05) with bulk roll-over / done / skip and per-row reschedule.
class OverdueList extends ConsumerWidget {
  const OverdueList({required this.items, super.key});

  final List<PlannerItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = todayFormat(context, ref);
    Future<void> bulk(Future<OpRecord> Function(PlannerItem) each, String message) async {
      final stack = ref.read(undoStackProvider);
      var pushed = 0;
      for (final i in items) {
        if (!(await each(i)).isEmpty) pushed++;
      }
      stack.squash(pushed, message); // one undo for the whole bulk action
      if (context.mounted) showPlannerUndoSnack(context, ref, message);
    }

    final service = ref.read(plannerServiceProvider);
    final today = ref.read(todayOverviewProvider).date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in items)
          ListTile(
            key: ValueKey('overdue-${i.key}'),
            dense: true,
            leading: Icon(Icons.warning_amber_rounded, color: context.appColors.missed),
            title: Text(i.title),
            subtitle: Text(todayDateTimeLabel(fmt, i)),
            trailing: IconButton(
              tooltip: l.tasksActionReschedule,
              icon: const Icon(Icons.event_repeat),
              onPressed: () => unawaited(postponeOccurrence(context, ref, i)),
            ),
            onTap: () => unawaited(showOccurrenceSheet(context, i)),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
          child: Wrap(
            spacing: Space.sm,
            children: [
              FilledButton.tonal(
                key: const ValueKey('overdue-rollover'),
                onPressed: () => unawaited(
                  bulk(
                    (i) => service.reschedule(
                      i,
                      newStart: i.allDay ? today.atStartOfDay : LocalDateTime(today, i.startLocal.time),
                      source: 'today_rollover',
                    ),
                    l.todayRolledOver(items.length),
                  ),
                ),
                child: Text(l.tasksActionMoveToToday),
              ),
              TextButton(
                key: const ValueKey('overdue-done'),
                onPressed: () => unawaited(bulk(service.markDone, l.tasksMarkedDone)),
                child: Text(l.todayMarkAllDone),
              ),
              TextButton(
                key: const ValueKey('overdue-skip'),
                onPressed: () => unawaited(bulk(service.skip, l.tasksMarkedSkipped)),
                child: Text(l.todaySkipAll),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String todayDateTimeLabel(AppFormat fmt, PlannerItem i) =>
    i.allDay ? fmt.dateMedium(i.startLocal.date) : '${fmt.dateMedium(i.startLocal.date)} ${fmt.timeOf(i.startLocal)}';

// --------------------------------------------------------------------------------------- habits --

class HabitsBlock extends TodayBlock {
  const HabitsBlock();

  @override
  TodayBlockId get id => TodayBlockId.habits;

  @override
  String title(AppLocalizations l) => l.todayBlockHabits;

  @override
  bool isLoading(TodayOverview o) => o.habits == null;

  @override
  bool isEmpty(TodayOverview o) => o.habits?.isEmpty ?? true;

  @override
  Widget build(BuildContext context, TodayOverview o) {
    final habits = o.habits ?? const <TodayHabitEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (habits.every((h) => h.resolved))
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.xs),
            child: Text(context.l10n.todayAllHabitsDone, style: context.text.titleSmall),
          ),
        for (final h in habits) HabitRow(entry: h),
      ],
    );
  }

  @override
  Widget empty(BuildContext context) => _Empty(
    icon: Icons.repeat,
    title: context.l10n.todayEmptyHabits,
    action: context.l10n.todayEmptyHabitsAction,
    onAction: () => unawaited(HabitRoutes.create(context)),
  );
}

/// A habit due today (T8.1.06): progress ring, streak, one-tap check-in (yes/no), +/− for counts,
/// a value sheet for durations / measurements, long press for not done / skip / excuse / note.
class HabitRow extends ConsumerWidget {
  const HabitRow({required this.entry, super.key});

  final TodayHabitEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = todayFormat(context, ref);
    final habit = entry.habit;
    final key = entry.checkInKey;
    final actions = CheckInActions(context, ref);
    final done = entry.explicitState == HabitLogKind.done || entry.resolved;
    Widget control;
    if (key == null) {
      control = Text(
        entry.nextSlot == null
            ? ''
            : l.todayHabitNextSlot(
                fmt.timeOf(
                  ref.read(zoneResolverProvider).toLocal(entry.nextSlot!.windowStart, ref.read(deviceZoneProvider)),
                ),
              ),
        style: context.text.bodySmall,
      );
    } else if (entry.isMeasurable) {
      control = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${formatAmount(context, entry.achieved, null)}/${formatAmount(context, entry.target, habit.goal.unit)}',
          ),
          IconButton(
            key: ValueKey('habit-plus-${habit.id}'),
            tooltip: l.habitsActionAddValue,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final step = habit.settings.incrementStep;
              if (habit.goal.type.name == 'count') {
                await actions.addProgress(habit, key, step);
                return;
              }
              final value = await showValueSheet(context, habit);
              if (value != null && context.mounted) await actions.addProgress(habit, key, value);
            },
          ),
        ],
      );
    } else {
      control = Checkbox(
        key: ValueKey('habit-check-${habit.id}'),
        value: done,
        semanticLabel: habit.name,
        onChanged: (v) => unawaited(actions.setState(habit, key, (v ?? false) ? CheckInState.done : null)),
      );
    }
    return ListTile(
      key: ValueKey('habit-row-${habit.id}'),
      dense: true,
      leading: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          value: entry.progress.clamp(0, 1).toDouble(),
          backgroundColor: context.colors.surfaceContainerHighest,
          semanticsLabel: habit.name,
        ),
      ),
      title: Text(habit.name),
      subtitle: entry.currentStreak > 0 ? Text(l.todayHabitStreak(entry.currentStreak)) : null,
      trailing: control,
      onTap: () => unawaited(HabitRoutes.detail(context, habit.id)),
      onLongPress: key == null
          ? null
          : () => unawaited(
              showAppSheet<void>(
                context,
                builder: (sheet) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: Text(l.habitsActionNotDone),
                      onTap: () {
                        Navigator.pop(sheet);
                        unawaited(actions.setState(habit, key, CheckInState.notDone));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.redo),
                      title: Text(l.habitsActionSkip),
                      onTap: () {
                        Navigator.pop(sheet);
                        unawaited(actions.skipOrExcuse(habit, key, CheckInState.skip));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.beach_access_outlined),
                      title: Text(l.habitsActionExcuse),
                      onTap: () {
                        Navigator.pop(sheet);
                        unawaited(actions.skipOrExcuse(habit, key, CheckInState.excuse));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: Text(l.habitsActionNoteMood),
                      onTap: () {
                        Navigator.pop(sheet);
                        unawaited(showNoteMoodSheet(context, ref, habit, key));
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ----------------------------------------------------------------------------------------- quit --

class QuitBlock extends TodayBlock {
  const QuitBlock();

  @override
  TodayBlockId get id => TodayBlockId.quit;

  @override
  String title(AppLocalizations l) => l.todayBlockQuit;

  @override
  bool isLoading(TodayOverview o) => o.quits == null;

  @override
  bool isEmpty(TodayOverview o) => o.quits?.isEmpty ?? true;

  @override
  Widget build(BuildContext context, TodayOverview o) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (final q in o.quits ?? const <TodayQuitEntry>[]) QuitRow(entry: q)],
  );

  @override
  Widget empty(BuildContext context) => _Empty(
    icon: Icons.smoke_free,
    title: context.l10n.todayEmptyQuit,
    action: context.l10n.todayEmptyQuitAction,
    onAction: () => unawaited(HabitRoutes.create(context, kind: 'quit')),
  );
}

/// A quit tracker (T8.1.07): live clean time (shared 1 Hz ticker), money saved, next milestone,
/// *Log craving* and *Log relapse*.
class QuitRow extends ConsumerWidget {
  const QuitRow({required this.entry, super.key});

  final TodayQuitEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = todayFormat(context, ref);
    final habit = entry.habit;
    final money = entry.moneySaved;
    final next = entry.nextMilestone;
    return Card(
      key: ValueKey('quit-row-${habit.id}'),
      margin: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
      child: InkWell(
        onTap: () => unawaited(HabitRoutes.quit(context, habit.id)),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.name, style: context.text.titleSmall),
              if (entry.isReduce)
                Text(l.todayQuitUsedToday(formatAmount(context, entry.usedToday ?? 0, habit.unit)))
              else
                LiveCounter(since: entry.abstinenceStart, size: CounterSize.compact),
              Text(
                [
                  if (money != null && entry.currency != null)
                    l.todayQuitSaved(fmt.currency(money.toDouble(), entry.currency!)),
                  if (next != null) l.todayQuitNextMilestone(fmt.duration(next.tMin.inMinutes)),
                ].join(' · '),
                style: context.text.bodySmall,
              ),
              Wrap(
                spacing: Space.sm,
                children: [
                  ActionChip(
                    key: ValueKey('quit-craving-${habit.id}'),
                    avatar: const Icon(Icons.bolt_outlined),
                    label: Text(l.quitLogCraving),
                    onPressed: () => unawaited(logQuickCraving(context, ref, habit)),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.restart_alt),
                    label: Text(entry.isReduce ? l.quitLogUse : l.quitLogRelapse),
                    onPressed: () => unawaited(
                      entry.isReduce ? showUseSheet(context, ref, habit) : showRelapseSheet(context, ref, habit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------------- checklists --

class ChecklistsBlock extends TodayBlock {
  const ChecklistsBlock();

  @override
  TodayBlockId get id => TodayBlockId.checklists;

  @override
  String title(AppLocalizations l) => l.todayBlockChecklists;

  @override
  bool isLoading(TodayOverview o) => o.pinned == null || o.dueItems == null || o.followUps == null;

  @override
  bool isEmpty(TodayOverview o) =>
      (o.pinned?.isEmpty ?? true) && (o.dueItems?.isEmpty ?? true) && (o.followUps?.isEmpty ?? true);

  @override
  Widget build(BuildContext context, TodayOverview o) => ChecklistsSummary(overview: o);

  @override
  Widget empty(BuildContext context) => _Empty(
    icon: Icons.push_pin_outlined,
    title: context.l10n.todayEmptyChecklists,
    action: context.l10n.todayEmptyChecklistsAction,
    onAction: () => context.go(AppLinks.lists()),
  );
}

/// Pinned lists with progress, items due today, follow-ups that have come (T8.1.08).
class ChecklistsSummary extends ConsumerWidget {
  const ChecklistsSummary({required this.overview, super.key});

  final TodayOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    Future<void> complete(TodayChecklistItem i) async {
      final record = await ref.read(checklistServiceProvider).changeStatus(i.checklistId, [i.id], ItemStatus.completed);
      if (record != null && context.mounted) {
        showUndoSnackBar(context, ref, message: l.actionDone, record: record);
      }
    }

    Widget item(TodayChecklistItem i, {required bool followUp}) => ListTile(
      key: ValueKey('today-item-${i.id}'),
      dense: true,
      leading: followUp
          ? Icon(i.status == ItemStatus.blocked ? Icons.block : Icons.hourglass_empty)
          : Checkbox(value: false, semanticLabel: i.text, onChanged: (_) => unawaited(complete(i))),
      title: Text(i.text),
      subtitle: Text([i.checklistTitle, ?i.parentText, if (followUp) ?i.statusNote].join(' › ')),
      onTap: () => unawaited(openChecklist(context, i.checklistId, itemId: i.id)),
    );

    final pinned = overview.pinned ?? const <TodayPinnedChecklist>[];
    final due = overview.dueItems ?? const <TodayChecklistItem>[];
    final follow = overview.followUps ?? const <TodayChecklistItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in pinned)
          ListTile(
            key: ValueKey('pinned-${c.id}'),
            dense: true,
            leading: Icon(Icons.push_pin, color: c.color == null ? null : Color(c.color!)),
            title: Text(c.title),
            subtitle: LinearProgressIndicator(value: c.progress),
            trailing: Text(l.todayListProgress(c.done, c.total)),
            onTap: () => unawaited(openChecklist(context, c.id)),
          ),
        if (due.isNotEmpty) ...[_SubHeader(l.todayDueItems), for (final i in due) item(i, followUp: false)],
        if (follow.isNotEmpty) ...[_SubHeader(l.todayFollowUps), for (final i in follow) item(i, followUp: true)],
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
    child: Text(text, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
  );
}

// ---------------------------------------------------------------------------------------- inbox --

class InboxBlock extends TodayBlock {
  const InboxBlock();

  @override
  TodayBlockId get id => TodayBlockId.inbox;

  @override
  String title(AppLocalizations l) => l.todayBlockInbox;

  @override
  bool isLoading(TodayOverview o) => o.unreadInbox == null;

  @override
  bool isEmpty(TodayOverview o) => (o.unreadInbox ?? 0) == 0;

  @override
  Widget build(BuildContext context, TodayOverview o) => _InboxSummary(overview: o);

  @override
  Widget empty(BuildContext context) => _Empty(icon: Icons.notifications_none, title: context.l10n.todayInboxUnread(0));
}

class _InboxSummary extends ConsumerWidget {
  const _InboxSummary({required this.overview});

  final TodayOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = todayFormat(context, ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in (overview.inboxHighlights ?? const []).take(3))
          InboxTile(item: i, format: fmt, now: overview.now, dense: true),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => unawaited(context.push(AppLinks.inbox())),
            child: Text('${l.todayInboxUnread(overview.unreadInbox ?? 0)} · ${l.todayOpenInbox}'),
          ),
        ),
      ],
    );
  }
}
