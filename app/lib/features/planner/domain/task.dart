import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

const Object _unset = Object();

/// `tasks.status`.
enum TaskStatus {
  active,
  paused,
  archived;

  String get json => name;

  static TaskStatus fromJson(Object? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => TaskStatus.active);
}

/// `tasks.notify_mode`.
enum NotifyMode {
  inherit('inherit'),
  custom('custom'),
  inheritPlus('inherit_plus'),
  off('off');

  NotifyMode(this.json);

  final String json;

  static NotifyMode fromJson(Object? value) =>
      values.firstWhere((v) => v.json == value, orElse: () => NotifyMode.inherit);
}

/// Priority 0–4 (`tasks.priority`).
enum Priority {
  none,
  low,
  medium,
  high,
  urgent;

  int get value => index;

  static Priority fromValue(int? value) => values[(value ?? 0).clamp(0, 4)];
}

extension TrackingModeJson on TrackingMode {
  String get json => name;

  static TrackingMode fromJson(Object? value) =>
      TrackingMode.values.firstWhere((v) => v.name == value, orElse: () => TrackingMode.check);
}

extension OccurrenceStatusJson on OccurrenceStatus {
  /// `task_occurrences.status` spelling.
  String get json => switch (this) {
    OccurrenceStatus.inProgress => 'in_progress',
    _ => name,
  };

  static OccurrenceStatus fromJson(Object? value) => switch (value) {
    'in_progress' => OccurrenceStatus.inProgress,
    'done' => OccurrenceStatus.done,
    'skipped' => OccurrenceStatus.skipped,
    'missed' => OccurrenceStatus.missed,
    'cancelled' => OccurrenceStatus.cancelled,
    _ => OccurrenceStatus.scheduled,
  };
}

/// How a task's wall-clock times map to instants (arch §9.1).
@immutable
sealed class TimeZoneMode {
  const TimeZoneMode();

  /// Same wall-clock time in whatever zone the viewer is in.
  const factory TimeZoneMode.floating() = FloatingZone;

  /// Anchored to an IANA zone.
  const factory TimeZoneMode.fixed(String zoneId) = FixedZone;

  factory TimeZoneMode.fromZoneId(String? zoneId) =>
      zoneId == null || zoneId.isEmpty ? const FloatingZone() : FixedZone(zoneId);

  /// IANA zone, or null for floating.
  String? get zoneId;

  bool get isFloating => zoneId == null;
}

final class FloatingZone extends TimeZoneMode {
  const FloatingZone();

  @override
  String? get zoneId => null;

  @override
  bool operator ==(Object other) => other is FloatingZone;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Floating';
}

final class FixedZone extends TimeZoneMode {
  const FixedZone(this.id);

  final String id;

  @override
  String? get zoneId => id;

  @override
  bool operator ==(Object other) => other is FixedZone && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Fixed($id)';
}

/// Countdown list membership of a task (`tasks.countdown_mode`, T3.7.12).
enum CountdownMode {
  until,
  since;

  String get json => name;

  static CountdownMode? fromJson(Object? v) => switch (v) {
    'until' => until,
    'since' => since,
    _ => null,
  };
}

/// The Planner's core entity (arch §7.3 `tasks`, T3.1.04).
///
/// Wall-clock values are [LocalDateTime]s in the task's own zone ([timeZone], or the viewer's
/// zone when floating). A task without [startLocal] is unscheduled (backlog).
@immutable
class Task {
  const Task({
    required this.id,
    required this.seriesId,
    required this.title,
    this.notes,
    this.categoryId,
    this.color,
    this.priority = 0,
    this.trackingMode = TrackingMode.check,
    this.isAllDay = false,
    this.startLocal,
    this.durationMinutes,
    this.timeZone,
    this.recurrence,
    this.recurrenceUntilLocal,
    this.estimateMinutes,
    this.location,
    this.url,
    this.icon,
    this.deadlineLocal,
    this.linkedChecklistId,
    this.manualSortKey,
    this.linkedItemId,
    this.horizonKey,
    this.countdownMode,
    this.locationLat,
    this.locationLng,
    this.isTemplate = false,
    this.notifyMode = NotifyMode.inherit,
    this.status = TaskStatus.active,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.pausedAt,
  });

