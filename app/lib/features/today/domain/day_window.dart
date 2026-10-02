import 'package:everslot/core/time/day_utils.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// The logical day Today shows (arch §9.1): the user's day starts at `dayStartsAt` (default
/// midnight), so at 01:00 with a 04:00 day start it is still "yesterday".
@immutable
class DayWindow {
  const DayWindow({
    required this.date,
    required this.zone,
    required this.startUtc,
    required this.endUtc,
    this.dayStartMinutes = 0,
  });

  /// Window of the logical day containing [nowUtc] in [zone].
  factory DayWindow.at(DateTime nowUtc, String zone, ZoneResolver zones, {int dayStartMinutes = 0}) {
    final date = DayUtils.logicalToday(nowUtc, zone, zones, dayStartMinutes: dayStartMinutes);
    return DayWindow.of(date, zone, zones, dayStartMinutes: dayStartMinutes);
  }

  /// Window of the logical [date] in [zone].
  factory DayWindow.of(LocalDate date, String zone, ZoneResolver zones, {int dayStartMinutes = 0}) => DayWindow(
    date: date,
    zone: zone,
    dayStartMinutes: dayStartMinutes,
    startUtc: DayUtils.startOfDayUtc(date, zone, zones, dayStartMinutes: dayStartMinutes),
    endUtc: DayUtils.startOfDayUtc(date.plusDays(1), zone, zones, dayStartMinutes: dayStartMinutes),
  );

  /// Logical date.
  final LocalDate date;

  /// IANA zone the window was computed in (the device zone).
  final String zone;
  final int dayStartMinutes;

  /// First instant of the logical day.
  final DateTime startUtc;

  /// First instant of the next logical day (exclusive) — the next day boundary.
  final DateTime endUtc;

  /// Wall-clock start of the window.
  LocalDateTime get startLocal => date.atTime(LocalTime.fromMinuteOfDay(dayStartMinutes));

  /// Wall-clock end of the window (exclusive).
  LocalDateTime get endLocal => date.plusDays(1).atTime(LocalTime.fromMinuteOfDay(dayStartMinutes));

  bool contains(DateTime instant) => !instant.isBefore(startUtc) && instant.isBefore(endUtc);

  @override
  bool operator ==(Object other) =>
      other is DayWindow &&
      other.date == date &&
      other.zone == zone &&
      other.dayStartMinutes == dayStartMinutes &&
      other.startUtc == startUtc &&
      other.endUtc == endUtc;

  @override
  int get hashCode => Object.hash(date, zone, dayStartMinutes, startUtc, endUtc);

  @override
  String toString() => 'DayWindow($date $zone, $startUtc → $endUtc)';
}

/// Time until the next day boundary after [nowUtc] (never negative; a boundary that is "now"
/// already belongs to the new day, so the next one is returned).
Duration untilNextBoundary(DateTime nowUtc, String zone, ZoneResolver zones, {int dayStartMinutes = 0}) {
  final window = DayWindow.at(nowUtc, zone, zones, dayStartMinutes: dayStartMinutes);
  final left = window.endUtc.difference(nowUtc);
  return left.isNegative ? Duration.zero : left;
}
