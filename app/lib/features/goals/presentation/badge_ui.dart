import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:material_ui/material_ui.dart';

/// Localized name of a badge ([currency] formats the savings badges).
String badgeName(BuildContext context, AchievementCode code, {String? currency}) {
  final l = context.l10n;
  final fmt = AppFormat(context.localeName, l10n: l);
  return switch (code) {
    AchievementCode.firstCheckIn => l.goalsBadgeFirstCheckIn,
    AchievementCode.firstPerfectDay => l.goalsBadgeFirstPerfectDay,
    AchievementCode.perfectWeek => l.goalsBadgePerfectWeek,
    AchievementCode.backfillFreeMonth => l.goalsBadgeBackfillFreeMonth,
    AchievementCode.streak7 ||
    AchievementCode.streak30 ||
    AchievementCode.streak100 ||
    AchievementCode.streak365 => l.goalsBadgeStreak(code.threshold.toInt()),
    AchievementCode.total1000 || AchievementCode.total10000 => l.goalsBadgeTotal(fmt.number(code.threshold)),
    AchievementCode.challengeCompleted => l.goalsBadgeChallenge,
    AchievementCode.clean1 ||
    AchievementCode.clean7 ||
    AchievementCode.clean30 ||
    AchievementCode.clean100 ||
    AchievementCode.clean365 => l.quitMilestoneDays(code.threshold.toInt()),
    AchievementCode.saved100 || AchievementCode.saved500 || AchievementCode.saved1000 => l.quitNotifMoneyMilestone(
      currency == null ? fmt.number(code.threshold) : fmt.currency(code.threshold, currency),
    ),
    AchievementCode.cravingsResisted50 => l.goalsBadgeCravings(code.threshold.toInt()),
  };
}

/// Icon of a badge.
IconData badgeIcon(AchievementCode code) => switch (code) {
  AchievementCode.firstCheckIn => Icons.check_circle,
  AchievementCode.firstPerfectDay || AchievementCode.perfectWeek => Icons.emoji_events,
  AchievementCode.backfillFreeMonth => Icons.event_available,
  AchievementCode.streak7 ||
  AchievementCode.streak30 ||
  AchievementCode.streak100 ||
  AchievementCode.streak365 => Icons.local_fire_department,
  AchievementCode.total1000 || AchievementCode.total10000 => Icons.stacked_bar_chart,
  AchievementCode.challengeCompleted => Icons.flag,
  AchievementCode.clean1 ||
  AchievementCode.clean7 ||
  AchievementCode.clean30 ||
  AchievementCode.clean100 ||
  AchievementCode.clean365 => Icons.smoke_free,
  AchievementCode.saved100 || AchievementCode.saved500 || AchievementCode.saved1000 => Icons.savings,
  AchievementCode.cravingsResisted50 => Icons.shield,
};
