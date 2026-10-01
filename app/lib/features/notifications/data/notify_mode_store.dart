import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';

/// Reads / writes the `notify_mode` column of the host tables (tasks, checklists,
/// checklist_items, habits) for the notification section component (T7.1.09). Only this column
/// is touched, always through [SyncWriter].
class NotifyModeStore {
  NotifyModeStore(this._db, this._writer);

  final AppDatabase _db;
  final SyncWriter _writer;

  static String? tableFor(RuleTargetType type) => switch (type) {
    RuleTargetType.task => 'tasks',
    RuleTargetType.checklist => 'checklists',
    RuleTargetType.checklistItem => 'checklist_items',
    RuleTargetType.habit => 'habits',
    _ => null,
  };

  TableInfo<Table, Object?>? _info(String table) {
    for (final t in _db.allTables) {
      if (t.actualTableName == table) return t;
    }
    return null;
  }

  Stream<NotifyMode?> watch(RuleTargetType type, String id) {
    final table = tableFor(type);
    final info = table == null ? null : _info(table);
    if (table == null || info == null) return Stream.value(null);
    return _db
        .customSelect(
          'SELECT notify_mode FROM $table WHERE id = ?',
          variables: [Variable<String>(id)],
          readsFrom: {info},
        )
        .watchSingleOrNull()
        .map((row) => row == null ? null : NotifyMode.parse(row.data['notify_mode'] as String?));
  }

  /// Writes inside an existing transaction (Customize snapshot, host editors).
  Future<void> setInTx(WriteTx tx, RuleTargetType type, String id, NotifyMode mode) async {
    final table = tableFor(type);
    if (table == null || !await tx.exists(table, id)) return;
    await tx.update(table, id, {'notify_mode': mode.wire});
  }

  Future<OpRecord> set(RuleTargetType type, String id, NotifyMode mode) =>
      _writer.run((tx) => setInTx(tx, type, id, mode));
}
