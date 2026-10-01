import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Variable;
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/data/occurrences_repository.dart';
import 'package:everslot/features/planner/data/tasks_repository.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Planner test helpers on top of [TestHarness].
extension PlannerHarness on TestHarness {
  TasksRepository get tasks => read(tasksRepositoryProvider);
  OccurrencesRepository get occurrences => read(occurrencesRepositoryProvider);
  PlannerService get planner => read(plannerServiceProvider);
  SyncWriter get writer => read(syncWriterProvider);

  Future<Task?> task(String id, {bool includeDeleted = false}) =>
      read(plannerQueriesProvider).task(id, includeDeleted: includeDeleted);

  Future<List<Task>> liveTasks() async => [
    for (final r in await (db.select(db.tasks)..where((t) => t.deletedAt.isNull())).get()) (await task(r.id))!,
  ];

  Future<List<TaskOccurrenceRecord>> records(String taskId) => read(plannerQueriesProvider).records([taskId]);

  Future<Map<String, Object?>?> raw(String table, String id) async {
    final row = await db
        .customSelect('SELECT * FROM $table WHERE id = ?', variables: [Variable<String>(id)])
        .getSingleOrNull();
    return row?.data;
  }

  /// Activity events, oldest first.
  Future<List<ActivityEvent>> events({String? type}) async {
    final rows =
        await (db.select(db.activityEvents)
              ..where((e) => e.deletedAt.isNull())
              ..orderBy([(e) => OrderingTerm.asc(e.occurredAt), (e) => OrderingTerm.asc(e.id)]))
            .get();
    return [
      for (final r in rows)
        if (type == null || r.eventType == type)
          ActivityEvent(
            id: r.id,
            entityType: r.entityType,
            entityId: r.entityId,
            parentId: r.parentId,
            eventType: r.eventType,
            payload: Map<String, Object?>.from(jsonDecode(r.payload) as Map),
            occurredAt: r.occurredAt,
          ),
    ];
  }

  /// Resolved items of a day range in the device zone.
  Future<List<PlannerItem>> items(LocalDate start, int days) async => (await read(
    occurrenceRangeServiceProvider,
  ).resolveRange(start.atStartOfDay, start.plusDays(days).atStartOfDay)).items;

  /// Creates a task and returns its id.
  Future<String> createTask({
    String title = 'Task',
    String? start,
    int? duration = 60,
    RecurrenceRule? rule,
    String? zone,
    bool allDay = false,
    TrackingMode mode = TrackingMode.check,
    int priority = 0,
    String? categoryId,
    int? estimate,
  }) async {
    final result = await tasks.create(
      Task(
        id: '',
        seriesId: '',
        title: title,
        startLocal: start == null ? null : LocalDateTime.parse(start),
        durationMinutes: duration,
        recurrence: rule,
        timeZone: zone,
        isAllDay: allDay,
        trackingMode: mode,
        priority: priority,
        categoryId: categoryId,
        estimateMinutes: estimate,
      ),
    );
    return result.taskId;
  }
}

LocalDateTime ldt(String s) => LocalDateTime.parse(s);
LocalDate ld(String s) => LocalDate.parse(s);

/// Creates the standard harness for planner tests (binding + tz + in-memory DB).
TestHarness plannerHarness({DateTime? now, String zone = 'UTC'}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  return TestHarness.create(now: now ?? DateTime.utc(2026, 9, 22, 9), zone: zone);
}
