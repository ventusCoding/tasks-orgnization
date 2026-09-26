import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show DayBoundaries, FunctionZoneClock, HabitGoal, HabitPeriod, HabitPeriodKind;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// How a schedule produces periods (arch §6.8, T5.1.05).
enum ScheduleShape {
  /// One period per local day (`YYYY-MM-DD`).
  day,

  /// Several intraday slots per day (`YYYY-MM-DDTHH:mm`): fixed times or interval windows.
  slot,

  /// N completions per week / month (`week:YYYY-MM-DD`, `month:YYYY-MM`).
  quota,

  /// Due N units after the last completion (T5.1.17).
  afterCompletion;

  static ScheduleShape of(RecurrenceRule rule) => switch (rule.type) {
    RuleType.quota => ScheduleShape.quota,
    RuleType.afterCompletion => ScheduleShape.afterCompletion,
    RuleType.fixed =>
      rule.freq.isSubDaily || rule.times.isNotEmpty || rule.byHour.isNotEmpty || rule.byMinute.isNotEmpty
          ? ScheduleShape.slot
          : ScheduleShape.day,
  };
}

/// A span of dates governed by one set of rules (a revision, or the habit's current values).
@immutable
class RuleSegment {
  const RuleSegment(this.start, this.end, this.rules);

  /// First date of the segment (also the schedule anchor: "every N days" counts from here).
  final LocalDate start;

  /// Last date (inclusive); null = open-ended.
  final LocalDate? end;
  final HabitRules rules;

  bool covers(LocalDate date) => !date.isBefore(start) && (end == null || !date.isAfter(end!));

  @override
  bool operator ==(Object other) =>
      other is RuleSegment && other.start == start && other.end == end && other.rules == rules;

  @override
  int get hashCode => Object.hash(start, end, rules);

  @override
  String toString() => 'RuleSegment($start..${end ?? '∞'})';
}

/// Turns a habit's revision-aware schedule into concrete periods (T5.1.05): day periods, intraday
/// slot periods and quota periods, each with its key, local dates and instant window.
///
/// - Keys (arch §6.8): day `YYYY-MM-DD`; slot `YYYY-MM-DDTHH:mm` (wall clock); quota
///   `week:YYYY-MM-DD` (period start, honouring the week start) or `month:YYYY-MM`.
/// - Day window = `[D @ dayStartsAt, D+1 @ dayStartsAt)` in the effective zone (floating habits →
///   the current zone; fixed → the habit zone). With `dayStartsAt = 04:00` a 01:00 check-in belongs
///   to the previous day.
/// - Slot window = `[slot start − early tolerance, next slot start)` (never opening before the
///   previous slot starts); the last slot ends with the day.
/// - Quota periods are clipped (pro-rated) at the habit start/end and at revision boundaries; their
///   `eligibleDays` exclude weekdays outside `byWeekday` and exdates.
/// - Each period carries the revision in force at its start. A quota revision that takes effect
///   inside a period of the same unit applies from the next period (the period keeps one rule).
/// - Periods before `start_date` / after `end_date` are excluded.
class HabitPeriodService {
  HabitPeriodService({
    required this.engine,
    required this.currentZone,
    this.dayStartsAt = LocalTime.midnight,
    this.weekStart = Weekday.monday,
  });

  final RecurrenceEngine engine;

  /// Device zone: floating habits resolve here.
  final String currentZone;

  /// Start of the habit day (arch §9.1 `dayStartsAt`).
  final LocalTime dayStartsAt;
  final Weekday weekStart;

  /// Days expanded per engine call (keeps each call far below the engine's occurrence cap).
  static const _dayChunk = 3000;

  ZoneResolver get resolver => engine.resolver;

  /// Effective zone of [habit].
  String zoneOf(Habit habit) => habit.timeZone ?? currentZone;

  /// Local-day boundaries of [habit] (zone + day start).
  DayBoundaries boundariesOf(Habit habit) => boundariesIn(zoneOf(habit));

  DayBoundaries boundariesIn(String zone) => DayBoundaries(
    FunctionZoneClock((i) => resolver.toLocal(i, zone), (l) => resolver.resolve(l, zone).utc),
    dayStartsAt: dayStartsAt,
  );

