import 'package:everslot/features/notifications/domain/delivery_resolution.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationRule rule(
  String id, {
  RuleTargetType type = RuleTargetType.section,
  String? targetId,
  NotificationSection section = NotificationSection.planner,
  bool isDefault = true,
  bool enabled = true,
  NotificationTrigger trigger = const RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -10),
  ConditionsSpec conditions = ConditionsSpec.empty,
  AppliesTo? appliesTo,
  String? profileId,
  DeliverySpec delivery = DeliverySpec.empty,
}) => NotificationRule(
  id: id,
  targetType: type,
  targetId: targetId,
  section: section,
  isDefault: isDefault,
  enabled: enabled,
  profileId: profileId,
  spec: NotificationRuleSpec(trigger: trigger, conditions: conditions, appliesTo: appliesTo, delivery: delivery),
);

NotificationTarget task({
  NotifyMode mode = NotifyMode.inherit,
  String? categoryId,
  ItemKind kind = ItemKind.timed,
  String? occ,
}) => NotificationTarget(
  type: NotificationTargetType.task,
  id: 't1',
  section: NotificationSection.planner,
  title: 'Gym',
  notifyMode: mode,
  categoryId: categoryId,
  itemKind: kind,
  occurrenceKey: occ,
);

void main() {
  group('EffectiveRulesResolver', () {
    final defaults = [
      rule('sec-before', conditions: const ConditionsSpec(itemKind: 'timed')),
      rule('sec-start', trigger: const RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: 0)),
      rule(
        'sec-allday',
        trigger: const RelativeTrigger(anchor: TriggerAnchor.end),
        conditions: const ConditionsSpec(itemKind: 'all_day'),
      ),
      rule('own', type: RuleTargetType.task, targetId: 't1', isDefault: false, trigger: const OverdueTrigger()),
      rule(
        'cat-work',
        type: RuleTargetType.category,
        targetId: 'work',
        trigger: const RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -15),
      ),
    ];
    List<String> ids(
      NotificationTarget t, {
      List<NotificationRule>? rules,
      NotificationSettings settings = NotificationSettings.defaults,
    }) => [for (final e in EffectiveRulesResolver(RuleIndex(rules ?? defaults), settings).forTarget(t)) e.rule.id];

    test('inherit = defaults matching the item kind', () => expect(ids(task()), ['sec-before', 'sec-start']));
    test('custom = own only', () => expect(ids(task(mode: NotifyMode.custom)), ['own']));
    test(
      'inherit_plus = defaults + own',
      () => expect(ids(task(mode: NotifyMode.inheritPlus)), ['sec-before', 'sec-start', 'own']),
    );
    test('off = nothing', () => expect(ids(task(mode: NotifyMode.off)), isEmpty));
    test(
      'all-day items get all-day defaults',
      () => expect(ids(task(kind: ItemKind.allDay)), ['sec-start', 'sec-allday']),
    );
    test('category default replaces section defaults of the same trigger kind', () {
      expect(ids(task(categoryId: 'work')), ['cat-work']);
      expect(ids(task(categoryId: 'home')), ['sec-before', 'sec-start']);
    });
    test('disabled section yields nothing', () {
      const settings = NotificationSettings(
        perSection: {NotificationSection.planner: SectionNotificationSettings(enabled: false)},
      );
      expect(ids(task(), settings: settings), isEmpty);
    });
    test('disabled rules are filtered', () {
      expect(
        ids(
          task(),
          rules: [
            rule('a', enabled: false),
            rule('b', trigger: const OverdueTrigger()),
          ],
        ),
        ['b'],
      );
    });
    test('occurrence keys limit rules to one occurrence; exclusions drop it', () {
      final rules = [
        rule(
          'occ',
          type: RuleTargetType.task,
          targetId: 't1',
          isDefault: false,
          conditions: const ConditionsSpec(occurrenceKeys: ['2026-09-22T08:00']),
        ),
        rule(
          'excl',
          type: RuleTargetType.task,
          targetId: 't1',
          isDefault: false,
          trigger: const OverdueTrigger(),
          conditions: const ConditionsSpec(excludeOccurrenceKeys: ['2026-09-22T08:00']),
        ),
      ];
      expect(
        ids(
          task(mode: NotifyMode.custom, occ: '2026-09-22T08:00'),
          rules: rules,
        ),
        ['occ'],
      );
      expect(
        ids(
          task(mode: NotifyMode.custom, occ: '2026-09-23T08:00'),
          rules: rules,
        ),
        ['excl'],
      );
    });
    test('checklist items inherit checklist rules scoped to items and nearest ancestor rules', () {
      final rules = [
        rule(
          'list',
          type: RuleTargetType.checklist,
          targetId: 'L',
          isDefault: false,
          section: NotificationSection.checklists,
          trigger: const RelativeTrigger(anchor: TriggerAnchor.due),
          appliesTo: AppliesTo.items,
        ),
        rule(
          'parent',
          type: RuleTargetType.checklistItem,
          targetId: 'P',
          isDefault: false,
          section: NotificationSection.checklists,
          trigger: const RelativeTrigger(anchor: TriggerAnchor.due, offsetMinutes: -60),
          appliesTo: AppliesTo.descendants,
        ),
        rule(
          'grand',
          type: RuleTargetType.checklistItem,
          targetId: 'G',
          isDefault: false,
          section: NotificationSection.checklists,
          trigger: const StaleTrigger(afterDays: 3),
          appliesTo: AppliesTo.descendants,
        ),
        rule(
          'list-self',
          type: RuleTargetType.checklist,
          targetId: 'L',
          isDefault: false,
          section: NotificationSection.checklists,
          trigger: const StaleTrigger(afterDays: 9),
        ),
      ];
      const item = NotificationTarget(
        type: NotificationTargetType.checklistItem,
        id: 'I',
        section: NotificationSection.checklists,
        title: 'Buy milk',
        checklistId: 'L',
        ancestorItemIds: ['P', 'G'],
      );
      final resolved = EffectiveRulesResolver(RuleIndex(rules), NotificationSettings.defaults).forTarget(item);
      expect([for (final e in resolved) e.rule.id], ['parent', 'grand']);
      expect(resolved.first.provenance, RuleProvenance.ancestor);
    });
    test('digest rules are standalone (never inherited)', () {
      final rules = [
        rule(
          'dg',
          trigger: const DigestTrigger(kind: 'daily_agenda', schedule: {}),
        ),
      ];
      expect(ids(task(), rules: rules), isEmpty);
      expect(RuleIndex(rules).standalone.single.id, 'dg');
    });
  });

  group('resolveDelivery (absent / set / disable × profile chain)', () {
    NotificationProfile profile(String code) =>
        NotificationProfile(id: code, code: code, name: code, isBuiltin: true, spec: BuiltinProfiles.specs[code]!);

    test('standard fallback when nothing is set', () {
      final d = resolveDelivery(spec: const NotificationRuleSpec(trigger: OverdueTrigger()));
      expect(d.sound, 'default');
      expect(d.importance, NotificationImportance.normal);
      expect(d.actions, ['done', 'snooze', 'skip']);
      expect(d.repeat, isNull);
      expect(d.respectQuietHours, isTrue);
      expect(d.profileCode, 'standard');
    });
    test('sound none over Standard is silent; removing the field restores the profile sound', () {
      final standard = profile(BuiltinProfiles.standard);
      final silent = resolveDelivery(
        spec: const NotificationRuleSpec(
          trigger: OverdueTrigger(),
          delivery: DeliverySpec(sound: 'none'),
        ),
        ruleProfile: standard,
      );
      expect(silent.sound, 'none');
      expect(silent.silent, isTrue);
      final restored = resolveDelivery(
        spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
        ruleProfile: standard,
      );
      expect(restored.sound, 'default');
    });
    test('gentle profile: low importance, passive, no sound', () {
      final d = resolveDelivery(
        spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
        ruleProfile: profile('gentle'),
      );
      expect(d.importance, NotificationImportance.low);
      expect(d.interruptionLevel, InterruptionLevel.passive);
      expect(d.sound, 'none');
      expect(d.profileCode, 'gentle');
    });
    test('nag profile repeats every 5 min ×5; repeat:false on the rule disables it', () {
      final nag = profile('nag');
      expect(
        resolveDelivery(
          spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
          ruleProfile: nag,
        ).repeat!.everyMinutes,
        5,
      );
      expect(
        resolveDelivery(
          spec: const NotificationRuleSpec(trigger: OverdueTrigger(), repeatDisabled: true),
          ruleProfile: nag,
        ).repeat,
        isNull,
      );
    });
    test('empty actions list disables actions; section default profile sits below the rule profile', () {
      final d = resolveDelivery(
        spec: const NotificationRuleSpec(
          trigger: OverdueTrigger(),
          delivery: DeliverySpec(actions: []),
        ),
        sectionDefault: profile('gentle'),
      );
      expect(d.actions, isEmpty);
      expect(d.importance, NotificationImportance.low);
      final ruleWins = resolveDelivery(
        spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
        ruleProfile: profile('nag'),
        sectionDefault: profile('gentle'),
      );
      expect(ruleWins.importance, NotificationImportance.high);
    });
    test('target default actions apply when no profile sets actions', () {
      final d = resolveDelivery(
        spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
        targetDefaultActions: ['log_value'],
      );
      expect(d.actions, ['log_value']);
    });
    test('alarm profile bypasses quiet hours', () {
      expect(
        resolveDelivery(
          spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
          ruleProfile: profile('alarm'),
        ).respectQuietHours,
        isFalse,
      );
    });
    test('importance → interruption level mapping', () {
      expect(interruptionLevelFor(NotificationImportance.min, timeSensitiveAllowed: true), InterruptionLevel.passive);
      expect(interruptionLevelFor(NotificationImportance.normal, timeSensitiveAllowed: true), InterruptionLevel.active);
      expect(
        interruptionLevelFor(NotificationImportance.urgent, timeSensitiveAllowed: true),
        InterruptionLevel.timeSensitive,
      );
      expect(interruptionLevelFor(NotificationImportance.high, timeSensitiveAllowed: false), InterruptionLevel.active);
      expect(
        effectiveInterruptionLevel(InterruptionLevel.timeSensitive, timeSensitiveAllowed: false),
        InterruptionLevel.active,
      );
    });
  });
}
