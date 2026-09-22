import 'package:everslot_recurrence/everslot_recurrence.dart';

/// "Now" and "today" helpers honouring the user's zone and `dayStartsAt` (arch §9.1).
abstract final class DayUtils {
  /// Wall-clock now in [zoneId].
  static LocalDateTime nowLocal(DateTime nowUtc, String zoneId, ZoneResolver resolver) =>
      resolver.toLocal(nowUtc, zoneId);

  /// The *logical* day: before [dayStartMinutes] (e.g. 240 = 04:00) it is still "yesterday".
  static LocalDate logicalToday(
    DateTime nowUtc,
    String zoneId,
    ZoneResolver resolver, {
    int dayStartMinutes = 0,
  }) {
    final local = resolver.toLocal(nowUtc, zoneId);
    return local.time.minuteOfDay < dayStartMinutes ? local.date.minusDays(1) : local.date;
  }

  /// Logical date of a local wall-clock moment.
  static LocalDate logicalDateOf(LocalDateTime local, {int dayStartMinutes = 0}) =>
      local.time.minuteOfDay < dayStartMinutes ? local.date.minusDays(1) : local.date;

  /// UTC instant of the start of [date] (at [dayStartMinutes]) in [zoneId].
  static DateTime startOfDayUtc(
    LocalDate date,
    String zoneId,
    ZoneResolver resolver, {
    int dayStartMinutes = 0,
  }) => resolver
      .resolve(date.atTime(LocalTime.fromMinuteOfDay(dayStartMinutes)), zoneId)
      .utc;

  /// Days of the week containing [date] for [weekStart].
  static List<LocalDate> weekOf(LocalDate date, Weekday weekStart) {
    final start = date.startOfWeek(weekStart);
    return [for (var i = 0; i < 7; i++) start.plusDays(i)];
  }
}
