/// Habit period evaluation (T5.1.06): the single implementation that decides each period's outcome
/// (`PeriodResult`) — the base of check-in UI, streaks, the strength score and every habit stat.
///
/// Inputs are already-expanded periods ([HabitPeriod], produced by the habit period service from
/// the schedule and the revision in force), the habit's logs, pauses and settings. Pure and
/// deterministic: results do not depend on log insertion order.
///
/// **Precedence** (arch §6.11):
/// 1. an explicit state log for the period (latest statement wins): `excuse` → excused, `skip` →
///    skipped, `fail` → failed, `done` → done, `freeze` → frozen;
/// 2. otherwise the goal is evaluated from progress logs; a `done` result stays done even inside a
///    pause;
/// 3. otherwise, if the period lies in a pause (habit-level or global) → paused (neutral);
/// 4. otherwise the goal result (partial / missed / pending / failed-by-limit).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// `habits.goal_type`.
enum HabitGoalType { check, count, duration, numeric }

/// `habits.target_op`: at least, at most (limit), exactly.
enum TargetOp { gte, lte, eq }

/// `habits.skip_policy`.
enum SkipPolicy { neutral, breaks }

/// Outcome of one period.
enum PeriodStatus {
  done,
  partial,

  /// Explicit "not done", or a limit exceeded.
  failed,

  /// Window closed with nothing (or not enough) logged.
  missed,
  skipped,
  excused,

  /// A streak freeze was applied ([5.4]).
  frozen,
  paused,
  pending,
  notDue;

  /// Statuses that neither extend nor break a streak and are excluded from denominators.
  bool get isNeutral =>
      this == excused || this == paused || this == frozen || this == notDue;
}

/// `habit_logs.kind`.
enum HabitLogKind {
  done,
  fail,
  progress,
  skip,
  excuse,
  clean,
  relapse,
  craving,
  note,
  use,
  restart,
  pledge,
  freeze,
  survey;

  /// Parses the database value.
  static HabitLogKind parse(String value) => HabitLogKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => throw FormatException('Unknown habit log kind', value),
  );

  /// Kinds that state the outcome of a period.
  bool get isState =>
      this == done ||
      this == fail ||
      this == skip ||
      this == excuse ||
      this == freeze;
}

/// A habit goal (arch §8.4): type, target and comparison.
@immutable
final class const HabitGoal(
  final HabitGoalType type, {
  final double? target,
  final TargetOp op = TargetOp.gte,
}) {
  const new check() : this(HabitGoalType.check);

  bool get isMeasurable => type != HabitGoalType.check;

  /// Target used for evaluation (1 for yes/no habits).
  double get effectiveTarget => type == HabitGoalType.check ? 1 : (target ?? 1);
}

/// One `habit_logs` row (only the fields evaluation and stats need).
@immutable
final class const HabitLog(
  final String id,
  final HabitLogKind kind, {
  required final DateTime loggedAt,
  required final LocalDate localDate,
  final double? value,
  final String? occurrenceKey,
  final DateTime? createdAt,
  final String source = 'manual',
  final int? mood,
  final int? durationSeconds,
  final String? note,
}) {
  /// Total ordering used to pick the latest statement: loggedAt, then createdAt, then id.
  int compareTo(HabitLog other) {
    final c = loggedAt.compareTo(other.loggedAt);
    if (c != 0) return c;
    final ca = createdAt ?? loggedAt;
    final cb = other.createdAt ?? other.loggedAt;
    final c2 = ca.compareTo(cb);
    return c2 != 0 ? c2 : id.compareTo(other.id);
  }
}

/// `habit_pauses` row; [habitId] null = all habits (vacation). [end] null = open-ended.
@immutable
final class const HabitPause(
  final LocalDate start, {
  final LocalDate? end,
  final String? habitId,
  final String? reason,
}) {
  bool covers(LocalDate date) =>
      !date.isBefore(start) && (end == null || !date.isAfter(end!));
}

/// Kind of a period.
enum HabitPeriodKind { day, slot, quota }

