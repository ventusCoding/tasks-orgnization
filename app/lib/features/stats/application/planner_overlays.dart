/// Insights shown where the user plans (T6.3.20) — the stats side of the planner overlays:
/// slot occupancy of the last four weeks at the view's slot size (PL-X-35/36) for the week-table
/// heat layer, and a series' mini-stats (adherence, current streak) for the tile preview.
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One batch through the compute service (results are memoized by the stats cache; no keep-alive,
/// these overlays come and go with the planner view).
Future<StatsBatch> _compute(Ref ref, StatsRequest request) {
  final versions = ref.watch(statsDataVersionsProvider);
  ref.watch(statsSettingsProvider);
  final now = ref.read(clockProvider).nowUtc();
  return ref
      .watch(statsComputeServiceProvider)
      .computeBatch(request, dataVersion: dataVersionKey(versions, request.scope, now));
}

/// Planned occupancy (0–1) per (ISO weekday, slot start minute) and the dead slots.
@immutable
final class SlotOccupancyOverlay {
  const SlotOccupancyOverlay(this.slotMinutes, this.planned, this.dead);

  static const empty = SlotOccupancyOverlay(60, {}, {});

  final int slotMinutes;
  final Map<(int, int), double> planned;
  final Set<(int, int)> dead;

  double plannedAt(int weekdayIso, int slotStart) => planned[(weekdayIso, slotStart)] ?? 0;
}

/// Slot occupancy over the last 28 days at [slotMinutes] (week-table overlay).
final slotOccupancyOverlayProvider = FutureProvider.autoDispose.family<SlotOccupancyOverlay, int>((
  ref,
  slotMinutes,
) async {
  final batch = await _compute(
    ref,
    StatsRequest(
      MetricScope.planner,
      selection: const PeriodSelection(StatsPeriod.rolling(28), compare: false),
      metricIds: const {'PL-X-35', 'PL-X-36'},
      extra: 'slot:$slotMinutes',
    ),
  );
  final matrix = batch['PL-X-35']?.chart;
  final planned = <(int, int), double>{};
  if (matrix is MatrixData) {
    for (var r = 0; r < matrix.rows.length; r++) {
      final row = matrix.rows[r];
      if (row is! WeekdayLabel) continue;
      for (var c = 0; c < matrix.columns.length; c++) {
        final v = matrix.values[r][c];
        if (v != null && v > 0) planned[(row.weekday.iso, c * slotMinutes)] = v;
      }
    }
  }
  final deadList = batch['PL-X-36']?.chart;
  final dead = <(int, int)>{
    if (deadList is ListData)
      for (final row in deadList.rows)
        if (row.label case WeekdayLabel(:final weekday))
          if (row.secondary case NumberLabel(:final value)) (weekday.iso, value.round()),
  };
  return SlotOccupancyOverlay(slotMinutes, planned, dead);
});

/// A series' adherence and current streak (the tile long-press preview).
@immutable
final class SeriesMiniStats {
  const SeriesMiniStats({this.adherence, this.streak});

  /// Adherence over the last 28 days (0–1), null when not enough data.
  final double? adherence;

  /// Current streak (occurrences).
  final int? streak;

  bool get isEmpty => adherence == null && streak == null;
}

final seriesMiniStatsProvider = FutureProvider.autoDispose.family<SeriesMiniStats, String>((ref, seriesId) async {
  final batch = await _compute(
    ref,
    StatsRequest(
      MetricScope.series,
      scopeId: seriesId,
      selection: const PeriodSelection(StatsPeriod.rolling(28), compare: false),
      metricIds: const {'PL-S-03', 'PL-S-05'},
    ),
  );
  return SeriesMiniStats(
    adherence: batch['PL-S-03']?.value.valueOrNull,
    streak: batch['PL-S-05']?.value.valueOrNull?.round(),
  );
});
