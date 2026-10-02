import 'dart:io';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema v5 → v6 (imported calendar events keep their UID: T8.2.12).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('migration_v6'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<Set<String>> columnsOf(AppDatabase db, String table) async => {
    for (final r in await db.customSelect('PRAGMA table_info($table)').get()) r.read<String>('name'),
  };

  test('a v5 database gains tasks.external_uid and keeps its rows', () async {
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('SELECT 1');
    await db.customStatement('ALTER TABLE tasks DROP COLUMN external_uid');
    await db.customStatement(
      'INSERT INTO tasks (id, user_id, created_at, updated_at, series_id, title) '
      "VALUES ('t1', 'u', '2026-09-21T08:00:00.000Z', '2026-09-21T08:00:00.000Z', 't1', 'Gym')",
    );
    await db.customStatement('PRAGMA user_version = 5');
    expect(await columnsOf(db, 'tasks'), isNot(contains('external_uid')));
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    expect(await columnsOf(db, 'tasks'), contains('external_uid'));
    final row = await db.select(db.tasks).getSingle();
    expect((row.title, row.externalUid), ('Gym', null));
    expect(db.schemaVersion, greaterThanOrEqualTo(6));
    await db.close();
  });
}
