import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:everslot_recurrence/src/rule/json_read.dart';
import 'package:everslot_recurrence/src/rule/recurrence_anchor.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/rule/rule_parts.dart';
import 'package:everslot_recurrence/src/rule/rule_validator.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/local_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';
import 'package:meta/meta.dart';

const Object _unset = Object();
const DeepCollectionEquality _deep = DeepCollectionEquality();

/// An Everslot recurrence rule — the JSON value of arch §8.1 (`"v": 1`).
///
/// A superset of RFC 5545 RRULE: calendar rules (`type = fixed`) with every
/// `BYxxx` part, plus daily windows, several times per day, quotas and
/// after-completion rules. Instances are immutable value objects; lists are
/// unmodifiable. Occurrences are computed by `RecurrenceEngine`.
///
/// Unlike RFC 5545 `DTSTART`, the anchor is **not** force-included: the
/// occurrences are exactly the rule's matches at or after the anchor (the
/// builder UI keeps the anchor synchronized with the rule).
@immutable
final class RecurrenceRule {
  new({
    this.type = RuleType.fixed,
    this.freq = Frequency.daily,
    this.interval = 1,
    List<WeekdayRule>? byWeekday,
    List<int> byMonthDay = const [],
    List<int> byMonth = const [],
    List<int> byYearDay = const [],
    List<int> byWeekNo = const [],
    List<int> bySetPos = const [],
    List<int> byHour = const [],
    List<int> byMinute = const [],
    List<LocalTime> times = const [],
    this.window,
    this.wkst = Weekday.monday,
    this.until,
    this.count,
    this.countMode = CountMode.occurrences,
    this.monthDayOverflow = MonthOverflow.skip,
    List<String> exdates = const [],
    List<String> rdates = const [],
    this.afterCompletion,
    this.quota,
    Map<String, Object?> extra = const {},
  }) : byWeekday = byWeekday == null ? null : List.unmodifiable(byWeekday),
       byMonthDay = List.unmodifiable(byMonthDay),
       byMonth = List.unmodifiable(byMonth),
       byYearDay = List.unmodifiable(byYearDay),
       byWeekNo = List.unmodifiable(byWeekNo),
       bySetPos = List.unmodifiable(bySetPos),
       byHour = List.unmodifiable(byHour),
       byMinute = List.unmodifiable(byMinute),
       times = List.unmodifiable(times),
       exdates = List.unmodifiable(exdates),
       rdates = List.unmodifiable(rdates),
       extra = Map.unmodifiable(extra);

  /// Convenience constructor for a quota rule ("[times] per [per]").
  factory forQuota(
    int times,
    PeriodUnit per, {
    int minGapDays = 0,
    List<WeekdayRule>? byWeekday,
    LocalDateTime? until,
  }) => RecurrenceRule(
    type: RuleType.quota,
    quota: Quota(times, per, minGapDays: minGapDays),
    byWeekday: byWeekday,
    until: until,
  );

  /// Convenience constructor for an after-completion rule ("[amount] [unit] after completion").
  factory forAfterCompletion(int amount, RecurrenceUnit unit, {LocalDateTime? until}) =>
      RecurrenceRule(type: RuleType.afterCompletion, afterCompletion: AfterCompletion(amount, unit), until: until);

