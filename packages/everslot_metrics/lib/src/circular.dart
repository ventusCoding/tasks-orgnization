/// Circular statistics for clock times (T6.1.18).
///
/// - θ = 2π·minuteOfDay/1440, minutes counted from the configured day start;
/// - circular mean = atan2(Σ sin θ, Σ cos θ);
/// - resultant length R̄ = √((Σcos)² + (Σsin)²)/n;
/// - circular SD = √(−2 ln R̄), converted back to minutes with ×1440/2π;
/// - drift = circular mean of signed differences (actual − planned), wrapped to (−720, 720].
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/stat.dart';
import 'package:meta/meta.dart';

const int _minutesPerDay = 1440;

/// Below this resultant length times are reported as "no consistent time".
const double defaultConsistencyThreshold = 0.1;

/// Circular summary of clock times.
@immutable
final class const CircularSummary(
  final int n, {
  required final double meanMinuteOfDay,
  required final double resultantLength,
  required final double? sdMinutes,
  required final bool consistent,
}) {
  /// The mean rounded to a whole minute of the day (0 … 1439).
  int get meanMinuteRounded => meanMinuteOfDay.round() % _minutesPerDay;
}

/// Wraps a minute difference to (−720, 720].
double wrapMinutes(num minutes) {
  var m = minutes.toDouble() % _minutesPerDay;
  if (m > _minutesPerDay / 2) m -= _minutesPerDay;
  if (m <= -_minutesPerDay / 2) m += _minutesPerDay;
  return m;
}

/// Circular mean/SD of clock times given as minutes of the (civil) day. [dayStartMinute] shifts
/// the angle origin (the result is still a civil minute of day). R̄ below [consistencyThreshold]
/// (default 0.1) sets `consistent = false` ("no consistent time"); R̄ = 0 has no defined mean
/// direction, so the mean is reported as the day start.
Stat<CircularSummary> circularTimeSummary(
  Iterable<num> minutesOfDay, {
  int dayStartMinute = 0,
  double consistencyThreshold = defaultConsistencyThreshold,
}) {
  final list = minutesOfDay.toList();
  if (list.isEmpty)
    return const Insufficient<CircularSummary>(1, 0, Reasons.empty);
  var s = 0.0;
  var c = 0.0;
  for (final m in list) {
    final theta = 2 * math.pi * (m - dayStartMinute) / _minutesPerDay;
    s += math.sin(theta);
    c += math.cos(theta);
  }
  final n = list.length;
  var r = math.sqrt(c * c + s * s) / n;
  if (r > 1) r = 1;
  final angle = r < 1e-12 ? 0.0 : math.atan2(s, c);
  var mean = angle * _minutesPerDay / (2 * math.pi) + dayStartMinute;
  mean %= _minutesPerDay;
  // Snap tiny floating residue (e.g. 1439.9999999) back to the day start.
  if ((mean - _minutesPerDay).abs() < 1e-9) mean = 0;
  final double? sd;
  if (r < 1e-12) {
    sd = null;
  } else if (r >= 1 - 1e-15) {
    sd = 0;
  } else {
    sd = math.sqrt(-2 * math.log(r)) * _minutesPerDay / (2 * math.pi);
  }
  return Value<CircularSummary>(
    CircularSummary(
      n,
      meanMinuteOfDay: mean,
      resultantLength: r,
      sdMinutes: sd,
      consistent: r >= consistencyThreshold,
    ),
    sampleSize: n,
  );
}

/// Drift: circular mean of signed differences (actual − planned) in minutes, wrapped to
/// (−720, 720].
Stat<double> circularDrift(Iterable<num> signedDifferenceMinutes) {
  final list = signedDifferenceMinutes.toList();
  if (list.isEmpty) return const Insufficient<double>(1, 0, Reasons.empty);
  var s = 0.0;
  var c = 0.0;
  for (final d in list) {
    final theta = 2 * math.pi * d / _minutesPerDay;
    s += math.sin(theta);
    c += math.cos(theta);
  }
  if (math.sqrt(s * s + c * c) / list.length < 1e-12) {
    return const NotApplicable<double>(Reasons.noVariance);
  }
  final mean = math.atan2(s, c) * _minutesPerDay / (2 * math.pi);
  return Value<double>(wrapMinutes(mean), sampleSize: list.length);
}
