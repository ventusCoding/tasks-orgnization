import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

/// Which cloud account the local database (synced rows + outbox) belongs to (T1.5.08).
///
/// Set once the local data has been claimed (first sign-in) or wiped (another account signed in
/// on this device). The sync engine refuses to run while it doesn't match the signed-in user, so
/// one account's outbox can never be pushed under another account.
abstract final class LocalDataOwner {
  static const key = 'data_owner';

  static Future<String?> read(AppDatabase db) async {
    final row = await db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
        .getSingleOrNull();
    final value = row?.data['value'] as String?;
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> write(AppDatabase db, String userId) => db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) '
    'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, userId],
  );

  static Future<void> clear(AppDatabase db) =>
      db.customStatement('DELETE FROM local_kv WHERE key = ?', [key]);

  /// True when the local data is bound to [userId].
  static Future<bool> matches(AppDatabase db, String userId) async =>
      userId.isNotEmpty && await read(db) == userId;
}
