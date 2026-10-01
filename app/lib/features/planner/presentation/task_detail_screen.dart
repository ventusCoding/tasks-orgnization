import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/notifications/presentation/mute_menu.dart' show MuteMenuButton;
import 'package:everslot/features/notifications/presentation/reminder_history.dart' show ReminderHistory;
import 'package:everslot/features/organization/application/providers.dart' show categoryByIdProvider;
import 'package:everslot/features/organization/presentation/tag_widgets.dart' show EntityTagChips;
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/markdown_lite.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/markdown_lite_view.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:everslot/features/planner/presentation/series_history_screen.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:everslot/features/planner/presentation/task_exceptions_sheet.dart';
import 'package:everslot/features/planner/presentation/task_history.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Task details (T3.1.09) with the occurrence sheet content on top when opened for one
/// occurrence (T3.2.05): schedule summary, badges, notes, links, tags, attachments, linked
/// checklist, next occurrences, reminders, history timeline (paged) and the series actions.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, this.occurrenceKey, super.key});

  final String taskId;
  final String? occurrenceKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final taskAsync = ref.watch(taskByIdProvider(taskId));
    final task = taskAsync.value;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tasksDetailTitle)),
        body: taskAsync.isLoading
            ? const LoadingState()
            : EmptyState(title: l.tasksDetailNotFound, icon: Icons.search_off),
      );
    }
    final key = occurrenceKey;
    final occurrence = key == null || key.isEmpty
        ? null
        : ref.watch(occurrenceItemProvider((taskId: taskId, key: key))).value;
    final series = ref.watch(seriesTasksProvider(task.seriesId)).value ?? [task];
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            key: const ValueKey('detail-edit'),
            tooltip: l.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => TaskEditorScreen(
                  taskId: task.id,
                  occurrenceKey: task.isRecurring ? occurrence?.occurrenceKey : null,
                ),
              ),
            ),
          ),
          MuteMenuButton(targetType: 'task', targetId: task.id),
          _DetailMenu(task: task, occurrence: occurrence),
        ],
      ),
      body: _readableWidth(
        context,
        ListView(
          key: const ValueKey('detail-list'),
          padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
          children: [
            if (occurrence != null) ...[OccurrencePanel(item: occurrence), const Divider()],
            _Summary(task: task),
            if (task.notes != null) ...[
              SectionHeader(l.tasksFieldNotes),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
                child: MarkdownLiteView(task.notes!, key: const ValueKey('detail-notes')),
              ),
            ],
            if (task.location != null) ListTile(leading: const Icon(Icons.place_outlined), title: Text(task.location!)),
            if (task.url != null)
              ListTile(
                key: const ValueKey('detail-url'),
                leading: const Icon(Icons.link),
                title: Text(task.url!, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => openExternalLink(context, task.url!),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
              child: EntityTagChips(entityType: 'task', entityId: task.id),
            ),
            if (task.linkedChecklistId != null) _ChecklistProgress(checklistId: task.linkedChecklistId!),
            SectionHeader(l.tasksAttachments),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              child: AttachmentStrip(ownerType: 'task', ownerId: task.id),
            ),
            if (!task.isUnscheduled) ...[SectionHeader(l.tasksNextOccurrences), _NextOccurrences(taskId: task.id)],
            SectionHeader(l.tasksHistory),
            TaskHistoryList(taskIds: [for (final t in series) t.id]),
            ReminderHistory(sourceType: 'task', sourceId: task.id),
          ],
        ),
      ),
    );
  }

  /// Tablets: a centered, readable column instead of a stretched phone layout.
  static Widget _readableWidth(BuildContext context, Widget child) => context.windowSize.isCompact
      ? child
      : Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
        );
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final category = ref.watch(categoryByIdProvider(task.categoryId));
    final service = ref.watch(recurrenceServiceProvider);
    final brightness = Theme.of(context).brightness;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final rule = task.recurrence;
    final anchor = task.anchor;
    String? schedule;
    if (task.isUnscheduled) {
      schedule = task.estimateMinutes == null
          ? l.tasksBacklogLabel
          : '${l.tasksBacklogLabel} · ${l.tasksFieldEstimate}: ${format.duration(task.estimateMinutes!)}';
    } else if (rule != null && anchor != null) {
      schedule = _describe(service, rule, anchor, context.localeName, prefs.use24h);
    } else {
      final start = task.startLocal!;
      schedule = task.isAllDay
          ? format.dateMedium(start.date)
          : '${format.dayLong(start.date)} · ${format.timeRange(start, start.plusMinutes(task.effectiveDurationMinutes))}';
    }
    Occurrence? next;
    if (rule != null && anchor != null) {
      try {
        next = service.nextAfter(rule, anchor);
      } on Object {
        next = null;
      }
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(task.isRecurring ? Icons.repeat : Icons.event_outlined, size: 20),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(schedule, key: const ValueKey('detail-schedule'), style: context.text.titleMedium),
              ),
            ],
          ),
          if (next != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: Space.xl + Space.xs, top: Space.xxs),
              child: Text(
                l.tasksNextLabel(format.dateTime(service.resolver.toLocal(next.startUtc, service.currentZone))),
                style: muted,
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: Space.xl + Space.xs, top: Space.xxs),
            child: Text(
              task.timeZone == null
                  ? '${l.tasksZoneFloating} · ${l.tasksZoneFloatingHint}'
                  : '${l.tasksZoneFixed} · ${l.tasksZoneBadge(task.timeZone!.replaceAll('_', ' '))}',
              style: muted,
            ),
          ),
          if (task.deadlineLocal != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.xs),
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 18, color: context.appColors.warning),
                  const SizedBox(width: Space.xs),
                  Text('${l.tasksFieldDeadline}: ${format.dateTime(task.deadlineLocal!)}'),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              if (category != null)
                StatusPill(
                  label: category.name,
                  color: CategoryColors.accent(category.color, brightness),
                  icon: IconCatalog.iconFor(category.icon),
                ),
              if (task.priority > 0) PriorityBadge(task.priority, showLabel: true),
              StatusPill(
                label: switch (task.trackingMode) {
                  TrackingMode.check => l.tasksTrackingCheck,
                  TrackingMode.event => l.tasksTrackingEvent,
                  TrackingMode.timer => l.tasksTrackingTimer,
                },
                color: context.colors.secondary,
                icon: switch (task.trackingMode) {
                  TrackingMode.check => Icons.check_box_outlined,
                  TrackingMode.event => Icons.event,
                  TrackingMode.timer => Icons.timer_outlined,
                },
              ),
              if (task.isPaused)
                StatusPill(label: l.tasksPausedBadge, color: context.appColors.waiting, icon: Icons.pause),
            ],
          ),
        ],
      ),
    );
  }

  static String _describe(
    RecurrenceService service,
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    String locale,
    bool use24h,
  ) {
    try {
      return service.describe(rule, anchor, locale: locale, use24h: use24h);
    } on Object {
      return '';
    }
  }
}

