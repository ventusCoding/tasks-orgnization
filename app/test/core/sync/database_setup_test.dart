import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/sync/synced_queries.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Database setup checks (T1.4.01): pragmas, schema creation, soft-delete conventions of the
/// synced tables (T1.4.02) and a second isolate writing to the same file concurrently.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('everslot_db_'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('opens a file database in WAL mode with foreign keys off and every table created', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase(File('${dir.path}/everslot.sqlite')));
    final journal = await db.customSelect('PRAGMA journal_mode').getSingle();
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(journal.data.values.first.toString().toLowerCase(), 'wal');
    expect(fk.data.values.first, 0);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type IN ('table')")
        .map((r) => r.data['name'] as String)
        .get();
    for (final t in db.allTables) {
      expect(tables, contains(t.actualTableName));
    }
    expect(tables, contains('search_index'));
    expect(db.schemaVersion, 1);
    await db.close();
  });

  test('every synced table carries the common columns (id, user_id, deleted_at, rev, field_clock)', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const common = {
      'id',
      'user_id',
      'created_at',
      'updated_at',
      'deleted_at',
      'rev',
      'field_clock',
      'server_updated_at',
      'origin_device_id',
    };
    for (final t in db.allTables.where((t) => t.$columns.any((c) => c.name == 'field_clock'))) {
      expect(t.$columns.map((c) => c.name).toSet().containsAll(common), isTrue, reason: t.actualTableName);
    }
    return db.close();
  });

  test('a second isolate reads and writes the same file concurrently', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final path = '${dir.path}/everslot.sqlite';
    final main = AppDatabase(NativeDatabase(File(path), setup: (raw) => raw.execute('PRAGMA busy_timeout = 5000')));
    await main.customSelect('SELECT 1').get(); // create the schema first
    final other = Isolate.run(() async {
      final db = AppDatabase(
        NativeDatabase(File(path), setup: (raw) => raw.execute('PRAGMA busy_timeout = 5000')),
      );
      for (var i = 0; i < 50; i++) {
        await db.into(db.localKv).insert(LocalKvRow(key: 'bg-$i', value: '$i'));
      }
      final n = await db.customSelect('SELECT COUNT(*) AS n FROM local_kv').getSingle();
      await db.close();
      return n.data['n'] as int;
    });
    for (var i = 0; i < 50; i++) {
      await main.into(main.localKv).insert(LocalKvRow(key: 'fg-$i', value: '$i'));
    }
    expect(await other, greaterThanOrEqualTo(50));
    final total = await main.customSelect('SELECT COUNT(*) AS n FROM local_kv').getSingle();
    expect(total.data['n'], 100);
    await main.close();
  });

  test('watchActive / getById hide tombstones and other users (T1.4.02)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final clock = FakeClock(DateTime.utc(2026, 9, 22, 9));
    var user = 'u1';
    final writer = SyncWriter(
      db: db,
      registry: TableRegistry(db),
      clock: clock,
      hlc: Hlc(deviceId: 'd', clock: clock),
      userId: () => user,
      deviceId: 'd',
    );
    Future<void> add(String id, String key) =>
        writer.run((tx) => tx.insert('categories', id, {'name': id, 'color': 1, 'sort_key': key}));
    await add('b', 'a1');
    await add('a', 'a0');
    user = 'u2';
    await add('other', 'a2');
    user = 'u1';
    final stream = db.watchActive(db.categories, userId: 'u1', orderBy: (t) => OrderingTerm.asc(t.sortKey));
    expect((await stream.first).map((c) => c.id), ['a', 'b']);
    await writer.run((tx) => tx.softDelete('categories', 'a'));
    expect((await stream.first).map((c) => c.id), ['b']);
    expect(await db.getById(db.categories, 'a'), isNull);
    expect((await db.getById(db.categories, 'a', includeDeleted: true))?.id, 'a');
    await writer.run((tx) => tx.restore('categories', 'a'));
    expect((await db.getActive(db.categories, userId: 'u1')).map((c) => c.id).toSet(), {'a', 'b'});
    await db.close();
  });
}
