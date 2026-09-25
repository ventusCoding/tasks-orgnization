import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:test/test.dart';

/// The barrel exposes the whole public API without name clashes (compile-time check) and a typical
/// app call path works through it.
void main() {
  test('barrel exports compose end to end', () {
    const clock = FixedOffsetClock(120);
    const bounds = DayBoundaries(clock);
    final period = const StatsPeriod.thisWeek().resolve(
      today: LocalDate(2026, 9, 23),
    );
    final results = evaluateHabitPeriods(
      [
        for (final date in period.toDate.dates)
          HabitPeriod(
            date.toIso(),
            kind: HabitPeriodKind.day,
            startDate: date,
            endDate: date,
            windowStart: bounds.startOf(date),
            windowEnd: bounds.endOf(date),
            goal: const HabitGoal.check(),
          ),
      ],
      [
        HabitLog(
          'a',
          HabitLogKind.done,
          loggedAt: bounds
              .startOf(LocalDate(2026, 9, 21))
              .add(const Duration(hours: 8)),
          localDate: LocalDate(2026, 9, 21),
        ),
      ],
      now: bounds
          .startOf(LocalDate(2026, 9, 23))
          .add(const Duration(hours: 12)),
      today: LocalDate(2026, 9, 23),
    );
    expect(successRate(results).valueOrNull, 0.5);
    expect(habitStreaks(results).currentLength, 0);
    final value = MetricValue.fromStat(
      'HB-H-05',
      successRate(results),
      unit: MetricUnit.percent,
    );
    expect(value.value, 0.5);
    expect(Weekday.monday.code, 'MO');
  });
}
