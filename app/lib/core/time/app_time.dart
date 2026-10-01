import 'package:everslot/core/time/clock.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// A span of whole local days, both ends included ("this week", a stats range).
class LocalDateRange {
  LocalDateRange(this.start, this.end) : assert(!end.isBefore(start), 'end before start');

  final LocalDate start;
  final LocalDate end;

  int get dayCount => start.daysUntil(end) + 1;

  List<LocalDate> get days => [for (var i = 0; i < dayCount; i++) start.plusDays(i)];

  bool contains(LocalDate date) => date.isOnOrAfter(start) && date.isOnOrBefore(end);

  @override
  bool operator ==(Object other) => other is LocalDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start..$end';
}

/// The app's one source for "now", "today" and "this week" (T2.3.07, arch §9.1): the injected
/// [Clock], the user's current zone, the logical day start (`dayStartsAt`, e.g. 04:00 → 03:59 is
/// still yesterday) and the profile's week start. Pure, so isolates and tests use it as-is.
class AppTime {
  const AppTime({
    required this.clock,
    required this.resolver,
    required this.zone,
    this.dayStartMinutes = 0,
    this.weekStart = Weekday.monday,
  });

  final Clock clock;
  final ZoneResolver resolver;

  /// IANA id of the zone the user is in now.
  final String zone;

  /// Minute of the day at which a logical day begins (0 = midnight).
  final int dayStartMinutes;
  final Weekday weekStart;

  DateTime nowUtc() => clock.nowUtc();

  /// Wall-clock now in [zone].
  LocalDateTime nowLocal() => resolver.toLocal(clock.nowUtc(), zone);

  /// Calendar date in [zone] (ignores the day start: the planner's "today").
  LocalDate calendarToday() => nowLocal().date;

  /// Logical today: before the day start it is still the previous date.
  LocalDate today() => logicalDateOf(nowLocal());

  LocalDate logicalDateOf(LocalDateTime local) =>
      local.time.minuteOfDay < dayStartMinutes ? local.date.minusDays(1) : local.date;

  /// Logical date of an instant in [zone].
  LocalDate logicalDateAt(DateTime instant) => logicalDateOf(resolver.toLocal(instant, zone));

  bool isToday(LocalDate date) => date == today();

  /// The week (per [weekStart]) containing [date] — logical today by default.
  LocalDateRange weekOf([LocalDate? date]) {
    final start = (date ?? today()).startOfWeek(weekStart);
    return LocalDateRange(start, start.plusDays(6));
  }

  LocalDateRange thisWeek() => weekOf();

  /// The calendar month containing [date] — logical today by default.
  LocalDateRange monthOf([LocalDate? date]) {
    final d = date ?? today();
    return LocalDateRange(d.firstDayOfMonth, d.lastDayOfMonth);
  }

  /// UTC instants bounding the logical day [date]: `[start, end)`. 23 or 25 hours on DST days.
  ({DateTime start, DateTime end}) dayBoundsUtc(LocalDate date) =>
      (start: startOfDayUtc(date), end: startOfDayUtc(date.plusDays(1)));

  DateTime startOfDayUtc(LocalDate date) =>
      resolver.resolve(date.atTime(LocalTime.fromMinuteOfDay(dayStartMinutes)), zone).utc;

  /// Instant → wall clock in [zoneId] (the current zone by default).
  LocalDateTime toLocal(DateTime instant, [String? zoneId]) => resolver.toLocal(instant, zoneId ?? zone);

  /// Wall clock → instant. A fixed value carries its own zone; a floating one (null [zoneId])
  /// follows the user and resolves in the current zone. DST gaps shift forward, overlaps take the
  /// earlier instant (arch §9.1).
  DateTime toInstant(LocalDateTime local, [String? zoneId]) => resolver.resolve(local, zoneId ?? zone).utc;

  AppTime copyWith({Clock? clock, String? zone, int? dayStartMinutes, Weekday? weekStart}) => AppTime(
    clock: clock ?? this.clock,
    resolver: resolver,
    zone: zone ?? this.zone,
    dayStartMinutes: dayStartMinutes ?? this.dayStartMinutes,
    weekStart: weekStart ?? this.weekStart,
  );
}