class _NextOccurrences extends ConsumerWidget {
  const _NextOccurrences({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final items = ref.watch(nextOccurrencesProvider(taskId)).value;
    if (items == null) return const SizedBox(height: 48, child: LoadingState());
    if (items.isEmpty) {
      return Padding(padding: const EdgeInsets.all(Space.lg), child: Text(l.tasksNoUpcoming));
    }
    return Column(
      children: [
        for (final item in items)
          ListTile(
            key: ValueKey('next-${item.occurrenceKey}'),
            dense: true,
            leading: Icon(occurrenceStatusVisual(context, item.status, overdue: item.overdue).icon),
            title: Text(
              item.allDay
                  ? format.dayLong(item.startLocal.date)
                  : '${format.dayLong(item.startLocal.date)} · ${format.timeOf(item.startLocal)}',
            ),
            trailing: StatusPill(
              dense: true,
              label: occurrenceStatusVisual(context, item.status, overdue: item.overdue).label,
              color: occurrenceStatusVisual(context, item.status, overdue: item.overdue).color,
            ),
            onTap: () => showOccurrenceSheet(context, item),
          ),
      ],
    );
  }
}

class _ChecklistProgress extends ConsumerWidget {
  const _ChecklistProgress({required this.checklistId});

  final String checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(linkedChecklistProvider(checklistId)).value;
    if (info == null) return const SizedBox.shrink();
    return ListTile(
      key: const ValueKey('detail-checklist'),
      leading: const Icon(Icons.checklist),
      title: Text(info.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.tasksChecklistProgress(info.completed, info.total)),
          const SizedBox(height: Space.xs),
          LinearProgressIndicator(value: info.progress),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => GoRouter.of(context).push(AppLinks.checklist(checklistId)),
    );
  }
}

/// Series actions: duplicate / duplicate to… / as new series, pause/resume, series history,
/// exceptions, save as template, move to backlog, share as text, delete.
class _DetailMenu extends ConsumerWidget {
  const _DetailMenu({required this.task, this.occurrence});

  final Task task;
  final PlannerItem? occurrence;

