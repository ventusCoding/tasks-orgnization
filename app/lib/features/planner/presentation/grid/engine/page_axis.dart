import 'dart:math' as math;

import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:meta/meta.dart';

export 'package:everslot/features/planner/domain/view_config/day_window.dart';

enum AxisBandKind {
  /// Proportional rows.
  normal,

  /// Hidden hours collapsed to a thin band (tap to expand).
  hidden,

  /// Wall-clock range missing on every visible day (clocks forward) — a thin marker.
  gap,
}

/// A contiguous wall-clock range on one pass (repeat 0/1).
@immutable
class AxisPiece {
  const AxisPiece(this.wallStart, this.wallEnd, [this.repeat = 0]);

  final int wallStart;
  final int wallEnd;
  final int repeat;

  int get minutes => wallEnd - wallStart;

  @override
  bool operator ==(Object other) =>
      other is AxisPiece && other.wallStart == wallStart && other.wallEnd == wallEnd && other.repeat == repeat;

  @override
  int get hashCode => Object.hash(wallStart, wallEnd, repeat);

  @override
  String toString() => '[$wallStart,$wallEnd)r$repeat';
}

/// One band of the vertical axis. Normal bands are proportional; hidden/gap bands have a fixed extent.
@immutable
class AxisBand {
  const AxisBand({
    required this.pieces,
    required this.kind,
    required this.minuteBefore,
    required this.fixedBefore,
    required this.fixedExtent,
  });

  final List<AxisPiece> pieces;
  final AxisBandKind kind;

  /// Normal (proportional) minutes before this band.
  final int minuteBefore;

  /// Fixed pixels (hidden/gap bands) before this band.
  final double fixedBefore;

  /// Extent of hidden/gap bands (0 for normal).
  final double fixedExtent;

  int get wallStart => pieces.first.wallStart;
  int get wallEnd => pieces.last.wallEnd;
  int get repeat => pieces.first.repeat;
  int get minutes => pieces.fold(0, (a, p) => a + p.minutes);

  double top(double ppm) => minuteBefore * ppm + fixedBefore;
  double extent(double ppm) => kind == AxisBandKind.normal ? minutes * ppm : fixedExtent;
  double bottom(double ppm) => top(ppm) + extent(ppm);

  @override
  String toString() => 'Band($kind $pieces)';
}

/// A row of the table renderer / day list (a slot, or a whole hidden/gap band).
@immutable
class AxisRow {
  const AxisRow(this.wallStart, this.wallEnd, this.repeat, this.kind, this.bandIndex);

  final int wallStart;
  final int wallEnd;
  final int repeat;
  final AxisBandKind kind;
  final int bandIndex;

  int get minutes => wallEnd - wallStart;

  @override
  bool operator ==(Object other) =>
      other is AxisRow &&
      other.wallStart == wallStart &&
      other.wallEnd == wallEnd &&
      other.repeat == repeat &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(wallStart, wallEnd, repeat, kind);

  @override
  String toString() => 'Row($wallStart–$wallEnd r$repeat $kind)';
}

/// Result of [PageAxis.locate].
typedef AxisLocation = ({double wall, int repeat, int bandIndex});

/// The vertical axis shared by the columns of one page (T3.3.04 / T3.4.09 / T3.4.15).
///
/// It is the union of the visible days' wall-clock rows: a repeated DST hour on any day appears
/// once more (after its first pass); a missing hour is removed only when it is missing on every
/// day (otherwise the column paints it as unavailable). Hidden hours collapse to thin bands.
@immutable
class PageAxis {
  const PageAxis._(this.bands);

  factory PageAxis.regular({DayWindow window = DayWindow.full, Set<int> expandedHidden = const {}}) =>
      PageAxis.build(const [], window: window, expandedHidden: expandedHidden);

