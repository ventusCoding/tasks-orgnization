@Tags(['storage'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:everslot/core/errors/app_exception.dart' show NetworkException;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_service.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachment_remote_storage.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tusc/tusc.dart';

import '../test/features/attachments/attachment_test_support.dart';
import '../test/support/test_app.dart';

/// T2.2.10: the attachment pipeline against a real local Supabase Storage (`supabase start`).
///
/// Run: `cd app && SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… SUPABASE_SECRET_KEY=… fvm flutter test test_storage`
/// (values from `supabase status -o env`; CI: `.github/workflows/backend.yml` › storage). Not part of
/// `flutter test` (other directory): it needs the stack and creates throwaway users.
void main() {
  final env = Platform.environment;
  final url = env['SUPABASE_URL'] ?? env['API_URL'] ?? '';
  final publishable = env['SUPABASE_PUBLISHABLE_KEY'] ?? env['PUBLISHABLE_KEY'] ?? '';
  final secret = env['SUPABASE_SECRET_KEY'] ?? env['SECRET_KEY'] ?? '';
  const bucket = 'attachments';

  late SupabaseClient admin;
  final clients = <SupabaseClient>[];
  final users = <String>[];

  setUpAll(() {
    if (url.isEmpty || publishable.isEmpty || secret.isEmpty) {
      fail('Set SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and SUPABASE_SECRET_KEY (supabase status -o env).');
    }
    admin = SupabaseClient(url, secret, authOptions: const AuthClientOptions(autoRefreshToken: false));
  });

  tearDownAll(() async {
    for (final c in clients) {
      await c.dispose();
    }
    for (final id in users) {
      // Objects first: Storage keeps owners' files otherwise.
      final files = await admin.storage.from(bucket).list(path: id);
      for (final folder in files) {
        final inner = await admin.storage.from(bucket).list(path: '$id/${folder.name}');
        await admin.storage.from(bucket).remove([for (final f in inner) '$id/${folder.name}/${f.name}']);
      }
      await admin.auth.admin.deleteUser(id);
    }
    await admin.dispose();
  });

  /// A new confirmed user; returns its id and password.
  Future<({String id, String email, String password})> newUser() async {
    final email = 'storage-${Ids.v7()}@example.test';
    const password = 'Storage-test-1!';
    final res = await admin.auth.admin.createUser(
      AdminUserAttributes(email: email, password: password, emailConfirm: true),
    );
    users.add(res.user!.id);
    return (id: res.user!.id, email: email, password: password);
  }

  /// A signed-in session ("device") of [user].
  Future<SupabaseClient> device(({String id, String email, String password}) user) async {
    final client = SupabaseClient(url, publishable, authOptions: const AuthClientOptions(autoRefreshToken: false));
    clients.add(client);
    await client.auth.signInWithPassword(email: user.email, password: user.password);
    return client;
  }

  File tempFile(String name, Uint8List bytes) {
    final dir = Directory.systemTemp.createTempSync('storage_it');
    addTearDown(() => dir.deleteSync(recursive: true));
    return File('${dir.path}/$name')..writeAsBytesSync(bytes);
  }

  Uint8List bytesOf(int length, {int seed = 1}) {
    final r = math.Random(seed);
    return Uint8List.fromList([for (var i = 0; i < length; i++) 0x61 + r.nextInt(26)]);
  }

  test('standard upload; a second device of the same user downloads it; retries overwrite', () async {
    final user = await newUser();
    final phone = SupabaseAttachmentStorage(await device(user), supabaseUrl: url);
    final tablet = SupabaseAttachmentStorage(await device(user), supabaseUrl: url);
    final path = AttachmentPaths.original(user.id, Ids.v7(), 'note.txt');
    final content = bytesOf(2048);

    final progress = <int>[];
    await phone.upload(
      bucket: bucket,
      path: path,
      file: tempFile('note.txt', content),
      mimeType: 'text/plain',
      onProgress: (sent, _) => progress.add(sent),
    );
    expect(progress.last, content.length);
    expect(await tablet.download(bucket: bucket, path: path), content);

    // A retry of the same path replaces the object (no duplicate, no error).
    final second = bytesOf(1024, seed: 2);
    await phone.upload(bucket: bucket, path: path, file: tempFile('note.txt', second), mimeType: 'text/plain');
    expect(await tablet.download(bucket: bucket, path: path), second);
    final folder = await admin.storage.from(bucket).list(path: path.substring(0, path.lastIndexOf('/')));
    expect(folder.map((f) => f.name), ['note.txt']);
  });

  test("another user can neither read nor write under someone else's folder", () async {
    final alice = await newUser();
    final bob = await newUser();
    final aliceStorage = SupabaseAttachmentStorage(await device(alice), supabaseUrl: url);
    final bobStorage = SupabaseAttachmentStorage(await device(bob), supabaseUrl: url);
    final path = AttachmentPaths.original(alice.id, Ids.v7(), 'secret.txt');
    await aliceStorage.upload(bucket: bucket, path: path, file: tempFile('s.txt', bytesOf(64)), mimeType: 'text/plain');

    await expectLater(bobStorage.download(bucket: bucket, path: path), throwsA(isA<NetworkException>()));
    await expectLater(
      bobStorage.upload(bucket: bucket, path: path, file: tempFile('x.txt', bytesOf(8)), mimeType: 'text/plain'),
      throwsA(isA<NetworkException>()),
      reason: "overwrite of another user's object",
    );
    expect(
      await aliceStorage.download(bucket: bucket, path: path),
      hasLength(64),
      reason: 'unchanged',
    );
  });

  test("path prefix: objects and attachment rows must live under the caller's uid", () async {
    final alice = await newUser();
    final bob = await newUser();
    final client = await device(alice);
    final storage = SupabaseAttachmentStorage(client, supabaseUrl: url);

    await expectLater(
      storage.upload(
        bucket: bucket,
        path: AttachmentPaths.original(bob.id, Ids.v7(), 'f.txt'),
        file: tempFile('f.txt', bytesOf(8)),
        mimeType: 'text/plain',
      ),
      throwsA(isA<NetworkException>()),
    );
    await expectLater(
      storage.upload(bucket: bucket, path: 'f.txt', file: tempFile('f.txt', bytesOf(8)), mimeType: 'text/plain'),
      throwsA(isA<NetworkException>()),
      reason: 'no user folder at all',
    );

    // The row-level trigger (DL007) rejects a storage_path outside the owner's folder.
    final id = Ids.v7();
    await expectLater(
      client.schema('app').from('attachments').insert({
        'id': id,
        'owner_type': 'task',
        'owner_id': Ids.v7(),
        'storage_path': '${bob.id}/$id/f.txt',
        'file_name': 'f.txt',
        'mime_type': 'text/plain',
        'byte_size': 8,
        'sort_key': 'a0',
      }),
      throwsA(isA<PostgrestException>().having((e) => e.code, 'code', 'DL007')),
    );
  });

  test('bucket limits: disallowed MIME types are refused by Storage', () async {
    final user = await newUser();
    final storage = SupabaseAttachmentStorage(await device(user), supabaseUrl: url);
    await expectLater(
      storage.upload(
        bucket: bucket,
        path: AttachmentPaths.original(user.id, Ids.v7(), 'app.exe'),
        file: tempFile('app.exe', bytesOf(16)),
        mimeType: 'application/x-msdownload',
      ),
      throwsA(isA<NetworkException>()),
    );
  });

  test('short videos may exceed 25 MB (bucket limit 50 MB, T2.2.12)', () async {
    final user = await newUser();
    final storage = SupabaseAttachmentStorage(await device(user), supabaseUrl: url);
    final path = AttachmentPaths.original(user.id, Ids.v7(), 'clip.mp4');
    final clip = bytesOf(30 * 1024 * 1024, seed: 5);
    await storage.upload(bucket: bucket, path: path, file: tempFile('clip.mp4', clip), mimeType: 'video/mp4');
    expect(await storage.download(bucket: bucket, path: path), hasLength(clip.length));
    await expectLater(
      storage.upload(
        bucket: bucket,
        path: AttachmentPaths.original(user.id, Ids.v7(), 'huge.mp4'),
        file: tempFile('huge.mp4', bytesOf(51 * 1024 * 1024, seed: 6)),
        mimeType: 'video/mp4',
      ),
      throwsA(isA<NetworkException>()),
      reason: 'above the bucket limit',
    );
  });

  test('large files use resumable (TUS) uploads; an interrupted upload resumes from its offset', () async {
    final user = await newUser();
    final client = await device(user);
    final storage = SupabaseAttachmentStorage(client, supabaseUrl: url);
    final path = AttachmentPaths.original(user.id, Ids.v7(), 'big.txt');
    final content = bytesOf(AttachmentLimits.resumableThreshold + 1024 * 1024, seed: 3); // 7 MB, 2 chunks
    final file = tempFile('big.txt', content);

    // First attempt: stopped after the first chunk (as when the app is killed or goes offline).
    final first = TusClient(
      file: XFile(file.path),
      url: SupabaseAttachmentStorage.resumableEndpoint(url),
      chunkSize: AttachmentLimits.tusChunkSize,
      headers: {'authorization': 'Bearer ${client.auth.currentSession!.accessToken}', 'x-upsert': 'true'},
      metadata: {'bucketName': bucket, 'objectName': path, 'contentType': 'text/plain', 'cacheControl': '3600'},
    );
    await first.startUpload(
      onProgress: (count, total, _) {
        if (count >= AttachmentLimits.tusChunkSize) unawaited(first.pauseUpload());
      },
    );
    expect(first.offset, AttachmentLimits.tusChunkSize);
    final resumeUrl = first.uploadUrl;
    expect(resumeUrl, isNotEmpty);

    // The queue persists the URL and resumes with it: only the remaining bytes are sent.
    final sent = <int>[];
    await storage.upload(
      bucket: bucket,
      path: path,
      file: file,
      mimeType: 'text/plain',
      resumeUrl: resumeUrl,
      onProgress: (count, _) => sent.add(count),
    );
    expect(sent.where((c) => c > 0).first, greaterThanOrEqualTo(AttachmentLimits.tusChunkSize));
    expect(await storage.download(bucket: bucket, path: path), content);
  });

  test('upload queue + downloader end to end: row marked uploaded, other device downloads', () async {
    final user = await newUser();
    final h = TestHarness.create(userId: user.id);
    final root = Directory.systemTemp.createTempSync('att_root');
    final otherRoot = Directory.systemTemp.createTempSync('att_other');
    addTearDown(() async {
      await h.dispose();
      root.deleteSync(recursive: true);
      otherRoot.deleteSync(recursive: true);
    });
    final repo = AttachmentsRepository(h.db, h.read(syncWriterProvider), () => user.id);
    final cache = AttachmentCacheStore(h.db);
    final files = tempFileStore(root);
    final net = FakeConnectivity(NetworkKind.offline);
    final queue = AttachmentUploadQueue(
      repository: repo,
      cache: cache,
      files: files,
      storage: SupabaseAttachmentStorage(await device(user), supabaseUrl: url),
      clock: h.clock,
      connectivity: net,
      userId: () => user.id,
    );
    addTearDown(queue.dispose);
    final service = AttachmentService(
      repository: repo,
      cache: cache,
      files: files,
      processor: AttachmentProcessor(files: files, codec: FakeImageCodec()),
      queue: queue,
      userId: () => user.id,
      newId: Ids.v7,
    );
    final content = bytesOf(4096, seed: 4);
    final source = tempFile('report.txt', content);
    await service.addFiles(AttachmentOwnerType.task, 'task-1', [PickedFileRef(path: source.path, name: 'report.txt')]);
    final added = (await repo.listFor(AttachmentOwnerType.task, 'task-1')).single;

    // Offline: nothing leaves the device.
    await queue.drain();
    expect((await repo.byId(added.id))!.isUploaded, isFalse);
    expect(UploadState.parse((await cache.get(added.id))!.uploadState), UploadState.pending);

    net.set(NetworkKind.wifi);
    await queue.drain();
    final uploaded = (await repo.byId(added.id))!;
    expect(uploaded.isUploaded, isTrue);
    expect(uploaded.storagePath, startsWith('${user.id}/${added.id}/'));
    expect(UploadState.parse((await cache.get(added.id))!.uploadState), UploadState.done);

    // Another device of the same user (own cache) downloads the original on open.
    final other = TestHarness.create(userId: user.id);
    addTearDown(other.dispose);
    final otherCache = AttachmentCacheStore(other.db);
    final downloader = AttachmentDownloader(
      cache: otherCache,
      files: tempFileStore(otherRoot),
      storage: SupabaseAttachmentStorage(await device(user), supabaseUrl: url),
      clock: other.clock,
    );
    await otherCache.putLocal(uploaded.id, originalRel: null, thumbRel: null, bytes: 0, uploadState: UploadState.done);
    final local = await downloader.ensureOriginal(uploaded);
    expect(File(local!).readAsBytesSync(), content);
  });
}
