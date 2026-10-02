/// Custom Insights dashboards (T6.7.16, GL-16): user-composed card layouts stored in the synced
/// `dashboards` table (`layout = [{metricId, scopeType, scopeId, period, chartVariant, span}]`).
library;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:meta/meta.dart';

/// One card of a dashboard.
@immutable
final class DashboardCard {
  const DashboardCard({
    required this.metricId,
    required this.scope,
    this.scopeId,
    this.period = 'thisWeek',
    this.chartVariant,
    this.span = 1,
  });

  /// Parses a layout entry (null when it is not usable).
  static DashboardCard? fromJson(Object? json) {
    if (json is! Map) return null;
    final metricId = json['metricId'];
    final scope = MetricScope.values.firstWhereOrNull((s) => s.name == json['scopeType']);
    if (metricId is! String || scope == null) return null;
    final span = json['span'];
    return DashboardCard(
      metricId: metricId,
      scope: scope,
      scopeId: json['scopeId'] as String?,
      period: json['period'] is String ? json['period']! as String : 'thisWeek',
      chartVariant: json['chartVariant'] as String?,
      span: span is num && span.toInt() >= 2 ? 2 : 1,
    );
  }

  final String metricId;
  final MetricScope scope;
  final String? scopeId;

  /// Period key of the card (`thisWeek`, `rolling:30`…).
  final String period;
  final String? chartVariant;

  /// 1 = half width, 2 = full width.
  final int span;

  Map<String, Object?> toJson() => {
    'metricId': metricId,
    'scopeType': scope.name,
    'scopeId': scopeId,
    'period': period,
    'chartVariant': chartVariant,
    'span': span,
  };

  DashboardCard copyWith({String? period, int? span}) => DashboardCard(
    metricId: metricId,
    scope: scope,
    scopeId: scopeId,
    period: period ?? this.period,
    chartVariant: chartVariant,
    span: span ?? this.span,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardCard &&
      other.metricId == metricId &&
      other.scope == scope &&
      other.scopeId == scopeId &&
      other.period == period &&
      other.chartVariant == chartVariant &&
      other.span == span;

  @override
  int get hashCode => Object.hash(metricId, scope, scopeId, period, chartVariant, span);
}

/// A dashboard: name, order and cards.
@immutable
final class Dashboard {
  const Dashboard({required this.id, required this.name, required this.sortKey, this.cards = const []});

  /// Parses the `layout` column (a JSON list; unknown entries are dropped).
  static List<DashboardCard> cardsOf(Object? layout) => [
    if (layout is List)
      for (final e in layout) ?DashboardCard.fromJson(e),
  ];

  final String id;
  final String name;
  final String sortKey;
  final List<DashboardCard> cards;

  Dashboard copyWith({String? name, List<DashboardCard>? cards}) =>
      Dashboard(id: id, name: name ?? this.name, sortKey: sortKey, cards: cards ?? this.cards);

  @override
  bool operator ==(Object other) =>
      other is Dashboard &&
      other.id == id &&
      other.name == name &&
      other.sortKey == sortKey &&
      const ListEquality<DashboardCard>().equals(other.cards, cards);

  @override
  int get hashCode => Object.hash(id, name, sortKey, Object.hashAll(cards));
}
