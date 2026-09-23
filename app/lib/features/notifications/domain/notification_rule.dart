import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:meta/meta.dart';

/// A stored rule (`notification_rules` row).
@immutable
class NotificationRule {
  const NotificationRule({
    required this.id,
    required this.targetType,
    required this.section,
    required this.spec,
    this.targetId,
    this.isDefault = false,
    this.enabled = true,
    this.name,
    this.profileId,
    this.sortKey = 'a0',
  });

  final String id;
  final RuleTargetType targetType;

  /// Null for section/global rules.
  final String? targetId;
  final NotificationSection section;
  final bool isDefault;
  final bool enabled;
  final String? name;
  final String? profileId;
  final NotificationRuleSpec spec;
  final String sortKey;

  /// Rules that are never inherited by items (planned once against a synthetic target).
  bool get isStandalone => spec.trigger is DigestTrigger;

  NotificationRule copyWith({
    RuleTargetType? targetType,
    String? targetId,
    NotificationSection? section,
    bool? isDefault,
    bool? enabled,
    String? name,
    String? profileId,
    bool clearProfile = false,
    NotificationRuleSpec? spec,
    String? sortKey,
  }) => NotificationRule(
    id: id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    section: section ?? this.section,
    isDefault: isDefault ?? this.isDefault,
    enabled: enabled ?? this.enabled,
    name: name ?? this.name,
    profileId: clearProfile ? null : (profileId ?? this.profileId),
    spec: spec ?? this.spec,
    sortKey: sortKey ?? this.sortKey,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationRule &&
      other.id == id &&
      other.targetType == targetType &&
      other.targetId == targetId &&
      other.section == section &&
      other.isDefault == isDefault &&
      other.enabled == enabled &&
      other.name == name &&
      other.profileId == profileId &&
      other.spec == spec &&
      other.sortKey == sortKey;

  @override
  int get hashCode =>
      Object.hash(id, targetType, targetId, section, isDefault, enabled, name, profileId, spec, sortKey);

  @override
  String toString() => 'NotificationRule($id ${targetType.wire}:${targetId ?? '-'} ${spec.trigger.typeWire})';
}

/// Built-in profile codes (`notification_profiles.code`).
abstract final class BuiltinProfiles {
  static const gentle = 'gentle';
  static const standard = 'standard';
  static const nag = 'nag';
  static const alarm = 'alarm';

  static const codes = [gentle, standard, nag, alarm];

  /// Default specs (T7.1.05). Delivery fields left out inherit the built-in fallback.
  static final Map<String, ProfileSpec> specs = {
    gentle: const ProfileSpec(
      delivery: DeliverySpec(
        system: true,
        inbox: true,
        banner: true,
        importance: 'low',
        interruptionLevel: 'passive',
        sound: 'none',
        vibration: 'none',
        actions: ['done', 'snooze'],
      ),
      repeatDisabled: true,
    ),
    standard: const ProfileSpec(
      delivery: DeliverySpec(
        system: true,
        inbox: true,
        banner: true,
        importance: 'default',
        interruptionLevel: 'active',
        sound: 'default',
        vibration: 'default',
        actions: ['done', 'snooze', 'skip'],
        snoozeOptionsMinutes: [5, 10, 30, 60],
      ),
      repeatDisabled: true,
    ),
    nag: const ProfileSpec(
      delivery: DeliverySpec(
        system: true,
        inbox: true,
        banner: true,
        importance: 'high',
        interruptionLevel: 'timeSensitive',
        sound: 'default',
        vibration: 'long',
        actions: ['done', 'snooze', 'skip'],
      ),
      repeat: RepeatSpec(everyMinutes: 5, maxTimes: 5),
    ),
    alarm: const ProfileSpec(
      delivery: DeliverySpec(
        system: true,
        inbox: true,
        banner: true,
        importance: 'urgent',
        interruptionLevel: 'timeSensitive',
        sound: 'alarm',
        vibration: 'long',
        alarmStyle: true,
        actions: ['done', 'snooze'],
      ),
      respectQuietHours: false,
      hidden: true,
    ),
  };
}

/// A delivery preset (`notification_profiles` row).
@immutable
class NotificationProfile {
  const NotificationProfile({
    required this.id,
    required this.name,
    required this.spec,
    this.code,
    this.isBuiltin = false,
    this.sortKey = 'a0',
  });

  final String id;
  final String? code;
  final String name;
  final bool isBuiltin;
  final ProfileSpec spec;
  final String sortKey;

  /// Channel family key: built-in code, or `p<first 8 chars of id>` for custom profiles.
  String get channelKey => code ?? 'p${id.replaceAll('-', '').substring(0, 8)}';

  bool get hidden => spec.hidden;

  NotificationProfile copyWith({String? name, ProfileSpec? spec, String? sortKey}) => NotificationProfile(
    id: id,
    code: code,
    name: name ?? this.name,
    isBuiltin: isBuiltin,
    spec: spec ?? this.spec,
    sortKey: sortKey ?? this.sortKey,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationProfile &&
      other.id == id &&
      other.code == code &&
      other.name == name &&
      other.isBuiltin == isBuiltin &&
      other.spec == spec &&
      other.sortKey == sortKey;

  @override
  int get hashCode => Object.hash(id, code, name, isBuiltin, spec, sortKey);
}

/// "Mute until …" (`notification_mutes` row). [targetType]: `rule | task | checklist |
/// checklist_item | habit | section`.
@immutable
class NotificationMute {
  const NotificationMute({required this.id, required this.targetType, this.targetId, this.section, this.until, this.reason});

  final String id;
  final String targetType;
  final String? targetId;
  final String? section;

  /// Null = until unmuted.
  final DateTime? until;
  final String? reason;

  bool activeAt(DateTime instant) => until == null || instant.isBefore(until!);

  @override
  bool operator ==(Object other) =>
      other is NotificationMute &&
      other.id == id &&
      other.targetType == targetType &&
      other.targetId == targetId &&
      other.section == section &&
      other.until == until &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(id, targetType, targetId, section, until, reason);
}
