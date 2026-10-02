// Patrol E2E harness (T9.1.07): boots the real app (dev flavor, local-only mode unless env says
// otherwise), hands the test its ProviderContainer for seeding / assertions through application
// APIs, and wraps the native helpers the suites share (permission dialogs, notification shade).

import 'package:everslot/bootstrap.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/startup/bootstrap_platform.dart';
import 'package:flutter/widgets.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Default timeouts for emulator runs (cold Flutter engine + Drift isolate).
const e2eConfig = PatrolTesterConfig(existsTimeout: Duration(seconds: 20), visibleTimeout: Duration(seconds: 20));

class _E2ePlatform extends RealBootstrapPlatform {
  _E2ePlatform(this.onContainer);

  final void Function(ProviderContainer container) onContainer;

  @override
  void launch(Widget root) {
    if (root is UncontrolledProviderScope) onContainer(root.container);
    super.launch(root);
  }
}

/// Starts Everslot like `main_dev.dart` and returns its provider container.
Future<ProviderContainer> launchEverslot(PatrolIntegrationTester $) async {
  // The app installs its own FlutterError handler; the test binding requires its own back.
  final testHandler = FlutterError.onError;
  ProviderContainer? container;
  await bootstrap(Flavor.dev, platform: _E2ePlatform((c) => container = c));
  FlutterError.onError = testHandler;
  await $.pumpAndSettle();
  if (container == null) fail('bootstrap did not reach the app (see the error screen)');
  // First run: leave the setup screen so deep links (notification taps) can navigate.
  try {
    await $('Set up Everslot').waitUntilVisible(timeout: const Duration(seconds: 5));
    await $('Skip').tap();
  } on WaitUntilVisibleTimeoutException {
    // already set up
  }
  return container!;
}

/// Asks for the notification permission through the app and accepts the OS dialog (Android 13+
/// "Allow", iOS "Allow"); fails when the app still reports it denied.
Future<void> grantNotifications(PatrolIntegrationTester $, ProviderContainer container) async {
  final granted = container.read(notificationCapabilitiesProvider.notifier).requestNotifications();
  final allow = Selector(text: 'Allow');
  if (await $.platform.mobile.isPermissionDialogVisible(timeout: const Duration(seconds: 15))) {
    await $.platform.mobile.tap(allow, timeout: const Duration(seconds: 10));
  }
  expect(await granted, isTrue, reason: 'notifications must be allowed for the E2E suite');
}

/// Polls the notification shade until [matches] holds for everything seen so far (reminders
/// expire — "1 min before" is gone once "at start" shows — so sightings accumulate). The shade
/// stays open on success.
Future<List<Notification>> waitForNotifications(
  PatrolIntegrationTester $,
  bool Function(List<Notification> seen) matches, {
  Duration timeout = const Duration(minutes: 7),
}) async {
  final deadline = DateTime.now().add(timeout);
  final seen = <Notification>[];
  while (DateTime.now().isBefore(deadline)) {
    await $.platform.mobile.openNotifications();
    for (final n in await $.platform.mobile.getNotifications()) {
      if (!seen.any((s) => s.title == n.title && s.content == n.content)) seen.add(n);
    }
    if (matches(seen)) return seen;
    await $.platform.mobile.pressHome(); // closes the shade (closeNotifications fails if it's gone)
    await Future<void>.delayed(const Duration(seconds: 5));
  }
  fail('notifications not shown in time; seen: ${seen.map((n) => '${n.title} — ${n.content}').toList()}');
}
