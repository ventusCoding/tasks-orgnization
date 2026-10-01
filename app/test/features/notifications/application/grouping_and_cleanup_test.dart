import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/local_scheduler.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// Grouping & threading (T7.2.19) and delivered-notification cleanup (T7.2.20).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 22, 6);

  NotificationTarget task(String id, {int hour = 8, bool open = true}) {
    final occ = '2026-09-22T0$hour:00';
    return NotificationTarget(
      type: NotificationTargetType.task,
      id: id,
      section: NotificationSection.planner,
      title: id,
      occurrenceKey: occ,
      start: DateTime.utc(2026, 9, 22, hour),
      end: DateTime.utc(2026, 9, 22, hour + 1),
      status: open ? 'scheduled' : 'done',
      isOpen: open,
      guard: NotificationGuard.taskOccurrenceOpen(id, occ),
    );
  }

  for (final platform in ['android', 'ios']) {
    group(platform, () {
      late TestHarness h;
      late InMemoryLocalNotificationsPort port;
      late InMemoryNotificationTargetSource source;

      setUp(() async {
        port = InMemoryLocalNotificationsPort(platform: platform);
        h = TestHarness.create(now: now, overrides: [localNotificationsPortProvider.overrideWithValue(port)]);
        source = InMemoryNotificationTargetSource(
          section: 'planner',
          // Different minutes so nothing is merged: 07:50/08:00, 08:50/09:00 (+ 08:50 nag chain).
          targets: [task('gym'), task('call', hour: 9)],
        );
        h.read(notificationRegistryProvider).registerSource(source);
        await seedNotificationDefaults(h.read);
      });
      tearDown(() async {
        await source.dispose();
        await h.dispose();
      });

      Future<void> replan() => h.read(notificationPipelineProvider).run('test');

      test('threads per section, nag chains per chain; group key per section', () async {
        await h.read(notificationRulesRepositoryProvider).create([
          RuleDraft(
            targetType: RuleTargetType.task,
            targetId: 'call',
            section: NotificationSection.planner,
            profileId: h.read(notificationProfilesRepositoryProvider).builtinId('nag'),
            spec: const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.end, offsetMinutes: 0)),
          ),
        ]);
        source.targets = [task('gym'), task('call', hour: 9).copyWith(notifyMode: NotifyMode.inheritPlus)];
        await replan();
        final requests = port.scheduled.values.toList();
        final plain = requests.where((r) => !r.threadId!.startsWith('nag:')).toList();
        final nags = requests.where((r) => r.threadId!.startsWith('nag:')).toList();
        expect(plain, isNotEmpty);
        expect(plain.map((r) => r.threadId).toSet(), {'sec:planner'});
        expect(nags.length, greaterThanOrEqualTo(2));
        expect(nags.map((r) => r.threadId).toSet(), hasLength(1));
        expect(requests.map((r) => r.groupKey).toSet(), {'dl.group.planner'});
        // Relevance follows importance: the high-importance nag ranks above the defaults.
        expect(nags.first.relevance, greaterThan(plain.first.relevance));
      });

      test('Android summarizes a section once 2+ are in the tray; the summary follows the tray', () async {
        await replan();
        final summaryTag = LocalNotificationScheduler.summaryTag('dl.group.planner');
        // 08:01: gym's two reminders fired.
        h.clock.set(DateTime.utc(2026, 9, 22, 8, 1));
        port.deliverDue(h.clock.nowUtc());
        await replan();
        final summaries = port.shown.where((r) => r.groupSummary).toList();
        if (platform == 'ios') {
          expect(summaries, isEmpty);
          return;
        }
        expect(summaries, hasLength(1));
        expect(summaries.single.tag, summaryTag);
        expect(summaries.single.lines, hasLength(2));
        expect(summaries.single.silent, isTrue);
        expect(summaries.single.title, '2 reminders');

        // Completing gym removes its delivered reminders (T7.2.20) and the summary with them.
        source.targets = [task('gym', open: false), task('call', hour: 9)];
        await replan();
        expect(port.shown.where((r) => r.tag != summaryTag), isEmpty);
        expect(port.shown.where((r) => r.groupSummary), isEmpty);
      });

      test('completing a target removes its delivered notification from the tray', () async {
        await replan();
        h.clock.set(DateTime.utc(2026, 9, 22, 7, 51));
        port.deliverDue(h.clock.nowUtc());
        final delivered = port.shown.single;
        source.targets = [task('gym', open: false), task('call', hour: 9)];
        await replan();
        expect(port.cancelled, contains(delivered.id));
        expect(port.shown.where((r) => r.id == delivered.id), isEmpty);
        // The other target keeps its scheduled reminders.
        expect(port.scheduled.values.map((r) => r.fireAt), contains(DateTime.utc(2026, 9, 22, 8, 50)));
      });

      test('sign-out clears every OS request and the schedule table', () async {
        await replan();
        expect(port.scheduled, isNotEmpty);
        await h.read(localSchedulerProvider).clearAll();
        expect(port.scheduled, isEmpty);
        expect(await h.read(localScheduleStoreProvider).all(), isEmpty);
      });
    });
  }
}
