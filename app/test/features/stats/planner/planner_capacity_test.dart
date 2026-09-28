// Capacity & utilization (T6.3.08) and time allocation (T6.3.09).
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';
import 'capacity_scenario.dart';

const _week = 'custom:2026-09-14..2026-09-20';

Future<StatsHarness> seeded({bool tracked = true}) async {
  final h = StatsHarness.create(now: DateTime.utc(2026, 9, 15, 12));
  await h.seedSettings(capacitySettings());
  final tables = capacityScenario();
  if (!tracked) tables.remove('time_entries');
  await h.seedTables(tables);
  return h;
}

Future<Map<String, MetricResult>> compute(StatsHarness h, Set<String> ids, [String period = _week]) =>
    h.compute(MetricScope.planner, period: PeriodSelection.parsePeriod(period)!, metricIds: ids);

void main() {
  group('capacity (T6.3.08)', () {
    test('work hours minus unavailable blocks; weekends have no capacity', () async {
      final h = await seeded();
      addTearDown(h.dispose);
      final r = await compute(h, {'PL-X-07', 'PL-X-08'});
      // 5 × 8 h − the 1 h "Doctor" event.
      expect(r['PL-X-07']!.value.valueOrNull, 5 * 480 - 60);
      // Clipped to work hours: Mon 60 + Wed 3 h + 5 h (the Saturday task is outside capacity).
      expect(r['PL-X-08']!.value.valueOrNull, closeTo(540 / 2340, 0.001));
      final perDay = r['PL-X-08']!.chart!.toTable().rows;
      expect([for (final row in perDay) row.last.value], [480, 480, 480, 420, 480, 0, 0]);
    });

    test('10 h planned on Wednesday is overbooked by 120 min', () async {
      final h = await seeded();
      addTearDown(h.dispose);
      final r = await compute(h, {'PL-X-10', 'PL-X-12'});
      final over = r['PL-X-10']!;
      expect(over.value.valueOrNull, 1);
      expect(over.args['overbookedMinutes'], 120);
      expect(over.args['days'], ['2026-09-16']);
      // Unclipped planned load, overlapping tasks counted separately; events excluded.
      expect(r['PL-X-12']!.args['planned'], 720);
    });

    test('actual utilization uses tracked time; free time counts from now', () async {
      final h = await seeded();
      addTearDown(h.dispose);
      final r = await compute(h, {'PL-X-09'});
      expect(r['PL-X-09']!.value.valueOrNull, closeTo(50 / 2340, 1e-9));
      expect(r['PL-X-09']!.args['coverage'], 1.0);
      final now = await h.compute(MetricScope.planner, period: const StatsPeriod.thisWeek(), metricIds: {'PL-X-11'});
      // Tue 12–17 + Wed + Thu (− 1 h) + Fri, minus Wednesday's 8 clipped hours.
      expect(now['PL-X-11']!.value.valueOrNull, 300 + 480 + 420 + 480 - 480);
    });
  });

  group('time allocation (T6.3.09)', () {
    test('actual time by category when coverage ≥ 60 %', () async {
      final h = await seeded();
      addTearDown(h.dispose);
      final r = await compute(h, {'PL-X-13', 'PL-X-15'});
      expect(r['PL-X-13']!.value.valueOrNull, 50);
      expect(r['PL-X-13']!.note, isNot('usedPlanned'));
      expect(r['PL-X-15']!.args['eventMinutes'], 60);
      expect(r['PL-X-15']!.args['taskMinutes'], 720);
    });

    test('planned fallback below 60 % coverage; shares sum to 100 % with an uncategorized slice', () async {
      final h = await seeded(tracked: false);
      addTearDown(h.dispose);
      final r = await compute(h, {'PL-X-13'});
      final alloc = r['PL-X-13']!;
      expect(alloc.note, 'usedPlanned');
      final donut = alloc.chart! as DonutData;
      final total = donut.slices.fold<double>(0, (a, s) => a + s.value);
      expect(total, donut.total);
      final shares = donut.slices.map((s) => s.value / donut.total).fold<double>(0, (a, b) => a + b);
      expect(shares, closeTo(1, 0.001));
      expect(donut.slices.any((s) => s.label == const TokenLabel(LabelToken.uncategorized)), isTrue);
    });
  });
}
