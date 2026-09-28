// Habit metrics through the whole pipeline: strength parity (T6.5.02), streak lists (T6.5.03) and
// history buckets (T6.5.04).
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';

/// A daily yes/no habit from 1 August 2026 done on the first [doneDays] days, seen in the evening of
/// the last one (today is done), so the score has been updated exactly [doneDays] times.
Future<StatsHarness> everyDay(int doneDays, {String goal = 'check', double? target, String op = 'gte', bool logs = true}) async {
  final start = LocalDate(2026, 8, 1);
  final last = start.plusDays(doneDays - 1);
  final h = StatsHarness.create(now: DateTime.utc(last.year, last.month, last.day, 20));
  await h.seedTables({
    'habits': [
      {
        'id': 'h',
        'kind': 'build',
        'name': 'Habit',
        'sort_key': 'a',
        'goal_type': goal,
        'target_value': ?target,
        'target_op': op,
        'schedule': _daily,
        'start_date': start.toIso(),
        'time_zone': 'UTC',
        'auto_success': true,
        'created_at': '2026-07-31T20:00:00.000Z',
      },
    ],
    'habit_logs': [
      if (logs)
        for (var i = 0; i < doneDays; i++)
          {
            'id': 'l$i',
            'habit_id': 'h',
            'kind': 'done',
            'logged_at': '${start.plusDays(i).toIso()}T08:00:00.000Z',
            'local_date': start.plusDays(i).toIso(),
            'occurrence_key': start.plusDays(i).toIso(),
          },
    ],
  });
  return h;
}

void main() {
  group('strength (T6.5.02)', () {
    test('a daily habit done every day reaches 0.500 after 13 updates and 0.798 after 30', () async {
      for (final (days, expected) in [(13, 0.5), (30, 0.798)]) {
        final h = await everyDay(days);
        final r = await h.compute(MetricScope.habit, scopeId: 'h', period: const StatsPeriod.allTime(), metricIds: {'HB-H-01'});
        expect(r['HB-H-01']!.value.valueOrNull, closeTo(expected, 0.001), reason: '$days days');
        await h.dispose();
      }
    });

    test('an at-most habit starts at 1.0 and stays there within the limit', () async {
      final h = await everyDay(10, goal: 'count', target: 2, op: 'lte', logs: false);
      addTearDown(h.dispose);
      final r = await h.compute(MetricScope.habit, scopeId: 'h', period: const StatsPeriod.allTime(), metricIds: {'HB-H-01'});
      expect(r['HB-H-01']!.value.valueOrNull, closeTo(1.0, 1e-9));
    });
  });

  group('streaks and history (T6.5.03, T6.5.04)', () {
    late StatsHarness h;
    setUp(() async => h = await StatsFixture.load('habits_portfolio').seed());
    tearDown(() => h.dispose());

    final period = PeriodSelection.parsePeriod('custom:2026-09-14..2026-09-27')!;

    test('top streaks are ordered by length, then recency; quota habits count periods', () async {
      final journal = await h.compute(MetricScope.habit, scopeId: 'journal', period: period, metricIds: {'HB-H-04'});
      final bars = (journal['HB-H-04']!.chart! as StreakData).streaks;
      expect(bars.first.length, 6);
      expect(bars.first.start, LocalDate(2026, 9, 14));
      expect(bars.map((b) => b.length), orderedEquals([...bars.map((b) => b.length)]..sort((a, b) => b.compareTo(a))));
      final gym = await h.compute(MetricScope.habit, scopeId: 'gym', period: period, metricIds: {'HB-H-03'});
      expect(gym['HB-H-03']!.args['unitKind'], 'period');
    });

    test('history buckets count successes per week', () async {
      final water = await h.compute(MetricScope.habit, scopeId: 'water', period: period, metricIds: {'HB-H-07'});
      final chart = water['HB-H-07']!.chart!;
      final successes = [for (final row in chart.toTable().rows) row[1].value];
      // Week of 14 Sep: 14, 16, 17, 18, 20 · week of 21 Sep: 21, 22, 24, 25, 26, 27.
      expect(successes.where((v) => v != null && v > 0), [5, 6]);
    });
  });
}
