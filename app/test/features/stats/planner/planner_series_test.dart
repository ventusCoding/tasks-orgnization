// Series execution metrics (T6.3.04): a "this & following" split keeps the series (ledger, streak,
// totals) continuous; time invested and the outcome calendar.
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

String _rule({String? until}) =>
    '{"v":1,"type":"fixed","freq":"daily","interval":1${until == null ? '' : ',"until":"$until"'}}';

/// Daily 07:00 "Run" from Mon 14 Sep; split on Sat 19 (07:30 from then on); every occurrence done
/// on time through Tue 22; now = Wed 23 12:00 UTC (23 is done too).
Map<String, Object?> splitSeries() {
  final occurrences = <Map<String, Object?>>[];
  final entries = <Map<String, Object?>>[];
  for (var day = 14; day <= 23; day++) {
    final dd = day.toString().padLeft(2, '0');
    final first = day < 19;
    final task = first ? 'run-1' : 'run-2';
    final time = first ? '07:00' : '07:30';
    final key = '2026-09-${dd}T$time';
    occurrences.add({
      'id': 'o$day',
      'task_id': task,
      'occurrence_key': key,
      'status': 'done',
      'completed_at': '2026-09-${dd}T${first ? '07:25' : '07:55'}:00.000Z',
    });
    if (day >= 21) {
      entries.add({
        'id': 'e$day',
        'task_id': task,
        'occurrence_key': key,
        'started_at': '2026-09-${dd}T07:30:00.000Z',
        'ended_at': '2026-09-${dd}T08:00:00.000Z',
      });
    }
  }
  return {
    'tasks': [
      {
        'id': 'run-1',
        'series_id': 'run',
        'title': 'Run',
        'start_local': '2026-09-14T07:00',
        'duration_minutes': 25,
        'time_zone': 'UTC',
        'recurrence': _rule(until: '2026-09-18T23:59'),
        'created_at': '2026-09-13T08:00:00.000Z',
      },
      {
        'id': 'run-2',
        'series_id': 'run',
        'title': 'Run',
        'start_local': '2026-09-19T07:30',
        'duration_minutes': 25,
        'time_zone': 'UTC',
        'recurrence': _rule(),
        'created_at': '2026-09-18T20:00:00.000Z',
      },
    ],
    'task_occurrences': occurrences,
    'time_entries': entries,
  };
}

/// 14 → 23 September.
final period = StatsPeriod.custom(LocalDate(2026, 9, 14), LocalDate(2026, 9, 23));

void main() {
  test('a split series stays one series: ledger, streak, totals and last done', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 12));
    addTearDown(h.dispose);
    await h.seedTables(splitSeries());
    final r = await h.compute(MetricScope.series, scopeId: 'run', period: period);
    expect(r['PL-S-01']!.value.valueOrNull, 10);
    expect(r['PL-S-03']!.value.valueOrNull, 1.0);
    expect(r['PL-S-05']!.value.valueOrNull, 10, reason: 'streak continues across the split');
    expect(r['PL-S-05']!.args['best'], 10);
    expect(r['PL-S-07']!.value.valueOrNull, 10);
    expect(r['PL-S-08']!.value.valueOrNull, 0);
  });

  test('time invested sums tracked sessions and planned time; the calendar has one cell per day', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 12));
    addTearDown(h.dispose);
    await h.seedTables(splitSeries());
    final r = await h.compute(MetricScope.series, scopeId: 'run', period: period);
    final invested = r['PL-S-06']!;
    // Three tracked 30-minute sessions (21–23 September).
    expect(invested.value.valueOrNull, 90);
    final calendar = r['PL-S-09']!.chart! as CalendarData;
    expect(calendar.cells, hasLength(10));
    expect(calendar.cells.values.every((c) => c.tone == ChartTone.done), isTrue);
  });
}
