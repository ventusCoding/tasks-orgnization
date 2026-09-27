import 'package:everslot/core/providers.dart';
import 'package:everslot/features/settings/data/devices_repository.dart';
import 'package:everslot/features/settings/data/sync_outbox_queries.dart';
import 'package:everslot/features/settings/domain/device_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Devices of the signed-in account, or null in local-only mode / signed out (T8.3.04).
final devicesRepositoryProvider = Provider<DevicesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (client == null || session == null || !session.isCloud) return null;
  return SupabaseDevicesRepository(client);
});

/// Visible devices (revoked ones hidden, this device first). Errors (offline) surface as
/// AsyncError; refresh with `ref.invalidate(devicesProvider)`.
final devicesProvider = FutureProvider.autoDispose<List<DeviceInfo>>((ref) async {
  final repo = ref.watch(devicesRepositoryProvider);
  if (repo == null) return const [];
  return visibleDevices(await repo.list(), ref.watch(activeDeviceIdProvider));
});

final syncOutboxQueriesProvider = Provider<SyncOutboxQueries>(
  (ref) => SyncOutboxQueries(ref.watch(appDatabaseProvider)),
);

/// Live `(pending, failed)` outbox counts.
final outboxCountsProvider = StreamProvider.autoDispose<({int pending, int failed})>(
  (ref) => ref.watch(syncOutboxQueriesProvider).watchCounts(),
);

/// Persisted sync state of the user (cursor, last pull/push) for the status card.
final syncStateProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return (db.select(db.syncState)..where((s) => s.userId.equals(userId))).watchSingleOrNull();
});
