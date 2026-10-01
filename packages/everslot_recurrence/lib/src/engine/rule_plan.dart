import 'dart:math' as math;

import 'package:everslot_recurrence/src/engine/recurrence_errors.dart';
import 'package:everslot_recurrence/src/rule/recurrence_rule.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/rule/rule_parts.dart';
import 'package:everslot_recurrence/src/rule/rule_validator.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';

/// Minutes per day.
const int minutesPerDay = 1440;

/// Floor division (rounds toward negative infinity).
int floorDiv(int a, int b) {
  final q = a ~/ b;
  return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q;
}

/// Ceiling division.
int ceilDiv(int a, int b) => -floorDiv(-a, b);

/// ISO weekday (1 = Monday) of an epoch day.
int weekdayIsoOfEpochDay(int epochDay) => (epochDay + 3) % 7 + 1;

const List<int> _cumulativeDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

/// Issue codes that make a rule impossible to expand.
const Set<RuleIssueCode> fatalIssueCodes = {
  RuleIssueCode.intervalInvalid,
  RuleIssueCode.valueOutOfRange,
  RuleIssueCode.countInvalid,
  RuleIssueCode.missingField,
};

/// Compiled, anchor-specific form of a fixed rule: the RFC 5545 expansion in
/// wall-clock minutes (epoch minutes), before zone resolution.
///
/// Semantics follow RFC 5545 §3.3.10 (expand/limit table, `BYSETPOS` on each
/// period's sorted set) with the conventions of python-dateutil, plus Everslot
/// extensions (windows, times, month-day clamping). Occurrences before the
/// anchor are never produced and the anchor is not force-included.
final class RulePlan {
  new _({
    required this.rule,
    required this.freq,
    required this.interval,
    required this.anchorMinute,
    required this.anchorDate,
    required this.allDay,
    required this.untilMinute,
    required this.count,
    required this.clamp,
    required this.wkst,
    required this.byMonth,
    required this.monthDayPos,
    required this.monthDayNeg,
    required this.yearDays,
    required this.weekNos,
    required this.weekdayFilter,
    required this.plainWeekdays,
    required this.ordinals,
    required this.setPos,
    required this.dayBased,
    required this.dayStep,
    required this.timeset,
    required this.stepMinutes,
    required this.hourLimit,
    required this.minuteLimit,
    required this.hourMinutes,
    required this.chainWindow,
    required this.exMinutes,
    required this.exDays,
    required this.rdateMinutes,
  });

