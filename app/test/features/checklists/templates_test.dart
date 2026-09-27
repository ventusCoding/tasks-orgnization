// Templates (T4.5.05): save as template (deep copy, statuses reset, notes kept, attachments by
// reference), new from template (records template_id), and the New-from-template flow.
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/archive_templates_screens.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show render;

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<List<ChecklistItem>> itemsOf(String id) => h.read(checklistItemsRepositoryProvider).items(id);

  Future<String> source() async {
    final id =
        (await h
                .read(checklistsRepositoryProvider)
                .create(
                  title: 'Trip',
                  items: const [
                    NodeSpec(
                      text: 'Documents',
                      note: 'Keep copies',
                      status: ItemStatus.completed,
                      children: [NodeSpec(text: 'Visa', status: ItemStatus.waiting, statusNote: 'embassy')],
                    ),
                    NodeSpec(text: 'Clothes'),
                  ],
                ))
            .id;
    final docs = (await itemsOf(id)).firstWhere((i) => i.text == 'Documents').id;
    await h.read(attachmentsRepositoryProvider).insertAll([
      NewAttachment(
        id: Ids.v7(),
        ownerType: AttachmentOwnerType.checklistItem,
        ownerId: docs,
        storagePath: 'user-1/scan.jpg',
        fileName: 'scan.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1000,
      ),
    ]);
    return id;
  }

  test('save as template: a deep copy with statuses reset, notes kept, attachments by reference', () async {
    final src = await source();
    final repo = h.read(checklistsRepositoryProvider);
    final t = await repo.duplicate(src, title: 'Trip', resetStatuses: true, asTemplate: true);
    final template = (await repo.byId(t.id))!;
    expect(template.isTemplate, isTrue);
    final items = await itemsOf(t.id);
    expect(render(ChecklistTree.build(items)), 'Documents\n  Visa\nClothes');
    expect(items.map((i) => i.status).toSet(), {ItemStatus.todo});
    expect(items.firstWhere((i) => i.text == 'Documents').note, 'Keep copies');
    expect(items.every((i) => i.statusNote == null), isTrue, reason: 'reason notes go with the statuses');

    final copies = await h.read(checklistItemsRepositoryProvider).watchChecklistAttachments(t.id).first;
    expect(copies.single.storagePath, 'user-1/scan.jpg', reason: 'the same stored file, a new row');
    final originals = await h.read(checklistItemsRepositoryProvider).watchChecklistAttachments(src).first;
    expect(copies.single.id, isNot(originals.single.id));

    // Templates live on their own screen, never on the board.
    expect((await repo.watchBoard().first).map((c) => c.id), isNot(contains(t.id)));
    expect((await repo.watchBoard(templates: true).first).map((c) => c.id), [t.id]);
  });

  test('new from template: a normal list that remembers its template', () async {
    final src = await source();
    final repo = h.read(checklistsRepositoryProvider);
    final t = await repo.duplicate(src, title: 'Trip', resetStatuses: true, asTemplate: true);
    final list = await repo.duplicate(t.id, title: 'Trip', resetStatuses: true, fromTemplate: true);
    final created = (await repo.byId(list.id))!;
    expect(created.isTemplate, isFalse);
    expect(created.templateId, t.id);
    expect(render(ChecklistTree.build(await itemsOf(list.id))), 'Documents\n  Visa\nClothes');
    expect((await repo.watchBoard().first).map((c) => c.id), contains(list.id));
  });

  testWidgets('New from template (built-in, pick mode) creates the nested list and opens it', (tester) async {
    await pumpInApp(tester, h, const TemplatesScreen(pickMode: true));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Packing list'));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ChecklistScreen), findsOneWidget);
    late List<Checklist> board;
    late List<ChecklistItem> items;
    await tester.runAsync(() async {
      board = await h.read(checklistsRepositoryProvider).watchBoard().first;
      items = await itemsOf(board.single.id);
    });
    expect(board.single.title, 'Packing list');
    expect(items.any((i) => i.parentId != null), isTrue, reason: 'nesting survives');
    await tester.pumpWidget(const SizedBox());
  });
}
