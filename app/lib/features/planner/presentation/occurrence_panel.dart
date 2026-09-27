import 'dart:async';

import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot/features/planner/presentation/markdown_lite_view.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the occurrence sheet for [item] (T3.2.05) — views call this when an occurrence is
/// tapped. The sheet stays live: every action shows in all open views within one frame.
Future<void> showOccurrenceSheet(BuildContext context, PlannerItem item) => showAppSheet<void>(
  context,
  builder: (_) => OccurrenceSheet(initial: item),
);

/// Label, color and icon of an occurrence status (color is never the only signal).
({String label, Color color, IconData icon}) occurrenceStatusVisual(
  BuildContext context,
  OccurrenceStatus status, {
  bool overdue = false,
}) {
  final l = context.l10n;
  final c = context.appColors;
  if (overdue) return (label: l.tasksOverdue, color: c.missed, icon: Icons.warning_amber_rounded);
  return switch (status) {
    OccurrenceStatus.scheduled => (label: l.tasksStatusScheduled, color: c.todo, icon: Icons.radio_button_unchecked),
    OccurrenceStatus.inProgress => (label: l.tasksStatusInProgress, color: c.ongoing, icon: Icons.timelapse),
    OccurrenceStatus.done => (label: l.tasksStatusDone, color: c.completed, icon: Icons.check_circle_outline),
    OccurrenceStatus.skipped => (label: l.tasksStatusSkipped, color: c.skipped, icon: Icons.redo),
    OccurrenceStatus.missed => (label: l.tasksStatusMissed, color: c.missed, icon: Icons.error_outline),
    OccurrenceStatus.cancelled => (label: l.tasksStatusCancelled, color: c.cancelled, icon: Icons.block),
  };
}

// ---------------------------------------------------------------------------
// Action flows shared by the sheet, the details screen and other hosts.

PlannerService _service(WidgetRef ref) => ref.read(plannerServiceProvider);

/// *Done* with the actual-time capture of T3.2.14 (asked per `planner.askActualTimeOnDone`).
Future<void> completeOccurrence(BuildContext context, WidgetRef ref, PlannerItem item) async {
  final service = _service(ref);
  ActualTimeChoice? choice;
  if (service.shouldAskActualTime(item)) {
    choice = await showActualTimeDialog(
      context,
      item: item,
      toUtc: (local) => service.zones.resolve(local, service.viewerZone).utc,
      use24h: ref.read(userPreferencesProvider).use24h,
    );
    if (choice == null) return;
  }
  await service.markDone(item, actual: choice?.option, customStart: choice?.start, customEnd: choice?.end);
  if (context.mounted) showPlannerUndoSnack(context, ref, context.l10n.tasksMarkedDone);
}

/// *Skip* with a reason (quick reasons or free text).
Future<void> skipOccurrence(BuildContext context, WidgetRef ref, PlannerItem item) async {
  final reason = await showSkipReasonDialog(context);
  if (reason == null) return;
  await _service(ref).skip(item, reason: reason.isEmpty ? null : reason);
  if (context.mounted) showPlannerUndoSnack(context, ref, context.l10n.tasksMarkedSkipped);
}

/// Delete with the scope dialog for recurring tasks (T3.1.10, T3.2.11). Returns true if deleted.
Future<bool> deleteOccurrence(BuildContext context, WidgetRef ref, PlannerItem item) async {
  final l = context.l10n;
  var scope = EditScope.allOccurrences;
  if (item.isRecurring) {
    final choice = await showEditScopeDialog(context, deleting: true);
    if (choice == null) return false;
    scope = choice.scope;
  }
  await _service(ref).delete(item, scope: scope);
  if (context.mounted) {
    showPlannerUndoSnack(context, ref, scope == EditScope.thisOccurrence ? l.tasksOccurrenceDeleted : l.tasksDeleted);
  }
  return true;
}

