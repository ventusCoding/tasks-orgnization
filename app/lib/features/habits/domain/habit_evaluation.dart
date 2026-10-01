import 'dart:math' as math;

import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' hide PeriodUnit;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Log kinds that matter for build-habit evaluation.
const buildLogKinds = {
  HabitLogKind.done,
  HabitLogKind.fail,
  HabitLogKind.progress,
  HabitLogKind.skip,
  HabitLogKind.excuse,
  HabitLogKind.note,
  HabitLogKind.freeze,
};

/// Evaluation settings of a build habit (`skip_policy`, `settings.requireExplicitLog`, slot roll-up).
HabitEvaluationSettings evaluationSettingsOf(BuildHabit habit) => HabitEvaluationSettings(
  skipPolicy: habit.skipPolicy,
  requireExplicitLog: habit.settings.requireExplicitLog,
  slotRollup: habit.settings.slotRollup == SlotRollupMode.minSlots && (habit.settings.minSlots ?? 0) > 0
      ? SlotRollup(minSlots: habit.settings.minSlots)
      : const SlotRollup.allSlots(),
);

/// Date bucket of a log: the date of its occurrence key, else its local date.
LocalDate logDateOf(HabitLog log) {
  final key = log.occurrenceKey;
  if (key != null && key.length >= 10) {
    final d = LocalDate.tryParse(key.substring(0, 10));
    if (d != null) return d;
  }
  return log.localDate;
}

/// The evaluated history of one build habit (T5.1.06 / T5.1.09).
@immutable
class HabitEvaluation {
  const HabitEvaluation({
    required this.habit,
    required this.units,
    required this.days,
    required this.slots,
    required this.quotas,
    required this.logs,
    required this.now,
    required this.today,
  });

  final BuildHabit habit;

  /// Streak / statistics units in chronological order: day results (day habits), day roll-ups
  /// (slot habits) and quota results (quota habits). Future periods are not included.
  final List<PeriodResult> units;

  /// Per logical date: the day result, the slot roll-up or — for quota habits — a day view.
  final Map<LocalDate, PeriodResult> days;

  /// Slot results per logical date (slot habits; today includes pending future slots).
  final Map<LocalDate, List<PeriodResult>> slots;

  /// Quota period results (quota habits), chronological.
  final List<PeriodResult> quotas;

  /// Build-relevant logs (metrics form).
  final List<HabitLog> logs;
  final DateTime now;
  final LocalDate today;

  PeriodResult? dayOn(LocalDate date) => days[date];

  List<PeriodResult> slotsOn(LocalDate date) => slots[date] ?? const [];

  PeriodResult? quotaOn(LocalDate date) {
    for (final q in quotas.reversed) {
      if (!date.isBefore(q.startDate) && !date.isAfter(q.endDate)) return q;
    }
    return null;
  }

  /// The streak unit covering [date] (quota period, or the day result / roll-up).
  PeriodResult? unitOn(LocalDate date) => quotaOn(date) ?? days[date];

  /// Results used to build day facts for strength & stats (slot level for slot habits).
  List<PeriodResult> get factResults => [
    ...[
      for (final e in slots.entries)
        if (!e.key.isAfter(today)) ...e.value.where((r) => !r.flags.future),
    ],
    for (final r in units)
      if (r.kind != HabitPeriodKind.day || slots[r.startDate] == null) r,
  ];
}

