import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/forecast.dart';
import 'package:everslot_metrics/src/global_metrics.dart';
import 'package:everslot_metrics/src/goals.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:test/test.dart';

import 'support/support.dart';

final ZoneClock paris = tzClock('Europe/Paris');

List<DaySectionFacts> factsOf(Map<String, Object?> fx) => [
  for (final r in (fx['days']! as List).cast<Map<String, Object?>>())
    DaySectionFacts(
      d(r['date']! as String),
      plannerPlanned: r['plannerPlanned'] as int?,
      plannerDone: r['plannerDone'] as int?,
      plannerDoneOnTime: r['plannerDoneOnTime'] as int?,
      plannedMinutes: (r['plannedMinutes'] as num?)?.toDouble(),
      actualMinutes: (r['actualMinutes'] as num?)?.toDouble(),
      habitsDue: r['habitsDue'] as int?,
      habitsDone: r['habitsDone'] as int?,
      itemsCompleted: r['itemsCompleted'] as int?,
      quitAbstinent: r['quitAbstinent'] as bool?,
      moneySaved: r['moneySaved'] == null
          ? null
          : Decimal.parse(r['moneySaved']! as String),
      cravings: r['cravings'] as int?,
    ),
];

double deltaOf(List<KpiDelta> deltas, String id) =>
    deltas.firstWhere((x) => x.metricId == id).comparison.delta.valueOrNull!;

