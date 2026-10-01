import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/data/tags_repository.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  late TagsRepository repo;

  setUp(() {
    h = TestHarness.create();
    repo = h.read(tagsRepositoryProvider);
  });
  tearDown(() => h.dispose());

  Future<String> task(String title) async {
    final id = Ids.v7();
    await h.read(syncWriterProvider).run((tx) => tx.insert('tasks', id, {'series_id': id, 'title': title}));
    return id;
  }

  Future<List<Map<String, Object?>>> linkRows() async => [
    for (final r in await h.db.customSelect('SELECT * FROM entity_tags ORDER BY id').get()) r.data,
  ];

  group('names', () {
    test('normalizes and validates', () async {
      expect(TagNames.normalize('  #Deep   work '), 'Deep work');
      final created = await repo.create(name: '##errands');
      expect((await repo.all()).single.name, 'errands');
      expect(created.record.isEmpty, isFalse);
      await expectLater(
        repo.create(name: '   '),
        throwsA(isA<ValidationException>().having((e) => e.message, 'code', TagNames.errorInvalid)),
      );
      await expectLater(
        repo.create(name: 'x' * 41),
        throwsA(isA<ValidationException>().having((e) => e.message, 'code', TagNames.errorInvalid)),
      );
      await expectLater(
        repo.create(name: 'ERRANDS'),
        throwsA(isA<ValidationException>().having((e) => e.message, 'code', TagNames.errorDuplicate)),
      );
      expect((await repo.findByName('#Errands'))?.id, created.id);
    });

    test('rename keeps uniqueness but allows renaming itself', () async {
      final a = await repo.create(name: 'home');
      await repo.create(name: 'work');
      await repo.update(a.id, name: 'HOME');
      expect((await repo.all()).first.name, 'HOME');
      await expectLater(repo.update(a.id, name: 'Work'), throwsA(isA<ValidationException>()));
    });

    test('recolor and clear color', () async {
      final a = await repo.create(name: 'x', color: 0xFF3B82F6);
      await repo.update(a.id, color: 0xFFEF4444);
      expect((await repo.all()).single.color, 0xFFEF4444);
      await repo.update(a.id, clearColor: true);
      expect((await repo.all()).single.color, isNull);
    });
  });

  test('new tags are appended and can be reordered', () async {
    final a = await repo.create(name: 'a');
    final b = await repo.create(name: 'b');
    final c = await repo.create(name: 'c');
    expect([for (final t in await repo.all()) t.id], [a.id, b.id, c.id]);
    final tags = await repo.all();
    await repo.move(c.id, afterKey: null, beforeKey: tags.first.sortKey);
    expect([for (final t in await repo.all()) t.id], [c.id, a.id, b.id]);
  });

  group('entity tags', () {
    test('attach uses the deterministic id and is idempotent', () async {
      final tag = await repo.create(name: 'work');
      final t = await task('Report');
      await repo.attach(tag.id, TaggableType.task, t);
      final again = await repo.attach(tag.id, TaggableType.task, t);
      expect(again.isEmpty, isTrue);
      final rows = await linkRows();
      expect(rows, hasLength(1));
      expect(rows.single['id'], Ids.entityTag(tag.id, 'task', t));
      expect(await repo.tagsForEntity('task', t), [isA<Tag>().having((x) => x.name, 'name', 'work')]);
    });

    test('detach soft-deletes and re-attach restores the same row', () async {
      final tag = await repo.create(name: 'work');
      final t = await task('Report');
      await repo.attach(tag.id, 'task', t);
      await repo.detach(tag.id, 'task', t);
      expect(await repo.tagsForEntity('task', t), isEmpty);
      expect((await linkRows()).single['deleted_at'], isNotNull);
      await repo.attach(tag.id, 'task', t);
      final rows = await linkRows();
      expect(rows, hasLength(1));
      expect(rows.single['deleted_at'], isNull);
    });

    test('setTags adds and removes in one operation and logs an update event', () async {
      final a = await repo.create(name: 'a');
      final b = await repo.create(name: 'b');
      final c = await repo.create(name: 'c');
      final t = await task('T');
      await repo.setTags('task', t, {a.id, b.id});
      final record = await repo.setTags('task', t, {b.id, c.id});
      expect({for (final x in await repo.tagsForEntity('task', t)) x.id}, {b.id, c.id});
      final opIds = {for (final r in await h.db.customSelect('SELECT op_id FROM sync_outbox').get()) r.data['op_id']};
      expect(opIds, contains(record.opId));
      final events =
          await (h.db.select(h.db.activityEvents)
                ..where((e) => e.entityId.equals(t) & e.eventType.equals('updated'))
                ..orderBy([(e) => OrderingTerm.asc(e.id)]))
              .get();
      expect(events, hasLength(2));
      final last = [for (final e in events) jsonDecode(e.payload) as Map<String, dynamic>]
          .singleWhere((p) => p['opId'] == record.opId);
      expect(last['fields'], ['tags']);
      expect(last['addedTags'], [c.id]);
      expect(last['removedTags'], [a.id]);
      expect(last['opId'], record.opId);
    });

    test('rejects non-taggable entity types', () async {
      final tag = await repo.create(name: 'x');
      await expectLater(repo.attach(tag.id, 'category', 'c1'), throwsArgumentError);
    });

    test('streams by entity type and usage counts ignore deleted entities', () async {
      final a = await repo.create(name: 'a');
      final b = await repo.create(name: 'b');
      final t1 = await task('one');
      final t2 = await task('two');
      await repo.setTags('task', t1, {a.id, b.id});
      await repo.setTags('task', t2, {a.id});
      final byEntity = await repo.watchByEntity('task').first;
      expect(byEntity.keys.toSet(), {t1, t2});
      expect([for (final t in byEntity[t1]!) t.name], ['a', 'b']);
      expect(await repo.watchUsageCounts().first, {a.id: 2, b.id: 1});
      await h.read(syncWriterProvider).run((tx) => tx.softDelete('tasks', t2));
      expect(await repo.watchUsageCounts().first, {a.id: 1, b.id: 1});
      expect(await repo.watchEntityIds(a.id).first, {t1, t2});
    });

    test('writeTags joins an operation run by another repository', () async {
      final tag = await repo.create(name: 'health');
      final id = Ids.v7();
      final record = await h.read(syncWriterProvider).run((tx) async {
        await tx.insert('habits', id, {'kind': 'build', 'name': 'Run', 'start_date': '2026-09-22', 'sort_key': 'a0'});
        await repo.writeTags(tx, 'habit', id, {tag.id});
      });
      expect(record.changes.map((c) => c.table), containsAll(['habits', 'entity_tags']));
      expect(await repo.tagsForEntity('habit', id), hasLength(1));
    });
  });

  group('delete & merge', () {
    test('delete removes links and one undo restores everything', () async {
      final tag = await repo.create(name: 'work');
      final t = await task('Report');
      await repo.attach(tag.id, 'task', t);
      final record = await repo.delete(tag.id);
      expect(await repo.all(), isEmpty);
      expect(await repo.tagsForEntity('task', t), isEmpty);
      await h.read(syncWriterProvider).revert(record);
      expect([for (final x in await repo.all()) x.name], ['work']);
      expect([for (final x in await repo.tagsForEntity('task', t)) x.name], ['work']);
    });

    test('merge rewrites links in one operation and undo restores them exactly', () async {
      final source = await repo.create(name: 'job');
      final target = await repo.create(name: 'work');
      final t1 = await task('only source');
      final t2 = await task('both');
      final t3 = await task('only target');
      await repo.setTags('task', t1, {source.id});
      await repo.setTags('task', t2, {source.id, target.id});
      await repo.setTags('task', t3, {target.id});
      final before = await linkRows();

      final record = await repo.merge(sourceId: source.id, targetId: target.id);
      expect([for (final x in await repo.all()) x.name], ['work']);
      for (final t in [t1, t2, t3]) {
        expect([for (final x in await repo.tagsForEntity('task', t)) x.id], [target.id]);
      }
      // One operation group: 1 new target link (t1; t2 already had it) + 2 source links deleted
      // + source tag + activity event, all pushed atomically under the merge's op id.
      expect(record.changes.where((c) => c.table == 'entity_tags'), hasLength(3));
      final outbox = await (h.db.select(h.db.syncOutbox)..where((o) => o.opId.equals(record.opId))).get();
      expect(
        {for (final o in outbox) '${o.tableName_}/${o.rowId}'},
        {for (final c in record.changes) '${c.table}/${c.id}'},
      );

      await h.read(syncWriterProvider).revert(record);
      expect([for (final x in await repo.all()) x.name], ['job', 'work']);
      // Live links are exactly the original ones; the link created by the merge is a tombstone.
      Set<String> live(List<Map<String, Object?>> rows) => {
        for (final r in rows)
          if (r['deleted_at'] == null) '${r['tag_id']}|${r['entity_id']}',
      };
      final after = await linkRows();
      expect(live(after), live(before));
      expect(after.length, before.length + 1);
      for (final t in [t1, t2]) {
        expect({for (final x in await repo.tagsForEntity('task', t)) x.name}, t == t1 ? {'job'} : {'job', 'work'});
      }
    });

    test('merge validates its arguments', () async {
      final a = await repo.create(name: 'a');
      final b = await repo.create(name: 'b');
      expect(() => repo.merge(sourceId: a.id, targetId: a.id), throwsA(isA<ValidationException>()));
      await repo.delete(b.id);
      await expectLater(repo.merge(sourceId: a.id, targetId: b.id), throwsA(isA<NotFoundException>()));
      expect(await repo.all(), hasLength(1));
    });
  });
}
