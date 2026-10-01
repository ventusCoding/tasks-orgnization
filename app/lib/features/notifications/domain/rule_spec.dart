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

/// `repeat` block — nagging (T7.2.18). Hard cap: 10 repeats.
@immutable
class RepeatSpec {
  const RepeatSpec({required this.everyMinutes, required this.maxTimes, this.until = RepeatUntil.completed, this.raw});

  factory RepeatSpec.fromJson(Map<String, Object?> json) => RepeatSpec(
    everyMinutes: asInt(json['everyMinutes']) ?? 5,
    maxTimes: asInt(json['maxTimes']) ?? 5,
    until: RepeatUntil.parse(asString(json['until'])),
    raw: json,
  );

  static const hardMaxTimes = 10;

  final int everyMinutes;
  final int maxTimes;
  final RepeatUntil until;
  final Map<String, Object?>? raw;

  Map<String, Object?> toJson() => mergeOrdered(
    raw,
    {'everyMinutes': everyMinutes, 'maxTimes': maxTimes, 'until': until.wire},
    const {'everyMinutes', 'maxTimes', 'until'},
  );

  RepeatSpec copyWith({int? everyMinutes, int? maxTimes, RepeatUntil? until}) => RepeatSpec(
    everyMinutes: everyMinutes ?? this.everyMinutes,
    maxTimes: maxTimes ?? this.maxTimes,
    until: until ?? this.until,
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

/// `content` block: title/body templates (`{variables}`), optional variants (P2).
@immutable
class ContentSpec {
  const ContentSpec({this.title, this.body, this.variants, this.raw});

  factory ContentSpec.fromJson(Map<String, Object?> json) => ContentSpec(
    title: asString(json['title']),
    body: asString(json['body']),
    variants: json['variants'] is List
        ? [
            for (final v in json['variants']! as List)
              if (asJsonMap(v) != null) ContentVariant.fromJson(asJsonMap(v)!),
          ]
        : null,
    raw: json,
  );

  static const empty = ContentSpec();

  final String? title;
  final String? body;
  final List<ContentVariant>? variants;
  final Map<String, Object?>? raw;

  bool get isEmpty => title == null && body == null && (variants == null || variants!.isEmpty);

  Map<String, Object?> toJson() => mergeOrdered(
    raw,
    {
      'title': ?title,
      'body': ?body,
      if (variants != null) 'variants': [for (final v in variants!) v.toJson()],
    },
    const {'title', 'body', 'variants'},
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
