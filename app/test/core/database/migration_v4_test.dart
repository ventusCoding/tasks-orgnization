import 'dart:io';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema v3 → v4 (fired insights keep their payload: T6.7.08).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('migration_v4'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<Set<String>> columnsOf(AppDatabase db, String table) async => {
    for (final r in await db.customSelect('PRAGMA table_info($table)').get()) r.read<String>('name'),
  };

  test('a v3 database gains insight_state.payload and keeps its rows', () async {
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('SELECT 1');
    await db.customStatement('ALTER TABLE insight_state DROP COLUMN payload');
    await db.customStatement(
      "INSERT INTO insight_state (key, fired_at) VALUES ('perfectWeek|habits|2026-09-14', '2026-09-21T08:00:00.000Z')",
    );
    await db.customStatement('PRAGMA user_version = 3');
    expect(await columnsOf(db, 'insight_state'), isNot(contains('payload')));
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    expect(await columnsOf(db, 'insight_state'), contains('payload'));
    final row = await db.select(db.insightState).getSingle();
    expect(row.key, 'perfectWeek|habits|2026-09-14');
    expect(row.payload, isNull);
    expect(db.schemaVersion, greaterThanOrEqualTo(4));
    await db.close();
  });
}
