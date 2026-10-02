import 'dart:convert';

import 'package:everslot/core/database/app_database.dart';

/// Recent searches (T8.1.15): device-local only (never synced), kept in `local_kv`.
class SearchRecentsStore {
  SearchRecentsStore(this._db);

  final AppDatabase _db;

  static const key = 'search.recents';

  Future<List<String>> load() async {
    final row = await (_db.select(_db.localKv)..where((k) => k.key.equals(key))).getSingleOrNull();
    if (row == null) return const [];
    try {
      return [for (final v in jsonDecode(row.value) as List<Object?>) ?v as String?];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<String> recents) =>
      _db.into(_db.localKv).insertOnConflictUpdate(LocalKvRow(key: key, value: jsonEncode(recents)));
}
