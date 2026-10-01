/// Streak engine (T6.1.09): one implementation for habits, planner series, checklist runs and
/// goal streaks.
///
/// - **Unit:** an occurrence for fixed rules; a period (week/month) for quota rules.
/// - **Success** extends a streak; **breaks** (failed, missed, partial — and skipped when the skip
///   policy is `breaks`) end it; **neutral** units (not scheduled, excused, paused, frozen, skipped
///   under the neutral policy) and the **open** current unit neither extend nor break it.
/// - **Two length policies:** `successfulUnits` (UI default) and `calendarSpan` (Loop style: from
///   the first to the last success, bridging neutral units). Both are reported.
/// - **Freezes:** each calendar month grants `freezesPerMonth` freezes (no carry-over). A freezable
///   miss consumes one automatically, oldest first, and becomes `frozen` (neutral). Freezes
///   materialized as `freeze` logs count against the same allotment.
/// - Optional P2 rule (flag): one miss forgiven per N units.
library;

import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// Role of a unit in streak computation.
enum StreakUnitKind { success, breaks, neutral, open }

/// Streak length policy.
enum StreakLengthPolicy { successfulUnits, calendarSpan }

/// One unit in chronological order.
@immutable
final class const StreakUnit(
  final String key, {
  required final LocalDate start,
  required final LocalDate end,
  required final StreakUnitKind kind,

  /// A break a freeze may protect (missed or failed; not partial).
  final bool freezable = false,

  /// Already frozen by a materialized `freeze` log.
  final bool frozen = false,
});

/// One streak (a maximal run of successes, neutral units bridged).
@immutable
final class const Streak(
  final String startKey,
  final String endKey, {
  required final LocalDate startDate,
  required final LocalDate endDate,
  required final int length,
  required final int spannedUnits,
  required final int frozenUnits,
  required final bool isCurrent,
}) {
  /// Calendar days from the first success's start to the last success's end (inclusive).
  int get calendarSpanDays => startDate.daysUntil(endDate) + 1;

  int lengthFor(StreakLengthPolicy policy) => switch (policy) {
    StreakLengthPolicy.successfulUnits => length,
    StreakLengthPolicy.calendarSpan => calendarSpanDays,
  };
}

/// Result of the streak engine.
@immutable
final class const StreakSummary(
  final List<Streak> streaks, {
  required final Streak? current,
  required final Streak? best,
  required final List<String> frozenKeys,
  required final List<String> forgivenKeys,
  required final Map<String, int> freezesUsedByMonth,
}) {
  /// Current streak in successful units (0 when broken).
  int get currentLength => current?.length ?? 0;

  /// Best streak in successful units.
  int get bestLength => best?.length ?? 0;

  /// Current calendar span in days (0 when broken).
  int get currentCalendarSpan => current?.calendarSpanDays ?? 0;

  /// Best streak's calendar span in days.
  int get bestCalendarSpan => best?.calendarSpanDays ?? 0;

  /// Streaks ordered by length, then recency (latest end first).
  List<Streak> get ranked => [...streaks]
    ..sort((a, b) {
      final c = b.length.compareTo(a.length);
      return c != 0 ? c : b.endDate.compareTo(a.endDate);
    });

  /// Top-10 streaks.
  List<Streak> get top10 => ranked.take(10).toList();

  /// Longest streak by the calendar-span policy.
  Streak? get bestBySpan {
    Streak? b;
    for (final s in streaks) {
      if (b == null ||
          s.calendarSpanDays > b.calendarSpanDays ||
          (s.calendarSpanDays == b.calendarSpanDays && s.endDate.isAfter(b.endDate))) {
        b = s;
      }
    }
    return b;
  }
}

