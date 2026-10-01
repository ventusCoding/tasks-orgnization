/// Expected-occurrences ledger — adherence denominators (T6.1.08).
///
/// Computes how many times something *should* have happened in a window, which of those units
/// happened, and how each one is classified, so every adherence, miss and on-time metric shares the
/// same denominators. The units are already expanded by the caller (recurrence engine / habit
/// period service); for habits they come from [PeriodResult]s ([ledgerUnitsFromPeriods]), for planner
/// series from resolved occurrences (`planner_metrics.dart`).
///
/// Outputs: E (expected), D (done), X (excused), M (missed), F (failed), P (pending), K (skipped),
/// bonus; adherence = D/(E − X), miss rate = (M + F)/(E − X), on-time rate = onTime/D. Open units
/// that are not yet resolved (P) are left out of the denominators, so on closed windows the
/// formulas are exactly D/(E − X) and (M + F)/(E − X).
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// State of a unit as resolved by its source (occurrence record, `PeriodResult`).
enum LedgerState {
  /// Nothing recorded yet: resolved by completion matching and the clock.
  open,
  done,
  partial,

  /// Explicit "not done".
  failed,

  /// Window closed with nothing logged (already resolved by the source).
  missed,
  skipped,
  excused,

  /// Cancelled occurrence (EXDATE): excused, counted separately.
  cancelled,
  paused,

  /// Streak freeze applied: still a miss for completion rates.
  frozen,
}

/// Classification of a unit in the ledger.
enum LedgerClass {
  onTime,
  late,
  partial,
  skipped,
  excused,
  cancelled,
  missed,
  failed,
  frozen,
  pending,
  future;

  bool get isDone => this == onTime || this == late;
}

/// One expected unit (occurrence, day, slot or quota period).
///
/// - [weight]: expected count E_u (1, or N·eligibleDays/periodDays for a quota period).
/// - [quotaCompletions]: completions inside a quota period (D_u = min(completions, weight), the
///   remainder is missed/pending, extras are bonus).
/// - [dueAt]: on-time deadline (defaults to [end]); a completion after it is `late`.
/// - [matchStart]/[matchEnd]: tolerance window for keyless completions (defaults to the unit
///   window). Day-level rules use the local day; intraday rules
///   [unit − earlyTolerance, next unit start) — see [intradayToleranceWindows].
@immutable
final class const LedgerUnit(
  final String key, {
  required final DateTime start,
  required final DateTime end,
  final LedgerState state = LedgerState.open,
  final double weight = 1,
  final double? quotaCompletions,
  final DateTime? completedAt,
  final DateTime? dueAt,
  final DateTime? matchStart,
  final DateTime? matchEnd,
  final LocalDate? date,
  final String? revisionId,
});

/// A completion to match against units: by [key] first, else by time within a tolerance window
/// (imports, legacy data).
@immutable
final class const LedgerCompletion(final DateTime at, {final String? key});

/// A classified unit.
@immutable
final class const LedgerEntry(
  final LedgerUnit unit, {
  required final LedgerClass classification,
  required final double done,
  required final double missed,
  required final double pending,
  final DateTime? completedAt,
});

/// Aggregated ledger.
@immutable
final class const Ledger(
  final List<LedgerEntry> entries, {
  required final double expected,
  required final double done,
  required final double excused,
  required final double missed,
  required final double failed,
  required final double pending,
  required final double partial,
  required final double skipped,
  required final double cancelled,
  required final double frozen,
  required final double onTime,
  required final double late,
  required final double bonus,
  required final double future,
}) {
  /// Closed expected units: E − P.
  double get expectedClosed => expected - pending;

  /// Denominator of adherence and miss rate: E − X − P.
  double get denominator => math.max(0, expected - excused - pending);

  /// Adherence (completion rate) = D/(E − X), capped at 100 %.
  Stat<double> get adherence => rate(math.min(done, denominator), denominator);

  /// Miss rate = (M + F)/(E − X).
  Stat<double> get missRate => rate(missed + failed, denominator);

  /// On-time rate = onTime/D.
  Stat<double> get onTimeRate => rate(onTime, done);

  /// Skip rate = K/E (PL-S-10).
  Stat<double> get skipRate => rate(skipped, expected - pending);

  /// Entries in chronological order of their units.
  List<LedgerEntry> get chronological => [...entries]..sort((a, b) => a.unit.start.compareTo(b.unit.start));
}

