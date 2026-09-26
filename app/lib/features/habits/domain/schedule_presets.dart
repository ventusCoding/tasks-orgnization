import 'package:collection/collection.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Schedule presets of the habit editor (T5.1.08). Every preset maps to a rule of arch §8.1 and
/// back, so reopening a habit shows the same preset instead of "Custom".
enum SchedulePresetKind {
  daily,
  weekdays,
  weekends,
  specificDays,
  everyNDays,
  timesPerWeek,
  timesPerMonth,

  /// `daily` + a count goal ≥ N "times" (8 glasses of water at any time).
  timesPerDay,

  /// `daily` + `times` (slot periods: medication at 08:00 and 20:00).
  specificTimes,

  /// `hourly`/`minutely` + window (stand up every hour 09:00–18:00).
  interval,

  /// `monthly` + `byMonthDay` (day X, or -1 = last day).
  monthlyDay,

  /// `monthly` + `byWeekday` with an ordinal (2nd Tuesday, last Friday).
  monthlyWeekday,

  /// `after_completion` (water the plants 3 days after the last time).
  afterCompletion,

  /// Any other rule the engine supports.
  custom,
}

const _weekdays = [Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday];
const _weekend = [Weekday.saturday, Weekday.sunday];
const _setEq = SetEquality<Weekday>();

/// A preset with its parameters.
@immutable
class SchedulePreset {
  const SchedulePreset(
    this.kind, {
    this.days = const [],
    this.n = 1,
    this.times = const [],
    this.everyMinutes = 60,
    this.windowStart,
    this.windowEnd,
    this.monthDay = 1,
    this.ordinal = 1,
    this.weekday = Weekday.monday,
    this.afterUnit = RecurrenceUnit.day,
    this.customRule,
  });

  const SchedulePreset.daily() : this(SchedulePresetKind.daily);

  final SchedulePresetKind kind;

  /// Weekdays (specific days, optional filter of times/interval presets).
  final List<Weekday> days;

  /// N of "every N days", "N× per week/month", "N times per day", after-completion amount.
  final int n;
  final List<LocalTime> times;
  final int everyMinutes;
  final LocalTime? windowStart;
  final LocalTime? windowEnd;

  /// 1…31, or -1 = last day of the month.
  final int monthDay;

  /// 1…4 or -1 (last) for monthly weekday presets.
  final int ordinal;
  final Weekday weekday;
  final RecurrenceUnit afterUnit;
  final RecurrenceRule? customRule;

  /// Whether this preset yields slot periods (several check-ins per day at given times).
  bool get isSlotBased => kind == SchedulePresetKind.specificTimes || kind == SchedulePresetKind.interval;

  /// Whether choosing this preset changes the goal (N times per day → count ≥ N "times").
  bool get impliesCountGoal => kind == SchedulePresetKind.timesPerDay;

  /// The rule of arch §8.1 for this preset. [weekStart] is written as `wkst` of weekly rules with an
  /// interval so weeks align with the user's week start.
  RecurrenceRule toRule({Weekday weekStart = Weekday.monday}) {
    List<WeekdayRule>? filter() => days.isEmpty ? null : [for (final d in _sorted(days)) WeekdayRule(d)];
    switch (kind) {
      case SchedulePresetKind.daily:
      case SchedulePresetKind.timesPerDay:
        return RecurrenceRule();
      case SchedulePresetKind.weekdays:
        return RecurrenceRule(freq: Frequency.weekly, byWeekday: [for (final d in _weekdays) WeekdayRule(d)]);
      case SchedulePresetKind.weekends:
        return RecurrenceRule(freq: Frequency.weekly, byWeekday: [for (final d in _weekend) WeekdayRule(d)]);
      case SchedulePresetKind.specificDays:
        return RecurrenceRule(
          freq: Frequency.weekly,
          byWeekday: [for (final d in _sorted(days.isEmpty ? const [Weekday.monday] : days)) WeekdayRule(d)],
        );
      case SchedulePresetKind.everyNDays:
        return RecurrenceRule(interval: n < 1 ? 1 : n);
      case SchedulePresetKind.timesPerWeek:
        return RecurrenceRule.forQuota(n < 1 ? 1 : n, PeriodUnit.week);
      case SchedulePresetKind.timesPerMonth:
        return RecurrenceRule.forQuota(n < 1 ? 1 : n, PeriodUnit.month);
      case SchedulePresetKind.specificTimes:
        final sorted = [...times]..sort();
        return RecurrenceRule(times: sorted.isEmpty ? [LocalTime(8, 0)] : sorted, byWeekday: filter());
      case SchedulePresetKind.interval:
        final minutes = everyMinutes < 1 ? 60 : everyMinutes;
        final hourly = minutes % 60 == 0;
        return RecurrenceRule(
          freq: hourly ? Frequency.hourly : Frequency.minutely,
          interval: hourly ? minutes ~/ 60 : minutes,
          window: DailyWindow(windowStart ?? LocalTime(9, 0), windowEnd ?? LocalTime(18, 0)),
          byWeekday: filter(),
        );
      case SchedulePresetKind.monthlyDay:
        return RecurrenceRule(freq: Frequency.monthly, byMonthDay: [monthDay]);
      case SchedulePresetKind.monthlyWeekday:
        return RecurrenceRule(freq: Frequency.monthly, byWeekday: [WeekdayRule(weekday, ordinal)]);
      case SchedulePresetKind.afterCompletion:
        return RecurrenceRule.forAfterCompletion(n < 1 ? 1 : n, afterUnit);
      case SchedulePresetKind.custom:
        return customRule ?? RecurrenceRule();
    }
  }

