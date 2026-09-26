import 'dart:math';

import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_validation.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = RecurrenceEngine(const FixedOffsetZoneResolver());
  LocalDateTime ldt(String s) => LocalDateTime.parse(s);

  group('TaskTitle & value objects', () {
    test('title is trimmed and 1–300 characters', () {
      expect(TaskTitle.parse('  Gym  '), 'Gym');
      expect(TaskTitle.check('   '), TaskValidationError.titleEmpty);
      expect(TaskTitle.check('x' * 301), TaskValidationError.titleTooLong);
      expect(TaskTitle.check('x' * 300), isNull);
      expect(() => TaskTitle.parse(''), throwsA(isA<TaskValidationException>()));
    });

    test('duration 0–525600', () {
      expect(DurationMinutes.isValid(0), isTrue);
      expect(DurationMinutes.isValid(525600), isTrue);
      expect(DurationMinutes.isValid(525601), isFalse);
      expect(DurationMinutes.isValid(-1), isFalse);
    });

    test('url normalization and validation', () {
      expect(TaskUrl.normalize('example.com/a'), 'https://example.com/a');
      expect(TaskUrl.normalize('http://x.org'), 'http://x.org');
      expect(TaskUrl.normalize('ftp://x.org'), isNull);
      expect(TaskUrl.normalize('not a url'), isNull);
      expect(TaskUrl.isValid(''), isTrue);
      expect(TaskUrl.isValid('nope'), isFalse);
    });

    test('time zone mode', () {
      expect(TimeZoneMode.fromZoneId(null), const TimeZoneMode.floating());
      expect(TimeZoneMode.fromZoneId('Europe/Paris'), const TimeZoneMode.fixed('Europe/Paris'));
      expect(const TimeZoneMode.fixed('Europe/Paris').isFloating, isFalse);
    });

    test('status json spellings round-trip', () {
      for (final s in OccurrenceStatus.values) {
        expect(OccurrenceStatusJson.fromJson(s.json), s);
      }
      expect(OccurrenceStatus.inProgress.json, 'in_progress');
      for (final m in TrackingMode.values) {
        expect(TrackingModeJson.fromJson(m.json), m);
      }
      expect(NotifyMode.fromJson('inherit_plus'), NotifyMode.inheritPlus);
    });
  });

  group('TaskSchedule invariants', () {
    test('rejects all-day at 09:00, 0-length all-day, partial days', () {
      expect(
        TaskSchedule(startLocal: ldt('2026-09-22T09:00'), durationMinutes: 1440, isAllDay: true).validate(),
        contains(TaskValidationError.allDayNotMidnight),
      );
      expect(
        TaskSchedule(startLocal: ldt('2026-09-22T00:00'), durationMinutes: 0, isAllDay: true).validate(),
        contains(TaskValidationError.allDayZeroLength),
      );
      expect(
        TaskSchedule(startLocal: ldt('2026-09-22T00:00'), durationMinutes: 600, isAllDay: true).validate(),
        contains(TaskValidationError.allDayPartialDay),
      );
      expect(
        TaskSchedule(startLocal: ldt('2026-09-22T00:00'), durationMinutes: 2880, isAllDay: true).validate(),
        isEmpty,
      );
    });

    test('rejects recurrence on an unscheduled task and invalid rules', () {
      expect(
        TaskSchedule(recurrence: RecurrenceRule()).validate(),
        contains(TaskValidationError.recurrenceWithoutStart),
      );
      expect(
        TaskSchedule(startLocal: ldt('2026-09-22T09:00'), durationMinutes: 30, recurrence: RecurrenceRule(interval: 0)).validate(),
        contains(TaskValidationError.recurrenceInvalid),
      );
    });

    test('rejects unknown zones through the predicate', () {
      final s = TaskSchedule(
        startLocal: ldt('2026-09-22T09:00'),
        durationMinutes: 30,
        zoneMode: const TimeZoneMode.fixed('Mars/Base'),
      );
      expect(s.validate(isValidZone: (z) => z != 'Mars/Base'), [TaskValidationError.zoneInvalid]);
    });

    test('recurrenceUntilLocal: null open-ended, last start for count, until for until-based', () {
      final start = ldt('2026-09-21T08:00');
      expect(TaskSchedule(startLocal: start, durationMinutes: 30, recurrence: RecurrenceRule()).recurrenceUntilLocal(engine), isNull);
      expect(
        TaskSchedule(startLocal: start, durationMinutes: 30, recurrence: RecurrenceRule(count: 5)).recurrenceUntilLocal(engine),
        ldt('2026-09-25T08:00'),
      );
      expect(
        TaskSchedule(
          startLocal: start,
          durationMinutes: 30,
          recurrence: RecurrenceRule(freq: Frequency.weekly, count: 3, byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.friday)]),
        ).recurrenceUntilLocal(engine),
        ldt('2026-09-28T08:00'),
      );
      expect(
        TaskSchedule(startLocal: start, durationMinutes: 30, recurrence: RecurrenceRule(until: ldt('2026-10-01T08:00'))).recurrenceUntilLocal(engine),
        ldt('2026-10-01T08:00'),
      );
      expect(
        TaskSchedule(
          startLocal: start,
          durationMinutes: 30,
          recurrence: RecurrenceRule(count: 2, rdates: const ['2026-12-01T10:00']),
        ).recurrenceUntilLocal(engine),
        ldt('2026-12-01T10:00'),
      );
      expect(TaskSchedule(startLocal: start, durationMinutes: 30).recurrenceUntilLocal(engine), isNull);
    });

    test('property: generated schedules satisfy their own invariants', () {
      final random = Random(42);
      for (var i = 0; i < 500; i++) {
        final allDay = random.nextBool();
        final days = random.nextInt(4);
        final start = allDay
            ? LocalDate(2026, 1 + random.nextInt(12), 1 + random.nextInt(28)).atStartOfDay
            : LocalDateTime.of(2026, 1 + random.nextInt(12), 1 + random.nextInt(28), random.nextInt(24), random.nextInt(60));
        final duration = allDay ? days * 1440 : random.nextInt(600);
        final errors = TaskSchedule(startLocal: start, durationMinutes: duration, isAllDay: allDay).validate();
        if (allDay && days == 0) {
          expect(errors, [TaskValidationError.allDayZeroLength]);
        } else {
          expect(errors, isEmpty);
        }
      }
    });
  });

  group('Task entity', () {
    final task = Task(
      id: 't1',
      seriesId: 't1',
      title: 'Gym',
      startLocal: ldt('2026-09-21T07:00'),
      durationMinutes: 60,
      timeZone: 'Europe/Paris',
      recurrence: RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday)]),
      priority: 3,
      trackingMode: TrackingMode.timer,
      icon: 'fitness',
      deadlineLocal: ldt('2026-09-30T18:00'),
    );

    test('json round-trip', () {
      final json = task.toJson();
      expect(Task.fromJson(json), task);
      expect(json['tracking_mode'], 'timer');
      expect(json['start_local'], '2026-09-21T07:00');
    });

    test('derived getters', () {
      expect(task.isRecurring, isTrue);
      expect(task.isUnscheduled, isFalse);
      expect(task.endLocal, ldt('2026-09-21T08:00'));
      expect(task.oneOffKey, '2026-09-21T07:00');
      expect(task.anchor!.zoneId, 'Europe/Paris');
      final allDay = task.copyWith(isAllDay: true, startLocal: ldt('2026-09-21T00:00'), durationMinutes: 1440);
      expect(allDay.oneOffKey, '2026-09-21');
      expect(task.copyWith(startLocal: null, recurrence: null).isUnscheduled, isTrue);
    });

    test('validateTask aggregates errors', () {
      expect(validateTask(task), isEmpty);
      expect(validateTask(task.copyWith(title: ' ', url: 'bad', priority: 7)), [
        TaskValidationError.titleEmpty,
        TaskValidationError.priorityOutOfRange,
        TaskValidationError.urlInvalid,
      ]);
    });

    test('occurrence record json round-trip and outcome flags', () {
      final r = TaskOccurrenceRecord(
        id: 'r',
        taskId: 't1',
        occurrenceKey: '2026-09-21T07:00',
        overrideStartLocal: ldt('2026-09-21T09:00'),
        status: OccurrenceStatus.done,
        completedAt: DateTime.utc(2026, 9, 21, 10),
        rating: 4,
      );
      expect(TaskOccurrenceRecord.fromJson(r.toJson()), r);
      expect(r.hasOutcome, isTrue);
      expect(r.isMoved, isTrue);
      expect(const TaskOccurrenceRecord(id: 'x', taskId: 't', occurrenceKey: 'k', overrideTitle: 'T').hasOutcome, isFalse);
    });

    test('time entry duration', () {
      final e = TimeEntry(id: 'e', taskId: 't', startedAt: DateTime.utc(2026, 9, 21, 9));
      expect(e.isRunning, isTrue);
      expect(e.durationAt(DateTime.utc(2026, 9, 21, 9, 30)), const Duration(minutes: 30));
      expect(TimeEntry.fromJson(e.toJson()), e);
    });
  });

  group('TrackingPolicy (T3.2.13)', () {
    test('full policy table', () {
      expect(TrackingPolicy.of(TrackingMode.check).canBeMissed, isTrue);
      expect(TrackingPolicy.of(TrackingMode.check).hasCheckbox, isTrue);
      expect(TrackingPolicy.of(TrackingMode.event).canBeMissed, isFalse);
      expect(TrackingPolicy.of(TrackingMode.event).hasCheckbox, isFalse);
      expect(TrackingPolicy.of(TrackingMode.event).countsInCompletionRate, isFalse);
      expect(TrackingPolicy.of(TrackingMode.event).countsAsBusyTime, isTrue);
      expect(TrackingPolicy.of(TrackingMode.timer).usesTimer, isTrue);
      expect(TrackingPolicy.of(TrackingMode.timer).canBeMissed, isTrue);
    });

    test('primary actions per mode and status', () {
      expect(TrackingPolicy.check.primaryActions(OccurrenceStatus.scheduled), [
        OccurrencePrimaryAction.done,
        OccurrencePrimaryAction.skip,
      ]);
      expect(TrackingPolicy.event.primaryActions(OccurrenceStatus.scheduled), [OccurrencePrimaryAction.skip]);
      expect(TrackingPolicy.timer.primaryActions(OccurrenceStatus.scheduled).first, OccurrencePrimaryAction.start);
      expect(TrackingPolicy.timer.primaryActions(OccurrenceStatus.inProgress, timerRunning: true), [
        OccurrencePrimaryAction.pause,
        OccurrencePrimaryAction.stop,
      ]);
      expect(TrackingPolicy.timer.primaryActions(OccurrenceStatus.inProgress), [
        OccurrencePrimaryAction.resume,
        OccurrencePrimaryAction.stop,
      ]);
      for (final mode in TrackingMode.values) {
        expect(TrackingPolicy.of(mode).primaryActions(OccurrenceStatus.done), [OccurrencePrimaryAction.reopen]);
      }
    });
  });
}
