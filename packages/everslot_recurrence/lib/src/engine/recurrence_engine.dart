import 'dart:math' as math;

import 'package:everslot_recurrence/src/engine/occurrence.dart';
import 'package:everslot_recurrence/src/engine/recurrence_errors.dart';
import 'package:everslot_recurrence/src/engine/rule_plan.dart';
import 'package:everslot_recurrence/src/rule/recurrence_anchor.dart';
import 'package:everslot_recurrence/src/rule/recurrence_rule.dart';
import 'package:everslot_recurrence/src/rule/rule_enums.dart';
import 'package:everslot_recurrence/src/rule/rule_parts.dart';
import 'package:everslot_recurrence/src/rule/rule_validator.dart';
import 'package:everslot_recurrence/src/time/local_date.dart';
import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:everslot_recurrence/src/time/weekday.dart';
import 'package:everslot_recurrence/src/time/zone_resolver.dart';
import 'package:meta/meta.dart';

const int _minuteMs = 60000;
const int _dayMs = 86400000;

/// Expands [RecurrenceRule]s into concrete [Occurrence]s (arch §6.8).
///
/// Rules are expanded in wall-clock time and then resolved with the
/// [resolver]: fixed-zone anchors use their own zone, floating anchors
/// (`zoneId == null`) use the `evalZone` passed to each call (the user's
/// current zone; `UTC` when omitted). DST gaps shift forward by the gap
/// length; ambiguous times take the earlier instant.
///
/// Query semantics:
/// * `between` returns occurrences whose start instant lies in `[from, to)`
///   (or, with a duration, whose `[start, end)` overlaps it), where `from`/`to`
///   are wall-clock values in the evaluation zone. All-day occurrences are
///   matched by date instead (floating dates).
/// * Results are lazy, in series order (ascending keys), and capped at
///   [maxOccurrencesPerCall] unless an explicit `limit` is passed.
final class RecurrenceEngine {
  new(this.resolver, {this.maxOccurrencesPerCall = 10000, this.maxSearchYears = 500});

  /// Wall clock ↔ instant conversion.
  final ZoneResolver resolver;

  /// Hard cap per call (throws [RecurrenceLimitExceeded] beyond it).
  final int maxOccurrencesPerCall;

  /// How far `nextAfter` searches before concluding there is no next occurrence.
  final int maxSearchYears;

  final Expando<Map<(LocalDateTime, bool), RulePlan>> _plans = Expando('plans');

  /// Zone used to resolve the series' wall-clock values.
  String zoneFor(RecurrenceAnchor anchor, String? evalZone) => anchor.zoneId ?? evalZone ?? 'UTC';

  /// Zone in which query ranges are expressed.
  String viewZoneFor(RecurrenceAnchor anchor, String? evalZone) => evalZone ?? anchor.zoneId ?? 'UTC';

  /// Compiled plan for a fixed rule (cached per rule instance and anchor).
  ///
  /// Internal to the package (used by the series splitter and RRULE codec).
  @internal
  RulePlan planFor(RecurrenceRule rule, RecurrenceAnchor anchor) {
    final byAnchor = _plans[rule] ??= {};
    final cacheKey = (anchor.start, anchor.allDay);
    return byAnchor[cacheKey] ??= RulePlan.compile(rule, anchor.start, allDay: anchor.allDay);
  }

  // ---------------------------------------------------------------------------
  // Range queries.

  /// Occurrences in `[fromLocal, toLocal)` (wall clock in the evaluation zone).
  ///
  /// With [durationMinutes] (default: the anchor's), occurrences that started
  /// before [fromLocal] but still overlap it are included. For quota rules the
  /// result lists one slot per required completion (`week:2026-09-21#1` …);
  /// for after-completion rules only the first due (the anchor) is known.
  ///
  /// Throws [InvalidRuleException] for rules that can't be expanded, and
  /// [RecurrenceLimitExceeded] (during iteration) when more than
  /// [maxOccurrencesPerCall] occurrences would be returned and no [limit] is given.
  Iterable<Occurrence> between(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime fromLocal,
    LocalDateTime toLocal, {
    String? evalZone,
    int? limit,
    int? durationMinutes,
  }) =>
      _capped(_between(rule, anchor, fromLocal, toLocal, evalZone: evalZone, durationMinutes: durationMinutes), limit);

