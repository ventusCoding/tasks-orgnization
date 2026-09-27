import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:meta/meta.dart';

/// One laid-out node of the mind map (T4.5.14). `id == null` is the map's root: the list itself,
/// or the focused item's parent context.
@immutable
class MindMapNode {
  const MindMapNode({
    required this.id,
    required this.parentId,
    required this.depth,
    required this.x,
    required this.y,
    this.hiddenChildren = 0,
  });

  /// Item id, or null for the list root.
  final String? id;
  final String? parentId;
  final int depth;

  /// Top-left corner in map coordinates (left-to-right; mirror for RTL).
  final double x;
  final double y;

  /// Direct children hidden because the node is collapsed.
  final int hiddenChildren;

  @override
  bool operator ==(Object other) =>
      other is MindMapNode &&
      other.id == id &&
      other.parentId == parentId &&
      other.depth == depth &&
      other.x == x &&
      other.y == y &&
      other.hiddenChildren == hiddenChildren;

  @override
  int get hashCode => Object.hash(id, parentId, depth, x, y, hiddenChildren);
}

/// Horizontal tidy-tree layout (T4.5.14): the root at the left, one column per depth, leaves
/// stacked top to bottom in outline order and every parent centred on its children. Fixed-size
/// nodes make the layout deterministic and overlap-free by construction. Pure.
@immutable
class MindMapLayout {
  const MindMapLayout._(this.nodes, this.width, this.height, this.nodeWidth, this.nodeHeight);

  /// Lays out [tree] from [rootId] (null = the whole list under a list root node); [collapsed]
  /// items keep their node but hide their subtree.
  factory MindMapLayout.compute(
    ChecklistTree tree, {
    String? rootId,
    Set<String> collapsed = const {},
    double nodeWidth = 176,
    double nodeHeight = 44,
    double horizontalGap = 48,
    double verticalGap = 12,
  }) {
    final nodes = <MindMapNode>[];
    var nextLeafY = 0.0;
    var maxDepth = 0;
    final root = rootId != null && tree.contains(rootId) ? rootId : null;

    // Returns the node's y. Recursion depth = tree depth (bounded by the editor's limits).
    double place(String? id, String? parentId, int depth) {
      if (depth > maxDepth) maxDepth = depth;
      final children = (id == null || !collapsed.contains(id)) ? tree.childIds(id) : const <String>[];
      final x = depth * (nodeWidth + horizontalGap);
      double y;
      final index = nodes.length;
      nodes.add(MindMapNode(id: id, parentId: parentId, depth: depth, x: x, y: 0));
      if (children.isEmpty) {
        y = nextLeafY;
        nextLeafY += nodeHeight + verticalGap;
      } else {
        final ys = [for (final c in children) place(c, id, depth + 1)];
        y = (ys.first + ys.last) / 2;
      }
      nodes[index] = MindMapNode(
        id: id,
        parentId: parentId,
        depth: depth,
        x: x,
        y: y,
        hiddenChildren: id != null && collapsed.contains(id) ? tree.childIds(id).length : 0,
      );
      return y;
    }

    if (root == null) {
      place(null, null, 0);
    } else {
      place(root, null, 0);
    }
    final width = (maxDepth + 1) * (nodeWidth + horizontalGap) - horizontalGap;
    final height = nextLeafY == 0 ? nodeHeight : nextLeafY - verticalGap;
    return MindMapLayout._(List.unmodifiable(nodes), width, height, nodeWidth, nodeHeight);
  }

  /// Nodes in depth-first outline order (root first).
  final List<MindMapNode> nodes;
  final double width;
  final double height;
  final double nodeWidth;
  final double nodeHeight;

  /// [node]'s x in a right-to-left map (root at the right).
  double mirroredX(MindMapNode node) => width - node.x - nodeWidth;
}
