import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/database_encryption.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory tmp;
  late File file;
  late MemorySecureStore store;
  late DatabaseEncryption encryption;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('everslot_enc_');
    file = File('${tmp.path}/everslot.sqlite');
    store = MemorySecureStore();
    encryption = DatabaseEncryption(store: store, file: () async => file);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// A real app database (all migrations, WAL) with [rows] categories.
  Future<void> seed({int rows = 3, String? key}) async {
    final db = AppDatabase.forTesting(
      NativeDatabase(file, setup: key == null ? null : (raw) => raw.execute(DatabaseCipher.keyPragma(key))),
    );
    await db.customStatement('PRAGMA journal_mode = WAL');
    for (var i = 0; i < rows; i++) {
      await db.customStatement(
        'INSERT INTO categories (id, user_id, name, color, sort_key, created_at, updated_at, origin_device_id, field_clock) '
        "VALUES ('c$i', 'u', 'Category $i', 1, 'a$i', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 'd', '{}')",
      );
    }
    await db.close();
  }

  Future<int> count({String? key}) async {
    final db = AppDatabase.forTesting(
      NativeDatabase(file, setup: key == null ? null : (raw) => raw.execute(DatabaseCipher.keyPragma(key))),
    );
    final n = (await db.customSelect('SELECT COUNT(*) AS n FROM categories').getSingle()).data['n']! as int;
    await db.close();
    return n;
  }

  test('plain → encrypted → plain keeps every row; the plain file is gone', () async {
    await seed();
    expect(DatabaseCipher.isEncrypted(file), isFalse);
    expect(await encryption.keyForOpen(), isNull);

    await encryption.setWanted(value: true);
    expect(await encryption.migrateIfNeeded(), EncryptionChange.encrypted);
    expect(DatabaseCipher.isEncrypted(file), isTrue);
    expect(File('${file.path}.converting').existsSync(), isFalse);
    expect(File('${file.path}.previous').existsSync(), isFalse);
    final key = await encryption.keyForOpen();
    expect(key, isNotNull);
    expect(key, store.values[DatabaseEncryption.keyName]);
    expect(await count(key: key), 3);
    expect(() => sqlite3.open(file.path).select('SELECT * FROM categories'), throwsA(isA<SqliteException>()));
    expect(await encryption.migrateIfNeeded(), EncryptionChange.none, reason: 'idempotent');

    await encryption.setWanted(value: false);
    expect(await encryption.migrateIfNeeded(), EncryptionChange.decrypted);
    expect(DatabaseCipher.isEncrypted(file), isFalse);
    expect(store.values.containsKey(DatabaseEncryption.keyName), isFalse);
    expect(await count(), 3);
  });

  test('a fresh install with encryption wanted starts encrypted', () async {
    await encryption.setWanted(value: true);
    final key = await encryption.keyForOpen();
    expect(key, isNotNull);
    await seed(rows: 1, key: key);
    expect(DatabaseCipher.isEncrypted(file), isTrue);
    expect(await count(key: key), 1);
  });

  test('an encrypted file without its key cannot be opened silently; a failed change keeps the file', () async {
    await seed();
    await encryption.setWanted(value: true);
    await encryption.migrateIfNeeded();
    store.values.remove(DatabaseEncryption.keyName);
    await expectLater(encryption.keyForOpen(), throwsStateError);

    // Wrong key: the conversion fails and leaves the encrypted file as it was.
    store.values[DatabaseEncryption.keyName] = 'wrong';
    await encryption.setWanted(value: false);
    final before = file.readAsBytesSync();
    expect(await encryption.migrateIfNeeded(), EncryptionChange.failed);
    expect(file.readAsBytesSync(), before);
  });

  test('performance: encrypted vs plain (recorded in the task notes)', () async {
    await seed(rows: 20000);
    Future<Duration> measure({String? key}) async {
      final sw = Stopwatch()..start();
      final db = AppDatabase.forTesting(
        NativeDatabase(file, setup: key == null ? null : (raw) => raw.execute(DatabaseCipher.keyPragma(key))),
      );
      for (var i = 0; i < 20; i++) {
        await db.customSelect("SELECT COUNT(*) FROM categories WHERE name LIKE '%9%'").get();
      }
      await db.close();
      return sw.elapsed;
    }

    final plain = await measure();
    await encryption.setWanted(value: true);
    final convertWatch = Stopwatch()..start();
    await encryption.migrateIfNeeded();
    final conversion = convertWatch.elapsed;
    final encrypted = await measure(key: await encryption.keyForOpen());
    // ignore: avoid_print — recorded for T8.3.15.
    print(
      '20k rows: plain ${plain.inMilliseconds} ms, encrypted ${encrypted.inMilliseconds} ms, '
      'conversion ${conversion.inMilliseconds} ms',
    );
    expect(encrypted, lessThan(plain * 5 + const Duration(seconds: 1)));
  });
}
