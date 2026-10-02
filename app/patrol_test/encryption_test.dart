// Local database encryption on a device (T8.3.15): the SQLite3MultipleCiphers build, the real
// Keychain / Keystore and the copy → rekey → verify → swap conversion. Run:
// `patrol test --flavor dev -t patrol_test/encryption_test.dart --dart-define-from-file=env/example.json`.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/database_encryption.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import 'support/e2e.dart';

void main() {
  patrolTest('a database file is encrypted and decrypted with the device key', config: e2eConfig, ($) async {
    // The app itself runs on the same SQLite build.
    await launchEverslot($);

    final dir = Directory('${(await getTemporaryDirectory()).path}/encryption_e2e');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/everslot.sqlite');
    final store = _NamespacedStore('e2e.');
    final encryption = DatabaseEncryption(store: store, file: () async => file);

    Future<int> count(String? key) async {
      final db = AppDatabase.forTesting(
        NativeDatabase(file, setup: key == null ? null : (raw) => raw.execute(DatabaseCipher.keyPragma(key))),
      );
      final n = (await db.customSelect('SELECT COUNT(*) AS n FROM categories').getSingle()).data['n']! as int;
      await db.close();
      return n;
    }

    final plain = AppDatabase.forTesting(NativeDatabase(file));
    for (var i = 0; i < 50; i++) {
      await plain.customStatement(
        'INSERT INTO categories (id, user_id, name, color, sort_key, created_at, updated_at, origin_device_id, '
        "field_clock) VALUES ('c$i', 'u', 'C$i', 1, 'a$i', '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z', 'd', '{}')",
      );
    }
    await plain.close();

    await encryption.setWanted(value: true);
    expect(await encryption.migrateIfNeeded(), EncryptionChange.encrypted);
    expect(DatabaseCipher.isEncrypted(file), isTrue);
    expect(await count(await encryption.keyForOpen()), 50);

    await encryption.setWanted(value: false);
    expect(await encryption.migrateIfNeeded(), EncryptionChange.decrypted);
    expect(await count(null), 50);
    await store.delete(DatabaseEncryption.wantedName);
    dir.deleteSync(recursive: true);
  });
}

/// The real secure store under a test prefix (keeps the app's own key untouched).
class _NamespacedStore implements SecureStore {
  _NamespacedStore(this.prefix);

  final String prefix;
  final _inner = const FlutterSecureStore();

  @override
  Future<String?> read(String key) => _inner.read('$prefix$key');

  @override
  Future<void> write(String key, String value) => _inner.write('$prefix$key', value);

  @override
  Future<void> delete(String key) => _inner.delete('$prefix$key');
}
