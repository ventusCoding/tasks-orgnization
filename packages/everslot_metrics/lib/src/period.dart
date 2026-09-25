/// Period model & comparisons (T6.1.05) plus zone/day-boundary helpers.
///
/// One model for every screen: a [StatsPeriod] resolves to an inclusive [DateRange] of local dates
/// (and to instants through [DayBoundaries]). Comparisons use the previous equivalent period, in
/// **to-date** mode while the current period is in progress (Mon–Wed vs Mon–Wed).
library;

import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:meta/meta.dart';

/// Converts between instants and wall-clock values for one zone.
///
/// The app adapts `everslot_recurrence`'s `ZoneResolver` (`toLocal(i, zone)` /
/// `resolve(l, zone).utc`) with [FunctionZoneClock]; tests use [FixedOffsetClock].
abstract interface class ZoneClock {
  LocalDateTime toLocal(DateTime instant);

  DateTime toInstant(LocalDateTime local);
}

/// A zone with a fixed UTC offset (tests, UTC).
final class const FixedOffsetClock([final int offsetMinutes = 0])
    implements ZoneClock {
  @override
  LocalDateTime toLocal(DateTime instant) {
    final ms = instant.toUtc().millisecondsSinceEpoch + offsetMinutes * 60000;
    return LocalDateTime.fromEpochMinute(_floorDiv(ms, 60000));
  }

  @override
  DateTime toInstant(LocalDateTime local) =>
      DateTime.fromMillisecondsSinceEpoch(
        (local.epochMinute - offsetMinutes) * 60000,
        isUtc: true,
      );
}

/// A [ZoneClock] built from two functions (adapter for a real zone database).
final class const FunctionZoneClock(
  final LocalDateTime Function(DateTime instant) toLocalFn,
  final DateTime Function(LocalDateTime local) toInstantFn,
) implements ZoneClock {
  @override
  LocalDateTime toLocal(DateTime instant) => toLocalFn(instant);

  @override
  DateTime toInstant(LocalDateTime local) => toInstantFn(local);
}

int _floorDiv(int a, int b) => a >= 0 ? a ~/ b : -((-a + b - 1) ~/ b);

/// Local-day boundaries in a zone with an optional day start (`habits.dayStartsAt`).
///
/// With `dayStartsAt = 04:00`, the local day D runs from D 04:00 to D+1 04:00, so an event at
/// 01:30 belongs to the previous date. Planner stats use civil midnight (the default).
final class const DayBoundaries(
  final ZoneClock clock, {
  final LocalTime dayStartsAt = LocalTime.midnight,
}) {
  /// The local (habit) date an [instant] belongs to.
  LocalDate dateOf(DateTime instant) =>
      clock.toLocal(instant).plusMinutes(-dayStartsAt.minuteOfDay).date;

  /// Instant at which [date] starts.
  DateTime startOf(LocalDate date) => clock.toInstant(date.atTime(dayStartsAt));

  /// Instant at which [date] ends (= start of the next date).
  DateTime endOf(LocalDate date) => startOf(date.plusDays(1));

  /// Length of [date] (23 h / 25 h on DST days).
  Duration lengthOf(LocalDate date) => endOf(date).difference(startOf(date));

  /// Minute of the (habit) day of [instant], counted from the day start (0 … 1439 on normal days).
  int minuteOfDay(DateTime instant) => clock
      .toLocal(instant)
      .plusMinutes(-dayStartsAt.minuteOfDay)
      .time
      .minuteOfDay;

  /// Instant range covering [range] (end exclusive).
  InstantRange instantsOf(DateRange range) =>
      InstantRange(startOf(range.start), endOf(range.end));
}

/// An inclusive range of local dates.
@immutable
final class const DateRange(final LocalDate start, final LocalDate end) {
  /// Number of dates in the range (inclusive).
  int get days => start.daysUntil(end) + 1;

  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  Iterable<LocalDate> get dates sync* {
    for (var d = start; !d.isAfter(end); d = d.plusDays(1)) {
      yield d;
    }
  }

  /// Intersection with [other], or null when disjoint.
  DateRange? intersect(DateRange other) {
    final s = LocalDate.max(start, other.start);
    final e = LocalDate.min(end, other.end);
    return s.isAfter(e) ? null : DateRange(s, e);
  }

  DateRange shiftDays(int days) =>
      DateRange(start.plusDays(days), end.plusDays(days));

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start..$end';
}

