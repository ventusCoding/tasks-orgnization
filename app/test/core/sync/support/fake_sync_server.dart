import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';

/// One row as stored by the fake server.
class FakeServerRow {
  FakeServerRow({
    required this.userId,
    required this.values,
    required this.fieldClock,
    required this.rev,
    required this.serverUpdatedAt,
  });

  final String userId;
  final Map<String, Object?> values;
  final Map<String, String> fieldClock;
  int rev;
  String serverUpdatedAt;

  FakeServerRow copy() => FakeServerRow(
    userId: userId,
    values: jsonDecode(jsonEncode(values)) as Map<String, Object?>,
    fieldClock: Map.of(fieldClock),
    rev: rev,
    serverUpdatedAt: serverUpdatedAt,
  );

  Map<String, dynamic> toJson(String id) => <String, dynamic>{
    ...(jsonDecode(jsonEncode(values)) as Map<String, dynamic>),
    'id': id,
    'user_id': userId,
    'rev': rev,
    'field_clock': Map<String, String>.of(fieldClock),
    'server_updated_at': serverUpdatedAt,
  };
}

/// In-memory implementation of the sync RPC semantics (T1.4.15; contract in supabase/README.md):
/// per-user revision counter, per-field LWW with HLC clocks (+5 min clamp), idempotent replays,
/// atomic operation groups, `integrity_refetch`, whole-call refusals, purge watermark and
/// `fetch_rows` with `missing` ids.
class FakeSyncServer {
  FakeSyncServer({DateTime? now}) : now = (now ?? DateTime.utc(2026, 9, 22, 9)).toUtc();

  DateTime now;

  /// table → id → row (all users).
  final Map<String, Map<String, FakeServerRow>> tables = {};
  final Map<String, int> heads = {};
  final Map<String, int> purgeWatermarks = {};
  final Set<String> revokedDevices = {};
  final Map<String, DeviceRegistration> devices = {};

  int maxChanges = 500;
  int minSupportedBuild = 0;

  /// Errors thrown by the next `push` calls (whole-call refusals).
  final List<Exception> queuedPushErrors = [];

  /// Group-end integrity check; return a violation message to reject the whole group.
  String? Function(FakeSyncServer server, String userId, String table, String id)? integrityCheck;

  int pushCalls = 0;
  int pullCalls = 0;
  final List<List<Map<String, Object?>>> pushedBatches = [];

  static final _knownTables = {for (final s in syncedTableSpecs) s.name};
  static const _serverManaged = {'user_id', 'rev', 'server_updated_at', 'field_clock'};
  static const _eq = DeepCollectionEquality();

  int head(String userId) => heads[userId] ?? 0;

  FakeServerRow? row(String table, String id) => tables[table]?[id];

  PushResponse push(
    String userId, {
    required String deviceId,
    required int build,
    required List<Map<String, Object?>> changes,
  }) {
    pushCalls++;
    if (queuedPushErrors.isNotEmpty) throw queuedPushErrors.removeAt(0);
    if (build < minSupportedBuild) {
      throw const SyncApiException(SyncApiException.unsupportedClient, status: 426);
    }
    if (revokedDevices.contains(deviceId)) {
      throw const SyncApiException(SyncApiException.deviceRevoked, status: 403);
    }
    if (changes.length > maxChanges) {
      throw const SyncApiException(SyncApiException.tooManyChanges, status: 413);
    }
    pushedBatches.add(changes);
    final order = <String>[];
    final groups = <String, List<Map<String, Object?>>>{};
    for (final c in changes) {
      final g = (c['g'] as String?) ?? c['id']! as String;
      if (!groups.containsKey(g)) order.add(g);
      groups.putIfAbsent(g, () => []).add(c);
    }
    final results = <String, PushResult>{};
    for (final g in order) {
      final snapshot = {
        for (final t in tables.entries) t.key: {for (final r in t.value.entries) r.key: r.value.copy()},
      };
      final headBefore = head(userId);
      final groupResults = <PushResult>[];
      String? violation;
      String? violationCode;
      for (final c in groups[g]!) {
        final r = _apply(userId, deviceId, c);
        groupResults.add(r);
        if (r.status == 'rejected' && violation == null) {
          violation = r.message ?? r.code;
          violationCode = r.code;
        }
      }
      if (violation == null && integrityCheck != null) {
        for (final c in groups[g]!) {
          final v = integrityCheck!(this, userId, c['t']! as String, c['row_id']! as String);
          if (v != null) {
            violation = v;
            violationCode = 'integrity_refetch';
            break;
          }
        }
      }
      if (violation != null) {
        tables
          ..clear()
          ..addAll(snapshot);
        heads[userId] = headBefore;
        for (var i = 0; i < groups[g]!.length; i++) {
          final c = groups[g]![i];
          final own = groupResults[i];
          final code = violationCode == 'integrity_refetch'
              ? 'integrity_refetch'
              : (own.status == 'rejected' ? own.code : 'group_rejected');
          results[c['id']! as String] = PushResult(
            changeId: c['id']! as String,
            status: 'rejected',
            code: code,
            message: violation,
          );
        }
      } else {
        for (var i = 0; i < groups[g]!.length; i++) {
          results[groups[g]![i]['id']! as String] = groupResults[i];
        }
      }
    }
    return PushResponse([for (final c in changes) results[c['id']]!], head(userId));
  }

