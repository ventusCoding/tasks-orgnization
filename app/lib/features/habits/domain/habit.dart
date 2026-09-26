import 'package:decimal/decimal.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitGoal, HabitGoalType, QuitMode, SkipPolicy, TargetOp;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

export 'package:everslot_metrics/everslot_metrics.dart' show HabitGoalType, QuitMode, SkipPolicy, TargetOp;

const Object _unset = Object();

/// `habits.kind`.
enum HabitKind {
  build,
  quit;

  static HabitKind parse(String? value) => value == 'quit' ? HabitKind.quit : HabitKind.build;
}

/// Database spelling helpers for the metrics enums reused by the domain.
extension HabitGoalTypeDb on HabitGoalType {
  String get db => name;

  static HabitGoalType parse(String? value) =>
      HabitGoalType.values.firstWhere((t) => t.name == value, orElse: () => HabitGoalType.check);
}

extension TargetOpDb on TargetOp {
  String get db => name;

  static TargetOp parse(String? value) =>
      TargetOp.values.firstWhere((t) => t.name == value, orElse: () => TargetOp.gte);
}

extension SkipPolicyDb on SkipPolicy {
  String get db => name;

  static SkipPolicy parse(String? value) => value == 'breaks' ? SkipPolicy.breaks : SkipPolicy.neutral;
}

extension QuitModeDb on QuitMode {
  String get db => name;

  static QuitMode parse(String? value) => value == 'reduce' ? QuitMode.reduce : QuitMode.abstain;
}

/// `habits.quit_substance` — gates health content (milestones and life regained: cigarettes only).
enum QuitSubstance {
  cigarettes('cigarettes'),
  vape('vape'),
  alcohol('alcohol'),
  cannabis('cannabis'),
  caffeine('caffeine'),
  sugar('sugar'),
  socialMedia('social_media'),
  gaming('gaming'),
  other('other');

  const QuitSubstance(this.db);

  final String db;

  static QuitSubstance? parse(String? value) {
    for (final s in values) {
      if (s.db == value) return s;
    }
    return null;
  }

  bool get hasHealthContent => this == QuitSubstance.cigarettes;
}

/// A habit goal (arch §8.4): *15 push-ups/day* → count, 15, gte, "reps"; *≤ 2 coffees* → count, 2,
/// lte; *30 min reading* → duration, 30, gte, "min".
@immutable
class HabitTarget {
  const HabitTarget({required this.type, this.target, this.op = TargetOp.gte, this.unit});

  const HabitTarget.check() : type = HabitGoalType.check, target = null, op = TargetOp.gte, unit = null;

  final HabitGoalType type;

  /// Target value (minutes for duration goals); null for yes/no goals.
  final double? target;
  final TargetOp op;

  /// Unit key from the catalog (`reps`, `glasses`…) or free text.
  final String? unit;

  bool get isMeasurable => type != HabitGoalType.check;
  bool get isLimit => op == TargetOp.lte;

  /// Target used for evaluation (1 for yes/no habits).
  double get effectiveTarget => isMeasurable ? (target ?? 1) : 1;

  HabitGoal toMetrics({double? overrideTarget}) =>
      HabitGoal(type, target: isMeasurable ? (overrideTarget ?? target) : null, op: isMeasurable ? op : TargetOp.gte);

  HabitTarget copyWith({HabitGoalType? type, Object? target = _unset, TargetOp? op, Object? unit = _unset}) =>
      HabitTarget(
        type: type ?? this.type,
        target: identical(target, _unset) ? this.target : (target as num?)?.toDouble(),
        op: op ?? this.op,
        unit: identical(unit, _unset) ? this.unit : unit as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is HabitTarget && other.type == type && other.target == target && other.op == op && other.unit == unit;

  @override
  int get hashCode => Object.hash(type, target, op, unit);

  @override
  String toString() => 'HabitTarget(${type.name} ${op.name} $target $unit)';
}

/// Machine-readable validation problems (localized by the presentation layer).
enum HabitValidationCode {
  nameEmpty,
  nameTooLong,
  targetRequired,
  durationOutOfRange,
  limitNeedsMeasurable,
  unitInvalid,
  endBeforeStart,
  scheduleInvalid,
  freezesOutOfRange,
  dailyLimitInvalid,
  negativeValue,
  currencyInvalid,
  quitStartInFuture,
}

/// Typed validation error of a habit (T5.1.03).
class HabitValidationException extends ValidationException {
  HabitValidationException(this.code, {String? field}) : super('Invalid habit: ${code.name}', field: field);

