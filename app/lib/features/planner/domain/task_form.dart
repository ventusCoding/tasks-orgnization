import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_validation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

const Object _unset = Object();

/// Quick duration chips of the editor (minutes, T3.1.06).
const List<int> taskDurationChips = [5, 15, 30, 45, 60, 90, 120, 180];

/// Editable state of the task editor (T3.1.06/T3.1.07). Pure and immutable: the editor keeps one
/// value, every field change returns a new one, and [validate] goes through the domain rules.
///
/// Times are in the task's own wall clock ([zoneId] = its zone, null = floating).
@immutable
class TaskForm {
  const TaskForm({
    this.title = '',
    this.notes = '',
    this.date,
    this.startTime,
    this.durationMinutes = 30,
    this.allDay = false,
    this.allDayDays = 1,
    this.endMode = false,
    this.zoneId,
    this.recurrence,
    this.categoryId,
    this.color,
    this.priority = 0,
    this.trackingMode = TrackingMode.check,
    this.icon,
    this.location = '',
    this.url = '',
    this.linkedChecklistId,
    this.deadline,
    this.estimateMinutes,
    this.coordinates,
  });

  /// A new task at [start] (null = backlog) for [durationMinutes].
  factory TaskForm.create({
    LocalDateTime? start,
    int durationMinutes = 30,
    bool allDay = false,
    TrackingMode trackingMode = TrackingMode.check,
    LocalTime? defaultTime,
  }) {
    final days = allDay ? (durationMinutes / 1440).ceil().clamp(1, 365) : 1;
    return TaskForm(
      date: start?.date,
      startTime: allDay ? (defaultTime ?? LocalTime(9, 0)) : (start?.time ?? defaultTime ?? LocalTime(9, 0)),
      durationMinutes: allDay ? 60 : durationMinutes,
      allDay: allDay,
      allDayDays: days,
      trackingMode: trackingMode,
    );
  }

  /// The form of an existing task. With [occurrenceKey] (and its [record]) the scheduling fields,
  /// title and notes show that occurrence's effective values.
  factory TaskForm.fromTask(Task task, {String? occurrenceKey, TaskOccurrenceRecord? record}) {
    var start = task.startLocal;
    var duration = task.effectiveDurationMinutes;
    var title = task.title;
    var notes = task.notes ?? '';
    if (occurrenceKey != null) {
      start =
          record?.overrideStartLocal ??
          LocalDateTime.tryParse(occurrenceKey) ??
          LocalDate.tryParse(occurrenceKey)?.atStartOfDay ??
          start;
      duration = record?.overrideDurationMinutes ?? duration;
      title = record?.overrideTitle ?? title;
      notes = record?.overrideNotes ?? notes;
    }
    return TaskForm(
      title: title,
      notes: notes,
      date: start?.date,
      startTime: task.isAllDay ? LocalTime(9, 0) : (start?.time ?? LocalTime(9, 0)),
      durationMinutes: task.isAllDay ? 60 : duration,
      allDay: task.isAllDay,
      allDayDays: task.isAllDay ? (duration / 1440).ceil().clamp(1, 365) : 1,
      zoneId: task.timeZone,
      recurrence: task.recurrence,
      categoryId: task.categoryId,
      color: task.color,
      priority: task.priority,
      trackingMode: task.trackingMode,
      icon: task.icon,
      location: task.location ?? '',
      url: task.url ?? '',
      linkedChecklistId: task.linkedChecklistId,
      deadline: task.deadlineLocal,
      estimateMinutes: task.estimateMinutes,
      coordinates: task.locationLat == null || task.locationLng == null
          ? null
          : (lat: task.locationLat!, lng: task.locationLng!),
    );
  }

  final String title;
  final String notes;

  /// Start date; null = unscheduled (backlog).
  final LocalDate? date;

  /// Start time of timed tasks (kept while all-day so toggling back restores it).
  final LocalTime? startTime;

  /// Duration of timed tasks (minutes).
  final int durationMinutes;
  final bool allDay;

  /// Length of an all-day task in days (multi-day range).
  final int allDayDays;

  /// Edit the end time instead of the duration.
  final bool endMode;

  /// IANA zone (fixed) or null (floating).
  final String? zoneId;
  final RecurrenceRule? recurrence;
  final String? categoryId;
  final int? color;
  final int priority;
  final TrackingMode trackingMode;
  final String? icon;
  final String location;
  final String url;
  final String? linkedChecklistId;
  final LocalDateTime? deadline;
  final int? estimateMinutes;

