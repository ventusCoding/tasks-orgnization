import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart' show categoryByIdProvider;
import 'package:everslot/features/organization/presentation/categories_screen.dart' show pickCategory;
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Quick-create sheet (T3.1.08): a title and chips for when / duration / repeat / category.
/// *More options* opens the full editor; *Add & new* keeps the sheet open with the next slot.
///
/// [tapped] is the tapped instant (viewer wall clock); [rangeMinutes] a dragged range;
/// [slotMinutes] the grid slot (1 440 = week-list mode → all-day). Without a position the
/// next quarter hour is used. Returns the ids of the created tasks.
Future<List<String>> showQuickCreateSheet(
  BuildContext context, {
  LocalDateTime? tapped,
  int? rangeMinutes,
  int? slotMinutes,
  bool allDay = false,
}) async {
  final created = <String>[];
  await showAppSheet<void>(
    context,
    builder: (_) => QuickCreateSheet(
      tapped: tapped,
      rangeMinutes: rangeMinutes,
      slotMinutes: slotMinutes,
      allDay: allDay,
      onCreated: created.add,
    ),
  );
  return created;
}

class QuickCreateSheet extends ConsumerStatefulWidget {
  const QuickCreateSheet({
    super.key,
    this.tapped,
    this.rangeMinutes,
    this.slotMinutes,
    this.allDay = false,
    this.onCreated,
  });

  final LocalDateTime? tapped;
  final int? rangeMinutes;
  final int? slotMinutes;
  final bool allDay;
  final ValueChanged<String>? onCreated;

