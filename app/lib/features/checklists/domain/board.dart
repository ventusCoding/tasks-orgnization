import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:meta/meta.dart';

/// One preview row on a board card.
@immutable
class CardRow {
  const CardRow({required this.id, required this.text, required this.status, required this.depth});

  final String id;
  final String text;
  final ItemStatus status;
  final int depth;

  @override
  bool operator ==(Object other) =>
      other is CardRow && other.id == id && other.text == text && other.status == status && other.depth == depth;

  @override
  int get hashCode => Object.hash(id, text, status, depth);
}

/// Everything a board card needs about its items (T4.1.08), computed in one batch per viewport.
@immutable
class CardSummary {
  const CardSummary({
    this.rollup = Rollup.zero,
    this.rows = const [],
    this.moreCount = 0,
    this.itemCount = 0,
    this.staleCount = 0,
    this.dueCount = 0,
  });

  static const empty = CardSummary();

  final Rollup rollup;
  final List<CardRow> rows;
  final int moreCount;
  final int itemCount;
  final int staleCount;
  final int dueCount;

  /// First [maxRows] rows at depth ≤ [maxDepth] in outline order.
  static CardSummary compute(
    List<ChecklistItem> items, {
    required ChecklistSettings settings,
    required DateTime now,
    int maxRows = 6,
    int maxDepth = 2,
  }) {
    if (items.isEmpty) return empty;
    final tree = ChecklistTree.build(items);
    final rollups = RollupCalculator.compute(tree);
    final visible = [
      for (final id in tree.order)
        if (tree.depthOf(id) <= maxDepth) id,
    ];
    final rows = [
      for (final id in visible.take(maxRows))
        CardRow(id: id, text: tree[id]!.text, status: tree[id]!.status, depth: tree.depthOf(id)),
    ];
    return CardSummary(
      rollup: RollupCalculator.root(tree, rollups),
      rows: rows,
      moreCount: tree.length - rows.length,
      itemCount: tree.length,
      staleCount: tree.items.where((i) => ItemTimeRules.isStale(i, now, settings.staleAfterDays)).length,
      dueCount: tree.items.where((i) => i.dueLocal != null && i.status.isOpen).length,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CardSummary &&
      other.rollup == rollup &&
      _listEq(other.rows, rows) &&
      other.moreCount == moreCount &&
      other.itemCount == itemCount &&
      other.staleCount == staleCount &&
      other.dueCount == dueCount;

  static bool _listEq(List<CardRow> a, List<CardRow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(rollup, Object.hashAll(rows), moreCount, itemCount, staleCount, dueCount);
}

enum BoardLayout { grid, list }

enum BoardSort { manual, recentlyEdited, title }

/// Board view configuration v1 (T4.1.16), persisted as a synced saved view.
@immutable
class BoardConfig {
  const BoardConfig({
    this.layout = BoardLayout.grid,
    this.density = 'comfortable',
    this.showBody = true,
    this.rowsPerCard = 6,
    this.sort = BoardSort.manual,
    this.showSmartChips = true,
    this.extra = const {},
  });

  static const defaults = BoardConfig();

  final BoardLayout layout;
  final String density;
  final bool showBody;
  final int rowsPerCard;
  final BoardSort sort;
  final bool showSmartChips;
  final Map<String, Object?> extra;

  static const _known = {'v', 'layout', 'density', 'showBody', 'rowsPerCard', 'sort', 'showSmartChips'};

  factory BoardConfig.fromJson(Map<String, Object?> j) => BoardConfig(
    layout: j['layout'] == 'list' ? BoardLayout.list : BoardLayout.grid,
    density: j['density'] as String? ?? 'comfortable',
    showBody: j['showBody'] as bool? ?? true,
    rowsPerCard: (j['rowsPerCard'] as num?)?.toInt().clamp(0, 20) ?? 6,
    sort: switch (j['sort']) {
      'recently_edited' => BoardSort.recentlyEdited,
      'title' => BoardSort.title,
      _ => BoardSort.manual,
    },
    showSmartChips: j['showSmartChips'] as bool? ?? true,
    extra: {
      for (final e in j.entries)
        if (!_known.contains(e.key)) e.key: e.value,
    },
  );

  Map<String, Object?> toJson() => {
    ...extra,
    'v': 1,
    'layout': layout.name,
    'density': density,
    'showBody': showBody,
    'rowsPerCard': rowsPerCard,
    'sort': switch (sort) {
      BoardSort.manual => 'manual',
      BoardSort.recentlyEdited => 'recently_edited',
      BoardSort.title => 'title',
    },
    'showSmartChips': showSmartChips,
  };

  BoardConfig copyWith({BoardLayout? layout, bool? showBody, int? rowsPerCard, BoardSort? sort, bool? showSmartChips}) =>
      BoardConfig(
        layout: layout ?? this.layout,
        density: density,
        showBody: showBody ?? this.showBody,
        rowsPerCard: rowsPerCard ?? this.rowsPerCard,
        sort: sort ?? this.sort,
        showSmartChips: showSmartChips ?? this.showSmartChips,
        extra: extra,
      );

  @override
  bool operator ==(Object other) =>
      other is BoardConfig &&
      other.layout == layout &&
      other.density == density &&
      other.showBody == showBody &&
      other.rowsPerCard == rowsPerCard &&
      other.sort == sort &&
      other.showSmartChips == showSmartChips;

  @override
  int get hashCode => Object.hash(layout, density, showBody, rowsPerCard, sort, showSmartChips);
}

/// Smart-view kinds (T4.5.01).
enum SmartKind {
  waiting,
  blocked,
  ongoing,
  followUps;

  static SmartKind? parse(String value) => switch (value) {
    'waiting' => SmartKind.waiting,
    'blocked' => SmartKind.blocked,
    'ongoing' => SmartKind.ongoing,
    'follow_ups' || 'followups' || 'follow-ups' => SmartKind.followUps,
    _ => null,
  };

  String get routeName => this == SmartKind.followUps ? 'follow_ups' : name;

  ItemStatus? get status => switch (this) {
    SmartKind.waiting => ItemStatus.waiting,
    SmartKind.blocked => ItemStatus.blocked,
    SmartKind.ongoing => ItemStatus.ongoing,
    SmartKind.followUps => null,
  };
}

/// An item listed in a cross-list smart view, with its checklist and breadcrumb.
@immutable
class SmartItem {
  const SmartItem({required this.item, required this.checklistTitle, required this.path, this.checklistColor});

  final ChecklistItem item;
  final String checklistTitle;
  final int? checklistColor;

  /// Ancestor texts, root first.
  final List<String> path;

  @override
  bool operator ==(Object other) =>
      other is SmartItem && other.item == item && other.checklistTitle == checklistTitle && _eq(other.path, path);

  static bool _eq(List<String> a, List<String> b) => a.length == b.length && a.indexed.every((e) => b[e.$1] == e.$2);

  @override
  int get hashCode => Object.hash(item, checklistTitle, Object.hashAll(path));
}

/// Counts for the board's smart chips.
@immutable
class SmartCounts {
  const SmartCounts({this.waiting = 0, this.blocked = 0, this.ongoing = 0, this.followUps = 0});

  final int waiting;
  final int blocked;
  final int ongoing;
  final int followUps;

  bool get isEmpty => waiting + blocked + ongoing + followUps == 0;

  int of(SmartKind k) => switch (k) {
    SmartKind.waiting => waiting,
    SmartKind.blocked => blocked,
    SmartKind.ongoing => ongoing,
    SmartKind.followUps => followUps,
  };

  @override
  bool operator ==(Object other) =>
      other is SmartCounts &&
      other.waiting == waiting &&
      other.blocked == blocked &&
      other.ongoing == ongoing &&
      other.followUps == followUps;

  @override
  int get hashCode => Object.hash(waiting, blocked, ongoing, followUps);
}
