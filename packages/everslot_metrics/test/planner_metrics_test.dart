import 'dart:math' as math;

import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/planner_facts.dart';
import 'package:everslot_metrics/src/planner_metrics.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/strength.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:test/test.dart';

import 'support/support.dart';

final ZoneClock paris = tzClock('Europe/Paris');

/// Builds facts from the `planner_two_weeks` fixture rows (all times local, Europe/Paris).
List<PlannerOccurrenceFact> factsFromFixture(Map<String, Object?> fixture) {
  final rows = (fixture['occurrences']! as List).cast<Map<String, Object?>>();
  return [for (final r in rows) factFromRow(r)];
}

PlannerOccurrenceFact factFromRow(Map<String, Object?> r) {
  final start = ldt(r['start']! as String);
  final allDay = r['allDay'] == true;
  final minutes = allDay ? 1440 : (r['minutes']! as num).toInt();
  DateTime? inst(String? s) => s == null ? null : at(paris, s);
  return PlannerOccurrenceFact(
    r['task']! as String,
    r['key']! as String,
    seriesId: r['series']! as String,
    taskCreatedAt: at(paris, r['created']! as String),
    isRecurring: r['recurring'] == true,
    plannedStartLocal: start,
    plannedDurationMinutes: allDay ? null : minutes,
    plannedStart: paris.toInstant(start),
    plannedEnd: paris.toInstant(start.plusMinutes(minutes)),
    isAllDay: allDay,
    status: PlannerOccurrenceStatus.values.byName(r['status']! as String),
    trackingMode: TrackingMode.values.byName(r['mode']! as String),
    sessions: [
      for (final s
          in (r['sessions'] as List? ?? const []).cast<List<Object?>>())
        TimeSessionFact(
          at(paris, s[0]! as String),
          at(paris, s[1]! as String),
          taskId: r['task']! as String,
          categoryId: r['category'] as String?,
        ),
    ],
    doneAt: inst(r['doneAt'] as String?),
    cancelledAt: inst(r['cancelledAt'] as String?),
    categoryId: r['category'] as String?,
    priority: (r['priority'] as num?)?.toInt() ?? 0,
    skipReason: r['skipReason'] as String?,
    moves: [
      for (final m
          in (r['moves'] as List? ?? const []).cast<Map<String, Object?>>())
        RescheduleFact(
          at(paris, m['at']! as String),
          fromStart: ldt(m['from']! as String),
          toStart: ldt(m['to']! as String),
        ),
    ],
  );
}

PlannerOccurrenceFact simple(
  String id, {
  required String start,
  int minutes = 60,
  PlannerOccurrenceStatus status = PlannerOccurrenceStatus.scheduled,
  TrackingMode mode = TrackingMode.check,
  List<(String, String)> sessions = const [],
  String? doneAt,
  String created = '2026-09-01T08:00',
  String? category,
  List<RescheduleFact> moves = const [],
  String? cancelledAt,
  int? completionPercent,
  double? linked,
  String? actualStart,
  String? actualEnd,
}) {
  final s = ldt(start);
  return PlannerOccurrenceFact(
    id,
    start,
    seriesId: id,
    taskCreatedAt: at(paris, created),
    plannedStartLocal: s,
    plannedDurationMinutes: minutes,
    plannedStart: paris.toInstant(s),
    plannedEnd: paris.toInstant(s.plusMinutes(minutes)),
    status: status,
    trackingMode: mode,
    sessions: [
      for (final (a, b) in sessions)
        TimeSessionFact(at(paris, a), at(paris, b), taskId: id),
    ],
    doneAt: doneAt == null ? null : at(paris, doneAt),
    categoryId: category,
    moves: moves,
    cancelledAt: cancelledAt == null ? null : at(paris, cancelledAt),
    completionPercent: completionPercent,
    linkedChecklistProgress: linked,
    actualStart: actualStart == null ? null : at(paris, actualStart),
    actualEnd: actualEnd == null ? null : at(paris, actualEnd),
  );
}

