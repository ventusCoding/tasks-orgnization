// Mind map layout (T4.5.14): deterministic horizontal tidy tree without overlaps.
import 'dart:math' as math;

import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/mind_map_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checklist_test_support.dart' show tree;

void main() {
  final t = tree('''
Documents
  Passport
  Visa
    Photos
    Form
Clothes
Toiletries
  Brush''');

  MindMapNode node(MindMapLayout l, String? id) => l.nodes.firstWhere((n) => n.id == id);

  bool overlaps(MindMapLayout l) {
    for (var i = 0; i < l.nodes.length; i++) {
      for (var j = i + 1; j < l.nodes.length; j++) {
        final a = l.nodes[i];
        final b = l.nodes[j];
        final dx = (a.x - b.x).abs() < l.nodeWidth;
        final dy = (a.y - b.y).abs() < l.nodeHeight;
        if (dx && dy) return true;
      }
    }
    return false;
  }

  test('columns by depth, leaves stacked in outline order, parents centred on their children', () {
    final l = MindMapLayout.compute(t, nodeWidth: 100, nodeHeight: 40, horizontalGap: 20, verticalGap: 10);
    expect(l.nodes.first.id, isNull, reason: 'the list root');
    expect([for (final n in l.nodes) n.id], [null, ...t.order]);
    expect(node(l, 'Documents').x, 120);
    expect(node(l, 'Photos').x, 360);
    // Leaves: Passport, Photos, Form, Clothes, Brush — 50 px apart.
    expect(
      [
        for (final id in ['Passport', 'Photos', 'Form', 'Clothes', 'Brush']) node(l, id).y,
      ],
      [0, 50, 100, 150, 200],
    );
    expect(node(l, 'Visa').y, 75);
    expect(node(l, 'Documents').y, (0 + 75) / 2);
    expect(node(l, 'Toiletries').y, 200);
    expect(node(l, null).y, (node(l, 'Documents').y + node(l, 'Toiletries').y) / 2);
    expect(l.width, 4 * 120 - 20);
    expect(l.height, 240);
    expect(overlaps(l), isFalse);
  });

  test('collapsed nodes keep their place and hide their subtree', () {
    final l = MindMapLayout.compute(t, collapsed: {'Visa', 'Toiletries'});
    expect(l.nodes.map((n) => n.id), isNot(contains('Photos')));
    expect(l.nodes.map((n) => n.id), isNot(contains('Brush')));
    expect(node(l, 'Visa').hiddenChildren, 2);
    expect(node(l, 'Toiletries').hiddenChildren, 1);
    expect(overlaps(l), isFalse);
  });

  test('a focus root lays out that branch only', () {
    final l = MindMapLayout.compute(t, rootId: 'Documents');
    expect([for (final n in l.nodes) n.id], ['Documents', 'Passport', 'Visa', 'Photos', 'Form']);
    expect(node(l, 'Documents').depth, 0);
  });

  test('deterministic, mirrored for RTL, and quick on large random trees', () {
    final random = math.Random(7);
    final lines = <String>[];
    var depth = 0;
    for (var i = 0; i < 3000; i++) {
      depth = (depth + random.nextInt(3) - 1).clamp(0, math.min(depth + 1, 14));
      lines.add('${'  ' * depth}n$i');
    }
    final big = ChecklistTree.build(tree(lines.join('\n')).items.toList());
    final watch = Stopwatch()..start();
    final a = MindMapLayout.compute(big);
    watch.stop();
    final b = MindMapLayout.compute(big);
    expect(a.nodes, b.nodes);
    expect(a.nodes, hasLength(3001));
    expect(watch.elapsedMilliseconds, lessThan(500));
    // Leaves never share a slot, so no two nodes of a column overlap.
    final byColumn = <double, List<double>>{};
    for (final n in a.nodes) {
      (byColumn[n.x] ??= []).add(n.y);
    }
    for (final ys in byColumn.values) {
      ys.sort();
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i] - ys[i - 1], greaterThanOrEqualTo(a.nodeHeight));
      }
    }
    final root = a.nodes.first;
    expect(a.mirroredX(root), a.width - a.nodeWidth);
  });
}
