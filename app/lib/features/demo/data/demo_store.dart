import 'dart:convert';

import 'package:everslot/core/database/app_database.dart';

/// Ids of the sample data on this device (`local_kv`), for one-tap removal (T8.3.16).
class DemoStore {
  DemoStore(this._db);

  final AppDatabase _db;
  static const _key = 'demo.created';

  Future<Map<String, List<String>>> read() async {
    final row = await (_db.select(_db.localKv)..where((k) => k.key.equals(_key))).getSingleOrNull();
    if (row == null) return const {};
    final json = jsonDecode(row.value) as Map<String, Object?>;
    return {
      for (final e in json.entries) e.key: [for (final id in e.value! as List) '$id'],
    };
  }

  Future<void> write(Map<String, List<String>> ids) =>
      _db.into(_db.localKv).insertOnConflictUpdate(LocalKvRow(key: _key, value: jsonEncode(ids)));

  Future<void> clear() => (_db.delete(_db.localKv)..where((k) => k.key.equals(_key))).go();
}
