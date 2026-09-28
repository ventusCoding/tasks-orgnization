import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/goals/application/achievement_service.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../habits/support/habit_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  // Thursday 2026-10-08, 10:00 UTC.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 10, 8, 10)));
  tearDown(() => h.dispose());

  Future<BuildHabit> habit({String name = 'Meditate'}) async {
    final b = BuildHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, 1),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: buildHabit().schedule,
    );
    await h.read(habitsRepositoryProvider).create(b);
    return b;
  }

  Future<void> doneDays(BuildHabit b, int count, {LocalDateLike from = const LocalDateLike(9, 1)}) async {
    final checkIn = h.read(checkInServiceProvider);
    var day = d(2026, from.month, from.day);
    for (var i = 0; i < count; i++) {
      await checkIn.markDone(b, day.toIso());
      day = day.plusDays(1);
    }
  }

  test('unlocks streak, check-in, perfect-day and week badges once (T5.4.08)', () async {
    final b = await habit();
    // Sept 1 → Oct 7: 37 days in a row; every day is a perfect day (only habit).
    await doneDays(b, 37);
    final service = h.read(achievementServiceProvider);
    final first = await service.evaluate();
    expect(first.map((e) => e.code), containsAll([
      AchievementCode.firstCheckIn,
      AchievementCode.firstPerfectDay,
      AchievementCode.perfectWeek,
      AchievementCode.streak7,
      AchievementCode.streak30,
    ]));
    expect(first.map((e) => e.code), isNot(contains(AchievementCode.streak100)));
    expect(await service.evaluate(), isEmpty, reason: 'idempotent');
    final rows = await h.read(achievementsRepositoryProvider).all();
    expect(rows.length, first.length);
    final streak30 = rows.firstWhere((r) => r.code == AchievementCode.streak30);
    expect(streak30.id, Ids.achievement('streak_30', 'habit', b.id), reason: 'deterministic id');
    expect(streak30.value, 37);
  });

  test('backfilled check-ins do not earn the backfill-free month', () async {
    final b = await habit();
    // September logged in real time (created at the logged time)...
    for (var day = 1; day <= 30; day++) {
      h.clock.set(DateTime.utc(2026, 9, day, 12));
      await h.read(checkInServiceProvider).markDone(b, '2026-09-${day.toString().padLeft(2, '0')}');
    }
    h.clock.set(DateTime.utc(2026, 10, 8, 10));
    expect((await h.read(achievementServiceProvider).facts()).global.backfillFreeMonth, isTrue);
  });

  test('a month logged afterwards (backfill) does not count', () async {
    final b = await habit();
    await doneDays(b, 30); // all written on Oct 8: backfills
    expect((await h.read(achievementServiceProvider).facts()).global.backfillFreeMonth, isFalse);
  });

  test('quit badges: clean days, savings and resisted cravings', () async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: 'Stop smoking',
      startDate: d(2026, 9, 1),
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 1),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 20,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
    );
    await h.read(habitsRepositoryProvider).create(tracker);
    await h.read(quitServiceProvider).logCraving(tracker, input: const CravingInput(resisted: true));
    final f = await h.read(achievementServiceProvider).facts();
    final q = f.quits.single;
    expect((q.longestCleanDays, q.cravingsResisted), (37, 1));
    expect(q.moneySaved, closeTo(37 * 10 + 10 * 10 / 24, 1e-6));
    final earned = await h.read(achievementServiceProvider).evaluate();
    expect(earned.map((e) => e.code), [
      AchievementCode.clean1,
      AchievementCode.clean7,
      AchievementCode.clean30,
      AchievementCode.saved100,
    ]);
  });
}

/// A September/October 2026 date (fixture helper).
class LocalDateLike {
  const LocalDateLike(this.month, this.day);

  final int month;
  final int day;
}
