import 'package:collection/collection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

const Object _unset = Object();
const DeepCollectionEquality _deep = DeepCollectionEquality();

/// How a slot habit rolls up to a day (T5.1.09).
enum SlotRollupMode {
  /// Every slot of the day must be done (default).
  allSlots('all_slots'),

  /// At least `minSlots` slots (e.g. 6 of 9 stand-ups).
  minSlots('min');

  SlotRollupMode(this.json);

  final String json;

  static SlotRollupMode parse(Object? value) =>
      SlotRollupMode.values.firstWhere((m) => m.json == value, orElse: () => SlotRollupMode.allSlots);
}

/// Daily pledge & evening review ritual of a quit tracker (T5.3.13).
@immutable
class PledgeSettings {
  const PledgeSettings({this.enabled = false, this.morning, this.evening});

  factory PledgeSettings.fromJson(Object? json) {
    if (json is! Map) return const PledgeSettings();
    return PledgeSettings(
      enabled: json['enabled'] == true,
      morning: json['morning'] is String ? LocalTime.tryParse(json['morning'] as String) : null,
      evening: json['evening'] is String ? LocalTime.tryParse(json['evening'] as String) : null,
    );
  }

  final bool enabled;
  final LocalTime? morning;
  final LocalTime? evening;

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    if (morning != null) 'morning': morning!.toIso(),
    if (evening != null) 'evening': evening!.toIso(),
  };

  PledgeSettings copyWith({bool? enabled, Object? morning = _unset, Object? evening = _unset}) => PledgeSettings(
    enabled: enabled ?? this.enabled,
    morning: identical(morning, _unset) ? this.morning : morning as LocalTime?,
    evening: identical(evening, _unset) ? this.evening : evening as LocalTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is PledgeSettings && other.enabled == enabled && other.morning == morning && other.evening == evening;

  @override
  int get hashCode => Object.hash(enabled, morning, evening);
}

/// Success rule of a time-boxed challenge (T5.4.05).
enum ChallengeRule {
  /// Every scheduled day done.
  everyDay('every_day'),

  /// At least `minRatio` of the scheduled days done.
  minRatio('min_ratio');

  ChallengeRule(this.json);

  final String json;

  static ChallengeRule parse(Object? value) =>
      ChallengeRule.values.firstWhere((m) => m.json == value, orElse: () => ChallengeRule.everyDay);
}

@immutable
class ChallengeSettings {
  const ChallengeSettings({this.rule = ChallengeRule.everyDay, this.minRatio = 0.8});

  factory ChallengeSettings.fromJson(Map<Object?, Object?> json) => ChallengeSettings(
    rule: ChallengeRule.parse(json['successRule']),
    minRatio: (json['minRatio'] as num?)?.toDouble() ?? 0.8,
  );

  final ChallengeRule rule;

  /// 0…1 (used with [ChallengeRule.minRatio]).
  final double minRatio;

  Map<String, Object?> toJson() => {'successRule': rule.json, 'minRatio': minRatio};

  @override
  bool operator ==(Object other) => other is ChallengeSettings && other.rule == rule && other.minRatio == minRatio;

  @override
  int get hashCode => Object.hash(rule, minRatio);
}

/// Target that grows during a challenge (T5.4.07): start at [start], +[step] every [everyDays]
/// days, capped at [max].
@immutable
class TargetProgression {
  const TargetProgression({required this.start, required this.step, required this.everyDays, this.max});

  factory TargetProgression.fromJson(Map<Object?, Object?> json) => TargetProgression(
    start: (json['start'] as num?)?.toDouble() ?? 1,
    step: (json['step'] as num?)?.toDouble() ?? 1,
    everyDays: ((json['everyDays'] as num?)?.toInt() ?? 1).clamp(1, 365),
    max: (json['max'] as num?)?.toDouble(),
  );

  final double start;
  final double step;
  final int everyDays;
  final double? max;

