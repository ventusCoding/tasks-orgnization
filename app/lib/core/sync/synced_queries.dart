import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

/// Base read helpers for every synced table (T1.4.02): tombstones (`deleted_at`) and other
/// users' rows never appear. Writes go through `SyncWriter` (`softDelete`, `restore`).
///
/// ```dart
/// db.watchActive(db.categories, userId: uid, orderBy: (t) => OrderingTerm.asc(t.sortKey));
/// ```
extension SyncedQueries on AppDatabase {
  /// Live non-deleted rows of [userId] in [table].
  Stream<List<D>> watchActive<T extends Table, D>(
    TableInfo<T, D> table, {
    required String userId,
    OrderingTerm Function(T t)? orderBy,
  }) => _active(table, userId, orderBy).watch();

  /// Non-deleted rows of [userId] in [table] (one-shot).
  Future<List<D>> getActive<T extends Table, D>(
    TableInfo<T, D> table, {
    required String userId,
    OrderingTerm Function(T t)? orderBy,
  }) => _active(table, userId, orderBy).get();

  /// The row [id] of [table] (tombstoned rows included when [includeDeleted]).
  Future<D?> getById<T extends Table, D>(TableInfo<T, D> table, String id, {bool includeDeleted = false}) {
    final q = select(table)
      ..where((t) {
        final c = t as SyncedColumns;
        final byId = c.id.equals(id);
        return includeDeleted ? byId : byId & c.deletedAt.isNull();
      });
    return q.getSingleOrNull();
  }

  SimpleSelectStatement<T, D> _active<T extends Table, D>(
    TableInfo<T, D> table,
    String userId,
    OrderingTerm Function(T t)? orderBy,
  ) {
    final q = select(table)
      ..where((t) {
        final c = t as SyncedColumns;
        return c.deletedAt.isNull() & c.userId.equals(userId);
      });
    if (orderBy != null) q.orderBy([orderBy]);
    return q;
  }
}