/// *Reschedule…* (postpone quick options or a picked date/time) — always this occurrence.
Future<void> postponeOccurrence(BuildContext context, WidgetRef ref, PlannerItem item) async {
  final service = _service(ref);
  final target = await showPostponeSheet(
    context,
    currentStart: item.startLocal,
    nowLocal: service.nowLocal,
    use24h: ref.read(userPreferencesProvider).use24h,
  );
  if (target == null) return;
  await service.reschedule(item, newStart: target, allDay: false, source: 'menu');
  if (context.mounted) showPlannerUndoSnack(context, ref, context.l10n.tasksMoved);
}

/// Opens the full editor for [item] (the occurrence for recurring tasks).
Future<void> editOccurrence(BuildContext context, PlannerItem item) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => TaskEditorScreen(taskId: item.taskId, occurrenceKey: item.isRecurring ? item.occurrenceKey : null),
  ),
);

Future<void> runPrimaryAction(BuildContext context, WidgetRef ref, PlannerItem item, OccurrencePrimaryAction action) async {
  final service = _service(ref);
  final l = context.l10n;
  switch (action) {
    case OccurrencePrimaryAction.done:
      await completeOccurrence(context, ref, item);
    case OccurrencePrimaryAction.skip:
      await skipOccurrence(context, ref, item);
    case OccurrencePrimaryAction.start:
      await service.setStatus(item, OccurrenceStatus.inProgress);
    case OccurrencePrimaryAction.pause:
      await service.pauseTimer(item);
    case OccurrencePrimaryAction.resume:
      await service.resumeTimer(item);
    case OccurrencePrimaryAction.stop:
      await service.stopTimer(item);
      if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksMarkedDone);
    case OccurrencePrimaryAction.reopen:
      await service.reopen(item);
      if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksReopened);
  }
}

// ---------------------------------------------------------------------------

/// Bottom-sheet body: the live [OccurrencePanel] of [initial].
class OccurrenceSheet extends ConsumerWidget {
  const OccurrenceSheet({required this.initial, super.key});

  final PlannerItem initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(occurrenceItemProvider((taskId: initial.taskId, key: initial.occurrenceKey)));
    final item = live.value ?? (live.isLoading ? initial : null);
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(context.l10n.tasksDetailNotFound, textAlign: TextAlign.center),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsetsDirectional.only(bottom: Space.lg),
      children: [
        OccurrencePanel(item: item, inSheet: true),
      ],
    );
  }
}

/// Occurrence details and actions (sheet and details screen): title, time range (viewer zone +
/// the task's own zone when fixed), recurrence summary, status, primary actions by tracking
/// mode, secondary actions, actual times, rating, progress, outcome note, sessions, linked
/// checklist and the occurrence's attachments.
class OccurrencePanel extends ConsumerWidget {
  const OccurrencePanel({required this.item, super.key, this.inSheet = false});

  final PlannerItem item;

  /// Inside the bottom sheet (actions that leave the occurrence close it).
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final occ = (taskId: item.taskId, key: item.occurrenceKey);
    final task = ref.watch(taskByIdProvider(item.taskId)).value;
    final record = ref.watch(occurrenceRecordProvider(occ)).value;
    final entries = ref.watch(timeEntriesProvider(occ)).value ?? const <TimeEntry>[];
    final running = entries.any((e) => e.isRunning);
    final status = occurrenceStatusVisual(context, item.status, overdue: item.overdue);
    final service = ref.watch(recurrenceServiceProvider);
    final policy = TrackingPolicy.of(item.trackingMode);
    final actions = primaryActionsFor(item, timerRunning: running);

