/// The metric registry (T6.1.06): every metric declared once, looked up by id or scope.
library;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/application/catalog/checklist_catalog.dart';
import 'package:everslot/features/stats/application/catalog/checklist_insights_catalog.dart';
import 'package:everslot/features/stats/application/catalog/global_catalog.dart';
import 'package:everslot/features/stats/application/catalog/habit_catalog.dart';
import 'package:everslot/features/stats/application/catalog/planner_catalog.dart';
import 'package:everslot/features/stats/application/catalog/planner_insights_catalog.dart';
import 'package:everslot/features/stats/application/catalog/quit_catalog.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';

/// Thrown when two definitions share an id (fails at startup in debug).
final class DuplicateMetricException implements Exception {
  const DuplicateMetricException(this.ids);

  final List<String> ids;

  @override
  String toString() => 'DuplicateMetricException(${ids.join(', ')})';
}

final class MetricRegistry {
  MetricRegistry(List<MetricDefinition> definitions)
    : all = List.unmodifiable(definitions),
      _byId = {for (final d in definitions) d.id: d},
      _byScope = groupBy(definitions, (d) => d.scope) {
    if (_byId.length != all.length) {
      final seen = <String>{};
      throw DuplicateMetricException([
        for (final d in all)
          if (!seen.add(d.id)) d.id,
      ]);
    }
  }

  /// The app registry: every section catalog ([6.3]–[6.7]).
  static final MetricRegistry instance = MetricRegistry([
    ...plannerMetrics,
    ...plannerInsightMetrics,
    ...checklistMetrics,
    ...checklistInsightMetrics,
    ...habitMetrics,
    ...quitMetrics,
    ...globalMetrics,
  ]);

  final List<MetricDefinition> all;
  final Map<String, MetricDefinition> _byId;
  final Map<MetricScope, List<MetricDefinition>> _byScope;

  MetricDefinition? byId(String id) => _byId[id];

  List<MetricDefinition> byScope(MetricScope scope) => _byScope[scope] ?? const [];

  bool contains(String id) => _byId.containsKey(id);

  /// Validates the registry (duplicate ids already throw in the constructor). Called by a debug
  /// startup task so a bad catalog fails fast.
  static void validate() => instance.all.length;
}
