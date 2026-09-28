import 'dart:convert';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/application/rule_preview.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

NotificationTarget gym({
  String occ = '2026-09-22T08:00',
  DateTime? start,
  bool open = true,
}) => NotificationTarget(
  type: NotificationTargetType.task,
  id: 'gym',
  section: NotificationSection.planner,
  title: 'Gym',
  occurrenceKey: occ,
  start: start ?? DateTime.utc(2026, 9, 22, 8),
  end: (start ?? DateTime.utc(2026, 9, 22, 8)).add(const Duration(hours: 1)),
  status: 'scheduled',
  isOpen: open,
  guard: NotificationGuard.taskOccurrenceOpen('gym', occ),
  defaultActions: const ['done', 'snooze', 'skip'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late InMemoryNotificationTargetSource source;
  late InMemoryLocalNotificationsPort port;

  setUp(() async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
    source = InMemoryNotificationTargetSource(
      section: 'planner',
      targets: [gym()],
    );
    h.read(notificationRegistryProvider).registerSource(source);
    port = h.read(
      localNotificationsPortProvider,
    ) as InMemoryLocalNotificationsPort;
    await seedNotificationDefaults(h.read);
  });
  tearDown(() async {
    await source.dispose();
    await h.dispose();
  });

  Future<void> replan() => h.read(notificationPipelineProvider).run('test');

  test('user example: seeded defaults schedule 10 min before and at start; no-change replan is free', () async {
    await replan();
    final scheduled = port.scheduled.values.toList()
      ..sort((a, b) => a.fireAt!.compareTo(b.fireAt!));
    expect(scheduled, hasLength(2));
    expect(scheduled.map((r) => r.fireAt), [
      DateTime.utc(2026, 9, 22, 7, 50),
      DateTime.utc(2026, 9, 22, 8),
    ]);
    expect(scheduled.first.body, contains('10'));
    expect(scheduled.first.channelId, 'dl.planner.standard.v1');
    expect(scheduled.first.actions.map((a) => a.id), [
      'start',
      'snooze',
      'skip',
    ]);
    expect(port.channels.keys, contains('dl.planner.standard.v1'));
    final calls = port.platformCalls;
    await replan();
    expect(
      port.platformCalls,
      calls,
      reason: 'replanning with no changes makes zero platform calls',
    );
  });

  test('completing the occurrence cancels its reminders', () async {
    await replan();
    expect(port.scheduled, hasLength(2));
    source.close('task:gym', '2026-09-22T08:00');
    await replan();
    expect(port.scheduled, isEmpty);
  });

  test('moving the task reschedules its reminders', () async {
    await replan();
    source.targets = [gym(start: DateTime.utc(2026, 9, 22, 10))];
    await replan();
    expect(port.scheduled.values.map((r) => r.fireAt).toSet(), {
      DateTime.utc(2026, 9, 22, 9, 50),
      DateTime.utc(2026, 9, 22, 10),
    });
  });

  test('fired reminders are reconciled into the inbox exactly once', () async {
    await replan();
    h.clock.set(DateTime.utc(2026, 9, 22, 8, 1));
    final reconciled = await h.read(inboxReconcilerProvider).reconcile();
    expect(reconciled, hasLength(2));
    expect(await h.read(inboxReconcilerProvider).reconcile(), isEmpty);
    final inbox = await h.read(inboxRepositoryProvider).inbox();
    expect(inbox, hasLength(2));
    expect(inbox.first.deliveredVia, ['local']);
    expect(inbox.first.sourceType, 'task');
    expect(inbox.first.deepLink, '/task/gym?occ=2026-09-22T08%3A00');
  });

  test('Done from a notification calls the feature handler once, stops the chain and records the action', () async {
    var calls = 0;
    h
        .read(notificationRegistryProvider)
        .registerActionHandler(
          CallbackActionHandler(
            actionIds: {NotificationActionIds.done},
            targetTypes: {NotificationTargetType.task},
            onHandle: (ctx) async {
              calls++;
              expect(ctx.targetId, 'gym');
              expect(ctx.occurrenceKey, '2026-09-22T08:00');
              source.close('task:gym', ctx.occurrenceKey);
              return NotificationActionResult.ok;
            },
          ),
        );
    await replan();
    h.clock.set(DateTime.utc(2026, 9, 22, 7, 51));
    final fired = port.scheduled.values.firstWhere(
      (r) => r.fireAt == DateTime.utc(2026, 9, 22, 7, 50),
    );
    final dispatcher = h.read(notificationActionDispatcherProvider);
    final response = OsResponse(
      id: fired.id,
      actionId: 'done',
      payload: fired.payload,
    );
    await dispatcher.handleResponse(response);
    final second = await dispatcher.handleResponse(response);
    expect(calls, 1);
    expect(second.duplicate, isTrue);
    final key = jsonDecode(fired.payload)['dk'] as String;
    final row = await h.read(inboxRepositoryProvider).byId(Ids.inbox(key));
    expect(row!.action, 'done');
    expect(row.actedAt, isNotNull);
    await replan();
    expect(
      port.scheduled,
      isEmpty,
      reason: 'the at-start reminder disappears once done',
    );
  });

  test(
    'an action without a feature handler opens the target instead',
    () async {
      await replan();
      final fired = port.scheduled.values.first;
      final result = await h
          .read(notificationActionDispatcherProvider)
          .handleResponse(
            // Planner handles done/skip/start/stop for tasks; nothing handles reschedule yet.
            OsResponse(
              id: fired.id,
              actionId: 'reschedule',
              payload: fired.payload,
            ),
          );
      expect(result.openLink, startsWith('/task/gym'));
    },
  );

  test('snooze creates a reserved instance, marks the row snoozed and respects the limit', () async {
    await replan();
    h.clock.set(DateTime.utc(2026, 9, 22, 7, 51));
    final fired = port.scheduled.values.firstWhere(
      (r) => r.fireAt == DateTime.utc(2026, 9, 22, 7, 50),
    );
    final dispatcher = h.read(notificationActionDispatcherProvider);
    final payload = NotificationPayload.tryDecode(fired.payload)!;
    final result = await dispatcher.snooze(payload, minutes: 10);
    expect(result.snoozedUntil, DateTime.utc(2026, 9, 22, 8, 1));
    final snoozes = (await h.read(localScheduleStoreProvider).all()).where(
      (e) => e.kind == ScheduleKind.snooze,
    );
    expect(snoozes, hasLength(1));
    expect(
      port.scheduled.values.where(
        (r) => r.fireAt == DateTime.utc(2026, 9, 22, 8, 1),
      ),
      hasLength(1),
    );
    final row = await h
        .read(inboxRepositoryProvider)
        .byDedupeKey(payload.dedupeKey);
    expect(row!.snoozedUntil, DateTime.utc(2026, 9, 22, 8, 1));
    for (var i = 0; i < 4; i++) {
      await dispatcher.snooze(payload, minutes: 5);
    }
    final limited = await dispatcher.snooze(payload, minutes: 5);
    expect(limited.message, isNotNull, reason: 'max 5 snoozes per instance');
    // Re-snoozing replaces the pending snooze; snooze rows survive replans; wake-now cancels them.
    await replan();
    expect(
      (await h.read(localScheduleStoreProvider).all()).where(
        (e) => e.kind == ScheduleKind.snooze,
      ),
      hasLength(1),
    );
    await dispatcher.wakeNow(payload.dedupeKey);
    expect(
      (await h.read(localScheduleStoreProvider).all()).where(
        (e) => e.kind == ScheduleKind.snooze,
      ),
      isEmpty,
    );
  });

  test('tap marks the row opened, cancels the nag chain and reports "already done" for closed targets', () async {
    final rules = h.read(notificationRulesRepositoryProvider);
    await rules.create([
      RuleDraft(
        targetType: RuleTargetType.task,
        targetId: 'gym',
        section: NotificationSection.planner,
        profileId: h
            .read(notificationProfilesRepositoryProvider)
            .builtinId('nag'),
        spec: const NotificationRuleSpec(
          trigger: RelativeTrigger(anchor: TriggerAnchor.end, offsetMinutes: 0),
        ),
      ),
    ]);
    source.targets = [gym().copyWith(notifyMode: NotifyMode.custom)];
    await replan();
    expect(
      port.scheduled,
      hasLength(6),
      reason: 'nag profile: base + 5 repeats',
    );
    final base = port.scheduled.values.reduce(
      (a, b) => a.fireAt!.isBefore(b.fireAt!) ? a : b,
    );
    h.clock.set(DateTime.utc(2026, 9, 22, 9, 1));
    source.close('task:gym', '2026-09-22T08:00');
    final result = await h
        .read(notificationActionDispatcherProvider)
        .handleResponse(OsResponse(id: base.id, payload: base.payload));
    expect(result.alreadyDone, isTrue);
    expect(
      port.scheduled.values.where((r) => r.fireAt!.isAfter(h.clock.nowUtc())),
      isEmpty,
      reason: 'nag chain cancelled',
    );
    final row = await h
        .read(inboxRepositoryProvider)
        .byDedupeKey(jsonDecode(base.payload)['dk'] as String);
    expect(row!.openedAt, isNotNull);
    expect(row.readAt, isNotNull);
  });

  test('mute action mutes the rule until tomorrow and the planner drops its firings', () async {
    await replan();
    final fired = port.scheduled.values.first;
    final result = await h
        .read(notificationActionDispatcherProvider)
        .handleResponse(
          OsResponse(
            id: fired.id,
            actionId: NotificationActionIds.muteRule,
            payload: fired.payload,
          ),
        );
    expect(result.message, isNotNull);
    final mutes = await h.read(notificationMutesRepositoryProvider).all();
    expect(mutes.single.targetType, 'rule');
    expect(mutes.single.until, DateTime.utc(2026, 9, 23));
    await replan();
    expect(
      port.scheduled,
      hasLength(1),
      reason: 'the other default rule still fires',
    );
  });

  test('preview shows the next firings with reasons; test notification fires in 5 s', () async {
    final preview = h.read(rulePreviewServiceProvider);
    final rules = await h.read(notificationRulesRepositoryProvider).all();
    final entries = await preview.nextFirings(rules, [gym()]);
    expect(entries.map((e) => e.fireAt), [
      DateTime.utc(2026, 9, 22, 7, 50),
      DateTime.utc(2026, 9, 22, 8),
    ]);
    final noise = await preview.noise(rules.first, gym());
    expect(noise.firesPerDay, lessThan(1));
    await preview.sendTest(rules.first, gym());
    expect(
      port.scheduled.values.where(
        (r) => r.fireAt == DateTime.utc(2026, 9, 22, 6, 0, 5),
      ),
      hasLength(1),
    );
  });
}
