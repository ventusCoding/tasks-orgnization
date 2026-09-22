import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CONTRACT consumed by all planner views. The planner data layer ([3.1]/[3.2]) replaces the stub
/// implementations below (same provider names and types).

/// Occurrences overlapping a range of local days (user's current zone), sorted by start.
final plannerItemsProvider = StreamProvider.autoDispose.family<List<PlannerItem>, DayRange>(
  (ref, range) => Stream.value(const <PlannerItem>[]),
);

/// Unscheduled (backlog) tasks as items with a placeholder start (T3.1.07 / T3.7.02).
final backlogItemsProvider = StreamProvider.autoDispose<List<PlannerItem>>(
  (ref) => Stream.value(const <PlannerItem>[]),
);

/// Mutations the views trigger (gestures, quick actions). Each returns the operation id for undo.
abstract interface class PlannerActions {
  /// Quick-create a task at [start] (wall clock, current zone) for [durationMinutes].
  Future<String?> createAt(LocalDateTime start, int durationMinutes, {String? title, bool allDay = false});

  /// Move/resize an occurrence. For recurring tasks the caller passes the chosen [scope].
  Future<void> reschedule(
    PlannerItem item, {
    required LocalDateTime newStart,
    int? newDurationMinutes,
    bool? allDay,
    EditScope scope = EditScope.thisOccurrence,
  });

  Future<void> setStatus(PlannerItem item, OccurrenceStatus status, {String? skipReason});

  Future<void> scheduleBacklogItem(PlannerItem item, LocalDateTime start, int durationMinutes);
}

/// Stub until the planner data layer lands.
class _NoopPlannerActions implements PlannerActions {
  @override
  Future<String?> createAt(LocalDateTime start, int durationMinutes, {String? title, bool allDay = false}) async => null;

  @override
  Future<void> reschedule(
    PlannerItem item, {
    required LocalDateTime newStart,
    int? newDurationMinutes,
    bool? allDay,
    EditScope scope = EditScope.thisOccurrence,
  }) async {}

  @override
  Future<void> setStatus(PlannerItem item, OccurrenceStatus status, {String? skipReason}) async {}

  @override
  Future<void> scheduleBacklogItem(PlannerItem item, LocalDateTime start, int durationMinutes) async {}
}

final plannerActionsProvider = Provider<PlannerActions>((ref) => _NoopPlannerActions());
