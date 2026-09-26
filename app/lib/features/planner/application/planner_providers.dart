import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/planner/application/occurrence_range_service.dart';
import 'package:everslot/features/planner/application/planner_settings.dart';
import 'package:everslot/features/planner/data/occurrences_repository.dart';
import 'package:everslot/features/planner/data/planner_queries.dart';
import 'package:everslot/features/planner/data/tasks_repository.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

// Planner application providers (manual Riverpod 3 providers, dev_patterns §3).

final plannerQueriesProvider = Provider<PlannerQueries>(
  (ref) => PlannerQueries(ref.watch(appDatabaseProvider), () => ref.read(currentUserIdProvider)),
);

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepository(
    ref.watch(syncWriterProvider),
    ref.watch(plannerQueriesProvider),
    () => ref.read(recurrenceServiceProvider),
  ),
);

final occurrencesRepositoryProvider = Provider<OccurrencesRepository>(
  (ref) => OccurrencesRepository(ref.watch(syncWriterProvider)),
);

/// Typed `planner` settings (live).
final plannerSettingsProvider = Provider<PlannerSettings>((ref) {
  final map = ref.watch(settingsProvider(SettingsNs.planner)).value;
  return map == null ? PlannerSettings.defaults : PlannerSettings.fromMap(map);
});

final occurrenceResolverProvider = Provider<OccurrenceResolver>(
  (ref) => OccurrenceResolver(ref.watch(recurrenceServiceProvider).engine),
);

/// Whether range watchers schedule a timer for the next status boundary. Off with a
/// [FakeClock] (tests drive time explicitly).
final plannerAutoRefreshProvider = Provider<bool>((ref) => ref.watch(clockProvider) is! FakeClock);

/// The range service for the current user, zone and settings (T3.2.02). Rebuilt when the
/// device zone changes, so floating tasks re-resolve in the new zone.
final occurrenceRangeServiceProvider = Provider<OccurrenceRangeService>((ref) {
  ref.watch(currentUserIdProvider);
  final service = OccurrenceRangeService(
    queries: ref.watch(plannerQueriesProvider),
    resolver: ref.watch(occurrenceResolverProvider),
    clock: ref.watch(clockProvider),
    viewerZone: ref.watch(deviceZoneProvider),
    settings: ref.watch(plannerSettingsProvider),
    autoRefresh: ref.watch(plannerAutoRefreshProvider),
  );
  final sub = ref.watch(lifecycleProvider).onResume.listen((_) => service.refresh());
  ref.onDispose(() {
    unawaited(sub.cancel());
    service.dispose();
  });
  return service;
});

/// Resolved range with the truncation flag (views show "zoom in" when truncated).
final plannerRangeProvider = StreamProvider.autoDispose.family<ResolvedRange, DayRange>(
  (ref, range) => ref.watch(occurrenceRangeServiceProvider).watch(range),
);

/// Whether the range hit the occurrence cap.
final plannerRangeTruncatedProvider = Provider.autoDispose.family<bool, DayRange>(
  (ref, range) => ref.watch(plannerRangeProvider(range)).value?.truncated ?? false,
);

final taskByIdProvider = StreamProvider.autoDispose.family<Task?, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(plannerQueriesProvider).watchTask(id);
});

final seriesTasksProvider = StreamProvider.autoDispose.family<List<Task>, String>(
  (ref, seriesId) => ref.watch(plannerQueriesProvider).watchSeries(seriesId),
);

final taskRecordsProvider = StreamProvider.autoDispose.family<List<TaskOccurrenceRecord>, String>(
  (ref, taskId) => ref.watch(plannerQueriesProvider).watchRecords([taskId]),
);

/// `(taskId, occurrenceKey)`.
typedef OccurrenceRef = ({String taskId, String key});

final occurrenceRecordProvider = StreamProvider.autoDispose.family<TaskOccurrenceRecord?, OccurrenceRef>(
  (ref, o) => ref.watch(plannerQueriesProvider).watchRecord(o.taskId, o.key),
);

