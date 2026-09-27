import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Checklist views (T4.5.02), remembered per checklist in `ui_checklist_state.view_type`.
enum ChecklistViewType {
  outline,
  kanban,
  gallery,

  /// Live mind map of the same tree (T4.5.14).
  mindMap;

  static ChecklistViewType parse(String? v) => switch (v) {
    'kanban' => ChecklistViewType.kanban,
    'gallery' => ChecklistViewType.gallery,
    'mindMap' => ChecklistViewType.mindMap,
    _ => ChecklistViewType.outline,
  };
}

/// One row the outline actually renders (T4.2.05).
@immutable
class VisibleRow {
  const VisibleRow({
    required this.item,
    required this.depth,
    required this.hasChildren,
    required this.collapsed,
    this.isContext = false,
    this.isOrphan = false,
    this.childCount = 0,
  });

  final ChecklistItem item;

  /// Depth relative to the focus root (its children are depth 0).
  final int depth;
  final bool hasChildren;
  final bool collapsed;

  /// Dimmed ancestor shown only to give context to filtered matches.
  final bool isContext;
  final bool isOrphan;
  final int childCount;

  String get id => item.id;

  @override
  bool operator ==(Object other) =>
      other is VisibleRow &&
      other.item == item &&
      other.depth == depth &&
      other.hasChildren == hasChildren &&
      other.collapsed == collapsed &&
      other.isContext == isContext &&
      other.isOrphan == isOrphan &&
      other.childCount == childCount;

  @override
  int get hashCode => Object.hash(item, depth, hasChildren, collapsed, isContext, isOrphan, childCount);
}

/// View-level filter (T4.2.05 / T4.5.11). Stored order is never touched.
@immutable
class ItemFilter {
  const ItemFilter({
    this.text = '',
    this.statuses = const {},
    this.hideCompleted = false,
    this.hasAttachments = false,
    this.dueSoon = false,
  });

  static const none = ItemFilter();

  final String text;

  /// Empty = every status.
  final Set<ItemStatus> statuses;
  final bool hideCompleted;
  final bool hasAttachments;
  final bool dueSoon;

  /// Filters that show matches with dimmed ancestors (hide-completed alone just prunes).
  bool get isActive => text.trim().isNotEmpty || statuses.isNotEmpty || hasAttachments || dueSoon;

  ItemFilter copyWith({
    String? text,
    Set<ItemStatus>? statuses,
    bool? hideCompleted,
    bool? hasAttachments,
    bool? dueSoon,
  }) => ItemFilter(
    text: text ?? this.text,
    statuses: statuses ?? this.statuses,
    hideCompleted: hideCompleted ?? this.hideCompleted,
    hasAttachments: hasAttachments ?? this.hasAttachments,
    dueSoon: dueSoon ?? this.dueSoon,
  );

  Map<String, Object?> toJson() => {
    'v': 1,
    if (text.isNotEmpty) 'text': text,
    if (statuses.isNotEmpty) 'statuses': [for (final s in statuses) s.name],
    if (hideCompleted) 'hideCompleted': true,
    if (hasAttachments) 'hasAttachments': true,
    if (dueSoon) 'dueSoon': true,
  };

  factory ItemFilter.fromJson(Map<String, Object?> j) => ItemFilter(
    text: j['text'] as String? ?? '',
    statuses: {
      if (j['statuses'] is List)
        for (final s in j['statuses']! as List)
          if (s is String) ItemStatus.parse(s),
    },
    hideCompleted: j['hideCompleted'] == true,
    hasAttachments: j['hasAttachments'] == true,
    dueSoon: j['dueSoon'] == true,
  );

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.text == text &&
      other.statuses.length == statuses.length &&
      other.statuses.containsAll(statuses) &&
      other.hideCompleted == hideCompleted &&
      other.hasAttachments == hasAttachments &&
      other.dueSoon == dueSoon;

  @override
  int get hashCode => Object.hash(text, Object.hashAllUnordered(statuses), hideCompleted, hasAttachments, dueSoon);
}

/// View-level sort (T4.5.11), applied per sibling group.
@immutable
class ItemSort {
  const ItemSort({this.by = ItemSortBy.manual, this.descending = false});

  static const manual = ItemSort();

  final ItemSortBy by;
  final bool descending;

  bool get isManual => by == ItemSortBy.manual;

  Map<String, Object?> toJson() => {'v': 1, 'by': by.name, 'descending': descending};

  factory ItemSort.fromJson(Map<String, Object?> j) => ItemSort(
    by: ItemSortBy.values.firstWhere((b) => b.name == j['by'], orElse: () => ItemSortBy.manual),
    descending: j['descending'] == true,
  );

  @override
  bool operator ==(Object other) => other is ItemSort && other.by == by && other.descending == descending;

  @override
  int get hashCode => Object.hash(by, descending);
}

