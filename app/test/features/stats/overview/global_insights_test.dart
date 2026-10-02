// Overview P1/P2 metrics (T6.7.03–T6.7.18) through the registry on small seeded scenarios; the
// statistical rules themselves are pinned by `everslot_metrics` (global_metrics_test.dart).
import 'dart:math' as math;

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';

Map<String, Object?> _habit(String id, {String start = '2026-06-01', String goal = 'check', num? target}) => {
  'id': id,
  'kind': 'build',
  'name': 'Habit $id',
  'sort_key': id,
  'goal_type': goal,
  'target_value': ?target,
  'target_op': 'gte',
  'schedule': _daily,
  'start_date': start,
  'time_zone': 'UTC',
  'created_at': '${start}T06:00:00.000Z',
};

Map<String, Object?> _log(
  String id,
  String habit,
  LocalDate d, {
  String kind = 'done',
  num? value,
  String time = '08:00',
}) => {
  'id': id,
  'habit_id': habit,
  'kind': kind,
  'logged_at': '${d.toIso()}T$time:00.000Z',
  'local_date': d.toIso(),
  'created_at': '${d.toIso()}T$time:00.000Z',
  'value': ?value,
};

Map<String, Object?> _review(String id, String week) => {
  'id': id,
  'entity_type': 'review',
  'entity_id': id,
  'event_type': 'completed',
  'occurred_at': '${week}T18:00:00.000Z',
  'payload': {'week': week},
};

Iterable<LocalDate> _days(LocalDate from, LocalDate to) sync* {
  for (var d = from; !d.isAfter(to); d = d.plusDays(1)) {
    yield d;
  }
}

