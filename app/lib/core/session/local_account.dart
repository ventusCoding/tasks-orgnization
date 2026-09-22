import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';

/// Local-only account used when Supabase isn't configured (or before signing in).
abstract final class LocalAccount {
  static const _key = 'local_user_id';

  static Future<String> ensureUserId(AppDatabase db) async {
    final row = await (db.select(db.localKv)..where((k) => k.key.equals(_key))).getSingleOrNull();
    if (row != null) return row.value;
    final id = Ids.v7();
    await db.into(db.localKv).insertOnConflictUpdate(LocalKvRow(key: _key, value: id));
    return id;
  }

  /// Re-assigns every locally created row to [cloudUserId] after the first cloud sign-in so
  /// offline-created data is pushed to the new account (outbox entries are kept).
  static Future<void> claimForCloudUser(AppDatabase db, String cloudUserId) async {
    final local = await (db.select(db.localKv)..where((k) => k.key.equals(_key))).getSingleOrNull();
    if (local == null || local.value == cloudUserId) return;
    await db.transaction(() async {
      for (final table in db.allTables) {
        final hasUserId = table.$columns.any((c) => c.name == 'user_id');
        if (!hasUserId) continue;
        await db.customStatement(
          'UPDATE ${table.actualTableName} SET user_id = ? WHERE user_id = ?',
          [cloudUserId, local.value],
        );
      }
      await db.customStatement('UPDATE profiles SET id = ? WHERE id = ?', [cloudUserId, local.value]);
      await db.into(db.localKv).insertOnConflictUpdate(LocalKvRow(key: _key, value: cloudUserId));
    });
  }
}
