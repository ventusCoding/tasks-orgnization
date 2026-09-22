import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter/foundation.dart';

/// Client sync engine (T1.4.10–T1.4.15): pushes outbox patches, pulls changes by per-user
/// revision cursor, applies them field by field and keeps a status for the UI.
///
/// Rules (arch §6.6): the cursor is the server revision — never timestamps; fields with pending
/// local patches are never overwritten by a pull; operation groups are never split.
class SyncService {
  SyncService({
    required this.db,
    required this.registry,
    required this.api,
    required this.hlc,
    required this.clock,
    required this.userId,
    required this.deviceId,
    required this.appBuild,
    this.schemaVersion = 1,
    this.batchSize = 500,
    this.pageSize = 1000,
    this.tombstoneRetention = const Duration(days: 90),
  });

  final AppDatabase db;
  final TableRegistry registry;
  final SyncApi api;
  final Hlc hlc;
  final Clock clock;
  final String Function() userId;
  final String deviceId;
  final int appBuild;
  final int schemaVersion;
  final int batchSize;
  final int pageSize;
  final Duration tombstoneRetention;

  static final _log = AppLog.get('sync');

  final ValueNotifier<SyncStatus> status = ValueNotifier(
    const SyncStatus(phase: SyncPhase.idle),
  );

  Timer? _pushDebounce;
  Timer? _pullDebounce;
  Timer? _periodic;
  Completer<void>? _running;
  int _failures = 0;
  bool _disposed = false;

  /// Starts periodic foreground sync.
  void start({Duration interval = const Duration(minutes: 5)}) {
    _periodic?.cancel();
    _periodic = Timer.periodic(interval, (_) => unawaited(syncNow()));
    unawaited(syncNow());
  }

  void stop() {
    _periodic?.cancel();
    _pushDebounce?.cancel();
    _pullDebounce?.cancel();
  }

  void dispose() {
    _disposed = true;
    stop();
    status.dispose();
  }

  /// Debounced push after local writes.
  void schedulePush([Duration delay = const Duration(milliseconds: 1500)]) {
    _pushDebounce?.cancel();
    _pushDebounce = Timer(delay, () => unawaited(syncNow()));
    unawaited(_refreshPendingCount());
  }

  /// Debounced pull (Broadcast nudges, data pushes).
  void schedulePull([Duration delay = const Duration(milliseconds: 400)]) {
    _pullDebounce?.cancel();
    _pullDebounce = Timer(delay, () => unawaited(syncNow()));
  }

  /// Push then pull, single-flight.
  Future<void> syncNow() async {
    if (_disposed) return;
    if (_running != null) return _running!.future;
    final completer = _running = Completer<void>();
    try {
      await _push();
      await _pull();
      _failures = 0;
      _set(status.value.copyWith(
        phase: SyncPhase.idle,
        lastSuccessAt: clock.nowUtc(),
        clearError: true,
        clearProgress: true,
      ));
    } on Object catch (e, st) {
      _failures++;
      final offline = _looksOffline(e);
      _log.warning('sync failed (${_failures}x)', e, st);
      _set(status.value.copyWith(
        phase: offline ? SyncPhase.offline : SyncPhase.error,
        lastError: e.toString(),
        clearProgress: true,
      ));
      _scheduleRetry();
    } finally {
      await _refreshPendingCount();
      completer.complete();
      _running = null;
    }
  }

  void _scheduleRetry() {
    final base = min(300, pow(2, _failures).toInt() * 2);
    final jitter = Random().nextInt(max(1, base ~/ 2));
    _pushDebounce?.cancel();
    _pushDebounce = Timer(Duration(seconds: base + jitter), () => unawaited(syncNow()));
  }

  // ---------------------------------------------------------------------------------- push --

