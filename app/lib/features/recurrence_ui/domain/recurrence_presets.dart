import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Where the recurrence picker is used (T2.1.15). Decides which presets and rule types are
/// offered: quota presets only for habits, after-completion for tasks and habits, and
/// *Does not repeat* everywhere except habits (a habit always has a schedule).
enum RecurrencePickerMode {
  /// Planner tasks.
  task,

  /// Habit schedules.
  habit,

  /// Checklist reset rules.
  checklistReset,

  /// Notification schedules.
  reminder;

  /// *Does not repeat* is offered.
  bool get allowsNone => this != habit;

  /// The *N times per week/month* preset is offered.
  bool get offersQuotaPreset => this == habit;

  /// After-completion rules are offered (presets and advanced editor).
  bool get allowsAfterCompletion => this == task || this == habit;

  /// Rule types the advanced editor offers. Planner tasks also accept quota rules through the
  /// advanced editor (T3.2.16); the quota *preset* stays habit-only.
  List<RuleType> get ruleTypes => switch (this) {
    task || habit => const [RuleType.fixed, RuleType.afterCompletion, RuleType.quota],
    checklistReset || reminder => const [RuleType.fixed],
  };
}

/// What the recurrence picker returns: the rule and the anchor aligned with it.
@immutable
class RecurrencePickResult {
  const RecurrencePickResult({required this.rule, required this.anchor});

  /// The chosen rule; null = *Does not repeat*.
  final RecurrenceRule? rule;

  /// The anchor moved to the rule's first occurrence (e.g. to Tuesday for "weekly on Tuesday"
  /// picked on a Monday). Callers owning a start date (task editor) apply it.
  final RecurrenceAnchor anchor;

  bool get repeats => rule != null;

  @override
  bool operator ==(Object other) => other is RecurrencePickResult && other.rule == rule && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(rule, anchor);

  @override
  String toString() => 'RecurrencePickResult($rule, $anchor)';
}

/// One entry of the presets sheet (T2.1.15).
enum RecurrencePreset {
  none,
  daily,
  weekdays,
  weekly,
  specificDays,
  everyNDays,
  monthlyOnDay,
  monthlyOnNthWeekday,
  monthlyOnLastWeekday,
  lastDayOfMonth,
  yearly,
  intraday,
  timesPerDay,
  quota,
  afterCompletion,
  custom;

  /// Presets that need extra input, shown inline when selected.
  bool get hasParams => switch (this) {
    specificDays || everyNDays || intraday || timesPerDay || quota || afterCompletion => true,
    _ => false,
  };
}

/// How a series ends ("Ends: never / on date / after N times").
enum RecurrenceEndKind { never, onDate, afterCount }

/// The *Ends* part of a rule (`until` / `count`).
@immutable
class RecurrenceEnds {
  const RecurrenceEnds.never() : kind = RecurrenceEndKind.never, until = null, count = null;

  const RecurrenceEnds.until(LocalDateTime this.until) : kind = RecurrenceEndKind.onDate, count = null;

  const RecurrenceEnds.after(int this.count) : kind = RecurrenceEndKind.afterCount, until = null;

  /// The ends of [rule] (never when null or open-ended).
  factory RecurrenceEnds.of(RecurrenceRule? rule) {
    final until = rule?.until;
    if (until != null) return RecurrenceEnds.until(until);
    final count = rule?.count;
    if (count != null) return RecurrenceEnds.after(count);
    return const RecurrenceEnds.never();
  }

  /// "Ends on [date]": the last allowed start is that day at 23:59 (inclusive).
  factory RecurrenceEnds.onDate(LocalDate date) => RecurrenceEnds.until(date.atTime(LocalTime(23, 59)));

  final RecurrenceEndKind kind;
  final LocalDateTime? until;
  final int? count;

  /// [rule] with these ends (count mode is kept).
  RecurrenceRule applyTo(RecurrenceRule rule) => switch (kind) {
    RecurrenceEndKind.never => rule.copyWith(until: null, count: null),
    RecurrenceEndKind.onDate => rule.copyWith(until: until, count: null),
    RecurrenceEndKind.afterCount => rule.copyWith(until: null, count: count),
  };

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEnds && other.kind == kind && other.until == until && other.count == count;

  @override
  int get hashCode => Object.hash(kind, until, count);
}

/// Inputs of the parameterized presets (specific days, every N days, intraday, times per day,
/// quota, after completion).
@immutable
class PresetParams {
  const PresetParams({
    required this.days,
    required this.window,
    required this.times,
    this.everyDays = 2,
    this.stepMinutes = 60,
    this.quotaTimes = 3,
    this.quotaPer = PeriodUnit.week,
    this.quotaMinGapDays = 0,
    this.afterAmount = 1,
    this.afterUnit = RecurrenceUnit.day,
  });

