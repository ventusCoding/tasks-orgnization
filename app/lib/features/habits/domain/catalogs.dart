import 'package:decimal/decimal.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Localized unit catalog of measurable goals (T5.1.07). Keys are stored in `habits.unit`; any other
/// value is free text (1–20 characters).
abstract final class HabitUnits {
  static const reps = 'reps';
  static const times = 'times';
  static const glasses = 'glasses';
  static const pages = 'pages';
  static const km = 'km';
  static const mi = 'mi';
  static const steps = 'steps';
  static const minutes = 'min';
  static const hours = 'h';
  static const kcal = 'kcal';
  static const liters = 'L';
  static const milliliters = 'ml';
  static const cups = 'cups';

  // Quit units (presets, T5.3.01).
  static const cigarettes = 'cigarettes';
  static const sessions = 'sessions';
  static const drinks = 'drinks';
  static const joints = 'joints';
  static const servings = 'servings';

  static const count = [reps, times, glasses, pages, steps, cups, kcal];
  static const numeric = [km, mi, liters, milliliters, kcal, steps, pages];
  static const quit = [cigarettes, sessions, drinks, joints, cups, servings, minutes, hours, times];
  static const all = {
    reps,
    times,
    glasses,
    pages,
    km,
    mi,
    steps,
    minutes,
    hours,
    kcal,
    liters,
    milliliters,
    cups,
    cigarettes,
    sessions,
    drinks,
    joints,
    servings,
  };

  static bool isCatalog(String? unit) => unit != null && all.contains(unit);

  /// Default unit of a goal type.
  static String? defaultFor(HabitGoalType type) => switch (type) {
    HabitGoalType.check => null,
    HabitGoalType.count => reps,
    HabitGoalType.duration => minutes,
    HabitGoalType.numeric => km,
  };
}

/// A localized template that prefills the habit editor (T5.1.16) — challenge templates carry a
/// duration in days (T5.4.05). Texts are l10n keys resolved by the presentation layer.
@immutable
class HabitTemplate {
  const HabitTemplate({
    required this.key,
    required this.icon,
    required this.colorIndex,
    required this.goal,
    required this.schedule,
    this.sectionKey = DefaultSections.anytime,
    this.settings = HabitSettings.defaults,
    this.challengeDays,
  });

  final String key;
  final String icon;
  final int colorIndex;
  final HabitTarget goal;
  final SchedulePreset schedule;

  /// Default section key (`morning`, `afternoon`, `evening`, `anytime`).
  final String sectionKey;
  final HabitSettings settings;

  /// Challenge length (end date = start + days − 1) for challenge templates.
  final int? challengeDays;

  bool get isChallenge => challengeDays != null;

  /// A habit built from this template (for validation and prefilling).
  BuildHabit toHabit({
    required String id,
    required String name,
    required LocalDate startDate,
    required String sortKey,
    Weekday weekStart = Weekday.monday,
    String? sectionId,
    int? color,
  }) => BuildHabit(
    id: id,
    name: name,
    startDate: startDate,
    endDate: challengeDays == null ? null : startDate.plusDays(challengeDays! - 1),
    sortKey: sortKey,
    icon: icon,
    color: color,
    sectionId: sectionId,
    goal: schedule.adaptGoal(goal),
    schedule: schedule.toRule(weekStart: weekStart),
    settings: challengeDays == null
        ? settings
        : settings.copyWith(challenge: settings.challenge ?? const ChallengeSettings()),
  );

