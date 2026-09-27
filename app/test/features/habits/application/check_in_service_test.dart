import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/data/habit_sections_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  late CheckInService checkIns;
  late HabitPeriodService periods;

  CheckInService serviceFor(HabitPeriodService p) => CheckInService(
    logs: h.read(habitLogsRepositoryProvider),
    habits: h.read(habitsRepositoryProvider),
    periods: p,
    clock: h.clock,
  );

  setUp(() {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10), zone: 'Europe/Paris');
    periods = periodService(zone: 'Europe/Paris');
    checkIns = serviceFor(periods);
  });
  tearDown(() => h.dispose());

  Future<BuildHabit> create(BuildHabit habit) async {
    await h.read(habitsRepositoryProvider).create(habit);
    return habit;
  }

  Future<List<HabitLogEntry>> liveLogs(String habitId) => h.read(habitLogsRepositoryProvider).forHabit(habitId);

  Future<HabitSnapshot> snapshot(BuildHabit habit) async => computeSnapshot(
    periods,
    habit,
    await h.read(habitsRepositoryProvider).revisionsFor(habit.id),
    await liveLogs(habit.id),
    const [],
    h.clock.nowUtc(),
  );

  group('yes/no habits', () {
    test('one state row per period (deterministic id); switching updates kind; clear + redo revive it', () async {
      final habit = await create(buildHabit(id: Ids.v7(), start: d(2026, 9, 1)));
      await checkIns.markDone(habit, '2026-09-22');
      var logs = await liveLogs(habit.id);
      expect(logs.single.id, Ids.habitDayState(habit.id, '2026-09-22'));
      expect(logs.single.kind, HabitLogKind.done);
      expect(logs.single.loggedAt, h.clock.nowUtc());
      expect(logs.single.localDate, d(2026, 9, 22));
      await checkIns.markNotDone(habit, '2026-09-22');
      logs = await liveLogs(habit.id);
      expect(logs.single.kind, HabitLogKind.fail);
      await checkIns.clear(habit, '2026-09-22');
      expect(await liveLogs(habit.id), isEmpty);
      await checkIns.markDone(habit, '2026-09-22');
      expect((await liveLogs(habit.id)).single.kind, HabitLogKind.done);
      expect((await snapshot(habit)).todayResult?.status, PeriodStatus.done);
    });

    test('undo restores the exact prior state', () async {
      final habit = await create(buildHabit(id: Ids.v7(), start: d(2026, 9, 1)));
      await checkIns.markDone(habit, '2026-09-22');
      final result = await checkIns.skip(habit, '2026-09-22', note: 'Sick');
      expect((await liveLogs(habit.id)).single.note, 'Sick');
      await h.read(syncWriterProvider).revert(result.record);
      final log = (await liveLogs(habit.id)).single;
      expect(log.kind, HabitLogKind.done);
      expect(log.note, isNull);
    });

    test('guards: future done refused, planned skip allowed, archived read-only', () async {
      final habit = await create(buildHabit(id: Ids.v7(), start: d(2026, 9, 1)));
      await expectLater(checkIns.markDone(habit, '2026-09-24'), throwsA(isA<CheckInException>()));
      await checkIns.skip(habit, '2026-09-24', note: 'Travel');
      final planned = (await liveLogs(habit.id)).single;
      expect(planned.kind, HabitLogKind.skip);
      expect(planned.loggedAt, DateTime.utc(2026, 9, 24, 10), reason: 'planned periods use 12:00 local');
      final archived = habit.copyWith(archivedAt: DateTime.utc(2026, 9, 22));
      await expectLater(checkIns.markDone(archived, '2026-09-22'), throwsA(isA<CheckInException>()));
    });

    test('backfill: logged_at = the period date at 12:00 (or the chosen time); created_at is the real time', () async {
      final habit = await create(buildHabit(id: Ids.v7(), start: d(2026, 9, 1)));
      await checkIns.markDone(habit, '2026-09-15');
      await checkIns.markDone(habit, '2026-09-16', at: LocalTime(7, 30));
      final logs = await liveLogs(habit.id);
      expect(logs.map((l) => l.loggedAt), [DateTime.utc(2026, 9, 15, 10), DateTime.utc(2026, 9, 16, 5, 30)]);
      expect(logs.every((l) => l.createdAt == h.clock.nowUtc()), isTrue);
      final s = await snapshot(habit);
      expect(s.evaluation!.dayOn(d(2026, 9, 15))?.status, PeriodStatus.done);
    });
  });

  group('measurable habits', () {
    test('10 then 5 push-ups keep two entries; Done logs the remaining amount', () async {
      final habit = await create(
        buildHabit(id: Ids.v7(), start: d(2026, 9, 1), goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps')),
      );
      await checkIns.addProgress(habit, '2026-09-22', 10);
      h.clock.advance(const Duration(hours: 2));
      await checkIns.addProgress(habit, '2026-09-22', 5);
      var logs = await liveLogs(habit.id);
      expect(logs.map((l) => l.value), [10, 5]);
      expect(logs.map((l) => l.loggedAt).toSet(), hasLength(2));
      expect((await snapshot(habit)).todayResult?.status, PeriodStatus.done);

      await checkIns.addProgress(habit, '2026-09-21', 4);
      await checkIns.markDone(habit, '2026-09-21');
      logs = [for (final l in await liveLogs(habit.id)) if (l.localDate == d(2026, 9, 21)) l];
      expect(logs.map((l) => l.value), [4, 11]);
      await expectLater(checkIns.addProgress(habit, '2026-09-23', 3), throwsA(isA<CheckInException>()));
    });

    test('entries can be edited and deleted', () async {
      final habit = await create(
        buildHabit(id: Ids.v7(), start: d(2026, 9, 1), goal: const HabitTarget(type: HabitGoalType.duration, target: 20, unit: 'min')),
      );
      await checkIns.addProgress(habit, '2026-09-22', 10, durationSeconds: 600);
      var entry = (await liveLogs(habit.id)).single;
      expect(entry.durationSeconds, 600);
      await checkIns.updateEntry(entry, value: 12, note: ' felt good ', mood: 4);
      entry = (await liveLogs(habit.id)).single;
      expect((entry.value, entry.note, entry.mood), (12.0, 'felt good', 4));
      await checkIns.deleteEntry(entry);
      expect(await liveLogs(habit.id), isEmpty);
    });

    test('note & mood go on the state row, else on a period note row', () async {
      final yesNo = await create(buildHabit(id: Ids.v7(), start: d(2026, 9, 1)));
      await checkIns.setNoteAndMood(yesNo, '2026-09-22', note: 'Early', mood: 5);
      var logs = await liveLogs(yesNo.id);
      expect(logs.single.kind, HabitLogKind.note);
      await checkIns.markDone(yesNo, '2026-09-22');
      await checkIns.setNoteAndMood(yesNo, '2026-09-22', note: 'Done early', mood: 4);
      logs = await liveLogs(yesNo.id);
      final state = logs.firstWhere((l) => l.kind == HabitLogKind.done);
      expect((state.note, state.mood), ('Done early', 4));
    });
  });

  group('slots & zones', () {
    test('check now at 13:40 (tolerance 30) records the 14:00 slot; roll-up 2/3', () async {
      final habit = await create(
        buildHabit(
          id: Ids.v7(),
          start: d(2026, 9, 1),
          zone: 'UTC',
          schedule: RecurrenceRule(times: [LocalTime(8, 0), LocalTime(14, 0), LocalTime(20, 0)]),
        ),
      );
      h.clock.set(DateTime.utc(2026, 9, 22, 8, 5));
      await checkIns.checkNow(habit);
      h.clock.set(DateTime.utc(2026, 9, 22, 13, 40));
      final result = await checkIns.checkNow(habit);
      expect(result.target.key, '2026-09-22T14:00');
      final s = await snapshot(habit);
      expect((s.todayResult!.achieved, s.todayResult!.target), (2.0, 3.0));
      h.clock.set(DateTime.utc(2026, 9, 22, 7));
      await expectLater(checkIns.checkNow(habit), throwsA(isA<CheckInException>()));
    });

    test('dayStartsAt 04:00: a 01:00 check-in counts for the previous day (two zones)', () async {
      for (final zone in ['Europe/Paris', 'America/New_York']) {
        final p = periodService(zone: zone, dayStartMinutes: 240);
        final service = serviceFor(p);
        final habit = await create(buildHabit(id: Ids.v7(), start: d(2026, 9, 1)));
        // 01:00 local on Sept 23.
        final local = LocalDateTime.of(2026, 9, 23, 1);
        h.clock.set(TzZoneResolver().resolve(local, zone).utc);
        final result = await service.checkNow(habit);
        expect(result.target.key, '2026-09-22', reason: zone);
        final log = (await liveLogs(habit.id)).single;
        expect(log.localDate, d(2026, 9, 22));
        expect(log.loggedAt, h.clock.nowUtc());
      }
    });
  });

  group('quit trackers', () {
    late QuitService quit;
    late QuitHabit tracker;

    setUp(() async {
      quit = QuitService(logs: h.read(habitLogsRepositoryProvider), periods: periods, clock: h.clock);
      tracker = QuitHabit(
        id: Ids.v7(),
        name: 'Stop smoking',
        startDate: d(2026, 9, 21),
        sortKey: '',
        mode: QuitMode.abstain,
        quitStartedAt: DateTime.utc(2026, 9, 21, 19), // 21:00 Paris
        substance: QuitSubstance.cigarettes,
        baselinePerDay: 15,
        unitCost: Decimal.parse('0.5'),
        currency: 'EUR',
        lifeMinutesPerUnit: 20,
      );
      await h.read(habitsRepositoryProvider).create(tracker);
    });

    Future<QuitSnapshotView> view() async {
      final logs = await liveLogs(tracker.id);
      final calc = quitCalculatorOf(
        tracker,
        revisions: await h.read(habitsRepositoryProvider).revisionsFor(tracker.id),
        logs: logs,
        days: periods.boundariesOf(tracker),
        now: h.clock.nowUtc(),
      );
      return QuitSnapshotView(calc.currentAbstinence, calc.attempts.length, calc.moneySaved, logs);
    }

    test('"quit yesterday 21:00, 15/day, 0.50 each" shows live values immediately', () async {
      final v = await view();
      expect(v.current, const Duration(hours: 15));
      expect(v.attempts, 1);
      // 3 h of Sept 21 + 12 h of Sept 22 (Paris) → 15 × 15/24 = 9.375 units × 0.50.
      expect(v.money, Decimal.parse('4.6875'));
    });

    test('slip keeps the quit date; new attempt writes a restart; relapse 2 h ago moves the streak', () async {
      await quit.logRelapse(tracker, at: h.clock.nowUtc().subtract(const Duration(hours: 2)), amount: 2, trigger: 'stress');
      var v = await view();
      expect(v.current, const Duration(hours: 2));
      expect(v.attempts, 1);
      final relapse = v.logs.single;
      expect((relapse.kind, relapse.value, relapse.trigger), (HabitLogKind.relapse, 2.0, 'stress'));
      await quit.deleteLog(relapse);
      expect((await view()).current, const Duration(hours: 15), reason: 'deleting restores the previous streak');
      await quit.logRelapse(tracker, newAttempt: true);
      v = await view();
      expect(v.attempts, 2);
      expect(v.logs.map((l) => l.kind), [HabitLogKind.relapse, HabitLogKind.restart]);
    });

    test('craving in one tap, pledge converges, clean state per day', () async {
      final craving = await quit.logCraving(tracker);
      var logs = await liveLogs(tracker.id);
      expect((logs.single.kind, logs.single.intensity), (HabitLogKind.craving, 5));
      await quit.updateLog(logs.single, craving: const CravingInput(intensity: 8, resisted: true, durationSeconds: 180, coping: 'breathing'));
      logs = await liveLogs(tracker.id);
      expect((logs.single.intensity, logs.single.resisted, logs.single.durationSeconds), (8, true, 180));
      expect(craving.id, logs.single.id);
      await quit.pledge(tracker);
      await quit.pledge(tracker);
      logs = await liveLogs(tracker.id);
      expect(logs.where((l) => l.kind == HabitLogKind.pledge).single.id, Ids.habitPledge(tracker.id, '2026-09-22'));
      expect(pledgeStreak(logs, tracker.id, d(2026, 9, 22)), 1);
      await quit.markClean(tracker, d(2026, 9, 21));
      logs = await liveLogs(tracker.id);
      expect(logs.where((l) => l.kind == HabitLogKind.clean).single.id, Ids.habitDayState(tracker.id, '2026-09-21'));
    });

    test('reduce mode logs uses with amounts', () async {
      final reduce = tracker.copyWith(mode: QuitMode.reduce, dailyLimit: 5);
      await quit.logUse(reduce);
      await quit.logUse(reduce, amount: 2);
      final logs = await liveLogs(tracker.id);
      expect(logs.map((l) => (l.kind, l.value)), [(HabitLogKind.use, 1.0), (HabitLogKind.use, 2.0)]);
      await expectLater(quit.logUse(reduce, amount: 0), throwsArgumentError);
    });
  });

  test('duration timers survive an app kill and return their elapsed seconds', () async {
    final store = h.read(habitTimerStoreProvider);
    final t0 = DateTime.utc(2026, 9, 22, 10);
    await store.start('h', '2026-09-22', t0);
    await store.pause('h', '2026-09-22', t0.add(const Duration(minutes: 5)));
    await store.start('h', '2026-09-22', t0.add(const Duration(minutes: 10)));
    // A new store instance (app restart) reads the persisted state.
    final reopened = HabitTimerStore(h.db);
    final row = await reopened.read('h', '2026-09-22');
    expect(row!.elapsedSeconds(t0.add(const Duration(minutes: 13))), 8 * 60);
    expect(await reopened.stop('h', '2026-09-22', t0.add(const Duration(minutes: 13))), 8 * 60);
    expect(await reopened.read('h', '2026-09-22'), isNull);
  });
}

class QuitSnapshotView {
  QuitSnapshotView(this.current, this.attempts, this.money, this.logs);

  final Duration current;
  final int attempts;
  final Decimal money;
  final List<HabitLogEntry> logs;
}
