import 'dart:async';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/lifecycle/app_lifecycle.dart';
import 'package:everslot/core/preferences/user_preferences.dart';
import 'package:everslot/core/session/device_identity.dart';
import 'package:everslot/core/session/local_data_owner.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/core/sync/device_registrar.dart';
import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/core/undo/undo_stack.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core providers (manual Riverpod providers — no code generation, ADR-003 update).
// Values marked "override in bootstrap" are provided by `bootstrap.dart` via ProviderScope overrides.

/// Build/runtime configuration. Override in bootstrap.
final envProvider = Provider<Env>((ref) => Env.fromEnvironment());

/// The local database. Override in bootstrap (and with an in-memory DB in tests).
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

/// Per-install device id. Override in bootstrap.
final deviceIdProvider = Provider<String>((ref) => 'test-device');

/// App build number (sync min-version gate). Override in bootstrap.
final appBuildProvider = Provider<int>((ref) => 1);

/// Supabase client, or null in local-only mode. Override in bootstrap.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final zoneResolverProvider = Provider<ZoneResolver>((ref) => TzZoneResolver());

final lifecycleProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService();
  ref.onDispose(service.dispose);
  return service;
});

/// Current IANA zone of the device (refreshed on resume, T1.5.06).
final deviceZoneProvider = NotifierProvider<DeviceZoneController, String>(DeviceZoneController.new);

class DeviceZoneController extends Notifier<String> {
  /// Initial value (override in bootstrap with the detected zone).
  static String initialZone = 'UTC';

  @override
  String build() {
    final sub = ref.watch(lifecycleProvider).onResume.listen((_) => unawaited(refresh()));
    ref.onDispose(sub.cancel);
    return initialZone;
  }

  Future<void> refresh() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final zone = info.identifier;
      if (zone.isNotEmpty && zone != state) state = zone;
    } on Object {
      // keep previous value
    }
  }

  /// Debug override (time-zone travel simulation).
  // ignore: use_setters_to_change_properties
  void debugSet(String zone) => state = zone;
}

/// The signed-in or local user. The auth feature ([1.5]) drives cloud sessions.
final sessionProvider = NotifierProvider<SessionController, AppSession?>(SessionController.new);

class SessionController extends Notifier<AppSession?> {
  /// Initial session (override in bootstrap).
  static AppSession? initial;

  @override
  AppSession? build() => initial;

  // ignore: use_setters_to_change_properties
  void set(AppSession? session) => state = session;
}

/// Current user id ('' when signed out).
final currentUserIdProvider = Provider<String>((ref) => ref.watch(sessionProvider)?.userId ?? '');

final tableRegistryProvider = Provider<TableRegistry>(
  (ref) => TableRegistry(ref.watch(appDatabaseProvider)),
);

/// Hybrid logical clock. Its persisted state is loaded in bootstrap (`Hlc.initialState`).
final hlcProvider = Provider<Hlc>(
  (ref) => Hlc(
    deviceId: ref.watch(deviceIdProvider),
    clock: ref.watch(clockProvider),
    initialState: HlcBootstrap.initialState,
  ),
);

abstract final class HlcBootstrap {
  static String? initialState;
}

/// The single write path for synced data.
final syncWriterProvider = Provider<SyncWriter>((ref) {
  final writer = SyncWriter(
    db: ref.watch(appDatabaseProvider),
    registry: ref.watch(tableRegistryProvider),
    clock: ref.watch(clockProvider),
    hlc: ref.watch(hlcProvider),
    userId: () => ref.read(currentUserIdProvider),
    deviceId: ref.watch(deviceIdProvider),
    onCommitted: (_) => ref.read(syncServiceProvider)?.schedulePush(),
  );
  return writer;
});

/// Device id used for the device registry and pushes. Starts as [deviceIdProvider]; rotated
/// after the server revoked this device (T1.5.14) so the next sign-in registers a new device.
final activeDeviceIdProvider = NotifierProvider<ActiveDeviceIdController, String>(
  ActiveDeviceIdController.new,
);

class ActiveDeviceIdController extends Notifier<String> {
  @override
  String build() => ref.watch(deviceIdProvider);

  Future<void> rotate() async {
    state = await DeviceIdentity.rotate(ref.read(appDatabaseProvider));
  }
}

/// Server API of the sync engine (null when Supabase isn't configured). Tests override it with a
/// fake to exercise the engine without a backend.
final syncApiProvider = Provider<SyncApi?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseSyncApi(client);
});

