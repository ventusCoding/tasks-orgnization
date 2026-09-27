import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/today/domain/habits_due.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitLogKind, PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final service = HabitPeriodService(
    engine: RecurrenceEngine(TzZoneResolver()),
    currentZone: 'UTC',
    dayStartsAt: LocalTime.midnight,
    weekStart: Weekday.monday,
  );
  final today = LocalDate(2026, 9, 22); // Tuesday
  var seq = 0;

  BuildHabit habit(RecurrenceRule schedule, {HabitTarget goal = const HabitTarget.check()}) => BuildHabit(
    id: 'h',
    name: 'Habit',
    startDate: LocalDate(2026, 9, 1),
    sortKey: 'a0',
    goal: goal,
    schedule: schedule,
  );

  HabitLogEntry log(HabitLogKind kind, String key, DateTime at, {double? value}) => HabitLogEntry(
    id: 'l${seq++}',
    habitId: 'h',
    kind: kind,
    loggedAt: at,
    localDate: LocalDate.parse(key.substring(0, 10)),
    occurrenceKey: key,
    value: value,
  );

  TodayHabitEntry? entry(
    BuildHabit h, {
    List<HabitLogEntry> logs = const [],
    List<PauseSpan> pauses = const [],
    DateTime? now,
  }) {
    final at = now ?? DateTime.utc(2026, 9, 22, 10);
    final evaluation = evaluateHabit(
      habit: h,
      periods: service.periods(h, const [], h.startDate, today),
      logs: logs,
      pauses: pauses,
      now: at,
      today: today,
      boundaries: service.boundariesOf(h),
    );
    HabitLogKind? stateOf(String key) {
      HabitLogEntry? best;
      for (final l in logs) {
        if (l.occurrenceKey == key && l.kind.isState && (best == null || l.loggedAt.isAfter(best.loggedAt))) best = l;
      }
      return best?.kind;
    }

    return todayHabitEntry(habit: h, evaluation: evaluation, today: today, now: at, stateOf: stateOf);
  }

  test('daily yes/no: due and pending, then resolved with its explicit state', () {
    final daily = habit(RecurrenceRule());
    final open = entry(daily)!;
    expect(open.checkInKey, '2026-09-22');
    expect(open.resolved, isFalse);
    expect(open.progress, 0);
    final done = entry(daily, logs: [log(HabitLogKind.done, '2026-09-22', DateTime.utc(2026, 9, 22, 8))])!;
    expect(done.resolved, isTrue);
    expect(done.explicitState, HabitLogKind.done);
    expect(done.progress, 1);
    expect(allHabitsDone([done]), isTrue);
    expect(allHabitsDone([done, open]), isFalse);
  });

  test('a weekly habit is not due on other weekdays', () {
    final mondays = habit(RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday)]));
    expect(entry(mondays), isNull);
    final tuesdays = habit(RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.tuesday)]));
    expect(entry(tuesdays), isNotNull);
  });

  test('quota 3× per week: due until met, listed on a day with a log', () {
    final quota = habit(RecurrenceRule.forQuota(3, PeriodUnit.week));
    final none = entry(quota)!;
    expect(none.isQuota, isTrue);
    expect(none.quota?.key, 'week:2026-09-21');
    expect(none.checkInKey, '2026-09-22');
    expect(none.progress, 0);
    expect(none.resolved, isFalse);

    // Two completions earlier this week (Sunday of the previous week doesn't count).
    final two = entry(
      quota,
      logs: [
        log(HabitLogKind.done, '2026-09-20', DateTime.utc(2026, 9, 20, 9)),
        log(HabitLogKind.done, '2026-09-21', DateTime.utc(2026, 9, 21, 9)),
      ],
    )!;
    expect(two.progress, closeTo(1 / 3, 1e-9));
    expect(two.resolved, isFalse);

    // Several units on one day are one completion day.
    final oneDay = entry(
      quota,
      logs: [
        for (var i = 0; i < 3; i++) log(HabitLogKind.progress, '2026-09-21', DateTime.utc(2026, 9, 21, 9, i), value: 1),
      ],
    )!;
    expect(oneDay.progress, closeTo(1 / 3, 1e-9));
    expect(oneDay.resolved, isFalse);

    // A completion today keeps the habit listed (so it can be undone) and resolves the day.
    final today2 = entry(
      quota,
      logs: [
        log(HabitLogKind.done, '2026-09-19', DateTime.utc(2026, 9, 19, 9)), // previous week
        log(HabitLogKind.done, '2026-09-21', DateTime.utc(2026, 9, 21, 9)),
        log(HabitLogKind.done, '2026-09-22', DateTime.utc(2026, 9, 22, 9)),
      ],
    )!;
    expect(today2.quota?.status, PeriodStatus.pending);
    expect(today2.progress, closeTo(2 / 3, 1e-9));
    expect(today2.day?.status, PeriodStatus.done);
    expect(today2.explicitState, HabitLogKind.done);
    expect(today2.resolved, isTrue);
  });

  test('a quota met on earlier days hides the habit; met today keeps it listed', () {
    final weekly = habit(RecurrenceRule.forQuota(1, PeriodUnit.week));
    expect(entry(weekly, logs: [log(HabitLogKind.done, '2026-09-21', DateTime.utc(2026, 9, 21, 9))]), isNull);
    final twice = habit(RecurrenceRule.forQuota(2, PeriodUnit.week));
    final metToday = entry(
      twice,
      logs: [
        log(HabitLogKind.done, '2026-09-21', DateTime.utc(2026, 9, 21, 9)),
        log(HabitLogKind.done, '2026-09-22', DateTime.utc(2026, 9, 22, 7)),
      ],
    )!;
    expect(metToday.quota?.status, PeriodStatus.done);
    expect(metToday.progress, 1);
    expect(metToday.resolved, isTrue);
  });

  test('intraday slots: the current slot is targeted, none before the first slot', () {
    final slots = habit(RecurrenceRule(times: [LocalTime(8, 0), LocalTime(12, 0), LocalTime(20, 0)]));
    final mid = entry(slots, now: DateTime.utc(2026, 9, 22, 10))!;
    expect(mid.isSlotHabit, isTrue);
    expect(mid.slots, hasLength(3));
    expect(mid.checkInKey, '2026-09-22T08:00');
    expect(mid.nextSlot?.key, '2026-09-22T12:00');
    final early = entry(slots, now: DateTime.utc(2026, 9, 22, 6))!;
    expect(early.checkInKey, isNull);
    expect(early.nextSlot?.key, '2026-09-22T08:00');
    final one = entry(
      slots,
      logs: [log(HabitLogKind.done, '2026-09-22T08:00', DateTime.utc(2026, 9, 22, 8, 5))],
    )!;
    expect(one.progress, closeTo(1 / 3, 1e-9));
    expect(one.resolved, isFalse);
  });

  test('paused days and archived habits are not due', () {
    final daily = habit(RecurrenceRule());
    expect(entry(daily, pauses: [PauseSpan(id: 'p', start: LocalDate(2026, 9, 20))]), isNull);
    expect(
      todayHabitEntry(
        habit: daily.copyWith(archivedAt: DateTime.utc(2026, 9, 21)),
        evaluation: evaluateHabit(
          habit: daily,
          periods: service.periods(daily, const [], daily.startDate, today),
          logs: const [],
          pauses: const [],
          now: DateTime.utc(2026, 9, 22, 10),
          today: today,
          boundaries: service.boundariesOf(daily),
        ),
        today: today,
        now: DateTime.utc(2026, 9, 22, 10),
      ),
      isNull,
    );
  });

  test('measurable and limit goals: ring progress and resolution', () {
    final count = habit(RecurrenceRule(), goal: const HabitTarget(type: HabitGoalType.count, target: 5, unit: 'reps'));
    final partial = entry(count, logs: [log(HabitLogKind.progress, '2026-09-22', DateTime.utc(2026, 9, 22, 9), value: 2)])!;
    expect(partial.progress, closeTo(0.4, 1e-9));
    expect(partial.achieved, 2);
    expect(partial.target, 5);
    expect(partial.resolved, isFalse);

    final limit = habit(
      RecurrenceRule(),
      goal: const HabitTarget(type: HabitGoalType.count, target: 2, op: TargetOp.lte),
    );
    final under = entry(limit, logs: [log(HabitLogKind.progress, '2026-09-22', DateTime.utc(2026, 9, 22, 9), value: 1)])!;
    expect(under.isLimit, isTrue);
    expect(under.resolved, isTrue);
    final over = entry(limit, logs: [log(HabitLogKind.progress, '2026-09-22', DateTime.utc(2026, 9, 22, 9), value: 3)])!;
    expect(over.day?.status, PeriodStatus.failed);
    expect(over.resolved, isFalse);
  });
}
