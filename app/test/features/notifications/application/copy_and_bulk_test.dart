import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// *Customize* snapshot, *Copy reminders from…* and bulk *Set reminders* (T7.1.15).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
  tearDown(() => h.dispose());

  Future<void> insertTask(String id, {String mode = 'inherit'}) => h
      .read(syncWriterProvider)
      .run((tx) => tx.insert('tasks', id, {'series_id': id, 'title': id, 'notify_mode': mode}));

  Future<String?> modeOf(String id) async =>
      (await (h.db.select(h.db.tasks)..where((t) => t.id.equals(id))).getSingle()).notifyMode;

  const thirtyBefore = NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -30));

  test('bulk Set reminders: own rules + Custom mode on every item, one undoable command', () async {
    await insertTask('a');
    await insertTask('b');
    await insertTask('c', mode: 'custom');
    final rules = h.read(notificationRulesRepositoryProvider);
    await rules.create([
      const RuleDraft(
        targetType: RuleTargetType.task,
        targetId: 'c',
        section: NotificationSection.planner,
        spec: NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: 0)),
      ),
    ]);
    final host = h.read(notificationHostApiProvider);
    final record = await host.setReminders(
      NotificationTargetType.task,
      ['a', 'b', 'c'],
      [
        const NotificationRule(
          id: 'template',
          targetType: RuleTargetType.task,
          targetId: 'x',
          section: NotificationSection.planner,
          spec: thirtyBefore,
        ),
      ],
    );
    for (final id in ['a', 'b', 'c']) {
      final own = await host.rulesOf(NotificationTargetType.task, id);
      expect(own, hasLength(1), reason: id); // replace: c's old rule is gone
      expect((own.single.spec.trigger as RelativeTrigger).offsetMinutes, -30);
      expect(await modeOf(id), 'custom', reason: id);
    }

    await h.read(syncWriterProvider).revert(record);
    expect(await host.rulesOf(NotificationTargetType.task, 'a'), isEmpty);
    expect(await modeOf('a'), 'inherit');
    expect(await host.rulesOf(NotificationTargetType.task, 'c'), hasLength(1));
    expect(await modeOf('c'), 'custom');
  });

  test('a Customize snapshot no longer follows the defaults', () async {
    await seedNotificationDefaults(h.read);
    await insertTask('t');
    final rules = h.read(notificationRulesRepositoryProvider);
    final defaults = [
      for (final r in await rules.all())
        if (r.isDefault && r.section == NotificationSection.planner) r,
    ];
    await rules.snapshot(
      type: RuleTargetType.task,
      targetId: 't',
      inherited: [for (final r in defaults) EffectiveRule(r, RuleProvenance.section)],
      setNotifyMode: (tx) => h.read(notifyModeStoreProvider).setInTx(tx, RuleTargetType.task, 't', NotifyMode.custom),
    );
    final before = [for (final r in await rules.forTarget(RuleTargetType.task, 't')) r.spec.encode()]..sort();
    // Change a default: the snapshot keeps its copy.
    await rules.update(
      Ids.v5('user-1|default-rule|planner|timed_before_10'),
      spec: const NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -45),
        conditions: ConditionsSpec(itemKind: 'timed'),
      ),
    );
    final after = [for (final r in await rules.forTarget(RuleTargetType.task, 't')) r.spec.encode()]..sort();
    expect(after, before);
    expect(await modeOf('t'), 'custom');
  });

  testWidgets('Copy reminders from… copies another item’s reminders with undo', (tester) async {
    await tester.runAsync(() async {
      await seedNotificationDefaults(h.read);
      await insertTask('src', mode: 'custom');
      await insertTask('dst');
      await h.read(notificationRulesRepositoryProvider).create([
        const RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 'src',
          section: NotificationSection.planner,
          spec: thirtyBefore,
        ),
      ]);
    });
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: ListView(
          children: [
            NotificationSettingsSection(
              targetType: NotificationTargetType.task,
              targetId: 'dst',
              section: NotificationSection.planner,
              pickCopySource: (_) async => 'src',
            ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('Copy reminders from…'));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('1 reminder copied'), findsOneWidget);
    final copied = await tester.runAsync(
      () => h.read(notificationHostApiProvider).rulesOf(NotificationTargetType.task, 'dst'),
    );
    expect(copied, hasLength(1));
    expect(await tester.runAsync(() => modeOf('dst')), 'custom');
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
