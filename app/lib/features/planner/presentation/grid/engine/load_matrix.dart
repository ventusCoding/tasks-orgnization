import 'dart:math' as math;

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Load heatmap aggregation (T3.6.16) — pure: minutes per (weekday, hour) and per day, planned or
// tracked, over a range of days, measured against capacity.

/// What the load heatmap sums (`options.metric`).
enum LoadMetric {
  planned,
  tracked;

  static LoadMetric parse(String? s) => s == 'tracked' ? tracked : planned;
}

/// Minutes of a range per weekday × hour, per day, and the items behind each cell.
@immutable
class LoadMatrix {
  const LoadMatrix({required this.cells, required this.days, required this.weeks, required this.itemsByCell});

  /// `cells[weekday.iso - 1][hour]` = minutes.
  final List<List<double>> cells;

  /// Minutes per day of the range.
  final Map<LocalDate, double> days;

  /// Weeks in the range (a cell's capacity is 60 min × weeks).
  final int weeks;

  /// Item keys touching each (iso weekday, hour).
  final Map<(int, int), List<PlannerItem>> itemsByCell;

  /// Cell load: minutes ÷ (60 × weeks).
  double cellLoad(Weekday w, int hour) => cells[w.iso - 1][hour] / (60 * math.max(1, weeks));
}

/// Aggregates [items] of the [days]-day range from [start]: timed items that are not cancelled /
/// skipped, split at hour boundaries of their wall-clock interval (clipped to the range). Tracked
/// minutes (`trackedSeconds`) are spread over the planned interval in proportion.
LoadMatrix loadMatrix(
  Iterable<PlannerItem> items, {
  required LocalDate start,
  required int days,
  LoadMetric metric = LoadMetric.planned,
}) {
  final cells = List.generate(7, (_) => List<double>.filled(24, 0));
  final perDay = <LocalDate, double>{};
  final byCell = <(int, int), List<PlannerItem>>{};
  final from = start.atStartOfDay;
  final to = start.plusDays(days).atStartOfDay;
  for (final i in items) {
    if (i.isBacklog || i.allDay || i.durationMinutes <= 0) continue;
    if (i.status == OccurrenceStatus.cancelled || i.status == OccurrenceStatus.skipped) continue;
    final factor = switch (metric) {
      LoadMetric.planned => 1.0,
      LoadMetric.tracked => (i.trackedSeconds ?? 0) / 60 / i.durationMinutes,
    };
    if (factor <= 0) continue;
    var t = i.startLocal.isBefore(from) ? from : i.startLocal;
    final end = i.endLocal.isAfter(to) ? to : i.endLocal;
    while (t.isBefore(end)) {
      final nextHour = t.date.atTime(LocalTime(t.time.hour, 0)).plusMinutes(60);
      final stop = nextHour.isBefore(end) ? nextHour : end;
      final minutes = t.minutesUntil(stop) * factor;
      final w = t.date.weekday.iso;
      cells[w - 1][t.time.hour] += minutes;
      perDay[t.date] = (perDay[t.date] ?? 0) + minutes;
      final list = byCell.putIfAbsent((w, t.time.hour), () => []);
      if (!list.any((x) => x.key == i.key)) list.add(i);
      t = stop;
    }
  }
  return LoadMatrix(cells: cells, days: perDay, weeks: math.max(1, (days / 7).ceil()), itemsByCell: byCell);
}

/// Heat level of a load ratio: 0 (none), 1–4 by quarters of capacity, 5 = over capacity.
int loadLevel(double load) {
  if (load <= 0) return 0;
  if (load <= 0.25) return 1;
  if (load <= 0.5) return 2;
  if (load <= 0.75) return 3;
  if (load <= 1.0) return 4;
  return 5;
}
