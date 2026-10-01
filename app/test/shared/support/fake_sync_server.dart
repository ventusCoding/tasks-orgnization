import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// In-memory stand-in for the Supabase sync RPCs (arch §6.6): per-field last-writer-wins by HLC,
/// a per-user revision counter and pull-by-revision. Enough to run two-client convergence tests.
class FakeSyncServer implements SyncApi {
  FakeSyncServer({this.userId = 'user-1'});

  final String userId;
  final Map<String, Map<String, Map<String, Object?>>> _rows = {};
  final Map<String, Map<String, Map<String, String>>> _clocks = {};
  int _head = 0;

  /// Server rows of [table] (id → server JSON row).
  Map<String, Map<String, Object?>> rows(String table) => _rows[table] ?? const {};

  @override
  Future<PushResponse> push({
    required String deviceId,
    required int schema,
    required int build,
    required List<Map<String, Object?>> changes,
  }) async {
    final results = <PushResult>[];
    for (final change in changes) {
      final table = change['t']! as String;
      final rowId = change['row_id']! as String;
      final fields = Map<String, Object?>.from(change['fields']! as Map);
      final clock = Map<String, Object?>.from(change['clock']! as Map);
      final row = _rows.putIfAbsent(table, () => {}).putIfAbsent(rowId, () => {'id': rowId});
      final rowClock = _clocks.putIfAbsent(table, () => {}).putIfAbsent(rowId, () => {});
      var applied = 0;
      for (final entry in fields.entries) {
        final incoming = clock[entry.key] as String? ?? '';
        final current = rowClock[entry.key];
        if (current == null || incoming.compareTo(current) > 0) {
          row[entry.key] = entry.value;
          rowClock[entry.key] = incoming;
          applied++;
        }
      }
      if (applied > 0) {
        row
          ..['user_id'] = userId
          ..['rev'] = ++_head
          ..['field_clock'] = Map<String, String>.of(rowClock);
      }
      results.add(
        PushResult(
          changeId: change['id']! as String,
          status: applied == fields.length ? 'applied' : (applied == 0 ? 'stale' : 'partial'),
        ),
      );
    }
    return PushResponse(results, _head);
  }

  @override
  Future<PullPage> pull({required int since, int limit = 1000}) async {
    final changes = <(int, PullChange)>[];
    for (final table in _rows.entries) {
      for (final row in table.value.values) {
        final rev = row['rev'] as int? ?? 0;
        if (rev > since) changes.add((rev, PullChange(table.key, Map.of(row))));
      }
    }
    changes.sort((a, b) => a.$1.compareTo(b.$1));
    final page = changes.take(limit).toList();
    return PullPage(
      changes: [for (final c in page) c.$2],
      next: page.isEmpty ? since : page.last.$1,
      more: changes.length > page.length,
      purgeWatermark: 0,
    );
  }

  @override
  Future<FetchRowsResult> fetchRows(String table, List<String> ids) async => FetchRowsResult(
    rows: [
      for (final id in ids)
        if (_rows[table]?[id] != null) Map<String, dynamic>.of(_rows[table]![id]!),
    ],
    missing: [
      for (final id in ids)
        if (_rows[table]?[id] == null) id,
    ],
  );

  @override
  Future<bool> registerDevice(DeviceRegistration device) async => false;

  @override
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state) async => false;
}

/// One simulated device: its own in-memory database, providers, HLC and sync engine.
class SyncDevice {
  factory SyncDevice(FakeSyncServer server, String deviceId, {DateTime? now}) {
    // Each device intentionally has its own in-memory database.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final clock = FakeClock(now ?? DateTime.utc(2026, 9, 22, 9));
    SessionController.initial = AppSession(userId: server.userId, mode: SessionMode.localOnly);
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(
          const Env(
            flavor: Flavor.dev,
            supabaseUrl: '',
            supabasePublishableKey: '',
            firebaseEnabled: false,
            featureFlags: {},
          ),
        ),
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        deviceIdProvider.overrideWithValue(deviceId),
      ],
    );
    final service = SyncService(
      db: db,
      registry: container.read(tableRegistryProvider),
      api: server,
      hlc: container.read(hlcProvider),
      clock: clock,
      userId: () => server.userId,
      deviceId: deviceId,
      appBuild: 1,
    );
    return SyncDevice._(db, container, service);
  }
  SyncDevice._(this.db, this.container, this.service);

  final AppDatabase db;
  final ProviderContainer container;
  final SyncService service;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Push pending changes, then pull everything new.
  Future<void> sync() => service.syncNow();

  Future<void> dispose() async {
    service.dispose();
    container.dispose();
    await db.close();
  }
}
