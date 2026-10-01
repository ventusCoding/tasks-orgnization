import 'dart:math' as math;

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Weekday × hour occupancy (T3.3.23 heat tint, T3.6.16 load heatmap) — pure aggregation of planned
// or tracked minutes per (ISO weekday, hour of day) cell over a range of days.

/// What a cell measures.
enum OccupancyMetric { planned, tracked }

/// Minutes per (weekday 1–7, hour 0–23) cell, with the items behind each cell.
@immutable
class OccupancyGrid {
  const OccupancyGrid._(this._minutes, this._items, this.weeks);

  /// Aggregates [items] over the [days] days from [start]; timed items only (all-day items don't
  /// occupy hours). [metric] tracked uses the tracked seconds (capped by the item's span).
  factory OccupancyGrid.build(
    Iterable<PlannerItem> items, {
    required LocalDate start,
    required int days,
    OccupancyMetric metric = OccupancyMetric.planned,
  }) {
    final minutes = List<double>.filled(7 * 24, 0);
    final keys = List<List<PlannerItem>>.generate(7 * 24, (_) => []);
    final from = start.atStartOfDay;
    final to = start.plusDays(days).atStartOfDay;
    for (final item in items) {
      if (item.allDay || item.isBacklog || item.durationMinutes <= 0) continue;
      if (item.status == OccurrenceStatus.cancelled) continue;
      final span = item.durationMinutes;
      final weight = switch (metric) {
        OccupancyMetric.planned => 1.0,
        OccupancyMetric.tracked => span == 0 ? 0.0 : math.min(1, (item.trackedSeconds ?? 0) / 60 / span),
      };
      if (weight == 0) continue;
      var cursor = LocalDateTime.max(item.startLocal, from);
      final end = LocalDateTime.min(item.endLocal, to);
      while (cursor.isBefore(end)) {
        final hourEnd = cursor.date.atTime(LocalTime(cursor.hour, 0)).plusMinutes(60);
        final pieceEnd = LocalDateTime.min(hourEnd, end);
        final cell = (cursor.date.weekday.iso - 1) * 24 + cursor.hour;
        minutes[cell] += cursor.minutesUntil(pieceEnd) * weight;
        final bucket = keys[cell];
        if (bucket.isEmpty || !identical(bucket.last, item)) bucket.add(item);
        cursor = pieceEnd;
      }
    }
    return OccupancyGrid._(minutes, keys, math.max(1, (days / 7).ceil()));
  }

  final List<double> _minutes;
  final List<List<PlannerItem>> _items;

  /// Number of weeks aggregated (averages divide by it).
  final int weeks;

  static int _cell(int weekdayIso, int hour) => (weekdayIso - 1) * 24 + hour;

  /// Total minutes of the cell.
  double minutes(int weekdayIso, int hour) => _minutes[_cell(weekdayIso, hour)];

  /// Average minutes per week of the cell (0–60 for non-overlapping plans).
  double averageMinutes(int weekdayIso, int hour) => minutes(weekdayIso, hour) / weeks;

  /// Items behind the cell (each once, in aggregation order).
  List<PlannerItem> itemsAt(int weekdayIso, int hour) => List.unmodifiable(_items[_cell(weekdayIso, hour)]);

  /// Load of the cell against an hour of capacity per week: 0 = free, 1 = fully booked, > 1 overbooked.
  double load(int weekdayIso, int hour) => averageMinutes(weekdayIso, hour) / 60;

  /// Highest cell load (for relative color scales).
  double get maxLoad {
    var m = 0.0;
    for (var i = 0; i < _minutes.length; i++) {
      m = math.max(m, _minutes[i] / weeks / 60);
    }
    return m;
  }

  /// Total minutes of a weekday.
  double dayMinutes(int weekdayIso) {
    var sum = 0.0;
    for (var h = 0; h < 24; h++) {
      sum += minutes(weekdayIso, h);
    }
    return sum;
  }
}

/// Heat bin 0–4 of a load (0 = empty, 4 = at or above capacity) for color scales.
int heatBin(double load) {
  if (load <= 0) return 0;
  if (load < 0.25) return 1;
  if (load < 0.5) return 2;
  if (load < 1.0) return 3;
  return 4;
}
