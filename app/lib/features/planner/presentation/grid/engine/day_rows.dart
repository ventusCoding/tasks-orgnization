import 'dart:math' as math;

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:meta/meta.dart';

/// Elapsed-minute ranges of axis [rows] on the day of [timeline] (monotonic; rows that don't exist
/// on that day — a repeated DST pass it doesn't have — are empty so nothing lands in them).
List<(int, int)> rowRangesFor(DayTimeline timeline, List<AxisRow> rows) {
  final result = <(int, int)>[];
  var prev = 0;
  for (final r in rows) {
    final exists = r.repeat == 0 || timeline.hasWall(r.wallStart, repeat: 1);
    if (!exists) {
      result.add((prev, prev));
      continue;
    }
    final a = math.max(prev, timeline.tOfWall(r.wallStart, repeat: r.repeat));
    final b = math.max(a, r.wallEnd >= 1440 ? timeline.lengthMinutes : timeline.tOfWallEnd(r.wallEnd, repeat: r.repeat));
    result.add((a, b));
    prev = b;
  }
  return result;
}

/// An item in the day list: shown once, in the row where it starts (T3.5.02).
@immutable
class DayEntry {
  const DayEntry({required this.item, required this.tStart, required this.tEnd, required this.lane, this.continues = false, this.continuesAfter = false});

  final PlannerItem item;

  /// Elapsed minutes on this day (clipped to the day).
  final int tStart;
  final int tEnd;

  /// Duration-bar lane.
  final int lane;

  /// Started on an earlier day ("continues").
  final bool continues;
  final bool continuesAfter;

  @override
  bool operator ==(Object other) =>
      other is DayEntry && other.item == item && other.tStart == tStart && other.tEnd == tEnd && other.lane == lane;

  @override
  int get hashCode => Object.hash(item, tStart, tEnd, lane);
}

/// A duration bar crossing a row.
@immutable
class RowBar {
  const RowBar({required this.lane, required this.item, required this.starts, required this.ends});

  final int lane;
  final PlannerItem item;
  final bool starts;
  final bool ends;
}

/// One slot of a day (DST aware; the last slot may be shorter).
@immutable
class SlotRow {
  const SlotRow({
    required this.wallStart,
    required this.wallEnd,
    required this.repeat,
    required this.tStart,
    required this.tEnd,
    required this.kind,
    this.entries = const [],
    this.bars = const [],
  });

  final int wallStart;
  final int wallEnd;
  final int repeat;
  final int tStart;
  final int tEnd;
  final AxisBandKind kind;

  /// Items starting here (items that continue from the previous day land in the first row).
  final List<DayEntry> entries;

  /// Duration bars crossing this row.
  final List<RowBar> bars;

  int get minutes => tEnd - tStart;

  /// No item starts here and none covers it.
  bool get isFree => entries.isEmpty && bars.isEmpty && kind == AxisBandKind.normal;

  /// Covered by an item that started in an earlier row.
  bool get isCovered => entries.isEmpty && bars.isNotEmpty;

  bool containsT(int t) => t >= tStart && t < tEnd;

  @override
  String toString() => 'Slot($wallStart–$wallEnd r$repeat, ${entries.length} items, ${bars.length} bars)';
}