final timeEntriesProvider = StreamProvider.autoDispose.family<List<TimeEntry>, OccurrenceRef>(
  (ref, o) => ref.watch(plannerQueriesProvider).watchTimeEntries(o.taskId, o.key),
);

final templatesProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(plannerQueriesProvider).watchTemplates(),
);

final backlogTasksProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(plannerQueriesProvider).watchUnscheduled(),
);

final linkedChecklistsProvider = StreamProvider.autoDispose<List<LinkedChecklistInfo>>(
  (ref) => ref.watch(plannerQueriesProvider).watchChecklists(),
);

final linkedChecklistProvider = StreamProvider.autoDispose.family<LinkedChecklistInfo?, String>(
  (ref, id) => ref.watch(plannerQueriesProvider).watchChecklist(id),
);

/// Activity history query: the tasks of a series (or one task) and a page size.
@immutable
class HistoryQuery {
  const HistoryQuery(this.taskIds, {this.limit = 50});

  final List<String> taskIds;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery && other.limit == limit && other.taskIds.join(',') == taskIds.join(',');

  @override
  int get hashCode => Object.hash(taskIds.join(','), limit);
}

final taskHistoryProvider = StreamProvider.autoDispose.family<List<ActivityEvent>, HistoryQuery>(
  (ref, q) => ref.watch(plannerQueriesProvider).watchHistory(q.taskIds, limit: q.limit),
);

/// A running timer with its task (T3.2.19).
@immutable
class RunningTimer {
  const RunningTimer(this.entry, this.task);

  final TimeEntry entry;
  final Task? task;

  String get title => task?.title ?? '';
}

final runningTimersProvider = StreamProvider.autoDispose<List<RunningTimer>>((ref) {
  final queries = ref.watch(plannerQueriesProvider);
  return queries.watchRunningEntries().asyncMap(
    (entries) async => [for (final e in entries) RunningTimer(e, await queries.task(e.taskId))],
  );
});

/// Occurrences of the tasks of one series in a wall-clock range (series history, next
/// occurrences). Re-resolves on data changes.
@immutable
class SeriesRangeQuery {
  const SeriesRangeQuery(this.taskIds, this.from, this.to);

  final List<String> taskIds;
  final LocalDateTime from;
  final LocalDateTime to;

  @override
  bool operator ==(Object other) =>
      other is SeriesRangeQuery && other.from == from && other.to == to && other.taskIds.join(',') == taskIds.join(',');

  @override
  int get hashCode => Object.hash(taskIds.join(','), from, to);
}

