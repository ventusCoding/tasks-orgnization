// Section execution & plan snapshot (T6.3.07): moves before and during the period, a series edit,
// a cancellation and an unplanned addition.
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';
import 'snapshot_scenario.dart';

const _ids = {'PL-X-01', 'PL-X-02', 'PL-X-03', 'PL-X-05', 'PL-X-06'};

void main() {
  late StatsHarness h;

  Future<Map<String, MetricResult>> week(String period) =>
      h.compute(MetricScope.planner, period: PeriodSelection.parsePeriod(period)!, metricIds: _ids);

  List<String> drill(MetricResult r, String key) => [for (final d in r.drill[key] ?? const <Never>[]) d.id];

  setUp(() async {
    h = StatsHarness.create(now: DateTime.utc(2026, 9, 22, 12));
    await h.seedTables(snapshotScenario());
  });
  tearDown(() => h.dispose());

  test('the plan as it stood at the period start: moved out, moved before, cancelled, unplanned', () async {
    final r = await week('custom:2026-09-14..2026-09-20');
    final completion = r['PL-X-01']!;
    // m1 (moved out, not done), d1, p1 (moved in before the week started), r × 6 (Wed cancelled).
    expect(completion.args['planned'], 9);
    expect(completion.args['done'], 8);
    expect(completion.value.valueOrNull, closeTo(8 / 9, 1e-9));
    expect(completion.exclusions, {'unplanned': 1});
    expect(drill(completion, 'planned'), containsAll(['m1', 'd1', 'p1']));
    expect(drill(completion, 'planned').where((id) => id == 'r'), hasLength(6));
    final moved = r['PL-X-03']!;
    expect(drill(moved, 'unplanned'), ['u1']);
    expect(drill(moved, 'movedOut'), ['m1']);
    expect(drill(moved, 'movedIn'), isEmpty);
  });

  test('a task moved into next week counts as planned there; unplanned additions never change PL-X-01', () async {
    final next = await week('custom:2026-09-21..2026-09-27');
    expect(next['PL-X-01']!.args['planned'], 1);
    expect(next['PL-X-01']!.value, isA<Insufficient<double>>());
    expect(drill(next['PL-X-03']!, 'movedOut'), isEmpty);
    // m1 is open and past its planned start: overdue for one day.
    expect(next['PL-X-06']!.value.valueOrNull, 1);
    expect(drill(next['PL-X-06']!, 'oneDay'), ['m1']);
  });

  test('a series edit during the period keeps its occurrences planned', () async {
    await h.seedTables({
      'tasks': [
        {
          'id': 'q',
          'series_id': 'q',
          'title': 'q',
          'start_local': '2026-09-14T21:00',
          'duration_minutes': 30,
          'time_zone': 'UTC',
          'created_at': '2026-09-10T08:00:00.000Z',
          'recurrence': '{"v":1,"type":"fixed","freq":"daily","interval":1,"until":"2026-09-20T23:59"}',
        },
      ],
      'activity_events': [
        {
          'id': 'ev-q',
          'entity_type': 'task',
          'entity_id': 'q',
          'event_type': 'rescheduled',
          'occurred_at': '2026-09-16T12:00:00.000Z',
          'payload': {
            'scope': 'series',
            'fromStart': '2026-09-14T20:00',
            'toStart': '2026-09-14T21:00',
            'fromDuration': 30,
            'toDuration': 30,
          },
        },
      ],
    });
    final r = await week('custom:2026-09-14..2026-09-20');
    expect(r['PL-X-01']!.args['planned'], 16);
    expect(r['PL-X-01']!.args['done'], 8);
    expect(drill(r['PL-X-03']!, 'movedOut'), ['m1']);
  });

  test('on-time rate counts every completion of the period', () async {
    final r = await week('custom:2026-09-14..2026-09-20');
    expect(r['PL-X-05']!.value.valueOrNull, 1.0);
    expect(r['PL-X-02']!.value.valueOrNull, 8);
  });
}
