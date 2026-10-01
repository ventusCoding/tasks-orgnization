import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('badge predicates (T5.4.08)', () {
    test('global badges', () {
      expect(earnedBadges(), isEmpty);
      expect(earnedBadges(global: const GlobalBadgeFacts(anyCheckIn: true, anyPerfectDay: true)).map((b) => b.code), [
        AchievementCode.firstCheckIn,
        AchievementCode.firstPerfectDay,
      ]);
      expect(
        earnedBadges(global: const GlobalBadgeFacts(perfectWeek: true, backfillFreeMonth: true)).map((b) => b.code),
        [AchievementCode.perfectWeek, AchievementCode.backfillFreeMonth],
      );
    });

    test('streaks, totals and challenges per habit', () {
      final earned = earnedBadges(
        habits: const [
          HabitBadgeFacts('a', bestStreak: 31, totalVolume: 1200, challengeWon: true),
          HabitBadgeFacts('b', bestStreak: 6, totalVolume: 999),
        ],
      );
      expect(earned, [
        const EarnedBadge(AchievementCode.streak7, habitId: 'a'),
        const EarnedBadge(AchievementCode.streak30, habitId: 'a'),
        const EarnedBadge(AchievementCode.total1000, habitId: 'a'),
        const EarnedBadge(AchievementCode.challengeCompleted, habitId: 'a'),
      ]);
      expect(earned.first.value, 31);
    });

    test('quit milestones, savings and resisted cravings', () {
      final earned = earnedBadges(
        quits: const [QuitBadgeFacts('q', longestCleanDays: 30, moneySaved: 520, cravingsResisted: 50)],
      );
      expect(earned.map((b) => b.code), [
        AchievementCode.clean1,
        AchievementCode.clean7,
        AchievementCode.clean30,
        AchievementCode.saved100,
        AchievementCode.saved500,
        AchievementCode.cravingsResisted50,
      ]);
    });

    test('perfect week needs seven consecutive days; progress hints', () {
      expect(hasPerfectWeek([1, 2, 3, 4, 5, 6, 8]), isFalse);
      expect(hasPerfectWeek([10, 11, 12, 13, 14, 15, 16]), isTrue);
      expect(hasPerfectWeek([16, 10, 11, 12, 13, 14, 15, 15]), isTrue, reason: 'order and duplicates do not matter');
      expect(badgeProgress(AchievementCode.streak30, 15), 0.5);
      expect(badgeProgress(AchievementCode.streak30, 45), 1);
    });

    test('codes round-trip', () {
      for (final c in AchievementCode.values) {
        expect(AchievementCode.tryParse(c.wire), c);
      }
    });
  });
}