  /// Map pin of the place (T3.7.13); the [location] text stays the display name.
  final ({double lat, double lng})? coordinates;

  bool get isBacklog => date == null;
  bool get isRecurring => recurrence != null;

  /// Start in the task's wall clock (null for backlog tasks).
  LocalDateTime? get startLocal {
    final d = date;
    if (d == null) return null;
    return allDay ? d.atStartOfDay : d.atTime(startTime ?? LocalTime(9, 0));
  }

  int get effectiveDurationMinutes => allDay ? allDayDays * 1440 : durationMinutes;

  LocalDateTime? get endLocal => startLocal?.plusMinutes(effectiveDurationMinutes);

  /// Days between the start date and the end (the "+1 day" label; all-day ranges excluded).
  int get endDayOffset {
    final start = startLocal;
    final end = endLocal;
    if (start == null || end == null || allDay) return 0;
    return start.date.daysUntil(end.date) - (end.time == LocalTime.midnight && end.isAfter(start) ? 1 : 0);
  }

  /// Last day of an all-day range.
  LocalDate? get lastAllDayDate => allDay ? date?.plusDays(allDayDays - 1) : null;

  /// Planned after the deadline (T3.1.13 warning).
  bool get plannedAfterDeadline {
    final d = deadline;
    final start = startLocal;
    if (d == null || start == null) return false;
    return start.isAfter(d);
  }

  RecurrenceAnchor? get anchor {
    final start = startLocal;
    if (start == null) return null;
    return allDay
        ? RecurrenceAnchor.allDayOn(start.date, zoneId, days: allDayDays)
        : RecurrenceAnchor(start, zoneId, durationMinutes: durationMinutes);
  }

  TaskForm copyWith({
    String? title,
    String? notes,
    Object? date = _unset,
    Object? startTime = _unset,
    int? durationMinutes,
    bool? allDay,
    int? allDayDays,
    bool? endMode,
    Object? zoneId = _unset,
    Object? recurrence = _unset,
    Object? categoryId = _unset,
    Object? color = _unset,
    int? priority,
    TrackingMode? trackingMode,
    Object? icon = _unset,
    String? location,
    String? url,
    Object? linkedChecklistId = _unset,
    Object? deadline = _unset,
    Object? estimateMinutes = _unset,
    Object? coordinates = _unset,
  }) => TaskForm(
    title: title ?? this.title,
    notes: notes ?? this.notes,
    date: identical(date, _unset) ? this.date : date as LocalDate?,
    startTime: identical(startTime, _unset) ? this.startTime : startTime as LocalTime?,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    allDay: allDay ?? this.allDay,
    allDayDays: allDayDays ?? this.allDayDays,
    endMode: endMode ?? this.endMode,
    zoneId: identical(zoneId, _unset) ? this.zoneId : zoneId as String?,
    recurrence: identical(recurrence, _unset) ? this.recurrence : recurrence as RecurrenceRule?,
    categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
    color: identical(color, _unset) ? this.color : color as int?,
    priority: priority ?? this.priority,
    trackingMode: trackingMode ?? this.trackingMode,
    icon: identical(icon, _unset) ? this.icon : icon as String?,
    location: location ?? this.location,
    url: url ?? this.url,
    linkedChecklistId: identical(linkedChecklistId, _unset) ? this.linkedChecklistId : linkedChecklistId as String?,
    deadline: identical(deadline, _unset) ? this.deadline : deadline as LocalDateTime?,
    estimateMinutes: identical(estimateMinutes, _unset) ? this.estimateMinutes : estimateMinutes as int?,
    coordinates: identical(coordinates, _unset) ? this.coordinates : coordinates as ({double lat, double lng})?,
  );

  // ---------------------------------------------------------------------------
  // Field transitions with their invariants.

  /// Sets the end time and keeps the start: crossing midnight means the next day(s).
  TaskForm withEnd(LocalTime end, {int dayOffset = 0}) {
    final start = startLocal;
    if (start == null || allDay) return this;
    var endAt = start.date.plusDays(dayOffset).atTime(end);
    if (!endAt.isAfter(start)) endAt = endAt.plusDays(1);
    return copyWith(durationMinutes: start.minutesUntil(endAt).clamp(1, DurationMinutes.max));
  }

  /// Toggles all-day: the day range covers the timed span, and back keeps the previous time.
  TaskForm withAllDay(bool on) {
    if (on == allDay) return this;
    if (on) {
      final days = durationMinutes >= 1440 ? (durationMinutes / 1440).ceil().clamp(1, 365) : 1;
      return copyWith(allDay: true, allDayDays: days);
    }
    return copyWith(allDay: false, durationMinutes: durationMinutes <= 0 ? 60 : durationMinutes);
  }

