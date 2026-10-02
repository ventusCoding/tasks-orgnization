import 'dart:convert';

import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/rule_triggers.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

export 'package:everslot/features/notifications/domain/rule_triggers.dart';

/// Nag chain stop condition.
enum RepeatUntil {
  acknowledged('acknowledged'),
  completed('completed'),
  max('max');

  RepeatUntil(this.wire);

  final String wire;

  static RepeatUntil parse(String? value) {
    for (final u in values) {
      if (u.wire == value) return u;
    }
    return RepeatUntil.completed;
  }
}

/// One `repeat.escalation[]` step (T7.2.23): from repeat [fromRepeat] on, nags are delivered
/// with profile [profile] (built-in code or profile id — its channel, importance, interruption
/// level, sound, alarm style) and, with [allDevices], on every device despite `conditions.devices`.
@immutable
class EscalationStep {
  const EscalationStep({required this.fromRepeat, required this.profile, this.allDevices = false});

  factory EscalationStep.fromJson(Map<String, Object?> json) => EscalationStep(
    fromRepeat: asInt(json['fromRepeat']) ?? 1,
    profile: asString(json['profile']) ?? '',
    allDevices: asBool(json['allDevices']) ?? false,
  );

  final int fromRepeat;
  final String profile;
  final bool allDevices;

  Map<String, Object?> toJson() => {'fromRepeat': fromRepeat, 'profile': profile, if (allDevices) 'allDevices': true};

  @override
  bool operator ==(Object other) =>
      other is EscalationStep &&
      other.fromRepeat == fromRepeat &&
      other.profile == profile &&
      other.allDevices == allDevices;

  @override
  int get hashCode => Object.hash(fromRepeat, profile, allDevices);
}

/// `repeat` block — nagging (T7.2.18). Hard cap: 10 repeats.
@immutable
class RepeatSpec {
  const RepeatSpec({
    required this.everyMinutes,
    required this.maxTimes,
    this.until = RepeatUntil.completed,
    this.escalation,
    this.raw,
  });

  factory RepeatSpec.fromJson(Map<String, Object?> json) => RepeatSpec(
    everyMinutes: asInt(json['everyMinutes']) ?? 5,
    maxTimes: asInt(json['maxTimes']) ?? 5,
    until: RepeatUntil.parse(asString(json['until'])),
    escalation: json['escalation'] is List
        ? [
            for (final s in json['escalation']! as List)
              if (asJsonMap(s) != null) EscalationStep.fromJson(asJsonMap(s)!),
          ]
        : null,
    raw: json,
  );

  static const hardMaxTimes = 10;

  final int everyMinutes;
  final int maxTimes;
  final RepeatUntil until;

  /// Delivery changes by repeat index, ascending `fromRepeat` (T7.2.23).
  final List<EscalationStep>? escalation;
  final Map<String, Object?>? raw;

  /// The escalation step in force for nag [repeatIdx] (≥ 1), if any.
  EscalationStep? stepFor(int repeatIdx) {
    EscalationStep? step;
    for (final s in escalation ?? const <EscalationStep>[]) {
      if (s.fromRepeat <= repeatIdx) step = s;
    }
    return step;
  }

  Map<String, Object?> toJson() => mergeOrdered(
    raw,
    {
      'everyMinutes': everyMinutes,
      'maxTimes': maxTimes,
      'until': until.wire,
      if (escalation != null) 'escalation': [for (final s in escalation!) s.toJson()],
    },
    const {'everyMinutes', 'maxTimes', 'until', 'escalation'},
  );

  RepeatSpec copyWith({int? everyMinutes, int? maxTimes, RepeatUntil? until, List<EscalationStep>? escalation}) =>
      RepeatSpec(
        everyMinutes: everyMinutes ?? this.everyMinutes,
        maxTimes: maxTimes ?? this.maxTimes,
        until: until ?? this.until,
        escalation: escalation ?? this.escalation,
        raw: raw,
      );

  @override
  bool operator ==(Object other) => other is RepeatSpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}

