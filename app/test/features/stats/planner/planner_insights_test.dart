// Planner Insights P1/P2 metrics (T6.3.03, T6.3.05, T6.3.06, T6.3.10–T6.3.16) through the registry:
// each acceptance criterion on a small seeded scenario (UTC, now = Wed 2026-09-23 12:00).
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

final _now = DateTime.utc(2026, 9, 23, 12);

Map<String, Object?> task(
  String id,
  String start,
  int minutes, {
  String? recurrence,
  String mode = 'timer',
  int priority = 0,
  String? category,
}) => {
  'id': id,
  'series_id': id,
  'title': 'Task $id',
  'created_at': '2026-09-10T08:00:00.000Z',
  'start_local': start,
  'duration_minutes': minutes,
  'time_zone': 'UTC',
  'tracking_mode': mode,
  'priority': priority,
  'category_id': ?category,
  'recurrence': ?recurrence,
};

Map<String, Object?> occ(String task, String key, {String status = 'done', String? done}) => {
  'id': 'occ-$task-$key',
  'task_id': task,
  'occurrence_key': key,
  'status': status,
  'completed_at': ?(status == 'done' ? (done ?? '$key:00.000Z') : null),
  'status_changed_at': done ?? '${key.substring(0, 10)}T20:00:00.000Z',
};

Map<String, Object?> session(String id, String task, String? key, String start, String end) => {
  'id': id,
  'task_id': task,
  'occurrence_key': key,
  'started_at': '$start:00.000Z',
  'ended_at': '$end:00.000Z',
};

Map<String, Object?> move(String id, String task, String from, String to, {String? key, String at = '2026-09-15'}) => {
  'id': id,
  'entity_type': 'task',
  'entity_id': task,
  'event_type': 'rescheduled',
  'occurred_at': '${at}T08:00:00.000Z',
  'payload': '{"fromStart":"$from","toStart":"$to"${key == null ? '' : ',"occurrenceKey":"$key"'}}',
};

