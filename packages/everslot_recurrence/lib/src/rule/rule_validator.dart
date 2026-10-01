import 'package:everslot_recurrence/src/rule/recurrence_anchor.dart';
import 'package:everslot_recurrence/src/rule/recurrence_rule.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/rule/rule_parts.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';
import 'package:meta/meta.dart';

/// Machine-readable validation issue codes (localized by the UI).
enum RuleIssueCode {
  /// `interval` < 1.
  intervalInvalid,

  /// `until` is before the anchor start.
  untilBeforeStart,

  /// Both `count` and `until` are set (RFC 5545 forbids it).
  countAndUntil,

  /// `byWeekday` is present but empty (no day selected).
  emptyWeekdaySet,

  /// A weekday ordinal (`2TU`, `-1FR`) on a rule that isn't monthly/yearly
  /// (or on a yearly rule with `byWeekNo`).
  ordinalOnWeekly,

  /// The window ends before it starts (windows can't cross midnight).
  windowEndBeforeStart,

  /// More occurrences per day than allowed (default 1 440).
  tooFrequent,

  /// A quota that can't be met (e.g. 8 times per week with `minGapDays` 1).
  quotaImpossible,

  /// Fields that can't be combined (e.g. `window` on a daily rule,
  /// `byWeekNo` on a monthly rule, `bySetPos` alone, `times` with `byHour`).
  unsupportedCombo,

  /// A numeric value outside its allowed range (`byMonthDay: 32`, `byHour: 24`…).
  valueOutOfRange,

  /// An `exdates`/`rdates` entry that is not a `YYYY-MM-DD[THH:mm]` key.
  invalidDate,

  /// `count` < 1.
  countInvalid,

  /// A field required by the rule type is missing (`quota`, `afterCompletion`).
  missingField,
}

/// Severity of a [RuleIssue].
enum RuleIssueSeverity { error, warning }

/// One validation finding: a [code], the offending [field] and parameters for
/// the localized message.
@immutable
final class RuleIssue {
  const new(this.code, {this.field, this.params = const {}, this.severity = RuleIssueSeverity.error});

  final RuleIssueCode code;

  /// JSON field name (e.g. `byMonthDay`), when the issue concerns one field.
  final String? field;

  /// Message parameters (e.g. `{"value": 32, "min": -31, "max": 31}`).
  final Map<String, Object?> params;

  final RuleIssueSeverity severity;

  bool get isError => severity == RuleIssueSeverity.error;

  @override
  bool operator ==(Object other) =>
      other is RuleIssue && other.code == code && other.field == field && other.severity == severity;

  @override
  int get hashCode => Object.hash(code, field, severity);

  @override
  String toString() => 'RuleIssue(${code.name}${field == null ? '' : ' @$field'}${params.isEmpty ? '' : ' $params'})';
}

/// Result of [RuleValidator.validate].
@immutable
final class ValidationResult {
  const new(this.issues);

  final List<RuleIssue> issues;

  /// True when there is no error-severity issue.
  bool get isValid => !issues.any((i) => i.isError);

  List<RuleIssue> get errors => [
    for (final i in issues)
      if (i.isError) i,
  ];

  List<RuleIssue> get warnings => [
    for (final i in issues)
      if (!i.isError) i,
  ];

  /// Distinct issue codes, in discovery order.
  List<RuleIssueCode> get codes => {for (final i in issues) i.code}.toList();

  bool has(RuleIssueCode code) => issues.any((i) => i.code == code);

  @override
  String toString() => 'ValidationResult($issues)';
}

/// Validates [RecurrenceRule]s (arch §9.5). Cheap: no expansion is performed.
final class RuleValidator {
  const new({this.maxOccurrencesPerDay = 1440});

  /// Density limit for [RuleIssueCode.tooFrequent].
  final int maxOccurrencesPerDay;

