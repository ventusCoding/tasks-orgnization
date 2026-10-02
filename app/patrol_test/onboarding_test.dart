// Onboarding E2E (T8.3.11): the tour on a real device, including the OS notification dialog that
// only follows the in-app primer. Run: `patrol test --flavor dev -t patrol_test/onboarding_test.dart
// --dart-define-from-file=env/example.json` (docs/guide.md › End-to-end tests).
import 'package:everslot/app/router.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/e2e.dart';

void main() {
  patrolTest('the tour asks for notifications after the primer and creates the chosen starter', config: e2eConfig, (
    $,
  ) async {
    final c = await launchEverslot($, skipSetup: false);
    // Already set up on this device: the tour is re-runnable from Settings.
    if (!$('Set up Everslot').exists) {
      c.read(routerProvider).go('/onboarding');
      await $.pumpAndSettle();
    }
    await $('Own every slot of your day').waitUntilVisible();
    await $('Continue').tap(); // welcome
    await $('Continue').tap(); // language, zone, week, clock
    await $('What do you want to track?').waitUntilVisible();
    await $('Continue').tap();

    await $('Never miss what matters').waitUntilVisible();
    if ($('Allow notifications').exists) {
      expect(
        await $.platform.mobile.isPermissionDialogVisible(timeout: const Duration(seconds: 2)),
        isFalse,
        reason: 'no OS prompt before the primer button',
      );
      await $('Allow notifications').tap();
      if (await $.platform.mobile.isPermissionDialogVisible(timeout: const Duration(seconds: 15))) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }
      await $('Notifications are on').waitUntilVisible();
    }
    expect(c.read(notificationCapabilitiesProvider).notifications, isTrue);
    await $('Continue').tap();

    await $('Start with something?').waitUntilVisible();
    await $('Drink water').tap();
    await $('Get started').tap();
    await $.pumpAndSettle();

    final profile = await c.read(profileRepositoryProvider).read();
    expect(profile?.onboardingDone, isTrue);
    final db = c.read(appDatabaseProvider);
    final habits = await (db.select(db.habits)..where((t) => t.name.equals('Drink water'))).get();
    expect(habits, isNotEmpty, reason: 'starter created');
    expect(habits.first, isA<HabitRow>());
  });
}