  factory PageAxis.build(
    List<DayTimeline> days, {
    DayWindow window = DayWindow.full,
    Set<int> expandedHidden = const {},
    double hiddenExtent = 20,
    double gapExtent = 10,
  }) {
    final repeated = _mergeRanges([for (final d in days) ...d.repeatedRanges]);
    var common = days.isEmpty ? const <(int, int)>[] : days.first.gaps;
    for (final d in days.skip(1)) {
      common = _intersect(common, d.gaps);
    }
    final ws = window.startMinute.clamp(0, 1439);
    final we = window.endMinute.clamp(ws + 1, 1440);
    final points = <int>{0, 1440, ws, we};
    for (final (a, b) in [...repeated, ...common]) {
      points
        ..add(a)
        ..add(b);
    }
    final sorted = points.toList()..sort();

    AxisBandKind hiddenOr(int a) {
      if (a < ws) return expandedHidden.contains(0) ? AxisBandKind.normal : AxisBandKind.hidden;
      if (a >= we) return expandedHidden.contains(we) ? AxisBandKind.normal : AxisBandKind.hidden;
      return AxisBandKind.normal;
    }

    final raw = <(AxisPiece, AxisBandKind)>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      if (b <= a) continue;
      final inGap = common.any((g) => a >= g.$1 && b <= g.$2);
      raw.add((AxisPiece(a, b), inGap ? AxisBandKind.gap : hiddenOr(a)));
      for (final (rs, re) in repeated) {
        if (re != b) continue;
        // Second pass of [rs, re), split at the window borders.
        final cuts = <int>{rs, re, if (ws > rs && ws < re) ws, if (we > rs && we < re) we}.toList()..sort();
        for (var j = 0; j < cuts.length - 1; j++) {
          raw.add((AxisPiece(cuts[j], cuts[j + 1], 1), hiddenOr(cuts[j])));
        }
      }
    }

    // Merge neighbours: hidden bands merge whatever their pieces; others when contiguous.
    final merged = <(List<AxisPiece>, AxisBandKind)>[];
    for (final (piece, kind) in raw) {
      if (merged.isNotEmpty && merged.last.$2 == kind) {
        final pieces = merged.last.$1;
        final last = pieces.last;
        final contiguous = last.repeat == piece.repeat && last.wallEnd == piece.wallStart;
        if (contiguous) {
          pieces[pieces.length - 1] = AxisPiece(last.wallStart, piece.wallEnd, last.repeat);
          continue;
        }
        if (kind == AxisBandKind.hidden) {
          pieces.add(piece);
          continue;
        }
      }
      merged.add(([piece], kind));
    }

