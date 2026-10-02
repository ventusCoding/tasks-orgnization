import 'package:everslot/core/database/app_database.dart';

/// Device-local bookkeeping of rating prompts (`local_kv`; never synced: the OS throttles per
/// device too).
class ReviewPromptStore {
  ReviewPromptStore(this._db);

  final AppDatabase _db;

  static const _lastKey = 'review.last_prompt_at';

  Future<DateTime?> lastPromptAt() => _read(_lastKey);

  Future<void> setLastPromptAt(DateTime at) => _write(_lastKey, at);

  Future<DateTime?> _read(String key) async {
    final row = await (_db.select(_db.localKv)..where((k) => k.key.equals(key))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value)?.toUtc();
  }

  Future<void> _write(String key, DateTime at) =>
      _db.into(_db.localKv).insertOnConflictUpdate(LocalKvRow(key: key, value: at.toUtc().toIso8601String()));
}
