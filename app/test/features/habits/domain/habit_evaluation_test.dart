import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPeriodKind, PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/habit_fixtures.dart';

void main() {
  setUpAll(ensureTz);

  HabitEvaluation evaluate(
    BuildHabit habit,
    List<HabitLogEntry> logs, {
    required DateTime now,
    List<PauseSpan> pauses = const [],
    List<HabitRevision> revisions = const [],
    HabitPeriodService? service,
  }) {
    final s = service ?? periodService();
    final today = s.dateOf(habit, now);
    return evaluateHabit(
      habit: habit,
      periods: s.periods(habit, revisions, habit.startDate, today),
      logs: logs,
      pauses: pauses,
      now: now,
      today: today,
      boundaries: s.boundariesOf(habit),
    );
  }

  HabitSummary summary(HabitEvaluation e, {List<HabitRevision> revisions = const []}) =>
      summarizeHabit(e, rulesOn: (date) => periodService().rulesOn(e.habit, revisions, date));

  PeriodStatus? status(HabitEvaluation e, int day) => e.dayOn(d(2026, 9, day))?.status;

  DateTime at(int day, [int hour = 12]) => DateTime.utc(2026, 9, day, hour);

  group('build goals', () {
    test('15 push-ups every day: done (10 + 5), partial, missed, pending', () {
      final habit = buildHabit(
        start: d(2026, 9, 19),
        goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'),
      );
      final e = evaluate(habit, [
        log(HabitLogKind.progress, key: '2026-09-20', at: at(20, 8), value: 10),
        log(HabitLogKind.progress, key: '2026-09-20', at: at(20, 18), value: 5),
        log(HabitLogKind.progress, key: '2026-09-21', at: at(21), value: 10),
        log(HabitLogKind.progress, key: '2026-09-22', at: at(22, 9), value: 10),
      ], now: at(22, 20));
      expect(
        [for (var day = 19; day <= 22; day++) status(e, day)],
        [PeriodStatus.missed, PeriodStatus.done, PeriodStatus.partial, PeriodStatus.pending],
      );
      expect(e.dayOn(d(2026, 9, 20))!.entries, hasLength(2), reason: 'two entries keep their own times');
      expect(e.dayOn(d(2026, 9, 22))!.achieved, 10);
      expect(remainingToTarget(e.dayOn(d(2026, 9, 22))!), 5);
      final s = summary(e);
      expect(s.currentStreak, 0);
      expect(s.bestStreak, 1);
    });

    test('yes/no: explicit not done ≠ missed; skip and excuse are explicit', () {
      final habit = buildHabit(start: d(2026, 9, 17));
      final e = evaluate(habit, [
        log(HabitLogKind.done, key: '2026-09-17', at: at(17)),
        log(HabitLogKind.fail, key: '2026-09-18', at: at(18)),
        log(HabitLogKind.skip, key: '2026-09-19', at: at(19)),
        log(HabitLogKind.excuse, key: '2026-09-20', at: at(20)),
      ], now: at(22));
      expect(
        [for (var day = 17; day <= 22; day++) status(e, day)],
        [
          PeriodStatus.done,
          PeriodStatus.failed,
          PeriodStatus.skipped,
          PeriodStatus.excused,
          PeriodStatus.missed,
          PeriodStatus.pending,
        ],
      );
    });

    test('results do not depend on log insertion order; the latest statement wins', () {
      final habit = buildHabit(start: d(2026, 9, 20));
      final a = log(HabitLogKind.done, key: '2026-09-20', at: at(20, 8), id: 'a');
      final b = log(HabitLogKind.fail, key: '2026-09-20', at: at(20, 9), id: 'b');
      expect(status(evaluate(habit, [a, b], now: at(22)), 20), PeriodStatus.failed);
      expect(status(evaluate(habit, [b, a], now: at(22)), 20), PeriodStatus.failed);
    });

    test('limit ≤ 2 coffees: over the limit fails live; empty day is done unless explicit logs are required', () {
      final habit = buildHabit(
        start: d(2026, 9, 20),
        goal: const HabitTarget(type: HabitGoalType.count, target: 2, op: TargetOp.lte, unit: 'cups'),
      );
      final logs = [
        log(HabitLogKind.progress, key: '2026-09-20', at: at(20), value: 3),
        log(HabitLogKind.progress, key: '2026-09-22', at: at(22, 9), value: 1),
      ];
      var e = evaluate(habit, logs, now: at(22, 10));
      expect(
        [status(e, 20), status(e, 21), status(e, 22)],
        [PeriodStatus.failed, PeriodStatus.done, PeriodStatus.pending],
      );
      e = evaluate(habit, [
        ...logs,
        log(HabitLogKind.progress, key: '2026-09-22', at: at(22, 11), value: 2),
      ], now: at(22, 12));
      expect(status(e, 22), PeriodStatus.failed, reason: 'exceeding the limit flips today to failed immediately');
      final strict = buildHabit(
        start: d(2026, 9, 20),
        goal: habit.goal,
        settings: const HabitSettings(requireExplicitLog: true),
      );
      expect(status(evaluate(strict, logs, now: at(22, 10)), 21), PeriodStatus.missed);
    });

    test('skip policy "breaks" breaks streaks; frozen periods are neutral', () {
      final logs = [
        log(HabitLogKind.done, key: '2026-09-18', at: at(18)),
        log(HabitLogKind.skip, key: '2026-09-19', at: at(19)),
        log(HabitLogKind.done, key: '2026-09-20', at: at(20)),
        log(HabitLogKind.freeze, key: '2026-09-21', at: at(21)),
        log(HabitLogKind.done, key: '2026-09-22', at: at(22)),
      ];
      final neutral = evaluate(buildHabit(start: d(2026, 9, 18)), logs, now: at(22, 20));
      expect(status(neutral, 21), PeriodStatus.frozen);
      expect(summary(neutral).currentStreak, 3);
      final breaking = evaluate(
        buildHabit(start: d(2026, 9, 18), skipPolicy: SkipPolicy.breaks),
        logs,
        now: at(22, 20),
      );
      expect(summary(breaking).currentStreak, 2);
    });
  });

  group('pauses (T5.1.14)', () {
    test('a 20-day streak survives a 5-day vacation; done inside a pause still counts', () {
      final habit = buildHabit(start: d(2026, 9, 1));
      final logs = [
        for (var day = 1; day <= 20; day++)
          log(HabitLogKind.done, key: '2026-09-${day.toString().padLeft(2, '0')}', at: at(day)),
        log(HabitLogKind.done, key: '2026-09-23', at: at(23)),
        log(HabitLogKind.done, key: '2026-09-26', at: at(26)),
        log(HabitLogKind.done, key: '2026-09-27', at: at(27)),
      ];
      final vacation = PauseSpan(id: 'p', start: d(2026, 9, 21), end: d(2026, 9, 25));
      final e = evaluate(habit, logs, pauses: [vacation], now: at(27, 20));
      expect(status(e, 21), PeriodStatus.paused);
      expect(status(e, 23), PeriodStatus.done);
      expect(summary(e).currentStreak, 23);
      final other = PauseSpan(id: 'q', habitId: 'other', start: d(2026, 9, 21));
      expect(status(evaluate(habit, logs, pauses: [other], now: at(27, 20)), 21), PeriodStatus.missed);
    });
  });

  group('slots (T5.1.09)', () {
    final rule = RecurrenceRule(times: [LocalTime(8, 0), LocalTime(14, 0), LocalTime(20, 0)]);

    test('two of three slots → "2/3" pending today, partial when closed; min-N roll-up', () {
      final habit = buildHabit(start: d(2026, 9, 21), schedule: rule);
      final logs = [
        log(HabitLogKind.done, key: '2026-09-21T08:00', at: at(21, 8)),
        log(HabitLogKind.done, key: '2026-09-21T14:00', at: at(21, 14)),
        log(HabitLogKind.done, key: '2026-09-22T08:00', at: at(22, 8)),
        log(HabitLogKind.done, key: '2026-09-22T14:00', at: at(22, 14)),
      ];
      final e = evaluate(habit, logs, now: at(22, 15));
      final today = e.dayOn(d(2026, 9, 22))!;
      expect(today.status, PeriodStatus.pending);
      expect((today.achieved, today.target), (2.0, 3.0));
      expect(e.slotsOn(d(2026, 9, 22)).map((r) => slotChipState(r, at(22, 15))), [
        SlotChipState.done,
        SlotChipState.done,
        SlotChipState.upcoming,
      ]);
      expect(status(e, 21), PeriodStatus.partial);
      final relaxed = buildHabit(
        start: d(2026, 9, 21),
        schedule: rule,
        settings: const HabitSettings(slotRollup: SlotRollupMode.minSlots, minSlots: 2),
      );
      expect(status(evaluate(relaxed, logs, now: at(22, 15)), 21), PeriodStatus.done);
      expect(e.units.where((u) => u.kind == HabitPeriodKind.day), hasLength(2), reason: 'streaks use the day roll-up');
    });
  });

  group('quota (N× per week)', () {
    test('period progress, per-day view and at-risk flag', () {
      final habit = buildHabit(start: d(2026, 9, 14), schedule: RecurrenceRule.forQuota(3, PeriodUnit.week));
      final logs = [
        for (final day in [14, 16, 18])
          log(HabitLogKind.done, key: '2026-09-${day.toString().padLeft(2, '0')}', at: at(day)),
        log(HabitLogKind.done, key: '2026-09-21', at: at(21)),
      ];
      final e = evaluate(habit, logs, now: at(26, 12));
      expect(e.quotas.map((q) => (q.key, q.status)), [
        ('week:2026-09-14', PeriodStatus.done),
        ('week:2026-09-21', PeriodStatus.pending),
      ]);
      final current = e.quotaOn(d(2026, 9, 26))!;
      expect(current.flags.activeDays, 1);
      expect(current.flags.requiredDays, 3);
      expect(current.flags.atRisk, isFalse, reason: '2 completions needed, 2 eligible days left (Sat, Sun)');
      final sunday = evaluate(habit, logs, now: at(27, 12)).quotaOn(d(2026, 9, 27))!;
      expect(sunday.flags.atRisk, isTrue, reason: '2 completions needed, 1 eligible day left');
      expect(status(e, 21), PeriodStatus.done);
      expect(status(e, 22), PeriodStatus.notDue);
      expect(summary(e).currentStreak, 1);
    });
  });

  group('check-in rules (T5.2.01 / T5.2.06 / T5.2.08)', () {
    test('tap cycles', () {
      expect(TapCycle.doneNotDoneClear.next(null), CheckInState.done);
      expect(TapCycle.doneNotDoneClear.next(HabitLogKind.done), CheckInState.notDone);
      expect(TapCycle.doneNotDoneClear.next(HabitLogKind.fail), isNull);
      expect(TapCycle.doneSkipClear.next(HabitLogKind.done), CheckInState.skip);
      expect(TapCycle.doneSkipClear.next(HabitLogKind.skip), isNull);
      expect(TapCycle.doneClear.next(HabitLogKind.done), isNull);
      expect(TapCycle.doneClear.next(HabitLogKind.excuse), CheckInState.done);
      expect(TapCycle.parse('done_skip_clear'), TapCycle.doneSkipClear);
      expect(TapCycle.parse(null), TapCycle.doneNotDoneClear);
    });

    test('logged_at: now while open, noon or the slot time for backfills, chosen time wins', () {
      final s = periodService(zone: 'Europe/Paris');
      final habit = buildHabit(zone: null);
      final b = s.boundariesOf(habit);
      final now = DateTime.utc(2026, 9, 22, 10);
      final today = CheckInTarget.day(d(2026, 9, 22), b);
      expect(checkInInstant(today, now: now, boundaries: b), now);
      final lastTuesday = CheckInTarget.day(d(2026, 9, 15), b);
      expect(checkInInstant(lastTuesday, now: now, boundaries: b), DateTime.utc(2026, 9, 15, 10));
      expect(
        checkInInstant(lastTuesday, now: now, boundaries: b, chosenTime: LocalTime(7, 30)),
        DateTime.utc(2026, 9, 15, 5, 30),
      );
      final slotHabit = buildHabit(schedule: RecurrenceRule(times: [LocalTime(8, 0), LocalTime(20, 0)]));
      final slot = s.periodForKey(slotHabit, const [], '2026-09-20T20:00')!;
      final target = CheckInTarget.ofPeriod(slot, b);
      expect(target.slotTime, LocalTime(20, 0));
      expect(checkInInstant(target, now: now, boundaries: b), DateTime.utc(2026, 9, 20, 18));
    });

    test('guards: no done/progress in the future, planned skips allowed, archived read-only', () {
      final b = periodService().boundariesOf(buildHabit());
      final now = DateTime.utc(2026, 9, 22, 10);
      final tomorrow = CheckInTarget.day(d(2026, 9, 23), b);
      expect(
        checkInRefusal(target: tomorrow, now: now, archived: false, state: CheckInState.done),
        CheckInRefusal.future,
      );
      expect(checkInRefusal(target: tomorrow, now: now, archived: false, progress: true), CheckInRefusal.future);
      expect(checkInRefusal(target: tomorrow, now: now, archived: false, state: CheckInState.skip), isNull);
      expect(checkInRefusal(target: tomorrow, now: now, archived: false, state: CheckInState.excuse), isNull);
      final today = CheckInTarget.day(d(2026, 9, 22), b);
      expect(
        checkInRefusal(target: today, now: now, archived: true, state: CheckInState.done),
        CheckInRefusal.archived,
      );
      expect(checkInRefusal(target: today, now: now, archived: false, state: CheckInState.done), isNull);
    });

    test('localized decimal parsing (en, fr, ar)', () {
      expect(parseLocalizedDecimal('12.5'), 12.5);
      expect(parseLocalizedDecimal('12,5'), 12.5);
      expect(parseLocalizedDecimal('1 234,5'), 1234.5);
      expect(parseLocalizedDecimal('١٢٫٥'), 12.5);
      expect(parseLocalizedDecimal('۱۵'), 15);
      expect(parseLocalizedDecimal(''), isNull);
      expect(parseLocalizedDecimal('abc'), isNull);
    });
  });
}