  @override
  ConsumerState<QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends ConsumerState<QuickCreateSheet> {
  final _title = TextEditingController();
  final _focus = FocusNode();
  late QuickCreateSlot _slot;
  RecurrenceRule? _rule;
  String? _categoryId;
  bool _busy = false;

  PlannerService get _service => ref.read(plannerServiceProvider);

  @override
  void initState() {
    super.initState();
    final defaultDuration = ref.read(plannerSettingsProvider).defaultTaskDurationMinutes;
    final tapped = widget.tapped ?? nextQuarterHour(_service.nowLocal);
    _slot = widget.allDay
        ? QuickCreateSlot(tapped.date.atStartOfDay, 1440, allDay: true)
        : quickCreateSlot(
            tapped: tapped,
            rangeMinutes: widget.rangeMinutes,
            slotMinutes: widget.slotMinutes,
            defaultDurationMinutes: defaultDuration,
          );
  }

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  RecurrenceAnchor get _anchor => _slot.allDay
      ? RecurrenceAnchor.allDayOn(_slot.start.date, null)
      : RecurrenceAnchor(_slot.start, null, durationMinutes: _slot.durationMinutes);

  Future<void> _add({required bool keepOpen}) async {
    if (_busy) return;
    final l = context.l10n;
    final title = _title.text.trim();
    setState(() => _busy = true);
    try {
      final result = await _service.createTask(
        Task(
          id: '',
          seriesId: '',
          title: title.isEmpty ? l.tasksUntitled : title,
          startLocal: _slot.allDay ? _slot.start.date.atStartOfDay : _slot.start,
          durationMinutes: _slot.durationMinutes,
          isAllDay: _slot.allDay,
          recurrence: _rule,
          categoryId: _categoryId,
          trackingMode: ref.read(plannerSettingsProvider).defaultTrackingMode,
        ),
        source: 'quick',
      );
      widget.onCreated?.call(result.taskId);
      if (!mounted) return;
      if (keepOpen) {
        // Next slot right after this one, same length.
        setState(() {
          _slot = QuickCreateSlot(
            _slot.allDay ? _slot.start.plusDays(1) : _slot.start.plusMinutes(_slot.durationMinutes),
            _slot.durationMinutes,
            allDay: _slot.allDay,
          );
          _title.clear();
          _rule = null;
        });
        _focus.requestFocus();
        showPlannerUndoSnack(context, ref, l.tasksCreated);
      } else {
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.of(context).pop();
        if (messenger != null) {
          final stack = ref.read(undoStackProvider);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l.tasksCreated),
                action: SnackBarAction(label: l.actionUndo, onPressed: stack.undo),
              ),
            );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _more() async {
    final navigator = Navigator.of(context);
    final start = _slot.allDay ? _slot.start.date.toIso() : _slot.start.toIso();
    final title = _title.text.trim();
    navigator.pop();
    await navigator.push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TaskEditorScreen(
          initialStart: start,
          initialDurationMinutes: _slot.durationMinutes,
          allDay: _slot.allDay,
          initialTitle: title.isEmpty ? null : title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final category = ref.watch(categoryByIdProvider(_categoryId));
    final service = ref.watch(recurrenceServiceProvider);
    String repeat;
    try {
      repeat = _rule == null
          ? l.tasksRepeatNone
          : service.describe(_rule!, _anchor, locale: context.localeName, use24h: prefs.use24h);
    } on Object {
      repeat = l.tasksRepeatNone;
    }
    final when = _slot.allDay
        ? format.dayShort(_slot.start.date)
        : '${format.dayShort(_slot.start.date)} ${format.timeRange(_slot.start, _slot.start.plusMinutes(_slot.durationMinutes))}';
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('quick-title'),
            controller: _title,
            focusNode: _focus,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.tasksQuickTitleHint),
            onSubmitted: (_) => _add(keepOpen: false),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              ActionChip(
                key: const ValueKey('quick-when'),
                avatar: const Icon(Icons.event, size: 18),
                label: Text(when),
                onPressed: () async {
                  final date = await pickDate(context, initial: _slot.start.date);
                  if (date == null || !context.mounted) return;
                  if (_slot.allDay) {
                    setState(() => _slot = QuickCreateSlot(date.atStartOfDay, 1440, allDay: true));
                    return;
                  }
                  final time = await pickTime(context, initial: _slot.start.time, use24h: prefs.use24h);
                  if (!mounted) return;
                  setState(() => _slot = QuickCreateSlot(date.atTime(time ?? _slot.start.time), _slot.durationMinutes));
                },
              ),
              if (!_slot.allDay)
                ActionChip(
                  key: const ValueKey('quick-duration'),
                  avatar: const Icon(Icons.timelapse, size: 18),
                  label: Text(format.duration(_slot.durationMinutes)),
                  onPressed: () async {
                    final m = await pickDuration(context, initialMinutes: _slot.durationMinutes);
                    if (m != null && mounted) setState(() => _slot = QuickCreateSlot(_slot.start, m));
                  },
                ),
              ActionChip(
                key: const ValueKey('quick-repeat'),
                avatar: const Icon(Icons.repeat, size: 18),
                label: Text(repeat, maxLines: 1, overflow: TextOverflow.ellipsis),
                onPressed: () async {
                  final result = await showRecurrencePickerDetailed(context, anchor: _anchor, initial: _rule);
                  if (result == null || !mounted) return;
                  setState(() {
                    _rule = result.rule;
                    if (result.rule != null && result.anchor.start != _anchor.start) {
                      _slot = QuickCreateSlot(result.anchor.start, _slot.durationMinutes, allDay: _slot.allDay);
                    }
                  });
                },
              ),
              ActionChip(
                key: const ValueKey('quick-category'),
                avatar: Icon(
                  IconCatalog.iconFor(category?.icon, fallback: Icons.label_outline),
                  size: 18,
                  color: category == null ? null : CategoryColors.accent(category.color, Theme.of(context).brightness),
                ),
                label: Text(category?.name ?? l.tasksFieldCategory),
                onPressed: () async {
                  final id = await pickCategory(context, ref, selectedId: _categoryId);
                  if (id != null && mounted) setState(() => _categoryId = id.isEmpty ? null : id);
                },
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: Space.sm,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton(key: const ValueKey('quick-more'), onPressed: _more, child: Text(l.tasksQuickMore)),
              OutlinedButton(
                key: const ValueKey('quick-add-new'),
                onPressed: _busy ? null : () => _add(keepOpen: true),
                child: Text(l.tasksQuickAddNew),
              ),
              FilledButton(
                key: const ValueKey('quick-add'),
                onPressed: _busy ? null : () => _add(keepOpen: false),
                child: Text(l.tasksQuickAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
