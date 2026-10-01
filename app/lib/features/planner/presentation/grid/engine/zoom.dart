import 'dart:math' as math;

import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';

/// Zoom math (T3.3.21).
abstract final class ZoomMath {
  /// Semantic zoom: the slot preset whose row extent (`slot × ppm`) lies within
  /// [minExtent, maxExtent], walking presets from [slot]. Returns [slot] when already within.
  static int semanticSlot(int slot, double ppm, {double minExtent = 24, double maxExtent = 96}) {
    var s = slot;
    for (var guard = 0; guard < SlotPresets.minutes.length + 1; guard++) {
      final extent = s * ppm;
      if (extent > maxExtent) {
        final finer = SlotPresets.finer(s);
        if (finer == s) return s;
        s = finer;
      } else if (extent < minExtent) {
        final coarser = SlotPresets.coarser(s);
        if (coarser == s || coarser * ppm > maxExtent) return s;
        s = coarser;
      } else {
        return s;
      }
    }
    return s;
  }

  /// New vertical scroll offset keeping the content point under [focalY] (viewport coords) fixed
  /// when px/min changes from [oldPpm] to [newPpm]. [contentYAt] maps (ppm) → content y of the focal
  /// time; simple proportional axes can use [scaleOffset].
  static double keepFocal({required double focalContentY, required double focalViewportY, required double maxOffset}) =>
      (focalContentY - focalViewportY).clamp(0.0, math.max(0, maxOffset));

  /// For a proportional axis with fixed bands of [fixedBefore] px above the focal point.
  static double scaleContentY(double oldContentY, double oldPpm, double newPpm, {double fixedBefore = 0}) =>
      (oldContentY - fixedBefore) / oldPpm * newPpm + fixedBefore;

  /// Horizontal pinch: days visible from a starting count and a horizontal scale factor.
  static int daysForScale(int startDays, double scale, {int maxDays = 7}) {
    if (scale <= 0) return startDays;
    return (startDays / scale).round().clamp(1, maxDays);
  }
}
