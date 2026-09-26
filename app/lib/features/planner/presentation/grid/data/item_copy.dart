import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Copy helper for [PlannerItem] covering fields the contract's `copyWith` doesn't expose
/// (priority, category, override flags). Every other field is preserved.
PlannerItem copyItem(
  PlannerItem i, {
  String? title,
  LocalDateTime? startLocal,
  int? durationMinutes,
  DateTime? startUtc,
  OccurrenceStatus? status,
  bool? allDay,
  int? priority,
  String? categoryId,
  bool? isOverridden,
  String? manualSortKey,
  LocalDateTime? deadlineLocal,
}) {
  final newStartUtc = startUtc ??
      (startLocal == null ? i.startUtc : i.startUtc.add(Duration(minutes: i.startLocal.minutesUntil(startLocal))));
  final minutes = durationMinutes ?? i.durationMinutes;
  final moved = startLocal != null && startLocal != i.startLocal;
  return PlannerItem(
    taskId: i.taskId,
    seriesId: i.seriesId,
    occurrenceKey: i.occurrenceKey,
    title: title ?? i.title,
    startLocal: startLocal ?? i.startLocal,
    durationMinutes: minutes,
    startUtc: newStartUtc,
    endUtc: newStartUtc.add(Duration(minutes: minutes)),
    status: status ?? i.status,
    allDay: allDay ?? i.allDay,
    color: i.color,
    categoryId: categoryId ?? i.categoryId,
    priority: priority ?? i.priority,
    trackingMode: i.trackingMode,
    isRecurring: i.isRecurring,
    isOverridden: isOverridden ?? i.isOverridden,
    overdue: i.overdue,
    timeZone: i.timeZone,
    icon: i.icon,
    location: i.location,
    linkedChecklistId: i.linkedChecklistId,
    notes: i.notes,
    recordId: i.recordId,
    isMoved: i.isMoved || moved,
    isCurrent: i.isCurrent,
    isQuotaSlot: i.isQuotaSlot,
    quotaPeriodKey: i.quotaPeriodKey,
    originalStartLocal: i.originalStartLocal,
    ownZoneStartLocal: i.ownZoneStartLocal,
    deadlineLocal: deadlineLocal ?? i.deadlineLocal,
    estimateMinutes: i.estimateMinutes,
    manualSortKey: manualSortKey ?? i.manualSortKey,
    completionPercent: i.completionPercent,
    trackedSeconds: i.trackedSeconds,
    rating: i.rating,
    isPaused: i.isPaused,
  );
}

/// True when [item] overlaps the local days of [range].
bool overlapsRange(PlannerItem item, DayRange range) {
  final start = item.startLocal;
  final rangeStart = range.start.atStartOfDay;
  final rangeEnd = range.endExclusive.atStartOfDay;
  final minutes = item.allDay ? (item.durationMinutes <= 0 ? 1440 : item.durationMinutes) : item.durationMinutes;
  final end = start.plusMinutes(minutes <= 0 ? 1 : minutes);
  return start.isBefore(rangeEnd) && end.isAfter(rangeStart);
}
