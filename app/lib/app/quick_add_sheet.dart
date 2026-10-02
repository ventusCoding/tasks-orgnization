import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// What the universal quick add creates (T8.1.10).
enum QuickAddType { task, list, item, habit, quit, log }

/// Context a host passes so the sheet starts with smart defaults (a planner slot, the open list…).
class QuickAddContext {
  const QuickAddContext({this.type = QuickAddType.task, this.start, this.durationMinutes, this.checklistId});

  final QuickAddType type;
  final LocalDateTime? start;
  final int? durationMinutes;
  final String? checklistId;
}

/// The universal quick add (T8.1.10): minimal fields per type, *Add & new* keeps the keyboard up
/// for rapid entry, *More options* opens the full editor. Everything writes locally (offline-safe).
Future<void> showQuickAdd(BuildContext context, {QuickAddContext initial = const QuickAddContext()}) =>
    showAppSheet<void>(
      context,
      title: context.l10n.shellQuickAdd,
      builder: (_) => QuickAddSheet(initial: initial),
    );

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({this.initial = const QuickAddContext(), super.key});

  final QuickAddContext initial;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late QuickAddType _type = widget.initial.type;
  final _title = TextEditingController();
  final _focus = FocusNode();
  late LocalDateTime _start = widget.initial.start ?? _defaultStart();
  late int _duration = widget.initial.durationMinutes ?? ref.read(plannerSettingsProvider).defaultTaskDurationMinutes;
  bool _allDay = false;
  late String? _checklistId = widget.initial.checklistId;
  String? _habitId;

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  LocalDateTime _defaultStart() {
    final now = ref.read(zoneResolverProvider).toLocal(ref.read(clockProvider).nowUtc(), ref.read(deviceZoneProvider));
    final minutes = ((now.time.minuteOfDay ~/ 30) + 1) * 30;
    return minutes >= 1440
        ? now.date.plusDays(1).atStartOfDay
        : LocalDateTime(now.date, LocalTime.fromMinuteOfDay(minutes));
  }

  bool get _needsTitle => _type != QuickAddType.log && _type != QuickAddType.quit;

  Future<bool> _add() async {
    final l = context.l10n;
    final title = _title.text.trim();
    if (_needsTitle && title.isEmpty) return false;
    switch (_type) {
      case QuickAddType.task:
        await ref.read(plannerServiceProvider).createAt(_start, _duration, title: title, allDay: _allDay);
      case QuickAddType.list:
        await ref.read(checklistsRepositoryProvider).create(title: title);
      case QuickAddType.item:
        final id = _checklistId;
        if (id == null) return false;
        await ref.read(checklistServiceProvider).appendItems(id, [title]);
      case QuickAddType.habit:
        final today = ref
            .read(zoneResolverProvider)
            .toLocal(ref.read(clockProvider).nowUtc(), ref.read(deviceZoneProvider))
            .date;
        await ref
            .read(habitServiceProvider)
            .create(
              BuildHabit(
                id: Ids.v7(),
                name: title,
                startDate: today,
                sortKey: '',
                goal: const HabitTarget.check(),
                schedule: const SchedulePreset.daily().toRule(weekStart: Weekday.monday),
              ),
            );
      case QuickAddType.quit:
        if (mounted) {
          Navigator.pop(context);
          await HabitRoutes.create(context, kind: 'quit');
        }
        return true;
      case QuickAddType.log:
        final habit = (ref.read(habitsProvider).value ?? const <Habit>[]).where((h) => h.id == _habitId).firstOrNull;
        if (habit == null || !mounted) return false;
        if (habit is QuitHabit) {
          await logQuickCraving(context, ref, habit);
        } else if (habit is BuildHabit) {
          await CheckInActions(context, ref).checkNow(habit);
        }
        return true;
    }
    if (mounted) showInfoSnackBar(context, l.quickAddAdded(title));
    return true;
  }

  Future<void> _more() async {
    Navigator.pop(context);
    switch (_type) {
      case QuickAddType.task:
        await context.push(AppLinks.taskNew(start: _start.toIso(), duration: _duration, allDay: _allDay));
      case QuickAddType.list || QuickAddType.item:
        await context.push(AppLinks.lists());
      case QuickAddType.habit || QuickAddType.log:
        await HabitRoutes.create(context);
      case QuickAddType.quit:
        await HabitRoutes.create(context, kind: 'quit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    final lists = ref.watch(boardChecklistsProvider).value ?? const <Checklist>[];
    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    String typeLabel(QuickAddType t) => switch (t) {
      QuickAddType.task => l.quickAddTask,
      QuickAddType.list => l.quickAddList,
      QuickAddType.item => l.quickAddItem,
      QuickAddType.habit => l.quickAddHabit,
      QuickAddType.quit => l.quickAddQuit,
      QuickAddType.log => l.quickAddLog,
    };
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Space.lg,
        0,
        Space.lg,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final t in QuickAddType.values)
                ChoiceChip(
                  key: ValueKey('quick-type-${t.name}'),
                  label: Text(typeLabel(t)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (_type == QuickAddType.item)
            DropdownButtonFormField<String>(
              key: const ValueKey('quick-list'),
              initialValue: lists.any((c) => c.id == _checklistId) ? _checklistId : null,
              decoration: InputDecoration(labelText: l.quickAddPickList),
              items: [for (final c in lists) DropdownMenuItem(value: c.id, child: Text(c.title))],
              onChanged: (v) => setState(() => _checklistId = v),
            ),
          if (_type == QuickAddType.log)
            DropdownButtonFormField<String>(
              key: const ValueKey('quick-habit'),
              initialValue: _habitId,
              decoration: InputDecoration(labelText: l.quickAddPickHabit),
              items: [
                for (final h in habits)
                  if (!h.isArchived) DropdownMenuItem(value: h.id, child: Text(h.name)),
              ],
              onChanged: (v) => setState(() => _habitId = v),
            ),
          if (_needsTitle)
            TextField(
              key: const ValueKey('quick-title'),
              controller: _title,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l.quickAddTitleHint),
              onSubmitted: (_) => unawaited(_addAndClose()),
            ),
          if (_type == QuickAddType.task) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event),
                  label: Text(fmt.dateMedium(_start.date)),
                  onPressed: () async {
                    final d = await pickDate(context, initial: _start.date);
                    if (d != null) setState(() => _start = LocalDateTime(d, _start.time));
                  },
                ),
                if (!_allDay) ...[
                  ActionChip(
                    avatar: const Icon(Icons.schedule),
                    label: Text(fmt.timeOf(_start)),
                    onPressed: () async {
                      final t = await pickTime(context, initial: _start.time);
                      if (t != null) setState(() => _start = LocalDateTime(_start.date, t));
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.timelapse),
                    label: Text(fmt.duration(_duration)),
                    onPressed: () async {
                      final m = await pickDuration(context, initialMinutes: _duration);
                      if (m != null) setState(() => _duration = m);
                    },
                  ),
                ],
                FilterChip(
                  label: Text(l.todayAllDay),
                  selected: _allDay,
                  onSelected: (v) => setState(() => _allDay = v),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.md),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: Space.sm,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton(onPressed: () => unawaited(_more()), child: Text(l.quickAddMore)),
              if (_needsTitle)
                TextButton(
                  key: const ValueKey('quick-add-new'),
                  onPressed: () async {
                    if (await _add()) {
                      _title.clear();
                      _focus.requestFocus();
                    }
                  },
                  child: Text(l.tasksQuickAddNew),
                ),
              FilledButton(
                key: const ValueKey('quick-add'),
                onPressed: () => unawaited(_addAndClose()),
                child: Text(l.tasksQuickAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addAndClose() async {
    final added = await _add();
    if (added && mounted && _type != QuickAddType.quit) Navigator.pop(context);
  }
}
