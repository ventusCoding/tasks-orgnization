import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/defaults_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// Section & category default-rule editors (T7.1.14).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  String defaultId(String section, String code) => Ids.v5('user-1|default-rule|$section|$code');

  testWidgets('planner tab lists timed / all-day / date-only defaults with their impact', (tester) async {
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    await pumpInApp(tester, h, const NotificationDefaultsScreen());
    await settle(tester);
    for (final header in ['Timed items', 'All-day items', 'Date-only items']) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
    expect(find.textContaining('10 min before'), findsOneWidget);
    expect(find.textContaining('Affects 0 items'), findsOneWidget);
  });

  testWidgets('swiping a default deletes it with undo', (tester) async {
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    await pumpInApp(tester, h, const NotificationDefaultsScreen());
    await settle(tester);
    await tester.drag(
      find.ancestor(of: find.textContaining('10 min before'), matching: find.byType(Dismissible)),
      const Offset(-600, 0),
    );
    await settle(tester);
    expect(find.textContaining('10 min before'), findsNothing);
    final deleted = await tester.runAsync(
      () => h.read(notificationRulesRepositoryProvider).byId(defaultId('planner', 'timed_before_10')),
    );
    expect(deleted, isNull);
    expect(find.byType(SnackBar), findsOneWidget);
    // Let the snackbar go away before the tree is torn down.
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);
  });

  test('editing a default replans inheriting items only', () async {
    final port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
    NotificationTarget task(String id, NotifyMode mode) => NotificationTarget(
      type: NotificationTargetType.task,
      id: id,
      section: NotificationSection.planner,
      title: id,
      occurrenceKey: '2026-09-22T08:00',
      notifyMode: mode,
      start: DateTime.utc(2026, 9, 22, 8),
      end: DateTime.utc(2026, 9, 22, 9),
      status: 'scheduled',
    );
    final source = InMemoryNotificationTargetSource(
      section: 'planner',
      targets: [task('inheriting', NotifyMode.inherit), task('own', NotifyMode.custom)],
    );
    addTearDown(source.dispose);
    h.read(notificationRegistryProvider).registerSource(source);
    await seedNotificationDefaults(h.read);
    final rules = h.read(notificationRulesRepositoryProvider);
    await rules.create([
      const RuleDraft(
        targetType: RuleTargetType.task,
        targetId: 'own',
        section: NotificationSection.planner,
        spec: NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -5)),
      ),
    ]);
    Map<String, List<DateTime>> fires() {
      final byTask = <String, List<DateTime>>{};
      for (final p in h.read(notificationPipelineProvider).lastPlan!.planned) {
        (byTask[p.targetId] ??= []).add(p.fireAt);
      }
      return {for (final e in byTask.entries) e.key: e.value..sort()};
    }

    await h.read(notificationPipelineProvider).run('before');
    expect(fires()['inheriting'], [DateTime.utc(2026, 9, 22, 7, 50), DateTime.utc(2026, 9, 22, 8)]);
    expect(fires()['own'], [DateTime.utc(2026, 9, 22, 7, 55)]);

    // "10 min before" → "30 min before" in the section defaults.
    await rules.update(
      defaultId('planner', 'timed_before_10'),
      spec: const NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -30),
        conditions: ConditionsSpec(itemKind: 'timed'),
      ),
    );
    await h.read(notificationPipelineProvider).run('after');
    expect(fires()['inheriting'], [DateTime.utc(2026, 9, 22, 7, 30), DateTime.utc(2026, 9, 22, 8)]);
    expect(fires()['own'], [DateTime.utc(2026, 9, 22, 7, 55)]);
    expect(
      port.scheduled.values.map((r) => r.fireAt),
      containsAll([DateTime.utc(2026, 9, 22, 7, 30), DateTime.utc(2026, 9, 22, 7, 55)]),
    );
  });
}
