import 'package:meta/meta.dart';

/// A wall-clock time with minute precision.
///
/// Valid values are 00:00 … 23:59. The special value [endOfDay] (24:00) is only
/// meaningful as the exclusive/inclusive end of a daily window.
@immutable
final class LocalTime implements Comparable<LocalTime> {
  factory(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be 0..23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be 0..59');
    }
    return LocalTime._(hour * 60 + minute);
  }

  /// 0..1439, or 1440 for [endOfDay].
  factory fromMinuteOfDay(int minuteOfDay) {
    if (minuteOfDay < 0 || minuteOfDay > 1440) {
      throw ArgumentError.value(minuteOfDay, 'minuteOfDay', 'must be 0..1440');
    }
    return LocalTime._(minuteOfDay);
  }

  const new _(this.minuteOfDay);

  static const LocalTime midnight = LocalTime._(0);
  static const LocalTime noon = LocalTime._(720);

  /// 24:00 — end of the day (only for window ends).
  static const LocalTime endOfDay = LocalTime._(1440);

  /// Minutes since midnight (0..1440).
  final int minuteOfDay;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;
  bool get isEndOfDay => minuteOfDay == 1440;

  /// Adds minutes, wrapping around midnight (never produces 24:00).
  LocalTime plusMinutesWrapped(int minutes) =>
      LocalTime._(((minuteOfDay + minutes) % 1440 + 1440) % 1440);

  /// `HH:mm` (24-hour).
  String toIso() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static final RegExp _iso = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  /// Parses `HH:mm` (seconds are accepted but must be 00). `24:00` → [endOfDay].
  static LocalTime parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Invalid local time (expected HH:mm)', input);
    }
    return result;
  }

  static LocalTime? tryParse(String input) {
    final m = _iso.firstMatch(input.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final sec = m.group(3) == null ? 0 : int.parse(m.group(3)!);
    if (sec != 0) return null;
    if (h == 24 && min == 0) return endOfDay;
    if (h > 23 || min > 59) return null;
    return LocalTime._(h * 60 + min);
  }

  bool isBefore(LocalTime other) => minuteOfDay < other.minuteOfDay;
  bool isAfter(LocalTime other) => minuteOfDay > other.minuteOfDay;

  @override
  int compareTo(LocalTime other) => minuteOfDay.compareTo(other.minuteOfDay);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.minuteOfDay == minuteOfDay;

  @override
  int get hashCode => minuteOfDay.hashCode;

  @override
  String toString() => toIso();
}
