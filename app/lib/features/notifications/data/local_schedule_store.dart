import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';

/// Local-only `local_notification_schedule` table (arch §6.13). Not synced → plain Drift writes.
///
/// The table has the core columns only; extra scheduler metadata (kind, hash, expiry, channel,
/// merge members, reconciliation marker, inbox content) lives in the `payload` JSON.
class LocalScheduleStore {
  LocalScheduleStore(this._db);

  final AppDatabase _db;

  static ScheduleEntry _map(LocalNotificationScheduleRow r) =>
      ScheduleEntry.fromRow(
        dedupeKey: r.dedupeKey,
        platformId: r.platformId,
        fireAt: r.fireAt,
        targetKey: r.targetKey,
        payload: r.payload,
        repeating: r.repeating,
        scheduledAt: r.scheduledAt,
      );

  Future<List<ScheduleEntry>> all() async => (await (_db.select(
    _db.localNotificationSchedule,
  )..orderBy([(s) => OrderingTerm.asc(s.fireAt)])).get()).map(_map).toList();

  Stream<List<ScheduleEntry>> watchAll() =>
      (_db.select(_db.localNotificationSchedule)
            ..orderBy([(s) => OrderingTerm.asc(s.fireAt)]))
          .watch()
          .map((rows) => rows.map(_map).toList());

  Future<ScheduleEntry?> byKey(String dedupeKey) async {
    final row = await (_db.select(
      _db.localNotificationSchedule,
    )..where((s) => s.dedupeKey.equals(dedupeKey))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<ScheduleEntry?> byPlatformId(int id) async {
    final row = await (_db.select(
      _db.localNotificationSchedule,
    )..where((s) => s.platformId.equals(id))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<Set<int>> usedPlatformIds() async => {
    for (final e in await all()) e.platformId,
  };

  Future<void> put(ScheduleEntry e) => _db
      .into(_db.localNotificationSchedule)
      .insertOnConflictUpdate(
        LocalNotificationScheduleCompanion.insert(
          dedupeKey: e.dedupeKey,
          platformId: e.platformId,
          fireAt: e.fireAt.toUtc(),
          targetKey: e.targetKey,
          payload: Value(e.encodePayload()),
          repeating: Value(e.repeating),
          scheduledAt: e.scheduledAt.toUtc(),
        ),
      );

  Future<void> putAll(Iterable<ScheduleEntry> entries) =>
      _db.transaction(() async {
        for (final e in entries) {
          await put(e);
        }
      });

  Future<void> remove(Iterable<String> keys) async {
    final list = keys.toList();
    if (list.isEmpty) return;
    await (_db.delete(
      _db.localNotificationSchedule,
    )..where((s) => s.dedupeKey.isIn(list))).go();
  }

  Future<void> clear() => _db.delete(_db.localNotificationSchedule).go();

  /// Fired rows not yet written to the inbox (reconciliation, T7.3.02).
  Future<List<ScheduleEntry>> dueUnreconciled(DateTime now) async => [
    for (final e in await all())
      if (!e.fireAt.isAfter(now) && e.reconciledAt == null && e.createsInboxRow)
        e,
  ];

  /// Deletes reconciled / fired rows older than [age] (T7.3.10: markers kept 14 days).
  Future<int> cleanup(
    DateTime now, {
    Duration age = const Duration(days: 14),
  }) async {
    final cutoff = now.subtract(age);
    return (_db.delete(
      _db.localNotificationSchedule,
    )..where((s) => s.fireAt.isSmallerThanValue(cutoff))).go();
  }
}
