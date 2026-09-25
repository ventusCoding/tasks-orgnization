import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LocalDateTime ldt(String s) => LocalDateTime.parse(s);

  group('quick-create duration rule (T3.1.08)', () {
    final cases = <(String, int?, int?, QuickCreateSlot)>[
      ('30-min grid', 30, null, QuickCreateSlot(ldt('2026-09-22T09:00'), 30)),
      ('5-min grid', 5, null, QuickCreateSlot(ldt('2026-09-22T09:00'), 30)),
      ('2-h grid', 120, null, QuickCreateSlot(ldt('2026-09-22T08:00'), 30)),
      ('15-min grid', 15, null, QuickCreateSlot(ldt('2026-09-22T09:00'), 15)),
      ('60-min grid', 60, null, QuickCreateSlot(ldt('2026-09-22T09:00'), 60)),
      ('1-min grid', 1, null, QuickCreateSlot(ldt('2026-09-22T09:00'), 30)),
      ('week list', 1440, null, QuickCreateSlot(ldt('2026-09-22T00:00'), 1440, allDay: true)),
      ('dragged range wins', 30, 95, QuickCreateSlot(ldt('2026-09-22T09:00'), 95)),
    ];
    for (final (name, slot, range, expected) in cases) {
      test(name, () {
        expect(
          quickCreateSlot(tapped: ldt('2026-09-22T09:00'), slotMinutes: slot, rangeMinutes: range),
          expected,
        );
      });
    }

    test('tap inside a slot snaps down to its start', () {
      expect(quickCreateSlot(tapped: ldt('2026-09-22T09:40'), slotMinutes: 30), QuickCreateSlot(ldt('2026-09-22T09:30'), 30));
      expect(
        quickCreateSlot(tapped: ldt('2026-09-22T09:40'), slotMinutes: 240, defaultDurationMinutes: 45),
        QuickCreateSlot(ldt('2026-09-22T08:00'), 45),
      );
    });
  });

  group('actual time capture (T3.2.14)', () {
    final start = DateTime.utc(2026, 9, 22, 9);
    final end = DateTime.utc(2026, 9, 22, 10);

    test('setting decides when to ask', () {
      expect(shouldAskActualTime(AskActualTimeOnDone.never, plannedEnd: end, now: end.add(const Duration(hours: 5))), isFalse);
      expect(shouldAskActualTime(AskActualTimeOnDone.always, plannedEnd: end, now: end), isTrue);
      expect(shouldAskActualTime(AskActualTimeOnDone.ifOffSchedule, plannedEnd: end, now: end.add(const Duration(minutes: 10))), isFalse);
      expect(shouldAskActualTime(AskActualTimeOnDone.ifOffSchedule, plannedEnd: end, now: end.add(const Duration(minutes: 16))), isTrue);
      expect(shouldAskActualTime(AskActualTimeOnDone.ifOffSchedule, plannedEnd: end, now: end.subtract(const Duration(minutes: 40))), isTrue);
      expect(AskActualTimeOnDone.fromJson('always'), AskActualTimeOnDone.always);
      expect(AskActualTimeOnDone.fromJson(null), AskActualTimeOnDone.ifOffSchedule);
    });

    test('as planned stores planned', () {
      final r = actualTimesFor(ActualTimeOption.asPlanned, plannedStart: start, plannedEnd: end, now: DateTime.utc(2026, 9, 22, 13));
      expect(r.start, start);
      expect(r.end, end);
    });

    test('just now stores end = now and start = now − planned duration', () {
      final now = DateTime.utc(2026, 9, 22, 13, 20);
      final r = actualTimesFor(ActualTimeOption.justNow, plannedStart: start, plannedEnd: end, now: now);
      expect(r.end, now);
      expect(r.start, DateTime.utc(2026, 9, 22, 12, 20));
    });

    test('custom validates end ≥ start', () {
      final r = actualTimesFor(
        ActualTimeOption.custom,
        plannedStart: start,
        plannedEnd: end,
        now: end,
        customStart: DateTime.utc(2026, 9, 22, 9, 10),
        customEnd: DateTime.utc(2026, 9, 22, 9, 50),
      );
      expect(r.start, DateTime.utc(2026, 9, 22, 9, 10));
      expect(
        () => actualTimesFor(ActualTimeOption.custom, plannedStart: start, plannedEnd: end, now: end, customStart: end, customEnd: start),
        throwsA(isA<ActualTimeException>()),
      );
    });
  });

  group('time tracking math (T3.2.17/18)', () {
    final now = DateTime.utc(2026, 9, 22, 12);
    final entries = [
      TimeEntry(id: 'a', taskId: 't', startedAt: DateTime.utc(2026, 9, 22, 9), endedAt: DateTime.utc(2026, 9, 22, 9, 30)),
      TimeEntry(id: 'b', taskId: 't', startedAt: DateTime.utc(2026, 9, 22, 11, 45)),
    ];

    test('sums closed and running entries', () {
      expect(trackedSecondsOf(entries, now), 45 * 60);
    });

    test('overlap detection excludes the edited entry', () {
      expect(
        overlappingEntries(DateTime.utc(2026, 9, 22, 9, 20), DateTime.utc(2026, 9, 22, 9, 40), entries, now: now).map((e) => e.id),
        ['a'],
      );
      expect(
        overlappingEntries(DateTime.utc(2026, 9, 22, 9, 20), DateTime.utc(2026, 9, 22, 9, 40), entries, now: now, excludeId: 'a'),
        isEmpty,
      );
      expect(overlappingEntries(DateTime.utc(2026, 9, 22, 11, 50), DateTime.utc(2026, 9, 22, 11, 55), entries, now: now).map((e) => e.id), ['b']);
    });

    test('negative durations are rejected', () {
      expect(validateTimeEntry(now, now.subtract(const Duration(minutes: 1)), now: now), TimeEntryError.endBeforeStart);
      expect(validateTimeEntry(now.subtract(const Duration(hours: 1)), now, now: now), isNull);
      expect(validateTimeEntry(now.add(const Duration(hours: 1)), null, now: now), TimeEntryError.inFuture);
    });

    test('timer policy parsing', () {
      expect(TimerPolicy.fromJson('multiple'), TimerPolicy.multiple);
      expect(TimerPolicy.fromJson(null), TimerPolicy.single);
    });
  });

  group('overlap warning (T3.1.14)', () {
    PlannerItem item(String id, String start, int minutes, {OccurrenceStatus status = OccurrenceStatus.scheduled, TrackingMode mode = TrackingMode.check, bool allDay = false}) {
      final s = ldt(start);
      final utc = s.toDateTimeUtc();
      return PlannerItem(
        taskId: id,
        seriesId: id,
        occurrenceKey: start,
        title: id,
        startLocal: s,
        durationMinutes: minutes,
        startUtc: utc,
        endUtc: utc.add(Duration(minutes: minutes)),
        status: status,
        trackingMode: mode,
        allDay: allDay,
      );
    }

    final items = [
      item('sync', '2026-09-22T09:30', 30),
      item('lunch', '2026-09-22T09:00', 60, mode: TrackingMode.event),
      item('done', '2026-09-22T09:00', 60, status: OccurrenceStatus.done),
      item('cancelled', '2026-09-22T09:00', 60, status: OccurrenceStatus.cancelled),
      item('allday', '2026-09-22T00:00', 1440, allDay: true),
      item('after', '2026-09-22T10:00', 30),
      item('self', '2026-09-22T09:00', 30),
    ];

    test('lists open check/timer overlaps, ignoring done/cancelled/all-day/touching', () {
      final found = findOverlaps(
        startUtc: DateTime.utc(2026, 9, 22, 9),
        endUtc: DateTime.utc(2026, 9, 22, 10),
        items: items,
        excludeTaskId: 'self',
      );
      expect(found.map((i) => i.taskId), ['sync']);
    });

    test('events are optional', () {
      final found = findOverlaps(
        startUtc: DateTime.utc(2026, 9, 22, 9),
        endUtc: DateTime.utc(2026, 9, 22, 10),
        items: items,
        excludeTaskId: 'self',
        includeEvents: true,
      );
      expect(found.map((i) => i.taskId), ['sync', 'lunch']);
    });
  });

  group('postpone options (T3.2.10)', () {
    final now = ldt('2026-09-22T14:10');
    test('relative to the planned start when still ahead', () {
      expect(postponeTarget(PostponeOption.plus15Minutes, currentStart: ldt('2026-09-22T16:00'), nowLocal: now), ldt('2026-09-22T16:15'));
      expect(postponeTarget(PostponeOption.plus1Hour, currentStart: ldt('2026-09-22T16:00'), nowLocal: now), ldt('2026-09-22T17:00'));
    });

    test('relative to now when already past', () {
      expect(postponeTarget(PostponeOption.plus15Minutes, currentStart: ldt('2026-09-22T09:00'), nowLocal: now), ldt('2026-09-22T14:25'));
    });

    test('evening, tomorrow and next week', () {
      expect(postponeTarget(PostponeOption.thisEvening, currentStart: ldt('2026-09-22T09:00'), nowLocal: now), ldt('2026-09-22T20:00'));
      expect(
        postponeTarget(PostponeOption.thisEvening, currentStart: ldt('2026-09-22T09:00'), nowLocal: ldt('2026-09-22T21:00')),
        ldt('2026-09-23T20:00'),
      );
      expect(postponeTarget(PostponeOption.tomorrowSameTime, currentStart: ldt('2026-09-22T09:00'), nowLocal: now), ldt('2026-09-23T09:00'));
      expect(postponeTarget(PostponeOption.nextWeekSameTime, currentStart: ldt('2026-09-22T09:00'), nowLocal: now), ldt('2026-09-29T09:00'));
      expect(postponeTarget(PostponeOption.nextWeekSameTime, currentStart: ldt('2026-09-18T09:00'), nowLocal: now), ldt('2026-09-29T09:00'));
    });

    test('move to today helpers', () {
      expect(sameTimeTodayIfAhead(ldt('2026-09-20T18:00'), now), ldt('2026-09-22T18:00'));
      expect(sameTimeTodayIfAhead(ldt('2026-09-20T09:00'), now), isNull);
      expect(nextQuarterHour(now), ldt('2026-09-22T14:15'));
      expect(nextQuarterHour(ldt('2026-09-22T23:50')), ldt('2026-09-23T00:00'));
    });
  });

  group('orphans (T3.2.09)', () {
    TaskOccurrenceRecord rec(String key, {OccurrenceStatus status = OccurrenceStatus.scheduled, String? moveTo, bool cancelled = false, int? rating}) =>
        TaskOccurrenceRecord(
          id: key,
          taskId: 't',
          occurrenceKey: key,
          status: status,
          overrideStartLocal: moveTo == null ? null : ldt(moveTo),
          isCancelled: cancelled,
          rating: rating,
        );

    test('classifies outcome, overrides-only and cancelled-only records', () {
      final report = findOrphans([
        rec('2026-09-01T08:00', status: OccurrenceStatus.done),
        rec('2026-09-02T08:00', status: OccurrenceStatus.skipped),
        rec('2026-09-03T08:00', rating: 5),
        rec('2026-09-04T08:00', moveTo: '2026-09-04T10:00'),
        rec('2026-09-05T08:00', cancelled: true, status: OccurrenceStatus.cancelled),
        rec('2026-09-06T09:00', status: OccurrenceStatus.done),
      ], (key) => key.endsWith('T09:00'));
      expect(report.withOutcome.map((r) => r.occurrenceKey), ['2026-09-01T08:00', '2026-09-02T08:00', '2026-09-03T08:00']);
      expect(report.completedCount, 1);
      expect(report.skippedCount, 1);
      expect(report.otherOutcomeCount, 1);
      expect(report.movedCount, 1);
      expect(report.cancelledOnly, hasLength(1));
      expect(report.needsChoice, isTrue);
      expect(findOrphans([rec('2026-09-06T09:00')], (_) => true).isEmpty, isTrue);
    });
  });

  test('skip reasons', () {
    expect(SkipReasons.isKey('sick'), isTrue);
    expect(SkipReasons.isKey('because'), isFalse);
  });
}
