import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';

/// Kind of row change inside an operation.
enum RowChangeKind { insert, update }

/// One row touched by an operation; `before` holds the previous SQLite values of the changed
/// columns (null for inserts) so the operation can be undone.
class RowChange {
  RowChange({
    required this.table,
    required this.id,
    required this.kind,
    required this.before,
    required this.after,
  });

  final String table;
  final String id;
  final RowChangeKind kind;
  final Map<String, Object?>? before;
  final Map<String, Object?> after;
}

/// Result of a [SyncWriter.run]: the operation id and every row change (used by the undo stack).
class OpRecord {
  const OpRecord({required this.opId, required this.changes, required this.cause});

  final String opId;
  final String cause;
  final List<RowChange> changes;

  bool get isEmpty => changes.isEmpty;
}

/// The only way to write synced tables (T1.4.07).
///
/// Each [run] is ONE Drift transaction and ONE operation group: row changes, outbox patches with
/// hybrid-logical-clock stamps and activity events are written atomically. Values are passed as
/// maps of **snake_case column names** to Dart values (`String`, `int`, `double`, `bool`,
/// `DateTime` (UTC), `Map`/`List` for JSON columns, or anything whose `toString()` is the stored
/// text such as `LocalDateTime`/`LocalDate`). Common columns (`id`, `user_id`, `created_at`,
/// `updated_at`, `origin_device_id`, `rev`, `field_clock`) are managed here.
class SyncWriter {
  SyncWriter({
    required this.db,
    required this.registry,
    required this.clock,
    required this.hlc,
    required this.userId,
    required this.deviceId,
    this.onCommitted,
  });

  final AppDatabase db;
  final TableRegistry registry;
  final Clock clock;
  final Hlc hlc;
  final String Function() userId;
  final String deviceId;

  /// Called after every committed operation (the sync service debounces a push).
  final void Function(OpRecord record)? onCommitted;

  final _committed = StreamController<OpRecord>.broadcast();

  /// Committed operations (for undo stacks, notification re-planning, widgets refresh…).
  Stream<OpRecord> get committed => _committed.stream;

  /// Runs [body] as one atomic operation.
  ///
  /// [cause] is recorded in activity events (`user`, `auto_rollup`, `cascade`, `reset`, `bulk`,
  /// `import`, `undo`). [scheduledAt] marks an *automatic* write: its clock is the scheduled
  /// instant so later user edits always win (arch §6.6).
  Future<OpRecord> run(
    Future<void> Function(WriteTx tx) body, {
    String? opId,
    String cause = 'user',
    DateTime? scheduledAt,
  }) async {
    // No session (signed out / sign-out in progress): a late background write must never
    // recreate user rows after the local wipe (T1.5.07).
    if (userId().isEmpty) throw const AuthException('SyncWriter.run without a signed-in user');
    final id = opId ?? Ids.v7();
    late WriteTx tx;
    await db.transaction(() async {
      tx = WriteTx._(this, id, cause, scheduledAt);
      await body(tx);
      await _coalesceSingleRowGroup(id);
      await db.customStatement(
        'INSERT INTO local_kv(key, value) VALUES (?, ?) '
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        ['hlc_state', hlc.state],
      );
    });
    final record = OpRecord(opId: id, changes: List.unmodifiable(tx._changes), cause: cause);
    if (!record.isEmpty) {
      onCommitted?.call(record);
      _committed.add(record);
    }
    return record;
  }

  /// An automatic, time-triggered write (T1.4.19, arch §6.6): resettable checklists, auto-success
  /// quit days, notification bookkeeping… Its field clocks are the [scheduledAt] instant of the
  /// triggering event (not "now"), so a later user edit always wins and two devices running the
  /// same automation (with deterministic ids) converge.
  Future<OpRecord> runAutomatic(
    DateTime scheduledAt,
    Future<void> Function(WriteTx tx) body, {
    String cause = 'auto',
    String? opId,
  }) => run(body, opId: opId, cause: cause, scheduledAt: scheduledAt);

