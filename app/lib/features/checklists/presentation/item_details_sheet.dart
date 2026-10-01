import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart' show AttachmentOwnerType;
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/task_links.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/markdown_lite.dart';
import 'package:everslot/features/checklists/presentation/status_sheet.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:everslot/features/planner/application/planner_providers.dart' show itemTasksProvider;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Actions of the details sheet handled by the screen.
enum DetailsAction { focus, duplicate, moveTo, promote, delete, insights }

/// Full editor for one item (T4.2.15). Text and note apply on Save (one undo step); status, due,
/// priority and attachments apply immediately (each undoable).
Future<DetailsAction?> showItemDetails(BuildContext context, {required String checklistId, required String itemId}) =>
    showAppSheet<DetailsAction>(
      context,
      title: context.l10n.itemDetailsTitle,
      builder: (_) => _ItemDetails(checklistId: checklistId, itemId: itemId),
    );

class _ItemDetails extends ConsumerStatefulWidget {
  const _ItemDetails({required this.checklistId, required this.itemId});

  final String checklistId;
  final String itemId;

  @override
  ConsumerState<_ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends ConsumerState<_ItemDetails> {
  TextEditingController? _text;
  TextEditingController? _note;

  @override
  void dispose() {
    _text?.dispose();
    _note?.dispose();
    super.dispose();
  }

  ChecklistEditor get _editor => ref.read(checklistEditorProvider(widget.checklistId).notifier);

  Future<void> _save(ChecklistItem item) async {
    final fields = <String, Object?>{
      if (_text!.text.trimRight() != item.text) 'text': ItemText(_text!.text).value,
      if (ItemText.note(_note!.text) != item.note) 'note': ItemText.note(_note!.text),
    };
    if (fields.isNotEmpty) await _editor.setFields(item.id, fields);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _status(ChecklistItem item, ChecklistSettings settings) async {
    final choice = await showStatusSheet(context, ref, item: item, settings: settings);
    if (choice == null) return;
    bool? cascade;
    if (choice.status == ItemStatus.completed && settings.completeChildrenWithParent == CascadeChoice.ask) {
      final tree = ref.read(checklistTreeProvider(widget.checklistId));
      final open = tree == null ? 0 : tree.descendants(item.id).where((d) => tree[d]!.status.isOpen).length;
      if (open > 0 && mounted) {
        cascade = await askCompleteDescendants(context, open);
        if (cascade == null) return;
      }
    }
    await _editor.setStatus(
      [item.id],
      choice.status,
      note: choice.note,
      setNote: choice.setNote,
      followUpAt: choice.followUpAt,
      completeOpenDescendants: cascade,
    );
  }

  Future<void> _due(ChecklistItem item) async {
    final prefs = ref.read(userPreferencesProvider);
    final date = await pickDate(context, initial: item.dueLocal?.date);
    if (date == null || !mounted) return;
    final time = await pickTime(context, initial: item.dueLocal?.time ?? LocalTime(9, 0), use24h: prefs.use24h);
    await _editor.setFields(item.id, {'due_local': date.atTime(time ?? LocalTime.midnight)}, label: 'due');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tree = ref.watch(checklistTreeProvider(widget.checklistId));
    final item = tree?[widget.itemId];
    final settings = ref.watch(checklistProvider(widget.checklistId)).value?.settings ?? ChecklistSettings.defaults;
    if (item == null) return const LoadingState();
    _text ??= TextEditingController(text: item.text);
    _note ??= TextEditingController(text: item.note);
    final now = ref.read(clockProvider).nowUtc();
    final zone = ref.watch(deviceZoneProvider);
    final nowLocal = ref.read(zoneResolverProvider).toLocal(now, zone);
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    String instant(DateTime t) => fmt.dateTime(ref.read(zoneResolverProvider).toLocal(t, zone));
    final due = item.dueLocal;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            maxLines: null,
            decoration: InputDecoration(labelText: l.itemText),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 8,
            decoration: InputDecoration(labelText: l.itemNote, border: const OutlineInputBorder()),
          ),
          // Notes are Markdown-lite (T4.1.11): plain text with a small formatting toolbar.
          MarkdownFormatBar(controller: _note!),
          const SizedBox(height: Space.md),
          // Status + reason + follow-up (T4.3.02).
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(StatusStyle.icon(item.status), color: StatusStyle.color(context, item.status)),
            title: Text(StatusStyle.label(context, item.status)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.statusSince != null) Text(formatAge(context, item.statusSince!, now)),
                if (item.statusNote != null)
                  Text(item.statusNote!, style: const TextStyle(fontStyle: FontStyle.italic)),
                if (item.followUpAt != null) Text(l.statusFollowUpChip(instant(item.followUpAt!))),
              ],
            ),
            trailing: TextButton(onPressed: () => _status(item, settings), child: Text(l.statusChange)),
          ),
          // Due (T4.3.10) + priority.
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(
              due == null
                  ? l.itemNoDue
                  : (ItemTimeRules.isDateOnly(due) ? fmt.dateMedium(due.date) : fmt.dateTime(due)),
            ),
            subtitle: due == null
                ? null
                : Text(switch (ItemTimeRules.classifyDue(due, nowLocal)) {
                    DueState.overdue => l.itemDueOverdue,
                    DueState.today => l.itemDueToday,
                    DueState.tomorrow => l.itemDueTomorrow,
                    DueState.later => fmt.relative(due.toDateTimeUtc(), nowLocal.toDateTimeUtc()),
                  }),
            onTap: () => _due(item),
            trailing: due == null
                ? null
                : IconButton(
                    tooltip: l.itemClearDue,
                    icon: const Icon(Icons.close),
                    onPressed: () => _editor.setFields(item.id, {'due_local': null}, label: 'due'),
                  ),
          ),
          Row(
            children: [
              Text(l.itemPriority, style: context.text.titleSmall),
              const SizedBox(width: Space.md),
              Expanded(
                child: PrioritySelector(
                  value: item.priority,
                  onChanged: (p) => _editor.setFields(item.id, {'priority': p}, label: 'priority'),
                ),
              ),
            ],
          ),
          // Step duration for the routine player (T3.7.07).
          ListTile(
            key: const Key('item-step-duration'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timelapse),
            title: Text(l.itemStepDuration),
            subtitle: Text(item.estimateMinutes == null ? l.itemNoStepDuration : fmt.duration(item.estimateMinutes!)),
            onTap: () async {
              final m = await pickDuration(context, initialMinutes: item.estimateMinutes ?? 5, maxMinutes: 1440);
              if (m != null) await _editor.setFields(item.id, {'estimate_minutes': m}, label: 'estimate');
            },
            trailing: item.estimateMinutes == null
                ? null
                : IconButton(
                    tooltip: l.actionClear,
                    icon: const Icon(Icons.close),
                    onPressed: () => _editor.setFields(item.id, {'estimate_minutes': null}, label: 'estimate'),
                  ),
          ),
                    // Scheduled as a task (T3.1.21): the link back, or *Schedule as task*.
          Builder(
            builder: (context) {
              final task = ref.watch(itemTasksProvider).value?[item.id];
              if (task != null) {
                return ListTile(
                  key: const Key('item-scheduled-task'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available),
                  title: Text(l.itemScheduledAs(task.title)),
                  subtitle: task.startLocal == null ? null : Text(fmt.dateTime(task.startLocal!)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openRoute(context, AppLinks.task(task.id)),
                );
              }
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('item-schedule-task'),
                  icon: const Icon(Icons.event_available),
                  label: Text(l.checklistScheduleTask),
                  onPressed: () async {
                    final taskId = await ref
                        .read(checklistTaskLinksProvider)
                        .scheduleItem(item, fallbackTitle: l.listsUntitled);
                    if (context.mounted) openRoute(context, AppLinks.taskEdit(taskId));
                  },
                ),
              );
            },
          ),
          SectionHeader(
            l.tagsTitle,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.sm),
          ),
          EntityTagChips(entityType: 'checklist_item', entityId: item.id, editable: true),
          SectionHeader(
            l.itemAttachments,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.sm),
          ),
          AttachmentStrip(
            ownerType: AttachmentOwnerType.checklistItem,
            ownerId: item.id,
            maxVisible: 12,
            onOperation: _editor.pushUndo,
          ),
          // Reminders of this item (T4.2.15 → [7.1] rule editor, [7.5] catalog).
          const SizedBox(height: Space.md),
          NotificationSettingsSection(
            targetType: NotificationTargetType.checklistItem,
            targetId: item.id,
            section: NotificationSection.checklists,
            checklistId: widget.checklistId,
            ancestorItemIds: [...?tree?.ancestors(item.id).reversed],
            itemKind: due == null ? ItemKind.any : (ItemTimeRules.isDateOnly(due) ? ItemKind.dateOnly : ItemKind.timed),
          ),
          SectionHeader(
            l.itemHistory,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
          ),
          StatusTimeline(item: item, now: now),
          const SizedBox(height: Space.md),
          Text(
            [
              if (item.createdAt != null) l.itemCreated(instant(item.createdAt!)),
              if (item.updatedAt != null) l.itemEdited(instant(item.updatedAt!)),
              if (item.completedAt != null) l.itemCompletedOn(instant(item.completedAt!)),
            ].join(' · '),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              ActionChip(
                avatar: const Icon(Icons.center_focus_strong, size: 18),
                label: Text(l.checklistFocus),
                onPressed: () => Navigator.pop(context, DetailsAction.focus),
              ),
              ActionChip(
                avatar: const Icon(Icons.copy_all_outlined, size: 18),
                label: Text(l.checklistDuplicateItem),
                onPressed: () => Navigator.pop(context, DetailsAction.duplicate),
              ),
              ActionChip(
                avatar: const Icon(Icons.drive_file_move_outline, size: 18),
                label: Text(l.checklistMoveTo),
                onPressed: () => Navigator.pop(context, DetailsAction.moveTo),
              ),
              ActionChip(
                avatar: const Icon(Icons.upgrade, size: 18),
                label: Text(l.checklistPromote),
                onPressed: () => Navigator.pop(context, DetailsAction.promote),
              ),
              ActionChip(
                avatar: const Icon(Icons.insights_outlined, size: 18),
                label: Text(l.itemInsights),
                onPressed: () => Navigator.pop(context, DetailsAction.insights),
              ),
              ActionChip(
                avatar: Icon(Icons.delete_outline, size: 18, color: context.colors.error),
                label: Text(l.checklistDeleteItem),
                onPressed: () => Navigator.pop(context, DetailsAction.delete),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
              const Spacer(),
              FilledButton(onPressed: () => _save(item), child: Text(l.actionSave)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status history (T4.3.05): chronological changes with notes, device and cause, plus the time
/// spent in each status (open current interval included).
class StatusTimeline extends ConsumerWidget {
  const StatusTimeline({required this.item, required this.now, super.key});

  final ChecklistItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final events = ref.watch(itemStatusEventsProvider(item.id)).value ?? const <StatusEvent>[];
    final device = ref.watch(deviceIdProvider);
    final zone = ref.watch(deviceZoneProvider);
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    final intervals = StatusHistory.intervals(
      events,
      createdAt: item.createdAt ?? events.firstOrNull?.at ?? now,
      currentStatus: item.status,
    );
    final totals = StatusHistory.totals(intervals, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (events.isEmpty)
          Text(l.itemHistoryEmpty, style: context.text.bodySmall)
        else
          for (final e in events.reversed)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(StatusStyle.icon(e.to), color: StatusStyle.color(context, e.to), size: 20),
              title: Text(
                e.from == null || e.type == 'status_note_changed'
                    ? StatusStyle.label(context, e.to)
                    : l.itemHistoryTransition(StatusStyle.label(context, e.from!), StatusStyle.label(context, e.to)),
              ),
              subtitle: Text(
                [
                  fmt.dateTime(ref.read(zoneResolverProvider).toLocal(e.at, zone)),
                  if (e.note != null) '“${e.note}”',
                  if (e.cause != null && e.cause != 'user') l.itemHistoryCause,
                  if (e.deviceId != null)
                    l.itemHistoryDevice(e.deviceId == device ? l.itemThisDevice : l.itemOtherDevice),
                ].join(' · '),
              ),
            ),
        if (totals.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          Text(l.itemTimeInStatus, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final e in totals.entries)
                StatusPill(
                  label: l.statusWithAge(StatusStyle.label(context, e.key), fmt.duration(e.value.inMinutes)),
                  color: StatusStyle.color(context, e.key),
                  icon: StatusStyle.icon(e.key),
                  dense: true,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
