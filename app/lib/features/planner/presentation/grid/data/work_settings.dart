import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Planner work hours / days from settings `planner.workHours` / `planner.workDays` (arch §8.5).
@immutable
class WorkSettings {
  const WorkSettings({this.hours = const DayWindow(540, 1020), this.days = const {1, 2, 3, 4, 5}, this.defaultDuration = 30});

  final DayWindow hours;

  /// ISO weekdays.
  final Set<int> days;
  final int defaultDuration;

  int get minutesPerDay => hours.minutes;

  static int? _hhmm(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
    return m == null ? null : (int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!)).clamp(0, 1440);
  }

  factory WorkSettings.fromSettings(Map<String, dynamic> planner) {
    final hours = planner['workHours'];
    DayWindow window = const DayWindow(540, 1020);
    if (hours is Map) {
      final s = _hhmm(hours['start']);
      final e = _hhmm(hours['end']);
      if (s != null && e != null && s < e) window = DayWindow(s, e);
    }
    final daysRaw = planner['workDays'];
    final days = daysRaw is List ? {for (final d in daysRaw) if (d is num && d >= 1 && d <= 7) d.toInt()} : <int>{};
    final duration = planner['defaultTaskDurationMinutes'];
    return WorkSettings(
      hours: window,
      days: days.isEmpty ? const {1, 2, 3, 4, 5} : days,
      defaultDuration: duration is num ? duration.toInt().clamp(1, 1440) : 30,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkSettings && other.hours == hours && other.days.length == days.length && other.days.containsAll(days) && other.defaultDuration == defaultDuration;

  @override
  int get hashCode => Object.hash(hours, Object.hashAllUnordered(days), defaultDuration);
}

final plannerWorkSettingsProvider = Provider<WorkSettings>((ref) {
  try {
    final map = ref.watch(settingsProvider(SettingsNs.planner)).value;
    return map == null ? const WorkSettings() : WorkSettings.fromSettings(map);
  } on Object {
    return const WorkSettings();
  }
});

/// Quick-create duration rule: the slot when it is a sensible task length, else the default.
int quickCreateDuration(int slotMinutes, WorkSettings work) =>
    slotMinutes >= 5 && slotMinutes <= 240 ? slotMinutes : work.defaultDuration;
