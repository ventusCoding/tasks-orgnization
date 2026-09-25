import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Derived status of one occurrence (arch §7.3 task_occurrences.status + derived `missed`).
enum OccurrenceStatus { scheduled, inProgress, done, skipped, missed, cancelled }

/// How a task is tracked (tasks.tracking_mode).
enum TrackingMode { check, event, timer }

const Object _unset = Object();

/// CONTRACT between the planner data layer ([3.1]/[3.2]) and every planner view ([3.3]–[3.7],
/// Today, stats…): one resolved occurrence ready to display.
///
/// Fields after [notes] were added by the planner data layer (additive, all optional).
@immutable
class PlannerItem {
  const PlannerItem({
    required this.taskId,
    required this.seriesId,
    required this.occurrenceKey,
    required this.title,
    required this.startLocal,
    required this.durationMinutes,
    required this.startUtc,
    required this.endUtc,
    required this.status,
    this.allDay = false,
    this.color,
    this.categoryId,
    this.priority = 0,
    this.trackingMode = TrackingMode.check,
    this.isRecurring = false,
    this.isOverridden = false,
    this.overdue = false,
    this.timeZone,
    this.icon,
    this.location,
    this.linkedChecklistId,
    this.notes,
    this.recordId,
    this.isMoved = false,
    this.isCurrent = false,
    this.isQuotaSlot = false,
    this.quotaPeriodKey,
    this.originalStartLocal,
    this.ownZoneStartLocal,
    this.deadlineLocal,
    this.estimateMinutes,
    this.manualSortKey,
    this.completionPercent,
    this.trackedSeconds,
    this.rating,
    this.isPaused = false,
  });

  final String taskId;
  final String seriesId;

  /// Original local start (identity of the occurrence; never changes when moved).
  final String occurrenceKey;
  final String title;

  /// Effective local start in the zone used for display (after overrides).
  final LocalDateTime startLocal;
  final int durationMinutes;
  final DateTime startUtc;
  final DateTime endUtc;
  final OccurrenceStatus status;
  final bool allDay;

  /// Effective ARGB color: the task's color override, else its category color.
  final int? color;
  final String? categoryId;
  final int priority;
  final TrackingMode trackingMode;
  final bool isRecurring;
  final bool isOverridden;
  final bool overdue;

  /// IANA zone, or null = floating.
  final String? timeZone;
  final String? icon;
  final String? location;
  final String? linkedChecklistId;
  final String? notes;

  /// Id of the stored `task_occurrences` row (null when the occurrence was never touched).
  final String? recordId;

  /// The occurrence was moved away from its generated start (override).
  final bool isMoved;

  /// `now` is inside `[startUtc, endUtc)` and the occurrence is still open.
  final bool isCurrent;

  /// Unplaced/placed slot of a quota rule ("3× per week"): [occurrenceKey] is `week:…#n`.
  final bool isQuotaSlot;

  /// Period key of a quota slot (`week:2026-09-21`).
  final String? quotaPeriodKey;

  /// Generated (pre-override) start in the task's own wall clock.
  final LocalDateTime? originalStartLocal;

  /// Effective start in the task's own zone (fixed-zone tasks; shown as a zone badge).
  final LocalDateTime? ownZoneStartLocal;

  /// Hard deadline (T3.1.13), task wall clock.
  final LocalDateTime? deadlineLocal;

  /// Estimate for backlog items (T3.1.11).
  final int? estimateMinutes;

  /// Manual order key (backlog and untimed items within a day).
  final String? manualSortKey;
  final int? completionPercent;
  final int? trackedSeconds;
  final int? rating;

  /// The series is paused (T3.2.21); only occurrences with an outcome are listed.
  final bool isPaused;

  LocalDateTime get endLocal => startLocal.plusMinutes(durationMinutes);

  /// Stable key for widgets/lists.
  String get key => '$taskId|$occurrenceKey';

  bool get isFixedZone => timeZone != null;
  /// Ends after the midnight following its start.
  bool get isMultiDay => endLocal.isAfter(startLocal.date.plusDays(1).atStartOfDay);
  bool get isDone => status == OccurrenceStatus.done;

  /// Still actionable (not done/skipped/cancelled).
  bool get isOpen => status == OccurrenceStatus.scheduled || status == OccurrenceStatus.inProgress || status == OccurrenceStatus.missed;

