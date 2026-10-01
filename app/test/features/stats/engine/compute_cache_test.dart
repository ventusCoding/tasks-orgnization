// Isolate execution, caching & invalidation (T6.1.13).
import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, UpdateKind;

import 'package:everslot/features/stats/application/stats_cache.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_engine.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/data/stats_invalidation.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _habitRequest = StatsRequest(
  MetricScope.habits,
  selection: PeriodSelection(StatsPeriod.thisWeek()),
  metricIds: {'HB-X-01', 'HB-X-02'},
);

/// An executor whose jobs complete when the test says so.
class _GatedExecutor implements StatsExecutor {
  final jobs = <(StatsJob, Completer<Map<String, MetricResult>>)>[];

  @override
  Future<Map<String, MetricResult>> run(StatsJob job) {
    final c = Completer<Map<String, MetricResult>>();
    jobs.add((job, c));
    return c.future;
  }

  void complete(int index, double value) {
    final (job, c) = jobs[index];
    c.complete({for (final id in job.metricIds) id: MetricResult(id, value: Value<double>(value))});
  }
}

Map<String, Object?> habitRows() => {
  'habits': [
    {
      'id': 'h1',
      'kind': 'build',
      'name': 'Read',
      'sort_key': 'a',
      'start_date': '2026-09-01',
      'schedule': '{"v":1,"freq":"DAILY","interval":1}',
    },
  ],
};