  /// The habit date an [instant] belongs to.
  LocalDate dateOf(Habit habit, DateTime instant) => boundariesOf(habit).dateOf(instant);

  /// Day key of [instant] (`YYYY-MM-DD`).
  String dayKeyFor(Habit habit, DateTime instant) => dateOf(habit, instant).toIso();

  /// The rules segments of [habit] in chronological order, with their natural start (the
  /// schedule anchor) and end — never clipped to a query range.
  List<RuleSegment> segments(BuildHabit habit, List<HabitRevision> revisions) {
    final boundaries = <LocalDate>{
      for (final r in revisions)
        if (r.effectiveFrom.isAfter(habit.startDate) &&
            (habit.endDate == null || !r.effectiveFrom.isAfter(habit.endDate!)))
          r.effectiveFrom,
    }.toList()..sort();
    final natural = <RuleSegment>[];
    var start = habit.startDate;
    for (var i = 0; i <= boundaries.length; i++) {
      final end = i < boundaries.length ? boundaries[i].minusDays(1) : habit.endDate;
      final resolved = HabitRules.on(habit, revisions, start);
      natural.add(
        RuleSegment(
          start,
          end,
          HabitRules(
            schedule: resolved.schedule,
            goal: resolved.goal,
            anchorDate: start,
            revisionId: resolved.revisionId,
          ),
        ),
      );
      if (i < boundaries.length) start = boundaries[i];
    }
    return _deferQuotaSwitches(natural);
  }

  /// A quota revision that starts inside a period of the same unit applies from the next period.
  List<RuleSegment> _deferQuotaSwitches(List<RuleSegment> input) {
    final out = <RuleSegment>[];
    for (final seg in input) {
      if (out.isEmpty) {
        out.add(seg);
        continue;
      }
      final prev = out.last;
      final a = prev.rules.schedule;
      final b = seg.rules.schedule;
      final sameQuotaUnit =
          a.type == RuleType.quota && b.type == RuleType.quota && a.quota?.per == b.quota?.per && b.quota != null;
      if (!sameQuotaUnit || _isPeriodStart(b.quota!.per, seg.start)) {
        out.add(seg);
        continue;
      }
      final nextStart = _periodEnd(b.quota!.per, seg.start).plusDays(1);
      if (seg.end != null && nextStart.isAfter(seg.end!)) {
        // The whole segment lies in the previous rule's period: extend the previous segment.
        out[out.length - 1] = RuleSegment(prev.start, seg.end, prev.rules);
        continue;
      }
      out[out.length - 1] = RuleSegment(prev.start, nextStart.minusDays(1), prev.rules);
      out.add(
        RuleSegment(
          nextStart,
          seg.end,
          HabitRules(
            schedule: seg.rules.schedule,
            goal: seg.rules.goal,
            anchorDate: nextStart,
            revisionId: seg.rules.revisionId,
          ),
        ),
      );
    }
    return out;
  }

  bool _isPeriodStart(PeriodUnit unit, LocalDate d) => switch (unit) {
    PeriodUnit.day => true,
    PeriodUnit.week => d.startOfWeek(weekStart) == d,
    PeriodUnit.month => d.day == 1,
    PeriodUnit.year => d.month == 1 && d.day == 1,
  };

  LocalDate _periodEnd(PeriodUnit unit, LocalDate d) => switch (unit) {
    PeriodUnit.day => d,
    PeriodUnit.week => d.startOfWeek(weekStart).plusDays(6),
    PeriodUnit.month => d.lastDayOfMonth,
    PeriodUnit.year => LocalDate(d.year, 12, 31),
  };

  /// The rules in force on [date] (quota switches deferred as in [periods]).
  HabitRules rulesOn(BuildHabit habit, List<HabitRevision> revisions, LocalDate date) {
    for (final s in segments(habit, revisions).reversed) {
      if (!date.isBefore(s.start)) return s.rules;
    }
    return HabitRules.on(habit, revisions, date);
  }

