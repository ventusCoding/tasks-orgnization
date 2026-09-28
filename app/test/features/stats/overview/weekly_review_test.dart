// Weekly review (T6.7.02) and overview (T6.7.01) on the overview_week dataset: the report's numbers
// equal the section metrics, and the builder output is pinned by a JSON snapshot (T6.7.19).
// Regenerate the snapshot with `UPDATE_STATS_SNAPSHOTS=1 fvm flutter test <this file>`.
import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show StatsPeriod;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

Object? label(ChartLabel? l) => switch (l) {
  null => null,
  TokenLabel(:final token) => 'token:${token.name}',
  TextLabel(:final text) => text,
  DateLabel(:final date) => date.toIso(),
  NumberLabel(:final value) => value,
  _ => l.toString(),
};

double? round(double? v) => v == null ? null : (v * 1e6).roundToDouble() / 1e6;

Map<String, Object?> tile(ValueTile t) => {
  'label': label(t.label),
  'metricId': t.metricId,
  'value': round(t.value),
  'delta': round(t.delta),
  'unit': t.unit.name,
};

Map<String, Object?> entry(ReviewEntry e) => {
  'kind': e.kind.name,
  'title': e.title,
  'value': round(e.value),
  'date': e.date?.toIso(),
  'ref': e.ref == null ? null : '${e.ref!.kind.name}:${e.ref!.id}${e.ref!.extra == null ? '' : '@${e.ref!.extra}'}',
};

Map<String, Object?> snapshot(ReviewData r) => {
  'from': r.from.toIso(),
  'to': r.to.toIso(),
  'headline': [for (final t in r.headline) tile(t)],
  'wins': [for (final e in r.wins) entry(e)],
  'attention': [for (final e in r.attention) entry(e)],
  'topCategories': [
    for (final (l, minutes, delta) in r.topCategories) {'label': label(l), 'minutes': minutes, 'delta': delta},
  ],
  'nextWeek': [
    for (final (d, planned, capacity, over) in r.nextWeek)
      {'date': d.toIso(), 'planned': planned, 'capacity': capacity, 'overbooked': over},
  ],
};

void main() {
  late StatsHarness h;
  late Map<String, MetricResult> results;

  setUp(() async {
    h = await StatsFixture.load('overview_week').seed();
    results = await h.compute(MetricScope.global, period: const StatsPeriod.thisWeek());
  });
  tearDown(() => h.dispose());

  test('the review of last week equals the section metrics', () {
    final r = results['GL-03']!.chart! as ReviewData;
    expect((r.from.toIso(), r.to.toIso()), ('2026-09-14', '2026-09-20'));
    final byMetric = {for (final t in r.headline) t.metricId: t};
    // PL-X-01 17/21 · PL-X-12 250 min actual · HB-X-04 27/34 (Δ −2.41 pp) · CL-X-04 1 (Δ −1) · QT-07 7 × 20 × €0.65.
    expect(byMetric['PL-X-01']!.value, closeTo(17 / 21, 1e-9));
    expect(byMetric['PL-X-12']!.value, closeTo(250 / 60, 1e-9));
    expect(byMetric['HB-X-04']!.value, closeTo(27 / 34, 1e-9));
    expect(byMetric['HB-X-04']!.delta, closeTo(-2.406417112299475, 1e-9));
    expect(byMetric['CL-X-04']!.value, 1);
    expect(byMetric['CL-X-04']!.delta, -1);
    expect(byMetric['QT-07']!.value, closeTo(91, 1e-9));
    expect([for (final w in r.wins) (w.kind, w.value)], [(ReviewEntryKind.perfectDays, 4.0)]);
    expect(
      [for (final a in r.attention) (a.kind, a.title)],
      unorderedEquals([
        (ReviewEntryKind.overdueTasks, 'Gym'),
        (ReviewEntryKind.overdueTasks, 'O9'),
        (ReviewEntryKind.overdueTasks, 'Reading'),
        (ReviewEntryKind.blockedWaiting, 'Item C'),
      ]),
    );
    // Every attention item opens its entity.
    expect(r.attention.every((a) => a.ref != null), isTrue);
    expect([for (final (_, minutes, _) in r.topCategories) minutes], [465, 210, 180]);
  });

  test('the builder output matches the committed snapshot', () {
    final file = File('test/features/stats/overview/weekly_review_snapshot.json');
    final actual = const JsonEncoder.withIndent('  ').convert({
      'lastWeek': snapshot(results['GL-03']!.chart! as ReviewData),
      'today': [for (final t in (results['GL-01']!.chart! as TilesData).tiles) tile(t)],
      'weekAtAGlance': [for (final t in (results['GL-02']!.chart! as TilesData).tiles) tile(t)],
    });
    if (Platform.environment['UPDATE_STATS_SNAPSHOTS'] == '1' || !file.existsSync()) {
      file.writeAsStringSync('$actual\n');
    }
    expect(actual, file.readAsStringSync().trimRight());
  });
}
