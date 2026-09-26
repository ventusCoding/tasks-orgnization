/// Device-local Insights UI state (T6.1.17): last segment and period per scope, stored in the
/// local-only `local_kv` table (never synced).
library;

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

class StatsLocalStore {
  StatsLocalStore(this._db);

  final AppDatabase _db;

  static const _prefix = 'stats.ui.';

  Future<Map<String, String>> readAll() async {
    final rows = await (_db.select(_db.localKv)..where((k) => k.key.like('$_prefix%'))).get();
    return {for (final r in rows) r.key.substring(_prefix.length): r.value};
  }

  Future<void> write(String key, String value) =>
      _db.into(_db.localKv).insertOnConflictUpdate(LocalKvCompanion.insert(key: '$_prefix$key', value: value));
}
