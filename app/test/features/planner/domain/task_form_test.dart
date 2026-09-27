import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_form.dart';
import 'package:everslot/features/planner/domain/task_validation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LocalDateTime ldt(String s) => LocalDateTime.parse(s);

  group('TaskForm (T3.1.06 form notifier)', () {
    test('create: timed and all-day defaults', () {
      final timed = TaskForm.create(start: ldt('2026-09-22T09:00'), durationMinutes: 45);
      expect(timed.startLocal, ldt('2026-09-22T09:00'));
      expect(timed.endLocal, ldt('2026-09-22T09:45'));
      final allDay = TaskForm.create(start: ldt('2026-09-22T00:00'), durationMinutes: 2880, allDay: true);
      expect(allDay.allDayDays, 2);
      expect(allDay.startLocal, ldt('2026-09-22T00:00'));
      expect(allDay.lastAllDayDate, LocalDate(2026, 9, 23));
      expect(TaskForm.create().isBacklog, isTrue);
    });

    test('editing the end keeps the start; crossing midnight is +1 day', () {
      final form = TaskForm.create(start: ldt('2026-09-22T23:00'), durationMinutes: 30).withEnd(LocalTime(1, 30));
      expect(form.startLocal, ldt('2026-09-22T23:00'));
      expect(form.durationMinutes, 150);
      expect(form.endDayOffset, 1);
      final sameDay = form.withEnd(LocalTime(23, 45));
      expect(sameDay.durationMinutes, 45);
      expect(sameDay.endDayOffset, 0);
      final midnight = TaskForm.create(start: ldt('2026-09-22T22:00'), durationMinutes: 120);
      expect(midnight.endDayOffset, 0, reason: 'ending at 24:00 is still that day');
    });

    test('all-day toggles keep the time and cover multi-day spans', () {
      final timed = TaskForm.create(start: ldt('2026-09-22T09:15'), durationMinutes: 50);
      final allDay = timed.withAllDay(true);
      expect(allDay.allDay, isTrue);
      expect(allDay.effectiveDurationMinutes, 1440);
      expect(allDay.withAllDayEnd(LocalDate(2026, 9, 24)).allDayDays, 3);
      expect(allDay.withAllDayEnd(LocalDate(2026, 9, 20)).allDayDays, 1, reason: 'never before the start');
      final back = allDay.withAllDay(false);
      expect(back.startLocal, ldt('2026-09-22T09:15'));
      expect(back.durationMinutes, 50);
    });

    test('backlog clears the date and the recurrence; scheduling again uses today', () {
      final form = TaskForm.create(start: ldt('2026-09-22T09:00')).withRecurrence(RecurrenceRule());
      final backlog = form.withBacklog(true, today: LocalDate(2026, 9, 25));
      expect(backlog.isBacklog, isTrue);
      expect(backlog.recurrence, isNull);
      expect(backlog.withBacklog(false, today: LocalDate(2026, 9, 25)).date, LocalDate(2026, 9, 25));
    });

    test('a picked rule moves the start to the aligned anchor', () {
      final form = TaskForm.create(start: ldt('2026-09-21T07:00'), durationMinutes: 60);
      final rule = RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.thursday)]);
      final next = form.withRecurrence(rule, alignedStart: ldt('2026-09-24T07:00'));
      expect(next.recurrence, rule);
      expect(next.startLocal, ldt('2026-09-24T07:00'));
      expect(next.anchor, RecurrenceAnchor(ldt('2026-09-24T07:00'), null, durationMinutes: 60));
    });

    test('validation goes through the domain rules', () {
      expect(TaskForm.create(start: ldt('2026-09-22T09:00')).validate(), [TaskValidationError.titleEmpty]);
      final ok = TaskForm.create(start: ldt('2026-09-22T09:00')).copyWith(title: 'Gym');
      expect(ok.validate(), isEmpty);
      expect(ok.copyWith(url: 'not a url').validate(), [TaskValidationError.urlInvalid]);
      expect(ok.copyWith(durationMinutes: 600000).validate(), contains(TaskValidationError.durationOutOfRange));
      expect(ok.withZone('Mars/Base').validate(isValidZone: (z) => z != 'Mars/Base'), [TaskValidationError.zoneInvalid]);
    });

    test('deadline warning when planned after it (T3.1.13)', () {
      final form = TaskForm.create(start: ldt('2026-09-26T09:00')).copyWith(deadline: ldt('2026-09-25T23:59'));
      expect(form.plannedAfterDeadline, isTrue);
      expect(form.copyWith(date: LocalDate(2026, 9, 24)).plannedAfterDeadline, isFalse);
    });

    test('applyTo writes every field; backlog tasks carry their estimate', () {
      final form = TaskForm.create(start: ldt('2026-09-22T09:00'), durationMinutes: 45).copyWith(
        title: '  Gym ',
        notes: 'Legs **day**',
        categoryId: 'cat',
        color: 0xFF3B82F6,
        priority: 3,
        trackingMode: TrackingMode.timer,
        icon: 'fitness',
        location: ' Gym A ',
        url: 'example.com',
        zoneId: 'Europe/Paris',
      );
      final task = form.applyTo(const Task(id: 'x', seriesId: 'x', title: ''));
      expect(task.title, 'Gym');
      expect(task.notes, 'Legs **day**');
      expect(task.startLocal, ldt('2026-09-22T09:00'));
      expect(task.durationMinutes, 45);
      expect(task.timeZone, 'Europe/Paris');
      expect(task.priority, 3);
      expect(task.trackingMode, TrackingMode.timer);
      expect(task.location, 'Gym A');
      expect(task.url, 'example.com');
      final backlog = form.withBacklog(true, today: LocalDate(2026, 9, 22)).copyWith(estimateMinutes: 90);
      final unscheduled = backlog.applyTo(const Task(id: 'y', seriesId: 'y', title: ''));
      expect(unscheduled.startLocal, isNull);
      expect(unscheduled.durationMinutes, 90);
    });

    test('an occurrence form shows its effective values', () {
      final task = Task(
        id: 't',
        seriesId: 't',
        title: 'Standup',
        startLocal: ldt('2026-09-21T09:30'),
        durationMinutes: 15,
        recurrence: RecurrenceRule(),
      );
      const record = TaskOccurrenceRecord(
        id: 'r',
        taskId: 't',
        occurrenceKey: '2026-09-23T09:30',
        overrideDurationMinutes: 30,
        overrideTitle: 'Long standup',
      );
      final form = TaskForm.fromTask(task, occurrenceKey: '2026-09-23T09:30', record: record);
      expect(form.startLocal, ldt('2026-09-23T09:30'));
      expect(form.durationMinutes, 30);
      expect(form.title, 'Long standup');
    });

    test('diff drives the unsaved guard and the scope matrix', () {
      final a = TaskForm.create(start: ldt('2026-09-22T09:00')).copyWith(title: 'A');
      expect(a.diff(a), isEmpty);
      final b = a.copyWith(title: 'B', priority: 2);
      expect(b.diff(a), {'title', 'priority'});
      expect(b.diff(a).every(TaskForm.occurrenceFields.contains), isFalse);
      expect(TaskForm.isTimingChange(a.copyWith(durationMinutes: 90).diff(a)), isTrue);
      expect(TaskForm.isTimingChange(b.diff(a)), isFalse);
    });
  });
}