  /// Sets the last day of an all-day range (never before the start).
  TaskForm withAllDayEnd(LocalDate last) {
    final d = date;
    if (d == null) return this;
    return copyWith(allDayDays: (d.daysUntil(last) + 1).clamp(1, 365));
  }

  /// *No date (backlog)*: unscheduled tasks can't repeat (T3.1.11).
  TaskForm withBacklog(bool on, {required LocalDate today}) =>
      on ? copyWith(date: null, recurrence: null) : copyWith(date: date ?? today);

  /// Floating ↔ fixed zone (the wall-clock values are kept).
  TaskForm withZone(String? zone) => copyWith(zoneId: zone);

  /// Applies a picked rule and the anchor it was aligned to (T2.1.15 anchor sync).
  TaskForm withRecurrence(RecurrenceRule? rule, {LocalDateTime? alignedStart}) {
    var next = copyWith(recurrence: rule);
    if (alignedStart != null && !isBacklog) {
      next = next.copyWith(date: alignedStart.date, startTime: allDay ? startTime : alignedStart.time);
    }
    return next;
  }

  // ---------------------------------------------------------------------------

  /// [base] with the form's values (a fresh task for creation, the current row for edits).
  Task applyTo(Task base) {
    String? blank(String s) => s.trim().isEmpty ? null : s;
    return base.copyWith(
      title: title.trim(),
      notes: blank(notes),
      startLocal: startLocal,
      durationMinutes: isBacklog
          ? (estimateMinutes ?? base.durationMinutes ?? durationMinutes)
          : effectiveDurationMinutes,
      isAllDay: !isBacklog && allDay,
      timeZone: zoneId,
      recurrence: isBacklog ? null : recurrence,
      categoryId: categoryId,
      color: color,
      priority: priority,
      trackingMode: trackingMode,
      icon: icon,
      location: blank(location)?.trim(),
      url: blank(url)?.trim(),
      linkedChecklistId: linkedChecklistId,
      deadlineLocal: deadline,
      estimateMinutes: estimateMinutes,
      locationLat: coordinates?.lat,
      locationLng: coordinates?.lng,
    );
  }

  /// Domain validation of the form ([isValidZone] checks IANA ids).
  List<TaskValidationError> validate({bool Function(String zoneId)? isValidZone}) => validateTask(
    applyTo(const Task(id: 'form', seriesId: 'form', title: '')),
    isValidZone: isValidZone,
  );

  /// Fields a single occurrence may override (T3.2.06): start, duration, title and notes.
  static const occurrenceFields = {'start', 'duration', 'title', 'notes'};

  /// Names of the fields that differ from [other] (unsaved-changes guard, scope matrix).
  Set<String> diff(TaskForm other) => {
    if (title.trim() != other.title.trim()) 'title',
    if (notes.trim() != other.notes.trim()) 'notes',
    if (startLocal != other.startLocal) 'start',
    if (effectiveDurationMinutes != other.effectiveDurationMinutes) 'duration',
    if (allDay != other.allDay) 'allDay',
    if (zoneId != other.zoneId) 'zone',
    if (recurrence != other.recurrence) 'recurrence',
    if (categoryId != other.categoryId) 'category',
    if (color != other.color) 'color',
    if (priority != other.priority) 'priority',
    if (trackingMode != other.trackingMode) 'tracking',
    if (icon != other.icon) 'icon',
    if (location.trim() != other.location.trim()) 'location',
    if (url.trim() != other.url.trim()) 'url',
    if (linkedChecklistId != other.linkedChecklistId) 'checklist',
    if (deadline != other.deadline) 'deadline',
    if (estimateMinutes != other.estimateMinutes) 'estimate',
    if (coordinates != other.coordinates) 'place',
  };

  /// Whether the changes of [diff] touch *when* the task happens.
  static bool isTimingChange(Set<String> changed) =>
      changed.contains('start') ||
      changed.contains('duration') ||
      changed.contains('allDay') ||
      changed.contains('zone') ||
      changed.contains('recurrence');

  @override
  bool operator ==(Object other) => other is TaskForm && diff(other).isEmpty && other.endMode == endMode;

  @override
  int get hashCode => Object.hash(title.trim(), startLocal, effectiveDurationMinutes, recurrence, categoryId);
}
