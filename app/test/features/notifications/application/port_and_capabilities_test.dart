import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/plugin_local_notifications_port.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show AppLifecycleState;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalNotificationsPort contract (in-memory fake, T7.2.01)', () {
    OsNotificationRequest request(int id, {DateTime? at}) =>
        OsNotificationRequest(
          id: id,
          title: 'Gym',
          body: 'Starts in 10 min',
          fireAt: at ?? DateTime.utc(2026, 9, 22, 8),
          channelId: 'dl.planner.standard.v1',
          payload: '{"v":1,"dk":"k$id"}',
          importance: NotificationImportance.normal,
        );

    test(
      'schedule → pending, cancel removes, show → active, cancelAll clears',
      () async {
        final port = InMemoryLocalNotificationsPort();
        await port.schedule(request(1));
        await port.schedule(request(2));
        expect((await port.pending()).map((p) => p.id), [1, 2]);
        await port.cancel(1);
        expect((await port.pending()).map((p) => p.id), [2]);
        await port.show(request(3));
        expect((await port.active()).map((a) => a.id), [3]);
        await port.cancelAll();
        expect(await port.pending(), isEmpty);
        expect(await port.active(), isEmpty);
        expect(port.platformCalls, 5);
      },
    );

    test('responses reach the initialize callback; launch details are returned once set', () async {
      final port = InMemoryLocalNotificationsPort();
      final responses = <OsResponse>[];
      await port.initialize(categories: const [], onResponse: responses.add);
      port.respond(const OsResponse(id: 1, actionId: 'done', payload: '{}'));
      port.respond(const OsResponse(id: 1, payload: '{}'));
      expect(responses.first.isTap, isFalse);
      expect(responses.last.isTap, isTrue);
      expect(await port.launchResponse(), isNull);
      port.launch = const OsResponse(id: 9);
      expect((await port.launchResponse())?.id, 9);
    });

    test('channels are created, updated and deleted (versioned ids)', () async {
      final port = InMemoryLocalNotificationsPort();
      const channel = OsChannel(
        id: 'dl.planner.standard.v1',
        name: 'Plan · Standard',
        groupId: 'dl.group.planner',
        importance: NotificationImportance.normal,
      );
      await port.ensureChannels(const [], const [channel]);
      await port.ensureChannels(
        const [],
        const [],
        delete: {'dl.planner.standard.v1'},
      );
      expect(port.channels, isEmpty);
      expect(port.deletedChannels, {'dl.planner.standard.v1'});
    });

    test(
      'plugin responses map taps, actions, text input and the background flag',
      () {
        final tap = PluginLocalNotificationsPort.mapResponse(
          const fln.NotificationResponse(
            notificationResponseType:
                fln.NotificationResponseType.selectedNotification,
            id: 4,
            payload: 'p',
            actionId: 'ignored',
          ),
        );
        expect(
          (tap.id, tap.isTap, tap.payload, tap.background),
          (4, true, 'p', false),
        );
        final action = PluginLocalNotificationsPort.mapResponse(
          const fln.NotificationResponse(
            notificationResponseType:
                fln.NotificationResponseType.selectedNotificationAction,
            id: 5,
            actionId: 'log_value',
            input: '15',
          ),
          background: true,
        );
        expect(
          (action.actionId, action.input, action.background, action.isTap),
          ('log_value', '15', true, false),
        );
      },
    );
  });

  group('NotificationCapabilitiesController (T7.2.04)', () {
    late InMemoryLocalNotificationsPort port;
    late ProviderContainer container;

    setUp(() {
      port = InMemoryLocalNotificationsPort(
        capabilities: const NotificationCapabilities(platform: 'android'),
      );
      container = ProviderContainer(
        overrides: [localNotificationsPortProvider.overrideWithValue(port)],
      );
    });
    tearDown(() => container.dispose());

    NotificationCapabilities caps() =>
        container.read(notificationCapabilitiesProvider);
    NotificationCapabilitiesController controller() =>
        container.read(notificationCapabilitiesProvider.notifier);

    test('unknown until the first query, then denied → granted → revoked on resume', () async {
      expect(caps().determined, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(caps().determined, isTrue);
      expect(caps().notifications, isFalse);

      // The user denies the OS prompt (shown after a primer).
      port.permissionResult = false;
      expect(await controller().requestNotifications(), isFalse);
      expect(caps().notifications, isFalse);

      // Granted.
      port.permissionResult = true;
      expect(await controller().requestNotifications(), isTrue);
      expect(caps().notifications, isTrue);

      // Exact alarms granted from the system page.
      expect(await controller().requestExactAlarms(), isTrue);
      expect(caps().exactAlarm, isTrue);

      // Revoked in system settings: reflected on the next resume.
      port.caps = port.caps.copyWith(notifications: false, exactAlarm: false);
      container.read(lifecycleProvider)
        ..didChangeAppLifecycleState(AppLifecycleState.paused)
        ..didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect((caps().notifications, caps().exactAlarm), (false, false));
    });

    test('primers are tracked once per session', () async {
      await Future<void>.delayed(Duration.zero);
      expect(controller().primersShown.add('notifications'), isTrue);
      expect(controller().primersShown.add('notifications'), isFalse);
    });
  });
}
