import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Anchors a relative trigger can refer to (arch §8.2).
enum TriggerAnchor {
  start('start'),
  end('end'),
  due('due'),
  followUp('follow_up'),
  slot('slot'),
  periodStart('period_start'),
  periodEnd('period_end');

  const TriggerAnchor(this.wire);

  final String wire;

  static TriggerAnchor? tryParse(String? value) {
    for (final a in values) {
      if (a.wire == value) return a;
    }
    return null;
  }
}

/// Trigger kinds (one trigger per rule — multiple offsets are multiple rules).
enum TriggerType {
  relative('relative'),
  absolute('absolute'),
  schedule('schedule'),
  notDoneBy('not_done_by'),
  statusAge('status_age'),
  overdue('overdue'),
  streakRisk('streak_risk'),
  quotaBehind('quota_behind'),
  milestone('milestone'),
  inactivity('inactivity'),
  digest('digest'),
  statusChange('status_change'),
  childrenComplete('children_complete'),
  childOverdue('child_overdue'),
  stale('stale');

  const TriggerType(this.wire);

  final String wire;

  static TriggerType? tryParse(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// Sealed trigger union of the rule spec (T7.1.03). Unknown future types decode to
/// [UnknownTrigger] and survive a round trip.
@immutable
sealed class NotificationTrigger {
  const NotificationTrigger({this.raw});

  /// Map this trigger was decoded from (key order / unknown keys), null when built in code.
  final Map<String, Object?>? raw;

  /// Wire `type`.
  String get typeWire;

  /// Known type, null for [UnknownTrigger].
  TriggerType? get type => TriggerType.tryParse(typeWire);

  Map<String, Object?> get _fields;

  Set<String> get _knownKeys;

  Map<String, Object?> toJson() => mergeOrdered(
    raw,
    {'type': typeWire, ..._fields},
    {'type', ..._knownKeys},
  );

  /// True for triggers evaluated once per target (not per occurrence): dedupe is by fire time.
  bool get isTargetLevel => switch (this) {
    AbsoluteTrigger() ||
    ScheduleTrigger() ||
    InactivityTrigger() ||
    StaleTrigger() => true,
    DigestTrigger() => true,
    _ => false,
  };

  static NotificationTrigger fromJson(Map<String, Object?> json) {
    final type = TriggerType.tryParse(asString(json['type']));
    LocalTime? time(String key) {
      final s = asString(json[key]);
      return s == null ? null : LocalTime.tryParse(s);
    }

    return switch (type) {
      TriggerType.relative => RelativeTrigger(
        anchor:
            TriggerAnchor.tryParse(asString(json['anchor'])) ??
            TriggerAnchor.start,
        offsetMinutes: asInt(json['offsetMinutes']),
        dayOffset: asInt(json['dayOffset']),
        atTime: time('atTime'),
        raw: json,
      ),
      TriggerType.absolute => AbsoluteTrigger(
        at:
            LocalDateTime.tryParse(asString(json['at']) ?? '') ??
            LocalDateTime.of(1970, 1, 1),
        timeZone: asString(json['timeZone']),
        raw: json,
      ),
      TriggerType.schedule => ScheduleTrigger(
        recurrence: asJsonMap(json['recurrence']) ?? const {},
        raw: json,
      ),
      TriggerType.notDoneBy => NotDoneByTrigger(
        anchor: asString(json['anchor']) ?? 'period_end',
        offsetMinutes: asInt(json['offsetMinutes']),
        atTime: time('atTime'),
        raw: json,
      ),
      TriggerType.statusAge => StatusAgeTrigger(
        statuses: asStringList(json['statuses']) ?? const [],
        afterMinutes: asInt(json['afterMinutes']) ?? 0,
        raw: json,
      ),
      TriggerType.overdue => OverdueTrigger(
        afterMinutes: asInt(json['afterMinutes']),
        raw: json,
      ),
      TriggerType.streakRisk => StreakRiskTrigger(
        atTime: time('atTime') ?? LocalTime(21, 0),
        minStreak: asInt(json['minStreak']),
        raw: json,
      ),
      TriggerType.quotaBehind => QuotaBehindTrigger(
        atTime: time('atTime') ?? LocalTime(20, 0),
        raw: json,
      ),
      TriggerType.milestone => MilestoneTrigger(
        metric: asString(json['metric']) ?? 'clean_days',
        thresholds: json['thresholds'] is List
            ? [
                for (final v in json['thresholds']! as List)
                  if (asNum(v) != null) asNum(v)!,
              ]
            : null,
        raw: json,
      ),
      TriggerType.inactivity => InactivityTrigger(
        afterDays: asInt(json['afterDays']) ?? 1,
        atTime: time('atTime'),
        raw: json,
      ),
      TriggerType.digest => DigestTrigger(
        kind: asString(json['kind']) ?? 'daily_agenda',
        schedule: asJsonMap(json['schedule']) ?? const {},
        raw: json,
      ),
      TriggerType.statusChange => StatusChangeTrigger(
        from: asString(json['from']),
        to: asString(json['to']) ?? '',
        atTime: time('atTime'),
        raw: json,
      ),
      TriggerType.childrenComplete => ChildrenCompleteTrigger(raw: json),
      TriggerType.childOverdue => ChildOverdueTrigger(raw: json),
      TriggerType.stale => StaleTrigger(
        afterDays: asInt(json['afterDays']) ?? 7,
        atTime: time('atTime'),
        raw: json,
      ),
      null => UnknownTrigger(typeWire: asString(json['type']) ?? '', raw: json),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationTrigger && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());
}

/// Anchor ± offset, or `dayOffset` days from the anchor's local date at `atTime`.
final class RelativeTrigger extends NotificationTrigger {
  const RelativeTrigger({
    required this.anchor,
    this.offsetMinutes,
    this.dayOffset,
    this.atTime,
    super.raw,
  });

  final TriggerAnchor anchor;

  /// Minutes relative to the anchor instant: before (< 0), at (0), after (> 0).
  final int? offsetMinutes;

  /// Alternative form: N days before (< 0) / after (> 0) the anchor's local date at [atTime].
  final int? dayOffset;
  final LocalTime? atTime;

  bool get usesDayForm => dayOffset != null && atTime != null;

  /// Effective minute offset for the offset form (0 when absent).
  int get effectiveOffset => offsetMinutes ?? 0;

  @override
  String get typeWire => 'relative';

  @override
  Set<String> get _knownKeys => const {
    'anchor',
    'offsetMinutes',
    'dayOffset',
    'atTime',
  };

  @override
  Map<String, Object?> get _fields => {
    'anchor': anchor.wire,
    'offsetMinutes': ?offsetMinutes,
    'dayOffset': ?dayOffset,
    'atTime': ?atTime?.toIso(),
  };

  RelativeTrigger copyWith({
    TriggerAnchor? anchor,
    int? offsetMinutes,
    int? dayOffset,
    LocalTime? atTime,
  }) => RelativeTrigger(
    anchor: anchor ?? this.anchor,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    dayOffset: dayOffset ?? this.dayOffset,
    atTime: atTime ?? this.atTime,
  );
}

/// A fixed wall-clock moment (zone = [timeZone] or floating).
final class AbsoluteTrigger extends NotificationTrigger {
  const AbsoluteTrigger({required this.at, this.timeZone, super.raw});

  final LocalDateTime at;
  final String? timeZone;

  @override
  String get typeWire => 'absolute';

  @override
  Set<String> get _knownKeys => const {'at', 'timeZone'};

  @override
  Map<String, Object?> get _fields => {'at': at.toIso(), 'timeZone': ?timeZone};
}

/// Standalone recurring reminder (recurrence rule §8.1).
final class ScheduleTrigger extends NotificationTrigger {
  const ScheduleTrigger({required this.recurrence, super.raw});

  final Map<String, Object?> recurrence;

  @override
  String get typeWire => 'schedule';

  @override
  Set<String> get _knownKeys => const {'recurrence'};

  @override
  Map<String, Object?> get _fields => {'recurrence': recurrence};
}

/// "If not done by …" — `anchor`: `period_end` | `end` | `time` (+ `atTime`).
final class NotDoneByTrigger extends NotificationTrigger {
  const NotDoneByTrigger({
    required this.anchor,
    this.offsetMinutes,
    this.atTime,
    super.raw,
  });

  final String anchor;
  final int? offsetMinutes;

  int get effectiveOffset => offsetMinutes ?? 0;
  final LocalTime? atTime;

  @override
  String get typeWire => 'not_done_by';

  @override
  Set<String> get _knownKeys => const {'anchor', 'offsetMinutes', 'atTime'};

  @override
  Map<String, Object?> get _fields => {
    'anchor': anchor,
    'offsetMinutes': ?offsetMinutes,
    'atTime': ?atTime?.toIso(),
  };
}

/// Item still in one of [statuses] [afterMinutes] after entering it.
final class StatusAgeTrigger extends NotificationTrigger {
  const StatusAgeTrigger({
    required this.statuses,
    required this.afterMinutes,
    super.raw,
  });

  final List<String> statuses;
  final int afterMinutes;

  @override
  String get typeWire => 'status_age';

  @override
  Set<String> get _knownKeys => const {'statuses', 'afterMinutes'};

  @override
  Map<String, Object?> get _fields => {
    'statuses': statuses,
    'afterMinutes': afterMinutes,
  };
}

/// Still open [afterMinutes] after the end (or due) instant.
final class OverdueTrigger extends NotificationTrigger {
  const OverdueTrigger({this.afterMinutes, super.raw});

  final int? afterMinutes;

  int get effectiveAfter => afterMinutes ?? 0;

  @override
  String get typeWire => 'overdue';

  @override
  Set<String> get _knownKeys => const {'afterMinutes'};

  @override
  Map<String, Object?> get _fields => {'afterMinutes': ?afterMinutes};
}

/// At [atTime] when the streak ≥ [minStreak] and today's period is still open.
final class StreakRiskTrigger extends NotificationTrigger {
  const StreakRiskTrigger({required this.atTime, this.minStreak, super.raw});

  final LocalTime atTime;
  final int? minStreak;

  int get effectiveMinStreak => minStreak ?? 1;

  @override
  String get typeWire => 'streak_risk';

  @override
  Set<String> get _knownKeys => const {'atTime', 'minStreak'};

  @override
  Map<String, Object?> get _fields => {
    'atTime': atTime.toIso(),
    'minStreak': ?minStreak,
  };
}

/// Quota habit behind pace (completions still needed ≥ eligible days left), checked at [atTime].
final class QuotaBehindTrigger extends NotificationTrigger {
  const QuotaBehindTrigger({required this.atTime, super.raw});

  final LocalTime atTime;

  @override
  String get typeWire => 'quota_behind';

  @override
  Set<String> get _knownKeys => const {'atTime'};

  @override
  Map<String, Object?> get _fields => {'atTime': atTime.toIso()};
}

/// Metric thresholds (projected instants; `thresholds` null = "auto").
final class MilestoneTrigger extends NotificationTrigger {
  const MilestoneTrigger({required this.metric, this.thresholds, super.raw});

  /// clean_days | streak | total_value | money_saved | units_avoided
  final String metric;
  final List<num>? thresholds;

  static const autoDays = <num>[
    1,
    2,
    3,
    7,
    14,
    30,
    60,
    90,
    180,
    365,
    730,
    1095,
  ];

  List<num> get effectiveThresholds => thresholds ?? autoDays;

  @override
  String get typeWire => 'milestone';

  @override
  Set<String> get _knownKeys => const {'metric', 'thresholds'};

  @override
  Map<String, Object?> get _fields => {
    'metric': metric,
    'thresholds': thresholds ?? 'auto',
  };
}

/// No activity for [afterDays] days.
final class InactivityTrigger extends NotificationTrigger {
  const InactivityTrigger({required this.afterDays, this.atTime, super.raw});

  final int afterDays;
  final LocalTime? atTime;

  @override
  String get typeWire => 'inactivity';

  @override
  Set<String> get _knownKeys => const {'afterDays', 'atTime'};

  @override
  Map<String, Object?> get _fields => {
    'afterDays': afterDays,
    'atTime': ?atTime?.toIso(),
  };
}

/// Digest (`daily_agenda | plan_tomorrow | evening_review | overdue_summary | weekly_review |
/// monthly_report`) on a recurrence schedule.
final class DigestTrigger extends NotificationTrigger {
  const DigestTrigger({required this.kind, required this.schedule, super.raw});

  final String kind;
  final Map<String, Object?> schedule;

  static const kinds = [
    'daily_agenda',
    'plan_tomorrow',
    'evening_review',
    'overdue_summary',
    'weekly_review',
    'monthly_report',
  ];

  @override
  String get typeWire => 'digest';

  @override
  Set<String> get _knownKeys => const {'kind', 'schedule'};

  @override
  Map<String, Object?> get _fields => {'kind': kind, 'schedule': schedule};
}

/// Event-driven: the target changed status (`from` optional) to [to].
final class StatusChangeTrigger extends NotificationTrigger {
  const StatusChangeTrigger({
    required this.to,
    this.from,
    this.atTime,
    super.raw,
  });

  final String? from;
  final String to;

  /// Optional: notify at this local time on the event day instead of immediately.
  final LocalTime? atTime;

  @override
  String get typeWire => 'status_change';

  @override
  Set<String> get _knownKeys => const {'from', 'to', 'atTime'};

  @override
  Map<String, Object?> get _fields => {
    'from': ?from,
    'to': to,
    'atTime': ?atTime?.toIso(),
  };
}

/// Event-driven: all children of the watched item are complete.
final class ChildrenCompleteTrigger extends NotificationTrigger {
  const ChildrenCompleteTrigger({super.raw});

  @override
  String get typeWire => 'children_complete';

  @override
  Set<String> get _knownKeys => const {};

  @override
  Map<String, Object?> get _fields => const {};
}

/// Event-driven: a child of the watched item became overdue.
final class ChildOverdueTrigger extends NotificationTrigger {
  const ChildOverdueTrigger({super.raw});

  @override
  String get typeWire => 'child_overdue';

  @override
  Set<String> get _knownKeys => const {};

  @override
  Map<String, Object?> get _fields => const {};
}

/// Open item/list without activity for [afterDays] days.
final class StaleTrigger extends NotificationTrigger {
  const StaleTrigger({required this.afterDays, this.atTime, super.raw});

  final int afterDays;
  final LocalTime? atTime;

  @override
  String get typeWire => 'stale';

  @override
  Set<String> get _knownKeys => const {'afterDays', 'atTime'};

  @override
  Map<String, Object?> get _fields => {
    'afterDays': afterDays,
    'atTime': ?atTime?.toIso(),
  };
}

/// A trigger type this app version doesn't know (kept verbatim, never fires).
final class UnknownTrigger extends NotificationTrigger {
  const UnknownTrigger({required this.typeWire, super.raw});

  @override
  final String typeWire;

  @override
  Set<String> get _knownKeys => const {};

  @override
  Map<String, Object?> get _fields => const {};

  @override
  Map<String, Object?> toJson() => raw ?? {'type': typeWire};
}
