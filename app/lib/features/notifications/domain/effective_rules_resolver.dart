import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:meta/meta.dart';

/// A rule applying to a target, with where it comes from (for the editor UI).
@immutable
class EffectiveRule {
  const EffectiveRule(this.rule, this.provenance, {this.sourceId});

  final NotificationRule rule;
  final RuleProvenance provenance;

  /// Category / ancestor / checklist id the rule was inherited from.
  final String? sourceId;

  bool get inherited => provenance != RuleProvenance.own && provenance != RuleProvenance.occurrence;

  @override
  bool operator ==(Object other) =>
      other is EffectiveRule && other.rule == rule && other.provenance == provenance && other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(rule, provenance, sourceId);

  @override
  String toString() => 'EffectiveRule(${rule.id}, $provenance)';
}

/// Rules indexed for fast per-target resolution.
class RuleIndex {
  RuleIndex(Iterable<NotificationRule> rules) {
    for (final r in rules) {
      if (r.isStandalone) {
        standalone.add(r);
        continue;
      }
      switch (r.targetType) {
        case RuleTargetType.global:
          global.add(r);
        case RuleTargetType.section:
          (bySection[r.section] ??= []).add(r);
        case RuleTargetType.category:
          if (r.targetId != null) (byCategory[r.targetId!] ??= []).add(r);
        case RuleTargetType.task || RuleTargetType.checklist || RuleTargetType.checklistItem || RuleTargetType.habit:
          if (r.targetId != null) (byOwner['${r.targetType.wire}:${r.targetId}'] ??= []).add(r);
      }
    }
  }

  final List<NotificationRule> global = [];
  final Map<NotificationSection, List<NotificationRule>> bySection = {};
  final Map<String, List<NotificationRule>> byCategory = {};
  final Map<String, List<NotificationRule>> byOwner = {};

  /// Digest rules (planned once against synthetic targets, never inherited).
  final List<NotificationRule> standalone = [];

  List<NotificationRule> owned(RuleTargetType type, String id) => byOwner['${type.wire}:$id'] ?? const [];
}

/// `EffectiveRulesResolver.forTarget(target)` (T7.1.06).
///
/// Precedence (most specific first): occurrence → item → ancestor items (nearest first) →
/// checklist (`scope.appliesTo` items/descendants) → category → section (per item kind) → global.
/// Defaults of a more specific level replace less specific defaults **of the same trigger kind**;
/// different trigger kinds accumulate. `notify_mode`: inherit = defaults, custom = own,
/// inherit_plus = both, off = none. Disabled sections and disabled rules are filtered; mutes are
/// time-dependent and applied by the planner.
class EffectiveRulesResolver {
  EffectiveRulesResolver(this.index, this.settings);

  final RuleIndex index;
  final NotificationSettings settings;

  List<EffectiveRule> forTarget(NotificationTarget target) {
    if (target.notifyMode == NotifyMode.off) return const [];
    if (!settings.sectionEnabled(target.section)) return const [];
    final result = <EffectiveRule>[];
    if (target.notifyMode.usesDefaults) result.addAll(_defaults(target));
    if (target.notifyMode.usesOwn) result.addAll(_own(target));
    return [
      for (final e in result)
        if (e.rule.enabled && _matchesKind(e.rule, target) && _matchesOccurrence(e.rule, target)) e,
    ];
  }

  /// Enabled rules a target inherits whatever its `notify_mode` (the editor shows them greyed and
  /// *Customize* copies them). Disabled defaults are left out: they never fire.
  List<EffectiveRule> inheritedFor(NotificationTarget target) =>
      [for (final e in _defaults(target)) if (e.rule.enabled && _matchesKind(e.rule, target)) e];

