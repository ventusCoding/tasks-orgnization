import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:meta/meta.dart';

/// A rule to create (target + spec), used for single and bulk creation and for the rules of an
/// item that isn't saved yet (T7.1.09 drafts).
@immutable
class RuleDraft {
  const RuleDraft({
    required this.targetType,
    required this.section,
    required this.spec,
    this.targetId,
    this.isDefault = false,
    this.enabled = true,
    this.name,
    this.profileId,
  });

  factory RuleDraft.fromRule(
    NotificationRule r, {
    RuleTargetType? targetType,
    String? targetId,
    bool? isDefault,
  }) => RuleDraft(
    targetType: targetType ?? r.targetType,
    targetId: targetId ?? r.targetId,
    section: r.section,
    spec: r.spec,
    isDefault: isDefault ?? r.isDefault,
    enabled: r.enabled,
    name: r.name,
    profileId: r.profileId,
  );

  final RuleTargetType targetType;
  final String? targetId;
  final NotificationSection section;
  final NotificationRuleSpec spec;
  final bool isDefault;
  final bool enabled;
  final String? name;
  final String? profileId;

  RuleDraft copyWith({
    RuleTargetType? targetType,
    String? targetId,
    NotificationSection? section,
    NotificationRuleSpec? spec,
    bool? isDefault,
    bool? enabled,
    String? name,
    String? profileId,
    bool clearProfile = false,
  }) => RuleDraft(
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    section: section ?? this.section,
    spec: spec ?? this.spec,
    isDefault: isDefault ?? this.isDefault,
    enabled: enabled ?? this.enabled,
    name: name ?? this.name,
    profileId: clearProfile ? null : (profileId ?? this.profileId),
  );

  @override
  bool operator ==(Object other) =>
      other is RuleDraft &&
      other.targetType == targetType &&
      other.targetId == targetId &&
      other.section == section &&
      other.spec == spec &&
      other.isDefault == isDefault &&
      other.enabled == enabled &&
      other.name == name &&
      other.profileId == profileId;

  @override
  int get hashCode => Object.hash(
    targetType,
    targetId,
    section,
    spec,
    isDefault,
    enabled,
    name,
    profileId,
  );
}
