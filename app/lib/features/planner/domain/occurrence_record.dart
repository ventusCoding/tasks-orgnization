import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

const Object _unset = Object();

/// A touched occurrence (`task_occurrences`, id = uuidv5(task_id|occurrence_key)).
///
/// Holds per-occurrence overrides (start/duration/title/notes), cancellation and the outcome
/// (status, actual times, tracked time, completion %, rating, note).
@immutable
class TaskOccurrenceRecord {
  const TaskOccurrenceRecord({
    required this.id,
    required this.taskId,
    required this.occurrenceKey,
    this.overrideStartLocal,
    this.overrideDurationMinutes,
    this.overrideTitle,
    this.overrideNotes,
    this.isCancelled = false,
    this.status = OccurrenceStatus.scheduled,
    this.statusChangedAt,
    this.completedAt,
    this.actualStartAt,
    this.actualEndAt,
    this.trackedSeconds,
    this.completionPercent,
    this.skipReason,
    this.rating,
    this.outcomeNote,
    this.updatedAt,
    this.deletedAt,
  });

  factory TaskOccurrenceRecord.fromJson(Map<String, Object?> json) => TaskOccurrenceRecord(
    id: json['id']! as String,
    taskId: json['task_id']! as String,
    occurrenceKey: json['occurrence_key']! as String,
    overrideStartLocal: json['override_start_local'] is String
        ? LocalDateTime.tryParse(json['override_start_local']! as String)
        : null,
    overrideDurationMinutes: (json['override_duration_minutes'] as num?)?.toInt(),
    overrideTitle: json['override_title'] as String?,
    overrideNotes: json['override_notes'] as String?,
    isCancelled: json['is_cancelled'] == true || json['is_cancelled'] == 1,
    status: OccurrenceStatusJson.fromJson(json['status']),
    statusChangedAt: _instant(json['status_changed_at']),
    completedAt: _instant(json['completed_at']),
    actualStartAt: _instant(json['actual_start_at']),
    actualEndAt: _instant(json['actual_end_at']),
    trackedSeconds: (json['tracked_seconds'] as num?)?.toInt(),
    completionPercent: (json['completion_percent'] as num?)?.toInt(),
    skipReason: json['skip_reason'] as String?,
    rating: (json['rating'] as num?)?.toInt(),
    outcomeNote: json['outcome_note'] as String?,
    updatedAt: _instant(json['updated_at']),
    deletedAt: _instant(json['deleted_at']),
  );

  final String id;
  final String taskId;

  /// Original local start (RECURRENCE-ID); never changes when the occurrence is moved.
  final String occurrenceKey;
  final LocalDateTime? overrideStartLocal;
  final int? overrideDurationMinutes;
  final String? overrideTitle;
  final String? overrideNotes;
  final bool isCancelled;
  final OccurrenceStatus status;
  final DateTime? statusChangedAt;
  final DateTime? completedAt;
  final DateTime? actualStartAt;
  final DateTime? actualEndAt;
  final int? trackedSeconds;
  final int? completionPercent;
  final String? skipReason;
  final int? rating;
  final String? outcomeNote;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Moved or resized away from the series.
  bool get isMoved => overrideStartLocal != null;

  /// Any per-occurrence override (time, title or notes).
  bool get hasOverride =>
      overrideStartLocal != null || overrideDurationMinutes != null || overrideTitle != null || overrideNotes != null;

  /// History worth protecting (T3.2.09): done/skipped/started, rated, tracked or annotated.
  bool get hasOutcome =>
      status == OccurrenceStatus.done ||
      status == OccurrenceStatus.skipped ||
      status == OccurrenceStatus.inProgress ||
      rating != null ||
      (trackedSeconds ?? 0) > 0 ||
      completionPercent != null ||
      (outcomeNote?.isNotEmpty ?? false);

  /// The instant the occurrence was completed (after-completion rules).
  DateTime? get completionInstant => completedAt ?? statusChangedAt ?? updatedAt;