  static final List<HabitTemplate> all = [
    const HabitTemplate(
      key: 'pushUps',
      icon: 'fitness',
      colorIndex: 1,
      goal: HabitTarget(type: HabitGoalType.count, target: 15, unit: HabitUnits.reps),
      schedule: SchedulePreset.daily(),
      sectionKey: DefaultSections.morning,
      settings: HabitSettings(incrementStep: 5, quickValues: [5, 10, 15]),
    ),
    const HabitTemplate(
      key: 'water',
      icon: 'water',
      colorIndex: 14,
      goal: HabitTarget(type: HabitGoalType.count, target: 8, unit: HabitUnits.glasses),
      schedule: SchedulePreset.daily(),
    ),
    const HabitTemplate(
      key: 'read',
      icon: 'book',
      colorIndex: 4,
      goal: HabitTarget(type: HabitGoalType.duration, target: 20, unit: HabitUnits.minutes),
      schedule: SchedulePreset.daily(),
      sectionKey: DefaultSections.evening,
      settings: HabitSettings(incrementStep: 5, quickValues: [5, 10, 20]),
    ),
    const HabitTemplate(
      key: 'meditate',
      icon: 'meditate',
      colorIndex: 10,
      goal: HabitTarget(type: HabitGoalType.duration, target: 10, unit: HabitUnits.minutes),
      schedule: SchedulePreset.daily(),
      sectionKey: DefaultSections.morning,
    ),
    const HabitTemplate(
      key: 'walk',
      icon: 'walk',
      colorIndex: 2,
      goal: HabitTarget(type: HabitGoalType.numeric, target: 5, unit: HabitUnits.km),
      schedule: SchedulePreset.daily(),
      settings: HabitSettings(incrementStep: 0.5, quickValues: [1, 2, 5]),
    ),
    const HabitTemplate(
      key: 'sleepEarly',
      icon: 'sleep',
      colorIndex: 9,
      goal: HabitTarget.check(),
      schedule: SchedulePreset.daily(),
      sectionKey: DefaultSections.evening,
    ),
    HabitTemplate(
      key: 'stretch',
      icon: 'fitness',
      colorIndex: 7,
      goal: const HabitTarget.check(),
      schedule: SchedulePreset(
        SchedulePresetKind.interval,
        everyMinutes: 60,
        windowStart: LocalTime(9, 0),
        windowEnd: LocalTime(18, 0),
      ),
      settings: const HabitSettings(slotRollup: SlotRollupMode.minSlots, minSlots: 6),
    ),
    const HabitTemplate(
      key: 'gym',
      icon: 'fitness',
      colorIndex: 8,
      goal: HabitTarget.check(),
      schedule: SchedulePreset(SchedulePresetKind.timesPerWeek, n: 3),
    ),
    const HabitTemplate(
      key: 'coffeeLimit',
      icon: 'coffee',
      colorIndex: 15,
      goal: HabitTarget(type: HabitGoalType.count, target: 2, op: TargetOp.lte, unit: HabitUnits.cups),
      schedule: SchedulePreset.daily(),
    ),
    const HabitTemplate(
      key: 'journal',
      icon: 'write',
      colorIndex: 11,
      goal: HabitTarget.check(),
      schedule: SchedulePreset.daily(),
      sectionKey: DefaultSections.evening,
    ),
    // Challenge templates (T5.4.05).
    const HabitTemplate(
      key: 'challengePushUps',
      icon: 'trophy',
      colorIndex: 1,
      goal: HabitTarget(type: HabitGoalType.count, target: 20, unit: HabitUnits.reps),
      schedule: SchedulePreset.daily(),
      challengeDays: 30,
      settings: HabitSettings(incrementStep: 5, quickValues: [5, 10, 20]),
    ),
    const HabitTemplate(
      key: 'challengeNoSugar',
      icon: 'trophy',
      colorIndex: 13,
      goal: HabitTarget.check(),
      schedule: SchedulePreset.daily(),
      challengeDays: 21,
    ),
    const HabitTemplate(
      key: 'challengeMeditate',
      icon: 'trophy',
      colorIndex: 10,
      goal: HabitTarget(type: HabitGoalType.duration, target: 10, unit: HabitUnits.minutes),
      schedule: SchedulePreset.daily(),
      challengeDays: 14,
      sectionKey: DefaultSections.morning,
    ),
  ];