    final bands = <AxisBand>[];
    var minutes = 0;
    var fixed = 0.0;
    for (final (pieces, kind) in merged) {
      final extent = switch (kind) {
        AxisBandKind.normal => 0.0,
        AxisBandKind.hidden => hiddenExtent,
        AxisBandKind.gap => gapExtent,
      };
      final band = AxisBand(
        pieces: List.unmodifiable(pieces),
        kind: kind,
        minuteBefore: minutes,
        fixedBefore: fixed,
        fixedExtent: extent,
      );
      bands.add(band);
      if (kind == AxisBandKind.normal) {
        minutes += band.minutes;
      } else {
        fixed += extent;
      }
    }
    return PageAxis._(List.unmodifiable(bands));
  }

  final List<AxisBand> bands;

  int get normalMinutes => bands.fold(0, (a, b) => a + (b.kind == AxisBandKind.normal ? b.minutes : 0));
  double get fixedTotal => bands.fold(0, (a, b) => a + b.fixedExtent);

  double height(double ppm) => normalMinutes * ppm + fixedTotal;

  bool get isSimple => bands.length == 1 && bands.first.kind == AxisBandKind.normal;

  /// y of wall-clock minute [wall] on pass [repeat]. With [end], a wall equal to a piece end maps to
  /// that piece's end (end-exclusive ranges).
  double yOf(num wall, {int repeat = 0, required double ppm, bool end = false}) {
    final r = _find(wall, repeat, end) ?? (repeat == 1 ? _find(wall, 0, end) : null);
    if (r == null) return wall <= 0 ? 0 : (wall >= 1440 ? height(ppm) : _nearest(wall, ppm));
    final (band, minutesInto) = r;
    if (band.kind == AxisBandKind.normal) return band.top(ppm) + minutesInto * ppm;
    final total = band.minutes;
    return band.top(ppm) + (total == 0 ? 0 : minutesInto / total * band.fixedExtent);
  }

  (AxisBand, double)? _find(num wall, int repeat, bool end) {
    for (final band in bands) {
      var before = 0;
      for (final p in band.pieces) {
        if (p.repeat == repeat) {
          final inside = end ? (wall > p.wallStart && wall <= p.wallEnd) : (wall >= p.wallStart && wall < p.wallEnd);
          if (inside) return (band, before + (wall - p.wallStart).toDouble());
        }
        before += p.minutes;
      }
    }
    return null;
  }

  double _nearest(num wall, double ppm) {
    for (final band in bands) {
      if (band.wallStart >= wall && band.repeat == 0) return band.top(ppm);
    }
    return height(ppm);
  }

  /// Wall-clock position at [y] (fractional minutes).
  AxisLocation locate(double y, double ppm) {
    if (bands.isEmpty) return (wall: 0, repeat: 0, bandIndex: 0);
    for (var i = 0; i < bands.length; i++) {
      final band = bands[i];
      final top = band.top(ppm);
      final bottom = band.bottom(ppm);
      if (y < bottom || i == bands.length - 1) {
        final into = (y - top).clamp(0.0, bottom - top);
        final minutesInto = band.kind == AxisBandKind.normal
            ? into / ppm
            : (band.fixedExtent == 0 ? 0.0 : into / band.fixedExtent * band.minutes);
        var remaining = minutesInto;
        for (final p in band.pieces) {
          if (remaining < p.minutes || identical(p, band.pieces.last)) {
            return (
              wall: math.min(p.wallStart + remaining, p.wallEnd.toDouble()),
              repeat: p.repeat,
              bandIndex: i,
            );
          }
          remaining -= p.minutes;
        }
      }
    }
    final last = bands.last.pieces.last;
    return (wall: last.wallEnd.toDouble(), repeat: last.repeat, bandIndex: bands.length - 1);
  }

  /// Rows at [slotMinutes] granularity (slots start at midnight, uneven last slot); hidden and gap
  /// bands become a single row each.
  List<AxisRow> slotRows(int slotMinutes) {
    final rows = <AxisRow>[];
    for (var i = 0; i < bands.length; i++) {
      final band = bands[i];
      if (band.kind != AxisBandKind.normal) {
        rows.add(AxisRow(band.wallStart, band.wallEnd, band.repeat, band.kind, i));
        continue;
      }
      for (final p in band.pieces) {
        var start = p.wallStart;
        while (start < p.wallEnd) {
          final next = math.min((start ~/ slotMinutes + 1) * slotMinutes, p.wallEnd);
          rows.add(AxisRow(start, next, p.repeat, AxisBandKind.normal, i));
          start = next;
        }
      }
    }
    return rows;
  }

  /// Scroll offset showing wall minute [minute] at the top of the viewport, or at [anchorFraction]
  /// of a viewport of [viewportExtent] (T3.3.02: the view state stores minutes, not pixels).
  double offsetForMinute(double ppm, double minute, {double viewportExtent = 0, double anchorFraction = 0}) {
    final y = yOf(minute, ppm: ppm) - viewportExtent * anchorFraction;
    final max = height(ppm) - viewportExtent;
    return y.clamp(0.0, max < 0 ? 0.0 : max);
  }

  /// Wall minute at scroll [offset] (+ [viewportExtent] × [anchorFraction]).
  double minuteAtOffset(double ppm, double offset, {double viewportExtent = 0, double anchorFraction = 0}) =>
      locate(offset + viewportExtent * anchorFraction, ppm).wall;

  /// y ranges of normal bands where [day] has no wall-clock time (paint as unavailable).
  List<(double, double)> unavailableRanges(DayTimeline day, double ppm) {
    final result = <(double, double)>[];
    for (final band in bands) {
      if (band.kind != AxisBandKind.normal) continue;
      for (final p in band.pieces) {
        final missing = p.repeat == 0
            ? _intersect([(p.wallStart, p.wallEnd)], day.gaps)
            : _subtract((p.wallStart, p.wallEnd), day.repeatedRanges);
        for (final (a, b) in missing) {
          result.add((yOf(a, repeat: p.repeat, ppm: ppm), yOf(b, repeat: p.repeat, ppm: ppm, end: true)));
        }
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is PageAxis && _listEquals(other.bands.map((b) => '$b').toList(), bands.map((b) => '$b').toList());

  @override
  int get hashCode => Object.hashAll(bands.map((b) => '$b'));

  @override
  String toString() => 'PageAxis($bands)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<(int, int)> _mergeRanges(List<(int, int)> ranges) {
  final sorted = [...ranges]..sort((x, y) => x.$1.compareTo(y.$1));
  final out = <(int, int)>[];
  for (final r in sorted) {
    if (out.isNotEmpty && r.$1 <= out.last.$2) {
      out[out.length - 1] = (out.last.$1, math.max(out.last.$2, r.$2));
    } else {
      out.add(r);
    }
  }
  return out;
}

List<(int, int)> _intersect(List<(int, int)> a, List<(int, int)> b) {
  final out = <(int, int)>[];
  for (final x in a) {
    for (final y in b) {
      final s = math.max(x.$1, y.$1);
      final e = math.min(x.$2, y.$2);
      if (e > s) out.add((s, e));
    }
  }
  return out;
}

List<(int, int)> _subtract((int, int) range, List<(int, int)> cuts) {
  var parts = [range];
  for (final (cs, ce) in cuts) {
    final next = <(int, int)>[];
    for (final (s, e) in parts) {
      if (ce <= s || cs >= e) {
        next.add((s, e));
        continue;
      }
      if (cs > s) next.add((s, cs));
      if (ce < e) next.add((ce, e));
    }
    parts = next;
  }
  return parts;
}
