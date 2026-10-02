import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart' show seedNotificationDefaults;
import 'package:everslot/features/notifications/application/rule_sets.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_set.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/rule_sets_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  final meeting = [
    NotificationRuleSpec(
      trigger: RelativeTrigger(anchor: TriggerAnchor.start, dayOffset: -1, atTime: LocalTime(20, 0)),
    ),
    const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -15)),
    const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: 0)),
  ];

  group('RuleSet file (T7.1.18)', () {
    final set = RuleSet(
      id: 'x',
      name: 'Meeting style',
      targetType: 'task',
      entries: [for (final s in meeting) RuleSetEntry(spec: s, profileCode: 'gentle')],
    );

    test('export → import round-trips (new id)', () {
      final back = RuleSet.parseFile(set.toFile(), id: 'y');
      expect(back, set.copyWith(id: 'y'));
      expect(set.toFile(), contains('"everslot": "rule_set"'));
    });

    test('rejects other files, newer versions, empty or invalid sets', () {
      void bad(String source) => expect(() => RuleSet.parseFile(source, id: 'z'), throwsFormatException);
      bad('not json');
      bad('{"everslot": "checklist", "v": 1, "name": "a", "rules": []}');
      bad(set.toFile().replaceFirst('"v": 1', '"v": 99'));
      bad('{"everslot": "rule_set", "v": 1, "name": "a", "targetType": "task", "rules": []}');
      bad(
        '{"everslot": "rule_set", "v": 1, "name": "", "targetType": "task", "rules": [{"spec": {"v": 1, "trigger": {"type": "overdue"}}}]}',
      );
      bad(
        '{"everslot": "rule_set", "v": 1, "name": "a", "targetType": "task", '
        '"rules": [{"spec": {"v": 1, "trigger": {"type": "warp_drive"}}}]}',
      );
    });
  });

  group('RuleSets service', () {
    Future<void> giveRules(String taskId) => h.read(notificationRulesRepositoryProvider).create([
      for (final s in meeting)
        RuleDraft(targetType: RuleTargetType.task, targetId: taskId, section: NotificationSection.planner, spec: s),
      RuleDraft(
        targetType: RuleTargetType.task,
        targetId: taskId,
        section: NotificationSection.planner,
        spec: const NotificationRuleSpec(
          trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -60),
          conditions: ConditionsSpec(occurrenceKeys: ['2026-09-22T08:00']),
        ),
      ),
    ]);

    test('save an item as a set (occurrence-only reminders left out), apply it to another item', () async {
      await seedNotificationDefaults(h.read);
      await giveRules('a');
      final service = h.read(ruleSetsServiceProvider);
      final set = await service.saveFromTarget(
        name: ' Meeting style ',
        type: NotificationTargetType.task,
        targetId: 'a',
      );
      expect(set!.name, 'Meeting style');
      expect(set.entries.map((e) => e.spec), meeting);
      expect((await service.all()).single, set);

      await service.apply(
        set,
        type: NotificationTargetType.task,
        targetIds: ['b'],
        section: NotificationSection.planner,
      );
      final applied = await h.read(notificationRulesRepositoryProvider).forTarget(RuleTargetType.task, 'b');
      expect(applied.map((r) => r.spec), unorderedEquals(meeting));

      expect(
        await service.saveFromTarget(name: 'Nothing', type: NotificationTargetType.task, targetId: 'none'),
        isNull,
      );
      await service.delete(set.id);
      expect(await service.all(), isEmpty);
    });

    test('import adds a set with a fresh id', () async {
      final service = h.read(ruleSetsServiceProvider);
      final file = RuleSet(
        id: 'old',
        name: 'Imported',
        targetType: 'habit',
        entries: [RuleSetEntry(spec: meeting.last)],
      ).toFile();
      final imported = await service.importFile(file);
      expect(imported.id, isNot('old'));
      expect((await service.all()).single.name, 'Imported');
      expect(() => service.importFile('{}'), throwsFormatException);
    });
  });

  testWidgets('Rule sets screen imports a file and lists it', (tester) async {
    final file = RuleSet(
      id: 'old',
      name: 'Morning habits',
      targetType: 'habit',
      entries: [RuleSetEntry(spec: meeting.last)],
    ).toFile();
    final app = TestHarness.create(
      now: DateTime.utc(2026, 9, 22, 6),
      overrides: [ruleSetFileReaderProvider.overrideWithValue(() async => file)],
    );
    addTearDown(app.dispose);
    await pumpInApp(tester, app, const RuleSetsScreen());
    expect(find.text('Morning habits'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('rule-set-import')));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Morning habits'), findsOneWidget);
    expect(find.text('1 reminder'), findsOneWidget);
  });
}