    Future<void> leaving(Future<bool> Function() action) async {
      final navigator = Navigator.of(context);
      if (await action() && inSheet && navigator.canPop()) navigator.pop();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.icon != null) ...[
                    Icon(IconCatalog.iconFor(item.icon, fallback: Icons.task_alt), color: item.color == null ? null : Color(item.color!)),
                    const SizedBox(width: Space.sm),
                  ] else if (item.color != null) ...[
                    Padding(padding: const EdgeInsetsDirectional.only(top: 6), child: ColorDot(Color(item.color!))),
                    const SizedBox(width: Space.sm),
                  ],
                  Expanded(
                    child: Text(
                      item.title,
                      key: const ValueKey('occurrence-title'),
                      style: context.text.titleLarge?.copyWith(
                        decoration: item.status == OccurrenceStatus.cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    key: const ValueKey('occurrence-status'),
                    label: status.label,
                    color: status.color,
                    icon: status.icon,
                  ),
                  if (item.priority > 0) PriorityBadge(item.priority),
                  if (task?.isPaused ?? false) StatusPill(label: l.tasksPausedBadge, color: context.appColors.waiting, icon: Icons.pause),
                ],
              ),
              const SizedBox(height: Space.sm),
              _TimeLines(item: item, format: format),
              if (task != null && task.recurrence != null && task.anchor != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: Space.xxs),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, size: 16, color: context.colors.onSurfaceVariant),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          _describe(service, task, context.localeName, prefs.use24h),
                          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              if (record?.skipReason != null && item.status == OccurrenceStatus.skipped)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: Space.xxs),
                  child: Text(l.tasksEvtSkippedReason(skipReasonLabel(context, record!.skipReason))),
                ),
            ],
          ),
        ),
        // Primary actions by tracking mode.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final (i, a) in actions.indexed)
                _PrimaryButton(
                  key: ValueKey('occurrence-action-${a.name}'),
                  action: a,
                  filled: i == 0,
                  onPressed: () => runPrimaryAction(context, ref, item, a),
                ),
            ],
          ),
        ),
        // Secondary actions.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.xs, Space.sm, 0),
          child: Wrap(
            children: [
              if (item.isOpen)
                TextButton.icon(
                  key: const ValueKey('occurrence-reschedule'),
                  onPressed: () => postponeOccurrence(context, ref, item),
                  icon: const Icon(Icons.schedule),
                  label: Text(l.tasksActionReschedule),
                ),
              if (item.overdue)
                TextButton.icon(
                  key: const ValueKey('occurrence-move-today'),
                  onPressed: () async {
                    await ref.read(plannerServiceProvider).moveToToday(item);
                    if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksMoved);
                  },
                  icon: const Icon(Icons.today),
                  label: Text(l.tasksActionMoveToToday),
                ),
              TextButton.icon(
                key: const ValueKey('occurrence-edit'),
                onPressed: () => editOccurrence(context, item),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.actionEdit),
              ),
              TextButton.icon(
                key: const ValueKey('occurrence-duplicate'),
                onPressed: () async {
                  await ref.read(plannerServiceProvider).duplicate(
                    item.taskId,
                    asOneOff: item.isRecurring,
                    occurrenceKey: item.isRecurring ? item.occurrenceKey : null,
                  );
                  if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksDuplicated);
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l.actionDuplicate),
              ),
              TextButton.icon(
                key: const ValueKey('occurrence-delete'),
                onPressed: () => leaving(() => deleteOccurrence(context, ref, item)),
                icon: const Icon(Icons.delete_outline),
                label: Text(l.actionDelete),
              ),
              if (item.isMoved || item.isOverridden)
                TextButton.icon(
                  key: const ValueKey('occurrence-restore-series'),
                  onPressed: () async {
                    await ref.read(plannerServiceProvider).restoreToSeries(item.taskId, item.occurrenceKey);
                    if (context.mounted) showPlannerUndoSnack(context, ref, l.recurExceptionsRestored);
                  },
                  icon: const Icon(Icons.restore),
                  label: Text(l.tasksActionRestoreSeries),
                ),
              if (inSheet)
                TextButton.icon(
                  key: const ValueKey('occurrence-open-series'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(GoRouter.of(context).push(AppLinks.task(item.taskId, occurrenceKey: item.occurrenceKey)));
                  },
                  icon: const Icon(Icons.open_in_full),
                  label: Text(item.isRecurring ? l.tasksActionOpenSeries : l.actionOpen),
                ),
            ],
          ),
        ),
        const Divider(),
        if (policy.hasCheckbox) _OutcomeSection(item: item, record: record, format: format),
        if (policy.usesTimer || entries.isNotEmpty) _SessionsSection(item: item, entries: entries, format: format),
        if (item.linkedChecklistId != null) _LinkedChecklistTile(checklistId: item.linkedChecklistId!),
        if (!item.isBacklog)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: AttachmentStrip(
              ownerType: 'task_occurrence',
              ownerId: Ids.taskOccurrence(item.taskId, item.occurrenceKey),
              compact: true,
            ),
          ),
      ],
    );
  }

  static String _describe(RecurrenceService service, Task task, String locale, bool use24h) {
    try {
      return service.describe(task.recurrence!, task.anchor!, locale: locale, use24h: use24h);
    } on Object {
      return '';
    }
  }
}

