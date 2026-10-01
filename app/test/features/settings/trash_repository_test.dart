import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/settings/application/trash_providers.dart';
import 'package:everslot/features/settings/data/trash_remote.dart';
import 'package:everslot/features/settings/domain/trash.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

class _FakeRemote implements TrashRemote {
  final calls = <String>[];
  bool offline = false;

  @override
  Future<int> purge(String entityType, List<String> ids) async {
    if (offline) throw Exception('SocketException: offline (fake)');
    calls.add('$entityType:${ids.join(',')}');
    return ids.length;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late SyncWriter w;

  setUp(() {
    h = TestHarness.create();
    w = h.read(syncWriterProvider);
  });
  tearDown(() => h.dispose());

  Future<void> tick() async => h.clock.advance(const Duration(seconds: 3));
  Future<List<TrashEntry>> trash() =>
      h.read(trashRepositoryProvider).list(since: h.clock.nowUtc().subtract(trashRetention));
  Future<bool> live(String table, String id) async =>
      (await h.db
              .customSelect('SELECT deleted_at FROM $table WHERE id = ?', variables: [Variable<String>(id)])
              .getSingle())
          .data['deleted_at'] ==
      null;
  Future<int> rows(String table, String id) async =>
      (await h.db
                  .customSelect('SELECT COUNT(*) AS n FROM $table WHERE id = ?', variables: [Variable<String>(id)])
                  .getSingle())
              .data['n']
          as int;

  Future<void> seedList() => w.run((tx) async {
    await tx.insert('checklists', 'L', {'title': 'Groceries', 'sort_key': 'a0'});
    await tx.insert('checklist_items', 'A', {'checklist_id': 'L', 'sort_key': 'a0', 'text': 'Fruit'});
    await tx.insert('checklist_items', 'A1', {
      'checklist_id': 'L',
      'parent_id': 'A',
      'sort_key': 'a0',
      'text': 'Apples',
    });
    await tx.insert('checklist_items', 'A2', {
      'checklist_id': 'L',
      'parent_id': 'A',
      'sort_key': 'a1',
      'text': 'Pears',
    });
    await tx.insert('checklist_items', 'A2x', {
      'checklist_id': 'L',
      'parent_id': 'A2',
      'sort_key': 'a0',
      'text': 'Ripe',
    });
    await tx.insert('attachments', 'P', {
      'owner_type': 'checklist_item',
      'owner_id': 'A1',
      'storage_path': 'u/p.jpg',
      'file_name': 'apples.jpg',
      'mime_type': 'image/jpeg',
      'byte_size': 10,
      'sort_key': 'a0',
    });
  });

  group('deleted together (same operation = same instant)', () {
    test('restoring an item brings back what was deleted with it, not what was deleted earlier', () async {
      await seedList();
      await tick();
      await w.run((tx) async {
        await tx.softDelete('checklist_items', 'A2x');
        await tx.softDelete('checklist_items', 'A2');
      });
      await tick();
      await w.run((tx) async {
        for (final id in ['A1', 'A']) {
          await tx.softDelete('checklist_items', id);
        }
        await tx.softDelete('attachments', 'P');
      });

      var entries = await trash();
      expect(
        [for (final e in entries) e.id],
        ['A'],
        reason: 'A2 lives under a deleted parent: it comes back with it later',
      );
      expect(entries.single.withCount, 2, reason: 'A1 and its photo');
      expect(entries.single.path, ['Groceries']);

      expect(await h.read(trashServiceProvider).restore(entries.single), 3);
      expect(await live('checklist_items', 'A'), isTrue);
      expect(await live('checklist_items', 'A1'), isTrue);
      expect(await live('attachments', 'P'), isTrue);
      expect(await live('checklist_items', 'A2'), isFalse, reason: 'deleted by an earlier operation');

      entries = await trash();
      expect([for (final e in entries) e.id], ['A2']);
      expect(entries.single.path, ['Groceries', 'Fruit']);
      expect(entries.single.withCount, 1, reason: 'A2x was deleted with it');
    });

    test('a deleted checklist restores its items; restores are synced patches', () async {
      await seedList();
      await tick();
      await w.run((tx) async {
        for (final id in ['A2x', 'A2', 'A1', 'A']) {
          await tx.softDelete('checklist_items', id);
        }
        await tx.softDelete('checklists', 'L');
      });
      final entries = await trash();
      expect([for (final e in entries) (e.kind, e.id, e.title)], [(TrashKind.checklist, 'L', 'Groceries')]);
      expect(entries.single.withCount, 4);
      final before = (await h.db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle()).data['n'] as int;
      await h.read(trashServiceProvider).restore(entries.single);
      for (final id in ['A', 'A1', 'A2', 'A2x']) {
        expect(await live('checklist_items', id), isTrue, reason: id);
      }
      expect(await trash(), isEmpty);
      final restoreEvents = await h.db
          .customSelect("SELECT COUNT(*) AS n FROM activity_events WHERE event_type = 'restored' AND entity_id = 'L'")
          .getSingle();
      expect(restoreEvents.data['n'], 1);
      final after = (await h.db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle()).data['n'] as int;
      expect(after, greaterThanOrEqualTo(before), reason: 'restores are pushed like any edit');
    });

    test('tasks, habits and standalone attachments are listed; older than 30 days are not', () async {
      await w.run((tx) async {
        await tx.insert('tasks', 'T', {'series_id': 'T', 'title': 'Call mom'});
        await tx.insert('habits', 'H', {
          'kind': 'build',
          'name': 'Water',
          'start_date': '2026-09-01',
          'sort_key': 'a0',
        });
        await tx.insert('habit_logs', 'HL', {
          'habit_id': 'H',
          'kind': 'check',
          'logged_at': h.clock.nowUtc(),
          'local_date': '2026-09-20',
        });
        await tx.insert('tasks', 'OLD', {'series_id': 'OLD', 'title': 'Old'});
      });
      await w.run((tx) => tx.softDelete('tasks', 'OLD'));
      h.clock.advance(const Duration(days: 31));
      await w.run((tx) async {
        await tx.softDelete('habit_logs', 'HL');
        await tx.softDelete('habits', 'H');
      });
      await tick();
      await w.run((tx) => tx.softDelete('tasks', 'T'));
      final entries = await trash();
      expect([for (final e in entries) (e.kind, e.id)], [(TrashKind.task, 'T'), (TrashKind.habit, 'H')]);
      expect(entries.last.withCount, 1);
    });
  });

  group('delete forever', () {
    Future<TrashEntry> deletedList() async {
      await seedList();
      await tick();
      await w.run((tx) async {
        for (final id in ['A2x', 'A2', 'A1', 'A']) {
          await tx.softDelete('checklist_items', id);
        }
        await tx.softDelete('attachments', 'P');
        await tx.softDelete('checklists', 'L');
      });
      return (await trash()).single;
    }

    test('local-only: the rows, their tombstoned children and outbox entries are removed', () async {
      final entry = await deletedList();
      await h.read(trashServiceProvider).deleteForever(entry);
      for (final (t, id) in [
        ('checklists', 'L'),
        ('checklist_items', 'A'),
        ('checklist_items', 'A2x'),
        ('attachments', 'P'),
      ]) {
        expect(await rows(t, id), 0, reason: id);
      }
      final outbox = await h.db
          .customSelect("SELECT COUNT(*) AS n FROM sync_outbox WHERE row_id IN ('L', 'A', 'P')")
          .getSingle();
      expect(outbox.data['n'], 0);
      expect(await trash(), isEmpty);
    });

    test('synced account: purge_now first; offline keeps everything', () async {
      final remote = _FakeRemote();
      await h.dispose();
      h = TestHarness.create(overrides: [trashRemoteProvider.overrideWithValue(remote)]);
      w = h.read(syncWriterProvider);
      final entry = await deletedList();
      // Pretend the deletion already reached the server.
      await h.db.customStatement('DELETE FROM sync_outbox');

      remote.offline = true;
      await expectLater(
        h.read(trashServiceProvider).deleteForever(entry),
        throwsA(isA<TrashException>().having((e) => e.failure, 'failure', TrashFailure.offline)),
      );
      expect(await rows('checklists', 'L'), 1);

      remote.offline = false;
      await h.read(trashServiceProvider).deleteForever(entry);
      expect(remote.calls, ['checklist:L']);
      expect(await rows('checklists', 'L'), 0);
    });

    test('synced account: a deletion not pushed yet is refused (it would survive on the server)', () async {
      final remote = _FakeRemote();
      await h.dispose();
      h = TestHarness.create(overrides: [trashRemoteProvider.overrideWithValue(remote)]);
      w = h.read(syncWriterProvider);
      final entry = await deletedList();
      await expectLater(
        h.read(trashServiceProvider).deleteForever(entry),
        throwsA(isA<TrashException>().having((e) => e.failure, 'failure', TrashFailure.notSynced)),
      );
      expect(remote.calls, isEmpty);
      expect(await rows('checklists', 'L'), 1);
    });
  });
}