  /// Cross-operation coalescing (T1.4.04 — "100 rapid edits of one row produce one pending
  /// patch"): when operation [opId] produced exactly one outbox entry and an older **pending**
  /// entry of the same row is also alone in its group, the new patch is merged into it (latest
  /// value and max clock per field, `entry_version + 1`). Entries of multi-row groups, in-flight
  /// or failed entries are never merged, so operation groups stay atomic.
  Future<void> _coalesceSingleRowGroup(String opId) async {
    final mine = await db
        .customSelect(
          'SELECT change_id, table_name, row_id, op, fields, clock FROM sync_outbox WHERE op_id = ?',
          variables: [Variable<String>(opId)],
        )
        .get();
    if (mine.length != 1) return;
    final m = mine.single.data;
    final target = await db
        .customSelect(
          'SELECT o.change_id, o.op, o.fields, o.clock FROM sync_outbox o '
          "WHERE o.table_name = ? AND o.row_id = ? AND o.state = 'pending' AND o.op_id != ? "
          'AND (SELECT COUNT(*) FROM sync_outbox g WHERE g.op_id = o.op_id) = 1 '
          'ORDER BY o.seq DESC LIMIT 1',
          variables: [
            Variable<String>(m['table_name'] as String),
            Variable<String>(m['row_id'] as String),
            Variable<String>(opId),
          ],
        )
        .getSingleOrNull();
    if (target == null) return;
    final t = target.data;
    final fields = {...WriteTx._decodeMap(t['fields']), ...WriteTx._decodeMap(m['fields'])};
    final clock = WriteTx._decodeMap(t['clock']);
    for (final e in WriteTx._decodeMap(m['clock']).entries) {
      final previous = clock[e.key];
      if (previous is! String || (e.value is String && (e.value! as String).compareTo(previous) > 0)) {
        clock[e.key] = e.value;
      }
    }
    final op = m['op'] == 'insert' ? 'insert' : t['op'];
    await db.customUpdate(
      'UPDATE sync_outbox SET op = ?, fields = ?, clock = ?, entry_version = entry_version + 1 '
      'WHERE change_id = ?',
      variables: [
        Variable<String>(op as String),
        Variable<String>(jsonEncode(fields)),
        Variable<String>(jsonEncode(clock)),
        Variable<String>(t['change_id'] as String),
      ],
      updates: {db.syncOutbox},
      updateKind: UpdateKind.update,
    );
    await db.customUpdate(
      'DELETE FROM sync_outbox WHERE change_id = ?',
      variables: [Variable<String>(m['change_id'] as String)],
      updates: {db.syncOutbox},
      updateKind: UpdateKind.delete,
    );
  }

  /// Reverts an operation (undo) as a new operation.
  Future<OpRecord> revert(OpRecord record) => run((tx) async {
    for (final change in record.changes.reversed) {
      switch (change.kind) {
        case RowChangeKind.insert:
          await tx.softDelete(change.table, change.id);
        case RowChangeKind.update:
          final before = change.before ?? const {};
          if (before.isEmpty) continue;
          await tx._updateRaw(change.table, change.id, before);
      }
    }
  }, cause: 'undo');
}

/// Write handle passed to [SyncWriter.run] bodies.
class WriteTx {
  WriteTx._(this._writer, this.opId, this.cause, this.scheduledAt)
    : now = (scheduledAt ?? _writer.clock.nowUtc()).toUtc(),
      _stamp = scheduledAt != null ? _writer.hlc.at(scheduledAt) : _writer.hlc.now();

  final SyncWriter _writer;
  final String opId;
  final String cause;
  final DateTime? scheduledAt;

  /// Timestamp used for `created_at` / `updated_at` of this operation.
  final DateTime now;
  final String _stamp;
  final List<RowChange> _changes = [];

  AppDatabase get db => _writer.db;
  String get userId => _writer.userId();
  String get deviceId => _writer.deviceId;