class _TimeLines extends StatelessWidget {
  const _TimeLines({required this.item, required this.format});

  final PlannerItem item;
  final AppFormat format;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final date = DateFormat.MMMMEEEEd(format.locale).format(item.startLocal.date.toDateTimeUtc());
    final end = item.endLocal;
    final String range;
    if (item.allDay) {
      final days = (item.durationMinutes / 1440).ceil();
      range = days > 1 ? '$date – ${format.dateMedium(item.startLocal.date.plusDays(days - 1))}' : date;
    } else {
      final plus = item.startLocal.date.daysUntil(end.date);
      range = '$date · ${format.timeRange(item.startLocal, end)}${plus > 0 ? ' (${l.tasksPlusDays(plus)})' : ''}';
    }
    final own = item.ownZoneStartLocal;
    final zone = item.timeZone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(item.allDay ? Icons.event : Icons.schedule, size: 16, color: context.colors.onSurfaceVariant),
            const SizedBox(width: Space.xs),
            Expanded(child: Text(range, key: const ValueKey('occurrence-time'))),
          ],
        ),
        if (zone != null && own != null && own != item.startLocal && !item.allDay)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: Space.lg + Space.xs, top: Space.xxs),
            child: Text(
              '${l.tasksZoneBadge(zone.replaceAll('_', ' '))}: ${format.timeRange(own, own.plusMinutes(item.durationMinutes))}',
              style: muted,
            ),
          ),
        if (item.isMoved && item.originalStartLocal != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: Space.lg + Space.xs, top: Space.xxs),
            child: Text(l.tasksMovedFrom(format.dateTime(item.originalStartLocal!)), style: muted),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.action, required this.filled, required this.onPressed, super.key});

  final OccurrencePrimaryAction action;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (label, icon) = switch (action) {
      OccurrencePrimaryAction.done => (l.actionDone, Icons.check),
      OccurrencePrimaryAction.skip => (l.actionSkip, Icons.redo),
      OccurrencePrimaryAction.start => (l.tasksActionStart, Icons.play_arrow),
      OccurrencePrimaryAction.pause => (l.tasksActionPauseTimer, Icons.pause),
      OccurrencePrimaryAction.resume => (l.tasksActionResumeTimer, Icons.play_arrow),
      OccurrencePrimaryAction.stop => (l.tasksActionStop, Icons.stop),
      OccurrencePrimaryAction.reopen => (l.tasksActionReopen, Icons.undo),
    };
    return filled
        ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label))
        : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
  }
}

/// Actual times, rating, progress % and outcome note (T3.2.04, T3.2.14, T3.2.22).
class _OutcomeSection extends ConsumerWidget {
  const _OutcomeSection({required this.item, required this.record, required this.format});

