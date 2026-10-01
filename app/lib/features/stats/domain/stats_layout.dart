/// Declarative layout of an Insights scope screen (T6.1.16): a KPI row plus collapsible sections of
/// metric cards (`metricId`, chart variant, span). A new scope screen only declares a layout. Pure Dart.
library;

import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:meta/meta.dart';

/// Card width in the responsive grid (1 column on phones, 2 on tablets).
enum CardSpan { full, half }

/// One card.
@immutable
final class StatsLayoutItem {
  const StatsLayoutItem(this.metricId, {this.span = CardSpan.full, this.variant});

  final String metricId;
  final CardSpan span;

  /// Optional rendering variant (`kpi`, `habitTable`, `yearGrid`…).
  final String? variant;

  Map<String, Object?> toJson() => {'metricId': metricId, 'span': span.name, if (variant != null) 'variant': variant};
}

/// A titled group of cards; [id] doubles as the l10n key suffix (`statsSection<Id>`).
@immutable
final class StatsLayoutSection {
  const StatsLayoutSection(this.id, this.items, {this.collapsedByDefault = false});

  final String id;
  final List<StatsLayoutItem> items;
  final bool collapsedByDefault;
}

/// The layout of one scope.
@immutable
final class StatsLayout {
  const StatsLayout(this.scope, {this.kpis = const [], this.sections = const []});

  final MetricScope scope;

  /// Headline metrics of the scope header (3–5).
  final List<String> kpis;
  final List<StatsLayoutSection> sections;

  /// Every metric the screen needs (one batch).
  Set<String> get metricIds => {
    ...kpis,
    for (final s in sections)
      for (final i in s.items) i.metricId,
  };

  /// Applies user customization (T6.1.22): `order` (metric ids), `hidden` and `pinned` lists. Pinned
  /// cards move to a leading section; hidden cards are dropped; unknown ids are ignored.
  StatsLayout customized({
    List<String> order = const [],
    Set<String> hidden = const {},
    List<String> pinned = const [],
  }) {
    if (order.isEmpty && hidden.isEmpty && pinned.isEmpty) return this;
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    int compare(StatsLayoutItem a, StatsLayoutItem b) =>
        (rank[a.metricId] ?? 1 << 20).compareTo(rank[b.metricId] ?? 1 << 20);
    final pinnedItems = <StatsLayoutItem>[];
    final sections = <StatsLayoutSection>[];
    for (final s in this.sections) {
      final items = <StatsLayoutItem>[];
      for (final i in s.items) {
        if (hidden.contains(i.metricId)) continue;
        if (pinned.contains(i.metricId)) {
          pinnedItems.add(i);
        } else {
          items.add(i);
        }
      }
      if (order.isNotEmpty) items.sort(compare);
      if (items.isNotEmpty) sections.add(StatsLayoutSection(s.id, items, collapsedByDefault: s.collapsedByDefault));
    }
    pinnedItems.sort((a, b) => pinned.indexOf(a.metricId).compareTo(pinned.indexOf(b.metricId)));
    return StatsLayout(
      scope,
      kpis: [
        for (final k in kpis)
          if (!hidden.contains(k)) k,
      ],
      sections: [if (pinnedItems.isNotEmpty) StatsLayoutSection('pinned', pinnedItems), ...sections],
    );
  }
}
