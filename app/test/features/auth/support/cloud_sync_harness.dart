import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/application/sign_out_service.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/sync/support/fake_sync_server.dart';
import '../../../support/test_app.dart';
import 'fake_auth_repository.dart';

/// A signed-in cloud device wired to a [FakeSyncServer] through the real providers
/// (sync service, registrar, sign-out, binding) — plugins replaced by fakes.
class CloudDevice {
  CloudDevice._(this.h, this.server, this.repo, this.fileRoot, this.cleanupLog, this._flags);

  static Future<CloudDevice> create({
    FakeSyncServer? server,
    FakeAuthRepository? repo,
    String userId = 'u1',
    bool bind = true,
    BeforeAccountWipe? beforeWipe,
    List<Override> overrides = const [],
  }) async {
    final s = server ?? FakeSyncServer();
    final r = repo ?? FakeAuthRepository();
    final root = Directory.systemTemp.createTempSync('everslot_wipe_');
    final log = <String>[];
    final flags = _Flags();
    late TestHarness h;
    h = TestHarness.create(
      userId: userId,
      overrides: [
        authRepositoryProvider.overrideWithValue(r),
        accountStartupProvider.overrideWithValue((_) async {}),
        syncApiProvider.overrideWith((ref) => FakeSyncApi(s, ref.watch(currentUserIdProvider))),
        syncOnlineChangesProvider.overrideWithValue(const Stream<bool>.empty()),
        wipeFileRootsProvider.overrideWithValue([root]),
        beforeAccountWipeProvider.overrideWithValue(beforeWipe),
        signOutCleanupsProvider.overrideWithValue([
          () async {
            if (flags.failCleanups) throw const SocketException('offline (fake)');
            log.add('push-token-cleared:${h.read(sessionProvider)?.userId}');
          },
          () async => log.add('local-notifications-cancelled'),
        ]),
        ...overrides,
      ],
    );
    h.read(sessionProvider.notifier).set(AppSession(userId: userId, mode: SessionMode.cloud, email: '$userId@x.io'));
    if (bind) await LocalDataOwner.write(h.db, userId);
    return CloudDevice._(h, s, r, root, log, flags);
  }

  final TestHarness h;
  final FakeSyncServer server;
  final FakeAuthRepository repo;
  final Directory fileRoot;
  final List<String> cleanupLog;
  final _Flags _flags;

  /// The push-token cleanup throws (offline server).
  set failCleanups(bool value) => _flags.failCleanups = value;

  FakeSyncApi get api => h.read(syncApiProvider)! as FakeSyncApi;

  Future<void> addCategory(String id, String name) =>
      h.read(syncWriterProvider).run((tx) => tx.insert('categories', id, {'name': name, 'color': 1, 'sort_key': 'a0'}));

  Future<int> count(String table) async =>
      (await h.db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle()).data['n'] as int;

  /// Row counts of every table with rows (FTS index included).
  Future<Map<String, int>> nonEmptyTables() async {
    final result = <String, int>{};
    for (final t in h.db.allTables) {
      final n = await count(t.actualTableName);
      if (n > 0) result[t.actualTableName] = n;
    }
    final fts = await count('search_index');
    if (fts > 0) result['search_index'] = fts;
    return result;
  }

  Future<void> dispose() async {
    await h.dispose();
    if (fileRoot.existsSync()) fileRoot.deleteSync(recursive: true);
  }
}

class _Flags {
  bool failCleanups = false;
}

/// Registration info of a device, from the fake server.
DeviceRegistration? registeredDevice(FakeSyncServer server, String id) => server.devices[id];