/// Behaviour outside `conditions.timeWindow`.
enum OutsideWindow {
  drop('drop'),
  shiftStart('shift_start'),
  shiftEnd('shift_end');

  OutsideWindow(this.wire);

  final String wire;

  static OutsideWindow parse(String? value) {
    for (final o in values) {
      if (o.wire == value) return o;
    }
    return OutsideWindow.drop;
  }
}

@immutable
class TimeWindowSpec {
  const TimeWindowSpec({required this.from, required this.to, this.outside = OutsideWindow.drop, this.raw});

  factory TimeWindowSpec.fromJson(Map<String, Object?> json) => TimeWindowSpec(
    from: LocalTime.tryParse(asString(json['from']) ?? '') ?? LocalTime.midnight,
    to: LocalTime.tryParse(asString(json['to']) ?? '') ?? LocalTime.endOfDay,
    outside: OutsideWindow.parse(asString(json['outside'])),
    raw: json,
  );

  final LocalTime from;
  final LocalTime to;
  final OutsideWindow outside;
  final Map<String, Object?>? raw;

  /// True when [time] lies inside the window (windows may cross midnight).
  bool contains(LocalTime time) {
    final m = time.minuteOfDay;
    if (from.minuteOfDay <= to.minuteOfDay) {
      return m >= from.minuteOfDay && m <= to.minuteOfDay;
    }
    return m >= from.minuteOfDay || m <= to.minuteOfDay;
  }

  Map<String, Object?> toJson() => mergeOrdered(
    raw,
    {'from': from.toIso(), 'to': to.toIso(), 'outside': outside.wire},
    const {'from', 'to', 'outside'},
  );
}

/// `conditions` block. Absent fields = no condition.
@immutable
class ConditionsSpec {
  const ConditionsSpec({
    this.onlyIfStatusIn,
    this.weekdays,
    this.timeWindow,
    this.respectQuietHours,
    this.devices,
    this.itemKind,
    this.occurrenceKeys,
    this.excludeOccurrenceKeys,
    this.raw,
  });

  factory ConditionsSpec.fromJson(Map<String, Object?> json) {
    final devices = json['devices'];
    final window = asJsonMap(json['timeWindow']);
    return ConditionsSpec(
      onlyIfStatusIn: asStringList(json['onlyIfStatusIn']),
      weekdays: asIntList(json['weekdays']),
      timeWindow: window == null ? null : TimeWindowSpec.fromJson(window),
      respectQuietHours: asBool(json['respectQuietHours']),
      devices: devices is List ? asStringList(devices) : null,
      itemKind: asString(json['itemKind']),
      occurrenceKeys: asStringList(json['occurrenceKeys']),
      excludeOccurrenceKeys: asStringList(json['excludeOccurrenceKeys']),
      raw: json,
    );
  }

  static const empty = ConditionsSpec();

  final List<String>? onlyIfStatusIn;

  /// ISO weekdays 1..7 (extra filter on the fire time's local weekday).
  final List<int>? weekdays;
  final TimeWindowSpec? timeWindow;
  final bool? respectQuietHours;

  /// Device ids this rule may schedule on (`null` = all — encoded as `"all"`).
  final List<String>? devices;

  /// timed | all_day | date_only | any
  final String? itemKind;
  final List<String>? occurrenceKeys;
  final List<String>? excludeOccurrenceKeys;
  final Map<String, Object?>? raw;

  bool get isEmpty => jsonEquals(toJson(), const <String, Object?>{});

  Map<String, Object?> toJson() {
    final rawDevices = raw?['devices'];
    return mergeOrdered(
      raw,
      {
        'onlyIfStatusIn': ?onlyIfStatusIn,
        'weekdays': ?weekdays,
        'timeWindow': ?timeWindow?.toJson(),
        'respectQuietHours': ?respectQuietHours,
        if (devices != null) 'devices': devices else if (rawDevices == 'all') 'devices': 'all',
        'itemKind': ?itemKind,
        'occurrenceKeys': ?occurrenceKeys,
        'excludeOccurrenceKeys': ?excludeOccurrenceKeys,
      },
      const {
        'onlyIfStatusIn',
        'weekdays',
        'timeWindow',
        'respectQuietHours',
        'devices',
        'itemKind',
        'occurrenceKeys',
        'excludeOccurrenceKeys',
      },
    );
  }

