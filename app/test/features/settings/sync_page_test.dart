import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/settings/application/sync_settings_providers.dart';
import 'package:everslot/features/settings/data/devices_repository.dart';
import 'package:everslot/features/settings/domain/device_info.dart';
import 'package:everslot/features/settings/presentation/pages/sync_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/cloud_sync_harness.dart';
import '../auth/support/widget_helpers.dart';

class _FakeDevices implements DevicesRepository {
  _FakeDevices(this.devices);

  List<DeviceInfo> devices;
  final revoked = <String>[];
  bool offline = false;

  @override
  Future<List<DeviceInfo>> list() async {
    if (offline) throw const SocketException('offline (fake)');
    return devices;
  }

  @override
  Future<void> revoke(String id) async {
    revoked.add(id);
    devices = [
      for (final d in devices)
        d.id == id
            ? DeviceInfo(id: d.id, platform: d.platform, name: d.name, revokedAt: DateTime.utc(2026, 9, 22))
            : d,
    ];
  }
}

class _Fixed extends SyncStatusController {
  _Fixed(this.value);

  final SyncStatus value;

  @override
  SyncStatus build() => value;
}

/// Runs [write] in the fake-async zone and pumps until it completes (the in-memory database is
/// synchronous; its futures resolve through microtasks flushed by pumps).
Future<void> _write(WidgetTester tester, Future<void> Function() write) async {
  var done = false;
  Object? error;
  write().then<void>((_) => done = true, onError: (Object e) => error = e);
  for (var i = 0; i < 20 && !done && error == null; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  if (error != null) throw error!;
  expect(done, isTrue, reason: 'write did not complete');
}

final _now = DateTime.utc(2026, 9, 22, 9);

List<DeviceInfo> _devices() => [
  DeviceInfo(id: 'd2', platform: 'android', name: 'Pixel 9', lastSeenAt: _now.subtract(const Duration(hours: 2)), pushEnabled: true, hasPushToken: true),
  DeviceInfo(id: 'device-test', platform: 'ios', name: 'iPhone', lastSeenAt: _now),
  DeviceInfo(id: 'd3', platform: 'android', name: 'Old tablet', revokedAt: DateTime.utc(2026, 9)),
];

void main() {
  testWidgets('local-only: sync is off, data pages stay reachable (T8.3.04)', (tester) async {
    final h = TestHarness.create();
    await pumpInApp(tester, h, const SyncPage());
    await settle(tester);
    expect(find.text('Sync is off'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-now')), findsNothing);
    expect(find.text('Export & import'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-in')), findsNothing, reason: 'cloud not configured on this build');
    await finish(tester, h);
  });

  testWidgets('the pending count goes down after Sync now', (tester) async {
    final devices = _FakeDevices([]);
    final d = (await tester.runAsync(
      () => CloudDevice.create(overrides: [devicesRepositoryProvider.overrideWithValue(devices)]),
    ))!;
    d.api.offline = true;
    await pumpInApp(tester, d.h, const SyncPage());
    await settle(tester);
    await _write(tester, () => d.addCategory('c1', 'Work'));
    await _write(tester, () => d.addCategory('c2', 'Home'));
    await settle(tester);
    expect(find.text('2 changes waiting'), findsOneWidget);

    d.api.offline = false;
    await tester.tap(find.byKey(const ValueKey('sync-now')));
    await settle(tester, rounds: 10);
    expect(find.text('No pending changes'), findsOneWidget);
    expect(d.server.row('categories', 'c2'), isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });

  testWidgets('error details and Force full resync behind a confirmation', (tester) async {
    final d = (await tester.runAsync(
      () => CloudDevice.create(
        overrides: [
          devicesRepositoryProvider.overrideWithValue(_FakeDevices([])),
          syncStatusProvider.overrideWith(
            () => _Fixed(const SyncStatus(phase: SyncPhase.error, lastError: 'HTTP 500 upstream timeout')),
          ),
        ],
      ),
    ))!;
    var pulls = 0;
    await pumpInApp(tester, d.h, const SyncPage());
    await settle(tester);
    expect(find.text('Sync problem'), findsOneWidget);
    await tester.tap(find.text('Last error'));
    await pumpFrames(tester);
    expect(find.text('HTTP 500 upstream timeout'), findsOneWidget);

    d.api.beforePull = () async => pulls++;
    await tester.tap(find.byKey(const ValueKey('sync-resync')));
    await pumpFrames(tester);
    expect(find.text('Resync everything?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, rounds: 10);
    expect(pulls, 1, reason: 'a pull from revision 0 ran');
    expect(d.h.read(syncServiceProvider)!.knownCursor, d.server.head('u1'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });

  testWidgets('devices: revoked ones hidden, this device first, remove another one', (tester) async {
    final devices = _FakeDevices(_devices());
    final d = (await tester.runAsync(
      () => CloudDevice.create(overrides: [devicesRepositoryProvider.overrideWithValue(devices)]),
    ))!;
    d.h.clock.set(_now);
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await pumpInApp(tester, d.h, const SyncPage());
    await settle(tester);
    expect(find.text('iPhone · This device'), findsOneWidget);
    expect(find.text('Pixel 9'), findsOneWidget);
    expect(find.text('Old tablet'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('device-device-test'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('device-d2'))).dy),
    );

    await tester.tap(find.byTooltip('Remove device'));
    await pumpFrames(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Remove device')));
    await settle(tester);
    expect(devices.revoked, ['d2']);
    expect(find.text('Pixel 9'), findsNothing);
    expect(find.text('Device removed'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });

  testWidgets('devices offline: explained, with a retry', (tester) async {
    final devices = _FakeDevices(_devices())..offline = true;
    final d = (await tester.runAsync(
      () => CloudDevice.create(overrides: [devicesRepositoryProvider.overrideWithValue(devices)]),
    ))!;
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await pumpInApp(tester, d.h, const SyncPage());
    await settle(tester);
    expect(find.byKey(const ValueKey('devices-offline')), findsOneWidget);
    devices.offline = false;
    await tester.tap(find.byTooltip('Retry'));
    await settle(tester);
    expect(find.text('Pixel 9'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });
}

/// Bounded frames for dialogs and expansion animations (never `pumpAndSettle`).
Future<void> pumpFrames(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
