import 'dart:convert';

import 'package:everslot/core/sync/hlc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

void main() {
  late FakeSyncServer server;
  late SimDevice d;

  setUp(() {
    server = FakeSyncServer();
    d = SimDevice(server, userId: 'u1', deviceId: 'A');
  });
  tearDown(() => d.dispose());

  Future<void> insert(String id) =>
      d.writer.run((tx) => tx.insert('categories', id, {'name': 'N', 'color': 1, 'sort_key': 'a0'}));

  test('100 rapid edits of one row produce one pending patch (T1.4.04)', () async {
    await insert('c1');
    for (var i = 0; i < 100; i++) {
      await d.writer.run((tx) => tx.update('categories', 'c1', {'name': 'Name $i', 'color': i}));
    }
    final outbox = await d.outbox();
    expect(outbox, hasLength(1));
    final fields = jsonDecode(outbox.single.fields) as Map<String, dynamic>;
    expect(outbox.single.op, 'insert');
    expect(fields['name'], 'Name 99');
    expect(fields['color'], 99);
    expect(outbox.single.entryVersion, 101);
    final clock = jsonDecode(outbox.single.clock) as Map<String, dynamic>;
    // The merged clock is the max per field: the name clock is the last edit's stamp.
    final nameClock = clock['name'] as String;
    final sortClock = clock['sort_key'] as String;
    expect(nameClock.compareTo(sortClock), greaterThan(0));
    expect(Hlc.tryParse(nameClock), isNotNull);
  });

  test('multi-row groups are never merged with other operations', () async {
    await d.writer.run((tx) async {
      await tx.insert('categories', 'c1', {'name': 'A', 'color': 1, 'sort_key': 'a0'});
      await tx.insert('categories', 'c2', {'name': 'B', 'color': 1, 'sort_key': 'a1'});
    });
    await d.writer.run((tx) => tx.update('categories', 'c1', {'name': 'A2'}));
    final outbox = await d.outbox();
    expect(outbox, hasLength(3));
    expect({for (final o in outbox) o.opId}, hasLength(2));
  });

  test('a single-row op is not merged into a multi-row op that touches the same row', () async {
    await insert('c1');
    await d.writer.run((tx) async {
      await tx.update('categories', 'c1', {'name': 'X'});
      await tx.logEvent(entityType: 'category', entityId: 'c1', eventType: 'renamed');
    });
    final outbox = await d.outbox();
    // insert (single) ← not merged: the rename op has two entries (row + event).
    expect(outbox, hasLength(3));
  });

  test('in-flight entries are never modified by coalescing', () async {
    await insert('c1');
    await d.db.customStatement("UPDATE sync_outbox SET state = 'inflight'");
    await d.writer.run((tx) => tx.update('categories', 'c1', {'name': 'Later'}));
    final outbox = await d.outbox();
    expect(outbox, hasLength(2));
    expect(outbox.first.entryVersion, 1);
  });

  test('a failed write leaves no partial state (transaction rollback)', () async {
    await insert('c1');
    final before = await d.outbox();
    await expectLater(
      d.writer.run((tx) async {
        await tx.update('categories', 'c1', {'name': 'Changed'});
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect((await d.rows('categories', ['name']))['c1']!['name'], 'N');
    final after = await d.outbox();
    expect(after.single.entryVersion, before.single.entryVersion);
  });

  test('automatic writes carry the scheduled instant as clock; a later user edit wins', () async {
    await insert('c1');
    await d.sync.syncNow();
    final scheduled = d.clock.nowUtc().subtract(const Duration(hours: 1));
    await d.writer.run(
      (tx) => tx.update('categories', 'c1', {'name': 'Auto'}),
      scheduledAt: scheduled,
      cause: 'reset',
    );
    final auto = jsonDecode((await d.outbox()).single.clock) as Map<String, dynamic>;
    expect(Hlc.tryParse(auto['name'] as String)!.ms, scheduled.millisecondsSinceEpoch);
    // Another device's user edit made before now but after the scheduled instant wins.
    final b = SimDevice(server, userId: 'u1', deviceId: 'B');
    await b.sync.syncNow();
    await b.writer.run((tx) => tx.update('categories', 'c1', {'name': 'User'}));
    await b.sync.syncNow();
    await d.sync.syncNow();
    expect(server.row('categories', 'c1')!.values['name'], 'User');
    expect((await d.rows('categories', ['name']))['c1']!['name'], 'User');
    await b.dispose();
  });
}
