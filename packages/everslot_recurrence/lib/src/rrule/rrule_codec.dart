import 'package:everslot_recurrence/src/engine/recurrence_engine.dart';
import 'package:everslot_recurrence/src/engine/rule_plan.dart';
import 'package:everslot_recurrence/src/rule/recurrence_anchor.dart';
import 'package:everslot_recurrence/src/rule/recurrence_rule.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/rule/rule_parts.dart';
import 'package:everslot_recurrence/src/rule/rule_validator.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/local_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';
import 'package:everslot_recurrence/src/time/zone_resolver.dart';
import 'package:meta/meta.dart';

/// Result of [RRuleCodec.parse].
@immutable
final class RRuleImport {
  const new(this.rule, this.anchor);

  final RecurrenceRule rule;

  /// From `DTSTART`; null when the text has no `DTSTART` line.
  final RecurrenceAnchor? anchor;

  @override
  String toString() => 'RRuleImport($rule, $anchor)';
}

/// RFC 5545 text ↔ [RecurrenceRule] (T2.1.17), used by ICS import/export.
///
/// Supported lines: `DTSTART` (`TZID`, UTC `Z`, floating, `VALUE=DATE`),
/// `RRULE`, `EXDATE`, `RDATE` (comma lists). RFC 7529 `RSCALE=GREGORIAN` with
/// `SKIP=OMIT|BACKWARD` maps to `monthDayOverflow` skip/clamp. Seconds must be
/// zero; `FREQ=SECONDLY`, `BYSECOND` ≠ 0, `EXRULE` and period `RDATE`s are
/// rejected with a [FormatException].
///
/// RFC 5545 always includes `DTSTART` and counts it in `COUNT`, while Everslot
/// never force-includes the anchor: on import a non-matching `DTSTART` becomes
/// an rdate (and uses one unit of `COUNT`); on export a non-matching anchor is
/// excluded with an `EXDATE` (and `COUNT` grows by one).
abstract final class RRuleCodec {
  static const Set<String> _supportedParts = {
    'FREQ',
    'INTERVAL',
    'COUNT',
    'UNTIL',
    'BYDAY',
    'BYMONTHDAY',
    'BYMONTH',
    'BYYEARDAY',
    'BYWEEKNO',
    'BYSETPOS',
    'BYHOUR',
    'BYMINUTE',
    'BYSECOND',
    'WKST',
    'RSCALE',
    'SKIP',
  };

