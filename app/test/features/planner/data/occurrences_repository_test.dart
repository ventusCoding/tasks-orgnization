import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';

void main() {
  late TestHarness h;
  // Harness clock: 2026-09-22 09:00 UTC, device zone UTC.
  setUp(() => h = plannerHarness());
  tearDown(() => h.dispose());

  Future<Map<String, Object?>?> record(String taskId, String key) =>
      h.raw('task_occurrences', Ids.taskOccurrence(taskId, key));

  group('status actions (T3.2.04)', () {
    test('done uses the deterministic id, stamps times and logs completed; repeating is a no-op', () async {
      final id = await h.createTask(start: '2026-09-22T08:00', rule: RecurrenceRule());
      const key = '2026-09-22T08:00';
      final op = await h.occurrences.markDone(id, key);
      expect(op.isEmpty, isFalse);
      final rec = (await h.records(id)).single;
      expect(rec.id, Ids.taskOccurrence(id, key));
      expect(rec.status, OccurrenceStatus.done);
      expect(rec.completedAt, h.clock.nowUtc());
      expect(rec.statusChangedAt, h.clock.nowUtc());
      final event = (await h.events(type: 'completed')).single;
      expect(event.entityType, 'task_occurrence');
      expect(event.entityId, rec.id);
      expect(event.parentId, id);
      expect(event.payload['occurrenceKey'], key);
      expect(event.payload['from'], 'scheduled');
      expect((await h.occurrences.markDone(id, key)).isEmpty, isTrue, reason: 'idempotent');
      expect(await h.events(type: 'completed'), hasLength(1));
    });

    test('undo of done restores "no record" exactly', () async {
      final id = await h.createTask(start: '2026-09-22T08:00', rule: RecurrenceRule());
      const key = '2026-09-22T08:00';
      final op = await h.occurrences.markDone(id, key);
      await h.writer.revert(op);
      final raw = await record(id, key);
      expect(raw!['deleted_at'], isNotNull, reason: 'the inserted record is tombstoned');
      expect(await h.records(id), isEmpty);
    });

    test('undo restores the previous record state (skipped → done → undo = skipped with reason)', () async {
      final id = await h.createTask(start: '2026-09-22T08:00', rule: RecurrenceRule());
      const key = '2026-09-22T08:00';
      await h.occurrences.skip(id, key, reason: SkipReasons.sick);
      final done = await h.occurrences.markDone(id, key);
      await h.writer.revert(done);
      final rec = (await h.records(id)).single;
      expect(rec.status, OccurrenceStatus.skipped);
      expect(rec.skipReason, 'sick');
    });

    test('skip with a reason key or free text (≤ 200 chars); reopen clears it', () async {
      final id = await h.createTask(start: '2026-09-22T08:00', rule: RecurrenceRule());
      const key = '2026-09-22T08:00';
      await h.occurrences.skip(id, key, reason: 'x' * 250);
      expect((await h.records(id)).single.skipReason, hasLength(200));
      await h.occurrences.skip(id, key, reason: SkipReasons.tooBusy);
      final skipped = await h.events(type: 'skipped');
      expect(skipped.last.payload['reason'], 'too_busy');
      await h.occurrences.reopen(id, key);
      final rec = (await h.records(id)).single;
      expect(rec.status, OccurrenceStatus.scheduled);
      expect(rec.skipReason, isNull);
      expect((await h.events(type: 'reopened')).single.payload['from'], 'skipped');
    });

    test('one-off tasks use their start as the key', () async {
      final id = await h.createTask(start: '2026-09-22T10:00');
      await h.occurrences.markDone(id, '2026-09-22T10:00');
      final items = await h.items(ld('2026-09-22'), 1);
      expect(items.single.status, OccurrenceStatus.done);
    });

    test('completion %, rating and outcome note are clamped, logged and idempotent', () async {
      final id = await h.createTask(start: '2026-09-22T08:00', rule: RecurrenceRule());
      const key = '2026-09-22T08:00';
      await h.occurrences.setCompletionPercent(id, key, 140);
      await h.occurrences.rate(id, key, 0);
      await h.occurrences.setOutcomeNote(id, key, '  felt great  ');
      final rec = (await h.records(id)).single;
      expect(rec.completionPercent, 100);
      expect(rec.rating, 1);
      expect(rec.outcomeNote, 'felt great');
      expect((await h.occurrences.rate(id, key, 1)).isEmpty, isTrue);
      final updates = await h.events(type: 'updated');
      expect(
        [for (final e in updates) (e.payload['fields']! as List).single],
        ['completion_percent', 'rating', 'outcome_note'],
      );
    });

    test('cancel (delete scope "this") and restore to series (T2.1.19)', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      const key = '2026-09-23T08:00';
      await h.occurrences.cancel(id, key);
      expect(await h.items(ld('2026-09-23'), 1), isEmpty);
      await h.occurrences.restoreToSeries(id, key);
      expect((await record(id, key))!['deleted_at'], isNotNull, reason: 'a record without outcome is removed');
      expect((await h.items(ld('2026-09-23'), 1)).single.occurrenceKey, key);
      expect((await h.events(type: 'restored')).single.payload['wasCancelled'], isTrue);
    });

    test('restore to series keeps the outcome but clears overrides; restore all in one op', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      await h.tasks.editOccurrence(id, '2026-09-21T08:00', start: ldt('2026-09-21T10:00'));
      await h.occurrences.markDone(id, '2026-09-21T08:00');
      await h.occurrences.cancel(id, '2026-09-24T08:00');
      await h.tasks.editOccurrence(id, '2026-09-25T08:00', title: 'Special');
      final op = await h.occurrences.restoreAllExceptions(id);
      final recs = await h.records(id);
      expect(recs.single.occurrenceKey, '2026-09-21T08:00');
      expect(recs.single.status, OccurrenceStatus.done);
      expect(recs.single.hasOverride, isFalse);
      expect(await h.events(type: 'restored'), hasLength(3));
      await h.writer.revert(op);
      expect(await h.records(id), hasLength(3), reason: 'one undo brings every exception back');
    });
  });

  group('actual time capture (T3.2.14)', () {
    Future<PlannerItem> item(String id) async => (await h.items(ld('2026-09-22'), 1)).firstWhere((i) => i.taskId == id);

    test('as planned / just now / custom', () async {
      final id = await h.createTask(start: '2026-09-22T07:00', duration: 45);
      await h.planner.markDone(await item(id), actual: ActualTimeOption.asPlanned);
      var rec = (await h.records(id)).single;
      expect(rec.actualStartAt, DateTime.utc(2026, 9, 22, 7));
      expect(rec.actualEndAt, DateTime.utc(2026, 9, 22, 7, 45));

      final b = await h.createTask(title: 'B', start: '2026-09-22T06:00', duration: 30);
      await h.planner.markDone(await item(b), actual: ActualTimeOption.justNow);
      rec = (await h.records(b)).single;
      expect(rec.actualEndAt, DateTime.utc(2026, 9, 22, 9));
      expect(rec.actualStartAt, DateTime.utc(2026, 9, 22, 8, 30));

      final c = await h.createTask(title: 'C', start: '2026-09-22T05:00', duration: 30);
      await h.planner.markDone(
        await item(c),
        actual: ActualTimeOption.custom,
        customStart: DateTime.utc(2026, 9, 22, 5, 10),
        customEnd: DateTime.utc(2026, 9, 22, 5, 50),
      );
      rec = (await h.records(c)).single;
      expect(rec.actualStartAt, DateTime.utc(2026, 9, 22, 5, 10));
      await expectLater(
        h.planner.markDone(
          await item(c),
          actual: ActualTimeOption.custom,
          customStart: DateTime.utc(2026, 9, 22, 6),
          customEnd: DateTime.utc(2026, 9, 22, 5),
        ),
        throwsA(isA<ActualTimeException>()),
      );
    });

    test('the setting decides when to ask', () {
      final end = DateTime.utc(2026, 9, 22, 8);
      expect(
        shouldAskActualTime(AskActualTimeOnDone.never, plannedEnd: end, now: end.add(const Duration(hours: 3))),
        isFalse,
      );
      expect(shouldAskActualTime(AskActualTimeOnDone.always, plannedEnd: end, now: end), isTrue);
      expect(
        shouldAskActualTime(
          AskActualTimeOnDone.ifOffSchedule,
          plannedEnd: end,
          now: end.add(const Duration(minutes: 10)),
        ),
        isFalse,
      );
      expect(
        shouldAskActualTime(
          AskActualTimeOnDone.ifOffSchedule,
          plannedEnd: end,
          now: end.add(const Duration(minutes: 16)),
        ),
        isTrue,
      );
    });
  });

  group('time tracking (T3.2.17 / T3.2.19)', () {
    test('start → pause → resume → stop: sessions, tracked seconds, actual times', () async {
      final id = await h.createTask(start: '2026-09-22T09:00', duration: 60, mode: TrackingMode.timer);
      const key = '2026-09-22T09:00';
      await h.occurrences.start(id, key);
      expect((await h.records(id)).single.status, OccurrenceStatus.inProgress);
      h.clock.advance(const Duration(minutes: 10));
      await h.occurrences.pause(id, key);
      expect((await h.records(id)).single.trackedSeconds, 600);
      h.clock.advance(const Duration(minutes: 5));
      await h.occurrences.resume(id, key);
      h.clock.advance(const Duration(minutes: 20));
      await h.occurrences.stop(id, key);
      final rec = (await h.records(id)).single;
      expect(rec.status, OccurrenceStatus.done);
      expect(rec.trackedSeconds, 1800);
      expect(rec.actualStartAt, DateTime.utc(2026, 9, 22, 9));
      expect(rec.actualEndAt, DateTime.utc(2026, 9, 22, 9, 35));
      final entries = await h.read(plannerQueriesProvider).watchTimeEntries(id, key).first;
      expect(entries, hasLength(2));
      expect(entries.every((e) => !e.isRunning), isTrue);
    });

    test('single timer policy pauses the other running timer; multiple keeps both', () async {
      final a = await h.createTask(title: 'A', start: '2026-09-22T09:00', mode: TrackingMode.timer);
      final b = await h.createTask(title: 'B', start: '2026-09-22T09:00', mode: TrackingMode.timer);
      await h.occurrences.start(a, '2026-09-22T09:00');
      h.clock.advance(const Duration(minutes: 1));
      await h.occurrences.start(b, '2026-09-22T09:00');
      var running = await h.read(plannerQueriesProvider).watchRunningEntries().first;
      expect(running.single.taskId, b);
      expect((await h.records(a)).single.trackedSeconds, 60);
      await h.occurrences.start(a, '2026-09-22T09:00', policy: TimerPolicy.multiple);
      running = await h.read(plannerQueriesProvider).watchRunningEntries().first;
      expect(running.map((e) => e.taskId).toSet(), {a, b});
    });

    test('a running entry is a persisted row (survives restart) and starting twice is a no-op', () async {
      final id = await h.createTask(start: '2026-09-22T09:00', mode: TrackingMode.timer);
      await h.occurrences.start(id, '2026-09-22T09:00');
      expect((await h.occurrences.start(id, '2026-09-22T09:00')).isEmpty, isTrue);
      final rows = await h.db.select(h.db.timeEntries).get();
      expect(rows.single.endedAt, isNull);
    });

    test('check tasks start without a timer', () async {
      final id = await h.createTask(start: '2026-09-22T09:00');
      await h.occurrences.start(id, '2026-09-22T09:00');
      expect(await h.db.select(h.db.timeEntries).get(), isEmpty);
      expect((await h.records(id)).single.status, OccurrenceStatus.inProgress);
    });
  });

  group('manual time entries (T3.2.18)', () {
    test('add, edit and delete keep tracked seconds; invalid entries are rejected', () async {
      final id = await h.createTask(start: '2026-09-22T07:00', mode: TrackingMode.timer);
      const key = '2026-09-22T07:00';
      await h.occurrences.addTimeEntry(
        id,
        key,
        start: DateTime.utc(2026, 9, 22, 7),
        end: DateTime.utc(2026, 9, 22, 7, 30),
      );
      expect((await h.records(id)).single.trackedSeconds, 1800);
      final entry = (await h.read(plannerQueriesProvider).watchTimeEntries(id, key).first).single;
      await h.occurrences.updateTimeEntry(
        entry.id,
        start: DateTime.utc(2026, 9, 22, 7),
        end: DateTime.utc(2026, 9, 22, 8),
      );
      expect((await h.records(id)).single.trackedSeconds, 3600);
      await expectLater(
        h.occurrences.addTimeEntry(id, key, start: DateTime.utc(2026, 9, 22, 8), end: DateTime.utc(2026, 9, 22, 7)),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        h.occurrences.addTimeEntry(id, key, start: DateTime.utc(2026, 9, 23, 8)),
        throwsA(isA<ValidationException>()),
      );
      await h.occurrences.deleteTimeEntry(entry.id);
      expect((await h.records(id)).single.trackedSeconds, 0);
    });

    test('overlap detection helper flags overlapping sessions', () {
      final now = DateTime.utc(2026, 9, 22, 9);
      final entries = [
        TimeEntry(
          id: 'a',
          taskId: 't',
          occurrenceKey: 'k',
          startedAt: DateTime.utc(2026, 9, 22, 7),
          endedAt: DateTime.utc(2026, 9, 22, 8),
        ),
        TimeEntry(id: 'r', taskId: 't', occurrenceKey: 'k', startedAt: DateTime.utc(2026, 9, 22, 8, 50)),
      ];
      List<String> ids(DateTime s, DateTime e, {String? exclude}) => [
        for (final x in overlappingEntries(s, e, entries, now: now, excludeId: exclude)) x.id,
      ];
      expect(ids(DateTime.utc(2026, 9, 22, 7, 30), DateTime.utc(2026, 9, 22, 8, 10)), ['a']);
      expect(ids(DateTime.utc(2026, 9, 22, 8), DateTime.utc(2026, 9, 22, 8, 30)), isEmpty);
      expect(ids(DateTime.utc(2026, 9, 22, 8, 55), DateTime.utc(2026, 9, 22, 10)), ['r'], reason: 'running until now');
      expect(ids(DateTime.utc(2026, 9, 22, 7, 30), DateTime.utc(2026, 9, 22, 7, 40), exclude: 'a'), isEmpty);
    });
  });

  test('actions invalidate the range stream (sheet ↔ views)', () async {
    final id = await h.createTask(start: '2026-09-22T08:00', rule: RecurrenceRule());
    final service = h.read(occurrenceRangeServiceProvider);
    final stream = service.watch(DayRange(ld('2026-09-22'), 1));
    final statuses = <OccurrenceStatus>[];
    final sub = stream.listen((r) => statuses.add(r.items.single.status));
    await pumpEventQueue();
    await h.occurrences.markDone(id, '2026-09-22T08:00');
    await pumpEventQueue(times: 50);
    await sub.cancel();
    expect(statuses.first, isNot(OccurrenceStatus.done));
    expect(statuses.last, OccurrenceStatus.done);
  });
}
