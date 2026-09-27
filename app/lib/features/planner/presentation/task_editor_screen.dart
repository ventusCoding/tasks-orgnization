import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart'
    show ItemKind, NotificationRulesDraft, NotificationSection, NotificationSettingsSection, NotificationTargetType;
import 'package:everslot/features/organization/application/providers.dart' show categoryByIdProvider, tagByIdProvider;
import 'package:everslot/features/organization/presentation/categories_screen.dart' show pickCategory;
import 'package:everslot/features/organization/presentation/tag_widgets.dart' show EntityTagChips, TagChip, pickTags;
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_form.dart';
import 'package:everslot/features/planner/domain/task_validation.dart';
import 'package:everslot/features/planner/presentation/markdown_lite_view.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:everslot/features/planner/presentation/templates_sheet.dart';
import 'package:everslot/features/planner/presentation/value_tile.dart';
import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

/// Localized message of a task validation error.
String taskErrorText(AppLocalizations l, TaskValidationError e) => switch (e) {
  TaskValidationError.titleEmpty => l.tasksErrTitleEmpty,
  TaskValidationError.titleTooLong => l.tasksErrTitleTooLong,
  TaskValidationError.durationOutOfRange => l.tasksErrDuration,
  TaskValidationError.allDayNotMidnight ||
  TaskValidationError.allDayPartialDay ||
  TaskValidationError.allDayZeroLength => l.tasksErrAllDay,
  TaskValidationError.recurrenceWithoutStart => l.tasksErrRecurrenceNoDate,
  TaskValidationError.recurrenceInvalid => l.tasksErrRecurrenceInvalid,
  TaskValidationError.zoneInvalid => l.tasksErrZone,
  TaskValidationError.priorityOutOfRange => l.tasksErrPriority,
  TaskValidationError.urlInvalid => l.tasksUrlInvalid,
  TaskValidationError.estimateOutOfRange => l.tasksErrEstimate,
};

bool _validZone(String zone) {
  if (zone == 'UTC') return true;
  try {
    tz.getLocation(zone);
    return true;
  } on Object {
    return false;
  }
}

