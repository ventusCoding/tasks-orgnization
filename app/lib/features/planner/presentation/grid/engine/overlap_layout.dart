import 'dart:math' as math;

import 'package:meta/meta.dart';

/// An item to lay out in one day column: [start, end) in any monotonic minute unit.
@immutable
class LayoutInput {
  const LayoutInput(this.index, this.start, this.end);

  /// Caller's index (identity).
  final int index;
  final int start;
  final int end;
}

/// A placed tile: horizontal position = [column] / [columns], width = [span] / [columns].
@immutable
class TileRect {
  const TileRect({
    required this.index,
    required this.start,
    required this.end,
    required this.column,
    required this.span,
    required this.columns,
  });

  final int index;
  final int start;

  /// Effective end (≥ start + min duration).
  final int end;
  final int column;
  final int span;
  final int columns;

  double get left => column / columns;
  double get width => span / columns;

  @override
  bool operator ==(Object other) =>
      other is TileRect &&
      other.index == index &&
      other.start == start &&
      other.end == end &&
      other.column == column &&
      other.span == span &&
      other.columns == columns;

  @override
  int get hashCode => Object.hash(index, start, end, column, span, columns);

  @override
  String toString() => 'Tile(#$index $start–$end col $column span $span/$columns)';
}

/// Items that didn't fit under the lane cap, anchored to the time range they cover ("+N").
@immutable
class OverflowGroup {
  const OverflowGroup({required this.start, required this.end, required this.indices});

  final int start;
  final int end;
  final List<int> indices;

  int get count => indices.length;

  @override
  String toString() => 'Overflow($start–$end $indices)';
}

@immutable
class DayLayout {
  const DayLayout(this.tiles, this.overflow);

  static const empty = DayLayout([], []);

  final List<TileRect> tiles;
  final List<OverflowGroup> overflow;
}

/// Overlap layout (T3.3.05, arch §6.9):
/// 1. sort by start asc, longer first on ties;
/// 2. clusters of transitively overlapping items;
/// 3. greedy columns (a column frees up when its item ends) limited to [laneCap];
/// 4. width = 1 / columns of the cluster, expanded right into free adjacent columns;
/// 5. items that need a column beyond [laneCap] collapse into "+N" groups;
/// 6. [minDuration] makes very short items occupy their minimum rendered height.
DayLayout layoutDay(List<LayoutInput> items, {int laneCap = 1 << 20, int minDuration = 1}) {
  if (items.isEmpty) return DayLayout.empty;
  final cap = math.max(1, laneCap);
  final minDur = math.max(1, minDuration);
  final sorted = [for (final i in items) (i.index, i.start, math.max(i.end, i.start + minDur))]
    ..sort((a, b) {
      final c = a.$2.compareTo(b.$2);
      if (c != 0) return c;
      final d = b.$3.compareTo(a.$3);
      return d != 0 ? d : a.$1.compareTo(b.$1);
    });

  final tiles = <TileRect>[];
  final overflow = <OverflowGroup>[];
  var i = 0;
  while (i < sorted.length) {
    // Collect one cluster.
    var clusterEnd = sorted[i].$3;
    var j = i + 1;
    while (j < sorted.length && sorted[j].$2 < clusterEnd) {
      clusterEnd = math.max(clusterEnd, sorted[j].$3);
      j++;
    }
    final cluster = sorted.sublist(i, j);
    final columnEnds = <int>[];
    final placed = <(int, int, int, int)>[]; // index, start, end, column
    final spill = <(int, int, int)>[];
    for (final (index, start, end) in cluster) {
      var col = -1;
      for (var c = 0; c < columnEnds.length; c++) {
        if (columnEnds[c] <= start) {
          col = c;
          break;
        }
      }
      if (col == -1 && columnEnds.length < cap) {
        columnEnds.add(end);
        col = columnEnds.length - 1;
      } else if (col != -1) {
        columnEnds[col] = end;
      }
      if (col == -1) {
        spill.add((index, start, end));
      } else {
        placed.add((index, start, end, col));
      }
    }
    final columns = math.max(1, columnEnds.length);
    for (final (index, start, end, col) in placed) {
      var span = 1;
      for (var c = col + 1; c < columns; c++) {
        final blocked = placed.any((o) => o.$4 == c && o.$2 < end && start < o.$3);
        if (blocked) break;
        span++;
      }
      tiles.add(TileRect(index: index, start: start, end: end, column: col, span: span, columns: columns));
    }
    // Group overflow items by overlapping ranges.
    var k = 0;
    while (k < spill.length) {
      var gEnd = spill[k].$3;
      final gStart = spill[k].$2;
      final indices = [spill[k].$1];
      var m = k + 1;
      while (m < spill.length && spill[m].$2 < gEnd) {
        gEnd = math.max(gEnd, spill[m].$3);
        indices.add(spill[m].$1);
        m++;
      }
      overflow.add(OverflowGroup(start: gStart, end: gEnd, indices: List.unmodifiable(indices)));
      k = m;
    }
    i = j;
  }
  return DayLayout(List.unmodifiable(tiles), List.unmodifiable(overflow));
}
