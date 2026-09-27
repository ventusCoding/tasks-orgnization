// Performance scenario for huge lists (T4.2.19, arch §9.6): the tree / roll-up / visible-list
// pipeline for 5 000 items at depth 12+ and a 20 000-item stress list, background tree builds
// above 10 000 items, and single-row edits that rebuild one row only.
//
// Thresholds are for debug (JIT) test runs on a busy host; release builds on devices are several
// times faster.
import 'dart:async';

import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _t0 = DateTime.utc(2026, 9, 22, 9);

/// [n] items: deep chains (every node gets a first child until [depth]) with extra siblings.
List<ChecklistItem> hugeList(int n, {int depth = 13, String checklistId = 'c1'}) {
  final items = <ChecklistItem>[];
  var next = 0;
  String key(int i) => 'a${i.toString().padLeft(7, '0')}';
  void grow(String? parent, int level) {
    for (var k = 0; k < (level == 0 ? 1 : 3) && next < n; k++) {
      final i = next++;
      final id = 'i$i';
      items.add(
        ChecklistItem(
          id: id,
          checklistId: checklistId,
          parentId: parent,
          sortKey: key(i),
          text: 'Item $i',
          status: switch (i % 7) {
            0 => ItemStatus.completed,
            1 => ItemStatus.waiting,
            2 => ItemStatus.ongoing,
            _ => ItemStatus.todo,
          },
          createdAt: _t0,
        ),
      );
      if (level + 1 < depth && k == 0) grow(id, level + 1);
    }
  }

  while (next < n) {
    grow(null, 0);
  }
  return items;
}

int _medianMicros(void Function() body, {int runs = 5}) {
  final times = <int>[];
  for (var r = 0; r < runs; r++) {
    final w = Stopwatch()..start();
    body();
    times.add(w.elapsedMicroseconds);
  }
  times.sort();
  return times[runs ~/ 2];
}

void main() {
  for (final (n, budgetMs) in [(5000, 60), (20000, 200)]) {
    test('tree, roll-ups and visible list for $n items stay within ${budgetMs}ms', () {
      final items = hugeList(n);
      late ChecklistTree tree;
      final build = _medianMicros(() => tree = ChecklistTree.build(items));
      expect(tree.length, n);
      expect(tree.order.map(tree.depthOf).reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(12));
      final rollups = _medianMicros(() => RollupCalculator.compute(tree));
      final visible = _medianMicros(() => VisibleListBuilder.build(tree));
      final totalMs = (build + rollups + visible) ~/ 1000;
      expect(totalMs, lessThan(budgetMs), reason: 'build ${build}µs, roll-ups ${rollups}µs, visible ${visible}µs');
    });
  }

  test('above the threshold the tree is built in an isolate; the previous tree stays until then', () async {
    final rows = StreamController<List<ChecklistItem>>();
    addTearDown(rows.close);
    final container = ProviderContainer(overrides: [checklistItemsProvider.overrideWith((ref, id) => rows.stream)]);
    addTearDown(container.dispose);
    final seen = <int?>[];
    container.listen(checklistTreeProvider('c1'), (_, t) => seen.add(t?.length), fireImmediately: true);

    Future<ChecklistTree> until(int length) async {
      for (var i = 0; i < 400; i++) {
        final t = container.read(checklistTreeProvider('c1'));
        if (t != null && t.length == length) return t;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('no tree of $length items');
    }

    // Small lists: built synchronously.
    rows.add(hugeList(100));
    expect((await until(100)).length, 100);

    // Huge list: first result from the isolate matches a synchronous build.
    final big = hugeList(treeIsolateThreshold + 500);
    rows.add(big);
    final built = await until(big.length);
    final reference = ChecklistTree.build(big);
    expect(built.order, reference.order);
    expect(built.depthOf('i12'), reference.depthOf('i12'));

    // An edit: until the isolate answers, readers keep the previous tree (never null). Only the
    // first background build of a list (crossing the threshold) has nothing to show meanwhile.
    seen.clear();
    rows.add([...big, ChecklistItem(id: 'extra', checklistId: 'c1', sortKey: 'zzz', text: 'Extra', createdAt: _t0)]);
    await until(big.length + 1);
    expect(seen, isNot(contains(null)), reason: 'no loading flashes while editing a huge list');
    expect(seen.last, big.length + 1);
  });

  testWidgets('a status change rebuilds only the changed row', (tester) async {
    final h = TestHarness.create();
    addTearDown(h.dispose);
    late String id;
    await tester.runAsync(() async {
      id =
          (await h
                  .read(checklistsRepositoryProvider)
                  .create(
                    title: 'Big',
                    items: [for (var i = 0; i < 300; i++) NodeSpec(text: 'Row $i')],
                  ))
              .id;
    });
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
    await settle();
    expect(find.text('Row 2'), findsOneWidget);

    final rebuilt = <String>[];
    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, _) {
      final w = element.widget;
      if (w is ItemRow) rebuilt.add(w.row.id);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);

    late String target;
    await tester.runAsync(() async {
      final items = await h.read(checklistItemsRepositoryProvider).items(id);
      target = items.firstWhere((i) => i.text == 'Row 2').id;
      await h.read(checklistServiceProvider).changeStatus(id, [target], ItemStatus.ongoing);
    });
    await settle();
    debugOnRebuildDirtyWidget = previous;
    expect(rebuilt.toSet(), {target}, reason: 'other rows are reused from the row cache');
    await tester.pumpWidget(const SizedBox());
  });
}
