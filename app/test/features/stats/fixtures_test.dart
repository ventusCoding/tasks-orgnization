// Fixture-driven checks of the whole stats pipeline (T6.1.15): table fixtures are seeded into an
// in-memory Drift database, loaded by the stats data source, resolved in a batch job and computed by
// the registry, then compared with the canonical hand-computed expectations.
import 'package:flutter_test/flutter_test.dart';

import 'support/stats_harness.dart';

void main() {
  for (final name in const ['planner_two_weeks']) {
    test('fixture $name', () async {
      final fixture = StatsFixture.load(name);
      final h = await fixture.seed();
      addTearDown(h.dispose);
      final failures = await runFixture(fixture, h);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
}
