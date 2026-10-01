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
  /// cards move to a leading section; hidden cards are dropped; unknown ids are ignored. Cards the
  /// order does not mention keep their default relative position after the ordered ones (a stable
  /// sort, so a card added by an app update lands at the end of its section).
  StatsLayout customized({
    List<String> order = const [],
    Set<String> hidden = const {},
    List<String> pinned = const [],
  }) {
    if (order.isEmpty && hidden.isEmpty && pinned.isEmpty) return this;
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
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
      if (order.isNotEmpty) items.setAll(0, _stableByRank(items, rank));
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

  /// The layout with [prefs] applied.
  StatsLayout withPrefs(LayoutPrefs prefs) =>
      customized(order: prefs.order, hidden: prefs.hidden, pinned: prefs.pinned);
}

/// [items] sorted by their rank in the user's order; unranked ones follow in their given order.
List<StatsLayoutItem> _stableByRank(List<StatsLayoutItem> items, Map<String, int> rank) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final byRank = (rank[a.$2.metricId] ?? 1 << 20).compareTo(rank[b.$2.metricId] ?? 1 << 20);
    return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// One scope's card customization as stored in `user_settings.stats.layouts[<scope>]` (T6.1.22):
/// `{order: [metricId…], hidden: [metricId…], pinned: [metricId…]}`. Unknown ids are kept (a later app
/// version may know them) but never rendered.
@immutable
final class LayoutPrefs {
  const LayoutPrefs({this.order = const [], this.hidden = const {}, this.pinned = const []});

  /// Parses a stored map (malformed entries are ignored).
  factory LayoutPrefs.fromJson(Map<String, Object?>? json) {
    if (json == null) return none;
    List<String> strings(Object? v) => [
      if (v is List)
        for (final e in v)
          if (e is String) e,
    ];
    return LayoutPrefs(
      order: strings(json['order']),
      hidden: strings(json['hidden']).toSet(),
      pinned: strings(json['pinned']),
    );
  }

  static const none = LayoutPrefs();

  /// Metric ids in the user's order (section by section; ids in several sections keep one rank).
  final List<String> order;
  final Set<String> hidden;

  /// Pinned metric ids in their pinned order (shown first).
  final List<String> pinned;

  /// Nothing customized: the default layout applies and the stored entry is removed.
  bool get isDefault => order.isEmpty && hidden.isEmpty && pinned.isEmpty;

  Map<String, Object?> toJson() => {
    'order': order,
    'hidden': [...hidden]..sort(),
    'pinned': pinned,
  };

  bool isHidden(String id) => hidden.contains(id);

  bool isPinned(String id) => pinned.contains(id);

  LayoutPrefs toggleHidden(String id) => LayoutPrefs(
    order: order,
    hidden: hidden.contains(id) ? ({...hidden}..remove(id)) : {...hidden, id},
    pinned: pinned,
  );

  /// Pinning appends to the pinned list; unpinning returns the card to its section.
  LayoutPrefs togglePinned(String id) => LayoutPrefs(
    order: order,
    hidden: hidden,
    pinned: pinned.contains(id) ? ([...pinned]..remove(id)) : [...pinned, id],
  );

  /// Moves a pinned card within the pinned group.
  LayoutPrefs movePinned(int from, int to) {
    final list = [...pinned];
    if (from < 0 || from >= list.length) return this;
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length), item);
    return LayoutPrefs(order: order, hidden: hidden, pinned: list);
  }

  /// Moves an unpinned card of [section] from [from] to [to] (indexes among the section's unpinned
  /// cards) and rewrites the complete `order` of [base], so later edits and unpinning keep positions.
  LayoutPrefs moveInSection(StatsLayout base, String section, int from, int to) {
    final ranked = _rankedOrder(base);
    final slots = ranked[section];
    if (slots == null) return this;
    final unpinned = [
      for (final id in slots)
        if (!pinned.contains(id)) id,
    ];
    if (from < 0 || from >= unpinned.length) return this;
    final moved = unpinned.removeAt(from);
    unpinned.insert(to.clamp(0, unpinned.length), moved);
    // Put the reordered unpinned ids back into the slots unpinned cards occupied.
    var next = 0;
    ranked[section] = [for (final id in slots) pinned.contains(id) ? id : unpinned[next++]];
    return LayoutPrefs(order: [for (final ids in ranked.values) ...ids], hidden: hidden, pinned: pinned);
  }

  /// The section → metric ids (current order) of [base], with the stored order applied.
  Map<String, List<String>> _rankedOrder(StatsLayout base) {
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    return {
      for (final s in base.sections) s.id: [for (final item in _stableByRank(s.items, rank)) item.metricId],
    };
  }

  /// The metric ids of [section] in the order they display (pinned ones excluded).
  List<String> visibleOrder(StatsLayout base, String section) {
    final ids = _rankedOrder(base)[section] ?? const [];
    return [
      for (final id in ids)
        if (!pinned.contains(id)) id,
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is LayoutPrefs &&
      _listEq(other.order, order) &&
      _listEq(other.pinned, pinned) &&
      other.hidden.length == hidden.length &&
      other.hidden.containsAll(hidden);

  @override
  int get hashCode => Object.hash(Object.hashAll(order), Object.hashAll(pinned), Object.hashAllUnordered(hidden));

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
