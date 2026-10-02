import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Optional on-device encryption of the local database (T8.3.15, ADR-020).
///
/// SQLite comes from the SQLite3MultipleCiphers build (`hooks.user_defines.sqlite3.source`), so a
/// plain database opens as before and `PRAGMA key` opens an encrypted one. The key is a random
/// passphrase kept in the Keychain / Keystore (`first_unlock_this_device`: background isolates —
/// notification actions, widgets, background sync — can open the database after the first unlock).
///
/// Switching happens at startup, before anything opens the database: the file is copied,
/// the copy re-keyed, verified (quick_check + same row count in every table) and only then swapped
/// in; the original file is deleted. A failure leaves the original untouched.
class DatabaseEncryption {
  DatabaseEncryption({this._store = const FlutterSecureStore(), Future<File> Function()? file})
    : _file = file ?? defaultFile;

  final SecureStore _store;
  final Future<File> Function() _file;
  static final _log = AppLog.get('db.encryption');

  static const keyName = 'everslot.db.key';
  static const wantedName = 'everslot.db.encrypt';

  /// The app database file (`<documents>/everslot.sqlite`, as opened by drift_flutter).
  static Future<File> defaultFile() async =>
      File(p.join((await getApplicationDocumentsDirectory()).path, 'everslot.sqlite'));

  /// Whether the user asked for encryption (applied at the next start).
  Future<bool> wanted() async => await _store.read(wantedName) == 'true';

  Future<void> setWanted({required bool value}) => _store.write(wantedName, '$value');

  /// Whether the database file on disk is encrypted now.
  Future<bool> isEncrypted() async => DatabaseCipher.isEncrypted(await _file());

  /// The passphrase to open the database with (null for a plain file). A fresh install with
  /// encryption wanted starts encrypted.
  Future<String?> keyForOpen() async {
    final file = await _file();
    if (file.existsSync() && file.lengthSync() > 0) {
      if (!DatabaseCipher.isEncrypted(file)) return null;
      final key = await _store.read(keyName);
      if (key == null) throw StateError('The database is encrypted but its key is missing');
      return key;
    }
    return await wanted() ? _ensureKey() : null;
  }

  Future<String> _ensureKey() async {
    final existing = await _store.read(keyName);
    if (existing != null) return existing;
    final random = Random.secure();
    final key = base64Url.encode([for (var i = 0; i < 32; i++) random.nextInt(256)]).replaceAll('=', '');
    await _store.write(keyName, key);
    return key;
  }

  /// Applies the wanted state to the file (main isolate, before the database is opened).
  /// Returns what happened; never throws (the app keeps working on the old file).
  Future<EncryptionChange> migrateIfNeeded() async {
    try {
      final file = await _file();
      if (!file.existsSync() || file.lengthSync() == 0) return EncryptionChange.none;
      final encrypted = DatabaseCipher.isEncrypted(file);
      final want = await wanted();
      if (want && !encrypted) {
        final key = await _ensureKey();
        final path = file.path;
        await Isolate.run(() => DatabaseCipher.encrypt(path, key));
        _log.info('database encrypted');
        return EncryptionChange.encrypted;
      }
      if (!want && encrypted) {
        final key = await _store.read(keyName);
        if (key == null) return EncryptionChange.none;
        final path = file.path;
        await Isolate.run(() => DatabaseCipher.decrypt(path, key));
        await _store.delete(keyName);
        _log.info('database decrypted');
        return EncryptionChange.decrypted;
      }
    } on Object catch (e, st) {
      _log.warning('database encryption change failed', e, st);
      return EncryptionChange.failed;
    }
    return EncryptionChange.none;
  }
}

enum EncryptionChange { none, encrypted, decrypted, failed }

/// File-level operations (synchronous; run them off the UI isolate).
abstract final class DatabaseCipher {
  static final _header = ascii.encode('SQLite format 3\u0000');

  /// Plain SQLite files start with "SQLite format 3\0"; encrypted ones don't.
  static bool isEncrypted(File file) {
    if (!file.existsSync() || file.lengthSync() < 16) return false;
    final raf = file.openSync();
    try {
      final head = raf.readSync(16);
      for (var i = 0; i < 16; i++) {
        if (head[i] != _header[i]) return true;
      }
      return false;
    } finally {
      raf.closeSync();
    }
  }

  /// `PRAGMA key` statement for [key] (quotes doubled).
  static String keyPragma(String key) => "PRAGMA key = '${key.replaceAll("'", "''")}'";

  static String _rekeyPragma(String key) => "PRAGMA rekey = '${key.replaceAll("'", "''")}'";

  /// Plain → encrypted with [key].
  static void encrypt(String path, String key) => _convert(path, fromKey: null, toKey: key);

  /// Encrypted with [key] → plain.
  static void decrypt(String path, String key) => _convert(path, fromKey: key, toKey: null);

  static void _convert(String path, {required String? fromKey, required String? toKey}) {
    Database open(String file, String? key) {
      final db = sqlite3.open(file);
      if (key != null) db.execute(keyPragma(key));
      return db;
    }

    // 1. Fold the WAL into the main file so a plain copy is complete.
    final source = open(path, fromKey);
    final counts = _counts(source);
    source
      ..execute('PRAGMA wal_checkpoint(TRUNCATE)')
      ..close();

    // 2. Copy, then re-key the copy (rekey needs a rollback journal, not WAL).
    final tmp = '$path.converting';
    _deleteWithSidecars(tmp);
    File(path).copySync(tmp);
    final copy = open(tmp, fromKey);
    copy
      ..execute('PRAGMA journal_mode = DELETE')
      ..execute(_rekeyPragma(toKey ?? ''))
      ..close();

    // 3. Verify the copy opens with the new key and holds the same rows.
    final check = open(tmp, toKey);
    try {
      final ok = check.select('PRAGMA quick_check').first.values.first;
      if (ok != 'ok') throw StateError('quick_check: $ok');
      final after = _counts(check);
      if (after.length != counts.length || after.entries.any((e) => counts[e.key] != e.value)) {
        throw StateError('row counts differ after conversion');
      }
    } finally {
      check.close();
    }
    if (DatabaseCipher.isEncrypted(File(tmp)) != (toKey != null)) throw StateError('conversion had no effect');

    // 4. Swap; the old file goes away only once the new one is in place.
    final backup = '$path.previous';
    _deleteWithSidecars(backup);
    File(path).renameSync(backup);
    for (final s in const ['-wal', '-shm']) {
      final f = File('$path$s');
      if (f.existsSync()) f.deleteSync();
    }
    File(tmp).renameSync(path);
    _deleteWithSidecars(backup);
  }

  static Map<String, int> _counts(Database db) => {
    for (final r in db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND sql NOT LIKE '%VIRTUAL%'",
    ))
      r['name'] as String: db.select('SELECT COUNT(*) AS n FROM "${r['name']}"').first['n'] as int,
  };

  static void _deleteWithSidecars(String path) {
    for (final s in const ['', '-wal', '-shm', '-journal']) {
      final f = File('$path$s');
      if (f.existsSync()) f.deleteSync();
    }
  }
}
