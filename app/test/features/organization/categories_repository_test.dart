import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/data/categories_repository.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Categories repository (T2.3.01) on the in-memory database.
void main() {
  late TestHarness h;
  late CategoriesRepository repo;
  setUp(() {
    h = TestHarness.create();
    repo = h.read(categoriesRepositoryProvider);
  });
  tearDown(() => h.dispose());

  Matcher validation(String code) =>
      isA<ValidationException>().having((e) => e.message, 'code', code);

  Future<String> insert(String table, Map<String, Object?> values) async {
    final id = Ids.v7();
    await h.read(syncWriterProvider).run((tx) => tx.insert(table, id, values));
    return id;
  }

  Future<String> task(String? categoryId) => insert('tasks', {
    'series_id': Ids.v7(),
    'title': 'Report',
    'category_id': categoryId,
  });

  Future<String> habit(String? categoryId) => insert('habits', {
    'kind': 'build',
    'name': 'Run',
    'start_date': '2026-09-01',
    'sort_key': 'a0',
    'category_id': categoryId,
  });

  Future<String> checklist(String? categoryId) => insert('checklists', {
    'title': 'Groceries',
    'sort_key': 'a0',
    'category_id': categoryId,
  });

  Future<String?> categoryOf(String table, String id) async {
    final row = await h.db
        .customSelect(
          'SELECT category_id FROM $table WHERE id = ?',
          variables: [Variable<String>(id)],
        )
        .getSingle();
    return row.data['category_id'] as String?;
  }

  group('create', () {
    test('normalizes the name and appends at the end', () async {
      await repo.create(name: '  Deep   work ', color: 1);
      await repo.create(name: 'Admin', color: 2, icon: 'work');
      final all = await repo.all();
      expect(all.map((c) => c.name), ['Deep work', 'Admin']);
      expect(all[0].sortKey.compareTo(all[1].sortKey), lessThan(0));
      expect(all[1].icon, 'work');
    });

    test(
      'rejects blank, too long and duplicate (case-insensitive) names',
      () async {
        await repo.create(name: 'Work', color: 1);
        expect(
          repo.create(name: '   ', color: 1),
          throwsA(validation(CategoryNames.errorInvalid)),
        );
        expect(
          repo.create(name: 'x' * 61, color: 1),
          throwsA(validation(CategoryNames.errorInvalid)),
        );
        expect(
          repo.create(name: ' WORK ', color: 1),
          throwsA(validation(CategoryNames.errorDuplicate)),
        );
        expect(await repo.all(), hasLength(1));
      },
    );

    test('add returns the new id', () async {
      final created = await repo.add(name: 'Health', color: 3);
      expect((await repo.all()).single.id, created.id);
      expect(created.record.isEmpty, isFalse);
    });

    test('a deleted name can be reused', () async {
      final first = await repo.add(name: 'Temp', color: 1);
      await repo.delete(first.id);
      await repo.create(name: 'temp', color: 1);
      expect((await repo.all()).single.name, 'temp');
    });
  });

  group('update', () {
    test(
      'renames, recolors and changes icon and capacity flag in one operation',
      () async {
        final c = await repo.add(name: 'Sleep', color: 1);
        final record = await repo.update(
          c.id,
          name: ' Rest ',
          color: 2,
          icon: 'sleep',
          countsAsUnavailable: true,
        );
        expect(record.changes, hasLength(1));
        final updated = (await repo.all()).single;
        expect(updated.name, 'Rest');
        expect(updated.color, 2);
        expect(updated.icon, 'sleep');
        expect(updated.countsAsUnavailable, isTrue);
      },
    );

    test('a rename cannot collide with another category', () async {
      await repo.create(name: 'Work', color: 1);
      final home = await repo.add(name: 'Home', color: 2);
      expect(
        repo.update(home.id, name: 'work'),
        throwsA(validation(CategoryNames.errorDuplicate)),
      );
      expect(
        repo.update(home.id, name: ''),
        throwsA(validation(CategoryNames.errorInvalid)),
      );
      // Changing the case of its own name is fine.
      await repo.update(home.id, name: 'HOME');
      expect((await repo.all()).map((c) => c.name), ['Work', 'HOME']);
    });
  });

  test('archived categories leave pickers but stay resolvable', () async {
    final c = await repo.add(name: 'Old', color: 1);
    await repo.setArchived(c.id, archived: true);
    expect(await repo.watchAll().first, isEmpty);
    final all = await repo.watchAll(includeArchived: true).first;
    expect(all.single.archived, isTrue);
    await repo.setArchived(c.id, archived: false);
    expect((await repo.watchAll().first).single.archived, isFalse);
  });

  test('move places a category between neighbours', () async {
    final a = await repo.add(name: 'A', color: 1);
    await repo.create(name: 'B', color: 1);
    await repo.create(name: 'C', color: 1);
    final before = await repo.all();
    await repo.move(
      a.id,
      afterKey: before[1].sortKey,
      beforeKey: before[2].sortKey,
    );
    expect((await repo.all()).map((c) => c.name), ['B', 'A', 'C']);
  });

  test('usage counts live tasks, habits and checklists only', () async {
    final work = await repo.add(name: 'Work', color: 1);
    final home = await repo.add(name: 'Home', color: 2);
    await task(work.id);
    await habit(work.id);
    final list = await checklist(work.id);
    await checklist(home.id);
    await task(null);
    await h
        .read(syncWriterProvider)
        .run((tx) => tx.softDelete('checklists', list));
    expect(await repo.watchUsageCounts().first, {work.id: 2, home.id: 1});
    expect(await repo.usageCount(work.id), 2);
    expect(await repo.usageCount('missing'), 0);
  });

  group('delete', () {
    test(
      'reassigns every reference in one operation with activity events',
      () async {
        final work = await repo.add(name: 'Work', color: 1);
        final job = await repo.add(name: 'Job', color: 2);
        final t = await task(work.id);
        final hb = await habit(work.id);
        final cl = await checklist(work.id);
        final other = await task(job.id);

        final record = await repo.delete(work.id, reassignTo: job.id);

        expect(await categoryOf('tasks', t), job.id);
        expect(await categoryOf('habits', hb), job.id);
        expect(await categoryOf('checklists', cl), job.id);
        expect(await categoryOf('tasks', other), job.id);
        expect((await repo.all()).map((c) => c.id), [job.id]);

        final events = await (h.db.select(h.db.activityEvents)).get();
        final mine = [
          for (final e in events)
            if ((jsonDecode(e.payload) as Map)['opId'] == record.opId) e,
        ];
        expect(
          {for (final e in mine) (e.entityType, e.eventType)},
          {
            ('task', 'updated'),
            ('habit', 'updated'),
            ('checklist', 'updated'),
            ('category', 'deleted'),
          },
        );
        final taskEvent = mine.firstWhere((e) => e.entityType == 'task');
        expect(jsonDecode(taskEvent.payload), containsPair('to', job.id));
        expect(jsonDecode(taskEvent.payload), containsPair('from', work.id));
        final deleted = mine.firstWhere((e) => e.entityType == 'category');
        expect(jsonDecode(deleted.payload), containsPair('items', 3));
        // One operation group → one atomic push.
        final outbox = await h.db.select(h.db.syncOutbox).get();
        expect(
          {
            for (final o in outbox.where((o) => o.opId == record.opId))
              o.tableName_,
          },
          containsAll([
            'tasks',
            'habits',
            'checklists',
            'categories',
            'activity_events',
          ]),
        );
      },
    );

    test('clears the category when not reassigned; no dangling ids', () async {
      final work = await repo.add(name: 'Work', color: 1);
      final t = await task(work.id);
      await repo.delete(work.id);
      expect(await categoryOf('tasks', t), isNull);
      final dangling = await h.db
          .customSelect(
            'SELECT COUNT(*) AS c FROM tasks t WHERE t.category_id IS NOT NULL AND NOT EXISTS '
            '(SELECT 1 FROM categories c WHERE c.id = t.category_id AND c.deleted_at IS NULL)',
          )
          .getSingle();
      expect(dangling.data['c'], 0);
    });

    test('undo restores the category and every reference', () async {
      final work = await repo.add(name: 'Work', color: 1);
      final job = await repo.add(name: 'Job', color: 2);
      final t = await task(work.id);
      final record = await repo.delete(work.id, reassignTo: job.id);
      await h.read(syncWriterProvider).revert(record);
      expect(await categoryOf('tasks', t), work.id);
      expect((await repo.all()).map((c) => c.name), ['Work', 'Job']);
    });

    test('cannot reassign to itself', () async {
      final work = await repo.add(name: 'Work', color: 1);
      expect(
        () => repo.delete(work.id, reassignTo: work.id),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('seedDefaults uses localized names, palette colors and icons', () async {
    await repo.seedDefaults({
      'work': 'Travail',
      'personal': 'Personnel',
      'health': 'Santé',
      'study': 'Études',
      'home': 'Maison',
      'social': 'Social',
    });
    final all = await repo.all();
    expect(all.map((c) => c.name), [
      'Travail',
      'Personnel',
      'Santé',
      'Études',
      'Maison',
      'Social',
    ]);
    expect(all.map((c) => c.color).toSet(), hasLength(6));
    expect(all.first.id, Ids.defaultCategory('user-1', 'work'));
    expect(all.first.icon, 'work');
  });

  test('copyWith and equality', () {
    const c = Category(id: 'c', name: 'A', color: 1, sortKey: 'a0');
    expect(c.copyWith(name: 'B').name, 'B');
    expect(c.copyWith(), c);
    expect(c.copyWith(archived: true) == c, isFalse);
    expect(CategoryNames.normalize('  a   b '), 'a b');
    expect(CategoryNames.key(' AB '), 'ab');
  });
}
