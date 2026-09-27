import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/application/habit_view_settings.dart';
import 'package:everslot/features/habits/application/live_ticker.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/organization/application/providers.dart' show categoriesProvider;
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodResult, PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Today list of [date] (T5.2.03): habits grouped by time-of-day section (current section first),
/// by category or not at all (T5.2.12), inside each *Due* → *Done* → *Not due today* (collapsed, or
/// hidden). With [reordering] every group becomes a drag-to-reorder list.
class TodayList extends ConsumerWidget {
  const TodayList({required this.date, super.key, this.dueOnly = false, this.sectionFilter, this.reordering = false});

  final LocalDate date;
  final bool dueOnly;

  /// Only this section (id), or null for all.
  final String? sectionFilter;

  /// Drag-to-reorder mode (T5.2.12).
  final bool reordering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final viewsAsync = ref.watch(habitDayViewsProvider(date));
    final sections = ref.watch(habitSectionsProvider).value ?? const <HabitSection>[];
    final settings = ref.watch(habitViewSettingsProvider);
    return AsyncValueView<List<HabitDayView>>(
      value: viewsAsync,
      data: (views) {
        if (views.isEmpty) {
          return EmptyState(
            icon: Icons.event_available,
            title: l.habitsNothingThisDay,
            message: l.habitsNothingThisDayBody,
          );
        }
        final groups = _groups(context, ref, views, sections, settings.groupBy);
        final visible = [
          for (final g in groups)
            if (sectionFilter == null || g.section?.id == sectionFilter) g,
        ];
        if (reordering) {
          return ListView(
            padding: const EdgeInsetsDirectional.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
                child: Text(l.habitsReorderHint, style: context.text.bodySmall),
              ),
              for (final g in visible) _ReorderGroup(group: g, key: ValueKey('reorder-${g.key}')),
            ],
          );
        }
        final allHandled = views.every((v) => v.group != DayGroup.due);
        return ListView(
          padding: const EdgeInsetsDirectional.only(bottom: 96),
          children: [
            if (allHandled && views.any((v) => v.group == DayGroup.done))
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Semantics(
                  liveRegion: true,
                  child: Text(l.habitsAllDone, style: context.text.titleMedium, textAlign: TextAlign.center),
                ),
              ),
            for (final g in visible)
              if (!(settings.hideNotDue && g.views.every((v) => v.group == DayGroup.notDue)))
                _SectionBlock(group: g, dueOnly: dueOnly, settings: settings, key: ValueKey('group-${g.key}')),
          ],
        );
      },
    );
  }

  List<_Group> _groups(
    BuildContext context,
    WidgetRef ref,
    List<HabitDayView> views,
    List<HabitSection> sections,
    HabitGroupBy by,
  ) {
    final l = context.l10n;
    switch (by) {
      case HabitGroupBy.none:
        return [_Group('all', l.habitsAllHabits, views)];
      case HabitGroupBy.category:
        final categories = ref.watch(categoriesProvider).value ?? const [];
        final known = {for (final c in categories) c.id};
        final grouped = <String?, List<HabitDayView>>{};
        for (final v in views) {
          final id = known.contains(v.habit.categoryId) ? v.habit.categoryId : null;
          grouped.putIfAbsent(id, () => []).add(v);
        }
        return [
          for (final c in categories)
            if (grouped.containsKey(c.id)) _Group(c.id, c.name, grouped[c.id]!),
          if (grouped.containsKey(null)) _Group('none', l.habitsNoCategory, grouped[null]!),
        ];
      case HabitGroupBy.section:
        final byId = {for (final s in sections) s.id: s};
        final grouped = <String?, List<HabitDayView>>{};
        for (final v in views) {
          final sid = byId.containsKey(v.habit.sectionId) ? v.habit.sectionId : null;
          grouped.putIfAbsent(sid, () => []).add(v);
        }
        String title(HabitSection s) =>
            s.defaultKey != null && s.name.trim().isEmpty ? l.defaultSectionName(s.defaultKey!) : s.name;
        final ordered = [
          for (final s in sections)
            if (grouped.containsKey(s.id)) _Group(s.id, title(s), grouped[s.id]!, section: s),
          if (grouped.containsKey(null)) _Group('none', l.habitsSectionNone, grouped[null]!),
        ];
        // The current section (by its time window) comes first on today's list.
        if (date == ref.read(habitTodayProvider)) {
          final nowLocal = ref.read(recurrenceNowProvider);
          final i = ordered.indexWhere((g) => g.section?.containsTime(nowLocal.time) ?? false);
          if (i > 0) ordered.insert(0, ordered.removeAt(i));
        }
        return ordered;
    }
  }
}