  Future<void> _push() async {
    while (true) {
      final batch = await _nextBatch();
      if (batch.isEmpty) return;
      _set(status.value.copyWith(phase: SyncPhase.pushing));
      final versions = {for (final r in batch) r.changeId: r.entryVersion};
      await db.customUpdate(
        "UPDATE sync_outbox SET state = 'inflight', attempts = attempts + 1 "
        'WHERE change_id IN (${List.filled(batch.length, '?').join(',')})',
        variables: [for (final r in batch) Variable<String>(r.changeId)],
        updates: {db.syncOutbox},
      );
      final PushResponse response;
      try {
        response = await api.push(
          deviceId: deviceId,
          schema: schemaVersion,
          build: appBuild,
          changes: [
            for (final r in batch)
              {
                'id': r.changeId,
                'g': r.opId,
                't': r.tableName_,
                'op': r.op,
                'row_id': r.rowId,
                'fields': jsonDecode(r.fields),
                'clock': jsonDecode(r.clock),
              },
          ],
        );
      } on Object {
        await db.customUpdate(
          "UPDATE sync_outbox SET state = 'pending' WHERE state = 'inflight'",
          updates: {db.syncOutbox},
        );
        rethrow;
      }
      final byId = {for (final r in batch) r.changeId: r};
      final refetch = <String, Set<String>>{};
      await db.transaction(() async {
        for (final result in response.results) {
          final entry = byId[result.changeId];
          if (entry == null) continue;
          final current = await (db.select(db.syncOutbox)
                ..where((o) => o.changeId.equals(result.changeId)))
              .getSingleOrNull();
          final modified = current != null && current.entryVersion != versions[result.changeId];
          switch (result.status) {
            case 'applied' || 'partial' || 'stale':
              if (modified) {
                await _setState(result.changeId, 'pending');
              } else {
                await _deleteEntry(result.changeId);
              }
            case 'rejected' when result.code == 'integrity_refetch':
              refetch.putIfAbsent(entry.tableName_, () => {}).add(entry.rowId);
              await _deleteEntry(result.changeId);
            case 'rejected' when result.code == 'unsupported_client':
              await _setState(result.changeId, 'pending');
              throw StateError('unsupported_client');
            default:
              await (db.update(db.syncOutbox)..where((o) => o.changeId.equals(result.changeId)))
                  .write(SyncOutboxCompanion(
                    state: const Value('failed'),
                    lastError: Value('${result.code}: ${result.message}'),
                  ));
          }
        }
        // Anything the server didn't mention goes back to pending.
        await db.customUpdate(
          "UPDATE sync_outbox SET state = 'pending' WHERE state = 'inflight'",
          updates: {db.syncOutbox},
        );
      });
      for (final e in refetch.entries) {
        await _refetchRows(e.key, e.value.toList());
      }
      await _saveState(lastPushAt: clock.nowUtc());
    }
  }

