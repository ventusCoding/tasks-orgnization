import 'dart:async';
import 'dart:ui';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/device_identity.dart';
import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/session/secure_session_storage.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

/// What one background run did.
enum BackgroundSyncOutcome {
  /// Pushed and pulled successfully.
  synced,

  /// Nothing to do: local-only / signed out / not configured, or the foreground app holds the sync
  /// lock (it syncs itself).
  skipped,

  /// Offline or refused by the server; the foreground retries.
  failed,

  /// The time budget ran out (the lease expires on its own; the next run resumes from the saved
  /// cursor — pages are applied atomically with their cursor).
  timedOut,
}

/// Background sync (T1.4.17): a periodic WorkManager task (Android ≥ 15 min; iOS BGAppRefresh,
/// best effort) and FCM `{"type": "sync"}` data messages ([7.4]) push and pull from a background
/// isolate within a time budget. The foreground engine and the background run share the SQLite
/// file; the cross-isolate [SyncLock] lease guarantees only one of them syncs at a time.
///
/// Integration: the app has ONE WorkManager dispatcher (`notificationsWorkmanagerDispatcher`, [7.2]);
/// it routes [periodicTask] to [runTask] and re-plans notifications afterwards. The FCM background
/// handler calls [runTask] for `sync` data messages.
abstract final class BackgroundSync {
  static const periodicTask = 'everslot.sync.periodic';

  /// FCM data message `type` that asks for a sync.
  static const dataMessageType = 'sync';

  /// Budget of one run (FCM background handlers get ~30 s).
  static const budget = Duration(seconds: 25);

  static const frequency = Duration(minutes: 30);

  static final _log = AppLog.get('sync.background');

  /// Runs [service] once within [budget]. The caller owns (and disposes) the service.
  static Future<BackgroundSyncOutcome> runWith(SyncService service, {Duration budget = BackgroundSync.budget}) async {
    final holder = await service.lock.holder();
    if (holder != null && holder != service.lock.owner) {
      _log.info('background sync skipped: $holder holds the sync lock');
      return BackgroundSyncOutcome.skipped;
    }
    final before = service.status.value.lastSuccessAt;
    try {
      await service.syncNow().timeout(budget);
    } on TimeoutException {
      _log.info('background sync ran out of time (${budget.inSeconds} s)');
      return BackgroundSyncOutcome.timedOut;
    }
    final status = service.status.value;
    if (status.phase == SyncPhase.idle && status.lastSuccessAt != null && status.lastSuccessAt != before) {
      return BackgroundSyncOutcome.synced;
    }
    if (status.phase == SyncPhase.idle) return BackgroundSyncOutcome.skipped;
    return BackgroundSyncOutcome.failed;
  }

  /// A sync engine for a background isolate: its own lock owner (`bg-…`), no periodic timer, no
  /// Broadcast channel, same guard as the foreground (local data must belong to [userId]).
  static SyncService createService({
    required AppDatabase db,
    required SyncApi api,
    required String userId,
    required String deviceId,
    required Clock clock,
    String? hlcState,
    int appBuild = 1,
  }) => SyncService(
    db: db,
    registry: TableRegistry(db),
    api: api,
    hlc: Hlc(deviceId: deviceId, clock: clock, initialState: hlcState),
    clock: clock,
    userId: () => userId,
    deviceId: deviceId,
    appBuild: appBuild,
    lockOwner: 'bg-${Ids.v7()}',
    guard: () => LocalDataOwner.matches(db, userId),
  );

  /// Entry point of the WorkManager task and the FCM `sync` handler (background isolate, or the
  /// main isolate on iOS). Restores the signed-in session from the secure storage (a refreshed
  /// token is written back, so the foreground keeps a valid refresh token), opens the database
  /// and runs one sync. Never throws.
  static Future<BackgroundSyncOutcome> runTask({Duration budget = BackgroundSync.budget}) async {
    final watch = Stopwatch()..start();
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final env = Env.fromEnvironment();
    if (!env.isSupabaseConfigured) return BackgroundSyncOutcome.skipped;
    final client = await _client(env);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return BackgroundSyncOutcome.skipped;
    final db = AppDatabase();
    SyncService? service;
    try {
      final deviceId = await DeviceIdentity.load(db);
      final hlc = await (db.select(db.localKv)..where((k) => k.key.equals(SyncService.hlcStateKey))).getSingleOrNull();
      var build = 1;
      try {
        build = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 1;
      } on Object {
        // unknown build: the server treats it as the oldest client
      }
      service = createService(
        db: db,
        api: SupabaseSyncApi(client),
        userId: user.id,
        deviceId: deviceId,
        clock: const SystemClock(),
        hlcState: hlc?.value,
        appBuild: build,
      );
      final left = budget - watch.elapsed;
      if (left <= Duration.zero) return BackgroundSyncOutcome.timedOut;
      final outcome = await runWith(service, budget: left);
      _log.info('background sync: ${outcome.name} in ${watch.elapsedMilliseconds} ms');
      return outcome;
    } on Object catch (e, st) {
      _log.warning('background sync failed', e, st);
      return BackgroundSyncOutcome.failed;
    } finally {
      service?.dispose();
      await db.close();
    }
  }

  static Future<SupabaseClient?> _client(Env env) async {
    try {
      return Supabase.instance.client; // main isolate (app alive, e.g. iOS background push)
    } on Object {
      // Fresh background isolate: initialize below.
    }
    try {
      await Supabase.initialize(
        url: env.supabaseUrl,
        publishableKey: env.supabasePublishableKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: SecureSessionStorage(),
          pkceAsyncStorage: SecurePkceStorage(),
          detectSessionInUri: false,
        ),
      );
      return Supabase.instance.client;
    } on Object catch (e) {
      _log.info('background sync: Supabase unavailable ($e)');
      return null;
    }
  }

  /// Registers the periodic task (network required). WorkManager must be initialized with the
  /// app's dispatcher (the notifications feature does it at start).
  static Future<void> registerPeriodic() async {
    try {
      await Workmanager().registerPeriodicTask(
        periodicTask,
        periodicTask,
        frequency: frequency,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } on Object catch (e) {
      _log.info('periodic background sync unavailable: $e');
    }
  }

  /// Cancels the periodic task (sign-out, local-only).
  static Future<void> cancelPeriodic() async {
    try {
      await Workmanager().cancelByUniqueName(periodicTask);
    } on Object {
      // not registered / plugin unavailable
    }
  }
}

/// Startup task (T1.4.17): cloud sessions get the periodic background sync; local-only devices
/// and signed-out states cancel it. Runs again after every account change.
Future<void> scheduleBackgroundSync(ProviderContainer container) async {
  final session = container.read(sessionProvider);
  if (session != null && session.isCloud) {
    unawaited(BackgroundSync.registerPeriodic());
  } else {
    unawaited(BackgroundSync.cancelPeriodic());
  }
}
