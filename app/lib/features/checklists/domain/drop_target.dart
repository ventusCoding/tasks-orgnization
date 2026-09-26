import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:meta/meta.dart';

/// Where a dragged subtree lands (T4.2.11).
@immutable
class DropTarget {
  const DropTarget({required this.parentId, required this.afterId, required this.depth, required this.gap});

  /// New parent (the focus root / null for top level).
  final String? parentId;

  /// Sibling after which the item goes (null = first child).
  final String? afterId;

  /// Relative depth of the drop indicator.
  final int depth;

  /// Gap index in the row list (0..rows.length).
  final int gap;

  @override
  bool operator ==(Object other) =>
      other is DropTarget &&
      other.parentId == parentId &&
      other.afterId == afterId &&
      other.depth == depth &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(parentId, afterId, depth, gap);

  @override
  String toString() => 'DropTarget(parent=$parentId after=$afterId depth=$depth gap=$gap)';
}

/// Pure drop-target resolution: `(visibleRows, pointer, rowHeights) → (parent, index, depth)`.
abstract final class DropResolver {
  /// Gap under a vertical pointer position [y] (list coordinates), given each row's height.
  static int gapAt(List<double> heights, double y) {
    var top = 0.0;
    for (var i = 0; i < heights.length; i++) {
      if (y < top + heights[i] / 2) return i;
      top += heights[i];
    }
    return heights.length;
  }

  /// Desired depth from the horizontal drag offset (mirrored in RTL).
  static int desiredDepth(int startDepth, double dx, double indentWidth, {bool rtl = false}) =>
      startDepth + ((rtl ? -dx : dx) / indentWidth).round();

  /// Resolves the drop. [rows] must exclude the dragged subtree. The depth is clamped between the
  /// depth of the row below (min) and the depth of the row above + 1 (max; +0 when that row is a
  /// collapsed parent).
  static DropTarget resolve(List<VisibleRow> rows, int gap, int desiredDepth, {String? focusRootId}) {
    final g = gap.clamp(0, rows.length);
    final above = g > 0 ? rows[g - 1] : null;
    final below = g < rows.length ? rows[g] : null;
    final maxDepth = above == null ? 0 : above.depth + (above.hasChildren && above.collapsed ? 0 : 1);
    var minDepth = below == null ? 0 : below.depth;
    if (minDepth > maxDepth) minDepth = maxDepth;
    final depth = desiredDepth.clamp(minDepth, maxDepth);
    String? parent = focusRootId;
    String? after;
    for (var i = g - 1; i >= 0; i--) {
      final r = rows[i];
      if (r.depth == depth && after == null) after = r.id;
      if (r.depth < depth) {
        parent = r.id;
        break;
      }
    }
    return DropTarget(parentId: parent, afterId: after, depth: depth, gap: g);
  }
}
