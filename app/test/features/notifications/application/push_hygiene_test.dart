import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/application/push/push_messaging_port.dart';
import 'package:everslot/features/notifications/application/push/push_service.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// Push token hygiene (T7.4.02) and completion-elsewhere `cancel` pushes (T7.4.10 / T7.4.12).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 22, 12);

  DeviceStateReporter reporter() => DeviceStateReporter(api: () => null, deviceId: 'd', clock: FakeClock(now));

  group('registration hygiene', () {
    Future<({FakePushMessagingPort port, List<DateTime> stamps})> start({
      required bool android,
      DateTime? registeredAt,
    }) async {
      final port = FakePushMessagingPort();
      final stamps = <DateTime>[];
      final service = PushService(
        port: port,
        reporter: reporter(),
        onSync: () {},
        onForegroundReminder: (_) async {},
        onOpened: (_) async {},
        isAndroid: android,
        now: () => now,
        readRegisteredAt: () async => stamps.isNotEmpty ? stamps.last : registeredAt,
        writeRegisteredAt: (at) async => stamps.add(at),
      );
      await service.start(bannerInApp: true);
      await service.dispose();
      return (port: port, stamps: stamps);
    }

    test('first registration is stamped', () async {
      final r = await start(android: true);
      expect(r.port.deleted, isFalse);
      expect(r.stamps, [now]);
    });

    test('Android re-registers after 270 days; recent registrations are kept', () async {
      final stale = await start(android: true, registeredAt: now.subtract(const Duration(days: 300)));
      expect(stale.port.deleted, isTrue);
      expect(stale.stamps, [now]);

      final fresh = await start(android: true, registeredAt: now.subtract(const Duration(days: 100)));
      expect(fresh.port.deleted, isFalse);
      expect(fresh.stamps, isEmpty);
    });

    test('iOS never deletes its registration for age', () async {
      final r = await start(android: false, registeredAt: now.subtract(const Duration(days: 400)));
      expect(r.port.deleted, isFalse);
    });
  });

  test('a cancel message reaches the cancel handler with its dedupe key', () async {
    final port = FakePushMessagingPort();
    final cancelled = <String?>[];
    final service = PushService(
      port: port,
      reporter: reporter(),
      onSync: () {},
      onForegroundReminder: (_) async => fail('not a reminder'),
      onOpened: (_) async {},
      onCancel: (m) async => cancelled.add(m.dedupeKey),
    );
    await service.start(bannerInApp: true);
    port.messages.add(const PushMessage(data: {'type': 'cancel', 'dk': 'abc'}));
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, ['abc']);
    await service.dispose();
  });

  test('cancelDelivered removes the local notification and a push-shown copy', () async {
    final h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
    addTearDown(h.dispose);
    final port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
    final source = InMemoryNotificationTargetSource(
      section: 'planner',
      targets: [
        NotificationTarget(
          type: NotificationTargetType.task,
          id: 'gym',
          section: NotificationSection.planner,
          title: 'Gym',
          occurrenceKey: '2026-09-22T08:00',
          start: DateTime.utc(2026, 9, 22, 8),
          end: DateTime.utc(2026, 9, 22, 9),
          status: 'scheduled',
        ),
      ],
    );
    addTearDown(source.dispose);
    h.read(notificationRegistryProvider).registerSource(source);
    await seedNotificationDefaults(h.read);
    await h.read(notificationPipelineProvider).run('test');
    final entry = (await h.read(localScheduleStoreProvider).all()).firstWhere((e) => e.os);
    await h.read(localSchedulerProvider).cancelDelivered(entry.dedupeKey);
    expect(port.cancelled, containsAll([entry.platformId, 0]));
    expect(port.scheduled.containsKey(entry.platformId), isFalse);
  });
}