/// Wall-clock now in the device zone (section windows).
final recurrenceNowProvider = Provider<LocalDateTime>((ref) {
  ref.watch(habitTickProvider);
  final service = ref.watch(habitPeriodServiceProvider);
  return service.resolver.toLocal(ref.watch(clockProvider).nowUtc(), service.currentZone);
});

/// A group of the Today list (section, category or everything).
class _Group {
  _Group(this.key, this.title, this.views, {this.section});

  final String key;
  final String title;
  final List<HabitDayView> views;

  /// The time-of-day section (section grouping only).
  final HabitSection? section;
}

class _SectionBlock extends StatefulWidget {
  const _SectionBlock({required this.group, required this.dueOnly, required this.settings, super.key});

  final _Group group;
  final bool dueOnly;
  final HabitViewSettings settings;

  @override
  State<_SectionBlock> createState() => _SectionBlockState();
}

class _SectionBlockState extends State<_SectionBlock> {
  bool _showNotDue = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = widget.settings;
    final views = widget.group.views;
    final due = [for (final v in views) if (v.group == DayGroup.due) v];
    final done = [for (final v in views) if (v.group == DayGroup.done) v];
    final notDue = [for (final v in views) if (v.group == DayGroup.notDue) v];
    final countable = due.length + done.length;
    Widget row(HabitDayView v) => HabitRow(
      view: v,
      compact: settings.compact,
      showStreak: settings.showStreakChips,
      key: ValueKey('row-${v.habit.id}'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          widget.group.title,
          trailing: countable == 0
              ? null
              : Text(l.habitsSectionProgress(done.length, countable), style: context.text.labelMedium),
        ),
        for (final v in due) row(v),
        if (!widget.dueOnly)
          for (final v in done) row(v),
        if (notDue.isNotEmpty && !widget.dueOnly && !settings.hideNotDue) ...[
          ListTile(
            dense: true,
            title: Text(l.habitsGroupNotDue(notDue.length), style: context.text.labelLarge),
            trailing: Icon(_showNotDue ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showNotDue = !_showNotDue),
          ),
          if (_showNotDue)
            for (final v in notDue) row(v),
        ],
      ],
    );
  }
}

/// Drag-to-reorder list of one group (T5.2.12): the order is saved as fractional sort keys.
class _ReorderGroup extends ConsumerWidget {
  const _ReorderGroup({required this.group, super.key});

