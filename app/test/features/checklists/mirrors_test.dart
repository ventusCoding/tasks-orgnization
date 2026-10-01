import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Live item mirrors (T4.5.16): rendering, edit-through, stats, delete → plain copy, cycle guards.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<String> list(String title, [List<NodeSpec> items = const []]) async =>
      (await h.read(checklistsRepositoryProvider).create(title: title, items: items)).id;

  Future<List<ChecklistItem>> shown(String listId) => h.read(checklistItemsRepositoryProvider).watchItems(listId).first;

  Future<ChecklistItem> byText(String listId, String text) async =>
      (await h.read(checklistItemsRepositoryProvider).items(listId)).firstWhere((i) => i.text == text);

  /// Home: Groceries > (Milk, Eggs); Today: Plan.
  Future<(String, String, ChecklistItem)> seed() async {
    final home = await list('Home', const [
      NodeSpec(
        text: 'Groceries',
        children: [
          NodeSpec(text: 'Milk'),
          NodeSpec(text: 'Eggs'),
        ],
      ),
    ]);
    final today = await list('Today', const [NodeSpec(text: 'Plan')]);
    return (home, today, await byText(home, 'Groceries'));
  }

  Future<ChecklistItem> mirrorIn(String listId) async => (await shown(listId)).firstWhere((i) => i.isMirror);

  test('a mirror shows its original live and edits go through to it', () async {
    final (home, today, groceries) = await seed();
    final service = h.read(checklistServiceProvider);
    final created = await service.createMirror(groceries.id, targetChecklistId: today);
    expect(created, isNotNull);

    var mirror = await mirrorIn(today);
    expect(mirror.mirrorOfId, groceries.id);
    expect(mirror.text, 'Groceries');

    // Status and text through the mirror change the original.
    await service.changeStatus(today, [mirror.id], ItemStatus.waiting, note: 'shop closed');
    await service.setText(today, mirror.id, 'Groceries for the week', logEvent: true);
    await service.setFields(today, mirror.id, {'priority': 3});
    final original = await byText(home, 'Groceries for the week');
    expect(original.status, ItemStatus.waiting);
    expect(original.statusNote, 'shop closed');
    expect(original.priority, 3);

    // …and the mirror row displays it (the original changed in another list).
    mirror = await mirrorIn(today);
    expect(mirror.text, 'Groceries for the week');
    expect(mirror.status, ItemStatus.waiting);

    // A mirror of the mirror points at the same original.
    await service.createMirror(mirror.id, targetChecklistId: home);
    final again = (await shown(home)).where((i) => i.isMirror).single;
    expect(again.mirrorOfId, groceries.id);

    // Children of the original come with the mirror sources.
    final sources = await h.read(checklistItemsRepositoryProvider).watchMirrorSources(today).first;
    expect(sources.children(groceries.id).map((i) => i.text), ['Milk', 'Eggs']);
  });

  test('stats count originals only', () async {
    final (home, today, groceries) = await seed();
    final service = h.read(checklistServiceProvider);
    await service.createMirror(groceries.id, targetChecklistId: today);
    await service.changeStatus(home, [groceries.id], ItemStatus.completed, completeOpenDescendants: true);

    final tree = ChecklistTree.build(await shown(today));
    final root = RollupCalculator.root(tree, RollupCalculator.compute(tree));
    expect(root.completed, 0, reason: 'the completed mirror is not counted in Today');
    expect(root.todo, 1, reason: 'only Plan');

    final summaries = await h.read(checklistsRepositoryProvider).watchCardSummaries([
      today,
    ], now: h.clock.nowUtc()).first;
    expect(summaries[today]!.rollup.completed, 0);

    final counts = await h.read(checklistsRepositoryProvider).watchSmartCounts(now: h.clock.nowUtc()).first;
    expect(counts.waiting, 0);
  });

  test('deleting the original turns its mirrors into plain copies with its children', () async {
    final (home, today, groceries) = await seed();
    final service = h.read(checklistServiceProvider);
    await service.createMirror(groceries.id, targetChecklistId: today);
    await service.changeStatus(home, [groceries.id], ItemStatus.ongoing);
    await service.run(home, (t, ctx, _) => TreeOps.deleteSubtrees(t, ctx, [groceries.id]));

    final rows = await h.read(checklistItemsRepositoryProvider).items(today);
    final copy = rows.firstWhere((i) => i.text == 'Groceries');
    expect(copy.isMirror, isFalse);
    expect(copy.status, ItemStatus.ongoing);
    final tree = ChecklistTree.build(rows);
    expect(tree.children(copy.id).map((i) => i.text), ['Milk', 'Eggs']);
    expect(await h.read(checklistItemsRepositoryProvider).liveById(groceries.id), isNull);
  });

  test('deleting the original list detaches its mirrors too', () async {
    final (home, today, groceries) = await seed();
    await h.read(checklistServiceProvider).createMirror(groceries.id, targetChecklistId: today);
    await h.read(checklistsRepositoryProvider).delete(home);
    final rows = await h.read(checklistItemsRepositoryProvider).items(today);
    expect(rows.where((i) => i.isMirror), isEmpty);
    expect(rows.map((i) => i.text), containsAll(['Plan', 'Groceries', 'Milk', 'Eggs']));
  });

  test('unlink keeps a plain copy of the original content', () async {
    final (home, today, groceries) = await seed();
    final service = h.read(checklistServiceProvider);
    await service.createMirror(groceries.id, targetChecklistId: today);
    await service.setText(home, groceries.id, 'Groceries!', logEvent: true);
    final mirror = await mirrorIn(today);
    await service.unlinkMirror(today, mirror.id);
    final row = (await h.read(checklistItemsRepositoryProvider).items(today)).firstWhere((i) => i.id == mirror.id);
    expect(row.isMirror, isFalse);
    expect(row.text, 'Groceries!');
  });

  test('cycle guards: no mirror inside its original, no children under a mirror', () async {
    final (home, today, groceries) = await seed();
    final service = h.read(checklistServiceProvider);
    final milk = await byText(home, 'Milk');
    expect(await service.createMirror(groceries.id, targetChecklistId: home, parentId: milk.id), isNull);
    expect(await service.createMirror(groceries.id, targetChecklistId: home, parentId: groceries.id), isNull);
    final created = (await service.createMirror(groceries.id, targetChecklistId: home))!;

    h.container
      ..listen(checklistTreeProvider(home), (_, _) {})
      ..listen(checklistEditorProvider(home), (_, _) {});
    for (var i = 0; i < 100 && !(h.read(checklistTreeProvider(home))?.contains(created.id) ?? false); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    final editor = h.read(checklistEditorProvider(home).notifier);
    // Moving the mirror under its original (or into its subtree) is refused.
    expect(await editor.moveTo([created.id], parentId: groceries.id), isNull);
    expect(await editor.moveTo([created.id], parentId: milk.id), isNull);
    // Nothing goes under a mirror.
    expect(await editor.addChild(created.id), isNull);
    expect(await editor.moveTo([milk.id], parentId: created.id), isNull);
    final mirror = (await h.read(checklistItemsRepositoryProvider).items(home)).firstWhere((i) => i.isMirror);
    expect(mirror.parentId, isNull);
    expect(today, isNotEmpty);
  });
}
