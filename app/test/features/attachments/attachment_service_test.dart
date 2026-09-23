import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_service.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import 'attachment_domain_test.dart' show jpegBytes, pngBytes;
import 'attachment_test_support.dart';

void main() {
  late TestHarness h;
  late Directory root;
  late Directory sources;
  late AttachmentsRepository repo;
  late AttachmentCacheStore cache;
  late AttachmentFileStore files;
  late FakeImageCodec codec;

  AttachmentUploadQueue queue({FakeRemoteStorage? storage, FakeConnectivity? net}) => AttachmentUploadQueue(
    repository: repo,
    cache: cache,
    files: files,
    storage: storage,
    clock: h.clock,
    connectivity: net ?? FakeConnectivity(),
    userId: () => 'user-1',
  );

  AttachmentService service(AttachmentUploadQueue q, {AttachmentLimits limits = AttachmentLimits.defaults}) =>
      AttachmentService(
        repository: repo,
        cache: cache,
        files: files,
        processor: AttachmentProcessor(files: files, codec: codec),
        queue: q,
        userId: () => 'user-1',
        newId: Ids.v7,
        limits: limits,
      );

  setUp(() async {
    h = TestHarness.create();
    root = await Directory.systemTemp.createTemp('att_root');
    sources = await Directory.systemTemp.createTemp('att_src');
    repo = AttachmentsRepository(h.db, h.read(syncWriterProvider), () => 'user-1');
    cache = AttachmentCacheStore(h.db);
    files = tempFileStore(root);
    codec = FakeImageCodec();
  });

  tearDown(() async {
    await h.dispose();
    await root.delete(recursive: true);
    await sources.delete(recursive: true);
  });

  PickedFileRef pick(String name, List<int> bytes) =>
      PickedFileRef(path: writeSource(sources, name, bytes).path, name: name);

  group('repository', () {
    test('insertAll writes rows + attachment_added events in one operation, ordered', () async {
      final record = await repo.insertAll([
        for (final n in ['a', 'b', 'c'])
          NewAttachment(
            id: 'att-$n',
            ownerType: AttachmentOwnerType.checklistItem,
            ownerId: 'item-1',
            storagePath: 'user-1/att-$n/$n.jpg',
            fileName: '$n.jpg',
            mimeType: 'image/jpeg',
            byteSize: 10,
          ),
      ]);
      final list = await repo.listFor(AttachmentOwnerType.checklistItem, 'item-1');
      expect(list.map((a) => a.fileName), ['a.jpg', 'b.jpg', 'c.jpg']);
      final events = await (h.db.select(h.db.activityEvents)).get();
      expect(events.where((e) => e.eventType == 'attachment_added'), hasLength(3));
      for (final e in events) {
        expect((jsonDecode(e.payload) as Map)['opId'], record.opId);
      }
      final outboxOps = (await h.db.select(h.db.syncOutbox).get()).map((o) => o.opId).toSet();
      expect(outboxOps, {record.opId});
    });

    test('watchFor excludes tombstones; remove is undoable; move reorders', () async {
      await repo.insertAll([
        for (final n in ['a', 'b'])
          NewAttachment(
            id: 'att-$n',
            ownerType: AttachmentOwnerType.task,
            ownerId: 't1',
            storagePath: 'user-1/att-$n/$n',
            fileName: n,
            mimeType: 'application/pdf',
            byteSize: 5,
          ),
      ]);
      final removed = await repo.remove('att-a');
      expect((await repo.listFor(AttachmentOwnerType.task, 't1')).map((a) => a.id), ['att-b']);
      await h.read(syncWriterProvider).revert(removed);
      final both = await repo.listFor(AttachmentOwnerType.task, 't1');
      expect(both.map((a) => a.id), ['att-a', 'att-b']);
      await repo.move('att-a', afterKey: both[1].sortKey);
      expect((await repo.listFor(AttachmentOwnerType.task, 't1')).map((a) => a.id), ['att-b', 'att-a']);
      final stream = repo.watchFor(AttachmentOwnerType.task, 't1');
      expect((await stream.first).length, 2);
    });

    test('AttachmentTx copies rows by reference, re-owns and cascades deletes', () async {
      await repo.insertAll([
        const NewAttachment(
          id: 'att-1',
          ownerType: AttachmentOwnerType.checklistItem,
          ownerId: 'i1',
          storagePath: 'user-1/att-1/x.jpg',
          fileName: 'x.jpg',
          mimeType: 'image/jpeg',
          byteSize: 7,
        ),
      ]);
      final writer = h.read(syncWriterProvider);
      late Map<String, String> copies;
      await writer.run((tx) async {
        copies = await AttachmentTx.copyForOwners(
          tx,
          fromType: AttachmentOwnerType.checklistItem,
          ownerIdMap: {'i1': 'i2'},
        );
      });
      final copy = (await repo.listFor(AttachmentOwnerType.checklistItem, 'i2')).single;
      expect(copy.id, copies['att-1']);
      expect(copy.storagePath, 'user-1/att-1/x.jpg');
      await writer.run(
        (tx) => AttachmentTx.reown(
          tx,
          fromType: AttachmentOwnerType.checklistItem,
          fromId: 'i2',
          toType: AttachmentOwnerType.checklist,
          toId: 'c1',
        ),
      );
      expect(await repo.listFor(AttachmentOwnerType.checklistItem, 'i2'), isEmpty);
      expect(await repo.listFor(AttachmentOwnerType.checklist, 'c1'), hasLength(1));
      await writer.run((tx) => AttachmentTx.softDeleteForOwners(tx, AttachmentOwnerType.checklistItem, ['i1']));
      expect(await repo.listFor(AttachmentOwnerType.checklistItem, 'i1'), isEmpty);
      // Storage used is deduplicated by path: two rows share one object.
      expect(await repo.watchStorageUsedBytes().first, 7);
    });
  });

  group('service (offline / local-only)', () {
    test('adds 5 photos offline: local files, pending cache rows, no remote needed', () async {
      final s = service(queue());
      final result = await s.addFiles(AttachmentOwnerType.checklistItem, 'item-1', [
        for (var i = 0; i < 5; i++) pick('photo$i.jpg', jpegBytes(4000 + i, 3000, orientation: 6)),
      ]);
      expect(result.added, hasLength(5));
      expect(result.rejected, isEmpty);
      final list = await repo.listFor(AttachmentOwnerType.checklistItem, 'item-1');
      expect(list, hasLength(5));
      for (final a in list) {
        expect(a.storagePath, startsWith('user-1/${a.id}/'));
        expect(a.thumbPath, 'user-1/${a.id}/thumb.jpg');
        expect(a.isUploaded, isFalse);
        expect(a.sha256, hasLength(64));
        final row = (await cache.get(a.id))!;
        expect(row.uploadState, 'pending');
        expect(await files.exists(row.localOriginalPath), isTrue);
        expect(await files.exists(row.localThumbPath), isTrue);
      }
      // Compression targets: long edge ≤ 2560, thumbnail ≤ 512.
      expect(codec.calls.where((c) => c.w == 2560), isNotEmpty);
      expect(codec.calls.every((c) => c.w <= 2560 && c.h <= 2560), isTrue);
      expect(codec.calls.where((c) => c.w == 512), hasLength(5));
    });

    test('PNG with alpha stays PNG; HEIC name becomes .jpg', () async {
      final s = service(queue());
      await s.addFiles(AttachmentOwnerType.task, 't', [pick('shot.png', pngBytes(100, 50, colorType: 6))]);
      expect(codec.calls.first.format, ImageOutputFormat.png);
      final a = (await repo.listFor(AttachmentOwnerType.task, 't')).single;
      expect(a.mimeType, 'image/png');
    });

    test('rejects too large, wrong type, duplicates and over-count with reasons', () async {
      final s = service(queue(), limits: const AttachmentLimits(maxBytes: 5000, maxPerOwner: 3));
      final result = await s.addFiles(AttachmentOwnerType.task, 't', [
        pick('big.pdf', List.filled(6000, 1)),
        pick('virus.exe', [0x4D, 0x5A, 1, 2, 3]),
        pick('note.txt', utf8.encode('hello')),
        pick('note-copy.txt', utf8.encode('hello')),
        pick('a.txt', utf8.encode('a')),
        pick('b.txt', utf8.encode('b')),
        pick('c.txt', utf8.encode('c')),
      ]);
      expect(result.rejected['big.pdf'], AttachmentRejection.tooLarge);
      expect(result.rejected['virus.exe'], AttachmentRejection.typeNotAllowed);
      expect(result.rejected['note-copy.txt'], AttachmentRejection.duplicate);
      expect(result.rejected['c.txt'], AttachmentRejection.tooMany);
      expect(result.added, hasLength(3));
    });

    test('local-only queue never uploads and keeps jobs pending', () async {
      final q = queue();
      final s = service(q);
      await s.addFiles(AttachmentOwnerType.task, 't', [pick('a.txt', utf8.encode('a'))]);
      await q.drain();
      expect((await cache.uploadQueue()).single.uploadState, 'pending');
      expect(q.isConfigured, isFalse);
    });
  });

  group('upload queue', () {
    test('uploads original + thumbnail, then marks uploaded (row patch)', () async {
      final storage = FakeRemoteStorage();
      final q = queue(storage: storage);
      final s = service(q);
      await s.addFiles(AttachmentOwnerType.task, 't', [pick('p.jpg', jpegBytes(100, 100))]);
      await q.drain();
      final a = (await repo.listFor(AttachmentOwnerType.task, 't')).single;
      expect(a.isUploaded, isTrue);
      expect(storage.objects.keys, containsAll(['attachments/${a.storagePath}', 'attachments/${a.thumbPath}']));
      expect((await cache.get(a.id))!.uploadState, 'done');
      final auto = await h.db
          .customSelect(
            "SELECT COUNT(*) AS n FROM sync_outbox WHERE table_name = 'attachments' AND fields LIKE ?",
            variables: [Variable<String>('%uploaded_at%')],
          )
          .getSingle();
      expect(auto.read<int>('n'), greaterThan(0));
    });

    test('offline: stays pending; back online: uploads', () async {
      final storage = FakeRemoteStorage();
      final net = FakeConnectivity(NetworkKind.offline);
      final q = queue(storage: storage, net: net);
      final s = service(q);
      await s.addFiles(AttachmentOwnerType.task, 't', [pick('a.txt', utf8.encode('a'))]);
      await q.drain();
      expect(storage.uploads, 0);
      net.kind = NetworkKind.cellular;
      await q.drain();
      expect((await repo.listFor(AttachmentOwnerType.task, 't')).single.isUploaded, isTrue);
    });

    test('failures back off; the retry succeeds without duplicate objects', () async {
      final storage = FakeRemoteStorage()..failNext = 1;
      final q = queue(storage: storage);
      final s = service(q);
      await s.addFiles(AttachmentOwnerType.task, 't', [pick('a.txt', utf8.encode('a'))]);
      await q.drain();
      final id = (await repo.listFor(AttachmentOwnerType.task, 't')).single.id;
      var row = (await cache.get(id))!;
      expect(row.uploadState, 'failed');
      expect(row.uploadAttempts, 1);
      // Not retried before the backoff elapses.
      await q.drain();
      expect(storage.uploads, 1);
      h.clock.advance(const Duration(minutes: 11));
      await q.drain();
      row = (await cache.get(id))!;
      expect(row.uploadState, 'done');
      expect(storage.objects, hasLength(1));
      await q.dispose();
    });

    test('downloader fetches thumbnails/originals on demand and respects the LRU cap', () async {
      final storage = FakeRemoteStorage();
      final q = queue(storage: storage);
      final s = service(q);
      await s.addFiles(AttachmentOwnerType.task, 't', [pick('p.jpg', jpegBytes(100, 100))]);
      await q.drain();
      final a = (await repo.listFor(AttachmentOwnerType.task, 't')).single;
      // Simulate another device: no local files.
      await files.deleteAll(a.id);
      await cache.remove(a.id);
      final downloader = AttachmentDownloader(cache: cache, files: files, storage: storage, clock: h.clock);
      expect(await downloader.ensureThumb(a), isNotNull);
      final original = await downloader.ensureOriginal(a);
      expect(File(original!).existsSync(), isTrue);
      final capped = AttachmentDownloader(cache: cache, files: files, storage: storage, clock: h.clock, capBytes: () async => 1);
      expect(await capped.enforceCap(), [a.id]);
      expect((await cache.get(a.id))!.localOriginalPath, isNull);
    });
  });
}
