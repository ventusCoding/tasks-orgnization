import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/goals.dart';
import 'package:everslot_metrics/src/habit_metrics.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/quit_calculator.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/strength.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:test/test.dart';

import 'support/support.dart';

final ZoneClock paris = tzClock('Europe/Paris');
final DayBoundaries bounds = DayBoundaries(paris);

HabitPeriod dayPeriod(LocalDate date, HabitGoal goal, {bool due = true}) => HabitPeriod(
  date.toIso(),
  kind: HabitPeriodKind.day,
  startDate: date,
  endDate: date,
  windowStart: bounds.startOf(date),
  windowEnd: bounds.endOf(date),
  goal: goal,
  due: due,
);

HabitGoal goalFrom(Map<String, Object?> g) => HabitGoal(
  HabitGoalType.values.byName(g['type']! as String),
  target: (g['target'] as num?)?.toDouble(),
  op: g['op'] == null ? TargetOp.gte : TargetOp.values.byName(g['op']! as String),
);

HabitLog progress(String date, double value, {String time = '12:00', String? created}) => HabitLog(
  'p-$date-$time',
  HabitLogKind.progress,
  loggedAt: at(paris, '${date}T$time'),
  localDate: d(date),
  value: value,
  occurrenceKey: date,
  createdAt: created == null ? null : at(paris, created),
);

HabitLog state(HabitLogKind kind, String date, {String time = '12:00', String? note, int? mood}) =>
    HabitLog(
      '$kind-$date-$time',
      kind,
      loggedAt: at(paris, '${date}T$time'),
      localDate: d(date),
      occurrenceKey: date,
      note: note,
      mood: mood,
    );