  final _Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final habits = [for (final v in group.views) v.habit];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(group.title),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) async {
            if (from == to) return;
            final record = await ref.read(habitServiceProvider).reorder(habits[from].id, habits, to);
            if (context.mounted) showUndoSnackBar(context, ref, message: l.habitsReordered, record: record);
          },
          children: [
            for (var i = 0; i < habits.length; i++)
              ListTile(
                key: ValueKey('reorder-row-${habits[i].id}'),
                leading: HabitAvatar(habit: habits[i], size: 32),
                title: Text(habits[i].name),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    container: true,
                    label: l.habitsDragHandle(habits[i].name),
                    child: const SizedBox(width: 48, height: 48, child: Icon(Icons.drag_handle)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One habit on the Today list: icon, name, progress text, streak chip and the goal's primary
/// action; swipe start→end = done / quick value, end→start = reveal *Not done* & *Skip* (full swipe
/// = not done), long-press = full menu. Directions mirror in RTL.
class HabitRow extends ConsumerWidget {
  const HabitRow({required this.view, super.key, this.compact = false, this.showStreak = true});

  final HabitDayView view;
  final bool compact;

  /// Show the streak chip (view setting, T5.2.12).
  final bool showStreak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final habit = view.habit;
    final actions = CheckInActions(context, ref);
    final subtitle = _subtitle(context, view);
    final status = view.status;
    final style = StatusStyle.of(context, status);

    Future<void> primarySwipe() async {
      if (view.future) return;
      if (habit.goal.isMeasurable && !view.isQuota) {
        final step = habit.settings.quickValues.isNotEmpty ? habit.settings.quickValues.first : habit.settings.incrementStep;
        await actions.addProgress(habit, view.key, step);
      } else {
        await actions.setState(habit, view.key, CheckInState.done);
      }
    }

    final row = Material(
      color: context.colors.surface,
      child: InkWell(
        onTap: () => HabitRoutes.detail(context, habit.id),
        onLongPress: () => showHabitActionsSheet(context, ref, view),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(Space.lg, compact ? Space.xs : Space.sm, Space.sm, compact ? Space.xs : Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HabitAvatar(habit: habit, size: compact ? 32 : 40),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (subtitle.isNotEmpty) Text(subtitle, style: context.text.bodySmall),
                            if (view.atRisk)
                              StatusPill(label: l.habitsAtRisk, color: context.appColors.warning, icon: Icons.warning_amber, dense: true),
                            if (view.explicit != null || status == PeriodStatus.missed || status == PeriodStatus.paused)
                              HabitStatusPill(status),
                            if (showStreak && view.streak > 0) StreakChip(view.streak),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  _PrimaryAction(view: view, style: style),
                ],
              ),
              if (view.isSlot && view.slots.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 52, top: Space.xs),
                  child: SlotChips(view: view),
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      customSemanticsActions: {
        if (!view.future) CustomSemanticsAction(label: l.habitsActionDone): () => unawaited(primarySwipe()),
        if (!view.future) CustomSemanticsAction(label: l.habitsActionNotDone): () =>
            unawaited(actions.setState(habit, view.key, CheckInState.notDone)),
        CustomSemanticsAction(label: l.habitsActionSkip): () =>
            unawaited(actions.skipOrExcuse(habit, view.key, CheckInState.skip)),
      },
      child: SwipeActionRow(
        enabled: !view.future,
        onSwipeStart: primarySwipe,
        startLabel: habit.goal.isMeasurable ? l.habitsActionAddValue : l.habitsActionDone,
        endActions: [
          SwipeAction(
            label: l.habitsActionNotDone,
            icon: Icons.cancel_outlined,
            color: context.appColors.danger,
            onTap: () => actions.setState(habit, view.key, CheckInState.notDone),
          ),
          SwipeAction(
            label: l.habitsActionSkip,
            icon: Icons.redo,
            color: context.appColors.skipped,
            onTap: () => actions.skipOrExcuse(habit, view.key, CheckInState.skip),
          ),
        ],
        child: row,
      ),
    );
  }

  static String _subtitle(BuildContext context, HabitDayView v) {
    final l = context.l10n;
    final goal = v.habit.goal;
    if (v.isQuota && v.quota != null) {
      final q = v.quota!;
      final done = q.flags.activeDays ?? q.achieved.round();
      final times = q.flags.requiredDays ?? q.target.round();
      final isMonth = q.key.startsWith('month:');
      final base = isMonth ? l.habitsQuotaMonth(done, times) : l.habitsQuotaWeek(done, times);
      if (goal.isMeasurable) {
        return '$base · ${formatAmount(context, q.achieved, goal.unit)} / ${formatAmount(context, q.target, goal.unit)}';
      }
      return base;
    }
    if (v.isSlot) {
      final done = v.slots.where((s) => s.status == PeriodStatus.done).length;
      return l.habitsSlotsProgress(done, v.slots.length);
    }
    if (!goal.isMeasurable) return '';
    if (goal.isLimit) {
      final left = v.target - v.achieved;
      if (left < 0) return l.habitsOverLimit;
      return l.habitsLeftOfLimit(formatValue(context, left), formatAmount(context, v.target, goal.unit));
    }
    return '${formatValue(context, v.achieved)} / ${formatAmount(context, v.target, goal.unit)}';
  }
}

/// The goal's primary action: yes/no → one-tap ring; count → stepper; duration → timer; numeric →
/// value sheet.
class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.view, required this.style});

  final HabitDayView view;
  final StatusStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final habit = view.habit;
    final actions = CheckInActions(context, ref);
    if (view.future) return HabitStatusPill(view.status);
    if (view.isSlot) {
      return IconButton(
        tooltip: l.habitsActionCheckNow,
        icon: const Icon(Icons.task_alt),
        onPressed: () => actions.checkNow(habit),
      );
    }
    final goal = habit.goal;
    final accent = habitAccent(context, habit);
    if (!goal.isMeasurable || view.isQuota) {
      final done = view.status == PeriodStatus.done || view.explicit?.kind == HabitLogKind.done;
      final ring = ProgressRing(
        progress: view.progress,
        size: 36,
        color: accent,
        child: Icon(done ? Icons.check : style.icon, size: 18, color: done ? accent : style.color),
      );
      if (!done && ref.watch(habitViewSettingsProvider).holdToComplete) {
        return HoldToCompleteRing(
          label: l.habitsActionDone,
          hint: l.habitsHoldRingHint,
          progress: view.progress,
          color: accent,
          onComplete: () => actions.setState(habit, view.key, CheckInState.done),
          child: Icon(style.icon, size: 18, color: style.color),
        );
      }
      return Semantics(
        button: true,
        checked: done,
        label: done ? l.habitsActionUndoDone : l.habitsActionDone,
        excludeSemantics: true,
        child: InkResponse(
          radius: 28,
          onTap: () => actions.setState(habit, view.key, done ? null : CheckInState.done),
          child: SizedBox(width: 48, height: 48, child: Center(child: ring)),
        ),
      );
    }
    return switch (goal.type) {
      HabitGoalType.count => _Stepper(view: view),
      HabitGoalType.duration => _TimerControl(view: view),
      _ => IconButton.filledTonal(
        tooltip: l.habitsActionAddValue,
        icon: const Icon(Icons.add),
        onPressed: () async {
          final value = await showValueSheet(context, habit);
          if (value != null) await actions.addProgress(habit, view.key, value);
        },
      ),
    };
  }
}

