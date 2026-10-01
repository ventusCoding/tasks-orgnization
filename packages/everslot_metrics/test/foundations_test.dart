import 'dart:math' as math;

import 'package:everslot_metrics/src/circular.dart';
import 'package:everslot_metrics/src/correlation.dart';
import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/forecast.dart';
import 'package:everslot_metrics/src/group_tests.dart';
import 'package:everslot_metrics/src/min_data.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/special_functions.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/survival.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:test/test.dart';

import 'support/support.dart';

List<num> nums(Object? list) => (list! as List).cast<num>();

void main() {
  group('Stat helpers (T6.1.01)', () {
    test('map, flatMap, fold, combine, valueOr, equality', () {
      const v = Value<double>(2, sampleSize: 4);
      expect(v.map((x) => x * 2), const Value<double>(4, sampleSize: 4));
      expect(v.flatMap((x) => Value<int>(x.toInt())), const Value<int>(2));
      expect(v.fold(value: (_) => 'v', insufficient: (_) => 'i', notApplicable: (_) => 'n'), 'v');
      const i = Insufficient<double>(10, 3);
      expect(i.missing, 7);
      expect(i.map((x) => x + 1), const Insufficient<double>(10, 3));
      expect(i.flatMap((x) => Value<int>(x.toInt())), const Insufficient<int>(10, 3));
      expect(i.fold(value: (_) => 'v', insufficient: (_) => 'i', notApplicable: (_) => 'n'), 'i');
      expect(const Insufficient<double>(1, 5).missing, 0);
      const n = NotApplicable<double>(Reasons.zeroDenominator);
      expect(n.map((x) => x), const NotApplicable<double>(Reasons.zeroDenominator));
      expect(n.flatMap((x) => Value<int>(x.toInt())), const NotApplicable<int>(Reasons.zeroDenominator));
      expect(n.fold(value: (_) => 'v', insufficient: (_) => 'i', notApplicable: (_) => 'n'), 'n');
      expect(n.valueOr(-1), -1);
      expect(n.valueOrNull, isNull);
      expect(v.hasValue, isTrue);
      expect(Stat.combine(v, const Value<int>(3), (a, b) => a * b), const Value<double>(6));
      expect(Stat.combine(v, i, (a, b) => a + b), const Insufficient<double>(10, 3));
      expect(Stat.combine(v, n, (a, b) => a + b), n);
      expect(Stat.combine(i, v, (a, b) => a + b), i);
      expect(Stat.combine(n, v, (a, b) => a + b), n);
      expect(Stat.ofDouble(double.nan), const NotApplicable<double>(Reasons.nonFinite));
      expect(Stat.ofDouble(double.infinity), const NotApplicable<double>(Reasons.nonFinite));
      expect(v.toString(), contains('n=4'));
      expect(i.toString(), contains('3/10'));
      expect(n.toString(), contains('zeroDenominator'));
      final copies = [
        Value<double>(2, sampleSize: v.sampleSize),
        Insufficient<double>(i.requiredN, i.haveN),
        NotApplicable<double>(n.reasonKey),
      ];
      expect({v, i, n, ...copies}.length, 3);
      const ci = ConfidenceInterval(0.1, 0.4);
      expect(ci.width, near(0.3));
      expect(ci.contains(0.2), isTrue);
      expect(ci.excludesZero, isTrue);
      expect(const ConfidenceInterval(-0.1, 0.2).excludesZero, isFalse);
      expect(ci.toString(), contains('0.95'));
      expect({ci, ConfidenceInterval(ci.lower, ci.upper)}.length, 1);
    });

    test('safe division never returns NaN', () {
      expect(safeDivide(1, 0), const NotApplicable<double>(Reasons.zeroDenominator));
      expect(safeDivide(0, 0), const NotApplicable<double>(Reasons.zeroDenominator));
      expect(safeDivide(3, 4, sampleSize: 4), const Value<double>(0.75, sampleSize: 4));
    });

    test('MetricValue.fromStat flattens values, durations and failures', () {
      final m = MetricValue.fromStat(
        'HB-H-05',
        const Value<double>(0.5, sampleSize: 10, interval: ConfidenceInterval(0.2, 0.8)),
        unit: MetricUnit.percent,
      );
      expect(m.value, 0.5);
      expect(m.sampleSize, 10);
      expect(m.interval, const ConfidenceInterval(0.2, 0.8));
      expect(m.hasValue, isTrue);
      final dur = MetricValue.fromStat(
        'PL-T-02',
        const Value<Duration>(Duration(minutes: 90)),
        unit: MetricUnit.duration,
      );
      expect(dur.value, 90);
      final other = MetricValue.fromStat('x', const Value<String>('a'), unit: MetricUnit.count);
      expect(other.value, isNull);
      final ins = MetricValue.fromStat('x', const Insufficient<double>(3, 1), unit: MetricUnit.percent);
      expect(ins.insufficient, isTrue);
      expect(ins.requiredN, 3);
      expect(ins.haveN, 1);
      final na = MetricValue.fromStat(
        'x',
        const NotApplicable<double>(Reasons.isNew),
        unit: MetricUnit.percent,
        estimate: true,
      );
      expect(na.notApplicable, isTrue);
      expect(na.reasonKey, Reasons.isNew);
      expect(na.estimate, isTrue);
    });
  });

  group('descriptive statistics vs NumPy/SciPy (T6.1.02, descriptive.json)', () {
    final fx = loadFixture('descriptive');
    final datasets = (fx['datasets']! as Map).cast<String, Map<String, Object?>>();
    for (final name in datasets.keys) {
      test(name, () {
        final e = datasets[name]!;
        final xs = nums(e['values']);
        const tol = 1e-9;
        expect(mean(xs).valueOrNull, near(e['mean']! as num, tol));
        expect(median(xs).valueOrNull, near(e['median']! as num, tol));
        final pct = (e['percentiles']! as Map).cast<String, num>();
        expect(p50(xs).valueOrNull, near(pct['50']!, tol));
        expect(p70(xs).valueOrNull, near(pct['70']!, tol));
        expect(p80(xs).valueOrNull, near(pct['80']!, tol));
        expect(p85(xs).valueOrNull, near(pct['85']!, tol));
        expect(p90(xs).valueOrNull, near(pct['90']!, tol));
        expect(p95(xs).valueOrNull, near(pct['95']!, tol));
        expect(percentile(xs, 85).valueOrNull, near(pct['85']!, tol));
        expect(variance(xs, sample: false).valueOrNull, near(e['populationVariance']! as num, tol));
        expect(standardDeviation(xs, sample: false).valueOrNull, near(e['populationSd']! as num, tol));
        if (e.containsKey('sampleVariance')) {
          expect(variance(xs).valueOrNull, near(e['sampleVariance']! as num, tol));
          expect(standardDeviation(xs).valueOrNull, near(e['sampleSd']! as num, tol));
        } else {
          expect(variance(xs), isA<Insufficient<double>>());
        }
        if (e.containsKey('cv')) {
          expect(coefficientOfVariation(xs).valueOrNull, near(e['cv']! as num, tol));
        }
        expect(interquartileRange(xs).valueOrNull, near(e['iqr']! as num, tol));
        expect(medianAbsoluteDeviation(xs).valueOrNull, near(e['mad']! as num, tol));
        expect(trimmedMean(xs).valueOrNull, near(e['trimmedMean10']! as num, tol));
        expect(minimum(xs).valueOrNull, e['min']);
        expect(maximum(xs).valueOrNull, e['max']);
        expect(valueRange(xs).valueOrNull, near((e['max']! as num) - (e['min']! as num), tol));
        expect(mode(xs).valueOrNull, e['mode']);
        if (e.containsKey('geometricMean')) {
          expect(geometricMean(xs).valueOrNull, near(e['geometricMean']! as num, 1e-9));
        } else {
          expect(geometricMean(xs), const NotApplicable<double>(Reasons.nonPositive));
        }
        final box = boxPlot(xs).valueOrNull!;
        final eb = e['box']! as Map<String, Object?>;
        expect(box.q1, near(eb['q1']! as num, tol));
        expect(box.q3, near(eb['q3']! as num, tol));
        expect(box.median, near(eb['median']! as num, tol));
        expect(box.whiskerLow, eb['whiskerLow']);
        expect(box.whiskerHigh, eb['whiskerHigh']);
        expect(box.outliers, eb['outliers']);
        expect(box.iqr, near(e['iqr']! as num, tol));
        if (e.containsKey('fdHistogram')) {
          final h = histogramFreedmanDiaconis(xs);
          final eh = e['fdHistogram']! as Map<String, Object?>;
          expect(h.edges.length, (eh['edges']! as List).length);
          for (var k = 0; k < h.edges.length; k++) {
            expect(h.edges[k], near(nums(eh['edges'])[k], 1e-9));
          }
          expect(h.bins.map((b) => b.count), eh['counts']);
        } else {
          final h = histogramFreedmanDiaconis(xs);
          expect(h.bins.single.count, xs.length);
        }
        final fixed = histogramFixedWidth(xs, 5);
        final ef = e['fixedWidth5']! as Map<String, Object?>;
        expect(fixed.edges, [for (final v in nums(ef['edges'])) near(v, 1e-9)]);
        expect(fixed.bins.map((b) => b.count), ef['counts']);
        final summary = describe(xs).valueOrNull!;
        expect(summary.mean, near(e['mean']! as num, tol));
        expect(summary.sampleSd, e.containsKey('sampleSd') ? near(e['sampleSd']! as num, tol) : isNull);
      });
    }

    test('empty input, zero mean, histograms with explicit edges, log ratios', () {
      expect(mean(const []), const Insufficient<double>(1, 0, Reasons.empty));
      expect(median(const []), isA<Insufficient<double>>());
      expect(mode(const []), isA<Insufficient<double>>());
      expect(minimum(const []), isA<Insufficient<double>>());
      expect(maximum(const []), isA<Insufficient<double>>());
      expect(valueRange(const []), isA<Insufficient<double>>());
      expect(interquartileRange(const []), isA<Insufficient<double>>());
      expect(medianAbsoluteDeviation(const []), isA<Insufficient<double>>());
      expect(trimmedMean(const []), isA<Insufficient<double>>());
      expect(trimmedMean(const [1, 2], proportion: 0.5), isA<Insufficient<double>>());
      expect(geometricMean(const []), isA<Insufficient<double>>());
      expect(boxPlot(const []), isA<Insufficient<BoxPlotSummary>>());
      expect(describe(const []), isA<Insufficient<DescriptiveSummary>>());
      expect(coefficientOfVariation(const [-1, 1]), const NotApplicable<double>(Reasons.zeroMean));
      expect(coefficientOfVariation(const [1]), isA<Insufficient<double>>());
      expect(() => quantile(const [1], 1.5), throwsArgumentError);
      expect(sum(const []), 0);
      expect(medianAbsoluteDeviation(const [1, 2, 3, 4, 100], scale: 1.4826).valueOrNull, near(1.4826));
      final h = histogramWithEdges(const [0, 5, 10, 10, -1, 11], const [0, 5, 10]);
      expect(h.bins.map((b) => b.count), [1, 3]);
      expect(h.underflow, 1);
      expect(h.overflow, 1);
      expect(h.total, 4);
      expect(h.bins.first.width, 5);
      expect(h.bins.first.toString(), contains('[0.0, 5.0)'));
      expect(() => histogramWithEdges(const [1], const [0]), throwsArgumentError);
      expect(() => histogramWithEdges(const [1], const [0, 0]), throwsArgumentError);
      expect(() => histogramFixedWidth(const [1], 0), throwsArgumentError);
      expect(histogramFixedWidth(const [], 5).bins, isEmpty);
      expect(histogramFreedmanDiaconis(const []).bins, isEmpty);
      expect(histogramFreedmanDiaconis(const [1, 1, 1, 1, 9]).bins.length, 40);
      expect(const Histogram([]).edges, isEmpty);
      expect(medianLogRatio(const []), isA<Insufficient<double>>());
      expect(medianLogRatio(const [1, -1]), const NotApplicable<double>(Reasons.nonPositive));
      expect(estimationBias(const [1.21, 1.21]).valueOrNull, near(0.21));
      expect(outlierShare(const [1, 2]), 0);
      expect(outlierShare(const [1, 2, 2, 3, 2, 1, 100]), near(1 / 7));
      final w = Welford()..addAll(const [1, 2, 3]);
      expect(w.n, 3);
      expect(w.mean, 2);
      expect(w.sampleVariance.valueOrNull, 1);
      expect(Welford().populationVariance, isA<Insufficient<double>>());
    });
  });

  group('rates, Wilson intervals and deltas (T6.1.03)', () {
    test('rates and fractional denominators', () {
      expect(rate(0, 0), const NotApplicable<double>(Reasons.zeroDenominator));
      final r = rate(6, 7) as Value<double>;
      expect(r.value, near(6 / 7));
      expect(r.interval!.contains(6 / 7), isTrue);
      final prorated = rate(1, 1.714) as Value<double>;
      expect(prorated.sampleSize, 1.714);
      expect(prorated.interval, isNotNull);
      expect(wilsonInterval(1, 0), isNull);
      expect(weightedRate([(score: 1, weight: 2), (score: 0.5, weight: 2)]).valueOrNull, 0.75);
      expect(weightedRate(const []), isA<NotApplicable<double>>());
      expect(proRate(3, 4, 7), near(12 / 7));
      expect(proRate(3, 4, 0), 0);
    });

    test('deltas: absolute, relative ("new"), percentage points', () {
      expect(absoluteDelta(5, 3), 2);
      expect(relativeDelta(6, 4).valueOrNull, 0.5);
      expect(relativeDelta(6, -4).valueOrNull, 2.5);
      expect(relativeDelta(5, 0), const NotApplicable<double>(Reasons.isNew));
      expect(percentagePointDelta(0.82, 0.8), near(2));
      final rateCmp = compareWithPrevious(const Value(0.82), const Value(0.8), isRate: true);
      expect(rateCmp.delta.valueOrNull, near(2));
      expect(rateCmp.deltaPct, isA<NotApplicable<double>>());
      final sumCmp = compareWithPrevious(const Value(12), const Value(8));
      expect(sumCmp.delta.valueOrNull, 4);
      expect(sumCmp.deltaPct.valueOrNull, 0.5);
      final missing = compareWithPrevious(const Value(1), const Insufficient<double>(3, 1));
      expect(missing.delta, const NotApplicable<double>(Reasons.needsMoreData));
      final na = compareWithPrevious(const NotApplicable<double>('x'), const Value(1));
      expect(na.deltaPct, const NotApplicable<double>('x'));
    });

    test('minimum-data rules (T6.1.14)', () {
      expect(MinDataRules.rate.apply(rate(1, 2)), const Insufficient<double>(3, 2));
      expect(MinDataRules.rate.apply(rate(3, 5)).hasValue, isTrue);
      expect(MinDataRules.rate.showsInterval(5), isTrue);
      expect(MinDataRules.rate.showsInterval(25), isFalse);
      expect(MinDataRules.rate.showsInterval(2), isFalse);
      expect(MinDataRules.p85.showsInterval(12), isFalse);
      expect(MinDataRules.p85.apply(const Value<double>(1), haveN: 9), const Insufficient<double>(10, 9));
      expect(MinDataRules.p95.apply(const NotApplicable<double>('x')), const NotApplicable<double>('x'));
      expect(MinDataRules.meanOrMedian.apply(const Value<double>(1)), const Insufficient<double>(3, 0));
      expect(MinDataRules.kaplanMeierAttempts.hiddenBelow, 2);
      expect(MinDataRules.correlationPairs.hiddenBelow, 21);
      expect(MinDataRules.correlationPerGroup.hiddenBelow, 7);
      expect(MinDataRules.monteCarloDays.hiddenBelow, 30);
      expect(MinDataRules.monteCarloCompletions.hiddenBelow, 10);
      expect(MinDataRules.trend.hiddenBelow, 6);
      expect(MinDataRules.trendSignificance.hiddenBelow, 8);
      expect(MinDataRules.dayOfWeekWeeks.hiddenBelow, 4);
    });
  });

  group('special functions', () {
    test('normal, Student-t, χ², gamma, beta', () {
      expect(normalCdf(1.959963984540054), near(0.975, 1e-12));
      expect(normalCdf(-1), near(0.15865525393145707, 1e-12));
      expect(normalTwoSidedP(1.959963984540054), near(0.05, 1e-12));
      expect(erfc(-0.5), near(1.5204998778130465, 1e-12));
      expect(studentTTwoSidedP(2.228138851986274, 10), near(0.05, 1e-9));
      expect(studentTCdf(2.228138851986274, 10), near(0.975, 1e-9));
      expect(studentTCdf(-2.228138851986274, 10), near(0.025, 1e-9));
      expect(studentTTwoSidedP(double.infinity, 5), 0);
      expect(chiSquareUpperTail(3.841458820694124, 1), near(0.05, 1e-10));
      expect(chiSquareUpperTail(5.991464547107979, 2), near(0.05, 1e-10));
      expect(lnGamma(0.5), near(math.log(math.sqrt(math.pi)), 1e-12));
      expect(lnGamma(10), near(math.log(362880), 1e-10));
      expect(lnGamma(0.1), near(2.252712651734206, 1e-10));
      expect(regularizedGammaP(1, 0), 0);
      expect(regularizedGammaQ(1, 0), 1);
      expect(regularizedGammaP(1, 2), near(1 - math.exp(-2), 1e-12));
      expect(regularizedGammaQ(3, 1), near(0.9196986029286058, 1e-12));
      expect(regularizedIncompleteBeta(2, 3, 0), 0);
      expect(regularizedIncompleteBeta(2, 3, 1), 1);
      expect(regularizedIncompleteBeta(2, 3, 0.4), near(0.5248, 1e-12));
      expect(regularizedIncompleteBeta(2, 3, 0.9), near(0.9963, 1e-12));
    });
  });

  group('time series (T6.1.04)', () {
    test('bucketing honours the week start (MO / SA / SU) and fills gaps', () {
      final values = [(d('2026-09-19'), 1), (d('2026-09-20'), 2), (d('2026-09-21'), 4)];
      for (final (ws, expected) in [
        (Weekday.monday, [3.0, 4.0]),
        (Weekday.saturday, [7.0]),
        (Weekday.sunday, [1.0, 6.0]),
      ]) {
        final series = bucketSum(
          values,
          from: d('2026-09-19'),
          to: d('2026-09-21'),
          granularity: Granularity.week,
          weekStart: ws,
        );
        expect(series.map((p) => p.value), expected, reason: ws.code);
      }
      final daily = bucketSum(
        [(d('2026-09-01'), 1), (d('2026-09-03'), 2), (d('2026-10-01'), 9)],
        from: d('2026-09-01'),
        to: d('2026-09-03'),
        granularity: Granularity.day,
      );
      expect(daily.map((p) => p.value), [1, 0, 2]);
      final rates = bucketRate(
        [(d('2026-09-01'), 1, 2), (d('2026-09-03'), 0, 1), (d('2026-12-01'), 1, 1)],
        from: d('2026-09-01'),
        to: d('2026-09-03'),
        granularity: Granularity.day,
      );
      expect(rates.map((p) => p.value), [0.5, null, 0]);
      final means = bucketMean(
        [(d('2026-01-15'), 2), (d('2026-02-20'), 4), (d('2026-02-21'), 6)],
        from: d('2026-01-01'),
        to: d('2026-06-30'),
        granularity: Granularity.quarter,
      );
      expect(means.map((p) => p.value), [4, null]);
      expect(bucketStart(d('2026-11-15'), Granularity.year), d('2026-01-01'));
      expect(bucketStart(d('2026-11-15'), Granularity.month), d('2026-11-01'));
      expect(nextBucketStart(d('2026-01-01'), Granularity.year), d('2027-01-01'));
      expect(nextBucketStart(d('2026-01-01'), Granularity.quarter), d('2026-04-01'));
      expect(Granularity.month.nominalDays, near(30.4375));
      expect(Granularity.quarter.nominalDays, near(91.3125));
      expect(Granularity.year.nominalDays, 365.25);
      expect(Granularity.day.nominalDays, 1);
      expect(SeriesPoint(d('2026-01-01'), 1).toString(), contains('2026-01-01'));
      expect({SeriesPoint(d('2026-01-01'), 1), SeriesPoint(d('2026-01-01'), 1)}.length, 1);
    });

    test('rolling windows emit null below 50 % coverage; EWMA; cumulative', () {
      expect(rollingMean([1, 2, 3, null, null, null, null, 8], 4), [null, 1.5, 2.0, 2.0, 2.5, null, null, null]);
      expect(rollingSum([1, null, 3], 2), [1, 1, 3]);
      expect(rollingSum([null, null, 3], 4), [null, null, null]);
      expect(rollingRate([1, 0, 1], [1, 0, 2], 2), [1.0, 1.0, 0.5]);
      expect(() => rollingRate([1], [1, 2], 2), throwsArgumentError);
      expect(() => rollingRate([1], [1], 0), throwsArgumentError);
      expect(alphaFromHalfLife(1), 0.5);
      expect(() => alphaFromHalfLife(0), throwsArgumentError);
      expect(ewma([null, 1, null, 3], alpha: 0.5), [null, 1, 1, 2]);
      expect(ewma([2, 4], halfLife: 1, initial: 0), [1, 2.5]);
      expect(() => ewma([1]), throwsArgumentError);
      expect(cumulative([1, null, 2]), [1, 1, 3]);
    });

    test('daily series across the October DST change buckets by local date', () {
      final paris = tzClock('Europe/Paris');
      final bounds = DayBoundaries(paris);
      final instants = [
        at(paris, '2026-10-24T23:30'),
        at(paris, '2026-10-25T02:30'),
        at(paris, '2026-10-25T23:59'),
        at(paris, '2026-10-26T00:00'),
      ];
      final series = bucketSum(
        [for (final t in instants) (bounds.dateOf(t), 1)],
        from: d('2026-10-24'),
        to: d('2026-10-26'),
        granularity: Granularity.day,
      );
      expect(series.map((p) => p.value), [1, 2, 1]);
      expect(bounds.lengthOf(d('2026-10-25')), const Duration(hours: 25));
      expect(bounds.lengthOf(d('2026-03-29')), const Duration(hours: 23));
    });
  });

  group('trend (T6.1.04, reference_tests.json)', () {
    final ref = loadFixture('reference_tests')['trend']! as Map<String, Object?>;
    final xs = nums(ref['x']);
    final ys = nums(ref['y']);
    final withOutliers = nums(ref['yOutliers']);

    test('OLS matches SciPy linregress; y = 3x + noise is significant', () {
      final o = ols(xs, ys).valueOrNull!;
      final e = ref['ols']! as Map<String, Object?>;
      expect(o.slope, near(e['slope']! as num, 1e-9));
      expect(o.intercept, near(e['intercept']! as num, 1e-9));
      expect(o.standardError, near(e['se']! as num, 1e-9));
      expect(o.pValue, lessThan(0.001));
      expect(o.pValue, near(e['p']! as num, 1e-20));
      expect(o.rSquared, near(e['r2']! as num, 1e-9));
      expect(ols(const [1, 2], const [1, 2]), isA<Insufficient<OlsResult>>());
      expect(ols(const [1, 1, 1], const [1, 2, 3]), isA<NotApplicable<OlsResult>>());
      final perfect = ols(const [1, 2, 3, 4], const [2, 4, 6, 8]).valueOrNull!;
      expect(perfect.pValue, 0);
      expect(perfect.standardError, 0);
      final flat = ols(const [1, 2, 3, 4], const [5, 5, 5, 5]).valueOrNull!;
      expect(flat.pValue, 1);
      expect(flat.rSquared, 1);
      expect(() => ols(const [1], const [1, 2]), throwsArgumentError);
    });

    test('Theil–Sen ignores 10 % injected outliers', () {
      final ts = theilSen(xs, withOutliers).valueOrNull!;
      final e = ref['theilSenOutliers']! as Map<String, Object?>;
      expect(ts.slope, near(e['slope']! as num, 1e-9));
      expect((ts.slope - 3).abs(), lessThan(0.1));
      expect(theilSen(const [1], const [1]), isA<Insufficient<TheilSenResult>>());
      expect(theilSen(const [1, 1], const [1, 2]), isA<NotApplicable<TheilSenResult>>());
      expect(() => theilSen(const [1], const [1, 2]), throwsArgumentError);
      expect(() => theilSen(xs, ys, bootstrapIterations: 10), throwsArgumentError);
      final big = List<num>.generate(1200, (i) => i);
      final bigY = [for (final x in big) 2 * x + (x % 7)];
      final sub = theilSen(big, bigY, random: math.Random(1), sampledPairs: 20000).valueOrNull!;
      expect((sub.slope - 2).abs(), lessThan(0.05));
      expect(() => theilSen(big, bigY), throwsArgumentError);
    });

    test('trend flag: outliers select Theil–Sen, significance needs ≥ 8 buckets', () {
      final rising = trend(ys.map((v) => v.toDouble()).toList(), bucketDays: 1, random: math.Random(7)).valueOrNull!;
      expect(rising.method, TrendMethod.ols);
      expect(rising.direction, TrendDirection.rising);
      expect(rising.slopePerWeek, near(rising.slopePerBucket * 7));
      final robust = trend(
        withOutliers.map((v) => v.toDouble()).toList(),
        bucketDays: 7,
        random: math.Random(7),
      ).valueOrNull!;
      expect(robust.method, TrendMethod.theilSen);
      expect(robust.significant, isTrue);
      expect(robust.interval!.excludesZero, isTrue);
      final six = trend([1, 2, 3, 4, 5, 6.5], bucketDays: 7, random: math.Random(1)).valueOrNull!;
      expect(six.significant, isFalse, reason: 'a significance label needs 8 buckets');
      expect(six.direction, TrendDirection.stable);
      expect(trend([1, null, 2], bucketDays: 7, random: math.Random(1)), const Insufficient<TrendResult>(6, 2));
      final falling = trend(
        [10, 9, 8.5, 7, 6, 5.5, 4, 3],
        bucketDays: 7,
        random: math.Random(1),
        method: TrendMethod.theilSen,
      ).valueOrNull!;
      expect(falling.direction, TrendDirection.falling);
      final noisy = trend(
        [5, 5.1, 4.9, 5, 5.2, 4.8, 5, 5.1],
        bucketDays: 7,
        random: math.Random(1),
        method: TrendMethod.theilSen,
      ).valueOrNull!;
      expect(noisy.direction, TrendDirection.stable);
    });
  });

  group('period model (T6.1.05)', () {
    test('thisWeek for week starts MO, SA and SU', () {
      final today = d('2026-09-23'); // Wednesday
      expect(const StatsPeriod.thisWeek().resolve(today: today).range, DateRange(d('2026-09-21'), d('2026-09-27')));
      expect(
        const StatsPeriod.thisWeek().resolve(today: today, weekStart: Weekday.saturday).range,
        DateRange(d('2026-09-19'), d('2026-09-25')),
      );
      expect(
        const StatsPeriod.thisWeek().resolve(today: today, weekStart: Weekday.sunday).range,
        DateRange(d('2026-09-20'), d('2026-09-26')),
      );
      expect(const StatsPeriod.lastWeek().resolve(today: today).range.start, d('2026-09-14'));
    });

    test('lastMonth on 2026-03-31 is February 2026; other periods and keys', () {
      final today = d('2026-03-31');
      expect(const StatsPeriod.lastMonth().resolve(today: today).range, DateRange(d('2026-02-01'), d('2026-02-28')));
      expect(const StatsPeriod.thisMonth().resolve(today: today).range.days, 31);
      expect(const StatsPeriod.today().resolve(today: today).range, DateRange(today, today));
      expect(const StatsPeriod.yesterday().resolve(today: today).range.start, d('2026-03-30'));
      expect(const StatsPeriod.thisQuarter().resolve(today: today).range, DateRange(d('2026-01-01'), d('2026-03-31')));
      expect(const StatsPeriod.lastQuarter().resolve(today: today).range, DateRange(d('2025-10-01'), d('2025-12-31')));
      expect(const StatsPeriod.thisYear().resolve(today: today).range.days, 365);
      expect(const StatsPeriod.lastYear().resolve(today: today).range.start, d('2025-01-01'));
      expect(
        const StatsPeriod.allTime().resolve(today: today, firstDataDate: d('2026-01-10')).range.start,
        d('2026-01-10'),
      );
      expect(const StatsPeriod.allTime().resolve(today: today).range.days, 1);
      expect(StatsPeriod.custom(d('2026-03-10'), d('2026-03-01')).resolve(today: today).range.days, 10);
      expect(
        [
          const StatsPeriod.today(),
          const StatsPeriod.yesterday(),
          const StatsPeriod.thisWeek(),
          const StatsPeriod.lastWeek(),
          const StatsPeriod.thisMonth(),
          const StatsPeriod.lastMonth(),
          const StatsPeriod.thisQuarter(),
          const StatsPeriod.lastQuarter(),
          const StatsPeriod.thisYear(),
          const StatsPeriod.lastYear(),
          const StatsPeriod.rolling(30),
          const StatsPeriod.allTime(),
          StatsPeriod.custom(d('2026-01-01'), d('2026-01-31')),
        ].map((p) => p.key).toSet().length,
        13,
      );
      expect(const StatsPeriod.rolling(30).key, 'rolling:30');
    });

    test('rolling 7 days across a DST change contains exactly 7 local dates', () {
      final paris = tzClock('Europe/Paris');
      final r = const StatsPeriod.rolling(7).resolve(today: d('2026-10-28'));
      expect(r.range.dates.length, 7);
      final instants = DayBoundaries(paris).instantsOf(r.range);
      expect(instants.duration, const Duration(days: 7, hours: 1));
      expect(instants.contains(at(paris, '2026-10-25T02:30')), isTrue);
      expect(instants.contains(instants.end), isFalse);
      expect(instants.overlap(instants.start.subtract(const Duration(hours: 1)), instants.start), Duration.zero);
      expect(instants.toString(), contains('['));
      expect({instants, DayBoundaries(paris).instantsOf(r.range)}.length, 1);
    });

    test('day start 04:00: an event at 01:30 belongs to the previous date', () {
      for (final zone in ['Europe/Paris', 'America/New_York', 'Africa/Tunis']) {
        final clock = tzClock(zone);
        final b = DayBoundaries(clock, dayStartsAt: LocalTime(4, 0));
        expect(b.dateOf(at(clock, '2026-09-23T01:30')), d('2026-09-22'), reason: zone);
        expect(b.dateOf(at(clock, '2026-09-23T04:00')), d('2026-09-23'), reason: zone);
        expect(b.minuteOfDay(at(clock, '2026-09-23T05:00')), 60);
      }
      final ny = tzClock('America/New_York');
      expect(DayBoundaries(ny).lengthOf(d('2026-03-08')), const Duration(hours: 23));
      expect(DayBoundaries(ny).lengthOf(d('2026-11-01')), const Duration(hours: 25));
      expect(DayBoundaries(tzClock('Africa/Tunis')).lengthOf(d('2026-03-29')), const Duration(hours: 24));
    });

    test('previous period in to-date mode, YoY, auto granularity, leap years', () {
      final week = const StatsPeriod.thisWeek().resolve(today: d('2026-09-23'));
      expect(week.inProgress, isTrue);
      expect(week.elapsedDays, 3);
      expect(week.previous(), DateRange(d('2026-09-14'), d('2026-09-16')));
      expect(week.previous(mode: CompareMode.fullPeriod), DateRange(d('2026-09-14'), d('2026-09-20')));
      final march = const StatsPeriod.thisMonth().resolve(today: d('2026-03-31'));
      expect(march.previous(), DateRange(d('2026-02-01'), d('2026-02-28')));
      final quarter = const StatsPeriod.thisQuarter().resolve(today: d('2026-05-10'));
      expect(quarter.previous().start, d('2026-01-01'));
      final year = const StatsPeriod.thisYear().resolve(today: d('2028-02-29'));
      expect(year.previous(), DateRange(d('2027-01-01'), d('2027-02-28')));
      expect(year.yearOverYear(), DateRange(d('2027-01-01'), d('2027-02-28')));
      final today = const StatsPeriod.today().resolve(today: d('2026-09-23'));
      expect(today.previous(), DateRange(d('2026-09-22'), d('2026-09-22')));
      final rolling = const StatsPeriod.rolling(30).resolve(today: d('2026-09-23'));
      expect(rolling.previous(), DateRange(d('2026-07-26'), d('2026-08-24')));
      expect(rolling.inProgress, isFalse);
      expect(rolling.toDate, rolling.range);
      expect(autoGranularityFor(DateRange(d('2026-01-01'), d('2026-01-14'))), Granularity.day);
      expect(autoGranularityFor(DateRange(d('2026-01-01'), d('2026-04-30'))), Granularity.week);
      expect(autoGranularityFor(DateRange(d('2026-01-01'), d('2027-12-31'))), Granularity.month);
      expect(autoGranularityFor(DateRange(d('2024-01-01'), d('2026-12-31'))), Granularity.quarter);
      expect(rolling.autoGranularity, Granularity.week);
      final range = DateRange(d('2026-09-01'), d('2026-09-10'));
      expect(range.intersect(DateRange(d('2026-09-08'), d('2026-09-20'))), DateRange(d('2026-09-08'), d('2026-09-10')));
      expect(range.intersect(DateRange(d('2026-10-01'), d('2026-10-02'))), isNull);
      expect(range.toString(), '2026-09-01..2026-09-10');
      const fixed = FixedOffsetClock(120);
      expect(fixed.toLocal(DateTime.utc(2026, 9, 1, 22, 30)), ldt('2026-09-02T00:30'));
      expect(fixed.toInstant(ldt('2026-09-02T00:30')), DateTime.utc(2026, 9, 1, 22, 30));
      expect(const FixedOffsetClock().toLocal(DateTime.utc(1969, 12, 31, 23, 59, 30)), ldt('1969-12-31T23:59'));
    });
  });

  group('circular statistics (T6.1.18)', () {
    test('mean of 23:00 and 01:00 is 00:00; identical times SD 0; uniform → no consistent time', () {
      final m = circularTimeSummary([23 * 60, 60]).valueOrNull!;
      expect(m.meanMinuteRounded, 0);
      final same = circularTimeSummary([600, 600, 600]).valueOrNull!;
      expect(same.sdMinutes, 0);
      expect(same.meanMinuteRounded, 600);
      final uniform = circularTimeSummary([0, 360, 720, 1080]).valueOrNull!;
      expect(uniform.resultantLength, lessThan(1e-9));
      expect(uniform.consistent, isFalse);
      expect(uniform.sdMinutes, isNull);
      final late = circularTimeSummary([23 * 60 + 50, 10]).valueOrNull!;
      expect(late.meanMinuteRounded, 0);
      expect(late.sdMinutes, lessThan(15));
      final shifted = circularTimeSummary([3 * 60 + 50, 4 * 60 + 10], dayStartMinute: 240).valueOrNull!;
      expect(shifted.meanMinuteRounded, 240);
      expect(circularTimeSummary(const []), isA<Insufficient<CircularSummary>>());
    });

    test('drift is wrapped to (−720, 720]', () {
      expect(circularDrift([30, 50]).valueOrNull, near(40, 1e-9));
      expect(circularDrift([700, 760]).valueOrNull, near(-710, 1e-9));
      expect(wrapMinutes(1000), -440);
      expect(wrapMinutes(-1000), 440);
      expect(wrapMinutes(720), 720);
      expect(circularDrift(const []), isA<Insufficient<double>>());
      expect(circularDrift([0, 720]), isA<NotApplicable<double>>());
    });
  });

  group('group tests vs R (T6.1.19, reference_tests.json)', () {
    final ref = loadFixture('reference_tests');
    test('Mann–Whitney U (wilcox.test exact = FALSE, correct = TRUE)', () {
      for (final c in (ref['mannWhitney']! as List).cast<Map<String, Object?>>()) {
        final r = mannWhitneyU(nums(c['x']), nums(c['y'])).valueOrNull!;
        expect(r.u, near(c['u']! as num, 1e-9));
        expect(r.pValue, near(c['p']! as num, 1e-9));
        expect(r.rankBiserial, near(2 * r.u / (r.nx * r.ny) - 1));
      }
      expect(mannWhitneyU(const [], const [1]), isA<Insufficient<MannWhitneyResult>>());
      expect(mannWhitneyU(const [1, 1], const [1]), isA<NotApplicable<MannWhitneyResult>>());
    });

    test('Kruskal–Wallis H (kruskal.test) and ε²', () {
      for (final c in (ref['kruskalWallis']! as List).cast<Map<String, Object?>>()) {
        final groups = [for (final g in (c['groups']! as List)) nums(g)];
        final r = kruskalWallis(groups).valueOrNull!;
        expect(r.h, near(c['h']! as num, 1e-9));
        expect(r.pValue, near(c['p']! as num, 1e-9));
        expect(r.epsilonSquared, near(c['epsilonSquared']! as num, 1e-9));
        expect(r.degreesOfFreedom, groups.length - 1);
      }
      expect(
        kruskalWallis([
          const [1],
          const [],
        ]),
        isA<Insufficient<KruskalWallisResult>>(),
      );
      expect(
        kruskalWallis([
          const [1, 1],
          const [1],
        ]),
        isA<NotApplicable<KruskalWallisResult>>(),
      );
      expect(averageRanks(const [3, 1, 3, 2]), [3.5, 1, 3.5, 2]);
    });
  });

  group('correlation & FDR vs R (T6.1.24, reference_tests.json)', () {
    final ref = loadFixture('reference_tests');
    test('Pearson, Spearman, phi, point-biserial (cor.test)', () {
      final p = ref['pearson']! as Map<String, Object?>;
      final pr = pearson(nums(p['x']), nums(p['y'])).valueOrNull!;
      expect(pr.r, near(p['r']! as num, 1e-12));
      expect(pr.pValue, near(p['p']! as num, 1e-12));
      final s = ref['spearman']! as Map<String, Object?>;
      final sr = spearman(nums(s['x']), nums(s['y'])).valueOrNull!;
      expect(sr.r, near(s['rho']! as num, 1e-12));
      expect(sr.pValue, near(s['p']! as num, 1e-10));
      final ph = ref['phi']! as Map<String, Object?>;
      final phi = phiCoefficient(
        [for (final v in nums(ph['a'])) v == 1],
        [for (final v in nums(ph['b'])) v == 1],
      ).valueOrNull!;
      expect(phi.r, near(ph['phi']! as num, 1e-12));
      expect(phi.pValue, near(ph['p']! as num, 1e-10));
      final pb = ref['pointBiserial']! as Map<String, Object?>;
      final pbr = pointBiserial([for (final v in nums(pb['group'])) v == 1], nums(pb['values'])).valueOrNull!;
      expect(pbr.r, near(pb['r']! as num, 1e-12));
      expect(pbr.pValue, near(pb['p']! as num, 1e-10));
      expect(pearson(const [1, 2], const [1, 2]), isA<Insufficient<CorrelationResult>>());
      expect(pearson(const [1, 1, 1], const [1, 2, 3]), isA<NotApplicable<CorrelationResult>>());
      expect(pearson(const [1, 2, 3], const [2, 4, 6]).valueOrNull!.pValue, 0);
      expect(() => pearson(const [1], const [1, 2]), throwsArgumentError);
      expect(() => spearman(const [1], const [1, 2]), throwsArgumentError);
      expect(meetsEffectThreshold(0.25, binaryPair: true), isTrue);
      expect(meetsEffectThreshold(0.25, binaryPair: false), isFalse);
    });

    test('Benjamini–Hochberg equals p.adjust(method = "BH")', () {
      final bh = ref['bh']! as Map<String, Object?>;
      final adjusted = benjaminiHochberg(nums(bh['p']).map((v) => v.toDouble()).toList());
      final expected = nums(bh['adjusted']);
      for (var i = 0; i < expected.length; i++) {
        expect(adjusted[i], near(expected[i], 1e-12));
      }
      expect(benjaminiHochbergDiscoveries(nums(bh['p']).map((v) => v.toDouble()).toList()), [0, 1]);
      expect(benjaminiHochberg(const []), isEmpty);
    });

    // BH under the complete null: P(any discovery) = q, so the clean-seed share is ≈ 1 − q (SciPy
    // gives 94.0 % / 89.2 % for this design over 2 000 seeds).
    test('50 independent pairs: BH clean-seed share ≈ 1 − q', () {
      var clean10 = 0;
      var clean05 = 0;
      const seeds = 1000;
      final rng = math.Random(99);
      for (var seed = 0; seed < seeds; seed++) {
        final ps = <double>[];
        for (var k = 0; k < 50; k++) {
          final a = [for (var i = 0; i < 30; i++) rng.nextDouble()];
          final b = [for (var i = 0; i < 30; i++) rng.nextDouble()];
          ps.add(pearson(a, b).valueOrNull!.pValue);
        }
        if (benjaminiHochbergDiscoveries(ps).isEmpty) clean10++;
        if (benjaminiHochbergDiscoveries(ps, q: 0.05).isEmpty) clean05++;
      }
      expect(clean10 / seeds, greaterThanOrEqualTo(0.85));
      expect(clean05 / seeds, greaterThanOrEqualTo(0.92));
      expect(clean05, greaterThanOrEqualTo(clean10));
    });

    test('lag alignment pairs a(d) with b(d + lag)', () {
      final a = {d('2026-09-01'): 1, d('2026-09-02'): 2, d('2026-09-03'): 3};
      final b = {d('2026-09-02'): 10, d('2026-09-03'): 20, d('2026-09-05'): 30};
      final aligned = alignWithLag(a, b, lag: 1);
      expect(aligned.a, [1, 2]);
      expect(aligned.b, [10, 20]);
      expect(aligned.dates, [d('2026-09-01'), d('2026-09-02')]);
    });
  });

  group('Kaplan–Meier vs survfit (T6.1.25)', () {
    final km = loadFixture('reference_tests')['kaplanMeier']! as Map<String, Object?>;
    test('steps, Greenwood log-CI and median', () {
      final times = nums(km['times']);
      final events = nums(km['events']);
      final r = kaplanMeier([
        for (var i = 0; i < times.length; i++) SurvivalObservation(times[i].toDouble(), event: events[i] == 1),
      ]).valueOrNull!;
      final steps = (km['steps']! as List).cast<Map<String, Object?>>();
      expect(r.steps.length, steps.length);
      for (var i = 0; i < steps.length; i++) {
        expect(r.steps[i].time, steps[i]['time']);
        expect(r.steps[i].atRisk, steps[i]['atRisk']);
        expect(r.steps[i].events, steps[i]['events']);
        expect(r.steps[i].censored, steps[i]['censored']);
        expect(r.steps[i].survival, near(steps[i]['survival']! as num, 1e-12));
        expect(r.steps[i].lower, near(steps[i]['lower']! as num, 1e-12));
        expect(r.steps[i].upper, near(steps[i]['upper']! as num, 1e-12));
      }
      expect(r.medianSurvival, km['median']);
      expect(r.medianReached, isTrue);
      expect(r.survivalAt(0.5), 1);
      expect(r.survivalAt(3.5), near(0.6));
      expect(r.events, 5);
      expect(r.n, 8);
    });

    test('all censored, single event, fewer than 2 subjects', () {
      final censored = kaplanMeier(const [SurvivalObservation(3, event: false), SurvivalObservation(5, event: false)])
          .valueOrNull!;
      expect(censored.medianSurvival, isNull);
      expect(censored.steps.every((s) => s.survival == 1), isTrue);
      final single = kaplanMeier(const [SurvivalObservation(2, event: true), SurvivalObservation(4, event: false)])
          .valueOrNull!;
      expect(single.medianSurvival, 2);
      expect(single.steps.first.survival, 0.5);
      final allEvents = kaplanMeier(const [SurvivalObservation(1, event: true), SurvivalObservation(1, event: true)])
          .valueOrNull!;
      expect(allEvents.steps.single.survival, 0);
      expect(allEvents.steps.single.standardError, isNull);
      expect(kaplanMeier(const [SurvivalObservation(1, event: true)]), isA<Insufficient<KaplanMeierResult>>());
    });
  });

  group('Monte Carlo forecasting (T6.1.26)', () {
    test('constant throughput 2/day and R = 10 → all percentiles day 5; fast', () {
      final pool = List<int>.filled(42, 2);
      final watch = Stopwatch()..start();
      final f = monteCarloWhen(pool: pool, remaining: 10, random: math.Random(1)).valueOrNull!;
      watch.stop();
      expect([f.p50Days, f.p85Days, f.p95Days], [5, 5, 5]);
      expect(f.probabilityWithin(4), 0);
      expect(f.probabilityWithin(5), 1);
      expect(f.unfinishedTrials, 0);
      expect(watch.elapsedMilliseconds, lessThan(500));
      final none = monteCarloWhen(pool: pool, remaining: 0, random: math.Random(1)).valueOrNull!;
      expect(none.p95Days, 0);
      final many = monteCarloHowMany(pool: pool, days: 7, random: math.Random(1)).valueOrNull!;
      expect([many.atLeastP50, many.atLeastP85, many.atLeastP95], [14, 14, 14]);
    });

    test('variable throughput, zero-throughput history and short history are insufficient', () {
      final pool = [for (var i = 0; i < 42; i++) i % 3];
      final f = monteCarloWhen(pool: pool, remaining: 20, random: math.Random(3)).valueOrNull!;
      expect(f.p50Days, lessThanOrEqualTo(f.p85Days));
      expect(f.p85Days, lessThanOrEqualTo(f.p95Days));
      expect(f.p50Days, inInclusiveRange(17, 23));
      final many = monteCarloHowMany(pool: pool, days: 10, random: math.Random(3)).valueOrNull!;
      expect(many.atLeastP95, lessThanOrEqualTo(many.atLeastP85));
      expect(many.atLeastP85, lessThanOrEqualTo(many.atLeastP50));
      expect(
        monteCarloWhen(pool: List<int>.filled(42, 0), remaining: 5, random: math.Random(1)),
        isA<Insufficient<ForecastWhen>>(),
      );
      expect(
        monteCarloWhen(pool: List<int>.filled(10, 2), remaining: 5, random: math.Random(1)),
        const Insufficient<ForecastWhen>(30, 10, 'monteCarloHistory'),
      );
      expect(
        monteCarloHowMany(pool: List<int>.filled(10, 2), days: 5, random: math.Random(1)),
        isA<Insufficient<ForecastHowMany>>(),
      );
      final stuck = monteCarloWhen(
        pool: [...List<int>.filled(39, 0), 10],
        remaining: 1000000,
        random: math.Random(1),
        trials: 5,
      ).valueOrNull!;
      expect(stuck.unfinishedTrials, 5);
    });

    test('throughput pool skips inactive days; forecast dates skip them too', () {
      final pool = throughputPool(
        {d('2026-09-01'): 3},
        from: d('2026-09-01'),
        to: d('2026-09-07'),
        isActive: (x) => !x.weekday.isWeekend,
      );
      expect(pool, [3, 0, 0, 0, 0]);
      expect(forecastDate(d('2026-09-04'), 2, isActive: (x) => !x.weekday.isWeekend), d('2026-09-08'));
      expect(forecastDate(d('2026-09-04'), 2), d('2026-09-06'));
    });
  });
}