  /// Parses RFC 5545 text (an `RRULE:` line, a bare `FREQ=…` value, or a
  /// block with `DTSTART`/`EXDATE`/`RDATE` lines).
  ///
  /// UTC values (`…Z`) are converted to the `DTSTART` zone's wall clock with
  /// [resolver] (default: [TzZoneResolver], which needs the tz database).
  static RRuleImport parse(String text, {ZoneResolver? resolver}) {
    final lines = _unfold(text);
    _Value? start;
    String? rruleValue;
    final exdates = <_Value>[];
    final rdates = <_Value>[];
    for (final line in lines) {
      if (!line.contains(':') && line.toUpperCase().startsWith('FREQ=')) {
        rruleValue = line;
        continue;
      }
      final colon = _valueSeparator(line);
      if (colon < 0) throw FormatException('Invalid iCalendar line', line);
      final head = line.substring(0, colon).split(';');
      final name = head.first.trim().toUpperCase();
      final params = <String, String>{
        for (final p in head.skip(1))
          if (p.contains('='))
            p.substring(0, p.indexOf('=')).trim().toUpperCase(): p.substring(p.indexOf('=') + 1).replaceAll('"', ''),
      };
      final value = line.substring(colon + 1).trim();
      switch (name) {
        case 'DTSTART':
          start = _parseValues(value, params, name).single;
        case 'RRULE':
          if (rruleValue != null) {
            throw FormatException('Several RRULE lines are not supported', line);
          }
          rruleValue = value;
        case 'EXDATE':
          exdates.addAll(_parseValues(value, params, name));
        case 'RDATE':
          rdates.addAll(_parseValues(value, params, name));
        case 'EXRULE':
          throw FormatException('EXRULE is not supported', line);
        default:
          break; // other properties (SUMMARY, UID…) are ignored
      }
    }
    if (rruleValue == null) throw FormatException('No RRULE found', text);

    final zone = start == null ? null : (start.utc ? 'UTC' : start.zone);
    var lazyResolver = resolver;
    ZoneResolver zones() => lazyResolver ??= TzZoneResolver();

    LocalDateTime toLocal(_Value v) {
      if (v.utc && zone != null && zone != 'UTC') {
        final instant = DateTime.utc(v.local.year, v.local.month, v.local.day, v.local.hour, v.local.minute);
        return zones().toLocal(instant, zone);
      }
      if (!v.utc && v.zone != null && zone != null && v.zone != zone) {
        return zones().toLocal(zones().resolve(v.local, v.zone!).utc, zone);
      }
      return v.local;
    }

    String keyOf(_Value v) => v.dateOnly ? v.local.date.toIso() : toLocal(v).toIso();

    final parts = <String, String>{};
    for (final part in rruleValue.split(';')) {
      if (part.trim().isEmpty) continue;
      final eq = part.indexOf('=');
      if (eq < 0) throw FormatException('Invalid RRULE part', part);
      final partName = part.substring(0, eq).trim().toUpperCase();
      if (!_supportedParts.contains(partName)) {
        throw FormatException('Unsupported RRULE part $partName', part);
      }
      parts[partName] = part.substring(eq + 1).trim();
    }
    final freqText = parts['FREQ'];
    if (freqText == null) {
      throw FormatException('RRULE without FREQ', rruleValue);
    }
    if (freqText.toUpperCase() == 'SECONDLY') {
      throw FormatException('FREQ=SECONDLY is not supported (minute precision)', rruleValue);
    }
    final freq = Frequency.values.where((f) => f.rrule == freqText.toUpperCase()).firstOrNull;
    if (freq == null) throw FormatException('Unknown FREQ', freqText);
    final rscale = parts['RSCALE'];
    if (rscale != null && rscale.toUpperCase() != 'GREGORIAN') {
      throw FormatException('RSCALE=$rscale is not supported (Gregorian only)', rruleValue);
    }
    final skip = parts['SKIP']?.toUpperCase();
    if (skip != null && skip != 'OMIT' && skip != 'BACKWARD') {
      throw FormatException('SKIP=$skip is not supported', rruleValue);
    }
    final bySecond = _ints(parts['BYSECOND'], 'BYSECOND');
    if (bySecond.any((s) => s != 0)) {
      throw FormatException('BYSECOND other than 0 is not supported', rruleValue);
    }

    LocalDateTime? until;
    final untilText = parts['UNTIL'];
    if (untilText != null) {
      final value = _parseValue(untilText, const {}, 'UNTIL');
      until = value.dateOnly ? value.local.date.atTime(LocalTime(23, 59)) : toLocal(value);
    }

    var rule = RecurrenceRule(
      freq: freq,
      interval: parts['INTERVAL'] == null ? 1 : _int(parts['INTERVAL']!, 'INTERVAL'),
      byWeekday: parts['BYDAY'] == null
          ? null
          : [for (final d in parts['BYDAY']!.split(',')) WeekdayRule.parseRRule(d)],
      byMonthDay: _ints(parts['BYMONTHDAY'], 'BYMONTHDAY'),
      byMonth: _ints(parts['BYMONTH'], 'BYMONTH'),
      byYearDay: _ints(parts['BYYEARDAY'], 'BYYEARDAY'),
      byWeekNo: _ints(parts['BYWEEKNO'], 'BYWEEKNO'),
      bySetPos: _ints(parts['BYSETPOS'], 'BYSETPOS'),
      byHour: _ints(parts['BYHOUR'], 'BYHOUR'),
      byMinute: _ints(parts['BYMINUTE'], 'BYMINUTE'),
      wkst: parts['WKST'] == null ? Weekday.monday : Weekday.fromCode(parts['WKST']!),
      until: until,
      count: parts['COUNT'] == null ? null : _int(parts['COUNT']!, 'COUNT'),
      monthDayOverflow: skip == 'BACKWARD' ? MonthOverflow.clamp : MonthOverflow.skip,
      exdates: [for (final e in exdates) keyOf(e)],
      rdates: [for (final r in rdates) keyOf(r)],
    );

    RecurrenceAnchor? anchor;
    if (start != null) {
      anchor = RecurrenceAnchor(
        start.local,
        zone,
        allDay: start.dateOnly,
        durationMinutes: start.dateOnly ? 1440 : null,
      );
      final issues = rule.validate();
      if (issues.errors.any((i) => fatalIssueCodes.contains(i.code))) {
        throw FormatException('Invalid RRULE: ${issues.errors.join(', ')}', rruleValue);
      }
      final engine = RecurrenceEngine(const FixedOffsetZoneResolver());
      final startKey = start.dateOnly ? start.local.date.toIso() : start.local.toIso();
      final plan = engine.planFor(rule, anchor);
      if (plan.ruleMinutes(plan.anchorMinute, plan.anchorMinute).isEmpty) {
        // RFC 5545: DTSTART is always the first occurrence and counts in COUNT.
        final count = rule.count;
        if (count != null && count > 1) rule = rule.copyWith(count: count - 1);
        if (!rule.exdates.contains(startKey) && !rule.rdates.contains(startKey)) {
          rule = rule.copyWith(rdates: [startKey, ...rule.rdates]);
        }
      }
    }
    return RRuleImport(rule, anchor);
  }

