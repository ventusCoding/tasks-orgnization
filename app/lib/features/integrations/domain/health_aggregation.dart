import 'package:everslot/features/habits/domain/habit_settings.dart' show HealthMetric;
import 'package:meta/meta.dart';

/// One reading from Apple Health / Health Connect (T8.2.14). Interval metrics (workouts, mindful,
/// sleep) use [start]–[end]; quantities (water, steps) use [value].
@immutable
class HealthSample {
  const HealthSample({required this.start, required this.end, this.value = 0, this.id});

  final DateTime start;
  final DateTime end;
  final double value;

  /// Platform id (duplicates of the same sample from several sources share it).
  final String? id;
}

/// Day totals with de-duplication: overlapping sessions from several sources (phone + watch)
/// count once, identical quantity samples count once.
abstract final class HealthAggregation {
  /// Total of [metric] for the day [dayStart]–[dayEnd] (UTC), in the metric's natural unit:
  /// steps, minutes (workout, mindful), hours (sleep — the night ending that day, from 18:00 the
  /// evening before), liters (water; samples in liters).
  static double dayTotal(
    HealthMetric metric,
    List<HealthSample> samples, {
    required DateTime dayStart,
    required DateTime dayEnd,
    double? stepsTotal,
  }) {
    switch (metric) {
      case HealthMetric.steps:
        if (stepsTotal != null) return stepsTotal;
        return _sumUnique(samples, dayStart, dayEnd);
      case HealthMetric.water:
        return _sumUnique(samples, dayStart, dayEnd);
      case HealthMetric.workout || HealthMetric.mindful:
        return _unionMinutes(samples, dayStart, dayEnd).toDouble();
      case HealthMetric.sleep:
        final nightStart = dayStart.subtract(const Duration(hours: 6));
        final nightEnd = dayStart.add(const Duration(hours: 18));
        return _unionMinutes(samples, nightStart, nightEnd) / 60;
    }
  }

  /// [total] in the habit's goal unit (`min`/`h`, `L`/`ml`, steps as is), rounded to 2 decimals.
  static double inUnit(HealthMetric metric, double total, String? unit) {
    final u = (unit ?? '').trim().toLowerCase();
    final v = switch ((metric, u)) {
      (HealthMetric.workout || HealthMetric.mindful, 'h' || 'hr' || 'hours' || 'heures') => total / 60,
      (HealthMetric.sleep, 'min' || 'minutes') => total * 60,
      (HealthMetric.water, 'ml') => total * 1000,
      (HealthMetric.water, 'cl') => total * 100,
      _ => total,
    };
    return (v * 100).round() / 100;
  }

  static double _sumUnique(List<HealthSample> samples, DateTime from, DateTime to) {
    final seen = <String>{};
    var total = 0.0;
    for (final s in samples) {
      if (!s.start.isBefore(to) || s.start.isBefore(from)) continue;
      final key = s.id ?? '${s.start.toIso8601String()}|${s.end.toIso8601String()}|${s.value}';
      if (seen.add(key)) total += s.value;
    }
    return total;
  }

  static int _unionMinutes(List<HealthSample> samples, DateTime from, DateTime to) {
    final clipped = [
      for (final s in samples)
        if (s.end.isAfter(from) && s.start.isBefore(to) && s.end.isAfter(s.start))
          (s.start.isBefore(from) ? from : s.start, s.end.isAfter(to) ? to : s.end),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    var total = Duration.zero;
    DateTime? curStart;
    DateTime? curEnd;
    for (final (s, e) in clipped) {
      if (curEnd == null || s.isAfter(curEnd)) {
        if (curStart != null) total += curEnd!.difference(curStart);
        curStart = s;
        curEnd = e;
      } else if (e.isAfter(curEnd)) {
        curEnd = e;
      }
    }
    if (curStart != null) total += curEnd!.difference(curStart);
    return total.inMinutes;
  }
}