  Future<List<OutboxRow>> _nextBatch() async {
    final pending = await (db.select(db.syncOutbox)
          ..where((o) => o.state.equals('pending'))
          ..orderBy([(o) => OrderingTerm.asc(o.seq)])
          ..limit(batchSize * 2))
        .get();
    if (pending.isEmpty) return const [];
    // Keep whole operation groups together.
    final byGroup = <String, List<OutboxRow>>{};
    final order = <String>[];
    for (final row in pending) {
      if (!byGroup.containsKey(row.opId)) order.add(row.opId);
      byGroup.putIfAbsent(row.opId, () => []).add(row);
    }
    final batch = <OutboxRow>[];
    for (final group in order) {
      final rows = byGroup[group]!;
      if (batch.isNotEmpty && batch.length + rows.length > batchSize) break;
      // Make sure the group is complete (it may have been cut by the limit above).
      final all = await (db.select(db.syncOutbox)
            ..where((o) => o.opId.equals(group) & o.state.equals('pending'))
            ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
          .get();
      batch.addAll(all);
      if (batch.length >= batchSize) break;
    }
    return batch;
  }

  Future<void> _setState(String changeId, String state) =>
      (db.update(db.syncOutbox)..where((o) => o.changeId.equals(changeId)))
          .write(SyncOutboxCompanion(state: Value(state)));

  Future<void> _deleteEntry(String changeId) =>
      (db.delete(db.syncOutbox)..where((o) => o.changeId.equals(changeId))).go();

  // ---------------------------------------------------------------------------------- pull --

  Future<void> _pull() async {
    final state = await _loadState();
    var cursor = state?.cursor ?? 0;
    final lastSuccess = state?.lastSuccessAt;
    final full =
        cursor == 0 ||
        (lastSuccess != null && clock.nowUtc().difference(lastSuccess) > tombstoneRetention);
    if (full) cursor = 0;
    final seen = full ? <String, Set<String>>{} : null;
    var first = true;
    while (true) {
      _set(status.value.copyWith(phase: SyncPhase.pulling));
      final page = await api.pull(since: cursor, limit: pageSize);
      if (first && !full && page.purgeWatermark > cursor && cursor > 0) {
        // Our cursor predates purged tombstones → full resync.
        _log.info('cursor $cursor < purge watermark ${page.purgeWatermark}: full resync');
        await _saveState(cursor: 0);
        return _pull();
      }
      first = false;
      await _applyPage(page, seen);
      cursor = page.next;
      await _saveState(cursor: cursor, lastPullAt: clock.nowUtc());
      if (full) {
        _set(status.value.copyWith(initialSyncProgress: page.more ? 0.5 : 1));
      }
      if (!page.more) break;
    }
    if (seen != null) await _dropUnseenAfterFullSync(seen);
  }

  Future<void> _applyPage(PullPage page, Map<String, Set<String>>? seen) async {
    final touched = <TableInfo<Table, Object?>>{};
    await db.transaction(() async {
      for (final change in page.changes) {
        if (!registry.isSynced(change.table)) {
          _log.warning('pull: unknown table ${change.table} (newer server?) — skipped');
          continue;
        }
        final t = registry[change.table];
        final id = change.row['id'] as String?;
        if (id == null) continue;
        seen?.putIfAbsent(t.name, () => {}).add(id);
        final values = <String, Object?>{};
        for (final column in t.columns) {
          if (!change.row.containsKey(column)) continue;
          values[column] = t.serverToSqlite(column, change.row[column]);
        }
        final clockJson = change.row['field_clock'];
        if (clockJson is Map) {
          for (final v in clockJson.values) {
            if (v is String) hlc.observe(v);
          }
        }
        final pending = await _pendingFields(t.name, id);
        final existing = await db
            .customSelect('SELECT id FROM ${t.name} WHERE id = ?', variables: [Variable<String>(id)])
            .getSingleOrNull();
        if (existing == null) {
          final cols = values.keys.toList();
          await db.customStatement(
            'INSERT INTO ${t.name} (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
            [for (final c in cols) values[c]],
          );
        } else {
          final cols = values.keys.where((c) => c != 'id' && !pending.contains(c)).toList();
          if (cols.isNotEmpty) {
            await db.customStatement(
              'UPDATE ${t.name} SET ${cols.map((c) => '$c = ?').join(', ')} WHERE id = ?',
              [for (final c in cols) values[c], id],
            );
          }
        }
        touched.add(t.info);
      }
    });
    if (touched.isNotEmpty) {
      db.notifyUpdates({for (final t in touched) TableUpdate.onTable(t)});
    }
  }

  Future<Set<String>> _pendingFields(String table, String rowId) async {
    final rows = await db
        .customSelect(
          "SELECT fields FROM sync_outbox WHERE table_name = ? AND row_id = ? AND state != 'failed'",
          variables: [Variable<String>(table), Variable<String>(rowId)],
        )
        .get();
    final fields = <String>{};
    for (final r in rows) {
      final decoded = jsonDecode(r.data['fields'] as String);
      if (decoded is Map) fields.addAll(decoded.keys.cast<String>());
    }
    return fields;
  }

  Future<void> _dropUnseenAfterFullSync(Map<String, Set<String>> seen) async {
    for (final t in registry.tables) {
      final ids = seen[t.name] ?? const <String>{};
      final local = await db
          .customSelect('SELECT id FROM ${t.name} WHERE rev > 0')
          .get();
      final stale = [
        for (final r in local)
          if (!ids.contains(r.data['id'])) r.data['id'] as String,
      ];
      for (final id in stale) {
        if ((await _pendingFields(t.name, id)).isNotEmpty) continue;
        await db.customStatement('DELETE FROM ${t.name} WHERE id = ?', [id]);
      }
      if (stale.isNotEmpty) db.notifyUpdates({TableUpdate.onTable(t.info)});
    }
  }

  Future<void> _refetchRows(String table, List<String> ids) async {
    final rows = await api.fetchRows(table, ids);
    final t = registry[table];
    await db.transaction(() async {
      for (final row in rows) {
        final cols = [for (final c in t.columns) if (row.containsKey(c)) c];
        await db.customStatement(
          'INSERT OR REPLACE INTO $table (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
          [for (final c in cols) t.serverToSqlite(c, row[c])],
        );
      }
    });
    db.notifyUpdates({TableUpdate.onTable(t.info)});
  }

  // --------------------------------------------------------------------------------- state --

  Future<SyncStateRow?> _loadState() =>
      (db.select(db.syncState)..where((s) => s.userId.equals(userId()))).getSingleOrNull();

  Future<void> _saveState({int? cursor, DateTime? lastPushAt, DateTime? lastPullAt}) async {
    await db.into(db.syncState).insert(
      SyncStateCompanion.insert(
        userId: userId(),
        cursor: Value(cursor ?? (await _loadState())?.cursor ?? 0),
        hlc: Value(hlc.state),
        lastPushAt: Value.absentIfNull(lastPushAt),
        lastPullAt: Value.absentIfNull(lastPullAt),
        lastSuccessAt: Value(clock.nowUtc()),
      ),
      onConflict: DoUpdate(
        (old) => SyncStateCompanion(
          cursor: cursor == null ? const Value.absent() : Value(cursor),
          hlc: Value(hlc.state),
          lastPushAt: Value.absentIfNull(lastPushAt),
          lastPullAt: Value.absentIfNull(lastPullAt),
        ),
      ),
    );
  }

  Future<void> _refreshPendingCount() async {
    if (_disposed) return;
    final count = await db
        .customSelect("SELECT COUNT(*) AS c FROM sync_outbox WHERE state != 'failed'")
        .getSingle();
    _set(status.value.copyWith(pendingChanges: count.data['c'] as int));
  }

  void _set(SyncStatus value) {
    if (!_disposed) status.value = value;
  }

  static bool _looksOffline(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('TimeoutException');
  }
}