  final HabitValidationCode code;
}

/// A habit or quit tracker (`habits` row). Sealed into [BuildHabit] and [QuitHabit].
@immutable
sealed class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.startDate,
    required this.sortKey,
    this.description,
    this.icon,
    this.color,
    this.categoryId,
    this.sectionId,
    this.endDate,
    this.timeZone,
    this.settings = HabitSettings.defaults,
    this.archivedAt,
    this.notifyMode = 'inherit',
    this.createdAt,
    this.autoSuccess = true,
    this.motivation,
  });

  static const maxNameLength = 80;

  final String id;
  final String name;
  final String? description;

  /// Icon key from `IconCatalog`.
  final String? icon;

  /// ARGB color (category palette) or null.
  final int? color;
  final String? categoryId;
  final String? sectionId;
  final LocalDate startDate;
  final LocalDate? endDate;

  /// IANA zone, or null = floating (the user's current zone).
  final String? timeZone;
  final HabitSettings settings;
  final String sortKey;
  final DateTime? archivedAt;
  final String notifyMode;
  final DateTime? createdAt;
  final bool autoSuccess;
  final String? motivation;

  HabitKind get kind;
  bool get isArchived => archivedAt != null;
  bool get isQuit => kind == HabitKind.quit;
  bool get isFloating => timeZone == null;

  /// Throws [HabitValidationException] when the habit is invalid.
  void validate() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw HabitValidationException(HabitValidationCode.nameEmpty, field: 'name');
    if (trimmed.length > maxNameLength) {
      throw HabitValidationException(HabitValidationCode.nameTooLong, field: 'name');
    }
    final end = endDate;
    if (end != null && end.isBefore(startDate)) {
      throw HabitValidationException(HabitValidationCode.endBeforeStart, field: 'end_date');
    }
  }
}

/// A habit to build (yes/no, count, duration, numeric or an "at most" limit) on any schedule.
@immutable
final class BuildHabit extends Habit {
  const BuildHabit({
    required super.id,
    required super.name,
    required super.startDate,
    required super.sortKey,
    required this.goal,
    required this.schedule,
    super.description,
    super.icon,
    super.color,
    super.categoryId,
    super.sectionId,
    super.endDate,
    super.timeZone,
    super.settings,
    super.archivedAt,
    super.notifyMode,
    super.createdAt,
    super.autoSuccess,
    super.motivation,
    this.skipPolicy = SkipPolicy.neutral,
    this.freezesPerMonth = 0,
  });

  final HabitTarget goal;
  final RecurrenceRule schedule;
  final SkipPolicy skipPolicy;
  final int freezesPerMonth;

  @override
  HabitKind get kind => HabitKind.build;

  /// Challenge = a time-boxed habit with a success rule (T5.4.05).
  bool get isChallenge => endDate != null && settings.challenge != null;

  @override
  void validate() {
    super.validate();
    validateGoal(goal);
    if (freezesPerMonth < 0 || freezesPerMonth > 31) {
      throw HabitValidationException(HabitValidationCode.freezesOutOfRange, field: 'freezes_per_month');
    }
    final issues = schedule.validate(maxOccurrencesPerDay: 1440);
    if (!issues.isValid) throw HabitValidationException(HabitValidationCode.scheduleInvalid, field: 'schedule');
  }

  /// Goal rules (T5.1.03): target > 0 for measurable goals; duration targets 1–1 440 min; `lte`
  /// only for measurable goals; unit 1–20 characters when present.
  static void validateGoal(HabitTarget goal) {
    if (!goal.isMeasurable) {
      if (goal.op != TargetOp.gte) {
        throw HabitValidationException(HabitValidationCode.limitNeedsMeasurable, field: 'target_op');
      }
      return;
    }
    final target = goal.target;
    // Every measurable goal needs a target > 0 (server CHECK `habits_build_goal`); a limit of 0 is
    // not a habit — the editor suggests a quit tracker instead (T5.1.10).
    if (target == null || target.isNaN || target <= 0) {
      throw HabitValidationException(HabitValidationCode.targetRequired, field: 'target_value');
    }
    if (goal.type == HabitGoalType.duration && (target > 1440 || target < 1)) {
      throw HabitValidationException(HabitValidationCode.durationOutOfRange, field: 'target_value');
    }
    final unit = goal.unit?.trim();
    if (unit != null && (unit.isEmpty || unit.length > 20)) {
      throw HabitValidationException(HabitValidationCode.unitInvalid, field: 'unit');
    }
  }

