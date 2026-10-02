import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/quick_parse.dart';
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
  final _title = QuickParseController();
  final _focus = FocusNode();
  late LocalDateTime _start = widget.initial.start ?? _defaultStart();
  late int _duration = widget.initial.durationMinutes ?? ref.read(plannerSettingsProvider).defaultTaskDurationMinutes;
  bool _allDay = false;
  late String? _checklistId = widget.initial.checklistId;
  String? _habitId;

  /// Natural-language parsing of task titles (T8.1.17).
  bool _smart = true;
  QuickParse? _parsed;

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

  QuickParse? get _smartParse => _type == QuickAddType.task && _smart ? _parsed : null;

  void _reparse() {
    final on = _type == QuickAddType.task && _smart && _title.text.trim().isNotEmpty;
    final now = ref.read(zoneResolverProvider).toLocal(ref.read(clockProvider).nowUtc(), ref.read(deviceZoneProvider));
    _parsed = on
        ? QuickParser.parse(_title.text, now: now, weekStart: ref.read(userPreferencesProvider).weekStart)
        : null;
    _title.spans = _parsed?.spans ?? const [];
  }

  String? _categoryIdOf(String? name) {
    if (name == null) return null;
    final key = Collation.key(name);
    return (ref.read(categoriesProvider).value ?? const []).where((c) => Collation.key(c.name) == key).firstOrNull?.id;
  }

  Future<bool> _add() async {
    final l = context.l10n;
    var title = _title.text.trim();
    if (_needsTitle && title.isEmpty) return false;
    switch (_type) {
      case QuickAddType.task:
        final p = _smartParse;
        if (p != null && p.recognizedAnything) {
          title = p.title;
          final date = p.date;
          await ref
              .read(plannerServiceProvider)
              .createAt(
                date == null ? _start : LocalDateTime(date, p.time ?? _start.time),
                p.durationMinutes ?? _duration,
                title: title,
                allDay: p.allDay || (date == null && _allDay),
                recurrence: p.rule,
                categoryId: _categoryIdOf(p.category),
                priority: p.priority?.index ?? 0,
              );
        } else {
          await ref.read(plannerServiceProvider).createAt(_start, _duration, title: title, allDay: _allDay);
        }
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
    // Keeps categories loaded for `#category` lookups.
    ref.watch(categoriesProvider);
    String typeLabel(QuickAddType t) => switch (t) {
      QuickAddType.task => l.quickAddTask,
      QuickAddType.list => l.quickAddList,
      QuickAddType.item => l.quickAddItem,
      QuickAddType.habit => l.quickAddHabit,
      QuickAddType.quit => l.quickAddQuit,
      QuickAddType.log => l.quickAddLog,
    };
    return Padding(
      // showAppSheet already lifts the sheet above the keyboard.
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
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
                  onSelected: (_) => setState(() {
                    _type = t;
                    _reparse();
                  }),
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
              decoration: InputDecoration(
                labelText: l.quickAddTitleHint,
                hintText: _type == QuickAddType.task && _smart ? l.quickAddSmartHint : null,
              ),
              onChanged: (_) => setState(_reparse),
              onSubmitted: (_) => unawaited(_addAndClose()),
            ),
          if (_smartParse case final p? when p.recognizedAnything) ...[
            const SizedBox(height: Space.sm),
            QuickParsePreview(parse: p, fallbackStart: _start, categoryKnown: _categoryIdOf(p.category) != null),
          ],
          if (_type == QuickAddType.task && !(_smartParse?.recognizedAnything ?? false)) ...[
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
          if (_type == QuickAddType.task)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilterChip(
                key: const ValueKey('quick-smart'),
                avatar: const Icon(Icons.auto_awesome_outlined),
                label: Text(l.quickAddSmart),
                selected: _smart,
                onSelected: (v) => setState(() {
                  _smart = v;
                  _reparse();
                }),
              ),
            ),
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

/// Title field that highlights what the quick-add parser recognized (T8.1.17).
class QuickParseController extends TextEditingController {
  List<QuickSpan> spans = const [];

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final visible = [
      for (final s in spans)
        if (s.end <= text.length) s,
    ];
    if (visible.isEmpty || (withComposing && value.isComposingRangeValid)) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final mark = (style ?? const TextStyle()).copyWith(
      color: context.colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: context.colors.primary,
    );
    final children = <TextSpan>[];
    var at = 0;
    for (final s in visible) {
      if (s.start < at) continue;
      if (s.start > at) children.add(TextSpan(text: text.substring(at, s.start)));
      children.add(TextSpan(text: text.substring(s.start, s.end), style: mark));
      at = s.end;
    }
    if (at < text.length) children.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: children);
  }
}

/// What the parsed phrase will create, before saving (T8.1.17).
class QuickParsePreview extends ConsumerWidget {
  const QuickParsePreview({required this.parse, required this.fallbackStart, required this.categoryKnown, super.key});

  final QuickParse parse;
  final LocalDateTime fallbackStart;
  final bool categoryKnown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final p = parse;
    final start = p.date == null ? null : LocalDateTime(p.date!, p.time ?? fallbackStart.time);
    String? repeat;
    if (p.rule case final rule?) {
      try {
        repeat = ref
            .watch(recurrenceServiceProvider)
            .describe(
              rule,
              RecurrenceAnchor(start ?? fallbackStart, ref.watch(deviceZoneProvider), allDay: p.allDay),
              locale: context.localeName,
              use24h: prefs.use24h,
            );
      } on Object {
        repeat = null;
      }
    }
    Widget chip(IconData icon, String label, {Key? key, bool warn = false}) => Chip(
      key: key,
      avatar: Icon(icon, size: 18, color: warn ? context.colors.error : null),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
    return Wrap(
      key: const ValueKey('quick-parsed'),
      spacing: Space.sm,
      runSpacing: Space.xs,
      children: [
        if (start != null)
          chip(
            Icons.event,
            p.allDay
                ? '${fmt.dateMedium(start.date)} · ${l.todayAllDay}'
                : '${fmt.dateMedium(start.date)} ${fmt.timeOf(start)}',
            key: const ValueKey('quick-parsed-start'),
          ),
        if (p.durationMinutes case final d?)
          chip(Icons.timelapse, fmt.duration(d), key: const ValueKey('quick-parsed-duration')),
        if (repeat != null && repeat.isNotEmpty) chip(Icons.repeat, repeat, key: const ValueKey('quick-parsed-repeat')),
        if (p.category case final c?)
          chip(
            categoryKnown ? Icons.label_outline : Icons.label_off_outlined,
            categoryKnown ? '#$c' : l.quickAddUnknownCategory(c),
            key: const ValueKey('quick-parsed-category'),
            warn: !categoryKnown,
          ),
        if (p.priority case final pr?)
          chip(
            Icons.flag_outlined,
            PriorityStyle.label(context, pr.index),
            key: const ValueKey('quick-parsed-priority'),
          ),
      ],
    );
  }
}
