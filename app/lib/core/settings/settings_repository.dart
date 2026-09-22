import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';

/// Settings namespaces (arch §8.5).
abstract final class SettingsNs {
  static const appearance = 'appearance';
  static const regional = 'regional';
  static const planner = 'planner';
  static const checklists = 'checklists';
  static const habits = 'habits';
  static const stats = 'stats';
  static const notifications = 'notifications';
  static const privacy = 'privacy';
  static const today = 'today';
}

/// Typed-by-convention access to `user_settings` (one synced row per namespace, T8.3.01).
///
/// Values are JSON maps with a `"v"` version. Unknown keys are preserved on update.
class SettingsRepository {
  SettingsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  Stream<Map<String, dynamic>> watch(String namespace) {
    final id = Ids.userSetting(_userId(), namespace);
    return (_db.select(_db.userSettings)
          ..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
        .watchSingleOrNull()
        .map((row) => row == null ? <String, dynamic>{} : _decode(row.value));
  }

  Future<Map<String, dynamic>> read(String namespace) async {
    final id = Ids.userSetting(_userId(), namespace);
    final row = await (_db.select(_db.userSettings)..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? <String, dynamic>{} : _decode(row.value);
  }

  /// Merges [patch] into the namespace (keys with `null` values are removed).
  Future<void> update(String namespace, Map<String, Object?> patch) async {
    final current = await read(namespace);
    final merged = <String, Object?>{'v': 1, ...current};
    for (final e in patch.entries) {
      if (e.value == null) {
        merged.remove(e.key);
      } else {
        merged[e.key] = e.value;
      }
    }
    final id = Ids.userSetting(_userId(), namespace);
    await _writer.run((tx) => tx.upsert('user_settings', id, {
      'namespace': namespace,
      'value': merged,
    }));
  }

  static Map<String, dynamic> _decode(String value) {
    try {
      final d = jsonDecode(value);
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }
}

/// Convenience readers with defaults.
extension SettingsMapX on Map<String, dynamic> {
  T get<T>(String key, T fallback) {
    final v = this[key];
    if (v is T) return v;
    if (T == double && v is num) return v.toDouble() as T;
    if (T == int && v is num) return v.toInt() as T;
    return fallback;
  }
}