  /// Decodes the JSON value (upgrading older schema versions).
  ///
  /// Throws [FormatException] for malformed JSON. Semantic problems (e.g. an
  /// interval of 0) are reported by [validate], not here. Unknown keys are kept
  /// in [extra] and re-emitted by [toJson].
  factory fromJson(Map<String, Object?> json) {
    final upgraded = _upgrade(json);
    final extra = <String, Object?>{};
    for (final entry in upgraded.entries) {
      if (!_knownKeys.contains(entry.key)) extra[entry.key] = entry.value;
    }
    final rule = RecurrenceRule(
      type: upgraded['type'] == null ? RuleType.fixed : RuleType.fromJson(upgraded['type']),
      freq: upgraded['freq'] == null ? Frequency.daily : Frequency.fromJson(upgraded['freq']),
      interval: upgraded['interval'] == null ? 1 : readInt(upgraded['interval'], 'interval'),
      byWeekday: _readWeekdays(upgraded['byWeekday']),
      byMonthDay: readIntList(upgraded['byMonthDay'], 'byMonthDay'),
      byMonth: readIntList(upgraded['byMonth'], 'byMonth'),
      byYearDay: readIntList(upgraded['byYearDay'], 'byYearDay'),
      byWeekNo: readIntList(upgraded['byWeekNo'], 'byWeekNo'),
      bySetPos: readIntList(upgraded['bySetPos'], 'bySetPos'),
      byHour: readIntList(upgraded['byHour'], 'byHour'),
      byMinute: readIntList(upgraded['byMinute'], 'byMinute'),
      times: [for (final t in readStringList(upgraded['times'], 'times')) readTime(t, 'times[]')],
      window: upgraded['window'] == null ? null : DailyWindow.fromJson(upgraded['window']),
      wkst: upgraded['wkst'] == null ? Weekday.monday : _readWeekday(upgraded['wkst'], 'wkst'),
      until: _readUntil(upgraded['until']),
      count: upgraded['count'] == null ? null : readInt(upgraded['count'], 'count'),
      countMode: upgraded['countMode'] == null ? CountMode.occurrences : CountMode.fromJson(upgraded['countMode']),
      monthDayOverflow: upgraded['monthDayOverflow'] == null
          ? MonthOverflow.skip
          : enumFromJson(MonthOverflow.values, upgraded['monthDayOverflow'], 'monthDayOverflow', (e) => e.name),
      exdates: readStringList(upgraded['exdates'], 'exdates'),
      rdates: readStringList(upgraded['rdates'], 'rdates'),
      afterCompletion: upgraded['afterCompletion'] == null
          ? null
          : AfterCompletion.fromJson(upgraded['afterCompletion']),
      quota: upgraded['quota'] == null ? null : Quota.fromJson(upgraded['quota']),
      extra: extra,
    );
    _presentKeys[rule] = upgraded.keys.where(_knownKeys.contains).toSet();
    return rule;
  }