  /// Validates [rule]; anchor-dependent checks run when [anchor] is given.
  ValidationResult validate(RecurrenceRule rule, {RecurrenceAnchor? anchor}) {
    final issues = <RuleIssue>[];
    void add(RuleIssueCode code, {String? field, Map<String, Object?> params = const {}, bool warning = false}) =>
        issues.add(
          RuleIssue(
            code,
            field: field,
            params: params,
            severity: warning ? RuleIssueSeverity.warning : RuleIssueSeverity.error,
          ),
        );

    void range(String field, Iterable<int> values, int min, int max, {bool allowNegative = false}) {
      for (final v in values) {
        final ok = allowNegative ? (v != 0 && v.abs() >= min && v.abs() <= max) : (v >= min && v <= max);
        if (!ok) {
          add(
            RuleIssueCode.valueOutOfRange,
            field: field,
            params: {'value': v, 'min': allowNegative ? -max : min, 'max': max},
          );
        }
      }
    }

    if (rule.interval < 1) {
      add(RuleIssueCode.intervalInvalid, field: 'interval', params: {'value': rule.interval});
    }
    final count = rule.count;
    if (count != null && count < 1) {
      add(RuleIssueCode.countInvalid, field: 'count', params: {'value': count});
    }
    if (count != null && rule.until != null) {
      add(RuleIssueCode.countAndUntil, field: 'count');
    }
    final until = rule.until;
    if (anchor != null && until != null && until.isBefore(anchor.start)) {
      add(
        RuleIssueCode.untilBeforeStart,
        field: 'until',
        params: {'until': until.toIso(), 'start': anchor.start.toIso()},
      );
    }
    for (final (field, values) in [('exdates', rule.exdates), ('rdates', rule.rdates)]) {
      for (final value in values) {
        if (parseRuleDate(value) == null) {
          add(RuleIssueCode.invalidDate, field: field, params: {'value': value});
        }
      }
    }
    final weekdays = rule.byWeekday;
    if (weekdays != null && weekdays.isEmpty) {
      add(RuleIssueCode.emptyWeekdaySet, field: 'byWeekday');
    }
    range('byMonthDay', rule.byMonthDay, 1, 31, allowNegative: true);
    range('byMonth', rule.byMonth, 1, 12);
    range('byYearDay', rule.byYearDay, 1, 366, allowNegative: true);
    range('byWeekNo', rule.byWeekNo, 1, 53, allowNegative: true);
    range('bySetPos', rule.bySetPos, 1, 366, allowNegative: true);
    range('byHour', rule.byHour, 0, 23);
    range('byMinute', rule.byMinute, 0, 59);
    range('byWeekday.n', [for (final w in weekdays ?? const <WeekdayRule>[]) ?w.n], 1, 53, allowNegative: true);

    switch (rule.type) {
      case RuleType.fixed:
        _validateFixed(rule, anchor, add);
      case RuleType.quota:
        _validateQuota(rule, add, range);
      case RuleType.afterCompletion:
        final after = rule.afterCompletion;
        if (after == null) {
          add(RuleIssueCode.missingField, field: 'afterCompletion');
        } else {
          range('afterCompletion.amount', [after.amount], 1, 1 << 31);
        }
    }
    return ValidationResult(List.unmodifiable(issues));
  }

  void _validateFixed(
    RecurrenceRule rule,
    RecurrenceAnchor? anchor,
    void Function(RuleIssueCode, {String? field, Map<String, Object?> params, bool warning}) add,
  ) {
    final freq = rule.freq;
    final ordinalsAllowed =
        (freq == Frequency.monthly || freq == Frequency.yearly) &&
        !(freq == Frequency.yearly && rule.byWeekNo.isNotEmpty);
    if (!ordinalsAllowed && (rule.byWeekday ?? const []).any((w) => w.n != null)) {
      add(RuleIssueCode.ordinalOnWeekly, field: 'byWeekday', params: {'freq': freq.json});
    }
    final window = rule.window;
    if (window != null) {
      if (!freq.isSubDaily) {
        add(RuleIssueCode.unsupportedCombo, field: 'window', params: {'freq': freq.json});
      }
      if (!window.end.isEndOfDay && window.end.isBefore(window.start)) {
        add(
          RuleIssueCode.windowEndBeforeStart,
          field: 'window',
          params: {'start': window.start.toIso(), 'end': window.end.toIso()},
        );
      }
    }
    if (rule.times.isNotEmpty) {
      if (freq.isSubDaily) {
        add(RuleIssueCode.unsupportedCombo, field: 'times', params: {'freq': freq.json});
      }
      if (rule.byHour.isNotEmpty || rule.byMinute.isNotEmpty) {
        add(RuleIssueCode.unsupportedCombo, field: 'times', params: {'with': 'byHour/byMinute'});
      }
    }
    if (rule.byWeekNo.isNotEmpty && freq != Frequency.yearly) {
      add(RuleIssueCode.unsupportedCombo, field: 'byWeekNo', params: {'freq': freq.json});
    }
    if (rule.byYearDay.isNotEmpty &&
        (freq == Frequency.daily || freq == Frequency.weekly || freq == Frequency.monthly)) {
      add(RuleIssueCode.unsupportedCombo, field: 'byYearDay', params: {'freq': freq.json});
    }
    if (rule.byMonthDay.isNotEmpty && freq == Frequency.weekly) {
      add(RuleIssueCode.unsupportedCombo, field: 'byMonthDay', params: {'freq': freq.json});
    }
    final hasOtherBy =
        rule.byWeekday != null ||
        rule.byMonthDay.isNotEmpty ||
        rule.byMonth.isNotEmpty ||
        rule.byYearDay.isNotEmpty ||
        rule.byWeekNo.isNotEmpty ||
        rule.byHour.isNotEmpty ||
        rule.byMinute.isNotEmpty ||
        rule.times.isNotEmpty ||
        rule.window != null;
    if (rule.bySetPos.isNotEmpty && !hasOtherBy) {
      add(RuleIssueCode.unsupportedCombo, field: 'bySetPos');
    }
    if (anchor != null && anchor.allDay && freq.isSubDaily) {
      add(RuleIssueCode.unsupportedCombo, field: 'freq', params: {'allDay': true}, warning: true);
    }
    if (rule.interval >= 1) {
      final perDay = maxOccurrencesPerDayOf(rule);
      if (perDay > maxOccurrencesPerDay) {
        add(RuleIssueCode.tooFrequent, params: {'perDay': perDay, 'max': maxOccurrencesPerDay});
      }
    }
  }