final seriesOccurrencesProvider = StreamProvider.autoDispose.family<List<ResolvedOccurrence>, SeriesRangeQuery>((ref, q) {
  final queries = ref.watch(plannerQueriesProvider);
  final resolver = ref.watch(occurrenceResolverProvider);
  final zone = ref.watch(deviceZoneProvider);
  final settings = ref.watch(plannerSettingsProvider).resolver;
  final clock = ref.watch(clockProvider);
  Future<List<ResolvedOccurrence>> load() async {
    final tasks = <Task>[];
    for (final id in q.taskIds) {
      final t = await queries.task(id);
      if (t != null) tasks.add(t);
    }
    final records = await queries.records(q.taskIds);
    return resolver
        .resolve(
          tasks: tasks,
          records: records,
          from: q.from,
          to: q.to,
          viewerZone: zone,
          now: clock.nowUtc(),
          settings: ResolverSettings(
            missedGraceMinutes: settings.missedGraceMinutes,
            overdueLookbackDays: settings.overdueLookbackDays,
            showCancelled: true,
            skipAdvancesAfterCompletion: settings.skipAdvancesAfterCompletion,
            maxOccurrences: 5000,
          ),
        )
        .occurrences;
  }

  final controller = StreamController<List<ResolvedOccurrence>>();
  Future<void> push() async {
    try {
      final result = await load();
      if (!controller.isClosed) controller.add(result);
    } on Object catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  final sub = queries.changes().listen((_) => unawaited(push()));
  unawaited(push());
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
});

/// One resolved occurrence of a task (occurrence sheet / details), live.
final occurrenceItemProvider = StreamProvider.autoDispose.family<PlannerItem?, OccurrenceRef>((ref, o) {
  final queries = ref.watch(plannerQueriesProvider);
  final resolver = ref.watch(occurrenceResolverProvider);
  final zone = ref.watch(deviceZoneProvider);
  final settings = ref.watch(plannerSettingsProvider).resolver;
  final clock = ref.watch(clockProvider);
  Future<PlannerItem?> load() async {
    final task = await queries.task(o.taskId);
    if (task == null) return null;
    final records = await queries.records([o.taskId]);
    final record = records.where((r) => r.occurrenceKey == o.key).firstOrNull;
    final center = record?.overrideStartLocal ??
        LocalDateTime.tryParse(o.key) ??
        LocalDate.tryParse(o.key)?.atStartOfDay ??
        _periodStart(o.key) ??
        task.startLocal;
    if (center == null) return null;
    final span = 2 + task.effectiveDurationMinutes ~/ 1440;
    final result = resolver.resolve(
      tasks: [task],
      records: records,
      from: center.date.minusDays(span + 1).atStartOfDay,
      to: center.date.plusDays(span + 8).atStartOfDay,
      viewerZone: zone,
      now: clock.nowUtc(),
      settings: ResolverSettings(
        missedGraceMinutes: settings.missedGraceMinutes,
        overdueLookbackDays: settings.overdueLookbackDays,
        showCancelled: true,
        skipAdvancesAfterCompletion: settings.skipAdvancesAfterCompletion,
      ),
    );
    final match = result.occurrences.where((r) => r.occurrenceKey == o.key).firstOrNull;
    return match?.toPlannerItem(categoryColor: (await queries.categoryColors())[task.categoryId]);
  }

  final controller = StreamController<PlannerItem?>();
  Future<void> push() async {
    try {
      final item = await load();
      if (!controller.isClosed) controller.add(item);
    } on Object catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  final sub = queries.changes().listen((_) => unawaited(push()));
  unawaited(push());
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
});

LocalDateTime? _periodStart(String key) {
  final hash = key.lastIndexOf('#');
  if (hash < 0) return null;
  return QuotaPeriodKey.parse(key.substring(0, hash))?.startDate.atStartOfDay;
}

/// Next occurrences (with statuses) of a task, from now (details view: next 5).
final nextOccurrencesProvider = StreamProvider.autoDispose.family<List<PlannerItem>, String>((ref, taskId) {
  final task = ref.watch(taskByIdProvider(taskId)).value;
  if (task == null || task.isUnscheduled) return Stream.value(const []);
  final service = ref.watch(recurrenceServiceProvider);
  final rule = task.recurrence;
  final today = service.nowLocal.date;
  var horizon = today.plusDays(1);
  if (rule != null) {
    try {
      final next = service.nextOccurrences(rule, task.anchor!, count: 5);
      if (next.isNotEmpty) horizon = LocalDate.max(horizon, next.last.startLocal.date.plusDays(2));
    } on Object {
      // invalid rule: nothing upcoming
    }
  } else {
    horizon = LocalDate.max(horizon, task.startLocal!.date.plusDays(2));
  }
  final from = LocalDate.min(today, task.startLocal!.date).atStartOfDay;
  final now = service.nowUtc;
  return ref
      .watch(occurrenceRangeServiceProvider)
      .watchLocal(from, horizon.atStartOfDay)
      .map((r) => r.items.where((i) => i.taskId == taskId && !i.endUtc.isBefore(now)).take(5).toList());
});

/// Overdue one-off check/timer items (T3.2.12): missed within the look-back.
final overdueItemsProvider = StreamProvider.autoDispose<List<PlannerItem>>((ref) {
  final settings = ref.watch(plannerSettingsProvider);
  final today = ref.watch(recurrenceServiceProvider).today;
  final range = DayRange(today.minusDays(settings.overdueLookbackDays), settings.overdueLookbackDays + 1);
  return ref.watch(occurrenceRangeServiceProvider).watch(range).map((r) => r.items.where((i) => i.overdue).toList());
});