  /// Decodes a JSON string (see [RecurrenceRule.fromJson]).
  factory decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('Recurrence rule is not valid JSON: ${e.message}', source);
    }
    return RecurrenceRule.fromJson(readMap(json, 'rule'));
  }

  /// Current schema version written by [toJson].
  static const int currentVersion = 1;

  /// Upgrades from version `n` to `n + 1` (none yet — v1 is the first version).
  static final Map<int, Map<String, Object?> Function(Map<String, Object?>)> migrations = {};

  final RuleType type;

  /// Base frequency (fixed rules).
  final Frequency freq;

  /// Every N [freq] units (≥ 1). For minutely/hourly rules with a window this is the step.
  final int interval;

  /// `BYDAY`. `null` = no weekday restriction; an empty list is the invalid
  /// "no day selected" state reported as [RuleIssueCode.emptyWeekdaySet].
  final List<WeekdayRule>? byWeekday;

  /// `BYMONTHDAY`: 1..31 or -1..-31 (from the end of the month).
  final List<int> byMonthDay;

  /// `BYMONTH`: 1..12.
  final List<int> byMonth;

  /// `BYYEARDAY`: 1..366 or -1..-366.
  final List<int> byYearDay;

  /// `BYWEEKNO`: 1..53 or -1..-53 (yearly rules only; weeks start on [wkst]).
  final List<int> byWeekNo;

  /// `BYSETPOS`: positions inside each period's sorted set (1 = first, -1 = last).
  final List<int> bySetPos;

  /// `BYHOUR`: 0..23.
  final List<int> byHour;

  /// `BYMINUTE`: 0..59.
  final List<int> byMinute;

  /// Several fixed times on each matching day (cross product dates × times).
  final List<LocalTime> times;

  /// Daily window for minutely/hourly rules.
  final DailyWindow? window;

  /// Week start used for weekly intervals, week numbers and set positions.
  final Weekday wkst;

  /// Last allowed start (local wall time, inclusive).
  final LocalDateTime? until;

  /// Number of occurrences (or completions, see [countMode]).
  final int? count;

  /// How [count] is interpreted.
  final CountMode countMode;

  /// What happens to month days that don't exist in a month (e.g. the 31st).
  final MonthOverflow monthDayOverflow;

  /// Removed occurrences: keys `YYYY-MM-DDTHH:mm` (one occurrence) or
  /// `YYYY-MM-DD` (every occurrence on that date).
  final List<String> exdates;

  /// Extra occurrences: keys `YYYY-MM-DDTHH:mm`, or `YYYY-MM-DD` (at the
  /// anchor's time of day; the date itself for all-day series).
  final List<String> rdates;

  /// After-completion delay (type `after_completion`).
  final AfterCompletion? afterCompletion;

  /// Quota (type `quota`).
  final Quota? quota;

  /// Unknown JSON keys, preserved on re-encode.
  final Map<String, Object?> extra;

  static final Expando<Set<String>> _presentKeys = Expando('presentKeys');

  static const List<String> _schemaOrder = [
    'v',
    'type',
    'freq',
    'interval',
    'byWeekday',
    'byMonthDay',
    'byMonth',
    'byYearDay',
    'byWeekNo',
    'bySetPos',
    'byHour',
    'byMinute',
    'times',
    'window',
    'wkst',
    'until',
    'count',
    'countMode',
    'monthDayOverflow',
    'exdates',
    'rdates',
    'afterCompletion',
    'quota',
  ];

  static final Set<String> _knownKeys = _schemaOrder.toSet();

  /// Encodes to the JSON value of arch §8.1.
  ///
  /// Keys follow the schema order; defaults and empty lists are omitted unless
  /// they were present in the decoded source (so decoded documents re-encode
  /// byte-identically). Unknown keys are appended in their original order.
  Map<String, Object?> toJson() {
    final present = _presentKeys[this] ?? const <String>{};
    final out = <String, Object?>{'v': currentVersion, 'type': type.json};
    bool keep(String key, {required bool isDefault}) => !isDefault || present.contains(key);
    final fixed = type == RuleType.fixed;
    if (keep('freq', isDefault: !fixed && freq == Frequency.daily)) {
      out['freq'] = freq.json;
    }
    if (keep('interval', isDefault: !fixed && interval == 1)) {
      out['interval'] = interval;
    }
    if (keep('byWeekday', isDefault: byWeekday == null)) {
      out['byWeekday'] = byWeekday?.map((w) => w.toJson()).toList();
    }
    void list(String key, List<Object?> values) {
      if (keep(key, isDefault: values.isEmpty)) out[key] = values;
    }

    list('byMonthDay', byMonthDay);
    list('byMonth', byMonth);
    list('byYearDay', byYearDay);
    list('byWeekNo', byWeekNo);
    list('bySetPos', bySetPos);
    list('byHour', byHour);
    list('byMinute', byMinute);
    list('times', [for (final t in times) t.toIso()]);
    if (keep('window', isDefault: window == null)) {
      out['window'] = window?.toJson();
    }
    if (keep('wkst', isDefault: wkst == Weekday.monday)) {
      out['wkst'] = wkst.code;
    }
    if (keep('until', isDefault: until == null)) out['until'] = until?.toIso();
    if (keep('count', isDefault: count == null)) out['count'] = count;
    if (keep('countMode', isDefault: countMode == CountMode.occurrences)) {
      out['countMode'] = countMode.name;
    }
    if (keep('monthDayOverflow', isDefault: monthDayOverflow == MonthOverflow.skip)) {
      out['monthDayOverflow'] = monthDayOverflow.name;
    }
    list('exdates', exdates);
    list('rdates', rdates);
    if (keep('afterCompletion', isDefault: afterCompletion == null)) {
      out['afterCompletion'] = afterCompletion?.toJson();
    }
    if (keep('quota', isDefault: quota == null)) out['quota'] = quota?.toJson();
    for (final entry in extra.entries) {
      out.putIfAbsent(entry.key, () => entry.value);
    }
    return out;
  }

  /// Compact JSON string of [toJson].
  String encode() => jsonEncode(toJson());

  /// Validates the rule; pass the [anchor] to enable anchor-dependent checks.
  ValidationResult validate({RecurrenceAnchor? anchor, int maxOccurrencesPerDay = 1440}) =>
      RuleValidator(maxOccurrencesPerDay: maxOccurrencesPerDay).validate(this, anchor: anchor);

  /// Returns a copy with the given fields replaced. Nullable fields
  /// ([byWeekday], [window], [until], [count], [afterCompletion], [quota]) can
  /// be cleared by passing `null` explicitly.
  RecurrenceRule copyWith({
    RuleType? type,
    Frequency? freq,
    int? interval,
    Object? byWeekday = _unset,
    List<int>? byMonthDay,
    List<int>? byMonth,
    List<int>? byYearDay,
    List<int>? byWeekNo,
    List<int>? bySetPos,
    List<int>? byHour,
    List<int>? byMinute,
    List<LocalTime>? times,
    Object? window = _unset,
    Weekday? wkst,
    Object? until = _unset,
    Object? count = _unset,
    CountMode? countMode,
    MonthOverflow? monthDayOverflow,
    List<String>? exdates,
    List<String>? rdates,
    Object? afterCompletion = _unset,
    Object? quota = _unset,
    Map<String, Object?>? extra,
  }) {
    final copy = RecurrenceRule(
      type: type ?? this.type,
      freq: freq ?? this.freq,
      interval: interval ?? this.interval,
      byWeekday: identical(byWeekday, _unset) ? this.byWeekday : byWeekday as List<WeekdayRule>?,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      byMonth: byMonth ?? this.byMonth,
      byYearDay: byYearDay ?? this.byYearDay,
      byWeekNo: byWeekNo ?? this.byWeekNo,
      bySetPos: bySetPos ?? this.bySetPos,
      byHour: byHour ?? this.byHour,
      byMinute: byMinute ?? this.byMinute,
      times: times ?? this.times,
      window: identical(window, _unset) ? this.window : window as DailyWindow?,
      wkst: wkst ?? this.wkst,
      until: identical(until, _unset) ? this.until : until as LocalDateTime?,
      count: identical(count, _unset) ? this.count : count as int?,
      countMode: countMode ?? this.countMode,
      monthDayOverflow: monthDayOverflow ?? this.monthDayOverflow,
      exdates: exdates ?? this.exdates,
      rdates: rdates ?? this.rdates,
      afterCompletion: identical(afterCompletion, _unset) ? this.afterCompletion : afterCompletion as AfterCompletion?,
      quota: identical(quota, _unset) ? this.quota : quota as Quota?,
      extra: extra ?? this.extra,
    );
    final present = _presentKeys[this];
    if (present != null) _presentKeys[copy] = present;
    return copy;
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.type == type &&
      other.freq == freq &&
      other.interval == interval &&
      _deep.equals(other.byWeekday, byWeekday) &&
      _deep.equals(other.byMonthDay, byMonthDay) &&
      _deep.equals(other.byMonth, byMonth) &&
      _deep.equals(other.byYearDay, byYearDay) &&
      _deep.equals(other.byWeekNo, byWeekNo) &&
      _deep.equals(other.bySetPos, bySetPos) &&
      _deep.equals(other.byHour, byHour) &&
      _deep.equals(other.byMinute, byMinute) &&
      _deep.equals(other.times, times) &&
      other.window == window &&
      other.wkst == wkst &&
      other.until == until &&
      other.count == count &&
      other.countMode == countMode &&
      other.monthDayOverflow == monthDayOverflow &&
      _deep.equals(other.exdates, exdates) &&
      _deep.equals(other.rdates, rdates) &&
      other.afterCompletion == afterCompletion &&
      other.quota == quota &&
      _deep.equals(other.extra, extra);

  @override
  int get hashCode => Object.hashAll([
    type,
    freq,
    interval,
    _deep.hash(byWeekday),
    _deep.hash(byMonthDay),
    _deep.hash(byMonth),
    _deep.hash(byYearDay),
    _deep.hash(byWeekNo),
    _deep.hash(bySetPos),
    _deep.hash(byHour),
    _deep.hash(byMinute),
    _deep.hash(times),
    window,
    wkst,
    until,
    count,
    countMode,
    monthDayOverflow,
    _deep.hash(exdates),
    _deep.hash(rdates),
    afterCompletion,
    quota,
    _deep.hash(extra),
  ]);

  @override
  String toString() => 'RecurrenceRule(${encode()})';

  static Map<String, Object?> _upgrade(Map<String, Object?> json) {
    final rawVersion = json['v'];
    var version = rawVersion == null ? currentVersion : readInt(rawVersion, 'v');
    if (version < 1) {
      throw FormatException('Unsupported rule version', rawVersion);
    }
    if (version > currentVersion) {
      throw FormatException('Rule version $version is newer than supported ($currentVersion)', rawVersion);
    }
    var current = json;
    while (version < currentVersion) {
      final migrate = migrations[version];
      if (migrate == null) {
        throw FormatException('No migration from rule version $version', rawVersion);
      }
      current = migrate(current);
      version++;
    }
    return current;
  }

  static Weekday _readWeekday(Object? value, String field) {
    if (value is String) {
      try {
        return Weekday.fromCode(value);
      } on FormatException {
        // fall through
      }
    }
    throw FormatException('"$field" must be a weekday code (MO…SU)', value);
  }

  static List<WeekdayRule>? _readWeekdays(Object? value) {
    if (value == null) return null;
    if (value is! List) {
      throw FormatException('"byWeekday" must be a list', value);
    }
    return [for (final item in value) WeekdayRule.fromJson(item)];
  }

  static LocalDateTime? _readUntil(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final dateTime = LocalDateTime.tryParse(value);
      if (dateTime != null) return dateTime;
      final date = LocalDate.tryParse(value);
      if (date != null) return date.atTime(LocalTime(23, 59));
    }
    throw FormatException('"until" must be a local date-time "YYYY-MM-DDTHH:mm"', value);
  }
}