  /// Like [between] with the range given as instants `[fromUtc, toUtc)`.
  Iterable<Occurrence> betweenInstants(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    DateTime fromUtc,
    DateTime toUtc, {
    String? evalZone,
    int? limit,
    int? durationMinutes,
  }) {
    final duration = durationMinutes ?? anchor.effectiveDurationMinutes;
    final from = fromUtc.millisecondsSinceEpoch;
    final to = toUtc.millisecondsSinceEpoch;
    switch (rule.type) {
      case RuleType.fixed:
        final plan = planFor(rule, anchor);
        return _capped(_timed(plan, anchor, zoneFor(anchor, evalZone), from, to, duration), limit);
      case RuleType.quota:
      case RuleType.afterCompletion:
        final zone = viewZoneFor(anchor, evalZone);
        return between(
          rule,
          anchor,
          resolver.toLocal(fromUtc, zone),
          resolver.toLocal(toUtc, zone).plusMinutes(1),
          evalZone: evalZone,
          limit: limit,
          durationMinutes: durationMinutes,
        ).where((o) {
          final start = o.startUtc.millisecondsSinceEpoch;
          final end = o.endUtc.millisecondsSinceEpoch;
          return start < to && (duration == 0 ? start >= from : end > from);
        });
    }
  }

  /// Number of occurrences [between] would return (not capped).
  int countBetween(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime fromLocal,
    LocalDateTime toLocal, {
    String? evalZone,
    int? durationMinutes,
  }) => _between(rule, anchor, fromLocal, toLocal, evalZone: evalZone, durationMinutes: durationMinutes).length;

  Iterable<Occurrence> _between(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime fromLocal,
    LocalDateTime toLocal, {
    String? evalZone,
    int? durationMinutes,
  }) {
    final duration = durationMinutes ?? anchor.effectiveDurationMinutes;
    switch (rule.type) {
      case RuleType.fixed:
        final plan = planFor(rule, anchor);
        final zone = zoneFor(anchor, evalZone);
        if (anchor.allDay) {
          return _allDay(plan, anchor, zone, fromLocal, toLocal, duration);
        }
        final viewZone = viewZoneFor(anchor, evalZone);
        final from = resolver.resolve(fromLocal, viewZone).utc.millisecondsSinceEpoch;
        final to = resolver.resolve(toLocal, viewZone).utc.millisecondsSinceEpoch;
        return _timed(plan, anchor, zone, from, to, duration);
      case RuleType.quota:
        return _quotaSlots(rule, anchor, fromLocal, toLocal, evalZone, duration);
      case RuleType.afterCompletion:
        _requireAfterCompletion(rule);
        final first = _build(anchor, zoneFor(anchor, evalZone), anchor.start, duration);
        return _filterLocal([first], anchor, fromLocal, toLocal, evalZone, duration);
    }
  }

  Iterable<Occurrence> _capped(Iterable<Occurrence> source, int? limit) sync* {
    if (limit != null && limit <= 0) return;
    var produced = 0;
    for (final occurrence in source) {
      if (limit == null && produced >= maxOccurrencesPerCall) {
        throw RecurrenceLimitExceeded(maxOccurrencesPerCall);
      }
      yield occurrence;
      produced++;
      if (limit != null && produced >= limit) return;
    }
  }

