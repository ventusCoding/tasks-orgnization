import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Derived status of one occurrence (arch §7.3 task_occurrences.status + derived `missed`).
enum OccurrenceStatus { scheduled, inProgress, done, skipped, missed, cancelled }

/// How a task is tracked (tasks.tracking_mode).
enum TrackingMode { check, event, timer }

/// CONTRACT between the planner data layer ([3.1]/[3.2]) and every planner view ([3.3]–[3.7],
/// Today, stats…): one resolved occurrence ready to display.
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

  LocalDateTime get endLocal => startLocal.plusMinutes(durationMinutes);

  /// Stable key for widgets/lists.
  String get key => '$taskId|$occurrenceKey';

  @override
  bool operator ==(Object other) =>
      other is PlannerItem &&
      other.taskId == taskId &&
      other.occurrenceKey == occurrenceKey &&
      other.title == title &&
      other.startLocal == startLocal &&
      other.durationMinutes == durationMinutes &&
      other.status == status &&
      other.allDay == allDay &&
      other.color == color &&
      other.categoryId == categoryId &&
      other.priority == priority &&
      other.overdue == overdue;

  @override
  int get hashCode => Object.hash(taskId, occurrenceKey, title, startLocal, durationMinutes, status, allDay, color, categoryId, priority, overdue);
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