  /// Target in force on [date] for a habit that started on [habitStart].
  double targetOn(LocalDate habitStart, LocalDate date) {
    final days = habitStart.daysUntil(date);
    final steps = days < 0 ? 0 : days ~/ everyDays;
    final value = start + step * steps;
    final cap = max;
    return cap != null && value > cap ? cap : value;
  }

  Map<String, Object?> toJson() => {'start': start, 'step': step, 'everyDays': everyDays, if (max != null) 'max': max};

  @override
  bool operator ==(Object other) =>
      other is TargetProgression &&
      other.start == start &&
      other.step == step &&
      other.everyDays == everyDays &&
      other.max == max;

  @override
  int get hashCode => Object.hash(start, step, everyDays, max);
}

/// `habits.settings` — HabitSettings JSON value object, version 1 (arch §7.3).
///
/// Unknown keys are preserved in [extra] and written back unchanged, so newer clients' settings
/// survive an edit made on an older client.
@immutable
class HabitSettings {
  const HabitSettings({
    this.slotRollup = SlotRollupMode.allSlots,
    this.minSlots,
    this.earlyToleranceMinutes = 30,
    this.requireExplicitLog = false,
    this.incrementStep = 1,
    this.quickValues = const [],
    this.askNoteAfterCheckIn = false,
    this.minPerDay,
    this.pledge = const PledgeSettings(),
    this.challenge,
    this.targetProgression,
    this.lifeEstimateSource,
    this.extra = const {},
  });

  static const currentVersion = 1;
  static const defaults = HabitSettings();

  static const _known = {
    'v',
    'slotRollup',
    'earlyToleranceMinutes',
    'requireExplicitLog',
    'incrementStep',
    'quickValues',
    'askNoteAfterCheckIn',
    'minPerDay',
    'pledge',
    'challenge',
    'targetProgression',
    'lifeEstimateSource',
  };

  /// Decodes (and upgrades) the JSON value; malformed values fall back to defaults.
  factory HabitSettings.fromJson(Object? json) {
    if (json is! Map) return defaults;
    final rollup = json['slotRollup'];
    final quick = json['quickValues'];
    return HabitSettings(
      slotRollup: rollup is Map ? SlotRollupMode.parse(rollup['mode']) : SlotRollupMode.allSlots,
      minSlots: rollup is Map ? (rollup['minSlots'] as num?)?.toInt() : null,
      earlyToleranceMinutes: ((json['earlyToleranceMinutes'] as num?)?.toInt() ?? 30).clamp(0, 120),
      requireExplicitLog: json['requireExplicitLog'] == true,
      incrementStep: _positive((json['incrementStep'] as num?)?.toDouble()) ?? 1,
      quickValues: quick is List
          ? [
              for (final v in quick)
                if (v is num && v > 0) v.toDouble(),
            ]
          : const [],
      askNoteAfterCheckIn: json['askNoteAfterCheckIn'] == true,
      minPerDay: _positive((json['minPerDay'] as num?)?.toDouble()),
      pledge: PledgeSettings.fromJson(json['pledge']),
      challenge: json['challenge'] is Map
          ? ChallengeSettings.fromJson(json['challenge'] as Map<Object?, Object?>)
          : null,
      targetProgression: json['targetProgression'] is Map
          ? TargetProgression.fromJson(json['targetProgression'] as Map<Object?, Object?>)
          : null,
      lifeEstimateSource: json['lifeEstimateSource'] as String?,
      extra: {
        for (final e in json.entries)
          if (e.key is String && !_known.contains(e.key)) e.key as String: e.value,
      },
    );
  }

  static double? _positive(double? v) => v != null && v > 0 ? v : null;

  final SlotRollupMode slotRollup;
  final int? minSlots;

  /// 0–120 minutes: how early "Check now" may target the next slot.
  final int earlyToleranceMinutes;

  /// Limit habits: a closed day with nothing logged counts as missed instead of done.
  final bool requireExplicitLog;
  final double incrementStep;
  final List<double> quickValues;
  final bool askNoteAfterCheckIn;

