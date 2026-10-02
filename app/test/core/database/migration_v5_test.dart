import 'dart:io';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema v4 → v5 (inbox entries join the global search index: T8.1.14).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('migration_v5'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<List<String>> indexed(AppDatabase db, String type) async => [
    for (final r
        in await db
            .customSelect("SELECT entity_id FROM search_index WHERE entity_type = '$type' ORDER BY entity_id")
            .get())
      r.read<String>('entity_id'),
  ];

  test('existing inbox entries are indexed and new ones follow', () async {
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('SELECT 1');
    for (final op in ['ai', 'au', 'ad']) {
      await db.customStatement('DROP TRIGGER trg_notifications_fts_$op');
    }
    await db.customStatement(
      'INSERT INTO notifications (id, user_id, created_at, updated_at, dedupe_key, category, title, body, fire_at) '
      "VALUES ('n1', 'u', '2026-09-21T08:00:00.000Z', '2026-09-21T08:00:00.000Z', 'n1', 'reminder', 'Dentist', "
      "'Bring the card', '2026-09-21T08:00:00.000Z')",
    );
    await db.customStatement('PRAGMA user_version = 4');
    expect(await indexed(db, 'notification'), isEmpty);
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    expect(await indexed(db, 'notification'), ['n1']);
    await db.customStatement(
      'INSERT INTO notifications (id, user_id, created_at, updated_at, dedupe_key, category, title, fire_at) '
      "VALUES ('n2', 'u', '2026-09-22T08:00:00.000Z', '2026-09-22T08:00:00.000Z', 'n2', 'digest', 'Week', "
      "'2026-09-22T08:00:00.000Z')",
    );
    expect(await indexed(db, 'notification'), ['n1', 'n2']);
    expect(db.schemaVersion, greaterThanOrEqualTo(5));
    await db.close();
  });
}