  /// Timed occurrences whose start is in `[from, to)` ms (or overlapping it).
  Iterable<Occurrence> _timed(
    RulePlan plan,
    RecurrenceAnchor anchor,
    String zone,
    int from,
    int to,
    int durationMinutes,
  ) sync* {
    if (to <= from && durationMinutes == 0) return;
    final lower = from - durationMinutes * _minuteMs;
    final offsets = [
      for (final t in [lower - _dayMs, lower, lower + _dayMs]) _offsetMs(t, zone),
    ];
    final upperOffsets = [
      for (final t in [to - _dayMs, to, to + _dayMs]) _offsetMs(t, zone),
    ];
    final wallFrom = floorDiv(lower + offsets.reduce(math.min), _minuteMs);
    final wallTo = ceilDiv(to + upperOffsets.reduce(math.max), _minuteMs);
    for (final minute in plan.seriesMinutes(wallFrom, wallTo)) {
      final occurrence = _build(anchor, zone, LocalDateTime.fromEpochMinute(minute), durationMinutes);
      final start = occurrence.startUtc.millisecondsSinceEpoch;
      if (start >= to) continue;
      if (durationMinutes == 0 ? start < from : occurrence.endUtc.millisecondsSinceEpoch <= from) {
        continue;
      }
      yield occurrence;
    }
  }