/// A yes/no ring that completes on press-and-hold (T5.2.03, T5.2.13): haptic at hold start, the ring
/// fills while held and commits when full; releasing early cancels. With reduce motion there is no
/// fill: a long press completes at once. Screen readers complete it with their long-press action.
class HoldToCompleteRing extends StatefulWidget {
  const HoldToCompleteRing({
    required this.label,
    required this.hint,
    required this.progress,
    required this.color,
    required this.onComplete,
    required this.child,
    super.key,
    this.holdFor = const Duration(milliseconds: 700),
  });

  final String label;
  final String hint;
  final double progress;
  final Color color;
  final Future<void> Function() onComplete;
  final Widget child;
  final Duration holdFor;

  @override
  State<HoldToCompleteRing> createState() => _HoldToCompleteRingState();
}

class _HoldToCompleteRingState extends State<HoldToCompleteRing> with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(vsync: this, duration: widget.holdFor)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) unawaited(_complete());
    });

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    _fill.value = 0;
    unawaited(HapticFeedback.heavyImpact());
    await widget.onComplete();
  }

  void _start() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_fill.forward(from: 0));
  }

  void _cancel() {
    _down = null;
    if (_fill.isAnimating) unawaited(_fill.reverse());
  }

  /// Where the current press started (null = none); moving beyond the slop (a scroll) cancels.
  Offset? _down;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    // The fill follows the raw pointer (the gesture arena would hand long presses to the row's
    // menu); the detector below claims taps and long presses so the row neither opens nor shows
    // its menu while the ring is held.
    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      excludeSemantics: true,
      onLongPress: () => unawaited(_complete()),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: reduced
            ? null
            : (e) {
                _down = e.position;
                _start();
              },
        onPointerMove: reduced
            ? null
            : (e) {
                if (_down != null && (e.position - _down!).distance > kTouchSlop) _cancel();
              },
        onPointerUp: reduced ? null : (_) => _cancel(),
        onPointerCancel: reduced ? null : (_) => _cancel(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onLongPress: reduced ? () => unawaited(_complete()) : () {},
          child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedBuilder(
              animation: _fill,
              builder: (context, child) => ProgressRing(
                progress: _fill.value > widget.progress ? _fill.value : widget.progress,
                size: 36,
                color: widget.color,
                child: child,
              ),
              child: widget.child,
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// +/− stepper with the habit's increment step; press-and-hold repeats and commits once on release.
class _Stepper extends ConsumerStatefulWidget {
  const _Stepper({required this.view});

  final HabitDayView view;

  @override
  ConsumerState<_Stepper> createState() => _StepperState();
}

class _StepperState extends ConsumerState<_Stepper> {
  Timer? _repeat;
  double _pending = 0;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  double get _step => widget.view.habit.settings.incrementStep;

  Future<void> _commit() async {
    _repeat?.cancel();
    _repeat = null;
    final amount = _pending;
    setState(() => _pending = 0);
    if (amount > 0) await CheckInActions(context, ref).addProgress(widget.view.habit, widget.view.key, amount);
  }

  Future<void> _decrement() async {
    final snapshot = widget.view.snapshot;
    final entries = [
      for (final e in snapshot.entriesOf(widget.view.key))
        if (e.kind == HabitLogKind.progress) e,
    ]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    if (entries.isEmpty) return;
    final last = entries.last;
    final service = ref.read(checkInServiceProvider);
    final value = last.value ?? 0;
    final record = value > _step ? await service.updateEntry(last, value: value - _step) : await service.deleteEntry(last);
    if (mounted) showUndoSnackBar(context, ref, message: context.l10n.savedSnack, record: record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = widget.view;
    final shown = v.achieved + _pending;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.habitsDecrease(formatValue(context, _step)),
          onPressed: v.achieved > 0 ? _decrement : null,
          icon: const Icon(Icons.remove),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 32),
          child: Text(
            formatValue(context, shown),
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        GestureDetector(
          onLongPressStart: (_) {
            unawaited(HapticFeedback.mediumImpact());
            setState(() => _pending += _step);
            _repeat = Timer.periodic(const Duration(milliseconds: 180), (_) {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _pending += _step);
            });
          },
          onLongPressEnd: (_) => unawaited(_commit()),
          child: IconButton.filledTonal(
            tooltip: l.habitsIncrease(formatValue(context, _step)),
            onPressed: () async {
              setState(() => _pending += _step);
              await _commit();
            },
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Start / pause / stop timer for duration goals (running state persisted locally).
class _TimerControl extends ConsumerStatefulWidget {
  const _TimerControl({required this.view});

  final HabitDayView view;

  @override
  ConsumerState<_TimerControl> createState() => _TimerControlState();
}

class _TimerControlState extends ConsumerState<_TimerControl> {
  SharedTicker? _ticker;

  @override
  void dispose() {
    _ticker?.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _listen(bool running) {
    if (running && _ticker == null) {
      final ticker = ref.read(sharedTickerProvider);
      ticker.addListener(_onTick);
      _ticker = ticker;
    } else if (!running && _ticker != null) {
      _ticker!.removeListener(_onTick);
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = widget.view;
    final habit = v.habit;
    final key = v.key;
    final timers = ref.watch(habitTimersProvider).value ?? const <HabitTimer>[];
    final row = timers.where((t) => t.habitId == habit.id && t.key == key).firstOrNull;
    final running = row?.running ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _listen(running);
    });
    final store = ref.read(habitTimerStoreProvider);
    // Read the clock when a button is pressed, not at build time (the row may be stale).
    DateTime now() => ref.read(clockProvider).nowUtc();
    if (row == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l.habitsActionAddValue,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final minutes = await showValueSheet(context, habit);
              if (minutes != null && context.mounted) await CheckInActions(context, ref).addProgress(habit, key, minutes);
            },
          ),
          IconButton.filledTonal(
            tooltip: l.habitsActionStartTimer,
            icon: const Icon(Icons.play_arrow),
            onPressed: () => store.start(habit.id, key, now()),
          ),
        ],
      );
    }
    final seconds = row.elapsedSeconds(now());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: false,
          label: l.habitsTimerElapsed(seconds ~/ 60),
          excludeSemantics: true,
          child: Text(
            AppFormat.counter(Duration(seconds: seconds)),
            style: context.text.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        IconButton(
          tooltip: running ? l.habitsActionPauseTimer : l.habitsActionStartTimer,
          icon: Icon(running ? Icons.pause : Icons.play_arrow),
          onPressed: () => running ? store.pause(habit.id, key, now()) : store.start(habit.id, key, now()),
        ),
        IconButton.filledTonal(
          tooltip: l.habitsActionStopTimer,
          icon: const Icon(Icons.stop),
          onPressed: () async {
            final total = await store.stop(habit.id, key, now());
            if (total <= 0 || !context.mounted) return;
            final minutes = math.max(1, (total / 60).round()).toDouble();
            await CheckInActions(context, ref).addProgress(habit, key, minutes, durationSeconds: total);
          },
        ),
      ],
    );
  }
}

/// Slot chips of a day (T5.2.05): tap toggles that slot; the current slot is highlighted; more than 8
/// slots scroll horizontally.
class SlotChips extends ConsumerWidget {
  const SlotChips({required this.view, super.key});

  final HabitDayView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = view.snapshot.now;
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h);
    final actions = CheckInActions(context, ref);
    final chips = [
      for (final r in view.slots) _chip(context, r, slotChipState(r, now), fmt, () {
        final done = r.status == PeriodStatus.done;
        unawaited(actions.setState(view.habit, r.key, done ? null : CheckInState.done));
      }),
    ];
    final label = l.habitsSlotsProgress(view.slots.where((s) => s.status == PeriodStatus.done).length, view.slots.length);
    if (chips.length > 8) {
      return Semantics(
        label: label,
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
            itemBuilder: (_, i) => chips[i],
          ),
        ),
      );
    }
    return Semantics(label: label, child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: chips));
  }

  Widget _chip(BuildContext context, PeriodResult r, SlotChipState state, AppFormat fmt, VoidCallback onTap) {
    final time = LocalDateTime.tryParse(r.key)?.time ?? LocalTime.midnight;
    final style = StatusStyle.of(context, r.status);
    final current = state == SlotChipState.current;
    final done = state == SlotChipState.done;
    return Semantics(
      button: true,
      checked: done,
      label: '${fmt.time(time)}, ${context.l10n.statusLabel(r.status)}',
      excludeSemantics: true,
      child: FilterChip(
        visualDensity: VisualDensity.compact,
        selected: done,
        showCheckmark: false,
        avatar: Icon(done ? Icons.check : style.icon, size: 16, color: style.color),
        side: current ? BorderSide(color: context.colors.primary, width: 2) : null,
        label: Text(fmt.time(time)),
        onSelected: view.future || r.windowStart.isAfter(view.snapshot.now) && !current ? null : (_) => onTap(),
      ),
    );
  }
}

