import 'dart:io';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema v2 → v3 (checklist item mirrors: T4.5.16).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('migration_v3'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<Set<String>> columnsOf(AppDatabase db, String table) async => {
    for (final r in await db.customSelect('PRAGMA table_info($table)').get()) r.read<String>('name'),
  };

  test('a v2 database gains checklist_items.mirror_of_id and keeps its rows', () async {
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('SELECT 1');
    await db.customStatement('ALTER TABLE checklist_items DROP COLUMN mirror_of_id');
    await db.customStatement('ALTER TABLE insight_state DROP COLUMN payload');
    await db.customStatement(
      'INSERT INTO checklist_items (id, user_id, checklist_id, sort_key, text, created_at, updated_at) '
      "VALUES ('i1', 'u1', 'c1', 'a0', 'Keep me', '2026-09-22T00:00:00.000Z', '2026-09-22T00:00:00.000Z')",
    );
    await db.customStatement('PRAGMA user_version = 2');
    expect(await columnsOf(db, 'checklist_items'), isNot(contains('mirror_of_id')));
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    expect(await columnsOf(db, 'checklist_items'), contains('mirror_of_id'));
    final row = await (db.select(db.checklistItems)..where((t) => t.id.equals('i1'))).getSingle();
    expect(row.itemText, 'Keep me');
    expect(row.mirrorOfId, isNull);
    expect(db.schemaVersion, greaterThanOrEqualTo(3));
    await db.close();
  });
}