/// Evaluates [periods] of [habit] (from the period service) with its logs and pauses.
///
/// Future periods are skipped except slots of today and earlier dates (so a day roll-up waits for
/// its later slots). Quota habits also get a per-day view (done / explicit states / neutral).
HabitEvaluation evaluateHabit({
  required BuildHabit habit,
  required List<HabitPeriod> periods,
  required Iterable<HabitLogEntry> logs,
  required Iterable<PauseSpan> pauses,
  required DateTime now,
  required LocalDate today,
  required DayBoundaries boundaries,
}) {
  final metricsLogs = [
    for (final l in logs)
      if (l.habitId == habit.id && buildLogKinds.contains(l.kind)) l.toMetrics(),
  ];
  final byDate = <LocalDate, List<HabitLog>>{};
  for (final l in metricsLogs) {
    byDate.putIfAbsent(logDateOf(l), () => []).add(l);
  }
  final habitPauses = [
    for (final p in pauses)
      if (p.appliesTo(habit.id)) p.toMetrics(),
  ];
  final settings = evaluationSettingsOf(habit);
  final units = <PeriodResult>[];
  final days = <LocalDate, PeriodResult>{};
  final slots = <LocalDate, List<PeriodResult>>{};
  final quotas = <PeriodResult>[];

  final slotPeriods = <LocalDate, List<HabitPeriod>>{};
  for (final p in periods) {
    switch (p.kind) {
      case HabitPeriodKind.day:
        if (p.windowStart.isAfter(now)) continue;
        final r = evaluateHabitPeriod(
          p,
          byDate[p.startDate] ?? const [],
          now: now,
          today: today,
          pauses: habitPauses,
          settings: settings,
        );
        days[p.startDate] = r;
        units.add(r);
      case HabitPeriodKind.slot:
        slotPeriods.putIfAbsent(p.startDate, () => []).add(p);
      case HabitPeriodKind.quota:
        final periodLogs = [for (var d = p.startDate; !d.isAfter(p.endDate); d = d.plusDays(1)) ...?byDate[d]];
        if (!p.windowStart.isAfter(now)) {
          final r = evaluateHabitPeriod(p, periodLogs, now: now, today: today, pauses: habitPauses, settings: settings);
          quotas.add(r);
          units.add(r);
        }
        for (var d = p.startDate; !d.isAfter(p.endDate) && !d.isAfter(today); d = d.plusDays(1)) {
          days[d] = _quotaDay(p, d, byDate[d] ?? const [], habitPauses, today, boundaries);
        }
    }
  }
  final slotDates = slotPeriods.keys.toList()..sort();
  for (final d in slotDates) {
    if (d.isAfter(today)) continue;
    final dayLogs = [...?byDate[d], ...?byDate[d.plusDays(1)]];
    final results = [
      for (final p in slotPeriods[d]!)
        evaluateHabitPeriod(p, dayLogs, now: now, today: today, pauses: habitPauses, settings: settings),
    ];
    slots[d] = results;
    final rollup = rollUpSlots(
      d,
      results,
      windowStart: boundaries.startOf(d),
      windowEnd: boundaries.endOf(d),
      settings: settings,
    );
    days[d] = rollup;
    units.add(rollup);
  }
  final rule = habit.schedule;
  if (rule.type == RuleType.afterCompletion && rule.afterCompletion != null) {
    _applyAfterCompletion(habit.startDate, rule.afterCompletion!, days, units, today);
  }
  units.sort((a, b) => a.startDate.compareTo(b.startDate));
  return HabitEvaluation(
    habit: habit,
    units: units,
    days: days,
    slots: slots,
    quotas: quotas,
    logs: metricsLogs,
    now: now,
    today: today,
  );
}

/// The next due date [a] after a completion (or handled day) on [d].
LocalDate afterCompletionDue(LocalDate d, AfterCompletion a) => switch (a.unit) {
  RecurrenceUnit.day => d.plusDays(a.amount),
  RecurrenceUnit.week => d.plusDays(7 * a.amount),
  RecurrenceUnit.month => d.plusMonths(a.amount),
  RecurrenceUnit.year => d.plusMonths(12 * a.amount),
  RecurrenceUnit.minute || RecurrenceUnit.hour => d.plusDays(1),
};