String _monthKey(LocalDate d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// Computes all streaks over [units] (any order; sorted by start date).
StreakSummary computeStreaks(List<StreakUnit> units, {int freezesPerMonth = 0, int? forgiveOneMissPerUnits}) {
  final sorted = [...units]..sort((a, b) => a.start.compareTo(b.start));
  final used = <String, int>{};
  final frozenKeys = <String>[];
  final forgivenKeys = <String>[];
  final kinds = <StreakUnitKind>[];
  final frozenFlags = <bool>[];
  int? lastForgivenIndex;
  var scheduledIndex = 0;
  for (final u in sorted) {
    var kind = u.kind;
    var frozen = false;
    final month = _monthKey(u.end);
    if (u.frozen) {
      used[month] = (used[month] ?? 0) + 1;
      frozenKeys.add(u.key);
      kind = StreakUnitKind.neutral;
      frozen = true;
    } else if (kind == StreakUnitKind.breaks && u.freezable && (used[month] ?? 0) < freezesPerMonth) {
      used[month] = (used[month] ?? 0) + 1;
      frozenKeys.add(u.key);
      kind = StreakUnitKind.neutral;
      frozen = true;
    } else if (kind == StreakUnitKind.breaks &&
        forgiveOneMissPerUnits != null &&
        (lastForgivenIndex == null || scheduledIndex - lastForgivenIndex >= forgiveOneMissPerUnits)) {
      forgivenKeys.add(u.key);
      lastForgivenIndex = scheduledIndex;
      kind = StreakUnitKind.neutral;
    }
    if (u.kind == StreakUnitKind.success || u.kind == StreakUnitKind.breaks) {
      scheduledIndex++;
    }
    kinds.add(kind);
    frozenFlags.add(frozen);
  }

  final streaks = <Streak>[];
  int? first;
  int? last;
  var length = 0;
  var frozenInRun = 0;
  var frozenPending = 0;

  Streak build({required bool current}) {
    final f = first!;
    final l = last!;
    return Streak(
      sorted[f].key,
      sorted[l].key,
      startDate: sorted[f].start,
      endDate: sorted[l].end,
      length: length,
      spannedUnits: l - f + 1,
      frozenUnits: frozenInRun,
      isCurrent: current,
    );
  }

  for (var i = 0; i < sorted.length; i++) {
    switch (kinds[i]) {
      case StreakUnitKind.success:
        first ??= i;
        last = i;
        length++;
        frozenInRun += frozenPending;
        frozenPending = 0;
      case StreakUnitKind.breaks:
        if (length > 0) streaks.add(build(current: false));
        first = null;
        last = null;
        length = 0;
        frozenInRun = 0;
        frozenPending = 0;
      case StreakUnitKind.neutral || StreakUnitKind.open:
        if (length > 0 && frozenFlags[i]) frozenPending++;
    }
  }
  Streak? current;
  if (length > 0) {
    current = build(current: true);
    streaks.add(current);
  }
  Streak? best;
  for (final s in streaks) {
    if (best == null || s.length > best.length || (s.length == best.length && s.endDate.isAfter(best.endDate))) {
      best = s;
    }
  }
  return StreakSummary(
    streaks,
    current: current,
    best: best,
    frozenKeys: frozenKeys,
    forgivenKeys: forgivenKeys,
    freezesUsedByMonth: used,
  );
}

/// Streak units from habit [PeriodResult]s: done → success; failed/missed → breaks (freezable);
/// partial → breaks; skipped → neutral or breaks per [skipPolicy]; excused/paused/not due →
/// neutral; frozen → neutral (counts against the freeze allotment); pending → open.
List<StreakUnit> streakUnitsFromPeriods(Iterable<PeriodResult> results, {SkipPolicy skipPolicy = SkipPolicy.neutral}) =>
    [
      for (final r in results)
        StreakUnit(
          r.key,
          start: r.startDate,
          end: r.endDate,
          kind: switch (r.status) {
            PeriodStatus.done => StreakUnitKind.success,
            PeriodStatus.failed || PeriodStatus.missed || PeriodStatus.partial => StreakUnitKind.breaks,
            PeriodStatus.skipped =>
              skipPolicy == SkipPolicy.breaks || r.flags.breaksStreak ? StreakUnitKind.breaks : StreakUnitKind.neutral,
            PeriodStatus.excused ||
            PeriodStatus.paused ||
            PeriodStatus.notDue ||
            PeriodStatus.frozen => StreakUnitKind.neutral,
            PeriodStatus.pending => StreakUnitKind.open,
          },
          freezable: r.status == PeriodStatus.failed || r.status == PeriodStatus.missed,
          frozen: r.status == PeriodStatus.frozen,
        ),
    ];

/// At-risk flag for fixed rules: the current unit is due, not yet done, and closes within the
/// at-risk horizon (default: end of today).
bool isFixedUnitAtRisk({required bool dueAndNotDone, required DateTime closesAt, required DateTime horizonEnd}) =>
    dueAndNotDone && !closesAt.isAfter(horizonEnd);

/// At-risk flag for quota rules: completions still needed exceed the eligible days left.
bool isQuotaAtRisk({required int needed, required int eligibleDaysLeft}) => needed > eligibleDaysLeft;
