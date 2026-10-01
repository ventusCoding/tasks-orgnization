import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/occurrence_ledger.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/quit_calculator.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/status_intervals.dart';
import 'package:everslot_metrics/src/streaks.dart';
import 'package:everslot_metrics/src/strength.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:test/test.dart';

import 'support/support.dart';

void main() {
  test('Wilson intervals (T6.1.03)', () {
    final w0 = wilsonInterval(0, 10)!;
    expect(w0.lower, near(0, 1e-3));
    expect(w0.upper, near(0.278, 1e-3));
    final w10 = wilsonInterval(10, 10)!;
    expect(w10.lower, near(0.722, 1e-3));
    expect(w10.upper, near(1, 1e-3));
    final w5 = wilsonInterval(5, 10)!;
    expect(w5.lower, near(0.237, 1e-3));
    expect(w5.upper, near(0.763, 1e-3));
  });

  test('Loop strength acceptance (T6.1.10)', () {
    final start = d('2026-01-01');
    final days = [
      for (var i = 0; i < 90; i++) StrengthDay(start.plusDays(i), value: 1, frequency: const StrengthFrequency.daily()),
    ];
    final r = computeStrength(days);
    expect(r.series[12].score, near(0.5, 1e-3));
    expect(r.series[29].score, near(0.798, 1e-3));
    expect(r.series[59].score, near(0.959, 1e-3));
    expect(r.series[89].score, near(0.992, 1e-3));
    expect(strengthMultiplier(0.375), near(0.967876, 1e-6));
  });

  test('streak acceptance D D S D X D M D (T6.1.09)', () {
    const pattern = 'DDSDXDMD';
    final start = d('2026-09-01');
    final units = [
      for (var i = 0; i < pattern.length; i++)
        StreakUnit(
          'u$i',
          start: start.plusDays(i),
          end: start.plusDays(i),
          kind: switch (pattern[i]) {
            'D' => StreakUnitKind.success,
            'M' => StreakUnitKind.breaks,
            _ => StreakUnitKind.neutral,
          },
          freezable: pattern[i] == 'M',
        ),
    ];
    final s = computeStreaks(units);
    expect(s.currentLength, 1);
    expect(s.bestLength, 4);
    expect(s.best!.calendarSpanDays, 6);
  });

  test('ledger weekly-rule acceptance (T6.1.08)', () {
    final clock = tzClock('Europe/Paris');
    final bounds = DayBoundaries(clock);
    final now = at(clock, '2026-09-30T23:00');
    final dates = [
      '2026-09-01', '2026-09-07', '2026-09-08', '2026-09-14', '2026-09-15', //
      '2026-09-21', '2026-09-22', '2026-09-28', '2026-09-29',
    ].map(d).toList();
    final paused = {d('2026-09-14'), d('2026-09-15')};
    final done = {
      d('2026-09-01'), d('2026-09-07'), d('2026-09-08'), //
      d('2026-09-21'), d('2026-09-22'), d('2026-09-28'),
    };
    final units = [
      for (final date in dates)
        LedgerUnit(
          date.toIso(),
          start: bounds.startOf(date),
          end: bounds.endOf(date),
          state: paused.contains(date) ? LedgerState.paused : LedgerState.open,
        ),
    ];
    final ledger = buildLedger(
      units,
      now: now,
      completions: [for (final date in done) LedgerCompletion(bounds.startOf(date).add(const Duration(hours: 9)))],
    );
    expect(ledger.expected, 9);
    expect(ledger.excused, 2);
    expect(ledger.done, 6);
    expect(ledger.missed, 1);
    expect(ledger.adherence.valueOrNull, near(6 / 7));
    expect(quotaExpectation(3, eligibleDays: 4, periodDays: 7), near(1.714, 1e-3));
  });

  test('CFD 5-day fixture (T6.4.05)', () {
    final clock = tzClock('Europe/Paris');
    final day = [for (var i = 1; i <= 5; i++) d('2026-09-0$i')];
    DateTime t(int dayIndex, int hour) =>
        at(clock, '${day[dayIndex - 1].toIso()}T${hour.toString().padLeft(2, '0')}:00');
    StatusEvent created(String id, int dd) =>
        StatusEvent(id, StatusEventType.created, occurredAt: t(dd, 9), to: 'todo');
    StatusEvent change(String id, int dd, int h, String from, String to) =>
        StatusEvent(id, StatusEventType.statusChanged, occurredAt: t(dd, h), from: from, to: to);
    final events = [
      created('A', 1),
      created('B', 1),
      created('C', 1),
      change('A', 1, 10, 'todo', 'ongoing'),
      change('A', 2, 10, 'ongoing', 'completed'),
      change('B', 2, 11, 'todo', 'ongoing'),
      created('D', 2),
      change('B', 3, 10, 'ongoing', 'blocked'),
      change('C', 3, 11, 'todo', 'ongoing'),
      change('A', 3, 12, 'completed', 'ongoing'),
      change('B', 4, 10, 'blocked', 'ongoing'),
      change('A', 4, 11, 'ongoing', 'completed'),
      created('E', 4),
      StatusEvent('D', StatusEventType.deleted, occurredAt: t(4, 12)),
      change('B', 5, 10, 'ongoing', 'completed'),
      change('C', 5, 11, 'ongoing', 'waiting'),
    ];
    final timelines = buildTimelines(events);
    final bounds = DayBoundaries(clock);
    final counts = boundaryCounts(timelines.values, [for (final x in day) bounds.endOf(x)]);
    List<int> bands(BoundaryCounts c) => [
      for (final s in ['todo', 'ongoing', 'waiting', 'blocked', 'completed']) c.byStatus[s] ?? 0,
    ];
    expect(counts.map(bands).toList(), [
      [2, 1, 0, 0, 0],
      [2, 1, 0, 0, 1],
      [1, 2, 0, 1, 0],
      [1, 2, 0, 0, 1],
      [1, 0, 1, 0, 2],
    ]);
    expect(timelines.values.fold<int>(0, (a, e) => a + e.reopenCount()), 1);
  });

  test('quit smoking acceptance (T6.6.02–04)', () {
    final clock = tzClock('Europe/Paris');
    final tracker = QuitTracker(
      at(clock, '2026-06-01T00:00'),
      mode: QuitMode.abstain,
      days: DayBoundaries(clock),
      baselinePerDay: 20,
      unitCost: Decimal.parse('0.60'),
      revisions: [
        QuitRevision(d('2026-06-01'), baselinePerDay: 20, unitCost: Decimal.parse('0.60')),
        QuitRevision(d('2026-07-01'), baselinePerDay: 20, unitCost: Decimal.parse('0.65')),
      ],
      lifeMinutesPerUnit: 20,
    );
    final calc = QuitCalculator(tracker, [
      QuitLog(
        'r1',
        HabitLogKind.relapse,
        loggedAt: at(clock, '2026-06-20T18:00'),
        localDate: d('2026-06-20'),
        value: 3,
      ),
    ], now: at(clock, '2026-07-31T00:00'));
    expect(calc.timeSinceQuit, const Duration(days: 60));
    expect(calc.currentAbstinence, const Duration(days: 40, hours: 6));
    expect(calc.longestAbstinence, const Duration(days: 40, hours: 6));
    expect(calc.cleanDays, 59);
    expect(calc.cleanDayShare.valueOrNull, near(59 / 60));
    expect(calc.unitsAvoided, near(1197));
    expect(calc.moneySaved, Decimal.parse('748.2'));
    expect(calc.moneySpent, Decimal.parse('1.8'));
    expect(calc.savingsProjection!.nextYear, Decimal.parse('4745'));
    expect(calc.lifeRegainedMinutes, near(23940));
  });

  test('period evaluation: pushups partial and limit failure', () {
    final clock = tzClock('Europe/Paris');
    final b = DayBoundaries(clock);
    final date = d('2026-09-10');
    final period = HabitPeriod(
      date.toIso(),
      kind: HabitPeriodKind.day,
      startDate: date,
      endDate: date,
      windowStart: b.startOf(date),
      windowEnd: b.endOf(date),
      goal: const HabitGoal(HabitGoalType.count, target: 15),
    );
    final r = evaluateHabitPeriod(
      period,
      [HabitLog('l1', HabitLogKind.progress, loggedAt: at(clock, '2026-09-10T08:00'), localDate: date, value: 10)],
      now: at(clock, '2026-09-11T08:00'),
      today: d('2026-09-11'),
    );
    expect(r.status, PeriodStatus.partial);
    expect(r.fulfilment, near(10 / 15));
    expect(LocalTime(4, 0).minuteOfDay, 240);
  });
}