void main() {
  final fx = loadFixture('overview_week');
  final facts = factsOf(fx);
  final e = fx['expect']! as Map<String, Object?>;

  group('overview_week (T6.7.01, T6.7.02, T6.7.19)', () {
    test('GL-01 today board', () {
      final t = e['todayBoard']! as Map<String, Object?>;
      final day = facts.firstWhere((f) => f.date == d(t['date']! as String));
      final board = todayBoard(
        day,
        wip: 3,
        blocked: 1,
        overdue: 1,
        nextUpId: 'o3',
      );
      expect(board.agendaProgress!.valueOrNull, near(t['agenda']! as num));
      expect(board.habitsProgress!.valueOrNull, near(t['habits']! as num));
      expect(board.perfectDay, t['perfectDay']);
      expect(board.cravingsToday, t['cravings']);
      expect(board.itemsCompletedToday, t['items']);
      expect(board.wip, 3);
      final empty = todayBoard(DaySectionFacts(d('2026-09-30')));
      expect(empty.agendaProgress, isNull);
      expect(empty.habitsProgress, isNull);
      expect(empty.perfectDay, isNull);
    });

    test('GL-02 week at a glance (to date vs the same days last week)', () {
      final w = e['weekAtAGlance']! as Map<String, Object?>;
      final glance = weekAtAGlance(facts, today: d(w['today']! as String));
      expect(
        deltaOf(glance.deltas, 'PL-X-01'),
        near(w['completionDeltaPp']! as num),
      );
      expect(
        deltaOf(glance.deltas, 'PL-X-12'),
        near(w['actualHoursDelta']! as num),
      );
      expect(
        deltaOf(glance.deltas, 'HB-X-04'),
        near(w['habitDeltaPp']! as num),
      );
      expect(deltaOf(glance.deltas, 'CL-X-04'), near(w['itemsDelta']! as num));
      expect(deltaOf(glance.deltas, 'QT-07'), near(w['moneyDelta']! as num));
      expect(glance.current.hasQuit, isTrue);
      final noQuit = weekAtAGlance([
        DaySectionFacts(d('2026-09-23'), itemsCompleted: 2),
      ], today: d('2026-09-23'));
      expect(noQuit.deltas.map((x) => x.metricId), ['CL-X-04']);
    });

    test('GL-03 weekly review builder', () {
      final w = e['weeklyReview']! as Map<String, Object?>;
      final ri = fx['reviewInput']! as Map<String, Object?>;
      final input = WeeklyReviewInput(
        streaks: [
          for (final s in (ri['streaks']! as List).cast<Map<String, Object?>>())
            (
              entityId: s['entityId']! as String,
              previous: s['previous']! as int,
              current: s['current']! as int,
            ),
        ],
        overdueTaskIds: (ri['overdueTaskIds']! as List).cast<String>(),
        blockedOrWaitingItemIds: (ri['blockedOrWaitingItemIds']! as List)
            .cast<String>(),
        staleListIds: (ri['staleListIds']! as List).cast<String>(),
        timeByCategory: [
          for (final c
              in (ri['timeByCategory']! as List).cast<Map<String, Object?>>())
            (
              categoryId: c['categoryId'] as String?,
              minutes: (c['minutes']! as num).toDouble(),
            ),
        ],
        previousTimeByCategory: [
          for (final c
              in (ri['previousTimeByCategory']! as List)
                  .cast<Map<String, Object?>>())
            (
              categoryId: c['categoryId'] as String?,
              minutes: (c['minutes']! as num).toDouble(),
            ),
        ],
        nextWeekLoad: [
          for (final c
              in (ri['nextWeekLoad']! as List).cast<Map<String, Object?>>())
            (
              date: d(c['date']! as String),
              plannedMinutes: (c['planned']! as num).toDouble(),
              capacityMinutes: (c['capacity']! as num).toDouble(),
            ),
        ],
      );
      final report = buildWeeklyReview(
        facts,
        weekStartDate: d(w['weekStart']! as String),
        input: input,
      );
      expect(
        report.current.completionVsPlan.valueOrNull,
        near(w['completionVsPlan']! as num),
      );
      final deltas = (w['headlineDeltas']! as Map).cast<String, num>();
      for (final id in deltas.keys) {
        expect(
          deltaOf(report.headline, id),
          near(deltas[id]!, 1e-9),
          reason: id,
        );
      }
      final items = report.headline.firstWhere((x) => x.metricId == 'CL-X-04');
      expect(
        items.comparison.deltaPct.valueOrNull,
        near(w['itemsPctDelta']! as num),
      );
      final perfect = report.wins.firstWhere(
        (x) => x.kind == ReviewItemKind.perfectDays,
      );
      expect(perfect.value, w['perfectDays']);
      expect([
        for (final x in report.wins)
          if (x.kind == ReviewItemKind.streakMilestone) [x.entityId, x.value],
      ], w['streakMilestones']);
      expect(report.attention.length, w['attentionCount']);
      expect([
        for (final x in report.attention)
          if (x.kind == ReviewItemKind.overbookedDay) x.date!.toIso(),
      ], w['overbooked']);
      expect(report.topCategories.map((c) => c.categoryId), w['topCategories']);
      expect(report.topCategories.first.delta.valueOrNull, w['workDelta']);
      expect(
        report.topCategories[1].delta,
        const NotApplicable<double>(Reasons.isNew),
      );
      expect(
        report.nextWeek.last.overbooked,
        isFalse,
        reason: 'days off are never flagged',
      );
    });

    test('GL-07 day score in the overview and the acceptance example', () {
      final ds = e['dayScore']! as Map<String, Object?>;
      final date = d(ds['date']! as String);
      final day = facts.firstWhere((f) => f.date == date);
      expect(listsMedianBefore(facts, date), 3.5);
      final score = dayScore(
        day,
        listsMedianPrior28: listsMedianBefore(facts, date),
      );
      expect(score.valueOrNull, near(ds['value']! as num));
      final series = dayScoreSeries(facts);
      expect(
        series.firstWhere((x) => x.date == date).score.valueOrNull,
        near(ds['value']! as num),
      );
      expect(series.first.deltaVsMedian, isA<NotApplicable<double>>());
      expect(series.last.deltaVsMedian.hasValue, isTrue);
      final acceptance = dayScore(
        DaySectionFacts(
          d('2026-09-01'),
          plannerPlanned: 5,
          plannerDone: 4,
          habitsDue: 4,
          habitsDone: 3,
          itemsCompleted: 2,
          quitAbstinent: true,
        ),
        listsMedianPrior28: 4,
      );
      expect(acceptance.valueOrNull!.round(), 76);
      // A section without data is excluded, not counted as 0.
      final partial = dayScore(
        DaySectionFacts(d('2026-09-01'), habitsDue: 4, habitsDone: 3),
      );
      expect(partial.valueOrNull, near(75));
      expect(
        dayScore(DaySectionFacts(d('2026-09-01'))),
        const NotApplicable<double>(Reasons.noData),
      );
      final weighted = dayScore(
        DaySectionFacts(
          d('2026-09-01'),
          plannerPlanned: 2,
          plannerDone: 2,
          quitAbstinent: false,
        ),
        weights: const DayScoreWeights(planner: 3),
      );
      expect(weighted.valueOrNull, near(75));
    });

    test('GL-04 review streak, GL-05 per-day comparison, GL-11 heatmap, GL-14 year', () {
      final streak = weeklyReviewStreak(
        {d('2026-09-07'), d('2026-09-14')},
        firstWeekStart: d('2026-08-31'),
        currentWeekStart: d('2026-09-21'),
      );
      expect(streak.currentLength, 2);
      final month = perDayComparison(
        currentSum: 62,
        currentDays: 31,
        previousSum: 56,
        previousDays: 28,
      );
      expect(month.delta.valueOrNull, near(0));
      final heat = yearActivityHeatmap(facts);
      expect(heat.first.total, 4 + 4 + 3);
      expect(
        heat.firstWhere((x) => x.date == d('2026-09-24')).abstinent,
        isFalse,
      );
      final year = yearInNumbers(facts);
      expect(year.tasksDone, 49);
      expect(year.itemsCompleted, 37);
      expect(year.habitCheckIns, 47);
      expect(year.moneySaved, Decimal.parse('180.7'));
      expect(year.abstinentDays, 13);
      expect(year.busiestMonth, 9);
      expect(year.busiestWeekday, Weekday.friday);
      expect(
        archetypes(
          medianFirstTaskStartMinute: 7 * 60 + 30,
          medianLastCheckInMinute: 22 * 60 + 15,
          deepWorkHours: 210,
          habitSuccess: 0.9,
          itemsCompleted: 400,
        ),
        Archetype.values,
      );
      expect(archetypes(), isEmpty);
    });
  });

  group('GL-06 personal records', () {
    test(
      'new record only in the current period; backfill is not announced',
      () {
        final series = [
          (date: d('2026-08-01'), value: 35.0, denominator: null),
          (date: d('2026-09-20'), value: 42.0, denominator: null),
        ];
        final r = personalRecord(
          'maxDayValue:pushups',
          series,
          currentPeriodStart: d('2026-09-14'),
        ).valueOrNull!;
        expect(r.isNew, isTrue);
        expect(r.previous, 35);
        expect(recordsToAnnounce([r], {}), [r]);
        expect(recordsToAnnounce([r], {r.announceKey}), isEmpty);
        final backfilled = personalRecord('maxDayValue:pushups', [
          ...series,
          (date: d('2026-07-01'), value: 50.0, denominator: null),
        ], currentPeriodStart: d('2026-09-14')).valueOrNull!;
        expect(backfilled.isNew, isFalse);
        expect(backfilled.value, 50);
        final weekly = personalRecord(
          'bestWeeklyCompletion',
          [
            (date: d('2026-09-07'), value: 1.0, denominator: 4),
            (date: d('2026-09-14'), value: 0.9, denominator: 12),
          ],
          currentPeriodStart: d('2026-09-14'),
          minBucketDenominator: 10,
        ).valueOrNull!;
        expect(weekly.value, 0.9);
        expect(weekly.isNew, isTrue);
        expect(
          personalRecord('x', const [], currentPeriodStart: d('2026-09-14')),
          isA<Insufficient<RecordEntry>>(),
        );
        expect(
          newRecordInsight(r)!.dedupeKey,
          'newRecord|maxDayValue:pushups|42.0',
        );
        expect(newRecordInsight(backfilled), isNull);
      },
    );
  });

  group('GL-08 day-of-week effects', () {
    test('significant weekday pattern, no pattern, insufficient', () {
      final start = d('2026-08-03');
      final strong = {
        for (var i = 0; i < 35; i++)
          start.plusDays(i): start.plusDays(i).weekday == Weekday.tuesday
              ? 0.9 + (i % 3) * 0.02
              : 0.4 + (i % 5) * 0.03,
      };
      final effect = dayOfWeekEffect(strong).valueOrNull!;
      expect(effect.best, Weekday.tuesday);
      expect(effect.significant, isTrue);
      expect(effect.test.epsilonSquared, greaterThan(0));
      final insight = bestWeekdayInsight(
        'habits',
        effect,
        today: d('2026-09-07'),
      );
      expect(insight!.args['weekday'], 'TU');
      // Every weekday gets the same multiset {0, .2, .4, .6, .8} over the 5 weeks → H = 0.
      final flat = {
        for (var i = 0; i < 35; i++)
          start.plusDays(i): ((i ~/ 7 + i % 7) % 5) / 5,
      };
      final none = dayOfWeekEffect(flat).valueOrNull!;
      expect(none.significant, isFalse);
      expect(
        bestWeekdayInsight('habits', none, today: d('2026-09-07')),
        isNull,
      );
      final short = {for (var i = 0; i < 20; i++) start.plusDays(i): 1.0};
      expect(dayOfWeekEffect(short), isA<Insufficient<WeekdayEffect>>());
      expect(dayOfWeekEffect(const {}), isA<Insufficient<WeekdayEffect>>());
    });
  });

  group('insights feed (T6.7.08)', () {
    final now = at(paris, '2026-09-21T08:00');
    final today = d('2026-09-21');

    test('each trigger fires exactly once within its cooldown', () {
      final candidates = <Insight>[
        ...streakMilestoneInsights('reading', 29, 30),
        ...streakMilestoneInsights('reading', 364, 400),
        ...moneyMilestoneInsights(
          'smoke',
          Decimal.fromInt(480),
          Decimal.fromInt(1100),
        ),
        healthMilestoneInsight('smoke', '72h', 2),
        ?risingOverdueInsight(12, 7, today: today),
        ?overbookedNextWeekInsight([
          d('2026-09-22'),
          d('2026-09-24'),
        ], weekStart: today),
        ...blockerClusterInsights([
          for (var i = 0; i < 3; i++)
            (
              cluster: 'supplier',
              startedAt: now.subtract(Duration(days: i * 3)),
            ),
          (cluster: 'legal', startedAt: now),
        ], now: now),
        ?followUpsDueInsight(3, today: today),
        ?staleListInsight('L7', 21),
        ?fallingCravingsInsight('smoke', last7: 6, previous7: 10, today: today),
        ?perfectWeekInsight([
          DaySectionFacts(d('2026-09-14'), habitsDue: 2, habitsDone: 2),
          DaySectionFacts(d('2026-09-15'), habitsDue: 0),
        ], weekStart: d('2026-09-14')),
        ?habitAtRiskInsight(
          'gym',
          quotaBehind: true,
          scoreDrop7Days: 0,
          today: today,
        ),
        ?estimationBiasInsight(const Value(0.27, sampleSize: 12), today: today),
        ...comebackInsights('journal', [
          (d('2026-09-10'), false),
          (d('2026-09-11'), false),
          (d('2026-09-12'), false),
          (d('2026-09-13'), true),
        ]),
        ...strengthThresholdInsights('meditation', [
          (d('2026-09-01'), 0.45),
          (d('2026-09-02'), 0.55),
          (d('2026-09-03'), 0.81),
          (d('2026-09-04'), 0.65),
          (d('2026-09-05'), 0.82),
        ]),
      ];
      expect(
        candidates
            .where((c) => c.trigger == InsightTrigger.streakMilestone)
            .map((c) => c.valueKey),
        ['30', '365', '400'],
      );
      expect(
        candidates
            .where((c) => c.trigger == InsightTrigger.moneyMilestone)
            .map((c) => c.valueKey),
        ['500', '1000'],
      );
      expect(
        candidates
            .where((c) => c.trigger == InsightTrigger.strengthThreshold)
            .length,
        3,
        reason: '50 %, 80 %, and 80 % again after dropping below 70 %',
      );
      final first = filterInsights(
        candidates,
        state: const InsightState(),
        now: now,
      );
      expect(first.length, candidates.length);
      final state = InsightState(
        firedAt: {for (final c in first) c.dedupeKey: now},
      );
      expect(filterInsights(candidates, state: state, now: now), isEmpty);
      // Tomorrow: daily-cooldown triggers may fire again for a new value; once-only ones never.
      final tomorrow = now.add(const Duration(days: 1));
      final again = filterInsights(
        [
          ?habitAtRiskInsight(
            'gym',
            quotaBehind: true,
            scoreDrop7Days: 0,
            today: today.plusDays(1),
          ),
          ?risingOverdueInsight(13, 7, today: today.plusDays(1)),
          ...streakMilestoneInsights('reading', 29, 30),
        ],
        state: state,
        now: tomorrow,
      );
      expect(again.map((c) => c.trigger), [InsightTrigger.habitAtRisk]);
      final muted = filterInsights(
        candidates,
        state: const InsightState(muted: {InsightTrigger.moneyMilestone}),
        now: now,
      );
      expect(
        muted.any((c) => c.trigger == InsightTrigger.moneyMilestone),
        isFalse,
      );
      expect(
        filterInsights(
          [...first, ...first],
          state: const InsightState(),
          now: now,
        ).length,
        first.length,
      );
    });

    test('non-firing conditions', () {
      expect(risingOverdueInsight(4, 1, today: today), isNull);
      expect(risingOverdueInsight(6, 5, today: today), isNull);
      expect(overbookedNextWeekInsight([today], weekStart: today), isNull);
      expect(followUpsDueInsight(2, today: today), isNull);
      expect(staleListInsight('L', 3), isNull);
      expect(
        fallingCravingsInsight('s', last7: 9, previous7: 10, today: today),
        isNull,
      );
      expect(
        fallingCravingsInsight('s', last7: 0, previous7: 4, today: today),
        isNull,
      );
      expect(
        perfectWeekInsight([
          DaySectionFacts(today, habitsDue: 2, habitsDone: 1),
        ], weekStart: today),
        isNull,
      );
      expect(
        habitAtRiskInsight(
          'h',
          quotaBehind: false,
          scoreDrop7Days: 0.05,
          today: today,
        ),
        isNull,
      );
      expect(
        habitAtRiskInsight(
          'h',
          quotaBehind: false,
          scoreDrop7Days: 0.2,
          today: today,
        ),
        isNotNull,
      );
      expect(
        estimationBiasInsight(const Value(0.27, sampleSize: 5), today: today),
        isNull,
      );
      expect(
        estimationBiasInsight(const Insufficient<double>(10, 3), today: today),
        isNull,
      );
      const flatTrend = TrendResult(
        TrendMethod.ols,
        slopePerBucket: 0.03,
        slopePerWeek: 0.03,
        n: 8,
        direction: TrendDirection.rising,
        significant: true,
        pValue: 0.01,
      );
      expect(
        significantTrendInsight(
          'gym',
          flatTrend,
          today: today,
        )!.args['ppPerWeek'],
        near(3),
      );
      const weak = TrendResult(
        TrendMethod.ols,
        slopePerBucket: 0.01,
        slopePerWeek: 0.01,
        n: 8,
        direction: TrendDirection.rising,
        significant: true,
      );
      expect(significantTrendInsight('gym', weak, today: today), isNull);
      expect(isStreakMilestone(500), isTrue);
      expect(isStreakMilestone(450), isFalse);
      expect(moneyThresholdsCrossed(Decimal.zero, Decimal.fromInt(9)), isEmpty);
      expect(moneyThresholdsCrossed(Decimal.zero, Decimal.fromInt(2600)), [
        10,
        50,
        100,
        250,
        500,
        1000,
        2500,
      ]);
    });
  });

  group('GL-09 goals, GL-10 data quality, GL-12 CSV, GL-15 XP, GL-17 budget, GL-18 forecast', () {
    test('goals dashboard and Monte Carlo goal forecast', () {
      final goal = GoalSpec(1000, start: d('2026-08-01'), end: d('2026-12-31'));
      final daily = {
        for (var i = 0; i < 42; i++)
          d('2026-09-21').minusDays(i): (i % 3 + 1) * 5.0,
      };
      final progress = goalProgress(
        goal,
        asOf: d('2026-09-21'),
        dailyValues: daily,
        actual: 400,
      );
      final done = goalProgress(goal, asOf: d('2026-09-21'), actual: 1000);
      final dash = goalsDashboard([progress, done]);
      expect(dash.active, [progress]);
      expect(dash.achieved, [done]);
      final forecast = goalForecast(
        progress,
        dailyValues: daily,
        random: math.Random(42),
        trials: 2000,
      ).valueOrNull!;
      // Mean progress 10/day → 600 remaining ≈ 60 days.
      expect(
        forecast.p50.daysUntil(d('2026-11-20')).abs(),
        lessThanOrEqualTo(3),
      );
      expect(
        forecast.p85.isAfter(forecast.p50) || forecast.p85 == forecast.p50,
        isTrue,
      );
      expect(
        forecast.p95.isAfter(forecast.p85) || forecast.p95 == forecast.p85,
        isTrue,
      );
      final stalled = goalForecast(
        progress,
        dailyValues: const {},
        random: math.Random(1),
      );
      expect(
        stalled,
        isA<
          Insufficient<
            ({
              LocalDate p50,
              LocalDate p85,
              LocalDate p95,
              ForecastWhen forecast,
            })
          >
        >(),
      );
    });

    test('data quality guidance', () {
      final dq = dataQuality(
        habitLoggedRatio: const Value(0.7),
        unknownUnits: 2,
        backfillShare: const Value(0.3),
        plannerActualTimeCoverage: const Value(0.4),
        pendingSyncChanges: 3,
      );
      expect(dq.guidanceKeys, [
        'logFromNotifications',
        'logSameDay',
        'trackTime',
        'syncPending',
      ]);
      final ok = dataQuality(
        habitLoggedRatio: const Value(0.95),
        unknownUnits: 0,
        backfillShare: const Value<double>(0),
        plannerActualTimeCoverage: const NotApplicable(Reasons.zeroDenominator),
        pendingSyncChanges: 0,
      );
      expect(ok.guidanceKeys, isEmpty);
    });

    test('CSV writer: ISO dates, dot decimals, quoting, BOM, RTL text', () {
      final csv = toCsv(
        ['date', 'value', 'label'],
        [
          [d('2026-09-21'), 0.5, 'plain'],
          [DateTime.utc(2026, 9, 21, 8), double.nan, 'a, "quoted" value'],
          [null, 3, 'قراءة'],
        ],
        headerComments: [
          'HB-H-05 success rate',
          'period 2026-09-14..2026-09-20',
        ],
        bom: true,
      );
      expect(csv.startsWith('﻿# HB-H-05 success rate\r\n'), isTrue);
      expect(csv, contains('date,value,label\r\n2026-09-21,0.5,plain\r\n'));
      expect(
        csv,
        contains('2026-09-21T08:00:00.000Z,,"a, ""quoted"" value"\r\n'),
      );
      expect(csv, endsWith(',3,قراءة\r\n'));
      expect(toCsv(['a'], const []), 'a\r\n');
    });

    test('XP rules: priorities, on-time bonus, streak bonus, cap and undo', () {
      final bounds = DayBoundaries(paris);
      final t = at(paris, '2026-09-21T09:00');
      expect(xpFor(XpEvent(t, XpSource.taskCompletion)), 10);
      expect(xpFor(XpEvent(t, XpSource.taskCompletion, priority: 2)), near(12));
      expect(
        xpFor(XpEvent(t, XpSource.taskCompletion, priority: 3, onTime: true)),
        near(16.5),
      );
      expect(xpFor(XpEvent(t, XpSource.taskCompletion, priority: 4)), 20);
      expect(xpFor(XpEvent(t, XpSource.habitCheckIn, streak: 50)), 15);
      expect(xpFor(XpEvent(t, XpSource.habitCheckIn, streak: 500)), 20);
      expect(xpFor(XpEvent(t, XpSource.checklistLeaf)), 5);
      expect(xpFor(XpEvent(t, XpSource.abstinentDay)), 20);
      final summary = xpSummary([
        for (var i = 0; i < 60; i++) XpEvent(t, XpSource.taskCompletion),
        XpEvent(t.add(const Duration(days: 1)), XpSource.abstinentDay),
        XpEvent(t.add(const Duration(days: 1)), XpSource.checklistLeaf),
        XpEvent(
          t.add(const Duration(days: 1)),
          XpSource.checklistLeaf,
          undone: true,
        ),
      ], bounds: bounds);
      expect(summary.perDay[d('2026-09-21')], 500);
      expect(summary.perDay[d('2026-09-22')], 20);
      expect(summary.total, 520);
      // Level thresholds 100·n^1.5: 100, 282.8, 519.6, 800 → level 3.
      expect(summary.level, 3);
      expect(summary.toNextLevel, near(800 - 520));
    });

    test('time budget de-duplicates habit/session overlaps', () {
      final budget = timeBudget(
        plannedTaskMinutes: 240,
        habitIntervals: [
          (at(paris, '2026-09-21T07:00'), at(paris, '2026-09-21T07:30')),
        ],
        sessionIntervals: [
          (at(paris, '2026-09-21T07:15'), at(paris, '2026-09-21T09:15')),
          (at(paris, '2026-09-21T10:00'), at(paris, '2026-09-21T11:00')),
        ],
      );
      expect(budget.habitMinutes, 30);
      expect(budget.trackedFocus, 180);
      expect(budget.overlap, 15);
      expect(budget.free, 16 * 60 - 240 - 30 + 15);
    });
  });

  group('GL-13 correlations explorer (T6.7.13, T6.1.24)', () {
    Map<LocalDate, double> randomSeries(
      math.Random rng, {
      bool binary = false,
      int days = 60,
    }) => {
      for (var i = 0; i < days; i++)
        d('2026-06-01').plusDays(i): binary
            ? (rng.nextBool() ? 1.0 : 0.0)
            : rng.nextDouble() * 10,
    };

    test('a planted relationship surfaces exactly that pair', () {
      final rng = math.Random(11);
      final run = randomSeries(rng, binary: true);
      final mood = {
        for (final e in run.entries)
          e.key: e.value * 3 + rng.nextDouble() * 1.5,
      };
      final findings = correlationExplorer([
        DailySeries('run', values: run, binary: true),
        DailySeries('mood', values: mood, binary: false),
        DailySeries('noise1', values: randomSeries(rng), binary: false),
        DailySeries(
          'noise2',
          values: randomSeries(rng, binary: true),
          binary: true,
        ),
        DailySeries(
          'noise3',
          values: randomSeries(rng),
          binary: false,
          groupKey: 'g',
        ),
        DailySeries(
          'noise4',
          values: randomSeries(rng),
          binary: false,
          groupKey: 'g',
        ),
      ]);
      final significant = [
        for (final f in findings)
          if (f.significant) f,
      ];
      expect(significant.length, 1);
      final planted = significant.single;
      expect({planted.a, planted.b}, {'run', 'mood'});
      expect(planted.lag, 0);
      expect(planted.method, CorrelationMethod.pointBiserial);
      expect(planted.stars, greaterThanOrEqualTo(4));
      expect(findings.first, planted);
      expect(
        findings.where((f) => {f.a, f.b}.containsAll({'noise3', 'noise4'})),
        isEmpty,
        reason: 'series sharing a group key are never tested together',
      );
      expect(
        correlationInsight(planted, today: d('2026-08-01'))!.entityId,
        contains('~'),
      );
      expect(correlationInsight(findings.last, today: d('2026-08-01')), isNull);
    });

    // Under the complete null, BH's chance of any discovery equals q, so the clean-seed share is
    // ≈ 1 − q: ≥ 90 % at the specified q = 0.10 and ≥ 95 % at q = 0.05.
    test('independent series: clean seeds ≥ 1 − q (all pairs, lags 0–3)', () {
      var clean10 = 0;
      var clean05 = 0;
      const seeds = 40;
      for (var seed = 0; seed < seeds; seed++) {
        final rng = math.Random(1000 + seed);
        final series = [
          for (var k = 0; k < 12; k++)
            DailySeries(
              's$k',
              values: randomSeries(rng, binary: k.isEven),
              binary: k.isEven,
            ),
        ];
        if (!correlationExplorer(series).any((f) => f.significant)) clean10++;
        if (!correlationExplorer(series, q: 0.05).any((f) => f.significant)) {
          clean05++;
        }
      }
      expect(clean10 / seeds, greaterThanOrEqualTo(0.90));
      expect(clean05 / seeds, greaterThanOrEqualTo(0.95));
    });

    test('guards: minimum paired days and per-group counts', () {
      final rng = math.Random(3);
      final short = correlationExplorer([
        DailySeries('a', values: randomSeries(rng, days: 15), binary: false),
        DailySeries('b', values: randomSeries(rng, days: 15), binary: false),
      ]);
      expect(short, isEmpty);
      final rare = {
        for (var i = 0; i < 40; i++)
          d('2026-06-01').plusDays(i): i < 3 ? 1.0 : 0.0,
      };
      final skewed = correlationExplorer([
        DailySeries('rare', values: rare, binary: true),
        DailySeries('num', values: randomSeries(rng, days: 40), binary: false),
      ]);
      expect(skewed, isEmpty);
      expect(correlationStars(0.8, 0.0001), 5);
      expect(correlationStars(0.25, 0.05), 1);
      expect(correlationStars(0.55, 0.005), 3);
    });
  });
}
