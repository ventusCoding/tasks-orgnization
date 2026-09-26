/// Requests, period selections, filters and route scopes of the Insights screens (T6.1.05,
/// T6.1.13, T6.1.17). Pure Dart.
library;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:meta/meta.dart';

/// Scopes reachable through `/insights/:scope/:id` (arch §6.4).
enum InsightsRoute {
  overview('global'),
  planner('planner'),
  series('series'),
  task('task'),
  checklists('checklists'),
  checklist('checklist'),
  item('item'),
  habits('habits'),
  habit('habit'),
  quit('quit'),
  review('review'),
  year('year'),
  feed('feed'),
  goals('goals'),
  records('records'),
  quality('quality'),
  correlations('correlations'),
  glossary('glossary'),
  dashboards('dashboards'),
  dashboard('dashboard'),
  budget('budget'),
  gallery('gallery');

  const InsightsRoute(this.segment);

  /// Path segment (`/insights/<segment>`).
  final String segment;

  /// Parses a route segment (`overview` is an alias of `global`); null when unknown.
  static InsightsRoute? parse(String segment) {
    if (segment == 'overview') return overview;
    return InsightsRoute.values.firstWhereOrNull((r) => r.segment == segment);
  }

  /// The metric scope computed on this route (null for non-metric screens).
  MetricScope? get metricScope => switch (this) {
    overview || review || year || feed || goals || records || quality || correlations || budget =>
      MetricScope.global,
    planner => MetricScope.planner,
    series => MetricScope.series,
    task => MetricScope.task,
    checklists => MetricScope.checklists,
    checklist => MetricScope.checklist,
    item => MetricScope.checklistItem,
    habits => MetricScope.habits,
    habit => MetricScope.habit,
    quit => MetricScope.quit,
    glossary || dashboards || dashboard || gallery => null,
  };
}

/// Period + comparison chosen on a screen.
@immutable
final class PeriodSelection {
  const PeriodSelection(
    this.period, {
    this.compare = true,
    this.mode = CompareMode.toDate,
    this.granularity,
  });

  final StatsPeriod period;

  /// Show Δ vs the previous equivalent period.
  final bool compare;
  final CompareMode mode;

  /// User override of the automatic bucket size.
  final Granularity? granularity;

  PeriodSelection copyWith({
    StatsPeriod? period,
    bool? compare,
    CompareMode? mode,
    Granularity? granularity,
    bool clearGranularity = false,
  }) => PeriodSelection(
    period ?? this.period,
    compare: compare ?? this.compare,
    mode: mode ?? this.mode,
    granularity: clearGranularity ? null : (granularity ?? this.granularity),
  );

  String get key => '${period.key}|$compare|${mode.name}|${granularity?.name ?? 'auto'}';

  @override
  bool operator ==(Object other) => other is PeriodSelection && other.key == key;

  @override
  int get hashCode => key.hashCode;

  /// Serializes to the `stats` settings / local state (`thisWeek`, `rolling:30`, `custom:a..b`).
  static StatsPeriod? parsePeriod(String? key) {
    if (key == null) return null;
    return switch (key) {
      'today' => const StatsPeriod.today(),
      'yesterday' => const StatsPeriod.yesterday(),
      'thisWeek' || 'week' => const StatsPeriod.thisWeek(),
      'lastWeek' => const StatsPeriod.lastWeek(),
      'thisMonth' || 'month' => const StatsPeriod.thisMonth(),
      'lastMonth' => const StatsPeriod.lastMonth(),
      'thisQuarter' || 'quarter' => const StatsPeriod.thisQuarter(),
      'lastQuarter' => const StatsPeriod.lastQuarter(),
      'thisYear' || 'year' => const StatsPeriod.thisYear(),
      'lastYear' => const StatsPeriod.lastYear(),
      'allTime' || 'all' => const StatsPeriod.allTime(),
      _ => _parseComplex(key),
    };
  }

  static StatsPeriod? _parseComplex(String key) {
    if (key.startsWith('rolling:')) {
      final days = int.tryParse(key.substring(8));
      return days == null || days < 1 ? null : StatsPeriod.rolling(days);
    }
    if (key.startsWith('custom:')) {
      final parts = key.substring(7).split('..');
      if (parts.length != 2) return null;
      final from = LocalDate.tryParse(parts[0]);
      final to = LocalDate.tryParse(parts[1]);
      return from == null || to == null ? null : StatsPeriod.custom(from, to);
    }
    return null;
  }
}

/// Filters of the section screens (category, tag, priority, tracking mode — T6.1.16, T6.3.19).
@immutable
final class StatsFilters {
  const StatsFilters({
    this.categoryIds = const {},
    this.tagIds = const {},
    this.priorities = const {},
    this.trackingModes = const {},
  });

  static const none = StatsFilters();

  final Set<String> categoryIds;
  final Set<String> tagIds;
  final Set<int> priorities;
  final Set<String> trackingModes;

  bool get isEmpty =>
      categoryIds.isEmpty && tagIds.isEmpty && priorities.isEmpty && trackingModes.isEmpty;

  int get count =>
      categoryIds.length + tagIds.length + priorities.length + trackingModes.length;

  String get key =>
      '${(categoryIds.toList()..sort()).join(',')}|${(tagIds.toList()..sort()).join(',')}|'
      '${(priorities.toList()..sort()).join(',')}|${(trackingModes.toList()..sort()).join(',')}';

  @override
  bool operator ==(Object other) => other is StatsFilters && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A batch request: one scope/entity, one period, a set of metrics (T6.1.13).
@immutable
final class StatsRequest {
  const StatsRequest(
    this.scope, {
    this.scopeId,
    required this.selection,
    this.filters = StatsFilters.none,
    this.metricIds,
    this.extra,
  });

  final MetricScope scope;
  final String? scopeId;
  final PeriodSelection selection;
  final StatsFilters filters;

  /// Metrics to compute (null = every registered metric of the scope).
  final Set<String>? metricIds;

  /// Scope-specific extra (task scope: occurrence key; review: week start…).
  final String? extra;

  /// Cache key without the data version.
  String get key =>
      '${scope.name}|${scopeId ?? ''}|${selection.key}|${filters.key}|${extra ?? ''}|'
      '${metricIds == null ? '*' : (metricIds!.toList()..sort()).join(',')}';

  @override
  bool operator ==(Object other) => other is StatsRequest && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'StatsRequest($key)';
}