  /// Encodes [rule] anchored at [anchor] as `DTSTART` + `RRULE` (+ `EXDATE` /
  /// `RDATE`) lines separated by `\n`, or returns null when the rule can't be
  /// expressed in RFC 5545 (quota and after-completion rules, completion
  /// counts, windows or `times` that are not an hour × minute cross product,
  /// date-only exdates on timed series).
  ///
  /// `UNTIL` is written in UTC for zoned anchors (RFC 5545 requirement), using
  /// [resolver] (default: [TzZoneResolver]).
  static String? encode(RecurrenceRule rule, RecurrenceAnchor anchor, {ZoneResolver? resolver}) {
    if (rule.type != RuleType.fixed) return null;
    if (rule.count != null && rule.countMode == CountMode.completions) {
      return null;
    }
    if (!rule.validate(anchor: anchor).isValid) return null;
    if (!anchor.allDay && rule.exdates.any((e) => parseRuleDate(e)?.dateTime == null)) {
      return null;
    }

    var freq = rule.freq;
    var interval = rule.interval;
    var byHour = rule.byHour;
    var byMinute = rule.byMinute;
    final window = rule.window;
    if (rule.times.isNotEmpty) {
      final cross = _crossProduct({for (final t in rule.times) t.minuteOfDay});
      if (cross == null) return null;
      (byHour, byMinute) = cross;
    } else if (window != null) {
      final encoded = _encodeWindow(rule, anchor, window);
      if (encoded == null) return null;
      (freq, interval, byHour, byMinute) = encoded;
    }
    if (rule.monthDayOverflow == MonthOverflow.clamp && rule.byMonthDay.any((d) => d < -28)) {
      return null;
    }

    final engine = RecurrenceEngine(const FixedOffsetZoneResolver());
    final plan = engine.planFor(rule, anchor);
    final anchorMatches = plan.ruleMinutes(plan.anchorMinute, plan.anchorMinute).isNotEmpty;
    final zone = anchor.zoneId;
    final exdates = [...rule.exdates];
    var count = rule.count;
    if (!anchorMatches) {
      final key = anchor.allDay ? anchor.start.date.toIso() : anchor.start.toIso();
      if (!exdates.contains(key)) exdates.insert(0, key);
      if (count != null) count++;
    }

    final parts = <String>[
      if (rule.monthDayOverflow == MonthOverflow.clamp) ...['RSCALE=GREGORIAN', 'SKIP=BACKWARD'],
      'FREQ=${freq.rrule}',
      if (interval != 1) 'INTERVAL=$interval',
      if (count != null) 'COUNT=$count',
      if (rule.until case final until?) 'UNTIL=${_formatUntil(until, anchor, resolver)}',
      if (rule.byMonth.isNotEmpty) 'BYMONTH=${rule.byMonth.join(',')}',
      if (rule.byWeekNo.isNotEmpty) 'BYWEEKNO=${rule.byWeekNo.join(',')}',
      if (rule.byYearDay.isNotEmpty) 'BYYEARDAY=${rule.byYearDay.join(',')}',
      if (rule.byMonthDay.isNotEmpty) 'BYMONTHDAY=${rule.byMonthDay.join(',')}',
      if (rule.byWeekday case final days? when days.isNotEmpty) 'BYDAY=${days.map((d) => d.toRRule()).join(',')}',
      if (byHour.isNotEmpty) 'BYHOUR=${byHour.join(',')}',
      if (byMinute.isNotEmpty) 'BYMINUTE=${byMinute.join(',')}',
      if (rule.bySetPos.isNotEmpty) 'BYSETPOS=${rule.bySetPos.join(',')}',
      if (rule.wkst != Weekday.monday) 'WKST=${rule.wkst.code}',
    ];
    final start = anchor.allDay ? anchor.start.date.atStartOfDay : anchor.start;
    return [
      'DTSTART${_formatValue(start, anchor.allDay, zone)}',
      'RRULE:${parts.join(';')}',
      if (exdates.isNotEmpty) 'EXDATE${_formatList(exdates, anchor, zone)}',
      if (rule.rdates.isNotEmpty) 'RDATE${_formatList(rule.rdates, anchor, zone)}',
    ].join('\n');
  }

