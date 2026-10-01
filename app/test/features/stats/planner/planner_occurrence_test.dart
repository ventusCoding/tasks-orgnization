// Planner stats adapter (T6.3.01) and per-occurrence timing & outcome metrics (T6.3.02): facts from
// the resolver for every outcome class and all three tracking modes, grace boundaries and the
// "not tracked" rule.
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/planner_resolution.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';
import 'planner_scenario.dart';

void main() {
  late StatsHarness h;

  setUp(() async {
    h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 12));
    await h.seedTables(plannerScenario());
  });
  tearDown(() => h.dispose());

  Future<Map<String, MetricResult>> task(String id, [String? key]) =>
      h.compute(MetricScope.task, scopeId: id, extra: key, period: const StatsPeriod.thisWeek());

  group('adapter (T6.3.01)', () {
    test('facts carry plan, sessions, outcome inputs and tracking modes', () async {
      final input = await h.read(statsDataSourceProvider).loadPlanner();
      final resolver = PlannerResolver(
        input,
        resolver: LocationZoneResolver(const {}),
        viewerZone: 'UTC',
        now: DateTime.utc(2026, 9, 23, 12),
      );
      final facts = resolver.resolve(from: LocalDate(2026, 9, 21), to: LocalDate(2026, 9, 24)).facts;
      final byKey = {for (final f in facts) '${f.taskId}@${f.occurrenceKey}': f};
      final a = byKey['a@2026-09-21T09:00']!;
      expect(a.trackingMode, TrackingMode.timer);
      expect(a.sessions, hasLength(2));
      expect(a.actualMinutes, 60);
      expect(a.plannedMinutes, 60);
      expect(a.status, PlannerOccurrenceStatus.done);
      expect(byKey['e@2026-09-22T08:00']!.trackingMode, TrackingMode.event);
      expect(byKey['b@2026-09-21T14:00']!.trackingMode, TrackingMode.check);
      // The daily series expands over the window; the cancelled occurrence stays as a fact.
      expect(facts.where((f) => f.taskId == 'g').map((f) => f.occurrenceKey), [
        '2026-09-21T07:00',
        '2026-09-22T07:00',
        '2026-09-23T07:00',
        '2026-09-24T07:00',
      ]);
      expect(byKey['g@2026-09-22T07:00']!.status, PlannerOccurrenceStatus.cancelled);
      expect(byKey['f@2026-09-22T18:00']!.skipReason, 'Too tired');
    });
  });

  group('per-occurrence metrics (T6.3.02)', () {
    test('two sessions: Da = 60 min, start +7 (late at g = 5), finish +12', () async {
      final r = await task('a');
      expect(r['PL-T-01']!.value.valueOrNull, 60);
      expect(r['PL-T-02']!.value.valueOrNull, 60);
      expect(r['PL-T-03']!.value.valueOrNull, 0);
      expect(r['PL-T-03']!.args['ratio'], 1.0);
      expect(r['PL-T-04']!.value.valueOrNull, 7);
      expect(r['PL-T-04']!.args['punctuality'], 'late');
      expect(r['PL-T-05']!.value.valueOrNull, 12);
      expect(r['PL-T-06']!.args['outcome'], 'doneLate');
    });

    test('finishing exactly at the grace is on time; one minute more is late', () async {
      final b = await task('b');
      expect(b['PL-T-05']!.value.valueOrNull, 5);
      expect(b['PL-T-05']!.args['punctuality'], 'onTime');
      expect(b['PL-T-06']!.args['outcome'], 'doneOnTime');
      final c = await task('c');
      expect(c['PL-T-05']!.value.valueOrNull, 6);
      expect(c['PL-T-05']!.args['punctuality'], 'late');
      expect(c['PL-T-06']!.args['outcome'], 'doneLate');
    });

    test('no sessions: actual time is "not tracked", never 0', () async {
      final b = await task('b');
      expect(b['PL-T-02']!.value, const NotApplicable<double>('notTracked'));
      expect(b['PL-T-03']!.note, 'notTracked');
      expect(b['PL-T-04']!.note, 'notStarted');
    });

    test('an open past check occurrence is overdue with its age bucket', () async {
      final d = await task('d');
      expect(d['PL-T-07']!.value.valueOrNull, 25 * 60 + 15);
      expect(d['PL-T-07']!.args['bucket'], 'oneDay');
      expect(d['PL-T-06']!.args['outcome'], 'missed');
      expect(d['PL-T-05']!.note, 'notDone');
      expect((await task('b'))['PL-T-07']!.note, 'notOverdue');
    });

    test('outcome classes: skipped (with reason), cancelled, early done, future, event', () async {
      final f = await task('f');
      expect(f['PL-T-06']!.args, containsPair('outcome', 'skipped'));
      expect(f['PL-T-06']!.args, containsPair('skipReason', 'Too tired'));
      expect((await task('g', '2026-09-22T07:00'))['PL-T-06']!.args['outcome'], 'cancelled');
      final early = await task('g', '2026-09-21T07:00');
      expect(early['PL-T-05']!.value.valueOrNull, -12);
      expect(early['PL-T-06']!.args['outcome'], 'doneOnTime');
      expect((await task('h'))['PL-T-06']!.args['outcome'], 'future');
      expect((await task('e', '2026-09-24T08:00'))['PL-T-06']!.args['outcome'], 'future');
      // Events never count as done or missed.
      expect((await task('e', '2026-09-21T08:00'))['PL-T-06']!.args['outcome'], 'notTracked');
    });

    test('an unknown task or occurrence is not applicable', () async {
      final r = await task('zzz');
      expect(r['PL-T-01']!.note, 'noOccurrence');
    });
  });
}
