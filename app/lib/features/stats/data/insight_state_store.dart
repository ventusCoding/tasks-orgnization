/// Local-only `insight_state` (T6.7.08): one row per fired insight (dedupe key → fired at,
/// dismissed at, payload). Never synced — each device keeps its own feed.
library;

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

class InsightStateStore {
  InsightStateStore(this._db);

  final AppDatabase _db;

  Future<List<InsightStateRow>> all() => _db.select(_db.insightState).get();

  Stream<List<InsightStateRow>> watch() => _db.select(_db.insightState).watch();

  /// Records newly fired insights ([payloads]: dedupe key → JSON); existing keys are kept.
  Future<void> fire(Map<String, String> payloads, DateTime at) => _db.batch((b) {
    for (final e in payloads.entries) {
      b.insert(
        _db.insightState,
        InsightStateCompanion.insert(key: e.key, firedAt: Value(at), payload: Value(e.value)),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });

  Future<void> dismiss(String key, DateTime at) => (_db.update(
    _db.insightState,
  )..where((r) => r.key.equals(key))).write(InsightStateCompanion(dismissedAt: Value(at)));
}