  final PlannerItem item;
  final TaskOccurrenceRecord? record;
  final AppFormat format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(plannerServiceProvider);
    final use24h = ref.watch(userPreferencesProvider).use24h;
    final rec = record;
    final start = rec?.actualStartAt;
    final end = rec?.actualEndAt;
    String local(DateTime t) => format.timeOf(service.zones.toLocal(t, service.viewerZone));
    final rating = rec?.rating ?? 0;
    final percent = rec?.completionPercent;
    final note = rec?.outcomeNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: const ValueKey('occurrence-actual'),
          leading: const Icon(Icons.access_time),
          title: Text(l.tasksActualTime),
          subtitle: Text(start == null || end == null ? l.tasksActualNotSet : '${local(start)} – ${local(end)}'),
          onTap: () async {
            final base = item.startLocal;
            final s = await pickTime(context, initial: start == null ? base.time : service.zones.toLocal(start, service.viewerZone).time, use24h: use24h);
            if (s == null || !context.mounted) return;
            final e = await pickTime(
              context,
              initial: end == null ? base.plusMinutes(item.durationMinutes).time : service.zones.toLocal(end, service.viewerZone).time,
              use24h: use24h,
            );
            if (e == null || !context.mounted) return;
            final startUtc = service.zones.resolve(base.date.atTime(s), service.viewerZone).utc;
            var endUtc = service.zones.resolve(base.date.atTime(e), service.viewerZone).utc;
            if (endUtc.isBefore(startUtc)) endUtc = endUtc.add(const Duration(days: 1));
            await service.setActualTimes(item, start: startUtc, end: endUtc);
          },
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          // The stars wrap under the label when both don't fit (Arabic, text scale 2.0).
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.tasksRating),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      key: ValueKey('occurrence-rate-$i'),
                      tooltip: l.tasksRatingValue(i),
                      isSelected: i <= rating,
                      onPressed: () => service.rate(item, i == rating ? null : i),
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: i <= rating ? context.appColors.warning : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, 0),
          child: Row(
            children: [
              Text(l.tasksCompletion),
              Expanded(
                child: _PercentSlider(
                  key: const ValueKey('occurrence-percent'),
                  value: percent,
                  label: l.tasksCompletionValue,
                  onChanged: (v) => service.setCompletionPercent(item, v),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          key: const ValueKey('occurrence-note'),
          leading: const Icon(Icons.notes),
          title: Text(l.tasksOutcomeNote),
          subtitle: note == null
              ? Text(l.tasksOutcomeNoteHint)
              : MarkdownLiteView(note, style: context.text.bodyMedium, maxBlocks: 6),
          onTap: () async {
            final text = await promptText(context, title: l.tasksOutcomeNote, initial: note, maxLines: 6, allowEmpty: true);
            if (text == null) return;
            await service.setOutcomeNote(item, text);
          },
        ),
      ],
    );
  }
}

class _PercentSlider extends StatefulWidget {
  const _PercentSlider({required this.value, required this.label, required this.onChanged, super.key});

  final int? value;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  @override
  State<_PercentSlider> createState() => _PercentSliderState();
}

class _PercentSliderState extends State<_PercentSlider> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final value = _dragging ?? (widget.value ?? 0).toDouble();
    return Slider(
      value: value,
      max: 100,
      divisions: 10,
      label: widget.label(value.round()),
      semanticFormatterCallback: (v) => widget.label(v.round()),
      onChanged: (v) => setState(() => _dragging = v),
      onChangeEnd: (v) {
        setState(() => _dragging = null);
        widget.onChanged(v.round());
      },
    );
  }
}

/// Timer sessions: tracked total, running entry with a live counter, manual add/edit/delete
/// (T3.2.17, T3.2.18). Overlaps are a warning, negative/future entries an error.
class _SessionsSection extends ConsumerWidget {
  const _SessionsSection({required this.item, required this.entries, required this.format});

  final PlannerItem item;
  final List<TimeEntry> entries;
  final AppFormat format;

  Future<({DateTime start, DateTime? end})?> _pickRange(
    BuildContext context,
    WidgetRef ref, {
    TimeEntry? entry,
  }) async {
    final service = ref.read(plannerServiceProvider);
    final use24h = ref.read(userPreferencesProvider).use24h;
    final zone = service.viewerZone;
    final day = entry == null ? item.startLocal.date : service.zones.toLocal(entry.startedAt, zone).date;
    final s = await pickTime(
      context,
      initial: entry == null ? item.startLocal.time : service.zones.toLocal(entry.startedAt, zone).time,
      use24h: use24h,
    );
    if (s == null || !context.mounted) return null;
    if (entry != null && entry.isRunning) {
      return (start: service.zones.resolve(day.atTime(s), zone).utc, end: null);
    }
    final endInitial = entry?.endedAt == null
        ? day.atTime(s).plusMinutes(item.durationMinutes).time
        : service.zones.toLocal(entry!.endedAt!, zone).time;
    final e = await pickTime(context, initial: endInitial, use24h: use24h);
    if (e == null) return null;
    final start = service.zones.resolve(day.atTime(s), zone).utc;
    var end = service.zones.resolve(day.atTime(e), zone).utc;
    if (end.isBefore(start) && e.minuteOfDay < s.minuteOfDay) end = end.add(const Duration(days: 1));
    return (start: start, end: end);
  }

