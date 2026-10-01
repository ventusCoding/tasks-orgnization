import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/zone_resolver.dart';
import 'package:meta/meta.dart';

/// One concrete occurrence of a series.
@immutable
final class Occurrence {
  const new({
    required this.key,
    required this.startLocal,
    required this.startUtc,
    required this.endUtc,
    required this.isAllDay,
    required this.resolutionKind,
    required this.zoneId,
  });

  /// Stable identity (arch §6.8): `YYYY-MM-DDTHH:mm` (original local start),
  /// `YYYY-MM-DD` for all-day series, `<period>#<n>` for quota slots
  /// (e.g. `week:2026-09-21#2`). Never changes when an occurrence is moved.
  final String key;

  /// Original wall-clock start in [zoneId].
  final LocalDateTime startLocal;

  /// Resolved start instant (UTC).
  final DateTime startUtc;

  /// End instant (UTC): start + duration (all-day: midnight after the last day).
  final DateTime endUtc;

  final bool isAllDay;

  /// How [startLocal] was resolved (exact, shifted out of a DST gap, earlier of two).
  final ResolutionKind resolutionKind;

  /// Zone used for resolution (the anchor's zone, or the evaluation zone when floating).
  final String zoneId;

  /// Calendar date of the original start.
  LocalDate get date => startLocal.date;

  /// Duration between [startUtc] and [endUtc].
  Duration get duration => endUtc.difference(startUtc);

  @override
  bool operator ==(Object other) =>
      other is Occurrence &&
      other.key == key &&
      other.startLocal == startLocal &&
      other.startUtc == startUtc &&
      other.endUtc == endUtc &&
      other.isAllDay == isAllDay &&
      other.resolutionKind == resolutionKind &&
      other.zoneId == zoneId;

  @override
  int get hashCode => Object.hash(key, startLocal, startUtc, endUtc, isAllDay, resolutionKind, zoneId);

  @override
  String toString() => 'Occurrence($key @ ${startUtc.toIso8601String()} $zoneId)';
}

/// One quota period (a week, a month…) with its pro-rated target.
@immutable
final class Period {
  const new({
    required this.key,
    required this.unit,
    required this.startDate,
    required this.endDate,
    required this.activeStart,
    required this.activeEnd,
    required this.timesPerPeriod,
    required this.eligibleDays,
    required this.periodDays,
  });

  /// `day:YYYY-MM-DD`, `week:YYYY-MM-DD` (first day of the week),
  /// `month:YYYY-MM` or `year:YYYY`.
  final String key;

  final PeriodUnit unit;

  /// First day of the full period.
  final LocalDate startDate;

  /// Last day of the full period (inclusive).
  final LocalDate endDate;

  /// First day the series is active in this period (≥ [startDate]).
  final LocalDate activeStart;

  /// Last day the series is active in this period (≤ [endDate]).
  final LocalDate activeEnd;

  /// The rule's N for a full period.
  final int timesPerPeriod;

  /// Eligible days in the active part (weekday filter, minus excluded days).
  final int eligibleDays;

  /// Eligible days in the full period (weekday filter only).
  final int periodDays;

  /// Expected completions: `N · eligibleDays / periodDays` (exact, for rates).
  double get target => periodDays == 0 ? 0 : timesPerPeriod * eligibleDays / periodDays;

  /// [target] rounded up for display and for planner slots.
  int get requiredCount {
    final t = target;
    final rounded = t.roundToDouble();
    if ((t - rounded).abs() < 1e-9) return rounded.toInt();
    return t.ceil();
  }

  /// Whether the period is pro-rated (series start/end, excluded days).
  bool get isPartial => eligibleDays < periodDays;

  /// Key of the [n]-th required completion (`week:2026-09-21#2`).
  String completionKey(int n) => '$key#$n';

  @override
  bool operator ==(Object other) =>
      other is Period &&
      other.key == key &&
      other.unit == unit &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.activeStart == activeStart &&
      other.activeEnd == activeEnd &&
      other.timesPerPeriod == timesPerPeriod &&
      other.eligibleDays == eligibleDays &&
      other.periodDays == periodDays;

  @override
  int get hashCode =>
      Object.hash(key, unit, startDate, endDate, activeStart, activeEnd, timesPerPeriod, eligibleDays, periodDays);

  @override
  String toString() => 'Period($key, target ${target.toStringAsFixed(3)}, $eligibleDays/$periodDays days)';
}