  /// Defaults for [anchor], overridden by the values found in [rule] (so re-opening the sheet
  /// shows the current configuration).
  factory PresetParams.initial(RecurrenceAnchor anchor, [RecurrenceRule? rule]) {
    final start = anchor.start;
    var params = PresetParams(
      days: {start.date.weekday},
      window: defaultWindow,
      times: _dedupeSorted([start.time, start.time.plusMinutesWrapped(12 * 60)]),
    );
    if (rule == null) return params;
    switch (rule.type) {
      case RuleType.quota:
        final q = rule.quota;
        if (q != null) {
          params = params.copyWith(quotaTimes: q.times, quotaPer: q.per, quotaMinGapDays: q.minGapDays);
        }
      case RuleType.afterCompletion:
        final a = rule.afterCompletion;
        if (a != null) params = params.copyWith(afterAmount: a.amount, afterUnit: a.unit);
      case RuleType.fixed:
        final weekdays = rule.byWeekday;
        if (rule.freq == Frequency.weekly && weekdays != null && weekdays.isNotEmpty) {
          params = params.copyWith(days: {for (final w in weekdays) w.day});
        }
        if (rule.freq == Frequency.daily && rule.interval > 1) {
          params = params.copyWith(everyDays: rule.interval);
        }
        if (rule.freq.isSubDaily) {
          params = params.copyWith(
            stepMinutes: rule.interval * (rule.freq == Frequency.hourly ? 60 : 1),
            window: rule.window,
          );
        }
        if (rule.times.isNotEmpty) params = params.copyWith(times: _dedupeSorted(rule.times));
    }
    return params;
  }

  /// Default daily window of the intraday preset (08:00–20:00, restarting each day).
  static final DailyWindow defaultWindow = DailyWindow(LocalTime(8, 0), LocalTime(20, 0));

  /// Quick steps of the intraday preset (minutes).
  static const List<int> quickSteps = [15, 30, 45, 60, 90, 120, 180, 240];

  /// Specific days (weekly).
  final Set<Weekday> days;

  /// Every N days (≥ 2).
  final int everyDays;

  /// Intraday step in minutes (≥ 1).
  final int stepMinutes;

  /// Intraday window; null = the whole day (one continuous chain from the start).
  final DailyWindow? window;

  /// Several times a day.
  final List<LocalTime> times;

  final int quotaTimes;
  final PeriodUnit quotaPer;
  final int quotaMinGapDays;
  final int afterAmount;
  final RecurrenceUnit afterUnit;

  PresetParams copyWith({
    Set<Weekday>? days,
    int? everyDays,
    int? stepMinutes,
    Object? window = _unset,
    List<LocalTime>? times,
    int? quotaTimes,
    PeriodUnit? quotaPer,
    int? quotaMinGapDays,
    int? afterAmount,
    RecurrenceUnit? afterUnit,
  }) => PresetParams(
    days: days ?? this.days,
    everyDays: everyDays ?? this.everyDays,
    stepMinutes: stepMinutes ?? this.stepMinutes,
    window: identical(window, _unset) ? this.window : window as DailyWindow?,
    times: times ?? this.times,
    quotaTimes: quotaTimes ?? this.quotaTimes,
    quotaPer: quotaPer ?? this.quotaPer,
    quotaMinGapDays: quotaMinGapDays ?? this.quotaMinGapDays,
    afterAmount: afterAmount ?? this.afterAmount,
    afterUnit: afterUnit ?? this.afterUnit,
  );

  @override
  bool operator ==(Object other) =>
      other is PresetParams &&
      _sameSet(other.days, days) &&
      other.everyDays == everyDays &&
      other.stepMinutes == stepMinutes &&
      other.window == window &&
      _sameList(other.times, times) &&
      other.quotaTimes == quotaTimes &&
      other.quotaPer == quotaPer &&
      other.quotaMinGapDays == quotaMinGapDays &&
      other.afterAmount == afterAmount &&
      other.afterUnit == afterUnit;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(days),
    everyDays,
    stepMinutes,
    window,
    Object.hashAll(times),
    quotaTimes,
    quotaPer,
    quotaMinGapDays,
    afterAmount,
    afterUnit,
  );
}

const Object _unset = Object();

bool _sameSet<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<LocalTime> _dedupeSorted(Iterable<LocalTime> times) => (times.toSet().toList()..sort());

