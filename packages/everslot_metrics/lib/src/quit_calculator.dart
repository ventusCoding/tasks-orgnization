/// Quit calculator (T5.3.03): the single, pure implementation of quit arithmetic used by the quit
/// dashboard, Today, widgets, notifications and the [6.6] analytics (which call it rather than
/// re-implementing it).
///
/// - **Attempts:** the first starts at `quit_started_at` (qd); each `restart` log starts a new one.
/// - **Use events:** `relapse` logs in abstain mode, `use` logs in reduce mode; amount null → 1.
/// - **Abstinence intervals:** between consecutive boundaries {qd, restarts, uses}; the current one
///   runs to now. Current abstinence start = max(qd, last restart, last use).
/// - **Day facts:** local dates from qd's date to today, each with the revision in force (baseline,
///   unit cost, daily limit); the first day is pro-rated by time from qd, today by time elapsed.
/// - **Units avoided (QT-06):** abstain Σ_d base_d·frac_d − Σ a_j, floored at 0 (per-day values may
///   be negative on heavy lapse days); reduce Σ_d max(0, base_d·frac_d − used_d).
/// - **Money (QT-07/08):** `Decimal`, piecewise over revisions: saved = Σ_d avoided_d × cpu_d;
///   spent on lapses = Σ a_j × cpu at t_j.
/// - **Time won back** = units avoided × `time_per_unit_minutes`; **life regained** = units avoided
///   × `life_minutes_per_unit` (a population estimate).
/// - Durations use instants (DST-safe); day buckets use `local_date`.
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// `habits.quit_mode`.
enum QuitMode { abstain, reduce }

/// A `habit_revisions` row for quit economics (null fields fall back to the tracker's values).
@immutable
final class const QuitRevision(
  final LocalDate effectiveFrom, {
  final double? baselinePerDay,
  final Decimal? unitCost,
  final double? dailyLimit,
});

/// Quit tracker configuration (`habits` quit columns).
@immutable
final class const QuitTracker(
  final DateTime quitStartedAt, {
  required final QuitMode mode,
  required final DayBoundaries days,
  final bool autoSuccess = true,
  final double baselinePerDay = 0,
  final Decimal? unitCost,
  final double? dailyLimit,
  final List<QuitRevision> revisions = const [],
  final double? timePerUnitMinutes,
  final double? lifeMinutesPerUnit,
  final String? substance,
  final String? currency,
}) {
  /// Economics in force on [date] (latest revision with `effective_from ≤ date`, else the tracker's
  /// own values).
  QuitEconomics economicsOn(LocalDate date) {
    final r = effectiveOn(revisions, date, (r) => r.effectiveFrom);
    return QuitEconomics(
      baselinePerDay: r?.baselinePerDay ?? baselinePerDay,
      unitCost: r?.unitCost ?? unitCost,
      dailyLimit: r?.dailyLimit ?? dailyLimit,
    );
  }
}

/// Baseline, unit cost and limit in force on a day.
@immutable
final class const QuitEconomics({
  required final double baselinePerDay,
  required final Decimal? unitCost,
  required final double? dailyLimit,
});

/// A quit-relevant `habit_logs` row.
@immutable
final class const QuitLog(
  final String id,
  final HabitLogKind kind, {
  required final DateTime loggedAt,
  required final LocalDate localDate,
  final double? value,
  final int? intensity,
  final String? trigger,
  final String? place,
  final String? coping,
  final int? mood,
  final bool? resisted,
  final int? durationSeconds,
  final String? note,
}) {
  /// Amount of a use (null → 1).
  double get amount => value ?? 1;
}

/// How an attempt or abstinence interval ended.
enum QuitEndReason { use, restart, ongoing }

/// One quit attempt `[start, end)`.
@immutable
final class const QuitAttempt(
  final int index,
  final DateTime start, {
  required final DateTime? end,
  required final QuitEndReason endedBy,
  required final List<QuitLog> uses,
}) {
  Duration durationAt(DateTime now) => (end ?? now).difference(start);

  bool get isCurrent => end == null;
}

/// One abstinence interval `[start, end)` (end null = current).
@immutable
final class const AbstinenceInterval(
  final DateTime start, {
  required final DateTime? end,
  required final QuitEndReason endedBy,
}) {
  Duration durationAt(DateTime now) => (end ?? now).difference(start);
}