  /// Quota habits with a measurable goal: minimum amount for a day to count as active.
  final double? minPerDay;
  final PledgeSettings pledge;
  final ChallengeSettings? challenge;
  final TargetProgression? targetProgression;

  /// Quit trackers: which life-expectancy estimate is used (`jackson2025`, `men`, `women`, `bmj2000`).
  final String? lifeEstimateSource;
  final Map<String, Object?> extra;

  Map<String, Object?> toJson() => {
    'v': currentVersion,
    'slotRollup': {'mode': slotRollup.json, if (minSlots != null) 'minSlots': minSlots},
    'earlyToleranceMinutes': earlyToleranceMinutes,
    'requireExplicitLog': requireExplicitLog,
    'incrementStep': incrementStep,
    if (quickValues.isNotEmpty) 'quickValues': quickValues,
    'askNoteAfterCheckIn': askNoteAfterCheckIn,
    if (minPerDay != null) 'minPerDay': minPerDay,
    if (pledge != const PledgeSettings()) 'pledge': pledge.toJson(),
    if (challenge != null) 'challenge': challenge!.toJson(),
    if (targetProgression != null) 'targetProgression': targetProgression!.toJson(),
    if (lifeEstimateSource != null) 'lifeEstimateSource': lifeEstimateSource,
    ...extra,
  };

  HabitSettings copyWith({
    SlotRollupMode? slotRollup,
    Object? minSlots = _unset,
    int? earlyToleranceMinutes,
    bool? requireExplicitLog,
    double? incrementStep,
    List<double>? quickValues,
    bool? askNoteAfterCheckIn,
    Object? minPerDay = _unset,
    PledgeSettings? pledge,
    Object? challenge = _unset,
    Object? targetProgression = _unset,
    Object? lifeEstimateSource = _unset,
  }) => HabitSettings(
    slotRollup: slotRollup ?? this.slotRollup,
    minSlots: identical(minSlots, _unset) ? this.minSlots : minSlots as int?,
    earlyToleranceMinutes: earlyToleranceMinutes ?? this.earlyToleranceMinutes,
    requireExplicitLog: requireExplicitLog ?? this.requireExplicitLog,
    incrementStep: incrementStep ?? this.incrementStep,
    quickValues: quickValues ?? this.quickValues,
    askNoteAfterCheckIn: askNoteAfterCheckIn ?? this.askNoteAfterCheckIn,
    minPerDay: identical(minPerDay, _unset) ? this.minPerDay : (minPerDay as num?)?.toDouble(),
    pledge: pledge ?? this.pledge,
    challenge: identical(challenge, _unset) ? this.challenge : challenge as ChallengeSettings?,
    targetProgression: identical(targetProgression, _unset)
        ? this.targetProgression
        : targetProgression as TargetProgression?,
    lifeEstimateSource: identical(lifeEstimateSource, _unset) ? this.lifeEstimateSource : lifeEstimateSource as String?,
    extra: extra,
  );

  @override
  bool operator ==(Object other) =>
      other is HabitSettings &&
      other.slotRollup == slotRollup &&
      other.minSlots == minSlots &&
      other.earlyToleranceMinutes == earlyToleranceMinutes &&
      other.requireExplicitLog == requireExplicitLog &&
      other.incrementStep == incrementStep &&
      _deep.equals(other.quickValues, quickValues) &&
      other.askNoteAfterCheckIn == askNoteAfterCheckIn &&
      other.minPerDay == minPerDay &&
      other.pledge == pledge &&
      other.challenge == challenge &&
      other.targetProgression == targetProgression &&
      other.lifeEstimateSource == lifeEstimateSource &&
      _deep.equals(other.extra, extra);

  @override
  int get hashCode => Object.hash(
    slotRollup,
    minSlots,
    earlyToleranceMinutes,
    requireExplicitLog,
    incrementStep,
    _deep.hash(quickValues),
    askNoteAfterCheckIn,
    minPerDay,
    pledge,
    challenge,
    targetProgression,
    lifeEstimateSource,
    _deep.hash(extra),
  );
}
