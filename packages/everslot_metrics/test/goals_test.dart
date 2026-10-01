import 'package:everslot_metrics/src/goals.dart';
import 'package:test/test.dart';

import 'support/support.dart';

void main() {
  group('goalProgress (T5.4.03, HB-H-26, GL-09)', () {
    final goal = GoalSpec(10000, start: d('2026-01-01'), end: d('2026-12-31'));

    test('push-up goal as of 2026-06-30', () {
      final values = {for (var i = 0; i < 28; i++) d('2026-06-30').minusDays(i): 30.0};
      final p = goalProgress(goal, asOf: d('2026-06-30'), dailyValues: values, actual: 4500);
      expect(p.elapsedDays, 181);
      expect(p.remainingDays, 184);
      expect(p.pace.round(), 4959);
      expect(p.onTrack, isFalse);
      expect(p.recentDailyRate, near(30));
      expect(p.projectedEnd, near(10020));
      expect(p.eta, d('2026-12-31'));
      expect(p.status, GoalStatus.behind);
      expect(p.requiredDailyRate, near(5500 / 184));
      expect(p.requiredWeeklyRate, near(5500 / 184 * 7));
      expect(p.progress, near(0.45));
      expect(p.elapsedFraction, near(181 / 365));
      expect(p.aheadBy, lessThan(0));
      // Constant daily values → no uncertainty.
      expect(p.etaEarliest, p.eta);
      expect(p.etaLatest, p.eta);
      expect(p.achievedOn, isNull);
    });

    test('sums daily values, detects achievement and on-track status', () {
      final small = GoalSpec(100, start: d('2026-09-01'), end: d('2026-09-30'));
      final values = {for (var i = 0; i < 10; i++) d('2026-09-01').plusDays(i): 12.0};
      final p = goalProgress(small, asOf: d('2026-09-10'), dailyValues: values);
      expect(p.actual, 120);
      expect(p.status, GoalStatus.achieved);
      expect(p.achievedOn, d('2026-09-09'));
      expect(p.eta, d('2026-09-10'));

      final onTrack = goalProgress(small, asOf: d('2026-09-05'), dailyValues: values);
      expect(onTrack.actual, 60);
      expect(onTrack.status, GoalStatus.onTrack);
    });

    test('at risk when the required rate exceeds 1.5 × the recent rate', () {
      final small = GoalSpec(100, start: d('2026-09-01'), end: d('2026-09-30'));
      final p = goalProgress(small, asOf: d('2026-09-25'), dailyValues: {d('2026-09-02'): 10.0, d('2026-09-20'): 5.0});
      expect(p.status, GoalStatus.atRisk);
      final stalled = goalProgress(small, asOf: d('2026-09-10'));
      expect(stalled.eta, isNull);
      expect(stalled.status, GoalStatus.atRisk);
    });

    test('uncertainty band widens with noisy data; asOf clamps to the goal', () {
      final small = GoalSpec(1000, start: d('2026-09-01'), end: d('2026-12-31'));
      final values = {for (var i = 0; i < 28; i++) d('2026-09-01').plusDays(i): i.isEven ? 2.0 : 10.0};
      final p = goalProgress(small, asOf: d('2026-09-28'), dailyValues: values);
      expect(p.etaEarliest!.isBefore(p.eta!), isTrue);
      expect(p.etaLatest!.isAfter(p.eta!), isTrue);
      final after = goalProgress(small, asOf: d('2027-02-01'), actual: 500);
      expect(after.remainingDays, 0);
      expect(after.requiredDailyRate, isNull);
      expect(after.status, GoalStatus.atRisk);
      final before = goalProgress(small, asOf: d('2026-08-01'));
      expect(before.elapsedDays, 0);
      final achieved = goalProgress(small, asOf: d('2026-10-01'), actual: 1000);
      expect(achieved.achievedOn, d('2026-10-01'));
      expect(GoalSpec(0, start: d('2026-01-01'), end: d('2026-01-01')).totalDays, 1);
    });
  });
}