  /// Periods of [habit] overlapping [from]…[to] (inclusive local dates), in chronological order.
  /// Quota periods may extend beyond [to] (the current week/month); slot periods are grouped by
  /// their logical date (`startDate`).
  List<HabitPeriod> periods(BuildHabit habit, List<HabitRevision> revisions, LocalDate from, LocalDate to) {
    final start = LocalDate.max(from, habit.startDate);
    final end = habit.endDate == null ? to : LocalDate.min(to, habit.endDate!);
    if (start.isAfter(end)) return const [];
    final out = <HabitPeriod>[];
    final b = boundariesOf(habit);
    for (final seg in segments(habit, revisions)) {
      final segEnd = seg.end;
      if (segEnd != null && segEnd.isBefore(start)) continue;
      if (seg.start.isAfter(end)) break;
      final cs = LocalDate.max(start, seg.start);
      final ce = segEnd == null ? end : LocalDate.min(end, segEnd);
      if (cs.isAfter(ce)) continue;
      switch (ScheduleShape.of(seg.rules.schedule)) {
        case ScheduleShape.day:
        case ScheduleShape.afterCompletion:
          out.addAll(_dayPeriods(habit, seg, cs, ce, b));
        case ScheduleShape.slot:
          out.addAll(_slotPeriods(habit, seg, cs, ce, b));
        case ScheduleShape.quota:
          for (final p in _quotaPeriods(habit, seg, cs, ce, b)) {
            if (out.isEmpty || out.last.key != p.key) out.add(p);
          }
      }
    }
    return out;
  }

  HabitGoal _goalOn(BuildHabit habit, HabitRules rules, LocalDate date) {
    final progression = habit.settings.targetProgression;
    if (progression != null && rules.goal.isMeasurable) {
      return rules.goal.toMetrics(overrideTarget: progression.targetOn(habit.startDate, date));
    }
    return rules.goal.toMetrics();
  }

  List<HabitPeriod> _dayPeriods(BuildHabit habit, RuleSegment seg, LocalDate cs, LocalDate ce, DayBoundaries b) {
    final rule = seg.rules.schedule;
    final due = <LocalDate>{};
    if (rule.type == RuleType.afterCompletion) {
      // After-completion habits are due every day until done (evaluated with their logs).
      for (var d = cs; !d.isAfter(ce); d = d.plusDays(1)) {
        due.add(d);
      }
    } else {
      final anchor = RecurrenceAnchor.allDayOn(seg.start, habit.timeZone);
      final zone = zoneOf(habit);
      try {
        for (var chunk = cs; !chunk.isAfter(ce); chunk = chunk.plusDays(_dayChunk)) {
          final chunkEnd = LocalDate.min(ce, chunk.plusDays(_dayChunk - 1));
          for (final o in engine.between(
            rule,
            anchor,
            chunk.atStartOfDay,
            chunkEnd.plusDays(1).atStartOfDay,
            evalZone: zone,
          )) {
            due.add(o.date);
          }
        }
      } on InvalidRuleException {
        // An invalid rule has no due day (the editor never saves one).
      }
    }
    return [
      for (var d = cs; !d.isAfter(ce); d = d.plusDays(1))
        HabitPeriod(
          d.toIso(),
          kind: HabitPeriodKind.day,
          startDate: d,
          endDate: d,
          windowStart: b.startOf(d),
          windowEnd: b.endOf(d),
          goal: _goalOn(habit, seg.rules, d),
          revisionId: seg.rules.revisionId,
          due: due.contains(d),
        ),
    ];
  }

