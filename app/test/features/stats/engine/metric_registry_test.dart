// Metric registry & definition format (T6.1.06) and minimum-data rules (T6.1.14).
import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/metric_registry.dart';
import 'package:everslot/features/stats/application/stats_engine.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

MetricDefinition fake(String id, {MetricResult Function(Object c)? compute, MinSampleRule? minSample}) =>
    MetricDefinition(
      id: id,
      scope: MetricScope.planner,
      unit: StatUnit.percent,
      chart: ChartKind.kpi,
      isRate: true,
      minSample: minSample,
      compute: compute ?? (c) => MetricResult(id, value: const Value<double>(0.5, sampleSize: 2)),
    );

Map<String, Object?> arb(String locale) =>
    jsonDecode(File('lib/l10n/parts/stats_$locale.arb').readAsStringSync()) as Map<String, Object?>;

void main() {
  final registry = MetricRegistry.instance;

  group('registry (T6.1.06)', () {
    test('duplicate ids fail at construction', () {
      expect(
        () => MetricRegistry([fake('PL-X-01'), fake('PL-X-02'), fake('PL-X-01')]),
        throwsA(isA<DuplicateMetricException>().having((e) => e.ids, 'ids', ['PL-X-01'])),
      );
      expect(MetricRegistry.validate, returnsNormally);
    });

    test('lookups by id and scope', () {
      expect(registry.byId('PL-S-03')?.scope, MetricScope.series);
      expect(registry.byId('nope'), isNull);
      expect(registry.contains('HB-H-01'), isTrue);
      for (final scope in MetricScope.values) {
        expect(registry.byScope(scope), isNotEmpty, reason: '$scope has no metrics');
        expect(registry.byScope(scope).every((d) => d.scope == scope), isTrue);
      }
      expect(registry.all.length, registry.all.map((d) => d.id).toSet().length);
    });

    test('ids follow the catalog scheme and derive their l10n keys', () {
      final pattern = RegExp(r'^(PL-(T|S|X)|CL-(I|L|X)|HB-(H|X)|QT|GL)-\d{2}$');
      for (final d in registry.all) {
        expect(pattern.hasMatch(d.id), isTrue, reason: d.id);
      }
      expect(metricKeyStem('PL-X-01'), 'PlX01');
      expect(registry.byId('QT-11')!.titleKey, 'statsMetricQt11Title');
      expect(registry.byId('CL-I-02')!.formulaKey, 'statsMetricClI02Formula');
    });

    test('every definition has EN/FR/AR title, description and formula keys', () {
      final locales = {
        for (final l in ['en', 'fr', 'ar']) l: arb(l),
      };
      for (final d in registry.all) {
        for (final key in [d.titleKey, d.descriptionKey, d.formulaKey]) {
          for (final e in locales.entries) {
            expect(e.value[key], isA<String>(), reason: '$key missing in ${e.key}');
          }
        }
      }
    });

    test('every layout references registered metrics of its scope', () {
      for (final scope in MetricScope.values) {
        final layout = defaultLayoutOf(scope);
        expect(layout.scope, scope);
        for (final id in layout.metricIds) {
          expect(registry.byId(id)?.scope, scope, reason: '$scope layout: $id');
        }
      }
      expect(reviewLayout.metricIds, {'GL-03', 'GL-04'});
    });
  });

  group('minimum-data rules (T6.1.14)', () {
    test('every metric declares or inherits a guard; rates need a rule or an explicit opt-out', () {
      for (final d in registry.all) {
        expect(d.minDataGuard, isNotNull, reason: '${d.id} has no minimum-data policy');
        if (d.minDataGuard == MinDataGuard.rule) expect(d.minSample, isNotNull);
      }
      expect(fake('PL-X-99').minDataGuard, isNull);
      expect(fake('PL-X-99', minSample: MinDataRules.rate).minDataGuard, MinDataGuard.rule);
    });

    test('a value below the threshold becomes Insufficient with the right counts', () {
      final def = fake('PL-X-99', minSample: MinDataRules.rate);
      final r = applyMinimumData(def, def.compute(Object()));
      expect(r.value, const Insufficient<double>(3, 2));
      expect((r.value as Insufficient<double>).missing, 1);
      expect(r.comparison, isNull);
      final ok = applyMinimumData(def, const MetricResult('PL-X-99', value: Value<double>(0.4, sampleSize: 12)));
      expect(ok.value.valueOrNull, 0.4);
      expect(MinDataRules.rate.showsInterval(12), isTrue);
      expect(MinDataRules.rate.showsInterval(20), isFalse);
      expect(MinDataRules.rate.showsInterval(2), isFalse);
    });

    test('percentile and mean rules', () {
      expect(MinDataRules.meanOrMedian.apply(const Value<double>(1, sampleSize: 2)), isA<Insufficient<double>>());
      expect(MinDataRules.p85.apply(const Value<double>(1, sampleSize: 9)), const Insufficient<double>(10, 9));
      expect(MinDataRules.p95.apply(const Value<double>(1, sampleSize: 20)), isA<Value<double>>());
      // Explicit haveN wins over the value's sample size.
      expect(
        MinDataRules.trend.apply(const Value<double>(1, sampleSize: 50), haveN: 5),
        const Insufficient<double>(6, 5),
      );
      // Failures pass through untouched.
      expect(
        MinDataRules.rate.apply(const NotApplicable<double>('zeroDenominator')),
        const NotApplicable<double>('zeroDenominator'),
      );
    });

    test('a throwing metric yields an error card, the others still compute', () {
      final reg = MetricRegistry([fake('PL-X-97', compute: (_) => throw StateError('boom')), fake('PL-X-98')]);
      final job = StatsJob(
        request: const StatsRequest(MetricScope.planner, selection: PeriodSelection(StatsPeriod.thisWeek())),
        env: StatsEnvironment(now: DateTime.utc(2026, 9, 23), zoneId: 'UTC', zones: const {}),
        metricIds: const ['PL-X-97', 'PL-X-98', 'PL-X-00'],
      );
      final results = computeStatsJob(job, registry: reg);
      expect(results.keys, unorderedEquals(['PL-X-97', 'PL-X-98']));
      expect(results['PL-X-97']!.note, 'error');
      expect(results['PL-X-98']!.value.valueOrNull, 0.5);
    });
  });

  group('every metric computes from its declared inputs', () {
    for (final scope in MetricScope.values) {
      test('$scope on an empty database', () async {
        final h = StatsHarness.create();
        addTearDown(h.dispose);
        final results = await h.compute(scope, scopeId: scope.needsId ? 'missing' : null);
        expect(results.keys.toSet(), {for (final d in registry.byScope(scope)) d.id});
        final errors = [
          for (final r in results.values)
            if (r.note == 'error') '${r.metricId}: ${r.args['error']}',
        ];
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  });
}