  PushResult _apply(String userId, String deviceId, Map<String, Object?> c) {
    final changeId = c['id']! as String;
    PushResult reject(String code, [String? message]) =>
        PushResult(changeId: changeId, status: 'rejected', code: code, message: message ?? code);
    final table = c['t'] as String?;
    final id = c['row_id'] as String?;
    final fields = Map<String, Object?>.from((c['fields'] as Map?) ?? const {});
    final clocks = Map<String, Object?>.from((c['clock'] as Map?) ?? const {});
    if (table == null || !_knownTables.contains(table)) return reject('unknown_table');
    if (id == null) return reject('invalid_change');
    for (final f in fields.keys) {
      if (_serverManaged.contains(f)) return reject('forbidden_column', f);
      if (f == 'id' && fields[f] != id) return reject('invalid_change');
      if (f != 'id' && Hlc.tryParse('${clocks[f]}') == null) return reject('invalid_clock', f);
    }
    final rows = tables.putIfAbsent(table, () => {});
    final existing = rows[id];
    if (existing != null && existing.userId != userId) {
      return reject('integrity_refetch', 'id owned by another user');
    }
    final limit = now.add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    final clamped = <String, String>{};
    for (final f in fields.keys) {
      if (f == 'id') continue;
      final parsed = Hlc.tryParse('${clocks[f]}')!;
      clamped[f] = parsed.ms > limit ? Hlc.format(limit, parsed.counter, parsed.device) : '${clocks[f]}';
    }
    final values = {...fields}..remove('id');
    if (existing == null) {
      rows[id] = FakeServerRow(
        userId: userId,
        values: {...values, 'origin_device_id': deviceId},
        fieldClock: clamped,
        rev: _bump(userId),
        serverUpdatedAt: now.toIso8601String(),
      );
      return PushResult(changeId: changeId, status: 'applied');
    }
    final applied = <String>[];
    final stale = <String>[];
    for (final f in values.keys) {
      final current = existing.fieldClock[f];
      final incoming = clamped[f]!;
      if (current == null ||
          incoming.compareTo(current) > 0 ||
          (incoming == current && !_eq.equals(existing.values[f], values[f]))) {
        applied.add(f);
      } else if (incoming.compareTo(current) < 0) {
        stale.add(f);
      }
    }
    if (applied.isEmpty) {
      return PushResult(changeId: changeId, status: 'stale', staleFields: stale);
    }
    for (final f in applied) {
      existing.values[f] = values[f];
      existing.fieldClock[f] = clamped[f]!;
    }
    existing
      ..values['origin_device_id'] = deviceId
      ..rev = _bump(userId)
      ..serverUpdatedAt = now.toIso8601String();
    return PushResult(changeId: changeId, status: stale.isEmpty ? 'applied' : 'partial', staleFields: stale);
  }

  int _bump(String userId) => heads[userId] = head(userId) + 1;

  PullPage pull(String userId, {required int since, int limit = 1000}) {
    pullCalls++;
    final all = <(String, String, FakeServerRow)>[
      for (final t in tables.entries)
        for (final r in t.value.entries)
          if (r.value.userId == userId && r.value.rev > since) (t.key, r.key, r.value),
    ]..sort((a, b) => a.$3.rev.compareTo(b.$3.rev));
    final page = all.take(limit).toList();
    return PullPage(
      changes: [for (final (t, id, r) in page) PullChange(t, r.toJson(id))],
      next: page.isEmpty ? since : page.last.$3.rev,
      more: all.length > limit,
      purgeWatermark: purgeWatermarks[userId] ?? 0,
    );
  }

  FetchRowsResult fetchRows(String userId, String table, List<String> ids) {
    final rows = tables[table] ?? const {};
    return FetchRowsResult(
      rows: [
        for (final id in ids)
          if (rows[id] != null && rows[id]!.userId == userId) rows[id]!.toJson(id),
      ],
      missing: [
        for (final id in ids)
          if (rows[id] == null || rows[id]!.userId != userId) id,
      ],
    );
  }

  /// Hard-deletes tombstones deleted before [before] and raises the purge watermark.
  int purgeTombstones(String userId, DateTime before) {
    var purged = 0;
    var maxRev = purgeWatermarks[userId] ?? 0;
    for (final t in tables.values) {
      t.removeWhere((id, r) {
        final deleted = r.values['deleted_at'];
        if (r.userId != userId || deleted is! String) return false;
        if (!DateTime.parse(deleted).isBefore(before)) return false;
        purged++;
        if (r.rev > maxRev) maxRev = r.rev;
        return true;
      });
    }
    // The watermark is a revision: the purge itself happens "at" the current head.
    purgeWatermarks[userId] = purged == 0 ? maxRev : head(userId);
    return purged;
  }

