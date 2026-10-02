import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:meta/meta.dart';

/// Fully resolved delivery of one rule (T7.1.05): every field has a concrete value.
@immutable
class EffectiveDelivery {
  const EffectiveDelivery({
    required this.system,
    required this.inbox,
    required this.banner,
    required this.importance,
    required this.interruptionLevel,
    required this.relevance,
    required this.sound,
    required this.vibration,
    required this.sticky,
    required this.alarmStyle,
    required this.actions,
    required this.snoozeOptionsMinutes,
    required this.latenessMinutes,
    required this.repeat,
    required this.respectQuietHours,
    required this.profileCode,
    required this.channelVersion,
    this.alarm,
  });

  final bool system;
  final bool inbox;
  final bool banner;
  final NotificationImportance importance;

  /// Requested level (before capability downgrade).
  final InterruptionLevel interruptionLevel;
  final double relevance;

  /// `default`, `none` or a curated sound key.
  final String sound;
  final String vibration;
  final bool sticky;
  final bool alarmStyle;
  final List<String> actions;
  final List<int> snoozeOptionsMinutes;

  /// Null = settings default.
  final int? latenessMinutes;

  /// Null = no nagging.
  final RepeatSpec? repeat;
  final bool respectQuietHours;

  /// Channel family (profile code or custom profile key) and version.
  final String profileCode;
  final int channelVersion;

  /// Alarm missions / snooze limit / rising volume (T7.2.25).
  final AlarmOptions? alarm;

  bool get silent => sound == 'none';

  EffectiveDelivery copyWith({
    bool? system,
    bool? banner,
    bool? inbox,
    String? sound,
    NotificationImportance? importance,
  }) => EffectiveDelivery(
    system: system ?? this.system,
    inbox: inbox ?? this.inbox,
    banner: banner ?? this.banner,
    importance: importance ?? this.importance,
    interruptionLevel: interruptionLevel,
    relevance: relevance,
    sound: sound ?? this.sound,
    vibration: vibration,
    sticky: sticky,
    alarmStyle: alarmStyle,
    actions: actions,
    snoozeOptionsMinutes: snoozeOptionsMinutes,
    latenessMinutes: latenessMinutes,
    repeat: repeat,
    respectQuietHours: respectQuietHours,
    profileCode: profileCode,
    channelVersion: channelVersion,
    alarm: alarm,
  );

  @override
  bool operator ==(Object other) =>
      other is EffectiveDelivery &&
      other.system == system &&
      other.inbox == inbox &&
      other.banner == banner &&
      other.importance == importance &&
      other.interruptionLevel == interruptionLevel &&
      other.relevance == relevance &&
      other.sound == sound &&
      other.vibration == vibration &&
      other.sticky == sticky &&
      other.alarmStyle == alarmStyle &&
      _listEq(other.actions, actions) &&
      _listEq(other.snoozeOptionsMinutes, snoozeOptionsMinutes) &&
      other.latenessMinutes == latenessMinutes &&
      other.repeat == repeat &&
      other.respectQuietHours == respectQuietHours &&
      other.profileCode == profileCode &&
      other.channelVersion == channelVersion &&
      other.alarm == alarm;

  @override
  int get hashCode => Object.hash(system, inbox, banner, importance, sound, vibration, profileCode, channelVersion);