/// One revealed action behind a row.
class SwipeAction {
  const SwipeAction({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;
}

/// Horizontal swipe gestures (mirrored in RTL): start→end triggers [onSwipeStart]; end→start reveals
/// [endActions] and a full swipe triggers the first of them.
class SwipeActionRow extends StatefulWidget {
  const SwipeActionRow({
    required this.child,
    required this.onSwipeStart,
    required this.startLabel,
    required this.endActions,
    super.key,
    this.enabled = true,
  });

  final Widget child;
  final Future<void> Function() onSwipeStart;
  final String startLabel;
  final List<SwipeAction> endActions;
  final bool enabled;

  @override
  State<SwipeActionRow> createState() => _SwipeActionRowState();
}

class _SwipeActionRowState extends State<SwipeActionRow> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: Motion.fast);
  double _dx = 0;
  double _from = 0;
  double _to = 0;
  static const _actionWidth = 88.0;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() => setState(() => _dx = _from + (_to - _from) * Motion.curve.transform(_anim.value)));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    if (context.reduceMotion) {
      setState(() => _dx = target);
      return;
    }
    _from = _dx;
    _to = target;
    unawaited(_anim.forward(from: 0));
  }

  /// Sign converting a physical drag delta into "towards end" (positive) in the reading direction.
  double get _sign => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final reveal = _actionWidth * widget.endActions.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) {
            setState(() => _dx = (_dx + d.delta.dx * _sign).clamp(-width, width * 0.6));
          },
          onHorizontalDragEnd: (d) async {
            if (_dx > width * 0.3) {
              _animateTo(0);
              unawaited(HapticFeedback.mediumImpact());
              await widget.onSwipeStart();
            } else if (_dx < -width * 0.65 && widget.endActions.isNotEmpty) {
              _animateTo(0);
              unawaited(HapticFeedback.mediumImpact());
              await widget.endActions.first.onTap();
            } else if (_dx < -reveal / 2) {
              _animateTo(-reveal);
            } else {
              _animateTo(0);
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: _dx > 0 ? context.appColors.success.withValues(alpha: 0.18) : Colors.transparent,
                        child: _dx > 0
                            ? Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(start: Space.lg),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, color: context.appColors.success),
                                      const SizedBox(width: Space.xs),
                                      Text(widget.startLabel),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_dx < 0)
                      for (final a in widget.endActions)
                        SizedBox(
                          width: _actionWidth,
                          child: Material(
                            color: a.color.withValues(alpha: 0.9),
                            child: InkWell(
                              onTap: () async {
                                _animateTo(0);
                                await a.onTap();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(a.icon, color: Colors.white),
                                  Text(
                                    a.label,
                                    style: context.text.labelSmall?.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              Transform.translate(offset: Offset(_dx * _sign, 0), child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

/// Shape of a habit's schedule on a date (helper for other widgets).
ScheduleShape shapeOn(WidgetRef ref, BuildHabit habit, List<HabitRevision> revisions, LocalDate date) =>
    ScheduleShape.of(ref.read(habitPeriodServiceProvider).rulesOn(habit, revisions, date).schedule);