  factory Task.fromJson(Map<String, Object?> json) {
    final recurrence = json['recurrence'];
    return Task(
      id: json['id']! as String,
      seriesId: (json['series_id'] ?? json['id'])! as String,
      title: json['title']! as String,
      notes: json['notes'] as String?,
      categoryId: json['category_id'] as String?,
      color: (json['color'] as num?)?.toInt(),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      trackingMode: TrackingModeJson.fromJson(json['tracking_mode']),
      isAllDay: json['is_all_day'] == true || json['is_all_day'] == 1,
      startLocal: _ldt(json['start_local']),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      timeZone: json['time_zone'] as String?,
      recurrence: recurrence == null
          ? null
          : recurrence is String
          ? RecurrenceRule.decode(recurrence)
          : RecurrenceRule.fromJson(Map<String, Object?>.from(recurrence as Map)),
      recurrenceUntilLocal: _ldt(json['recurrence_until_local']),
      estimateMinutes: (json['estimate_minutes'] as num?)?.toInt(),
      location: json['location'] as String?,
      url: json['url'] as String?,
      icon: json['icon'] as String?,
      deadlineLocal: _ldt(json['deadline_local']),
      linkedChecklistId: json['linked_checklist_id'] as String?,
      manualSortKey: json['manual_sort_key'] as String?,
      linkedItemId: json['linked_item_id'] as String?,
      horizonKey: json['horizon_key'] as String?,
      countdownMode: CountdownMode.fromJson(json['countdown_mode']),
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      isTemplate: json['is_template'] == true || json['is_template'] == 1,
      notifyMode: NotifyMode.fromJson(json['notify_mode']),
      status: TaskStatus.fromJson(json['status']),
      createdAt: _instant(json['created_at']),
      updatedAt: _instant(json['updated_at']),
      deletedAt: _instant(json['deleted_at']),
    );
  }

  final String id;

  /// Id of the original task; shared by "this & following" splits (stats continuity).
  final String seriesId;
  final String title;
  final String? notes;
  final String? categoryId;

  /// ARGB color override (null = category color).
  final int? color;
  final int priority;
  final TrackingMode trackingMode;
  final bool isAllDay;

  /// Planned start (task wall clock); null = unscheduled (backlog).
  final LocalDateTime? startLocal;
  final int? durationMinutes;

  /// IANA zone; null = floating.
  final String? timeZone;
  final RecurrenceRule? recurrence;

  /// Denormalized last possible start (null = open-ended), for range pre-filters.
  final LocalDateTime? recurrenceUntilLocal;
  final int? estimateMinutes;
  final String? location;
  final String? url;
  final String? icon;
  final LocalDateTime? deadlineLocal;
  final String? linkedChecklistId;
  final String? manualSortKey;

  /// Checklist item this task schedules (T3.1.21).
  final String? linkedItemId;

  /// Horizon of an unscheduled intention (`week:2026-09-21`, T3.7.11).
  final String? horizonKey;

  /// Shown in the countdown list (T3.7.12).
  final CountdownMode? countdownMode;

  /// Map pin (T3.7.13); both or none.
  final double? locationLat;
  final double? locationLng;
  final bool isTemplate;
  final NotifyMode notifyMode;
  final TaskStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// When the series was paused (derived from the latest `paused` activity event; not a column).
  final DateTime? pausedAt;

  bool get isRecurring => recurrence != null;
  bool get isUnscheduled => startLocal == null;
  bool get isDeleted => deletedAt != null;
  bool get isPaused => status == TaskStatus.paused;
  bool get isFixedZone => timeZone != null;
  TimeZoneMode get zoneMode => TimeZoneMode.fromZoneId(timeZone);

