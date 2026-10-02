import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart' show seedNotificationDefaults;
import 'package:everslot/features/notifications/application/occurrence_overrides.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/occurrence_reminders_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  const key = '2026-09-22T08:00';
  OccurrenceOverrides overrides() => h.read(occurrenceOverridesProvider);
  Future<List<NotificationRule>> rules() => h.read(notificationRulesRepositoryProvider).all();
  Future<List<NotificationRule>> own() =>
      h.read(notificationRulesRepositoryProvider).forTarget(RuleTargetType.task, 't1');

  group('OccurrenceOverrides (T7.1.16)', () {
    test('an own rule is switched off for one occurrence through its exclusions, and back', () async {
      await h.read(notificationRulesRepositoryProvider).create([
        const RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 't1',
          section: NotificationSection.planner,
          spec: NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -15)),
        ),
      ]);
      final rule = (await own()).single;
      await overrides().switchOff(
        rule: rule,
        type: RuleTargetType.task,
        targetId: 't1',
        section: NotificationSection.planner,
        key: key,
      );
      final excluded = (await own()).single;
      expect(excluded.spec.conditions.excludeOccurrenceKeys, [key]);
      await overrides().restore(rule: excluded, key: key);
      expect((await own()).single.spec.conditions.excludeOccurrenceKeys, isEmpty);
    });

    test('an inherited default is switched off by a disabled occurrence rule; restore deletes it', () async {
      await seedNotificationDefaults(h.read);
      final section = (await rules()).firstWhere(
        (r) => r.section == NotificationSection.planner && r.spec.trigger is RelativeTrigger,
      );
      await overrides().switchOff(
        rule: section,
        type: RuleTargetType.task,
        targetId: 't1',
        section: NotificationSection.planner,
        key: key,
      );
      final off = (await own()).single;
      expect((off.enabled, off.spec.trigger), (false, section.spec.trigger));
      expect(off.spec.conditions.occurrenceKeys, [key]);
      expect((await rules()).firstWhere((r) => r.id == section.id).spec, section.spec, reason: 'defaults untouched');
      await overrides().restore(rule: off, key: key);
      expect(await own(), isEmpty);
    });

    test('added reminders are limited to the occurrence; switching one off deletes it', () async {
      await overrides().add(
        type: RuleTargetType.task,
        targetId: 't1',
        section: NotificationSection.planner,
        key: key,
        spec: const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -60)),
      );
      final added = (await own()).single;
      expect(added.spec.conditions.occurrenceKeys, [key]);
      await overrides().switchOff(
        rule: added,
        type: RuleTargetType.task,
        targetId: 't1',
        section: NotificationSection.planner,
        key: key,
      );
      expect(await own(), isEmpty);
    });
  });

  testWidgets('the sheet lists the occurrence reminders and switches one off for this occurrence', (tester) async {
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    await pumpInApp(
      tester,
      h,
      const Scaffold(
        body: OccurrenceRemindersSheet(
          targetType: NotificationTargetType.task,
          targetId: 't1',
          section: NotificationSection.planner,
          occurrenceKey: key,
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    final on = find.byWidgetPredicate((w) => w is SwitchListTile && w.value);
    expect(on, findsWidgets, reason: 'the section defaults of a timed task');
    final before = tester.widgetList(on).length;
    await tester.tap(on.first);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.widgetList(on).length, before - 1);
    expect(find.text('Off for this occurrence'), findsOneWidget);
    expect(find.byKey(const ValueKey('occ-add')), findsOneWidget);
  });
}