  /// Recognizes the preset of [rule] (with the habit's [goal] for "N times per day").
  static SchedulePreset fromRule(RecurrenceRule rule, {HabitTarget? goal}) {
    SchedulePreset custom() => SchedulePreset(SchedulePresetKind.custom, customRule: rule);
    final noBounds =
        rule.until == null &&
        rule.count == null &&
        rule.exdates.isEmpty &&
        rule.rdates.isEmpty &&
        rule.extra.isEmpty;
    if (!noBounds) return custom();
    switch (rule.type) {
      case RuleType.quota:
        final quota = rule.quota;
        if (quota == null || quota.minGapDays != 0 || rule.byWeekday != null) return custom();
        if (quota.per == PeriodUnit.week) return SchedulePreset(SchedulePresetKind.timesPerWeek, n: quota.times);
        if (quota.per == PeriodUnit.month) return SchedulePreset(SchedulePresetKind.timesPerMonth, n: quota.times);
        return custom();
      case RuleType.afterCompletion:
        final after = rule.afterCompletion;
        if (after == null || !after.unit.isDayBased) return custom();
        return SchedulePreset(SchedulePresetKind.afterCompletion, n: after.amount, afterUnit: after.unit);
      case RuleType.fixed:
        break;
    }
    final noParts =
        rule.byMonthDay.isEmpty &&
        rule.byMonth.isEmpty &&
        rule.byYearDay.isEmpty &&
        rule.byWeekNo.isEmpty &&
        rule.bySetPos.isEmpty &&
        rule.byHour.isEmpty &&
        rule.byMinute.isEmpty &&
        rule.afterCompletion == null &&
        rule.quota == null;
    final plainDays = rule.byWeekday == null || rule.byWeekday!.every((w) => w.n == null);
    final daySet = {for (final w in rule.byWeekday ?? const <WeekdayRule>[]) w.day};
    switch (rule.freq) {
      case Frequency.daily:
        if (!noParts || rule.window != null || !plainDays) return custom();
        if (rule.times.isNotEmpty) {
          if (rule.interval != 1) return custom();
          return SchedulePreset(
            SchedulePresetKind.specificTimes,
            times: rule.times,
            days: _sorted(daySet),
          );
        }
        if (rule.byWeekday != null) {
          if (rule.interval != 1 || daySet.isEmpty) return custom();
          return _weeklyPreset(daySet);
        }
        if (rule.interval > 1) return SchedulePreset(SchedulePresetKind.everyNDays, n: rule.interval);
        if (goal != null &&
            goal.type == HabitGoalType.count &&
            goal.op == TargetOp.gte &&
            goal.unit == 'times' &&
            (goal.target ?? 0) >= 1) {
          return SchedulePreset(SchedulePresetKind.timesPerDay, n: goal.target!.round());
        }
        return const SchedulePreset.daily();
      case Frequency.weekly:
        if (!noParts || rule.window != null || rule.times.isNotEmpty || rule.interval != 1 || !plainDays) {
          return custom();
        }
        if (rule.byWeekday == null || daySet.isEmpty) return custom();
        return _weeklyPreset(daySet);
      case Frequency.hourly:
      case Frequency.minutely:
        final window = rule.window;
        if (!noParts || window == null || rule.times.isNotEmpty || !plainDays) return custom();
        if (window.anchor != WindowAnchor.windowStart || window.end.isEndOfDay) return custom();
        final minutes = rule.freq == Frequency.hourly ? rule.interval * 60 : rule.interval;
        return SchedulePreset(
          SchedulePresetKind.interval,
          everyMinutes: minutes,
          windowStart: window.start,
          windowEnd: window.end,
          days: _sorted(daySet),
        );
      case Frequency.monthly:
        final onlyMonthParts =
            rule.byMonth.isEmpty &&
            rule.byYearDay.isEmpty &&
            rule.byWeekNo.isEmpty &&
            rule.bySetPos.isEmpty &&
            rule.byHour.isEmpty &&
            rule.byMinute.isEmpty &&
            rule.times.isEmpty &&
            rule.window == null &&
            rule.interval == 1;
        if (!onlyMonthParts) return custom();
        if (rule.byWeekday == null && rule.byMonthDay.length == 1) {
          final d = rule.byMonthDay.single;
          if ((d >= 1 && d <= 31) || d == -1) return SchedulePreset(SchedulePresetKind.monthlyDay, monthDay: d);
        }
        if (rule.byMonthDay.isEmpty && rule.byWeekday?.length == 1) {
          final w = rule.byWeekday!.single;
          final n = w.n;
          if (n != null && ((n >= 1 && n <= 4) || n == -1)) {
            return SchedulePreset(SchedulePresetKind.monthlyWeekday, ordinal: n, weekday: w.day);
          }
        }
        return custom();
      case Frequency.yearly:
        return custom();
    }
  }

