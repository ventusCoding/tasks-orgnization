import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/occurrence_ledger.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/quit_calculator.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/status_intervals.dart';
import 'package:everslot_metrics/src/streaks.dart';
import 'package:everslot_metrics/src/strength.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:test/test.dart';

import 'support/support.dart';

final ZoneClock paris = tzClock('Europe/Paris');
final DayBoundaries bounds = DayBoundaries(paris);

HabitPeriod day(String date, HabitGoal goal, {bool due = true, String? revision}) => HabitPeriod(
  date,
  kind: HabitPeriodKind.day,
  startDate: d(date),
  endDate: d(date),
  windowStart: bounds.startOf(d(date)),
  windowEnd: bounds.endOf(d(date)),
  goal: goal,
  due: due,
  revisionId: revision,
);

HabitLog log(HabitLogKind kind, String localTime, {double? value, String? key, String? id, String? created}) {
  final at_ = at(paris, localTime);
  return HabitLog(
    id ?? '$kind@$localTime',
    kind,
    loggedAt: at_,
    localDate: bounds.dateOf(at_),
    value: value,
    occurrenceKey: key,
    createdAt: created == null ? null : at(paris, created),
  );
}

PeriodStatus statusOf(
  HabitPeriod p,
  List<HabitLog> logs, {
  String now = '2026-09-20T12:00',
  List<HabitPause> pauses = const [],
  HabitEvaluationSettings settings = const HabitEvaluationSettings(),
}) => evaluateHabitPeriod(
  p,
  logs,
  now: at(paris, now),
  today: bounds.dateOf(at(paris, now)),
  pauses: pauses,
  settings: settings,
).status;

