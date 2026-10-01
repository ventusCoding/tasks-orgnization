import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/integrations/domain/external_link.dart';

/// Existence of an entity addressed by a link.
enum EntityState { live, deleted, missing }

/// Small read-only queries the integrations need and no feature exposes (T8.2.x). Everything
/// else is read through the owning feature's application API.
class IntegrationQueries {
  IntegrationQueries(this._db, this._userId);

  final AppDatabase _db;
  final String Function() _userId;

  static const _tables = {'task': 'tasks', 'checklist': 'checklists', 'habit': 'habits'};

  /// Whether [ref] exists for the current user and is live or in the trash.
  Future<EntityState> entityState(EntityRef ref) async {
    final table = _tables[ref.kind];
    if (table == null) return EntityState.missing;
    final row = await _db
        .customSelect(
          'SELECT deleted_at FROM $table WHERE id = ? AND user_id = ?',
          variables: [Variable<String>(ref.id), Variable<String>(_userId())],
        )
        .getSingleOrNull();
    if (row == null) return EntityState.missing;
    return row.data['deleted_at'] == null ? EntityState.live : EntityState.deleted;
  }

  // ------------------------------------------------------------------------ device-local prefs --

  /// Device-local value (never synced) from `local_kv`.
  Future<String?> readLocal(String key) async {
    final row = await _db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
        .getSingleOrNull();
    return row?.data['value'] as String?;
  }

  Future<void> writeLocal(String key, String? value) async {
    if (value == null) {
      await _db.customStatement('DELETE FROM local_kv WHERE key = ?', [key]);
      return;
    }
    await _db.customStatement(
      'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  Future<Map<String, Object?>> readLocalJson(String key) async {
    final raw = await readLocal(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, Object?>.from(decoded) : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> writeLocalJson(String key, Map<String, Object?> value) => writeLocal(key, jsonEncode(value));

  /// Keys with [prefix] (ledger pruning).
  Future<Map<String, String>> localWithPrefix(String prefix) async {
    final rows = await _db
        .customSelect(
          r"SELECT key, value FROM local_kv WHERE key LIKE ? ESCAPE '\'",
          variables: [Variable<String>('${prefix.replaceAll('_', r'\_').replaceAll('%', r'\%')}%')],
        )
        .get();
    return {for (final r in rows) r.data['key']! as String: r.data['value']! as String};
  }
}
