import 'package:everslot/core/providers.dart';
import 'package:everslot/features/goals/data/achievements_repository.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:everslot/features/habits/application/habit_celebrations.dart' show isPerfectDay;
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/challenge.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// How far back perfect days and backfill-free months are looked for.
const badgeLookbackDays = 400;

/// A log written more than this after the moment it records is a backfill (T5.2.08).
const backfillDelay = Duration(hours: 24);

final achievementsRepositoryProvider = Provider<AchievementsRepository>(
  (ref) => AchievementsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Unlocked badges, newest first (gallery).
final unlockedBadgesProvider = StreamProvider<List<UnlockedBadge>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(achievementsRepositoryProvider).watchAll();
});

/// The unlock engine (T5.4.08): gathers facts from every habit's snapshot and writes the badges
/// they earn that are not unlocked yet. Cheap enough to run after check-ins and at start-up;
/// deterministic ids make repeated runs and several devices converge on one row per badge.
class AchievementService {
  AchievementService(this._read);

  final T Function<T>(ProviderListenable<T> provider) _read;

  /// Facts of every active habit and tracker as of now. The 400-day scans for perfect days and
  /// backfill-free months can be skipped once their badges are unlocked.
  Future<({GlobalBadgeFacts global, List<HabitBadgeFacts> habits, List<QuitBadgeFacts> quits})> facts({
    bool scanPerfectDays = true,
    bool scanBackfills = true,
  }) async {
    final all = await _read(habitsRepositoryProvider).all(includeArchived: false);
    final now = _read(clockProvider).nowUtc();
    final service = _read(habitPeriodServiceProvider);
    final builds = <HabitSnapshot>[];
    final habits = <HabitBadgeFacts>[];
    final quits = <QuitBadgeFacts>[];
    for (final h in all) {
      final s = await loadHabitSnapshot(_read, h, now);
      switch (h) {
        case BuildHabit():
          builds.add(s);
          final challenge = s.evaluation == null ? null : challengeOutcome(h, s.evaluation!, today: s.today);
          habits.add(
            HabitBadgeFacts(
              h.id,
              bestStreak: s.summary?.bestStreak ?? 0,
              totalVolume: h.goal.isMeasurable ? s.summary?.volume ?? 0 : 0,
              challengeWon: challenge != null && challenge.finished && challenge.success,
            ),
          );
        case QuitHabit():
          final calc = s.quit;
          if (calc == null) continue;
          quits.add(
            QuitBadgeFacts(
              h.id,
              longestCleanDays: calc.longestAbstinence.inDays,
              moneySaved: calc.moneySaved.toDouble(),
              cravingsResisted: s.logs.where((l) => l.kind == HabitLogKind.craving && l.resisted == true).length,
            ),
          );
      }
    }
    return (
      global: _globalFacts(builds, service, scanPerfectDays: scanPerfectDays, scanBackfills: scanBackfills),
      habits: habits,
      quits: quits,
    );
  }

  GlobalBadgeFacts _globalFacts(
    List<HabitSnapshot> builds,
    HabitPeriodService service, {
    required bool scanPerfectDays,
    required bool scanBackfills,
  }) {
    if (builds.isEmpty) return const GlobalBadgeFacts();
    final today = builds.first.today;
    final anyCheckIn = builds.any((s) => (s.summary?.repetitions ?? 0) > 0);
    final origin = today.minusDays(badgeLookbackDays);
    final perfect = <int>[];
    for (var i = scanPerfectDays ? badgeLookbackDays : -1; i >= 0; i--) {
      final date = today.minusDays(i);
      final views = [
        for (final s in builds)
          if (habitDayView(s, date, service) case final v?) v,
      ];
      if (isPerfectDay(views)) perfect.add(origin.daysUntil(date));
    }
    return GlobalBadgeFacts(
      anyCheckIn: anyCheckIn,
      anyPerfectDay: perfect.isNotEmpty,
      perfectWeek: hasPerfectWeek(perfect),
      backfillFreeMonth: scanBackfills && _backfillFreeMonth(builds, today),
    );
  }

  /// A closed calendar month (within the look-back) with check-ins, none of them backfilled.
  static bool _backfillFreeMonth(List<HabitSnapshot> builds, LocalDate today) {
    final thisMonth = today.firstDayOfMonth;
    final byMonth = <LocalDate, ({int count, bool backfilled})>{};
    for (final s in builds) {
      for (final l in s.logs) {
        if (l.kind != HabitLogKind.done && l.kind != HabitLogKind.progress) continue;
        final month = l.localDate.firstDayOfMonth;
        if (!month.isBefore(thisMonth) || l.localDate.isBefore(today.minusDays(badgeLookbackDays))) continue;
        final created = l.createdAt;
        final late = created != null && created.difference(l.loggedAt) > backfillDelay;
        final prev = byMonth[month] ?? (count: 0, backfilled: false);
        byMonth[month] = (count: prev.count + 1, backfilled: prev.backfilled || late);
      }
    }
    return byMonth.values.any((m) => m.count > 0 && !m.backfilled);
  }

  Future<List<EarnedBadge>>? _running;

  /// Writes the newly earned badges; returns them. Concurrent calls share one run.
  Future<List<EarnedBadge>> evaluate() => _running ??= _evaluate().whenComplete(() => _running = null);

  Future<List<EarnedBadge>> _evaluate() async {
    final repo = _read(achievementsRepositoryProvider);
    final unlocked = {for (final b in await repo.all()) b.code};
    final f = await facts(
      scanPerfectDays:
          !unlocked.contains(AchievementCode.firstPerfectDay) || !unlocked.contains(AchievementCode.perfectWeek),
      scanBackfills: !unlocked.contains(AchievementCode.backfillFreeMonth),
    );
    final earned = earnedBadges(global: f.global, habits: f.habits, quits: f.quits);
    return repo.unlockMissing(earned, _read(clockProvider).nowUtc());
  }
}

final achievementServiceProvider = Provider<AchievementService>((ref) => AchievementService(ref.read));
