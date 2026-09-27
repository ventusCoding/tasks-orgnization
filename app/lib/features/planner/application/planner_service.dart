import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart'
    show NotificationRulesDraft, notificationHostApiProvider;
import 'package:everslot/features/notifications/domain/notification_types.dart' show NotificationTargetType;
import 'package:everslot/features/organization/application/providers.dart' show tagsRepositoryProvider;
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
/// (actual-time capture, timer policy) and registers every write on the undo stack — except
/// when [registerUndo] is false (the planner contract: views register their own undo entry).
class PlannerService {
  PlannerService(this._ref, {this.registerUndo = true});

  final Ref _ref;
  final bool registerUndo;

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
    if (registerUndo) _ref.read(undoStackProvider).push(label, record);
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

  /// Creates [draft]; the editor's pending [reminders] and [tagIds] are saved in the same
  /// operation (one undo, one atomic push — T7.1.09, T3.1.17).
  Future<TaskWriteResult> createTask(
    Task draft, {
    String source = 'editor',
    NotificationRulesDraft? reminders,
    Set<String> tagIds = const {},
  }) async {
    final pending = reminders == null || reminders.isEmpty ? null : reminders;
    final host = pending == null ? null : _ref.read(notificationHostApiProvider);
    final tags = tagIds.isEmpty ? null : _ref.read(tagsRepositoryProvider);
    final result = await tasks.create(
      draft,
      source: source,
      inTx: host == null && tags == null
          ? null
          : (tx, task) async {
              if (host != null) {
                await host.saveDraftInTx(tx, pending!, type: NotificationTargetType.task, targetId: task.id);
              }
              if (tags != null) await tags.writeTags(tx, 'task', task.id, tagIds);
            },
    );
    _undo(l10n.tasksCreated, result.record);
    return result;
  }

  /// Removes what an abandoned *new-task* editor attached to the pre-generated [taskId]
  /// (attachments added before saving). No-op for saved tasks.
  Future<void> discardDraft(String taskId) => tasks.discardDraft(taskId);

  /// [discardDraft] bound to the current repository, for `State.dispose`: it never touches the
  /// provider scope again (which may already be gone) and ignores a closed database.
  Future<void> Function(String taskId) draftDiscarder() {
    final repository = tasks;
    return (taskId) async {
      try {
        await repository.discardDraft(taskId);
      } on Object {
        // The session ended with the editor still open: nothing left to clean up.
      }
    };
  }

  /// Saves an edited task with the chosen scope (T3.2.06–T3.2.09).
  Future<TaskWriteResult> updateTask(
    Task edited, {
    EditScope scope = EditScope.allOccurrences,
    String? occurrenceKey,
    bool rewritePast = false,
    OrphanPolicy orphanPolicy = OrphanPolicy.keepAsOneOff,
    String source = 'editor',
  }) async {
    final result = await tasks.update(
      edited,
      scope: scope,
      occurrenceKey: occurrenceKey,
      rewritePast: rewritePast,
      orphanPolicy: orphanPolicy,
      source: source,
    );
    _undo(l10n.tasksSaved, result.record);
    return result;
  }

  /// Orphans an edit would leave (confirmation dialog, T3.2.09).
  Future<OrphanReport> previewOrphans(
    Task edited, {
    EditScope scope = EditScope.allOccurrences,
    String? occurrenceKey,
    bool rewritePast = false,
  }) => tasks.previewOrphans(edited, scope: scope, occurrenceKey: occurrenceKey, rewritePast: rewritePast);

  // ---------------------------------------------------------------------------
  // Series operations (T3.1.19, T3.1.20, T3.2.21, T2.1.19)

  Future<TaskWriteResult> duplicate(String taskId, {bool asOneOff = false, String? occurrenceKey}) async {
    final result = await tasks.duplicate(taskId, asOneOff: asOneOff, occurrenceKey: occurrenceKey);
    _undo(l10n.tasksDuplicated, result.record);
    return result;
  }

