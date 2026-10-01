import 'package:everslot_recurrence/src/rule/json_read.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';
import 'package:meta/meta.dart';

/// A `BYDAY` entry: a weekday, optionally with an ordinal ([n] = 2 → 2nd, -1 → last).
///
/// Ordinals are only meaningful for monthly and yearly rules.
@immutable
final class WeekdayRule {
  const new(this.day, [this.n]);

  /// Decodes `{"day": "MO", "n": 2}`.
  factory fromJson(Object? json) {
    final map = readMap(json, 'byWeekday[]');
    final code = map['day'];
    if (code is! String) {
      throw FormatException('byWeekday[].day must be a weekday code', json);
    }
    final Weekday day;
    try {
      day = Weekday.fromCode(code);
    } on FormatException {
      throw FormatException('Unknown weekday code in byWeekday', code);
    }
    return WeekdayRule(day, readOptionalInt(map, 'n', 'byWeekday[].n'));
  }

  /// Parses the RFC 5545 form (`MO`, `2TU`, `-1FR`, `+3WE`).
  factory parseRRule(String text) {
    final match = _rrule.firstMatch(text.trim().toUpperCase());
    if (match == null) throw FormatException('Invalid BYDAY entry', text);
    final ordinal = match.group(1);
    return WeekdayRule(
      Weekday.fromCode(match.group(2)!),
      ordinal == null || ordinal.isEmpty ? null : int.parse(ordinal.replaceFirst('+', '')),
    );
  }

  static final RegExp _rrule = RegExp(r'^([+-]?\d{1,2})?(MO|TU|WE|TH|FR|SA|SU)$');

  /// The weekday.
  final Weekday day;

  /// Ordinal inside the month/year (1 = first … -1 = last); null = every such weekday.
  final int? n;

  /// JSON form.
  Map<String, Object?> toJson() => {'day': day.code, if (n != null) 'n': n};

  /// RFC 5545 form.
  String toRRule() => '${n ?? ''}${day.code}';

  @override
  bool operator ==(Object other) => other is WeekdayRule && other.day == day && other.n == n;

  @override
  int get hashCode => Object.hash(day, n);

  @override
  String toString() => toRRule();
}

/// A daily time window for minutely/hourly rules (e.g. 08:00–20:00).
///
/// The end is inclusive when a step lands on it exactly; `24:00` is allowed as
/// an end and means "until midnight" (exclusive). Windows never cross midnight.
@immutable
final class DailyWindow {
  const new(this.start, this.end, {this.anchor = WindowAnchor.windowStart});

  /// Decodes `{"start": "08:00", "end": "20:00", "anchor": "window_start"}`.
  factory fromJson(Object? json) {
    final map = readMap(json, 'window');
    return DailyWindow(
      readTime(map['start'], 'window.start'),
      readTime(map['end'], 'window.end', allowEndOfDay: true),
      anchor: map['anchor'] == null ? WindowAnchor.windowStart : WindowAnchor.fromJson(map['anchor']),
    );
  }

  /// First slot of the window.
  final LocalTime start;

  /// Last possible slot (inclusive) — `24:00` for "until midnight".
  final LocalTime end;

  /// Restart at [start] each day, or chain from the series start.
  final WindowAnchor anchor;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'start': start.toIso(),
    'end': end.isEndOfDay ? '24:00' : end.toIso(),
    'anchor': anchor.json,
  };

  /// Minutes of the day covered: `[start, end]`, or `[start, 1440)` for a 24:00 end.
  bool containsMinuteOfDay(int minuteOfDay) =>
      minuteOfDay >= start.minuteOfDay && (end.isEndOfDay ? minuteOfDay < 1440 : minuteOfDay <= end.minuteOfDay);

  DailyWindow copyWith({LocalTime? start, LocalTime? end, WindowAnchor? anchor}) =>
      DailyWindow(start ?? this.start, end ?? this.end, anchor: anchor ?? this.anchor);

  @override
  bool operator ==(Object other) =>
      other is DailyWindow && other.start == start && other.end == end && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(start, end, anchor);

  @override
  String toString() => 'DailyWindow(${toJson()})';
}

/// "N units after completion" (rule type `after_completion`).
@immutable
final class AfterCompletion {
  const new(this.amount, this.unit);

  /// Decodes `{"amount": 2, "unit": "day"}`.
  factory fromJson(Object? json) {
    final map = readMap(json, 'afterCompletion');
    return AfterCompletion(readInt(map['amount'], 'afterCompletion.amount'), RecurrenceUnit.fromJson(map['unit']));
  }

  /// How many [unit]s after the last completion the next one is due (≥ 1).
  final int amount;

  /// Unit of [amount].
  final RecurrenceUnit unit;

  /// JSON form.
  Map<String, Object?> toJson() => {'amount': amount, 'unit': unit.name};

  @override
  bool operator ==(Object other) => other is AfterCompletion && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);

  @override
  String toString() => 'AfterCompletion($amount ${unit.name})';
}

/// "N times per period" (rule type `quota`).
@immutable
final class Quota {
  const new(this.times, this.per, {this.minGapDays = 0});

  /// Decodes `{"times": 3, "per": "week", "minGapDays": 0}`.
  factory fromJson(Object? json) {
    final map = readMap(json, 'quota');
    return Quota(
      readInt(map['times'], 'quota.times'),
      PeriodUnit.fromJson(map['per']),
      minGapDays: readOptionalInt(map, 'minGapDays', 'quota.minGapDays') ?? 0,
    );
  }

  /// Required completions per period (≥ 1).
  final int times;

  /// Period length.
  final PeriodUnit per;

  /// Minimum number of empty days between two completions (0 = no constraint;
  /// 1 = "never two days in a row").
  final int minGapDays;

  /// JSON form.
  Map<String, Object?> toJson() => {'times': times, 'per': per.name, 'minGapDays': minGapDays};

  /// Whether the given completion days respect [minGapDays].
  bool respectsMinGap(Iterable<LocalDate> completionDays) {
    if (minGapDays <= 0) return true;
    final days = completionDays.map((d) => d.epochDay).toSet().toList()..sort();
    if (days.length != completionDays.length) return false;
    for (var i = 1; i < days.length; i++) {
      if (days[i] - days[i - 1] <= minGapDays) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is Quota && other.times == times && other.per == per && other.minGapDays == minGapDays;

  @override
  int get hashCode => Object.hash(times, per, minGapDays);

  @override
  String toString() => 'Quota($times per ${per.name}, minGap $minGapDays)';
}
