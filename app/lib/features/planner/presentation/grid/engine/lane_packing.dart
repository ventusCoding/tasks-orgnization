import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A bar of the all-day lane spanning columns [startCol, endCol).
@immutable
class LaneInput {
  const LaneInput(this.index, this.startCol, this.endCol, {this.continuesBefore = false, this.continuesAfter = false});

  final int index;
  final int startCol;
  final int endCol;
  final bool continuesBefore;
  final bool continuesAfter;
}

@immutable
class LaneBar {
  const LaneBar({
    required this.index,
    required this.startCol,
    required this.endCol,
    required this.row,
    this.continuesBefore = false,
    this.continuesAfter = false,
  });

  final int index;
  final int startCol;
  final int endCol;
  final int row;
  final bool continuesBefore;
  final bool continuesAfter;

  int get span => endCol - startCol;

  @override
  String toString() => 'Bar(#$index $startCol–$endCol row $row)';
}

@immutable
class LanePacking {
  const LanePacking({required this.bars, required this.rowCount, required this.hiddenPerColumn});

  /// Visible bars (row < maxRows when collapsed).
  final List<LaneBar> bars;

  /// Rows used by visible bars.
  final int rowCount;

  /// Hidden bar count per column ("+N").
  final List<int> hiddenPerColumn;

  bool get hasHidden => hiddenPerColumn.any((c) => c > 0);
}

/// Greedy row packing of all-day / multi-day bars (T3.3.18). With [maxRows], rows beyond it are
/// hidden and counted per column.
LanePacking packLane(List<LaneInput> inputs, int columns, {int? maxRows}) {
  final sorted = [...inputs]..sort((a, b) {
      final c = a.startCol.compareTo(b.startCol);
      if (c != 0) return c;
      final d = (b.endCol - b.startCol).compareTo(a.endCol - a.startCol);
      return d != 0 ? d : a.index.compareTo(b.index);
    });
  final rowEnds = <int>[];
  final all = <LaneBar>[];
  for (final input in sorted) {
    final s = input.startCol.clamp(0, columns);
    final e = math.max(s + 1, input.endCol.clamp(0, columns));
    var row = rowEnds.indexWhere((end) => end <= s);
    if (row == -1) {
      rowEnds.add(e);
      row = rowEnds.length - 1;
    } else {
      rowEnds[row] = e;
    }
    all.add(LaneBar(
      index: input.index,
      startCol: s,
      endCol: e,
      row: row,
      continuesBefore: input.continuesBefore,
      continuesAfter: input.continuesAfter,
    ));
  }
  final limit = maxRows ?? rowEnds.length;
  final hidden = List<int>.filled(columns, 0);
  final visible = <LaneBar>[];
  for (final bar in all) {
    if (bar.row < limit) {
      visible.add(bar);
    } else {
      for (var c = bar.startCol; c < bar.endCol && c < columns; c++) {
        hidden[c]++;
      }
    }
  }
  return LanePacking(bars: visible, rowCount: math.min(limit, rowEnds.length), hiddenPerColumn: hidden);
}
