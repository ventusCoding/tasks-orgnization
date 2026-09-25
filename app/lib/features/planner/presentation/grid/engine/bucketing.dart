import 'dart:math' as math;

import 'package:meta/meta.dart';

/// An item of one day for bucketing: [start, end) in the same unit as the rows.
@immutable
class BucketInput {
  const BucketInput(this.index, this.start, this.end, {this.priority = 0, this.continuesFromPreviousDay = false});

  final int index;
  final int start;
  final int end;
  final int priority;

  /// The item started on an earlier day: its first row here is a continuation.
  final bool continuesFromPreviousDay;
}

/// One chip in a cell: a full chip where the item starts, a continuation marker elsewhere.
@immutable
class BucketEntry {
  const BucketEntry(this.index, {required this.isStart});

  final int index;
  final bool isStart;

  @override
  bool operator ==(Object other) => other is BucketEntry && other.index == index && other.isStart == isStart;

  @override
  int get hashCode => Object.hash(index, isStart);

  @override
  String toString() => isStart ? 'chip#$index' : 'cont#$index';
}

/// Bucketing (T3.3.06): every item is listed in each row it overlaps; its first row gets a full chip,
/// later rows a continuation marker. Chips are ordered by start, then priority (high first).
/// [rows] are sorted, non-overlapping `[start, end)` ranges (empty ranges receive nothing).
List<List<BucketEntry>> bucketDay(List<BucketInput> items, List<(int, int)> rows) {
  final result = [for (var i = 0; i < rows.length; i++) <(BucketInput, bool)>[]];
  if (rows.isEmpty) return const [];
  for (final item in items) {
    final end = math.max(item.end, item.start + 1);
    // First row whose end is after the item start.
    var lo = 0;
    var hi = rows.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (rows[mid].$2 <= item.start) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    var first = true;
    for (var r = lo; r < rows.length; r++) {
      final (rs, re) = rows[r];
      if (rs >= end) break;
      if (re <= rs) continue;
      if (re <= item.start) continue;
      final isStart = first && !item.continuesFromPreviousDay && item.start >= rs;
      result[r].add((item, isStart));
      first = false;
    }
  }
  return [
    for (final cell in result)
      (cell..sort((a, b) {
            final c = a.$1.start.compareTo(b.$1.start);
            if (c != 0) return c;
            final p = b.$1.priority.compareTo(a.$1.priority);
            return p != 0 ? p : a.$1.index.compareTo(b.$1.index);
          }))
          .map((e) => BucketEntry(e.$1.index, isStart: e.$2))
          .toList(growable: false),
  ];
}

/// Row sizing for the table renderer.
@immutable
class RowSizing {
  const RowSizing({required this.heights, required this.visibleChips});

  final List<double> heights;

  /// Chips shown per row before "+N".
  final List<int> visibleChips;
}

/// Fixed rows show as many chips as fit (then "+N"); auto-fit rows grow to the largest chip count of
/// that row across the visible days, capped at [maxChipsPerCell].
RowSizing sizeRows({
  required List<int> maxCountPerRow,
  required bool autoFit,
  required double rowExtent,
  required double chipExtent,
  required int maxChipsPerCell,
  double padding = 4,
}) {
  final heights = <double>[];
  final visible = <int>[];
  final fitFixed = math.max(0, ((rowExtent - padding) / chipExtent).floor());
  for (final count in maxCountPerRow) {
    if (!autoFit) {
      heights.add(rowExtent);
      visible.add(count <= fitFixed ? count : math.max(0, fitFixed - 1));
      continue;
    }
    final shown = math.min(count, maxChipsPerCell);
    final overflow = count > maxChipsPerCell ? 1 : 0;
    heights.add(math.max(rowExtent, (shown + overflow) * chipExtent + padding));
    visible.add(shown);
  }
  return RowSizing(heights: heights, visibleChips: visible);
}

/// Max chip count per row across several days' buckets.
List<int> maxCounts(List<List<List<BucketEntry>>> days, int rowCount) => [
  for (var r = 0; r < rowCount; r++)
    days.fold(0, (m, d) => r < d.length ? math.max(m, d[r].length) : m),
];