void main() {
  group('habit_pushups_month (T6.5.04–T6.5.11)', () {
    final fx = loadFixture('habit_pushups_month');
    final e = fx['expect']! as Map<String, Object?>;
    final goal = goalFrom((fx['habit']! as Map)['goal']! as Map<String, Object?>);
    final now = at(paris, fx['now']! as String);
    final logs = [
      for (final l in (fx['logs']! as List).cast<Map<String, Object?>>())
        HabitLog(
          '${l['kind']}-${l['date']}',
          HabitLogKind.values.byName(l['kind']! as String),
          loggedAt: at(paris, l['at']! as String),
          localDate: d(l['date']! as String),
          value: (l['value'] as num?)?.toDouble(),
          occurrenceKey: l['key'] as String?,
          createdAt: l['created'] == null ? null : at(paris, l['created']! as String),
          note: l['note'] as String?,
        ),
    ];
    final range = DateRange(d('2026-09-01'), d('2026-09-30'));
    final results = evaluateHabitPeriods(
      [for (final date in range.dates) dayPeriod(date, goal)],
      logs,
      now: now,
      today: d('2026-10-01'),
    );

    test('success & outcomes (HB-H-05/06)', () {
      final s = successRate(results);
      expect(s.valueOrNull, near(e['successRate']! as num));
      expect((s as Value<double>).sampleSize, 29);
      expect(s.interval, isNotNull);
      final c = outcomeCounts(results);
      final o = e['outcomes']! as Map<String, Object?>;
      expect(c.success, o['success']);
      expect(c.partial, o['partial']);
      expect(c.failed, o['failed']);
      expect(c.missed, o['missed']);
      expect(c.skipped, o['skipped']);
      expect(c.excused, o['excused']);
      expect(c.total, o['total']);
      expect(totalRepetitions(logs), e['totalRepetitions']);
    });

    test('target & volume (HB-H-10/11/12/14/15)', () {
      expect(totalVolume(results), e['totalVolume']);
      expect(
        targetProgress(results, from: range.start, to: range.end).valueOrNull,
        near(e['targetProgress']! as num),
      );
      final pf = partialAndFulfilment(results);
      expect(pf.partialShare.valueOrNull, near(e['partialShare']! as num));
      expect(pf.meanFulfilment.valueOrNull, near(e['meanFulfilment']! as num));
      final avg = volumeAverages(results);
      expect(avg.perActiveDay.valueOrNull, near(e['perActiveDay']! as num));
      expect(avg.perScheduledDay.valueOrNull, near(e['perScheduledDay']! as num));
      expect(valueDistribution(results).median.valueOrNull, e['valueMedian']);
      final history = historyBuckets(
        results,
        from: range.start,
        to: range.end,
        granularity: Granularity.month,
      );
      expect(history.successes.single.value, 24);
      expect(history.volume.single.value, 390);
      final records = habitRecords(
        results,
        from: range.start,
        to: range.end,
        currentPeriodStart: d('2026-09-28'),
      );
      expect(records.day.valueOrNull!.value, 15);
      expect(records.day.valueOrNull!.isNew, isFalse);
      expect(records.week.valueOrNull!.value, 90);
      expect(records.month.valueOrNull!.value, 390);
      expect(habitCalendar(results)[d('2026-09-08')], PeriodStatus.missed);
    });

    test('streaks, recovery, consistency, completeness (HB-H-02/22/17/25)', () {
      final streaks = habitStreaks(results);
      expect(streaks.currentLength, e['currentStreak']);
      expect(streaks.bestLength, e['bestStreak']);
      expect(streaks.top10.first.length, 8);
      final r = recovery(results);
      expect(r.recoveryRate.valueOrNull, near(e['recoveryRate']! as num));
      expect(r.longestGap, e['longestGap']);
      expect(r.comebacks, e['comebacks']);
      final ci = consistencyIndex(results, from: d('2026-09-30'), to: d('2026-09-30'));
      expect(ci.l2.single.value, near(e['consistencyL2At30']! as num));
      expect(ci.index.valueOrNull, near(e['consistencyL2At30']! as num));
      final dc = dataCompleteness(results);
      expect(dc.loggedRatio.valueOrNull, near(e['loggedRatio']! as num));
      expect(dc.unknownUnits, e['unknownUnits']);
      expect(dc.backfillShare.valueOrNull, near(e['backfillShare']! as num));
      expect(skipExcuseReasons(logs), [(label: 'sore shoulder', count: 1)]);
    });

    test('weekday profile and strength with momentum', () {
      final profile = habitWeekdayProfile(results);
      expect(profile[Weekday.tuesday]!.valueOrNull, near(0.5));
      final days = habitDayFacts(results);
      final strength = habitStrength(
        days,
        today: d('2026-09-30'),
        frequencyOn: (_) => const StrengthFrequency.daily(),
        kind: StrengthGoalKind.atLeast,
        targetOn: (_) => 15,
      );
      expect(strength.series.length, 30);
      expect(strength.series.firstWhere((p) => p.date == d('2026-09-15')).scored, isFalse);
      expect(strength.current, inInclusiveRange(0.7, 0.9));
      final momentum = scoreMomentum(strength).valueOrNull!;
      expect(momentum.momentum, Momentum.rising);
      final pace = habitGoalPace(
        GoalSpec(500, start: d('2026-09-01'), end: d('2026-09-30')),
        results,
        asOf: d('2026-09-30'),
      );
      expect(pace.actual, 390);
      expect(pace.status, GoalStatus.atRisk);
    });
  });

  group('habits_portfolio (T6.5.13, T6.5.14, T6.5.01)', () {
    final fx = loadFixture('habits_portfolio');
    final e = fx['expect']! as Map<String, Object?>;
    final now = at(paris, fx['now']! as String);
    final today = d('2026-09-28');
    final days = [for (final s in (fx['days']! as List).cast<String>()) d(s)];
    final series = <String, HabitSeries>{};
    final firstDaySlots = <PeriodResult>[];
    for (final h in (fx['habits']! as List).cast<Map<String, Object?>>()) {
      final id = h['id']! as String;
      final goal = goalFrom(h['goal']! as Map<String, Object?>);
      final logs = <HabitLog>[];
      var results = <PeriodResult>[];
      switch (h['schedule']) {
        case 'daily':
          final values = (h['values'] as Map?)?.cast<String, Object?>();
          for (final entry in values?.entries ?? const <MapEntry<String, Object?>>[]) {
            if (entry.value != null) logs.add(progress(entry.key, (entry.value! as num).toDouble()));
          }
          for (final dd in (h['done'] as List? ?? const []).cast<String>()) {
            logs.add(state(HabitLogKind.done, dd));
          }
          final weekdaysFrom = h['weekdaysFrom'] == null ? null : d(h['weekdaysFrom']! as String);
          final pause = (h['pause'] as List?)?.cast<String>();
          results = evaluateHabitPeriods(
            [
              for (final date in days)
                dayPeriod(
                  date,
                  goal,
                  due: weekdaysFrom == null || date.isBefore(weekdaysFrom) || !date.weekday.isWeekend,
                ),
            ],
            logs,
            now: now,
            today: today,
            pauses: pause == null ? const [] : [HabitPause(d(pause[0]), end: d(pause[1]))],
          );
        case 'quota3':
          for (final dd in (h['done']! as List).cast<String>()) {
            logs.add(state(HabitLogKind.done, dd));
          }
          results = evaluateHabitPeriods(
            [
              for (final start in [days.first, days.first.plusDays(7)])
                HabitPeriod(
                  'week:${start.toIso()}',
                  kind: HabitPeriodKind.quota,
                  startDate: start,
                  endDate: start.plusDays(6),
                  windowStart: bounds.startOf(start),
                  windowEnd: bounds.endOf(start.plusDays(6)),
                  goal: goal,
                  quotaTimes: 3,
                ),
            ],
            logs,
            now: now,
            today: today,
          );
        case 'slots8':
          final done = (h['slotsDone']! as Map).cast<String, int>();
          for (final date in days) {
            final slots = <HabitPeriod>[];
            for (var k = 0; k < 8; k++) {
              final hh = (9 + k).toString().padLeft(2, '0');
              final key = '${date.toIso()}T$hh:00';
              slots.add(
                HabitPeriod(
                  key,
                  kind: HabitPeriodKind.slot,
                  startDate: date,
                  endDate: date,
                  windowStart: at(paris, key),
                  windowEnd: k == 7 ? bounds.endOf(date) : at(paris, '${date.toIso()}T${(10 + k).toString().padLeft(2, '0')}:00'),
                  matchStart: at(paris, key).subtract(const Duration(minutes: 30)),
                  goal: goal,
                ),
              );
              if (k < done[date.toIso()]!) {
                logs.add(
                  HabitLog(
                    'slot-$key',
                    HabitLogKind.done,
                    loggedAt: at(paris, key).add(Duration(minutes: k * 3)),
                    localDate: date,
                    occurrenceKey: key,
                  ),
                );
              }
            }
            final slotResults = evaluateHabitPeriods(slots, logs, now: now, today: today);
            results.add(
              rollUpSlots(
                date,
                slotResults,
                windowStart: bounds.startOf(date),
                windowEnd: bounds.endOf(date),
              ),
            );
            if (date == days.first) firstDaySlots.addAll(slotResults);
          }
      }
      series[id] = HabitSeries(id, results: results, logs: logs, categoryId: h['category'] as String?);
    }
    final all = series.values.toList();

    test('slots: punctuality and multi-times per day (HB-H-20/21)', () {
      expect(slotPunctuality(firstDaySlots).valueOrNull, near(1));
      final meds = series['meds']!.results.first;
      expect(meds.status, PeriodStatus.done);
      final multi = multiTimesPerDay([meds]);
      expect(multi.perDay[days.first]!.$1, 8);
      expect(multi.meanSpacing.valueOrNull, near(63));
      expect(multi.medianSpacing.valueOrNull, near(63));
    });

    test('per-habit success rates and streaks', () {
      final rates = (e['successRates']! as Map).cast<String, num>();
      for (final id in rates.keys) {
        expect(successRate(series[id]!.results).valueOrNull, near(rates[id]!), reason: id);
      }
      final streaks = (e['streaks']! as Map).cast<String, List<Object?>>();
      for (final id in streaks.keys) {
        final s = habitStreaks(series[id]!.results);
        expect([s.currentLength, s.bestLength], streaks[id], reason: id);
      }
      final readNotDue = [
        for (final r in series['read']!.results)
          if (r.status == PeriodStatus.notDue) r.key,
      ];
      expect(readNotDue, e['readNotDue']);
      final limit = limitMetricsOf(series['coffee']!.results);
      expect(limit.withinLimitShare.valueOrNull, near(e['coffeeWithinLimit']! as num));
      expect(limit.excess, e['coffeeExcess']);
    });

    test('section metrics HB-X-01…04, 08, 09, 10, 12, 14', () {
      final tp = e['todayProgress']! as Map<String, Object?>;
      expect(todayProgress(all, today: d(tp['date']! as String)).valueOrNull, near(tp['value']! as num));
      final range = DateRange(days.first, days.last);
      final perfect = perfectDays(all, range: range, today: today);
      expect(perfect.perfectDays.map((x) => x.toIso()), e['perfectDays']);
      expect(perfect.streak.bestLength, e['perfectStreakBest']);
      expect(perfect.streak.currentLength, e['perfectStreakCurrent']);
      final trend = adherenceTrend(all, range: range);
      expect(trend.weekly.map((p) => p.value), [
        for (final v in (e['weekly']! as List).cast<num>()) near(v),
      ]);
      expect(trend.lastVsPrevious.delta.valueOrNull, near(e['weeklyDeltaPp']! as num));
      final ranking = bestAndWorstHabits(all, from: days.first, to: days.last);
      expect(ranking.map((r) => r.$1), e['ranking']);
      final areas = habitAreas(all);
      expect(areas['mind']!.successRate.valueOrNull, near(20 / 23));
      expect(checkInVolume(all, range: range).first.value, greaterThan(0));
      expect(sectionDataCompleteness(all).closedUnits, greaterThan(50));
      final heat = dailyCompletionHeatmap(all, range: range);
      expect(heat.first.value, 1);
      final portfolio = habitPortfolio(
        [
          HabitSeries('a', results: const [], createdOn: d('2026-06-01'), archivedOn: d('2026-07-15')),
          HabitSeries('b', results: const [], createdOn: d('2026-06-01')),
          HabitSeries('c', results: const [], createdOn: d('2026-09-20')),
        ],
        range: DateRange(d('2026-06-01'), d('2026-09-30')),
        today: today,
      );
      expect(portfolio.activeAt30.valueOrNull, 1);
      expect(portfolio.activeAt90.valueOrNull, 0.5);
      expect(portfolio.created.first.value, 2);
      expect(portfolio.archived[1].value, 1);
      expect(habitCoOccurrence(all), isEmpty, reason: 'fewer than 21 overlapping days');
    });
  });

  test('Loop parity vectors (strength_loop.json)', () {
    final fx = loadFixture('strength_loop');
    final start = d(fx['start']! as String);
    for (final c in (fx['cases']! as List).cast<Map<String, Object?>>()) {
      final values = (c['values']! as List).cast<num>();
      final skips = (c['skips']! as List).cast<int>().toSet();
      final freq = StrengthFrequency(c['num']! as int, c['den']! as int);
      final kind = StrengthGoalKind.values.byName(c['kind']! as String);
      final result = computeStrength(
        [
          for (var i = 0; i < values.length; i++)
            StrengthDay(
              start.plusDays(i),
              value: values[i].toDouble(),
              frequency: freq,
              skipped: skips.contains(i),
              target: (c['target'] as num?)?.toDouble(),
              expectedInDay: freq.f > 1 ? freq.numerator.toDouble() : 1,
            ),
        ],
        kind: kind,
      );
      final expected = (c['expected']! as List).cast<num>();
      for (var i = 0; i < expected.length; i++) {
        expect(result.series[i].score, near(expected[i], 1e-9), reason: '${c['name']} day $i');
        expect(result.series[i].score, inInclusiveRange(0, 1));
      }
    }
    final a = fx['acceptance']! as Map<String, Object?>;
    expect(strengthMultiplier(0.375), near(a['multiplierF0375']! as num, 1e-6));
  });

  group('acceptance examples', () {
    test('limit {1, 2, 3, 5, 0} with limit 2 (HB-H-16)', () {
      final m = limitMetrics([1, 2, 3, 5, 0], 2);
      expect(m.withinLimitShare.valueOrNull, near(3 / 5));
      expect(m.excess, 4);
      expect(m.credits, [1, 1, 0.5, 0, 1]);
      expect(limitMetricsOf(const []).withinLimitShare, isA<NotApplicable<double>>());
    });

    test('recovery D M D M M D M (HB-H-22)', () {
      final start = d('2026-09-01');
      const pattern = 'DMDMMDM';
      final results = [
        for (var i = 0; i < pattern.length; i++)
          PeriodResult(
            'u$i',
            kind: HabitPeriodKind.day,
            startDate: start.plusDays(i),
            endDate: start.plusDays(i),
            windowStart: bounds.startOf(start.plusDays(i)),
            windowEnd: bounds.endOf(start.plusDays(i)),
            status: pattern[i] == 'D' ? PeriodStatus.done : PeriodStatus.missed,
            achieved: pattern[i] == 'D' ? 1 : 0,
            target: 1,
            goal: const HabitGoal.check(),
          ),
      ];
      final r = recovery(results);
      expect(r.recoveryRate.valueOrNull, near(2 / 3));
      expect(r.longestGap, 2);
      expect(r.comebacks, 0);
      expect(r.meanGap.valueOrNull, near(4 / 3));
      final comeback = recovery([
        results[0],
        results[1],
        results[3],
        results[4].withStatus(PeriodStatus.missed),
        results[5],
      ]);
      expect(comeback.comebacks, 1);
      final formation = formationDays(results, today: start.plusDays(6));
      expect(formation, const NotApplicable<int>(Reasons.notReached));
      final allDone = [for (final x in results) x.withStatus(PeriodStatus.done)];
      expect(formationDays(allDone, today: start.plusDays(30)).valueOrNull, 1);
      expect(formationDays(const [], today: start), const NotApplicable<int>(Reasons.noData));
    });

    test('check-ins at 23:30 and 00:30 with a 04:00 day start (HB-H-19)', () {
      final nightOwl = DayBoundaries(paris, dayStartsAt: LocalTime(4, 0));
      final logs = [
        HabitLog('a', HabitLogKind.done, loggedAt: at(paris, '2026-09-10T23:30'), localDate: d('2026-09-10')),
        HabitLog('b', HabitLogKind.done, loggedAt: at(paris, '2026-09-11T00:30'), localDate: d('2026-09-10')),
      ];
      expect(nightOwl.dateOf(logs[1].loggedAt), d('2026-09-10'));
      final times = checkInTimes(logs, bounds: nightOwl);
      expect(times.circular.valueOrNull!.meanMinuteRounded, 0);
      expect(times.matrix[Weekday.thursday]![23], 1);
      expect(times.matrix[Weekday.thursday]![0], 1);
    });

    test('freezes, momentum stable/falling, reminders, mood, quit roll-up, co-occurrence', () {
      final start = d('2026-09-01');
      PeriodResult unit(int i, PeriodStatus s, {int? mood}) => PeriodResult(
        'u$i',
        kind: HabitPeriodKind.day,
        startDate: start.plusDays(i),
        endDate: start.plusDays(i),
        windowStart: bounds.startOf(start.plusDays(i)),
        windowEnd: bounds.endOf(start.plusDays(i)),
        status: s,
        achieved: s == PeriodStatus.done ? 1 : 0,
        target: 1,
        goal: const HabitGoal.check(),
        entries: mood == null
            ? const []
            : [
                HabitLog(
                  'm$i',
                  HabitLogKind.note,
                  loggedAt: bounds.startOf(start.plusDays(i)).add(const Duration(hours: 20)),
                  localDate: start.plusDays(i),
                  mood: mood,
                ),
              ],
      );
      final results = [
        unit(0, PeriodStatus.done),
        unit(1, PeriodStatus.missed),
        unit(2, PeriodStatus.done),
        unit(3, PeriodStatus.missed),
        unit(4, PeriodStatus.done),
      ];
      final streaks = habitStreaks(results, freezesPerMonth: 1);
      expect(streaks.currentLength, 1);
      final usage = freezeUsage(streaks, freezesPerMonth: 1, today: d('2026-09-30'), habitStart: start);
      expect(usage.usedThisMonth, 1);
      expect(usage.grantedAllTime, 1);
      expect(usage.protectedKeys, ['u1']);
      StrengthResult flat(double v) => StrengthResult(
        [for (var i = 0; i < 40; i++) StrengthPoint(start.plusDays(i), v - i * 0.02)],
        initialScore: 0,
      );
      expect(scoreMomentum(flat(0.8)).valueOrNull!.momentum, Momentum.falling);
      expect(
        scoreMomentum(
          StrengthResult(
            [for (var i = 0; i < 10; i++) StrengthPoint(start.plusDays(i), 0.5)],
            initialScore: 0,
          ),
        ).valueOrNull!.momentum,
        Momentum.stable,
      );
      final reminders = reminderEffectiveness(
        reminders: [at(paris, '2026-09-01T08:00'), at(paris, '2026-09-02T08:00')],
        checkIns: [at(paris, '2026-09-01T08:20'), at(paris, '2026-09-02T10:00'), at(paris, '2026-08-31T09:00')],
      );
      expect(reminders.share.valueOrNull, near(1 / 3));
      expect(reminders.medianLatencyMinutes.valueOrNull, 20);
      final moodDays = habitDayFacts([
        unit(0, PeriodStatus.done, mood: 5),
        unit(1, PeriodStatus.missed, mood: 2),
        unit(2, PeriodStatus.done, mood: 4),
        unit(3, PeriodStatus.missed, mood: 3),
      ]);
      final mood = moodByOutcome(moodDays);
      expect(mood.doneMean.valueOrNull, 4.5);
      expect(mood.notDoneMean.valueOrNull, 2.5);
      expect(mood.test.hasValue, isTrue);
      final clock = paris;
      final calc = QuitCalculator(
        QuitTracker(
          at(clock, '2026-09-01T00:00'),
          mode: QuitMode.abstain,
          days: bounds,
          baselinePerDay: 10,
          unitCost: Decimal.parse('0.5'),
          lifeMinutesPerUnit: 20,
          currency: 'EUR',
        ),
        const [],
        now: at(clock, '2026-09-11T00:00'),
      );
      final rollUp = quitRollUp([calc, calc]);
      expect(rollUp.moneySaved['EUR'], Decimal.fromInt(100));
      expect(rollUp.unitsAvoided, near(200));
      expect(rollUp.lifeRegainedMinutes, near(4000));
      expect(rollUp.cleanDays, 20);
      final rng = math.Random(7);
      List<PeriodResult> randomHabit(bool Function(int) doneOn) => [
        for (var i = 0; i < 40; i++) unit(i, doneOn(i) ? PeriodStatus.done : PeriodStatus.missed),
      ];
      final base = [for (var i = 0; i < 40; i++) rng.nextBool()];
      final pairs = habitCoOccurrence([
        HabitSeries('x', results: randomHabit((i) => base[i])),
        HabitSeries('y', results: randomHabit((i) => base[i])),
        HabitSeries('z', results: randomHabit((i) => i.isEven)),
      ]);
      final xy = pairs.firstWhere((p) => p.a == 'x' && p.b == 'y');
      expect(xy.phi, near(1));
      expect(xy.significant, isTrue);
      expect(pairs.length, 3);
      final atRisk = atRiskHabits(
        [
          HabitSeries('s', results: const [], strength: flat(0.9)),
        ],
        today: start.plusDays(9),
      );
      expect(atRisk, [('s', HabitRisk.scoreDrop)]);
      final dist = strengthDistribution([
        HabitSeries('s', results: const [], strength: flat(0.9)),
        const HabitSeries('t', results: []),
      ]);
      expect(dist.ranked.single.$1, 's');
      expect(dist.falling, ['s']);
      expect(habitStrength(const [], today: start, frequencyOn: (_) => const StrengthFrequency.daily()).current, 0);
    });
  });
}
