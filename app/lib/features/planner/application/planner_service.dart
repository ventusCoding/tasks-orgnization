import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/planner/application/occurrence_range_service.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_settings.dart';
import 'package:everslot/features/planner/data/occurrences_repository.dart';
import 'package:everslot/features/planner/data/planner_queries.dart';
import 'package:everslot/features/planner/data/tasks_repository.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localizations for non-widget code (default titles, undo labels) in the user's language.
final plannerL10nProvider = Provider<AppLocalizations>((ref) {
  final code = ref.watch(userPreferencesProvider).localeCode ?? PlatformDispatcher.instance.locale.languageCode;
  try {
    return lookupAppLocalizations(Locale(code));
  } on Object {
    return lookupAppLocalizations(const Locale('en'));
  }
});

/// Application facade of the planner used by the editors, the occurrence sheet and the planner
/// contract. Converts the viewer's wall clock to each task's own zone, applies settings
/// (actual-time capture, timer policy) and registers every write on the undo stack.
class PlannerService {
  PlannerService(this._ref);

  final Ref _ref;

  TasksRepository get tasks => _ref.read(tasksRepositoryProvider);
  OccurrencesRepository get occurrences => _ref.read(occurrencesRepositoryProvider);
  PlannerQueries get queries => _ref.read(plannerQueriesProvider);
  RecurrenceService get recurrence => _ref.read(recurrenceServiceProvider);
  PlannerSettings get settings => _ref.read(plannerSettingsProvider);
  OccurrenceRangeService get ranges => _ref.read(occurrenceRangeServiceProvider);
  String get viewerZone => _ref.read(deviceZoneProvider);
  ZoneResolver get zones => _ref.read(zoneResolverProvider);
  AppLocalizations get l10n => _ref.read(plannerL10nProvider);

  DateTime get nowUtc => recurrence.nowUtc;
  LocalDateTime get nowLocal => zones.toLocal(nowUtc, viewerZone);

  OpRecord _undo(String label, OpRecord record) {
    _ref.read(undoStackProvider).push(label, record);
    return record;
  }

  // ---------------------------------------------------------------------------
  // Zone conversions (T3.2.03)

  /// Viewer wall clock → the task's own wall clock (fixed-zone tasks); floating and all-day
  /// values are unchanged.
  LocalDateTime toTaskLocal(String? taskZone, LocalDateTime viewerLocal, {bool allDay = false}) {
    if (allDay || taskZone == null || taskZone == viewerZone) return viewerLocal;
    return zones.toLocal(zones.resolve(viewerLocal, viewerZone).utc, taskZone);
  }

  /// Task wall clock → viewer wall clock.
  LocalDateTime toViewerLocal(String? taskZone, LocalDateTime taskLocal, {bool allDay = false}) {
    if (allDay || taskZone == null || taskZone == viewerZone) return taskLocal;
    return zones.toLocal(zones.resolve(taskLocal, taskZone).utc, viewerZone);
  }

  /// Effective start of [item] in its task's wall clock.
  LocalDateTime taskLocalStart(PlannerItem item) =>
      item.ownZoneStartLocal ?? toTaskLocal(item.timeZone, item.startLocal, allDay: item.allDay);

  // ---------------------------------------------------------------------------
  // Creation

  /// Quick-create (planner contract): floating task at [start] (viewer wall clock).
  Future<TaskWriteResult> createAt(LocalDateTime start, int durationMinutes, {String? title, bool allDay = false}) async {
    final days = (durationMinutes / 1440).ceil().clamp(1, 365);
    final result = await tasks.create(
      Task(
        id: '',
        seriesId: '',
        title: (title == null || title.trim().isEmpty) ? l10n.tasksUntitled : title,
        startLocal: allDay ? start.date.atStartOfDay : start,
        durationMinutes: allDay ? days * 1440 : durationMinutes,
        isAllDay: allDay,
        trackingMode: settings.defaultTrackingMode,
      ),
      source: 'quick',
    );
    _undo(l10n.tasksCreated, result.record);
    return result;
  }

  Future<TaskWriteResult> createTask(Task draft, {String source = 'editor'}) async {
    final result = await tasks.create(draft, source: source);
    _undo(l10n.tasksCreated, result.record);
    return result;
  }