  static (Frequency, int, List<int>, List<int>)? _encodeWindow(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    DailyWindow window,
  ) {
    final step = rule.interval * (rule.freq == Frequency.hourly ? 60 : 1);
    final start = window.start.minuteOfDay;
    final end = window.end.isEndOfDay ? 1439 : window.end.minuteOfDay;
    bool limitsOk(int t) =>
        (rule.byHour.isEmpty || rule.byHour.contains(t ~/ 60)) &&
        (rule.byMinute.isEmpty || rule.byMinute.contains(t % 60));
    if (window.anchor == WindowAnchor.windowStart) {
      final slots = {
        for (var t = start; t <= end; t += step)
          if (limitsOk(t)) t,
      };
      if (slots.isEmpty) return null;
      final cross = _crossProduct(slots);
      if (cross == null) return null;
      return (Frequency.daily, 1, cross.$1, cross.$2);
    }
    if (rule.freq == Frequency.hourly && rule.byMinute.isNotEmpty) return null;
    // Minutes of the day the chain can reach.
    final anchorTod = anchor.start.time.minuteOfDay;
    final period = _gcd(step, 1440);
    final reachable = {
      for (var t = anchorTod % period; t < 1440; t += period)
        if (limitsOk(t)) t,
    };
    final inWindow = {
      for (final t in reachable)
        if (t >= start && t <= end) t,
    };
    final hours = ({for (final t in inWindow) t ~/ 60}.toList()..sort());
    final covered = {
      for (final t in reachable)
        if (hours.contains(t ~/ 60)) t,
    };
    if (covered.length != inWindow.length || !covered.containsAll(inWindow)) {
      return null;
    }
    return (rule.freq, rule.interval, hours, rule.freq == Frequency.minutely ? rule.byMinute : const <int>[]);
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  /// Hours × minutes when [minutes] (minutes of the day) is a full cross product.
  static (List<int>, List<int>)? _crossProduct(Set<int> minutes) {
    final hours = ({for (final t in minutes) t ~/ 60}.toList()..sort());
    final mins = ({for (final t in minutes) t % 60}.toList()..sort());
    if (hours.length * mins.length != minutes.length) return null;
    return (hours, mins);
  }

  static String _formatUntil(LocalDateTime until, RecurrenceAnchor anchor, ZoneResolver? resolver) {
    if (anchor.allDay) return _date(until.date);
    final zone = anchor.zoneId;
    if (zone == null) return _dateTime(until);
    final utc = zone == 'UTC' ? until.toDateTimeUtc() : (resolver ?? TzZoneResolver()).resolve(until, zone).utc;
    return '${_dateTime(LocalDateTime.fromDateTime(utc))}Z';
  }

  static String _formatValue(LocalDateTime value, bool allDay, String? zone) {
    if (allDay) return ';VALUE=DATE:${_date(value.date)}';
    if (zone == null) return ':${_dateTime(value)}';
    if (zone == 'UTC') return ':${_dateTime(value)}Z';
    return ';TZID=$zone:${_dateTime(value)}';
  }

  static String _formatList(List<String> keys, RecurrenceAnchor anchor, String? zone) {
    final values = <LocalDateTime>[];
    for (final key in keys) {
      final parsed = parseRuleDate(key);
      if (parsed == null) continue;
      values.add(parsed.dateTime ?? parsed.date.atTime(anchor.start.time));
    }
    if (anchor.allDay) {
      return ';VALUE=DATE:${values.map((v) => _date(v.date)).join(',')}';
    }
    final formatted = values.map(_dateTime).join(',');
    if (zone == null) return ':$formatted';
    if (zone == 'UTC') {
      return ':${values.map((v) => '${_dateTime(v)}Z').join(',')}';
    }
    return ';TZID=$zone:$formatted';
  }

  static String _date(LocalDate d) => d.toIso().replaceAll('-', '');

  static String _dateTime(LocalDateTime v) => '${_date(v.date)}T${v.time.toIso().replaceAll(':', '')}00';

  static List<String> _unfold(String text) {
    final raw = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final lines = <String>[];
    for (final line in raw) {
      if ((line.startsWith(' ') || line.startsWith('\t')) && lines.isNotEmpty) {
        lines[lines.length - 1] += line.substring(1);
      } else if (line.trim().isNotEmpty) {
        lines.add(line.trim());
      }
    }
    return lines;
  }

  static int _valueSeparator(String line) {
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') quoted = !quoted;
      if (c == ':' && !quoted) return i;
    }
    return -1;
  }

