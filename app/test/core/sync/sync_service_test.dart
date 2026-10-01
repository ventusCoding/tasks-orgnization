import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_lock.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

Future<void> _addCategory(SimDevice d, String id, String name, {int color = 1}) =>
    d.writer.run((tx) => tx.insert('categories', id, {'name': name, 'color': color, 'sort_key': 'a0'}));

void main() {
  late FakeSyncServer server;
  final devices = <SimDevice>[];

  SimDevice device(String id, {String user = 'u1', int batchSize = 500, int pageSize = 1000}) {
    final d = SimDevice(server, userId: user, deviceId: id, batchSize: batchSize, pageSize: pageSize);
    devices.add(d);
    return d;
  }

  setUp(() => server = FakeSyncServer());
  tearDown(() async {
    for (final d in devices) {
      await d.dispose();
    }
    devices.clear();
  });

  group('push', () {
    test('applied entries leave the outbox and reach the server', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      await a.sync.syncNow();
      expect(await a.outbox(), isEmpty);
      expect(server.row('categories', 'c1')!.values['name'], 'Work');
      expect(server.row('categories', 'c1')!.values['origin_device_id'], 'A');
      expect(a.sync.status.value.phase, SyncPhase.idle);
      expect(a.sync.status.value.lastSuccessAt, isNotNull);
    });

    test('network loss mid-push retries without duplicates (idempotent replay)', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      a.api.dropNextPushResponse = true;
      await a.sync.syncNow();
      expect(a.sync.status.value.phase, SyncPhase.offline);
      final pending = await a.outbox();
      expect(pending, hasLength(1));
      expect(pending.single.state, 'pending');
      final headAfterFirst = server.head('u1');
      await a.sync.syncNow();
      expect(await a.outbox(), isEmpty);
      // The replay was a no-op on the server, only the pull happened.
      expect(server.head('u1'), headAfterFirst);
    });

    test('rejected changes are marked failed with the server code; others still apply', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      // A change for a table the server doesn't know (client bug) → rejected → failed.
      await a.db.customStatement(
        'INSERT INTO sync_outbox (change_id, op_id, table_name, row_id, op, fields, clock, enqueued_at) '
        "VALUES ('bad', 'g-bad', 'nope', 'r1', 'patch', '{\"x\":1}', '{\"x\":\"000000000000001:00000:A\"}', '2026-09-22T09:00:00.000Z')",
      );
      await a.sync.syncNow();
      final outbox = await a.outbox();
      expect(outbox, hasLength(1));
      expect(outbox.single.state, 'failed');
      expect(outbox.single.lastError, startsWith('unknown_table'));
      expect(server.row('categories', 'c1'), isNotNull);
      expect(a.sync.status.value.failedChanges, 1);
      expect(a.sync.status.value.pendingChanges, 0);
    });

    test('operation groups are never split across pushes', () async {
      final a = device('A', batchSize: 5);
      // One group of 8 rows + 3 single-row groups.
      final big = await a.writer.run((tx) async {
        for (var i = 0; i < 8; i++) {
          await tx.insert('categories', 'g$i', {'name': 'G$i', 'color': 1, 'sort_key': 'a$i'});
        }
      });
      for (var i = 0; i < 3; i++) {
        await _addCategory(a, 's$i', 'S$i');
      }
      await a.sync.syncNow();
      expect(await a.outbox(), isEmpty);
      final containing = server.pushedBatches.where((b) => b.any((c) => c['g'] == big.opId)).toList();
      expect(containing, hasLength(1), reason: 'the 8-row group travels in exactly one call');
      expect(containing.single.where((c) => c['g'] == big.opId), hasLength(8));
      expect(server.pushedBatches, hasLength(2));
      expect(server.pushedBatches.last, hasLength(3));
    });

    test('too_many_changes halves the batch size and retries', () async {
      final a = device('A', batchSize: 8);
      for (var i = 0; i < 8; i++) {
        await a.writer.run((tx) async {
          await tx.insert('categories', 'c$i', {'name': 'C$i', 'color': 1, 'sort_key': 'a$i'});
          await tx.logEvent(entityType: 'category', entityId: 'c$i', eventType: 'created');
        });
      }
      server.maxChanges = 4;
      await a.sync.syncNow();
      expect(a.sync.currentBatchSize, 4);
      expect(await a.outbox(), isEmpty);
      expect(server.snapshot('u1', 'categories'), hasLength(8));
    });

    test('a single group larger than the server limit is parked as failed', () async {
      final a = device('A');
      await a.writer.run((tx) async {
        for (var i = 0; i < 6; i++) {
          await tx.insert('categories', 'c$i', {'name': 'C$i', 'color': 1, 'sort_key': 'a$i'});
        }
      });
      server.maxChanges = 4;
      await a.sync.syncNow();
      final outbox = await a.outbox();
      expect(outbox, hasLength(6));
      expect(outbox.every((o) => o.state == 'failed'), isTrue);
      expect(outbox.first.lastError, startsWith('too_many_changes'));
    });

    test('invalid_request marks the batch failed', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      server.queuedPushErrors.add(const SyncApiException(SyncApiException.invalidRequest, status: 400));
      await a.sync.syncNow();
      final outbox = await a.outbox();
      expect(outbox.single.state, 'failed');
      expect(outbox.single.lastError, startsWith('invalid_request'));
    });

    test('unsupported_client keeps the outbox and stops auto-retry until a manual sync', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      server.minSupportedBuild = 99;
      await a.sync.syncNow();
      expect(a.sync.status.value.phase, SyncPhase.error);
      expect(a.sync.status.value.errorCode, SyncErrorCodes.unsupportedClient);
      final outbox = await a.outbox();
      expect(outbox.single.state, 'pending');
      final calls = server.pushCalls;
      await a.sync.syncNow(); // automatic trigger → ignored
      expect(server.pushCalls, calls);
      server.minSupportedBuild = 0;
      await a.sync.syncNow(manual: true);
      expect(await a.outbox(), isEmpty);
      expect(a.sync.status.value.errorCode, isNull);
    });

    test('device_revoked exposes the revoked flag and stops syncing', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      server.revokedDevices.add('A');
      var notified = false;
      a.sync.revoked.addListener(() => notified = true);
      await a.sync.syncNow();
      expect(a.sync.revoked.value, isTrue);
      expect(notified, isTrue);
      expect(a.sync.status.value.errorCode, SyncErrorCodes.deviceRevoked);
      expect((await a.outbox()).single.state, 'pending');
      final calls = server.pushCalls;
      await a.sync.syncNow(manual: true);
      expect(server.pushCalls, calls);
    });

    test('offline keeps entries pending and reports the offline phase', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'Work');
      a.api.offline = true;
      await a.sync.syncNow();
      expect(a.sync.status.value.phase, SyncPhase.offline);
      expect((await a.outbox()).single.state, 'pending');
      expect(a.sync.status.value.pendingChanges, 1);
    });

    test('integrity_refetch rejects the whole group, refetches rows and deletes missing ones', () async {
      final a = device('A');
      await _addCategory(a, 'keep', 'Keep');
      await a.sync.syncNow();
      // Group: rename existing row + insert a new row that violates integrity.
      server.integrityCheck = (s, user, table, id) => id == 'bad' ? 'DL001 parent in another checklist' : null;
      await a.writer.run((tx) async {
        await tx.update('categories', 'keep', {'name': 'Renamed'});
        await tx.insert('categories', 'bad', {'name': 'Bad', 'color': 1, 'sort_key': 'b0'});
      });
      await a.sync.syncNow();
      expect(await a.outbox(), isEmpty);
      final rows = await a.rows('categories', ['name']);
      // The server copy wins for the existing row; the rejected insert is gone locally.
      expect(rows['keep']!['name'], 'Keep');
      expect(rows.containsKey('bad'), isFalse);
      expect(server.row('categories', 'bad'), isNull);
    });

    test('stale fields are recorded in the conflict log', () async {
      final a = device('A');
      final b = device('B');
      await _addCategory(a, 'c1', 'Work');
      await a.sync.syncNow();
      await b.sync.syncNow();
      // B edits first (older clock) but pushes last.
      await b.writer.run((tx) => tx.update('categories', 'c1', {'name': 'From B'}));
      a.clock.advance(const Duration(seconds: 5));
      await a.writer.run((tx) => tx.update('categories', 'c1', {'name': 'From A'}));
      await a.sync.syncNow();
      await b.sync.syncNow();
      final log = await b.sync.conflictLog();
      expect(log, hasLength(1));
      expect(log.single.table, 'categories');
      expect(log.single.fields, contains('name'));
      expect((await b.rows('categories', ['name']))['c1']!['name'], 'From A');
    });
  });

  group('pull', () {
    test('rows from another device are applied; cursor = server revision', () async {
      final a = device('A');
      final b = device('B');
      await _addCategory(a, 'c1', 'Work');
      await a.sync.syncNow();
      await b.sync.syncNow();
      expect((await b.rows('categories', ['name']))['c1']!['name'], 'Work');
      final state = await b.sync.loadState();
      expect(state!.cursor, server.head('u1'));
    });

    test('a pull never overwrites a field with a pending local patch', () async {
      final a = device('A');
      final b = device('B');
      await _addCategory(a, 'c1', 'Work', color: 1);
      await a.sync.syncNow();
      await b.sync.syncNow();
      await a.writer.run((tx) => tx.update('categories', 'c1', {'name': 'A name', 'color': 7}));
      await a.sync.syncNow();
      // The user edits the name on B while B's pull is running.
      b.api.beforePull = () async {
        b.clock.advance(const Duration(seconds: 1));
        await b.writer.run((tx) => tx.update('categories', 'c1', {'name': 'B name'}));
      };
      await b.sync.syncNow();
      final rows = await b.rows('categories', ['name', 'color']);
      expect(rows['c1']!['name'], 'B name', reason: 'pending field kept');
      expect(rows['c1']!['color'], 7, reason: 'other fields take the server value');
      expect((await b.outbox()).single.state, 'pending');
      // The next run pushes B's newer edit, which wins by HLC.
      await b.sync.syncNow();
      expect(server.row('categories', 'c1')!.values['name'], 'B name');
      expect(server.row('categories', 'c1')!.values['color'], 7);
    });

    test('tombstones propagate', () async {
      final a = device('A');
      final b = device('B');
      await _addCategory(a, 'c1', 'Work');
      await a.sync.syncNow();
      await b.sync.syncNow();
      await a.writer.run((tx) => tx.softDelete('categories', 'c1'));
      await a.sync.syncNow();
      await b.sync.syncNow();
      final row = await b.db.customSelect("SELECT deleted_at FROM categories WHERE id = 'c1'").getSingle();
      expect(row.data['deleted_at'], isNotNull);
    });

    test('unknown tables are skipped (forward compatibility)', () async {
      final b = device('B');
      server.tables['future_table'] = {
        'x1': FakeServerRow(
          userId: 'u1',
          values: {'a': 1},
          fieldClock: {},
          rev: 1,
          serverUpdatedAt: '2026-09-22T09:00:00Z',
        ),
      };
      server.heads['u1'] = 1;
      await b.sync.syncNow();
      expect(b.sync.status.value.phase, SyncPhase.idle);
      expect((await b.sync.loadState())!.cursor, 1);
    });

    test('a crash between pages resumes from the saved cursor without duplicates', () async {
      final a = device('A');
      for (var i = 0; i < 5; i++) {
        await _addCategory(a, 'c$i', 'C$i');
      }
      await a.sync.syncNow();
      final b = device('B', pageSize: 2);
      b.api.failPullAfter = 1;
      await b.sync.syncNow();
      expect(b.sync.status.value.phase, SyncPhase.offline);
      final cursor = (await b.sync.loadState())!.cursor;
      expect(cursor, 2);
      expect(await b.rows('categories', ['name']), hasLength(2));
      b.api.failPullAfter = null;
      await b.sync.syncNow();
      expect(await b.rows('categories', ['name']), hasLength(5));
      expect((await b.sync.loadState())!.cursor, server.head('u1'));
    });

    test('HLC observes pulled clocks and persists them for the next start', () async {
      final a = device('A');
      a.clock.advance(const Duration(minutes: 3)); // A's clock runs ahead
      await _addCategory(a, 'c1', 'Work');
      await a.sync.syncNow();
      final b = device('B');
      await b.sync.syncNow();
      final remote = server.row('categories', 'c1')!.fieldClock['name']!;
      expect(b.hlc.state.compareTo(remote), greaterThanOrEqualTo(0));
      final kv = await b.db.customSelect("SELECT value FROM local_kv WHERE key = 'hlc_state'").getSingle();
      expect(kv.data['value'], b.hlc.state);
      // A later local edit on B beats A's earlier edit despite B's slower clock.
      await b.writer.run((tx) => tx.update('categories', 'c1', {'name': 'B later'}));
      await b.sync.syncNow();
      expect(server.row('categories', 'c1')!.values['name'], 'B later');
    });

    test('purge watermark above the cursor forces a full resync that drops purged rows', () async {
      final a = device('A');
      final b = device('B');
      await _addCategory(a, 'c1', 'One');
      await _addCategory(a, 'c2', 'Two');
      await a.sync.syncNow();
      await b.sync.syncNow();
      await a.writer.run((tx) => tx.softDelete('categories', 'c2'));
      await a.sync.syncNow();
      // B was offline; the server purges c2's tombstone and moves the watermark.
      server.purgeTombstones('u1', DateTime.utc(2100));
      await _addCategory(a, 'c3', 'Three');
      await a.sync.syncNow();
      await b.sync.syncNow();
      final rows = await b.rows('categories', ['name']);
      expect(rows.keys.toSet(), {'c1', 'c3'});
    });

    test('last success older than the tombstone retention forces a full resync', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'One');
      await _addCategory(a, 'c2', 'Two');
      await a.sync.syncNow();
      // c2 disappears server-side without a watermark (only a full resync notices).
      server.tables['categories']!.remove('c2');
      a.clock.advance(const Duration(days: 30));
      server.now = server.now.add(const Duration(days: 30));
      await a.sync.syncNow();
      expect((await a.rows('categories', ['name'])).keys, containsAll(<String>['c1', 'c2']));
      // lastSuccessAt is refreshed after every successful run (it used to be set only once).
      final state = await a.sync.loadState();
      expect(state!.lastSuccessAt!.isAtSameMomentAs(a.clock.nowUtc()), isTrue);
      a.clock.advance(const Duration(days: 91));
      server.now = server.now.add(const Duration(days: 91));
      await a.sync.syncNow();
      expect((await a.rows('categories', ['name'])).keys, ['c1']);
    });

    test('Force full resync keeps unsynced local edits', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'One');
      await _addCategory(a, 'c2', 'Two');
      await a.sync.syncNow();
      a.api.beforePull = () async {
        a.clock.advance(const Duration(seconds: 1));
        await a.writer.run((tx) => tx.update('categories', 'c1', {'name': 'Local edit'}));
      };
      await a.sync.resync();
      final rows = await a.rows('categories', ['name']);
      expect(rows['c1']!['name'], 'Local edit');
      expect(rows['c2']!['name'], 'Two');
      await a.sync.syncNow();
      expect(server.row('categories', 'c1')!.values['name'], 'Local edit');
    });
  });

  group('failed entries (diagnostics)', () {
    test('retryFailed re-queues; discardFailed drops and realigns rows with the server', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'One');
      await a.sync.syncNow();
      await a.writer.run((tx) => tx.update('categories', 'c1', {'name': 'Local'}));
      server.queuedPushErrors.add(const SyncApiException(SyncApiException.invalidRequest));
      await a.sync.syncNow();
      expect((await a.outbox()).single.state, 'failed');
      await a.sync.retryFailed();
      expect((await a.outbox()).single.state, 'pending');
      server.queuedPushErrors.add(const SyncApiException(SyncApiException.invalidRequest));
      await a.sync.syncNow();
      await a.sync.discardFailed();
      expect(await a.outbox(), isEmpty);
      expect((await a.rows('categories', ['name']))['c1']!['name'], 'One');
    });
  });

  group('single flight & reruns', () {
    test('a trigger during a run schedules exactly one more run', () async {
      final a = device('A');
      await _addCategory(a, 'c1', 'One');
      final first = a.sync.syncNow();
      final second = a.sync.syncNow();
      await first;
      await second;
      // The rerun is scheduled on a zero timer.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _waitIdle(a);
      expect(server.pullCalls, greaterThanOrEqualTo(2));
    });

    test('guard=false skips the run without touching the server', () async {
      final d = device('G');
      await _addCategory(d, 'c1', 'One');
      final guarded = SyncService(
        db: d.db,
        registry: d.registry,
        api: d.api,
        hlc: d.hlc,
        clock: d.clock,
        userId: () => 'u1',
        deviceId: 'G',
        appBuild: 1,
        guard: () async => false,
      );
      await guarded.syncNow();
      guarded.dispose();
      expect(server.pushCalls, 0);
      expect(server.pullCalls, 0);
      expect(await d.outbox(), hasLength(1));
    });

    test('another isolate holding the sync lock defers the run', () async {
      final d = device('L');
      await _addCategory(d, 'c1', 'One');
      final other = SyncLock(d.db, owner: 'bg-other', clock: d.clock);
      expect(await other.tryAcquire(ttl: const Duration(seconds: 30)), isTrue);
      await d.sync.syncNow();
      expect(server.pushCalls, 0);
      await other.release();
      await d.sync.syncNow();
      expect(server.pushCalls, 1);
    });
  });
}

Future<void> _waitIdle(SimDevice d) async {
  for (var i = 0; i < 50 && d.sync.isRunning; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
