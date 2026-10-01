// Habit Insights P1/P2 metrics (T6.5.06–T6.5.10, T6.5.12, T6.5.14, T6.5.15) through the registry:
// the canonical push-up month and small seeded habits for the other acceptance criteria.
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';

Map<String, Object?> _habit(
  String id, {
  String goal = 'check',
  num? target,
  String op = 'gte',
  String start = '2026-09-01',
}) => {
  'id': id,
  'kind': 'build',
  'name': 'Habit $id',
  'sort_key': id,
  'goal_type': goal,
  'target_value': ?target,
  'target_op': op,
  'schedule': _daily,
  'start_date': start,
  'time_zone': 'UTC',
  'created_at': '${start}T06:00:00.000Z',
};

Map<String, Object?> _log(
  String id,
  String habit,
  String date, {
  String kind = 'done',
  num? value,
  String time = '08:00',
}) => {
  'id': id,
  'habit_id': habit,
  'kind': kind,
  'logged_at': '${date}T$time:00.000Z',
  'local_date': date,
  'created_at': '${date}T$time:00.000Z',
  'value': ?value,
};

String _day(int d) => LocalDate(2026, 9, d).toIso();

void main() {
  test('T6.5.06: canonical month — partial share 3/29, mean fulfilment 89.7 %', () async {
    final h = await StatsFixture.load('habit_pushups_month').seed();
    addTearDown(h.dispose);
    final r = await h.compute(
      MetricScope.habit,
      scopeId: 'pushups',
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-30')!,
    );
    expect(r['HB-H-15']!.args['partialShare']! as double, closeTo(3 / 29, 1e-9));
    expect(r['HB-H-15']!.value.valueOrNull, closeTo((24 + 3 * 10 / 15) / 29, 1e-9));
    final records = r['HB-H-13']!.chart! as ListData;
    expect(records.rows.first.value, 15);
    expect(r['HB-H-14']!.chart, isA<HistogramData>());
    expect(r['HB-H-12']!.value.hasValue, isTrue);
  });

  test('T6.5.07: limit 2 with {1, 2, 3, 5, 0} → 3/5 within, excess 4, credits', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 6, 12));
    addTearDown(h.dispose);
    const values = [1, 2, 3, 5, 0];
    await h.seedTables({
      'habits': [
        {..._habit('coffee', goal: 'count', target: 2, op: 'lte'), 'auto_success': true},
      ],
      'habit_logs': [
        for (var i = 0; i < 5; i++)
          if (values[i] > 0) _log('c$i', 'coffee', _day(i + 1), kind: 'progress', value: values[i]),
      ],
    });
    final r = await h.compute(
      MetricScope.habit,
      scopeId: 'coffee',
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-05')!,
    );
    expect(r['HB-H-16']!.value.valueOrNull, closeTo(3 / 5, 1e-9));
    expect(r['HB-H-16']!.args['excess'], 4);
    expect(r['HB-H-16']!.args['credits'], [1.0, 1.0, 0.5, 0.0, 1.0]);
  });

  test('T6.5.10: D M D M M D M → recovery 2/3, longest gap 2, no comebacks', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 8, 12));
    addTearDown(h.dispose);
    const pattern = 'DMDMMDM';
    await h.seedTables({
      'habits': [_habit('r')],
      'habit_logs': [
        for (var i = 0; i < pattern.length; i++)
          if (pattern[i] == 'D') _log('l$i', 'r', _day(i + 1)),
      ],
    });
    final r = await h.compute(
      MetricScope.habit,
      scopeId: 'r',
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-07')!,
    );
    expect(r['HB-H-22']!.value.valueOrNull, closeTo(2 / 3, 1e-9), reason: 'the final miss has no closed next unit');
    expect(r['HB-H-22']!.args['longestGap'], 2);
    expect(r['HB-H-22']!.args['comebacks'], 0);
    final tiles = r['HB-H-22']!.chart! as TilesData;
    expect(tiles.tiles.first.value, 2);
  });

  test('T6.5.09: check-ins at 23:30 and 00:30 with a 04:00 day start average to midnight', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedSettings({
      'habits': {'dayStartMinutes': 240},
    });
    await h.seedTables({
      'habits': [_habit('n')],
      'habit_logs': [
        _log('a', 'n', _day(7), time: '23:30'),
        _log(
          'b',
          'n',
          _day(7),
          time: '00:30',
        ).map((k, v) => MapEntry(k, k == 'logged_at' ? '${_day(8)}T00:30:00.000Z' : v)),
      ],
    });
    final r = await h.compute(MetricScope.habit, scopeId: 'n', period: const StatsPeriod.thisMonth());
    expect(r['HB-H-19']!.value.valueOrNull, 0);
    final rose = (r['HB-H-19']!.chart! as ChartGroup).charts.first.$2 as RoseData;
    expect(rose.dayStartMinute, 240);
  });

  test('T6.5.08: consistency ignores days the rule does not schedule', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 29, 12));
    addTearDown(h.dispose);
    const mwf =
        '{"v":1,"type":"fixed","freq":"weekly","interval":1,"byWeekday":[{"day":"MO"},{"day":"WE"},{"day":"FR"}]}';
    await h.seedTables({
      'habits': [
        {..._habit('m'), 'schedule': mwf},
      ],
      'habit_logs': [
        for (var d = 1; d <= 28; d++)
          if (LocalDate(2026, 9, d).weekday.iso case 1 || 3 || 5) _log('m$d', 'm', _day(d)),
      ],
    });
    final r = await h.compute(
      MetricScope.habit,
      scopeId: 'm',
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-28')!,
    );
    expect(r['HB-H-17']!.value.valueOrNull, closeTo(1, 1e-3));
    final weekdays = r['HB-H-18']!.chart! as BarData;
    expect(weekdays.series.first.values.where((v) => v > 0), hasLength(3));
  });

  test('T6.5.12: 10 000 push-ups in 2026 — pace 4 959, behind, projection 10 020, ETA Dec 31', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 6, 30, 20));
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [_habit('p', goal: 'count', target: 1, start: '2026-01-01')],
      'habit_logs': [
        _log('big', 'p', '2026-01-01', kind: 'progress', value: 3660),
        for (var d = 3; d <= 30; d++) _log('d$d', 'p', LocalDate(2026, 6, d).toIso(), kind: 'progress', value: 30),
      ],
      'goals': [
        {
          'id': 'g',
          'scope_type': 'habit',
          'scope_id': 'p',
          'metric': 'volume',
          'target': 10000,
          'period': 'once',
          'start_date': '2026-01-01',
          'end_date': '2026-12-31',
        },
      ],
    });
    final r = await h.compute(MetricScope.habit, scopeId: 'p', period: const StatsPeriod.thisMonth());
    final m = r['HB-H-26']!;
    expect(m.value.valueOrNull, 4500);
    expect(m.args['pace']! as double, closeTo(4958.9, 0.1));
    expect(m.args['status'], 'behind');
    expect(m.args['projectedEnd']! as double, closeTo(10020, 1e-6));
    expect(m.args['eta'], '2026-12-31');
  });

  test('T6.5.14/15: section metrics compute; co-occurrence stays hidden below 21 shared days', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [_habit('a'), _habit('b')],
      'habit_logs': [
        for (var d = 1; d <= 9; d++) _log('a$d', 'a', _day(d)),
        for (var d = 1; d <= 9; d += 2) _log('b$d', 'b', _day(d)),
      ],
    });
    final r = await h.compute(MetricScope.habits, period: const StatsPeriod.thisMonth());
    expect((r['HB-X-06']!.chart! as BarData).categories, hasLength(2));
    expect(r['HB-X-09']!.args['best'], 'a');
    expect(r['HB-X-10']!.value.valueOrNull, 14);
    expect(r['HB-X-13']!.value, isA<NotApplicable<double>>());
    expect(r.values.where((m) => m.note == 'error'), isEmpty);
  });

  test('every P1/P2 habit metric computes on an empty database', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    for (final scope in [MetricScope.habit, MetricScope.habits]) {
      final r = await h.compute(scope, scopeId: scope == MetricScope.habit ? 'none' : null);
      expect(r.values.where((m) => m.note == 'error'), isEmpty, reason: '$scope');
    }
  });
}
