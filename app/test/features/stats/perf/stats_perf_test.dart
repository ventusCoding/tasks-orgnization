// Stats performance suite (T6.1.23): synthetic large datasets and timing assertions against arch §9.6.
//
//   - habit stats, 30 habits × 5 years of logs: first paint < 300 ms, cached < 50 ms
//   - Planner Insights for one year (2 000 tasks, 3 years): < 400 ms
//   - a one-year checklist Insights screen (5 000-item list, ~100 k status events in the DB): < 250 ms
//
// Default run (`flutter test`): a 4 % "smoke" scale that exercises every dataset, loader and metric on the
// real isolate pipeline and fails only on errors or a catastrophic (> 5 s) run.
// Reference run: `STATS_PERF=full flutter test test/features/stats/perf` seeds the full arch §9.6 sizes,
// checks the budgets and records every miss in `overBudget` (`STATS_PERF_STRICT=1` makes a miss fail,
// `STATS_PERF_SLACK=1.5` loosens the budgets). The budgets are device numbers (profile/release AOT on the
// reference phone); `flutter test` runs JIT with asserts on a desktop, so the hard CI gate is the
// regression check: every run writes `build/perf/stats_perf.json` (uploaded as the CI artifact) and,
// with `STATS_PERF_BASELINE=<previous stats_perf.json>`, a scenario that got more than 10 % slower fails.
@Timeout(Duration(minutes: 15))
library;

import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';
import 'perf_datasets.dart';

final _full = Platform.environment['STATS_PERF'] == 'full';
final _scale = _full ? 1.0 : 0.04;
final _slack = double.tryParse(Platform.environment['STATS_PERF_SLACK'] ?? '') ?? 1.0;
final _strict = Platform.environment['STATS_PERF_STRICT'] == '1';
final _now = DateTime.utc(2026, 9, 30, 9);

/// Timings of one scenario (milliseconds).
class Sample {
  Sample({
    required this.name,
    required this.coldMs,
    required this.loadMs,
    required this.computeMs,
    required this.cachedMs,
    required this.metrics,
    required this.rssDeltaMb,
  });

  final String name;

  /// Median of the cold runs (empty cache): loaders + isolate job + metrics.
  final double coldMs;
  final double loadMs;
  final double computeMs;

  /// A repeated request with the same data version: cache hits only.
  final double cachedMs;
  final int metrics;
  final double rssDeltaMb;

  Map<String, Object?> toJson() => {
    'coldMs': coldMs,
    'loadMs': loadMs,
    'computeMs': computeMs,
    'cachedMs': cachedMs,
    'metrics': metrics,
    'rssDeltaMb': rssDeltaMb,
  };
}

double _median(List<int> micros) {
  final sorted = [...micros]..sort();
  return sorted[sorted.length ~/ 2] / 1000;
}

final _samples = <String, Sample>{};
final _datasets = <String, Object?>{};
final _overBudget = <String>[];

Future<Sample> measure(StatsHarness h, String name, StatsRequest request, {int runs = 3}) async {
  final service = h.read(statsComputeServiceProvider);
  final cache = h.read(statsCacheProvider);
  final ids = service.metricIdsOf(request);
  expect(ids, isNotEmpty, reason: '$name: no metrics registered for the request');
  final rssBefore = ProcessInfo.currentRss;
  final load = <int>[];
  final compute = <int>[];
  final total = <int>[];
  var results = const <String, MetricResult>{};
  for (var i = 0; i < runs; i++) {
    cache.clear();
    final all = Stopwatch()..start();
    final loading = Stopwatch()..start();
    final job = await service.buildJob(request, ids);
    load.add(loading.elapsedMicroseconds);
    final computing = Stopwatch()..start();
    results = await service.executor.run(job);
    compute.add(computing.elapsedMicroseconds);
    total.add(all.elapsedMicroseconds);
  }
  final rssDelta = (ProcessInfo.currentRss - rssBefore) / (1024 * 1024);
  // The same request again with a fixed data version: the second call is served from the cache.
  cache.clear();
  await service.computeBatch(request, dataVersion: 'perf');
  final cachedWatch = Stopwatch()..start();
  final cached = await service.computeBatch(request, dataVersion: 'perf');
  final cachedMs = cachedWatch.elapsedMicroseconds / 1000;
  expect(cached.fromCache, ids.length, reason: '$name: the repeat must be served from the cache');
  final errors = [
    for (final r in results.values)
      if (r.note == 'error') '${r.metricId}: ${r.args['error']}',
  ];
  expect(errors, isEmpty, reason: '$name: metrics failed on the large dataset');
  expect(results, hasLength(ids.length));
  final sample = Sample(
    name: name,
    coldMs: _median(total),
    loadMs: _median(load),
    computeMs: _median(compute),
    cachedMs: cachedMs,
    metrics: ids.length,
    rssDeltaMb: rssDelta,
  );
  _samples[name] = sample;
  return sample;
}