/// After-completion habits (T5.1.17): due on the start date, then [a] after each completion. Each
/// due window (due date → completion) is one streak unit — done when completed on (or before) its
/// due date, missed when completed late, pending while open — so the streak counts on-time
/// windows. In the day view, days before the due date are not due, the due day of a late window
/// shows missed, the overdue days after it are neutral, and today shows the open window (flagged
/// at risk when overdue). Skips and excuses close a window like a completion.
void _applyAfterCompletion(
  LocalDate start,
  AfterCompletion a,
  Map<LocalDate, PeriodResult> days,
  List<PeriodResult> units,
  LocalDate today,
) {
  units.removeWhere((u) => u.kind == HabitPeriodKind.day);
  var due = start;
  PeriodResult window(PeriodResult first, PeriodResult last, PeriodStatus status) => PeriodResult(
    first.key,
    kind: HabitPeriodKind.day,
    startDate: first.startDate,
    endDate: last.endDate,
    windowStart: first.windowStart,
    windowEnd: last.windowEnd,
    status: status,
    achieved: last.achieved,
    target: last.target,
    goal: last.goal,
    revisionId: last.revisionId,
    entries: last.entries,
    flags: last.flags,
  );
  const handled = {PeriodStatus.done, PeriodStatus.skipped, PeriodStatus.excused, PeriodStatus.frozen};
  final dates = days.keys.toList()..sort();
  for (final d in dates) {
    final r = days[d]!;
    if (r.status == PeriodStatus.paused) continue;
    final dueDay = days[due];
    if (d.isBefore(due)) {
      if (r.status == PeriodStatus.done) {
        // Early: completes the coming window on time.
        units.add(window(r, r, PeriodStatus.done));
        due = afterCompletionDue(d, a);
      } else {
        days[d] = r.withStatus(PeriodStatus.notDue);
      }
      continue;
    }
    if (handled.contains(r.status)) {
      final onTime = d == due;
      final status = r.status == PeriodStatus.done && !onTime ? PeriodStatus.missed : r.status;
      units.add(window(dueDay ?? r, r, status));
      if (!onTime && dueDay != null) days[due] = dueDay.withStatus(PeriodStatus.missed);
      due = afterCompletionDue(d, a);
    } else if (d == today) {
      days[d] = r.withStatus(
        PeriodStatus.pending,
        flags: PeriodFlags(atRisk: d.isAfter(due), explicit: r.flags.explicit),
      );
      units.add(window(dueDay ?? r, r, PeriodStatus.pending));
    } else if (d != due) {
      // Overdue days after the due day are neutral (the window is one period).
      days[d] = r.withStatus(PeriodStatus.notDue);
    } else if (!r.status.isNeutral && r.status != PeriodStatus.failed) {
      days[d] = r.withStatus(PeriodStatus.missed);
    }
  }
}

PeriodResult _quotaDay(
  HabitPeriod q,
  LocalDate d,
  List<HabitLog> dayLogs,
  List<HabitPause> pauses,
  LocalDate today,
  DayBoundaries b,
) {
  HabitLog? state;
  var progress = 0.0;
  for (final l in dayLogs) {
    if (l.kind == HabitLogKind.progress) progress += l.value ?? 0;
    if (l.kind.isState && (state == null || l.compareTo(state) > 0)) state = l;
  }
  final measurable = q.goal.isMeasurable;
  final active = measurable ? progress > 0 && progress >= (q.minPerDay ?? 0) : progress >= 1;
  final PeriodStatus status;
  if (state != null) {
    status = switch (state.kind) {
      HabitLogKind.done => PeriodStatus.done,
      HabitLogKind.fail => PeriodStatus.failed,
      HabitLogKind.skip => PeriodStatus.skipped,
      HabitLogKind.excuse => PeriodStatus.excused,
      _ => PeriodStatus.frozen,
    };
  } else if (active) {
    status = PeriodStatus.done;
  } else if (pauses.any((p) => p.covers(d))) {
    status = PeriodStatus.paused;
  } else if (d.isAfter(today)) {
    status = PeriodStatus.pending;
  } else {
    status = PeriodStatus.notDue;
  }
  final achieved = measurable ? progress : (status == PeriodStatus.done ? 1.0 : 0.0);
  return PeriodResult(
    d.toIso(),
    kind: HabitPeriodKind.day,
    startDate: d,
    endDate: d,
    windowStart: b.startOf(d),
    windowEnd: b.endOf(d),
    status: status,
    achieved: achieved,
    target: measurable ? (q.minPerDay ?? 0) : 1,
    goal: q.goal,
    revisionId: q.revisionId,
    entries: dayLogs,
    flags: PeriodFlags(explicit: state != null, inPause: status == PeriodStatus.paused),
  );
}

