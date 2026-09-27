// Copy, cut & paste of subtrees (T4.2.17): the internal clipboard keeps structure and statuses,
// pastes at any depth or at the end of the focus root, cut is a move (ids kept) and both work
// across checklists; the system clipboard gets indented Markdown.
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show render;

const _trip = [
  NodeSpec(
    text: 'Documents',
    children: [
      NodeSpec(text: 'Passport'),
      NodeSpec(text: 'Visa', status: ItemStatus.waiting, statusNote: 'embassy'),
    ],
  ),
  NodeSpec(text: 'Clothes'),
];

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<String> create(String title, [List<NodeSpec> items = _trip]) async =>
      (await h.read(checklistsRepositoryProvider).create(title: title, items: items)).id;

  /// Keeps the list's editor and tree alive (as the open screen does) and waits for the tree.
  Future<ChecklistTree> open(String id) async {
    h.container
      ..listen(checklistTreeProvider(id), (_, _) {})
      ..listen(checklistEditorProvider(id), (_, _) {});
    for (var i = 0; i < 200; i++) {
      final t = h.read(checklistTreeProvider(id));
      if (t != null) return t;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('the tree of $id never loaded');
  }

  Future<List<ChecklistItem>> items(String id) => h.read(checklistItemsRepositoryProvider).items(id);

  Future<String> outline(String id, {bool statuses = false}) async =>
      render(ChecklistTree.build(await items(id)), statuses: statuses);

  /// Waits until the tree provider reflects [predicate] (streams deliver asynchronously).
  Future<ChecklistTree> settled(String id, bool Function(ChecklistTree t) predicate) async {
    for (var i = 0; i < 200; i++) {
      final t = h.read(checklistTreeProvider(id));
      if (t != null && predicate(t)) return t;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('the tree of $id never reached the expected state');
  }

  String idOf(ChecklistTree t, String text) => t.order.firstWhere((id) => t[id]!.text == text);

  ChecklistEditor editor(String id) => h.read(checklistEditorProvider(id).notifier);
  ChecklistClipboard clipboard() => h.read(checklistClipboardProvider.notifier);

  test('copy keeps structure and statuses; paste after a nested item lands at its depth', () async {
    final a = await create('Trip');
    final t = await open(a);
    clipboard().copy(t, a, [idOf(t, 'Documents')]);
    await editor(a).paste(h.read(checklistClipboardProvider)!, afterId: idOf(t, 'Visa'));
    await settled(a, (t) => t.length == 7);
    expect(await outline(a, statuses: true), '''
Documents
  Passport
  Visa:waiting
  Documents
    Passport
    Visa:waiting
Clothes''');
    final copy = (await items(a)).where((i) => i.text == 'Visa' && i.statusNote == 'embassy');
    expect(copy, hasLength(2), reason: 'the reason note travels with the status');
    expect(h.read(checklistClipboardProvider), isNotNull, reason: 'a copy can be pasted again');
  });

  test('paste at the top level and at the end of the focus root', () async {
    final a = await create('Trip');
    var t = await open(a);
    clipboard().copy(t, a, [idOf(t, 'Passport')]);
    await editor(a).paste(h.read(checklistClipboardProvider)!, afterId: idOf(t, 'Clothes'));
    t = await settled(a, (t) => t.length == 5);
    expect(await outline(a), 'Documents\n  Passport\n  Visa\nClothes\nPassport');

    // Zoomed into Documents, a paste without an anchor appends to the zoomed item.
    await editor(a).zoomTo(idOf(t, 'Documents'));
    await editor(a).paste(h.read(checklistClipboardProvider)!);
    await settled(a, (t) => t.length == 6);
    expect(await outline(a), 'Documents\n  Passport\n  Visa\n  Passport\nClothes\nPassport');
  });

  test('cut is a move: same rows, new place, clipboard cleared', () async {
    final a = await create('Trip');
    final t = await open(a);
    final visa = idOf(t, 'Visa');
    clipboard().cut(t, a, [visa]);
    await editor(a).paste(h.read(checklistClipboardProvider)!, afterId: idOf(t, 'Clothes'));
    await settled(a, (t) => t.parentOf(visa) == null);
    expect(await outline(a), 'Documents\n  Passport\nClothes\nVisa');
    expect((await items(a)).where((i) => i.id == visa), hasLength(1), reason: 'the id is kept');
    expect(h.read(checklistClipboardProvider), isNull);
  });

  test('across checklists: copy creates new rows, cut moves the originals', () async {
    final a = await create('Trip');
    final b = await create('Weekend', const [NodeSpec(text: 'Tent')]);
    final ta = await open(a);
    final tb = await open(b);

    clipboard().copy(ta, a, [idOf(ta, 'Documents')]);
    await editor(b).paste(h.read(checklistClipboardProvider)!, afterId: idOf(tb, 'Tent'));
    await settled(b, (t) => t.length == 4);
    expect(await outline(b, statuses: true), 'Tent\nDocuments\n  Passport\n  Visa:waiting');
    expect(await outline(a), 'Documents\n  Passport\n  Visa\nClothes', reason: 'the source is unchanged');
    final sourceIds = {for (final i in await items(a)) i.id};
    expect((await items(b)).where((i) => sourceIds.contains(i.id)), isEmpty, reason: 'copies get new ids');

    final clothes = idOf(ta, 'Clothes');
    clipboard().cut(ta, a, [clothes]);
    await editor(b).paste(h.read(checklistClipboardProvider)!);
    await settled(b, (t) => t.contains(clothes));
    expect(await outline(a), 'Documents\n  Passport\n  Visa');
    expect(await outline(b), 'Tent\nDocuments\n  Passport\n  Visa\nClothes');
    expect((await items(b)).firstWhere((i) => i.id == clothes).checklistId, b);
  });

  test('the system clipboard gets indented Markdown with statuses', () async {
    final a = await create('Trip');
    final t = await open(a);
    expect(ChecklistClipboard.asText(t, [idOf(t, 'Documents')]), contains('- [ ] Documents\n  - [ ] Passport\n'));
    expect(ChecklistClipboard.asText(t, [idOf(t, 'Visa')]), contains('Visa'));
  });
}
