@Tags(['sync'])
library;

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../shared/support/fake_sync_server.dart';

/// Two-client convergence for organization primitives (T2.3.02, T2.3.10).
void main() {
  late FakeSyncServer server;
  late SyncDevice a;
  late SyncDevice b;

  setUpAll(tzdata.initializeTimeZones);
  setUp(() {
    server = FakeSyncServer();
    a = SyncDevice(server, 'device-a');
    b = SyncDevice(server, 'device-b');
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  Future<void> syncAll() async {
    await a.sync();
    await b.sync();
    await a.sync();
  }

  test('default categories seeded offline on two devices converge to exactly 6', () async {
    await a.read(categoriesRepositoryProvider).seedDefaults({'work': 'Work', 'home': 'Home'});
    await b.read(categoriesRepositoryProvider).seedDefaults({'work': 'Travail', 'home': 'Maison'});
    await syncAll();
    expect(server.rows('categories'), hasLength(6));
    final onA = await a.read(categoriesRepositoryProvider).all();
    final onB = await b.read(categoriesRepositoryProvider).all();
    expect(onA, hasLength(6));
    expect(onB, hasLength(6));
    expect({for (final c in onA) c.id}, {for (final c in onB) c.id});
    // Per-field last-writer-wins: both devices end with the same names.
    expect({for (final c in onA) c.id: c.name}, {for (final c in onB) c.id: c.name});
  });

  test('tagging the same entity on two offline devices converges to one link', () async {
    final tags = a.read(tagsRepositoryProvider);
    final tag = await tags.create(name: 'work');
    final taskId = Ids.v7();
    await a.read(syncWriterProvider).run((tx) => tx.insert('tasks', taskId, {'series_id': taskId, 'title': 'Report'}));
    await a.sync();
    await b.sync();
    expect(await b.read(tagsRepositoryProvider).all(), hasLength(1));

    // Both devices tag the same task while offline.
    await tags.attach(tag.id, 'task', taskId);
    await b.read(tagsRepositoryProvider).attach(tag.id, 'task', taskId);
    await syncAll();

    expect(server.rows('entity_tags'), hasLength(1));
    for (final device in [a, b]) {
      final rows = await device.db.select(device.db.entityTags).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, Ids.entityTag(tag.id, 'task', taskId));
      expect(rows.single.deletedAt, isNull);
      expect(await device.read(tagsRepositoryProvider).tagsForEntity('task', taskId), hasLength(1));
    }
  });

  test('a merge on one device reaches the other device completely', () async {
    final tags = a.read(tagsRepositoryProvider);
    final job = await tags.create(name: 'job');
    final work = await tags.create(name: 'work');
    final taskId = Ids.v7();
    await a.read(syncWriterProvider).run((tx) => tx.insert('tasks', taskId, {'series_id': taskId, 'title': 'Report'}));
    await tags.attach(job.id, 'task', taskId);
    await syncAll();

    await tags.merge(sourceId: job.id, targetId: work.id);
    await syncAll();

    final onB = b.read(tagsRepositoryProvider);
    expect([for (final t in await onB.all()) t.name], ['work']);
    expect([for (final t in await onB.tagsForEntity('task', taskId)) t.id], [work.id]);
  });
}
