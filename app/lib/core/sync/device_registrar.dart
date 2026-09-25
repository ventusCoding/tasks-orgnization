import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Loads what `app.register_device` needs about this install.
typedef DeviceInfoLoader = Future<DeviceRegistration> Function();

/// Device registry client (T1.4.05): registers this install after sign-in, on start and on
/// resume — throttled to once per [interval] per user — and reports when the server says the
/// device was revoked (Settings › Devices on another device, T8.3.04).
class DeviceRegistrar {
  DeviceRegistrar({
    required this.api,
    required this.db,
    required this.clock,
    required this.userId,
    required this.loadInfo,
    this.interval = const Duration(hours: 1),
  });

  final SyncApi api;
  final AppDatabase db;
  final Clock clock;
  final String Function() userId;
  final DeviceInfoLoader loadInfo;
  final Duration interval;

  static final _log = AppLog.get('devices');

  Future<bool?>? _inFlight;

  static String throttleKey(String userId) => 'device_registered_at:$userId';

  /// Registers the device unless it was registered for this user less than [interval] ago
  /// (or [force]). Returns true when the server reports the device as revoked, false when
  /// registered, null when skipped (throttled, signed out) or failed (retried next time).
  Future<bool?> maybeRegister({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _register(force: force);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<bool?> _register({required bool force}) async {
    final uid = userId();
    if (uid.isEmpty) return null;
    final key = throttleKey(uid);
    final now = clock.nowUtc();
    if (!force) {
      final row = await db
          .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
          .getSingleOrNull();
      final last = DateTime.tryParse(row?.data['value'] as String? ?? '');
      if (last != null && now.difference(last) < interval && !now.isBefore(last)) return null;
    }
    try {
      final info = await loadInfo();
      final revoked = await api.registerDevice(info);
      await db.customStatement(
        'INSERT INTO local_kv(key, value) VALUES (?, ?) '
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        [key, now.toIso8601String()],
      );
      if (revoked) _log.warning('register_device: this device is revoked');
      return revoked;
    } on SyncApiException catch (e) {
      if (e.code == SyncApiException.deviceRevoked) return true;
      _log.info('register_device failed: ${e.code}');
      return null;
    } on Object catch (e) {
      _log.info('register_device failed (will retry): $e');
      return null;
    }
  }

  /// Forgets the throttle (after sign-out / device id rotation).
  Future<void> reset(String userId) =>
      db.customStatement('DELETE FROM local_kv WHERE key = ?', [throttleKey(userId)]);
}

/// Real [DeviceInfoLoader] (package_info_plus + device_info_plus). Never includes user content.
DeviceInfoLoader platformDeviceInfoLoader({
  required String deviceId,
  required String Function() timeZone,
  required String Function() locale,
  required int build,
}) => () async {
  var platform = 'android';
  String? model;
  String? osVersion;
  String? deviceName;
  String? appVersion;
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      platform = 'ios';
      final ios = await plugin.iosInfo;
      model = ios.utsname.machine;
      osVersion = ios.systemVersion;
      deviceName = ios.name;
    } else if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      model = '${android.manufacturer} ${android.model}'.trim();
      osVersion = android.version.release;
      deviceName = android.name.isEmpty ? android.model : android.name;
    } else if (Platform.isMacOS) {
      platform = 'macos';
    } else if (Platform.isWindows) {
      platform = 'windows';
    } else if (Platform.isLinux) {
      platform = 'linux';
    }
  } on Object {
    // Unsupported platform / tests: keep defaults.
  }
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } on Object {
    // tests
  }
  return DeviceRegistration(
    id: deviceId,
    platform: platform,
    model: model,
    osVersion: osVersion,
    appVersion: appVersion,
    appBuild: build,
    locale: locale(),
    timeZone: timeZone(),
    deviceName: deviceName == null || deviceName.length <= 200 ? deviceName : deviceName.substring(0, 200),
  );
};