  int get effectiveDurationMinutes => durationMinutes ?? (isAllDay ? 1440 : 0);

  /// Planned end (task wall clock).
  LocalDateTime? get endLocal => startLocal?.plusMinutes(effectiveDurationMinutes);

  /// Recurrence anchor (null when unscheduled).
  RecurrenceAnchor? get anchor {
    final start = startLocal;
    if (start == null) return null;
    return RecurrenceAnchor(
      isAllDay ? start.date.atStartOfDay : start,
      timeZone,
      durationMinutes: effectiveDurationMinutes,
      allDay: isAllDay,
    );
  }

  /// Occurrence key of a one-off task (its planned start).
  String? get oneOffKey {
    final start = startLocal;
    if (start == null) return null;
    return isAllDay ? start.date.toIso() : start.toIso();
  }

  bool get isAfterCompletion => recurrence?.type == RuleType.afterCompletion;
  bool get isQuota => recurrence?.type == RuleType.quota;

  Task copyWith({
    String? id,
    String? seriesId,
    String? title,
    Object? notes = _unset,
    Object? categoryId = _unset,
    Object? color = _unset,
    int? priority,
    TrackingMode? trackingMode,
    bool? isAllDay,
    Object? startLocal = _unset,
    Object? durationMinutes = _unset,
    Object? timeZone = _unset,
    Object? recurrence = _unset,
    Object? recurrenceUntilLocal = _unset,
    Object? estimateMinutes = _unset,
    Object? location = _unset,
    Object? url = _unset,
    Object? icon = _unset,
    Object? deadlineLocal = _unset,
    Object? linkedChecklistId = _unset,
    Object? manualSortKey = _unset,
    Object? linkedItemId = _unset,
    Object? horizonKey = _unset,
    Object? countdownMode = _unset,
    Object? locationLat = _unset,
    Object? locationLng = _unset,
    bool? isTemplate,
    NotifyMode? notifyMode,
    TaskStatus? status,
    Object? pausedAt = _unset,
  }) => Task(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    title: title ?? this.title,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
    color: identical(color, _unset) ? this.color : color as int?,
    priority: priority ?? this.priority,
    trackingMode: trackingMode ?? this.trackingMode,
    isAllDay: isAllDay ?? this.isAllDay,
    startLocal: identical(startLocal, _unset) ? this.startLocal : startLocal as LocalDateTime?,
    durationMinutes: identical(durationMinutes, _unset) ? this.durationMinutes : durationMinutes as int?,
    timeZone: identical(timeZone, _unset) ? this.timeZone : timeZone as String?,
    recurrence: identical(recurrence, _unset) ? this.recurrence : recurrence as RecurrenceRule?,
    recurrenceUntilLocal: identical(recurrenceUntilLocal, _unset)
        ? this.recurrenceUntilLocal
        : recurrenceUntilLocal as LocalDateTime?,
    estimateMinutes: identical(estimateMinutes, _unset) ? this.estimateMinutes : estimateMinutes as int?,
    location: identical(location, _unset) ? this.location : location as String?,
    url: identical(url, _unset) ? this.url : url as String?,
    icon: identical(icon, _unset) ? this.icon : icon as String?,
    deadlineLocal: identical(deadlineLocal, _unset) ? this.deadlineLocal : deadlineLocal as LocalDateTime?,
    linkedChecklistId: identical(linkedChecklistId, _unset) ? this.linkedChecklistId : linkedChecklistId as String?,
    manualSortKey: identical(manualSortKey, _unset) ? this.manualSortKey : manualSortKey as String?,
    linkedItemId: identical(linkedItemId, _unset) ? this.linkedItemId : linkedItemId as String?,
    horizonKey: identical(horizonKey, _unset) ? this.horizonKey : horizonKey as String?,
    countdownMode: identical(countdownMode, _unset) ? this.countdownMode : countdownMode as CountdownMode?,
    locationLat: identical(locationLat, _unset) ? this.locationLat : locationLat as double?,
    locationLng: identical(locationLng, _unset) ? this.locationLng : locationLng as double?,
    isTemplate: isTemplate ?? this.isTemplate,
    notifyMode: notifyMode ?? this.notifyMode,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    pausedAt: identical(pausedAt, _unset) ? this.pausedAt : pausedAt as DateTime?,
  );