  ConditionsSpec copyWith({
    List<String>? onlyIfStatusIn,
    List<int>? weekdays,
    TimeWindowSpec? timeWindow,
    bool? respectQuietHours,
    List<String>? devices,
    String? itemKind,
    List<String>? occurrenceKeys,
    List<String>? excludeOccurrenceKeys,
    bool clearOnlyIfStatusIn = false,
    bool clearWeekdays = false,
    bool clearTimeWindow = false,
    bool clearRespectQuietHours = false,
    bool clearDevices = false,
    bool clearItemKind = false,
  }) => ConditionsSpec(
    onlyIfStatusIn: clearOnlyIfStatusIn ? null : (onlyIfStatusIn ?? this.onlyIfStatusIn),
    weekdays: clearWeekdays ? null : (weekdays ?? this.weekdays),
    timeWindow: clearTimeWindow ? null : (timeWindow ?? this.timeWindow),
    respectQuietHours: clearRespectQuietHours ? null : (respectQuietHours ?? this.respectQuietHours),
    devices: clearDevices ? null : (devices ?? this.devices),
    itemKind: clearItemKind ? null : (itemKind ?? this.itemKind),
    occurrenceKeys: occurrenceKeys ?? this.occurrenceKeys,
    excludeOccurrenceKeys: excludeOccurrenceKeys ?? this.excludeOccurrenceKeys,
    raw: raw,
  );

  @override
  bool operator ==(Object other) => other is ConditionsSpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}

/// What stops a ringing alarm (T7.2.25).
enum AlarmMissionType {
  /// Solve [AlarmMission.count] sums.
  math('math'),

  /// Type the reminder's title.
  type('type'),

  /// Shake the phone [AlarmMission.count] times.
  shake('shake'),

  /// Scan the saved QR code ([AlarmMission.code]).
  qr('qr');

  AlarmMissionType(this.wire);

  final String wire;

