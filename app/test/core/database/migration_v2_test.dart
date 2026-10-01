import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema v1 → v2 (planner P2 columns: T3.1.21, T3.7.07, T3.7.11–T3.7.13).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('migration_v2'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<Set<String>> columnsOf(AppDatabase db, String table) async => {
    for (final r in await db.customSelect('PRAGMA table_info($table)').get()) r.read<String>('name'),
  };

  test('a v1 database gains the P2 columns and keeps its rows', () async {
    final file = File('${dir.path}/db.sqlite');
    // Build the v2 schema, then strip it back to v1 (drop the new columns, user_version = 1).
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('SELECT 1');
    for (final c in ['linked_item_id', 'horizon_key', 'countdown_mode', 'location_lat', 'location_lng']) {
      await db.customStatement('ALTER TABLE tasks DROP COLUMN $c');
    }
    await db.customStatement('ALTER TABLE checklist_items DROP COLUMN estimate_minutes');
    await db.customStatement(
      "INSERT INTO tasks (id, user_id, series_id, title, created_at, updated_at) "
      "VALUES ('t1', 'u1', 't1', 'Keep me', '2026-09-22T00:00:00.000Z', '2026-09-22T00:00:00.000Z')",
    );
    await db.customStatement('PRAGMA user_version = 1');
    expect(await columnsOf(db, 'tasks'), isNot(contains('horizon_key')));
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    final tasks = await columnsOf(db, 'tasks');
    expect(tasks, containsAll(['linked_item_id', 'horizon_key', 'countdown_mode', 'location_lat', 'location_lng']));
    expect(await columnsOf(db, 'checklist_items'), contains('estimate_minutes'));
    final row = await (db.select(db.tasks)..where((t) => t.id.equals('t1'))).getSingle();
    expect(row.title, 'Keep me');
    expect(row.horizonKey, isNull);
    expect(db.schemaVersion, 2);
    await db.close();
  });
}
