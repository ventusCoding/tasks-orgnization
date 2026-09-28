@Tags(['sync'])
library;

import 'dart:async';

import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/sync/background_sync.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

void main() {
  late FakeSyncServer server;
  late SimDevice fg;
  late SyncService bg;

  setUp(() async {
    server = FakeSyncServer();
    fg = SimDevice(server, userId: 'u1', deviceId: 'A');
    await LocalDataOwner.write(fg.db, 'u1');
    // The background isolate opens the same database file with its own engine and lock owner.
    bg = BackgroundSync.createService(db: fg.db, api: fg.api, userId: 'u1', deviceId: 'A', clock: fg.clock);
  });

  tearDown(() async {
    bg.dispose();
    await fg.dispose();
  });

  Future<void> addCategory(String id) =>
      fg.writer.run((tx) => tx.insert('categories', id, {'name': id, 'color': 1, 'sort_key': 'a0'}));

  test('a background run pushes local changes and pulls remote ones', () async {
    await addCategory('local');
    final other = SimDevice(server, userId: 'u1', deviceId: 'B');
    await other.writer.run((tx) => tx.insert('categories', 'remote', {'name': 'R', 'color': 2, 'sort_key': 'b0'}));
    await other.sync.syncNow();

    expect(await BackgroundSync.runWith(bg), BackgroundSyncOutcome.synced);
    expect(server.row('categories', 'local'), isNotNull);
    expect((await fg.rows('categories', ['name'])).keys, containsAll(['local', 'remote']));
    expect(await fg.outbox(), isEmpty);
    expect(await bg.lock.holder(), isNull, reason: 'the lease is released');
    await other.dispose();
  });

  test('skipped while the foreground engine holds the lock', () async {
    await addCategory('c1');
    expect(await fg.sync.lock.tryAcquire(), isTrue);
    expect(await BackgroundSync.runWith(bg), BackgroundSyncOutcome.skipped);
    expect(server.row('categories', 'c1'), isNull);
    await fg.sync.lock.release();
  });

  test('foreground and background started together push each change exactly once', () async {
    await addCategory('c1');
    await addCategory('c2');
    await Future.wait([fg.sync.syncNow(), BackgroundSync.runWith(bg)]);
    await fg.sync.syncNow();
    expect(server.pushedBatches.expand((b) => b).where((c) => c['row_id'] == 'c1'), hasLength(1));
    expect(await fg.outbox(), isEmpty);
  });

  test('the time budget ends the run; the lease expires so the foreground takes over', () async {
    await addCategory('c1');
    final never = Completer<void>();
    fg.api.beforePull = () => never.future;
    expect(await BackgroundSync.runWith(bg, budget: const Duration(milliseconds: 50)), BackgroundSyncOutcome.timedOut);
    expect(await fg.sync.lock.tryAcquire(), isFalse, reason: 'the killed run still holds its lease');
    fg.clock.advance(const Duration(minutes: 3));
    expect(await fg.sync.lock.tryAcquire(), isTrue);
    await fg.sync.lock.release();
  });

  test('offline: failed, local changes stay queued', () async {
    await addCategory('c1');
    fg.api.offline = true;
    expect(await BackgroundSync.runWith(bg), BackgroundSyncOutcome.failed);
    expect(await fg.outbox(), hasLength(1));
  });
}