  Future<OpRecord> duplicateToDates(String taskId, List<LocalDate> dates, {String? occurrenceKey}) async =>
      _undo(l10n.tasksDuplicatedTo(dates.length), await tasks.duplicateToDates(taskId, dates, occurrenceKey: occurrenceKey));

  Future<TaskWriteResult> saveAsTemplate(Task task) async {
    final result = await tasks.saveAsTemplate(task);
    _undo(l10n.tasksTemplateSaved, result.record);
    return result;
  }

  Future<OpRecord> deleteTemplate(String id) async => _undo(l10n.tasksDeleted, await tasks.deleteTemplate(id));

  /// A new-task draft from [template] (fresh ids, not a template) at [start] (null = backlog).
  Task draftFromTemplate(Task template, {LocalDateTime? start, bool allDay = false}) => template.copyWith(
    id: '',
    seriesId: '',
    isTemplate: false,
    startLocal: start == null ? null : (allDay || template.isAllDay ? start.date.atStartOfDay : start),
    isAllDay: start != null && (allDay || template.isAllDay),
    durationMinutes: template.isAllDay || allDay ? 1440 : template.durationMinutes,
    status: TaskStatus.active,
    manualSortKey: null,
  );

  Future<OpRecord> pauseSeries(String taskId) async => _undo(l10n.tasksPauseSnack, await tasks.pauseSeries(taskId));

  Future<OpRecord> resumeSeries(String taskId) async => _undo(l10n.tasksResumeSnack, await tasks.resumeSeries(taskId));

  Future<OpRecord> unschedule(String taskId) async => _undo(l10n.tasksMoved, await tasks.unschedule(taskId));

  Future<OpRecord> restoreTask(String taskId) async => _undo(l10n.tasksRestored, await tasks.restoreTask(taskId));

  /// *Restore to series* for one exception (T2.1.19).
  Future<OpRecord> restoreToSeries(String taskId, String key) async =>
      _undo(l10n.recurExceptionsRestored, await occurrences.restoreToSeries(taskId, key));

  /// Restores every exception of the series in ONE operation (one undo): cancelled, moved and
  /// edited occurrences, and — unless [includeExcluded] is false — the rule's excluded dates.
  Future<OpRecord> restoreAllExceptions(String taskId, {bool includeExcluded = true}) async {
    final task = await queries.task(taskId);
    final rule = task?.recurrence;
    if (task == null || rule == null || !includeExcluded || rule.exdates.isEmpty) {
      return _undo(l10n.recurExceptionsRestored, await occurrences.restoreAllExceptions(taskId));
    }
    final result = await tasks.update(
      task.copyWith(recurrence: rule.copyWith(exdates: const [])),
      rewritePast: true,
      source: 'exceptions',
      inTx: (tx) => occurrences.restoreAllExceptionsInTx(tx, taskId),
    );
    return _undo(l10n.recurExceptionsRestored, result.record);
  }

  /// Removes [key] from the rule's `exdates` (the occurrence comes back; no key disappears, so
  /// the master is edited directly).
  Future<OpRecord?> removeExdate(String taskId, String key) async {
    final task = await queries.task(taskId);
    final rule = task?.recurrence;
    if (task == null || rule == null || !rule.exdates.contains(key)) return null;
    final result = await tasks.update(
      task.copyWith(recurrence: rule.copyWith(exdates: [...rule.exdates.where((e) => e != key)])),
      rewritePast: true,
      source: 'exceptions',
    );
    return _undo(l10n.recurExceptionsRestored, result.record);
  }

  /// Links (or unlinks with null) a checklist (T3.1.16).
  Future<OpRecord?> linkChecklist(String taskId, String? checklistId) async {
    final task = await queries.task(taskId);
    if (task == null || task.linkedChecklistId == checklistId) return null;
    final result = await tasks.update(task.copyWith(linkedChecklistId: checklistId), source: 'checklist');
    return _undo(l10n.tasksUpdated, result.record);
  }

