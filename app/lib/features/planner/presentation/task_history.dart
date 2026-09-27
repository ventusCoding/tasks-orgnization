import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Label of an edited column in `updated` events.
String taskFieldLabel(AppLocalizations l, String field) => switch (field) {
  'title' => l.tasksFieldTitle,
  'notes' => l.tasksFieldNotes,
  'category_id' => l.tasksFieldCategory,
  'color' => l.tasksFieldColor,
  'priority' => l.tasksFieldPriority,
  'tracking_mode' => l.tasksFieldTracking,
  'location' => l.tasksFieldLocation,
  'url' => l.tasksFieldUrl,
  'icon' => l.tasksFieldIcon,
  'recurrence' => l.tasksFieldRepeat,
  'time_zone' => l.tasksFieldTimeZone,
  'deadline_local' => l.tasksFieldDeadline,
  'linked_checklist_id' => l.tasksFieldChecklist,
  'is_all_day' => l.tasksFieldAllDay,
  'estimate_minutes' => l.tasksFieldEstimate,
  'completion_percent' => l.tasksCompletion,
  'rating' => l.tasksRating,
  'outcome_note' => l.tasksOutcomeNote,
  'actual_start_at' || 'actual_end_at' => l.tasksActualTime,
  'notify_mode' => l.tasksReminders,
  'start_local' => l.tasksFieldStart,
  'duration_minutes' => l.tasksFieldDuration,
  _ => field,
};

/// Human description of one activity event of a task or its occurrences (T3.1.09).
/// Reschedule times are shown in the viewer's zone.
String describeTaskEvent(AppLocalizations l, AppFormat format, ActivityEvent e, PlannerService service) {
  final p = e.payload;
  String when(Object? raw) {
    if (raw is! String) return '—';
    final local = LocalDateTime.tryParse(raw);
    if (local != null) {
      final zone = p['zone'];
      final viewer = zone is String && zone != service.viewerZone
          ? service.zones.toLocal(service.zones.resolve(local, zone).utc, service.viewerZone)
          : local;
      return format.dateTime(viewer);
    }
    final date = LocalDate.tryParse(raw);
    return date == null ? raw : format.dateMedium(date);
  }

  final fields = [for (final f in (p['fields'] as List?) ?? const []) taskFieldLabel(l, '$f')];
  final text = switch (e.eventType) {
    'created' => l.tasksEvtCreated,
    'updated' => l.tasksEvtUpdated(fields.join(', ')),
    'rescheduled' => l.tasksEvtRescheduled(when(p['fromStart']), when(p['toStart'])),
    'completed' => l.tasksEvtCompleted,
    'reopened' => l.tasksEvtReopened,
    'skipped' => p['reason'] is String ? l.tasksEvtSkippedReason('${p['reason']}') : l.tasksEvtSkipped,
    'started' => l.tasksEvtStarted,
    'stopped' => l.tasksEvtStopped,
    'deleted' => p['scope'] == 'this' ? l.tasksEvtDeletedOccurrence : l.tasksEvtDeleted,
    'restored' => l.tasksEvtRestored,
    'series_split' => l.tasksEvtSplit,
    'scheduled' => l.tasksEvtScheduled,
    'unscheduled' => l.tasksEvtUnscheduled,
    'paused' => l.tasksEvtPaused,
    'resumed' => l.tasksEvtResumed,
    'status_changed' => l.tasksEvtStatusChanged,
    'time_entry_added' => l.tasksEvtTimeEntry,
    _ => e.eventType,
  };
  final key = p['occurrenceKey'];
  if (e.entityType == 'task_occurrence' && key is String && e.eventType != 'rescheduled') {
    return '${l.tasksEvtOccurrence(when(key))} · $text';
  }
  return text;
}

IconData _eventIcon(String type) => switch (type) {
  'created' => Icons.add_circle_outline,
  'updated' => Icons.edit_outlined,
  'rescheduled' => Icons.schedule,
  'completed' => Icons.check_circle_outline,
  'reopened' => Icons.undo,
  'skipped' => Icons.redo,
  'started' => Icons.play_arrow,
  'stopped' => Icons.stop,
  'deleted' => Icons.delete_outline,
  'restored' => Icons.restore,
  'series_split' => Icons.call_split,
  'scheduled' || 'unscheduled' => Icons.inbox_outlined,
  'paused' => Icons.pause,
  'resumed' => Icons.play_circle_outline,
  _ => Icons.history,
};

/// History timeline of tasks (a series across splits), newest first, paged 50 at a time.
class TaskHistoryList extends ConsumerStatefulWidget {
  const TaskHistoryList({required this.taskIds, super.key, this.pageSize = 50});

  final List<String> taskIds;
  final int pageSize;

  @override
  ConsumerState<TaskHistoryList> createState() => _TaskHistoryListState();
}

class _TaskHistoryListState extends ConsumerState<TaskHistoryList> {
  late int _limit = widget.pageSize;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final service = ref.read(plannerServiceProvider);
    final events = ref.watch(taskHistoryProvider(HistoryQuery(widget.taskIds, limit: _limit))).value;
    if (events == null) return const LoadingState();
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Text(l.tasksHistoryEmpty, key: const ValueKey('history-empty')),
      );
    }
    final now = service.nowUtc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in events)
          ListTile(
            key: ValueKey('history-${e.id}'),
            dense: true,
            leading: Icon(_eventIcon(e.eventType), size: 20),
            title: Text(_withReason(context, describeTaskEvent(l, format, e, service), e)),
            subtitle: Text(format.relative(e.occurredAt, now)),
          ),
        if (events.length >= _limit)
          TextButton(
            key: const ValueKey('history-more'),
            onPressed: () => setState(() => _limit += widget.pageSize),
            child: Text(l.tasksHistoryLoadMore),
          ),
      ],
    );
  }

  /// Localizes skip reason keys inside the skipped label.
  String _withReason(BuildContext context, String text, ActivityEvent e) {
    final reason = e.payload['reason'];
    if (e.eventType != 'skipped' || reason is! String) return text;
    return text.replaceFirst(reason, skipReasonLabel(context, reason));
  }
}