/// An expanded period to evaluate (produced by the habit period service, [5.1] T5.1.05).
///
/// - Day: key `YYYY-MM-DD`, window = [D @ dayStartsAt, D+1 @ dayStartsAt).
/// - Slot: key `YYYY-MM-DDTHH:mm`, window = [slot start, next slot start); keyless logs are matched
///   within [matchStart] (slot start − early tolerance) … [windowEnd].
/// - Quota: key `week:YYYY-MM-DD` / `month:YYYY-MM`, one period over [startDate]…[endDate] with
///   [quotaTimes]; [eligibleDays] are the dates allowed by the rule inside this (possibly clipped)
///   period and [fullEligibleDays] their count in a full period (pro-rating base).
@immutable
final class const HabitPeriod(
  final String key, {
  required final HabitPeriodKind kind,
  required final LocalDate startDate,
  required final LocalDate endDate,
  required final DateTime windowStart,
  required final DateTime windowEnd,
  required final HabitGoal goal,
  final String? revisionId,
  final bool due = true,
  final int? quotaTimes,
  final double? minPerDay,
  final List<LocalDate>? eligibleDays,
  final int? fullEligibleDays,
  final DateTime? matchStart,
}) {
  /// Every local date covered by the period.
  List<LocalDate> get dates => [
    for (var d = startDate; !d.isAfter(endDate); d = d.plusDays(1)) d,
  ];
}

/// How a slot habit rolls up to a day.
@immutable
final class const SlotRollup({final int? minSlots}) {
  /// Every slot must be done (default).
  const new allSlots() : this();

  bool get requiresAll => minSlots == null;
}

/// Evaluation settings (`habits.skip_policy`, `habits.settings`).
@immutable
final class const HabitEvaluationSettings({
  final SkipPolicy skipPolicy = SkipPolicy.neutral,
  final bool requireExplicitLog = false,
  final SlotRollup slotRollup = const SlotRollup.allSlots(),
});

/// Extra facts about a period result.
@immutable
final class const PeriodFlags({
  final bool explicit = false,
  final bool breaksStreak = false,
  final bool atRisk = false,
  final bool future = false,
  final bool bonus = false,
  final bool inPause = false,
  final int? activeDays,
  final int? requiredDays,
  final int? eligibleDays,
  final int? remainingEligibleDays,
  final double? expected,
});

/// The evaluated outcome of one period.
@immutable
final class const PeriodResult(
  final String key, {
  required final HabitPeriodKind kind,
  required final LocalDate startDate,
  required final LocalDate endDate,
  required final DateTime windowStart,
  required final DateTime windowEnd,
  required final PeriodStatus status,
  required final double achieved,
  required final double target,
  required final HabitGoal goal,
  final String? revisionId,
  final List<HabitLog> entries = const [],
  final PeriodFlags flags = const PeriodFlags(),
}) {
  /// achieved ÷ target (null when the target is 0).
  double? get ratio => target > 0 ? achieved / target : null;

  /// Fulfilment min(1, v/t) for build goals; the Loop credit clamp(1 − (v − t)/t, 0, 1) for limits.
  double get fulfilment {
    if (goal.op == TargetOp.lte) return limitCredit(achieved, target);
    if (target <= 0) return achieved > 0 ? 1 : 0;
    return math.min(1, achieved / target);
  }

  bool get isClosed => status != PeriodStatus.pending;

  PeriodResult withStatus(PeriodStatus newStatus, {PeriodFlags? flags}) =>
      PeriodResult(
        key,
        kind: kind,
        startDate: startDate,
        endDate: endDate,
        windowStart: windowStart,
        windowEnd: windowEnd,
        status: newStatus,
        achieved: achieved,
        target: target,
        goal: goal,
        revisionId: revisionId,
        entries: entries,
        flags: flags ?? this.flags,
      );
}

/// Loop credit for a limit: c = clamp(1 − (v − limit)/limit, 0, 1) (HB-H-16). A limit of 0 gives 1
/// when nothing was consumed, else 0.
double limitCredit(double value, double limit) {
  if (limit <= 0) return value > 0 ? 0 : 1;
  return (1 - (value - limit) / limit).clamp(0.0, 1.0);
}

/// Returns the latest element whose [effectiveFrom] is on or before [date] (revision resolution:
/// `HabitRevision.effectiveFor(date)`), or null.
T? effectiveOn<T>(
  Iterable<T> revisions,
  LocalDate date,
  LocalDate Function(T revision) effectiveFrom,
) {
  T? best;
  LocalDate? bestFrom;
  for (final r in revisions) {
    final from = effectiveFrom(r);
    if (from.isAfter(date)) continue;
    if (bestFrom == null || from.isAfter(bestFrom)) {
      best = r;
      bestFrom = from;
    }
  }
  return best;
}

String _dayKey(LocalDate d) => d.toIso();

LocalDate? _dateOfKey(String? key) {
  if (key == null || key.length < 10) return null;
  return LocalDate.tryParse(key.substring(0, 10));
}