/// Tolerance windows for intraday units: [start − earlyTolerance, next unit start), the last one
/// ending at [dayEnd]. Returns `(matchStart, matchEnd)` per unit start (sorted input expected).
List<(DateTime, DateTime)> intradayToleranceWindows(
  List<DateTime> unitStarts, {
  required DateTime dayEnd,
  Duration earlyTolerance = const Duration(minutes: 30),
}) => [
  for (var i = 0; i < unitStarts.length; i++)
    (unitStarts[i].subtract(earlyTolerance), i + 1 < unitStarts.length ? unitStarts[i + 1] : dayEnd),
];

/// Quota expectation E = N · eligibleDays / periodDays (fractional).
double quotaExpectation(int times, {required int eligibleDays, required int periodDays}) =>
    proRate(times, eligibleDays, periodDays);

/// Builds the ledger.
///
/// Matching: completions with a key go to the unit with that key; keyless completions are
/// assigned, in time order, to the nearest unmatched open unit whose tolerance window contains
/// them. Unmatched or surplus completions are `bonus` (shown, but adherence is capped at 100 %).
///
/// Classification: done → onTime/late (a done unit without a completion time counts as onTime);
/// open units → matched: done; window closed: missed; started: pending; not started: future.
/// Skips are excused when [skipPolicy] is neutral (they always count in K). Future units are
/// excluded from E.
Ledger buildLedger(
  List<LedgerUnit> units, {
  required DateTime now,
  List<LedgerCompletion> completions = const [],
  SkipPolicy skipPolicy = SkipPolicy.neutral,
}) {
  final sortedUnits = [...units]..sort((a, b) => a.start.compareTo(b.start));
  final matched = <int, DateTime>{};
  final quotaMatched = <int, int>{};
  var bonus = 0.0;
  final byKey = <String, int>{};
  for (var i = 0; i < sortedUnits.length; i++) {
    byKey[sortedUnits[i].key] = i;
  }
  final keyless = <LedgerCompletion>[];
  for (final c in [...completions]..sort((a, b) => a.at.compareTo(b.at))) {
    final idx = c.key == null ? null : byKey[c.key];
    if (c.key != null && idx == null) {
      bonus += 1;
      continue;
    }
    if (idx == null) {
      keyless.add(c);
      continue;
    }
    final u = sortedUnits[idx];
    if (u.quotaCompletions != null) {
      quotaMatched[idx] = (quotaMatched[idx] ?? 0) + 1;
    } else if (u.state == LedgerState.open && !matched.containsKey(idx)) {
      matched[idx] = c.at;
    } else {
      bonus += 1;
    }
  }
  for (final c in keyless) {
    int? best;
    Duration? bestDistance;
    for (var i = 0; i < sortedUnits.length; i++) {
      final u = sortedUnits[i];
      if (u.state != LedgerState.open || u.quotaCompletions != null) continue;
      if (matched.containsKey(i)) continue;
      final from = u.matchStart ?? u.start;
      final to = u.matchEnd ?? u.end;
      if (c.at.isBefore(from) || !c.at.isBefore(to)) continue;
      final distance = c.at.difference(u.start).abs();
      if (bestDistance == null || distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (best == null) {
      bonus += 1;
    } else {
      matched[best] = c.at;
    }
  }

  final entries = <LedgerEntry>[];
  var e = 0.0;
  var d = 0.0;
  var x = 0.0;
  var m = 0.0;
  var f = 0.0;
  var p = 0.0;
  var partial = 0.0;
  var k = 0.0;
  var cancelled = 0.0;
  var frozen = 0.0;
  var onTime = 0.0;
  var late = 0.0;
  var future = 0.0;

  for (var i = 0; i < sortedUnits.length; i++) {
    final u = sortedUnits[i];
    final w = u.weight;
    final started = !u.start.isAfter(now);
    final closed = !u.end.isAfter(now);
    if (!started && u.state == LedgerState.open && !matched.containsKey(i)) {
      future += w;
      entries.add(LedgerEntry(u, classification: LedgerClass.future, done: 0, missed: 0, pending: 0));
      continue;
    }
    e += w;
    if (u.quotaCompletions != null) {
      if (u.state == LedgerState.excused || u.state == LedgerState.paused || u.state == LedgerState.cancelled) {
        x += w;
        entries.add(LedgerEntry(u, classification: LedgerClass.excused, done: 0, missed: 0, pending: 0));
        continue;
      }
      // Quota period: D_u = min(completions, E_u); the rest is missed (closed) or pending (open).
      final count = u.quotaCompletions! + (quotaMatched[i] ?? 0);
      final unitDone = math.min(count, w);
      bonus += math.max(0, count - w);
      final rest = w - unitDone;
      d += unitDone;
      onTime += unitDone;
      final LedgerClass cls;
      var missedPart = 0.0;
      var pendingPart = 0.0;
      if (rest <= 1e-12) {
        cls = LedgerClass.onTime;
      } else if (closed) {
        m += rest;
        missedPart = rest;
        cls = unitDone > 0 ? LedgerClass.partial : LedgerClass.missed;
      } else {
        p += rest;
        pendingPart = rest;
        cls = LedgerClass.pending;
      }
      entries.add(LedgerEntry(u, classification: cls, done: unitDone, missed: missedPart, pending: pendingPart));
      continue;
    }
    var state = u.state;
    var completedAt = u.completedAt;
    if (state == LedgerState.open && matched.containsKey(i)) {
      state = LedgerState.done;
      completedAt = matched[i];
    }
    final LedgerClass cls;
    switch (state) {
      case LedgerState.done:
        final due = u.dueAt ?? u.end;
        cls = completedAt == null || !completedAt.isAfter(due) ? LedgerClass.onTime : LedgerClass.late;
      case LedgerState.partial:
        cls = LedgerClass.partial;
      case LedgerState.failed:
        cls = LedgerClass.failed;
      case LedgerState.missed:
        cls = LedgerClass.missed;
      case LedgerState.skipped:
        cls = LedgerClass.skipped;
      case LedgerState.excused || LedgerState.paused:
        cls = LedgerClass.excused;
      case LedgerState.cancelled:
        cls = LedgerClass.cancelled;
      case LedgerState.frozen:
        cls = LedgerClass.frozen;
      case LedgerState.open:
        cls = closed ? LedgerClass.missed : LedgerClass.pending;
    }
    var unitDone = 0.0;
    var unitMissed = 0.0;
    var unitPending = 0.0;
    switch (cls) {
      case LedgerClass.onTime:
        d += w;
        onTime += w;
        unitDone = w;
      case LedgerClass.late:
        d += w;
        late += w;
        unitDone = w;
      case LedgerClass.partial:
        partial += w;
      case LedgerClass.failed:
        f += w;
      case LedgerClass.missed:
        m += w;
        unitMissed = w;
      case LedgerClass.frozen:
        frozen += w;
        m += w;
        unitMissed = w;
      case LedgerClass.skipped:
        k += w;
        if (skipPolicy == SkipPolicy.neutral) x += w;
      case LedgerClass.excused:
        x += w;
      case LedgerClass.cancelled:
        cancelled += w;
        x += w;
      case LedgerClass.pending:
        p += w;
        unitPending = w;
      case LedgerClass.future:
        break;
    }
    entries.add(
      LedgerEntry(
        u,
        classification: cls,
        done: unitDone,
        missed: unitMissed,
        pending: unitPending,
        completedAt: completedAt,
      ),
    );
  }
  return Ledger(
    entries,
    expected: e,
    done: d,
    excused: x,
    missed: m,
    failed: f,
    pending: p,
    partial: partial,
    skipped: k,
    cancelled: cancelled,
    frozen: frozen,
    onTime: onTime,
    late: late,
    bonus: bonus,
    future: future,
  );
}

/// Ledger units from habit [PeriodResult]s ([5.1]); `notDue` periods are not units. Quota periods
/// become one unit weighted by their pro-rated expectation, with their active days as
/// completions.
List<LedgerUnit> ledgerUnitsFromPeriods(Iterable<PeriodResult> results) => [
  for (final r in results)
    if (r.status != PeriodStatus.notDue)
      LedgerUnit(
        r.key,
        start: r.windowStart,
        end: r.windowEnd,
        date: r.startDate,
        revisionId: r.revisionId,
        weight: r.kind == HabitPeriodKind.quota ? (r.flags.expected ?? 1) : 1,
        quotaCompletions: r.kind == HabitPeriodKind.quota && !r.goal.isMeasurable
            ? (r.flags.activeDays ?? 0).toDouble()
            : null,
        state: switch (r.status) {
          PeriodStatus.done => LedgerState.done,
          PeriodStatus.partial => LedgerState.partial,
          PeriodStatus.failed => LedgerState.failed,
          PeriodStatus.missed => LedgerState.missed,
          PeriodStatus.skipped => LedgerState.skipped,
          PeriodStatus.excused => LedgerState.excused,
          PeriodStatus.frozen => LedgerState.frozen,
          PeriodStatus.paused => LedgerState.paused,
          PeriodStatus.pending || PeriodStatus.notDue => LedgerState.open,
        },
      ),
];
