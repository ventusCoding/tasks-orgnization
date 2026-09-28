// Attachments in export & import bundles (T4.4.08): Markdown lists file names under their items;
// a zip bundle carries the Markdown plus `files/`, and importing it re-attaches the same files to
// the same items through the attachment pipeline.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/application/checklist_bundles.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/bundle.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../attachments/attachment_domain_test.dart' show jpegBytes;
import '../attachments/attachment_test_support.dart';
import 'checklist_test_support.dart' show render;

void main() {
  test('bundle names are safe and reversible', () {
    expect(ChecklistBundle.entryPath(0, 'scan: 1/2.jpg'), 'files/1-scan_ 1_2.jpg');
    expect(ChecklistBundle.originalName('files/12-photo.jpg'), 'photo.jpg');
    expect(ChecklistBundle.textName('Trip / 2026'), 'Trip _ 2026.md');
    expect(ChecklistBundle.textName(''), 'checklist.md');
    expect(ChecklistBundle.isEntryPath('files/1-a.txt'), isTrue);
    expect(ChecklistBundle.isEntryPath('scan.jpg'), isFalse);
  });

  test('the importer keeps 📎 references per item in preorder when asked', () {
    const md = '# Trip\n- [ ] Documents\n  📎 files/1-a.txt\n  - [ ] Passport\n    📎 files/2-b.jpg\n- [ ] Clothes\n';
    final plain = ChecklistImport.parseText(md);
    expect(plain.attachmentRefs, isEmpty);
    expect(plain.warnings, contains(ImportWarning.attachmentsSkipped));
    final kept = ChecklistImport.parseText(md, keepAttachments: true);
    expect(kept.attachmentRefs, [
      ['files/1-a.txt'],
      ['files/2-b.jpg'],
      <String>[],
    ]);
  });

  group('round trip', () {
    late TestHarness h;
    late Directory root;
    late Directory src;
    late Directory scratch;

    setUp(() {
      root = Directory.systemTemp.createTempSync('bundle_root');
      src = Directory.systemTemp.createTempSync('bundle_src');
      scratch = Directory.systemTemp.createTempSync('bundle_scratch');
      h = TestHarness.create(
        overrides: [
          attachmentFileStoreProvider.overrideWithValue(tempFileStore(root)),
          imageCodecProvider.overrideWithValue(FakeImageCodec()),
          connectivityProbeProvider.overrideWithValue(FakeConnectivity(NetworkKind.wifi)),
        ],
      );
    });
    tearDown(() async {
      await h.dispose();
      for (final d in [root, src, scratch]) {
        if (d.existsSync()) d.deleteSync(recursive: true);
      }
    });

    test('export bundle → import → same structure and the same files per item', () async {
      final repo = h.read(checklistsRepositoryProvider);
      final itemsRepo = h.read(checklistItemsRepositoryProvider);
      final id = (await repo.create(
        title: 'Trip',
        items: const [
          NodeSpec(
            text: 'Documents',
            children: [NodeSpec(text: 'Passport')],
          ),
          NodeSpec(text: 'Clothes'),
        ],
      )).id;
      final items = await itemsRepo.items(id);
      String idOf(List<ChecklistItem> list, String text) => list.firstWhere((i) => i.text == text).id;
      final service = h.read(attachmentServiceProvider);
      final added = await service.addFiles(AttachmentOwnerType.checklistItem, idOf(items, 'Passport'), [
        PickedFileRef(path: writeSource(src, 'scan.jpg', jpegBytes(64, 48)).path, name: 'scan.jpg'),
        PickedFileRef(
          path: writeSource(src, 'notes.txt', utf8.encode('visa appointment at 9')).path,
          name: 'notes.txt',
        ),
      ]);
      expect(added.rejected, isEmpty);

      final bytes = await h.read(checklistBundlesProvider).export(id);
      final zip = ZipDecoder().decodeBytes(bytes);
      final md = utf8.decode(zip.findFile('Trip.md')!.content);
      expect(md, contains('📎 files/'));
      expect(zip.files.where((f) => f.name.startsWith('files/')), hasLength(2));

      final newId = await h.read(checklistBundlesProvider).import(bytes, scratch: scratch);
      expect(newId, isNotNull);
      final copy = await itemsRepo.items(newId!);
      expect(render(ChecklistTree.build(copy)), 'Documents\n  Passport\nClothes');
      expect((await repo.byId(newId))!.title, 'Trip');

      final attachments = await itemsRepo.watchChecklistAttachments(newId).first;
      final passport = idOf(copy, 'Passport');
      expect(attachments.map((a) => a.ownerId).toSet(), {passport}, reason: 'the files land on the new Passport');
      expect(attachments.map((a) => a.fileName).toSet(), {'scan.jpg', 'notes.txt'});
      final notes = attachments.firstWhere((a) => a.fileName == 'notes.txt');
      final local = await h.read(attachmentDownloaderProvider).ensureOriginal(notes);
      expect(utf8.decode(File(local!).readAsBytesSync()), 'visa appointment at 9');
    });
  });
}
