// Fixture-driven checks of the whole stats pipeline (T6.1.15): table fixtures are seeded into an
// in-memory Drift database, loaded by the stats data source, resolved in a batch job and computed by
// the registry, then compared with the canonical hand-computed expectations.
import 'package:flutter_test/flutter_test.dart';

import 'support/stats_harness.dart';

/// Canonical datasets (`test/features/stats/fixtures/`, derived from `fixtures/stats/`).
const canonicalFixtures = [
  'planner_two_weeks',
  'habit_pushups_month',
  'habits_portfolio',
  'quit_smoking_90_days',
  'quit_reduce_week',
  'quit_attempts',
  'checklist_flow_small',
  'overview_week',
];

void main() {
  for (final name in canonicalFixtures) {
    test('fixture $name', () async {
      final fixture = StatsFixture.load(name);
      final h = await fixture.seed();
      addTearDown(h.dispose);
      final failures = await runFixture(fixture, h);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }

  group('harness self-tests', () {
    StatsFixture inline(List<Map<String, Object?>> expect) => StatsFixture('inline', {
      'now': '2026-09-22T09:00:00.000Z',
      'zone': 'UTC',
      'settings': <String, Object?>{},
      'tables': <String, Object?>{},
      'expect': expect,
    });

    Future<List<String>> run(List<Map<String, Object?>> expect) async {
      final fixture = inline(expect);
      final h = await fixture.seed();
      addTearDown(h.dispose);
      return runFixture(fixture, h);
    }

    Map<String, Object?> overdue(Map<String, Object?> extra) => {'scope': 'planner', 'metricId': 'PL-X-06', ...extra};

    test('values within the tolerance pass; outside it they fail with a readable diff', () async {
      expect(await run([overdue({'value': 0.0000005})]), isEmpty);
      expect(await run([overdue({'value': 0.4, 'tolerance': 0.5})]), isEmpty);
      final failures = await run([overdue({'value': 0.01})]);
      expect(failures, hasLength(1));
      expect(failures.single, contains('inline · PL-X-06'));
      expect(failures.single, contains('value expected 0.01'));
    });

    test('insufficient, note, arg and unknown-metric expectations are checked', () async {
      final failures = await run([
        overdue({'insufficient': true}),
        {'scope': 'planner', 'metricId': 'PL-X-05', 'note': 'nope'},
        {'scope': 'planner', 'metricId': 'PL-X-03', 'args': {'unplanned': 99}},
        {'scope': 'planner', 'metricId': 'PL-X-99', 'value': 1},
      ]);
      expect(failures, hasLength(4), reason: failures.join('\n'));
      expect(failures[0], contains('expected Insufficient'));
      expect(failures[1], contains('note expected nope'));
      expect(failures[2], contains('arg unplanned expected 99'));
      expect(failures[3], contains('no result'));
    });
  });
}
