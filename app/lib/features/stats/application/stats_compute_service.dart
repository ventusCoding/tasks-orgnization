/// Batch computation of metrics (T6.1.13): loads the scope's rows once, runs every requested metric
/// in one background isolate and memoizes results by (metric, scope, period, compare mode, filters,
/// data version).
library;

import 'dart:isolate';

import 'package:everslot/features/stats/application/metric_registry.dart';
import 'package:everslot/features/stats/application/stats_cache.dart';
import 'package:everslot/features/stats/application/stats_engine.dart';
import 'package:everslot/features/stats/data/stats_data_source.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

/// Runs a job: in a background isolate (app) or inline (tests).
abstract interface class StatsExecutor {
  Future<Map<String, MetricResult>> run(StatsJob job);
}

/// Computes in `Isolate.run` so the UI thread never blocks (T6.1.13).
final class IsolateStatsExecutor implements StatsExecutor {
  const IsolateStatsExecutor();

  @override
  Future<Map<String, MetricResult>> run(StatsJob job) => Isolate.run(() => computeStatsJob(job));
}

/// Computes on the calling isolate (widget tests, tiny jobs).
final class InlineStatsExecutor implements StatsExecutor {
  const InlineStatsExecutor();

  @override
  Future<Map<String, MetricResult>> run(StatsJob job) async => computeStatsJob(job);
}

/// Results of one batch.
@immutable
final class StatsBatch {
  const StatsBatch(this.request, this.results, {required this.dataVersion, this.fromCache = 0});

  final StatsRequest request;
  final Map<String, MetricResult> results;
  final String dataVersion;

  /// How many results came from the cache.
  final int fromCache;

  MetricResult? operator [](String metricId) => results[metricId];
}

final class StatsComputeService {
  StatsComputeService({
    required this.source,
    required this.executor,
    required this.cache,
    required this.environment,
    MetricRegistry? registry,
  }) : registry = registry ?? MetricRegistry.instance;

  final StatsDataSource source;
  final StatsExecutor executor;
  final StatsResultCache cache;
  final MetricRegistry registry;

  /// Builds the batch environment (clock, zone, preferences, settings) — zones are added here.
  final StatsEnvironment Function() environment;

  /// Metric ids of [request] (all registered metrics of the scope by default).
  List<String> metricIdsOf(StatsRequest request) {
    final ids = request.metricIds;
    if (ids != null) {
      return [
        for (final id in ids)
          if (registry.contains(id)) id,
      ];
    }
    return [for (final d in registry.byScope(request.scope)) d.id];
  }

  Future<StatsBatch> computeBatch(StatsRequest request, {required String dataVersion}) async {
    final ids = metricIdsOf(request);
    final results = <String, MetricResult>{};
    final missing = <String>[];
    for (final id in ids) {
      final hit = cache.get(statsCacheKey(request, id, dataVersion));
      if (hit != null) {
        results[id] = hit;
      } else {
        missing.add(id);
      }
    }
    if (missing.isEmpty) return StatsBatch(request, results, dataVersion: dataVersion, fromCache: results.length);
    final job = await buildJob(request, missing);
    final computed = await executor.run(job);
    for (final e in computed.entries) {
      cache.put(statsCacheKey(request, e.key, dataVersion), e.value);
      results[e.key] = e.value;
    }
    return StatsBatch(request, results, dataVersion: dataVersion, fromCache: ids.length - missing.length);
  }

  /// Loads the rows of [request]'s scope and assembles the isolate job.
  Future<StatsJob> buildJob(StatsRequest request, List<String> metricIds) async {
    final env = environment();
    final scope = request.scope;
    PlannerInput? planner;
    ChecklistInput? checklists;
    HabitInput? habits;
    LocalDate? first;
    final needsPlanner = scope.domains.contains(StatsDomain.planner);
    final needsLists = scope.domains.contains(StatsDomain.checklists);
    final needsHabits = scope.domains.contains(StatsDomain.habits);
    if (needsPlanner) {
      planner = switch (scope) {
        MetricScope.task => await source.loadPlanner(taskId: request.scopeId),
        MetricScope.series => await source.loadPlanner(seriesId: request.scopeId),
        _ => await source.loadPlanner(),
      };
      if (scope == MetricScope.planner || scope == MetricScope.series || scope == MetricScope.global) {
        first = await source.firstPlannerDate(seriesId: scope == MetricScope.series ? request.scopeId : null);
      }
    }
    if (needsLists) {
      checklists = switch (scope) {
        MetricScope.checklist => await source.loadChecklists(checklistId: request.scopeId),
        MetricScope.checklistItem => await source.loadChecklists(itemId: request.scopeId),
        _ => await source.loadChecklists(),
      };
      final f = await source.firstChecklistInstant(
        checklistId: scope == MetricScope.checklist ? request.scopeId : null,
      );
      if (f != null) {
        final d = LocalDate.fromDateTime(f);
        if (first == null || d.isBefore(first)) first = d;
      }
    }
    if (needsHabits) {
      habits = await source.loadHabits(
        habitId: scope == MetricScope.habit || scope == MetricScope.quit ? request.scopeId : null,
        withNotifications: scope == MetricScope.habit,
        // Reminder effectiveness looks back at most two years.
        notificationsSince: env.now.subtract(const Duration(days: 731)),
      );
      final f = await source.firstHabitDate(
        habitId: scope == MetricScope.habit || scope == MetricScope.quit ? request.scopeId : null,
      );
      if (f != null && (first == null || f.isBefore(first))) first = f;
    }
    final zones = <String>{
      env.zoneId,
      for (final t in planner?.tasks ?? const <TaskRecord>[]) ?t.timeZone,
      for (final h in habits?.habits ?? const <HabitRecord>[]) ?h.timeZone,
      for (final i in checklists?.items ?? const <ItemRecord>[]) ?i.timeZone,
    };
    final unavailable = {
      for (final c in planner?.categories ?? const <CategoryInfo>[])
        if (c.unavailable) c.id,
    };
    return StatsJob(
      request: request,
      env: StatsEnvironment(
        now: env.now,
        zoneId: env.zoneId,
        zones: {...env.zones, ...locationsOf(zones)},
        weekStart: env.weekStart,
        dayStartMinutes: env.dayStartMinutes,
        settings: unavailable.isEmpty ? env.settings : env.settings.copyWith(unavailableCategoryIds: unavailable),
        currency: env.currency,
      ),
      metricIds: metricIds,
      planner: planner,
      checklists: checklists,
      habits: habits,
      pendingOutbox: scope == MetricScope.global || scope == MetricScope.habits ? await source.pendingOutbox() : 0,
      firstDataDate: first,
    );
  }

  /// Snapshot of IANA locations (the tz database is initialized in bootstrap / tests).
  static Map<String, tz.Location> locationsOf(Iterable<String> zones) {
    final result = <String, tz.Location>{};
    for (final z in zones) {
      if (z == 'UTC') continue;
      try {
        result[z] = tz.getLocation(z);
      } on Object {
        // Unknown zone: the isolate falls back to the user's zone.
      }
    }
    return result;
  }
}
