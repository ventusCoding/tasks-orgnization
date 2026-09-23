import 'package:decimal/decimal.dart';
import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/quit_calculator.dart';
import 'package:everslot_metrics/src/quit_metrics.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/survival.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:test/test.dart';

import 'support/support.dart';

final ZoneClock paris = tzClock('Europe/Paris');

QuitCalculator calculatorFrom(Map<String, Object?> fx, {bool autoSuccess = true, String? now}) {
  final t = fx['tracker']! as Map<String, Object?>;
  final tracker = QuitTracker(
    at(paris, t['quitStartedAt']! as String),
    mode: QuitMode.values.byName(t['mode']! as String),
    days: DayBoundaries(paris),
    autoSuccess: autoSuccess,
    baselinePerDay: (t['baselinePerDay']! as num).toDouble(),
    unitCost: t['unitCost'] == null ? null : Decimal.parse(t['unitCost']! as String),
    dailyLimit: (t['dailyLimit'] as num?)?.toDouble(),
    lifeMinutesPerUnit: (t['lifeMinutesPerUnit'] as num?)?.toDouble(),
    timePerUnitMinutes: (t['timePerUnitMinutes'] as num?)?.toDouble(),
    substance: t['substance'] as String?,
    currency: t['currency'] as String?,
    revisions: [
      for (final r in (t['revisions']! as List).cast<Map<String, Object?>>())
        QuitRevision(
          d(r['from']! as String),
          baselinePerDay: (r['baselinePerDay'] as num?)?.toDouble(),
          unitCost: r['unitCost'] == null ? null : Decimal.parse(r['unitCost']! as String),
        ),
    ],
  );
  var i = 0;
  final logs = [
    for (final l in (fx['logs']! as List).cast<Map<String, Object?>>())
      QuitLog(
        'l${i++}',
        HabitLogKind.values.byName(l['kind']! as String),
        loggedAt: at(paris, l['at']! as String),
        localDate: d(l['date']! as String),
        value: (l['value'] as num?)?.toDouble(),
        intensity: l['intensity'] as int?,
        trigger: l['trigger'] as String?,
        place: l['place'] as String?,
        coping: l['coping'] as String?,
        resisted: l['resisted'] as bool?,
        durationSeconds: l['durationSeconds'] as int?,
      ),
  ];
  return QuitCalculator(tracker, logs, now: at(paris, now ?? fx['now']! as String));
}

double hours(Duration x) => x.inMinutes / 60;

