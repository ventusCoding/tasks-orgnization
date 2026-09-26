import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';

void main() {
  late TestHarness h;
  // Harness clock: Tue 2026-09-22 09:00 UTC, device zone UTC.
  setUp(() => h = plannerHarness());
  tearDown(() => h.dispose());

  Future<List<PlannerItem>> day(String date) => h.items(ld(date), 1);
  Future<PlannerItem> itemOn(String date, String taskId) async => (await day(date)).firstWhere((i) => i.taskId == taskId);

  group('this occurrence (T3.2.06)', () {
    test('dragging one occurrence of a daily series moves only that day; restore moves it back', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      await h.planner.reschedule(await itemOn('2026-09-24', id), newStart: ldt('2026-09-24T10:00'));
      expect((await itemOn('2026-09-24', id)).startLocal, ldt('2026-09-24T10:00'));
      expect((await itemOn('2026-09-24', id)).isMoved, isTrue);
      expect((await itemOn('2026-09-25', id)).startLocal, ldt('2026-09-25T08:00'));
      await h.occurrences.restoreToSeries(id, '2026-09-24T08:00');
      expect((await itemOn('2026-09-24', id)).startLocal, ldt('2026-09-24T08:00'));
    });

    test('series-level fields cannot change for one occurrence', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      final task = (await h.task(id))!;
      await expectLater(
        h.tasks.update(task.copyWith(priority: 3), scope: EditScope.thisOccurrence, occurrenceKey: '2026-09-23T08:00'),
        throwsA(isA<ValidationException>()),
      );
      await h.tasks.update(
        task.copyWith(title: 'Special', durationMinutes: 90),
        scope: EditScope.thisOccurrence,
        occurrenceKey: '2026-09-23T08:00',
      );
      final item = await itemOn('2026-09-23', id);
      expect(item.title, 'Special');
      expect(item.durationMinutes, 90);
      expect((await itemOn('2026-09-24', id)).title, 'Task');
    });
  });

  group('this & following (T3.2.07)', () {
    test('open-ended split: truncates, creates a new part in the same series, logs series_split', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      final task = (await h.task(id))!;
      final result = await h.tasks.update(
        task.copyWith(startLocal: ldt('2026-09-24T09:00')),
        scope: EditScope.thisAndFollowing,
        occurrenceKey: '2026-09-24T08:00',
      );
      final newId = result.newTaskId!;
      final old = (await h.task(id))!;
      final part = (await h.task(newId))!;
      expect(old.recurrence!.until, ldt('2026-09-23T08:00'));
      expect(part.seriesId, id);
      expect(part.startLocal, ldt('2026-09-24T09:00'));
      expect((await itemOn('2026-09-23', id)).startLocal, ldt('2026-09-23T08:00'));
      expect((await itemOn('2026-09-24', newId)).startLocal, ldt('2026-09-24T09:00'));
      final split = (await h.events(type: 'series_split')).single;
      expect(split.payload, containsPair('fromTaskId', id));
      expect(split.payload, containsPair('toTaskId', newId));
      expect(split.payload, containsPair('atKey', '2026-09-24T08:00'));
    });

    test('count-based split keeps the total count', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule(count: 10));
      final task = (await h.task(id))!;
      final result = await h.tasks.update(
        task.copyWith(title: 'Renamed'),
        scope: EditScope.thisAndFollowing,
        occurrenceKey: '2026-09-24T08:00',
      );
      final old = (await h.task(id))!;
      final part = (await h.task(result.newTaskId!))!;
      expect(old.recurrence!.count, 3);
      expect(part.recurrence!.count, 7);
      expect(part.title, 'Renamed');
      expect(part.startLocal, ldt('2026-09-24T08:00'), reason: 'unchanged series start → k keeps its own start');
      final all = await h.items(ld('2026-09-21'), 14);
      expect(all, hasLength(10));
      expect({for (final i in all) i.startLocal.date}, hasLength(10), reason: 'no duplicated day');
      expect(all.last.startLocal, ldt('2026-09-30T08:00'));
    });

    test('records ≥ k follow the new part; a time-of-day change converts outcomes to one-offs', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      await h.occurrences.markDone(id, '2026-09-21T08:00');
      await h.occurrences.markDone(id, '2026-09-25T08:00');
      final task = (await h.task(id))!;
      final result = await h.tasks.update(
        task.copyWith(recurrence: RecurrenceRule(freq: Frequency.daily, interval: 2)),
        scope: EditScope.thisAndFollowing,
        occurrenceKey: '2026-09-24T08:00',
      );
      // 2026-09-25 is not generated by "every 2 days from the 24th": the done record becomes a one-off.
      final oneOffs = [for (final t in await h.liveTasks()) if (!t.isRecurring) t];
      expect(oneOffs.single.startLocal, ldt('2026-09-25T08:00'));
      expect((await h.records(oneOffs.single.id)).single.status, OccurrenceStatus.done);
      expect((await h.records(id)).single.occurrenceKey, '2026-09-21T08:00');
      expect(result.newTaskId, isNotNull);
    });

    test('splitting at the first occurrence edits the whole series', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      final task = (await h.task(id))!;
      final result = await h.tasks.update(
        task.copyWith(title: 'New'),
        scope: EditScope.thisAndFollowing,
        occurrenceKey: '2026-09-21T08:00',
      );
      expect(result.newTaskId, isNull);
      expect((await h.task(id))!.title, 'New');
      expect(await h.events(type: 'series_split'), isEmpty);
    });

    test('one undo restores both tasks and all records', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      await h.occurrences.markDone(id, '2026-09-25T08:00');
      final task = (await h.task(id))!;
      final result = await h.tasks.update(
        task.copyWith(title: 'After'),
        scope: EditScope.thisAndFollowing,
        occurrenceKey: '2026-09-24T08:00',
      );
      expect((await h.records(result.newTaskId!)).single.occurrenceKey, '2026-09-25T08:00');
      await h.writer.revert(result.record);
      expect(await h.task(result.newTaskId!), isNull);
      final restored = (await h.task(id))!;
      expect(restored.recurrence!.until, isNull);
      expect((await h.records(id)).single.occurrenceKey, '2026-09-25T08:00');
    });
  });

  group('all occurrences (T3.2.08)', () {
    test('moving a daily 08:00 task to 09:00 keeps past history at 08:00', () async {
      final id = await h.createTask(start: '2026-09-01T08:00', rule: RecurrenceRule());
      await h.occurrences.markDone(id, '2026-09-10T08:00');
      final task = (await h.task(id))!;
      final result = await h.tasks.update(task.copyWith(startLocal: ldt('2026-09-01T09:00')));
      expect(result.newTaskId, isNotNull, reason: 'implicit split from the first non-past occurrence');
      expect((await itemOn('2026-09-10', id)).startLocal, ldt('2026-09-10T08:00'));
      expect((await itemOn('2026-09-10', id)).status, OccurrenceStatus.done);
      expect((await itemOn('2026-09-22', id)).startLocal, ldt('2026-09-22T08:00'), reason: 'already past today');
      expect((await itemOn('2026-09-23', result.newTaskId!)).startLocal, ldt('2026-09-23T09:00'));
      final rescheduled = (await h.events(type: 'rescheduled')).single;
      expect(rescheduled.payload['scope'], 'all');
      expect(rescheduled.payload['fromStart'], '2026-09-23T08:00');
      expect(rescheduled.payload['toStart'], '2026-09-23T09:00');
    });

    test('non-timing edits update the master for past and future', () async {
      final id = await h.createTask(start: '2026-09-01T08:00', rule: RecurrenceRule());
      final task = (await h.task(id))!;
      final result = await h.tasks.update(task.copyWith(title: 'Renamed', priority: 2));
      expect(result.newTaskId, isNull);
      expect((await itemOn('2026-09-10', id)).title, 'Renamed');
      expect((await itemOn('2026-09-30', id)).priority, 2);
    });

    test('"also rewrite past occurrences" edits the master; outcomes become one-offs', () async {
      final id = await h.createTask(start: '2026-09-01T08:00', rule: RecurrenceRule());
      await h.occurrences.markDone(id, '2026-09-10T08:00');
      final task = (await h.task(id))!;
      final report = await h.tasks.previewOrphans(task.copyWith(startLocal: ldt('2026-09-01T09:00')), rewritePast: true);
      expect(report.withOutcome, hasLength(1));
      await h.tasks.update(task.copyWith(startLocal: ldt('2026-09-01T09:00')), rewritePast: true);
      final day10 = await day('2026-09-10');
      expect(day10.map((i) => i.startLocal), containsAll([ldt('2026-09-10T08:00'), ldt('2026-09-10T09:00')]));
      expect(day10.firstWhere((i) => i.startLocal == ldt('2026-09-10T08:00')).isRecurring, isFalse);
    });
  });

  group('orphans (T3.2.09)', () {
    test('keep as one-off vs discard for moved occurrences; outcomes always kept', () async {
      Future<String> seed() async {
        final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
        await h.tasks.editOccurrence(id, '2026-09-23T08:00', start: ldt('2026-09-23T12:00'));
        await h.occurrences.skip(id, '2026-09-25T08:00', reason: 'sick');
        return id;
      }

      final weekly = RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday)]);
      final a = await seed();
      final taskA = (await h.task(a))!;
      final report = await h.tasks.previewOrphans(taskA.copyWith(recurrence: weekly), rewritePast: true);
      expect(report.overridesOnly, hasLength(1));
      expect(report.withOutcome, hasLength(1));
      await h.tasks.update(taskA.copyWith(recurrence: weekly), rewritePast: true, orphanPolicy: OrphanPolicy.discard);
      var oneOffs = [for (final t in await h.liveTasks()) if (!t.isRecurring) t];
      expect(oneOffs.single.startLocal, ldt('2026-09-25T08:00'), reason: 'the skipped outcome survives, the move is dropped');

      final b = await seed();
      await h.tasks.update((await h.task(b))!.copyWith(recurrence: weekly), rewritePast: true);
      oneOffs = [for (final t in await h.liveTasks()) if (!t.isRecurring) t];
      expect(oneOffs.map((t) => t.startLocal), containsAll([ldt('2026-09-23T12:00'), ldt('2026-09-25T08:00')]));
    });
  });

  group('reschedule history (T3.2.10)', () {
    test('postponing one occurrence three times writes three chained events', () async {
      final id = await h.createTask(start: '2026-09-21T10:00', duration: 30, rule: RecurrenceRule());
      for (final _ in [1, 2, 3]) {
        final item = (await day('2026-09-22')).firstWhere((i) => i.taskId == id);
        await h.planner.postpone(item, PostponeOption.plus15Minutes);
      }
      final events = await h.events(type: 'rescheduled');
      expect(events, hasLength(3));
      expect([for (final e in events) e.payload['fromStart']], ['2026-09-22T10:00', '2026-09-22T10:15', '2026-09-22T10:30']);
      expect([for (final e in events) e.payload['toStart']], ['2026-09-22T10:15', '2026-09-22T10:30', '2026-09-22T10:45']);
      for (final e in events) {
        expect(e.payload.keys, containsAll(['occurrenceKey', 'scope', 'fromStart', 'toStart', 'fromDuration', 'toDuration', 'zone', 'source']));
        expect(e.payload['occurrenceKey'], '2026-09-22T10:00');
        expect(e.payload['source'], 'menu');
        expect(e.payload['fromDuration'], 30);
      }
    });

    test('move to today for an overdue one-off: same time if ahead, otherwise next quarter hour', () async {
      final id = await h.createTask(start: '2026-09-21T18:00');
      final item = (await day('2026-09-21')).single;
      expect(item.overdue, isTrue);
      await h.planner.moveToToday(item);
      expect((await h.task(id))!.startLocal, ldt('2026-09-22T18:00'));
      final early = await h.createTask(title: 'Early', start: '2026-09-21T07:00');
      await h.planner.moveToToday((await day('2026-09-21')).single);
      expect((await h.task(early))!.startLocal, ldt('2026-09-22T09:15'), reason: 'now is 09:00 → next quarter hour');
    });
  });

  group('delete scopes (T3.2.11)', () {
    test('this cancels, following truncates and tombstones later records, all cascades', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      await h.occurrences.markDone(id, '2026-09-22T08:00');
      await h.occurrences.markDone(id, '2026-09-26T08:00');
      await h.planner.delete(await itemOn('2026-09-23', id), scope: EditScope.thisOccurrence);
      expect(await day('2026-09-23'), isEmpty);
      await h.planner.delete(await itemOn('2026-09-25', id), scope: EditScope.thisAndFollowing);
      expect((await h.task(id))!.recurrence!.until, ldt('2026-09-24T08:00'));
      expect(await day('2026-09-26'), isEmpty);
      expect((await h.records(id)).map((r) => r.occurrenceKey), isNot(contains('2026-09-26T08:00')));
      await h.planner.delete(await itemOn('2026-09-21', id));
      expect(await h.task(id), isNull);
      expect(await h.records(id), isEmpty);
    });

    test('"this & following" at the first occurrence deletes the series; every scope is undoable', () async {
      final id = await h.createTask(start: '2026-09-21T08:00', rule: RecurrenceRule());
      final op = await h.planner.delete(await itemOn('2026-09-21', id), scope: EditScope.thisAndFollowing);
      expect(await h.task(id), isNull);
      await h.writer.revert(op);
      expect(await h.task(id), isNotNull);
      final cancel = await h.planner.delete(await itemOn('2026-09-24', id), scope: EditScope.thisOccurrence);
      await h.writer.revert(cancel);
      expect((await day('2026-09-24')).single.taskId, id);
    });
  });

  group('missed, overdue & roll-over (T3.2.12)', () {
    test('missed is derived after the grace period; events are never missed', () async {
      final check = await h.createTask(title: 'Check', start: '2026-09-22T08:00', duration: 30);
      final event = await h.createTask(title: 'Meeting', start: '2026-09-22T07:00', duration: 30, mode: TrackingMode.event);
      var items = await day('2026-09-22');
      expect(items.firstWhere((i) => i.taskId == check).status, OccurrenceStatus.missed, reason: '08:30 + 15 min < 09:00');
      expect(items.firstWhere((i) => i.taskId == event).status, OccurrenceStatus.scheduled);
      final soon = await h.createTask(title: 'Soon', start: '2026-09-22T08:30', duration: 20);
      items = await day('2026-09-22');
      expect(items.firstWhere((i) => i.taskId == soon).status, OccurrenceStatus.scheduled, reason: 'within the grace period');
      expect((await h.records(check)), isEmpty, reason: 'derived, never written');
    });

    test('auto roll-over moves unfinished one-offs to today exactly once (two devices)', () async {
      final id = await h.createTask(start: '2026-09-21T18:00');
      final recurring = await h.createTask(title: 'Daily', start: '2026-09-20T18:00', rule: RecurrenceRule());
      expect(await h.planner.rollOverIfEnabled(force: true), 1);
      expect((await h.task(id))!.startLocal, ldt('2026-09-22T18:00'));
      expect(await h.planner.rollOverIfEnabled(force: true), 0, reason: 'already on today');
      final events = [for (final e in await h.events(type: 'rescheduled')) if (e.entityId == id) e];
      expect(events.single.payload['source'], 'rollover');
      // A second device replaying the same roll-over converges (deterministic event id).
      final task = (await h.task(id))!;
      await h.tasks.rollOver([task.copyWith(startLocal: ldt('2026-09-21T18:00'))], today: ld('2026-09-22'), nowLocal: ldt('2026-09-22T09:00'));
      expect([for (final e in await h.events(type: 'rescheduled')) if (e.entityId == id) e], hasLength(1));
      expect((await h.task(recurring))!.startLocal, ldt('2026-09-20T18:00'), reason: 'recurring tasks never roll over');
    });

    test('roll-over of a past-time task lands all-day today', () async {
      final id = await h.createTask(start: '2026-09-21T07:00');
      await h.planner.rollOverIfEnabled(force: true);
      final task = (await h.task(id))!;
      expect(task.isAllDay, isTrue);
      expect(task.startLocal, ldt('2026-09-22T00:00'));
    });
  });

  group('after completion (T3.2.15)', () {
    test('"water plants 3 days after done, at 09:00"', () async {
      final id = await h.createTask(
        start: '2026-09-21T09:00',
        rule: RecurrenceRule.forAfterCompletion(3, RecurrenceUnit.day),
      );
      // Done Monday 21 at 20:00 → next Thursday 24 at 09:00.
      h.clock.set(DateTime.utc(2026, 9, 21, 20));
      await h.occurrences.markDone(id, '2026-09-21T09:00');
      final next = (await h.items(ld('2026-09-21'), 14)).where((i) => i.status != OccurrenceStatus.done).toList();
      expect(next.single.startLocal, ldt('2026-09-24T09:00'));
      // That one done late on Friday 25 → next Monday 28 at 09:00.
      h.clock.set(DateTime.utc(2026, 9, 25, 18));
      await h.occurrences.markDone(id, next.single.occurrenceKey);
      final after = (await h.items(ld('2026-09-21'), 14)).where((i) => i.status != OccurrenceStatus.done).toList();
      expect(after.single.startLocal, ldt('2026-09-28T09:00'));
    });
  });

  group('quota tasks (T3.2.16)', () {
    test('three unplaced slots per week; done for the week after three completions', () async {
      final id = await h.createTask(title: 'Run', start: '2026-09-21T00:00', allDay: true, duration: 1440, rule: RecurrenceRule.forQuota(3, PeriodUnit.week));
      var week = (await h.items(ld('2026-09-21'), 7)).where((i) => i.taskId == id).toList();
      expect(week, hasLength(3));
      expect(week.every((i) => i.isQuotaSlot && i.quotaPeriodKey == 'week:2026-09-21'), isTrue);
      for (final slot in week) {
        await h.occurrences.markDone(id, slot.occurrenceKey);
      }
      week = (await h.items(ld('2026-09-21'), 7)).where((i) => i.taskId == id).toList();
      expect(week.every((i) => i.status == OccurrenceStatus.done), isTrue);
      expect(week, hasLength(3));
    });
  });

  group('pause / resume (T3.2.21)', () {
    test('pausing hides occurrences from the pause moment on; resuming brings them back', () async {
      final id = await h.createTask(start: '2026-09-20T08:00', rule: RecurrenceRule());
      await h.tasks.pauseSeries(id);
      final days = await h.items(ld('2026-09-20'), 5);
      expect(days.map((i) => i.startLocal.date), [ld('2026-09-20'), ld('2026-09-21'), ld('2026-09-22')],
          reason: 'occurrences before the pause (09:00 on the 22nd) stay');
      await h.tasks.resumeSeries(id);
      expect(await h.items(ld('2026-09-20'), 5), hasLength(5));
      expect((await h.events(type: 'paused')).single.entityId, id);
    });
  });

  test('timer tasks are missed only when never started (T3.2.13)', () async {
    final idle = await h.createTask(title: 'Idle', start: '2026-09-22T07:00', duration: 30, mode: TrackingMode.timer);
    final started = await h.createTask(title: 'Started', start: '2026-09-22T07:00', duration: 30, mode: TrackingMode.timer);
    h.clock.set(DateTime.utc(2026, 9, 22, 7, 5));
    await h.occurrences.start(started, '2026-09-22T07:00');
    h.clock.set(DateTime.utc(2026, 9, 22, 9));
    final items = await day('2026-09-22');
    expect(items.firstWhere((i) => i.taskId == idle).status, OccurrenceStatus.missed);
    expect(items.firstWhere((i) => i.taskId == started).status, OccurrenceStatus.inProgress);
    expect(h.read(plannerQueriesProvider), isNotNull);
  });
}
