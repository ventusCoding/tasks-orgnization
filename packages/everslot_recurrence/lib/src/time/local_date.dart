import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/local_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';
import 'package:meta/meta.dart';

/// What to do when month arithmetic lands on a day that doesn't exist (e.g. Feb 30).
enum MonthOverflow {
  /// Use the last valid day of the target month (Jan 31 + 1 month = Feb 28/29).
  clamp,

  /// Signal that the date doesn't exist (the caller skips it); `plusMonths` returns null.
  skip,
}

/// A calendar date without time or zone (proleptic Gregorian).
@immutable
final class LocalDate implements Comparable<LocalDate> {
  factory(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1..12');
    }
    final dim = daysInMonth(year, month);
    if (day < 1 || day > dim) {
      throw ArgumentError.value(day, 'day', 'must be 1..$dim for $year-$month');
    }
    return LocalDate._(year, month, day);
  }

  const new _(this.year, this.month, this.day);

  /// Days since 1970-01-01 (can be negative).
  factory fromEpochDay(int epochDay) {
    // Howard Hinnant's civil_from_days.
    final z = epochDay + 719468;
    final era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final doe = z - era * 146097;
    final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
    final y = yoe + era * 400;
    final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
    final mp = (5 * doy + 2) ~/ 153;
    final d = doy - (153 * mp + 2) ~/ 5 + 1;
    final m = mp < 10 ? mp + 3 : mp - 9;
    return LocalDate._(m <= 2 ? y + 1 : y, m, d);
  }

  /// The calendar date of [dateTime] (its own year/month/day fields, zone ignored).
  factory fromDateTime(DateTime dateTime) => LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  /// Returns null when the combination is not a valid date.
  static LocalDate? tryCreate(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > daysInMonth(year, month)) return null;
    return LocalDate._(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return days[month - 1];
  }

  static int daysInYear(int year) => isLeapYear(year) ? 366 : 365;

  /// Days since 1970-01-01.
  int get epochDay {
    // Howard Hinnant's days_from_civil.
    final y = month <= 2 ? year - 1 : year;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yoe = y - era * 400;
    final mp = month > 2 ? month - 3 : month + 9;
    final doy = (153 * mp + 2) ~/ 5 + day - 1;
    final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
    return era * 146097 + doe - 719468;
  }

  Weekday get weekday => Weekday.fromIso(((epochDay + 3) % 7 + 7) % 7 + 1);

  /// 1-based day of the year.
  int get dayOfYear => epochDay - LocalDate._(year, 1, 1).epochDay + 1;

  LocalDate plusDays(int days) => days == 0 ? this : LocalDate.fromEpochDay(epochDay + days);

  LocalDate minusDays(int days) => plusDays(-days);

  /// Adds calendar months. With [MonthOverflow.skip] returns null when the day doesn't exist.
  LocalDate? plusMonthsOrNull(int months, {MonthOverflow overflow = MonthOverflow.clamp}) {
    final total = year * 12 + (month - 1) + months;
    final y = total >= 0 ? total ~/ 12 : -((-total + 11) ~/ 12);
    final m = total - y * 12 + 1;
    final dim = daysInMonth(y, m);
    if (day > dim) {
      return overflow == MonthOverflow.clamp ? LocalDate._(y, m, dim) : null;
    }
    return LocalDate._(y, m, day);
  }

  /// Adds calendar months, clamping to the last day of the target month.
  LocalDate plusMonths(int months) => plusMonthsOrNull(months)!;

  LocalDate plusYears(int years) => plusMonths(years * 12);

  /// Signed number of days from this date to [other].
  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  /// First day of the week containing this date, for the given [weekStart].
  LocalDate startOfWeek(Weekday weekStart) => minusDays(weekday.offsetFrom(weekStart));

  LocalDate get firstDayOfMonth => LocalDate._(year, month, 1);

  LocalDate get lastDayOfMonth => LocalDate._(year, month, daysInMonth(year, month));

  /// ISO-8601 week-based year and week number (weeks start on Monday, week 1 contains Jan 4).
  ({int weekYear, int week}) get isoWeek {
    final thursday = plusDays(4 - weekday.iso);
    final weekYear = thursday.year;
    final week = (thursday.dayOfYear - 1) ~/ 7 + 1;
    return (weekYear: weekYear, week: week);
  }

  /// Week-based year and week number for weeks starting on [weekStart].
  ///
  /// Generalizes the ISO-8601 rule to any week start (RFC 5545 `WKST`): week 1
  /// is the first week with at least four days in the year, i.e. the week that
  /// contains 4 January. With [Weekday.monday] this equals [isoWeek].
  ({int weekYear, int week}) weekOfYear(Weekday weekStart) {
    final start = startOfWeek(weekStart);
    var weekYear = year;
    final nextFirst = LocalDate.firstDayOfWeekYear(year + 1, weekStart);
    if (!start.isBefore(nextFirst)) {
      weekYear = year + 1;
    } else if (start.isBefore(LocalDate.firstDayOfWeekYear(year, weekStart))) {
      weekYear = year - 1;
    }
    final first = LocalDate.firstDayOfWeekYear(weekYear, weekStart);
    return (weekYear: weekYear, week: first.daysUntil(start) ~/ 7 + 1);
  }

  /// First day of week 1 of [weekYear] for weeks starting on [weekStart].
  factory firstDayOfWeekYear(int weekYear, Weekday weekStart) => LocalDate._(weekYear, 1, 4).startOfWeek(weekStart);

  /// Number of weeks (52 or 53) in [weekYear] for weeks starting on [weekStart].
  static int weeksInWeekYear(int weekYear, Weekday weekStart) =>
      LocalDate.firstDayOfWeekYear(
        weekYear,
        weekStart,
      ).daysUntil(LocalDate.firstDayOfWeekYear(weekYear + 1, weekStart)) ~/
      7;

  LocalDateTime atTime(LocalTime time) => LocalDateTime(this, time);

  LocalDateTime get atStartOfDay => LocalDateTime(this, LocalTime.midnight);

  /// UTC midnight of this date as a [DateTime] (handy for formatting with intl).
  DateTime toDateTimeUtc() => DateTime.utc(year, month, day);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;
  bool isOnOrBefore(LocalDate other) => compareTo(other) <= 0;
  bool isOnOrAfter(LocalDate other) => compareTo(other) >= 0;

  static LocalDate min(LocalDate a, LocalDate b) => a.isBefore(b) ? a : b;
  static LocalDate max(LocalDate a, LocalDate b) => a.isAfter(b) ? a : b;

  /// `YYYY-MM-DD`.
  String toIso() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';

  static final RegExp _iso = RegExp(r'^(-?\d{4,})-(\d{2})-(\d{2})$');

  static LocalDate parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Invalid local date (expected YYYY-MM-DD)', input);
    }
    return result;
  }

  static LocalDate? tryParse(String input) {
    final m = _iso.firstMatch(input.trim());
    if (m == null) return null;
    return tryCreate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

String _pad(int value, int width) {
  final negative = value < 0;
  final s = value.abs().toString().padLeft(width, '0');
  return negative ? '-$s' : s;
}