void main() {
  test('T6.7.03: review streak counts consecutive reviewed weeks; the due week stays open', () async {
    // Mon 21 Sep: the week due for review is 14–20 Sep.
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 21, 9));
    addTearDown(h.dispose);
    await h.seedTables({
      'activity_events': [_review('r1', '2026-08-31'), _review('r2', '2026-09-07')],
    });
    var r = await h.compute(MetricScope.global, metricIds: {'GL-04'});
    expect(r['GL-04']!.value.valueOrNull, 2, reason: 'the unreviewed due week does not break the streak');
    expect(r['GL-04']!.args['reviewedDue'], isFalse);
    await h.seedTables({
      'activity_events': [_review('r3', '2026-09-14')],
    });
    r = await h.compute(MetricScope.global, metricIds: {'GL-04'});
    expect(r['GL-04']!.value.valueOrNull, 3);
    expect(r['GL-04']!.args['longest'], 3);
  });

  test('T6.7.04: February vs March compares per-day averages and says so', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 4, 5, 12));
    addTearDown(h.dispose);
    // One check-in a day all of February and March: equal per-day volume, unequal raw sums.
    await h.seedTables({
      'habits': [_habit('h', start: '2026-02-01')],
      'habit_logs': [
        for (final d in _days(LocalDate(2026, 2, 1), LocalDate(2026, 4, 5))) _log('l${d.toIso()}', 'h', d),
      ],
    });
    final r = await h.compute(MetricScope.global, metricIds: {'GL-05'});
    final review = r['GL-05']!.chart! as ReviewData;
    expect((review.from.toIso(), review.to.toIso()), ('2026-03-01', '2026-03-31'));
    expect(review.perDay, isTrue);
    expect(r['GL-05']!.args['days'], 31);
    expect(r['GL-05']!.args['previousDays'], 28);
    final habits = review.headline.singleWhere((t) => t.metricId == 'HB-X-04');
    expect(habits.value, 1);
    expect(habits.delta, 0);
    expect(review.calendar!.cells, hasLength(31));
    expect(review.calendar!.cells[LocalDate(2026, 3, 3)]!.breakdown.single.$2, 1);
    // This month so far.
    final current = await h.compute(MetricScope.global, metricIds: {'GL-05'}, extra: 'current');
    expect((current['GL-05']!.chart! as ReviewData).from.toIso(), '2026-04-01');
  });

  group('T6.7.05 personal records', () {
    test('an old (backfilled) record is never new; a record set this week is announced once', () async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(h.dispose);
      await h.seedTables({
        'habits': [_habit('a'), _habit('b')],
        'habit_logs': [
          // a: 20-day streak in June (logged today = backfill), 11-day streak now.
          for (final d in _days(LocalDate(2026, 6, 1), LocalDate(2026, 6, 20)))
            {..._log('a${d.toIso()}', 'a', d), 'created_at': '2026-09-20T10:00:00.000Z'},
          for (final d in _days(LocalDate(2026, 9, 10), LocalDate(2026, 9, 20))) _log('a${d.toIso()}', 'a', d),
          // b: 10 days in June, then 27 days up to today (new record).
          for (final d in _days(LocalDate(2026, 6, 1), LocalDate(2026, 6, 10))) _log('b${d.toIso()}', 'b', d),
          for (final d in _days(LocalDate(2026, 8, 25), LocalDate(2026, 9, 20))) _log('b${d.toIso()}', 'b', d),
        ],
      });
      final r = await h.compute(MetricScope.global, metricIds: {'GL-06'});
      final records = (r['GL-06']!.args['records']! as List).cast<Map<String, Object?>>();
      Map<String, Object?> rec(String type, [String? entity]) =>
          records.singleWhere((x) => x['type'] == type && x['entity'] == entity);
      expect(rec('habitStreak', 'a')['value'], 20);
      expect(rec('habitStreak', 'a')['date'], '2026-06-20');
      expect(rec('habitStreak', 'a')['isNew'], isFalse);
      expect(rec('habitStreak', 'b')['value'], 27);
      expect(rec('habitStreak', 'b')['isNew'], isTrue);
      expect(rec('habitStreak', 'b')['previous'], 10);
      // Overall longest streak: b's 27 days.
      expect(rec('habitStreak')['value'], 27);
      final toAnnounce = r['GL-06']!.args['toAnnounce']! as List;
      expect(toAnnounce, contains('habitStreak:b|27.0'));
      expect(toAnnounce.any((k) => '$k'.startsWith('habitStreak:a')), isFalse);

      // Once announced (stored keys), the same record is not announced again.
      final announced = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(announced.dispose);
      await announced.seedSettings({
        'stats': {
          'announcedRecords': ['habitStreak:b|27.0', 'habitStreak|27.0'],
        },
      });
      await announced.seedTables({
        'habits': [_habit('b')],
        'habit_logs': [
          for (final d in _days(LocalDate(2026, 6, 1), LocalDate(2026, 6, 10))) _log('b${d.toIso()}', 'b', d),
          for (final d in _days(LocalDate(2026, 8, 25), LocalDate(2026, 9, 20))) _log('b${d.toIso()}', 'b', d),
        ],
      });
      final again = await announced.compute(MetricScope.global, metricIds: {'GL-06'});
      expect(again['GL-06']!.args['toAnnounce'], isNot(contains('habitStreak:b|27.0')));
    });
  });

  group('T6.7.06 day score', () {
    test('sections without data are excluded, not counted as 0', () async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(h.dispose);
      await h.seedTables({
        'habits': [_habit('a', start: '2026-09-15'), _habit('b', start: '2026-09-15')],
        'habit_logs': [_log('x', 'a', LocalDate(2026, 9, 20))],
      });
      final r = await h.compute(MetricScope.global, metricIds: {'GL-07'});
      // Habits only: 1 of 2 → 50, nothing else pulls it down.
      expect(r['GL-07']!.value.valueOrNull, closeTo(0.5, 1e-9));
      expect(r['GL-07']!.args['sections'], ['habits']);
    });

    test('acceptance example: (0.8 + 0.75 + 0.5 + 1) ÷ 4 = 76', () {
      final s = dayScore(
        DaySectionFacts(
          LocalDate(2026, 9, 20),
          plannerPlanned: 5,
          plannerDone: 4,
          habitsDue: 4,
          habitsDone: 3,
          itemsCompleted: 2,
          quitAbstinent: true,
        ),
        listsMedianPrior28: 4,
      );
      expect(s.valueOrNull, closeTo(76.25, 1e-9));
    });
  });

  test('T6.7.07: under 4 weeks is insufficient; a flat pattern has no clear weekday effect', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [_habit('a', start: '2026-09-05')],
      'habit_logs': [
        for (final d in _days(LocalDate(2026, 9, 5), LocalDate(2026, 9, 19)))
          if (d.day.isEven) _log('l${d.toIso()}', 'a', d),
      ],
    });
    var r = await h.compute(MetricScope.global, metricIds: {'GL-08'});
    expect(r['GL-08']!.value, isA<Insufficient<double>>());
    await h.seedTables({
      'habits': [_habit('b', start: '2026-06-01')],
      'habit_logs': [
        for (final d in _days(LocalDate(2026, 6, 1), LocalDate(2026, 9, 19))) _log('b${d.toIso()}', 'b', d),
      ],
    });
    r = await h.compute(MetricScope.global, metricIds: {'GL-08'});
    final effects = (r['GL-08']!.args['effects']! as List).cast<Map<String, Object?>>();
    expect(effects.single['metric'], 'habits');
    expect(effects.single['significant'], isFalse);
  });

  test('T6.7.09: habit goal numbers equal HB-H-26; achieved goals move to the achieved list', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 6, 30, 20));
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [_habit('p', goal: 'count', target: 1, start: '2026-01-01')],
      'habit_logs': [
        _log('big', 'p', LocalDate(2026, 1, 1), kind: 'progress', value: 3660),
        for (var d = 3; d <= 30; d++) _log('d$d', 'p', LocalDate(2026, 6, d), kind: 'progress', value: 30),
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
        {
          'id': 'done',
          'scope_type': 'habit',
          'scope_id': 'p',
          'metric': 'completions',
          'target': 5,
          'period': 'custom',
          'start_date': '2026-06-01',
          'end_date': '2026-06-30',
        },
      ],
    });
    final habit = await h.compute(MetricScope.habit, scopeId: 'p', period: const StatsPeriod.thisMonth());
    final global = await h.compute(MetricScope.global, metricIds: {'GL-09'});
    final goals = {for (final g in (global['GL-09']!.args['goals']! as List).cast<Map<String, Object?>>()) g['id']: g};
    expect(goals['g']!['actual'], habit['HB-H-26']!.value.valueOrNull);
    expect(goals['g']!['pace'], closeTo(habit['HB-H-26']!.args['pace']! as double, 1e-9));
    expect(goals['g']!['status'], habit['HB-H-26']!.args['status']);
    expect(goals['g']!['projectedEnd'], closeTo(habit['HB-H-26']!.args['projectedEnd']! as double, 1e-9));
    expect(goals['g']!['eta'], habit['HB-H-26']!.args['eta']);
    expect(goals['done']!['status'], 'achieved');
    final tabs = (global['GL-09']!.chart! as ChartGroup).charts;
    expect(tabs.last.$1, const TokenLabel(LabelToken.achieved));
    expect((tabs.last.$2 as ListData).rows, hasLength(1));
  });

  test('T6.7.11: the year grid counts done units per day with a section breakdown', () async {
    final h = await StatsFixture.load('overview_week').seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.global, metricIds: {'GL-11'});
    final grid = r['GL-11']!.chart! as CalendarData;
    expect(grid.mode, CalendarMode.intensity);
    expect(grid.from.daysUntil(grid.to), 364);
    for (final c in grid.cells.values) {
      final sum = c.breakdown
          .where((b) => b.$1 != const TokenLabel(LabelToken.abstinent))
          .fold<double>(0, (a, b) => a + b.$2);
      expect(sum, c.value);
    }
    expect(r['GL-11']!.value.valueOrNull, grid.cells.values.fold<double>(0, (a, c) => a + c.value!));
  });

  test('T6.7.13: a planted relationship between two habits surfaces exactly that pair', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
    addTearDown(h.dispose);
    final random = math.Random(7);
    final start = LocalDate(2026, 6, 1);
    final days = _days(start, LocalDate(2026, 9, 19)).toList();
    final a = [for (final _ in days) random.nextBool()];
    final c = [for (final _ in days) random.nextBool()];
    await h.seedTables({
      'habits': [_habit('a'), _habit('b'), _habit('c')],
      'habit_logs': [
        for (var i = 0; i < days.length; i++) ...[
          if (a[i]) _log('a$i', 'a', days[i]),
          // b follows a on 90 % of days.
          if (a[i] != (i % 10 == 0)) _log('b$i', 'b', days[i]),
          if (c[i]) _log('c$i', 'c', days[i]),
        ],
      ],
    });
    final r = await h.compute(MetricScope.global, metricIds: {'GL-13'});
    final pairs = (r['GL-13']!.args['pairs']! as List).cast<Map<String, Object?>>();
    expect(pairs.map((p) => {p['a'], p['b']}).toSet(), {
      {'habit:a', 'habit:b'},
    });
    expect(pairs.first['lag'], 0);
    expect(r['GL-13']!.note, 'correlationNotCausation');
  });

  test('T6.7.15: XP is opt-in, derived from what is done, so undoing removes it', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
    addTearDown(h.dispose);
    await h.seedTables({
      'habits': [_habit('a', start: '2026-09-20')],
      'habit_logs': [_log('x', 'a', LocalDate(2026, 9, 20))],
    });
    final off = await h.compute(MetricScope.global, metricIds: {'GL-15'});
    expect(off['GL-15']!.note, 'gamificationOff');
    final on = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
    addTearDown(on.dispose);
    await on.seedSettings({
      'stats': {'gamification': true},
    });
    await on.seedTables({
      'habits': [_habit('a', start: '2026-09-20')],
      'habit_logs': [_log('x', 'a', LocalDate(2026, 9, 20))],
    });
    var r = await on.compute(MetricScope.global, metricIds: {'GL-15'});
    expect(r['GL-15']!.value.valueOrNull, 10, reason: 'first check-in: 10 × (1 + 0/100)');
    await on.db.customStatement("DELETE FROM habit_logs WHERE id = 'x'");
    r = await on.compute(MetricScope.global, metricIds: {'GL-15'});
    expect(r['GL-15']!.value.valueOrNull, 0);
  });

  test('T6.7.17: time budget de-duplicates a habit log overlapping a focus session', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 22));
    addTearDown(h.dispose);
    await h.seedTables({
      'tasks': [
        {
          'id': 't',
          'series_id': 't',
          'title': 'Write',
          'created_at': '2026-09-10T08:00:00.000Z',
          'start_local': '2026-09-20T09:00',
          'duration_minutes': 120,
          'time_zone': 'UTC',
          'tracking_mode': 'timer',
        },
      ],
      'time_entries': [
        {'id': 's', 'task_id': 't', 'started_at': '2026-09-20T09:00:00.000Z', 'ended_at': '2026-09-20T10:00:00.000Z'},
      ],
      'habits': [_habit('r', start: '2026-09-20', goal: 'duration', target: 30)],
      // 09:45–10:15: overlaps the 09:00–10:00 session by 15 min.
      'habit_logs': [_log('l', 'r', LocalDate(2026, 9, 20), kind: 'progress', value: 30, time: '10:15')],
    });
    final r = await h.compute(
      MetricScope.global,
      metricIds: {'GL-17'},
      period: PeriodSelection.parsePeriod('custom:2026-09-20..2026-09-20')!,
    );
    final bars = r['GL-17']!.chart! as BarData;
    expect(bars.series[0].values.single, 2, reason: 'max(planned 120, tracked 60) min');
    expect(bars.series[1].values.single, closeTo(15 / 60, 1e-9), reason: '30 min habit − 15 min overlap');
    expect(bars.series[2].values.single, closeTo((960 - 135) / 60, 1e-9));
    expect(r['GL-17']!.args['overlapMinutes'], 15);
  });

  test('T6.7.18: Monte Carlo forecasts need 30 days and are reproducible per goal', () async {
    Future<Map<String, Object?>?> run(LocalDate start) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
      addTearDown(h.dispose);
      await h.seedTables({
        'habits': [_habit('p', goal: 'count', target: 1, start: start.toIso())],
        'habit_logs': [
          for (final d in _days(start, LocalDate(2026, 9, 20)))
            _log('l${d.toIso()}', 'p', d, kind: 'progress', value: d.day % 3 == 0 ? 0 : 20),
        ],
        'goals': [
          {
            'id': 'g',
            'scope_type': 'habit',
            'scope_id': 'p',
            'metric': 'total_value',
            'target': 5000,
            'period': 'custom',
            'start_date': start.toIso(),
            'end_date': '2026-12-31',
          },
        ],
      });
      final r = await h.compute(MetricScope.global, metricIds: {'GL-18'});
      if (r['GL-18']!.value is Insufficient<double>) return null;
      expect(r['GL-18']!.estimate, isTrue);
      return ((r['GL-18']!.args['forecasts']! as List).single as Map).cast<String, Object?>();
    }

    expect(await run(LocalDate(2026, 9, 1)), isNull, reason: '20 days of history');
    final first = await run(LocalDate(2026, 7, 1));
    final second = await run(LocalDate(2026, 7, 1));
    expect(first, isNotNull);
    expect(first!['p50'], second!['p50']);
    expect(LocalDate.parse(first['p50']! as String).isAfter(LocalDate(2026, 9, 20)), isTrue);
    expect(LocalDate.parse(first['p95']! as String).isBefore(LocalDate.parse(first['p50']! as String)), isFalse);
  });

  test('every P1/P2 overview metric computes on an empty database and on overview_week', () async {
    final empty = StatsHarness.create(now: DateTime.utc(2026, 9, 20, 20));
    addTearDown(empty.dispose);
    final e = await empty.compute(MetricScope.global);
    expect(e.values.where((m) => m.note == 'error'), isEmpty);
    final h = await StatsFixture.load('overview_week').seed();
    addTearDown(h.dispose);
    final r = await h.compute(MetricScope.global, extra: '2026');
    expect(r.values.where((m) => m.note == 'error').map((m) => m.metricId), isEmpty);
    expect((r['GL-14']!.chart! as ChartGroup).charts.first.$1, const TokenLabel(LabelToken.yearInNumbers));
  });
}
