import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/time/clock.dart';

/// Cross-isolate mutex for sync runs (T1.4.17): a lease row in `local_kv`.
///
/// The foreground [SyncService] and the background task (workmanager / FCM data message) open
/// the same SQLite file; acquiring is one atomic UPSERT, so two isolates can never push or pull
/// at the same time. A lease expires after its TTL so a killed isolate never blocks sync forever.
class SyncLock {
  SyncLock(this._db, {required this.owner, required Clock clock}) : _clock = clock;

  static const key = 'sync_lock';

  final AppDatabase _db;
  final Clock _clock;

  /// Unique id of this lock holder (e.g. `fg-<uuid>` or `bg-<uuid>`).
  final String owner;

  /// Tries to take (or renew) the lease for [ttl]. Returns false when another live owner holds it.
  Future<bool> tryAcquire({Duration ttl = const Duration(minutes: 2)}) async {
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    final value = '$owner|${now + ttl.inMilliseconds}';
    await _db.customStatement(
      'INSERT INTO local_kv(key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value '
      "WHERE CAST(substr(local_kv.value, instr(local_kv.value, '|') + 1) AS INTEGER) < ? "
      "OR substr(local_kv.value, 1, instr(local_kv.value, '|') - 1) = ?",
      [key, value, now, owner],
    );
    return (await holder()) == owner;
  }

  /// Releases the lease if this owner holds it.
  Future<void> release() => _db.customStatement(
    "DELETE FROM local_kv WHERE key = ? AND substr(value, 1, instr(value, '|') - 1) = ?",
    [key, owner],
  );

  /// Current live holder, or null when free/expired.
  Future<String?> holder() async {
    final row = await _db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
        .getSingleOrNull();
    final raw = row?.data['value'] as String?;
    if (raw == null) return null;
    final sep = raw.lastIndexOf('|');
    if (sep < 0) return null;
    final expires = int.tryParse(raw.substring(sep + 1)) ?? 0;
    if (expires < _clock.nowUtc().millisecondsSinceEpoch) return null;
    return raw.substring(0, sep);
  }
}
