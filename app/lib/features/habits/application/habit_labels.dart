import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;

/// Localized labels of habit domain values.
extension HabitLabels on AppLocalizations {
  /// Unit label for [count] (catalog units are pluralized; free text is shown as typed).
  String unitLabel(String? unit, num count) {
    final n = count is int ? count : (count == count.roundToDouble() ? count.round() : 2);
    return switch (unit) {
      null || '' => '',
      HabitUnits.reps => habitsUnitReps(n),
      HabitUnits.times => habitsUnitTimes(n),
      HabitUnits.glasses => habitsUnitGlasses(n),
      HabitUnits.pages => habitsUnitPages(n),
      HabitUnits.km => habitsUnitKm,
      HabitUnits.mi => habitsUnitMi,
      HabitUnits.steps => habitsUnitSteps(n),
      HabitUnits.minutes => habitsUnitMin,
      HabitUnits.hours => habitsUnitH,
      HabitUnits.kcal => habitsUnitKcal,
      HabitUnits.liters => habitsUnitL,
      HabitUnits.milliliters => habitsUnitMl,
      HabitUnits.cups => habitsUnitCups(n),
      HabitUnits.cigarettes => habitsUnitCigarettes(n),
      HabitUnits.sessions => habitsUnitSessions(n),
      HabitUnits.drinks => habitsUnitDrinks(n),
      HabitUnits.joints => habitsUnitJoints(n),
      HabitUnits.servings => habitsUnitServings(n),
      _ => unit,
    };
  }

  String statusLabel(PeriodStatus s) => switch (s) {
    PeriodStatus.done => habitsStatusDone,
    PeriodStatus.partial => habitsStatusPartial,
    PeriodStatus.failed => habitsStatusFailed,
    PeriodStatus.missed => habitsStatusMissed,
    PeriodStatus.skipped => habitsStatusSkipped,
    PeriodStatus.excused => habitsStatusExcused,
    PeriodStatus.frozen => habitsStatusFrozen,
    PeriodStatus.paused => habitsStatusPaused,
    PeriodStatus.pending => habitsStatusPending,
    PeriodStatus.notDue => habitsStatusNotDue,
  };

  String presetLabel(SchedulePresetKind k) => switch (k) {
    SchedulePresetKind.daily => habitsPresetDaily,
    SchedulePresetKind.weekdays => habitsPresetWeekdays,
    SchedulePresetKind.weekends => habitsPresetWeekends,
    SchedulePresetKind.specificDays => habitsPresetSpecificDays,
    SchedulePresetKind.everyNDays => habitsPresetEveryNDays,
    SchedulePresetKind.timesPerWeek => habitsPresetTimesPerWeek,
    SchedulePresetKind.timesPerMonth => habitsPresetTimesPerMonth,
    SchedulePresetKind.timesPerDay => habitsPresetTimesPerDay,
    SchedulePresetKind.specificTimes => habitsPresetSpecificTimes,
    SchedulePresetKind.interval => habitsPresetInterval,
    SchedulePresetKind.monthlyDay => habitsPresetMonthlyDay,
    SchedulePresetKind.monthlyWeekday => habitsPresetMonthlyWeekday,
    SchedulePresetKind.afterCompletion => habitsPresetAfterCompletion,
    SchedulePresetKind.custom => habitsPresetCustom,
  };

  String goalTypeLabel(HabitGoalType t) => switch (t) {
    HabitGoalType.check => habitsGoalTypeCheck,
    HabitGoalType.count => habitsGoalTypeCount,
    HabitGoalType.duration => habitsGoalTypeDuration,
    HabitGoalType.numeric => habitsGoalTypeNumeric,
  };

  String goalTypeExample(HabitGoalType t) => switch (t) {
    HabitGoalType.check => habitsGoalExampleCheck,
    HabitGoalType.count => habitsGoalExampleCount,
    HabitGoalType.duration => habitsGoalExampleDuration,
    HabitGoalType.numeric => habitsGoalExampleNumeric,
  };

  String opLabel(TargetOp op) => switch (op) {
    TargetOp.gte => habitsOpAtLeast,
    TargetOp.lte => habitsOpAtMost,
    TargetOp.eq => habitsOpExactly,
  };

  String moodLabel(int mood) => switch (mood) {
    1 => habitsMood1,
    2 => habitsMood2,
    3 => habitsMood3,
    4 => habitsMood4,
    _ => habitsMood5,
  };

  String defaultSectionName(String key) => switch (key) {
    DefaultSections.morning => habitsSectionMorning,
    DefaultSections.afternoon => habitsSectionAfternoon,
    DefaultSections.evening => habitsSectionEvening,
    _ => habitsSectionAnytime,
  };

  String quitPresetLabel(QuitSubstance? s) => switch (s) {
    QuitSubstance.cigarettes => quitPresetCigarettes,
    QuitSubstance.vape => quitPresetVape,
    QuitSubstance.alcohol => quitPresetAlcohol,
    QuitSubstance.cannabis => quitPresetCannabis,
    QuitSubstance.caffeine => quitPresetCaffeine,
    QuitSubstance.sugar => quitPresetSugar,
    QuitSubstance.socialMedia => quitPresetSocialMedia,
    QuitSubstance.gaming => quitPresetGaming,
    QuitSubstance.other || null => quitPresetOther,
  };

  /// Default name of a new tracker ("Stop smoking", "Cut down on caffeine"…).
  String quitPresetName(QuitSubstance? s) => switch (s) {
    QuitSubstance.cigarettes => quitNameCigarettes,
    QuitSubstance.vape => quitNameVape,
    QuitSubstance.alcohol => quitNameAlcohol,
    QuitSubstance.cannabis => quitNameCannabis,
    QuitSubstance.caffeine => quitNameCaffeine,
    QuitSubstance.sugar => quitNameSugar,
    QuitSubstance.socialMedia => quitNameSocialMedia,
    QuitSubstance.gaming => quitNameGaming,
    QuitSubstance.other || null => quitNameOther,
  };

  String validationMessage(HabitValidationCode code) => switch (code) {
    HabitValidationCode.nameEmpty => habitsErrNameEmpty,
    HabitValidationCode.nameTooLong => habitsErrNameTooLong,
    HabitValidationCode.targetRequired => habitsErrTarget,
    HabitValidationCode.durationOutOfRange => habitsErrDuration,
    HabitValidationCode.limitNeedsMeasurable => habitsErrLimitNeedsMeasurable,
    HabitValidationCode.unitInvalid => habitsErrUnit,
    HabitValidationCode.endBeforeStart => habitsErrEnd,
    HabitValidationCode.scheduleInvalid => habitsErrSchedule,
    HabitValidationCode.freezesOutOfRange => habitsErrFreezes,
    HabitValidationCode.dailyLimitInvalid => quitErrDailyLimit,
    HabitValidationCode.negativeValue => quitErrNegative,
    HabitValidationCode.currencyInvalid => quitErrCurrency,
    HabitValidationCode.quitStartInFuture => quitErrStartInFuture,
  };
}