  Iterable<EffectiveRule> _own(NotificationTarget target) sync* {
    final type = RuleTargetType.forTarget(target.type);
    if (type == null) return;
    for (final r in index.owned(type, target.id)) {
      final applies = r.spec.appliesTo;
      if (applies == AppliesTo.items || applies == AppliesTo.descendants) continue;
      yield EffectiveRule(
        r,
        r.spec.conditions.occurrenceKeys?.isNotEmpty == true ? RuleProvenance.occurrence : RuleProvenance.own,
      );
    }
  }

  List<EffectiveRule> _defaults(NotificationTarget target) {
    final levels = <List<EffectiveRule>>[];
    // Ancestor items (nearest first): rules scoped to descendants.
    for (final ancestor in target.ancestors) {
      levels.add([
        for (final r in index.owned(RuleTargetType.checklistItem, ancestor))
          if (r.spec.appliesTo == AppliesTo.descendants || r.spec.appliesTo == AppliesTo.selfAndDescendants)
            EffectiveRule(r, RuleProvenance.ancestor, sourceId: ancestor),
      ]);
    }
    // Checklist-level rules covering its items.
    if (target.checklistId != null && target.type == NotificationTargetType.checklistItem) {
      levels.add([
        for (final r in index.owned(RuleTargetType.checklist, target.checklistId!))
          if (r.spec.appliesTo == AppliesTo.items ||
              r.spec.appliesTo == AppliesTo.descendants ||
              r.spec.appliesTo == AppliesTo.selfAndDescendants)
            EffectiveRule(r, RuleProvenance.checklist, sourceId: target.checklistId),
      ]);
    }
    if (target.categoryId != null) {
      levels.add([
        for (final r in index.byCategory[target.categoryId!] ?? const <NotificationRule>[])
          if (r.isDefault && r.section == target.section)
            EffectiveRule(r, RuleProvenance.category, sourceId: target.categoryId),
      ]);
    }
    levels
      ..add([
        for (final r in index.bySection[target.section] ?? const <NotificationRule>[])
          if (r.isDefault && _matchesKind(r, target)) EffectiveRule(r, RuleProvenance.section),
      ])
      ..add([
        for (final r in index.global)
          if (r.isDefault && _matchesKind(r, target)) EffectiveRule(r, RuleProvenance.global),
      ]);

    final claimed = <String>{};
    final result = <EffectiveRule>[];
    for (final level in levels) {
      final levelKinds = <String>{};
      for (final e in level) {
        if (!e.rule.enabled && e.provenance != RuleProvenance.section && e.provenance != RuleProvenance.global) {
          // A disabled specific default still claims its kind (explicit "not here").
          levelKinds.add(triggerKindKey(e.rule.spec.trigger));
          continue;
        }
        final kind = triggerKindKey(e.rule.spec.trigger);
        if (claimed.contains(kind)) continue;
        levelKinds.add(kind);
        result.add(e);
      }
      claimed.addAll(levelKinds);
    }
    return result;
  }

  static bool _matchesKind(NotificationRule rule, NotificationTarget target) {
    final kind = ItemKind.tryParse(rule.spec.conditions.itemKind);
    if (kind == null || kind == ItemKind.any) return true;
    return kind == target.itemKind;
  }

  static bool _matchesOccurrence(NotificationRule rule, NotificationTarget target) {
    final only = rule.spec.conditions.occurrenceKeys;
    final exclude = rule.spec.conditions.excludeOccurrenceKeys;
    final occ = target.occurrenceKey;
    if (only != null && only.isNotEmpty && (occ == null || !only.contains(occ))) return false;
    if (exclude != null && occ != null && exclude.contains(occ)) return false;
    return true;
  }

  /// "Identical trigger kind" key (relative triggers are distinguished by anchor).
  static String triggerKindKey(NotificationTrigger trigger) => switch (trigger) {
    RelativeTrigger(:final anchor) => 'relative:${anchor.wire}',
    MilestoneTrigger(:final metric) => 'milestone:$metric',
    DigestTrigger(:final kind) => 'digest:$kind',
    _ => trigger.typeWire,
  };
}
