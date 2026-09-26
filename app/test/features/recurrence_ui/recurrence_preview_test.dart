import 'package:everslot/core/time/clock.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/recurrence_ui/application/recurrence_preview.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  tzdata.initializeTimeZones();
  // Tue 2026-09-22 07:00 UTC = 09:00 Paris.
  final clock = FakeClock(DateTime.utc(2026, 9, 22, 7));
  RecurrenceService service({String zone = 'Europe/Paris'}) =>
      RecurrenceService(clock: clock, resolver: TzZoneResolver(), currentZone: zone, useIsolates: false);
  final anchor = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 9, 30), null, durationMinutes: 30);

  test('next 10 occurrences from now, 60-day calendar and no warnings for a daily rule', () {
    final p = RecurrencePreviewer(service()).preview(RecurrenceRule(), anchor);
    expect(p.isValid, isTrue);
    expect(p.next, hasLength(10));
    expect(p.next.first.startLocal, LocalDateTime.of(2026, 9, 22, 9, 30));
    expect(p.calendarStart, LocalDate(2026, 9, 22));
    expect(p.calendarLength, 60);
    expect(p.occurrenceDays, hasLength(60));
    expect(p.warnings, isEmpty);
    expect(p.anchorMoved, isFalse);
  });

  test('weekly on Monday and Thursday: anchor moves to the first match (Thursday)', () {
    final rule = RecurrenceRule(
      freq: Frequency.weekly,
      byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.thursday)],
    );
    final p = RecurrencePreviewer(service()).preview(rule, anchor);
    expect(p.anchorMoved, isTrue);
    expect(p.alignedAnchor.start, LocalDateTime.of(2026, 9, 24, 9, 30));
    expect(p.next.map((o) => o.startLocal.date.weekday).toSet(), {Weekday.monday, Weekday.thursday});
    // 60 days from Thu 24 Sep: ~17 matching days.
    expect(p.occurrenceDays.length, inInclusiveRange(16, 18));
    expect(p.occurrenceDays.every((d) => d.weekday == Weekday.monday || d.weekday == Weekday.thursday), isTrue);
  });

  test('last weekday of the month (monthly + MO–FR + bySetPos -1)', () {
    final rule = RecurrenceRule(
      freq: Frequency.monthly,
      byWeekday: const [
        WeekdayRule(Weekday.monday),
        WeekdayRule(Weekday.tuesday),
        WeekdayRule(Weekday.wednesday),
        WeekdayRule(Weekday.thursday),
        WeekdayRule(Weekday.friday),
      ],
      bySetPos: const [-1],
    );
    final p = RecurrencePreviewer(service()).preview(rule, anchor);
    expect(p.isValid, isTrue);
    expect(
      [for (final o in p.next.take(3)) o.startLocal.date],
      [LocalDate(2026, 9, 30), LocalDate(2026, 10, 30), LocalDate(2026, 11, 30)],
    );
  });

  test('every 5 minutes all day warns "288 occurrences per day"', () {
    final rule = RecurrenceRule(freq: Frequency.minutely, interval: 5);
    final p = RecurrencePreviewer(service()).preview(rule, anchor);
    expect(p.warnings, contains(const RecurrenceWarning(RecurrenceWarningKind.tooManyPerDay, count: 288)));
  });

  test('a rule that never occurs within 5 years warns', () {
    final rule = RecurrenceRule(freq: Frequency.yearly, byMonth: const [2], byMonthDay: const [30]);
    final p = RecurrencePreviewer(service()).preview(rule, anchor);
    expect(p.next, isEmpty);
    expect(p.hasWarning(RecurrenceWarningKind.neverOccurs), isTrue);
    expect(p.occurrenceDays, isEmpty);
  });

  test('a time falling in a DST gap is flagged (02:30 Europe/Paris, spring forward)', () {
    final fixed = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 2, 30), 'Europe/Paris', durationMinutes: 15);
    final p = RecurrencePreviewer(service(), dstScanDays: 200).preview(RecurrenceRule(), fixed);
    expect(p.hasWarning(RecurrenceWarningKind.dstShift), isTrue);
    final noon = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 12), 'Europe/Paris', durationMinutes: 15);
    expect(
      RecurrencePreviewer(
        service(),
        dstScanDays: 200,
      ).preview(RecurrenceRule(), noon).hasWarning(RecurrenceWarningKind.dstShift),
      isFalse,
    );
  });

  test('invalid rules report issues and skip expansion', () {
    final p = RecurrencePreviewer(service())
        .preview(RecurrenceRule(freq: Frequency.weekly, byWeekday: const []), anchor);
    expect(p.isValid, isFalse);
    expect(p.validation.has(RuleIssueCode.emptyWeekdaySet), isTrue);
    expect(p.next, isEmpty);
    expect(p.calendarStart, isNull);
  });

  test('all-day anchor with a sub-daily rule warns', () {
    final allDay = RecurrenceAnchor.allDayOn(LocalDate(2026, 9, 22), null);
    final p = RecurrencePreviewer(service()).preview(RecurrenceRule(freq: Frequency.hourly), allDay);
    expect(p.hasWarning(RecurrenceWarningKind.allDaySubDaily), isTrue);
  });

  test('quota rules list the next periods; after-completion lists the first due', () {
    final quota = RecurrencePreviewer(service()).preview(RecurrenceRule.forQuota(3, PeriodUnit.week), anchor);
    expect(quota.periods, isNotEmpty);
    expect(quota.periods.first.key, 'week:2026-09-21');
    expect(quota.calendarStart, isNull);
    final after = RecurrencePreviewer(service())
        .preview(RecurrenceRule.forAfterCompletion(3, RecurrenceUnit.day), anchor);
    expect(after.next.single.startLocal, anchor.start);
  });

  test('fixed-zone anchors keep their own wall clock in the preview', () {
    final ny = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 10), 'America/New_York', durationMinutes: 15);
    final p = RecurrencePreviewer(service()).preview(RecurrenceRule(), ny);
    expect(p.next.first.startLocal.time, LocalTime(10, 0));
    expect(p.next.first.zoneId, 'America/New_York');
  });

  test('preview updates stay under 50 ms (every 45 min 09–18 on weekdays)', () {
    final s = service();
    final previewer = RecurrencePreviewer(s);
    RecurrenceRule rule(int step) => RecurrenceRule(
      freq: Frequency.minutely,
      interval: step,
      window: DailyWindow(LocalTime(9, 0), LocalTime(18, 0)),
      byWeekday: const [
        WeekdayRule(Weekday.monday),
        WeekdayRule(Weekday.tuesday),
        WeekdayRule(Weekday.wednesday),
        WeekdayRule(Weekday.thursday),
        WeekdayRule(Weekday.friday),
      ],
    );
    previewer.preview(rule(30), anchor); // warm-up (JIT, tz tables)
    final watch = Stopwatch()..start();
    final p = previewer.preview(rule(45), anchor);
    watch.stop();
    expect(p.isValid, isTrue);
    expect(p.next.first.startLocal, LocalDateTime.of(2026, 9, 22, 9, 45));
    expect(watch.elapsedMilliseconds, lessThan(50));
  });
}