  /// Inserts a new synced row.
  Future<void> insert(String table, String id, Map<String, Object?> values) async {
    final t = _writer.registry[table];
    final row = <String, Object?>{
      for (final e in values.entries) e.key: t.toSqlite(e.key, e.value),
      'id': id,
      'user_id': userId,
      'created_at': t.toSqlite('created_at', values['created_at'] ?? now),
      'updated_at': t.toSqlite('updated_at', now),
      'origin_device_id': deviceId,
    };
    final clockMap = {
      for (final c in row.keys)
        if (!serverOwnedColumns.contains(c)) c: _stamp,
    };
    row['field_clock'] = jsonEncode(clockMap);
    final columns = row.keys.toList();
    await db.customInsert(
      'INSERT INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')})',
      variables: [for (final c in columns) _variable(row[c])],
      updates: {t.info},
    );
    await _enqueue(t, id, 'insert', {
      for (final c in columns)
        if (!serverOwnedColumns.contains(c)) c: t.sqliteToServer(c, row[c]),
    });
    _changes.add(RowChange(table: table, id: id, kind: RowChangeKind.insert, before: null, after: row));
  }

  /// Patches an existing row; only columns whose value actually changes are written/pushed.
  /// Returns false when nothing changed.
  Future<bool> update(String table, String id, Map<String, Object?> changes) async {
    final t = _writer.registry[table];
    return _updateRaw(table, id, {for (final e in changes.entries) e.key: t.toSqlite(e.key, e.value)});
  }

  Future<bool> _updateRaw(String table, String id, Map<String, Object?> sqliteValues) async {
    final t = _writer.registry[table];
    final current = await readRaw(table, id);
    if (current == null) throw NotFoundException('$table/$id not found');
    final changed = <String, Object?>{};
    final before = <String, Object?>{};
    for (final e in sqliteValues.entries) {
      if (serverOwnedColumns.contains(e.key) || e.key == 'id') continue;
      if (current[e.key] != e.value) {
        changed[e.key] = e.value;
        before[e.key] = current[e.key];
      }
    }
    if (changed.isEmpty) return false;
    changed['updated_at'] = t.toSqlite('updated_at', now);
    changed['origin_device_id'] = deviceId;
    final clock = _decodeMap(current['field_clock']);
    for (final c in changed.keys) {
      clock[c] = _stamp;
    }
    final assignments = [...changed.keys.map((c) => '$c = ?'), 'field_clock = ?'];
    await db.customUpdate(
      'UPDATE $table SET ${assignments.join(', ')} WHERE id = ?',
      variables: [
        for (final c in changed.keys) _variable(changed[c]),
        _variable(jsonEncode(clock)),
        _variable(id),
      ],
      updates: {t.info},
      updateKind: UpdateKind.update,
    );
    await _enqueue(t, id, 'patch', {
      for (final c in changed.keys) c: t.sqliteToServer(c, changed[c]),
    });
    _changes.add(
      RowChange(table: table, id: id, kind: RowChangeKind.update, before: before, after: changed),
    );
    return true;
  }

  /// Inserts or patches (for deterministic-id rows).
  Future<void> upsert(String table, String id, Map<String, Object?> values) async {
    if (await exists(table, id)) {
      await update(table, id, values);
    } else {
      await insert(table, id, values);
    }
  }

  Future<void> softDelete(String table, String id) =>
      update(table, id, {'deleted_at': now});

  Future<void> restore(String table, String id) =>
      update(table, id, {'deleted_at': null});

  Future<bool> exists(String table, String id) async =>
      (await readRaw(table, id)) != null;

  /// Raw SQLite row (snake_case keys) or null.
  Future<Map<String, Object?>?> readRaw(String table, String id) async {
    final row = await db
        .customSelect('SELECT * FROM $table WHERE id = ?', variables: [Variable<String>(id)])
        .getSingleOrNull();
    return row?.data;
  }

  /// Appends an activity event (append-only log, arch §7.3). The payload always gets `opId` and
  /// `cause`. Pass a deterministic [id] for events two devices might both create.
  Future<void> logEvent({
    required String entityType,
    required String entityId,
    required String eventType,
    String? parentId,
    Map<String, Object?> payload = const {},
    String? id,
  }) async {
    final eventId = id ?? Ids.v7();
    if (id != null && await exists('activity_events', eventId)) return;
    await insert('activity_events', eventId, {
      'entity_type': entityType,
      'entity_id': entityId,
      'parent_id': parentId,
      'event_type': eventType,
      'payload': {...payload, 'opId': opId, 'cause': cause},
      'occurred_at': now,
    });
  }

  Future<void> _enqueue(
    RegisteredTable t,
    String rowId,
    String op,
    Map<String, Object?> fields,
  ) async {
    final existing = await db
        .customSelect(
          "SELECT change_id, op, fields, clock FROM sync_outbox WHERE table_name = ? AND row_id = ? "
          "AND op_id = ? AND state = 'pending' LIMIT 1",
          variables: [Variable<String>(t.name), Variable<String>(rowId), Variable<String>(opId)],
        )
        .getSingleOrNull();
    final clock = {for (final c in fields.keys) c: _stamp};
    if (existing != null) {
      final mergedFields = {..._decodeMap(existing.data['fields']), ...fields};
      final mergedClock = {..._decodeMap(existing.data['clock']), ...clock};
      await db.customUpdate(
        'UPDATE sync_outbox SET fields = ?, clock = ?, entry_version = entry_version + 1 '
        'WHERE change_id = ?',
        variables: [
          _variable(jsonEncode(mergedFields)),
          _variable(jsonEncode(mergedClock)),
          _variable(existing.data['change_id']),
        ],
        updates: {db.syncOutbox},
        updateKind: UpdateKind.update,
      );
      return;
    }
    await db.customInsert(
      'INSERT INTO sync_outbox (change_id, op_id, table_name, row_id, op, fields, clock, enqueued_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        _variable(Ids.v7()),
        _variable(opId),
        _variable(t.name),
        _variable(rowId),
        _variable(op),
        _variable(jsonEncode(fields)),
        _variable(jsonEncode(clock)),
        _variable(now.toIso8601String()),
      ],
      updates: {db.syncOutbox},
    );
  }

  static Map<String, Object?> _decodeMap(Object? value) {
    if (value is! String || value.isEmpty) return {};
    final decoded = jsonDecode(value);
    return decoded is Map ? Map<String, Object?>.from(decoded) : {};
  }

  static Variable<Object> _variable(Object? value) => Variable<Object>(value);
}
