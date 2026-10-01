import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:meta/meta.dart';

/// One printed row: an item at its depth below the printed root.
@immutable
class PdfRow {
  const PdfRow(this.id, this.depth);

  final String id;
  final int depth;

  @override
  bool operator ==(Object other) => other is PdfRow && other.id == id && other.depth == depth;

  @override
  int get hashCode => Object.hash(id, depth);

  @override
  String toString() => 'PdfRow($id, $depth)';
}

/// Consecutive rows printed as one unit. A [keepTogether] block is never split across pages
/// (it moves to the next page when it doesn't fit).
@immutable
class PdfBlock {
  const PdfBlock(this.rows, {required this.keepTogether});

  final List<PdfRow> rows;
  final bool keepTogether;

  @override
  String toString() => 'PdfBlock(${keepTogether ? 'keep ' : ''}$rows)';
}

/// Page-break plan of the PDF export (T4.5.10): small subtrees (at most [keepTogetherRows] items)
/// stay on one page; larger ones print their own row alone and recurse into their children, so a
/// long list still breaks between branches rather than inside them. [rootId] prints a branch
/// (its children at depth 0).
List<PdfBlock> pdfBlocks(ChecklistTree tree, {String? rootId, int keepTogetherRows = 12}) {
  final blocks = <PdfBlock>[];
  void subtreeRows(String id, int depth, List<PdfRow> out) {
    out.add(PdfRow(id, depth));
    for (final child in tree.childIds(id)) {
      subtreeRows(child, depth + 1, out);
    }
  }

  void visit(String id, int depth) {
    final size = 1 + tree.descendantCount(id);
    if (size <= keepTogetherRows) {
      final rows = <PdfRow>[];
      subtreeRows(id, depth, rows);
      blocks.add(PdfBlock(rows, keepTogether: size > 1));
      return;
    }
    blocks.add(PdfBlock([PdfRow(id, depth)], keepTogether: false));
    for (final child in tree.childIds(id)) {
      visit(child, depth + 1);
    }
  }

  for (final id in tree.childIds(rootId)) {
    visit(id, 0);
  }
  return blocks;
}