  void _validateQuota(
    RecurrenceRule rule,
    void Function(RuleIssueCode, {String? field, Map<String, Object?> params, bool warning}) add,
    void Function(String, Iterable<int>, int, int, {bool allowNegative}) range,
  ) {
    final quota = rule.quota;
    if (quota == null) {
      add(RuleIssueCode.missingField, field: 'quota');
      return;
    }
    range('quota.times', [quota.times], 1, 1 << 31);
    range('quota.minGapDays', [quota.minGapDays], 0, 366);
    if (quota.times < 1 || quota.minGapDays < 0) return;
    final eligible = eligibleWeekdays(rule.byWeekday);
    if (eligible.isEmpty) return; // reported as emptyWeekdaySet
    if (quota.minGapDays == 0) {
      return; // several completions per day are allowed
    }
    final max = maxQuotaCompletions(quota.per, quota.minGapDays, eligible, rule.wkst);
    if (quota.times > max) {
      add(
        RuleIssueCode.quotaImpossible,
        field: 'quota',
        params: {'times': quota.times, 'max': max, 'per': quota.per.name},
      );
    }
  }
}

/// Upper bound of occurrences per day produced by a fixed [rule].
int maxOccurrencesPerDayOf(RecurrenceRule rule) {
  if (rule.interval < 1) return 0;
  if (!rule.freq.isSubDaily) {
    if (rule.times.isNotEmpty) return rule.times.toSet().length;
    final hours = rule.byHour.isEmpty ? 1 : rule.byHour.toSet().length;
    final minutes = rule.byMinute.isEmpty ? 1 : rule.byMinute.toSet().length;
    return hours * minutes;
  }
  final step = rule.interval * (rule.freq == Frequency.hourly ? 60 : 1);
  final window = rule.window;
  final start = window?.start.minuteOfDay ?? 0;
  final end = window == null || window.end.isEndOfDay ? 1439 : window.end.minuteOfDay;
  if (end < start) return 0;
  final span = end - start + 1;
  final expand = rule.freq == Frequency.hourly && rule.byMinute.isNotEmpty ? rule.byMinute.toSet().length : 1;
  if (window != null && window.anchor == WindowAnchor.windowStart) {
    return (end - start) ~/ step + 1;
  }
  return ((span + step - 1) ~/ step) * expand;
}

/// Plain weekdays eligible for a quota (all when [byWeekday] is null).
Set<Weekday> eligibleWeekdays(List<WeekdayRule>? byWeekday) =>
    byWeekday == null ? Weekday.values.toSet() : {for (final w in byWeekday) w.day};

/// Maximum completions possible in the worst-aligned period when completions
/// must be on distinct [eligible] days separated by more than [minGapDays] days.
int maxQuotaCompletions(PeriodUnit per, int minGapDays, Set<Weekday> eligible, Weekday weekStart) {
  int greedy(LocalDate first, int days) {
    var picks = 0;
    int? last;
    for (var i = 0; i < days; i++) {
      final day = first.plusDays(i);
      if (!eligible.contains(day.weekday)) continue;
      if (last == null || i - last > minGapDays) {
        picks++;
        last = i;
      }
    }
    return picks;
  }

  // 2024-01-01 is a Monday; offsets give every starting weekday.
  final monday = LocalDate(2024, 1, 1);
  switch (per) {
    case PeriodUnit.day:
      return 1;
    case PeriodUnit.week:
      return greedy(monday.plusDays(weekStart.iso - 1), 7);
    case PeriodUnit.month:
    case PeriodUnit.year:
      final lengths = per == PeriodUnit.month ? const [28, 29, 30, 31] : const [365, 366];
      var best = 1 << 30;
      for (final length in lengths) {
        for (var offset = 0; offset < 7; offset++) {
          final value = greedy(monday.plusDays(offset), length);
          if (value < best) best = value;
        }
      }
      return best;
  }
}

/// Parses an exdate/rdate entry: `YYYY-MM-DDTHH:mm` (time set) or `YYYY-MM-DD` (time null).
({LocalDate date, LocalDateTime? dateTime})? parseRuleDate(String value) {
  final dateTime = LocalDateTime.tryParse(value);
  if (dateTime != null) return (date: dateTime.date, dateTime: dateTime);
  final date = LocalDate.tryParse(value);
  if (date != null) return (date: date, dateTime: null);
  return null;
}