  int _offsetMs(int utcMs, String zone) =>
      resolver.offsetMinutesAt(DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true), zone) * _minuteMs;

  /// All-day occurrences whose days overlap `[from, to)` (wall clock, floating dates).
  Iterable<Occurrence> _allDay(
    RulePlan plan,
    RecurrenceAnchor anchor,
    String zone,
    LocalDateTime from,
    LocalDateTime to,
    int durationMinutes,
  ) sync* {
    final days = _allDayLength(durationMinutes);
    final wallFrom = from.epochMinute - days * minutesPerDay + 1;
    final wallTo = to.epochMinute - 1;
    if (wallTo < wallFrom) return;
    for (final minute in plan.seriesMinutes(wallFrom, wallTo)) {
      yield _build(anchor, zone, LocalDateTime.fromEpochMinute(minute), durationMinutes);
    }
  }

  static int _allDayLength(int durationMinutes) => math.max(1, ceilDiv(durationMinutes, minutesPerDay));

  Iterable<Occurrence> _filterLocal(
    Iterable<Occurrence> source,
    RecurrenceAnchor anchor,
    LocalDateTime fromLocal,
    LocalDateTime toLocal,
    String? evalZone,
    int durationMinutes,
  ) {
    if (anchor.allDay) {
      final days = _allDayLength(durationMinutes);
      return source.where((o) {
        final start = o.startLocal.date.atStartOfDay;
        return start.isBefore(toLocal) && start.plusDays(days).isAfter(fromLocal);
      });
    }
    final viewZone = viewZoneFor(anchor, evalZone);
    final from = resolver.resolve(fromLocal, viewZone).utc;
    final to = resolver.resolve(toLocal, viewZone).utc;
    return source.where((o) {
      if (!o.startUtc.isBefore(to)) return false;
      return durationMinutes == 0 ? !o.startUtc.isBefore(from) : o.endUtc.isAfter(from);
    });
  }

  /// Builds the [Occurrence] for a wall-clock start (no rule check).
  ///
  /// Useful for callers that need the resolved form of a key or of a moved
  /// occurrence; [durationMinutes] defaults to the anchor's.
  Occurrence occurrenceAt(
    RecurrenceAnchor anchor,
    LocalDateTime startLocal, {
    String? evalZone,
    int? durationMinutes,
    String? key,
  }) => _build(
    anchor,
    zoneFor(anchor, evalZone),
    startLocal,
    durationMinutes ?? anchor.effectiveDurationMinutes,
    key: key,
  );

  Occurrence _build(RecurrenceAnchor anchor, String zone, LocalDateTime local, int durationMinutes, {String? key}) {
    final resolved = resolver.resolve(local, zone);
    final DateTime end;
    if (anchor.allDay) {
      end = resolver.resolve(local.date.plusDays(_allDayLength(durationMinutes)).atStartOfDay, zone).utc;
    } else {
      end = resolved.utc.add(Duration(minutes: durationMinutes));
    }
    return Occurrence(
      key: key ?? (anchor.allDay ? local.date.toIso() : local.toIso()),
      startLocal: local,
      startUtc: resolved.utc,
      endUtc: end,
      isAllDay: anchor.allDay,
      resolutionKind: resolved.kind,
      zoneId: zone,
    );
  }

  // ---------------------------------------------------------------------------
  // Point queries.

  /// First occurrence (in series order) starting after [instant]
  /// (at or after it when [inclusive]); null when none within [maxSearchYears].
  Occurrence? nextAfter(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    DateTime instant, {
    String? evalZone,
    bool inclusive = false,
  }) {
    final from = instant.millisecondsSinceEpoch + (inclusive ? 0 : 1);
    switch (rule.type) {
      case RuleType.fixed:
        final plan = planFor(rule, anchor);
        final horizon = from + maxSearchYears * 366 * _dayMs;
        return _timed(plan, anchor, zoneFor(anchor, evalZone), from, horizon, 0).firstOrNull;
      case RuleType.afterCompletion:
        final first = nextDue(rule, anchor, null, evalZone: evalZone);
        return first != null && first.startUtc.millisecondsSinceEpoch >= from ? first : null;
      case RuleType.quota:
        final zone = viewZoneFor(anchor, evalZone);
        final local = resolver.toLocal(DateTime.fromMillisecondsSinceEpoch(from, isUtc: true), zone);
        final horizon = local.date.plusYears(5).atStartOfDay;
        return _quotaSlots(
          rule,
          anchor,
          local.date.atStartOfDay,
          horizon,
          evalZone,
          0,
        ).where((o) => o.startUtc.millisecondsSinceEpoch >= from).firstOrNull;
    }
  }

  /// Last occurrence (in series order) starting before [instant] (at or
  /// before it when [inclusive]), found with a bounded backward search.
  Occurrence? previousBefore(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    DateTime instant, {
    String? evalZone,
    bool inclusive = false,
  }) {
    final end = instant.millisecondsSinceEpoch + (inclusive ? 1 : 0);
    switch (rule.type) {
      case RuleType.fixed:
        final plan = planFor(rule, anchor);
        final zone = zoneFor(anchor, evalZone);
        final lowest = (plan.seriesLowerBound - 2 * minutesPerDay) * _minuteMs;
        var windowEnd = end;
        var width = math.max(plan.typicalGapMinutes * 2, 60) * _minuteMs;
        while (windowEnd > lowest) {
          final windowStart = math.max(windowEnd - width, lowest);
          Occurrence? last;
          for (final occurrence in _timed(plan, anchor, zone, windowStart, windowEnd, 0)) {
            last = occurrence;
          }
          if (last != null) return last;
          windowEnd = windowStart;
          width *= 2;
        }
        return null;
      case RuleType.afterCompletion:
        final first = nextDue(rule, anchor, null, evalZone: evalZone);
        return first != null && first.startUtc.millisecondsSinceEpoch < end ? first : null;
      case RuleType.quota:
        final zone = viewZoneFor(anchor, evalZone);
        final local = resolver.toLocal(DateTime.fromMillisecondsSinceEpoch(end, isUtc: true), zone);
        final from = LocalDateTime.max(anchor.start.date.atStartOfDay, local.date.plusYears(-1).atStartOfDay);
        return _quotaSlots(
          rule,
          anchor,
          from,
          local.plusMinutes(1),
          evalZone,
          0,
        ).where((o) => o.startUtc.millisecondsSinceEpoch < end).lastOrNull;
    }
  }

  /// Whether [key] is an occurrence of the series (exdates removed, rdates included).
  ///
  /// For after-completion rules only the first due (the anchor) is known.
  bool occurs(RecurrenceRule rule, RecurrenceAnchor anchor, String key) => occurrenceForKey(rule, anchor, key) != null;

  /// The occurrence identified by [key], or null when the series has none.
  Occurrence? occurrenceForKey(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    String key, {
    String? evalZone,
    int? durationMinutes,
  }) {
    final duration = durationMinutes ?? anchor.effectiveDurationMinutes;
    switch (rule.type) {
      case RuleType.fixed:
        final plan = planFor(rule, anchor);
        final local = anchor.allDay
            ? LocalDate.tryParse(key)?.atStartOfDay
            : (key.contains('T') ? LocalDateTime.tryParse(key) : null);
        if (local == null || local.toIso() != (anchor.allDay ? '${key}T00:00' : key)) {
          return null;
        }
        final minute = local.epochMinute;
        if (plan.seriesMinutes(minute, minute).isEmpty) return null;
        return _build(anchor, zoneFor(anchor, evalZone), local, duration);
      case RuleType.afterCompletion:
        _requireAfterCompletion(rule);
        final start = anchor.allDay ? anchor.start.date.atStartOfDay : anchor.start;
        final first = _build(anchor, zoneFor(anchor, evalZone), start, duration);
        return first.key == key ? first : null;
      case RuleType.quota:
        final hash = key.lastIndexOf('#');
        if (hash < 0) return null;
        final n = int.tryParse(key.substring(hash + 1));
        final start = _periodStartOfKey(key.substring(0, hash));
        if (n == null || n < 1 || start == null) return null;
        for (final slot in _quotaSlots(
          rule,
          anchor,
          start.atStartOfDay,
          start.plusDays(1).atStartOfDay,
          evalZone,
          duration,
        )) {
          if (slot.key == key) return slot;
        }
        return null;
    }
  }

  static LocalDate? _periodStartOfKey(String periodKey) {
    final colon = periodKey.indexOf(':');
    if (colon < 0) return null;
    final value = periodKey.substring(colon + 1);
    return switch (periodKey.substring(0, colon)) {
      'day' || 'week' => LocalDate.tryParse(value),
      'month' => LocalDate.tryParse('$value-01'),
      'year' => LocalDate.tryParse('$value-01-01'),
      _ => null,
    };
  }

  // ---------------------------------------------------------------------------
  // Quota rules.

  /// Quota periods overlapping `[from, to]` (inclusive dates), pro-rated at the
  /// series start (anchor) and end (`until`).
  ///
  /// Week periods start on [weekStart] (default: the rule's `wkst`). Days for
  /// which [isExcluded] returns true (paused/excused) and date-level exdates
  /// reduce the eligible days; `byWeekday` restricts eligible weekdays.
  /// Target: `E = N · eligibleDays / periodDays`.
  List<Period> periods(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDate from,
    LocalDate to, {
    Weekday? weekStart,
    bool Function(LocalDate day)? isExcluded,
  }) {
    final quota = rule.quota;
    if (rule.type != RuleType.quota || quota == null) {
      throw ArgumentError.value(rule, 'rule', 'periods() needs a quota rule');
    }
    final start = weekStart ?? rule.wkst;
    final eligibleWeekdays = rule.byWeekday == null ? null : {for (final w in rule.byWeekday!) w.day};
    final excludedDays = <int>{
      for (final value in rule.exdates)
        if (parseRuleDate(value) case final parsed?) parsed.date.epochDay,
    };
    final seriesStart = anchor.start.date;
    final seriesEnd = rule.until?.date;
    var periodStart = _periodStart(quota.per, LocalDate.max(from, seriesStart), start);
    final result = <Period>[];
    while (!periodStart.isAfter(to) && (seriesEnd == null || !periodStart.isAfter(seriesEnd))) {
      final periodEnd = _periodEnd(quota.per, periodStart);
      final activeStart = LocalDate.max(periodStart, seriesStart);
      final activeEnd = seriesEnd == null ? periodEnd : LocalDate.min(periodEnd, seriesEnd);
      if (!activeStart.isAfter(activeEnd)) {
        var periodDays = 0;
        var eligibleDays = 0;
        for (var day = periodStart; !day.isAfter(periodEnd); day = day.plusDays(1)) {
          if (eligibleWeekdays != null && !eligibleWeekdays.contains(day.weekday)) {
            continue;
          }
          periodDays++;
          if (day.isBefore(activeStart) || day.isAfter(activeEnd)) continue;
          if (excludedDays.contains(day.epochDay) || (isExcluded?.call(day) ?? false)) {
            continue;
          }
          eligibleDays++;
        }
        result.add(
          Period(
            key: periodKey(quota.per, periodStart),
            unit: quota.per,
            startDate: periodStart,
            endDate: periodEnd,
            activeStart: activeStart,
            activeEnd: activeEnd,
            timesPerPeriod: quota.times,
            eligibleDays: eligibleDays,
            periodDays: periodDays,
          ),
        );
      }
      periodStart = periodEnd.plusDays(1);
    }
    return result;
  }

  /// Period key for the period starting on [start].
  static String periodKey(PeriodUnit unit, LocalDate start) => switch (unit) {
    PeriodUnit.day => 'day:${start.toIso()}',
    PeriodUnit.week => 'week:${start.toIso()}',
    PeriodUnit.month => 'month:${start.toIso().substring(0, start.toIso().length - 3)}',
    PeriodUnit.year => 'year:${start.toIso().substring(0, start.toIso().length - 6)}',
  };

  static LocalDate _periodStart(PeriodUnit unit, LocalDate day, Weekday weekStart) => switch (unit) {
    PeriodUnit.day => day,
    PeriodUnit.week => day.startOfWeek(weekStart),
    PeriodUnit.month => day.firstDayOfMonth,
    PeriodUnit.year => LocalDate(day.year, 1, 1),
  };

  static LocalDate _periodEnd(PeriodUnit unit, LocalDate start) => switch (unit) {
    PeriodUnit.day => start,
    PeriodUnit.week => start.plusDays(6),
    PeriodUnit.month => start.lastDayOfMonth,
    PeriodUnit.year => LocalDate(start.year, 12, 31),
  };

  Iterable<Occurrence> _quotaSlots(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime fromLocal,
    LocalDateTime toLocal,
    String? evalZone,
    int durationMinutes,
  ) sync* {
    if (!toLocal.isAfter(fromLocal)) return;
    final lastDay = toLocal.plusMinutes(-1).date;
    final zone = zoneFor(anchor, evalZone);
    final time = anchor.allDay ? LocalDateTime(anchor.start.date, anchor.start.time).time : anchor.start.time;
    for (final period in periods(rule, anchor, fromLocal.date, lastDay)) {
      if (period.activeEnd.isBefore(fromLocal.date)) continue;
      final start = anchor.allDay ? period.activeStart.atStartOfDay : period.activeStart.atTime(time);
      for (var n = 1; n <= period.requiredCount; n++) {
        yield _build(anchor, zone, start, durationMinutes, key: period.completionKey(n));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // After-completion rules.

  /// When an after-completion series is next due.
  ///
  /// Never completed ([lastCompletion] null) → the anchor. Otherwise the
  /// completion instant is converted to the owner's wall clock and the delay is
  /// added with calendar arithmetic; day-based units keep the anchor's time of
  /// day (month/year units clamp to the month's last day). Returns null when
  /// the due time is after `until`.
  Occurrence? nextDue(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    DateTime? lastCompletion, {
    String? evalZone,
    int? durationMinutes,
  }) {
    final after = _requireAfterCompletion(rule);
    final zone = zoneFor(anchor, evalZone);
    LocalDateTime due;
    if (lastCompletion == null) {
      due = anchor.start;
    } else {
      final done = resolver.toLocal(lastCompletion, zone);
      final time = anchor.start.time;
      final amount = after.amount;
      due = switch (after.unit) {
        RecurrenceUnit.minute => done.plusMinutes(amount),
        RecurrenceUnit.hour => done.plusHours(amount),
        RecurrenceUnit.day => done.date.plusDays(amount).atTime(time),
        RecurrenceUnit.week => done.date.plusDays(amount * 7).atTime(time),
        RecurrenceUnit.month => done.date.plusMonths(amount).atTime(time),
        RecurrenceUnit.year => done.date.plusYears(amount).atTime(time),
      };
    }
    if (anchor.allDay) due = due.date.atStartOfDay;
    final until = rule.until;
    if (until != null && due.isAfter(until)) return null;
    return _build(anchor, zone, due, durationMinutes ?? anchor.effectiveDurationMinutes);
  }

  AfterCompletion _requireAfterCompletion(RecurrenceRule rule) {
    final after = rule.afterCompletion;
    if (rule.type != RuleType.afterCompletion || after == null) {
      throw ArgumentError.value(rule, 'rule', 'needs an after-completion rule');
    }
    if (after.amount < 1) {
      throw InvalidRuleException([
        RuleIssue(RuleIssueCode.valueOutOfRange, field: 'afterCompletion.amount', params: {'value': after.amount}),
      ]);
    }
    return after;
  }
}
