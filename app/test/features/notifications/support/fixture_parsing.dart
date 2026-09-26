import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';

/// JSON → domain helpers shared by the planner fixture runner and other tests.
DateTime? parseInstant(Object? v) => v is String ? DateTime.parse(v).toUtc() : null;

NotificationRule ruleFromJson(Map<String, Object?> j) => NotificationRule(
  id: asString(j['id'])!,
  targetType: RuleTargetType.parse(asString(j['targetType']) ?? 'section'),
  targetId: asString(j['targetId']),
  section: NotificationSection.parse(asString(j['section']) ?? 'planner'),
  isDefault: asBool(j['isDefault']) ?? (j['targetType'] == 'section' || j['targetType'] == 'global' || j['targetType'] == 'category'),
  enabled: asBool(j['enabled']) ?? true,
  profileId: asString(j['profileId']),
  spec: NotificationRuleSpec.fromJson(asJsonMap(j['spec'])!),
);

NotificationTarget targetFromJson(Map<String, Object?> j) {
  final quota = asJsonMap(j['quota']);
  return NotificationTarget(
    type: NotificationTargetType.parse(asString(j['type'])),
    id: asString(j['id'])!,
    section: NotificationSection.parse(asString(j['section'])),
    title: asString(j['title']) ?? 'Item',
    occurrenceKey: asString(j['occurrenceKey']),
    categoryId: asString(j['categoryId']),
    checklistId: asString(j['checklistId']),
    parentItemId: asString(j['parentItemId']),
    ancestorItemIds: asStringList(j['ancestorItemIds']) ?? const [],
    notifyMode: NotifyMode.parse(asString(j['notifyMode'])),
    itemKind: ItemKind.tryParse(asString(j['itemKind'])) ?? ItemKind.timed,
    timeZone: asString(j['timeZone']),
    start: parseInstant(j['start']),
    end: parseInstant(j['end']),
    due: parseInstant(j['due']),
    followUp: parseInstant(j['followUp']),
    slot: parseInstant(j['slot']),
    periodStart: parseInstant(j['periodStart']),
    periodEnd: parseInstant(j['periodEnd']),
    status: asString(j['status']),
    statusChangedAt: parseInstant(j['statusChangedAt']),
    lastActivityAt: parseInstant(j['lastActivityAt']),
    isOpen: asBool(j['isOpen']) ?? true,
    streak: asInt(j['streak']),
    quota: quota == null
        ? null
        : QuotaProgress(
            done: asInt(quota['done'])!,
            target: asInt(quota['target'])!,
            eligibleDaysLeft: asInt(quota['eligibleDaysLeft'])!,
          ),
    milestoneBaseline: parseInstant(j['milestoneBaseline']),
    milestones: [
      for (final m in (j['milestones'] as List?) ?? const <Object?>[])
        NotificationMilestone(
          metric: asString(asJsonMap(m)!['metric'])!,
          threshold: asNum(asJsonMap(m)!['threshold'])!,
          at: parseInstant(asJsonMap(m)!['at'])!,
        ),
    ],
    events: [
      for (final e in (j['events'] as List?) ?? const <Object?>[])
        NotificationEvent(
          kind: asString(asJsonMap(e)!['kind'])!,
          at: parseInstant(asJsonMap(e)!['at'])!,
          data: asJsonMap(asJsonMap(e)!['data']) ?? const {},
        ),
    ],
    variables: asJsonMap(j['variables']) ?? const {},
  );
}

NotificationMute muteFromJson(Map<String, Object?> j) => NotificationMute(
  id: asString(j['id']) ?? 'm',
  targetType: asString(j['targetType'])!,
  targetId: asString(j['targetId']),
  section: asString(j['section']),
  until: parseInstant(j['until']),
);

/// Built-in profiles with id == code (fixtures reference them by code).
List<NotificationProfile> builtinProfilesById() => [
  for (final e in BuiltinProfiles.specs.entries)
    NotificationProfile(id: e.key, code: e.key, name: e.key, isBuiltin: true, spec: e.value),
];