/// The metrics a screen requests (its layout, KPIs included).
StatsRequest screen(MetricScope scope, StatsLayout layout, StatsPeriod period, {String? scopeId}) => StatsRequest(
  scope,
  scopeId: scopeId,
  selection: PeriodSelection(period, compare: true),
  metricIds: layout.metricIds,
);

/// Budgets apply at full scale (recorded, failing only in strict mode); the smoke scale just guards
/// against catastrophes.
void expectBudget(String what, double ms, double budgetMs) {
  if (!_full) {
    expect(ms, lessThan(5000), reason: '$what took ${ms.toStringAsFixed(0)} ms');
    return;
  }
  final limit = budgetMs * _slack;
  if (ms < limit) return;
  final miss = '$what took ${ms.toStringAsFixed(0)} ms (budget ${limit.toStringAsFixed(0)} ms)';
  _overBudget.add(miss);
  if (_strict) fail(miss);
}

void main() {
  late StatsHarness h;

  setUpAll(() async {
    h = StatsHarness.create(now: _now, zone: perfZone, executor: const IsolateStatsExecutor());
    await h.settle();
    final clock = Stopwatch()..start();
    _datasets['habits'] = await seedHabitPerf(h.db, now: _now, scale: _scale);
    _datasets['planner'] = await seedPlannerPerf(h.db, now: _now, scale: _scale);
    _datasets['checklists'] = await seedChecklistPerf(h.db, now: _now, scale: _scale);
    _datasets['seedMs'] = clock.elapsedMilliseconds;
    // Warm the JIT and the isolate machinery once on a small request so the first scenario is not
    // charged for compiling the engine (release builds are AOT).
    await h
        .read(statsComputeServiceProvider)
        .computeBatch(
          screen(MetricScope.habit, habitLayout, const StatsPeriod.thisMonth(), scopeId: 'h0'),
          dataVersion: 'warm',
        );
  });

  tearDownAll(() async {
    final report = {
      'scale': _scale,
      'mode': _full ? 'full' : 'smoke',
      'slack': _slack,
      'now': _now.toIso8601String(),
      'datasets': _datasets,
      'overBudget': _overBudget,
      'scenarios': {for (final e in _samples.entries) e.key: e.value.toJson()},
    };
    final file = File('build/perf/stats_perf.json')..createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    // ignore: avoid_print
    print(
      'stats perf (${report['mode']}) → ${file.path}\n${const JsonEncoder.withIndent('  ').convert(report['scenarios'])}',
    );
    await h.dispose();
  });

  test('datasets have the arch §9.6 shape', () {
    final habits = _datasets['habits']! as Map;
    final planner = _datasets['planner']! as Map;
    final lists = _datasets['checklists']! as Map;
    if (_full) {
      expect(habits['habits'], 30);
      // ~55 k planned check-ins; the generator leaves realistic gaps (missed and skipped days).
      expect(habits['habit_logs'] as int, greaterThan(40000));
      expect(planner['tasks'], 2000);
      expect(planner['task_occurrences'] as int, greaterThan(40000));
      expect(lists['checklists'], 50);
      expect(lists['activity_events'] as int, greaterThan(80000));
      expect(checklistSizes(1).first, 5000);
    } else {
      expect(habits['habit_logs'] as int, greaterThan(100));
      expect(planner['tasks'] as int, greaterThan(50));
      expect(lists['checklist_items'] as int, greaterThan(300));
    }
  });

  test('habit stats: 30 habits × 5 years — first paint and cached', () async {
    final section = await measure(
      h,
      'habitsSection',
      screen(MetricScope.habits, habitsLayout, const StatsPeriod.thisWeek()),
    );
    expectBudget('habits section first paint', section.coldMs, 300);
    expectBudget('habits section cached', section.cachedMs, 50);
    // Neighbouring screens on the same data (recorded, budgeted like the section screen).
    final allTime = await measure(
      h,
      'habitsSectionAllTime',
      screen(MetricScope.habits, habitsLayout, const StatsPeriod.allTime()),
    );
    expectBudget('habits section (all time) first paint', allTime.coldMs, 300);
    final one = await measure(
      h,
      'habitDetail',
      screen(MetricScope.habit, habitLayout, const StatsPeriod.thisMonth(), scopeId: 'h0'),
    );
    expectBudget('habit detail first paint', one.coldMs, 300);
    expectBudget('habit detail cached', one.cachedMs, 50);
  });

  test('Planner Insights for one year (2 000 tasks, 3 years of occurrences)', () async {
    final year = await measure(
      h,
      'plannerYear',
      screen(MetricScope.planner, plannerLayout, const StatsPeriod.thisYear()),
    );
    expectBudget('Planner Insights (year)', year.coldMs, 400);
    expectBudget('Planner Insights (year) cached', year.cachedMs, 50);
    final month = await measure(
      h,
      'plannerMonth',
      screen(MetricScope.planner, plannerLayout, const StatsPeriod.thisMonth()),
    );
    expectBudget('Planner Insights (month)', month.coldMs, 400);
  });

  test('checklist Insights for one year (5 000-item list, ~100 k status events in the database)', () async {
    final year = await measure(
      h,
      'checklistYear',
      screen(MetricScope.checklist, checklistLayout, const StatsPeriod.rolling(365), scopeId: 'L0'),
    );
    expectBudget('checklist Insights (one year)', year.coldMs, 250);
    expectBudget('checklist Insights (one year) cached', year.cachedMs, 50);
    // The Lists section reads every list (recorded; budgeted like a section screen).
    final section = await measure(
      h,
      'checklistsSectionYear',
      screen(MetricScope.checklists, checklistsLayout, const StatsPeriod.thisYear()),
    );
    expectBudget('Lists Insights (year)', section.coldMs, 1000);
  });

  test('scenarios do not regress more than 10 % against the previous run', () {
    final path = Platform.environment['STATS_PERF_BASELINE'];
    if (path == null || !File(path).existsSync()) {
      // No baseline supplied (local run): nothing to compare, the budgets above still apply.
      expect(_samples, isNotEmpty);
      return;
    }
    final baseline = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    if (baseline['mode'] != (_full ? 'full' : 'smoke')) return; // different scale: not comparable
    final previous = baseline['scenarios']! as Map<String, Object?>;
    final regressions = <String>[];
    for (final e in _samples.entries) {
      final before = (previous[e.key] as Map<String, Object?>?)?['coldMs'] as num?;
      if (before == null) continue;
      // 10 % plus a 10 ms noise floor for very fast scenarios.
      if (e.value.coldMs > before * 1.10 + 10) {
        regressions.add('${e.key}: ${e.value.coldMs.toStringAsFixed(0)} ms vs ${before.toStringAsFixed(0)} ms');
      }
    }
    expect(regressions, isEmpty, reason: regressions.join('\n'));
  });
}
