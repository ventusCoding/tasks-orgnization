import 'package:everslot/core/database/app_database.dart';

/// Live outbox counters for Settings › Sync (T8.3.04): they change after every pushed batch, so
/// the pending count decreases while a long push runs.
class SyncOutboxQueries {
  SyncOutboxQueries(this._db);

  final AppDatabase _db;

  Stream<({int pending, int failed})> watchCounts() => _db
      .customSelect(
        "SELECT SUM(CASE WHEN state != 'failed' THEN 1 ELSE 0 END) AS p, "
        "SUM(CASE WHEN state = 'failed' THEN 1 ELSE 0 END) AS f FROM sync_outbox",
        readsFrom: {_db.syncOutbox},
      )
      .watchSingle()
      .map((r) => (pending: (r.data['p'] as int?) ?? 0, failed: (r.data['f'] as int?) ?? 0));

  /// Failed entries with their server error (newest first) for the details sheet.
  Future<List<({String table, String rowId, String? error})>> failed() async {
    final rows = await (_db.select(_db.syncOutbox)..where((o) => o.state.equals('failed'))).get();
    return [for (final r in rows.reversed) (table: r.tableName_, rowId: r.rowId, error: r.lastError)];
  }
}
