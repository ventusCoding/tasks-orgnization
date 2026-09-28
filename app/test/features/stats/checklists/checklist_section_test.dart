// Lists section overview (T6.4.12) and the list ranking of the Lists screen (T6.4.17), on the
// checklist_flow_small dataset.
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _week = 'custom:2026-09-01..2026-09-07';

Future<StatsHarness> seeded({bool archiveL1 = false}) async {
  final fixture = StatsFixture.load('checklist_flow_small');
  if (archiveL1) {
    final lists = ((fixture.json['tables']! as Map<String, Object?>)['checklists']! as List).cast<Map<String, Object?>>();
    lists.firstWhere((l) => l['id'] == 'L1')['archived_at'] = '2026-09-07T20:00:00.000Z';
  }
  return fixture.seed();
}

void main() {
  test('archived lists leave WIP but keep their historical throughput', () async {
    final h = await seeded(archiveL1: true);
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.checklists, period: PeriodSelection.parsePeriod(_week)!);
    // C (waiting) lives in the archived list L1.
    expect(r['CL-X-03']!.value.valueOrNull, 0);
    // A and B were completed in L1 during the week.
    expect(r['CL-X-04']!.value.valueOrNull, 2);
  });

  test('ranking: most active, most blocked and stalest lists, each opening its list', () async {
    final h = await seeded();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.checklists, period: PeriodSelection.parsePeriod(_week)!, metricIds: {'CL-X-01'});
    final group = r['CL-X-01']!.chart! as ChartGroup;
    expect(group.charts.map((c) => c.$1), const [
      TokenLabel(LabelToken.summary),
      TokenLabel(LabelToken.mostActive),
      TokenLabel(LabelToken.mostBlocked),
      TokenLabel(LabelToken.stalest),
    ]);
    ListData tab(int i) => group.charts[i].$2 as ListData;
    // L1 holds the CFD history (5 creations, 10 status changes, 1 deletion), L0 the single item (7).
    expect(tab(1).rows.first.ref?.id, 'L1');
    expect(tab(1).rows.first.value, 16);
    // Blocked time inside the week: B (L1) 09-03 10:00 → 09-04 10:00 = 24 h; X (L0) 09-06 → 09-07 = 24 h.
    expect({for (final row in tab(2).rows) row.ref!.id: row.value}, {'L1': 24 * 60.0, 'L0': 24 * 60.0});
    // Lists with open items: L1 (C, E) and L3 (M); L0 is done.
    expect(tab(3).rows.map((row) => row.ref!.id), unorderedEquals(['L1', 'L3']));
    expect(tab(3).rows.every((row) => row.unit == StatUnit.days), isTrue);
  });
}
