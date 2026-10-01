import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_lock.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter/foundation.dart';

/// Summary of one pulled page (sync diagnostics, T1.4.18).
class PullPageSummary {
  const PullPageSummary({
    required this.at,
    required this.since,
    required this.next,
    required this.changes,
    required this.more,
  });

  final DateTime at;
  final int since;
  final int next;
  final int changes;
  final bool more;
}

/// One server-side conflict: fields of a pushed patch that lost against newer server values
/// (`partial` / `stale` results) — the local conflict log of T1.4.18.
class ConflictLogEntry {
  const ConflictLogEntry({
    required this.at,
    required this.table,
    required this.rowId,
    required this.fields,
    required this.status,
  });

  factory ConflictLogEntry.fromJson(Map<String, dynamic> json) => ConflictLogEntry(
    at: DateTime.tryParse(json['at'] as String? ?? '')?.toUtc() ?? DateTime.utc(1970),
    table: json['t'] as String? ?? '',
    rowId: json['row'] as String? ?? '',
    fields: [for (final f in (json['fields'] as List?) ?? const []) f.toString()],
    status: json['status'] as String? ?? '',
  );

  final DateTime at;
  final String table;
  final String rowId;
  final List<String> fields;
  final String status;

  Map<String, Object?> toJson() => {
    'at': at.toUtc().toIso8601String(),
    't': table,
    'row': rowId,
    'fields': fields,
    'status': status,
  };
}

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
    this.guard,
    this.lockTtl = const Duration(minutes: 2),
    String? lockOwner,
  }) : _batchSize = batchSize,
       lock = SyncLock(db, owner: lockOwner ?? 'fg-${Ids.v7()}', clock: clock);

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

  /// Extra precondition checked before every run (account-switch safety, T1.5.08: the local
  /// data must belong to [userId]). Returning false skips the run without touching the server.
  final Future<bool> Function()? guard;

  /// Cross-isolate lease (T1.4.17).
  final SyncLock lock;
  final Duration lockTtl;

  static final _log = AppLog.get('sync');

  /// Max entries kept in the persisted conflict log.
  static const conflictLogSize = 100;
  static const conflictLogKey = 'sync_conflict_log';
  static const hlcStateKey = 'hlc_state';

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus(phase: SyncPhase.idle));

  /// Becomes true when the server reports this device as revoked (`device_revoked`): sync stops
  /// and the auth layer signs out and rotates the device id (T1.5.14).
  final ValueNotifier<bool> revoked = ValueNotifier(false);

  /// Debug switch (sync diagnostics): every run fails as if offline.
  bool simulateOffline = false;

  int _batchSize;
  int? _cursor;
  Timer? _pushDebounce;
  Timer? _pullDebounce;
  Timer? _periodic;
  Completer<void>? _running;
  bool _rerun = false;
  int _failures = 0;
  bool _disposed = false;
  bool _unsupportedClient = false;
  final _recentPulls = <PullPageSummary>[];

  /// Current push batch size (halved after `too_many_changes`).
  int get currentBatchSize => _batchSize;

  /// Last pulled pages, newest first (diagnostics).
  List<PullPageSummary> get recentPulls => List.unmodifiable(_recentPulls.reversed);

  bool get isRunning => _running != null;

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
    cancel();
    status.dispose();
    revoked.dispose();
  }

  /// Stops the engine for good without disposing its notifiers (the session ended): timers stop
  /// and a run in progress applies no further pulled page nor push result, so nothing lands
  /// after a local wipe (T1.5.07). Await [whenIdle] before wiping.
  void cancel() {
    _disposed = true;
    stop();
  }

  /// Completes when no run is in progress.
  Future<void> whenIdle() => _running?.future ?? Future<void>.value();

  /// Debounced push after local writes.
  void schedulePush([Duration delay = const Duration(milliseconds: 1500)]) {
    if (_disposed) return;
    _pushDebounce?.cancel();
    _pushDebounce = Timer(delay, () => unawaited(syncNow()));
    unawaited(_refreshCounts());
  }

  /// Debounced pull (Broadcast nudges, data pushes).
  void schedulePull([Duration delay = const Duration(milliseconds: 400)]) {
    if (_disposed) return;
    _pullDebounce?.cancel();
    _pullDebounce = Timer(delay, () => unawaited(syncNow()));
  }

  /// Realtime Broadcast nudge (`user:<uid>`, event `sync`, payload `{"rev": <head>}`, T1.4.12):
  /// schedules a debounced pull unless the announced revision is already pulled.
  void onBroadcast(Map<String, dynamic> payload) {
    final rev = (payload['rev'] as num?)?.toInt();
    final cursor = _cursor;
    if (rev != null && cursor != null && rev <= cursor) return;
    schedulePull();
  }

  /// Last pull cursor known to this service (null until the first pull or state read).
  int? get knownCursor => _cursor;

  /// Marks the device as revoked (also used by the device registrar).
  void markRevoked() {
    if (_disposed || revoked.value) return;
    revoked.value = true;
    stop();
    _set(status.value.copyWith(phase: SyncPhase.error, errorCode: SyncErrorCodes.deviceRevoked));
  }

  /// Push then pull, single-flight. A call arriving while a run is in progress schedules one more
  /// run afterwards (a write made during the pull phase is never left waiting for the timer).
  ///
  /// [manual] ("Sync now") also retries after an `unsupported_client` refusal.
  Future<void> syncNow({bool manual = false}) async {
    if (_disposed || revoked.value) return;
    if (_unsupportedClient && !manual) return;
    if (_running != null) {
      _rerun = true;
      return _running!.future;
    }
    final completer = _running = Completer<void>();
    var retry = true;
    try {
      if (guard != null && !await guard!()) {
        _log.info('sync skipped: local data not bound to the current user yet');
        retry = false;
        return;
      }
      if (simulateOffline) {
        throw const SyncApiException('simulated_offline', message: 'SocketException (simulated)');
      }
      if (!await lock.tryAcquire(ttl: lockTtl)) {
        _log.info('sync skipped: another isolate holds the sync lock');
        retry = false;
        _pushDebounce?.cancel();
        _pushDebounce = Timer(const Duration(seconds: 15), () => unawaited(syncNow()));
        return;
      }
      try {
        await _push();
        await _pull();
      } finally {
        await lock.release();
      }
      _failures = 0;
      _unsupportedClient = false;
      final now = clock.nowUtc();
      await _markSuccess(now);
      _set(status.value.copyWith(phase: SyncPhase.idle, lastSuccessAt: now, clearError: true, clearProgress: true));
    } on SyncApiException catch (e, st) {
      retry = _handleApiError(e, st);
    } on Object catch (e, st) {
      _failures++;
      final offline = looksOffline(e);
      _log.warning('sync failed (${_failures}x)', e, st);
      _set(
        status.value.copyWith(
          phase: offline ? SyncPhase.offline : SyncPhase.error,
          lastError: e.toString(),
          errorCode: offline ? null : SyncErrorCodes.unknown,
          clearProgress: true,
        ),
      );
    } finally {
      if (retry && !_disposed && status.value.phase != SyncPhase.idle) _scheduleRetry();
      await _refreshCounts();
      completer.complete();
      _running = null;
      if (_rerun && !_disposed && !revoked.value) {
        _rerun = false;
        _pushDebounce?.cancel();
        _pushDebounce = Timer(Duration.zero, () => unawaited(syncNow()));
      }
    }
  }

  /// Returns whether an automatic retry should be scheduled.
  bool _handleApiError(SyncApiException e, StackTrace st) {
    switch (e.code) {
      case SyncApiException.unsupportedClient:
        _unsupportedClient = true;
        _log.warning('server refuses this build (unsupported_client) — sync paused until update');
        _set(
          status.value.copyWith(
            phase: SyncPhase.error,
            errorCode: SyncErrorCodes.unsupportedClient,
            lastError: e.message ?? e.code,
            clearProgress: true,
          ),
        );
        return false;
      case SyncApiException.deviceRevoked:
        _log.warning('device revoked — stopping sync');
        markRevoked();
        return false;
      case SyncApiException.notAuthenticated:
        _failures++;
        _set(
          status.value.copyWith(
            phase: SyncPhase.error,
            errorCode: SyncErrorCodes.notAuthenticated,
            lastError: e.message ?? e.code,
            clearProgress: true,
          ),
        );
        return true;
      default:
        _failures++;
        final offline = e.code == 'simulated_offline';
        _log.warning('sync failed (${_failures}x)', e, st);
        _set(
          status.value.copyWith(
            phase: offline ? SyncPhase.offline : SyncPhase.error,
            lastError: e.toString(),
            errorCode: offline ? null : SyncErrorCodes.unknown,
            clearProgress: true,
          ),
        );
        return true;
    }
  }

  /// Forces a full resync: cursor back to 0 (the outbox is kept and re-applied on top), then a
  /// manual run (Settings › Sync › Force full resync, T8.3.04).
  Future<void> resync() async {
    await _saveState(cursor: 0);
    _cursor = 0;
    await syncNow(manual: true);
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
      if (_disposed) throw const SyncApiException('cancelled', message: 'sync engine stopped');
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
      } on SyncApiException catch (e) {
        await _resetInflight();
        switch (e.code) {
          case SyncApiException.tooManyChanges:
            final groups = {for (final r in batch) r.opId};
            if (groups.length <= 1 || _batchSize <= 1) {
              // One operation group larger than the server limit can never be pushed (groups are
              // never split) → park it as failed instead of looping.
              await _markFailed(batch, '${e.code}: ${e.message ?? 'group too large'}');
            } else {
              _batchSize = max(1, _batchSize ~/ 2);
              _log.info('too_many_changes → batch size $_batchSize');
            }
            continue;
          case SyncApiException.invalidRequest:
            await _markFailed(batch, '${e.code}: ${e.message ?? ''}');
            continue;
          default:
            rethrow;
        }
      } on Object {
        await _resetInflight();
        rethrow;
      }
      final byId = {for (final r in batch) r.changeId: r};
      final refetch = <String, Set<String>>{};
      var matched = 0;
      var unsupported = false;
      final conflicts = <ConflictLogEntry>[];
      // The session ended while the push was in flight: the server has the changes; nothing more
      // is written locally (the data may already be wiped).
      if (_disposed) throw const SyncApiException('cancelled', message: 'sync engine stopped');
      await db.transaction(() async {
        for (final result in response.results) {
          final entry = byId[result.changeId];
          if (entry == null) continue;
          matched++;
          final current = await (db.select(
            db.syncOutbox,
          )..where((o) => o.changeId.equals(result.changeId))).getSingleOrNull();
          final modified = current != null && current.entryVersion != versions[result.changeId];
          switch (result.status) {
            case 'applied' || 'partial' || 'stale':
              if (result.staleFields.isNotEmpty) {
                // The server kept newer values. Our cursor may already be past that row's
                // revision (pulled before this edit), so the pull would never bring it back:
                // refetch the row to realign the local copy (convergence).
                refetch.putIfAbsent(entry.tableName_, () => {}).add(entry.rowId);
                conflicts.add(
                  ConflictLogEntry(
                    at: clock.nowUtc(),
                    table: entry.tableName_,
                    rowId: entry.rowId,
                    fields: result.staleFields,
                    status: result.status,
                  ),
                );
              }
              if (modified) {
                await _setState(result.changeId, 'pending');
              } else {
                await _deleteEntry(result.changeId);
              }
            case 'rejected' when result.code == 'integrity_refetch':
              refetch.putIfAbsent(entry.tableName_, () => {}).add(entry.rowId);
              await _deleteEntry(result.changeId);
            case 'rejected' when result.code == SyncApiException.unsupportedClient:
              await _setState(result.changeId, 'pending');
              unsupported = true;
            default:
              await (db.update(db.syncOutbox)..where((o) => o.changeId.equals(result.changeId))).write(
                SyncOutboxCompanion(
                  state: const Value('failed'),
                  lastError: Value('${result.code}: ${result.message}'),
                ),
              );
          }
        }
        // Anything the server didn't mention goes back to pending.
        await _resetInflight();
        if (conflicts.isNotEmpty) await _appendConflicts(conflicts);
      });
      if (unsupported) {
        throw const SyncApiException(SyncApiException.unsupportedClient);
      }
      if (matched == 0) {
        // The response covered none of the batch: stop instead of re-sending the same batch in a
        // hot loop; the normal backoff retries later.
        throw StateError('sync_push returned no results for ${batch.length} changes');
      }
      for (final e in refetch.entries) {
        await refetchRows(e.key, e.value.toList());
      }
      await _saveState(lastPushAt: clock.nowUtc());
    }
  }

  Future<List<OutboxRow>> _nextBatch() async {
    final pending =
        await (db.select(db.syncOutbox)
              ..where((o) => o.state.equals('pending'))
              ..orderBy([(o) => OrderingTerm.asc(o.seq)])
              ..limit(_batchSize * 2))
            .get();
    if (pending.isEmpty) return const [];
    // Keep whole operation groups together.
    final order = <String>[];
    for (final row in pending) {
      if (!order.contains(row.opId)) order.add(row.opId);
    }
    final batch = <OutboxRow>[];
    for (final group in order) {
      // The group may have been cut by the limit above: load it completely.
      final all =
          await (db.select(db.syncOutbox)
                ..where((o) => o.opId.equals(group) & o.state.equals('pending'))
                ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
              .get();
      if (batch.isNotEmpty && batch.length + all.length > _batchSize) break;
      batch.addAll(all);
      if (batch.length >= _batchSize) break;
    }
    return batch;
  }

  Future<void> _resetInflight() =>
      db.customUpdate("UPDATE sync_outbox SET state = 'pending' WHERE state = 'inflight'", updates: {db.syncOutbox});

  Future<void> _markFailed(List<OutboxRow> batch, String error) => db.customUpdate(
    "UPDATE sync_outbox SET state = 'failed', last_error = ? "
    'WHERE change_id IN (${List.filled(batch.length, '?').join(',')})',
    variables: [Variable<String>(error), for (final r in batch) Variable<String>(r.changeId)],
    updates: {db.syncOutbox},
  );

  Future<void> _setState(String changeId, String state) => (db.update(
    db.syncOutbox,
  )..where((o) => o.changeId.equals(changeId))).write(SyncOutboxCompanion(state: Value(state)));

  Future<void> _deleteEntry(String changeId) =>
      (db.delete(db.syncOutbox)..where((o) => o.changeId.equals(changeId))).go();

  /// Failed entries go back to the queue (diagnostics › Retry).
  Future<void> retryFailed() async {
    await db.customUpdate(
      "UPDATE sync_outbox SET state = 'pending', last_error = NULL WHERE state = 'failed'",
      updates: {db.syncOutbox},
    );
    schedulePush(Duration.zero);
  }

  /// Drops failed entries and realigns the affected rows with the server (diagnostics › Discard).
  Future<void> discardFailed({List<String>? changeIds}) async {
    final q = db.select(db.syncOutbox)..where((o) => o.state.equals('failed'));
    if (changeIds != null) q.where((o) => o.changeId.isIn(changeIds));
    final rows = await q.get();
    if (rows.isEmpty) return;
    final byTable = <String, Set<String>>{};
    for (final r in rows) {
      byTable.putIfAbsent(r.tableName_, () => {}).add(r.rowId);
    }
    await (db.delete(db.syncOutbox)..where((o) => o.changeId.isIn([for (final r in rows) r.changeId]))).go();
    await _refreshCounts();
    for (final e in byTable.entries) {
      try {
        await refetchRows(e.key, e.value.toList());
      } on Object catch (err) {
        _log.warning('refetch after discard failed', err);
      }
    }
  }

  // ---------------------------------------------------------------------------------- pull --

  Future<void> _pull() async {
    final state = await _loadState();
    var cursor = state?.cursor ?? 0;
    _cursor ??= cursor;
    final lastSuccess = state?.lastSuccessAt;
    final full = cursor == 0 || (lastSuccess != null && clock.nowUtc().difference(lastSuccess) > tombstoneRetention);
    if (full) cursor = 0;
    final seen = full ? <String, Set<String>>{} : null;
    var first = true;
    var pages = 0;
    while (true) {
      _set(status.value.copyWith(phase: SyncPhase.pulling));
      final page = await api.pull(since: cursor, limit: pageSize);
      if (first && !full && page.purgeWatermark > cursor && cursor > 0) {
        // Our cursor predates purged tombstones → full resync.
        _log.info('cursor $cursor < purge watermark ${page.purgeWatermark}: full resync');
        await _saveState(cursor: 0);
        _cursor = 0;
        return _pull();
      }
      first = false;
      pages++;
      final since = cursor;
      await _applyPage(page, seen);
      cursor = page.next;
      _recentPulls.add(
        PullPageSummary(
          at: clock.nowUtc(),
          since: since,
          next: page.next,
          changes: page.changes.length,
          more: page.more,
        ),
      );
      while (_recentPulls.length > 20) {
        _recentPulls.removeAt(0);
      }
      if (full) {
        // Unknown total: approach 1 asymptotically while pages keep coming.
        _set(status.value.copyWith(initialSyncProgress: page.more ? 1 - 1 / (pages + 1) : 1));
      }
      if (!page.more) break;
    }
    if (seen != null) await _dropUnseenAfterFullSync(seen);
  }

  /// Applies one page and saves the new cursor in the SAME transaction (crash-safe resume).
  Future<void> _applyPage(PullPage page, Map<String, Set<String>>? seen) async {
    final touched = <TableInfo<Table, Object?>>{};
    await db.transaction(() async {
      // Checked inside the transaction: a wipe that ran while the page was downloading is never
      // undone by applying it afterwards.
      if (_disposed) throw const SyncApiException('cancelled', message: 'sync engine stopped');
      for (final change in page.changes) {
        if (!registry.isSynced(change.table)) {
          _log.warning('pull: unknown table ${change.table} (newer server?) — skipped');
          continue;
        }
        final t = registry[change.table];
        final id = change.row['id'] as String?;
        if (id == null) continue;
        seen?.putIfAbsent(t.name, () => {}).add(id);
        await _applyRow(t, change.row);
        touched.add(t.info);
      }
      await _saveState(cursor: page.next, lastPullAt: clock.nowUtc(), purgeWatermark: page.purgeWatermark);
    });
    _cursor = page.next;
    if (touched.isNotEmpty) {
      db.notifyUpdates({for (final t in touched) TableUpdate.onTable(t)});
    }
  }

  /// Applies a server row field by field: columns with pending local patches keep the local value.
  Future<void> _applyRow(RegisteredTable t, Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    final values = <String, Object?>{};
    for (final column in t.columns) {
      if (!row.containsKey(column)) continue;
      values[column] = t.serverToSqlite(column, row[column]);
    }
    final clockJson = row['field_clock'];
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
        await db.customStatement('UPDATE ${t.name} SET ${cols.map((c) => '$c = ?').join(', ')} WHERE id = ?', [
          for (final c in cols) values[c],
          id,
        ]);
      }
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
      final local = await db.customSelect('SELECT id FROM ${t.name} WHERE rev > 0').get();
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

  /// Targeted refetch (`app.fetch_rows`, ≤ 1000 ids per call): server rows overwrite the local
  /// copies field by field (fields of later pending patches are kept); ids the server reports as
  /// `missing` are deleted locally together with their outbox entries.
  Future<void> refetchRows(String table, List<String> ids) async {
    if (!registry.isSynced(table) || ids.isEmpty) return;
    final t = registry[table];
    for (var i = 0; i < ids.length; i += 1000) {
      final chunk = ids.sublist(i, min(ids.length, i + 1000));
      final result = await api.fetchRows(table, chunk);
      await db.transaction(() async {
        for (final row in result.rows) {
          await _applyRow(t, row);
        }
        for (final id in result.missing) {
          await db.customStatement('DELETE FROM ${t.name} WHERE id = ?', [id]);
          await db.customStatement('DELETE FROM sync_outbox WHERE table_name = ? AND row_id = ?', [t.name, id]);
        }
      });
    }
    db.notifyUpdates({TableUpdate.onTable(t.info), TableUpdate.onTable(db.syncOutbox)});
  }

  // --------------------------------------------------------------------------------- state --

  Future<SyncStateRow?> _loadState() =>
      (db.select(db.syncState)..where((s) => s.userId.equals(userId()))).getSingleOrNull();

  /// Current persisted sync state of the user (diagnostics).
  Future<SyncStateRow?> loadState() => _loadState();

  Future<void> _saveState({int? cursor, DateTime? lastPushAt, DateTime? lastPullAt, int? purgeWatermark}) async {
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            userId: userId(),
            cursor: Value(cursor ?? 0),
            hlc: Value(hlc.state),
            lastPushAt: Value.absentIfNull(lastPushAt),
            lastPullAt: Value.absentIfNull(lastPullAt),
            purgeWatermarkSeen: Value.absentIfNull(purgeWatermark),
          ),
          onConflict: DoUpdate(
            (old) => SyncStateCompanion(
              cursor: cursor == null ? const Value.absent() : Value(cursor),
              hlc: Value(hlc.state),
              lastPushAt: Value.absentIfNull(lastPushAt),
              lastPullAt: Value.absentIfNull(lastPullAt),
              purgeWatermarkSeen: Value.absentIfNull(purgeWatermark),
            ),
          ),
        );
    await _persistHlc();
  }

  /// The HLC observed from pulled clocks must survive restarts: bootstrap restores it from
  /// `local_kv.hlc_state` (the same key the writer uses).
  Future<void> _persistHlc() => db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) '
    'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [hlcStateKey, hlc.state],
  );

  Future<void> _markSuccess(DateTime now) async {
    await _saveState();
    await (db.update(db.syncState)..where((s) => s.userId.equals(userId()))).write(
      SyncStateCompanion(lastSuccessAt: Value(now), lastError: const Value(null)),
    );
  }

  Future<void> _appendConflicts(List<ConflictLogEntry> entries) async {
    final existing = await conflictLog();
    final all = [...existing.reversed, ...entries];
    final kept = all.length > conflictLogSize ? all.sublist(all.length - conflictLogSize) : all;
    await db.customStatement(
      'INSERT INTO local_kv(key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [
        conflictLogKey,
        jsonEncode([for (final e in kept) e.toJson()]),
      ],
    );
  }

  /// Local conflict log (newest first).
  Future<List<ConflictLogEntry>> conflictLog() async {
    final row = await db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [const Variable<String>(conflictLogKey)])
        .getSingleOrNull();
    final raw = row?.data['value'] as String?;
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded.reversed)
          if (e is Map) ConflictLogEntry.fromJson(Map<String, dynamic>.from(e)),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<void> clearConflictLog() => db.customStatement('DELETE FROM local_kv WHERE key = ?', [conflictLogKey]);

  Future<void> _refreshCounts() async {
    if (_disposed) return;
    final count = await db
        .customSelect(
          "SELECT SUM(CASE WHEN state != 'failed' THEN 1 ELSE 0 END) AS p, "
          "SUM(CASE WHEN state = 'failed' THEN 1 ELSE 0 END) AS f FROM sync_outbox",
        )
        .getSingle();
    _set(
      status.value.copyWith(
        pendingChanges: (count.data['p'] as int?) ?? 0,
        failedChanges: (count.data['f'] as int?) ?? 0,
      ),
    );
  }

  void _set(SyncStatus value) {
    if (!_disposed) status.value = value;
  }

  /// Heuristic for "no network" errors (status `offline` instead of `error`).
  static bool looksOffline(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('Network is unreachable') ||
        s.contains('TimeoutException');
  }
}