  /// Column map (server snake_case names) of the editable fields — used by the repository and
  /// JSON export. Common columns are managed by `SyncWriter`.
  Map<String, Object?> toColumns() => {
    'series_id': seriesId,
    'title': title,
    'notes': notes,
    'category_id': categoryId,
    'color': color,
    'priority': priority,
    'tracking_mode': trackingMode.json,
    'is_all_day': isAllDay,
    'start_local': startLocal?.toIso(),
    'duration_minutes': durationMinutes,
    'time_zone': timeZone,
    'recurrence': recurrence?.toJson(),
    'recurrence_until_local': recurrenceUntilLocal?.toIso(),
    'estimate_minutes': estimateMinutes,
    'location': location,
    'url': url,
    'icon': icon,
    'deadline_local': deadlineLocal?.toIso(),
    'linked_checklist_id': linkedChecklistId,
    'manual_sort_key': manualSortKey,
    'linked_item_id': linkedItemId,
    'horizon_key': horizonKey,
    'countdown_mode': countdownMode?.json,
    'location_lat': locationLat,
    'location_lng': locationLng,
    'is_template': isTemplate,
    'notify_mode': notifyMode.json,
    'status': status.json,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    ...toColumns(),
    'created_at': createdAt?.toUtc().toIso8601String(),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.seriesId == seriesId &&
      other.title == title &&
      other.notes == notes &&
      other.categoryId == categoryId &&
      other.color == color &&
      other.priority == priority &&
      other.trackingMode == trackingMode &&
      other.isAllDay == isAllDay &&
      other.startLocal == startLocal &&
      other.durationMinutes == durationMinutes &&
      other.timeZone == timeZone &&
      other.recurrence == recurrence &&
      other.recurrenceUntilLocal == recurrenceUntilLocal &&
      other.estimateMinutes == estimateMinutes &&
      other.location == location &&
      other.url == url &&
      other.icon == icon &&
      other.deadlineLocal == deadlineLocal &&
      other.linkedChecklistId == linkedChecklistId &&
      other.manualSortKey == manualSortKey &&
      other.linkedItemId == linkedItemId &&
      other.horizonKey == horizonKey &&
      other.countdownMode == countdownMode &&
      other.locationLat == locationLat &&
      other.locationLng == locationLng &&
      other.isTemplate == isTemplate &&
      other.notifyMode == notifyMode &&
      other.status == status &&
      other.deletedAt == deletedAt &&
      other.pausedAt == pausedAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    seriesId,
    title,
    notes,
    categoryId,
    color,
    priority,
    trackingMode,
    isAllDay,
    startLocal,
    durationMinutes,
    timeZone,
    recurrence,
    recurrenceUntilLocal,
    estimateMinutes,
    location,
    url,
    icon,
    deadlineLocal,
    linkedChecklistId,
    manualSortKey,
    linkedItemId,
    horizonKey,
    countdownMode,
    locationLat,
    locationLng,
    isTemplate,
    notifyMode,
    status,
    deletedAt,
    pausedAt,
  ]);

  @override
  String toString() => 'Task($id, $title, ${startLocal ?? 'unscheduled'}${isRecurring ? ', recurring' : ''})';
}

LocalDateTime? _ldt(Object? value) => value is String && value.isNotEmpty ? LocalDateTime.tryParse(value) : null;

DateTime? _instant(Object? value) => switch (value) {
  final DateTime d => d.toUtc(),
  final String s when s.isNotEmpty => DateTime.tryParse(s)?.toUtc(),
  _ => null,
};