/// Device registry client (T1.4.05), or null in local-only mode / when signed out.
final deviceRegistrarProvider = Provider<DeviceRegistrar?>((ref) {
  final api = ref.watch(syncApiProvider);
  final session = ref.watch(sessionProvider);
  if (api == null || session == null || session.isLocalOnly) return null;
  return DeviceRegistrar(
    api: api,
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    userId: () => ref.read(currentUserIdProvider),
    loadInfo: platformDeviceInfoLoader(
      deviceId: ref.watch(activeDeviceIdProvider),
      timeZone: () => ref.read(deviceZoneProvider),
      locale: () =>
          ref.read(profileRowProvider).value?.locale ??
          PlatformDispatcher.instance.locale.toLanguageTag(),
      build: ref.watch(appBuildProvider),
    ),
  );
});

/// Sync engine, or null in local-only mode / when signed out.
final syncServiceProvider = Provider<SyncService?>((ref) {
  final api = ref.watch(syncApiProvider);
  final session = ref.watch(sessionProvider);
  if (api == null || session == null || session.isLocalOnly) return null;
  final db = ref.watch(appDatabaseProvider);
  final service = SyncService(
    db: db,
    registry: ref.watch(tableRegistryProvider),
    api: api,
    hlc: ref.watch(hlcProvider),
    clock: ref.watch(clockProvider),
    userId: () => ref.read(currentUserIdProvider),
    deviceId: ref.watch(activeDeviceIdProvider),
    appBuild: ref.watch(appBuildProvider),
    // Account-switch safety (T1.5.08): never push/pull before the local data is bound to this user.
    guard: () => LocalDataOwner.matches(db, session.userId),
  )..start();
  final registrar = ref.watch(deviceRegistrarProvider);
  Future<void> register() async {
    final revoked = await registrar?.maybeRegister();
    if (revoked ?? false) service.markRevoked();
  }

  unawaited(register());
  final lifecycle = ref.watch(lifecycleProvider);
  final sub = lifecycle.onResume.listen((_) {
    service.schedulePull(Duration.zero);
    unawaited(register());
  });
  final client = ref.watch(supabaseClientProvider);
  final channel = client
      ?.channel('user:${session.userId}', opts: const RealtimeChannelConfig(private: true))
      .onBroadcast(event: 'sync', callback: (_) => service.schedulePull())
      .subscribe();
  ref.onDispose(() {
    unawaited(sub.cancel());
    if (channel != null) unawaited(client!.removeChannel(channel));
    service.dispose();
  });
  return service;
});

/// Sync status for the UI (local-only when no service).
final syncStatusProvider = NotifierProvider<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);

class SyncStatusController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    final service = ref.watch(syncServiceProvider);
    if (service == null) return SyncStatus.localOnly;
    void listener() => state = service.status.value;
    service.status.addListener(listener);
    ref.onDispose(() => service.status.removeListener(listener));
    return service.status.value;
  }
}

final undoStackProvider = Provider<UndoStack>((ref) {
  final stack = UndoStack(ref.watch(syncWriterProvider));
  ref.onDispose(stack.dispose);
  return stack;
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Settings map of one namespace (live).
final settingsProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, namespace) {
    ref.watch(currentUserIdProvider);
    return ref.watch(settingsRepositoryProvider).watch(namespace);
  },
);

/// Live profile row of the current user.
final profileRowProvider = StreamProvider<ProfileRow?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return (db.select(db.profiles)..where((p) => p.id.equals(userId))).watchSingleOrNull();
});

/// Resolved preferences (profile + regional/habits settings + device zone).
final userPreferencesProvider = Provider<UserPreferences>((ref) {
  final profile = ref.watch(profileRowProvider).value;
  final regional = ref.watch(settingsProvider(SettingsNs.regional)).value ?? const {};
  final habits = ref.watch(settingsProvider(SettingsNs.habits)).value ?? const {};
  final appearance = ref.watch(settingsProvider(SettingsNs.appearance)).value ?? const {};
  final zone = ref.watch(deviceZoneProvider);
  return UserPreferences(
    weekStart: Weekday.fromIso((profile?.weekStart ?? 1).clamp(1, 7)),
    use24h: (profile?.timeFormat ?? 'h24') == 'h24',
    dayStartMinutes: (habits['dayStartMinutes'] as num?)?.toInt() ?? 0,
    homeTimeZone: profile?.homeTimeZone ?? zone,
    currentTimeZone: zone,
    localeCode: profile?.locale,
    currency: regional['currency'] as String? ?? 'EUR',
    useArabicDigits: appearance['arabicDigits'] as bool? ?? false,
  );
});

/// Debug-only feature flag overrides (T1.3.16).
final featureFlagsProvider = NotifierProvider<FeatureFlagsController, Set<String>>(
  FeatureFlagsController.new,
);

class FeatureFlagsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(envProvider).featureFlags;

  void toggle(String flag) {
    if (!kDebugMode) return;
    state = state.contains(flag) ? ({...state}..remove(flag)) : {...state, flag};
  }
}
