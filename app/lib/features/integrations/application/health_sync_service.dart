import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart' show HealthMetric;
import 'package:everslot/features/integrations/data/health_source.dart';
import 'package:everslot/features/integrations/domain/health_aggregation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// Health auto-logging (T8.2.14): for every active habit linked to a metric, writes yesterday's and
/// today's totals as one `auto` progress log per day (idempotent; see
/// `CheckInService.setHealthProgress`). Runs at start, on resume and after linking a habit.
class HealthSyncService {
  HealthSyncService(this._read, this._source);

  final T Function<T>(ProviderListenable<T> provider) _read;
  final HealthSource _source;
  static final _log = AppLog.get('integrations.health');
  Future<int>? _running;

  /// Number of logs written.
  Future<int> sync() => _running ??= _sync().whenComplete(() => _running = null);

  Future<int> _sync() async {
    try {
      final habits = [
        for (final h in await _read(habitsRepositoryProvider).all(includeArchived: false))
          if (h case final BuildHabit b when b.settings.healthMetric != null) b,
      ];
      if (habits.isEmpty || !await _source.isAvailable()) return 0;
      final zones = _read(zoneResolverProvider);
      final zone = _read(deviceZoneProvider);
      final today = zones.toLocal(_read(clockProvider).nowUtc(), zone).date;
      final checkIn = _read(checkInServiceProvider);
      var written = 0;
      for (final day in [today.plusDays(-1), today]) {
        final dayStart = zones.resolve(day.atStartOfDay, zone).utc;
        final dayEnd = zones.resolve(day.plusDays(1).atStartOfDay, zone).utc;
        final cache = <HealthMetric, double>{};
        for (final habit in habits) {
          final metric = habit.settings.healthMetric!;
          if (day.isBefore(habit.startDate)) continue;
          final total = cache[metric] ??= await _total(metric, dayStart, dayEnd);
          final value = HealthAggregation.inUnit(metric, total, habit.goal.unit);
          if (await checkIn.setHealthProgress(habit, day, value)) written++;
        }
      }
      return written;
    } on Object catch (e, st) {
      _log.info('health sync skipped: $e', e, st);
      return 0;
    }
  }

  Future<double> _total(HealthMetric metric, DateTime dayStart, DateTime dayEnd) async {
    if (metric == HealthMetric.steps) {
      return await _source.stepsTotal(dayStart, dayEnd) ?? 0;
    }
    // Sleep: the night ending that day starts the evening before.
    final from = metric == HealthMetric.sleep ? dayStart.subtract(const Duration(hours: 6)) : dayStart;
    final to = metric == HealthMetric.sleep ? dayStart.add(const Duration(hours: 18)) : dayEnd;
    final samples = await _source.samples(metric, from, to);
    return HealthAggregation.dayTotal(metric, samples, dayStart: dayStart, dayEnd: dayEnd);
  }
}

final healthSourceProvider = Provider<HealthSource>((ref) => PluginHealthSource());

final healthSyncServiceProvider = Provider<HealthSyncService>(
  (ref) => HealthSyncService(ref.read, ref.watch(healthSourceProvider)),
);

/// Whether health data can be used on this device.
final healthAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(healthSourceProvider).isAvailable();
  } on Object {
    return false;
  }
});

/// Startup hook: sync now and on every resume.
void startHealthSync(ProviderContainer container) {
  final service = container.read(healthSyncServiceProvider);
  unawaited(service.sync());
  container.read(lifecycleProvider).onResume.listen((_) => unawaited(service.sync()));
}