  static List<_Value> _parseValues(String value, Map<String, String> params, String name) {
    final type = params['VALUE']?.toUpperCase();
    if (type == 'PERIOD') {
      throw FormatException('$name;VALUE=PERIOD is not supported', value);
    }
    return [
      for (final v in value.split(','))
        if (v.trim().isNotEmpty) _parseValue(v.trim(), params, name),
    ];
  }

  static final RegExp _dateTimePattern = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z?))?$');

  static _Value _parseValue(String text, Map<String, String> params, String name) {
    final match = _dateTimePattern.firstMatch(text.toUpperCase());
    if (match == null) throw FormatException('Invalid $name value', text);
    final date = LocalDate.tryCreate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (date == null) throw FormatException('Invalid $name date', text);
    if (match.group(4) == null) {
      return _Value(date.atStartOfDay, dateOnly: true, zone: params['TZID']);
    }
    if (match.group(6) != '00') {
      throw FormatException('$name with seconds is not supported (minute precision)', text);
    }
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    if (hour > 23 || minute > 59) {
      throw FormatException('Invalid $name time', text);
    }
    return _Value(date.atTime(LocalTime(hour, minute)), utc: match.group(7) == 'Z', zone: params['TZID']);
  }

  static int _int(String text, String name) {
    final value = int.tryParse(text.trim().replaceFirst('+', ''));
    if (value == null) throw FormatException('Invalid $name value', text);
    return value;
  }

  static List<int> _ints(String? text, String name) =>
      text == null || text.isEmpty ? const [] : [for (final v in text.split(',')) _int(v, name)];
}

final class _Value {
  const new(this.local, {this.dateOnly = false, this.utc = false, this.zone});

  final LocalDateTime local;
  final bool dateOnly;
  final bool utc;
  final String? zone;
}
