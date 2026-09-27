import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// What a goal is about (`goals.scope_type`, arch §7.3).
enum GoalScopeType {
  habit,
  series,
  category,
  checklist,
  global;

  static GoalScopeType parse(String? value) => values.firstWhere((s) => s.name == value, orElse: () => global);
}

/// What a goal counts (`goals.metric`).
enum GoalMetric {
  /// Σ logged values of a measurable habit (10 000 push-ups).
  totalValue('total_value'),

  /// Done periods of a habit / completed occurrences of a task series.
  completions('completions'),

  /// Current streak length of a habit.
  streakDays('streak_days'),

  /// Clean days of a quit tracker.
  cleanDays('clean_days'),

  /// Money saved by a quit tracker.
  moneySaved('money_saved'),

  /// Units avoided by a quit tracker.
  unitsAvoided('units_avoided'),

  /// Tracked minutes of a series or category.
  trackedMinutes('tracked_minutes'),

  /// Completed checklist items.
  itemsCompleted('items_completed');

  const GoalMetric(this.wire);

  final String wire;

  static GoalMetric? tryParse(String? value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return null;
  }

  /// Metrics whose value is not a sum of daily contributions.
  bool get isLevel => this == streakDays;
}

/// Time frame of a goal (`goals.period`).
enum GoalPeriod {
  allTime('all_time'),
  year('year'),
  quarter('quarter'),
  month('month'),
  week('week'),
  custom('custom');

  const GoalPeriod(this.wire);

  final String wire;

  static GoalPeriod parse(String? value) => values.firstWhere((p) => p.wire == value, orElse: () => allTime);
}

/// The kind of habit a habit-scoped goal is about (decides the metrics it allows).
enum GoalHabitKind { yesNo, measurable, quit }

/// Why a goal is invalid (mapped to localized messages).
enum GoalValidationCode { metricNotAllowed, targetNotPositive, customPeriodNeedsDates, endBeforeStart, scopeIdMissing, titleTooLong }

class GoalValidationException implements Exception {
  const GoalValidationException(this.code);

  final GoalValidationCode code;

  @override
  String toString() => 'GoalValidationException(${code.name})';
}

/// Metrics a scope allows (the same table as the `goals_metric_scope` CHECK). For habits the kind
/// narrows it further: totals need a measurable goal, clean days / money / units need a quit
/// tracker, streaks a build habit.
Set<GoalMetric> goalMetricsFor(GoalScopeType scope, {GoalHabitKind? habitKind}) => switch (scope) {
  GoalScopeType.habit => switch (habitKind) {
    GoalHabitKind.quit => const {GoalMetric.cleanDays, GoalMetric.moneySaved, GoalMetric.unitsAvoided},
    GoalHabitKind.measurable => const {GoalMetric.totalValue, GoalMetric.completions, GoalMetric.streakDays},
    GoalHabitKind.yesNo => const {GoalMetric.completions, GoalMetric.streakDays},
    null => const {
      GoalMetric.totalValue,
      GoalMetric.completions,
      GoalMetric.streakDays,
      GoalMetric.cleanDays,
      GoalMetric.moneySaved,
      GoalMetric.unitsAvoided,
    },
  },
  GoalScopeType.series => const {GoalMetric.completions, GoalMetric.trackedMinutes},
  GoalScopeType.category => const {GoalMetric.trackedMinutes},
  GoalScopeType.checklist => const {GoalMetric.itemsCompleted},
  GoalScopeType.global => const {GoalMetric.completions, GoalMetric.trackedMinutes, GoalMetric.itemsCompleted},
};

