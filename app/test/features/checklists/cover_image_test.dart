// Checklist cover image (T4.1.17): the chosen cover (`cover_attachment_id`) leads the card; without
// one — or once it is deleted — the first list image, then the first item image, is used.
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  /// "Trip" with items Beach (beach.jpg) and Hotel (hotel.jpg, receipt.pdf).
  Future<({String list, Map<String, String> att})> seed() async {
    final list =
        (await h
                .read(checklistsRepositoryProvider)
                .create(
                  title: 'Trip',
                  items: const [
                    NodeSpec(text: 'Beach'),
                    NodeSpec(text: 'Hotel'),
                  ],
                ))
            .id;
    final items = await h.read(checklistItemsRepositoryProvider).items(list);
    String item(String t) => items.firstWhere((i) => i.text == t).id;
    final att = <String, String>{};
    NewAttachment a(String owner, String name, String mime) {
      final id = Ids.v7();
      att[name] = id;
      return NewAttachment(
        id: id,
        ownerType: AttachmentOwnerType.checklistItem,
        ownerId: owner,
        storagePath: 'user-1/$name',
        fileName: name,
        mimeType: mime,
        byteSize: 1000,
      );
    }

    await h.read(attachmentsRepositoryProvider).insertAll([
      a(item('Beach'), 'beach.jpg', 'image/jpeg'),
      a(item('Hotel'), 'hotel.jpg', 'image/jpeg'),
      a(item('Hotel'), 'receipt.pdf', 'application/pdf'),
    ]);
    return (list: list, att: att);
  }

  Future<String?> thumbOf(String list) async =>
      (await h.read(checklistsRepositoryProvider).watchCardThumbnails([list]).first)[list]?.fileName;

  test('the cover leads the card; a deleted cover falls back to the first image', () async {
    final s = await seed();
    final repo = h.read(checklistsRepositoryProvider);
    expect(await thumbOf(s.list), 'beach.jpg', reason: 'first item image in outline order');

    await repo.update(s.list, coverAttachmentId: s.att['hotel.jpg']);
    expect(await thumbOf(s.list), 'hotel.jpg');

    await h.read(attachmentsRepositoryProvider).remove(s.att['hotel.jpg']!);
    expect(await thumbOf(s.list), 'beach.jpg', reason: 'deleted covers fall back');

    await repo.update(s.list, clearCover: true);
    expect((await repo.byId(s.list))!.coverAttachmentId, isNull);
  });

  testWidgets('Cover image… offers the list images and Automatic', (tester) async {
    late ({String list, Map<String, String> att}) s;
    await tester.runAsync(() async => s = await seed());
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> openCoverSheet() async {
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byTooltip('More')));
      await settle();
      await tester.ensureVisible(find.text('Cover image…'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Cover image…'));
      await settle();
    }

    await pumpInApp(tester, h, ChecklistScreen(checklistId: s.list, preview: true));
    await settle();
    await openCoverSheet();
    expect(find.bySemanticsLabel('receipt.pdf'), findsNothing, reason: 'only images can be covers');
    await tester.tap(find.bySemanticsLabel('hotel.jpg'));
    await settle();
    String? cover;
    await tester.runAsync(
      () async => cover = (await h.read(checklistsRepositoryProvider).byId(s.list))!.coverAttachmentId,
    );
    expect(cover, s.att['hotel.jpg']);

    await openCoverSheet();
    await tester.tap(find.text('Automatic (first image)'));
    await settle();
    await tester.runAsync(
      () async => cover = (await h.read(checklistsRepositoryProvider).byId(s.list))!.coverAttachmentId,
    );
    expect(cover, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