void main() {
  final fixture = loadFixture('planner_two_weeks');
  final facts = factsFromFixture(fixture);
  final now = at(paris, fixture['now']! as String);
  final expect_ = fixture['expect']! as Map<String, Object?>;
  final settings = PlannerStatsSettings(
    workHours: defaultWorkHours,
    unavailableCategoryIds: const {'timeoff'},
  );
  final bounds = DayBoundaries(paris);
  List<PlannerOccurrenceFact> series(String id) =>
      facts.where((f) => f.seriesId == id).toList();
  PlannerOccurrenceFact occ(String task) =>
      facts.firstWhere((f) => f.taskId == task);

  group('planner_two_weeks fixture — series (T6.3.04)', () {
    final seriesExpect = expect_['series']! as Map<String, Object?>;
    for (final id in seriesExpect.keys) {
      test(id, () {
        final e = seriesExpect[id]! as Map<String, Object?>;
        final ledger = seriesLedger(series(id), now: now, settings: settings);
        expect(ledger.expected, e['E']);
        expect(ledger.excused, e['X']);
        expect(ledger.done, e['D']);
        expect(ledger.missed, e['M']);
        expect(ledger.skipped, e['K']);
        expect(
          ledger.adherence.valueOrNull,
          near(e['E'] == null ? 0 : e['adherence']! as num),
        );
        expect(ledger.missRate.valueOrNull, near(e['missRate']! as num));
        if (e['onTimeRate'] != null) {
          expect(
            onTimeCompletionRate(
              series(id),
              now: now,
              settings: settings,
            ).valueOrNull,
            near(e['onTimeRate']! as num),
          );
        }
        final streaks = seriesStreaks(series(id), now: now, settings: settings);
        expect(streaks.currentLength, e['currentStreak']);
        expect(streaks.bestLength, e['bestStreak']);
        if (e['bestSpanDays'] != null) {
          expect(streaks.best!.calendarSpanDays, e['bestSpanDays']);
        }
        if (e['totalDone'] != null) {
          expect(seriesTotalDone(series(id)), e['totalDone']);
          final last = seriesLastDone(
            series(id),
            clock: paris,
            today: d('2026-09-21'),
          );
          expect(last.valueOrNull!.date, d(e['lastDone']! as String));
          expect(last.valueOrNull!.daysSince, e['daysSinceLastDone']);
        }
        if (e['startOnTimeRate'] != null) {
          final t = startTimeliness(series(id));
          expect(t.onTimeRate.valueOrNull, near(e['startOnTimeRate']! as num));
          expect(
            t.meanDelayMinutes.valueOrNull,
            near(e['meanStartDelay']! as num),
          );
          expect(
            t.medianDelayMinutes.valueOrNull,
            near(e['medianStartDelay']! as num),
          );
          expect(t.p85DelayMinutes, isA<Insufficient<double>>());
        }
      });
    }
  });

  group('planner_two_weeks fixture — section week 2 (T6.3.07–T6.3.09)', () {
    final w = expect_['week2']! as Map<String, Object?>;
    final period = DateRange(
      d((w['period']! as List)[0] as String),
      d((w['period']! as List)[1] as String),
    );
    final inPeriod = facts
        .where((f) => f.plannedDate != null && period.contains(f.plannedDate!))
        .toList();

    test('plan snapshot PL-X-01/03', () {
      final snap = planSnapshot(
        facts,
        period: period,
        bounds: bounds,
        now: now,
      );
      expect(snap.planned.length, w['planned']);
      expect(snap.plannedDone.length, w['plannedDone']);
      expect(
        snap.completionRate.valueOrNull,
        near(w['completionRate']! as num),
      );
      expect(snap.unplanned.map((f) => f.taskId), w['unplanned']);
      expect(snap.movedOut.map((f) => f.taskId), w['movedOut']);
      expect(snap.movedIn.map((f) => f.taskId), w['movedIn']);
      final perDay = donePlannedPerDay(snap, bounds: bounds);
      expect(perDay.values.fold<int>(0, (a, v) => a + v.planned), w['planned']);
      expect(perDay[d('2026-09-14')]!.planned, 5);
    });

    test('next week counts the moved task as planned', () {
      final w3 = expect_['week3']! as Map<String, Object?>;
      final p3 = DateRange(
        d((w3['period']! as List)[0] as String),
        d((w3['period']! as List)[1] as String),
      );
      final snap = planSnapshot(
        facts,
        period: p3,
        bounds: bounds,
        now: at(paris, w3['now']! as String),
      );
      expect(
        snap.planned.map((f) => f.taskId),
        containsAll(w3['plannedIncludes']! as List),
      );
      // While the week is in progress (Monday 08:00) the 14:00 slot is not "to date" yet.
      final inProgress = planSnapshot(
        facts,
        period: p3,
        bounds: bounds,
        now: now,
      );
      expect(inProgress.planned, isEmpty);
    });

    test('on-time completion and overdue PL-X-05/06', () {
      expect(
        onTimeCompletionRate(
          inPeriod,
          now: now,
          settings: settings,
        ).valueOrNull,
        near(w['onTimeCompletionRate']! as num),
      );
      final overdue = overdueNow(
        facts,
        now: now,
        bounds: bounds,
        range: DateRange(d('2026-09-07'), d('2026-09-20')),
      );
      expect(overdue.count, w['overdueCount']);
      expect(overdue.byBucket[OverdueBucket.oneDay], 3);
      expect(overdue.newlyOverduePerWeek.map((p) => p.value), [0, 3]);
    });

    test('capacity PL-X-07…10', () {
      final report = capacityReport(
        facts,
        range: period,
        clock: paris,
        settings: settings,
      );
      expect(report.capacityMinutes, near(w['capacityMinutes']! as num));
      expect(report.plannedMinutes, near(w['plannedMinutes']! as num));
      expect(
        report.days.fold<double>(0, (a, x) => a + x.plannedClippedMinutes),
        near(w['plannedClippedMinutes']! as num),
      );
      expect(
        report.plannedUtilization.valueOrNull,
        near(w['plannedUtilization']! as num),
      );
      expect(report.overbookedDays, isEmpty);
      expect(report.actualUtilization, isA<Insufficient<double>>());
      expect(
        report.days.last.overbooked,
        isFalse,
        reason: 'days off are never flagged',
      );
    });

    test('allocation PL-X-13/15', () {
      final alloc = timeByCategory(inPeriod);
      expect(alloc.usedPlanned, w['timeByCategoryUsedPlanned']);
      final expected = w['timeByCategory']! as Map<String, Object?>;
      for (final s in alloc.slices) {
        expect(s.minutes, near(expected[s.key]! as num), reason: '${s.key}');
      }
      expect(alloc.slices.fold<double>(0, (a, s) => a + s.share), near(1));
      final ev = eventVsTaskMinutes(inPeriod);
      expect(ev.event, near(w['eventMinutes']! as num));
      expect(ev.task, near(w['taskMinutes']! as num));
    });
  });

  group('planner_two_weeks fixture — occurrences', () {
    final occExpect = expect_['occurrences']! as Map<String, Object?>;
    test('o4 snowballing reschedules (PL-T-08…11)', () {
      final e = occExpect['o4']! as Map<String, Object?>;
      final f = occ('o4');
      expect(rescheduleCount(f), e['reschedules']);
      expect(rescheduleDistance(f).inMinutes, e['distanceMinutes']);
      expect(netDrift(f).inMinutes, e['netDriftMinutes']);
      expect(isSnowballing(f), e['snowballing']);
      expect(plannerOutcome(f, now: now).name, e['outcome']);
    });
    test('o8 deep work (PL-X-38)', () {
      final e = occExpect['o8']! as Map<String, Object?>;
      final f = occ('o8');
      expect(f.actualMinutes, near(e['actualMinutes']! as num));
      final blocks = deepWorkBlocks([f]);
      expect(blocks.length, e['deepWorkBlocks']);
      expect(blocks.single.minutes, near(e['longestBlockMinutes']! as num));
      expect(focusSessions(f).valueOrNull!.pauses, 0);
    });
    test('o9 overdue and o11 all-day', () {
      final o9 = occExpect['o9']! as Map<String, Object?>;
      expect(plannerOutcome(occ('o9'), now: now).name, o9['outcome']);
      expect(
        overdueAge(occ('o9'), now: now).valueOrNull!.bucket.name,
        o9['overdueBucket'],
      );
      final o11 = occExpect['o11']! as Map<String, Object?>;
      expect(plannerOutcome(occ('o11'), now: now).name, o11['outcome']);
      expect(
        plannedDuration(occ('o11')),
        const NotApplicable<Duration>(Reasons.allDay),
      );
    });
  });

  group('per-occurrence acceptance (T6.3.02)', () {
    final f = simple(
      'x',
      start: '2026-09-10T09:00',
      status: PlannerOccurrenceStatus.done,
      mode: TrackingMode.timer,
      sessions: [
        ('2026-09-10T09:07', '2026-09-10T09:40'),
        ('2026-09-10T09:45', '2026-09-10T10:12'),
      ],
      doneAt: '2026-09-10T10:12',
    );
    test('Da, Δs, Δe', () {
      expect(actualDuration(f).valueOrNull, const Duration(minutes: 60));
      final s = startDelay(f).valueOrNull!;
      expect(s.delta, const Duration(minutes: 7));
      expect(s.punctuality, Punctuality.late);
      final e = finishDelay(f).valueOrNull!;
      expect(e.delta, const Duration(minutes: 12));
      expect(e.punctuality, Punctuality.late);
      expect(plannedDuration(f).valueOrNull, const Duration(minutes: 60));
      final v = durationVariance(f).valueOrNull!;
      expect(v.variance, Duration.zero);
      expect(v.ratio, near(1));
      expect(v.label, DurationLabel.onPlan);
      final fs = focusSessions(f).valueOrNull!;
      expect(fs.count, 2);
      expect(fs.pauses, 1);
      expect(fs.longestBlock, const Duration(minutes: 33));
      expect(fs.mean, const Duration(minutes: 30));
      final fit = slotFit(f).valueOrNull!;
      expect(fit.fitShare, near(48 / 60));
      expect(fit.spilledAfter, const Duration(minutes: 12));
      expect(fit.spilledBefore, Duration.zero);
    });
    test('no sessions is "not tracked", never 0', () {
      final g = simple('y', start: '2026-09-10T09:00');
      expect(
        actualDuration(g),
        const NotApplicable<Duration>(Reasons.notTracked),
      );
      expect(
        durationVariance(g),
        const NotApplicable<DurationVariance>(Reasons.notTracked),
      );
      expect(
        startDelay(g),
        const NotApplicable<TimingDelta>(Reasons.notStarted),
      );
      expect(finishDelay(g), const NotApplicable<TimingDelta>(Reasons.notDone));
      expect(slotFit(g), const NotApplicable<SlotFit>(Reasons.notTracked));
      expect(
        focusSessions(g),
        const NotApplicable<FocusSessions>(Reasons.notTracked),
      );
      expect(g.actualMinutes, isNull);
    });
    test('grace boundaries: exactly g is on time, g + 1 min is late', () {
      PlannerOccurrenceFact started(String t) => simple(
        'z',
        start: '2026-09-10T09:00',
        sessions: [(t, '2026-09-10T09:30')],
      );
      expect(
        startDelay(started('2026-09-10T09:05')).valueOrNull!.punctuality,
        Punctuality.onTime,
      );
      expect(
        startDelay(started('2026-09-10T09:06')).valueOrNull!.punctuality,
        Punctuality.late,
      );
      expect(
        startDelay(started('2026-09-10T08:54')).valueOrNull!.punctuality,
        Punctuality.early,
      );
      PlannerOccurrenceFact doneAt(String t) => simple(
        'z',
        start: '2026-09-10T09:00',
        status: PlannerOccurrenceStatus.done,
        doneAt: t,
      );
      expect(
        plannerOutcome(doneAt('2026-09-10T10:05'), now: now),
        PlannerOutcome.doneOnTime,
      );
      expect(
        plannerOutcome(doneAt('2026-09-10T10:06'), now: now),
        PlannerOutcome.doneLate,
      );
      expect(
        finishDelay(doneAt('2026-09-10T10:05')).valueOrNull!.punctuality,
        Punctuality.onTime,
      );
    });
    test('over/under labels, partial, fallback session, outcome classes', () {
      final over = simple(
        'o',
        start: '2026-09-10T09:00',
        actualStart: '2026-09-10T09:00',
        actualEnd: '2026-09-10T10:30',
      );
      expect(durationVariance(over).valueOrNull!.label, DurationLabel.over);
      final under = simple(
        'u',
        start: '2026-09-10T09:00',
        sessions: [('2026-09-10T09:00', '2026-09-10T09:20')],
      );
      expect(durationVariance(under).valueOrNull!.label, DurationLabel.under);
      final partial = simple(
        'p',
        start: '2026-09-10T09:00',
        status: PlannerOccurrenceStatus.done,
        completionPercent: 40,
      );
      expect(plannerOutcome(partial, now: now), PlannerOutcome.partial);
      expect(partialCompletion(partial).valueOrNull, near(0.4));
      final linked = simple(
        'l',
        start: '2026-09-10T09:00',
        status: PlannerOccurrenceStatus.done,
        linked: 0.5,
      );
      expect(plannerOutcome(linked, now: now), PlannerOutcome.partial);
      expect(partialCompletion(linked).valueOrNull, 0.5);
      expect(
        partialCompletion(over),
        const NotApplicable<double>(Reasons.noData),
      );
      final future = simple('f', start: '2026-09-30T09:00');
      expect(plannerOutcome(future, now: now), PlannerOutcome.future);
      final pending = simple('pe', start: '2026-09-21T07:30');
      expect(plannerOutcome(pending, now: now), PlannerOutcome.pending);
      final event = simple(
        'e',
        start: '2026-09-10T09:00',
        mode: TrackingMode.event,
      );
      expect(plannerOutcome(event, now: now), PlannerOutcome.notTracked);
      expect(overdueAge(event, now: now).hasValue, isFalse);
      final missed = simple(
        'm',
        start: '2026-09-10T09:00',
        status: PlannerOccurrenceStatus.missed,
      );
      expect(plannerOutcome(missed, now: now), PlannerOutcome.missed);
      expect(selfRating(missed), (rating: null, note: null));
      for (final age in [0.5, 3, 10, 20, 40]) {
        overdueBucketFor(Duration(hours: (age * 24).round()));
      }
      expect(
        overdueBucketFor(const Duration(days: 40)),
        OverdueBucket.thirtyPlusDays,
      );
      expect(
        overdueBucketFor(const Duration(days: 20)),
        OverdueBucket.fourteenDays,
      );
      expect(
        overdueBucketFor(const Duration(days: 10)),
        OverdueBucket.sevenDays,
      );
      expect(
        overdueBucketFor(const Duration(hours: 5)),
        OverdueBucket.underOneDay,
      );
    });
  });

  test('reschedule acceptance: +1 d, +2 h, −30 min (T6.3.03)', () {
    final f = occ('o4');
    expect(rescheduleDistance(f), const Duration(hours: 26, minutes: 30));
    expect(netDrift(f), const Duration(days: 1, hours: 1, minutes: 30));
    expect(
      leadTime(f).valueOrNull,
      at(paris, '2026-09-10T12:30').difference(at(paris, '2026-09-01T08:00')),
    );
    expect(planningHorizon(f, clock: paris).valueOrNull!.inHours, 8 * 24 + 2);
    expect(startLatency(occ('o1')).hasValue, isTrue);
    expect(leadTime(occ('o9')).hasValue, isFalse);
    expect(startLatency(occ('o9')).hasValue, isFalse);
  });

  test('estimation accuracy acceptance (T6.3.11)', () {
    final acc = estimationAccuracyFromRatios([
      1.2,
      1.5,
      1.0,
      1.3,
      1.4,
      1.1,
      1.25,
      1.6,
      0.9,
      1.35,
    ]);
    expect(acc.bias.valueOrNull, near(math.sqrt(1.25 * 1.3) - 1));
    expect(acc.mape.valueOrNull, near(0.28));
    expect(acc.suggestedBuffer.valueOrNull, near(0.42));
    expect(
      estimationTendency(acc.bias.valueOrNull!),
      EstimationTendency.underestimate,
    );
    expect(estimationTendency(-0.2), EstimationTendency.overestimate);
    expect(estimationTendency(0.01), EstimationTendency.accurate);
    final few = estimationAccuracyFromRatios([1.0, 1.1]);
    expect(few.bias, isA<Insufficient<double>>());
    final fromFacts = estimationAccuracy(facts);
    expect(fromFacts.n, 11);
    expect(fromFacts.bias.valueOrNull, near(0));
    expect(estimationByCategory(facts)['work']!.n, 11);
    final points = plannedVsActualPoints(facts);
    expect(points.length, 11);
    expect(points.where((p) => p.withinBand).length, 9);
    final dist = plannedDurationDistribution(facts);
    expect(dist.histogram.total, 40);
    expect(dist.median.valueOrNull, 30);
  });

  test('capacity acceptance: 10 h planned on Wednesday (T6.3.08)', () {
    final wed = simple('w', start: '2026-09-16T08:00', minutes: 600);
    final report = capacityReport(
      [wed],
      range: DateRange(d('2026-09-14'), d('2026-09-20')),
      clock: paris,
      settings: settings,
    );
    final day = report.days.firstWhere((x) => x.date == d('2026-09-16'));
    expect(day.overbooked, isTrue);
    expect(day.overbookedMinutes, 120);
    expect(report.plannedUtilization.valueOrNull, near(480 / 2400, 1e-3));
    expect(report.overbookedDays.single.date, d('2026-09-16'));
    final remaining = remainingFreeMinutes(
      [wed],
      range: DateRange(d('2026-09-14'), d('2026-09-20')),
      now: at(paris, '2026-09-16T12:00'),
      clock: paris,
      settings: settings,
    );
    // Wed 12–17 (300) + Thu/Fri (960) − Wed 12–17 planned (300).
    expect(remaining, near(960));
    final covered = capacityReport(
      [
        simple(
          'a',
          start: '2026-09-14T09:00',
          status: PlannerOccurrenceStatus.done,
          sessions: [('2026-09-14T09:00', '2026-09-14T10:00')],
        ),
      ],
      range: DateRange(d('2026-09-14'), d('2026-09-14')),
      clock: paris,
      settings: settings,
    );
    expect(covered.actualUtilization.valueOrNull, near(60 / 480));
    expect(covered.actualMinutes, 60);
  });

  test('deep work merge acceptance: 50 min + 1 min gap + 20 min (T6.3.14)', () {
    final f = simple(
      'dw',
      start: '2026-09-17T10:00',
      minutes: 90,
      sessions: [
        ('2026-09-17T10:00', '2026-09-17T10:50'),
        ('2026-09-17T10:51', '2026-09-17T11:11'),
      ],
    );
    final blocks = deepWorkBlocks([f]);
    expect(blocks.single.minutes, 70);
    final after = afterHours([f, occ('gym')], clock: paris, settings: settings);
    expect(after.afterHoursMinutes, 0);
    final timer = timerUsage(facts);
    expect(timer.sessions, 12);
    expect(actualTimeCoverage(facts).valueOrNull, near(11 / 31));
  });

  group('plan snapshot unit cases (T6.3.07)', () {
    final period = DateRange(d('2026-09-14'), d('2026-09-20'));
    final after = at(paris, '2026-09-25T00:00');
    test('move before the period starts', () {
      final f = simple(
        'a',
        start: '2026-09-15T10:00',
        moves: [
          RescheduleFact(
            at(paris, '2026-09-12T10:00'),
            fromStart: ldt('2026-09-22T10:00'),
            toStart: ldt('2026-09-15T10:00'),
          ),
        ],
      );
      final snap = planSnapshot(
        [f],
        period: period,
        bounds: bounds,
        now: after,
      );
      expect(snap.planned, [f]);
      expect(snap.movedIn, isEmpty);
    });
    test('move into the period during it is moved-in, not planned', () {
      final f = simple(
        'b',
        start: '2026-09-16T10:00',
        moves: [
          RescheduleFact(
            at(paris, '2026-09-15T10:00'),
            fromStart: ldt('2026-09-23T10:00'),
            toStart: ldt('2026-09-16T10:00'),
          ),
        ],
      );
      final snap = planSnapshot(
        [f],
        period: period,
        bounds: bounds,
        now: after,
      );
      expect(snap.planned, isEmpty);
      expect(snap.movedIn, [f]);
      expect(
        snap.completionRate,
        const NotApplicable<double>(Reasons.zeroDenominator),
      );
    });
    test('series edit (time change) replays like a move; cancellation before start excluded', () {
      final edited = simple(
        'c',
        start: '2026-09-17T11:00',
        moves: [
          RescheduleFact(
            at(paris, '2026-09-16T09:00'),
            fromStart: ldt('2026-09-17T10:00'),
            toStart: ldt('2026-09-17T11:00'),
            seriesScope: true,
          ),
        ],
      );
      final cancelled = simple(
        'd',
        start: '2026-09-18T10:00',
        cancelledAt: '2026-09-10T10:00',
      );
      final cancelledLater = simple(
        'e',
        start: '2026-09-18T10:00',
        cancelledAt: '2026-09-16T10:00',
      );
      final snap = planSnapshot(
        [edited, cancelled, cancelledLater],
        period: period,
        bounds: bounds,
        now: after,
      );
      expect(snap.planned, [edited, cancelledLater]);
      expect(
        snapshotStartAt(edited, at(paris, '2026-09-14T00:00')),
        ldt('2026-09-17T10:00'),
      );
      expect(
        snapshotStartAt(edited, at(paris, '2026-09-17T00:00')),
        ldt('2026-09-17T11:00'),
      );
    });
  });

  test('series quality & pattern metrics (T6.3.05–T6.3.06)', () {
    final gym = series('gym');
    final skip = skipRateAndReasons(gym, now: now);
    expect(skip.rate.valueOrNull, near(1 / 6));
    expect(skip.reasons, [(label: 'sick', count: 1)]);
    final strength = seriesStrength(
      gym,
      frequency: const StrengthFrequency(3, 7),
      today: d('2026-09-21'),
      now: now,
    );
    expect(strength.series.first.date, d('2026-09-07'));
    expect(strength.current, inInclusiveRange(0, 1));
    expect(
      strength.series.firstWhere((p) => p.date == d('2026-09-11')).scored,
      isFalse,
    );
    final stability = durationStability(series('standup'));
    expect(stability.meanMinutes.valueOrNull, near(140 / 9));
    expect(stability.medianRatio.valueOrNull, near(1));
    final weekday = weekdayAdherence(gym, now: now);
    expect(
      weekday.keys,
      unorderedEquals([Weekday.monday, Weekday.wednesday, Weekday.friday]),
    );
    expect(weekday[Weekday.wednesday]!.valueOrNull, near(0.5));
    expect(weekday[Weekday.friday]!.valueOrNull, near(1));
    final hours = completionHourProfile(gym, clock: paris);
    expect(hours[19], 3);
    expect(hours[18], 1);
    expect(
      completionHourProfile(series('standup'), clock: paris, useStart: true)[9],
      9,
    );
    final behaviour = rescheduleBehaviour(facts);
    expect(behaviour.movedShare.valueOrNull, near(2 / 41));
    expect(behaviour.meanMovesPerMovedOccurrence.valueOrNull, near(2));
    expect(behaviour.hoursPostponed, near((10080 + 1440 + 120) / 60));
    expect(behaviour.procrastinationIndex.valueOrNull, near(2 / 41));
    final markers = ruleChangeMarkers(
      series('reading'),
      changeDates: [d('2026-09-14')],
      now: now,
      windowDays: 7,
    );
    expect(markers.single.adherenceBefore.valueOrNull, near(1));
    expect(markers.single.adherenceAfter.valueOrNull, near(6 / 7));
    final tod = seriesTimeOfDay(series('reading'), clock: paris).valueOrNull!;
    expect(tod.meanMinuteRounded, 21 * 60 + 30);
    expect(seriesStartDrift(series('standup')).valueOrNull, near(37 / 9, 1e-3));
    final calendar = seriesOutcomeCalendar(gym, now: now);
    expect(calendar[d('2026-09-09')], CalendarOutcome.late);
    expect(calendar[d('2026-09-16')], CalendarOutcome.missed);
    expect(calendar[d('2026-09-11')], CalendarOutcome.skipped);
    final invested = seriesTimeInvested(gym);
    expect(invested.planned.last.$2, 360);
    final trend = seriesAdherenceTrend(
      series('reading'),
      now: now,
      from: d('2026-09-07'),
      to: d('2026-09-20'),
      random: math.Random(1),
    );
    expect(trend.weekly.map((p) => p.value), [1.0, 6 / 7]);
    expect(trend.trend, isA<Insufficient<TrendResult>>());
    expect(
      startDelayBoxPlotsByMonth(series('standup')).values.single.valueOrNull!.n,
      9,
    );
  });

  test('allocation by priority, tag, treemap, recurring (T6.3.10)', () {
    final byPriority = timeByPriority(facts);
    expect(byPriority[4], near(70));
    final tagged = [
      simple('t1', start: '2026-09-14T10:00'),
      PlannerOccurrenceFact(
        't2',
        'k',
        seriesId: 't2',
        taskCreatedAt: now,
        plannedDurationMinutes: 30,
        tagIds: const ['a', 'b'],
      ),
    ];
    final tags = timeByTag(tagged);
    expect(tags.overlapping, isTrue);
    expect(tags.minutes, {'a': 30, 'b': 30});
    final align = priorityAlignment(facts, now: now);
    expect(align.highTimeShare.valueOrNull, greaterThan(0));
    expect(align.highCompletionRate.valueOrNull, near(1));
    final tree = allocationTreemap(facts);
    expect(tree['health']!['gym'], near(360));
    final rec = recurringVsOneOff(facts);
    expect(rec.recurringDone, 24);
    expect(rec.oneOffDone, 7);
    final trendByCat = categoryTrend(
      facts,
      range: DateRange(d('2026-09-07'), d('2026-09-20')),
    );
    expect(trendByCat['health']!.map((p) => p.value), [180, 180]);
    final pva = plannedVsActualByCategory(facts);
    expect(pva['health']!.planned, 360);
  });

  test('patterns (T6.3.13) and focus/advanced (T6.3.14–T6.3.16)', () {
    final planned = busiestHours(
      facts,
      measure: BusyMeasure.plannedMinutes,
      clock: paris,
    );
    expect(planned[Weekday.monday]![18], 120);
    final actual = busiestHours(
      facts,
      measure: BusyMeasure.actualMinutes,
      clock: paris,
    );
    expect(actual[Weekday.thursday]![10], near(54));
    final done = busiestHours(
      facts,
      measure: BusyMeasure.completions,
      clock: paris,
    );
    expect(done[Weekday.sunday]![21], 1);
    final best = bestWorkingDays(facts, now: now);
    expect(best[Weekday.saturday]!.completionRate.valueOrNull, near(0.5));
    final occupancy = slotOccupancy(
      facts,
      range: DateRange(d('2026-09-07'), d('2026-09-20')),
      slotMinutes: 60,
      clock: paris,
    );
    final mon9 = occupancy.firstWhere(
      (o) => o.weekday == Weekday.monday && o.slotStartMinute == 540,
    );
    expect(mon9.plannedShare, 1);
    expect(mon9.usedShare, 1);
    final dead = deadSlots(occupancy, slotMinutes: 60, minWeeks: 2);
    expect(
      dead.any((o) => o.weekday == Weekday.monday && o.slotStartMinute == 900),
      isTrue,
    );
    expect(
      deadSlots(occupancy, slotMinutes: 60),
      isEmpty,
      reason: 'needs ≥ 4 weeks',
    );
    final byHour = completionRateByHour(facts, now: now);
    expect(byHour[18]!.valueOrNull, near(4 / 5));
    final punch = startDelayPunchCard(series('standup'));
    expect(punch[(Weekday.monday, 9)], near(1.5));
    final frag = fragmentation(
      facts,
      date: d('2026-09-14'),
      settings: settings,
    ).valueOrNull!;
    // Free: 09:00–09:30, 09:45–10:00, 12:00–17:00 → 30 + 15 + 300.
    expect(frag.freeMinutes, 345);
    expect(frag.index, near(1 - 300 / 345));
    expect(frag.gapsOver15, 3);
    final single = fragmentation(
      const [],
      date: d('2026-09-15'),
      settings: settings,
    ).valueOrNull!;
    expect(single.index, 0);
    expect(
      fragmentation(const [], date: d('2026-09-19')),
      isA<NotApplicable<Fragmentation>>(),
    );
    final switches = contextSwitches(facts, clock: paris);
    expect(switches.perDay[d('2026-09-14')], 0);
    expect(switches.perTrackedHour.hasValue, isTrue);
    expect(productivityScore(facts), isA<NotApplicable<double>>());
    final score = productivityScore(
      facts,
      settings: const PlannerStatsSettings(
        categoryWeights: {'work': 4, 'health': 2},
      ),
    );
    expect(score.valueOrNull, inInclusiveRange(50, 100));
    expect(planningHorizonDistribution(facts, clock: paris).total, 42);
    final goal = completionGoalStreak(
      facts,
      target: 3,
      range: DateRange(d('2026-09-14'), d('2026-09-21')),
      bounds: bounds,
      today: d('2026-09-21'),
      isDayOff: (x) => x.weekday.isWeekend,
    );
    expect(goal.currentLength, 5);
    final flow = backlogFlow(
      taskCreatedAt: [at(paris, '2026-09-16T08:00')],
      facts: facts,
      unscheduledOpenTasks: 2,
      bounds: bounds,
      range: DateRange(d('2026-09-07'), d('2026-09-20')),
      now: now,
    );
    expect(flow.openBacklog, 5);
    expect(flow.created.map((p) => p.value), [0, 1]);
    expect(flow.completed.fold<double>(0, (a, p) => a + p.value), 31);
    expect(pareto([null, 'A', 'a', 'b']), [
      (label: 'A', count: 2),
      (label: 'b', count: 1),
      (label: 'Unspecified', count: 1),
    ]);
    expect(LocalTimeWindow.of(LocalTime(9, 0), LocalTime(8, 0)).minutes, 0);
    expect(mergeSessions(const []), isEmpty);
  });
}