  TaskOccurrenceRecord copyWith({
    Object? overrideStartLocal = _unset,
    Object? overrideDurationMinutes = _unset,
    Object? overrideTitle = _unset,
    Object? overrideNotes = _unset,
    bool? isCancelled,
    OccurrenceStatus? status,
    Object? completedAt = _unset,
  }) => TaskOccurrenceRecord(
    id: id,
    taskId: taskId,
    occurrenceKey: occurrenceKey,
    overrideStartLocal: identical(overrideStartLocal, _unset)
        ? this.overrideStartLocal
        : overrideStartLocal as LocalDateTime?,
    overrideDurationMinutes: identical(overrideDurationMinutes, _unset)
        ? this.overrideDurationMinutes
        : overrideDurationMinutes as int?,
    overrideTitle: identical(overrideTitle, _unset) ? this.overrideTitle : overrideTitle as String?,
    overrideNotes: identical(overrideNotes, _unset) ? this.overrideNotes : overrideNotes as String?,
    isCancelled: isCancelled ?? this.isCancelled,
    status: status ?? this.status,
    statusChangedAt: statusChangedAt,
    completedAt: identical(completedAt, _unset) ? this.completedAt : completedAt as DateTime?,
    actualStartAt: actualStartAt,
    actualEndAt: actualEndAt,
    trackedSeconds: trackedSeconds,
    completionPercent: completionPercent,
    skipReason: skipReason,
    rating: rating,
    outcomeNote: outcomeNote,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'task_id': taskId,
    'occurrence_key': occurrenceKey,
    'override_start_local': overrideStartLocal?.toIso(),
    'override_duration_minutes': overrideDurationMinutes,
    'override_title': overrideTitle,
    'override_notes': overrideNotes,
    'is_cancelled': isCancelled,
    'status': status.json,
    'status_changed_at': statusChangedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'actual_start_at': actualStartAt?.toIso8601String(),
    'actual_end_at': actualEndAt?.toIso8601String(),
    'tracked_seconds': trackedSeconds,
    'completion_percent': completionPercent,
    'skip_reason': skipReason,
    'rating': rating,
    'outcome_note': outcomeNote,
  };

  @override
  bool operator ==(Object other) =>
      other is TaskOccurrenceRecord &&
      other.id == id &&
      other.taskId == taskId &&
      other.occurrenceKey == occurrenceKey &&
      other.overrideStartLocal == overrideStartLocal &&
      other.overrideDurationMinutes == overrideDurationMinutes &&
      other.overrideTitle == overrideTitle &&
      other.overrideNotes == overrideNotes &&
      other.isCancelled == isCancelled &&
      other.status == status &&
      other.statusChangedAt == statusChangedAt &&
      other.completedAt == completedAt &&
      other.actualStartAt == actualStartAt &&
      other.actualEndAt == actualEndAt &&
      other.trackedSeconds == trackedSeconds &&
      other.completionPercent == completionPercent &&
      other.skipReason == skipReason &&
      other.rating == rating &&
      other.outcomeNote == outcomeNote &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    overrideStartLocal,
    overrideDurationMinutes,
    overrideTitle,
    overrideNotes,
    isCancelled,
    status,
    completedAt,
    actualStartAt,
    actualEndAt,
    trackedSeconds,
    completionPercent,
    skipReason,
    rating,
    outcomeNote,
    deletedAt,
  ]);

  @override
  String toString() => 'TaskOccurrenceRecord($taskId|$occurrenceKey, ${status.name}${isCancelled ? ', cancelled' : ''})';
}

/// One timer session (`time_entries`); `endedAt == null` while running.
@immutable
class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.taskId,
    required this.startedAt,
    this.occurrenceKey,
    this.endedAt,
    this.note,
    this.deletedAt,
  });

  factory TimeEntry.fromJson(Map<String, Object?> json) => TimeEntry(
    id: json['id']! as String,
    taskId: json['task_id']! as String,
    occurrenceKey: json['occurrence_key'] as String?,
    startedAt: _instant(json['started_at'])!,
    endedAt: _instant(json['ended_at']),
    note: json['note'] as String?,
    deletedAt: _instant(json['deleted_at']),
  );

  final String id;
  final String taskId;
  final String? occurrenceKey;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? note;
  final DateTime? deletedAt;

  bool get isRunning => endedAt == null;

  /// Elapsed time (up to [now] while running).
  Duration durationAt(DateTime now) => (endedAt ?? now).difference(startedAt);

  Map<String, Object?> toJson() => {
    'id': id,
    'task_id': taskId,
    'occurrence_key': occurrenceKey,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt?.toUtc().toIso8601String(),
    'note': note,
  };

  @override
  bool operator ==(Object other) =>
      other is TimeEntry &&
      other.id == id &&
      other.taskId == taskId &&
      other.occurrenceKey == occurrenceKey &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.note == note &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(id, taskId, occurrenceKey, startedAt, endedAt, note, deletedAt);

  @override
  String toString() => 'TimeEntry($taskId|$occurrenceKey $startedAt → ${endedAt ?? 'running'})';
}

/// One row of the append-only activity log (`activity_events`) used for history views.
@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.occurredAt,
    this.parentId,
    this.payload = const {},
  });

  final String id;
  final String entityType;
  final String entityId;
  final String? parentId;
  final String eventType;
  final Map<String, Object?> payload;
  final DateTime occurredAt;

  String? get occurrenceKey => payload['occurrenceKey'] as String?;

  @override
  bool operator ==(Object other) => other is ActivityEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ActivityEvent($eventType $entityType/$entityId $payload)';
}

DateTime? _instant(Object? value) => switch (value) {
  final DateTime d => d.toUtc(),
  final String s when s.isNotEmpty => DateTime.tryParse(s)?.toUtc(),
  _ => null,
};