/// A numeric goal over a scope and period (T5.4.01) — also a savings reward (T5.3.15) when it has
/// a [reward]: "Concert ticket, 120 € saved".
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.scopeType,
    required this.metric,
    required this.target,
    required this.period,
    this.scopeId,
    this.startDate,
    this.endDate,
    this.title,
    this.reward,
    this.achievedAt,
    this.createdAt,
  });

  static const maxTitleLength = 80;

  final String id;
  final GoalScopeType scopeType;
  final String? scopeId;
  final GoalMetric metric;
  final double target;
  final GoalPeriod period;
  final LocalDate? startDate;
  final LocalDate? endDate;
  final String? title;

  /// Reward to buy with savings (T5.3.15); null for plain goals.
  final String? reward;

  /// Set once when the goal is achieved (or a reward claimed).
  final DateTime? achievedAt;
  final DateTime? createdAt;

  bool get isAchieved => achievedAt != null;
  bool get isReward => reward != null;

  /// Throws [GoalValidationException] when the goal breaks a rule (the same rules as the server).
  void validate({GoalHabitKind? habitKind}) {
    if (!goalMetricsFor(scopeType, habitKind: habitKind).contains(metric)) {
      throw const GoalValidationException(GoalValidationCode.metricNotAllowed);
    }
    if (!(target > 0) || target.isInfinite) throw const GoalValidationException(GoalValidationCode.targetNotPositive);
    if (period == GoalPeriod.custom && (startDate == null || endDate == null)) {
      throw const GoalValidationException(GoalValidationCode.customPeriodNeedsDates);
    }
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      throw const GoalValidationException(GoalValidationCode.endBeforeStart);
    }
    if ((scopeType == GoalScopeType.global) != (scopeId == null)) {
      throw const GoalValidationException(GoalValidationCode.scopeIdMissing);
    }
    if ((title?.length ?? 0) > maxTitleLength || (reward?.length ?? 0) > maxTitleLength) {
      throw const GoalValidationException(GoalValidationCode.titleTooLong);
    }
  }

  /// The inclusive dates the goal covers as of [asOf]: the current year/quarter/month/week (from
  /// [weekStart]) — starting no earlier than [startDate] —, the custom range, or for all-time goals
  /// [startDate] (else [origin], e.g. the habit's start) with an open end.
  ({LocalDate start, LocalDate? end}) window(LocalDate asOf, {required Weekday weekStart, required LocalDate origin}) {
    LocalDate clip(LocalDate s) => startDate != null && startDate!.isAfter(s) ? startDate! : s;
    switch (period) {
      case GoalPeriod.custom:
        return (start: startDate!, end: endDate);
      case GoalPeriod.allTime:
        return (start: startDate ?? origin, end: endDate);
      case GoalPeriod.year:
        return (start: clip(LocalDate(asOf.year, 1, 1)), end: LocalDate(asOf.year, 12, 31));
      case GoalPeriod.quarter:
        final firstMonth = ((asOf.month - 1) ~/ 3) * 3 + 1;
        final first = LocalDate(asOf.year, firstMonth, 1);
        return (start: clip(first), end: first.plusMonths(3).minusDays(1));
      case GoalPeriod.month:
        return (start: clip(asOf.firstDayOfMonth), end: asOf.lastDayOfMonth);
      case GoalPeriod.week:
        final first = asOf.startOfWeek(weekStart);
        return (start: clip(first), end: first.plusDays(6));
    }
  }

  Goal copyWith({
    GoalMetric? metric,
    double? target,
    GoalPeriod? period,
    Object? startDate = _keep,
    Object? endDate = _keep,
    Object? title = _keep,
    Object? reward = _keep,
    Object? achievedAt = _keep,
  }) => Goal(
    id: id,
    scopeType: scopeType,
    scopeId: scopeId,
    metric: metric ?? this.metric,
    target: target ?? this.target,
    period: period ?? this.period,
    startDate: identical(startDate, _keep) ? this.startDate : startDate as LocalDate?,
    endDate: identical(endDate, _keep) ? this.endDate : endDate as LocalDate?,
    title: identical(title, _keep) ? this.title : title as String?,
    reward: identical(reward, _keep) ? this.reward : reward as String?,
    achievedAt: identical(achievedAt, _keep) ? this.achievedAt : achievedAt as DateTime?,
    createdAt: createdAt,
  );

  static const Object _keep = Object();

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.scopeType == scopeType &&
      other.scopeId == scopeId &&
      other.metric == metric &&
      other.target == target &&
      other.period == period &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.title == title &&
      other.reward == reward &&
      other.achievedAt == achievedAt;

  @override
  int get hashCode =>
      Object.hash(id, scopeType, scopeId, metric, target, period, startDate, endDate, title, reward, achievedAt);

  @override
  String toString() => 'Goal($id, ${scopeType.name}:$scopeId, ${metric.wire} $target ${period.wire})';
}
