import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('LocalDate', () {
    test('validates fields and leap years', () {
      expect(LocalDate(2024, 2, 29).day, 29);
      expect(() => LocalDate(2100, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
      expect(LocalDate.tryCreate(2026, 0, 1), isNull);
      expect(LocalDate.tryCreate(2026, 2, 29), isNull);
      expect(LocalDate.isLeapYear(2000), isTrue);
      expect(LocalDate.isLeapYear(1900), isFalse);
      expect(LocalDate.daysInYear(2024), 366);
      expect(LocalDate.daysInYear(2026), 365);
    });

    test('epoch day round trips and weekdays', () {
      for (final day in [-800000, -1, 0, 1, 20000, 800000]) {
        expect(LocalDate.fromEpochDay(day).epochDay, day);
      }
      expect(LocalDate(1970, 1, 1).epochDay, 0);
      expect(LocalDate(1970, 1, 1).weekday, Weekday.thursday);
      expect(LocalDate(2026, 9, 21).weekday, Weekday.monday);
      expect(LocalDate(1969, 12, 31).weekday, Weekday.wednesday);
      expect(LocalDate(2024, 12, 31).dayOfYear, 366);
    });

    test('arithmetic', () {
      final jan31 = LocalDate(2026, 1, 31);
      expect(jan31.plusDays(0), same(jan31));
      expect(jan31.plusDays(1), LocalDate(2026, 2, 1));
      expect(jan31.minusDays(31), LocalDate(2025, 12, 31));
      expect(jan31.plusMonths(1), LocalDate(2026, 2, 28));
      expect(LocalDate(2024, 1, 31).plusMonths(1), LocalDate(2024, 2, 29));
      expect(jan31.plusMonthsOrNull(1, overflow: MonthOverflow.skip), isNull);
      expect(jan31.plusMonthsOrNull(-14), LocalDate(2024, 11, 30));
      expect(LocalDate(2024, 2, 29).plusYears(1), LocalDate(2025, 2, 28));
      expect(LocalDate(2026, 1, 1).daysUntil(LocalDate(2027, 1, 1)), 365);
      expect(LocalDate(2026, 9, 23).firstDayOfMonth, LocalDate(2026, 9, 1));
      expect(LocalDate(2026, 2, 3).lastDayOfMonth, LocalDate(2026, 2, 28));
      expect(LocalDate.fromDateTime(DateTime.utc(2026, 9, 21, 23)), LocalDate(2026, 9, 21));
      expect(LocalDate(2026, 9, 21).toDateTimeUtc(), DateTime.utc(2026, 9, 21));
      expect(LocalDate(2026, 9, 21).atTime(LocalTime(8, 0)), LocalDateTime.of(2026, 9, 21, 8));
    });

    test('comparisons', () {
      final a = LocalDate(2026, 1, 1);
      final b = LocalDate(2026, 1, 2);
      expect(a.isBefore(b) && b.isAfter(a) && a.isOnOrBefore(a) && b.isOnOrAfter(a), isTrue);
      expect(LocalDate.min(a, b), a);
      expect(LocalDate.max(a, b), b);
      expect(LocalDate(2026, 2, 1).compareTo(LocalDate(2026, 1, 31)), greaterThan(0));
      expect(LocalDate(2027, 1, 1).compareTo(LocalDate(2026, 12, 31)), greaterThan(0));
      expect(a.hashCode, LocalDate(2026, 1, 1).hashCode);
    });

    test('ISO parsing', () {
      expect(LocalDate.parse('2026-09-21'), LocalDate(2026, 9, 21));
      expect(LocalDate(2026, 9, 1).toString(), '2026-09-01');
      expect(LocalDate.fromEpochDay(-800000).toIso(), startsWith('-'));
      expect(LocalDate.tryParse('2026-02-30'), isNull);
      expect(LocalDate.tryParse('26-02-01'), isNull);
      expect(() => LocalDate.parse('nope'), throwsFormatException);
    });

    test('week helpers for every week start across year boundaries', () {
      expect(LocalDate(2026, 9, 23).startOfWeek(Weekday.monday), LocalDate(2026, 9, 21));
      expect(LocalDate(2026, 9, 23).startOfWeek(Weekday.sunday), LocalDate(2026, 9, 20));
      expect(LocalDate(2026, 9, 23).startOfWeek(Weekday.saturday), LocalDate(2026, 9, 19));
      // ISO: 2021-01-03 belongs to 2020-W53, 2024-12-30 to 2025-W01.
      expect(LocalDate(2021, 1, 3).isoWeek, (weekYear: 2020, week: 53));
      expect(LocalDate(2024, 12, 30).isoWeek, (weekYear: 2025, week: 1));
      for (var day = LocalDate(2019, 12, 1); day.isBefore(LocalDate(2027, 2, 1)); day = day.plusDays(1)) {
        expect(day.weekOfYear(Weekday.monday), day.isoWeek, reason: '$day');
      }
      expect(LocalDate(2026, 1, 1).weekOfYear(Weekday.sunday), (weekYear: 2025, week: 53));
      expect(LocalDate(2022, 1, 1).weekOfYear(Weekday.saturday), (weekYear: 2022, week: 1));
      expect(LocalDate.weeksInWeekYear(2020, Weekday.monday), 53);
      expect(LocalDate.weeksInWeekYear(2026, Weekday.monday), 53);
      expect(LocalDate.weeksInWeekYear(2025, Weekday.monday), 52);
      expect(LocalDate.firstDayOfWeekYear(2026, Weekday.sunday), LocalDate(2026, 1, 4));
    });
  });

  group('LocalTime', () {
    test('construction and parsing', () {
      expect(LocalTime(8, 5).toIso(), '08:05');
      expect(() => LocalTime(24, 0), throwsArgumentError);
      expect(() => LocalTime(1, 60), throwsArgumentError);
      expect(() => LocalTime.fromMinuteOfDay(1441), throwsArgumentError);
      expect(LocalTime.parse('24:00'), LocalTime.endOfDay);
      expect(LocalTime.parse('7:30:00'), LocalTime(7, 30));
      expect(LocalTime.tryParse('07:30:15'), isNull);
      expect(LocalTime.tryParse('25:00'), isNull);
      expect(LocalTime.tryParse('x'), isNull);
      expect(() => LocalTime.parse('x'), throwsFormatException);
      expect(LocalTime.endOfDay.isEndOfDay, isTrue);
      expect(LocalTime.noon.hour, 12);
    });

    test('arithmetic and comparisons', () {
      expect(LocalTime(23, 30).plusMinutesWrapped(45), LocalTime(0, 15));
      expect(LocalTime(0, 15).plusMinutesWrapped(-30), LocalTime(23, 45));
      expect(LocalTime(8, 0).isBefore(LocalTime(9, 0)), isTrue);
      expect(LocalTime(9, 0).isAfter(LocalTime(8, 0)), isTrue);
      expect(LocalTime(9, 0).compareTo(LocalTime(9, 0)), 0);
      expect(LocalTime(9, 0).hashCode, LocalTime(9, 0).hashCode);
      expect(LocalTime(9, 0).toString(), '09:00');
    });
  });

  group('LocalDateTime', () {
    test('construction, epoch minutes and 24:00 normalization', () {
      final d = LocalDateTime(LocalDate(2026, 9, 21), LocalTime.endOfDay);
      expect(d, LocalDateTime.of(2026, 9, 22));
      for (final minute in [-2000000, -1, 0, 1, 29000000]) {
        expect(LocalDateTime.fromEpochMinute(minute).epochMinute, minute);
      }
      expect(LocalDateTime.fromDateTime(DateTime.utc(2026, 9, 21, 8, 30, 59)), LocalDateTime.of(2026, 9, 21, 8, 30));
      final x = LocalDateTime.of(2026, 1, 31, 8, 15);
      expect(x.year + x.month + x.day + x.hour + x.minute, 2026 + 1 + 31 + 8 + 15);
    });

    test('arithmetic', () {
      final x = LocalDateTime.of(2026, 1, 31, 23, 30);
      expect(x.plusMinutes(0), same(x));
      expect(x.plusMinutes(45), LocalDateTime.of(2026, 2, 1, 0, 15));
      expect(x.plusHours(-24), LocalDateTime.of(2026, 1, 30, 23, 30));
      expect(x.plusDays(1), LocalDateTime.of(2026, 2, 1, 23, 30));
      expect(x.plusMonths(1), LocalDateTime.of(2026, 2, 28, 23, 30));
      expect(x.minutesUntil(LocalDateTime.of(2026, 2, 1)), 30);
      expect(x.withTime(LocalTime(6, 0)), LocalDateTime.of(2026, 1, 31, 6));
      expect(x.toDateTimeUtc(), DateTime.utc(2026, 1, 31, 23, 30));
    });

    test('comparisons and parsing', () {
      final a = LocalDateTime.of(2026, 1, 1, 8);
      final b = LocalDateTime.of(2026, 1, 1, 9);
      expect(a.isBefore(b) && b.isAfter(a) && a.isOnOrBefore(a) && b.isOnOrAfter(b), isTrue);
      expect(LocalDateTime.min(a, b), a);
      expect(LocalDateTime.max(a, b), b);
      expect(LocalDateTime.parse('2026-09-21 08:00'), LocalDateTime.of(2026, 9, 21, 8));
      expect(LocalDateTime.parse('2026-09-21T08:00:00.000'), LocalDateTime.of(2026, 9, 21, 8));
      expect(LocalDateTime.tryParse('2026-09-21T08:00:30'), isNull);
      expect(LocalDateTime.tryParse('2026-09-31T08:00'), isNull);
      expect(LocalDateTime.tryParse('2026-09-21T24:00'), isNull);
      expect(LocalDateTime.tryParse('2026-09-21'), isNull);
      expect(() => LocalDateTime.parse('bad'), throwsFormatException);
      expect(a.toString(), '2026-01-01T08:00');
      expect(a.hashCode, LocalDateTime.of(2026, 1, 1, 8).hashCode);
    });
  });

  group('Weekday', () {
    test('codes and ordering', () {
      expect(Weekday.fromIso(7), Weekday.sunday);
      expect(() => Weekday.fromIso(0), throwsArgumentError);
      expect(Weekday.fromCode('tu'), Weekday.tuesday);
      expect(() => Weekday.fromCode('XX'), throwsFormatException);
      expect(Weekday.monday.offsetFrom(Weekday.sunday), 1);
      expect(Weekday.ordered(Weekday.saturday).first, Weekday.saturday);
      expect(Weekday.ordered(Weekday.saturday).last, Weekday.friday);
      expect(Weekday.sunday.isWeekend && !Weekday.friday.isWeekend, isTrue);
    });
  });

  group('TzZoneResolver', () {
    final resolver = TzZoneResolver();

    ResolvedInstant r(String local, String zone) => resolver.resolve(LocalDateTime.parse(local), zone);

    test('exact, gap and overlap resolution', () {
      final exact = r('2026-07-01T12:00', 'Europe/Paris');
      expect(exact.utc, DateTime.utc(2026, 7, 1, 10));
      expect(exact.kind, ResolutionKind.exact);
      expect(exact.offsetMinutes, 120);

      final gap = r('2026-03-29T02:30', 'Europe/Paris');
      expect(gap.utc, DateTime.utc(2026, 3, 29, 1, 30));
      expect(gap.kind, ResolutionKind.shiftedForward);
      expect(gap.offsetMinutes, 120);

      final overlap = r('2026-11-01T01:30', 'America/New_York');
      expect(overlap.utc, DateTime.utc(2026, 11, 1, 5, 30));
      expect(overlap.kind, ResolutionKind.ambiguousEarlier);

      final lordHowe = r('2026-10-04T02:15', 'Australia/Lord_Howe');
      expect(lordHowe.kind, ResolutionKind.shiftedForward);
      expect(lordHowe.utc, DateTime.utc(2026, 10, 3, 15, 45));
    });

    test('fast path agrees with the full computation', () {
      final fresh = TzZoneResolver();
      final cached = TzZoneResolver();
      for (var m = 0; m < 60 * 24 * 40; m += 7) {
        final local = LocalDateTime.of(2026, 3, 1).plusMinutes(m);
        cached.resolve(local, 'Europe/Paris');
        final a = cached.resolve(local, 'Europe/Paris');
        final b = fresh.resolve(local, 'Europe/Paris');
        expect(a.utc, b.utc, reason: '$local');
        expect(a.kind, b.kind, reason: '$local');
      }
    });

    test('toLocal and offsets (UTC is built in)', () {
      expect(resolver.toLocal(DateTime.utc(2026, 3, 29, 1, 30), 'Europe/Paris'), LocalDateTime.of(2026, 3, 29, 3, 30));
      expect(resolver.toLocal(DateTime.utc(1969, 12, 31, 23, 59, 30), 'UTC'), LocalDateTime.of(1969, 12, 31, 23, 59));
      expect(resolver.offsetMinutesAt(DateTime.utc(2026, 1, 1), 'Pacific/Chatham'), 825);
      expect(r('2026-01-01T00:00', 'UTC').utc, DateTime.utc(2026));
    });
  });

  group('FixedOffsetZoneResolver', () {
    test('uses one offset everywhere', () {
      const resolver = FixedOffsetZoneResolver(60);
      final resolved = resolver.resolve(LocalDateTime.of(2026, 1, 1, 1), 'Any/Zone');
      expect(resolved.utc, DateTime.utc(2026));
      expect(resolved.kind, ResolutionKind.exact);
      expect(resolved.offsetMinutes, 60);
      expect(resolver.toLocal(DateTime.utc(2026), 'x'), LocalDateTime.of(2026, 1, 1, 1));
      expect(const FixedOffsetZoneResolver(-60).toLocal(DateTime.utc(1970, 1, 1, 0, 30), 'x'),
          LocalDateTime.of(1969, 12, 31, 23, 30));
      expect(resolver.offsetMinutesAt(DateTime.utc(2026), 'x'), 60);
    });
  });
}