  List<HabitPeriod> _slotPeriods(BuildHabit habit, RuleSegment seg, LocalDate cs, LocalDate ce, DayBoundaries b) {
    final rule = seg.rules.schedule;
    final zone = zoneOf(habit);
    final anchor = RecurrenceAnchor(seg.start.atStartOfDay, habit.timeZone);
    final tolerance = Duration(minutes: habit.settings.earlyToleranceMinutes);
    final byDate = <LocalDate, List<Occurrence>>{};
    final dayStart = dayStartsAt.minuteOfDay;
    final chunkDays = _slotChunkDays(rule);
    try {
      // Chunks sized to the rule density keep every call far below the engine cap.
      for (var chunk = cs; !chunk.isAfter(ce); chunk = chunk.plusDays(chunkDays)) {
        final chunkEnd = LocalDate.min(ce, chunk.plusDays(chunkDays - 1));
        for (final o in engine.between(
          rule,
          anchor,
          chunk.atTime(dayStartsAt),
          chunkEnd.plusDays(1).atTime(dayStartsAt),
          evalZone: zone,
          durationMinutes: 0,
        )) {
          final logical = o.startLocal.plusMinutes(-dayStart).date;
          if (logical.isBefore(cs) || logical.isAfter(ce)) continue;
          byDate.putIfAbsent(logical, () => []).add(o);
        }
      }
    } on Object {
      // Invalid or runaway rules have no slot (the editor never saves one).
      return const [];
    }
    final out = <HabitPeriod>[];
    final dates = byDate.keys.toList()..sort();
    for (final d in dates) {
      final slots = byDate[d]!..sort((x, y) => x.startUtc.compareTo(y.startUtc));
      final dayEnd = b.endOf(d);
      final goal = _goalOn(habit, seg.rules, d);
      for (var i = 0; i < slots.length; i++) {
        final o = slots[i];
        var open = o.startUtc.subtract(tolerance);
        if (i > 0 && open.isBefore(slots[i - 1].startUtc)) open = slots[i - 1].startUtc;
        out.add(
          HabitPeriod(
            o.key,
            kind: HabitPeriodKind.slot,
            startDate: d,
            endDate: d,
            windowStart: open,
            windowEnd: i + 1 < slots.length ? slots[i + 1].startUtc : dayEnd,
            goal: goal,
            revisionId: seg.rules.revisionId,
          ),
        );
      }
    }
    return out;
  }

  /// Days per engine call for a slot rule (≈ 5 000 occurrences at most).
  static int _slotChunkDays(RecurrenceRule rule) {
    final step = rule.interval < 1 ? 1 : rule.interval;
    final w = rule.window;
    final span = w == null ? 1440 : (w.end.minuteOfDay - w.start.minuteOfDay + 1).clamp(1, 1440);
    final perDay = switch (rule.freq) {
      Frequency.minutely => (span / step).ceil(),
      Frequency.hourly => (span / (60 * step)).ceil(),
      _ => (rule.times.isEmpty ? 1 : rule.times.length) *
          (rule.byHour.isEmpty ? 1 : rule.byHour.length) *
          (rule.byMinute.isEmpty ? 1 : rule.byMinute.length),
    };
    return (5000 ~/ (perDay < 1 ? 1 : perDay)).clamp(1, 31);
  }

  List<HabitPeriod> _quotaPeriods(BuildHabit habit, RuleSegment seg, LocalDate cs, LocalDate ce, DayBoundaries b) {
    final rule = seg.rules.schedule;
    final quota = rule.quota;
    if (quota == null) return const [];
    final anchor = RecurrenceAnchor.allDayOn(seg.start, habit.timeZone);
    var until = rule.until;
    final segEnd = seg.end;
    if (segEnd != null) {
      final segUntil = segEnd.atTime(LocalTime(23, 59));
      if (until == null || segUntil.isBefore(until)) until = segUntil;
    }
    final clipped = until == rule.until ? rule : rule.copyWith(until: until);
    final allowed = rule.byWeekday == null ? null : {for (final w in rule.byWeekday!) w.day};
    final excluded = {
      for (final x in rule.exdates)
        if (LocalDate.tryParse(x.length >= 10 ? x.substring(0, 10) : x) case final d?) d,
    };
    final List<Period> raw;
    try {
      raw = engine.periods(clipped, anchor, cs, ce, weekStart: weekStart);
    } on Object {
      return const [];
    }
    return [
      for (final p in raw)
        HabitPeriod(
          p.key,
          kind: HabitPeriodKind.quota,
          startDate: p.activeStart,
          endDate: p.activeEnd,
          windowStart: b.startOf(p.activeStart),
          windowEnd: b.endOf(p.activeEnd),
          goal: _goalOn(habit, seg.rules, p.activeStart),
          revisionId: seg.rules.revisionId,
          quotaTimes: quota.times,
          minPerDay: habit.settings.minPerDay,
          eligibleDays: [
            for (var d = p.activeStart; !d.isAfter(p.activeEnd); d = d.plusDays(1))
              if ((allowed == null || allowed.contains(d.weekday)) && !excluded.contains(d)) d,
          ],
          fullEligibleDays: p.periodDays,
        ),
    ];
  }