/// Full task editor (T3.1.06, T3.1.07): title, date and 1-minute start, duration or end, all-day
/// range, backlog, zone mode, repeat (recurrence picker), deadline, category, color, priority,
/// tracking mode, icon, notes (markdown-lite), location, URL, linked checklist, tags,
/// attachments and reminders. Recurring edits ask for the scope; orphaned occurrences are
/// confirmed. Keeps the class name/constructor used by the router (plus [occurrenceKey]).
class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({
    this.taskId,
    this.initialStart,
    this.initialDurationMinutes,
    this.allDay = false,
    this.occurrenceKey,
    this.initialTitle,
    super.key,
  });

  final String? taskId;

  /// ISO local start (`YYYY-MM-DDTHH:mm` or `YYYY-MM-DD`) of a new task.
  final String? initialStart;
  final int? initialDurationMinutes;
  final bool allDay;

  /// Occurrence being edited (recurring tasks): the form shows it and saving asks the scope.
  final String? occurrenceKey;

  /// Title typed in the quick-create sheet (*More options*).
  final String? initialTitle;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late final String _id = widget.taskId ?? Ids.v7();
  bool get _isNew => widget.taskId == null;

  Task? _task;
  TaskForm? _initial;
  TaskForm? _form;
  bool _missing = false;
  bool _saving = false;
  bool _saved = false;
  bool _submitted = false;

  /// Set right before a programmatic close so the [PopScope] lets it through.
  bool _allowPop = false;
  String? _anchorNote;
  Set<String> _newTags = {};
  List<PlannerItem> _overlaps = const [];
  Timer? _overlapTimer;

  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _location = TextEditingController();
  final _url = TextEditingController();
  final _reminders = NotificationRulesDraft();

  late final PlannerService _service = ref.read(plannerServiceProvider);

  /// Bound in [initState]: [dispose] must not touch `ref` (discarding an abandoned draft).
  Future<void> Function(String taskId)? _discardDraft;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _discardDraft = _service.draftDiscarder();
      final settings = ref.read(plannerSettingsProvider);
      final start = _parseStart(widget.initialStart) ?? nextQuarterHour(_service.nowLocal);
      final form = TaskForm.create(
        start: start,
        durationMinutes: widget.initialDurationMinutes ?? settings.defaultTaskDurationMinutes,
        allDay: widget.allDay,
        trackingMode: settings.defaultTrackingMode,
      ).copyWith(title: widget.initialTitle ?? '');
      _setForm(form, initial: true);
    } else {
      unawaited(_load());
    }
  }

  static LocalDateTime? _parseStart(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return LocalDateTime.tryParse(raw) ?? LocalDate.tryParse(raw)?.atStartOfDay;
  }

  Future<void> _load() async {
    final queries = ref.read(plannerQueriesProvider);
    final task = await queries.task(widget.taskId!);
    if (!mounted) return;
    if (task == null) {
      setState(() => _missing = true);
      return;
    }
    TaskOccurrenceRecord? record;
    final key = widget.occurrenceKey;
    if (key != null) {
      record = (await queries.records([task.id])).where((r) => r.occurrenceKey == key).firstOrNull;
    }
    if (!mounted) return;
    _task = task;
    _setForm(TaskForm.fromTask(task, occurrenceKey: key, record: record), initial: true);
  }

  void _setForm(TaskForm form, {bool initial = false}) {
    setState(() {
      _form = form;
      if (initial) {
        _initial = form;
        _title.text = form.title;
        _notes.text = form.notes;
        _location.text = form.location;
        _url.text = form.url;
      }
    });
    _scheduleOverlapCheck();
  }

  void _update(TaskForm Function(TaskForm f) change) {
    final form = _form;
    if (form == null) return;
    final next = change(form);
    final timingChanged = next.startLocal != form.startLocal || next.effectiveDurationMinutes != form.effectiveDurationMinutes;
    setState(() => _form = next);
    if (timingChanged) _scheduleOverlapCheck();
  }

  void _scheduleOverlapCheck() {
    _overlapTimer?.cancel();
    _overlapTimer = Timer(const Duration(milliseconds: 250), _checkOverlaps);
  }

  Future<void> _checkOverlaps() async {
    final form = _form;
    final start = form?.startLocal;
    if (form == null || start == null || form.allDay || !mounted) {
      if (mounted && _overlaps.isNotEmpty) setState(() => _overlaps = const []);
      return;
    }
    final service = _service;
    final viewerStart = service.toViewerLocal(form.zoneId, start);
    final overlaps = await service.overlapsFor(
      start: viewerStart,
      durationMinutes: form.durationMinutes,
      excludeTaskId: _isNew ? null : _id,
      excludeKey: null,
    );
    if (mounted) setState(() => _overlaps = overlaps);
  }

  bool get _dirty {
    final form = _form;
    final initial = _initial;
    if (form == null || initial == null || _saved || _allowPop) return false;
    return form.diff(initial).isNotEmpty || (_isNew && (_newTags.isNotEmpty || !_reminders.isEmpty));
  }

  @override
  void dispose() {
    _overlapTimer?.cancel();
    _title.dispose();
    _notes.dispose();
    _location.dispose();
    _url.dispose();
    _reminders.dispose();
    if (_isNew && !_saved) unawaited(_discardDraft?.call(_id));
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Save

  Future<void> _save() async {
    final form = _form;
    if (form == null || _saving) return;
    final l = context.l10n;
    setState(() => _submitted = true);
    final errors = form.validate(isValidZone: _validZone);
    if (errors.isNotEmpty) {
      showInfoSnackBar(context, taskErrorText(l, errors.first));
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isNew) {
        final draft = form.applyTo(Task(id: _id, seriesId: '', title: '', trackingMode: form.trackingMode));
        await _service.createTask(draft, reminders: _reminders, tagIds: _newTags);
        _finish(l.tasksCreated);
        return;
      }
      await _saveEdit(form);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEdit(TaskForm form) async {
    final l = context.l10n;
    final service = _service;
    final current = await service.queries.task(_id) ?? _task!;
    final changed = form.diff(_initial!);
    if (changed.isEmpty) {
      _finish(null);
      return;
    }
    var edited = form.applyTo(current);
    var scope = EditScope.allOccurrences;
    var rewritePast = false;
    var policy = OrphanPolicy.keepAsOneOff;
    final key = widget.occurrenceKey;
    final timing = TaskForm.isTimingChange(changed);
    if (current.isRecurring) {
      if (key != null) {
        final choice = await showEditScopeDialog(
          context,
          thisAllowed: changed.every(TaskForm.occurrenceFields.contains),
          timingChange: timing,
        );
        if (choice == null || !mounted) return;
        scope = choice.scope;
        rewritePast = choice.rewritePast;
      } else if (timing) {
        // Series editor: only "all occurrences" makes sense; past ones keep their times
        // unless the user rewrites them (T3.2.08).
        final choice = await showEditScopeDialog(
          context,
          thisAllowed: false,
          followingAllowed: false,
          timingChange: true,
        );
        if (choice == null || !mounted) return;
        rewritePast = choice.rewritePast;
      }
      edited = _forScope(current, edited, form, changed, scope);
      if (timing && scope != EditScope.thisOccurrence) {
        final report = await service.previewOrphans(edited, scope: scope, occurrenceKey: key, rewritePast: rewritePast);
        if (!mounted) return;
        if (!report.isEmpty) {
          final picked = await showOrphansDialog(context, report);
          if (picked == null || !mounted) return;
          policy = picked;
        }
      }
    }
    await service.updateTask(
      edited,
      scope: scope,
      occurrenceKey: current.isRecurring ? key : null,
      rewritePast: rewritePast,
      orphanPolicy: policy,
    );
    _finish(l.tasksSaved);
  }

  /// The form shows one occurrence: unchanged occurrence-level fields keep the series values,
  /// and the start is re-expressed for the chosen scope.
  Task _forScope(Task current, Task edited, TaskForm form, Set<String> changed, EditScope scope) {
    final key = widget.occurrenceKey;
    if (key == null) return edited;
    var t = edited;
    if (!changed.contains('title')) t = t.copyWith(title: current.title);
    if (!changed.contains('notes')) t = t.copyWith(notes: current.notes);
    if (!changed.contains('duration') && !changed.contains('allDay')) t = t.copyWith(durationMinutes: current.durationMinutes);
    final original = LocalDateTime.tryParse(key) ?? LocalDate.tryParse(key)?.atStartOfDay;
    final startChanged = changed.contains('start');
    switch (scope) {
      case EditScope.thisOccurrence:
        return t;
      case EditScope.thisAndFollowing:
        return startChanged || original == null ? t : t.copyWith(startLocal: original);
      case EditScope.allOccurrences:
        final seriesStart = current.startLocal;
        final from = _initial!.startLocal;
        final to = form.startLocal;
        if (!startChanged || seriesStart == null || from == null || to == null) return t.copyWith(startLocal: seriesStart);
        return t.copyWith(startLocal: seriesStart.plusMinutes(from.minutesUntil(to)));
    }
  }

  /// Lets the [PopScope] rebuild with `canPop: true`, then closes the editor.
  void _popNow() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _finish(String? message) {
    _saved = true;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final undo = context.l10n.actionUndo;
    _popNow();
    if (message != null && messenger != null) {
      final stack = ref.read(undoStackProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(message),
          action: SnackBarAction(label: undo, onPressed: () => stack.undo()),
        ));
    }
  }

  Future<void> _close() async {
    if (!_dirty) {
      _popNow();
      return;
    }
    final l = context.l10n;
    final discard = await confirmDialog(
      context,
      title: l.tasksUnsavedTitle,
      body: l.tasksUnsavedBody,
      confirmLabel: l.tasksDiscard,
      destructive: true,
    );
    if (discard && mounted) _popNow();
  }

  Future<void> _delete() async {
    final task = _task;
    if (task == null) return;
    final l = context.l10n;
    var scope = EditScope.allOccurrences;
    if (task.isRecurring && widget.occurrenceKey != null) {
      final choice = await showEditScopeDialog(context, deleting: true);
      if (choice == null) return;
      scope = choice.scope;
    } else {
      final ok = await confirmDialog(
        context,
        title: l.tasksDeleteConfirmTitle,
        body: l.tasksDeleteConfirmBody,
        confirmLabel: l.actionDelete,
        destructive: true,
      );
      if (!ok) return;
    }
    await _service.deleteTask(task.id, scope: scope, occurrenceKey: widget.occurrenceKey);
    _finish(scope == EditScope.thisOccurrence ? l.tasksOccurrenceDeleted : l.tasksDeleted);
  }

  Future<void> _fromTemplate() async {
    final template = await showTemplatesSheet(context);
    final form = _form;
    if (template == null || form == null || !mounted) return;
    final draft = _service.draftFromTemplate(template, start: form.startLocal, allDay: form.allDay);
    _setForm(TaskForm.fromTask(draft).copyWith(date: form.date), initial: false);
    _title.text = draft.title;
    _notes.text = draft.notes ?? '';
    _location.text = draft.location ?? '';
    _url.text = draft.url ?? '';
  }

  Future<void> _saveAsTemplate() async {
    final form = _form;
    if (form == null) return;
    final l = context.l10n;
    if (form.title.trim().isEmpty) {
      showInfoSnackBar(context, l.tasksErrTitleEmpty);
      return;
    }
    await _service.saveAsTemplate(form.applyTo(_task ?? Task(id: '', seriesId: '', title: form.title)));
    if (mounted) showPlannerUndoSnack(context, ref, l.tasksTemplateSaved);
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final form = _form;
    final title = _isNew
        ? l.tasksEditorNewTitle
        : (widget.occurrenceKey != null ? l.tasksEditorEditOccurrenceTitle : l.tasksEditorEditTitle);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: l.actionClose, icon: const Icon(Icons.close), onPressed: _close),
          title: Text(title),
          actions: [
            TextButton(
              key: const ValueKey('task-save'),
              onPressed: form == null || _saving ? null : _save,
              child: Text(l.actionSave),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('task-editor-menu'),
              onSelected: (v) => switch (v) {
                'template' => _fromTemplate(),
                'save-template' => _saveAsTemplate(),
                'delete' => _delete(),
                _ => Future<void>.value(),
              },
              itemBuilder: (_) => [
                if (_isNew) PopupMenuItem(value: 'template', child: Text(l.tasksFromTemplate)),
                PopupMenuItem(value: 'save-template', child: Text(l.tasksSaveAsTemplate)),
                if (!_isNew) PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
              ],
            ),
          ],
        ),
        body: _missing
            ? EmptyState(title: l.tasksDetailNotFound, icon: Icons.search_off)
            : form == null
            ? const LoadingState()
            : _fields(context, form),
      ),
    );
  }

  Widget _fields(BuildContext context, TaskForm form) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final errors = _submitted ? form.validate(isValidZone: _validZone).toSet() : const <TaskValidationError>{};
    final recurring = form.isRecurring;
    return ListView(
      key: const ValueKey('task-editor-list'),
      padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: TextField(
            key: const ValueKey('task-title'),
            controller: _title,
            autofocus: _isNew && form.title.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            style: context.text.titleLarge,
            decoration: InputDecoration(
              labelText: l.tasksFieldTitle,
              hintText: l.tasksFieldTitleHint,
              errorText: errors.contains(TaskValidationError.titleEmpty)
                  ? l.tasksErrTitleEmpty
                  : (errors.contains(TaskValidationError.titleTooLong) ? l.tasksErrTitleTooLong : null),
            ),
            onChanged: (v) => _update((f) => f.copyWith(title: v)),
          ),
        ),
        _scheduleSection(context, form, format, prefs.use24h, prefs.weekStart),
        const Divider(),
        _detailsSection(context, form, format),
        const Divider(),
        SectionHeader(l.tasksFieldNotes),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: MarkdownLiteField(
            fieldKey: const ValueKey('task-notes'),
            controller: _notes,
            onChanged: (v) => _update((f) => f.copyWith(notes: v)),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: TextField(
            key: const ValueKey('task-location'),
            controller: _location,
            decoration: InputDecoration(labelText: l.tasksFieldLocation, prefixIcon: const Icon(Icons.place_outlined)),
            onChanged: (v) => _update((f) => f.copyWith(location: v)),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: TextField(
            key: const ValueKey('task-url'),
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l.tasksFieldUrl,
              prefixIcon: const Icon(Icons.link),
              errorText: TaskUrl.isValid(form.url) ? null : l.tasksUrlInvalid,
              suffixIcon: form.url.trim().isNotEmpty && TaskUrl.isValid(form.url)
                  ? IconButton(
                      tooltip: l.tasksOpenLinkTitle,
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => openExternalLink(context, TaskUrl.normalize(form.url)!),
                    )
                  : null,
            ),
            onChanged: (v) => _update((f) => f.copyWith(url: v)),
          ),
        ),
        const SizedBox(height: Space.sm),
        _checklistTile(context, form),
        SectionHeader(l.tasksFieldTags),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: _isNew ? _newTagsEditor(context) : EntityTagChips(entityType: 'task', entityId: _id, editable: true),
        ),
        SectionHeader(l.tasksAttachments),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: AttachmentStrip(ownerType: 'task', ownerId: _id),
        ),
        SectionHeader(l.tasksReminders),
        NotificationSettingsSection(
          targetType: NotificationTargetType.task,
          targetId: _id,
          section: NotificationSection.planner,
          itemKind: form.isBacklog ? ItemKind.dateOnly : (form.allDay ? ItemKind.allDay : ItemKind.timed),
          categoryId: form.categoryId,
          draft: _isNew ? _reminders : null,
        ),
        if (recurring && !_isNew && widget.occurrenceKey == null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
            child: Text(l.tasksScopePastKept, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
      ],
    );
  }

  Widget _scheduleSection(BuildContext context, TaskForm form, AppFormat format, bool use24h, Weekday weekStart) {
    final l = context.l10n;
    final start = form.startLocal;
    final service = ref.read(recurrenceServiceProvider);
    final errors = _submitted ? form.validate(isValidZone: _validZone).toSet() : const <TaskValidationError>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('task-backlog'),
          secondary: const Icon(Icons.inbox_outlined),
          title: Text(l.tasksFieldNoDate),
          value: form.isBacklog,
          onChanged: (on) {
            if (on && form.isRecurring) return;
            _update((f) => f.withBacklog(on, today: _service.nowLocal.date));
          },
        ),
        if (!form.isBacklog) ...[
          SwitchListTile(
            key: const ValueKey('task-all-day'),
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: Text(l.tasksFieldAllDay),
            value: form.allDay,
            onChanged: (on) => _update((f) => f.withAllDay(on)),
          ),
          ValueTile(
            key: const ValueKey('task-date'),
            icon: Icons.event_outlined,
            label: form.allDay ? l.tasksFieldStartDate : l.tasksFieldDate,
            value: format.dateMedium(form.date!),
            onTap: () async {
              final d = await pickDate(context, initial: form.date);
              if (d != null) _update((f) => f.copyWith(date: d));
            },
          ),
          if (form.allDay)
            ValueTile(
              key: const ValueKey('task-end-date'),
              icon: Icons.event_available_outlined,
              label: l.tasksFieldEndDate,
              value: format.dateMedium(form.lastAllDayDate!),
              onTap: () async {
                final d = await pickDate(context, initial: form.lastAllDayDate, first: form.date);
                if (d != null) _update((f) => f.withAllDayEnd(d));
              },
            )
          else ...[
            ValueTile(
              key: const ValueKey('task-start'),
              icon: Icons.schedule,
              label: l.tasksFieldStart,
              value: format.timeOf(start!),
              onTap: () async {
                final t = await pickTime(context, initial: form.startTime, use24h: use24h);
                if (t != null) _update((f) => f.copyWith(startTime: t));
              },
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              child: Wrap(
                spacing: Space.sm,
                children: [
                  ChoiceChip(
                    key: const ValueKey('task-duration-mode'),
                    label: Text(l.tasksDurationMode),
                    selected: !form.endMode,
                    onSelected: (_) => _update((f) => f.copyWith(endMode: false)),
                  ),
                  ChoiceChip(
                    key: const ValueKey('task-end-mode'),
                    label: Text(l.tasksEndMode),
                    selected: form.endMode,
                    onSelected: (_) => _update((f) => f.copyWith(endMode: true)),
                  ),
                ],
              ),
            ),
            if (form.endMode)
              ValueTile(
                key: const ValueKey('task-end'),
                icon: Icons.schedule_outlined,
                label: l.tasksFieldEnd,
                value: form.endDayOffset > 0
                    ? '${format.timeOf(form.endLocal!)} (${l.tasksPlusDays(form.endDayOffset)})'
                    : format.timeOf(form.endLocal!),
                onTap: () async {
                  final t = await pickTime(context, initial: form.endLocal!.time, use24h: use24h);
                  if (t != null) _update((f) => f.withEnd(t));
                },
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
                child: Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    for (final m in taskDurationChips)
                      ChoiceChip(
                        key: ValueKey('task-duration-$m'),
                        label: Text(format.duration(m)),
                        selected: form.durationMinutes == m,
                        onSelected: (_) => _update((f) => f.copyWith(durationMinutes: m)),
                      ),
                    ActionChip(
                      key: const ValueKey('task-duration-custom'),
                      avatar: const Icon(Icons.tune, size: 18),
                      label: Text(
                        taskDurationChips.contains(form.durationMinutes)
                            ? l.tasksCustomDuration
                            : format.duration(form.durationMinutes),
                      ),
                      onPressed: () async {
                        final m = await pickDuration(context, initialMinutes: form.durationMinutes);
                        if (m != null) _update((f) => f.copyWith(durationMinutes: m));
                      },
                    ),
                  ],
                ),
              ),
            if (errors.contains(TaskValidationError.durationOutOfRange))
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
                child: Text(l.tasksErrDuration, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
              ),
          ],
          _zoneTiles(context, form),
          _repeatTile(context, form, format, service),
          if (_overlaps.isNotEmpty) _overlapHint(context, format),
        ] else
          ValueTile(
            key: const ValueKey('task-estimate'),
            icon: Icons.hourglass_empty,
            label: l.tasksFieldEstimate,
            value: form.estimateMinutes == null ? '—' : format.duration(form.estimateMinutes!),
            onTap: () async {
              final m = await pickDuration(context, initialMinutes: form.estimateMinutes ?? 30);
              if (m != null) _update((f) => f.copyWith(estimateMinutes: m));
            },
          ),
        ValueTile(
          key: const ValueKey('task-deadline'),
          icon: Icons.flag_outlined,
          label: l.tasksFieldDeadline,
          value: form.deadline == null ? l.tasksDeadlineNone : _deadlineLabel(format, form.deadline!),
          note: form.plannedAfterDeadline
              ? Text(l.tasksDeadlineWarning, style: context.text.bodySmall?.copyWith(color: context.appColors.warning))
              : null,
          action: form.deadline == null
              ? null
              : IconButton(
                  tooltip: l.actionClear,
                  icon: const Icon(Icons.clear),
                  onPressed: () => _update((f) => f.copyWith(deadline: null)),
                ),
          onTap: () async {
            final d = await pickDate(context, initial: form.deadline?.date ?? form.date);
            if (d == null || !mounted) return;
            final t = await pickTime(context, initial: form.deadline?.time ?? LocalTime(23, 59), use24h: use24h);
            _update((f) => f.copyWith(deadline: d.atTime(t ?? LocalTime(23, 59))));
          },
        ),
      ],
    );
  }

  static String _deadlineLabel(AppFormat format, LocalDateTime deadline) =>
      deadline.time == LocalTime(23, 59) ? format.dateMedium(deadline.date) : format.dateTime(deadline);

  Widget _zoneTiles(BuildContext context, TaskForm form) {
    final l = context.l10n;
    final fixed = form.zoneId != null;
    final service = _service;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
          child: Text(l.tasksFieldTimeZone, style: context.text.labelLarge),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: Space.sm,
            children: [
              ChoiceChip(
                key: const ValueKey('task-zone-floating'),
                label: Text(l.tasksZoneFloating),
                tooltip: l.tasksZoneFloatingHint,
                selected: !fixed,
                onSelected: (_) => _update((f) => f.withZone(null)),
              ),
              ChoiceChip(
                key: const ValueKey('task-zone-fixed'),
                label: Text(l.tasksZoneFixed),
                tooltip: l.tasksZoneFixedHint,
                selected: fixed,
                onSelected: (_) => _update((f) => f.withZone(f.zoneId ?? service.viewerZone)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, 0),
          child: Text(
            fixed ? l.tasksZoneFixedHint : l.tasksZoneFloatingHint,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        if (fixed)
          ValueTile(
            key: const ValueKey('task-zone'),
            icon: Icons.public,
            label: form.zoneId!.replaceAll('_', ' '),
            value: zoneOffsetLabel(form.zoneId!, service.nowUtc),
            onTap: () async {
              final zone = await pickTimeZone(
                context,
                deviceZone: service.viewerZone,
                nowUtc: service.nowUtc,
                selected: form.zoneId,
              );
              if (zone != null) _update((f) => f.withZone(zone));
            },
          ),
      ],
    );
  }

  Widget _repeatTile(BuildContext context, TaskForm form, AppFormat format, RecurrenceService service) {
    final l = context.l10n;
    final rule = form.recurrence;
    final anchor = form.anchor!;
    String description;
    try {
      description = rule == null
          ? l.tasksRepeatNone
          : service.describe(rule, anchor, locale: context.localeName, use24h: format.use24h);
    } on Object {
      description = l.tasksErrRecurrenceInvalid;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const ValueKey('task-repeat'),
          leading: const Icon(Icons.repeat),
          title: Text(l.tasksFieldRepeat),
          subtitle: Text(description, key: const ValueKey('task-repeat-description')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final result = await showRecurrencePickerDetailed(
              context,
              anchor: anchor,
              initial: rule,
              mode: RecurrencePickerMode.task,
            );
            if (result == null || !mounted) return;
            final moved = result.rule != null && result.anchor.start != anchor.start;
            _update((f) => f.withRecurrence(result.rule, alignedStart: moved ? result.anchor.start : null));
            setState(() {
              _anchorNote = moved
                  ? l.tasksAnchorMoved(
                      form.allDay ? format.dateMedium(result.anchor.start.date) : format.dateTime(result.anchor.start),
                    )
                  : null;
            });
          },
        ),
        if (_anchorNote != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.xxxl + Space.lg, 0, Space.lg, Space.xs),
            child: Text(
              _anchorNote!,
              key: const ValueKey('task-anchor-note'),
              style: context.text.bodySmall?.copyWith(color: context.colors.primary),
            ),
          ),
      ],
    );
  }

  Widget _overlapHint(BuildContext context, AppFormat format) {
    final l = context.l10n;
    final first = _overlaps.first;
    final more = _overlaps.length - 1;
    final text = [
      l.tasksOverlapHint(BidiText.isolate(first.title), format.timeRange(first.startLocal, first.endLocal)),
      if (more > 0) l.tasksOverlapMore(more),
    ].join(' ');
    return Padding(
      key: const ValueKey('task-overlap'),
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: context.appColors.warning),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: context.text.bodySmall?.copyWith(color: context.appColors.warning))),
        ],
      ),
    );
  }

  Widget _detailsSection(BuildContext context, TaskForm form, AppFormat format) {
    final l = context.l10n;
    final category = ref.watch(categoryByIdProvider(form.categoryId));
    final brightness = Theme.of(context).brightness;
    final colorValue = form.color ?? category?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueTile(
          key: const ValueKey('task-category'),
          leading: Icon(
            IconCatalog.iconFor(category?.icon, fallback: Icons.label_outline),
            color: category == null ? null : CategoryColors.accent(category.color, brightness),
          ),
          label: l.tasksFieldCategory,
          value: category?.name ?? '—',
          onTap: () async {
            final id = await pickCategory(context, ref, selectedId: form.categoryId);
            if (id != null) _update((f) => f.copyWith(categoryId: id.isEmpty ? null : id));
          },
        ),
        ValueTile(
          key: const ValueKey('task-color'),
          leading: colorValue == null
              ? const Icon(Icons.palette_outlined)
              : ColorDot(CategoryColors.accent(colorValue, brightness), size: 20),
          label: l.tasksFieldColor,
          value: form.color == null ? l.tasksColorCategoryDefault : null,
          action: form.color == null
              ? null
              : IconButton(
                  tooltip: l.actionClear,
                  icon: const Icon(Icons.clear),
                  onPressed: () => _update((f) => f.copyWith(color: null)),
                ),
          onTap: () async {
            final c = await pickColor(context, selected: form.color, allowNone: true);
            if (c != null) _update((f) => f.copyWith(color: c == -1 ? null : c));
          },
        ),
        ValueTile(
          key: const ValueKey('task-icon'),
          leading: Icon(IconCatalog.iconFor(form.icon ?? category?.icon, fallback: Icons.emoji_symbols_outlined)),
          label: l.tasksFieldIcon,
          value: form.icon == null ? l.tasksIconDefault : null,
          action: form.icon == null
              ? null
              : IconButton(
                  tooltip: l.actionClear,
                  icon: const Icon(Icons.clear),
                  onPressed: () => _update((f) => f.copyWith(icon: null)),
                ),
          onTap: () async {
            final key = await pickIcon(context, selected: form.icon);
            if (key != null) _update((f) => f.copyWith(icon: key));
          },
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
          child: Text(l.tasksFieldPriority, style: context.text.labelLarge),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
          child: PrioritySelector(value: form.priority, onChanged: (p) => _update((f) => f.copyWith(priority: p))),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: Text(l.tasksFieldTracking, style: context.text.labelLarge),
        ),
        RadioGroup<TrackingMode>(
          groupValue: form.trackingMode,
          onChanged: (m) {
            if (m != null) _update((f) => f.copyWith(trackingMode: m));
          },
          child: Column(
            children: [
              for (final (mode, name, hint) in [
                (TrackingMode.check, l.tasksTrackingCheck, l.tasksTrackingCheckHint),
                (TrackingMode.event, l.tasksTrackingEvent, l.tasksTrackingEventHint),
                (TrackingMode.timer, l.tasksTrackingTimer, l.tasksTrackingTimerHint),
              ])
                RadioListTile<TrackingMode>(
                  key: ValueKey('task-tracking-${mode.name}'),
                  value: mode,
                  title: Text(name),
                  subtitle: Text(hint),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checklistTile(BuildContext context, TaskForm form) {
    final l = context.l10n;
    final id = form.linkedChecklistId;
    final info = id == null ? null : ref.watch(linkedChecklistProvider(id)).value;
    return ValueTile(
      key: const ValueKey('task-checklist'),
      icon: Icons.checklist,
      label: l.tasksFieldChecklist,
      value: id == null
          ? l.tasksChecklistNone
          : (info == null ? null : '${info.title} · ${l.tasksChecklistProgress(info.completed, info.total)}'),
      action: id == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l.tasksChecklistOpen,
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => GoRouter.of(context).push(AppLinks.checklist(id)),
                ),
                IconButton(
                  tooltip: l.tasksChecklistUnlink,
                  icon: const Icon(Icons.link_off),
                  onPressed: () => _update((f) => f.copyWith(linkedChecklistId: null)),
                ),
              ],
            ),
      onTap: () async {
        final choice = await pickLinkedChecklist(context, selected: id);
        if (choice != null) _update((f) => f.copyWith(linkedChecklistId: choice.id));
      },
    );
  }

  Widget _newTagsEditor(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final id in _newTags)
          Consumer(
            builder: (context, ref, _) {
              final tag = ref.watch(tagByIdProvider(id));
              if (tag == null) return const SizedBox.shrink();
              return TagChip(tag: tag, onDeleted: () => setState(() => _newTags = {..._newTags}..remove(id)));
            },
          ),
        ActionChip(
          key: const ValueKey('task-tags-add'),
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l.tasksAddTag),
          onPressed: () async {
            final picked = await pickTags(context, ref, selected: _newTags);
            if (picked != null) setState(() => _newTags = picked);
          },
        ),
      ],
    );
  }
}