  static AlarmMissionType? tryParse(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

@immutable
class AlarmMission {
  const AlarmMission({required this.type, this.count, this.code});

  static AlarmMission? fromJson(Map<String, Object?>? json) {
    final type = AlarmMissionType.tryParse(asString(json?['type']));
    if (json == null || type == null) return null;
    return AlarmMission(type: type, count: asInt(json['count']), code: asString(json['code']));
  }

  final AlarmMissionType type;

  /// Sums to solve / shakes (defaults 3 / 20).
  final int? count;

  /// The QR payload to scan.
  final String? code;

  int get effectiveCount => count ?? (type == AlarmMissionType.math ? 3 : 20);

  Map<String, Object?> toJson() => {'type': type.wire, 'count': ?count, 'code': ?code};

  @override
  bool operator ==(Object other) =>
      other is AlarmMission && other.type == type && other.count == count && other.code == code;

  @override
  int get hashCode => Object.hash(type, count, code);
}

/// `delivery.alarm` (T7.2.25): Alarmy-style options of an alarm-style reminder — a mission before
/// it can be stopped, a snooze limit and a volume that rises while it rings.
@immutable
class AlarmOptions {
  const AlarmOptions({this.mission, this.maxSnoozes, this.rampVolume = false});

  factory AlarmOptions.fromJson(Map<String, Object?> json) => AlarmOptions(
    mission: AlarmMission.fromJson(asJsonMap(json['mission'])),
    maxSnoozes: asInt(json['maxSnoozes']),
    rampVolume: asBool(json['rampVolume']) ?? false,
  );

  final AlarmMission? mission;

  /// Snoozes allowed for one alarm (null = the settings limit).
  final int? maxSnoozes;
  final bool rampVolume;

  Map<String, Object?> toJson() => {
    if (mission != null) 'mission': mission!.toJson(),
    'maxSnoozes': ?maxSnoozes,
    if (rampVolume) 'rampVolume': true,
  };

  @override
  bool operator ==(Object other) =>
      other is AlarmOptions &&
      other.mission == mission &&
      other.maxSnoozes == maxSnoozes &&
      other.rampVolume == rampVolume;

  @override
  int get hashCode => Object.hash(mission, maxSnoozes, rampVolume);
}

/// `delivery` block. Absent (null) = inherit; disable sentinels: `"none"` (sound/vibration),
/// `[]` (actions/snooze presets), `false` (booleans).
@immutable
class DeliverySpec {
  const DeliverySpec({
    this.system,
    this.inbox,
    this.banner,
    this.importance,
    this.interruptionLevel,
    this.relevance,
    this.sound,
    this.vibration,
    this.sticky,
    this.alarmStyle,
    this.actions,
    this.snoozeOptionsMinutes,
    this.latenessMinutes,
    this.alarm,
    this.raw,
  });

  factory DeliverySpec.fromJson(Map<String, Object?> json) => DeliverySpec(
    system: asBool(json['system']),
    inbox: asBool(json['inbox']),
    banner: asBool(json['banner']),
    importance: asString(json['importance']),
    interruptionLevel: asString(json['interruptionLevel']),
    relevance: asNum(json['relevance']),
    sound: asString(json['sound']),
    vibration: asString(json['vibration']),
    sticky: asBool(json['sticky']),
    alarmStyle: asBool(json['alarmStyle']),
    actions: asStringList(json['actions']),
    snoozeOptionsMinutes: asIntList(json['snoozeOptionsMinutes']),
    latenessMinutes: asInt(json['latenessMinutes']),
    alarm: asJsonMap(json['alarm']) == null ? null : AlarmOptions.fromJson(asJsonMap(json['alarm'])!),
    raw: json,
  );

  static const empty = DeliverySpec();

  static const keys = {
    'system',
    'inbox',
    'banner',
    'importance',
    'interruptionLevel',
    'relevance',
    'sound',
    'vibration',
    'sticky',
    'alarmStyle',
    'actions',
    'snoozeOptionsMinutes',
    'latenessMinutes',
    'alarm',
  };

  final bool? system;
  final bool? inbox;
  final bool? banner;

  /// min | low | default | high | urgent
  final String? importance;

  /// passive | active | timeSensitive
  final String? interruptionLevel;
  final num? relevance;
  final String? sound;
  final String? vibration;
  final bool? sticky;
  final bool? alarmStyle;
  final List<String>? actions;
  final List<int>? snoozeOptionsMinutes;
  final int? latenessMinutes;

  /// Missions, snooze limit and rising volume of alarm-style reminders (T7.2.25).
  final AlarmOptions? alarm;
  final Map<String, Object?>? raw;

  Map<String, Object?> toJson() => mergeOrdered(raw, {
    'system': ?system,
    'inbox': ?inbox,
    'banner': ?banner,
    'importance': ?importance,
    'interruptionLevel': ?interruptionLevel,
    'relevance': ?relevance,
    'sound': ?sound,
    'vibration': ?vibration,
    'sticky': ?sticky,
    'alarmStyle': ?alarmStyle,
    'actions': ?actions,
    'snoozeOptionsMinutes': ?snoozeOptionsMinutes,
    'latenessMinutes': ?latenessMinutes,
    if (alarm != null) 'alarm': alarm!.toJson(),
  }, keys);

  bool get isEmpty => toJson().isEmpty;

  /// Returns a copy where the named fields are replaced; pass [clear] to make fields absent
  /// (= inherit).
  DeliverySpec copyWith({
    bool? system,
    bool? inbox,
    bool? banner,
    String? importance,
    String? interruptionLevel,
    num? relevance,
    String? sound,
    String? vibration,
    bool? sticky,
    bool? alarmStyle,
    List<String>? actions,
    List<int>? snoozeOptionsMinutes,
    int? latenessMinutes,
    AlarmOptions? alarm,
    Set<String> clear = const {},
  }) => DeliverySpec(
    system: clear.contains('system') ? null : (system ?? this.system),
    inbox: clear.contains('inbox') ? null : (inbox ?? this.inbox),
    banner: clear.contains('banner') ? null : (banner ?? this.banner),
    importance: clear.contains('importance') ? null : (importance ?? this.importance),
    interruptionLevel: clear.contains('interruptionLevel') ? null : (interruptionLevel ?? this.interruptionLevel),
    relevance: clear.contains('relevance') ? null : (relevance ?? this.relevance),
    sound: clear.contains('sound') ? null : (sound ?? this.sound),
    vibration: clear.contains('vibration') ? null : (vibration ?? this.vibration),
    sticky: clear.contains('sticky') ? null : (sticky ?? this.sticky),
    alarmStyle: clear.contains('alarmStyle') ? null : (alarmStyle ?? this.alarmStyle),
    actions: clear.contains('actions') ? null : (actions ?? this.actions),
    snoozeOptionsMinutes: clear.contains('snoozeOptionsMinutes')
        ? null
        : (snoozeOptionsMinutes ?? this.snoozeOptionsMinutes),
    latenessMinutes: clear.contains('latenessMinutes') ? null : (latenessMinutes ?? this.latenessMinutes),
    alarm: clear.contains('alarm') ? null : (alarm ?? this.alarm),
    raw: raw == null
        ? null
        : {
            for (final e in raw!.entries)
              if (!clear.contains(e.key)) e.key: e.value,
          },
  );

  @override
  bool operator ==(Object other) => other is DeliverySpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}

@immutable
class ContentVariant {
  const ContentVariant({this.title, this.body});

  factory ContentVariant.fromJson(Map<String, Object?> json) =>
      ContentVariant(title: asString(json['title']), body: asString(json['body']));

  final String? title;
  final String? body;

  Map<String, Object?> toJson() => {'title': ?title, 'body': ?body};
}

/// Curated motivational packs (`content.pack`, T7.1.17): localized body variants rotated per
/// occurrence; variants whose `{variables}` the target lacks are skipped.
abstract final class ContentPacks {
  static const habitMotivation = 'habit_motivation';
  static const quitMotivation = 'quit_motivation';
  static const all = [habitMotivation, quitMotivation];
}

/// `content` block: title/body templates (`{variables}`), optional variants (P2).
@immutable
class ContentSpec {
  const ContentSpec({this.title, this.body, this.variants, this.pack, this.raw});

  factory ContentSpec.fromJson(Map<String, Object?> json) => ContentSpec(
    title: asString(json['title']),
    body: asString(json['body']),
    variants: json['variants'] is List
        ? [
            for (final v in json['variants']! as List)
              if (asJsonMap(v) != null) ContentVariant.fromJson(asJsonMap(v)!),
          ]
        : null,
    pack: asString(json['pack']),
    raw: json,
  );

  static const empty = ContentSpec();

  final String? title;
  final String? body;
  final List<ContentVariant>? variants;

  /// Curated localized variants ([ContentPacks]) used when [variants] is empty (T7.1.17).
  final String? pack;
  final Map<String, Object?>? raw;

  bool get isEmpty => title == null && body == null && (variants == null || variants!.isEmpty) && pack == null;

  Map<String, Object?> toJson() => mergeOrdered(
    raw,
    {
      'title': ?title,
      'body': ?body,
      if (variants != null) 'variants': [for (final v in variants!) v.toJson()],
      'pack': ?pack,
    },
    const {'title', 'body', 'variants', 'pack'},
  );

  @override
  bool operator ==(Object other) => other is ContentSpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}

/// `scope.appliesTo` for checklist / item rules (T7.1 conventions).
enum AppliesTo {
  self('self'),
  items('items'),
  descendants('descendants'),
  selfAndDescendants('self_and_descendants');

  AppliesTo(this.wire);

  final String wire;

  static AppliesTo parse(String? value) {
    for (final a in values) {
      if (a.wire == value) return a;
    }
    return AppliesTo.self;
  }
}

/// A notification rule spec (arch §8.2, `notification_rules.spec`), JSON `"v": 1`.
@immutable
class NotificationRuleSpec {
  const NotificationRuleSpec({
    required this.trigger,
    this.repeat,
    this.repeatDisabled = false,
    this.conditions = ConditionsSpec.empty,
    this.delivery = DeliverySpec.empty,
    this.content = ContentSpec.empty,
    this.appliesTo,
    this.raw,
  });

  factory NotificationRuleSpec.fromJson(Map<String, Object?> json) {
    final repeat = json['repeat'];
    final scope = asJsonMap(json['scope']);
    return NotificationRuleSpec(
      trigger: NotificationTrigger.fromJson(
        asJsonMap(json['trigger']) ?? const {'type': 'relative', 'anchor': 'start'},
      ),
      repeat: asJsonMap(repeat) == null ? null : RepeatSpec.fromJson(asJsonMap(repeat)!),
      repeatDisabled: repeat == false,
      conditions: asJsonMap(json['conditions']) == null
          ? ConditionsSpec.empty
          : ConditionsSpec.fromJson(asJsonMap(json['conditions'])!),
      delivery: asJsonMap(json['delivery']) == null
          ? DeliverySpec.empty
          : DeliverySpec.fromJson(asJsonMap(json['delivery'])!),
      content: asJsonMap(json['content']) == null
          ? ContentSpec.empty
          : ContentSpec.fromJson(asJsonMap(json['content'])!),
      appliesTo: scope == null ? null : AppliesTo.parse(asString(scope['appliesTo'])),
      raw: json,
    );
  }

  /// Decodes a stored JSON string (returns null when unreadable).
  static NotificationRuleSpec? tryDecode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      final map = asJsonMap(decoded);
      return map == null ? null : NotificationRuleSpec.fromJson(map);
    } on FormatException {
      return null;
    }
  }