List<HabitLog> _logsForPeriod(HabitPeriod p, List<HabitLog> logs) {
  switch (p.kind) {
    case HabitPeriodKind.day:
      final dayKey = _dayKey(p.startDate);
      return [
        for (final l in logs)
          if (l.occurrenceKey == null
              ? l.localDate == p.startDate
              : (l.occurrenceKey == dayKey ||
                    l.occurrenceKey!.startsWith('${dayKey}T')))
            l,
      ];
    case HabitPeriodKind.slot:
      final from = p.matchStart ?? p.windowStart;
      return [
        for (final l in logs)
          if (l.occurrenceKey == null
              ? !l.loggedAt.isBefore(from) && l.loggedAt.isBefore(p.windowEnd)
              : l.occurrenceKey == p.key)
            l,
      ];
    case HabitPeriodKind.quota:
      return [
        for (final l in logs)
          if (_logDate(l) case final d
              when !d.isBefore(p.startDate) && !d.isAfter(p.endDate))
            l,
      ];
  }
}

LocalDate _logDate(HabitLog l) => _dateOfKey(l.occurrenceKey) ?? l.localDate;

HabitLog? _latestState(Iterable<HabitLog> logs) {
  HabitLog? latest;
  for (final l in logs) {
    if (!l.kind.isState) continue;
    if (latest == null || l.compareTo(latest) > 0) latest = l;
  }
  return latest;
}

double _progressSum(Iterable<HabitLog> logs) => logs
    .where((l) => l.kind == HabitLogKind.progress)
    .fold(0, (acc, l) => acc + (l.value ?? 0));

bool _inPause(LocalDate date, List<HabitPause> pauses) =>
    pauses.any((p) => p.covers(date));

/// Evaluates one period. See the library documentation for the precedence rules.
///
/// Goal rules: *check* — no state and window closed → missed, open → pending. *gte* — Σ progress ≥
/// target → done (early completion allowed); closed and 0 < Σ < target → partial; closed and Σ = 0
/// → missed. *lte* — Σ > target → failed immediately; closed and Σ ≤ target → done, unless
/// [HabitEvaluationSettings.requireExplicitLog] and nothing logged → missed. *eq* — Σ > target →
/// failed; closed and Σ = target → done; closed and 0 < Σ < target → partial; closed and Σ = 0 →
/// missed.
PeriodResult evaluateHabitPeriod(
  HabitPeriod period,
  List<HabitLog> logs, {
  required DateTime now,
  required LocalDate today,
  List<HabitPause> pauses = const [],
  HabitEvaluationSettings settings = const HabitEvaluationSettings(),
}) {
  final entries = _logsForPeriod(period, logs)..sort((a, b) => a.compareTo(b));
  if (period.kind == HabitPeriodKind.quota) {
    return _evaluateQuota(period, entries, now, today, pauses, settings);
  }
  final target = period.goal.effectiveTarget;
  final closed = !period.windowEnd.isAfter(now);
  final state = _latestState(entries);
  final progress = _progressSum(entries);
  final achieved = period.goal.isMeasurable
      ? progress
      : (entries.any((l) => l.kind == HabitLogKind.done) || progress >= 1
            ? 1.0
            : 0.0);

  PeriodResult result(
    PeriodStatus status, [
    PeriodFlags flags = const PeriodFlags(),
  ]) => PeriodResult(
    period.key,
    kind: period.kind,
    startDate: period.startDate,
    endDate: period.endDate,
    windowStart: period.windowStart,
    windowEnd: period.windowEnd,
    status: status,
    achieved: achieved,
    target: target,
    goal: period.goal,
    revisionId: period.revisionId,
    entries: entries,
    flags: flags,
  );

  if (!period.due) {
    return result(PeriodStatus.notDue, PeriodFlags(bonus: achieved > 0));
  }
  if (period.windowStart.isAfter(now)) {
    return result(PeriodStatus.pending, const PeriodFlags(future: true));
  }
  final paused = _inPause(period.startDate, pauses);
  if (state != null) {
    final status = switch (state.kind) {
      HabitLogKind.excuse => PeriodStatus.excused,
      HabitLogKind.skip => PeriodStatus.skipped,
      HabitLogKind.fail => PeriodStatus.failed,
      HabitLogKind.freeze => PeriodStatus.frozen,
      _ => PeriodStatus.done,
    };
    return result(
      status,
      PeriodFlags(
        explicit: true,
        inPause: paused,
        breaksStreak:
            status == PeriodStatus.skipped &&
            settings.skipPolicy == SkipPolicy.breaks,
      ),
    );
  }
  final goalStatus = _goalStatus(
    period.goal,
    target,
    achieved,
    closed: closed,
    anyLogged: entries.any((l) => l.kind == HabitLogKind.progress),
    requireExplicitLog: settings.requireExplicitLog,
  );
  if (goalStatus == PeriodStatus.done) {
    return result(PeriodStatus.done, PeriodFlags(inPause: paused));
  }
  if (paused)
    return result(PeriodStatus.paused, const PeriodFlags(inPause: true));
  return result(goalStatus);
}

