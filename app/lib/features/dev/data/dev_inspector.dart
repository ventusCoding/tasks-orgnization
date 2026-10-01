import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/dev/domain/dev_models.dart';

/// Read-only views of the local database for the dev debug menu (T1.3.16) and sync diagnostics
/// (T1.4.18).
class DevInspector {
  DevInspector(this._db);

  final AppDatabase _db;

  /// Row counts of every local table (FTS index included), by name.
  Future<List<TableCount>> tableCounts() async {
    final names = {for (final t in _db.allTables) t.actualTableName, 'search_index'}.toList()..sort();
    return [
      for (final n in names)
        TableCount(n, (await _db.customSelect('SELECT COUNT(*) AS n FROM "$n"').getSingle()).data['n'] as int),
    ];
  }

  /// The first [limit] rows of [table] (column → value); unknown tables yield nothing.
  Future<List<Map<String, Object?>>> sampleRows(String table, {int limit = 20}) async {
    final known = {for (final t in _db.allTables) t.actualTableName};
    if (!known.contains(table)) return const [];
    final rows = await _db.customSelect('SELECT * FROM "$table" LIMIT ?', variables: [Variable<int>(limit)]).get();
    return [for (final r in rows) Map<String, Object?>.from(r.data)];
  }

  /// Live outbox, in push order.
  Stream<List<OutboxEntryView>> watchOutbox() => (_db.select(
    _db.syncOutbox,
  )..orderBy([(o) => OrderingTerm.asc(o.seq)])).watch().map((rows) => [for (final r in rows) _entry(r)]);

  static OutboxEntryView _entry(OutboxRow r) {
    var fields = const <String>[];
    try {
      final decoded = jsonDecode(r.fields);
      if (decoded is Map) fields = [for (final k in decoded.keys) '$k'];
    } on FormatException {
      // Unreadable patch: show no field names.
    }
    return OutboxEntryView(
      changeId: r.changeId,
      opId: r.opId,
      seq: r.seq,
      table: r.tableName_,
      rowId: r.rowId,
      op: r.op,
      fields: fields,
      state: r.state,
      attempts: r.attempts,
      enqueuedAt: r.enqueuedAt.toUtc(),
      lastError: r.lastError,
    );
  }

  /// Live sync cursor of [userId].
  Stream<SyncStateView?> watchSyncState(String userId) =>
      (_db.select(_db.syncState)..where((s) => s.userId.equals(userId))).watchSingleOrNull().map(
        (s) => s == null
            ? null
            : SyncStateView(
                cursor: s.cursor,
                purgeWatermarkSeen: s.purgeWatermarkSeen,
                lastPushAt: s.lastPushAt?.toUtc(),
                lastPullAt: s.lastPullAt?.toUtc(),
                lastSuccessAt: s.lastSuccessAt?.toUtc(),
                lastError: s.lastError,
              ),
      );
}