  /// Compiles [rule] for a series starting at [anchorStart].
  ///
  /// Throws [InvalidRuleException] when the rule can't be expanded.
  factory compile(RecurrenceRule rule, LocalDateTime anchorStart, {bool allDay = false}) {
    final validation = const RuleValidator(maxOccurrencesPerDay: 1 << 30).validate(rule);
    final fatal = [
      for (final i in validation.errors)
        if (fatalIssueCodes.contains(i.code)) i,
    ];
    if (fatal.isNotEmpty) throw InvalidRuleException(fatal);

    final start = allDay ? anchorStart.date.atStartOfDay : anchorStart;
    final freq = rule.freq;
    final weekdays = rule.byWeekday;
    final ordinalCapable = (freq == Frequency.monthly || freq == Frequency.yearly) && rule.byWeekNo.isEmpty;

    var byMonth = rule.byMonth.isEmpty ? null : rule.byMonth.toSet();
    var monthDays = rule.byMonthDay.toSet();
    final plain = <int>{};
    final ordinals = <(int, int)>[];
    for (final w in weekdays ?? const <WeekdayRule>[]) {
      final n = w.n;
      if (n == null || !ordinalCapable) {
        plain.add(w.day.iso);
      } else {
        ordinals.add((w.day.iso, n));
      }
    }
    var weekdayFilter = weekdays != null;

    // RFC 5545: information missing from the rule comes from the start.
    final noDaySpec = rule.byWeekNo.isEmpty && rule.byYearDay.isEmpty && rule.byMonthDay.isEmpty && weekdays == null;
    if (noDaySpec) {
      switch (freq) {
        case Frequency.yearly:
          byMonth ??= {start.month};
          monthDays = {start.day};
        case Frequency.monthly:
          monthDays = {start.day};
        case Frequency.weekly:
          plain.add(start.date.weekday.iso);
          weekdayFilter = true;
        case Frequency.daily:
        case Frequency.hourly:
        case Frequency.minutely:
          break;
      }
    }

    final window = rule.window;
    final windowStartMode = freq.isSubDaily && window != null && window.anchor == WindowAnchor.windowStart;
    final unitMinutes = freq == Frequency.hourly ? 60 : 1;
    final step = rule.interval * unitMinutes;
    final hourLimit = rule.byHour.isEmpty ? null : rule.byHour.toSet();
    final minuteLimit = rule.byMinute.isEmpty ? null : rule.byMinute.toSet();

    List<int> timeset;
    if (allDay) {
      timeset = const [0];
    } else if (windowStartMode) {
      final end = window.end.isEndOfDay ? minutesPerDay - 1 : window.end.minuteOfDay;
      timeset = [
        for (var t = window.start.minuteOfDay; t <= end; t += step)
          if ((hourLimit == null || hourLimit.contains(t ~/ 60)) &&
              (minuteLimit == null || minuteLimit.contains(t % 60)))
            t,
      ];
    } else if (rule.times.isNotEmpty) {
      timeset = (rule.times.map((t) => t.minuteOfDay).toSet().toList()..sort());
    } else {
      final hours = hourLimit == null ? [start.hour] : (hourLimit.toList()..sort());
      final minutes = minuteLimit == null ? [start.minute] : (minuteLimit.toList()..sort());
      timeset = [
        for (final h in hours)
          for (final m in minutes) h * 60 + m,
      ];
    }

    final exMinutes = <int>{};
    final exDays = <int>{};
    for (final value in rule.exdates) {
      final parsed = parseRuleDate(value);
      if (parsed == null) continue;
      final dateTime = parsed.dateTime;
      if (dateTime == null || allDay) {
        exDays.add(parsed.date.epochDay);
      } else {
        exMinutes.add(dateTime.epochMinute);
      }
    }
    final rdates = <int>{};
    for (final value in rule.rdates) {
      final parsed = parseRuleDate(value);
      if (parsed == null) continue;
      final dateTime = parsed.dateTime;
      if (allDay) {
        rdates.add(parsed.date.epochDay * minutesPerDay);
      } else {
        rdates.add(dateTime?.epochMinute ?? parsed.date.epochDay * minutesPerDay + start.time.minuteOfDay);
      }
    }

    final until = rule.until;
    return RulePlan._(
      rule: rule,
      freq: freq,
      interval: rule.interval,
      anchorMinute: start.epochMinute,
      anchorDate: start.date,
      allDay: allDay,
      untilMinute: until?.epochMinute,
      count: rule.countMode == CountMode.occurrences ? rule.count : null,
      clamp: rule.monthDayOverflow == MonthOverflow.clamp,
      wkst: rule.wkst,
      byMonth: byMonth,
      monthDayPos: {
        for (final d in monthDays)
          if (d > 0) d,
      },
      monthDayNeg: {
        for (final d in monthDays)
          if (d < 0) d,
      },
      yearDays: rule.byYearDay.isEmpty ? null : rule.byYearDay.toSet(),
      weekNos: rule.byWeekNo.isEmpty ? null : rule.byWeekNo.toSet(),
      weekdayFilter: weekdayFilter,
      plainWeekdays: plain,
      ordinals: ordinals,
      setPos: rule.bySetPos.toSet().toList()..sort(),
      dayBased: !freq.isSubDaily || windowStartMode,
      dayStep: freq == Frequency.daily ? rule.interval : 1,
      timeset: timeset,
      stepMinutes: step,
      hourLimit: hourLimit,
      minuteLimit: freq == Frequency.minutely ? minuteLimit : null,
      hourMinutes: freq == Frequency.hourly && minuteLimit != null ? (minuteLimit.toList()..sort()) : [start.minute],
      chainWindow: windowStartMode ? null : window,
      exMinutes: exMinutes,
      exDays: exDays,
      rdateMinutes: rdates.toList()..sort(),
    );
  }