/// Builds and recognizes the preset rules (T2.1.15). Pure: the sheet and its tests use it.
///
/// Anchor-derived presets (weekly, monthly on day N, yearly) are stored in their RFC 5545
/// minimal form (`{"freq": "weekly"}` …) so they keep following the task's start date;
/// multi-day, ordinal and last-day presets are explicit.
abstract final class RecurrencePresets {
  static const List<Weekday> workWeek = [
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
  ];

  /// Ordinal of [date]'s weekday inside its month (1 = first … 5 = fifth).
  static int nthWeekdayOfMonth(LocalDate date) => (date.day - 1) ~/ 7 + 1;

  /// Whether [date] is the last such weekday of its month.
  static bool isLastWeekdayOfMonth(LocalDate date) => date.day + 7 > LocalDate.daysInMonth(date.year, date.month);

  /// Presets offered for [mode] and [anchor], in display order.
  static List<RecurrencePreset> available(RecurrencePickerMode mode, RecurrenceAnchor anchor) {
    final date = anchor.start.date;
    return [
      if (mode.allowsNone) RecurrencePreset.none,
      RecurrencePreset.daily,
      RecurrencePreset.weekdays,
      RecurrencePreset.weekly,
      RecurrencePreset.specificDays,
      RecurrencePreset.everyNDays,
      RecurrencePreset.monthlyOnDay,
      if (nthWeekdayOfMonth(date) <= 4) RecurrencePreset.monthlyOnNthWeekday,
      if (isLastWeekdayOfMonth(date)) RecurrencePreset.monthlyOnLastWeekday,
      RecurrencePreset.lastDayOfMonth,
      RecurrencePreset.yearly,
      if (!anchor.allDay) ...[RecurrencePreset.intraday, RecurrencePreset.timesPerDay],
      if (mode.offersQuotaPreset) RecurrencePreset.quota,
      if (mode.allowsAfterCompletion) RecurrencePreset.afterCompletion,
      RecurrencePreset.custom,
    ];
  }

  /// The rule of [preset] (without bounds). Null for [RecurrencePreset.none] and
  /// [RecurrencePreset.custom] (the custom rule comes from the advanced editor).
  static RecurrenceRule? build(RecurrencePreset preset, RecurrenceAnchor anchor, PresetParams params) {
    final date = anchor.start.date;
    switch (preset) {
      case RecurrencePreset.none:
      case RecurrencePreset.custom:
        return null;
      case RecurrencePreset.daily:
        return RecurrenceRule(freq: Frequency.daily);
      case RecurrencePreset.weekdays:
        return RecurrenceRule(freq: Frequency.weekly, byWeekday: [for (final d in workWeek) WeekdayRule(d)]);
      case RecurrencePreset.weekly:
        return RecurrenceRule(freq: Frequency.weekly);
      case RecurrencePreset.specificDays:
        final days = params.days.toList()..sort((a, b) => a.iso.compareTo(b.iso));
        return RecurrenceRule(freq: Frequency.weekly, byWeekday: [for (final d in days) WeekdayRule(d)]);
      case RecurrencePreset.everyNDays:
        return RecurrenceRule(freq: Frequency.daily, interval: params.everyDays < 1 ? 1 : params.everyDays);
      case RecurrencePreset.monthlyOnDay:
        return RecurrenceRule(freq: Frequency.monthly);
      case RecurrencePreset.monthlyOnNthWeekday:
        return RecurrenceRule(freq: Frequency.monthly, byWeekday: [WeekdayRule(date.weekday, nthWeekdayOfMonth(date))]);
      case RecurrencePreset.monthlyOnLastWeekday:
        return RecurrenceRule(freq: Frequency.monthly, byWeekday: [WeekdayRule(date.weekday, -1)]);
      case RecurrencePreset.lastDayOfMonth:
        return RecurrenceRule(freq: Frequency.monthly, byMonthDay: const [-1]);
      case RecurrencePreset.yearly:
        return RecurrenceRule(freq: Frequency.yearly);
      case RecurrencePreset.intraday:
        final step = params.stepMinutes < 1 ? 1 : params.stepMinutes;
        final hourly = step % 60 == 0;
        return RecurrenceRule(
          freq: hourly ? Frequency.hourly : Frequency.minutely,
          interval: hourly ? step ~/ 60 : step,
          window: params.window,
        );
      case RecurrencePreset.timesPerDay:
        return RecurrenceRule(freq: Frequency.daily, times: _dedupeSorted(params.times));
      case RecurrencePreset.quota:
        return RecurrenceRule.forQuota(params.quotaTimes, params.quotaPer, minGapDays: params.quotaMinGapDays);
      case RecurrencePreset.afterCompletion:
        return RecurrenceRule.forAfterCompletion(params.afterAmount, params.afterUnit);
    }
  }