  static const version = 1;

  final NotificationTrigger trigger;

  /// Nag repeat (null = inherit from the profile unless [repeatDisabled]).
  final RepeatSpec? repeat;

  /// `"repeat": false` — explicitly no nagging even if the profile nags.
  final bool repeatDisabled;
  final ConditionsSpec conditions;
  final DeliverySpec delivery;
  final ContentSpec content;
  final AppliesTo? appliesTo;
  final Map<String, Object?>? raw;

  Map<String, Object?> toJson() {
    final scopeRaw = asJsonMap(raw?['scope']);
    final conditionsJson = conditions.toJson();
    final deliveryJson = delivery.toJson();
    final contentJson = content.toJson();
    return mergeOrdered(
      raw,
      {
        'v': version,
        'trigger': trigger.toJson(),
        if (repeat != null) 'repeat': repeat!.toJson() else if (repeatDisabled) 'repeat': false,
        if (conditionsJson.isNotEmpty || raw?.containsKey('conditions') == true) 'conditions': conditionsJson,
        if (deliveryJson.isNotEmpty || raw?.containsKey('delivery') == true) 'delivery': deliveryJson,
        if (contentJson.isNotEmpty || raw?.containsKey('content') == true) 'content': contentJson,
        if (appliesTo != null) 'scope': mergeOrdered(scopeRaw, {'appliesTo': appliesTo!.wire}, const {'appliesTo'}),
      },
      const {'v', 'trigger', 'repeat', 'conditions', 'delivery', 'content', 'scope'},
    );
  }