/// Rows of [slice]'s day at [slotMinutes] (T3.5.02): slots start at midnight on the DST-aware
/// wall clock (repeated hours twice, missing hours dropped, uneven last slot); hidden hours of
/// [window] are one row each.
List<SlotRow> buildDayRows({required DaySlice slice, required int slotMinutes, DayWindow window = DayWindow.full}) {
  final timeline = slice.timeline;
  final axis = PageAxis.build([timeline], window: window);
  final axisRows = axis.slotRows(slotMinutes.clamp(1, 1440));
  final ranges = rowRangesFor(timeline, axisRows);
  // Lanes for duration bars: greedy by start.
  final laneEnds = <int>[];
  final entries = <DayEntry>[];
  for (final s in slice.timed) {
    var lane = laneEnds.indexWhere((e) => e <= s.tStart);
    final end = math.max(s.tEnd, s.tStart + 1);
    if (lane == -1) {
      laneEnds.add(end);
      lane = laneEnds.length - 1;
    } else {
      laneEnds[lane] = end;
    }
    entries.add(DayEntry(
      item: s.item,
      tStart: s.tStart,
      tEnd: s.tEnd,
      lane: lane,
      continues: s.continuesBefore,
      continuesAfter: s.continuesAfter,
    ));
  }
  final starting = [for (var i = 0; i < axisRows.length; i++) <DayEntry>[]];
  final crossing = [for (var i = 0; i < axisRows.length; i++) <RowBar>[]];
  int rowOf(int t) {
    var lo = 0;
    var hi = ranges.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (ranges[mid].$2 <= t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // Skip empty rows (missing passes) that share the boundary.
    while (lo < ranges.length - 1 && ranges[lo].$1 == ranges[lo].$2) {
      lo++;
    }
    return lo;
  }

  for (final e in entries) {
    if (ranges.isEmpty) break;
    final first = rowOf(e.tStart);
    starting[first].add(e);
    if (e.tEnd <= e.tStart) continue;
    for (var r = first; r < ranges.length && ranges[r].$1 < e.tEnd; r++) {
      if (ranges[r].$2 <= ranges[r].$1) continue;
      final last = r + 1 >= ranges.length || ranges[r + 1].$1 >= e.tEnd;
      crossing[r].add(RowBar(lane: e.lane, item: e.item, starts: r == first && !e.continues, ends: last && !e.continuesAfter));
    }
  }
  return [
    for (var i = 0; i < axisRows.length; i++)
      SlotRow(
        wallStart: axisRows[i].wallStart,
        wallEnd: axisRows[i].wallEnd,
        repeat: axisRows[i].repeat,
        tStart: ranges[i].$1,
        tEnd: ranges[i].$2,
        kind: axisRows[i].kind,
        entries: List.unmodifiable(starting[i]),
        bars: List.unmodifiable(crossing[i]),
      ),
  ];
}

/// A row of the (optionally collapsed) day list.
@immutable
sealed class DayListRow {
  const DayListRow();
}

/// A slot (with its items, or empty in the uncollapsed list).
final class SlotListRow extends DayListRow {
  const SlotListRow(this.row, this.index);

  final SlotRow row;

  /// Index in the uncollapsed rows.
  final int index;
}

/// A run of free slots collapsed into one row ("Free 10:00–11:20 · 1 h 20", T3.5.08).
final class FreeListRow extends DayListRow {
  const FreeListRow({required this.first, required this.last, required this.fromIndex, required this.toIndex});

  final SlotRow first;
  final SlotRow last;
  final int fromIndex;
  final int toIndex;

  int get tStart => first.tStart;
  int get tEnd => last.tEnd;
  int get wallStart => first.wallStart;
  int get wallEnd => last.wallEnd;
  int get minutes => tEnd - tStart;
  int get slots => toIndex - fromIndex + 1;
}

/// Collapses consecutive free slots into one row and drops slots covered by an item shown above
/// (the item row stands for its whole duration). [expanded] keeps runs starting at those row
/// indices expanded (the user tapped *Expand*).
List<DayListRow> collapseRows(List<SlotRow> rows, {Set<int> expanded = const {}}) {
  final result = <DayListRow>[];
  var i = 0;
  while (i < rows.length) {
    final r = rows[i];
    if (!r.isFree) {
      if (!r.isCovered || r.kind != AxisBandKind.normal) result.add(SlotListRow(r, i));
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < rows.length && rows[j + 1].isFree) {
      j++;
    }
    if (expanded.contains(i)) {
      for (var k = i; k <= j; k++) {
        result.add(SlotListRow(rows[k], k));
      }
    } else if (rows[i].tEnd > rows[i].tStart || j > i) {
      result.add(FreeListRow(first: rows[i], last: rows[j], fromIndex: i, toIndex: j));
    }
    i = j + 1;
  }
  return result;
}
