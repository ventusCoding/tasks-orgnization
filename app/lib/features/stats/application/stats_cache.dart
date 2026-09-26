/// LRU cache of metric results (T6.1.13), keyed by
/// `(metricId, scopeId, periodKey, compareMode, filters, extra, dataVersion)`.
library;

import 'dart:collection';

import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';

/// Cache key of one metric result.
String statsCacheKey(StatsRequest request, String metricId, String dataVersion) =>
    '$metricId|${request.scope.name}|${request.scopeId ?? ''}|${request.selection.key}|'
    '${request.filters.key}|${request.extra ?? ''}|$dataVersion';

final class StatsResultCache {
  StatsResultCache({this.capacity = 200});

  final int capacity;
  final LinkedHashMap<String, MetricResult> _entries = LinkedHashMap();
  int hits = 0;
  int misses = 0;

  int get length => _entries.length;

  MetricResult? get(String key) {
    final v = _entries.remove(key);
    if (v == null) {
      misses++;
      return null;
    }
    hits++;
    _entries[key] = v;
    return v;
  }

  void put(String key, MetricResult value) {
    _entries
      ..remove(key)
      ..[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}
