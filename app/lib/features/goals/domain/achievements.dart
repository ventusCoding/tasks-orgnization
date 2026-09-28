import 'package:meta/meta.dart';

/// What an achievement is about.
enum AchievementScope { global, habit }

/// Badge catalog (T5.4.08). Habit-scoped badges are earned per habit or quit tracker.
enum AchievementCode {
  firstCheckIn('first_check_in', AchievementScope.global),
  firstPerfectDay('first_perfect_day', AchievementScope.global),
  perfectWeek('perfect_week', AchievementScope.global),
  backfillFreeMonth('backfill_free_month', AchievementScope.global),
  streak7('streak_7', AchievementScope.habit, 7),
  streak30('streak_30', AchievementScope.habit, 30),
  streak100('streak_100', AchievementScope.habit, 100),
  streak365('streak_365', AchievementScope.habit, 365),
  total1000('total_1000', AchievementScope.habit, 1000),
  total10000('total_10000', AchievementScope.habit, 10000),
  challengeCompleted('challenge_completed', AchievementScope.habit),
  clean1('clean_1', AchievementScope.habit, 1),
  clean7('clean_7', AchievementScope.habit, 7),
  clean30('clean_30', AchievementScope.habit, 30),
  clean100('clean_100', AchievementScope.habit, 100),
  clean365('clean_365', AchievementScope.habit, 365),
  saved100('saved_100', AchievementScope.habit, 100),
  saved500('saved_500', AchievementScope.habit, 500),
  saved1000('saved_1000', AchievementScope.habit, 1000),
  cravingsResisted50('cravings_resisted_50', AchievementScope.habit, 50);

  const AchievementCode(this.wire, this.scope, [this.threshold = 1]);

  final String wire;
  final AchievementScope scope;

  /// The value to reach (streak days, total, clean days, money, resisted cravings).
  final num threshold;

  static AchievementCode? tryParse(String? value) {
    for (final c in values) {
      if (c.wire == value) return c;
    }
    return null;
  }
}

/// Facts about one build habit that badges read.
@immutable
class HabitBadgeFacts {
  const HabitBadgeFacts(this.habitId, {this.bestStreak = 0, this.totalVolume = 0, this.challengeWon = false});

  final String habitId;
  final int bestStreak;

  /// Σ logged values of a measurable habit (0 for yes/no habits).
  final double totalVolume;
  final bool challengeWon;
}

/// Facts about one quit tracker.
@immutable
class QuitBadgeFacts {
  const QuitBadgeFacts(this.habitId, {this.longestCleanDays = 0, this.moneySaved = 0, this.cravingsResisted = 0});

  final String habitId;

  /// Longest abstinence, in whole days.
  final int longestCleanDays;
  final double moneySaved;
  final int cravingsResisted;
}

/// Facts across every habit.
@immutable
class GlobalBadgeFacts {
  const GlobalBadgeFacts({
    this.anyCheckIn = false,
    this.anyPerfectDay = false,
    this.perfectWeek = false,
    this.backfillFreeMonth = false,
  });

  final bool anyCheckIn;
  final bool anyPerfectDay;

  /// Seven perfect days in a row.
  final bool perfectWeek;

  /// A closed calendar month with check-ins and none of them backfilled (logged > 24 h late).
  final bool backfillFreeMonth;
}

/// An earned badge (scope id null for global badges).
@immutable
class EarnedBadge {
  const EarnedBadge(this.code, {this.habitId, this.value});

  final AchievementCode code;
  final String? habitId;

  /// The value that earned it (payload).
  final num? value;

  @override
  bool operator ==(Object other) => other is EarnedBadge && other.code == code && other.habitId == habitId;

  @override
  int get hashCode => Object.hash(code, habitId);

  @override
  String toString() => 'EarnedBadge(${code.wire}, $habitId)';
}

/// Every badge the facts earn (pure; the unlock engine writes the missing ones).
List<EarnedBadge> earnedBadges({
  GlobalBadgeFacts global = const GlobalBadgeFacts(),
  List<HabitBadgeFacts> habits = const [],
  List<QuitBadgeFacts> quits = const [],
}) => [
  if (global.anyCheckIn) const EarnedBadge(AchievementCode.firstCheckIn),
  if (global.anyPerfectDay) const EarnedBadge(AchievementCode.firstPerfectDay),
  if (global.perfectWeek) const EarnedBadge(AchievementCode.perfectWeek),
  if (global.backfillFreeMonth) const EarnedBadge(AchievementCode.backfillFreeMonth),
  for (final h in habits) ...[
    for (final c in const [AchievementCode.streak7, AchievementCode.streak30, AchievementCode.streak100, AchievementCode.streak365])
      if (h.bestStreak >= c.threshold) EarnedBadge(c, habitId: h.habitId, value: h.bestStreak),
    for (final c in const [AchievementCode.total1000, AchievementCode.total10000])
      if (h.totalVolume >= c.threshold) EarnedBadge(c, habitId: h.habitId, value: h.totalVolume),
    if (h.challengeWon) EarnedBadge(AchievementCode.challengeCompleted, habitId: h.habitId),
  ],
  for (final q in quits) ...[
    for (final c in const [
      AchievementCode.clean1,
      AchievementCode.clean7,
      AchievementCode.clean30,
      AchievementCode.clean100,
      AchievementCode.clean365,
    ])
      if (q.longestCleanDays >= c.threshold) EarnedBadge(c, habitId: q.habitId, value: q.longestCleanDays),
    for (final c in const [AchievementCode.saved100, AchievementCode.saved500, AchievementCode.saved1000])
      if (q.moneySaved >= c.threshold) EarnedBadge(c, habitId: q.habitId, value: q.moneySaved),
    if (q.cravingsResisted >= AchievementCode.cravingsResisted50.threshold)
      EarnedBadge(AchievementCode.cravingsResisted50, habitId: q.habitId, value: q.cravingsResisted),
  ],
];

/// Progress hint toward a locked badge: value ÷ threshold (0…1).
double badgeProgress(AchievementCode code, num value) =>
    code.threshold <= 0 ? 0 : (value / code.threshold).clamp(0, 1).toDouble();

/// Seven consecutive perfect days among [perfectDays] (dates as day numbers since epoch).
bool hasPerfectWeek(Iterable<int> perfectDays) {
  final sorted = perfectDays.toSet().toList()..sort();
  var run = 0;
  int? previous;
  for (final d in sorted) {
    run = previous != null && d == previous + 1 ? run + 1 : 1;
    if (run >= 7) return true;
    previous = d;
  }
  return false;
}
