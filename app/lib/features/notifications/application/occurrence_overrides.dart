import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "For this occurrence only" (T7.1.16): reminders added to, or switched off for, one occurrence
/// of an item. Stored as the item's own rules limited by `conditions.occurrenceKeys`, so they keep
/// applying while the occurrence key survives series edits; switching off one of the item's own
/// rules adds the key to its `excludeOccurrenceKeys`, switching off an inherited one stores a
/// disabled occurrence rule with the same trigger (the resolver drops the identical reminder).
class OccurrenceOverrides {
  OccurrenceOverrides(this._rules);

  final NotificationRulesRepository _rules;

  /// Adds [spec] for occurrence [key] of the item only.
  Future<void> add({
    required RuleTargetType type,
    required String targetId,
    required NotificationSection section,
    required String key,
    required NotificationRuleSpec spec,
    String? profileId,
  }) => _rules.create([
    RuleDraft(
      targetType: type,
      targetId: targetId,
      section: section,
      spec: spec.copyWith(conditions: spec.conditions.copyWith(occurrenceKeys: [key])),
      profileId: profileId,
    ),
  ]);

  /// Switches the effective reminder [rule] off for occurrence [key].
  Future<void> switchOff({
    required NotificationRule rule,
    required RuleTargetType type,
    required String targetId,
    required NotificationSection section,
    required String key,
  }) async {
    if (EffectiveRulesResolver.isOccurrenceScoped(rule)) {
      await _rules.delete(rule.id); // an occurrence-only reminder: just remove it
    } else if (rule.targetType == type && rule.targetId == targetId) {
      final c = rule.spec.conditions;
      await _rules.update(
        rule.id,
        spec: rule.spec.copyWith(
          conditions: c.copyWith(excludeOccurrenceKeys: {...?c.excludeOccurrenceKeys, key}.toList()),
        ),
      );
    } else {
      await _rules.create([
        RuleDraft(
          targetType: type,
          targetId: targetId,
          section: section,
          enabled: false,
          spec: NotificationRuleSpec(
            trigger: rule.spec.trigger,
            conditions: ConditionsSpec(occurrenceKeys: [key]),
          ),
        ),
      ]);
    }
  }

  /// Undoes [switchOff] for occurrence [key]: drops the key from an own rule's exclusions, or
  /// deletes the disabled occurrence rule.
  Future<void> restore({required NotificationRule rule, required String key}) async {
    if (EffectiveRulesResolver.isOccurrenceScoped(rule) && !rule.enabled) {
      await _rules.delete(rule.id);
      return;
    }
    final c = rule.spec.conditions;
    final excluded = c.excludeOccurrenceKeys;
    if (excluded == null || !excluded.contains(key)) return;
    await _rules.update(
      rule.id,
      spec: rule.spec.copyWith(
        conditions: c.copyWith(
          excludeOccurrenceKeys: [
            for (final k in excluded)
              if (k != key) k,
          ],
        ),
      ),
    );
  }
}

final occurrenceOverridesProvider = Provider<OccurrenceOverrides>(
  (ref) => OccurrenceOverrides(ref.watch(notificationRulesRepositoryProvider)),
);
