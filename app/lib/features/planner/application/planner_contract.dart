import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CONTRACT consumed by all planner views, implemented by the planner data layer ([3.1]/[3.2]).
///
/// Richer APIs for views live next to it: `plannerRangeProvider` (items + truncation flag),
/// `plannerServiceProvider` (postpone, move to today, timers…), `showOccurrenceSheet`,
/// `showQuickCreateSheet`, `showEditScopeDialog` and `showBulkActionsSheet` (presentation).

/// Occurrences overlapping a range of local days (user's current zone), sorted by start
/// (day → all-day first → start → priority desc → title → id). Streams on every task /
/// occurrence / category change; floating tasks follow the device zone.
final plannerItemsProvider = StreamProvider.autoDispose.family<List<PlannerItem>, DayRange>(
  (ref, range) => ref.watch(occurrenceRangeServiceProvider).watch(range).map((r) => r.items),
);

/// Unscheduled (backlog) tasks as items with a placeholder start (today 00:00, key `''`), in
/// manual order (T3.1.11 / T3.7.02).
final backlogItemsProvider = StreamProvider.autoDispose<List<PlannerItem>>((ref) {
  final queries = ref.watch(plannerQueriesProvider);
  final clock = ref.watch(clockProvider);
  final zones = ref.watch(zoneResolverProvider);
  final zone = ref.watch(deviceZoneProvider);
  final defaultDuration = ref.watch(plannerSettingsProvider).defaultTaskDurationMinutes;
  return queries.watchUnscheduled().asyncMap((tasks) async {
    final colors = await queries.categoryColors();
    final now = clock.nowUtc();
    final today = zones.toLocal(now, zone).date.atStartOfDay;
    return [
      for (final t in tasks)
        PlannerItem(
          taskId: t.id,
          seriesId: t.seriesId,
          occurrenceKey: '',
          title: t.title,
          startLocal: today,
          durationMinutes: t.estimateMinutes ?? t.durationMinutes ?? defaultDuration,
          startUtc: now,
          endUtc: now.add(Duration(minutes: t.estimateMinutes ?? t.durationMinutes ?? defaultDuration)),
          status: OccurrenceStatus.scheduled,
          color: t.color ?? colors[t.categoryId],
          categoryId: t.categoryId,
          priority: t.priority,
          trackingMode: t.trackingMode,
          timeZone: t.timeZone,
          icon: t.icon,
          location: t.location,
          linkedChecklistId: t.linkedChecklistId,
          notes: t.notes,
          deadlineLocal: t.deadlineLocal,
          estimateMinutes: t.estimateMinutes,
          manualSortKey: t.manualSortKey,
        ),
    ];
  });
});

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

/// Planner data layer implementation: every call is one transaction registered on the undo
/// stack. `createAt` returns the new task id.
class _PlannerActionsImpl implements PlannerActions {
  _PlannerActionsImpl(this._ref);

  final Ref _ref;

  PlannerService get _service => _ref.read(plannerServiceProvider);

  @override
  Future<String?> createAt(LocalDateTime start, int durationMinutes, {String? title, bool allDay = false}) async =>
      (await _service.createAt(start, durationMinutes, title: title, allDay: allDay)).taskId;

  @override
  Future<void> reschedule(
    PlannerItem item, {
    required LocalDateTime newStart,
    int? newDurationMinutes,
    bool? allDay,
    EditScope scope = EditScope.thisOccurrence,
  }) async {
    if (item.isBacklog) {
      await _service.scheduleBacklog(item.taskId, newStart, newDurationMinutes, allDay: allDay ?? false);
      return;
    }
    await _service.reschedule(
      item,
      newStart: newStart,
      newDurationMinutes: newDurationMinutes,
      allDay: allDay,
      scope: scope,
    );
  }

  @override
  Future<void> setStatus(PlannerItem item, OccurrenceStatus status, {String? skipReason}) async {
    if (item.isBacklog) return;
    await _service.setStatus(item, status, skipReason: skipReason);
  }

  @override
  Future<void> scheduleBacklogItem(PlannerItem item, LocalDateTime start, int durationMinutes) async {
    await _service.scheduleBacklog(item.taskId, start, durationMinutes);
  }
}

final plannerActionsProvider = Provider<PlannerActions>(_PlannerActionsImpl.new);
