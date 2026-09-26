/// The stats isolate entry point (T6.1.13): builds the scope context of a job and computes every
/// requested metric, applying the minimum-data rules (T6.1.14). Pure Dart (no Flutter), so it runs
/// in `Isolate.run` — the job carries only plain records and a zone snapshot.
library;

import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/checklist_catalog.dart';
import 'package:everslot/features/stats/application/catalog/global_catalog.dart';
import 'package:everslot/features/stats/application/catalog/habit_catalog.dart';
import 'package:everslot/features/stats/application/catalog/planner_catalog.dart';
import 'package:everslot/features/stats/application/catalog/quit_catalog.dart';
import 'package:everslot/features/stats/application/metric_registry.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show ZoneResolver;

/// The scope context of [job].
StatsContext contextFor(StatsJob job, ZoneResolver resolver) => switch (job.request.scope) {
  MetricScope.task || MetricScope.series || MetricScope.planner => PlannerContext(job, resolver),
  MetricScope.checklistItem || MetricScope.checklist || MetricScope.checklists => ChecklistContext(job, resolver),
  MetricScope.habit || MetricScope.habits => HabitContext(job, resolver),
  MetricScope.quit => QuitContext(job, resolver),
  MetricScope.global => GlobalContext(job, resolver),
};

/// Computes the metrics of [job]. A metric that throws yields an error result; the others still
/// render (one broken card never breaks a screen).
Map<String, MetricResult> computeStatsJob(StatsJob job, {MetricRegistry? registry}) {
  final reg = registry ?? MetricRegistry.instance;
  final resolver = LocationZoneResolver(job.env.zones, fallbackZone: job.env.zoneId);
  final context = contextFor(job, resolver);
  final results = <String, MetricResult>{};
  for (final id in job.metricIds) {
    final def = reg.byId(id);
    if (def == null) continue;
    try {
      results[id] = applyMinimumData(def, def.compute(context));
    } on Object catch (e) {
      results[id] = metricError(id, e);
    }
  }
  return results;
}

/// Applies the definition's minimum-data rule (T6.1.14) to the headline value.
MetricResult applyMinimumData(MetricDefinition def, MetricResult r) => r.withRule(def.minSample);
