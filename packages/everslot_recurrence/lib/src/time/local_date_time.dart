import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_time.dart';
import 'package:meta/meta.dart';

/// A wall-clock date and time with minute precision, without a zone.
///
/// Arithmetic is pure calendar arithmetic (no DST); zones are applied only when
/// resolving to an instant via a `ZoneResolver`.
@immutable
final class LocalDateTime implements Comparable<LocalDateTime> {
  factory(LocalDate date, LocalTime time) {
    if (time.isEndOfDay) {
      return LocalDateTime._(date.plusDays(1), LocalTime.midnight);
    }
    return LocalDateTime._(date, time);
  }

  factory of(int year, int month, int day, [int hour = 0, int minute = 0]) =>
      LocalDateTime._(LocalDate(year, month, day), LocalTime(hour, minute));

  /// Minutes since 1970-01-01T00:00 (wall clock).
  factory fromEpochMinute(int epochMinute) {
    final day = epochMinute >= 0
        ? epochMinute ~/ 1440
        : -((-epochMinute + 1439) ~/ 1440);
    final minute = epochMinute - day * 1440;
    return LocalDateTime._(
      LocalDate.fromEpochDay(day),
      LocalTime.fromMinuteOfDay(minute),
    );
  }

  /// The wall-clock fields of [dateTime] (seconds truncated; zone ignored).
  factory fromDateTime(DateTime dateTime) => LocalDateTime._(
    LocalDate.fromDateTime(dateTime),
    LocalTime(dateTime.hour, dateTime.minute),
  );

  const new _(this.date, this.time);

  final LocalDate date;
  final LocalTime time;

  int get year => date.year;
  int get month => date.month;
  int get day => date.day;
  int get hour => time.hour;
  int get minute => time.minute;

  /// Minutes since 1970-01-01T00:00 (wall clock).
  int get epochMinute => date.epochDay * 1440 + time.minuteOfDay;

  LocalDateTime plusMinutes(int minutes) => minutes == 0
      ? this
      : LocalDateTime.fromEpochMinute(epochMinute + minutes);

  LocalDateTime plusHours(int hours) => plusMinutes(hours * 60);

  LocalDateTime plusDays(int days) =>
      LocalDateTime._(date.plusDays(days), time);

  LocalDateTime plusMonths(int months) =>
      LocalDateTime._(date.plusMonths(months), time);

  /// Signed minutes from this to [other] (wall clock).
  int minutesUntil(LocalDateTime other) => other.epochMinute - epochMinute;

  LocalDateTime withTime(LocalTime newTime) => LocalDateTime(date, newTime);

  /// Treats the wall-clock value as UTC (useful for formatting only).
  DateTime toDateTimeUtc() =>
      DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);

  bool isBefore(LocalDateTime other) => compareTo(other) < 0;
  bool isAfter(LocalDateTime other) => compareTo(other) > 0;
  bool isOnOrBefore(LocalDateTime other) => compareTo(other) <= 0;
  bool isOnOrAfter(LocalDateTime other) => compareTo(other) >= 0;

  static LocalDateTime min(LocalDateTime a, LocalDateTime b) =>
      a.isBefore(b) ? a : b;
  static LocalDateTime max(LocalDateTime a, LocalDateTime b) =>
      a.isAfter(b) ? a : b;

  /// `YYYY-MM-DDTHH:mm` — also the canonical occurrence-key format.
  String toIso() => '${date.toIso()}T${time.toIso()}';

  static final RegExp _iso = RegExp(
    r'^(-?\d{4,}-\d{2}-\d{2})[T ](\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?)$',
  );

  static LocalDateTime parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException(
        'Invalid local date-time (expected YYYY-MM-DDTHH:mm)',
        input,
      );
    }
    return result;
  }

  static LocalDateTime? tryParse(String input) {
    final m = _iso.firstMatch(input.trim());
    if (m == null) return null;
    final date = LocalDate.tryParse(m.group(1)!);
    if (date == null) return null;
    var timePart = m.group(2)!;
    if (timePart.length > 5) {
      final seconds = timePart.substring(6);
      if (double.tryParse(seconds) != 0) return null;
      timePart = timePart.substring(0, 5);
    }
    final time = LocalTime.tryParse(timePart);
    if (time == null || time.isEndOfDay) return null;
    return LocalDateTime._(date, time);
  }

  @override
  int compareTo(LocalDateTime other) {
    final c = date.compareTo(other.date);
    return c != 0 ? c : time.compareTo(other.time);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDateTime && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => toIso();
}
