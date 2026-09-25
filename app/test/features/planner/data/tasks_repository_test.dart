import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/data/tasks_repository.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_validation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';

void main() {
  late TestHarness h;
  setUp(() => h = plannerHarness());
  tearDown(() => h.dispose());

  group('create (T3.1.05)', () {
    test('writes the row, one outbox entry per row and a created event', () async {
      final id = await h.createTask(title: '  Gym  ', start: '2026-09-22T07:00', duration: 60);
      final task = (await h.task(id))!;
      expect(task.title, 'Gym');
      expect(task.seriesId, id);
      expect(task.startLocal, ldt('2026-09-22T07:00'));
      final outbox = await h.db.select(h.db.syncOutbox).get();
      final byRow = <String, int>{};
      for (final o in outbox) {
        byRow['${o.tableName_}/${o.rowId}'] = (byRow['${o.tableName_}/${o.rowId}'] ?? 0) + 1;
      }
      expect(byRow.values.every((n) => n == 1), isTrue);
      expect(byRow.keys, contains('tasks/$id'));
      final created = (await h.events(type: 'created')).single;
      expect(created.entityType, 'task');
      expect(created.entityId, id);
      expect(created.payload['start'], '2026-09-22T07:00');
      expect(created.payload['cause'], 'user');
      expect(created.payload['opId'], isNotNull);
    });

    test('derives recurrence_until_local', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule(count: 3));
      expect((await h.task(id))!.recurrenceUntilLocal, ldt('2026-09-23T08:00'));
      final open = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      expect((await h.task(open))!.recurrenceUntilLocal, isNull);
    });

    test('rejects invalid tasks with typed errors', () async {
      await expectLater(
        h.createTask(title: ' ', start: '2026-09-22T07:00'),
        throwsA(isA<TaskValidationException>().having((e) => e.errors, 'errors', [TaskValidationError.titleEmpty])),
      );
      await expectLater(
        h.createTask(start: '2026-09-22T09:00', allDay: true, duration: 1440),
        throwsA(isA<TaskValidationException>()),
      );
      await expectLater(h.createTask(rule: RecurrenceRule()), throwsA(isA<TaskValidationException>()));
      await expectLater(
        h.createTask(start: '2026-09-22T09:00', zone: 'Mars/Olympus'),
        throwsA(isA<TaskValidationException>()),
      );
    });

    test('unscheduled tasks get a backlog order key', () async {
      final a = await h.createTask(title: 'A');
      final b = await h.createTask(title: 'B');
      final ka = (await h.task(a))!.manualSortKey!;
      final kb = (await h.task(b))!.manualSortKey!;
      expect(ka.compareTo(kb), lessThan(0));
    });
  });

  group('update (T3.1.05)', () {
    test('start/duration changes emit rescheduled; other changes emit updated with time fields', () async {
      final id = await h.createTask(title: 'Call', start: '2026-09-22T10:00', duration: 30);
      final task = (await h.task(id))!;
      await h.tasks.update(task.copyWith(startLocal: ldt('2026-09-22T11:00'), durationMinutes: 45, title: 'Call mom'));
      final res = (await h.events(type: 'rescheduled')).single;
      expect(res.payload['occurrenceKey'], '2026-09-22T10:00');
      expect(res.payload['fromStart'], '2026-09-22T10:00');
      expect(res.payload['toStart'], '2026-09-22T11:00');
      expect(res.payload['fromDuration'], 30);
      expect(res.payload['toDuration'], 45);
      expect(res.payload['zone'], 'UTC');
      expect(res.payload['source'], 'editor');
      final upd = (await h.events(type: 'updated')).single;
      expect(upd.payload['fields'], ['title']);
      expect((upd.payload['before']! as Map)['start'], '2026-09-22T10:00');
      expect((upd.payload['after']! as Map)['start'], '2026-09-22T11:00');
    });

    test('a one-off done record follows the task to its new start', () async {
      final id = await h.createTask(start: '2026-09-22T10:00');
      await h.occurrences.markDone(id, '2026-09-22T10:00');
      final task = (await h.task(id))!;
      await h.tasks.update(task.copyWith(startLocal: ldt('2026-09-23T10:00')));
      final recs = await h.records(id);
      expect(recs.single.occurrenceKey, '2026-09-23T10:00');
      expect(recs.single.status, OccurrenceStatus.done);
      expect(recs.single.id, Ids.taskOccurrence(id, '2026-09-23T10:00'));
    });

    test('no-op edits write nothing', () async {
      final id = await h.createTask(start: '2026-09-22T10:00');
      final result = await h.tasks.update((await h.task(id))!);
      expect(result.record.isEmpty, isTrue);
    });
  });

  group('soft delete cascade & restore (T3.1.05 / T3.1.10)', () {
    Future<String> attachment(String ownerType, String ownerId) async {
      final id = Ids.v7();
      await h.writer.run((tx) => tx.insert('attachments', id, {
        'owner_type': ownerType,
        'owner_id': ownerId,
        'storage_path': 'u/$id.jpg',
        'file_name': 'a.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 10,
        'sort_key': 'a0',
      }));
      return id;
    }

    test('delete cascades in one op; restore brings back exactly those rows', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule(), mode: TrackingMode.timer);
      await h.occurrences.markDone(id, '2026-09-21T08:00');
      await h.occurrences.addTimeEntry(id, '2026-09-21T08:00', start: DateTime.utc(2026, 9, 21, 8), end: DateTime.utc(2026, 9, 21, 8, 30));
      await h.occurrences.skip(id, '2026-09-20T08:00');
      final att = await attachment('task', id);
      final occAtt = await attachment('task_occurrence', Ids.taskOccurrence(id, '2026-09-21T08:00'));
      // A record deleted earlier must stay deleted after the restore.
      await h.writer.run((tx) => tx.softDelete('task_occurrences', Ids.taskOccurrence(id, '2026-09-20T08:00')));

      final record = await h.tasks.delete(id);
      expect({for (final c in record.changes) c.table}, containsAll(['tasks', 'task_occurrences', 'time_entries', 'attachments']));
      expect(await h.task(id), isNull);
      expect((await h.raw('attachments', att))!['deleted_at'], isNotNull);
      expect((await h.raw('attachments', occAtt))!['deleted_at'], isNotNull);

      await h.tasks.restoreTask(id);
      expect(await h.task(id), isNotNull);
      expect((await h.records(id)).map((r) => r.occurrenceKey), ['2026-09-21T08:00']);
      expect((await h.raw('attachments', att))!['deleted_at'], isNull);
      expect((await h.raw('attachments', occAtt))!['deleted_at'], isNull);
      final entries = await (h.db.select(h.db.timeEntries)..where((e) => e.deletedAt.isNull())).get();
      expect(entries, hasLength(1));
      expect((await h.raw('task_occurrences', Ids.taskOccurrence(id, '2026-09-20T08:00')))!['deleted_at'], isNotNull);
      expect(await h.events(type: 'restored'), hasLength(1));
    });

    test('restoreOperation restores the rows tombstoned by that op', () async {
      final id = await h.createTask(start: '2026-09-22T08:00');
      await h.occurrences.markDone(id, '2026-09-22T08:00');
      final op = await h.tasks.delete(id);
      await h.tasks.restoreOperation(op.opId);
      expect(await h.task(id), isNotNull);
      expect(await h.records(id), hasLength(1));
    });

    test('undo (revert) of a delete restores everything', () async {
      final id = await h.createTask(start: '2026-09-22T08:00');
      await h.occurrences.markDone(id, '2026-09-22T08:00');
      final op = await h.tasks.delete(id);
      await h.writer.revert(op);
      expect(await h.task(id), isNotNull);
      expect(await h.records(id), hasLength(1));
    });
  });

  group('duplicate & copy (T3.1.05 / T3.1.19)', () {
    test('duplicate never shares ids; fresh series; attachments point at the same objects', () async {
      final id = await h.createTask(title: 'Gym', start: '2026-09-21T07:00', rule: RecurrenceRule(freq: Frequency.weekly), zone: 'Europe/Paris');
      await h.writer.run((tx) => tx.insert('attachments', 'att1', {
        'owner_type': 'task',
        'owner_id': id,
        'storage_path': 'u/photo.jpg',
        'file_name': 'photo.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 10,
        'sort_key': 'a0',
      }));
      final dup = await h.tasks.duplicate(id);
      final copy = (await h.task(dup.newTaskId!))!;
      expect(copy.id, isNot(id));
      expect(copy.seriesId, copy.id);
      expect(copy.recurrence, isNotNull);
      expect(copy.timeZone, 'Europe/Paris');
      final atts = await (h.db.select(h.db.attachments)..where((a) => a.ownerId.equals(copy.id))).get();
      expect(atts.single.storagePath, 'u/photo.jpg');
      expect(atts.single.id, isNot('att1'));
      final oneOff = await h.tasks.duplicate(id, asOneOff: true, targetStartLocal: ldt('2026-10-01T07:00'));
      expect((await h.task(oneOff.newTaskId!))!.recurrence, isNull);
      expect((await h.task(oneOff.newTaskId!))!.startLocal, ldt('2026-10-01T07:00'));
    });

    test('duplicate to dates copies one-offs at the same time, zone mode preserved', () async {
      final id = await h.createTask(title: 'Standup', start: '2026-09-21T09:30', duration: 15, rule: RecurrenceRule(), zone: 'Europe/Paris');
      await h.tasks.editOccurrence(id, '2026-09-22T09:30', start: ldt('2026-09-22T10:00'));
      await h.tasks.duplicateToDates(id, [ld('2026-10-01'), ld('2026-10-03')], occurrenceKey: '2026-09-22T09:30');
      final copies = (await h.liveTasks()).where((t) => t.id != id).toList()..sort((a, b) => a.startLocal!.compareTo(b.startLocal!));
      expect(copies.map((t) => t.startLocal), [ldt('2026-10-01T10:00'), ldt('2026-10-03T10:00')]);
      expect(copies.every((t) => t.recurrence == null && t.timeZone == 'Europe/Paris' && t.durationMinutes == 15), isTrue);
      expect(copies.map((t) => t.id).toSet(), hasLength(2));
    });
  });

  group('backlog (T3.1.11)', () {
    test('schedule and unschedule keep other fields and log scheduled/unscheduled', () async {
      final id = await h.createTask(title: 'Read', priority: 3, estimate: 40, duration: null);
      expect((await h.task(id))!.isUnscheduled, isTrue);
      await h.tasks.schedule(id, ldt('2026-09-23T18:00'));
      final scheduled = (await h.task(id))!;
      expect(scheduled.startLocal, ldt('2026-09-23T18:00'));
      expect(scheduled.durationMinutes, 40);
      expect(scheduled.priority, 3);
      expect((await h.events(type: 'scheduled')).single.payload['source'], 'backlog');
      await h.tasks.unschedule(id);
      final back = (await h.task(id))!;
      expect(back.isUnscheduled, isTrue);
      expect(back.priority, 3);
      expect(await h.events(type: 'unscheduled'), hasLength(1));
    });

    test('recurring tasks cannot be unscheduled', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      await expectLater(h.tasks.unschedule(id), throwsA(anything));
    });

    test('backlog order via fractional keys', () async {
      final a = await h.createTask(title: 'A');
      final b = await h.createTask(title: 'B');
      final ka = (await h.task(a))!.manualSortKey;
      await h.tasks.moveInBacklog(b, beforeKey: ka);
      final ordered = await h.read(plannerQueriesProvider).unscheduled();
      expect(ordered.map((t) => t.title), ['B', 'A']);
    });
  });

  group('templates (T3.1.20)', () {
    test('saved without dates and excluded from ranges and backlog', () async {
      final id = await h.createTask(title: 'Workout', start: '2026-09-22T07:00', rule: RecurrenceRule(), mode: TrackingMode.timer);
      final tpl = await h.tasks.saveAsTemplate((await h.task(id))!);
      final template = (await h.task(tpl.taskId))!;
      expect(template.isTemplate, isTrue);
      expect(template.startLocal, isNull);
      expect(template.recurrence, isNull);
      expect(template.trackingMode, TrackingMode.timer);
      expect(await h.read(plannerQueriesProvider).unscheduled(), isEmpty);
      final items = await h.items(ld('2026-09-22'), 1);
      expect(items.map((i) => i.taskId), [id]);
      await h.tasks.deleteTemplate(tpl.taskId);
      expect(await h.task(tpl.taskId), isNull);
    });
  });

  group('bulk (T3.1.18)', () {
    test('one transaction, one undo', () async {
      final a = await h.createTask(title: 'A', start: '2026-09-22T10:00');
      final b = await h.createTask(title: 'B', start: '2026-09-21T08:00', rule: RecurrenceRule());
      final op = await h.tasks.bulk([
        BulkTarget(a),
        BulkTarget(b, occurrenceKey: '2026-09-22T08:00'),
      ], const BulkMove(days: 1));
      expect({for (final c in op.changes) c.table}, containsAll(['tasks', 'task_occurrences']));
      expect((await h.task(a))!.startLocal, ldt('2026-09-23T10:00'));
      expect((await h.records(b)).single.overrideStartLocal, ldt('2026-09-23T08:00'));
      final bulkEvents = await h.events(type: 'rescheduled');
      expect(bulkEvents.every((e) => e.payload['source'] == 'bulk' && e.payload['cause'] == 'bulk'), isTrue);
      await h.writer.revert(op);
      expect((await h.task(a))!.startLocal, ldt('2026-09-22T10:00'));
      expect(await h.records(b), isEmpty);
    });

    test('set priority / category / tracking and delete series or occurrence', () async {
      final a = await h.createTask(title: 'A', start: '2026-09-22T10:00');
      final b = await h.createTask(title: 'B', start: '2026-09-21T08:00', rule: RecurrenceRule());
      await h.tasks.bulk([BulkTarget(a), BulkTarget(b, series: true)], const BulkSetPriority(4));
      expect((await h.task(a))!.priority, 4);
      expect((await h.task(b))!.priority, 4);
      await h.tasks.bulk([BulkTarget(a)], const BulkSetTrackingMode(TrackingMode.event));
      expect((await h.task(a))!.trackingMode, TrackingMode.event);
      await h.tasks.bulk([BulkTarget(a), BulkTarget(b, occurrenceKey: '2026-09-22T08:00')], const BulkDelete());
      expect(await h.task(a), isNull);
      expect((await h.records(b)).single.isCancelled, isTrue);
    });
  });

  test('pause and resume log events', () async {
    final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule(), mode: TrackingMode.event);
    await h.tasks.pauseSeries(id);
    expect((await h.task(id))!.status, TaskStatus.paused);
    await h.tasks.resumeSeries(id);
    expect((await h.task(id))!.status, TaskStatus.active);
    expect((await h.events()).map((e) => e.eventType), containsAllInOrder(['paused', 'resumed']));
  });

  test('outbox keeps one coalesced entry per touched row and op', () async {
    final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
    final op = (await h.tasks.update((await h.task(id))!.copyWith(title: 'X', priority: 2))).record;
    final outbox = await (h.db.select(h.db.syncOutbox)
          ..where((o) => o.opId.equals(op.opId))
          ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
        .get();
    final rows = outbox.map((o) => '${o.tableName_}/${o.rowId}').toList();
    expect(rows.toSet().length, rows.length);
    final patch = jsonDecode(outbox.firstWhere((o) => o.tableName_ == 'tasks').fields) as Map<String, dynamic>;
    expect(patch.keys, containsAll(['title', 'priority']));
  });

  test('restore changes are recorded as an op', () async {
    final id = await h.createTask(start: '2026-09-22T08:00');
    await h.tasks.delete(id);
    final op = await h.tasks.restoreTask(id);
    expect(op, isA<OpRecord>());
    expect(op.changes, isNotEmpty);
  });
}
