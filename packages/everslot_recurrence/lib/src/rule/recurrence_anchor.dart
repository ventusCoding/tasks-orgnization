import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:meta/meta.dart';

/// Where a series starts: the owner's wall-clock start plus its zone.
///
/// A null [zoneId] means *floating*: the wall-clock values are resolved in the
/// zone supplied at evaluation time (the user's current zone).
@immutable
final class RecurrenceAnchor {
  const new(
    this.start,
    this.zoneId, {
    this.durationMinutes,
    this.allDay = false,
  });

  /// An all-day anchor on [date] (time of day ignored; keys are `YYYY-MM-DD`).
  factory allDayOn(LocalDate date, String? zoneId, {int days = 1}) =>
      RecurrenceAnchor(
        date.atStartOfDay,
        zoneId,
        durationMinutes: days * 1440,
        allDay: true,
      );

  /// Local start of the series (the first possible occurrence).
  final LocalDateTime start;

  /// IANA zone, or null for floating.
  final String? zoneId;

  /// Default duration of each occurrence (minutes); null = 0 (1 day when [allDay]).
  final int? durationMinutes;

  /// Whether occurrences are whole days.
  final bool allDay;

  /// True when [zoneId] is null.
  bool get isFloating => zoneId == null;

  /// Effective duration in minutes (all-day series default to one day).
  int get effectiveDurationMinutes => durationMinutes ?? (allDay ? 1440 : 0);

  RecurrenceAnchor copyWith({
    LocalDateTime? start,
    Object? zoneId = _unset,
    Object? durationMinutes = _unset,
    bool? allDay,
  }) => RecurrenceAnchor(
    start ?? this.start,
    identical(zoneId, _unset) ? this.zoneId : zoneId as String?,
    durationMinutes: identical(durationMinutes, _unset)
        ? this.durationMinutes
        : durationMinutes as int?,
    allDay: allDay ?? this.allDay,
  );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceAnchor &&
      other.start == start &&
      other.zoneId == zoneId &&
      other.durationMinutes == durationMinutes &&
      other.allDay == allDay;

  @override
  int get hashCode => Object.hash(start, zoneId, durationMinutes, allDay);

  @override
  String toString() =>
      'RecurrenceAnchor(${allDay ? start.date : start}, ${zoneId ?? 'floating'}'
      '${durationMinutes == null ? '' : ', ${durationMinutes}min'})';
}

const Object _unset = Object();