  static bool _listEq(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Resolves a rule's delivery over its profile chain (arch §6.13 *Profiles*, T7.1.05):
/// built-in fallback (Standard) ← section default profile ← rule profile ← rule fields.
/// Absent field = inherit; `"none"` / `[]` / `false` = explicitly disabled.
EffectiveDelivery resolveDelivery({
  required NotificationRuleSpec spec,
  NotificationProfile? ruleProfile,
  NotificationProfile? sectionDefault,
  List<String>? targetDefaultActions,
}) {
  final fallback = BuiltinProfiles.specs[BuiltinProfiles.standard]!;
  final layers = <DeliverySpec>[
    fallback.delivery,
    if (sectionDefault != null) sectionDefault.spec.delivery,
    if (ruleProfile != null) ruleProfile.spec.delivery,
    spec.delivery,
  ];
  T pick<T>(T? Function(DeliverySpec d) f, T fallbackValue) {
    for (final layer in layers.reversed) {
      final v = f(layer);
      if (v != null) return v;
    }
    return fallbackValue;
  }

  // Actions: a layer only counts when it sets actions; target defaults sit between the fallback
  // profile and any explicitly configured profile/rule actions.
  List<String> actions() {
    for (final layer in layers.skip(1).toList().reversed) {
      if (layer.actions != null) return layer.actions!;
    }
    return targetDefaultActions ?? fallback.delivery.actions ?? const [];
  }

  // Repeat: rule (set / false) ← rule profile ← section default ← none.
  RepeatSpec? repeat() {
    if (spec.repeatDisabled) return null;
    if (spec.repeat != null) return spec.repeat;
    for (final profile in [ruleProfile, sectionDefault]) {
      if (profile == null) continue;
      if (profile.spec.repeatDisabled) return null;
      if (profile.spec.repeat != null) return profile.spec.repeat;
    }
    return null;
  }

  bool respectQuietHours() {
    final own = spec.conditions.respectQuietHours;
    if (own != null) return own;
    for (final profile in [ruleProfile, sectionDefault]) {
      final v = profile?.spec.respectQuietHours;
      if (v != null) return v;
    }
    return true;
  }

  final importance =
      NotificationImportance.tryParse(pick((d) => d.importance, 'default')) ?? NotificationImportance.normal;
  final requestedLevel =
      InterruptionLevel.tryParse(pick((d) => d.interruptionLevel, '')) ??
      interruptionLevelFor(importance, timeSensitiveAllowed: true);
  final channelProfile = ruleProfile ?? sectionDefault;
  return EffectiveDelivery(
    system: pick((d) => d.system, true),
    inbox: pick((d) => d.inbox, true),
    banner: pick((d) => d.banner, true),
    importance: importance,
    interruptionLevel: requestedLevel,
    relevance: pick<num>((d) => d.relevance, _relevanceFor(importance)).toDouble().clamp(0, 1),
    sound: pick((d) => d.sound, 'default'),
    vibration: pick((d) => d.vibration, 'default'),
    sticky: pick((d) => d.sticky, false),
    alarmStyle: pick((d) => d.alarmStyle, false),
    actions: actions(),
    snoozeOptionsMinutes: pick((d) => d.snoozeOptionsMinutes, const [5, 10, 30, 60]),
    latenessMinutes: pick<int?>((d) => d.latenessMinutes, null),
    repeat: repeat(),
    respectQuietHours: respectQuietHours(),
    profileCode: channelProfile?.channelKey ?? BuiltinProfiles.standard,
    channelVersion: channelProfile?.spec.channelVersion ?? 1,
    alarm: pick<AlarmOptions?>((d) => d.alarm, null),
  );
}

/// Importance → iOS interruption level (T7.1.05 mapping table, reused by [7.2]/[7.4]):
/// min/low → passive, default → active, high/urgent → timeSensitive when the capability is
/// granted, else active.
InterruptionLevel interruptionLevelFor(NotificationImportance importance, {required bool timeSensitiveAllowed}) =>
    switch (importance) {
      NotificationImportance.min || NotificationImportance.low => InterruptionLevel.passive,
      NotificationImportance.normal => InterruptionLevel.active,
      NotificationImportance.high || NotificationImportance.urgent =>
        timeSensitiveAllowed ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
    };

/// Downgrades a requested level when the device lacks the capability.
InterruptionLevel effectiveInterruptionLevel(InterruptionLevel requested, {required bool timeSensitiveAllowed}) =>
    requested == InterruptionLevel.timeSensitive && !timeSensitiveAllowed ? InterruptionLevel.active : requested;

double _relevanceFor(NotificationImportance importance) => switch (importance) {
  NotificationImportance.min => 0.1,
  NotificationImportance.low => 0.3,
  NotificationImportance.normal => 0.5,
  NotificationImportance.high => 0.8,
  NotificationImportance.urgent => 1,
};
