import 'dart:math' as math;

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Timeline / Gantt layout (T3.6.14) — pure: the horizontal scale, rows grouped by task / category /
// priority, bars (x, width, sub-lane) and drag snapping. Positions are wall-clock minutes from the
// range start times the scale's px per minute.

/// Horizontal scale of the timeline (`options.scale`): hours → days → weeks → months.
enum GanttScale {
  hours(pxPerMinute: 1, pageDays: 2, snapMinutes: 15),
  days(pxPerMinute: 96 / 1440, pageDays: 21, snapMinutes: 60),
  weeks(pxPerMinute: 140 / 10080, pageDays: 112, snapMinutes: 1440),
  months(pxPerMinute: 120 / 43200, pageDays: 365, snapMinutes: 1440);

  GanttScale({required this.pxPerMinute, required this.pageDays, required this.snapMinutes});

  final double pxPerMinute;

  /// Days covered by one page of the timeline.
  final int pageDays;

  /// Drag snap (move and resize).
  final int snapMinutes;

  static GanttScale parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => days);

  /// One step finer (+1) or coarser (−1), clamped.
  GanttScale step(int dir) => values[(index - dir).clamp(0, values.length - 1)];

  /// First day of the page containing [anchor]: the day itself (hours), its week (days, weeks) or
  /// its month (months).
  LocalDate pageStart(LocalDate anchor, Weekday weekStart) => switch (this) {
    GanttScale.hours => anchor,
    GanttScale.days || GanttScale.weeks => anchor.startOfWeek(weekStart),
    GanttScale.months => anchor.firstDayOfMonth,
  };
}

/// Row grouping (`options.groupBy`).
enum GanttGroupBy {
  task,
  category,
  priority;

  static GanttGroupBy parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => task);
}

/// One positioned bar.
@immutable
class GanttBar {
  const GanttBar({required this.item, required this.x, required this.width, required this.lane});

  final PlannerItem item;
  final double x;
  final double width;

  /// Sub-lane inside its row (overlapping bars stack).
  final int lane;

  @override
  String toString() => 'GanttBar(${item.title} x=$x w=$width lane=$lane)';
}

/// One row: its group key (series id, category id or priority), bars and number of sub-lanes.
@immutable
class GanttRow {
  const GanttRow({required this.key, required this.bars, required this.lanes, this.title});

  /// Series id (task), category id or '' (no category), or the priority as a string.
  final String key;

  /// Display title for task rows (the first item's title).
  final String? title;
  final List<GanttBar> bars;
  final int lanes;
}

/// Minimum bar width so short items stay tappable.
const double ganttMinBarWidth = 6;

/// Lays out [items] in rows by [groupBy] for a page starting at [start]: bars sorted by start,
/// greedy sub-lanes per row. Rows: task → by first start; category → by category order of
/// [categoryOrder] (unknown last, no category last); priority → urgent first.
List<GanttRow> ganttRows(
  Iterable<PlannerItem> items, {
  required LocalDate start,
  required GanttScale scale,
  required GanttGroupBy groupBy,
  List<String> categoryOrder = const [],
}) {
  final origin = start.atStartOfDay;
  final groups = <String, List<PlannerItem>>{};
  for (final i in items) {
    if (i.isBacklog) continue;
    final key = switch (groupBy) {
      GanttGroupBy.task => i.seriesId,
      GanttGroupBy.category => i.categoryId ?? '',
      GanttGroupBy.priority => '${i.priority}',
    };
    groups.putIfAbsent(key, () => []).add(i);
  }
  final rows = <GanttRow>[];
  for (final e in groups.entries) {
    final sorted = [...e.value]..sort((a, b) => a.startLocal.compareTo(b.startLocal));
    final laneEnds = <double>[];
    final bars = <GanttBar>[];
    for (final i in sorted) {
      final x = origin.minutesUntil(i.startLocal) * scale.pxPerMinute;
      final width = math.max(ganttMinBarWidth, i.durationMinutes * scale.pxPerMinute);
      var lane = laneEnds.indexWhere((end) => end <= x);
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(0);
      }
      laneEnds[lane] = x + width;
      bars.add(GanttBar(item: i, x: x, width: width, lane: lane));
    }
    rows.add(GanttRow(key: e.key, title: sorted.first.title, bars: bars, lanes: math.max(1, laneEnds.length)));
  }
  int categoryRank(String id) {
    if (id.isEmpty) return 1 << 30;
    final i = categoryOrder.indexOf(id);
    return i < 0 ? (1 << 29) : i;
  }

  rows.sort(
    (a, b) => switch (groupBy) {
      GanttGroupBy.task => a.bars.first.item.startLocal.compareTo(b.bars.first.item.startLocal),
      GanttGroupBy.category => categoryRank(a.key).compareTo(categoryRank(b.key)),
      GanttGroupBy.priority => int.parse(b.key).compareTo(int.parse(a.key)),
    },
  );
  return rows;
}

/// Wall-clock start for a bar dragged by [dx] px, snapped to the scale.
LocalDateTime ganttMovedStart(PlannerItem item, double dx, GanttScale scale) {
  final minutes = _snap(dx / scale.pxPerMinute, scale.snapMinutes);
  return item.startLocal.plusMinutes(minutes);
}

/// Duration after dragging the end edge by [dx] px, snapped, at least one snap step.
int ganttResizedDuration(PlannerItem item, double dx, GanttScale scale) {
  final end = item.durationMinutes + dx / scale.pxPerMinute;
  return math.max(scale.snapMinutes, _snap(end, scale.snapMinutes));
}

int _snap(double minutes, int step) => (minutes / step).round() * step;

/// Tick marks of the axis: (offset px, date-time) at each scale unit (hour / day / week / month).
List<(double, LocalDateTime)> ganttTicks(LocalDate start, GanttScale scale, Weekday weekStart) {
  final origin = start.atStartOfDay;
  final end = start.plusDays(scale.pageDays).atStartOfDay;
  final ticks = <(double, LocalDateTime)>[];
  var t = origin;
  while (t.isBefore(end)) {
    ticks.add((origin.minutesUntil(t) * scale.pxPerMinute, t));
    t = switch (scale) {
      GanttScale.hours => t.plusMinutes(60),
      GanttScale.days => t.plusDays(1),
      GanttScale.weeks => t.date.plusDays(7).startOfWeek(weekStart).atStartOfDay,
      GanttScale.months => _nextMonth(t.date).atStartOfDay,
    };
  }
  return ticks;
}

/// Width of a full page at [scale].
double ganttPageWidth(LocalDate start, GanttScale scale) =>
    start.atStartOfDay.minutesUntil(start.plusDays(scale.pageDays).atStartOfDay) * scale.pxPerMinute;

LocalDate _nextMonth(LocalDate d) => d.month == 12 ? LocalDate(d.year + 1, 1, 1) : LocalDate(d.year, d.month + 1, 1);