  // ---------------------------------------------------------------------------
  // Reschedule (T3.2.10)

  /// Moves/resizes [item] to [newStart] (viewer wall clock) with the chosen [scope].
  Future<OpRecord> reschedule(
    PlannerItem item, {
    required LocalDateTime newStart,
    int? newDurationMinutes,
    bool? allDay,
    EditScope scope = EditScope.thisOccurrence,
    String source = 'drag',
  }) async {
    final task = await queries.task(item.taskId);
    if (task == null) return const OpRecord(opId: '', changes: [], cause: 'user');
    final targetAllDay = allDay ?? item.allDay;
    final taskStart = toTaskLocal(task.timeZone, newStart, allDay: targetAllDay);
    final OpRecord record;
    if (!task.isRecurring) {
      record = await tasks.rescheduleTask(
        task.id,
        start: taskStart,
        durationMinutes: newDurationMinutes,
        allDay: allDay,
        source: source,
      );
    } else if (item.isQuotaSlot || scope == EditScope.thisOccurrence) {
      record = await tasks.editOccurrence(
        task.id,
        item.occurrenceKey,
        start: taskStart,
        duration: newDurationMinutes,
        source: source,
      );
    } else if (scope == EditScope.thisAndFollowing) {
      record = (await tasks.update(
        task.copyWith(startLocal: taskStart, durationMinutes: newDurationMinutes ?? task.durationMinutes),
        scope: EditScope.thisAndFollowing,
        occurrenceKey: item.occurrenceKey,
        source: source,
      )).record;
    } else {
      final delta = taskLocalStart(item).minutesUntil(taskStart);
      record = (await tasks.update(
        task.copyWith(
          startLocal: task.startLocal!.plusMinutes(delta),
          durationMinutes: newDurationMinutes ?? task.durationMinutes,
        ),
        source: source,
      )).record;
    }
    return _undo(l10n.tasksMoved, record);
  }

  /// *Postpone* quick options (T3.2.10) — always "this occurrence".
  Future<OpRecord> postpone(PlannerItem item, PostponeOption option) {
    final target = postponeTarget(option, currentStart: item.startLocal, nowLocal: nowLocal);
    return reschedule(item, newStart: target, allDay: false, source: 'menu');
  }

  /// *Move to today* (overdue items): same time if still ahead, else the next quarter hour.
  Future<OpRecord> moveToToday(PlannerItem item) {
    final now = nowLocal;
    final target = item.allDay ? now.date.atStartOfDay : (sameTimeTodayIfAhead(item.startLocal, now) ?? nextQuarterHour(now));
    return reschedule(item, newStart: target, source: 'menu');
  }

  /// Schedules a backlog item at [start] (viewer wall clock).
  Future<OpRecord> scheduleBacklog(String taskId, LocalDateTime start, int? durationMinutes, {bool allDay = false}) async {
    final task = await queries.task(taskId);
    if (task == null) return const OpRecord(opId: '', changes: [], cause: 'user');
    final record = await tasks.schedule(
      taskId,
      toTaskLocal(task.timeZone, start, allDay: allDay),
      durationMinutes: durationMinutes,
      allDay: allDay,
      fallbackDuration: settings.defaultTaskDurationMinutes,
    );
    return _undo(l10n.tasksMoved, record);
  }

  // ---------------------------------------------------------------------------
  // Status (T3.2.04, T3.2.14)

  /// Whether the Done flow should ask for actual times.
  bool shouldAskActualTime(PlannerItem item) =>
      item.trackingMode != TrackingMode.timer &&
      !item.allDay &&
      TrackingPolicy.of(item.trackingMode).hasCheckbox &&
      shouldAskActualTimeFor(item);

  bool shouldAskActualTimeFor(PlannerItem item) =>
      shouldAskActualTimeSetting(settings.askActualTimeOnDone, plannedEnd: item.endUtc, now: nowUtc);