  String encode() => jsonEncode(toJson());

  NotificationRuleSpec copyWith({
    NotificationTrigger? trigger,
    RepeatSpec? repeat,
    bool? repeatDisabled,
    bool clearRepeat = false,
    ConditionsSpec? conditions,
    DeliverySpec? delivery,
    ContentSpec? content,
    AppliesTo? appliesTo,
  }) => NotificationRuleSpec(
    trigger: trigger ?? this.trigger,
    repeat: clearRepeat ? null : (repeat ?? this.repeat),
    repeatDisabled: clearRepeat ? (repeatDisabled ?? false) : (repeatDisabled ?? this.repeatDisabled),
    conditions: conditions ?? this.conditions,
    delivery: delivery ?? this.delivery,
    content: content ?? this.content,
    appliesTo: appliesTo ?? this.appliesTo,
    raw: raw == null
        ? null
        : {
            for (final e in raw!.entries)
              if (!(clearRepeat && e.key == 'repeat')) e.key: e.value,
          },
  );

  @override
  bool operator ==(Object other) => other is NotificationRuleSpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}

/// Delivery/repeat/content defaults of a profile (`notification_profiles.spec`).
@immutable
class ProfileSpec {
  const ProfileSpec({
    this.delivery = DeliverySpec.empty,
    this.repeat,
    this.repeatDisabled = false,
    this.respectQuietHours,
    this.content = ContentSpec.empty,
    this.channelVersion = 1,
    this.hidden = false,
    this.raw,
  });

