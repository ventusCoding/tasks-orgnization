import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// T7.2.10 end to end: plan → scheduler → fake OS port, on both platforms.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const paris = 'Europe/Paris';
  final now = DateTime.utc(2026, 10, 20, 12);
  NotificationTarget water({bool open = true}) => NotificationTarget(
    type: NotificationTargetType.checklistItem,
    id: 'i',
    section: NotificationSection.checklists,
    title: 'Water the plants',
    checklistId: 'L',
    notifyMode: NotifyMode.custom,
    status: open ? 'todo' : 'completed',
    isOpen: open,
    guard: NotificationGuard.itemNotCompleted('i'),
  );

  for (final platform in ['ios', 'android']) {
    group(platform, () {
      late TestHarness h;
      late InMemoryNotificationTargetSource source;
      late InMemoryLocalNotificationsPort port;

      setUp(() async {
        port = InMemoryLocalNotificationsPort(platform: platform);
        h = TestHarness.create(
          now: now,
          zone: paris,
          overrides: [localNotificationsPortProvider.overrideWithValue(port)],
        );
        source = InMemoryNotificationTargetSource(
          section: 'checklists',
          targets: [water()],
        );
        h.read(notificationRegistryProvider).registerSource(source);
        await seedNotificationDefaults(h.read);
        await h.read(notificationRulesRepositoryProvider).create([
          const RuleDraft(
            targetType: RuleTargetType.checklistItem,
            targetId: 'i',
            section: NotificationSection.checklists,
            spec: NotificationRuleSpec(
              trigger: ScheduleTrigger(
                recurrence: {
                  'v': 1,
                  'type': 'fixed',
                  'freq': 'daily',
                  'interval': 1,
                  'times': ['07:00'],
                },
              ),
            ),
          ),
        ]);
      });
      tearDown(() async {
        await source.dispose();
        await h.dispose();
      });

      Future<void> replan() => h.read(notificationPipelineProvider).run('test');

      test(
        'a daily reminder is one repeating OS request; the next day is free',
        () async {
          await replan();
          final requests = port.scheduled.values.toList();
          expect(requests, hasLength(1));
          final r = requests.single;
          expect(r.repeat, RepeatMatch.daily);
          expect(r.repeatZone, paris);
          expect(r.fireAt, DateTime.utc(2026, 10, 21, 5)); // 07:00 Paris (CEST)
          expect(
            NotificationPayload.tryDecode(r.payload)!.kind,
            ScheduleKind.repeating,
          );

          final report = await h
              .read(notificationPipelineProvider)
              .run('again');
          expect(report.scheduler.platformCalls, 0);
          expect(report.scheduler.repeatingRules, hasLength(1));

          h.clock.advance(const Duration(days: 1));
          final nextDay = await h.read(notificationPipelineProvider).run('day');
          expect(nextDay.scheduler.platformCalls, 0);
          expect(port.scheduled, hasLength(1));
        },
      );

      test(
        'a response is mapped to the member instance that fired last',
        () async {
          await replan();
          final r = port.scheduled.values.single;
          h.clock.set(DateTime.utc(2026, 10, 23, 5, 1));
          final member = await h
              .read(notificationActionDispatcherProvider)
              .firedMember(NotificationPayload.tryDecode(r.payload)!);
          expect(member.occurrenceKey, 'sch:2026-10-23T07:00');
          expect(member.dedupeKey, isNot(startsWith('rpt:')));
          expect(member.ruleId, isNotNull);
        },
      );

      test('fired members reach the inbox once, delivered locally', () async {
        await replan();
        h.clock.set(DateTime.utc(2026, 10, 22, 5, 1));
        final reconciled = await h.read(inboxReconcilerProvider).reconcile();
        expect(reconciled, hasLength(2)); // 21 and 22 Oct
        expect(await h.read(inboxReconcilerProvider).reconcile(), isEmpty);
        final inbox = await h.read(inboxRepositoryProvider).inbox();
        expect(inbox, hasLength(2));
        expect(inbox.every((i) => i.deliveredVia.single == 'local'), isTrue);
        expect(inbox.map((i) => i.occurrenceKey).toSet(), {
          'sch:2026-10-21T07:00',
          'sch:2026-10-22T07:00',
        });
      });

      test('completing the item cancels the trigger', () async {
        await replan();
        expect(port.scheduled, hasLength(1));
        source.targets = [water(open: false)];
        await replan();
        expect(port.scheduled, isEmpty);
      });
    });
  }
}
