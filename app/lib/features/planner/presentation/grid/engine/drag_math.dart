import 'dart:math' as math;

import 'package:everslot/features/planner/presentation/grid/engine/snapping.dart';
import 'package:meta/meta.dart';

/// A snapped range in wall-clock minutes relative to the start of a reference day (may be negative
/// or exceed 1440 when it crosses midnight).
@immutable
class DragRange {
  const DragRange(this.start, this.end, {this.kind = SnapKind.grid});

  final int start;
  final int end;

  /// How the moving edge was snapped (drives haptics: one click per new snapped value).
  final SnapKind kind;

  int get duration => end - start;

  @override
  bool operator ==(Object other) => other is DragRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DragRange($start–$end)';
}

/// Pure geometry of the create / move / resize gestures (T3.3.15–T3.3.17).
abstract final class DragMath {
  /// Smallest range length: the snap step (1 min in free mode).
  static int minLength(SnapEngine snap) => snap.free ? 1 : snap.snapMinutes.clamp(1, 60);

  /// Create: [anchor] is the snapped slot start under the long-press. Dragging down extends the end
  /// to the snapped finger; dragging up moves the start. Never shorter than one snap step.
  static DragRange create(int anchor, double fingerMinute, SnapEngine snap) {
    final step = minLength(snap);
    final r = snap.snap(fingerMinute);
    if (r.minute > anchor) return DragRange(anchor, math.max(r.minute, anchor + step), kind: r.kind);
    if (r.minute < anchor) return DragRange(r.minute, anchor + step, kind: r.kind);
    return DragRange(anchor, anchor + step, kind: r.kind);
  }

  /// Move: the item keeps its [duration]; the start follows the finger minus [grabOffset] (minutes
  /// between the item start and the press point). Magnetic targets attract the start first, then
  /// the end.
  static DragRange move(double fingerMinute, int grabOffset, int duration, SnapEngine snap) {
    final rawStart = fingerMinute - grabOffset;
    final s = snap.snap(rawStart);
    if (s.kind != SnapKind.magnet && snap.magnetTargets.isNotEmpty && snap.pxPerMinute > 0 && !snap.free) {
      final radius = snap.magnetPx / snap.pxPerMinute;
      final rawEnd = rawStart + duration;
      int? best;
      var bestDist = double.infinity;
      for (final t in snap.magnetTargets) {
        final d = (t - rawEnd).abs();
        if (d <= radius && d < bestDist) {
          best = t;
          bestDist = d;
        }
      }
      if (best != null) return DragRange(best - duration, best, kind: SnapKind.magnet);
    }
    return DragRange(s.minute, s.minute + duration, kind: s.kind);
  }

  /// Resize one edge; the other edge stays fixed and the length never drops below one snap step.
  static DragRange resize({required bool endEdge, required double fingerMinute, required int start, required int end, required SnapEngine snap}) {
    final step = minLength(snap);
    final r = snap.snap(fingerMinute);
    if (endEdge) return DragRange(start, math.max(r.minute, start + step), kind: r.kind);
    return DragRange(math.min(r.minute, end - step), end, kind: r.kind);
  }

  /// Auto-scroll speed (px/s, signed) when the finger is within [edge] px of the top/bottom of a
  /// viewport spanning [top, bottom) — proportional to the depth into the edge zone (T3.3.20).
  static double autoScrollSpeed(double y, double top, double bottom, {double edge = 48, double maxSpeed = 1200}) {
    if (bottom - top <= edge * 2) return 0;
    if (y < top + edge) {
      final depth = ((top + edge) - y).clamp(0.0, edge) / edge;
      return -maxSpeed * depth;
    }
    if (y > bottom - edge) {
      final depth = (y - (bottom - edge)).clamp(0.0, edge) / edge;
      return maxSpeed * depth;
    }
    return 0;
  }

  /// Horizontal edge direction for auto-paging: -1 near the reading-start edge, +1 near the
  /// reading-end edge, 0 elsewhere (mirrored in RTL).
  static int pageEdgeDirection(double x, double width, {required bool rtl, double edge = 24}) {
    if (width <= edge * 2) return 0;
    final nearLeft = x < edge;
    final nearRight = x > width - edge;
    if (!nearLeft && !nearRight) return 0;
    final towardsStart = rtl ? nearRight : nearLeft;
    return towardsStart ? -1 : 1;
  }
}
