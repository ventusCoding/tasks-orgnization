import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/badge_count.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../../support/test_app.dart';

/// App-icon badge policy (T7.3.06).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final zones = TzZoneResolver();
  // Tuesday 22 Sep 2026, 12:00 UTC = 14:00 in Paris.
  final now = DateTime.utc(2026, 9, 22, 12);

  NotificationTarget task(String id, DateTime start, {bool open = true}) => NotificationTarget(
    type: NotificationTargetType.task,
    id: id,
    section: NotificationSection.planner,
    title: id,
    occurrenceKey: start.toIso8601String(),
    start: start,
    end: start.add(const Duration(hours: 1)),
    isOpen: open,
  );

  final targets = [
    task('overdue', DateTime.utc(2026, 9, 22, 7)), // ended 08:00 UTC
    task('later-today', DateTime.utc(2026, 9, 22, 18)),
    task('tomorrow', DateTime.utc(2026, 9, 23, 18)),
    task('done-today', DateTime.utc(2026, 9, 22, 16), open: false),
    task('yesterday-missed', DateTime.utc(2026, 9, 21, 9)),
    NotificationTarget(
      type: NotificationTargetType.checklistItem,
      id: 'item',
      section: NotificationSection.checklists,
      title: 'item',
      due: DateTime.utc(2026, 9, 22, 20),
    ),
    NotificationTarget(
      type: NotificationTargetType.habit,
      id: 'habit',
      section: NotificationSection.habits,
      title: 'habit',
      occurrenceKey: '2026-09-22',
      periodStart: DateTime.utc(2026, 9, 21, 22),
      periodEnd: DateTime.utc(2026, 9, 22, 22),
    ),
    NotificationTarget(
      type: NotificationTargetType.habit,
      id: 'habit',
      section: NotificationSection.habits,
      title: 'habit',
      occurrenceKey: '2026-09-21',
      periodStart: DateTime.utc(2026, 9, 20, 22),
      periodEnd: DateTime.utc(2026, 9, 21, 22),
    ),
    NotificationTarget(
      type: NotificationTargetType.habit,
      id: 'quit',
      section: NotificationSection.quit,
      title: 'quit',
      periodStart: DateTime.utc(2026, 9, 21, 22),
      periodEnd: DateTime.utc(2026, 9, 22, 22),
    ),
  ];

  int count(String policy, {int unread = 7}) =>
      BadgeCount.compute(policy, unread: unread, targets: targets, now: now, zone: 'Europe/Paris', zones: zones);

  test('off shows nothing; unread mirrors the inbox', () {
    expect(count(BadgePolicy.off), 0);
    expect(count(BadgePolicy.unread), 7);
    expect(count(BadgePolicy.unread, unread: 0), 0);
  });

  test('overdue + due today: open items only, current habit periods, no quit/tomorrow', () {
    // overdue, later-today, yesterday-missed (overdue), item due tonight, today's habit period.
    expect(count(BadgePolicy.due), 5);
  });

  group('pipeline applies the policy after every replan', () {
    late TestHarness h;
    late InMemoryLocalNotificationsPort port;
    late InMemoryNotificationTargetSource source;
    setUp(() async {
      h = TestHarness.create(now: now, zone: 'Europe/Paris');
      port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
      source = InMemoryNotificationTargetSource(section: 'planner', targets: targets.take(4).toList());
      h.read(notificationRegistryProvider).registerSource(source);
      await seedNotificationDefaults(h.read);
    });
    tearDown(() async {
      await source.dispose();
      await h.dispose();
    });

    test('due policy counts open targets; unread follows the inbox; off clears it', () async {
      await h.read(settingsRepositoryProvider).update(SettingsNs.notifications, {'badgePolicy': 'due'});
      await h.read(notificationPipelineProvider).run('due');
      expect(port.badge, 2); // overdue + later-today

      await h.read(settingsRepositoryProvider).update(SettingsNs.notifications, {'badgePolicy': 'unread'});
      await h
          .read(inboxRepositoryProvider)
          .upsertDelivered(InboxDelivery(dedupeKey: 'a', category: InboxCategory.reminder, title: 'A', fireAt: now));
      await h.read(notificationPipelineProvider).run('unread');
      expect(port.badge, 1);

      await h.read(settingsRepositoryProvider).update(SettingsNs.notifications, {'badgePolicy': 'off'});
      await h.read(notificationPipelineProvider).run('off');
      expect(port.badge, 0);
      expect(h.read(notificationPipelineProvider).lastBadge, 0);
    });
  });
}
