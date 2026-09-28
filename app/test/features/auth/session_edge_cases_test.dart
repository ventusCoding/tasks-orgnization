import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cloud_sync_harness.dart';

/// Waits (real time, bounded) until [check] holds.
Future<void> _until(bool Function() check, {String? reason}) async {
  for (var i = 0; i < 200 && !check(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(check(), isTrue, reason: reason);
}

/// Session edge cases (T1.5.14): no data loss when the session expires offline, when the refresh
/// token is dead, or when the device was revoked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CloudDevice d;

  setUp(() async {
    d = await CloudDevice.create();
    d.repo
      ..currentUser = const AuthUser(id: 'u1', email: 'u1@x.io', providers: ['email'])
      ..accounts['u1@x.io'] = 'u1';
    d.h.read(authBindingProvider);
    d.h.read(syncServiceProvider);
    await _until(() => !d.h.read(syncServiceProvider)!.isRunning);
  });

  tearDown(() => d.dispose());

  Set<SessionIssue> issues() => d.h.read(sessionIssuesProvider);

  Future<int> queued(String rowId) async =>
      (await d.h.db.customSelect("SELECT COUNT(*) AS n FROM sync_outbox WHERE row_id = '$rowId'").getSingle()).data['n']
          as int;

  Future<bool> hasCategory(String id) async =>
      (await d.h.db.customSelect("SELECT id FROM categories WHERE id = '$id'").getSingleOrNull()) != null;

  test('session ended while offline: still usable, writes queue, signing in again pushes them', () async {
    d.api.offline = true;
    d.repo.endSession(); // refresh token rejected
    await _until(() => issues().contains(SessionIssue.reauthRequired));
    expect(d.h.read(sessionProvider)?.userId, 'u1', reason: 'no forced sign-out, data kept');

    await d.addCategory('c1', 'Offline work');
    expect(await queued('c1'), 1);

    d.api.offline = false;
    await d.repo.verifyEmailCode('u1@x.io', '123456'); // "Sign in again"
    await _until(() => !issues().contains(SessionIssue.reauthRequired));
    await _until(() => d.server.row('categories', 'c1') != null, reason: 'the queued change is pushed');
    expect(await hasCategory('c1'), isTrue);
    expect(await queued('c1'), 0);
  });

  test('a 401 with a dead refresh token asks to sign in again; the outbox is preserved', () async {
    d.repo.refreshSucceeds = false;
    d.server.queuedPushErrors.add(const SyncApiException(SyncApiException.notAuthenticated, status: 401));
    await d.addCategory('c1', 'Work');
    await d.h.read(syncServiceProvider)!.syncNow(manual: true);
    await _until(() => issues().contains(SessionIssue.reauthRequired));
    expect(d.repo.calls, contains('refresh'));
    expect(await queued('c1'), 1);
    expect(d.h.read(sessionProvider), isNotNull);
  });

  test('a 401 fixed by a silent refresh raises nothing', () async {
    d.server.queuedPushErrors.add(const SyncApiException(SyncApiException.notAuthenticated, status: 401));
    await d.addCategory('c1', 'Work');
    await d.h.read(syncServiceProvider)!.syncNow(manual: true);
    await _until(() => d.repo.calls.contains('refresh'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(issues(), isEmpty);
  });

  test('revoked device: sync stops, the account keeps its data until the user signs out', () async {
    d.server.revokedDevices.add('device-test');
    await d.addCategory('c1', 'Work');
    await d.h.read(syncServiceProvider)!.syncNow(manual: true);
    await _until(() => issues().contains(SessionIssue.deviceRevoked));
    expect(d.h.read(syncServiceProvider)!.revoked.value, isTrue);
    expect(await hasCategory('c1'), isTrue, reason: 'nothing is wiped before the export offer');
    expect(await queued('c1'), 1);
    expect(d.h.read(sessionProvider), isNotNull);
  });
}
