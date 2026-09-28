// Screens rendered by the screen goldens (each section adds its cases).
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../planner/planner_scenario.dart';
import '../planner/planner_series_test.dart' show splitSeries;
import '../support/stats_harness.dart';

class ScreenCase {
  const ScreenCase(this.name, this.harness, this.build, {this.height = 2000});

  final String name;
  final Future<StatsHarness> Function() harness;
  final Widget Function() build;
  final double height;
}

Future<StatsHarness> _seeded(Map<String, Object?> tables, DateTime now) async {
  final h = StatsHarness.create(now: now);
  await h.seedTables(tables);
  return h;
}

final screenCases = <ScreenCase>[
  ScreenCase(
    'task',
    () => _seeded(plannerScenario(), DateTime.utc(2026, 9, 23, 12)),
    () => const ScopeStatsScreen(scope: 'task', scopeId: 'a'),
    height: 1200,
  ),
  ScreenCase(
    'series',
    () => _seeded(splitSeries(), DateTime.utc(2026, 9, 23, 12)),
    () => const ScopeStatsScreen(scope: 'series', scopeId: 'run', query: {'period': 'custom:2026-09-14..2026-09-23'}),
    height: 2600,
  ),
  ScreenCase(
    'planner',
    () => StatsFixture.load('planner_two_weeks').seed(),
    () => const ScopeStatsScreen(scope: 'planner', query: {'period': 'custom:2026-09-14..2026-09-20'}),
    height: 3600,
  ),
];
