/// Typed view of the `stats` settings namespace plus the planner/habit values stats read
/// (arch §8.5). Pure Dart; parsed from the JSON maps of `user_settings`.
library;

import 'package:everslot_metrics/everslot_metrics.dart' show LocalTimeWindow, PlannerStatsSettings, SkipPolicy;
import 'package:everslot_recurrence/everslot_recurrence.dart' show Weekday;
import 'package:meta/meta.dart';

/// What the capacity of a day is made of (`stats.capacityBasis`, PL-X-07).
enum CapacityBasis { workHours, dayWindow, custom }

@immutable
final class StatsSettings {
  const StatsSettings({
    this.defaultPeriod = 'thisWeek',
    this.compareWithPrevious = true,
    this.weekStartOverride,
    this.graceMinutes = 5,
    this.missedGraceMinutes = 15,
    this.skipPolicy = SkipPolicy.neutral,
    this.deepWorkMinutes = 60,
    this.slotToleranceMinutes = 30,
    this.staleDays = 14,
    this.workStartMinute = 540,
    this.workEndMinute = 1020,
    this.workDays = const {1, 2, 3, 4, 5},
    this.capacityBasis = CapacityBasis.workHours,
    this.vacationExcusesPlanner = false,
    this.categoryWeights = const {},
    this.dayScoreWeights = const {},
    this.blockerClusters = const {},
    this.announcedRecords = const {},
    this.mutedInsights = const {},
    this.layouts = const {},
    this.unavailableCategoryIds = const {},
  });

  /// Parses the `stats` and `planner` namespaces (unknown keys are ignored).
  factory StatsSettings.fromMaps({
    Map<String, dynamic> stats = const {},
    Map<String, dynamic> planner = const {},
    Set<String> unavailableCategoryIds = const {},
  }) {
    int intOf(Map<String, dynamic> m, String key, int fallback, int min, int max) {
      final v = m[key];
      return v is num ? v.toInt().clamp(min, max) : fallback;
    }

    int? hhmm(Object? v) {
      if (v is! String) return null;
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
      if (m == null) return null;
      return (int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!)).clamp(0, 1440);
    }