/// Turns a tree + UI state into rendered rows (T4.2.05) — O(n), no recursion.
abstract final class VisibleListBuilder {
  static List<VisibleRow> build(
    ChecklistTree tree, {
    String? focusRootId,
    Set<String> collapsed = const {},
    ItemFilter filter = ItemFilter.none,
    ItemSort sort = ItemSort.manual,
    bool sortCompletedToBottom = false,
    Set<String> withAttachments = const {},
    LocalDate? today,
    int dueSoonDays = 3,
    int? maxDepth,
  }) {
    final root = focusRootId != null && tree.contains(focusRootId) ? focusRootId : null;

    List<String> kids(String? parent) {
      final ids = tree.childIds(parent);
      if (ids.length < 2 || (sort.isManual && !sortCompletedToBottom)) return ids;
      var items = [for (final id in ids) tree[id]!];
      if (!sort.isManual) items = ItemComparators.sort(items, sort.by, descending: sort.descending);
      if (sortCompletedToBottom) {
        items = [...items.where((i) => !i.status.isTerminal), ...items.where((i) => i.status.isTerminal)];
      }
      return [for (final i in items) i.id];
    }

    bool matches(ChecklistItem i) {
      if (filter.statuses.isNotEmpty && !filter.statuses.contains(i.status)) return false;
      final q = filter.text.trim();
      if (q.isNotEmpty &&
          !Collation.contains(i.text, q) &&
          !Collation.contains(i.note ?? '', q) &&
          !Collation.contains(i.statusNote ?? '', q)) {
        return false;
      }
      if (filter.hasAttachments && !withAttachments.contains(i.id)) return false;
      if (filter.dueSoon) {
        final due = i.dueLocal;
        if (due == null || today == null || due.date.isAfter(today.plusDays(dueSoonDays))) return false;
      }
      if (filter.hideCompleted && i.status == ItemStatus.completed) return false;
      return true;
    }

    // Subtree scope of the focus root.
    final scope = root == null ? tree.order : tree.descendants(root);

    // Hide-completed pruning: a completed node stays (as context) only if something open is below.
    Set<String>? keep;
    if (filter.hideCompleted && !filter.isActive) {
      keep = <String>{};
      for (var i = scope.length - 1; i >= 0; i--) {
        final id = scope[i];
        final item = tree[id]!;
        if (item.status != ItemStatus.completed || tree.childIds(id).any(keep.contains)) keep.add(id);
      }
    }

    // Active filters: matches + their ancestors (expanded, dimmed).
    Set<String>? include;
    Set<String>? matched;
    if (filter.isActive) {
      matched = {
        for (final id in scope)
          if (matches(tree[id]!)) id,
      };
      include = {...matched};
      for (final id in matched) {
        for (final a in tree.ancestors(id)) {
          if (a == root) continue;
          if (root != null && !tree.isDescendant(a, root)) continue;
          include.add(a);
        }
      }
    }

    final rows = <VisibleRow>[];
    final stack = <(String, int)>[];
    void pushChildren(String? parent, int depth) {
      final list = kids(parent);
      for (var i = list.length - 1; i >= 0; i--) {
        final id = list[i];
        if (include != null && !include.contains(id)) continue;
        if (keep != null && !keep.contains(id)) continue;
        stack.add((id, depth));
      }
    }

    pushChildren(root, 0);
    while (stack.isNotEmpty) {
      final (id, depth) = stack.removeLast();
      final item = tree[id]!;
      final hasKids = tree.hasChildren(id);
      final isCollapsed = collapsed.contains(id);
      final isContext = include != null
          ? !matched!.contains(id)
          : (keep != null && item.status == ItemStatus.completed);
      rows.add(
        VisibleRow(
          item: item,
          depth: depth,
          hasChildren: hasKids,
          collapsed: hasKids && (include == null ? isCollapsed : false),
          isContext: isContext,
          isOrphan: tree.isOrphan(id) || tree.isCycleBreak(id),
          childCount: tree.childIds(id).length,
        ),
      );
      final expand = include != null ? true : !isCollapsed;
      if (hasKids && expand && (maxDepth == null || depth < maxDepth)) pushChildren(id, depth + 1);
    }
    return rows;
  }

  /// Collapsed set for "expand to level N" (Checkvist-style, T4.2.12): every parent at relative
  /// depth ≥ [level] - 1 is collapsed; shallower ones are expanded.
  static Set<String> collapsedForLevel(ChecklistTree tree, int level, {String? focusRootId}) {
    final base = focusRootId == null ? 0 : tree.depthOf(focusRootId) + 1;
    final scope = focusRootId == null ? tree.order : tree.descendants(focusRootId);
    return {
      for (final id in scope)
        if (tree.hasChildren(id) && tree.depthOf(id) - base >= level - 1) id,
    };
  }

  /// Every parent in scope (collapse all).
  static Set<String> allParents(ChecklistTree tree, {String? focusRootId}) {
    final scope = focusRootId == null ? tree.order : tree.descendants(focusRootId);
    return {
      for (final id in scope)
        if (tree.hasChildren(id)) id,
    };
  }
}