  BuildHabit copyWith({
    String? name,
    Object? description = _unset,
    Object? icon = _unset,
    Object? color = _unset,
    Object? categoryId = _unset,
    Object? sectionId = _unset,
    LocalDate? startDate,
    Object? endDate = _unset,
    Object? timeZone = _unset,
    HabitSettings? settings,
    String? sortKey,
    Object? archivedAt = _unset,
    String? notifyMode,
    HabitTarget? goal,
    RecurrenceRule? schedule,
    SkipPolicy? skipPolicy,
    int? freezesPerMonth,
    Object? motivation = _unset,
  }) => BuildHabit(
    id: id,
    name: name ?? this.name,
    description: identical(description, _unset) ? this.description : description as String?,
    icon: identical(icon, _unset) ? this.icon : icon as String?,
    color: identical(color, _unset) ? this.color : color as int?,
    categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
    sectionId: identical(sectionId, _unset) ? this.sectionId : sectionId as String?,
    startDate: startDate ?? this.startDate,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as LocalDate?,
    timeZone: identical(timeZone, _unset) ? this.timeZone : timeZone as String?,
    settings: settings ?? this.settings,
    sortKey: sortKey ?? this.sortKey,
    archivedAt: identical(archivedAt, _unset) ? this.archivedAt : archivedAt as DateTime?,
    notifyMode: notifyMode ?? this.notifyMode,
    createdAt: createdAt,
    autoSuccess: autoSuccess,
    motivation: identical(motivation, _unset) ? this.motivation : motivation as String?,
    goal: goal ?? this.goal,
    schedule: schedule ?? this.schedule,
    skipPolicy: skipPolicy ?? this.skipPolicy,
    freezesPerMonth: freezesPerMonth ?? this.freezesPerMonth,
  );

  @override
  bool operator ==(Object other) =>
      other is BuildHabit &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.icon == icon &&
      other.color == color &&
      other.categoryId == categoryId &&
      other.sectionId == sectionId &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.timeZone == timeZone &&
      other.settings == settings &&
      other.sortKey == sortKey &&
      other.archivedAt == archivedAt &&
      other.notifyMode == notifyMode &&
      other.autoSuccess == autoSuccess &&
      other.motivation == motivation &&
      other.goal == goal &&
      other.schedule == schedule &&
      other.skipPolicy == skipPolicy &&
      other.freezesPerMonth == freezesPerMonth;

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    description,
    icon,
    color,
    categoryId,
    sectionId,
    startDate,
    endDate,
    timeZone,
    settings,
    sortKey,
    archivedAt,
    notifyMode,
    autoSuccess,
    motivation,
    goal,
    schedule,
    skipPolicy,
    freezesPerMonth,
  ]);

  @override
  String toString() => 'BuildHabit($id, $name, $goal)';
}

/// A quit tracker (stop smoking, cut down alcohol…). Quit specifics: arch §7.3, [5.3].
@immutable
final class QuitHabit extends Habit {
  const QuitHabit({
    required super.id,
    required super.name,
    required super.startDate,
    required super.sortKey,
    required this.mode,
    required this.quitStartedAt,
    super.description,
    super.icon,
    super.color,
    super.categoryId,
    super.sectionId,
    super.endDate,
    super.timeZone,
    super.settings,
    super.archivedAt,
    super.notifyMode,
    super.createdAt,
    super.autoSuccess,
    super.motivation,
    this.substance,
    this.dailyLimit,
    this.baselinePerDay = 0,
    this.unitCost,
    this.currency,
    this.timePerUnitMinutes,
    this.lifeMinutesPerUnit,
    this.unit,
  });

  final QuitMode mode;
  final QuitSubstance? substance;

  /// First quit instant — never overwritten by relapses (later attempts are `restart` logs).
  final DateTime quitStartedAt;

  /// Reduce mode: maximum units per day.
  final double? dailyLimit;
  final double baselinePerDay;

  /// Price of one unit (exact decimal arithmetic).
  final Decimal? unitCost;

  /// ISO 4217 code.
  final String? currency;
  final double? timePerUnitMinutes;
  final double? lifeMinutesPerUnit;

  /// Unit label (`habits.unit`, e.g. "cigarettes").
  final String? unit;

  @override
  HabitKind get kind => HabitKind.quit;

  bool get isReduce => mode == QuitMode.reduce;