    var start = 540;
    var end = 1020;
    final hours = planner['workHours'];
    if (hours is Map) {
      final s = hhmm(hours['start']);
      final e = hhmm(hours['end']);
      if (s != null && e != null && s < e) {
        start = s;
        end = e;
      }
    }
    final daysRaw = planner['workDays'];
    final days = daysRaw is List
        ? {
            for (final d in daysRaw)
              if (d is num && d >= 1 && d <= 7) d.toInt(),
          }
        : <int>{};
    Map<String, double> weights(Object? raw) => raw is Map
        ? {
            for (final e in raw.entries)
              if (e.value is num) '${e.key}': (e.value as num).toDouble(),
          }
        : const {};
    Set<String> strings(Object? raw) => raw is List
        ? {
            for (final v in raw)
              if (v is String) v,
          }
        : const {};
    final layoutsRaw = stats['layouts'];
    final weekStartRaw = stats['weekStartOverride'];
    return StatsSettings(
      defaultPeriod: stats['defaultPeriod'] is String ? stats['defaultPeriod'] as String : 'thisWeek',
      compareWithPrevious: stats['compareWithPrevious'] is bool ? stats['compareWithPrevious'] as bool : true,
      weekStartOverride: weekStartRaw is num && weekStartRaw >= 1 && weekStartRaw <= 7
          ? Weekday.fromIso(weekStartRaw.toInt())
          : null,
      graceMinutes: intOf(stats, 'graceMinutes', 5, 0, 240),
      missedGraceMinutes: intOf(planner, 'missedGraceMinutes', 15, 0, 1440),
      skipPolicy: stats['skipPolicy'] == 'breaks' ? SkipPolicy.breaks : SkipPolicy.neutral,
      deepWorkMinutes: intOf(stats, 'deepWorkMinBlockMinutes', intOf(stats, 'deepWorkMinutes', 60, 5, 480), 5, 480),
      slotToleranceMinutes: intOf(stats, 'slotToleranceMinutes', 30, 1, 240),
      staleDays: intOf(stats, 'staleThresholdDays', intOf(stats, 'staleDays', 14, 1, 365), 1, 365),
      workStartMinute: start,
      workEndMinute: end,
      workDays: days.isEmpty ? const {1, 2, 3, 4, 5} : days,
      capacityBasis: CapacityBasis.values.firstWhere(
        (b) => b.name == stats['capacityBasis'],
        orElse: () => CapacityBasis.workHours,
      ),
      vacationExcusesPlanner: stats['vacationExcusesPlanner'] == true,
      categoryWeights: weights(stats['categoryWeights']),
      dayScoreWeights: weights(stats['dayScoreWeights']),
      blockerClusters: stats['blockerClusters'] is Map
          ? {
              for (final e in (stats['blockerClusters'] as Map).entries)
                if (e.value is String) '${e.key}': e.value as String,
            }
          : const {},
      announcedRecords: strings(stats['announcedRecords']),
      mutedInsights: strings(stats['mutedInsightTypes'] ?? stats['mutedInsights']),
      layouts: layoutsRaw is Map
          ? {
              for (final e in layoutsRaw.entries)
                if (e.value is Map) '${e.key}': Map<String, Object?>.from(e.value as Map),
            }
          : const {},
      unavailableCategoryIds: unavailableCategoryIds,
    );
  }

  /// `stats.defaultPeriod` key (see `PeriodSelection.parsePeriod`).
  final String defaultPeriod;
  final bool compareWithPrevious;
  final Weekday? weekStartOverride;

  /// On-time grace g (`stats.graceMinutes`).
  final int graceMinutes;

  /// `planner.missedGraceMinutes`.
  final int missedGraceMinutes;
  final SkipPolicy skipPolicy;
  final int deepWorkMinutes;
  final int slotToleranceMinutes;

  /// Stale threshold N (`stats.staleThresholdDays`).
  final int staleDays;

  /// Work hours (`planner.workHours`), minutes of the day.
  final int workStartMinute;
  final int workEndMinute;

  /// ISO weekdays with work hours (`planner.workDays`).
  final Set<int> workDays;
  final CapacityBasis capacityBasis;
  final bool vacationExcusesPlanner;

  /// Productivity-score weights 0…4 per category id (PL-X-45).
  final Map<String, double> categoryWeights;

  /// Day-score weights per section (GL-07).
  final Map<String, double> dayScoreWeights;

  /// Normalized blocker reason → cluster name (CL-L-26).
  final Map<String, String> blockerClusters;

  /// Record keys already announced (GL-06).
  final Set<String> announcedRecords;

  /// Muted insight trigger names (T6.7.08).
  final Set<String> mutedInsights;

  /// Per-scope card layouts (T6.1.22): scope → `{order: [...], hidden: [...], pinned: [...]}`.
  final Map<String, Map<String, Object?>> layouts;

  /// Categories marked "unavailable" (capacity).
  final Set<String> unavailableCategoryIds;

  /// Work hours per weekday for the planner calculators.
  Map<Weekday, List<LocalTimeWindow>> get workHours => {
    for (final iso in workDays) Weekday.fromIso(iso): [LocalTimeWindow(workStartMinute, workEndMinute)],
  };

  /// The planner calculators' settings.
  PlannerStatsSettings get planner => PlannerStatsSettings(
    grace: Duration(minutes: graceMinutes),
    missedGrace: Duration(minutes: missedGraceMinutes),
    skipPolicy: skipPolicy,
    deepWorkMinutes: deepWorkMinutes,
    workHours: workHours,
    unavailableCategoryIds: unavailableCategoryIds,
    categoryWeights: {for (final e in categoryWeights.entries) e.key: e.value.round().clamp(0, 4)},
  );

  StatsSettings copyWith({Set<String>? unavailableCategoryIds}) => StatsSettings(
    defaultPeriod: defaultPeriod,
    compareWithPrevious: compareWithPrevious,
    weekStartOverride: weekStartOverride,
    graceMinutes: graceMinutes,
    missedGraceMinutes: missedGraceMinutes,
    skipPolicy: skipPolicy,
    deepWorkMinutes: deepWorkMinutes,
    slotToleranceMinutes: slotToleranceMinutes,
    staleDays: staleDays,
    workStartMinute: workStartMinute,
    workEndMinute: workEndMinute,
    workDays: workDays,
    capacityBasis: capacityBasis,
    vacationExcusesPlanner: vacationExcusesPlanner,
    categoryWeights: categoryWeights,
    dayScoreWeights: dayScoreWeights,
    blockerClusters: blockerClusters,
    announcedRecords: announcedRecords,
    mutedInsights: mutedInsights,
    layouts: layouts,
    unavailableCategoryIds: unavailableCategoryIds ?? this.unavailableCategoryIds,
  );
}