/// A half-open instant range `[start, end)`.
@immutable
final class const InstantRange(final DateTime start, final DateTime end) {
  Duration get duration => end.difference(start);

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);

  /// Overlap length with `[a, b)`.
  Duration overlap(DateTime a, DateTime b) {
    final s = a.isAfter(start) ? a : start;
    final e = b.isBefore(end) ? b : end;
    return e.isAfter(s) ? e.difference(s) : Duration.zero;
  }

  @override
  bool operator ==(Object other) =>
      other is InstantRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}

/// How a period is compared with the previous one.
enum CompareMode {
  /// While the current period is in progress, compare only the elapsed part (default).
  toDate,

  /// Compare full periods.
  fullPeriod,
}

/// A stats period (sealed). Resolve it with [StatsPeriod.resolve].
sealed class StatsPeriod {
  const new();

  const factory today() = TodayPeriod;
  const factory yesterday() = YesterdayPeriod;
  const factory thisWeek() = ThisWeekPeriod;
  const factory lastWeek() = LastWeekPeriod;
  const factory thisMonth() = ThisMonthPeriod;
  const factory lastMonth() = LastMonthPeriod;
  const factory thisQuarter() = ThisQuarterPeriod;
  const factory lastQuarter() = LastQuarterPeriod;
  const factory thisYear() = ThisYearPeriod;
  const factory lastYear() = LastYearPeriod;
  const factory rolling(int days) = RollingPeriod;
  const factory allTime() = AllTimePeriod;
  const factory custom(LocalDate from, LocalDate to) = CustomPeriod;

  /// Stable key for caching (`thisWeek`, `rolling:30`, `custom:2026-01-01..2026-01-31`).
  String get key;

  /// Resolves the period against [today] (the user's current local date).
  ResolvedPeriod resolve({
    required LocalDate today,
    Weekday weekStart = Weekday.monday,
    LocalDate? firstDataDate,
  }) {
    final range = _range(today, weekStart, firstDataDate);
    return ResolvedPeriod(this, range, today: today, unit: _unit);
  }

  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData);

  PeriodUnit get _unit;
}

/// Calendar unit of a period (drives the previous-period rule).
enum PeriodUnit { day, week, month, quarter, year, span }

LocalDate _quarterStart(LocalDate d) =>
    LocalDate(d.year, ((d.month - 1) ~/ 3) * 3 + 1, 1);

final class TodayPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'today';
  @override
  PeriodUnit get _unit => PeriodUnit.day;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) =>
      DateRange(today, today);
}

final class YesterdayPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'yesterday';
  @override
  PeriodUnit get _unit => PeriodUnit.day;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final y = today.minusDays(1);
    return DateRange(y, y);
  }
}

final class ThisWeekPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'thisWeek';
  @override
  PeriodUnit get _unit => PeriodUnit.week;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final s = today.startOfWeek(weekStart);
    return DateRange(s, s.plusDays(6));
  }
}

final class LastWeekPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'lastWeek';
  @override
  PeriodUnit get _unit => PeriodUnit.week;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final s = today.startOfWeek(weekStart).minusDays(7);
    return DateRange(s, s.plusDays(6));
  }
}

final class ThisMonthPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'thisMonth';
  @override
  PeriodUnit get _unit => PeriodUnit.month;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) =>
      DateRange(today.firstDayOfMonth, today.lastDayOfMonth);
}

final class LastMonthPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'lastMonth';
  @override
  PeriodUnit get _unit => PeriodUnit.month;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final s = today.firstDayOfMonth.plusMonths(-1);
    return DateRange(s, s.lastDayOfMonth);
  }
}

final class ThisQuarterPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'thisQuarter';
  @override
  PeriodUnit get _unit => PeriodUnit.quarter;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final s = _quarterStart(today);
    return DateRange(s, s.plusMonths(3).minusDays(1));
  }
}

final class LastQuarterPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'lastQuarter';
  @override
  PeriodUnit get _unit => PeriodUnit.quarter;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final s = _quarterStart(today).plusMonths(-3);
    return DateRange(s, s.plusMonths(3).minusDays(1));
  }
}

final class ThisYearPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'thisYear';
  @override
  PeriodUnit get _unit => PeriodUnit.year;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) =>
      DateRange(LocalDate(today.year, 1, 1), LocalDate(today.year, 12, 31));
}

final class LastYearPeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'lastYear';
  @override
  PeriodUnit get _unit => PeriodUnit.year;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) =>
      DateRange(
        LocalDate(today.year - 1, 1, 1),
        LocalDate(today.year - 1, 12, 31),
      );
}

