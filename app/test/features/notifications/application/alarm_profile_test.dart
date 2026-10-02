import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/alarm_screen.dart';
import 'package:everslot/features/notifications/presentation/notification_link_opener.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import 'pipeline_and_actions_test.dart' show gym;

/// Alarm profile (T7.2.24): alarm-stream channel, alarm-clock + full-screen scheduling when the
/// user allows it, and the alarm screen opened by a tap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late InMemoryNotificationTargetSource source;
  late InMemoryLocalNotificationsPort port;

  setUp(() async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
    source = InMemoryNotificationTargetSource(section: 'planner', targets: [gym()]);
    h.read(notificationRegistryProvider).registerSource(source);
    port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
    await seedNotificationDefaults(h.read);
    final alarm = (await h.read(notificationProfilesRepositoryProvider).all()).firstWhere(
      (p) => p.code == BuiltinProfiles.alarm,
    );
    await h.read(notificationRulesRepositoryProvider).create([
      RuleDraft(
        targetType: RuleTargetType.section,
        section: NotificationSection.planner,
        isDefault: true,
        profileId: alarm.id,
        spec: const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -5)),
      ),
    ]);
  });
  tearDown(() async {
    await source.dispose();
    await h.dispose();
  });

  Future<OsNotificationRequest> alarmRequest({required bool fullScreen}) async {
    port.caps = port.caps.copyWith(exactAlarm: true, fullScreenIntent: fullScreen);
    await h.read(notificationCapabilitiesProvider.notifier).refresh();
    await h.read(notificationPipelineProvider).run('test');
    return port.scheduled.values.firstWhere((r) => r.fireAt == DateTime.utc(2026, 9, 22, 7, 55));
  }

  test('alarm reminders use the alarm channel, alarm-clock mode and full-screen only when allowed', () async {
    final allowed = await alarmRequest(fullScreen: true);
    expect((allowed.channelId, allowed.alarmClock, allowed.fullScreen), ('dl.planner.alarm.v2', true, true));
    expect(port.channels['dl.planner.alarm.v2']!.alarm, isTrue);
    expect(port.channels['dl.planner.standard.v1']!.alarm, isFalse);
    final denied = await alarmRequest(fullScreen: false);
    expect((denied.alarmClock, denied.fullScreen), (true, false), reason: 'degrades to a heads-up alarm');
  });

  test('a tap on a ringing alarm opens the alarm screen; the inbox opens the item', () async {
    // A real task: the planner source answers the guard for it.
    final task = await h.read(plannerServiceProvider).createAt(LocalDateTime.of(2026, 9, 22, 9), 30, title: 'Swim');
    port.caps = port.caps.copyWith(exactAlarm: true, fullScreenIntent: true);
    await h.read(notificationCapabilitiesProvider.notifier).refresh();
    await h.read(notificationPipelineProvider).run('test');
    final request = port.scheduled.values.firstWhere(
      (r) => r.payload.contains(task.taskId) && r.fireAt == DateTime.utc(2026, 9, 22, 8, 55),
    );
    final dispatcher = h.read(notificationActionDispatcherProvider);
    final tap = await dispatcher.handleResponse(OsResponse(id: request.id, payload: request.payload));
    final uri = Uri.parse(tap.openLink!);
    expect(uri.path, NotificationLinks.alarm);
    final payload = NotificationLinks.alarmPayload(uri)!;
    expect((payload.alarm, payload.targetId, payload.title), (true, task.taskId, 'Swim'));
    expect(notificationPageFor(tap.openLink!), isA<AlarmScreen>());
    final fromInbox = await dispatcher.handleTap(payload, origin: ActionOrigin.inbox);
    expect(fromInbox.openLink, startsWith('/task/${task.taskId}'));
  });

  testWidgets('the alarm screen snoozes (first preset) through the dispatcher', (tester) async {
    final request = await tester.runAsync(() => alarmRequest(fullScreen: true));
    final payload = NotificationPayload.tryDecode(request!.payload)!;
    await pumpInApp(tester, h, AlarmScreen(payload: payload));
    expect(find.text('Gym'), findsOneWidget);
    expect(find.byKey(const ValueKey('alarm-done')), findsOneWidget);
    final before = port.scheduled.length;
    await tester.tap(find.byKey(const ValueKey('alarm-snooze')));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(port.scheduled.length, greaterThanOrEqualTo(before), reason: 'the snooze is scheduled');
    expect(port.scheduled.values.any((r) => r.fireAt == h.clock.nowUtc().add(const Duration(minutes: 5))), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
