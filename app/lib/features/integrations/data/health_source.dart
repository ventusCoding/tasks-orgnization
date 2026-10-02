import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart' show HealthMetric;
import 'package:everslot/features/integrations/domain/health_aggregation.dart';
import 'package:health/health.dart';

/// Apple Health / Health Connect, read-only (T8.2.14); faked in tests.
abstract interface class HealthSource {
  Future<bool> isAvailable();
  Future<bool> requestAccess(Set<HealthMetric> metrics);
  Future<double?> stepsTotal(DateTime from, DateTime to);
  Future<List<HealthSample>> samples(HealthMetric metric, DateTime from, DateTime to);
}

class PluginHealthSource implements HealthSource {
  final _health = Health();
  var _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  static List<HealthDataType> typesOf(HealthMetric m) => switch (m) {
    HealthMetric.steps => const [HealthDataType.STEPS],
    HealthMetric.workout => const [HealthDataType.WORKOUT],
    HealthMetric.mindful => const [HealthDataType.MINDFULNESS],
    HealthMetric.sleep =>
      Platform.isAndroid ? const [HealthDataType.SLEEP_SESSION] : const [HealthDataType.SLEEP_ASLEEP],
    HealthMetric.water => const [HealthDataType.WATER],
  };

  @override
  Future<bool> isAvailable() async {
    if (Platform.isIOS) return true;
    if (!Platform.isAndroid) return false;
    // The plugin is linked below its own minSdk (overrideLibrary): Health Connect needs Android 9+.
    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdk < 28) return false;
    await _configure();
    return await _health.getHealthConnectSdkStatus() == HealthConnectSdkStatus.sdkAvailable;
  }

  @override
  Future<bool> requestAccess(Set<HealthMetric> metrics) async {
    await _configure();
    final types = [for (final m in metrics) ...typesOf(m)];
    return _health.requestAuthorization(types, permissions: [for (final _ in types) HealthDataAccess.READ]);
  }

  @override
  Future<double?> stepsTotal(DateTime from, DateTime to) async {
    await _configure();
    return (await _health.getTotalStepsInInterval(from, to))?.toDouble();
  }

  @override
  Future<List<HealthSample>> samples(HealthMetric metric, DateTime from, DateTime to) async {
    await _configure();
    final points = await _health.getHealthDataFromTypes(types: typesOf(metric), startTime: from, endTime: to);
    return [
      for (final p in _health.removeDuplicates(points))
        HealthSample(
          id: p.uuid,
          start: p.dateFrom.toUtc(),
          end: p.dateTo.toUtc(),
          value: switch (p.value) {
            // Water comes in liters; other quantities as reported.
            final NumericHealthValue n => n.numericValue.toDouble(),
            _ => 0,
          },
        ),
    ];
  }
}