/// Loop-style frequency f = numerator / denominator of [rule] (T6.1.10): daily 1/1, every N days
/// 1/N, k weekdays per week k/7, N per week/month quota N/7 · N/30, slot habits [slotsPerDay]/1.
StrengthFrequency strengthFrequencyOf(RecurrenceRule rule, {int slotsPerDay = 1}) {
  final interval = rule.interval < 1 ? 1 : rule.interval;
  switch (rule.type) {
    case RuleType.quota:
      final q = rule.quota;
      if (q == null) return const StrengthFrequency.daily();
      final times = q.times < 1 ? 1 : q.times;
      return switch (q.per) {
        PeriodUnit.day => StrengthFrequency(times, 1),
        PeriodUnit.week => StrengthFrequency(times, 7),
        PeriodUnit.month => StrengthFrequency(times, 30),
        PeriodUnit.year => StrengthFrequency(times, 365),
      };
    case RuleType.afterCompletion:
      final a = rule.afterCompletion;
      if (a == null) return const StrengthFrequency.daily();
      final days = switch (a.unit) {
        RecurrenceUnit.minute || RecurrenceUnit.hour => 1,
        RecurrenceUnit.day => a.amount,
        RecurrenceUnit.week => a.amount * 7,
        RecurrenceUnit.month => a.amount * 30,
        RecurrenceUnit.year => a.amount * 365,
      };
      return StrengthFrequency(1, math.max(1, days));
    case RuleType.fixed:
      if (rule.freq.isSubDaily || rule.times.isNotEmpty) {
        return StrengthFrequency(math.max(1, slotsPerDay), 1);
      }
      final weekdays = rule.byWeekday?.length ?? 0;
      return switch (rule.freq) {
        Frequency.daily => weekdays > 0 ? StrengthFrequency(weekdays, 7 * interval) : StrengthFrequency(1, interval),
        Frequency.weekly => StrengthFrequency(math.max(1, weekdays), 7 * interval),
        Frequency.monthly => StrengthFrequency(
          math.max(1, rule.byMonthDay.isNotEmpty ? rule.byMonthDay.length : weekdays),
          30 * interval,
        ),
        Frequency.yearly => StrengthFrequency(1, 365 * interval),
        Frequency.minutely || Frequency.hourly => StrengthFrequency(math.max(1, slotsPerDay), 1),
      };
  }
}

/// Strength-score goal kind of a habit goal.
StrengthGoalKind strengthKindOf(HabitTarget goal) {
  if (!goal.isMeasurable) return StrengthGoalKind.boolean;
  return goal.op == TargetOp.lte ? StrengthGoalKind.atMost : StrengthGoalKind.atLeast;
}

/// Headline statistics of a habit (T5.2.07): computed with the single implementations of
/// `everslot_metrics` (streaks, Loop strength, success rate, outcome counts).
@immutable
class HabitSummary {
  const HabitSummary({
    required this.streaks,
    required this.strength,
    required this.rate30,
    required this.counts90,
    required this.repetitions,
    required this.volume,
  });

  final StreakSummary streaks;
  final StrengthResult strength;

  /// Success rate over the last 30 days (min-data rule applied).
  final Stat<double> rate30;

  /// Outcome counts over the last 90 days.
  final OutcomeCounts counts90;

  /// Manual done/progress logs ("votes for your identity").
  final int repetitions;

  /// Σ achieved over all history.
  final double volume;

  int get currentStreak => streaks.currentLength;
  int get bestStreak => streaks.bestLength;

  /// Strength 0…1.
  double get strengthScore => strength.current;
}

/// Summarizes an evaluation. [rulesOn] gives the rules in force on a date (revision-aware).
HabitSummary summarizeHabit(HabitEvaluation e, {required HabitRules Function(LocalDate date) rulesOn}) {
  final habit = e.habit;
  final today = e.today;
  final closedUnits = [
    for (final r in e.units)
      if (!r.startDate.isAfter(today)) r,
  ];
  final streaks = habitStreaks(closedUnits, skipPolicy: habit.skipPolicy, freezesPerMonth: habit.freezesPerMonth);
  final maxSlots = e.slots.values.fold<int>(0, (a, s) => math.max(a, s.length));
  final strength = habitStrength(
    habitDayFacts(e.factResults, skipPolicy: habit.skipPolicy),
    today: today,
    frequencyOn: (d) => strengthFrequencyOf(rulesOn(d).schedule, slotsPerDay: math.max(1, maxSlots)),
    kind: strengthKindOf(habit.goal),
    targetOn: (d) {
      final goal = rulesOn(d).goal;
      return goal.isMeasurable ? goal.target : null;
    },
  );
  final rate = successRate(closedUnits, from: today.minusDays(29), to: today, skipPolicy: habit.skipPolicy);
  return HabitSummary(
    streaks: streaks,
    strength: strength,
    rate30: MinDataRules.rate.apply(rate),
    counts90: outcomeCounts(closedUnits, from: today.minusDays(89), to: today),
    repetitions: totalRepetitions(e.logs),
    volume: totalVolume(closedUnits),
  );
}