  final RecurrenceRule rule;
  final Frequency freq;
  final int interval;
  final int anchorMinute;
  final LocalDate anchorDate;
  final bool allDay;
  final int? untilMinute;
  final int? count;
  final bool clamp;
  final Weekday wkst;
  final Set<int>? byMonth;
  final Set<int> monthDayPos;
  final Set<int> monthDayNeg;
  final Set<int>? yearDays;
  final Set<int>? weekNos;
  final bool weekdayFilter;
  final Set<int> plainWeekdays;
  final List<(int, int)> ordinals;
  final List<int> setPos;

  /// Periods of days (yearly/monthly/weekly/daily, or a `window_start` window).
  final bool dayBased;

  /// Day step for daily rules (1 for window_start rules).
  final int dayStep;

  /// Minutes of the day generated on each matching day (day-based mode).
  final List<int> timeset;

  /// Chain step in minutes (sub-daily chain mode).
  final int stepMinutes;
  final Set<int>? hourLimit;
  final Set<int>? minuteLimit;
  final List<int> hourMinutes;
  final DailyWindow? chainWindow;
  final Set<int> exMinutes;
  final Set<int> exDays;
  final List<int> rdateMinutes;

  bool get _hasMonthDay => monthDayPos.isNotEmpty || monthDayNeg.isNotEmpty;

  /// Earliest possible start of the series (anchor or earliest rdate).
  int get seriesLowerBound => rdateMinutes.isEmpty ? anchorMinute : math.min(anchorMinute, rdateMinutes.first);

  /// Typical distance between occurrences, in minutes (used to size searches).
  int get typicalGapMinutes => switch (freq) {
    Frequency.minutely || Frequency.hourly => dayBased ? minutesPerDay : stepMinutes,
    Frequency.daily => interval * minutesPerDay,
    Frequency.weekly => interval * 7 * minutesPerDay,
    Frequency.monthly => interval * 31 * minutesPerDay,
    Frequency.yearly => interval * 366 * minutesPerDay,
  };

  // ---------------------------------------------------------------------------
  // Series = rule ∪ rdates − exdates.

  /// Wall-clock starts (epoch minutes) of the series within `[from, to]`
  /// (inclusive), ascending and unique.
  Iterable<int> seriesMinutes(int from, int to) sync* {
    final rule = ruleMinutes(from, to).iterator;
    var ruleNext = rule.moveNext() ? rule.current : null;
    var r = _lowerBoundIndex(rdateMinutes, from);
    int? last;
    while (true) {
      final rdate = r < rdateMinutes.length && rdateMinutes[r] <= to ? rdateMinutes[r] : null;
      int value;
      if (ruleNext == null && rdate == null) return;
      if (rdate == null || (ruleNext != null && ruleNext <= rdate)) {
        value = ruleNext!;
        ruleNext = rule.moveNext() ? rule.current : null;
      } else {
        value = rdate;
        r++;
      }
      if (value == last) continue;
      if (exMinutes.contains(value) || exDays.contains(floorDiv(value, minutesPerDay))) {
        continue;
      }
      last = value;
      yield value;
    }
  }

  static int _lowerBoundIndex(List<int> sorted, int value) {
    var lo = 0;
    var hi = sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid] < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Rule-generated wall-clock starts within `[from, to]` (no rdates/exdates),
  /// respecting the anchor, `until` and `count`.
  Iterable<int> ruleMinutes(int from, int to) {
    final stop = untilMinute == null ? to : math.min(to, untilMinute!);
    if (allDay && !dayBased) return _collapseDays(_chain(from, stop));
    if (dayBased) return _dayBased(from, stop);
    return freq == Frequency.hourly ? _hourlyChain(from, stop) : _chain(from, stop);
  }

  Iterable<int> _collapseDays(Iterable<int> source) sync* {
    int? last;
    for (final w in source) {
      final day = floorDiv(w, minutesPerDay) * minutesPerDay;
      if (day == last) continue;
      last = day;
      yield day;
    }
  }

  // ---------------------------------------------------------------------------
  // Day-based periods (yearly / monthly / weekly / daily / window_start).