  /// Plain snapshot of one user's rows of [table] (id → values without server columns).
  Map<String, Map<String, Object?>> snapshot(String userId, String table, {Set<String> columns = const {}}) => {
    for (final e in (tables[table] ?? const <String, FakeServerRow>{}).entries)
      if (e.value.userId == userId)
        e.key: {
          for (final v in e.value.values.entries)
            if (columns.isEmpty || columns.contains(v.key)) v.key: v.value,
        },
  };
}

/// [SyncApi] bound to one user of a [FakeSyncServer], with failure injection.
class FakeSyncApi implements SyncApi {
  FakeSyncApi(this.server, this.userId);

  final FakeSyncServer server;
  final String userId;

  /// Every call fails with a `SocketException`.
  bool offline = false;

  /// The server applies the push but the response is lost (network drop mid-push).
  bool dropNextPushResponse = false;

  /// Pull calls fail after this many successful pages (crash between pages).
  int? failPullAfter;
  int _pulls = 0;

  /// Runs before each pull page is returned (e.g. a user edit made while a pull is running).
  Future<void> Function()? beforePull;

  final List<DeviceRegistration> registrations = [];
  final List<Map<String, Object?>> reports = [];

  void _check() {
    if (offline) throw const SocketException('Network is unreachable (fake)');
  }

  @override
  Future<PushResponse> push({
    required String deviceId,
    required int schema,
    required int build,
    required List<Map<String, Object?>> changes,
  }) async {
    _check();
    final encoded = jsonDecode(jsonEncode(changes)) as List;
    final res = server.push(
      userId,
      deviceId: deviceId,
      build: build,
      changes: [for (final c in encoded) Map<String, Object?>.from(c as Map)],
    );
    if (dropNextPushResponse) {
      dropNextPushResponse = false;
      throw const SocketException('Connection reset by peer (fake)');
    }
    return res;
  }

  @override
  Future<PullPage> pull({required int since, int limit = 1000}) async {
    _check();
    if (failPullAfter != null && _pulls >= failPullAfter!) {
      throw const SocketException('Connection closed while pulling (fake)');
    }
    _pulls++;
    final page = server.pull(userId, since: since, limit: limit);
    final hook = beforePull;
    if (hook != null) {
      beforePull = null;
      await hook();
    }
    return page;
  }

  @override
  Future<FetchRowsResult> fetchRows(String table, List<String> ids) async {
    _check();
    return server.fetchRows(userId, table, ids);
  }

  @override
  Future<bool> registerDevice(DeviceRegistration device) async {
    _check();
    registrations.add(device);
    server.devices[device.id] = device;
    return server.revokedDevices.contains(device.id);
  }

  @override
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state) async {
    _check();
    reports.add(DeviceStateKeys.sanitize(state));
    return server.revokedDevices.contains(deviceId);
  }
}

/// One simulated install: in-memory DB, own clock/HLC, writer and sync engine.
class SimDevice {
  SimDevice(
    this.server, {
    required this.userId,
    required this.deviceId,
    DateTime? now,
    int batchSize = 500,
    int pageSize = 1000,
  }) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = FakeClock(now ?? server.now);
    registry = TableRegistry(db);
    hlc = Hlc(deviceId: deviceId, clock: clock);
    writer = SyncWriter(db: db, registry: registry, clock: clock, hlc: hlc, userId: () => userId, deviceId: deviceId);
    api = FakeSyncApi(server, userId);
    sync = SyncService(
      db: db,
      registry: registry,
      api: api,
      hlc: hlc,
      clock: clock,
      userId: () => userId,
      deviceId: deviceId,
      appBuild: 1,
      batchSize: batchSize,
      pageSize: pageSize,
    );
  }

  final FakeSyncServer server;
  final String userId;
  final String deviceId;
  late final AppDatabase db;
  late final FakeClock clock;
  late final TableRegistry registry;
  late final Hlc hlc;
  late final SyncWriter writer;
  late final FakeSyncApi api;
  late final SyncService sync;

  Future<List<OutboxRow>> outbox() => (db.select(db.syncOutbox)..orderBy([(o) => OrderingTerm.asc(o.seq)])).get();

  /// Local rows of [table] (id → selected columns).
  Future<Map<String, Map<String, Object?>>> rows(String table, List<String> columns) async {
    final result = await db.customSelect('SELECT id, ${columns.join(', ')} FROM $table').get();
    return {
      for (final r in result) r.data['id'] as String: {for (final c in columns) c: r.data[c]},
    };
  }

  Future<void> dispose() async {
    sync.dispose();
    await db.close();
  }
}
