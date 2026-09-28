import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/system_notices.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/diagnostics_screen.dart';
import 'package:everslot/features/notifications/presentation/notification_link_opener.dart';
import 'package:everslot/features/notifications/presentation/notifications_settings_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// System notices in the inbox (T7.3.07).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 22, 12);

  Set<String> active({
    NotificationCapabilities caps = const NotificationCapabilities(
      platform: 'android',
      notifications: true,
      exactAlarm: true,
    ),
    bool saturated = false,
    SyncStatus sync = SyncStatus.localOnly,
  }) => SystemNotices.activeCodes(
    capabilities: caps,
    saturated: saturated,
    sync: sync,
    now: now,
  );

  group('conditions', () {
    test('nothing while capabilities are unknown or everything is fine', () {
      expect(active(caps: NotificationCapabilities.unknown), isEmpty);
      expect(active(), isEmpty);
    });

    test(
      'permission, blocked channels, exact alarms (Android only), saturation',
      () {
        expect(
          active(caps: const NotificationCapabilities(platform: 'android')),
          {SystemNotices.notificationsOff},
        );
        expect(
          active(
            caps: const NotificationCapabilities(
              platform: 'android',
              notifications: true,
              exactAlarm: true,
              blockedChannels: {'dl.planner.standard.v1'},
            ),
          ),
          {SystemNotices.channelBlocked},
        );
        expect(
          active(
            caps: const NotificationCapabilities(
              platform: 'android',
              notifications: true,
            ),
          ),
          {SystemNotices.exactAlarmsOff},
        );
        expect(
          active(
            caps: const NotificationCapabilities(
              platform: 'ios',
              notifications: true,
            ),
            saturated: true,
          ),
          {SystemNotices.budgetSaturated},
        );
      },
    );

    test(
      'sync: revoked device, update required, failing for more than a day',
      () {
        SyncStatus error(String? code, DateTime? lastSuccess) => SyncStatus(
          phase: SyncPhase.error,
          lastError: 'boom',
          errorCode: code,
          lastSuccessAt: lastSuccess,
        );
        expect(active(sync: error(SyncErrorCodes.deviceRevoked, null)), {
          SystemNotices.deviceRevoked,
        });
        expect(active(sync: error(SyncErrorCodes.unsupportedClient, null)), {
          SystemNotices.updateRequired,
        });
        expect(
          active(
            sync: error(
              SyncErrorCodes.unknown,
              now.subtract(const Duration(hours: 25)),
            ),
          ),
          {SystemNotices.syncFailing},
        );
        expect(
          active(
            sync: error(
              SyncErrorCodes.unknown,
              now.subtract(const Duration(hours: 2)),
            ),
          ),
          isEmpty,
        );
        expect(active(sync: error(SyncErrorCodes.unknown, null)), isEmpty);
      },
    );
  });

  group('lifecycle', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: now));
    tearDown(() => h.dispose());

    test('created once, resolved when fixed, re-opened with the same id when it returns', () async {
      final notices = h.read(systemNoticesProvider);
      final inbox = h.read(inboxRepositoryProvider);
      final id = Ids.inbox(
        SystemNotices.dedupeKey(SystemNotices.exactAlarmsOff),
      );

      await notices.apply({SystemNotices.exactAlarmsOff});
      await notices.apply({SystemNotices.exactAlarmsOff});
      var rows = await inbox.inbox();
      expect(rows, hasLength(1));
      expect(rows.single.id, id);
      expect(rows.single.category, InboxCategory.system);
      expect(rows.single.title, 'Reminders may arrive up to an hour late');
      expect(rows.single.deepLink, NotificationLinks.settings);
      expect(rows.single.readAt, isNull);

      // Granted again → resolved (dismissed), not deleted.
      await inbox.markRead([id]);
      await notices.apply(const {});
      expect((await inbox.byId(id))!.dismissedAt, isNotNull);
      expect(await inbox.inbox(), isEmpty);

      // Revoked again later → the same row comes back unread.
      h.clock.advance(const Duration(days: 2));
      await notices.apply({SystemNotices.exactAlarmsOff});
      final back = await inbox.byId(id);
      expect(back!.dismissedAt, isNull);
      expect(back.readAt, isNull);
      expect(back.fireAt, now.add(const Duration(days: 2)));
      expect(await inbox.inbox(), hasLength(1));
    });

    test('every notice has localized content and a fix link', () async {
      final l = h.read(notificationTextsProvider).l10n;
      for (final code in SystemNotices.codes) {
        final (title, body, link) = SystemNotices.content(code, l);
        expect(title, isNotEmpty, reason: code);
        expect(body, isNotEmpty, reason: code);
        expect(link, startsWith('/'), reason: code);
      }
    });
  });

  test('notification links open the module pages; others go to the router', () {
    expect(
      notificationPageFor(NotificationLinks.settings),
      isA<NotificationsSettingsPage>(),
    );
    expect(
      notificationPageFor(NotificationLinks.diagnostics),
      isA<NotificationDiagnosticsScreen>(),
    );
    expect(notificationPageFor('/task/gym'), isNull);
  });
}
