import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Typed validation errors of the task model (localized by the presentation layer).
enum TaskValidationError {
  titleEmpty,
  titleTooLong,
  durationOutOfRange,
  allDayNotMidnight,
  allDayPartialDay,
  allDayZeroLength,
  recurrenceWithoutStart,
  recurrenceInvalid,
  zoneInvalid,
  priorityOutOfRange,
  urlInvalid,
  estimateOutOfRange,
}

/// Thrown by the repository when a task can't be saved.
class TaskValidationException implements Exception {
  const TaskValidationException(this.errors);

  final List<TaskValidationError> errors;

  @override
  String toString() => 'TaskValidationException(${errors.map((e) => e.name).join(', ')})';
}

/// Trimmed title, 1–300 characters.
abstract final class TaskTitle {
  static const maxLength = 300;

  static TaskValidationError? check(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return TaskValidationError.titleEmpty;
    if (t.length > maxLength) return TaskValidationError.titleTooLong;
    return null;
  }

  static String parse(String raw) {
    final error = check(raw);
    if (error != null) throw TaskValidationException([error]);
    return raw.trim();
  }
}

/// Duration 0–525 600 minutes (365 days).
abstract final class DurationMinutes {
  static const max = 525600;

  static bool isValid(int? minutes) => minutes == null || (minutes >= 0 && minutes <= max);
}

/// URL fields: http(s) with a host; a bare domain gets `https://`.
abstract final class TaskUrl {
  static String? normalize(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return null;
    final withScheme = t.contains('://') ? t : 'https://$t';
    final uri = Uri.tryParse(withScheme);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        !uri.host.contains('.')) {
      return null;
    }
    return withScheme;
  }

  static bool isValid(String? raw) => (raw?.trim().isEmpty ?? true) || normalize(raw) != null;
}

/// Scheduling part of a task (T3.1.04): enforces the server invariants of T3.1.01.
@immutable
class TaskSchedule {
  const TaskSchedule({
    this.startLocal,
    this.durationMinutes,
    this.isAllDay = false,
    this.zoneMode = const TimeZoneMode.floating(),
    this.recurrence,
  });

  factory TaskSchedule.of(Task task) => TaskSchedule(
    startLocal: task.startLocal,
    durationMinutes: task.durationMinutes,
    isAllDay: task.isAllDay,
    zoneMode: task.zoneMode,
    recurrence: task.recurrence,
  );

  final LocalDateTime? startLocal;
  final int? durationMinutes;
  final bool isAllDay;
  final TimeZoneMode zoneMode;
  final RecurrenceRule? recurrence;

  bool get isUnscheduled => startLocal == null;
  bool get isRecurring => recurrence != null;
  int get effectiveDurationMinutes => durationMinutes ?? (isAllDay ? 1440 : 0);
  LocalDateTime? get endLocal => startLocal?.plusMinutes(effectiveDurationMinutes);

  RecurrenceAnchor? get anchor {
    final start = startLocal;
    if (start == null) return null;
    return RecurrenceAnchor(
      isAllDay ? start.date.atStartOfDay : start,
      zoneMode.zoneId,
      durationMinutes: effectiveDurationMinutes,
      allDay: isAllDay,
    );
  }

  /// Validation errors (empty when valid). [isValidZone] checks IANA names (optional).
  List<TaskValidationError> validate({bool Function(String zoneId)? isValidZone}) {
    final errors = <TaskValidationError>[];
    final duration = durationMinutes;
    if (!DurationMinutes.isValid(duration)) errors.add(TaskValidationError.durationOutOfRange);
    final start = startLocal;
    if (isAllDay && start != null) {
      if (start.time != LocalTime.midnight) errors.add(TaskValidationError.allDayNotMidnight);
      final d = effectiveDurationMinutes;
      if (d == 0) {
        errors.add(TaskValidationError.allDayZeroLength);
      } else if (d % 1440 != 0) {
        errors.add(TaskValidationError.allDayPartialDay);
      }
    }
    final rule = recurrence;
    if (rule != null) {
      if (start == null) {
        errors.add(TaskValidationError.recurrenceWithoutStart);
      } else if (!rule.validate(anchor: anchor).isValid) {
        errors.add(TaskValidationError.recurrenceInvalid);
      }
    }
    final zone = zoneMode.zoneId;
    if (zone != null && isValidZone != null && !isValidZone(zone)) errors.add(TaskValidationError.zoneInvalid);
    return errors;
  }

  /// Denormalized `recurrence_until_local` (T3.1.04): null for one-offs and open-ended rules;
  /// the last occurrence start for `count`/`until` rules (rdates included).
  LocalDateTime? recurrenceUntilLocal(RecurrenceEngine engine) {
    final rule = recurrence;
    final a = anchor;
    if (rule == null || a == null) return null;
    LocalDateTime? latestRdate;
    for (final r in rule.rdates) {
      final parsed = LocalDateTime.tryParse(r) ?? LocalDate.tryParse(r)?.atTime(a.start.time);
      if (parsed != null && (latestRdate == null || parsed.isAfter(latestRdate))) latestRdate = parsed;
    }
    LocalDateTime? max(LocalDateTime? x, LocalDateTime? y) => x == null ? y : (y == null ? x : (x.isAfter(y) ? x : y));
    switch (rule.type) {
      case RuleType.afterCompletion:
      case RuleType.quota:
        final until = rule.until;
        return until == null ? null : max(until, latestRdate);
      case RuleType.fixed:
        final count = rule.countMode == CountMode.occurrences ? rule.count : null;
        final until = rule.until;
        if (count == null && until == null) return null;
        // Wall-clock expansion in a fixed evaluation zone (floating anchors are zone-free).
        const zone = 'UTC';
        final evalAnchor = a.zoneId == null ? a : a.copyWith(zoneId: zone);
        try {
          if (count != null) {
            LocalDateTime? last;
            for (final o in engine.between(
              rule,
              evalAnchor,
              a.start.plusDays(-1),
              a.start.date.plusYears(400).atStartOfDay,
              evalZone: zone,
              durationMinutes: 0,
              limit: count + rule.rdates.length,
            )) {
              last = o.startLocal;
            }
            return max(last, latestRdate) ?? a.start;
          }
          return max(until, latestRdate);
        } on Object {
          return until;
        }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TaskSchedule &&
      other.startLocal == startLocal &&
      other.durationMinutes == durationMinutes &&
      other.isAllDay == isAllDay &&
      other.zoneMode == zoneMode &&
      other.recurrence == recurrence;

  @override
  int get hashCode => Object.hash(startLocal, durationMinutes, isAllDay, zoneMode, recurrence);
}

/// Validates a whole task (title, schedule, priority, URL, estimate).
List<TaskValidationError> validateTask(Task task, {bool Function(String zoneId)? isValidZone}) => [
  ?TaskTitle.check(task.title),
  if (task.priority < 0 || task.priority > 4) TaskValidationError.priorityOutOfRange,
  if (!TaskUrl.isValid(task.url)) TaskValidationError.urlInvalid,
  if (!DurationMinutes.isValid(task.estimateMinutes)) TaskValidationError.estimateOutOfRange,
  ...TaskSchedule.of(task).validate(isValidZone: isValidZone),
];
