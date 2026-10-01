import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/presentation/permission_primers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  late InMemoryLocalNotificationsPort port;
  setUp(() {
    h = TestHarness.create();
    port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
  });
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpBanner(WidgetTester tester, {bool showExact = true, Locale locale = const Locale('en')}) async {
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: ListView(children: [NotificationPermissionBanner(showExact: showExact)]),
      ),
      locale: locale,
    );
    await settle(tester);
  }

  testWidgets('nothing to fix → no banner', (tester) async {
    await pumpBanner(tester);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('notifications off: primer, then the OS prompt; the banner disappears once granted', (tester) async {
    port.caps = const NotificationCapabilities(platform: 'android');
    await pumpBanner(tester);
    expect(find.text('Notifications are turned off'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await settle(tester);
    expect(find.text('Never miss what matters'), findsOneWidget);
    await tester.tap(find.text('Allow notifications'));
    await settle(tester);

    expect(h.read(notificationCapabilitiesProvider).notifications, isTrue);
    expect(find.text('Notifications are turned off'), findsNothing);
  });

  testWidgets('the primer is never shown twice in a session; the second tap opens the settings', (tester) async {
    port.caps = const NotificationCapabilities(platform: 'android');
    await pumpBanner(tester);
    await tester.tap(find.text('Turn on'));
    await settle(tester);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(h.read(notificationCapabilitiesProvider.notifier).primersShown, contains('notifications'));

    await tester.tap(find.text('Turn on'));
    await settle(tester);
    expect(find.text('Never miss what matters'), findsNothing);
    expect(find.text('Notifications are turned off'), findsOneWidget);
  });

  testWidgets('blocked channel → open settings', (tester) async {
    port.caps = const NotificationCapabilities(
      platform: 'android',
      notifications: true,
      exactAlarm: true,
      blockedChannels: {'dl.planner.standard.v1'},
    );
    await pumpBanner(tester);
    expect(find.text('Some notification categories are blocked'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('exact alarms missing on Android → precise reminders primer', (tester) async {
    port.caps = const NotificationCapabilities(platform: 'android', notifications: true);
    await pumpBanner(tester);
    expect(find.text('Reminders may arrive up to an hour late'), findsOneWidget);

    await tester.tap(find.text('Allow precise reminders'));
    await settle(tester);
    expect(find.text('Precise reminders'), findsOneWidget);
    await tester.tap(find.text('Allow precise reminders').last);
    await settle(tester);
    expect(h.read(notificationCapabilitiesProvider).exactAlarm, isTrue);
    expect(find.text('Reminders may arrive up to an hour late'), findsNothing);
  });

  testWidgets('exact-alarm hint is hidden where the host asks for it', (tester) async {
    port.caps = const NotificationCapabilities(platform: 'android', notifications: true);
    await pumpBanner(tester, showExact: false);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('Arabic: recovery banner and primer', (tester) async {
    port.caps = const NotificationCapabilities(platform: 'android');
    await pumpBanner(tester, locale: const Locale('ar'));
    expect(find.text('الإشعارات متوقفة'), findsOneWidget);
    await tester.tap(find.text('تفعيل'));
    await settle(tester);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