PeriodStatus _goalStatus(
  HabitGoal goal,
  double target,
  double achieved, {
  required bool closed,
  required bool anyLogged,
  required bool requireExplicitLog,
}) {
  switch (goal.op) {
    case TargetOp.gte:
      if (achieved >= target) return PeriodStatus.done;
      if (!closed) return PeriodStatus.pending;
      return achieved > 0 ? PeriodStatus.partial : PeriodStatus.missed;
    case TargetOp.lte:
      if (achieved > target) return PeriodStatus.failed;
      if (!closed) return PeriodStatus.pending;
      if (requireExplicitLog && !anyLogged) return PeriodStatus.missed;
      return PeriodStatus.done;
    case TargetOp.eq:
      if (achieved > target) return PeriodStatus.failed;
      if (!closed) return PeriodStatus.pending;
      if (achieved == target) return PeriodStatus.done;
      return achieved > 0 ? PeriodStatus.partial : PeriodStatus.missed;
  }
}

PeriodResult _evaluateQuota(
  HabitPeriod p,
  List<HabitLog> entries,
  DateTime now,
  LocalDate today,
  List<HabitPause> pauses,
  HabitEvaluationSettings settings,
) {
  final dates = p.eligibleDays ?? p.dates;
  final fullEligible = p.fullEligibleDays ?? p.dates.length;
  var active = 0;
  var eligible = 0;
  var remaining = 0;
  var total = 0.0;
  var pausedDays = 0;
  var excusedDays = 0;
  for (final date in dates) {
    final dayLogs = entries.where((l) => _logDate(l) == date).toList();
    final state = _latestState(dayLogs);
    final value = _progressSum(dayLogs);
    total += value;
    final bool isActive;
    if (state != null && state.kind == HabitLogKind.done) {
      isActive = true;
    } else if (state != null && state.kind == HabitLogKind.fail) {
      isActive = false;
    } else if (p.goal.isMeasurable) {
      // A day is active when Σ ≥ minPerDay (any positive amount by default).
      isActive = value > 0 && value >= (p.minPerDay ?? 0);
    } else {
      isActive = value >= 1;
    }
    if (isActive) {
      active++;
      eligible++;
      continue;
    }
    final neutralState =
        state != null &&
        (state.kind == HabitLogKind.excuse ||
            state.kind == HabitLogKind.freeze ||
            (state.kind == HabitLogKind.skip &&
                settings.skipPolicy == SkipPolicy.neutral));
    if (neutralState) {
      excusedDays++;
      continue;
    }
    if (_inPause(date, pauses)) {
      pausedDays++;
      continue;
    }
    eligible++;
    if (!date.isBefore(today)) remaining++;
  }
  final times = p.quotaTimes;
  final scale = fullEligible <= 0
      ? 1.0
      : math.min(1, eligible / fullEligible).toDouble();
  final int requiredDays;
  final double requiredTotal;
  final double expected;
  if (p.goal.isMeasurable) {
    // The target applies to the period total; quota.times (optional) is the minimum number of
    // active days. The period is one unit for adherence (weight = pro-rating scale).
    requiredTotal = p.goal.effectiveTarget * scale;
    requiredDays = times == null ? 0 : _proRatedCount(times, scale);
    expected = scale;
  } else {
    requiredDays = _proRatedCount(times ?? 1, scale);
    requiredTotal = requiredDays.toDouble();
    expected = (times ?? 1) * scale;
  }
  final done =
      eligible > 0 &&
      active >= requiredDays &&
      (!p.goal.isMeasurable || total >= requiredTotal - 1e-9);
  final closed = !p.windowEnd.isAfter(now);
  final future = p.windowStart.isAfter(now);
  final neededDays = math.max(0, requiredDays - active);
  final achieved = p.goal.isMeasurable ? total : active.toDouble();

  PeriodResult result(PeriodStatus status) => PeriodResult(
    p.key,
    kind: p.kind,
    startDate: p.startDate,
    endDate: p.endDate,
    windowStart: p.windowStart,
    windowEnd: p.windowEnd,
    status: status,
    achieved: achieved,
    target: requiredTotal,
    goal: p.goal,
    revisionId: p.revisionId,
    entries: entries,
    flags: PeriodFlags(
      activeDays: active,
      requiredDays: requiredDays,
      eligibleDays: eligible,
      remainingEligibleDays: remaining,
      expected: expected,
      inPause: pausedDays > 0,
      future: future,
      atRisk:
          status == PeriodStatus.pending && !future && neededDays > remaining,
    ),
  );

  if (!p.due) return result(PeriodStatus.notDue);
  if (future) return result(PeriodStatus.pending);
  if (done) return result(PeriodStatus.done);
  if (eligible == 0) {
    return result(
      pausedDays > 0 && excusedDays == 0
          ? PeriodStatus.paused
          : PeriodStatus.excused,
    );
  }
  if (!closed) return result(PeriodStatus.pending);
  return result(
    active > 0 || total > 0 ? PeriodStatus.partial : PeriodStatus.missed,
  );
}