void main() {
  const check = HabitGoal.check();
  const count15 = HabitGoal(HabitGoalType.count, target: 15);
  const limit2 = HabitGoal(HabitGoalType.count, target: 2, op: TargetOp.lte);
  const exactly3 = HabitGoal(HabitGoalType.numeric, target: 3, op: TargetOp.eq);

  group('period evaluation (T5.1.06)', () {
    test('check goal: done, missed, pending, explicit states, latest statement wins', () {
      final p = day('2026-09-10', check);
      expect(statusOf(p, [log(HabitLogKind.done, '2026-09-10T08:00')]), PeriodStatus.done);
      expect(statusOf(p, const []), PeriodStatus.missed);
      expect(statusOf(p, const [], now: '2026-09-10T12:00'), PeriodStatus.pending);
      expect(statusOf(p, [log(HabitLogKind.fail, '2026-09-10T08:00')]), PeriodStatus.failed);
      expect(statusOf(p, [log(HabitLogKind.excuse, '2026-09-10T08:00')]), PeriodStatus.excused);
      expect(statusOf(p, [log(HabitLogKind.freeze, '2026-09-11T00:10', key: '2026-09-10')]), PeriodStatus.frozen);
      final flip = [log(HabitLogKind.done, '2026-09-10T08:00'), log(HabitLogKind.fail, '2026-09-10T20:00')];
      expect(statusOf(p, flip), PeriodStatus.failed);
      expect(statusOf(p, flip.reversed.toList()), PeriodStatus.failed, reason: 'order independent');
      final skip = evaluateHabitPeriod(
        p,
        [log(HabitLogKind.skip, '2026-09-10T08:00')],
        now: at(paris, '2026-09-20T12:00'),
        today: d('2026-09-20'),
        settings: const HabitEvaluationSettings(skipPolicy: SkipPolicy.breaks),
      );
      expect(skip.status, PeriodStatus.skipped);
      expect(skip.flags.breaksStreak, isTrue);
      expect(skip.flags.explicit, isTrue);
      expect(statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 1)]), PeriodStatus.done);
      final other = [log(HabitLogKind.done, '2026-09-11T08:00')];
      expect(statusOf(p, other), PeriodStatus.missed, reason: 'logs of other days are ignored');
      final keyed = [log(HabitLogKind.done, '2026-09-11T01:00', key: '2026-09-10')];
      expect(statusOf(p, keyed), PeriodStatus.done, reason: 'the occurrence key wins over the local date');
    });

    test('same-instant state logs resolve by created_at then id', () {
      final p = day('2026-09-10', check);
      final a = HabitLog(
        'a',
        HabitLogKind.done,
        loggedAt: at(paris, '2026-09-10T08:00'),
        localDate: d('2026-09-10'),
        createdAt: at(paris, '2026-09-10T09:00'),
      );
      final b = HabitLog(
        'b',
        HabitLogKind.fail,
        loggedAt: at(paris, '2026-09-10T08:00'),
        localDate: d('2026-09-10'),
        createdAt: at(paris, '2026-09-10T08:30'),
      );
      expect(statusOf(p, [a, b]), PeriodStatus.done);
      final c = HabitLog('c', HabitLogKind.fail, loggedAt: a.loggedAt, localDate: a.localDate, createdAt: a.createdAt);
      expect(statusOf(p, [a, c]), PeriodStatus.failed, reason: 'id tie-breaker');
    });

    test('gte: early completion, partial, missed, pending', () {
      final p = day('2026-09-10', count15);
      expect(
        statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 15)], now: '2026-09-10T09:00'),
        PeriodStatus.done,
      );
      expect(statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 10)]), PeriodStatus.partial);
      expect(
        statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 10)], now: '2026-09-10T09:00'),
        PeriodStatus.pending,
      );
      expect(statusOf(p, const []), PeriodStatus.missed);
      final r = evaluateHabitPeriod(
        p,
        [
          log(HabitLogKind.progress, '2026-09-10T08:00', value: 10),
          log(HabitLogKind.progress, '2026-09-10T18:00', value: 8),
        ],
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(r.achieved, 18);
      expect(r.ratio, near(18 / 15));
      expect(r.fulfilment, 1);
      expect(r.isClosed, isTrue);
    });

    test('lte limit: fails immediately, auto-success, requireExplicitLog', () {
      final p = day('2026-09-10', limit2);
      expect(
        statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 3)], now: '2026-09-10T09:00'),
        PeriodStatus.failed,
      );
      expect(statusOf(p, const []), PeriodStatus.done);
      expect(statusOf(p, const [], now: '2026-09-10T09:00'), PeriodStatus.pending);
      const explicit = HabitEvaluationSettings(requireExplicitLog: true);
      expect(statusOf(p, const [], settings: explicit), PeriodStatus.missed);
      expect(
        statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 0)], settings: explicit),
        PeriodStatus.done,
      );
      final r = evaluateHabitPeriod(
        p,
        [log(HabitLogKind.progress, '2026-09-10T08:00', value: 3)],
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(r.fulfilment, 0.5);
      expect(limitCredit(0, 0), 1);
      expect(limitCredit(1, 0), 0);
    });

    test('eq exact goals', () {
      final p = day('2026-09-10', exactly3);
      expect(statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 3)]), PeriodStatus.done);
      expect(
        statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 3)], now: '2026-09-10T09:00'),
        PeriodStatus.pending,
      );
      expect(
        statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 4)], now: '2026-09-10T09:00'),
        PeriodStatus.failed,
      );
      expect(statusOf(p, [log(HabitLogKind.progress, '2026-09-10T08:00', value: 2)]), PeriodStatus.partial);
      expect(statusOf(p, const []), PeriodStatus.missed);
    });

    test('pauses, vacation, not due, future', () {
      final p = day('2026-09-10', check);
      final vacation = [HabitPause(d('2026-09-08'))];
      expect(statusOf(p, const [], pauses: vacation), PeriodStatus.paused);
      expect(
        statusOf(p, [log(HabitLogKind.done, '2026-09-10T08:00')], pauses: vacation),
        PeriodStatus.done,
        reason: 'a done result stays done inside a pause',
      );
      expect(
        statusOf(
          p,
          const [],
          pauses: [HabitPause(d('2026-09-01'), end: d('2026-09-05'), habitId: 'h')],
        ),
        PeriodStatus.missed,
      );
      final notDue = evaluateHabitPeriod(
        day('2026-09-12', check, due: false),
        [log(HabitLogKind.done, '2026-09-12T08:00')],
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(notDue.status, PeriodStatus.notDue);
      expect(notDue.flags.bonus, isTrue);
      final future = evaluateHabitPeriod(
        day('2026-09-25', check),
        const [],
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(future.status, PeriodStatus.pending);
      expect(future.flags.future, isTrue);
      final many = evaluateHabitPeriods(
        [day('2026-09-19', check), day('2026-09-25', check)],
        const [],
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(many.length, 1);
      expect(
        evaluateHabitPeriods(
          [day('2026-09-25', check)],
          const [],
          now: at(paris, '2026-09-20T00:00'),
          today: d('2026-09-20'),
          includeFuture: true,
        ).single.flags.future,
        isTrue,
      );
    });

    test('revision change: each period uses the goal of its revision', () {
      final before = day('2026-09-14', const HabitGoal(HabitGoalType.count, target: 10), revision: 'r1');
      final after = day('2026-09-15', count15, revision: 'r2');
      final logs = [
        log(HabitLogKind.progress, '2026-09-14T08:00', value: 12),
        log(HabitLogKind.progress, '2026-09-15T08:00', value: 12),
      ];
      final results = evaluateHabitPeriods(
        [before, after],
        logs,
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(results.map((r) => r.status), [PeriodStatus.done, PeriodStatus.partial]);
      expect(results.map((r) => r.revisionId), ['r1', 'r2']);
      final ledger = buildLedger(ledgerUnitsFromPeriods(results), now: at(paris, '2026-09-20T00:00'));
      expect(ledger.done, 1);
      expect(ledger.partial, 1);
      final revisions = [(from: d('2026-09-01'), target: 10), (from: d('2026-09-15'), target: 15)];
      expect(effectiveOn(revisions, d('2026-09-14'), (r) => r.from)!.target, 10);
      expect(effectiveOn(revisions, d('2026-09-15'), (r) => r.from)!.target, 15);
      expect(effectiveOn(revisions, d('2026-08-31'), (r) => r.from), isNull);
    });

    test('slots: keyless matching within [slot − tolerance, next slot) and roll-ups', () {
      PeriodResult slot(String time, List<HabitLog> logs, {String now = '2026-09-20T00:00'}) {
        final start = at(paris, '2026-09-10T$time');
        return evaluateHabitPeriod(
          HabitPeriod(
            '2026-09-10T$time',
            kind: HabitPeriodKind.slot,
            startDate: d('2026-09-10'),
            endDate: d('2026-09-10'),
            windowStart: start,
            windowEnd: start.add(const Duration(hours: 4)),
            matchStart: start.subtract(const Duration(minutes: 30)),
            goal: check,
          ),
          logs,
          now: at(paris, now),
          today: bounds.dateOf(at(paris, now)),
        );
      }

      final early = slot('08:00', [log(HabitLogKind.done, '2026-09-10T07:45')]);
      expect(early.status, PeriodStatus.done);
      final tooEarly = slot('08:00', [log(HabitLogKind.done, '2026-09-10T07:20')]);
      expect(tooEarly.status, PeriodStatus.missed);
      final keyed = slot('12:00', [log(HabitLogKind.done, '2026-09-10T18:00', key: '2026-09-10T12:00')]);
      expect(keyed.status, PeriodStatus.done);
      final missed = slot('16:00', const []);
      final pending = slot('16:00', const [], now: '2026-09-10T17:00');
      final excused = slot('20:00', [log(HabitLogKind.excuse, '2026-09-10T20:00', key: '2026-09-10T20:00')]);
      final paused = missed.withStatus(PeriodStatus.paused);
      final frozen = missed.withStatus(PeriodStatus.frozen);
      final skipped = missed.withStatus(PeriodStatus.skipped);
      final failed = missed.withStatus(PeriodStatus.failed);
      final notDue = missed.withStatus(PeriodStatus.notDue);
      final partial = missed.withStatus(PeriodStatus.partial);
      PeriodStatus rollUp(List<PeriodResult> slots, {HabitEvaluationSettings s = const HabitEvaluationSettings()}) =>
          rollUpSlots(
            d('2026-09-10'),
            slots,
            windowStart: bounds.startOf(d('2026-09-10')),
            windowEnd: bounds.endOf(d('2026-09-10')),
            settings: s,
          ).status;
      expect(rollUp([early, keyed, excused]), PeriodStatus.done);
      expect(rollUp([early, keyed, missed]), PeriodStatus.partial);
      expect(
        rollUp([early, keyed, missed], s: const HabitEvaluationSettings(slotRollup: SlotRollup(minSlots: 2))),
        PeriodStatus.done,
      );
      expect(rollUp([early, pending]), PeriodStatus.pending);
      expect(rollUp([missed, tooEarly]), PeriodStatus.missed);
      expect(rollUp([missed, failed]), PeriodStatus.failed);
      expect(rollUp([partial, missed]), PeriodStatus.partial);
      expect(rollUp([skipped], s: const HabitEvaluationSettings(skipPolicy: SkipPolicy.breaks)), PeriodStatus.skipped);
      expect(rollUp([excused]), PeriodStatus.excused);
      expect(rollUp([paused, excused]), PeriodStatus.paused);
      expect(rollUp([frozen]), PeriodStatus.frozen);
      expect(rollUp([notDue]), PeriodStatus.notDue);
      expect(rollUp(const []), PeriodStatus.notDue);
      expect(const SlotRollup.allSlots().requiresAll, isTrue);
    });

    test('quota periods: done, partial, missed, at-risk, pro-rating, exclusions', () {
      HabitPeriod week({
        String start = '2026-09-14',
        int times = 3,
        HabitGoal goal = check,
        List<String>? eligible,
        int? full,
        double? minPerDay,
      }) {
        final s = d(start);
        return HabitPeriod(
          'week:$start',
          kind: HabitPeriodKind.quota,
          startDate: s,
          endDate: s.plusDays(6),
          windowStart: bounds.startOf(s),
          windowEnd: bounds.endOf(s.plusDays(6)),
          goal: goal,
          quotaTimes: times,
          eligibleDays: eligible?.map(d).toList(),
          fullEligibleDays: full,
          minPerDay: minPerDay,
        );
      }

      PeriodResult eval(HabitPeriod p, List<HabitLog> logs, String now, {List<HabitPause> pauses = const []}) =>
          evaluateHabitPeriod(p, logs, now: at(paris, now), today: bounds.dateOf(at(paris, now)), pauses: pauses);
      HabitLog done(String date) => log(HabitLogKind.done, '${date}T08:00', key: date);

      final three = [done('2026-09-14'), done('2026-09-16'), done('2026-09-18')];
      expect(eval(week(), three, '2026-09-25T00:00').status, PeriodStatus.done);
      expect(eval(week(), three, '2026-09-18T12:00').status, PeriodStatus.done, reason: 'early completion');
      final two = three.take(2).toList();
      final closedPartial = eval(week(), two, '2026-09-25T00:00');
      expect(closedPartial.status, PeriodStatus.partial);
      expect(closedPartial.flags.activeDays, 2);
      expect(eval(week(), const [], '2026-09-25T00:00').status, PeriodStatus.missed);
      // T6.1.09 at-risk: 2 of 3 done and 1 day left → false; 0 days left → true.
      final oneLeft = eval(
        week(eligible: ['2026-09-14', '2026-09-16', '2026-09-18', '2026-09-20'], full: 4),
        two,
        '2026-09-19T12:00',
      );
      expect(oneLeft.status, PeriodStatus.pending);
      expect(oneLeft.flags.remainingEligibleDays, 1);
      expect(oneLeft.flags.atRisk, isFalse);
      final noneLeft = eval(
        week(eligible: ['2026-09-14', '2026-09-16', '2026-09-18'], full: 3),
        two,
        '2026-09-19T12:00',
      );
      expect(noneLeft.flags.remainingEligibleDays, 0);
      expect(noneLeft.flags.atRisk, isTrue);
      expect(isQuotaAtRisk(needed: 1, eligibleDaysLeft: 1), isFalse);
      expect(isQuotaAtRisk(needed: 1, eligibleDaysLeft: 0), isTrue);
      // Pro-rating: a partial first week (Wed–Sun, one excused day) needs ⌈3·4/7⌉ = 2 active days.
      final partialWeek = HabitPeriod(
        'week:2026-09-14',
        kind: HabitPeriodKind.quota,
        startDate: d('2026-09-16'),
        endDate: d('2026-09-20'),
        windowStart: bounds.startOf(d('2026-09-16')),
        windowEnd: bounds.endOf(d('2026-09-20')),
        goal: check,
        quotaTimes: 3,
        fullEligibleDays: 7,
      );
      final excuse = log(HabitLogKind.excuse, '2026-09-17T08:00', key: '2026-09-17');
      final pr = eval(partialWeek, [excuse, done('2026-09-16'), done('2026-09-19')], '2026-09-21T00:00');
      expect(pr.flags.eligibleDays, 4);
      expect(pr.flags.expected, near(3 * 4 / 7));
      expect(pr.flags.requiredDays, 2);
      expect(pr.status, PeriodStatus.done);
      // Paused and skipped days are ineligible; all paused → paused, all excused → excused.
      final allPaused = eval(week(), const [], '2026-09-25T00:00', pauses: [HabitPause(d('2026-09-01'))]);
      expect(allPaused.status, PeriodStatus.paused);
      final allSkipped = eval(week(eligible: ['2026-09-14']), [
        log(HabitLogKind.skip, '2026-09-14T08:00', key: '2026-09-14'),
      ], '2026-09-25T00:00');
      expect(allSkipped.status, PeriodStatus.excused);
      final failDay = eval(week(times: 1, eligible: ['2026-09-14']), [
        log(HabitLogKind.fail, '2026-09-14T08:00', key: '2026-09-14'),
      ], '2026-09-25T00:00');
      expect(failDay.status, PeriodStatus.missed);
      // Measurable quota: the target applies to the period total; quota.times = min active days.
      const run20 = HabitGoal(HabitGoalType.numeric, target: 20);
      final km = [
        log(HabitLogKind.progress, '2026-09-14T08:00', value: 8, key: '2026-09-14'),
        log(HabitLogKind.progress, '2026-09-16T08:00', value: 7, key: '2026-09-16'),
        log(HabitLogKind.progress, '2026-09-18T08:00', value: 6, key: '2026-09-18'),
      ];
      expect(eval(week(goal: run20), km, '2026-09-25T00:00').status, PeriodStatus.done);
      expect(eval(week(goal: run20, times: 4), km, '2026-09-25T00:00').status, PeriodStatus.partial);
      expect(eval(week(goal: run20, minPerDay: 7), km, '2026-09-25T00:00').flags.activeDays, 2);
      final notDue = evaluateHabitPeriod(
        HabitPeriod(
          'week:x',
          kind: HabitPeriodKind.quota,
          startDate: d('2026-09-14'),
          endDate: d('2026-09-20'),
          windowStart: bounds.startOf(d('2026-09-14')),
          windowEnd: bounds.endOf(d('2026-09-20')),
          goal: check,
          due: false,
        ),
        const [],
        now: at(paris, '2026-09-25T00:00'),
        today: d('2026-09-25'),
      );
      expect(notDue.status, PeriodStatus.notDue);
      final future = eval(week(start: '2026-09-28'), const [], '2026-09-25T00:00');
      expect(future.flags.future, isTrue);
      expect(future.status, PeriodStatus.pending);
    });

    test('properties: more progress never lowers achieved; removing a pause keeps done', () {
      final rng = math.Random(5);
      for (var i = 0; i < 200; i++) {
        final p = day('2026-09-10', count15);
        final logs = [
          for (var k = 0; k < rng.nextInt(4); k++)
            log(HabitLogKind.progress, '2026-09-10T0${k + 1}:00', value: rng.nextInt(10).toDouble()),
        ];
        final base = evaluateHabitPeriod(p, logs, now: at(paris, '2026-09-20T00:00'), today: d('2026-09-20'));
        final more = evaluateHabitPeriod(
          p,
          [...logs, log(HabitLogKind.progress, '2026-09-10T09:00', value: rng.nextInt(10).toDouble())],
          now: at(paris, '2026-09-20T00:00'),
          today: d('2026-09-20'),
        );
        expect(more.achieved, greaterThanOrEqualTo(base.achieved));
        final paused = evaluateHabitPeriod(
          p,
          logs,
          now: at(paris, '2026-09-20T00:00'),
          today: d('2026-09-20'),
          pauses: [HabitPause(d('2026-09-01'))],
        );
        if (paused.status == PeriodStatus.done) {
          expect(base.status, PeriodStatus.done);
        }
      }
      expect(HabitLogKind.parse('restart'), HabitLogKind.restart);
      expect(() => HabitLogKind.parse('nope'), throwsFormatException);
      expect(HabitLogKind.skip.isState, isTrue);
      expect(HabitLogKind.progress.isState, isFalse);
      expect(PeriodStatus.frozen.isNeutral, isTrue);
      expect(check.effectiveTarget, 1);
      expect(const HabitGoal(HabitGoalType.count).effectiveTarget, 1);
      final zero = evaluateHabitPeriod(
        day('2026-09-10', const HabitGoal(HabitGoalType.count, target: 0)),
        const [],
        now: at(paris, '2026-09-20T00:00'),
        today: d('2026-09-20'),
      );
      expect(zero.ratio, isNull);
      expect(zero.fulfilment, 0);
      expect(HabitPause(d('2026-09-01'), end: d('2026-09-03')).covers(d('2026-09-04')), isFalse);
    });
  });

  group('expected-occurrences ledger (T6.1.08)', () {
    final now = at(paris, '2026-09-20T12:00');
    LedgerUnit unit(String date, {LedgerState state = LedgerState.open, String? due, String? completed}) => LedgerUnit(
      date,
      start: bounds.startOf(d(date)),
      end: bounds.endOf(d(date)),
      state: state,
      date: d(date),
      dueAt: due == null ? null : at(paris, due),
      completedAt: completed == null ? null : at(paris, completed),
    );

    test('classification of every state; skip policy; frozen counts as a miss', () {
      final units = [
        unit('2026-09-10', state: LedgerState.done, due: '2026-09-10T09:00', completed: '2026-09-10T08:00'),
        unit('2026-09-11', state: LedgerState.done, due: '2026-09-11T09:00', completed: '2026-09-11T10:00'),
        unit('2026-09-12', state: LedgerState.partial),
        unit('2026-09-13', state: LedgerState.failed),
        unit('2026-09-14', state: LedgerState.missed),
        unit('2026-09-15', state: LedgerState.skipped),
        unit('2026-09-16', state: LedgerState.excused),
        unit('2026-09-17', state: LedgerState.cancelled),
        unit('2026-09-18', state: LedgerState.paused),
        unit('2026-09-19', state: LedgerState.frozen),
        unit('2026-09-20'),
        unit('2026-09-21'),
      ];
      final l = buildLedger(units, now: now);
      expect(l.expected, 11);
      expect(l.future, 1);
      expect(l.done, 2);
      expect(l.onTime, 1);
      expect(l.late, 1);
      expect(l.partial, 1);
      expect(l.failed, 1);
      expect(l.missed, 2, reason: 'missed + frozen');
      expect(l.frozen, 1);
      expect(l.skipped, 1);
      expect(l.cancelled, 1);
      expect(l.excused, 4, reason: 'skip (neutral) + excused + cancelled + paused');
      expect(l.pending, 1);
      expect(l.expectedClosed, 10);
      expect(l.denominator, 6);
      expect(l.adherence.valueOrNull, near(2 / 6));
      expect(l.missRate.valueOrNull, near(3 / 6));
      expect(l.onTimeRate.valueOrNull, 0.5);
      expect(l.skipRate.valueOrNull, near(1 / 10));
      expect(l.chronological.first.unit.key, '2026-09-10');
      final breaks = buildLedger(units, now: now, skipPolicy: SkipPolicy.breaks);
      expect(breaks.excused, 3);
      expect(breaks.adherence.valueOrNull, near(2 / 7));
    });

    test('keyless completions match the nearest unit in its tolerance window; extras are bonus', () {
      final starts = [at(paris, '2026-09-10T08:00'), at(paris, '2026-09-10T12:00'), at(paris, '2026-09-10T16:00')];
      final windows = intradayToleranceWindows(starts, dayEnd: bounds.endOf(d('2026-09-10')));
      expect(windows.first.$1, at(paris, '2026-09-10T07:30'));
      expect(windows.first.$2, starts[1]);
      expect(windows.last.$2, bounds.endOf(d('2026-09-10')));
      final units = [
        for (var i = 0; i < 3; i++)
          LedgerUnit(
            'slot$i',
            start: starts[i],
            end: windows[i].$2,
            matchStart: windows[i].$1,
            matchEnd: windows[i].$2,
          ),
      ];
      final l = buildLedger(
        units,
        now: now,
        completions: [
          LedgerCompletion(at(paris, '2026-09-10T07:45')),
          LedgerCompletion(at(paris, '2026-09-10T11:10')),
          LedgerCompletion(at(paris, '2026-09-10T12:05')),
          LedgerCompletion(at(paris, '2026-09-10T13:00'), key: 'slot1'),
          LedgerCompletion(at(paris, '2026-09-10T13:00'), key: 'unknown'),
        ],
      );
      expect(l.done, 2);
      expect(l.missed, 1);
      expect(l.bonus, 3);
      expect(l.adherence.valueOrNull, near(2 / 3));
      expect(l.entries.first.completedAt, at(paris, '2026-09-10T07:45'));
    });

    test('keyed completions, late matches and pending/future units', () {
      final l = buildLedger(
        [
          LedgerUnit(
            'a',
            start: at(paris, '2026-09-20T08:00'),
            end: at(paris, '2026-09-20T20:00'),
            dueAt: at(paris, '2026-09-20T09:00'),
          ),
          LedgerUnit('b', start: at(paris, '2026-09-20T13:00'), end: at(paris, '2026-09-20T20:00')),
        ],
        now: now,
        completions: [LedgerCompletion(at(paris, '2026-09-20T10:00'), key: 'a')],
      );
      expect(l.late, 1);
      expect(l.future, 1);
      expect(l.expected, 1);
      expect(l.onTimeRate.valueOrNull, 0);
    });

    test('quota units: E = N·eligible/period, partial credit, pending remainder, bonus', () {
      expect(quotaExpectation(3, eligibleDays: 4, periodDays: 7), near(1.714, 1e-3));
      LedgerUnit quota(double completions, {String end = '2026-09-13', LedgerState state = LedgerState.open}) =>
          LedgerUnit(
            'week',
            start: bounds.startOf(d('2026-09-07')),
            end: bounds.endOf(d(end)),
            weight: 3 * 4 / 7,
            quotaCompletions: completions,
            state: state,
          );
      final closedOne = buildLedger([quota(1)], now: now);
      expect(closedOne.done, 1);
      expect(closedOne.missed, near(3 * 4 / 7 - 1));
      expect(closedOne.entries.single.classification, LedgerClass.partial);
      final surplus = buildLedger([quota(3)], now: now);
      expect(surplus.done, near(3 * 4 / 7));
      expect(surplus.bonus, near(3 - 3 * 4 / 7));
      expect(surplus.adherence.valueOrNull, 1);
      final open = buildLedger(
        [quota(0, end: '2026-09-27')],
        now: now,
        completions: [LedgerCompletion(now, key: 'week')],
      );
      expect(open.done, 1);
      expect(open.pending, near(3 * 4 / 7 - 1));
      expect(open.entries.single.classification, LedgerClass.pending);
      final none = buildLedger([quota(0)], now: now);
      expect(none.entries.single.classification, LedgerClass.missed);
      final excused = buildLedger([quota(0, state: LedgerState.paused)], now: now);
      expect(excused.excused, near(3 * 4 / 7));
      expect(excused.adherence, const NotApplicable<double>(Reasons.zeroDenominator));
    });

    test('units from period results, including quota periods', () {
      PeriodResult result(
        PeriodStatus s, {
        HabitPeriodKind kind = HabitPeriodKind.day,
        PeriodFlags flags = const PeriodFlags(),
      }) => PeriodResult(
        s.name,
        kind: kind,
        startDate: d('2026-09-10'),
        endDate: d('2026-09-10'),
        windowStart: bounds.startOf(d('2026-09-10')),
        windowEnd: bounds.endOf(d('2026-09-10')),
        status: s,
        achieved: 0,
        target: 1,
        goal: check,
        flags: flags,
      );
      final units = ledgerUnitsFromPeriods([
        for (final s in PeriodStatus.values) result(s),
        result(PeriodStatus.partial, kind: HabitPeriodKind.quota, flags: const PeriodFlags(expected: 3, activeDays: 2)),
      ]);
      expect(units.length, PeriodStatus.values.length);
      expect(units.last.weight, 3);
      expect(units.last.quotaCompletions, 2);
      expect(units.map((u) => u.state), containsAll(LedgerState.values.where((s) => s != LedgerState.cancelled)));
    });
  });

  group('streak engine (T6.1.09)', () {
    StreakUnit u(
      int i,
      StreakUnitKind kind, {
      bool freezable = false,
      bool frozen = false,
      String start = '2026-09-01',
    }) => StreakUnit(
      'u$i',
      start: d(start).plusDays(i),
      end: d(start).plusDays(i),
      kind: kind,
      freezable: freezable,
      frozen: frozen,
    );

    test('freezes: 1 per month protects the first miss, the second breaks; monthly reset', () {
      final units = [
        u(0, StreakUnitKind.success),
        u(1, StreakUnitKind.breaks, freezable: true),
        u(2, StreakUnitKind.success),
        u(3, StreakUnitKind.breaks, freezable: true),
        u(4, StreakUnitKind.success),
      ];
      final s = computeStreaks(units, freezesPerMonth: 1);
      expect(s.frozenKeys, ['u1']);
      expect(s.currentLength, 1);
      expect(s.bestLength, 2);
      expect(s.best!.frozenUnits, 1);
      expect(s.freezesUsedByMonth, {'2026-09': 1});
      final boundary = computeStreaks([
        u(0, StreakUnitKind.success, start: '2026-09-29'),
        u(1, StreakUnitKind.breaks, freezable: true, start: '2026-09-29'),
        u(2, StreakUnitKind.breaks, freezable: true, start: '2026-09-29'),
        u(3, StreakUnitKind.success, start: '2026-09-29'),
      ], freezesPerMonth: 1);
      expect(boundary.frozenKeys, ['u1', 'u2'], reason: 'Sep 30 and Oct 1 use different allotments');
      expect(boundary.currentLength, 2);
      final materialized = computeStreaks([
        u(0, StreakUnitKind.neutral, frozen: true),
        u(1, StreakUnitKind.breaks, freezable: true),
      ], freezesPerMonth: 1);
      expect(materialized.frozenKeys, ['u0']);
      expect(materialized.currentLength, 0);
      final partial = computeStreaks([u(0, StreakUnitKind.success), u(1, StreakUnitKind.breaks)], freezesPerMonth: 1);
      expect(partial.frozenKeys, isEmpty, reason: 'partial units are not freezable');
    });

    test('P2 flag: one miss forgiven per N units', () {
      final units = [
        u(0, StreakUnitKind.success),
        u(1, StreakUnitKind.breaks),
        u(2, StreakUnitKind.success),
        u(3, StreakUnitKind.breaks),
        for (var i = 4; i < 10; i++) u(i, StreakUnitKind.success),
        u(10, StreakUnitKind.breaks),
      ];
      final s = computeStreaks(units, forgiveOneMissPerUnits: 7);
      expect(s.forgivenKeys, ['u1', 'u10']);
      expect(s.bestLength, 6);
      expect(s.currentLength, 6);
      expect(s.streaks.first.length, 2, reason: 'u1 forgiven, u3 not (within 7 units)');
    });

    test('length policies, ranking, top-10, calendar span', () {
      final units = [
        u(0, StreakUnitKind.success),
        u(1, StreakUnitKind.neutral),
        u(2, StreakUnitKind.neutral),
        u(3, StreakUnitKind.success),
        u(4, StreakUnitKind.breaks),
        u(5, StreakUnitKind.success),
        u(6, StreakUnitKind.success),
        u(7, StreakUnitKind.open),
      ];
      final s = computeStreaks(units);
      expect(s.streaks.length, 2);
      expect(s.best!.endKey, 'u6', reason: 'ties resolve to the most recent');
      expect(s.bestBySpan!.endKey, 'u3');
      expect(s.bestBySpan!.lengthFor(StreakLengthPolicy.calendarSpan), 4);
      expect(s.best!.lengthFor(StreakLengthPolicy.successfulUnits), 2);
      expect(s.best!.spannedUnits, 2);
      expect(s.currentCalendarSpan, 2);
      expect(s.bestCalendarSpan, 2);
      expect(s.ranked.first.endKey, 'u6');
      expect(s.top10.length, 2);
      expect(s.current!.isCurrent, isTrue);
      final empty = computeStreaks(const []);
      expect(empty.currentLength, 0);
      expect(empty.bestLength, 0);
      expect(empty.bestBySpan, isNull);
      expect(empty.currentCalendarSpan, 0);
      expect(empty.bestCalendarSpan, 0);
      expect(
        isFixedUnitAtRisk(
          dueAndNotDone: true,
          closesAt: at(paris, '2026-09-21T00:00'),
          horizonEnd: at(paris, '2026-09-21T00:00'),
        ),
        isTrue,
      );
      expect(
        isFixedUnitAtRisk(
          dueAndNotDone: true,
          closesAt: at(paris, '2026-09-22T00:00'),
          horizonEnd: at(paris, '2026-09-21T00:00'),
        ),
        isFalse,
      );
    });

    test('period results: skip policy and breaksStreak flag', () {
      PeriodResult r(int i, PeriodStatus s, {bool breaks = false}) => PeriodResult(
        'r$i',
        kind: HabitPeriodKind.day,
        startDate: d('2026-09-01').plusDays(i),
        endDate: d('2026-09-01').plusDays(i),
        windowStart: bounds.startOf(d('2026-09-01').plusDays(i)),
        windowEnd: bounds.endOf(d('2026-09-01').plusDays(i)),
        status: s,
        achieved: 0,
        target: 1,
        goal: check,
        flags: PeriodFlags(breaksStreak: breaks),
      );
      final results = [r(0, PeriodStatus.done), r(1, PeriodStatus.skipped), r(2, PeriodStatus.done)];
      expect(computeStreaks(streakUnitsFromPeriods(results)).currentLength, 2);
      expect(computeStreaks(streakUnitsFromPeriods(results, skipPolicy: SkipPolicy.breaks)).currentLength, 1);
      final flagged = [r(0, PeriodStatus.done), r(1, PeriodStatus.skipped, breaks: true), r(2, PeriodStatus.done)];
      expect(computeStreaks(streakUnitsFromPeriods(flagged)).currentLength, 1);
      final kinds = streakUnitsFromPeriods([for (final s in PeriodStatus.values) r(0, s)]).map((x) => x.kind).toSet();
      expect(kinds, StreakUnitKind.values.toSet());
    });

    test('property: the current streak never exceeds the best streak', () {
      final rng = math.Random(17);
      for (var i = 0; i < 300; i++) {
        final units = [
          for (var k = 0; k < 1 + rng.nextInt(40); k++)
            u(k, StreakUnitKind.values[rng.nextInt(4)], freezable: rng.nextBool()),
        ];
        final s = computeStreaks(units, freezesPerMonth: rng.nextInt(3));
        expect(s.currentLength, lessThanOrEqualTo(s.bestLength));
      }
    });
  });

  group('strength score (T6.1.10)', () {
    final start = d('2026-01-01');
    test('skipped days leave the score unchanged; at-most starts at 1.0', () {
      final days = [
        for (var i = 0; i < 10; i++)
          StrengthDay(start.plusDays(i), value: 1, frequency: const StrengthFrequency.daily(), skipped: i == 5),
      ];
      final r = computeStrength(days);
      expect(r.series[5].score, r.series[4].score);
      expect(r.series[5].scored, isFalse);
      final atMost = computeStrength([
        StrengthDay(start, value: 0, frequency: const StrengthFrequency.daily(), target: 2),
      ], kind: StrengthGoalKind.atMost);
      expect(atMost.initialScore, 1);
      expect(atMost.current, 1);
      final zeroTarget = computeStrength([
        StrengthDay(start, value: 1, frequency: const StrengthFrequency.daily(), target: 0),
      ], kind: StrengthGoalKind.atMost);
      expect(zeroTarget.series.single.credit, 0);
      final atLeastNoTarget = computeStrength([
        StrengthDay(start, value: 0, frequency: const StrengthFrequency.daily()),
      ], kind: StrengthGoalKind.atLeast);
      expect(atLeastNoTarget.series.single.credit, 1);
      final several = computeStrength([
        StrengthDay(start, value: 6, frequency: const StrengthFrequency(9, 1), expectedInDay: 9),
        StrengthDay(start.plusDays(1), value: 3, frequency: const StrengthFrequency(9, 1), expectedInDay: 0),
      ]);
      expect(several.series.first.credit, near(6 / 9));
      expect(several.series.last.credit, 0);
    });

    test('gaps are filled, lookups before/after the series, deltas, projection', () {
      final r = computeStrength([
        StrengthDay(start, value: 1, frequency: const StrengthFrequency.daily()),
        StrengthDay(start.plusDays(3), value: 1, frequency: const StrengthFrequency.daily()),
      ]);
      expect(r.series.length, 4);
      expect(r.series[1].credit, 0);
      expect(r.scoreAt(start.minusDays(1)), 0);
      expect(r.scoreAt(start.plusDays(10)), r.current);
      expect(r.scoreAt(start.plusDays(1)), r.series[1].score);
      expect(r.deltaVsDaysAgo(30).valueOrNull, r.current);
      expect(const StrengthResult([], initialScore: 0).deltaVsDaysAgo(30), const NotApplicable<double>(Reasons.noData));
      expect(computeStrength(const []).current, 0);
      expect(computeStrength(const [], kind: StrengthGoalKind.atMost).current, 1);
      final projection = projectStrength(0.5, 1, 1, days: 13);
      expect(projection.length, 13);
      expect(projection.last, near(0.75, 1e-9));
      expect(strengthStep(0, 1, 1), near(1 - strengthMultiplier(1)));
      expect(const StrengthFrequency(3, 7) == const StrengthFrequency(3, 7), isTrue);
      expect({const StrengthFrequency(3, 7), const StrengthFrequency(6, 14)}.length, 2);
    });

    test('property: the score always stays in [0, 1]', () {
      final rng = math.Random(23);
      for (var i = 0; i < 100; i++) {
        final kind = StrengthGoalKind.values[rng.nextInt(3)];
        final freq = [
          const StrengthFrequency.daily(),
          const StrengthFrequency(3, 8),
          const StrengthFrequency(2, 7),
          const StrengthFrequency(8, 1),
        ][rng.nextInt(4)];
        final r = computeStrength([
          for (var k = 0; k < 60; k++)
            StrengthDay(
              start.plusDays(k),
              value: rng.nextInt(12).toDouble(),
              frequency: freq,
              skipped: rng.nextInt(10) == 0,
              target: 1 + rng.nextInt(10).toDouble(),
              expectedInDay: freq.f > 1 ? 8 : 1,
            ),
        ], kind: kind);
        for (final p in r.series) {
          expect(p.score, inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('status-interval primitives (T6.1.11)', () {
    DateTime t(String local) => at(paris, local);

    test('out-of-order events, identical timestamps (rev), missing created event', () {
      final events = [
        StatusEvent(
          'x',
          StatusEventType.statusChanged,
          occurredAt: t('2026-09-03T10:00'),
          rev: 2,
          from: 'ongoing',
          to: 'completed',
        ),
        StatusEvent(
          'x',
          StatusEventType.statusChanged,
          occurredAt: t('2026-09-02T10:00'),
          rev: 1,
          from: 'todo',
          to: 'ongoing',
        ),
        StatusEvent(
          'x',
          StatusEventType.statusChanged,
          occurredAt: t('2026-09-03T10:00'),
          rev: 3,
          from: 'completed',
          to: 'ongoing',
        ),
      ];
      final tl = buildTimelines(events, seeds: [EntitySeed('x', createdAt: t('2026-09-01T10:00'))])['x']!;
      expect(tl.createdAt, t('2026-09-01T10:00'));
      expect(tl.currentStatus, 'ongoing');
      expect(tl.reopenCount(), 1);
      expect(tl.statusChangeCount, 3);
      expect(tl.intervals.map((i) => i.status), ['todo', 'ongoing', 'ongoing']);
      expect(tl.stateAt(t('2026-08-31T10:00')), isNull);
      expect(tl.stateAt(t('2026-09-02T10:00')), 'ongoing');
      expect(tl.stateAt(t('2026-09-02T10:00'), inclusive: false), 'todo');
      expect(tl.firstEntry('ongoing'), t('2026-09-02T10:00'));
      expect(tl.firstEntry('blocked'), isNull);
      expect(tl.lastExit('todo'), t('2026-09-02T10:00'));
      expect(tl.firstExit('ongoing'), t('2026-09-03T10:00'));
      expect(tl.firstExit('blocked'), isNull);
      expect(tl.episodes('ongoing').length, 2);
      expect(tl.deletedAt, isNull);
      final noSeed = buildTimelines([events[1]])['x']!;
      expect(noSeed.createdAt, t('2026-09-02T10:00'));
      final created = buildTimelines([
        StatusEvent(
          'y',
          StatusEventType.created,
          occurredAt: t('2026-09-01T09:00'),
          to: 'ongoing',
          toContainerId: 'L1',
        ),
        StatusEvent(
          'y',
          StatusEventType.statusChanged,
          occurredAt: t('2026-09-01T09:00'),
          from: 'ongoing',
          to: 'waiting',
        ),
        StatusEvent(
          'y',
          StatusEventType.statusChanged,
          occurredAt: t('2026-09-01T09:00'),
          rev: 1,
          from: 'waiting',
          to: 'blocked',
        ),
        StatusEvent('y', StatusEventType.statusChanged, occurredAt: t('2026-09-02T09:00')),
      ])['y']!;
      expect(created.initialStatus, 'ongoing');
      expect(created.currentStatus, 'blocked');
      expect(created.intervals.length, 1, reason: 'zero-length statuses leave no interval');
      expect(created.containerAt(t('2026-09-01T12:00')), 'L1');
      expect(created.containerAt(t('2026-08-01T12:00')), isNull);
    });

    test('delete, restore, clip windows, removed-from-scope counts, containers', () {
      final events = [
        StatusEvent('z', StatusEventType.created, occurredAt: t('2026-09-01T00:00'), to: 'todo'),
        StatusEvent('z', StatusEventType.deleted, occurredAt: t('2026-09-02T00:00')),
        StatusEvent('z', StatusEventType.restored, occurredAt: t('2026-09-03T00:00')),
        StatusEvent(
          'z',
          StatusEventType.moved,
          occurredAt: t('2026-09-04T00:00'),
          fromContainerId: 'A',
          toContainerId: 'B',
        ),
        StatusEvent(
          'z',
          StatusEventType.statusChanged,
          occurredAt: t('2026-09-05T00:00'),
          from: 'todo',
          to: 'cancelled',
        ),
      ];
      final tl = buildTimelines(events)['z']!;
      expect(tl.alive.length, 2);
      expect(tl.isAliveAt(t('2026-09-02T12:00')), isFalse);
      expect(tl.deletedBefore(t('2026-09-02T12:00')), t('2026-09-02T00:00'));
      final tis = tl.timeInStatus(now: t('2026-09-06T00:00'));
      expect(tis['todo'], const Duration(days: 3));
      expect(tis['cancelled'], const Duration(days: 1));
      final clipped = tl.timeInStatus(
        now: t('2026-09-06T00:00'),
        from: t('2026-09-03T12:00'),
        to: t('2026-09-04T00:00'),
      );
      expect(clipped['todo'], const Duration(hours: 12));
      expect(tl.containerAt(t('2026-09-03T12:00')), 'A');
      expect(tl.containerAt(t('2026-09-04T12:00')), 'B');
      final samples = [for (var i = 1; i <= 5; i++) bounds.endOf(d('2026-09-0$i'))];
      final counts = boundaryCounts([tl], samples);
      expect(counts.map((c) => c.arrived), [1, 0, 1, 1, 1]);
      expect(counts.map((c) => c.removed), [0, 1, 0, 0, 0]);
      expect(counts.last.cancelled, 1);
      expect(counts.last.wip(), 0);
      expect(boundaryCounts([tl], samples, containerId: 'A').map((c) => c.arrived), [1, 0, 1, 0, 0]);
      expect(boundaryCounts([tl], samples, containerId: 'B').map((c) => c.removed), [0, 0, 0, 0, 0]);
      final seeded = buildTimelines(
        const [],
        seeds: [
          EntitySeed(
            's',
            createdAt: DateTime.utc(2026, 9, 1),
            deletedAt: DateTime.utc(2026, 9, 2),
            initialStatus: 'ongoing',
          ),
        ],
      )['s']!;
      expect(seeded.deletedAt, DateTime.utc(2026, 9, 2));
      expect(seeded.currentStatus, 'ongoing');
      final interval = StatusInterval('todo', t('2026-09-01T00:00'));
      expect(
        interval.overlap(t('2026-09-02T00:00'), t('2026-09-03T00:00'), t('2026-09-02T12:00')),
        const Duration(hours: 12),
      );
      expect(interval.overlap(t('2026-09-03T00:00'), t('2026-09-04T00:00'), t('2026-09-02T12:00')), Duration.zero);
      expect(
        MembershipInterval(
          'A',
          t('2026-09-01T00:00'),
          end: t('2026-09-02T00:00'),
        ).containsInstant(t('2026-09-02T00:00')),
        isFalse,
      );
    });
  });

  group('quit calculator (T5.3.03)', () {
    QuitTracker tracker({
      String qd = '2026-09-01T21:00',
      QuitMode mode = QuitMode.abstain,
      bool autoSuccess = true,
      List<QuitRevision> revisions = const [],
      Decimal? cost,
    }) => QuitTracker(
      at(paris, qd),
      mode: mode,
      days: bounds,
      autoSuccess: autoSuccess,
      baselinePerDay: 24,
      unitCost: cost ?? Decimal.parse('0.5'),
      dailyLimit: mode == QuitMode.reduce ? 10 : null,
      revisions: revisions,
      timePerUnitMinutes: 5,
      lifeMinutesPerUnit: 20,
    );
    QuitLog q(HabitLogKind kind, String local, {double? value}) {
      final at_ = at(paris, local);
      return QuitLog('$kind@$local', kind, loggedAt: at_, localDate: bounds.dateOf(at_), value: value);
    }

    test('partial first day is pro-rated by time; fractional current day', () {
      final c = QuitCalculator(tracker(), const [], now: at(paris, '2026-09-03T12:00'));
      expect(c.days.length, 3);
      expect(c.days.first.fraction, near(3 / 24));
      expect(c.days.last.fraction, near(0.5));
      expect(c.days.last.status, QuitDayStatus.pending);
      expect(c.unitsAvoided, near(24 * (3 / 24 + 1 + 0.5)));
      expect(c.moneySaved, Decimal.parse('19.5'));
      expect(c.timeWonBackMinutes, near(39 * 5));
      expect(c.lifeRegainedMinutes, near(39 * 20));
      expect(c.cleanDays, 2);
      expect(c.dayStreak, 2);
      expect(c.bestDayStreak, 2);
      final before = QuitCalculator(tracker(), const [], now: at(paris, '2026-08-30T12:00'));
      expect(before.days, isEmpty);
    });

    test('explicit mode: unknown days, clean logs, lapses', () {
      final c = QuitCalculator(tracker(qd: '2026-09-01T00:00', autoSuccess: false), [
        q(HabitLogKind.clean, '2026-09-01T21:00'),
        q(HabitLogKind.relapse, '2026-09-02T18:00', value: 2),
      ], now: at(paris, '2026-09-04T00:00'));
      expect(c.cleanDays, 1);
      expect(c.unknownDays, 1);
      expect(c.abstinentDays, 2);
      expect(c.days[1].status, QuitDayStatus.used);
      expect(c.cleanDayShare.valueOrNull, near(1 / 3));
      expect(c.moneySpent, Decimal.fromInt(1));
    });

    test('attempts, restarts and abstinence intervals; uses before qd ignored', () {
      final c = QuitCalculator(tracker(qd: '2026-09-01T00:00'), [
        q(HabitLogKind.relapse, '2026-08-30T12:00'),
        q(HabitLogKind.restart, '2026-08-31T12:00'),
        q(HabitLogKind.relapse, '2026-09-03T12:00'),
        q(HabitLogKind.restart, '2026-09-04T12:00'),
        q(HabitLogKind.relapse, '2026-09-06T12:00'),
      ], now: at(paris, '2026-09-08T12:00'));
      expect(c.uses.length, 2);
      expect(c.restarts.length, 1);
      expect(c.attempts.length, 2);
      expect(c.attempts.first.endedBy, QuitEndReason.restart);
      expect(c.attempts.first.uses.length, 1);
      expect(c.attempts.last.isCurrent, isTrue);
      expect(c.abstinenceIntervals.map((i) => i.endedBy), [
        QuitEndReason.use,
        QuitEndReason.restart,
        QuitEndReason.use,
        QuitEndReason.ongoing,
      ]);
      expect(c.currentAbstinenceStart, at(paris, '2026-09-06T12:00'));
      expect(c.longestAbstinence, const Duration(days: 2, hours: 12));
      expect(c.dayStreak, 1);
    });

    test('heavy lapses floor units and money at 0; missing economics', () {
      final c = QuitCalculator(tracker(qd: '2026-09-01T00:00'), [
        q(HabitLogKind.relapse, '2026-09-01T12:00', value: 100),
      ], now: at(paris, '2026-09-02T00:00'));
      expect(c.unitsAvoided, 0);
      expect(c.moneySaved, Decimal.zero);
      expect(c.unitsAvoidedByDay.first.$2, -76);
      final noCost = QuitCalculator(
        QuitTracker(at(paris, '2026-09-01T00:00'), mode: QuitMode.abstain, days: bounds, baselinePerDay: 10),
        [q(HabitLogKind.relapse, '2026-09-01T12:00')],
        now: at(paris, '2026-09-03T00:00'),
      );
      expect(noCost.moneySaved, Decimal.zero);
      expect(noCost.moneySpent, Decimal.zero);
      expect(noCost.savingsProjection, isNull);
      expect(noCost.timeWonBackMinutes, isNull);
      expect(noCost.lifeRegainedMinutes, isNull);
      expect(noCost.moneySavedByDay.first.$2, Decimal.zero);
      final t = tracker(revisions: [QuitRevision(d('2026-09-05'), unitCost: Decimal.one)]);
      expect(t.economicsOn(d('2026-09-10')).unitCost, Decimal.one);
      expect(t.economicsOn(d('2026-09-10')).baselinePerDay, 24, reason: 'null fields fall back');
      expect(t.economicsOn(d('2026-09-01')).unitCost, Decimal.parse('0.5'));
    });

    test('reduce mode: today over the limit breaks the streak', () {
      final c = QuitCalculator(tracker(qd: '2026-09-01T00:00', mode: QuitMode.reduce), [
        q(HabitLogKind.use, '2026-09-01T12:00', value: 5),
        q(HabitLogKind.use, '2026-09-02T12:00', value: 12),
        q(HabitLogKind.use, '2026-09-03T12:00', value: 11),
      ], now: at(paris, '2026-09-03T18:00'));
      expect(c.withinLimitDays, 1);
      expect(c.dayStreak, 0);
      expect(c.bestDayStreak, 1);
      expect(c.days.first.withinLimit, isTrue);
    });

    test('DST: a counter across the October change stays exact', () {
      final c = QuitCalculator(tracker(qd: '2026-10-24T12:00'), const [], now: at(paris, '2026-10-26T12:00'));
      expect(c.timeSinceQuit, const Duration(hours: 49));
      expect(c.days.map((x) => x.fraction), [near(0.5), 1, near(0.5)]);
      expect(c.unitsAvoided, near(48));
    });

    test('milestones: single point, range window, ETA, next', () {
      final start = at(paris, '2026-09-01T00:00');
      final table = [
        const QuitMilestone('8h', tMin: Duration(hours: 8)),
        const QuitMilestone('24h-3d', tMin: Duration(hours: 24), tMax: Duration(days: 3)),
        const QuitMilestone('1w', tMin: Duration(days: 7)),
        const QuitMilestone('zero', tMin: Duration.zero),
      ];
      final p = milestoneProgress(table, abstinenceStart: start, now: at(paris, '2026-09-02T12:00'));
      expect(p.map((m) => m.milestone.id), ['zero', '8h', '24h-3d', '1w']);
      expect(p[0].progress, 1);
      expect(p[1].state, MilestoneState.done);
      expect(p[2].state, MilestoneState.inWindow);
      expect(p[2].isNext, isTrue);
      expect(p[2].progress, near(36 / 72));
      expect(p[2].eta, start.add(const Duration(days: 3)));
      expect(p[3].state, MilestoneState.upcoming);
      expect(p[3].isNext, isFalse);
      expect(p[3].eta, start.add(const Duration(days: 7)));
      expect(defaultDayMilestones.map((m) => m.tMin.inDays), [1, 3, 7, 14, 30, 60, 90, 180, 365]);
      expect(table[1].isRange, isTrue);
    });

    test('lapse vs relapse (SRNT) and the Russell Standard', () {
      final start = d('2026-03-01');
      List<(LocalDate, double)> uses(List<int> days, [double amount = 1]) => [
        for (final x in days) (start.plusDays(x - 1), amount),
      ];
      final seven = classifyRelapse(start, uses([10, 11, 12, 13, 14, 15, 16]));
      expect(seven.isRelapse, isTrue);
      final single = classifyRelapse(start, uses([10]));
      expect(single.isRelapse, isFalse);
      expect(single.lapseDays, 1);
      final blocks = classifyRelapse(start, uses([10, 18]));
      expect(blocks.isRelapse, isTrue);
      expect(blocks.rule, RelapseRule.twoConsecutiveBlocks);
      expect(blocks.detectedOn, start.plusDays(17));
      final consecutiveOnly = classifyRelapse(start, uses([15, 16, 17, 18, 19, 20, 21]));
      expect(consecutiveOnly.rule, RelapseRule.sevenConsecutiveDays);
      expect(consecutiveOnly.detectedOn, start.plusDays(20));
      final russell = classifyRelapse(start, [
        ...uses([3], 10),
        ...uses([20, 30], 2),
      ]);
      expect(russell.unitsAfterGrace, 4);
      expect(russell.russellSustained, isTrue);
      final heavy = classifyRelapse(start, uses([20, 30], 3));
      expect(heavy.russellSustained, isFalse);
      expect(classifyRelapse(start, [(start.minusDays(2), 1)]).lapseDays, 0);
      expect(
        savingsGoalEtaDays(saved: Decimal.fromInt(10), goal: Decimal.fromInt(5), dailySaving: Decimal.one).valueOrNull,
        0,
      );
      expect(
        savingsGoalEtaDays(saved: Decimal.zero, goal: Decimal.fromInt(5), dailySaving: Decimal.zero),
        const NotApplicable<int>(Reasons.zeroDenominator),
      );
    });
  });
}