  /// Backlog items carry a placeholder start (see `backlogItemsProvider`).
  bool get isBacklog => occurrenceKey.isEmpty;

  PlannerItem copyWith({
    String? title,
    LocalDateTime? startLocal,
    int? durationMinutes,
    DateTime? startUtc,
    DateTime? endUtc,
    OccurrenceStatus? status,
    bool? allDay,
    Object? color = _unset,
    bool? overdue,
    bool? isCurrent,
    bool? isMoved,
    Object? recordId = _unset,
  }) => PlannerItem(
    taskId: taskId,
    seriesId: seriesId,
    occurrenceKey: occurrenceKey,
    title: title ?? this.title,
    startLocal: startLocal ?? this.startLocal,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    status: status ?? this.status,
    allDay: allDay ?? this.allDay,
    color: identical(color, _unset) ? this.color : color as int?,
    categoryId: categoryId,
    priority: priority,
    trackingMode: trackingMode,
    isRecurring: isRecurring,
    isOverridden: isOverridden,
    overdue: overdue ?? this.overdue,
    timeZone: timeZone,
    icon: icon,
    location: location,
    linkedChecklistId: linkedChecklistId,
    notes: notes,
    recordId: identical(recordId, _unset) ? this.recordId : recordId as String?,
    isMoved: isMoved ?? this.isMoved,
    isCurrent: isCurrent ?? this.isCurrent,
    isQuotaSlot: isQuotaSlot,
    quotaPeriodKey: quotaPeriodKey,
    originalStartLocal: originalStartLocal,
    ownZoneStartLocal: ownZoneStartLocal,
    deadlineLocal: deadlineLocal,
    estimateMinutes: estimateMinutes,
    manualSortKey: manualSortKey,
    completionPercent: completionPercent,
    trackedSeconds: trackedSeconds,
    rating: rating,
    isPaused: isPaused,
  );

  @override
  bool operator ==(Object other) =>
      other is PlannerItem &&
      other.taskId == taskId &&
      other.seriesId == seriesId &&
      other.occurrenceKey == occurrenceKey &&
      other.title == title &&
      other.startLocal == startLocal &&
      other.durationMinutes == durationMinutes &&
      other.startUtc == startUtc &&
      other.endUtc == endUtc &&
      other.status == status &&
      other.allDay == allDay &&
      other.color == color &&
      other.categoryId == categoryId &&
      other.priority == priority &&
      other.trackingMode == trackingMode &&
      other.isRecurring == isRecurring &&
      other.isOverridden == isOverridden &&
      other.overdue == overdue &&
      other.timeZone == timeZone &&
      other.icon == icon &&
      other.location == location &&
      other.linkedChecklistId == linkedChecklistId &&
      other.notes == notes &&
      other.recordId == recordId &&
      other.isMoved == isMoved &&
      other.isCurrent == isCurrent &&
      other.isQuotaSlot == isQuotaSlot &&
      other.deadlineLocal == deadlineLocal &&
      other.estimateMinutes == estimateMinutes &&
      other.manualSortKey == manualSortKey &&
      other.completionPercent == completionPercent &&
      other.trackedSeconds == trackedSeconds &&
      other.rating == rating &&
      other.isPaused == isPaused;

  @override
  int get hashCode => Object.hash(
    taskId,
    occurrenceKey,
    title,
    startLocal,
    durationMinutes,
    status,
    allDay,
    color,
    categoryId,
    priority,
    overdue,
    isCurrent,
    isMoved,
    recordId,
    completionPercent,
    trackingMode,
  );

  @override
  String toString() => 'PlannerItem($title, $occurrenceKey → $startLocal, ${status.name})';
}

/// A range of local days: [start, start + days).
@immutable
class DayRange {
  const DayRange(this.start, this.days);

  final LocalDate start;
  final int days;

  LocalDate get endExclusive => start.plusDays(days);

  bool contains(LocalDate d) => !d.isBefore(start) && d.isBefore(endExclusive);

  @override
  bool operator ==(Object other) => other is DayRange && other.start == start && other.days == days;

  @override
  int get hashCode => Object.hash(start, days);

  @override
  String toString() => 'DayRange($start, $days)';
}

/// Scope of an edit on a recurring series (T3.2.05).
enum EditScope { thisOccurrence, thisAndFollowing, allOccurrences }
