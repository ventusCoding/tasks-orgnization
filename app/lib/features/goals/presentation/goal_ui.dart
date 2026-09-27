import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show GoalStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Localized labels of goal values.
extension GoalLabels on AppLocalizations {
  String goalMetricLabel(GoalMetric m) => switch (m) {
    GoalMetric.totalValue => goalsMetricTotalValue,
    GoalMetric.completions => goalsMetricCompletions,
    GoalMetric.streakDays => goalsMetricStreakDays,
    GoalMetric.cleanDays => goalsMetricCleanDays,
    GoalMetric.moneySaved => goalsMetricMoneySaved,
    GoalMetric.unitsAvoided => goalsMetricUnitsAvoided,
    GoalMetric.trackedMinutes => goalsMetricTrackedMinutes,
    GoalMetric.itemsCompleted => goalsMetricItemsCompleted,
  };

  String goalPeriodLabel(GoalPeriod p) => switch (p) {
    GoalPeriod.week => goalsPeriodWeek,
    GoalPeriod.month => goalsPeriodMonth,
    GoalPeriod.quarter => goalsPeriodQuarter,
    GoalPeriod.year => goalsPeriodYear,
    GoalPeriod.allTime => goalsPeriodAllTime,
    GoalPeriod.custom => goalsPeriodCustom,
  };

  String goalStatusLabel(GoalStatus s) => switch (s) {
    GoalStatus.achieved => goalsStatusAchieved,
    GoalStatus.onTrack => goalsStatusOnTrack,
    GoalStatus.behind => goalsStatusBehind,
    GoalStatus.atRisk => goalsStatusAtRisk,
  };

  String goalValidationMessage(GoalValidationCode c) => switch (c) {
    GoalValidationCode.metricNotAllowed => goalsErrMetric,
    GoalValidationCode.targetNotPositive => goalsErrTarget,
    GoalValidationCode.customPeriodNeedsDates => goalsErrDates,
    GoalValidationCode.endBeforeStart => goalsErrEnd,
    GoalValidationCode.scopeIdMissing => goalsErrScope,
    GoalValidationCode.titleTooLong => goalsErrTitle,
  };
}

/// A value of [metric] for [habit]: "4 200 reps", "12 days", "€45.00", "30 cigarettes".
String goalValueText(BuildContext context, WidgetRef ref, GoalMetric metric, double value, Habit habit) {
  final l = context.l10n;
  switch (metric) {
    case GoalMetric.moneySaved:
      final currency = (habit is QuitHabit ? habit.currency : null) ?? ref.read(userPreferencesProvider).currency;
      return AppFormat(context.localeName).currency(value, currency);
    case GoalMetric.totalValue:
      return formatAmount(context, value, habit is BuildHabit ? habit.goal.unit : null);
    case GoalMetric.unitsAvoided:
      return formatAmount(context, value, habit is QuitHabit ? habit.unit : null);
    case GoalMetric.completions:
    case GoalMetric.streakDays:
    case GoalMetric.cleanDays:
      return l.habitsDays(value.floor());
    case GoalMetric.trackedMinutes:
      return AppFormat(context.localeName, l10n: l).duration(value.round());
    case GoalMetric.itemsCompleted:
      return formatValue(context, value);
  }
}

/// The goal's title, else "10 000 reps · Total logged".
String goalDisplayTitle(BuildContext context, WidgetRef ref, Goal goal, Habit habit) {
  final title = goal.reward ?? goal.title;
  if (title != null && title.trim().isNotEmpty) return title;
  return '${goalValueText(context, ref, goal.metric, goal.target, habit)} · ${context.l10n.goalMetricLabel(goal.metric)}';
}

/// A round target just above [value] (≈ +10 %): 8 400 → 10 000, 23 → 25, 7 → 8.
double niceTargetAbove(double value) {
  if (value <= 0) return 1;
  final wanted = value * 1.1;
  final magnitude = math.pow(10, (math.log(wanted) / math.ln10).floor()).toDouble();
  for (final step in const [1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]) {
    final candidate = step * magnitude;
    if (candidate >= wanted - 1e-9) return candidate;
  }
  return 10 * magnitude;
}

/// Color of a goal status (always shown with its text).
Color goalStatusColor(BuildContext context, GoalStatus s) => switch (s) {
  GoalStatus.achieved || GoalStatus.onTrack => context.appColors.success,
  GoalStatus.behind => context.appColors.warning,
  GoalStatus.atRisk => context.appColors.danger,
};
