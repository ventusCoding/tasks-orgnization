/// Data-quality plumbing (T6.1.20): how complete and trustworthy the user's data is, shared by the
/// habit card (HB-H-25), the Habits section (HB-X-12) and the Overview (GL-10).
///
/// - Logged ratio: units with any log ÷ closed scheduled units (day-level units; intraday slots
///   through their day roll-up, quota periods as they are).
/// - Unknown units: `missed` units without any log — "unlogged", not "failed".
/// - Backfill share: logs created more than 24 h after their unit ended ÷ logs.
/// - Actual-time coverage (planner, PL-X-41): the package's `actualTimeCoverage`.
/// - Sync caveat: pending outbox changes (another device's data may be missing).
library;

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/habit_resolution.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';

/// Completeness of [evaluations] over [range] (units ending in the range; open units excluded by the
/// calculator).
DataCompleteness habitCompletenessIn(Iterable<HabitEvaluation> evaluations, DateRange range) => dataCompleteness([
  for (final e in evaluations)
    for (final u in e.outcomeUnits)
      if (range.contains(u.endDate)) u,
]);

/// Unlogged units (`missed` without any log) of [e] in [range], most recent first.
List<PeriodResult> unloggedUnits(HabitEvaluation e, DateRange range) => [
  for (final u in e.outcomeUnits.reversed)
    if (range.contains(u.endDate) && isClosedScheduled(u) && u.status == PeriodStatus.missed && u.entries.isEmpty) u,
];

/// The completeness tiles of HB-H-25 / HB-X-12 (the unknown tile drills into its units).
TilesData completenessTiles(DataCompleteness c) => TilesData([
  ValueTile(const TokenLabel(LabelToken.loggedRatio), c.loggedRatio.valueOrNull, StatUnit.percent),
  ValueTile(
    const TokenLabel(LabelToken.unknownUnits),
    c.unknownUnits.toDouble(),
    StatUnit.count,
    drillKey: 'unknown',
    direction: MetricDirection.lowerIsBetter,
  ),
  ValueTile(
    const TokenLabel(LabelToken.backfillShare),
    c.backfillShare.valueOrNull,
    StatUnit.percent,
    direction: MetricDirection.lowerIsBetter,
  ),
]);
