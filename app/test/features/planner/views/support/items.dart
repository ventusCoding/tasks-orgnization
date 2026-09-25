import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

var _seq = 0;

/// Builds a [PlannerItem] in UTC-like wall time (startUtc = start as UTC unless [startUtc] given).
PlannerItem item(
  String title,
  LocalDateTime start,
  int minutes, {
  String? id,
  OccurrenceStatus status = OccurrenceStatus.scheduled,
  bool allDay = false,
  int priority = 0,
  String? categoryId,
  int? color,
  TrackingMode trackingMode = TrackingMode.check,
  bool recurring = false,
  DateTime? startUtc,
  String? notes,
  String? location,
}) {
  final taskId = id ?? 'task-${_seq++}';
  final su = startUtc ?? start.toDateTimeUtc();
  return PlannerItem(
    taskId: taskId,
    seriesId: taskId,
    occurrenceKey: start.toIso(),
    title: title,
    startLocal: start,
    durationMinutes: minutes,
    startUtc: su,
    endUtc: su.add(Duration(minutes: minutes)),
    status: status,
    allDay: allDay,
    priority: priority,
    categoryId: categoryId,
    color: color,
    trackingMode: trackingMode,
    isRecurring: recurring,
    notes: notes,
    location: location,
  );
}

LocalDateTime at(int y, int m, int d, [int h = 0, int min = 0]) => LocalDateTime.of(y, m, d, h, min);
