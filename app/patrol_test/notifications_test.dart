// Notification E2E (T7.2.22): the real plugin, OS scheduler and notification shade on an
// emulator / simulator. Run: `patrol test --flavor dev -t patrol_test/notifications_test.dart
// --dart-define-from-file=env/example.json` (docs/guide.md › End-to-end tests).
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/e2e.dart';

void main() {
  const title = 'E2E reminder';

  /// Creates a 30-min task starting at the current whole minute + [lead] (far enough ahead that the
  /// section default "10 min before" catch-up doesn't swallow "1 min before") with "1 min before" and
  /// "at start" reminders, replans, and returns (task id, occurrence key).
  Future<(String, String)> seedTask(ProviderContainer c, {Duration lead = const Duration(minutes: 4)}) async {
    final zones = c.read(zoneResolverProvider);
    final zone = c.read(deviceZoneProvider);
    final now = c.read(clockProvider).nowUtc();
    final start = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute).add(lead);
    final local = zones.toLocal(start, zone);
    final result = await c.read(plannerServiceProvider).createAt(local, 30, title: title);
    await c.read(notificationRulesRepositoryProvider).create([
      for (final offset in const [-1, 0])
        RuleDraft(
          targetType: RuleTargetType.task,
          targetId: result.taskId,
          section: NotificationSection.planner,
          spec: NotificationRuleSpec(
            trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: offset),
          ),
        ),
    ]);
    // "Custom" in the editor: the task's own reminders replace the section defaults.
    await c.read(notifyModeStoreProvider).set(RuleTargetType.task, result.taskId, NotifyMode.custom);
    await c.read(notificationPipelineProvider).run('e2e');
    final key = '${local.date.toIso()}T${local.time.toIso()}';
    return (result.taskId, key);
  }

  Future<NotificationTarget?> occurrence(ProviderContainer c, String id, String key) async {
    final now = c.read(clockProvider).nowUtc();
    for (final source in c.read(notificationTargetSourcesProvider)) {
      if (source.section != NotificationSection.planner.wire) continue;
      final targets = await source.targetsBetween(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      for (final t in targets) {
        if (t.id == id && t.occurrenceKey == key) return t;
      }
    }
    return null;
  }

  patrolTest(
    'task reminders: "1 min before" and "at start" fire in the background; Done from the shade closes the occurrence',
    config: e2eConfig,
    ($) async {
      final c = await launchEverslot($);
      await grantNotifications($, c);
      final (id, key) = await seedTask(c);

      // The app goes to the background: delivery is the OS scheduler's job now.
      await $.platform.mobile.pressHome();
      await waitForNotifications(
        $,
        (shown) =>
            shown.any((n) => n.title == title && n.content.startsWith('Starts in 1 min')) &&
            shown.any((n) => n.title == title && n.content.startsWith('Starting now')),
      );

      // Action button of the newest (expanded) notification, handled without opening the app.
      await $.platform.mobile.tap(Selector(text: 'Done'));
      await $.platform.mobile.pressHome();

      final deadline = DateTime.now().add(const Duration(seconds: 30));
      NotificationTarget? target;
      while (DateTime.now().isBefore(deadline)) {
        target = await occurrence(c, id, key);
        if (target != null && !target.isOpen) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      expect(target?.status, 'done', reason: 'Done from the notification marks the occurrence done');
    },
  );

  patrolTest('tapping a reminder opens its occurrence', config: e2eConfig, ($) async {
    final c = await launchEverslot($);
    await grantNotifications($, c);
    await seedTask(c, lead: const Duration(minutes: 1));

    await $.platform.mobile.pressHome();
    await waitForNotifications($, (shown) => shown.any((n) => n.title == title));
    await $.platform.mobile.tapOnNotificationBySelector(Selector(textContains: title));
    await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
    expect($(title), findsWidgets, reason: 'the occurrence screen shows the task');
  });
}
