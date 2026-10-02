import 'dart:io';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/attachment_previews.dart';
import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import 'attachment_domain_test.dart' show pngBytes;
import 'attachment_test_support.dart';

/// Rich notifications pick the owner's first image already cached on the device (T7.2.26).
void main() {
  late Directory root;
  late Directory sources;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('prev_root');
    sources = await Directory.systemTemp.createTemp('prev_src');
  });
  tearDown(() async {
    await root.delete(recursive: true);
    await sources.delete(recursive: true);
  });

  test('first cached image of the owner; documents skipped; nothing when the files are gone', () async {
    final files = tempFileStore(root);
    final h = TestHarness.create(overrides: [attachmentFileStoreProvider.overrideWithValue(files)]);
    addTearDown(h.dispose);
    final repo = AttachmentsRepository(h.db, h.read(syncWriterProvider), () => 'user-1');
    final cache = AttachmentCacheStore(h.db);
    final service = AttachmentService(
      repository: repo,
      cache: cache,
      files: files,
      processor: AttachmentProcessor(files: files, codec: FakeImageCodec()),
      queue: AttachmentUploadQueue(
        repository: repo,
        cache: cache,
        files: files,
        storage: null,
        clock: h.clock,
        connectivity: FakeConnectivity(),
        userId: () => 'user-1',
      ),
      userId: () => 'user-1',
      newId: Ids.v7,
      limits: AttachmentLimits.defaults,
    );
    PickedFileRef pick(String name, List<int> bytes) =>
        PickedFileRef(path: writeSource(sources, name, bytes).path, name: name);
    await service.addFiles('checklist_item', 'i1', [
      pick('notes.txt', 'hello'.codeUnits),
      pick('photo.png', pngBytes(64, 48)),
    ]);

    final previews = h.read(attachmentPreviewsProvider);
    final path = await previews.cachedImage('checklist_item', 'i1');
    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    expect(await previews.cachedImage('checklist_item', 'other'), isNull);

    await root.delete(recursive: true);
    await root.create();
    expect(await previews.cachedImage('checklist_item', 'i1'), isNull, reason: 'never downloads');
  });
}