  factory ProfileSpec.fromJson(Map<String, Object?> json) {
    final repeat = json['repeat'];
    final conditions = asJsonMap(json['conditions']);
    return ProfileSpec(
      delivery: asJsonMap(json['delivery']) == null
          ? DeliverySpec.empty
          : DeliverySpec.fromJson(asJsonMap(json['delivery'])!),
      repeat: asJsonMap(repeat) == null ? null : RepeatSpec.fromJson(asJsonMap(repeat)!),
      repeatDisabled: repeat == false,
      respectQuietHours: conditions == null ? null : asBool(conditions['respectQuietHours']),
      content: asJsonMap(json['content']) == null
          ? ContentSpec.empty
          : ContentSpec.fromJson(asJsonMap(json['content'])!),
      channelVersion: asInt(json['channelVersion']) ?? 1,
      hidden: asBool(json['hidden']) ?? false,
      raw: json,
    );
  }

  static ProfileSpec tryDecode(String? source) {
    if (source == null || source.isEmpty) return const ProfileSpec();
    try {
      final map = asJsonMap(jsonDecode(source));
      return map == null ? const ProfileSpec() : ProfileSpec.fromJson(map);
    } on FormatException {
      return const ProfileSpec();
    }
  }

  final DeliverySpec delivery;
  final RepeatSpec? repeat;
  final bool repeatDisabled;
  final bool? respectQuietHours;
  final ContentSpec content;

  /// Bumped when importance/sound/vibration change → new Android channel id (T7.1.13).
  final int channelVersion;

  /// Hidden built-ins (Alarm, P2).
  final bool hidden;
  final Map<String, Object?>? raw;

  Map<String, Object?> toJson() {
    final contentJson = content.toJson();
    return mergeOrdered(
      raw,
      {
        'v': 1,
        'delivery': delivery.toJson(),
        if (repeat != null) 'repeat': repeat!.toJson() else if (repeatDisabled) 'repeat': false,
        if (respectQuietHours != null) 'conditions': {'respectQuietHours': respectQuietHours},
        if (contentJson.isNotEmpty) 'content': contentJson,
        'channelVersion': channelVersion,
        if (hidden) 'hidden': true,
      },
      const {'v', 'delivery', 'repeat', 'conditions', 'content', 'channelVersion', 'hidden'},
    );
  }

  String encode() => jsonEncode(toJson());

  ProfileSpec copyWith({
    DeliverySpec? delivery,
    RepeatSpec? repeat,
    bool? repeatDisabled,
    bool clearRepeat = false,
    bool? respectQuietHours,
    ContentSpec? content,
    int? channelVersion,
  }) => ProfileSpec(
    delivery: delivery ?? this.delivery,
    repeat: clearRepeat ? null : (repeat ?? this.repeat),
    repeatDisabled: repeatDisabled ?? this.repeatDisabled,
    respectQuietHours: respectQuietHours ?? this.respectQuietHours,
    content: content ?? this.content,
    channelVersion: channelVersion ?? this.channelVersion,
    hidden: hidden,
    raw: raw,
  );

  /// Whether switching from this spec to [next] requires a new Android channel.
  bool channelChanged(ProfileSpec next) =>
      delivery.importance != next.delivery.importance ||
      delivery.sound != next.delivery.sound ||
      delivery.vibration != next.delivery.vibration;

  @override
  bool operator ==(Object other) => other is ProfileSpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}
