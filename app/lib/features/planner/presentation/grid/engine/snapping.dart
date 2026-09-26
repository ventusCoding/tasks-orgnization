import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart' show defaultSnapMinutes;
import 'package:meta/meta.dart';

enum SnapKind { none, grid, magnet }

@immutable
class SnapResult {
  const SnapResult(this.minute, this.kind);

  final int minute;
  final SnapKind kind;

  @override
  bool operator ==(Object other) => other is SnapResult && other.minute == minute && other.kind == kind;

  @override
  int get hashCode => Object.hash(minute, kind);

  @override
  String toString() => 'Snap($minute, $kind)';
}

/// Snap engine (T3.3.17): grid snapping to [snapMinutes] plus magnetic snapping to neighbouring tile
/// edges and *now* within [magnetPx]; [free] disables snapping (1-minute precision).
@immutable
class SnapEngine {
  const SnapEngine({
    required this.snapMinutes,
    required this.pxPerMinute,
    this.magnetTargets = const [],
    this.magnetPx = 8,
    this.free = false,
  });

  /// Default snap = min(slot, 15), clamped to 1–60.
  static int defaultSnapFor(int slotMinutes) => defaultSnapMinutes(slotMinutes);

  final int snapMinutes;
  final double pxPerMinute;
  final List<int> magnetTargets;
  final double magnetPx;
  final bool free;

  SnapResult snap(double rawMinute) {
    if (free) return SnapResult(rawMinute.round(), SnapKind.none);
    if (magnetTargets.isNotEmpty && pxPerMinute > 0) {
      final radius = magnetPx / pxPerMinute;
      int? best;
      var bestDist = double.infinity;
      for (final t in magnetTargets) {
        final d = (t - rawMinute).abs();
        if (d <= radius && d < bestDist) {
          best = t;
          bestDist = d;
        }
      }
      if (best != null) return SnapResult(best, SnapKind.magnet);
    }
    final step = snapMinutes.clamp(1, 60);
    return SnapResult((rawMinute / step).round() * step, SnapKind.grid);
  }

  /// Snaps down (range starts while creating).
  SnapResult snapFloor(double rawMinute) {
    if (free) return SnapResult(rawMinute.floor(), SnapKind.none);
    final step = snapMinutes.clamp(1, 60);
    return SnapResult((rawMinute / step).floor() * step, SnapKind.grid);
  }
}

/// Throttles selection haptics to at most [maxPerSecond] (T3.3.17: ≤ 30/s).
class HapticThrottle {
  HapticThrottle({this.maxPerSecond = 30});

  final int maxPerSecond;
  Duration? _last;

  /// True when a haptic may fire at [elapsed] (monotonic time).
  bool tryFire(Duration elapsed) {
    final minGap = Duration(microseconds: 1000000 ~/ maxPerSecond);
    final last = _last;
    if (last != null && elapsed - last < minGap) return false;
    _last = elapsed;
    return true;
  }

  void reset() => _last = null;
}