  Frequency get _periodFreq => freq.isSubDaily ? Frequency.daily : freq;

  int _periodIndexOf(LocalDate date) => switch (_periodFreq) {
    Frequency.yearly => date.year,
    Frequency.monthly => date.year * 12 + date.month - 1,
    Frequency.weekly => date.startOfWeek(wkst).epochDay,
    _ => date.epochDay,
  };

  int get _periodStep => switch (_periodFreq) {
    Frequency.yearly || Frequency.monthly => interval,
    Frequency.weekly => interval * 7,
    _ => dayStep,
  };

  int _periodStartDay(int index) => switch (_periodFreq) {
    Frequency.yearly => LocalDate(index, 1, 1).epochDay,
    Frequency.monthly => LocalDate(floorDiv(index, 12), index - floorDiv(index, 12) * 12 + 1, 1).epochDay,
    _ => index,
  };

  Iterable<int> _dayBased(int from, int stop) sync* {
    final counting = count != null;
    final anchorPeriod = _periodIndexOf(anchorDate);
    final periodStep = _periodStep;
    var k = 0;
    if (!counting && from > anchorMinute) {
      final fromDate = LocalDate.fromEpochDay(floorDiv(from, minutesPerDay));
      k = math.max(0, floorDiv(_periodIndexOf(fromDate) - anchorPeriod, periodStep));
    }
    var emitted = 0;
    final days = <int>[];
    while (true) {
      final period = anchorPeriod + k * periodStep;
      if (_periodStartDay(period) * minutesPerDay > stop) return;
      days.clear();
      _collectPeriodDays(period, days);
      if (days.isNotEmpty) {
        for (final w in _periodMinutes(days)) {
          if (w < anchorMinute) continue;
          if (w > stop) return;
          if (counting && ++emitted > count!) return;
          if (w >= from) yield w;
        }
      }
      k++;
    }
  }

  /// Sorted candidate minutes of a period (days × timeset, then BYSETPOS).
  List<int> _periodMinutes(List<int> days) {
    final times = timeset;
    if (setPos.isEmpty) {
      return [
        for (final d in days)
          for (final t in times) d * minutesPerDay + t,
      ];
    }
    final total = days.length * times.length;
    final picked = <int>{};
    for (final pos in setPos) {
      final index = pos > 0 ? pos - 1 : total + pos;
      if (index < 0 || index >= total) continue;
      picked.add(days[index ~/ times.length] * minutesPerDay + times[index % times.length]);
    }
    return picked.toList()..sort();
  }

  void _collectPeriodDays(int period, List<int> out) {
    switch (_periodFreq) {
      case Frequency.yearly:
        final year = period;
        final perMonthOrdinals = byMonth != null;
        Set<int>? yearOrdinals;
        if (ordinals.isNotEmpty && !perMonthOrdinals) {
          yearOrdinals = _ordinalDays(LocalDate(year, 1, 1).epochDay, LocalDate(year, 12, 31).epochDay);
        }
        for (var month = 1; month <= 12; month++) {
          if (byMonth != null && !byMonth!.contains(month)) continue;
          final first = LocalDate(year, month, 1).epochDay;
          final dim = LocalDate.daysInMonth(year, month);
          final ordinalDays = ordinals.isEmpty
              ? null
              : (perMonthOrdinals ? _ordinalDays(first, first + dim - 1) : yearOrdinals);
          _collectMonth(year, month, first, dim, ordinalDays, out);
        }
      case Frequency.monthly:
        final year = floorDiv(period, 12);
        final month = period - year * 12 + 1;
        if (byMonth != null && !byMonth!.contains(month)) return;
        final first = LocalDate(year, month, 1).epochDay;
        final dim = LocalDate.daysInMonth(year, month);
        _collectMonth(year, month, first, dim, ordinals.isEmpty ? null : _ordinalDays(first, first + dim - 1), out);
      case Frequency.weekly:
        for (var i = 0; i < 7; i++) {
          final day = period + i;
          if (dayMatches(day)) out.add(day);
        }
      case _:
        if (dayMatches(period)) out.add(period);
    }
  }

