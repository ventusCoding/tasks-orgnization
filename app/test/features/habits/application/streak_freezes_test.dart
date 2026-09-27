import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/streak_freezes.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  // Monday 2026-10-12, 10:00 UTC.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 10, 12, 10)));
  tearDown(() => h.dispose());

  /// Daily habit since Sept 1 with one freeze a month, done every day up to yesterday except
  /// [misses].
  Future<BuildHabit> seed(List<LocalDate> misses, {int freezes = 1}) async {
    final habit = buildHabit(id: Ids.v7(), start: d(2026, 9, 1), freezesPerMonth: freezes).copyWith(sortKey: '');
    await h.read(habitsRepositoryProvider).create(habit);
    final checkIn = h.read(checkInServiceProvider);
    for (var day = d(2026, 9, 1); day.isBefore(d(2026, 10, 12)); day = day.plusDays(1)) {
      if (!misses.contains(day)) await checkIn.markDone(habit, day.toIso());
    }
    return habit;
  }

  Future<List<HabitLogEntry>> freezes(String habitId) async => [
    for (final l in await h.read(habitLogsRepositoryProvider).forHabit(habitId))
      if (l.kind == HabitLogKind.freeze) l,
  ];

  test('the first miss of each month is frozen; the second breaks the streak (T5.4.06)', () async {
    final habit = await seed([d(2026, 9, 5), d(2026, 9, 9), d(2026, 10, 3)]);
    expect(await h.read(streakFreezeJobProvider).run(), 2);
    final rows = await freezes(habit.id);
    expect(rows.map((r) => r.occurrenceKey), unorderedEquals(['2026-09-05', '2026-10-03']));
    for (final r in rows) {
      expect(r.id, HabitLogsRepository.stateId(habit.id, r.occurrenceKey!), reason: 'deterministic: devices converge');
      expect(r.source, LogSource.auto);
    }

    final snapshot = await loadHabitSnapshot(h.read, habit, h.clock.nowUtc());
    final e = snapshot.evaluation!;
    expect(e.dayOn(d(2026, 9, 5))!.status, PeriodStatus.frozen);
    expect(e.dayOn(d(2026, 9, 9))!.status, PeriodStatus.missed, reason: 'the September freeze is used up');
    expect(e.dayOn(d(2026, 10, 3))!.status, PeriodStatus.frozen, reason: 'a new month, a new freeze');
    // Sept 10 → Oct 11 (32 days) with Oct 3 frozen: 31 successful days in a row.
    expect(snapshot.summary!.currentStreak, 31);
  });

  test('the job is idempotent and skips habits without freezes', () async {
    final habit = await seed([d(2026, 10, 3)]);
    final noFreezes = await seed([d(2026, 10, 4)], freezes: 0);
    final job = h.read(streakFreezeJobProvider);
    expect(await job.run(), 1);
    expect(await job.run(), 0);
    expect(await freezes(habit.id), hasLength(1));
    expect(await freezes(noFreezes.id), isEmpty);
  });
}
