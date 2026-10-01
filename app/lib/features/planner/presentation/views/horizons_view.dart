import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/goal_providers.dart' show goalsProvider;
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/planner/application/view_config/horizon_actions.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/horizons.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart' show weekStartFor;
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Horizons view (T3.7.11, Timestripe style): side-by-side intention lists for Day, Week, Month,
/// Quarter and Year — unscheduled tasks with a `horizon_key`. Add per column, drag a card to
/// another horizon (moves it to that horizon's current period) or onto a day of this week below
/// (scheduled into that day's first free slot), and *Make it a goal* links it to [5.4].
class HorizonsView extends ConsumerWidget {
  const HorizonsView({required this.args, super.key});

  final PlannerViewArgs args;

  String get _key => args.viewKey;

  String _label(BuildContext context, Horizon h) {
    final l = context.l10n;
    return switch (h) {
      Horizon.day => l.pvHorizonDay,
      Horizon.week => l.pvHorizonWeek,
      Horizon.month => l.pvHorizonMonth,
      Horizon.quarter => l.pvHorizonQuarter,
      Horizon.year => l.pvHorizonYear,
    };
  }

  Future<void> _schedule(BuildContext context, WidgetRef ref, Task task, LocalDate day) async {
    final work = ref.read(plannerWorkSettingsProvider);
    final today = ref.read(plannerTodayProvider);
    final minutes = task.estimateMinutes ?? task.durationMinutes ?? work.defaultDuration;
    final dayItems = ref.read(viewItemsProvider(DayRange(day, 1))).value ?? const <PlannerItem>[];
    final start =
        scheduleOnDay(
          day: day,
          items: dayItems,
          durations: [minutes],
          options: FreeSlotOptions(window: work.hours, workDays: work.days),
          notBefore: day == today ? ref.read(plannerNowProvider) : null,
        ).single ??
        day.atStartOfDay.plusMinutes(work.hours.startMinute);
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    await PlannerCommands(context, ref).track(
      context.l10n.pvMovedSnack('${f.dayShort(day)} ${f.timeOf(start)}'),
      () => ref.read(horizonActionsProvider).schedule(task, start, minutes),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final config = ref.watch(plannerViewConfigProvider(_key));
    final weekStart = weekStartFor(config, prefs.weekStart);
    final today = ref.watch(plannerTodayProvider);
    final tasks = ref.watch(horizonTasksProvider);
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final goalSeries = {
      for (final g in goals)
        if (g.scopeType == GoalScopeType.series && g.scopeId != null) g.scopeId!,
    };
    final week = today.startOfWeek(weekStart);
    // Warm the week's occurrences so drops can find free slots.
    for (var i = 0; i < 7; i++) {
      ref.watch(viewItemsProvider(DayRange(week.plusDays(i), 1)));
    }
    final f = context.plannerFormat(use24h: prefs.use24h);
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
                  l.pvHorizonsHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium,
                ),
              ),
              PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
            ],
          ),
        ),
      ),
      body: AsyncValueView<List<Task>>(
        value: tasks,
        data: (list) {
          final byHorizon = {for (final h in Horizon.values) h: <Task>[]};
          for (final t in list) {
            final h = Horizon.of(t.horizonKey);
            if (h != null) byHorizon[h]!.add(t);
          }
          for (final l in byHorizon.values) {
            l.sort((a, b) => a.horizonKey!.compareTo(b.horizonKey!));
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('horizons-board'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(Space.sm),
                  children: [
                    for (final h in Horizon.values)
                      _HorizonColumn(
                        key: ValueKey('horizon-${h.name}'),
                        title: _label(context, h),
                        currentKey: h.keyFor(today, weekStart),
                        tasks: byHorizon[h]!,
                        goalSeries: goalSeries,
                        isPast: (t) => horizonIsPast(t.horizonKey!, today, weekStart),
                        onDrop: (t) => unawaited(
                          PlannerCommands(context, ref).track(
                            _label(context, h),
                            () => ref.read(horizonActionsProvider).move(t, h.keyFor(today, weekStart)),
                          ),
                        ),
                        onAdd: (title) => unawaited(
                          PlannerCommands(context, ref).track(
                            l.pvCreatedSnack,
                            () => ref.read(horizonActionsProvider).create(title, h.keyFor(today, weekStart)),
                          ),
                        ),
                        onGoal: (t) => unawaited(ref.read(horizonActionsProvider).linkGoal(t, today, weekStart)),
                        onOpen: (t) => ref.read(plannerNavProvider).openTaskId(context, t.id),
                      ),
                  ],
                ),
              ),
              // Drop onto a day of this week to schedule.
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: DragTarget<Task>(
                          key: ValueKey('horizon-day-${week.plusDays(i).toIso()}'),
                          onAcceptWithDetails: (d) => unawaited(_schedule(context, ref, d.data, week.plusDays(i))),
                          builder: (context, candidates, _) => Container(
                            margin: const EdgeInsets.all(Space.xxs),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: candidates.isNotEmpty
                                  ? context.colors.primaryContainer
                                  : context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(Radii.md),
                              border: week.plusDays(i) == today ? Border.all(color: context.colors.primary) : null,
                            ),
                            child: Text(
                              f.dayShort(week.plusDays(i)),
                              textAlign: TextAlign.center,
                              style: context.text.labelSmall,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HorizonColumn extends StatefulWidget {
  const _HorizonColumn({
    required this.title,
    required this.currentKey,
    required this.tasks,
    required this.goalSeries,
    required this.isPast,
    required this.onDrop,
    required this.onAdd,
    required this.onGoal,
    required this.onOpen,
    super.key,
  });

  final String title;
  final String currentKey;
  final List<Task> tasks;
  final Set<String> goalSeries;
  final bool Function(Task t) isPast;
  final ValueChanged<Task> onDrop;
  final ValueChanged<String> onAdd;
  final ValueChanged<Task> onGoal;
  final ValueChanged<Task> onOpen;

  @override
  State<_HorizonColumn> createState() => _HorizonColumnState();
}

class _HorizonColumnState extends State<_HorizonColumn> {
  final _add = TextEditingController();

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) => d.data.horizonKey != widget.currentKey,
      onAcceptWithDetails: (d) => widget.onDrop(d.data),
      builder: (context, candidates, _) => Container(
        width: 240,
        margin: const EdgeInsetsDirectional.only(end: Space.sm),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? c.primaryContainer.withValues(alpha: 0.5) : c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(
                '${widget.title} · ${widget.tasks.length}',
                style: context.text.titleSmall,
                semanticsLabel: '${widget.title}, ${l.pvItemsCount(widget.tasks.length)}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: TextField(
                key: ValueKey('horizon-add-${widget.currentKey.split(':').first}'),
                controller: _add,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.pvAddTask,
                  prefixIcon: const Icon(Icons.add, size: 18),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (v) {
                  final t = v.trim();
                  if (t.isEmpty) return;
                  _add.clear();
                  widget.onAdd(t);
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Space.xs),
                children: [
                  for (final t in widget.tasks)
                    LongPressDraggable<Task>(
                      data: t,
                      feedback: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        child: SizedBox(width: 220, child: _Card(task: t, past: false, goal: false)),
                      ),
                      childWhenDragging: Opacity(opacity: 0.35, child: _Card(task: t, past: false, goal: false)),
                      child: GestureDetector(
                        onTap: () => widget.onOpen(t),
                        child: _Card(
                          key: ValueKey('horizon-card-${t.id}'),
                          task: t,
                          past: widget.isPast(t),
                          goal: widget.goalSeries.contains(t.seriesId),
                          onGoal: widget.goalSeries.contains(t.seriesId) ? null : () => widget.onGoal(t),
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

class _Card extends StatelessWidget {
  const _Card({required this.task, required this.past, required this.goal, this.onGoal, super.key});

  final Task task;
  final bool past;
  final bool goal;
  final VoidCallback? onGoal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(color: past ? c.error : null),
              ),
            ),
            if (goal)
              Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Icon(Icons.flag, size: 18, color: c.primary, semanticLabel: l.pvGoalLinked),
              )
            else if (onGoal != null)
              IconButton(
                key: ValueKey('horizon-goal-${task.id}'),
                tooltip: l.pvMakeGoal,
                icon: const Icon(Icons.outlined_flag, size: 18),
                onPressed: onGoal,
              ),
          ],
        ),
      ),
    );
  }
}