  /// The period an [instant] falls in: the day period, the slot targeted by "check now" (the
  /// latest slot whose early window has opened) or the quota period. Null when nothing applies
  /// (before the habit starts, before today's first slot, after the end date).
  HabitPeriod? periodForInstant(BuildHabit habit, List<HabitRevision> revisions, DateTime instant) {
    final date = dateOf(habit, instant);
    final ps = periods(habit, revisions, date, date);
    if (ps.isEmpty) return null;
    final first = ps.first;
    switch (first.kind) {
      case HabitPeriodKind.day:
        return first;
      case HabitPeriodKind.slot:
        HabitPeriod? found;
        for (final p in ps) {
          if (p.startDate == date && !p.windowStart.isAfter(instant)) found = p;
        }
        return found;
      case HabitPeriodKind.quota:
        for (final p in ps) {
          if (!date.isBefore(p.startDate) && !date.isAfter(p.endDate)) return p;
        }
        return null;
    }
  }

  /// The current period ([periodForInstant] at [now]).
  HabitPeriod? currentPeriod(BuildHabit habit, List<HabitRevision> revisions, DateTime now) =>
      periodForInstant(habit, revisions, now);

  /// The period with [key] (day, slot or quota key), or null.
  HabitPeriod? periodForKey(BuildHabit habit, List<HabitRevision> revisions, String key) {
    final LocalDate? date;
    if (key.startsWith('week:')) {
      date = LocalDate.tryParse(key.substring(5));
    } else if (key.startsWith('month:')) {
      date = LocalDate.tryParse('${key.substring(6)}-01');
    } else {
      date = LocalDate.tryParse(key.length >= 10 ? key.substring(0, 10) : key);
    }
    if (date == null) return null;
    // A slot before the day start belongs to the previous logical day.
    for (final p in periods(habit, revisions, date.minusDays(1), date.plusDays(1))) {
      if (p.key == key) return p;
    }
    // A quota period clipped at the habit start keeps its full-period key.
    if (key.startsWith('week:') || key.startsWith('month:')) {
      for (final p in periods(habit, revisions, date, date.plusDays(31))) {
        if (p.key == key) return p;
      }
    }
    return null;
  }

  /// Slot periods (or the single day period) of [date].
  List<HabitPeriod> periodsOn(BuildHabit habit, List<HabitRevision> revisions, LocalDate date) => [
    for (final p in periods(habit, revisions, date, date))
      if (p.kind != HabitPeriodKind.quota || (!date.isBefore(p.startDate) && !date.isAfter(p.endDate))) p,
  ];

  /// Maximum number of slots on one day over the next [days] days from [from] (editor warnings).
  int maxSlotsPerDay(BuildHabit habit, List<HabitRevision> revisions, LocalDate from, {int days = 7}) {
    final counts = <LocalDate, int>{};
    for (final p in periods(habit, revisions, from, from.plusDays(days - 1))) {
      if (p.kind == HabitPeriodKind.slot) counts[p.startDate] = (counts[p.startDate] ?? 0) + 1;
    }
    return counts.values.fold(0, (a, b) => a > b ? a : b);
  }

  /// Due periods from [from] onwards (live editor preview: "next 10 periods").
  List<HabitPeriod> upcoming(BuildHabit habit, List<HabitRevision> revisions, LocalDate from, {int count = 10}) {
    final out = <HabitPeriod>[];
    var cursor = from;
    for (var guard = 0; out.length < count && guard < 40; guard++) {
      final end = cursor.plusDays(30);
      for (final p in periods(habit, revisions, cursor, end)) {
        if (!p.due) continue;
        if (p.kind == HabitPeriodKind.quota && out.any((q) => q.key == p.key)) continue;
        out.add(p);
        if (out.length >= count) break;
      }
      cursor = end.plusDays(1);
      if (habit.endDate != null && cursor.isAfter(habit.endDate!)) break;
    }
    return out;
  }
}
