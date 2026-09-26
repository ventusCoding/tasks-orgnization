import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

/// "Use on this device only" chosen on the sign-in screen while cloud sync IS configured
/// (e.g. offline at first launch). Bootstrap then starts a local-only session instead of the
/// sign-in screen; signing in later claims the local data (ADR-017).
abstract final class LocalOnlyChoice {
  static const key = 'local_only_opt_in';

  static Future<bool> isChosen(AppDatabase db) async {
    final row = await db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
        .getSingleOrNull();
    return row?.data['value'] == '1';
  }

  static Future<void> choose(AppDatabase db) => db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, '1'],
  );

  static Future<void> clear(AppDatabase db) =>
      db.customStatement('DELETE FROM local_kv WHERE key = ?', [key]);
}
