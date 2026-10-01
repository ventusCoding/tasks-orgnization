import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/session/local_data_wiper.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/sign_out_service.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/fake_sync_server.dart';
import 'support/cloud_sync_harness.dart';

Future<void> _idle(CloudDevice d) async {
  // Let the sync service's start-up run finish.
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final s = d.h.read(syncServiceProvider);
    if (s == null || !s.isRunning) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sign-out (T1.5.07)', () {
    test('unsynced changes block the sign-out until pushed (pending guard)', () async {
      final d = await CloudDevice.create();
      addTearDown(d.dispose);
      await _idle(d);
      await d.addCategory('c1', 'Work');
      d.api.offline = true;

      final blocked = await d.h.read(signOutServiceProvider).signOut();
      expect(blocked.outcome, SignOutOutcome.pendingChanges);
      expect(blocked.pending, 1);
      expect(d.h.read(sessionProvider), isNotNull, reason: 'nothing happened');
      expect(await d.count('categories'), 1);
      expect(d.cleanupLog, isEmpty);

      d.api.offline = false;
      final done = await d.h.read(signOutServiceProvider).signOut();
      expect(done.outcome, SignOutOutcome.signedOut);
      expect(d.server.row('categories', 'c1')!.values['name'], 'Work', reason: 'final push reached the server');
      expect(d.h.read(sessionProvider), isNull);
      expect(d.repo.calls, contains('signOut'));
    });

    test('after sign-out no user data remains on disk (tables, caches, files)', () async {
      final d = await CloudDevice.create();
      addTearDown(d.dispose);
      await _idle(d);
      await d.addCategory('c1', 'Work');
      await d.h.db.customStatement('INSERT INTO ui_view_state(view_id, json, updated_at) VALUES (?, ?, ?)', [
        'v1',
        '{}',
        '2026-09-22T09:00:00.000Z',
      ]);
      await d.h.db.customStatement("INSERT INTO local_kv(key, value) VALUES ('notif_user_id', 'u1')");
      final attachments = Directory('${d.fileRoot.path}/attachments')..createSync(recursive: true);
      File('${attachments.path}/photo.jpg').writeAsStringSync('x');
      final exports = Directory('${d.fileRoot.path}/exports')..createSync();
      File('${exports.path}/everslot.json').writeAsStringSync('{}');
      final deviceId = d.h.read(activeDeviceIdProvider);

      final result = await d.h.read(signOutServiceProvider).signOut(force: true);
      expect(result.outcome, SignOutOutcome.signedOut);

      final left = await d.nonEmptyTables();
      expect(left.keys, ['local_kv'], reason: 'only device-level keys survive: $left');
      final keys = await d.h.db.customSelect('SELECT key FROM local_kv').map((r) => r.data['key']).get();
      expect(keys.toSet().difference(LocalDataWiper.deviceKeys), isEmpty);
      expect(attachments.existsSync(), isFalse);
      expect(exports.existsSync(), isFalse);
      expect(d.h.read(activeDeviceIdProvider), deviceId, reason: 'a normal sign-out keeps the install id');
    });

    test('server/OS cleanups run while the session is still valid', () async {
      final d = await CloudDevice.create();
      addTearDown(d.dispose);
      await _idle(d);
      await d.h.read(signOutServiceProvider).signOut();
      expect(d.cleanupLog, ['push-token-cleared:u1', 'local-notifications-cancelled']);
    });

    test('a failing cleanup never blocks the sign-out', () async {
      final d = await CloudDevice.create();
      addTearDown(d.dispose);
      await _idle(d);
      d.failCleanups = true;
      final result = await d.h.read(signOutServiceProvider).signOut(force: true);
      expect(result.outcome, SignOutOutcome.signedOut);
      expect(d.cleanupLog, ['local-notifications-cancelled'], reason: 'later cleanups still ran');
      expect(d.h.read(sessionProvider), isNull);
    });

    test('a revoked device signs out without the guard and gets a new install id', () async {
      final d = await CloudDevice.create();
      addTearDown(d.dispose);
      await _idle(d);
      final before = d.h.read(activeDeviceIdProvider);
      d.server.revokedDevices.add(before);
      await d.addCategory('c1', 'Work');
      await d.h.read(syncServiceProvider)!.syncNow();
      expect(d.h.read(syncServiceProvider)!.revoked.value, isTrue);
      final result = await d.h.read(signOutServiceProvider).signOut(force: true, rotateDevice: true);
      expect(result.outcome, SignOutOutcome.signedOut);
      expect(d.h.read(activeDeviceIdProvider), isNot(before));
    });
  });

  group('account switch safety (T1.5.08)', () {
    test("another account signing in wipes the previous account's data before any pull", () async {
      final server = FakeSyncServer();
      final d = await CloudDevice.create(server: server, userId: 'alice');
      addTearDown(d.dispose);
      await _idle(d);
      d.api.offline = true;
      await d.addCategory('a1', "Alice's list");
      // Interrupted sign-out: the session vanished but Alice's data and outbox are still here.
      d.h.read(sessionProvider.notifier).set(null);
      expect(await d.count('sync_outbox'), 1);

      final binding = d.h.read(authBindingProvider);
      await binding.bind(const AuthUser(id: 'bob', email: 'bob@x.io'));

      // (Bob's own default rows may already be seeded after his first pull.)
      Future<int> alice(String table) async =>
          (await d.h.db.customSelect("SELECT COUNT(*) AS n FROM $table WHERE user_id = 'alice'").getSingle()).data['n']
              as int;
      expect(await alice('categories'), 0);
      final aliceOutbox = await d.h.db
          .customSelect("SELECT COUNT(*) AS n FROM sync_outbox WHERE row_id = 'a1'")
          .getSingle();
      expect(aliceOutbox.data['n'], 0);
      expect(await LocalDataOwner.read(d.h.db), 'bob');
      expect(d.h.read(sessionProvider)?.userId, 'bob');
      expect(server.pushedBatches.expand((b) => b).where((c) => c['row_id'] == 'a1'), isEmpty);
    });

    test('no cross-user push: the engine refuses to run until the data is bound', () async {
      final server = FakeSyncServer();
      final d = await CloudDevice.create(server: server, userId: 'alice');
      addTearDown(d.dispose);
      await _idle(d);
      d.api.offline = true;
      await d.addCategory('a1', "Alice's list");
      d.api.offline = false;
      final pushesBefore = server.pushCalls;
      // Bob's session appears before the binding re-assigned the data (owner is still alice).
      d.h.read(sessionProvider.notifier).set(const AppSession(userId: 'bob', mode: SessionMode.cloud));
      final service = d.h.read(syncServiceProvider)!;
      await service.syncNow(manual: true);
      expect(server.pushCalls, pushesBefore);
      expect(server.row('categories', 'a1'), isNull);
      expect(service.status.value.phase, isNot(SyncPhase.error));
    });

    test('the backup hook receives the previous owner before the wipe', () async {
      final seen = <String>[];
      final categoriesAtHook = <int>[];
      late CloudDevice d;
      d = await CloudDevice.create(
        userId: 'alice',
        beforeWipe: (previous) async {
          seen.add(previous);
          categoriesAtHook.add(await d.count('categories'));
        },
      );
      addTearDown(d.dispose);
      await _idle(d);
      d.api.offline = true;
      await d.addCategory('a1', 'A');
      await d.h.read(authBindingProvider).bind(const AuthUser(id: 'bob'));
      expect(seen, ['alice']);
      expect(categoriesAtHook.single, greaterThanOrEqualTo(1), reason: 'the hook runs before the wipe');
      final left = await d.h.db.customSelect("SELECT COUNT(*) AS n FROM categories WHERE id = 'a1'").getSingle();
      expect(left.data['n'], 0);
    });

    test('the same account signing in again keeps its local data', () async {
      final d = await CloudDevice.create(userId: 'alice');
      addTearDown(d.dispose);
      await _idle(d);
      d.api.offline = true;
      await d.addCategory('a1', 'A');
      await d.h.read(authBindingProvider).bind(const AuthUser(id: 'alice', email: 'alice@x.io'));
      final kept = await d.h.db.customSelect("SELECT COUNT(*) AS n FROM categories WHERE id = 'a1'").getSingle();
      expect(kept.data['n'], 1);
      final queued = await d.h.db.customSelect("SELECT COUNT(*) AS n FROM sync_outbox WHERE row_id = 'a1'").getSingle();
      expect(queued.data['n'], 1, reason: 'unsynced edits survive a re-sign-in of the same account');
    });

    test('the first sign-in claims local-only data for the account (ADR-017)', () async {
      final server = FakeSyncServer();
      final d = await CloudDevice.create(server: server, userId: 'local-1', bind: false);
      addTearDown(d.dispose);
      // Local-only history: local account + rows + outbox.
      d.h.read(sessionProvider.notifier).set(const AppSession(userId: 'local-1', mode: SessionMode.localOnly));
      await d.h.db.customStatement(
        "INSERT INTO local_kv(key, value) VALUES ('local_user_id', 'local-1') "
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      );
      await d.addCategory('c1', 'Offline list');
      expect(await LocalAccount.current(d.h.db), 'local-1');

      await d.h.read(authBindingProvider).bind(const AuthUser(id: 'cloud-9', email: 'me@x.io'));
      await _idle(d);
      final owner = await d.h.db.customSelect("SELECT user_id FROM categories WHERE id = 'c1'").getSingle();
      expect(owner.data['user_id'], 'cloud-9');
      expect(await LocalDataOwner.read(d.h.db), 'cloud-9');
      await d.h.read(syncServiceProvider)!.syncNow(manual: true);
      expect(server.row('categories', 'c1')!.userId, 'cloud-9');
    });
  });
}
