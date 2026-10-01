import 'dart:math' as math;

import 'package:meta/meta.dart';

// 24-hour radial clock (T3.7.10) — pure geometry on the day's elapsed-minute axis (a DST day has
// 1 380 or 1 500 minutes, so the dial always spans the real day): the visible window, angles of
// minutes (12 o'clock at the top, clockwise) and arcs of items.

/// The part of the day shown around the dial: [startT, startT + lengthT) in elapsed minutes.
@immutable
class DialWindow {
  const DialWindow(this.startT, this.lengthT);

  final int startT;
  final int lengthT;

  int get endT => startT + lengthT;

  @override
  bool operator ==(Object other) => other is DialWindow && other.startT == startT && other.lengthT == lengthT;

  @override
  int get hashCode => Object.hash(startT, lengthT);

  @override
  String toString() => 'DialWindow($startT +$lengthT)';
}

/// Window of the dial: the whole day ([hours] 24), the half day containing [nowT] ([hours] 12), or
/// [zoomHours] (1–12) centered on now.
DialWindow dialWindow({required int dayLength, required int hours, required int zoomHours, required int nowT}) {
  if (zoomHours > 0) {
    final length = zoomHours.clamp(1, 12) * 60;
    return DialWindow(nowT - length ~/ 2, length);
  }
  if (hours == 12) {
    final half = dayLength ~/ 2;
    return nowT < half ? DialWindow(0, half) : DialWindow(half, dayLength - half);
  }
  return DialWindow(0, dayLength);
}

/// Angle (radians) of elapsed minute [t]: −π/2 (12 o'clock) at the window start, clockwise.
double angleOf(int t, DialWindow w) => -math.pi / 2 + 2 * math.pi * (t - w.startT) / w.lengthT;

/// Arc of [tStart, tEnd) clipped to the window: start angle and sweep, or null when outside.
({double start, double sweep})? arcOf(int tStart, int tEnd, DialWindow w) {
  final a = math.max(tStart, w.startT);
  final b = math.min(tEnd, w.endT);
  if (b <= a) return null;
  return (start: angleOf(a, w), sweep: 2 * math.pi * (b - a) / w.lengthT);
}

/// Elapsed minute at [angle] (radians, same convention as [angleOf]).
int tAtAngle(double angle, DialWindow w) {
  var fraction = (angle + math.pi / 2) / (2 * math.pi);
  fraction -= fraction.floorToDouble();
  return w.startT + (fraction * w.lengthT).floor();
}
