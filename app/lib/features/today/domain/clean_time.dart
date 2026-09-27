import 'package:meta/meta.dart';

/// A clean-time counter split into days, hours, minutes and seconds (T8.1.07).
///
/// Computed from two UTC instants, so it is the real elapsed time: a DST switch neither freezes
/// nor jumps the counter, and backgrounding the app loses nothing (the next tick recomputes it).
@immutable
class CleanTime {
  const CleanTime(this.days, this.hours, this.minutes, this.seconds);

  factory CleanTime.of(Duration elapsed) {
    final d = elapsed.isNegative ? Duration.zero : elapsed;
    return CleanTime(d.inDays, d.inHours % 24, d.inMinutes % 60, d.inSeconds % 60);
  }

  /// Time elapsed from [start] to [now] (zero when [start] is in the future).
  factory CleanTime.between(DateTime start, DateTime now) => CleanTime.of(now.toUtc().difference(start.toUtc()));

  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  Duration get duration => Duration(days: days, hours: hours, minutes: minutes, seconds: seconds);

  /// "3d 04:12:09" / "04:12:09" (digits only; units are localized by the UI).
  String get compact {
    String two(int v) => v.toString().padLeft(2, '0');
    final clock = '${two(hours)}:${two(minutes)}:${two(seconds)}';
    return days > 0 ? '${days}d $clock' : clock;
  }

  @override
  bool operator ==(Object other) =>
      other is CleanTime && other.days == days && other.hours == hours && other.minutes == minutes && other.seconds == seconds;

  @override
  int get hashCode => Object.hash(days, hours, minutes, seconds);

  @override
  String toString() => 'CleanTime($compact)';
}