/// Clean status of a local day.
enum QuitDayStatus {
  /// No use (auto-success) or an explicit `clean` log.
  clean,

  /// At least one use (abstain: lapse).
  used,

  /// Explicit mode and no `clean` log.
  unknown,

  /// Today (still open).
  pending,
}

/// One local day since the quit date (`QuitDayFact` of [6.6] T6.6.01).
@immutable
final class const QuitDayFact(
  final LocalDate localDate, {
  required final double used,
  required final double base,
  required final Decimal? cpu,
  required final double? limit,
  required final double fraction,
  required final bool closed,
  required final QuitDayStatus status,
  required final double avoided,
}) {
  /// No use that day.
  bool get abstinent => used == 0;

  /// Reduce mode: used ≤ limit (null without a limit).
  bool? get withinLimit => limit == null ? null : used <= limit! + 1e-9;
}

/// Savings projection at the current baseline × unit cost (QT-09).
@immutable
final class const SavingsProjection({
  required final Decimal perDay,
  required final Decimal nextMonth,
  required final Decimal nextYear,
  required final Decimal nextFiveYears,
  required final int monthDays,
  required final int yearDays,
  required final int fiveYearDays,
});

Decimal _dec(double v) => Decimal.parse(v.toString());

/// The quit calculator for one tracker at one instant [now].
final class QuitCalculator {
  new(this.tracker, List<QuitLog> logs, {required this.now})
    : logs = [...logs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  final QuitTracker tracker;
  final DateTime now;

  /// All logs sorted by `logged_at`.
  final List<QuitLog> logs;

  DateTime get quitStartedAt => tracker.quitStartedAt;

  HabitLogKind get _useKind => tracker.mode == QuitMode.abstain ? HabitLogKind.relapse : HabitLogKind.use;

  /// Use events (relapse in abstain mode, use in reduce mode) at or after qd and not after now.
  late final List<QuitLog> uses = [
    for (final l in logs)
      if (l.kind == _useKind && !l.loggedAt.isBefore(quitStartedAt) && !l.loggedAt.isAfter(now)) l,
  ];

  /// Restart logs after qd (each starts a new attempt).
  late final List<QuitLog> restarts = [
    for (final l in logs)
      if (l.kind == HabitLogKind.restart && l.loggedAt.isAfter(quitStartedAt) && !l.loggedAt.isAfter(now)) l,
  ];

  /// Quit attempts (QT-20).
  late final List<QuitAttempt> attempts = () {
    final starts = [quitStartedAt, for (final r in restarts) r.loggedAt];
    return [
      for (var i = 0; i < starts.length; i++)
        QuitAttempt(
          i + 1,
          starts[i],
          end: i + 1 < starts.length ? starts[i + 1] : null,
          endedBy: i + 1 < starts.length ? QuitEndReason.restart : QuitEndReason.ongoing,
          uses: [
            for (final u in uses)
              if (!u.loggedAt.isBefore(starts[i]) && (i + 1 >= starts.length || u.loggedAt.isBefore(starts[i + 1]))) u,
          ],
        ),
    ];
  }();

  /// Abstinence intervals between consecutive boundaries {qd, restarts, uses}.
  late final List<AbstinenceInterval> abstinenceIntervals = () {
    final boundaries = <(DateTime, QuitEndReason)>[
      for (final r in restarts) (r.loggedAt, QuitEndReason.restart),
      for (final u in uses) (u.loggedAt, QuitEndReason.use),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final result = <AbstinenceInterval>[];
    var start = quitStartedAt;
    for (final (at, reason) in boundaries) {
      if (at.isAfter(start)) {
        result.add(AbstinenceInterval(start, end: at, endedBy: reason));
      }
      if (at.isAfter(start)) start = at;
    }
    result.add(AbstinenceInterval(start, end: null, endedBy: QuitEndReason.ongoing));
    return result;
  }();

  /// Start of the current abstinence: max(qd, last restart, last use).
  DateTime get currentAbstinenceStart => abstinenceIntervals.last.start;

  /// QT-01 — time since the first quit (now − qd).
  Duration get timeSinceQuit => now.difference(quitStartedAt);

  /// QT-02 — current abstinence (now − max(qd, last restart, last use)).
  Duration get currentAbstinence => now.difference(currentAbstinenceStart);

  /// QT-03 — longest abstinence interval (including the current one).
  Duration get longestAbstinence =>
      abstinenceIntervals.map((i) => i.durationAt(now)).fold(Duration.zero, (a, b) => a > b ? a : b);

  /// Day facts from qd's local date through today.
  late final List<QuitDayFact> days = () {
    final b = tracker.days;
    final firstDate = b.dateOf(quitStartedAt);
    final today = b.dateOf(now);
    if (today.isBefore(firstDate)) return <QuitDayFact>[];
    final usedByDate = <LocalDate, double>{};
    for (final u in uses) {
      usedByDate[u.localDate] = (usedByDate[u.localDate] ?? 0) + u.amount;
    }
    final cleanDates = {
      for (final l in logs)
        if (l.kind == HabitLogKind.clean) l.localDate,
    };
    final result = <QuitDayFact>[];
    for (var d = firstDate; !d.isAfter(today); d = d.plusDays(1)) {
      final start = b.startOf(d);
      final end = b.endOf(d);
      final length = end.difference(start).inMicroseconds;
      final from = start.isBefore(quitStartedAt) ? quitStartedAt : start;
      final to = end.isAfter(now) ? now : end;
      final fraction = length <= 0 ? 0.0 : (to.difference(from).inMicroseconds / length).clamp(0.0, 1.0);
      final closed = !end.isAfter(now);
      final econ = tracker.economicsOn(d);
      final used = usedByDate[d] ?? 0;
      final QuitDayStatus status;
      if (used > 0) {
        status = QuitDayStatus.used;
      } else if (!closed) {
        status = QuitDayStatus.pending;
      } else if (tracker.autoSuccess || cleanDates.contains(d)) {
        status = QuitDayStatus.clean;
      } else {
        status = QuitDayStatus.unknown;
      }
      final expectedUse = econ.baselinePerDay * fraction;
      final avoided = tracker.mode == QuitMode.abstain
          ? expectedUse - used
          : math.max(0, expectedUse - used).toDouble();
      result.add(
        QuitDayFact(
          d,
          used: used,
          base: econ.baselinePerDay,
          cpu: econ.unitCost,
          limit: econ.dailyLimit,
          fraction: fraction,
          closed: closed,
          status: status,
          avoided: avoided,
        ),
      );
    }
    return result;
  }();

  /// Closed local days since qd (days whose end ≤ now).
  List<QuitDayFact> get closedDays => [
    for (final d in days)
      if (d.closed) d,
  ];

  /// QT-04 — clean (abstinent) closed days: no use, and — in explicit mode — a `clean` log.
  int get cleanDays => closedDays.where((d) => d.status == QuitDayStatus.clean).length;

  /// Closed days without any use (regardless of explicit confirmation).
  int get abstinentDays => closedDays.where((d) => d.abstinent).length;

  /// Explicit mode: closed days without a use and without a `clean` log.
  int get unknownDays => closedDays.where((d) => d.status == QuitDayStatus.unknown).length;

  /// QT-05 — clean days ÷ closed local days since qd.
  Stat<double> get cleanDayShare => safeDivide(cleanDays, closedDays.length, sampleSize: closedDays.length);

  /// QT-06 — units avoided (fractional current day allowed).
  double get unitsAvoided {
    final total = days.fold<double>(0, (acc, d) => acc + d.avoided);
    return math.max(0, total);
  }

  /// Units avoided per day (the line of QT-06).
  List<(LocalDate, double)> get unitsAvoidedByDay => [for (final d in days) (d.localDate, d.avoided)];

  /// QT-07 — money saved: Σ_d avoided_d × cpu_d (piecewise over revisions), floored at 0.
  Decimal get moneySaved {
    var total = Decimal.zero;
    for (final d in days) {
      final cpu = d.cpu;
      if (cpu == null) continue;
      total += _dec(d.avoided) * cpu;
    }
    return total < Decimal.zero ? Decimal.zero : total;
  }

  /// Money saved per local day (QT-23 bars).
  List<(LocalDate, Decimal)> get moneySavedByDay => [
    for (final d in days) (d.localDate, d.cpu == null ? Decimal.zero : _dec(d.avoided) * d.cpu!),
  ];

  /// QT-08 — money spent on lapses/uses: Σ a_j × cpu at t_j.
  Decimal get moneySpent {
    var total = Decimal.zero;
    for (final u in uses) {
      final cpu = tracker.economicsOn(u.localDate).unitCost;
      if (cpu != null) total += _dec(u.amount) * cpu;
    }
    return total;
  }

  /// QT-22 — time not spent consuming (minutes) = units avoided × TPU; null without TPU.
  double? get timeWonBackMinutes {
    final tpu = tracker.timePerUnitMinutes;
    return tpu == null ? null : unitsAvoided * tpu;
  }

  /// QT-10 — life regained (minutes, population estimate) = units avoided × LMU; null without LMU.
  double? get lifeRegainedMinutes {
    final lmu = tracker.lifeMinutesPerUnit;
    return lmu == null ? null : unitsAvoided * lmu;
  }

  /// QT-09 — savings projections at the current baseline × unit cost, over the next calendar month,
  /// year and five years from today.
  SavingsProjection? get savingsProjection {
    final today = tracker.days.dateOf(now);
    final econ = tracker.economicsOn(today);
    final cpu = econ.unitCost;
    if (cpu == null) return null;
    final perDay = _dec(econ.baselinePerDay) * cpu;
    final monthDays = today.daysUntil(today.plusMonths(1));
    final yearDays = today.daysUntil(today.plusYears(1));
    final fiveYearDays = today.daysUntil(today.plusYears(5));
    return SavingsProjection(
      perDay: perDay,
      nextMonth: perDay * Decimal.fromInt(monthDays),
      nextYear: perDay * Decimal.fromInt(yearDays),
      nextFiveYears: perDay * Decimal.fromInt(fiveYearDays),
      monthDays: monthDays,
      yearDays: yearDays,
      fiveYearDays: fiveYearDays,
    );
  }

  /// Reduce mode: closed days within the limit (used ≤ limit in force).
  int get withinLimitDays => closedDays.where((d) => d.withinLimit ?? false).length;

  /// Reduce mode: consecutive successful closed days up to yesterday (0 when today is already over
  /// the limit). Abstain mode: consecutive clean closed days.
  int get dayStreak {
    final today = days.isEmpty ? null : days.last;
    if (today != null && !today.closed && !_daySuccess(today, allowOpen: true)) {
      return 0;
    }
    var streak = 0;
    for (final d in closedDays.reversed) {
      if (!_daySuccess(d)) break;
      streak++;
    }
    return streak;
  }

  /// Longest run of successful closed days.
  int get bestDayStreak {
    var best = 0;
    var run = 0;
    for (final d in closedDays) {
      run = _daySuccess(d) ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  bool _daySuccess(QuitDayFact d, {bool allowOpen = false}) {
    if (tracker.mode == QuitMode.reduce) return d.withinLimit ?? d.abstinent;
    if (allowOpen && d.status == QuitDayStatus.pending) return true;
    return d.status == QuitDayStatus.clean;
  }
}

/// A milestone row of the (smoking) content table or a day milestone: single point ([tMax] null)
/// or range [tMin, tMax].
@immutable
final class const QuitMilestone(final String id, {required final Duration tMin, final Duration? tMax}) {
  bool get isRange => tMax != null && tMax! > tMin;
}

/// State of a milestone.
enum MilestoneState { done, inWindow, upcoming }

/// Progress of one milestone for the current abstinence.
@immutable
final class const MilestoneProgress(
  final QuitMilestone milestone, {
  required final double progress,
  required final MilestoneState state,
  required final DateTime eta,
  required final bool isNext,
});

/// P0 day milestones (1/3/7/14/30/60/90/180/365 days).
final List<QuitMilestone> defaultDayMilestones = [
  for (final d in const [1, 3, 7, 14, 30, 60, 90, 180, 365]) QuitMilestone('day_$d', tMin: Duration(days: d)),
];

/// QT-11 — milestone progress driven by the current abstinence (the clock restarts after a lapse):
/// - single point: progress = min(1, elapsed ÷ t), done when elapsed ≥ t;
/// - range: the bar runs to tMax with a marker at tMin; "in window" between tMin and tMax;
/// - ETA = abstinence start + t (tMin while upcoming, tMax while in window);
/// - the next milestone is the first one (by tMin) not yet done.
List<MilestoneProgress> milestoneProgress(
  List<QuitMilestone> table, {
  required DateTime abstinenceStart,
  required DateTime now,
}) {
  final elapsed = now.difference(abstinenceStart);
  final sorted = [...table]..sort((a, b) => a.tMin.compareTo(b.tMin));
  var nextAssigned = false;
  return [
    for (final m in sorted)
      () {
        final end = m.isRange ? m.tMax! : m.tMin;
        final MilestoneState state;
        if (elapsed >= end) {
          state = MilestoneState.done;
        } else if (m.isRange && elapsed >= m.tMin) {
          state = MilestoneState.inWindow;
        } else {
          state = MilestoneState.upcoming;
        }
        final isNext = !nextAssigned && state != MilestoneState.done;
        if (isNext) nextAssigned = true;
        final progress = end.inMicroseconds <= 0
            ? 1.0
            : math.min(1, elapsed.inMicroseconds / end.inMicroseconds).toDouble();
        return MilestoneProgress(
          m,
          progress: math.max(0, progress),
          state: state,
          eta: abstinenceStart.add(state == MilestoneState.inWindow ? end : m.tMin),
          isNext: isNext,
        );
      }(),
  ];
}

/// Which SRNT rule classified an attempt as a relapse.
enum RelapseRule { sevenConsecutiveDays, twoConsecutiveBlocks }

/// QT-18 — lapse vs relapse classification of one attempt.
@immutable
final class const RelapseClassification({
  required final int lapseDays,
  required final bool isRelapse,
  required final RelapseRule? rule,
  required final LocalDate? detectedOn,
  required final double unitsAfterGrace,
  required final bool russellSustained,
});

/// Classifies an attempt that started on [attemptStartDate] (day 1) from its use days:
/// - lapse = any use;
/// - relapse (SRNT) = use on 7 consecutive days, or use on ≥ 1 day in each of 2 consecutive 7-day
///   blocks counted from the attempt start (days 1–7 = block 1, 8–14 = block 2, …);
/// - Russell Standard sustained abstinence = ≤ 5 units in total after a 2-week grace period
///   (uses on days 1–14 are ignored).
RelapseClassification classifyRelapse(LocalDate attemptStartDate, Iterable<(LocalDate date, double amount)> useDays) {
  final byDay = <int, double>{};
  for (final (date, amount) in useDays) {
    final day = attemptStartDate.daysUntil(date) + 1;
    if (day < 1) continue;
    byDay[day] = (byDay[day] ?? 0) + amount;
  }
  final daysSorted = byDay.keys.toList()..sort();
  RelapseRule? rule;
  int? detectedDay;
  // Seven consecutive use days.
  var run = 0;
  int? prev;
  for (final d in daysSorted) {
    run = prev != null && d == prev + 1 ? run + 1 : 1;
    prev = d;
    if (run >= 7) {
      rule = RelapseRule.sevenConsecutiveDays;
      detectedDay = d;
      break;
    }
  }
  // Uses in two consecutive 7-day blocks.
  final blocks = <int, int>{};
  for (final d in daysSorted) {
    blocks.putIfAbsent((d - 1) ~/ 7 + 1, () => d);
  }
  for (final b in blocks.keys.toList()..sort()) {
    final nextFirst = blocks[b + 1];
    if (nextFirst != null && (detectedDay == null || nextFirst < detectedDay)) {
      rule = RelapseRule.twoConsecutiveBlocks;
      detectedDay = nextFirst;
      break;
    }
  }
  final afterGrace = byDay.entries.where((e) => e.key > 14).fold<double>(0, (acc, e) => acc + e.value);
  return RelapseClassification(
    lapseDays: daysSorted.length,
    isRelapse: rule != null,
    rule: rule,
    detectedOn: detectedDay == null ? null : attemptStartDate.plusDays(detectedDay - 1),
    unitsAfterGrace: afterGrace,
    russellSustained: afterGrace <= 5,
  );
}

/// QT-21 — days until a savings goal is reached at [dailySaving]: ⌈(goal − saved) ÷ dailySaving⌉
/// (0 when reached; [NotApplicable] without a positive daily saving).
Stat<int> savingsGoalEtaDays({required Decimal saved, required Decimal goal, required Decimal dailySaving}) {
  if (saved >= goal) return const Value<int>(0);
  if (dailySaving <= Decimal.zero) {
    return const NotApplicable<int>(Reasons.zeroDenominator);
  }
  final remaining = goal - saved;
  final days = (remaining / dailySaving).ceil().toInt();
  return Value<int>(days);
}
