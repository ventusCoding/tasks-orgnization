import 'dart:convert';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Row → domain mappers for the planner tables (T3.1.03).
abstract final class PlannerMappers {
  static Task task(TaskRow r) => Task(
    id: r.id,
    seriesId: r.seriesId,
    title: r.title,
    notes: r.notes,
    categoryId: r.categoryId,
    color: r.color,
    priority: r.priority,
    trackingMode: TrackingModeJson.fromJson(r.trackingMode),
    isAllDay: r.isAllDay,
    startLocal: _ldt(r.startLocal),
    durationMinutes: r.durationMinutes,
    timeZone: r.timeZone,
    recurrence: rule(r.recurrence),
    recurrenceUntilLocal: _ldt(r.recurrenceUntilLocal),
    estimateMinutes: r.estimateMinutes,
    location: r.location,
    url: r.url,
    icon: r.icon,
    deadlineLocal: _ldt(r.deadlineLocal),
    linkedChecklistId: r.linkedChecklistId,
    manualSortKey: r.manualSortKey,
    linkedItemId: r.linkedItemId,
    horizonKey: r.horizonKey,
    countdownMode: CountdownMode.fromJson(r.countdownMode),
    locationLat: r.locationLat,
    locationLng: r.locationLng,
    externalUid: r.externalUid,
    isTemplate: r.isTemplate,
    notifyMode: NotifyMode.fromJson(r.notifyMode),
    status: TaskStatus.fromJson(r.status),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
  );

  /// Raw SQLite row map (snake_case) → task.
  static Task taskFromRaw(Map<String, Object?> m) =>
      Task.fromJson({...m, 'recurrence': null}).copyWith(recurrence: rule(m['recurrence'] as String?));

  static TaskOccurrenceRecord record(TaskOccurrenceRow r) => TaskOccurrenceRecord(
    id: r.id,
    taskId: r.taskId,
    occurrenceKey: r.occurrenceKey,
    overrideStartLocal: _ldt(r.overrideStartLocal),
    overrideDurationMinutes: r.overrideDurationMinutes,
    overrideTitle: r.overrideTitle,
    overrideNotes: r.overrideNotes,
    isCancelled: r.isCancelled,
    status: OccurrenceStatusJson.fromJson(r.status),
    statusChangedAt: r.statusChangedAt,
    completedAt: r.completedAt,
    actualStartAt: r.actualStartAt,
    actualEndAt: r.actualEndAt,
    trackedSeconds: r.trackedSeconds,
    completionPercent: r.completionPercent,
    skipReason: r.skipReason,
    rating: r.rating,
    outcomeNote: r.outcomeNote,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
  );

  static TaskOccurrenceRecord recordFromRaw(Map<String, Object?> m) => TaskOccurrenceRecord.fromJson(m);

  static TimeEntry timeEntry(TimeEntryRow r) => TimeEntry(
    id: r.id,
    taskId: r.taskId,
    occurrenceKey: r.occurrenceKey,
    startedAt: r.startedAt,
    endedAt: r.endedAt,
    note: r.note,
    deletedAt: r.deletedAt,
  );

  static ActivityEvent event(ActivityEventRow r) => ActivityEvent(
    id: r.id,
    entityType: r.entityType,
    entityId: r.entityId,
    parentId: r.parentId,
    eventType: r.eventType,
    payload: _json(r.payload),
    occurredAt: r.occurredAt,
  );

  /// Decodes a stored rule; malformed JSON yields null (the task behaves as a one-off).
  static RecurrenceRule? rule(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return RecurrenceRule.decode(json);
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?> _json(String value) {
    try {
      final d = jsonDecode(value);
      return d is Map ? Map<String, Object?>.from(d) : const {};
    } on FormatException {
      return const {};
    }
  }

  static LocalDateTime? _ldt(String? value) => value == null || value.isEmpty ? null : LocalDateTime.tryParse(value);
}