/// Pro-rated required count: N when the period is complete, else ⌈N·scale⌉ (at least 1).
int _proRatedCount(int n, double scale) {
  if (scale >= 1) return n;
  return math.max(1, (n * scale - 1e-9).ceil());
}

/// Evaluates many periods (future periods are skipped unless [includeFuture]).
List<PeriodResult> evaluateHabitPeriods(
  List<HabitPeriod> periods,
  List<HabitLog> logs, {
  required DateTime now,
  required LocalDate today,
  List<HabitPause> pauses = const [],
  HabitEvaluationSettings settings = const HabitEvaluationSettings(),
  bool includeFuture = false,
}) => [
  for (final p in periods)
    if (includeFuture || !p.windowStart.isAfter(now))
      evaluateHabitPeriod(
        p,
        logs,
        now: now,
        today: today,
        pauses: pauses,
        settings: settings,
      ),
];

/// Rolls slot results up to one day result (T5.1.09): `all slots` (default) or `min N` slots.
/// Neutral slots (excused, paused, frozen, not due, and skipped when skips are neutral) are removed
/// from the requirement.
PeriodResult rollUpSlots(
  LocalDate date,
  List<PeriodResult> slots, {
  required DateTime windowStart,
  required DateTime windowEnd,
  HabitEvaluationSettings settings = const HabitEvaluationSettings(),
}) {
  bool neutral(PeriodResult r) =>
      r.status.isNeutral ||
      (r.status == PeriodStatus.skipped &&
          settings.skipPolicy == SkipPolicy.neutral);
  final counted = slots.where((r) => !neutral(r)).toList();
  final doneCount = counted.where((r) => r.status == PeriodStatus.done).length;
  final requiredCount = settings.slotRollup.requiresAll
      ? counted.length
      : math.min(settings.slotRollup.minSlots!, counted.length);
  final PeriodStatus status;
  if (slots.isEmpty || slots.every((r) => r.status == PeriodStatus.notDue)) {
    status = PeriodStatus.notDue;
  } else if (counted.isEmpty) {
    status = slots.any((r) => r.status == PeriodStatus.paused)
        ? PeriodStatus.paused
        : (slots.any((r) => r.status == PeriodStatus.frozen)
              ? PeriodStatus.frozen
              : PeriodStatus.excused);
  } else if (doneCount >= requiredCount) {
    status = PeriodStatus.done;
  } else if (counted.any((r) => r.status == PeriodStatus.pending)) {
    status = PeriodStatus.pending;
  } else if (doneCount > 0 ||
      counted.any((r) => r.status == PeriodStatus.partial)) {
    status = PeriodStatus.partial;
  } else if (counted.every((r) => r.status == PeriodStatus.skipped)) {
    status = PeriodStatus.skipped;
  } else if (counted.any((r) => r.status == PeriodStatus.failed)) {
    status = PeriodStatus.failed;
  } else {
    status = PeriodStatus.missed;
  }
  return PeriodResult(
    _dayKey(date),
    kind: HabitPeriodKind.day,
    startDate: date,
    endDate: date,
    windowStart: windowStart,
    windowEnd: windowEnd,
    status: status,
    achieved: doneCount.toDouble(),
    target: requiredCount.toDouble(),
    goal: const HabitGoal(HabitGoalType.count),
    entries: [for (final s in slots) ...s.entries],
    flags: PeriodFlags(
      breaksStreak:
          status == PeriodStatus.skipped &&
          settings.skipPolicy == SkipPolicy.breaks,
    ),
  );
}
