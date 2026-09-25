import 'dart:math' as math;

import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checklist_test_support.dart';

void main() {
  group('ChecklistTree.build', () {
    test('orders siblings by (sort_key, id), computes depth, DFS order and helpers', () {
      final t = tree('''
A
  A1
  A2
    A2a
B''');
      expect(t.order, ['A', 'A1', 'A2', 'A2a', 'B']);
      expect(t.depthOf('A2a'), 2);
      expect(t.ancestors('A2a'), ['A', 'A2']);
      expect(t.descendants('A'), ['A1', 'A2', 'A2a']);
      expect(t.isLeaf('A1'), isTrue);
      expect(t.previousSibling('A2'), 'A1');
      expect(t.nextSibling('A'), 'B');
      expect(t.isDescendant('A2a', 'A'), isTrue);
      expect(t.topMost(['A2a', 'A', 'B']), ['A', 'B']);
    });

    test('equal keys are tie-broken by id on every device', () {
      final items = [
        const ChecklistItem(id: 'z', checklistId: 'c', sortKey: 'a0'),
        const ChecklistItem(id: 'b', checklistId: 'c', sortKey: 'a0'),
        const ChecklistItem(id: 'm', checklistId: 'c', sortKey: 'Zz'),
      ];
      expect(ChecklistTree.build(items).order, ['m', 'b', 'z']);
      expect(ChecklistTree.build(items.reversed).order, ['m', 'b', 'z']);
    });

    test('orphans surface as roots; cycles are broken at the smallest id', () {
      final items = [
        const ChecklistItem(id: 'x', checklistId: 'c', sortKey: 'a1', parentId: 'y'),
        const ChecklistItem(id: 'y', checklistId: 'c', sortKey: 'a2', parentId: 'x'),
        const ChecklistItem(id: 'kid', checklistId: 'c', sortKey: 'a3', parentId: 'y'),
        const ChecklistItem(id: 'lost', checklistId: 'c', sortKey: 'a4', parentId: 'gone'),
        const ChecklistItem(id: 'self', checklistId: 'c', sortKey: 'a5', parentId: 'self'),
      ];
      final t = ChecklistTree.build(items);
      expect(t.length, 5);
      expect(t.orphans, {'lost'});
      expect(t.cycleBreaks, {'x'});
      expect(t.parentOf('x'), isNull);
      expect(t.parentOf('y'), 'x');
      expect(t.childIds('y'), ['kid']);
      expect(t.parentOf('self'), isNull);
    });

    test('deep chains (depth 5 000) build without recursion', () {
      final items = [
        for (var i = 0; i < 5000; i++)
          ChecklistItem(id: 'n$i', checklistId: 'c', sortKey: 'a0', parentId: i == 0 ? null : 'n${i - 1}'),
      ];
      final sw = Stopwatch()..start();
      final t = ChecklistTree.build(items);
      sw.stop();
      expect(t.depthOf('n4999'), 4999);
      expect(t.descendants('n0'), hasLength(4999));
      expect(t.subtreeEnd('n0'), 5000);
    });

    test('5 000 items build quickly', () {
      final r = math.Random(3);
      final items = <ChecklistItem>[];
      for (var i = 0; i < 5000; i++) {
        final parent = i < 10 ? null : 'n${r.nextInt(i)}';
        items.add(ChecklistItem(id: 'n$i', checklistId: 'c', sortKey: 'a${r.nextInt(9) + 1}', parentId: parent));
      }
      final sw = Stopwatch()..start();
      final t = ChecklistTree.build(items);
      sw.stop();
      expect(t.length, 5000);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  group('inserts & enter', () {
    test('insertAfter / insertBefore / first child / append', () {
      var items = outline('A\n  A1\nB');
      var t = ChecklistTree.build(items);
      final c = ctx();
      var ch = TreeOps.insertAfter(t, c, 'A');
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      final newId = ch.focus!.itemId;
      expect(t.order, ['A', 'A1', newId, 'B']);
      ch = TreeOps.insertBefore(t, c, 'A');
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      expect(t.order.first, ch.focus!.itemId);
      ch = TreeOps.insertFirstChild(t, c, 'A');
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      expect(t.childIds('A').first, ch.focus!.itemId);
      ch = TreeOps.appendChild(t, c, 'A');
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      expect(t.childIds('A').last, ch.focus!.itemId);
      checkInvariants(items);
    });

    test('enter splits text at the cursor; expanded parent gets a first child', () {
      var items = outline('Buy milk\nParent\n  Kid');
      var t = ChecklistTree.build(items);
      var ch = TreeOps.enter(t, ctx(), 'Buy milk', text: 'Buy milk and eggs', cursor: 8, expanded: true);
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      final created = ch.focus!.itemId;
      expect(t['Buy milk']!.text, 'Buy milk');
      expect(t[created]!.text, ' and eggs');
      expect(t.parentOf(created), isNull);
      expect(ch.focus!.cursor, 0);
      ch = TreeOps.enter(t, ctx(), 'Parent', text: 'Parent', cursor: 6, expanded: true);
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      expect(t.childIds('Parent').first, ch.focus!.itemId);
      ch = TreeOps.enter(t, ctx(), 'Parent', text: 'Parent', cursor: 6, expanded: false);
      items = applyChange(items, ch);
      t = ChecklistTree.build(items);
      expect(t.parentOf(ch.focus!.itemId), isNull);
      expect(t.previousSibling(ch.focus!.itemId), 'Parent');
    });

    test('enter at offset 0 of a non-empty row inserts above and keeps the caret', () {
      final items = outline('A');
      final ch = TreeOps.enter(ChecklistTree.build(items), ctx(), 'A', text: 'A', cursor: 0, expanded: true);
      final t = ChecklistTree.build(applyChange(items, ch));
      expect(t.order.last, 'A');
      expect(ch.focus!.itemId, 'A');
    });

    test('adding a child under a completed parent reopens it (auto-complete on)', () {
      final items = outline('P:completed\n  K:completed');
      final ch = TreeOps.appendChild(ChecklistTree.build(items), ctx(), 'P');
      final t = ChecklistTree.build(applyChange(items, ch));
      expect(t['P']!.status, ItemStatus.todo);
      expect(ch.events.where((e) => e.cause == 'cascade'), hasLength(1));
    });
  });

  group('backspace / merge', () {
    test('empty childless row is deleted and focus goes to the previous row end', () {
      final items = outline('A\nB');
      final ch = TreeOps.backspaceAtStart(ChecklistTree.build(items), ctx(), 'B', text: '', previousVisibleId: 'A');
      expect(ch.deletedItemIds, {'B'});
      expect(ch.focus!.itemId, 'A');
      expect(ChecklistTree.build(applyChange(items, ch)).order, ['A']);
    });

    test('merge appends text, re-parents children and re-owns attachments', () {
      final items = outline('A\n  A1\nB\n  B1\n  B2');
      final ch = TreeOps.backspaceAtStart(ChecklistTree.build(items), ctx(), 'B', text: 'B', previousVisibleId: 'A1');
      final t = ChecklistTree.build(applyChange(items, ch));
      expect(t['A1']!.text, 'A1B');
      expect(t.childIds('A1'), ['B1', 'B2']);
      expect(t.contains('B'), isFalse);
      expect(ch.reownedAttachments.single, (fromItemId: 'B', toItemId: 'A1'));
      expect(ch.focus!.cursor, 2);
    });

    test('merging a first child into its parent keeps the children in place', () {
      final items = outline('P\n  K\n    K1\n  L');
      final t = ChecklistTree.build(applyChange(
        items,
        TreeOps.backspaceAtStart(ChecklistTree.build(items), ctx(), 'K', text: 'K', previousVisibleId: 'P'),
      ));
      expect(render(t), 'PK\n  K1\n  L');
    });

    test('never merges across the focus root', () {
      final items = outline('P\n  K');
      final ch = TreeOps.backspaceAtStart(
        ChecklistTree.build(items),
        ctx(),
        'K',
        text: 'K',
        previousVisibleId: 'P',
        focusRootId: 'P',
      );
      expect(ch.isEmpty, isTrue);
    });
  });

  group('indent / outdent / move', () {
    test('indent makes the row the last child of its previous sibling; first row is denied', () {
      final items = outline('A\n  A1\nB\nC');
      final t = ChecklistTree.build(items);
      final t2 = ChecklistTree.build(applyChange(items, TreeOps.indent(t, ctx(), ['B'])));
      expect(render(t2), 'A\n  A1\n  B\nC');
      expect(TreeOps.indent(t, ctx(), ['A']).isEmpty, isTrue);
    });

    test('contiguous selected siblings indent together', () {
      final items = outline('A\nB\nC\nD');
      final t2 = ChecklistTree.build(applyChange(items, TreeOps.indent(ChecklistTree.build(items), ctx(), ['B', 'C'])));
      expect(render(t2), 'A\n  B\n  C\nD');
    });

    test('outdent: following siblings stay under the old parent (Workflowy)', () {
      final items = outline('P\n  A\n  B\n  C\nQ');
      final t2 = ChecklistTree.build(applyChange(items, TreeOps.outdent(ChecklistTree.build(items), ctx(), ['B'])));
      expect(render(t2), 'P\n  A\n  C\nB\nQ');
    });

    test('outdent is a no-op at root and directly under the focus root', () {
      final t = tree('P\n  A');
      expect(TreeOps.outdent(t, ctx(), ['P']).isEmpty, isTrue);
      expect(TreeOps.outdent(t, ctx(), ['A'], focusRootId: 'P').isEmpty, isTrue);
    });

    test('several selected rows under one parent outdent in order', () {
      final items = outline('P\n  A\n  B\n  C\nQ');
      final t2 = ChecklistTree.build(applyChange(items, TreeOps.outdent(ChecklistTree.build(items), ctx(), ['A', 'C'])));
      expect(render(t2), 'P\n  B\nA\nC\nQ');
    });

    test('move up / down among siblings', () {
      var items = outline('A\nB\nC');
      items = applyChange(items, TreeOps.moveUp(ChecklistTree.build(items), ctx(), ['C']));
      expect(ChecklistTree.build(items).order, ['A', 'C', 'B']);
      items = applyChange(items, TreeOps.moveDown(ChecklistTree.build(items), ctx(), ['A']));
      expect(ChecklistTree.build(items).order, ['C', 'A', 'B']);
      expect(TreeOps.moveUp(ChecklistTree.build(items), ctx(), ['C']).isEmpty, isTrue);
    });

    test('moveTo is cycle-safe', () {
      final t = tree('A\n  A1\n    A1a\nB');
      expect(TreeOps.moveTo(t, ctx(), ['A'], newParentId: 'A1a').isEmpty, isTrue);
      expect(TreeOps.moveTo(t, ctx(), ['A'], newParentId: 'A').isEmpty, isTrue);
      final items = outline('A\n  A1\n    A1a\nB');
      final moved = ChecklistTree.build(applyChange(items, TreeOps.moveTo(t, ctx(), ['A1'], newParentId: 'B')));
      expect(render(moved), 'A\nB\n  A1\n    A1a');
    });
  });

  group('subtrees', () {
    test('delete tombstones the whole subtree under one change', () {
      final items = outline('A\n  A1\n    A1a\nB');
      final ch = TreeOps.deleteSubtrees(ChecklistTree.build(items), ctx(), ['A', 'A1a']);
      expect(ch.deletedItemIds, {'A', 'A1', 'A1a'});
      expect(ch.events.where((e) => e.eventType == 'deleted'), hasLength(1));
      expect(ChecklistTree.build(applyChange(items, ch)).order, ['B']);
    });

    test('duplicate copies structure with fresh ids right after the original', () {
      final items = outline('A:completed\n  A1:waiting\n  A2\nB');
      final t = ChecklistTree.build(items);
      final ch = TreeOps.duplicateSubtrees(t, ctx(), ['A'], resetStatuses: true);
      final t2 = ChecklistTree.build(applyChange(items, ch));
      expect(t2.length, 7);
      final copy = ch.focus!.itemId;
      expect(t2.nextSibling('A'), copy);
      expect(t2.children(copy).map((i) => i.text), ['A1', 'A2']);
      expect(t2.children(copy).every((i) => i.status == ItemStatus.todo), isTrue);
      expect(ch.copiedItemIds.keys.toSet(), {'A', 'A1', 'A2'});
      expect(ch.copiedItemIds.values.toSet().intersection({'A', 'A1', 'A2'}), isEmpty);
    });

    test('duplicating 1 000 rows is fast', () {
      final items = <ChecklistItem>[
        const ChecklistItem(id: 'root', checklistId: 'c1', sortKey: 'a0'),
        for (var i = 0; i < 999; i++)
          ChecklistItem(id: 'k$i', checklistId: 'c1', sortKey: FractionalIndex.nBetween(null, null, 999)[0], parentId: 'root'),
      ];
      final t = ChecklistTree.build(items);
      final sw = Stopwatch()..start();
      final ch = TreeOps.duplicateSubtrees(t, ctx(), ['root']);
      sw.stop();
      expect(ch.writesTo('checklist_items'), hasLength(1000));
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('insertNodes builds nested rows (import/paste) and copies attachments of sources', () {
      final items = outline('A');
      final ch = TreeOps.insertNodes(ChecklistTree.build(items), ctx(), const [
        NodeSpec(text: 'X', sourceItemId: 'orig', children: [NodeSpec(text: 'X1'), NodeSpec(text: 'X2', status: ItemStatus.completed)]),
        NodeSpec(text: 'Y'),
      ]);
      final t = ChecklistTree.build(applyChange(items, ch));
      expect(render(t, statuses: true), 'A\nX\n  X1\n  X2:completed\nY');
      expect(ch.copiedItemIds.keys, ['orig']);
    });

    test('moveToChecklist updates checklist_id on every descendant and logs moved', () {
      final t = tree('A\n  A1\n    A1a\nB');
      final ch = TreeOps.moveToChecklist(t, ctx(), ['A'], targetChecklistId: 'c2');
      final ids = ch.writes.where((w) => w.values['checklist_id'] == 'c2').map((w) => w.id).toSet();
      expect(ids, {'A', 'A1', 'A1a'});
      final ev = ch.events.single;
      expect(ev.payload['fromChecklistId'], 'c1');
      expect(ev.payload['toChecklistId'], 'c2');
    });

    test('promote: children become roots of the new list, attachments become checklist-level', () {
      final t = tree('A\n  A1\n    A1a\nB');
      final ch = TreeOps.promote(t, ctx(), 'A', newChecklistId: 'c9');
      expect(ch.valuesFor('A1'), {'checklist_id': 'c9', 'parent_id': null});
      expect(ch.valuesFor('A1a'), {'checklist_id': 'c9'});
      expect(ch.promotedAttachments, {'A': 'c9'});
      expect(ch.deletedItemIds, {'A'});
    });

    test('sortChildren rewrites one sibling group with locale-aware collation', () {
      final items = outline('Zèbre\népée\nÉcole\nabricot');
      final t2 = ChecklistTree.build(
        applyChange(items, TreeOps.sortChildren(ChecklistTree.build(items), ctx(), null, ItemSortBy.alphabetical)),
      );
      expect(t2.order, ['abricot', 'École', 'épée', 'Zèbre']);
    });
  });

  test('property: 3 000 random operations keep the invariants', () {
    final r = math.Random(42);
    var items = outline('A\nB\nC');
    for (var step = 0; step < 3000; step++) {
      final t = ChecklistTree.build(items);
      final ids = t.order;
      final c = ctx();
      final pick = ids.isEmpty ? null : ids[r.nextInt(ids.length)];
      TreeChange change;
      switch (ids.isEmpty ? 0 : r.nextInt(9)) {
        case 0:
          change = TreeOps.appendChild(t, c, pick == null || r.nextBool() ? null : pick);
        case 1:
          change = TreeOps.insertAfter(t, c, pick!);
        case 2:
          change = TreeOps.indent(t, c, [pick!]);
        case 3:
          change = TreeOps.outdent(t, c, [pick!]);
        case 4:
          change = TreeOps.moveUp(t, c, [pick!]);
        case 5:
          change = TreeOps.moveDown(t, c, [pick!]);
        case 6:
          final target = ids[r.nextInt(ids.length)];
          change = TreeOps.moveTo(t, c, [pick!], newParentId: r.nextBool() ? null : target);
        case 7:
          change = ids.length > 30 ? TreeOps.deleteSubtrees(t, c, [pick!]) : TreeOps.insertBefore(t, c, pick!);
        default:
          change = ids.length < 60 ? TreeOps.duplicateSubtrees(t, c, [pick!]) : TreeOps.indent(t, c, [pick!]);
      }
      items = applyChange(items, change);
      checkInvariants(items);
    }
  });
}