void main() {
  group('LRU result cache', () {
    test('evicts the least recently used entry and counts hits', () {
      final cache = StatsResultCache(capacity: 2);
      MetricResult r(String id) => MetricResult(id, value: const Value<double>(1));
      cache
        ..put('a', r('a'))
        ..put('b', r('b'));
      expect(cache.get('a'), isNotNull); // a becomes most recent
      cache.put('c', r('c'));
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), isNotNull);
      expect(cache.get('c'), isNotNull);
      expect((cache.hits, cache.misses, cache.length), (3, 1, 2));
      cache.clear();
      expect(cache.length, 0);
    });

    test('keys include metric, scope, entity, period, compare mode, filters, extra and data version', () {
      const a = StatsRequest(MetricScope.habit, scopeId: 'h1', selection: PeriodSelection(StatsPeriod.thisWeek()));
      final keys = {
        statsCacheKey(a, 'HB-H-01', 'v1'),
        statsCacheKey(a, 'HB-H-02', 'v1'),
        statsCacheKey(a, 'HB-H-01', 'v2'),
        statsCacheKey(
          const StatsRequest(MetricScope.habit, scopeId: 'h2', selection: PeriodSelection(StatsPeriod.thisWeek())),
          'HB-H-01',
          'v1',
        ),
        statsCacheKey(
          const StatsRequest(
            MetricScope.habit,
            scopeId: 'h1',
            selection: PeriodSelection(StatsPeriod.thisWeek(), compare: false),
          ),
          'HB-H-01',
          'v1',
        ),
        statsCacheKey(
          const StatsRequest(
            MetricScope.habit,
            scopeId: 'h1',
            selection: PeriodSelection(StatsPeriod.thisWeek()),
            filters: StatsFilters(categoryIds: {'c1'}),
          ),
          'HB-H-01',
          'v1',
        ),
      };
      expect(keys, hasLength(6));
    });
  });

  group('compute service', () {
    test('a second batch with the same data version is served from the cache', () async {
      final h = StatsHarness.create();
      addTearDown(h.dispose);
      await h.seedTables(habitRows());
      await h.settle();
      final service = h.read(statsComputeServiceProvider);
      final first = await service.computeBatch(_habitRequest, dataVersion: 'v1');
      expect(first.fromCache, 0);
      final watch = Stopwatch()..start();
      final again = await service.computeBatch(_habitRequest, dataVersion: 'v1');
      watch.stop();
      expect(again.fromCache, 2);
      expect(watch.elapsedMilliseconds, lessThan(50));
      expect(again['HB-X-01'], same(first['HB-X-01']));
      final bumped = await service.computeBatch(_habitRequest, dataVersion: 'v2');
      expect(bumped.fromCache, 0);
    });

    test('unknown metric ids are ignored; null ids compute the whole scope', () {
      final h = StatsHarness.create();
      addTearDown(h.dispose);
      final service = h.read(statsComputeServiceProvider);
      expect(
        service.metricIdsOf(
          const StatsRequest(
            MetricScope.quit,
            selection: PeriodSelection(StatsPeriod.thisWeek()),
            metricIds: {'QT-01', 'XX-99'},
          ),
        ),
        ['QT-01'],
      );
      expect(
        service
            .metricIdsOf(const StatsRequest(MetricScope.quit, selection: PeriodSelection(StatsPeriod.thisWeek())))
            .length,
        greaterThan(10),
      );
    });

    test('jobs are sendable and compute in a background isolate', () async {
      final h = StatsHarness.create(zone: 'Europe/Paris');
      addTearDown(h.dispose);
      await h.seedTables(habitRows());
      await h.settle();
      final service = h.read(statsComputeServiceProvider);
      final job = await service.buildJob(
        const StatsRequest(MetricScope.habit, scopeId: 'h1', selection: PeriodSelection(StatsPeriod.thisMonth())),
        const ['HB-H-01', 'HB-H-02', 'HB-H-05'],
      );
      expect(job.env.zones.keys, contains('Europe/Paris'));
      final inIsolate = await const IsolateStatsExecutor().run(job);
      final inline = computeStatsJob(job);
      expect(inIsolate.keys, unorderedEquals(inline.keys));
      for (final id in inline.keys) {
        expect(inIsolate[id]!.value, inline[id]!.value, reason: id);
      }
    });
  });

  group('invalidation', () {
    test('a habit log bumps only the habits domain, debounced into one event', () async {
      final h = StatsHarness.create();
      addTearDown(h.dispose);
      final events = <Set<StatsDomain>>[];
      final sub = watchStatsDomains(h.db, debounce: const Duration(milliseconds: 20)).listen(events.add);
      addTearDown(sub.cancel);
      await h.seedTables(habitRows()..remove('habits'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      events.clear();
      for (var i = 0; i < 3; i++) {
        await h.db.customStatement(
          'INSERT INTO habit_logs (id, user_id, created_at, updated_at, habit_id, kind, logged_at, local_date) '
          "VALUES ('l$i', 'user-1', '2026-09-22', '2026-09-22', 'h1', 'done', '2026-09-22T08:00:00.000Z', '2026-09-22')",
        );
        h.db.notifyUpdates({TableUpdate.onTable(h.db.habitLogs, kind: UpdateKind.insert)});
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(events, [
        {StatsDomain.habits},
      ]);
    });

    test('data version keys only move with the scope domains and settings', () {
      final now = DateTime.utc(2026, 9, 22, 9);
      final base = {for (final d in StatsDomain.values) d: 0};
      final habitsBumped = {...base, StatsDomain.habits: 1};
      expect(dataVersionKey(habitsBumped, MetricScope.planner, now), dataVersionKey(base, MetricScope.planner, now));
      expect(dataVersionKey(habitsBumped, MetricScope.habit, now), isNot(dataVersionKey(base, MetricScope.habit, now)));
      expect(
        dataVersionKey(habitsBumped, MetricScope.global, now),
        isNot(dataVersionKey(base, MetricScope.global, now)),
      );
      final settings = {...base, StatsDomain.settings: 1};
      expect(dataVersionKey(settings, MetricScope.planner, now), isNot(dataVersionKey(base, MetricScope.planner, now)));
      // A 5-minute time bucket expires time-dependent results.
      expect(
        dataVersionKey(base, MetricScope.quit, now.add(const Duration(minutes: 5))),
        isNot(dataVersionKey(base, MetricScope.quit, now)),
      );
    });

    test('the batch provider recomputes after a habits write and drops the stale result', () async {
      final gate = _GatedExecutor();
      final h = StatsHarness.create(executor: gate);
      addTearDown(h.dispose);
      await h.settle();
      final values = <double?>[];
      final sub = h.container.listen(
        metricsBatchProvider(_habitRequest),
        (_, next) => values.add(next.value?['HB-X-01']?.value.valueOrNull),
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(gate.jobs, hasLength(1));
      await h.seedTables(habitRows());
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await pumpEventQueue();
      expect(gate.jobs, hasLength(2));
      gate
        ..complete(1, 2)
        ..complete(0, 1);
      await pumpEventQueue();
      expect(h.container.read(metricsBatchProvider(_habitRequest)).value?['HB-X-01']?.value.valueOrNull, 2);
      expect(values.whereType<double>(), [2]);
    });
  });
}