  void _collectMonth(int year, int month, int first, int dim, Set<int>? ordinalDays, List<int> out) {
    final leap = LocalDate.isLeapYear(year);
    final yearLength = leap ? 366 : 365;
    final doyBase = _cumulativeDays[month - 1] + (leap && month > 2 ? 1 : 0);
    for (var day = 1; day <= dim; day++) {
      final epochDay = first + day - 1;
      if (_matches(epochDay, year, month, day, dim, doyBase + day, yearLength, ordinalDays)) {
        out.add(epochDay);
      }
    }
  }

  int? _cachedDay;
  bool _cachedDayMatch = false;

  /// Whether a single day passes the day-level filters (ordinals act as plain weekdays).
  bool dayMatches(int epochDay) {
    if (_cachedDay == epochDay) return _cachedDayMatch;
    final date = LocalDate.fromEpochDay(epochDay);
    final leap = LocalDate.isLeapYear(date.year);
    final result = _matches(
      epochDay,
      date.year,
      date.month,
      date.day,
      LocalDate.daysInMonth(date.year, date.month),
      _cumulativeDays[date.month - 1] + (leap && date.month > 2 ? 1 : 0) + date.day,
      leap ? 366 : 365,
      null,
    );
    _cachedDay = epochDay;
    _cachedDayMatch = result;
    return result;
  }

  bool _matches(
    int epochDay,
    int year,
    int month,
    int day,
    int dim,
    int dayOfYear,
    int yearLength,
    Set<int>? ordinalDays,
  ) {
    if (byMonth != null && !byMonth!.contains(month)) return false;
    if (weekNos != null && !_weekNoMatches(epochDay, year)) return false;
    final yd = yearDays;
    if (yd != null && !yd.contains(dayOfYear) && !yd.contains(dayOfYear - yearLength - 1)) {
      return false;
    }
    if (_hasMonthDay && !_monthDayMatches(day, dim)) return false;
    // Ordinals only exist for monthly/yearly plans, which always pass [ordinalDays].
    if (weekdayFilter &&
        !plainWeekdays.contains(weekdayIsoOfEpochDay(epochDay)) &&
        !(ordinalDays?.contains(epochDay) ?? false)) {
      return false;
    }
    return true;
  }

  bool _monthDayMatches(int day, int dim) {
    if (monthDayPos.contains(day) || monthDayNeg.contains(day - dim - 1)) {
      return true;
    }
    if (!clamp) return false;
    if (day == dim && monthDayPos.any((v) => v > dim)) return true;
    if (day == 1 && monthDayNeg.any((v) => -v > dim)) return true;
    return false;
  }

  final Map<int, int> _weekYearStarts = {};

  int _weekYearStart(int year) =>
      _weekYearStarts.putIfAbsent(year, () => LocalDate.firstDayOfWeekYear(year, wkst).epochDay);

  bool _weekNoMatches(int epochDay, int year) {
    final thisYear = _weekYearStart(year);
    final nextYear = _weekYearStart(year + 1);
    int start;
    int next;
    if (epochDay >= nextYear) {
      start = nextYear;
      next = _weekYearStart(year + 2);
    } else if (epochDay >= thisYear) {
      start = thisYear;
      next = nextYear;
    } else {
      start = _weekYearStart(year - 1);
      next = thisYear;
    }
    final week = (epochDay - start) ~/ 7 + 1;
    final weeks = (next - start) ~/ 7;
    return weekNos!.contains(week) || weekNos!.contains(week - weeks - 1);
  }