  @override
  void validate() {
    super.validate();
    if (mode == QuitMode.reduce && (dailyLimit == null || dailyLimit! < 0)) {
      throw HabitValidationException(HabitValidationCode.dailyLimitInvalid, field: 'daily_limit');
    }
    for (final v in [baselinePerDay, timePerUnitMinutes, lifeMinutesPerUnit]) {
      if (v != null && v < 0) throw HabitValidationException(HabitValidationCode.negativeValue);
    }
    if (unitCost != null && unitCost! < Decimal.zero) {
      throw HabitValidationException(HabitValidationCode.negativeValue, field: 'unit_cost');
    }
    final c = currency;
    if (c != null && !RegExp(r'^[A-Z]{3}$').hasMatch(c)) {
      throw HabitValidationException(HabitValidationCode.currencyInvalid, field: 'currency');
    }
  }

  QuitHabit copyWith({
    String? name,
    Object? description = _unset,
    Object? icon = _unset,
    Object? color = _unset,
    Object? categoryId = _unset,
    Object? sectionId = _unset,
    LocalDate? startDate,
    Object? timeZone = _unset,
    HabitSettings? settings,
    String? sortKey,
    Object? archivedAt = _unset,
    bool? autoSuccess,
    Object? motivation = _unset,
    QuitMode? mode,
    Object? substance = _unset,
    DateTime? quitStartedAt,
    Object? dailyLimit = _unset,
    double? baselinePerDay,
    Object? unitCost = _unset,
    Object? currency = _unset,
    Object? timePerUnitMinutes = _unset,
    Object? lifeMinutesPerUnit = _unset,
    Object? unit = _unset,
  }) => QuitHabit(
    id: id,
    name: name ?? this.name,
    description: identical(description, _unset) ? this.description : description as String?,
    icon: identical(icon, _unset) ? this.icon : icon as String?,
    color: identical(color, _unset) ? this.color : color as int?,
    categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
    sectionId: identical(sectionId, _unset) ? this.sectionId : sectionId as String?,
    startDate: startDate ?? this.startDate,
    endDate: endDate,
    timeZone: identical(timeZone, _unset) ? this.timeZone : timeZone as String?,
    settings: settings ?? this.settings,
    sortKey: sortKey ?? this.sortKey,
    archivedAt: identical(archivedAt, _unset) ? this.archivedAt : archivedAt as DateTime?,
    notifyMode: notifyMode,
    createdAt: createdAt,
    autoSuccess: autoSuccess ?? this.autoSuccess,
    motivation: identical(motivation, _unset) ? this.motivation : motivation as String?,
    mode: mode ?? this.mode,
    substance: identical(substance, _unset) ? this.substance : substance as QuitSubstance?,
    quitStartedAt: quitStartedAt ?? this.quitStartedAt,
    dailyLimit: identical(dailyLimit, _unset) ? this.dailyLimit : (dailyLimit as num?)?.toDouble(),
    baselinePerDay: baselinePerDay ?? this.baselinePerDay,
    unitCost: identical(unitCost, _unset) ? this.unitCost : unitCost as Decimal?,
    currency: identical(currency, _unset) ? this.currency : currency as String?,
    timePerUnitMinutes: identical(timePerUnitMinutes, _unset)
        ? this.timePerUnitMinutes
        : (timePerUnitMinutes as num?)?.toDouble(),
    lifeMinutesPerUnit: identical(lifeMinutesPerUnit, _unset)
        ? this.lifeMinutesPerUnit
        : (lifeMinutesPerUnit as num?)?.toDouble(),
    unit: identical(unit, _unset) ? this.unit : unit as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is QuitHabit &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.icon == icon &&
      other.color == color &&
      other.categoryId == categoryId &&
      other.sectionId == sectionId &&
      other.startDate == startDate &&
      other.timeZone == timeZone &&
      other.settings == settings &&
      other.sortKey == sortKey &&
      other.archivedAt == archivedAt &&
      other.autoSuccess == autoSuccess &&
      other.motivation == motivation &&
      other.mode == mode &&
      other.substance == substance &&
      other.quitStartedAt == quitStartedAt &&
      other.dailyLimit == dailyLimit &&
      other.baselinePerDay == baselinePerDay &&
      other.unitCost == unitCost &&
      other.currency == currency &&
      other.timePerUnitMinutes == timePerUnitMinutes &&
      other.lifeMinutesPerUnit == lifeMinutesPerUnit &&
      other.unit == unit;

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    description,
    icon,
    color,
    categoryId,
    sectionId,
    startDate,
    timeZone,
    settings,
    sortKey,
    archivedAt,
    autoSuccess,
    motivation,
    mode,
    substance,
    quitStartedAt,
    dailyLimit,
    baselinePerDay,
    unitCost,
    currency,
    timePerUnitMinutes,
    lifeMinutesPerUnit,
    unit,
  ]);

  @override
  String toString() => 'QuitHabit($id, $name, ${mode.name})';
}