  /// Bulk edit (T3.1.18): one transaction, one undo.
  Future<OpRecord> bulk(List<BulkTarget> targets, BulkChange change) async =>
      _undo(l10n.tasksBulkDone(targets.length), await tasks.bulk(targets, change));

  // ---------------------------------------------------------------------------
  // Occurrence outcome (T3.2.04, T3.2.22) and sessions (T3.2.18)

  Future<OpRecord> skip(PlannerItem item, {String? reason}) =>
      setStatus(item, OccurrenceStatus.skipped, skipReason: reason);

  Future<OpRecord> reopen(PlannerItem item) => setStatus(item, OccurrenceStatus.scheduled);

  Future<OpRecord> setCompletionPercent(PlannerItem item, int? percent) async =>
      _undo(l10n.tasksUpdated, await occurrences.setCompletionPercent(item.taskId, item.occurrenceKey, percent));

  Future<OpRecord> rate(PlannerItem item, int? rating) async =>
      _undo(l10n.tasksUpdated, await occurrences.rate(item.taskId, item.occurrenceKey, rating));

  Future<OpRecord> setOutcomeNote(PlannerItem item, String? note) async =>
      _undo(l10n.tasksUpdated, await occurrences.setOutcomeNote(item.taskId, item.occurrenceKey, note));

  Future<OpRecord> setActualTimes(PlannerItem item, {required DateTime start, required DateTime end}) async =>
      _undo(l10n.tasksUpdated, await occurrences.setActualTimes(item.taskId, item.occurrenceKey, start: start, end: end));

  Future<OpRecord> resumeTimer(PlannerItem item) =>
      occurrences.resume(item.taskId, item.occurrenceKey, policy: settings.timerPolicy);

  Future<OpRecord> addTimeEntry(PlannerItem item, {required DateTime start, DateTime? end, String? note}) async =>
      _undo(l10n.tasksEvtTimeEntry, await occurrences.addTimeEntry(item.taskId, item.occurrenceKey, start: start, end: end, note: note));

  Future<OpRecord> updateTimeEntry(String entryId, {required DateTime start, DateTime? end, String? note}) async =>
      _undo(l10n.tasksUpdated, await occurrences.updateTimeEntry(entryId, start: start, end: end, note: note));

  Future<OpRecord> deleteTimeEntry(String entryId) async =>
      _undo(l10n.tasksUpdated, await occurrences.deleteTimeEntry(entryId));

  // ---------------------------------------------------------------------------
  // Overlap warning (T3.1.14)

  /// Open `check`/`timer` occurrences (plus `event` ones when the setting says so) overlapping
  /// `[start, start + duration)` in the viewer's wall clock, excluding the edited task/occurrence.
  Future<List<PlannerItem>> overlapsFor({
    required LocalDateTime start,
    required int durationMinutes,
    String? excludeTaskId,
    String? excludeKey,
  }) async {
    if (!settings.overlapHint || durationMinutes <= 0) return const [];
    final end = start.plusMinutes(durationMinutes);
    final range = await ranges.resolveRange(start.date.atStartOfDay, end.date.plusDays(1).atStartOfDay);
    final startUtc = zones.resolve(start, viewerZone).utc;
    final endUtc = zones.resolve(end, viewerZone).utc;
    return findOverlaps(
      startUtc: startUtc,
      endUtc: endUtc,
      items: range.items,
      excludeTaskId: excludeTaskId,
      excludeKey: excludeKey,
      includeEvents: settings.overlapIncludesEvents,
    );
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

  Future<OpRecord> delete(PlannerItem item, {EditScope scope = EditScope.allOccurrences}) =>
      deleteTask(item.taskId, scope: scope, occurrenceKey: item.occurrenceKey);

  /// Deletes a task (or one/following occurrences of a series) with undo.
  Future<OpRecord> deleteTask(String taskId, {EditScope scope = EditScope.allOccurrences, String? occurrenceKey}) async {
    final record = await tasks.delete(taskId, scope: scope, occurrenceKey: occurrenceKey);
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
