import 'package:drift/drift.dart' show OrderingTerm;
import 'dart:convert';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  test('insert writes row, outbox patch with HLC clocks and field_clock', () async {
    final writer = h.read(syncWriterProvider);
    await writer.run((tx) => tx.insert('categories', 'c1', {
      'name': 'Work',
      'color': 0xFF3B82F6,
      'sort_key': 'a0',
    }));
    final row = await (h.db.select(h.db.categories)).getSingle();
    expect(row.name, 'Work');
    expect(row.userId, 'user-1');
    final outbox = await h.db.select(h.db.syncOutbox).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.op, 'insert');
    final fields = jsonDecode(outbox.single.fields) as Map<String, dynamic>;
    expect(fields['name'], 'Work');
    expect(fields.containsKey('user_id'), isFalse);
    final clock = jsonDecode(outbox.single.clock) as Map<String, dynamic>;
    expect(clock['name'], matches(RegExp(r'^\d{15}:\d{5}:device-test$')));
  });

  test('update only records changed fields; same-op writes coalesce', () async {
    final writer = h.read(syncWriterProvider);
    // A two-row operation: its entries are never merged with later operations (group atomicity);
    // cross-operation coalescing of single-row groups is covered in test/core/sync/.
    await writer.run((tx) async {
      await tx.insert('categories', 'c1', {'name': 'A', 'color': 1, 'sort_key': 'a0'});
      await tx.insert('categories', 'c2', {'name': 'Z', 'color': 1, 'sort_key': 'a1'});
    });
    await writer.run((tx) async {
      await tx.update('categories', 'c1', {'name': 'B', 'color': 1});
      await tx.update('categories', 'c1', {'name': 'C'});
    });
    final outbox = await (h.db.select(h.db.syncOutbox)..orderBy([(o) => OrderingTerm.asc(o.seq)])).get();
    expect(outbox, hasLength(3));
    final patch = jsonDecode(outbox.last.fields) as Map<String, dynamic>;
    expect(patch['name'], 'C');
    expect(patch.containsKey('color'), isFalse);
    expect(outbox.last.entryVersion, 2);
  });

  test('undo reverts an operation', () async {
    final repo = h.read(categoriesRepositoryProvider);
    await repo.create(name: 'Gym', color: 1);
    final created = (await repo.all()).single;
    final record = await repo.update(created.id, name: 'Sport');
    expect((await repo.all()).single.name, 'Sport');
    await h.read(syncWriterProvider).revert(record);
    expect((await repo.all()).single.name, 'Gym');
  });

  test('seedDefaults is idempotent (deterministic ids)', () async {
    final repo = h.read(categoriesRepositoryProvider);
    await repo.seedDefaults({'work': 'Work'});
    await repo.seedDefaults({'work': 'Work'});
    expect(await repo.all(), hasLength(6));
  });
}
