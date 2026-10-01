import 'dart:math' as math;

import 'package:everslot/features/planner/presentation/grid/engine/overlap_layout.dart';
import 'package:meta/meta.dart';

// Category swimlanes (T3.6.15): each day column splits into one sub-column per lane (selected
// categories in the user's order, plus "Other" for everything else); overlapping items share their
// lane with the regular overlap layout. Pure.

/// Sub-columns per lane: divisible by every lane cap 1–4, so each item's share stays whole.
const swimlaneUnits = 12;

/// One timed item to place: caller's [index], [start, end) and its category.
@immutable
class SwimlaneInput {
  const SwimlaneInput(this.index, this.start, this.end, this.categoryId);

  final int index;
  final int start;
  final int end;
  final String? categoryId;
}

/// Lane of [categoryId]: its position in [lanes], else the trailing "Other" lane.
int swimlaneOf(String? categoryId, List<String> lanes) {
  final i = categoryId == null ? -1 : lanes.indexOf(categoryId);
  return i < 0 ? lanes.length : i;
}

/// Lays out one day: [lanes].length + 1 lanes of [swimlaneUnits] columns each. Inside a lane the
/// overlap layout runs with [laneCap] (≤ 4); "+N" groups keep their lane's items.
DayLayout layoutSwimlanes(List<SwimlaneInput> items, List<String> lanes, {int laneCap = 2, int minDuration = 1}) {
  if (items.isEmpty) return DayLayout.empty;
  final laneCount = lanes.length + 1;
  final cap = laneCap.clamp(1, 4);
  final byLane = <int, List<LayoutInput>>{};
  for (final i in items) {
    byLane.putIfAbsent(swimlaneOf(i.categoryId, lanes), () => []).add(LayoutInput(i.index, i.start, i.end));
  }
  final tiles = <TileRect>[];
  final overflow = <OverflowGroup>[];
  for (final e in byLane.entries) {
    final layout = layoutDay(e.value, laneCap: cap, minDuration: minDuration);
    for (final t in layout.tiles) {
      final unit = swimlaneUnits ~/ math.max(1, t.columns);
      tiles.add(
        TileRect(
          index: t.index,
          start: t.start,
          end: t.end,
          column: e.key * swimlaneUnits + t.column * unit,
          span: t.span * unit,
          columns: laneCount * swimlaneUnits,
        ),
      );
    }
    overflow.addAll(layout.overflow);
  }
  tiles.sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : a.column.compareTo(b.column));
  return DayLayout(List.unmodifiable(tiles), List.unmodifiable(overflow));
}