/// The last [days] local dates, ending today (7, 28, 30, 90, 365 in the UI; any N ≥ 1 accepted).
final class RollingPeriod extends StatsPeriod {
  const new(this.days)
    : assert(days >= 1, 'a rolling period needs at least one day');

  final int days;

  @override
  String get key => 'rolling:$days';
  @override
  PeriodUnit get _unit => PeriodUnit.span;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) =>
      DateRange(today.minusDays(days - 1), today);
}

/// From the first data point of the scope (or today when there is none) to today.
final class AllTimePeriod extends StatsPeriod {
  const new();
  @override
  String get key => 'allTime';
  @override
  PeriodUnit get _unit => PeriodUnit.span;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) {
    final start = firstData == null || firstData.isAfter(today)
        ? today
        : firstData;
    return DateRange(start, today);
  }
}

/// A user-picked inclusive date range.
final class CustomPeriod extends StatsPeriod {
  const new(this.from, this.to);

  final LocalDate from;
  final LocalDate to;

  @override
  String get key => 'custom:$from..$to';
  @override
  PeriodUnit get _unit => PeriodUnit.span;
  @override
  DateRange _range(LocalDate today, Weekday weekStart, LocalDate? firstData) =>
      from.isAfter(to) ? DateRange(to, from) : DateRange(from, to);
}

/// A period resolved against "today".
@immutable
final class ResolvedPeriod {
  const new(this.period, this.range, {required this.today, required this.unit});

  final StatsPeriod period;

  /// Full inclusive range of the period.
  final DateRange range;

  final LocalDate today;

  /// Calendar unit of the period.
  final PeriodUnit unit;

  /// True when today lies inside the period and the period extends beyond today.
  bool get inProgress => range.contains(today) && range.end.isAfter(today);

  /// The part of the period up to and including today ("to date").
  DateRange get toDate => inProgress ? DateRange(range.start, today) : range;

  /// Number of elapsed dates in the period (including today when in progress).
  int get elapsedDays => toDate.days;

  /// The previous equivalent period: the previous calendar day/week/month/quarter/year, or the N
  /// days immediately before a rolling/custom/all-time range. In [CompareMode.toDate] (default) and
  /// while the period is in progress, the previous period is clipped to the same number of elapsed
  /// days (clamped to its own length), so a partial period is never compared with a full one.
  DateRange previous({CompareMode mode = CompareMode.toDate}) {
    final DateRange full;
    switch (unit) {
      case PeriodUnit.day:
        full = range.shiftDays(-1);
      case PeriodUnit.week:
        full = range.shiftDays(-7);
      case PeriodUnit.month:
        final s = range.start.plusMonths(-1);
        full = DateRange(s, s.lastDayOfMonth);
      case PeriodUnit.quarter:
        final s = range.start.plusMonths(-3);
        full = DateRange(s, s.plusMonths(3).minusDays(1));
      case PeriodUnit.year:
        final s = LocalDate(range.start.year - 1, 1, 1);
        full = DateRange(s, LocalDate(s.year, 12, 31));
      case PeriodUnit.span:
        return range.shiftDays(-range.days);
    }
    if (mode == CompareMode.toDate && inProgress) {
      // Days and weeks compare the same number of elapsed days (Mon–Wed vs Mon–Wed); months,
      // quarters and years compare up to the same calendar date (clamped to the period's end,
      // e.g. YTD to Feb 29 vs YTD to Feb 28).
      final end = switch (unit) {
        PeriodUnit.month => today.plusMonths(-1),
        PeriodUnit.quarter => today.plusMonths(-3),
        PeriodUnit.year => today.plusYears(-1),
        _ => full.start.plusDays(elapsedDays - 1),
      };
      return DateRange(full.start, LocalDate.min(end, full.end));
    }
    return full;
  }

  /// Same period one year earlier (P1). Feb 29 maps to Feb 28.
  DateRange yearOverYear({CompareMode mode = CompareMode.toDate}) {
    final base = mode == CompareMode.toDate ? toDate : range;
    return DateRange(base.start.plusYears(-1), base.end.plusYears(-1));
  }

  /// Bucket size chosen automatically for the full range.
  Granularity get autoGranularity => autoGranularityFor(range);
}

/// Auto granularity: ≤ 14 days → daily, ≤ 120 days → weekly, ≤ 2 years (731 days) → monthly,
/// otherwise quarterly.
Granularity autoGranularityFor(DateRange range) {
  final d = range.days;
  if (d <= 14) return Granularity.day;
  if (d <= 120) return Granularity.week;
  if (d <= 731) return Granularity.month;
  return Granularity.quarter;
}
