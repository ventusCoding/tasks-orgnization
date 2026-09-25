import 'package:everslot/features/checklists/domain/checklist.dart';

/// Immutable in-memory tree of one checklist's live items (T4.2.01, arch §6.10).
///
/// Built from flat rows (adjacency list + fractional `sort_key`). Siblings are ordered by
/// `(sort_key, id)` so devices that generated equal keys concurrently still agree. The builder
/// never throws: items whose parent is missing are surfaced as roots flagged [isOrphan]; cycles
/// (possible transiently while local moves mix with pulled rows) are broken at the member with the
/// smallest id, which becomes a root flagged [isCycleBreak].
class ChecklistTree {
  ChecklistTree._({
    required this.byId,
    required Map<String?, List<String>> children,
    required Map<String, String?> parent,
    required Map<String, int> depth,
    required this.order,
    required Map<String, int> index,
    required this.orphans,
    required this.cycleBreaks,
  }) : _children = children,
       _parent = parent,
       _depth = depth,
       _index = index;

  static final empty = ChecklistTree.build(const []);

  factory ChecklistTree.build(Iterable<ChecklistItem> items) {
    final byId = <String, ChecklistItem>{for (final i in items) i.id: i};
    final parent = <String, String?>{};
    final orphans = <String>{};
    for (final item in byId.values) {
      final p = item.parentId;
      if (p == null) {
        parent[item.id] = null;
      } else if (p == item.id || !byId.containsKey(p)) {
        parent[item.id] = null;
        if (p != item.id) orphans.add(item.id);
      } else {
        parent[item.id] = p;
      }
    }

    // Resolve reachability from the root; break cycles deterministically.
    final cycleBreaks = <String>{};
    final resolved = <String>{};
    final ids = byId.keys.toList()..sort();
    for (final start in ids) {
      if (resolved.contains(start)) continue;
      final path = <String>[];
      final pos = <String, int>{};
      String? x = start;
      while (x != null && !resolved.contains(x)) {
        final seen = pos[x];
        if (seen != null) {
          final cycle = path.sublist(seen);
          final breakAt = cycle.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
          parent[breakAt] = null;
          cycleBreaks.add(breakAt);
          path.clear();
          pos.clear();
          x = start;
          continue;
        }
        pos[x] = path.length;
        path.add(x);
        x = parent[x];
      }
      resolved.addAll(path);
    }

    final children = <String?, List<String>>{};
    for (final e in parent.entries) {
      (children[e.value] ??= []).add(e.key);
    }
    int compare(String a, String b) {
      final ka = byId[a]!.sortKey;
      final kb = byId[b]!.sortKey;
      final c = ka.compareTo(kb);
      return c != 0 ? c : a.compareTo(b);
    }

    for (final list in children.values) {
      list.sort(compare);
    }

    // Iterative pre-order DFS (no recursion: chains can be thousands deep).
    final order = <String>[];
    final depth = <String, int>{};
    final index = <String, int>{};
    final stack = <(String, int)>[];
    final roots = children[null] ?? const <String>[];
    for (var i = roots.length - 1; i >= 0; i--) {
      stack.add((roots[i], 0));
    }
    while (stack.isNotEmpty) {
      final (id, d) = stack.removeLast();
      index[id] = order.length;
      order.add(id);
      depth[id] = d;
      final kids = children[id];
      if (kids != null) {
        for (var i = kids.length - 1; i >= 0; i--) {
          stack.add((kids[i], d + 1));
        }
      }
    }

    return ChecklistTree._(
      byId: byId,
      children: children,
      parent: parent,
      depth: depth,
      order: order,
      index: index,
      orphans: orphans,
      cycleBreaks: cycleBreaks,
    );
  }

  final Map<String, ChecklistItem> byId;
  final Map<String?, List<String>> _children;
  final Map<String, String?> _parent;
  final Map<String, int> _depth;

  /// All ids in DFS pre-order.
  final List<String> order;
  final Map<String, int> _index;
  final Set<String> orphans;
  final Set<String> cycleBreaks;

  int get length => order.length;
  bool get isEmpty => order.isEmpty;

  ChecklistItem? operator [](String id) => byId[id];
  bool contains(String? id) => id != null && byId.containsKey(id);

  bool isOrphan(String id) => orphans.contains(id);
  bool isCycleBreak(String id) => cycleBreaks.contains(id);

  /// Ordered child ids of [parentId] (`null` = top level).
  List<String> childIds(String? parentId) => _children[parentId] ?? const [];

  List<ChecklistItem> children(String? parentId) => [for (final id in childIds(parentId)) byId[id]!];

  bool hasChildren(String id) => (_children[id]?.isNotEmpty) ?? false;
  bool isLeaf(String id) => !hasChildren(id);

  /// Effective parent (after orphan/cycle handling).
  String? parentOf(String id) => _parent[id];
  int depthOf(String id) => _depth[id] ?? 0;
  int indexOf(String id) => _index[id] ?? -1;

  List<String> siblingsOf(String id) => childIds(parentOf(id));
  int siblingIndex(String id) => siblingsOf(id).indexOf(id);

  String? previousSibling(String id) {
    final s = siblingsOf(id);
    final i = s.indexOf(id);
    return i > 0 ? s[i - 1] : null;
  }

  String? nextSibling(String id) {
    final s = siblingsOf(id);
    final i = s.indexOf(id);
    return i >= 0 && i < s.length - 1 ? s[i + 1] : null;
  }

  /// Root-first path of ancestors (excluding [id]) — O(depth).
  List<String> ancestors(String id) {
    final out = <String>[];
    var p = _parent[id];
    while (p != null) {
      out.add(p);
      p = _parent[p];
    }
    return out.reversed.toList();
  }

  /// Index in [order] just after the last descendant of [id].
  int subtreeEnd(String id) {
    final start = indexOf(id);
    if (start < 0) return -1;
    final d = depthOf(id);
    var i = start + 1;
    while (i < order.length && depthOf(order[i]) > d) {
      i++;
    }
    return i;
  }

  /// Descendants of [id] in pre-order (excluding [id]).
  List<String> descendants(String id) {
    final start = indexOf(id);
    if (start < 0) return const [];
    return order.sublist(start + 1, subtreeEnd(id));
  }

  int descendantCount(String id) => descendants(id).length;

  /// Whether [id] is inside the subtree of [ancestorId] (strictly below it).
  bool isDescendant(String id, String ancestorId) {
    var p = _parent[id];
    while (p != null) {
      if (p == ancestorId) return true;
      p = _parent[p];
    }
    return false;
  }

  /// The top-most ids of a selection (drops ids whose ancestor is also selected), in DFS order.
  List<String> topMost(Iterable<String> ids) {
    final set = ids.where(byId.containsKey).toSet();
    final result = set.where((id) => !ancestors(id).any(set.contains)).toList()
      ..sort((a, b) => indexOf(a).compareTo(indexOf(b)));
    return result;
  }

  /// Items in DFS order.
  Iterable<ChecklistItem> get items => order.map((id) => byId[id]!);
}