  static SchedulePreset _weeklyPreset(Set<Weekday> days) {
    if (days.length == 7) return const SchedulePreset.daily();
    if (_setEq.equals(days, _weekdays.toSet())) return const SchedulePreset(SchedulePresetKind.weekdays);
    if (_setEq.equals(days, _weekend.toSet())) return const SchedulePreset(SchedulePresetKind.weekends);
    return SchedulePreset(SchedulePresetKind.specificDays, days: _sorted(days));
  }

  static List<Weekday> _sorted(Iterable<Weekday> days) => days.toSet().toList()..sort((a, b) => a.iso - b.iso);

  /// Applies the goal side effect of a preset: "N times per day" turns the goal into count ≥ N
  /// "times"; leaving that preset turns a "times" count back into a yes/no goal.
  HabitTarget adaptGoal(HabitTarget goal) {
    if (kind == SchedulePresetKind.timesPerDay) {
      return HabitTarget(type: HabitGoalType.count, target: n.toDouble(), unit: 'times');
    }
    if (goal.type == HabitGoalType.count && goal.unit == 'times' && goal.op == TargetOp.gte) {
      return const HabitTarget.check();
    }
    return goal;
  }

  SchedulePreset copyWith({
    List<Weekday>? days,
    int? n,
    List<LocalTime>? times,
    int? everyMinutes,
    LocalTime? windowStart,
    LocalTime? windowEnd,
    int? monthDay,
    int? ordinal,
    Weekday? weekday,
    RecurrenceUnit? afterUnit,
  }) => SchedulePreset(
    kind,
    days: days ?? this.days,
    n: n ?? this.n,
    times: times ?? this.times,
    everyMinutes: everyMinutes ?? this.everyMinutes,
    windowStart: windowStart ?? this.windowStart,
    windowEnd: windowEnd ?? this.windowEnd,
    monthDay: monthDay ?? this.monthDay,
    ordinal: ordinal ?? this.ordinal,
    weekday: weekday ?? this.weekday,
    afterUnit: afterUnit ?? this.afterUnit,
    customRule: customRule,
  );

  @override
  bool operator ==(Object other) =>
      other is SchedulePreset &&
      other.kind == kind &&
      const ListEquality<Weekday>().equals(other.days, days) &&
      other.n == n &&
      const ListEquality<LocalTime>().equals(other.times, times) &&
      other.everyMinutes == everyMinutes &&
      other.windowStart == windowStart &&
      other.windowEnd == windowEnd &&
      other.monthDay == monthDay &&
      other.ordinal == ordinal &&
      other.weekday == weekday &&
      other.afterUnit == afterUnit &&
      other.customRule == customRule;

  @override
  int get hashCode => Object.hash(
    kind,
    Object.hashAll(days),
    n,
    Object.hashAll(times),
    everyMinutes,
    windowStart,
    windowEnd,
    monthDay,
    ordinal,
    weekday,
    afterUnit,
    customRule,
  );

  @override
  String toString() => 'SchedulePreset(${kind.name}, n: $n)';
}
