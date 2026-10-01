import 'package:everslot/features/notifications/domain/notification_actions.dart' show NotificationActionIds;
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart' as planner show NotifyMode;
import 'package:everslot_recurrence/everslot_recurrence.dart' show ZoneResolver;

/// Projects resolved task occurrences onto notification targets (features/notifications
/// README §2). Pure: the application source loads the occurrences, this maps them.
abstract final class PlannerNotificationTargets {
  /// Actions used when neither the rule nor the profile sets any.
  static const defaultActions = [NotificationActionIds.done, NotificationActionIds.snooze, NotificationActionIds.skip];

  /// Timer tasks start (and stop) from the notification instead of being ticked off.
  static const timerActions = [NotificationActionIds.start, NotificationActionIds.snooze, NotificationActionIds.skip];

  /// Longest notes excerpt passed to templates.
  static const notesExcerptLength = 120;

  /// Wire status of an occurrence (`scheduled`, `in_progress`, `done`, …).
  static String statusWire(OccurrenceStatus status) => switch (status) {
    OccurrenceStatus.scheduled => 'scheduled',
    OccurrenceStatus.inProgress => 'in_progress',
    OccurrenceStatus.done => 'done',
    OccurrenceStatus.skipped => 'skipped',
    OccurrenceStatus.missed => 'missed',
    OccurrenceStatus.cancelled => 'cancelled',
  };

  /// Open = the reminders still make sense (scheduled, in progress, or missed but not closed).
  static bool isOpen(ResolvedOccurrence o) =>
      !(o.record?.isCancelled ?? false) &&
      (o.status == OccurrenceStatus.scheduled ||
          o.status == OccurrenceStatus.inProgress ||
          o.status == OccurrenceStatus.missed);

  static NotifyMode notifyMode(planner.NotifyMode mode) => NotifyMode.parse(mode.json);

  /// First paragraph of [notes], trimmed to [notesExcerptLength] characters.
  static String? notesExcerpt(String? notes) {
    final text = notes?.trim();
    if (text == null || text.isEmpty) return null;
    final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => text).trim();
    return firstLine.length <= notesExcerptLength ? firstLine : '${firstLine.substring(0, notesExcerptLength - 1)}…';
  }

  /// One target per occurrence. Closed occurrences are returned too (`isOpen: false`) so a
  /// replan cancels their reminders; quota slots (no time of their own) are left out.
  /// [categoryNames] feeds the `category` template variable; [zones] and [viewerZone] resolve
  /// one-off deadlines (the `due` anchor, T3.1.13) in the task's zone mode.
  static List<NotificationTarget> build(
    Iterable<ResolvedOccurrence> occurrences, {
    required ZoneResolver zones,
    required String viewerZone,
    Map<String, String> categoryNames = const {},
  }) => [
    for (final o in occurrences)
      if (!o.isQuotaSlot)
        target(o, zones: zones, viewerZone: viewerZone, categoryName: categoryNames[o.task.categoryId]),
  ];

  static NotificationTarget target(
    ResolvedOccurrence o, {
    required ZoneResolver zones,
    required String viewerZone,
    String? categoryName,
  }) {
    final task = o.task;
    final excerpt = notesExcerpt(o.notes);
    final deadline = task.deadlineLocal;
    final due = deadline == null || task.isRecurring ? null : zones.resolve(deadline, task.timeZone ?? viewerZone).utc;
    return NotificationTarget(
      type: NotificationTargetType.task,
      id: task.id,
      section: NotificationSection.planner,
      title: o.title,
      occurrenceKey: o.occurrenceKey,
      categoryId: task.categoryId,
      notifyMode: notifyMode(task.notifyMode),
      itemKind: o.isAllDay ? ItemKind.allDay : ItemKind.timed,
      timeZone: task.timeZone,
      start: o.startInstant,
      end: o.endInstant,
      due: due,
      status: statusWire(o.status),
      statusChangedAt: o.record?.statusChangedAt,
      isOpen: isOpen(o),
      guard: NotificationGuard.taskOccurrenceOpen(task.id, o.occurrenceKey),
      variables: {
        'category': ?categoryName,
        'notes_excerpt': ?excerpt,
        if (task.location != null) 'location': task.location,
      },
      defaultActions: task.trackingMode == TrackingMode.timer ? timerActions : defaultActions,
    );
  }
}