void main() {
  late StatsHarness h;
  setUp(() => h = StatsHarness.create(now: _now));
  tearDown(() => h.dispose());

  Future<Map<String, MetricResult>> section({String? extra, StatsPeriod period = const StatsPeriod.thisWeek()}) =>
      h.compute(MetricScope.planner, period: period, extra: extra);

  test('T6.3.03: three moves (+1 d, +2 h, −30 min) — count, distance, drift, snowball', () async {
    await h.seedTables({
      'tasks': [task('m', '2026-09-19T10:30', 30)],
      'activity_events': [
        move('e1', 'm', '2026-09-18T09:00', '2026-09-19T09:00', at: '2026-09-15'),
        move('e2', 'm', '2026-09-19T09:00', '2026-09-19T11:00', at: '2026-09-16'),
        move('e3', 'm', '2026-09-19T11:00', '2026-09-19T10:30', at: '2026-09-17'),
      ],
    });
    final r = await h.compute(MetricScope.task, scopeId: 'm');
    expect(r['PL-T-08']!.value.valueOrNull, 3);
    expect(r['PL-T-08']!.chart, isA<MoveTimelineData>());
    expect(r['PL-T-09']!.value.valueOrNull, 26.5 * 60);
    expect(r['PL-T-10']!.value.valueOrNull, 24 * 60 + 90);
    expect(r['PL-T-11']!.chart, isA<ListData>());
    // Planning horizon: first planned start (Sep 18 09:00) − created (Sep 10 08:00).
    expect(r['PL-T-14']!.value.valueOrNull, 8 * 1440 + 60);
  });

  test('T6.3.03: focus sessions and slot fit of one occurrence', () async {
    await h.seedTables({
      'tasks': [task('f', '2026-09-22T09:00', 60)],
      'task_occurrences': [occ('f', '2026-09-22T09:00', done: '2026-09-22T10:20:00.000Z')],
      'time_entries': [
        session('s1', 'f', '2026-09-22T09:00', '2026-09-22T08:50', '2026-09-22T09:40'),
        session('s2', 'f', '2026-09-22T09:00', '2026-09-22T09:45', '2026-09-22T10:20'),
      ],
    });
    final r = await h.compute(MetricScope.task, scopeId: 'f');
    expect(r['PL-T-16']!.value.valueOrNull, 2);
    expect(r['PL-T-16']!.args['pauses'], 1);
    // 85 tracked minutes, 40 + 15 of them inside 09:00–10:00.
    expect(r['PL-T-15']!.value.valueOrNull, closeTo(55 / 85, 1e-9));
    expect(r['PL-T-15']!.args['spilledBeforeMinutes'], 10);
    expect(r['PL-T-15']!.args['spilledAfterMinutes'], 20);
    expect(r['PL-T-15']!.chart, isA<GanttData>());
  });

  test('T6.3.06: starts at 23:50 and 00:10 average to midnight with a small spread', () async {
    const daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';
    await h.seedTables({
      'tasks': [task('g', '2026-09-14T23:50', 10, recurrence: daily)],
      'task_occurrences': [
        occ('g', '2026-09-20T23:50', done: '2026-09-21T00:00:00.000Z'),
        occ('g', '2026-09-21T23:50', done: '2026-09-22T00:20:00.000Z'),
      ],
      'time_entries': [
        session('a', 'g', '2026-09-20T23:50', '2026-09-20T23:50', '2026-09-21T00:00'),
        session('b', 'g', '2026-09-21T23:50', '2026-09-22T00:10', '2026-09-22T00:20'),
      ],
    });
    final r = await h.compute(MetricScope.series, scopeId: 'g');
    expect(r['PL-S-20']!.value.valueOrNull, 0);
    expect(r['PL-S-20']!.args['sd']! as double, lessThan(15));
    expect(r['PL-S-20']!.chart, isA<RoseData>());
    // Start drift: 0 and +20 min → +10.
    expect(r['PL-S-21']!.value.valueOrNull, closeTo(10, 1e-6));
  });

  test('T6.3.05: weekday profile only lists the weekdays the rule schedules', () async {
    const moTh = '{"v":1,"type":"fixed","freq":"weekly","interval":1,"byWeekday":[{"day":"MO"},{"day":"TH"}]}';
    await h.seedTables({
      'tasks': [task('w', '2026-08-31T08:00', 30, recurrence: moTh, mode: 'check')],
      'task_occurrences': [occ('w', '2026-09-03T08:00'), occ('w', '2026-09-07T08:00'), occ('w', '2026-09-21T08:00')],
    });
    final r = await h.compute(MetricScope.series, scopeId: 'w');
    final bars = r['PL-S-16']!.chart! as BarData;
    expect(bars.categories, hasLength(2));
    expect(r['PL-S-14']!.value.hasValue, isTrue);
    expect(r['PL-S-13']!.chart, isA<StreakData>());
  });

  test('T6.3.10: tag totals carry an overlap note when a task has several tags', () async {
    await h.seedTables({
      'tasks': [task('a', '2026-09-21T09:00', 60, priority: 4), task('b', '2026-09-22T09:00', 30)],
      'tags': [
        {'id': 't1', 'name': 'Deep', 'sort_key': 'a'},
        {'id': 't2', 'name': 'Client', 'sort_key': 'b'},
      ],
      'entity_tags': [
        {'id': 'l1', 'tag_id': 't1', 'entity_type': 'task', 'entity_id': 'a'},
        {'id': 'l2', 'tag_id': 't2', 'entity_type': 'task', 'entity_id': 'a'},
      ],
    });
    final r = await section();
    expect(r['PL-X-17']!.note, 'tagsOverlap');
    expect(r['PL-X-18']!.value.valueOrNull, closeTo(60 / 90, 1e-9));
    expect(r['PL-X-16']!.value.valueOrNull, 90);
    expect(r['PL-X-19']!.chart, isA<TreemapData>());
  });

  test('T6.3.11: bias +27.5 %, MAPE 28 %, buffer +42 % from the reference ratios', () async {
    const ratios = [1.2, 1.5, 1.0, 1.3, 1.4, 1.1, 1.25, 1.6, 0.9, 1.35];
    String at(int i) => '2026-09-2${1 + i % 2}T${(6 + i).toString().padLeft(2, '0')}:00';
    String plus(String start, int minutes) {
      final t = DateTime.parse('$start:00Z').add(Duration(minutes: minutes));
      return t.toIso8601String().substring(0, 16);
    }

    await h.seedTables({
      'tasks': [for (var i = 0; i < 10; i++) task('e$i', at(i), 100)],
      'task_occurrences': [for (var i = 0; i < 10; i++) occ('e$i', at(i), done: '${plus(at(i), 160)}:00.000Z')],
      'time_entries': [
        for (var i = 0; i < 10; i++) session('s$i', 'e$i', at(i), at(i), plus(at(i), (ratios[i] * 100).round())),
      ],
    });
    final r = await section();
    expect(r['PL-X-21']!.value.valueOrNull, closeTo(0.2748, 1e-3));
    expect(r['PL-X-21']!.args['tendency'], 'underestimate');
    expect(r['PL-X-22']!.value.valueOrNull, closeTo(0.28, 1e-9));
    expect(r['PL-X-23']!.value.valueOrNull, closeTo(0.42, 1e-9));
    expect((r['PL-X-24']!.chart! as ScatterData).points, hasLength(10));
  });

  test('T6.3.11: fewer than 10 tracked occurrences are insufficient', () async {
    await h.seedTables({
      'tasks': [task('x', '2026-09-21T09:00', 60)],
      'task_occurrences': [occ('x', '2026-09-21T09:00')],
      'time_entries': [session('s', 'x', '2026-09-21T09:00', '2026-09-21T09:00', '2026-09-21T10:00')],
    });
    expect((await section())['PL-X-21']!.value, isA<Insufficient<double>>());
  });

  test('T6.3.12: an earlier move counts as rescheduled but not as postponement', () async {
    await h.seedTables({
      'tasks': [
        task('p', '2026-09-22T08:00', 30),
        task('q', '2026-09-22T15:00', 30),
        task('r', '2026-09-22T17:00', 30),
        task('s', '2026-09-23T09:00', 30),
      ],
      'activity_events': [
        move('e1', 'p', '2026-09-22T10:00', '2026-09-22T08:00'),
        move('e2', 'q', '2026-09-22T13:00', '2026-09-22T15:00'),
      ],
    });
    final r = await section();
    expect(r['PL-X-29']!.value.valueOrNull, 0.5, reason: 'both moved occurrences count');
    expect(r['PL-X-30']!.value.valueOrNull, 2, reason: 'only the 2-hour forward move');
    expect(r['PL-X-31']!.value.valueOrNull, 0.25);
  });

  test('T6.3.13: slot occupancy follows the slot size of the view', () async {
    await h.seedTables({
      'tasks': [task('a', '2026-09-21T09:00', 60)],
    });
    final hour = await section(extra: 'slot:60');
    final half = await section(extra: 'slot:30');
    expect((hour['PL-X-35']!.chart! as MatrixData).columns, hasLength(24));
    expect((half['PL-X-35']!.chart! as MatrixData).columns, hasLength(48));
    expect(half['PL-X-35']!.args['slotMinutes'], 30);
  });

  test('T6.3.14: 50 min + 1 min gap + 20 min of the same task is one 70-minute deep-work block', () async {
    await h.seedTables({
      'tasks': [task('d', '2026-09-22T09:00', 120)],
      'task_occurrences': [occ('d', '2026-09-22T09:00', done: '2026-09-22T10:11:00.000Z')],
      'time_entries': [
        session('s1', 'd', '2026-09-22T09:00', '2026-09-22T09:00', '2026-09-22T09:50'),
        session('s2', 'd', '2026-09-22T09:00', '2026-09-22T09:51', '2026-09-22T10:11'),
      ],
    });
    final r = await section();
    expect(r['PL-X-38']!.value.valueOrNull, closeTo(70 / 60, 1e-9));
    expect(r['PL-X-38']!.args['blocks'], 1);
    expect(r['PL-X-41']!.value, isA<Insufficient<double>>(), reason: 'one done occurrence is below the rate rule');
  });

  test('T6.3.15: a weekend without capacity does not break a daily goal streak', () async {
    final days = ['2026-09-17', '2026-09-18', '2026-09-21', '2026-09-22'];
    await h.seedTables({
      'tasks': [for (final d in days) task('t$d', '${d}T09:00', 30, mode: 'check')],
      'task_occurrences': [for (final d in days) occ('t$d', '${d}T09:00')],
      'goals': [
        {'id': 'g1', 'scope_type': 'global', 'metric': 'completions', 'target': 1, 'period': 'day'},
      ],
    });
    final r = await section();
    // Thu, Fri, (weekend neutral), Mon, Tue; today (Wed) is still open.
    expect(r['PL-X-42']!.value.valueOrNull, 4);
  });

  test('T6.3.16: one free block → fragmentation 0; productivity hidden without weights', () async {
    await h.seedTables({
      'tasks': [task('a', '2026-09-21T09:00', 60), task('b', '2026-09-22T09:00', 60)],
    });
    final r = await section(period: StatsPeriod.custom(LocalDate(2026, 9, 21), LocalDate(2026, 9, 22)));
    expect(r['PL-X-43']!.value.valueOrNull, 0);
    expect(r['PL-X-45']!.value, isA<NotApplicable<double>>());
    expect(r['PL-X-45']!.note ?? (r['PL-X-45']!.value as NotApplicable<double>).reasonKey, 'noCategoryWeights');
  });

  test('every P1/P2 planner metric computes on an empty database', () async {
    for (final scope in [MetricScope.task, MetricScope.series, MetricScope.planner]) {
      final r = await h.compute(scope, scopeId: scope == MetricScope.planner ? null : 'none');
      expect(r.values.where((m) => m.note == 'error'), isEmpty, reason: '$scope');
    }
  });
}