  /// Marks done with an actual-time option (T3.2.14).
  Future<OpRecord> markDone(
    PlannerItem item, {
    ActualTimeOption? actual,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    DateTime? start;
    DateTime? end;
    if (actual != null) {
      final r = actualTimesFor(
        actual,
        plannedStart: item.startUtc,
        plannedEnd: item.endUtc,
        now: nowUtc,
        customStart: customStart,
        customEnd: customEnd,
      );
      start = r.start;
      end = r.end;
    }
    final record = await occurrences.markDone(item.taskId, item.occurrenceKey, actualStart: start, actualEnd: end);
    return _undo(l10n.tasksMarkedDone, record);
  }

  Future<OpRecord> setStatus(PlannerItem item, OccurrenceStatus status, {String? skipReason}) async {
    final key = item.occurrenceKey;
    final OpRecord record;
    switch (status) {
      case OccurrenceStatus.done:
        return markDone(item);
      case OccurrenceStatus.scheduled:
        record = await occurrences.reopen(item.taskId, key);
        return _undo(l10n.tasksReopened, record);
      case OccurrenceStatus.skipped:
        record = await occurrences.skip(item.taskId, key, reason: skipReason);
        return _undo(l10n.tasksMarkedSkipped, record);
      case OccurrenceStatus.inProgress:
        record = await occurrences.start(item.taskId, key, policy: settings.timerPolicy);
      case OccurrenceStatus.cancelled:
        record = await occurrences.cancel(item.taskId, key);
        return _undo(l10n.tasksOccurrenceDeleted, record);
      case OccurrenceStatus.missed:
        record = await occurrences.setStatus(item.taskId, key, OccurrenceStatus.missed);
    }
    return _undo(l10n.tasksUpdated, record);
  }

  Future<OpRecord> startTimer(PlannerItem item) =>
      occurrences.start(item.taskId, item.occurrenceKey, policy: settings.timerPolicy);

  Future<OpRecord> pauseTimer(PlannerItem item) => occurrences.pause(item.taskId, item.occurrenceKey);

  Future<OpRecord> stopTimer(PlannerItem item) async =>
      _undo(l10n.tasksMarkedDone, await occurrences.stop(item.taskId, item.occurrenceKey));

  // ---------------------------------------------------------------------------
  // Delete (T3.1.10, T3.2.11)

  Future<OpRecord> delete(PlannerItem item, {EditScope scope = EditScope.allOccurrences}) async {
    final record = await tasks.delete(item.taskId, scope: scope, occurrenceKey: item.occurrenceKey);
    return _undo(scope == EditScope.thisOccurrence ? l10n.tasksOccurrenceDeleted : l10n.tasksDeleted, record);
  }

  // ---------------------------------------------------------------------------
  // Roll-over (T3.2.12)

  /// Unresolved one-off check/timer tasks that ended before today (within the look-back).
  Future<List<Task>> rollOverCandidates() async {
    final today = recurrence.today;
    final range = await ranges.resolveRange(
      today.minusDays(settings.overdueLookbackDays).atStartOfDay,
      today.atStartOfDay,
    );
    final byId = <String, Task>{};
    for (final o in range.occurrences) {
      final open = o.status == OccurrenceStatus.missed ||
          o.status == OccurrenceStatus.scheduled ||
          o.status == OccurrenceStatus.inProgress;
      if (!open || o.task.isRecurring || !TrackingPolicy.of(o.trackingMode).canBeMissed) continue;
      if (!o.startLocalViewer.date.isBefore(today)) continue;
      byId[o.task.id] = o.task;
    }
    return byId.values.toList();
  }

  /// Applies `planner.rollOverIncomplete = auto` (app start / day change). Returns the number of
  /// moved tasks. Deterministic event ids keep two devices from duplicating the move.
  Future<int> rollOverIfEnabled({bool force = false}) async {
    if (!force && settings.rollOverIncomplete != RollOverPolicy.auto) return 0;
    final candidates = await rollOverCandidates();
    if (candidates.isEmpty) return 0;
    final today = recurrence.today;
    await tasks.rollOver(
      candidates,
      today: today,
      nowLocal: nowLocal,
      scheduledAt: zones.resolve(today.atStartOfDay, viewerZone).utc,
    );
    return candidates.length;
  }
}

/// Local alias to avoid a name clash with [PlannerService.shouldAskActualTime].
bool shouldAskActualTimeSetting(AskActualTimeOnDone setting, {required DateTime plannedEnd, required DateTime now}) =>
    shouldAskActualTime(setting, plannedEnd: plannedEnd, now: now);

final plannerServiceProvider = Provider<PlannerService>(PlannerService.new);
