// Attachments in exports (T4.4.08): Markdown and OPML list file names under their items; the
// export sheet offers a zip bundle when the list has files.
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show tree;

void main() {
  test('Markdown lists file names under items; OPML carries them as an attribute', () {
    final t = tree('Documents\n  Passport\nClothes');
    const names = {
      'Passport': ['scan.jpg', 'form "A".pdf'],
    };
    final md = ChecklistExport.markdown(t, attachmentNames: names);
    expect(md, contains('  - [ ] Passport\n    📎 scan.jpg\n    📎 form "A".pdf\n'));
    final opml = ChecklistExport.opml(t, attachmentNames: names);
    expect(opml, contains('text="Passport" _attachments="scan.jpg | form &quot;A&quot;.pdf"'));
    // Re-importing the OPML keeps the structure (file names are not items).
    expect(ChecklistImport.parse(opml).count, 3);
  });

  testWidgets('the export sheet offers a zip bundle only when the list has files', (tester) async {
    final h = TestHarness.create();
    addTearDown(h.dispose);
    late String withFiles;
    late String plain;
    await tester.runAsync(() async {
      final repo = h.read(checklistsRepositoryProvider);
      withFiles = (await repo.create(
        title: 'Trip',
        items: const [NodeSpec(text: 'Passport')],
      )).id;
      plain = (await repo.create(
        title: 'Plain',
        items: const [NodeSpec(text: 'Milk')],
      )).id;
      final passport = (await h.read(checklistItemsRepositoryProvider).items(withFiles)).single.id;
      await h.read(attachmentsRepositoryProvider).insertAll([
        NewAttachment(
          id: Ids.v7(),
          ownerType: AttachmentOwnerType.checklistItem,
          ownerId: passport,
          storagePath: 'user-1/scan.jpg',
          fileName: 'scan.jpg',
          mimeType: 'image/jpeg',
          byteSize: 10,
        ),
      ]);
    });
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> openShare(String id) async {
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle();
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byTooltip('More')));
      await settle();
      await tester.ensureVisible(find.text('Share / export'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Share / export'));
      await settle();
    }

    await openShare(withFiles);
    expect(find.text('Share as zip (with files)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle();
    await openShare(plain);
    expect(find.text('Share as zip (with files)'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