  PlannerService _service(WidgetRef ref) => ref.read(plannerServiceProvider);

  Future<void> _run(BuildContext context, WidgetRef ref, String action) async {
    final l = context.l10n;
    final service = _service(ref);
    final prefs = ref.read(userPreferencesProvider);
    switch (action) {
      case 'duplicate':
        await service.duplicate(
          task.id,
          asOneOff: task.isRecurring && occurrence != null,
          occurrenceKey: task.isRecurring ? occurrence?.occurrenceKey : null,
        );
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksDuplicated);
      case 'duplicate-series':
        await service.duplicate(task.id);
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksDuplicated);
      case 'duplicate-to':
        final dates = await showDuplicateToDialog(
          context,
          initialMonth: occurrence?.startLocal.date ?? task.startLocal?.date ?? service.nowLocal.date,
          weekStart: prefs.weekStart,
        );
        if (dates == null || dates.isEmpty) return;
        await service.duplicateToDates(
          task.id,
          dates,
          occurrenceKey: task.isRecurring ? occurrence?.occurrenceKey : null,
        );
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksDuplicatedTo(dates.length));
      case 'pause':
        await service.pauseSeries(task.id);
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksPauseSnack);
      case 'resume':
        await service.resumeSeries(task.id);
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksResumeSnack);
      case 'history':
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => SeriesHistoryScreen(seriesId: task.seriesId, title: task.title),
          ),
        );
      case 'exceptions':
        await showTaskExceptionsSheet(context, taskId: task.id);
      case 'template':
        await service.saveAsTemplate(task);
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksTemplateSaved);
      case 'backlog':
        await service.unschedule(task.id);
        if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksMoved);
      case 'share':
        await SharePlus.instance.share(ShareParams(text: _shareText(context, ref)));
      case 'delete':
        var scope = EditScope.allOccurrences;
        if (task.isRecurring && occurrence != null) {
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
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.maybeOf(context);
        final undoLabel = l.actionUndo;
        final message = scope == EditScope.thisOccurrence ? l.tasksOccurrenceDeleted : l.tasksDeleted;
        await service.deleteTask(task.id, scope: scope, occurrenceKey: occurrence?.occurrenceKey);
        if (scope != EditScope.thisOccurrence && navigator.canPop()) navigator.pop();
        final stack = ref.read(undoStackProvider);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(label: undoLabel, onPressed: stack.undo),
            ),
          );
    }
  }

  String _shareText(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.read(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final service = ref.read(recurrenceServiceProvider);
    final lines = <String>[task.title];
    final start = task.startLocal;
    if (start != null) {
      lines.add(
        task.isAllDay
            ? format.dateMedium(start.date)
            : '${format.dayLong(start.date)} · ${format.timeRange(start, start.plusMinutes(task.effectiveDurationMinutes))}',
      );
    }
    final rule = task.recurrence;
    if (rule != null && task.anchor != null) {
      try {
        lines.add(
          l.tasksShareRepeats(service.describe(rule, task.anchor!, locale: context.localeName, use24h: prefs.use24h)),
        );
      } on Object {
        // no description
      }
    }
    if (task.location != null) lines.add(task.location!);
    if (task.url != null) lines.add(task.url!);
    if (task.notes != null) {
      lines
        ..add('')
        ..add(markdownLiteToPlain(task.notes!));
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recurring = task.isRecurring;
    return PopupMenuButton<String>(
      key: const ValueKey('detail-menu'),
      onSelected: (v) => unawaited(_run(context, ref, v)),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'duplicate', child: Text(l.actionDuplicate)),
        PopupMenuItem(value: 'duplicate-to', child: Text(l.tasksActionDuplicateTo)),
        if (recurring) PopupMenuItem(value: 'duplicate-series', child: Text(l.tasksActionDuplicateSeries)),
        if (recurring)
          PopupMenuItem(
            value: task.isPaused ? 'resume' : 'pause',
            child: Text(task.isPaused ? l.tasksActionResume : l.tasksActionPause),
          ),
        if (recurring) PopupMenuItem(value: 'history', child: Text(l.tasksActionSeriesHistory)),
        if (recurring) PopupMenuItem(value: 'exceptions', child: Text(l.tasksActionExceptions)),
        PopupMenuItem(value: 'template', child: Text(l.tasksSaveAsTemplate)),
        if (!recurring && !task.isUnscheduled) PopupMenuItem(value: 'backlog', child: Text(l.tasksActionUnschedule)),
        PopupMenuItem(value: 'share', child: Text(l.tasksActionShare)),
        PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
      ],
    );
  }
}