void main() {
  group('quit_smoking_90_days (T6.6.02–T6.6.08)', () {
    final fx = loadFixture('quit_smoking_90_days');
    final e = fx['expect']! as Map<String, Object?>;
    final c = calculatorFrom(fx);

    test('abstinence, units, money, life (QT-01…10, QT-22)', () {
      final s = quitSummary(c);
      expect(hours(s.timeSinceQuit), e['timeSinceQuitHours']);
      expect(hours(s.currentAbstinence), e['currentAbstinenceHours']);
      expect(hours(s.longestAbstinence), e['longestAbstinenceHours']);
      expect(s.abstinentDays, e['abstinentDays']);
      expect(s.abstinentDayShare.valueOrNull, near(e['abstinentShare']! as num));
      expect(s.unitsAvoided, near(e['unitsAvoided']! as num));
      expect(s.moneySaved, Decimal.parse(e['moneySaved']! as String));
      expect(s.moneySpent, Decimal.parse(e['moneySpent']! as String));
      expect(s.projection!.nextYear, Decimal.parse(e['projectionYear']! as String));
      expect(s.lifeRegainedMinutes.valueOrNull, near(e['lifeRegainedMinutes']! as num));
      expect(s.timeNotSpentMinutes, near(e['timeNotSpentMinutes']! as num));
      expect(cleanOfTotal(c), (clean: 59, total: 60));
    });

    test('cravings (QT-13…17)', () {
      final load = cravingLoad(c);
      expect(load.perDay.valueOrNull, near(e['cravingsPerDay']! as num));
      expect(load.meanIntensity.valueOrNull, near(e['meanIntensity']! as num));
      expect(load.maxIntensity.valueOrNull, e['maxIntensity']);
      expect(load.daily.length, 60);
      final context = cravingContext(c, weekStart: Weekday.sunday);
      final counts = (e['triggerCounts']! as Map).cast<String, int>();
      expect(context.triggers.first, (label: 'coffee', count: counts['coffee']));
      expect(context.triggers.last, (label: 'Unspecified', count: counts['']));
      expect(context.matrix.first.$1, Weekday.sunday);
      expect(context.places.fold<int>(0, (a, p) => a + p.count), 40);
      expect(resistRate(c).valueOrNull, near(e['resistRate']! as num));
      final duration = cravingDuration(c);
      expect(duration.medianSeconds.hasValue, isTrue);
      expect(duration.histogram.total, 40);
      final decline = cravingsDecline(c);
      final weekly = (e['weeklyCravings']! as List).cast<int>();
      expect(decline.weekly.first.$2, near(weekly.first / 7));
      expect(decline.weekly.length, 9);
      expect(decline.weekly.last.$2, 0);
      expect(decline.changeVsWeek1.valueOrNull, near((1 - 10) / 10));
      final coping = copingEffectiveness(c);
      expect(coping.keys, containsAll(['breathing', 'walk', 'water']));
      expect(coping['walk']!.hasValue, isTrue);
      final free = cravingFreeTime(c);
      expect(free.sinceLast, greaterThan(const Duration(days: 4)));
      expect(free.longest, greaterThanOrEqualTo(free.sinceLast));
    });

    test('milestones, withdrawal, savings goal, money per period, pledges', () {
      final milestones = healthMilestones(c, const [
        QuitMilestone('20m', tMin: Duration(minutes: 20)),
        QuitMilestone('2-12w', tMin: Duration(days: 14), tMax: Duration(days: 84)),
        QuitMilestone('1y', tMin: Duration(days: 365)),
      ]).valueOrNull!;
      expect(milestones[0].state, MilestoneState.done);
      expect(milestones[1].state, MilestoneState.inWindow);
      expect(milestones[1].isNext, isTrue);
      expect(milestones[1].progress, near(966 / 24 / 84));
      expect(milestones[2].eta, at(paris, '2026-06-20T18:00').add(const Duration(days: 365)));
      expect(nextDayMilestone(c)!.milestone.id, 'day_60');
      expect(withdrawalPhase(c).valueOrNull!.name, e['withdrawal']);
      final goal = savingsGoal(c, goal: Decimal.fromInt(1200), dailySaving: Decimal.fromInt(13));
      expect(goal.etaDays.valueOrNull, e['savingsGoalEtaDays']);
      expect(goal.progress.valueOrNull, near(748.2 / 1200));
      final perMonth = moneySavedPerPeriod(c, granularity: Granularity.month);
      expect(perMonth.buckets[d('2026-06-01')], Decimal.parse('358.2'));
      expect(perMonth.buckets[d('2026-07-01')], Decimal.parse('390'));
      expect(perMonth.meanPerDay.valueOrNull, near(748.2 / 60));
      expect(pledgeStreak(c), 0);
      final use = useAnalytics(c);
      expect(use.episodes, 1);
      expect(use.meanAmount.valueOrNull, 3);
      expect(use.precedingTriggers.first, (label: 'alcohol', count: 1));
      expect(use.meanDaysBetweenLapses, isA<Insufficient<double>>());
      expect(timeToLapseSurvival(c), isA<Insufficient<KaplanMeierResult>>());
    });
  });

  group('quit_reduce_week (T6.6.06)', () {
    final fx = loadFixture('quit_reduce_week');
    final e = fx['expect']! as Map<String, Object?>;
    final c = calculatorFrom(fx);
    test('reduction progress', () {
      final r = reductionProgress(c);
      expect(r.withinLimitShare.valueOrNull, near(e['withinLimitShare']! as num));
      expect(r.meanDailyUse.valueOrNull, near(e['meanUse']! as num));
      expect(r.reduction.valueOrNull, near(e['reduction']! as num));
      expect(r.unitsAvoided, near(e['unitsAvoided']! as num));
      expect(r.limit, 10);
      expect(r.rolling7Use.last, near(9));
      expect(c.dayStreak, e['dayStreak']);
      expect(c.bestDayStreak, e['bestDayStreak']);
      expect(c.moneySaved, Decimal.parse(e['moneySaved']! as String));
      expect(c.withinLimitDays, 5);
    });
  });

  group('quit_attempts (T6.6.09, T6.6.12)', () {
    final fx = loadFixture('quit_attempts');
    final e = fx['expect']! as Map<String, Object?>;
    final c = calculatorFrom(fx);
    test('attempts, lapse vs relapse, survival across the DST change', () {
      final attempts = quitAttempts(c);
      expect(attempts.count, e['attempts']);
      expect([for (final a in c.attempts) hours(a.durationAt(c.now))], e['attemptHours']);
      expect(hours(attempts.longest), e['longestAttemptHours']);
      expect(attempts.currentRank, e['currentRank']);
      expect(hours(c.currentAbstinence), e['currentAbstinenceHours']);
      final classes = lapseRelapse(c);
      expect([for (final (_, r) in classes) r.isRelapse], e['relapse']);
      expect([for (final (_, r) in classes) r.rule?.name], e['relapseRule']);
      expect([for (final (_, r) in classes) r.detectedOn?.toIso()], e['relapseDetectedOn']);
      final km = timeToLapseSurvival(c).valueOrNull!;
      expect(km.medianSurvival, e['kmMedianHours']);
      final expectedSteps = (e['kmSurvival']! as List).cast<List<Object?>>();
      for (var i = 0; i < expectedSteps.length; i++) {
        expect(km.steps[i].time, expectedSteps[i][0]);
        expect(km.steps[i].survival, near(expectedSteps[i][1]! as num));
      }
      expect(km.steps.last.censored, 1);
      final use = useAnalytics(c);
      expect(use.episodes, 8);
      expect(use.meanDaysBetweenLapses.valueOrNull, near(19 / 7));
    });
  });

  test('QT-15 acceptance: 10 cravings, 2 followed by a use within 2 h → 80 %', () {
    final bounds = DayBoundaries(paris);
    final tracker = QuitTracker(
      at(paris, '2026-09-01T00:00'),
      mode: QuitMode.abstain,
      days: bounds,
      substance: 'alcohol',
      baselinePerDay: 2,
    );
    final logs = [
      for (var i = 0; i < 10; i++)
        QuitLog(
          'c$i',
          HabitLogKind.craving,
          loggedAt: at(paris, '2026-09-0${i ~/ 2 + 2}T${10 + (i % 2) * 6}:00'),
          localDate: d('2026-09-0${i ~/ 2 + 2}'),
          intensity: 5,
        ),
      QuitLog('u1', HabitLogKind.relapse, loggedAt: at(paris, '2026-09-02T11:30'), localDate: d('2026-09-02')),
      QuitLog('u2', HabitLogKind.relapse, loggedAt: at(paris, '2026-09-03T17:59'), localDate: d('2026-09-03')),
      QuitLog('p', HabitLogKind.pledge, loggedAt: at(paris, '2026-09-09T08:00'), localDate: d('2026-09-09')),
      QuitLog('q', HabitLogKind.clean, loggedAt: at(paris, '2026-09-10T21:00'), localDate: d('2026-09-10')),
    ];
    final c = QuitCalculator(tracker, logs, now: at(paris, '2026-09-10T22:00'));
    expect(resistRate(c).valueOrNull, near(0.8));
    expect(pledgeStreak(c), 2);
    expect(healthMilestones(c, const []), isA<NotApplicable<List<MilestoneProgress>>>());
    expect(withdrawalPhase(c), isA<NotApplicable<WithdrawalPhase>>());
    expect(quitSummary(c).lifeRegainedMinutes, isA<NotApplicable<double>>());
    expect(quitSummary(c, explicitLifeMinutesPerUnit: true).lifeRegainedMinutes, isA<NotApplicable<double>>());
    final empty = QuitCalculator(tracker, const [], now: at(paris, '2026-09-01T10:00'));
    expect(cravingLoad(empty).perDay, isA<NotApplicable<double>>());
    expect(cravingsDecline(empty).changeVsWeek1, isA<NotApplicable<double>>());
    expect(cravingFreeTime(empty).sinceLast, const Duration(hours: 10));
    expect(savingsGoal(empty, goal: Decimal.zero).progress, isA<NotApplicable<double>>());
    final smoker = QuitCalculator(
      QuitTracker(
        at(paris, '2026-09-01T00:00'),
        mode: QuitMode.abstain,
        days: bounds,
        substance: smokingSubstance,
      ),
      const [],
      now: at(paris, '2026-09-02T00:00'),
    );
    expect(withdrawalPhase(smoker).valueOrNull, WithdrawalPhase.peak);
    final week = QuitCalculator(smoker.tracker, const [], now: at(paris, '2026-09-06T00:00'));
    expect(withdrawalPhase(week).valueOrNull, WithdrawalPhase.firstWeek);
    final easing = QuitCalculator(smoker.tracker, const [], now: at(paris, '2026-09-20T00:00'));
    expect(withdrawalPhase(easing).valueOrNull, WithdrawalPhase.easing);
    expect(quitSummary(smoker).lifeRegainedMinutes, isA<NotApplicable<double>>());
  });
}
