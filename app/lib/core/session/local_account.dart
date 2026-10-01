import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/table_registry.dart';

/// Derives the deterministic id of a user-scoped row (arch §9.2) for [userId] and [key].
typedef UserScopedIdRule = ({String Function(String userId, String key) derive, List<String> keys});

/// Local-only account used when Supabase isn't configured (or before signing in).
abstract final class LocalAccount {
  static const _key = 'local_user_id';

  /// Deterministic ids derived from the user id that must be re-derived when local data is claimed
  /// by a cloud account (otherwise lookups by `Ids.xxx(cloudUserId, key)` miss the rows and seeding
  /// creates duplicates). Features with their own user-scoped defaults register here.
  static final List<UserScopedIdRule> userScopedIdRules = [
    // Keep in sync with CategoriesRepository.seedDefaults (organization feature).
    (derive: Ids.defaultCategory, keys: const ['work', 'personal', 'health', 'study', 'home', 'social']),
  ];

  static Future<String> ensureUserId(AppDatabase db) async {
    final row = await (db.select(db.localKv)..where((k) => k.key.equals(_key))).getSingleOrNull();
    if (row != null) return row.value;
    final id = Ids.v7();
    await db.into(db.localKv).insertOnConflictUpdate(LocalKvRow(key: _key, value: id));
    return id;
  }

  /// The local account id, if one was ever created on this device.
  static Future<String?> current(AppDatabase db) async =>
      (await (db.select(db.localKv)..where((k) => k.key.equals(_key))).getSingleOrNull())?.value;

  /// Forgets the local account (after a full local wipe).
  static Future<void> forget(AppDatabase db) => (db.delete(db.localKv)..where((k) => k.key.equals(_key))).go();

  /// Re-assigns every locally created row to [cloudUserId] after the first cloud sign-in so
  /// offline-created data is pushed to the new account (outbox entries are kept).
  ///
  /// User-derived deterministic ids (profile = user id, `user_settings` per namespace, default
  /// categories, built-in notification profiles and [userScopedIdRules]) are re-derived for the
  /// cloud user; references to them (`*_id` columns, JSON columns, outbox row ids and patch
  /// fields) are rewritten in the same transaction.
  static Future<void> claimForCloudUser(AppDatabase db, String cloudUserId) async {
    final local = await current(db);
    if (local == null || local == cloudUserId) return;
    await db.transaction(() async {
      final rekeys = <String, String>{local: cloudUserId};
      final settings = await db
          .customSelect(
            'SELECT id, namespace FROM user_settings WHERE user_id = ?',
            variables: [Variable<String>(local)],
          )
          .get();
      for (final s in settings) {
        final ns = s.data['namespace'] as String;
        if (s.data['id'] == Ids.userSetting(local, ns)) {
          rekeys[s.data['id'] as String] = Ids.userSetting(cloudUserId, ns);
        }
      }
      final profiles = await db
          .customSelect(
            'SELECT id, code FROM notification_profiles WHERE user_id = ? AND code IS NOT NULL',
            variables: [Variable<String>(local)],
          )
          .get();
      for (final p in profiles) {
        final code = p.data['code'] as String;
        if (p.data['id'] == Ids.builtinProfile(local, code)) {
          rekeys[p.data['id'] as String] = Ids.builtinProfile(cloudUserId, code);
        }
      }
      for (final rule in userScopedIdRules) {
        for (final key in rule.keys) {
          final old = rule.derive(local, key);
          if (await _existsAnywhere(db, old)) rekeys[old] = rule.derive(cloudUserId, key);
        }
      }

      final jsonColumns = {for (final s in syncedTableSpecs) s.name: s.jsonColumns};
      for (final table in db.allTables) {
        final name = table.actualTableName;
        final columns = table.$columns;
        if (columns.any((c) => c.name == 'user_id')) {
          await db.customStatement('UPDATE $name SET user_id = ? WHERE user_id = ?', [cloudUserId, local]);
        }
        final idColumns = [
          for (final c in columns)
            if (c.type == DriftSqlType.string && (c.name == 'id' || c.name.endsWith('_id')) && c.name != 'user_id')
              c.name,
        ];
        for (final e in rekeys.entries) {
          for (final column in idColumns) {
            await db.customStatement('UPDATE $name SET $column = ? WHERE $column = ?', [e.value, e.key]);
          }
          for (final column in jsonColumns[name] ?? const <String>{}) {
            await db.customStatement('UPDATE $name SET $column = replace($column, ?, ?) WHERE instr($column, ?) > 0', [
              '"${e.key}"',
              '"${e.value}"',
              e.key,
            ]);
          }
        }
      }
      for (final e in rekeys.entries) {
        await db.customStatement('UPDATE sync_outbox SET row_id = ? WHERE row_id = ?', [e.value, e.key]);
        await db.customStatement('UPDATE sync_outbox SET fields = replace(fields, ?, ?) WHERE instr(fields, ?) > 0', [
          '"${e.key}"',
          '"${e.value}"',
          e.key,
        ]);
      }
      await db.into(db.localKv).insertOnConflictUpdate(LocalKvRow(key: _key, value: cloudUserId));
    });
    db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
  }

  static Future<bool> _existsAnywhere(AppDatabase db, String id) async {
    for (final spec in syncedTableSpecs) {
      final row = await db
          .customSelect('SELECT 1 AS x FROM ${spec.name} WHERE id = ? LIMIT 1', variables: [Variable<String>(id)])
          .getSingleOrNull();
      if (row != null) return true;
    }
    return false;
  }
}