  static HabitTemplate? byKey(String key) {
    for (final t in all) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Quit preset (T5.3.01): sensible, editable defaults labelled as estimates. The preset key is
/// stored in `habits.quit_substance`, which gates health content (smoking only).
@immutable
class QuitPreset {
  const QuitPreset({
    required this.substance,
    required this.unit,
    required this.baselinePerDay,
    required this.icon,
    required this.colorIndex,
    this.timePerUnitMinutes,
    this.lifeMinutesPerUnit,
    this.unitsPerPack,
    this.mode = QuitMode.abstain,
  });

  final QuitSubstance substance;

  /// Unit key ([HabitUnits]).
  final String unit;
  final double baselinePerDay;
  final double? timePerUnitMinutes;

  /// Life-expectancy estimate per unit — smoking only (Jackson et al. 2025 ≈ 20 min per cigarette).
  final double? lifeMinutesPerUnit;

  /// Pack size for "pack price ÷ units per pack" cost entry.
  final int? unitsPerPack;
  final String icon;
  final int colorIndex;
  final QuitMode mode;

  String get key => substance.db;

  bool get hasHealthContent => substance.hasHealthContent;

  static const all = [
    QuitPreset(
      substance: QuitSubstance.cigarettes,
      unit: HabitUnits.cigarettes,
      baselinePerDay: 10,
      timePerUnitMinutes: 5,
      lifeMinutesPerUnit: 20,
      unitsPerPack: 20,
      icon: 'smoke_free',
      colorIndex: 12,
    ),
    QuitPreset(
      substance: QuitSubstance.vape,
      unit: HabitUnits.sessions,
      baselinePerDay: 10,
      timePerUnitMinutes: 5,
      icon: 'smoke_free',
      colorIndex: 5,
    ),
    QuitPreset(
      substance: QuitSubstance.alcohol,
      unit: HabitUnits.drinks,
      baselinePerDay: 2,
      timePerUnitMinutes: 30,
      icon: 'no_drinks',
      colorIndex: 1,
    ),
    QuitPreset(
      substance: QuitSubstance.cannabis,
      unit: HabitUnits.joints,
      baselinePerDay: 2,
      timePerUnitMinutes: 15,
      icon: 'smoke_free',
      colorIndex: 7,
    ),
    QuitPreset(
      substance: QuitSubstance.caffeine,
      unit: HabitUnits.cups,
      baselinePerDay: 3,
      timePerUnitMinutes: 10,
      icon: 'coffee',
      colorIndex: 15,
      mode: QuitMode.reduce,
    ),
    QuitPreset(
      substance: QuitSubstance.sugar,
      unit: HabitUnits.servings,
      baselinePerDay: 3,
      timePerUnitMinutes: 5,
      icon: 'food',
      colorIndex: 6,
    ),
    QuitPreset(
      substance: QuitSubstance.socialMedia,
      unit: HabitUnits.minutes,
      baselinePerDay: 120,
      timePerUnitMinutes: 1,
      icon: 'phone_off',
      colorIndex: 0,
      mode: QuitMode.reduce,
    ),
    QuitPreset(
      substance: QuitSubstance.gaming,
      unit: HabitUnits.hours,
      baselinePerDay: 2,
      timePerUnitMinutes: 60,
      icon: 'game',
      colorIndex: 9,
      mode: QuitMode.reduce,
    ),
    QuitPreset(substance: QuitSubstance.other, unit: HabitUnits.times, baselinePerDay: 1, icon: 'flag', colorIndex: 2),
  ];

  static QuitPreset of(QuitSubstance? substance) {
    for (final p in all) {
      if (p.substance == substance) return p;
    }
    return all.last;
  }

  /// Unit cost from a pack price: price ÷ units per pack (exact decimal arithmetic).
  static Decimal? unitCostFromPack(Decimal? packPrice, int? unitsPerPack) {
    if (packPrice == null || unitsPerPack == null || unitsPerPack <= 0) return null;
    return (packPrice / Decimal.fromInt(unitsPerPack)).toDecimal(scaleOnInfinitePrecision: 6);
  }
}