  Future<void> _save(BuildContext context, WidgetRef ref, {TimeEntry? entry}) async {
    final l = context.l10n;
    final range = await _pickRange(context, ref, entry: entry);
    if (range == null || !context.mounted) return;
    final service = ref.read(plannerServiceProvider);
    final overlaps = overlappingEntries(range.start, range.end ?? service.nowUtc, entries, now: service.nowUtc, excludeId: entry?.id);
    try {
      if (entry == null) {
        await service.addTimeEntry(item, start: range.start, end: range.end);
      } else {
        await service.updateTimeEntry(entry.id, start: range.start, end: range.end, note: entry.note);
      }
      if (overlaps.isNotEmpty && context.mounted) showInfoSnackBar(context, l.tasksEntryOverlap);
    } on ValidationException catch (e) {
      if (!context.mounted) return;
      showInfoSnackBar(context, e.message == TimeEntryError.inFuture.name ? l.tasksEntryFuture : l.tasksEntryNegative);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(plannerServiceProvider);
    final tracked = trackedSecondsOf(entries, service.nowUtc);
    String at(DateTime t) => format.timeOf(service.zones.toLocal(t, service.viewerZone));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(l.tasksTimeTracking),
        // Under the header, not beside it: long totals and text scale 2.0 must not overflow.
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: Text(
            l.tasksTracked(format.duration((tracked / 60).round())),
            key: const ValueKey('occurrence-tracked'),
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        for (final e in entries)
          ListTile(
            key: ValueKey('entry-${e.id}'),
            dense: true,
            leading: Icon(e.isRunning ? Icons.fiber_manual_record : Icons.timer_outlined, color: e.isRunning ? context.appColors.danger : null),
            title: Text(e.isRunning ? '${at(e.startedAt)} – ${l.tasksEntryRunning}' : '${at(e.startedAt)} – ${at(e.endedAt!)}'),
            subtitle: e.isRunning ? LiveElapsed(since: e.startedAt) : Text(format.duration(e.endedAt!.difference(e.startedAt).inMinutes)),
            onTap: () => _save(context, ref, entry: e),
            trailing: IconButton(
              tooltip: l.tasksEntryDelete,
              onPressed: () async {
                await ref.read(plannerServiceProvider).deleteTimeEntry(e.id);
                if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksEntryDelete);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: Space.sm),
            child: TextButton.icon(
              key: const ValueKey('entry-add'),
              onPressed: () => _save(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l.tasksAddEntry),
            ),
          ),
        ),
      ],
    );
  }
}

/// Live "hh:mm:ss" counter since [since] (running timers). Honours reduce-motion by updating
/// once per minute instead of every second.
class LiveElapsed extends ConsumerStatefulWidget {
  const LiveElapsed({required this.since, super.key, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  ConsumerState<LiveElapsed> createState() => _LiveElapsedState();
}

class _LiveElapsedState extends ConsumerState<LiveElapsed> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = Timer.periodic(context.reduceMotion ? const Duration(minutes: 1) : const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.read(clockProvider).nowUtc();
    final elapsed = now.difference(widget.since);
    return Text(
      AppFormat.counter(elapsed.isNegative ? Duration.zero : elapsed),
      style: widget.style ?? context.text.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

class _LinkedChecklistTile extends ConsumerWidget {
  const _LinkedChecklistTile({required this.checklistId});

  final String checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(linkedChecklistProvider(checklistId)).value;
    if (info == null) return const SizedBox.shrink();
    return ListTile(
      key: const ValueKey('occurrence-checklist'),
      leading: const Icon(Icons.checklist),
      title: Text(info.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.tasksChecklistProgress(info.completed, info.total)),
          const SizedBox(height: Space.xs),
          LinearProgressIndicator(value: info.progress, semanticsLabel: l.tasksChecklistProgress(info.completed, info.total)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => GoRouter.of(context).push(AppLinks.checklist(checklistId)),
    );
  }
}