  /// The preset that exactly represents [rule] (bounds, exceptions and week start ignored),
  /// or [RecurrencePreset.custom].
  static RecurrencePreset detect(
    RecurrenceRule? rule,
    RecurrenceAnchor anchor, {
    RecurrencePickerMode mode = RecurrencePickerMode.task,
  }) {
    if (rule == null) return RecurrencePreset.none;
    final offered = available(mode, anchor);
    RecurrencePreset pick(RecurrencePreset p) => offered.contains(p) ? p : RecurrencePreset.custom;
    switch (rule.type) {
      case RuleType.quota:
        return pick(RecurrencePreset.quota);
      case RuleType.afterCompletion:
        return pick(RecurrencePreset.afterCompletion);
      case RuleType.fixed:
        return pick(_detectFixed(rule, anchor));
    }
  }

  static RecurrencePreset _detectFixed(RecurrenceRule rule, RecurrenceAnchor anchor) {
    const custom = RecurrencePreset.custom;
    final advanced =
        rule.byYearDay.isNotEmpty ||
        rule.byWeekNo.isNotEmpty ||
        rule.bySetPos.isNotEmpty ||
        rule.byHour.isNotEmpty ||
        rule.byMinute.isNotEmpty ||
        rule.monthDayOverflow != MonthOverflow.skip;
    if (advanced) return custom;
    final date = anchor.start.date;
    final weekdays = rule.byWeekday;
    final plainDays = weekdays == null || weekdays.any((w) => w.n != null) ? null : {for (final w in weekdays) w.day};
    final noTimes = rule.times.isEmpty && rule.window == null;
    switch (rule.freq) {
      case Frequency.daily:
        if (weekdays != null || rule.byMonthDay.isNotEmpty || rule.byMonth.isNotEmpty || rule.window != null) {
          return custom;
        }
        if (rule.times.isNotEmpty) return rule.interval == 1 ? RecurrencePreset.timesPerDay : custom;
        return rule.interval == 1 ? RecurrencePreset.daily : RecurrencePreset.everyNDays;
      case Frequency.weekly:
        if (rule.interval != 1 || !noTimes || rule.byMonth.isNotEmpty || rule.byMonthDay.isNotEmpty) return custom;
        if (weekdays == null) return RecurrencePreset.weekly;
        // Ordinals on a weekly rule are invalid: only the advanced editor can show them.
        if (plainDays == null) return custom;
        // No day selected: the (invalid) state of the *Specific days* chips.
        if (plainDays.isEmpty) return RecurrencePreset.specificDays;
        if (plainDays.length == 1 && plainDays.first == date.weekday) return RecurrencePreset.weekly;
        if (_sameSet(plainDays, workWeek.toSet())) return RecurrencePreset.weekdays;
        return RecurrencePreset.specificDays;
      case Frequency.monthly:
        if (rule.interval != 1 || !noTimes || rule.byMonth.isNotEmpty) return custom;
        final days = rule.byMonthDay;
        if (weekdays == null) {
          if (days.isEmpty || (days.length == 1 && days.first == date.day)) return RecurrencePreset.monthlyOnDay;
          if (days.length == 1 && days.first == -1) return RecurrencePreset.lastDayOfMonth;
          return custom;
        }
        if (days.isNotEmpty || weekdays.length != 1) return custom;
        final w = weekdays.first;
        if (w.day != date.weekday) return custom;
        if (w.n == -1 && isLastWeekdayOfMonth(date)) return RecurrencePreset.monthlyOnLastWeekday;
        if (w.n != null && w.n == nthWeekdayOfMonth(date)) return RecurrencePreset.monthlyOnNthWeekday;
        return custom;
      case Frequency.yearly:
        if (rule.interval != 1 || !noTimes || weekdays != null) return custom;
        final months = rule.byMonth;
        final days = rule.byMonthDay;
        if (months.isEmpty && days.isEmpty) return RecurrencePreset.yearly;
        final sameDate = months.length == 1 && months.first == date.month && days.length == 1 && days.first == date.day;
        return sameDate ? RecurrencePreset.yearly : custom;
      case Frequency.hourly:
      case Frequency.minutely:
        if (weekdays != null || rule.byMonthDay.isNotEmpty || rule.byMonth.isNotEmpty || rule.times.isNotEmpty) {
          return custom;
        }
        return RecurrencePreset.intraday;
    }
  }

  /// Starting rule of the advanced editor when the sheet has no rule yet (weekly on the start day).
  static RecurrenceRule get defaultCustomRule => RecurrenceRule(freq: Frequency.weekly);
}