  /// Days of `[first, last]` matching an ordinal weekday (`2TU`, `-1FR`…).
  Set<int> _ordinalDays(int first, int last) {
    final result = <int>{};
    final firstWd = weekdayIsoOfEpochDay(first);
    final lastWd = weekdayIsoOfEpochDay(last);
    for (final (iso, n) in ordinals) {
      if (n > 0) {
        final day = first + (iso - firstWd + 7) % 7 + (n - 1) * 7;
        if (day <= last) result.add(day);
      } else {
        final day = last - (lastWd - iso + 7) % 7 + (n + 1) * 7;
        if (day >= first) result.add(day);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Sub-daily chains (minutely / hourly, optionally filtered by a window).

  int? _cachedFilterDay;
  bool _cachedFilterMatch = false;

  bool _subDailyDayOk(int day) {
    if (_cachedFilterDay != day) {
      _cachedFilterDay = day;
      _cachedFilterMatch = dayMatches(day);
    }
    return _cachedFilterMatch;
  }

  /// Returns -1 when [w] passes the sub-daily filters, otherwise a later
  /// minute before which no chain element can pass.
  int _reject(int w, {bool hourGranularity = false}) {
    final day = floorDiv(w, minutesPerDay);
    final tod = w - day * minutesPerDay;
    final window = chainWindow;
    // With hour granularity, a period starting up to 59 minutes before the
    // window start still contains in-window minutes.
    final slack = hourGranularity ? 59 : 0;
    final windowStart = window?.start.minuteOfDay ?? 0;
    if (!_subDailyDayOk(day)) {
      return (day + 1) * minutesPerDay + windowStart - slack;
    }
    if (window != null) {
      final windowEnd = window.end.isEndOfDay ? minutesPerDay - 1 : window.end.minuteOfDay;
      if (tod + slack < windowStart) {
        return day * minutesPerDay + windowStart - slack;
      }
      if (tod > windowEnd) {
        return (day + 1) * minutesPerDay + windowStart - slack;
      }
    }
    final hours = hourLimit;
    if (hours != null && !hours.contains(tod ~/ 60)) {
      for (var h = tod ~/ 60 + 1; h < 24; h++) {
        if (hours.contains(h)) return day * minutesPerDay + h * 60;
      }
      return (day + 1) * minutesPerDay;
    }
    final minutes = minuteLimit;
    if (!hourGranularity && minutes != null && !minutes.contains(tod % 60)) {
      return w + 1;
    }
    return -1;
  }

  bool get _singleSetPosOk => setPos.isEmpty || setPos.contains(1) || setPos.contains(-1);

  Iterable<int> _chain(int from, int stop) sync* {
    if (freq == Frequency.hourly) {
      yield* _hourlyChain(from, stop);
      return;
    }
    if (!_singleSetPosOk) return;
    final counting = count != null;
    final base = anchorMinute;
    final step = stepMinutes;
    var k = !counting && from > base ? ceilDiv(from - base, step) : 0;
    var emitted = 0;
    while (true) {
      final w = base + k * step;
      if (w > stop) return;
      final skip = _reject(w);
      if (skip < 0) {
        if (counting && ++emitted > count!) return;
        if (w >= from) yield w;
        k++;
      } else {
        final next = ceilDiv(skip - base, step);
        k = next > k ? next : k + 1;
      }
    }
  }

  Iterable<int> _hourlyChain(int from, int stop) sync* {
    final counting = count != null;
    final base = floorDiv(anchorMinute, 60) * 60;
    final step = stepMinutes;
    var k = !counting && from > base ? math.max(0, floorDiv(from - base, step)) : 0;
    var emitted = 0;
    final window = chainWindow;
    final candidates = <int>[];
    while (true) {
      final hour = base + k * step;
      if (hour > stop) return;
      final skip = _reject(hour, hourGranularity: true);
      if (skip >= 0) {
        final next = ceilDiv(skip - base, step);
        k = next > k ? next : k + 1;
        continue;
      }
      final tod = hour - floorDiv(hour, minutesPerDay) * minutesPerDay;
      candidates.clear();
      for (final m in hourMinutes) {
        if (window == null || window.containsMinuteOfDay(tod + m)) {
          candidates.add(hour + m);
        }
      }
      final selected = setPos.isEmpty ? candidates : _selectPositions(candidates);
      for (final w in selected) {
        if (w < anchorMinute) continue;
        if (w > stop) return;
        if (counting && ++emitted > count!) return;
        if (w >= from) yield w;
      }
      k++;
    }
  }

  List<int> _selectPositions(List<int> sorted) {
    final picked = <int>{};
    for (final pos in setPos) {
      final index = pos > 0 ? pos - 1 : sorted.length + pos;
      if (index >= 0 && index < sorted.length) picked.add(sorted[index]);
    }
    return picked.toList()..sort();
  }
}
