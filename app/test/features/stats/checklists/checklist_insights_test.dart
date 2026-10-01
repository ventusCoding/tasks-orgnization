// Checklist Insights P1/P2 metrics (T6.4.03, T6.4.05–T6.4.11, T6.4.13, T6.4.14) through the
// registry: the canonical checklist_flow_small dataset (T6.4.02 item X, T6.4.05 CFD in L1) and
// small seeded scenarios for the other acceptance criteria.
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/widgets/blocker_clusters_sheet.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

const _week = 'custom:2026-09-01..2026-09-07';

Map<String, Object?> _item(
  String id,
  String list, {
  String status = 'todo',
  String created = '2026-08-01T08:00:00.000Z',
  String? parent,
}) => {
  'id': id,
  'checklist_id': list,
  'sort_key': id,
  'text': 'Item $id',
  'status': status,
  'created_at': created,
  'parent_id': ?parent,
};

Map<String, Object?> _status(String id, String item, String list, String at, String from, String to, {String? note}) =>
    {
      'id': id,
      'entity_type': 'checklist_item',
      'entity_id': item,
      'parent_id': list,
      'event_type': 'status_changed',
      'occurred_at': at,
      'payload': {'from': from, 'to': to, 'note': ?note},
    };

Map<String, Object?> _created(String id, String item, String list, String at) => {
  'id': id,
  'entity_type': 'checklist_item',
  'entity_id': item,
  'parent_id': list,
  'event_type': 'created',
  'occurred_at': at,
  'payload': {'to': 'todo'},
};

void main() {
  group('on checklist_flow_small', () {
    late StatsHarness h;
    setUp(() async => h = await StatsFixture.load('checklist_flow_small').seed());
    tearDown(() => h.dispose());

    test('T6.4.03: flow efficiency 50 %, blocked 16.7 % of CT, 6 changes, 0 reopens, 1 loop', () async {
      final r = await h.compute(MetricScope.checklistItem, scopeId: 'X', period: PeriodSelection.parsePeriod(_week)!);
      expect(r['CL-I-10']!.value.valueOrNull, closeTo(0.5, 1e-9));
      expect(r['CL-I-08']!.args['shareOfCycleTime']! as double, closeTo(1 / 6, 1e-3));
      expect(r['CL-I-11']!.value.valueOrNull, 6);
      expect(r['CL-I-11']!.args['reopens'], 0);
      expect(r['CL-I-11']!.args['loops'], 1);
      expect(r['CL-I-12']!.value.hasValue, isTrue);
    });

    test('T6.4.05: exact CFD bands for d1…d5 and one reopen', () async {
      final r = await h.compute(
        MetricScope.checklist,
        scopeId: 'L1',
        period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-05')!,
      );
      final cfd = r['CL-L-07']!.chart! as StackedAreaData;
      List<double> band(LabelToken t) => cfd.bands.firstWhere((b) => b.label == TokenLabel(t)).values.cast<double>();
      expect(band(LabelToken.todo), [2, 2, 1, 1, 1]);
      expect(band(LabelToken.ongoing), [1, 1, 2, 2, 0]);
      expect(band(LabelToken.waiting), [0, 0, 0, 0, 1]);
      expect(band(LabelToken.blocked), [0, 0, 1, 0, 0]);
      expect(band(LabelToken.completed), [0, 1, 0, 1, 2]);
      expect(r['CL-L-07']!.args['reopens'], 1);
      expect(cfd.markers.single.index, 2, reason: 'the reopen lowers the completed band on d3');
    });

    test('T6.4.06: items completed without start are counted apart; P85 hidden below 10', () async {
      final r = await h.compute(MetricScope.checklist, scopeId: 'L1', period: PeriodSelection.parsePeriod(_week)!);
      expect(r['CL-L-08']!.args['p85'], isNull);
      expect(r['CL-L-09']!.value, isA<Insufficient<double>>());
      expect(r['CL-L-10']!.chart, anyOf(isNull, isA<ScatterData>()));
    });
  });

  test('T6.4.07: three items added to a ten-item list give 30 % scope creep and a step', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'checklists': [
        {'id': 'L', 'title': 'Move', 'sort_key': 'a', 'created_at': '2026-09-01T08:00:00.000Z'},
      ],
      'checklist_items': [
        for (var i = 0; i < 10; i++) _item('i$i', 'L', created: '2026-09-01T08:00:00.000Z'),
        for (var i = 10; i < 13; i++) _item('i$i', 'L', created: '2026-09-05T08:00:00.000Z'),
      ],
      'activity_events': [
        for (var i = 0; i < 10; i++) _created('c$i', 'i$i', 'L', '2026-09-01T08:00:00.000Z'),
        _status('s0', 'i0', 'L', '2026-09-02T09:00:00.000Z', 'todo', 'ongoing'),
        for (var i = 10; i < 13; i++) _created('c$i', 'i$i', 'L', '2026-09-05T08:00:00.000Z'),
      ],
    });
    final r = await h.compute(
      MetricScope.checklist,
      scopeId: 'L',
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-10')!,
    );
    expect(r['CL-L-12']!.value.valueOrNull, closeTo(0.3, 1e-9));
    final burn = r['CL-L-12']!.chart! as TimeSeriesData;
    final step = burn.annotations.single;
    expect(step.kind, AnnotationKind.scopeChange);
    expect(step.details, hasLength(3));
    expect(burn.series.first.values[3], 10);
    expect(burn.series.first.values[4], 13);
  });

  test('T6.4.08: "waiting for Sam" and "@sam invoice" group under Sam', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'checklists': [
        {'id': 'L', 'title': 'Work', 'sort_key': 'a', 'created_at': '2026-09-01T08:00:00.000Z'},
      ],
      'checklist_items': [
        _item('a', 'L', status: 'waiting'),
        _item('b', 'L', status: 'waiting'),
        _item('c', 'L', status: 'blocked'),
      ],
      'activity_events': [
        _status('s1', 'a', 'L', '2026-09-08T09:00:00.000Z', 'todo', 'waiting', note: 'waiting for Sam'),
        _status('s2', 'b', 'L', '2026-09-09T09:00:00.000Z', 'todo', 'waiting', note: '@sam invoice'),
        _status('s3', 'c', 'L', '2026-09-09T10:00:00.000Z', 'todo', 'blocked', note: 'No budget'),
      ],
    });
    final r = await h.compute(MetricScope.checklists, period: const StatsPeriod.thisWeek());
    final register = r['CL-X-07']!.args['entities']! as List;
    final sam = register.cast<Map<String, Object?>>().singleWhere(
      (e) => (e['entity']! as String).toLowerCase() == 'sam',
    );
    expect(sam['open'], 2);
    expect(r['CL-X-06']!.chart, isA<ParetoData>());
    final l = await h.compute(MetricScope.checklist, scopeId: 'L', period: const StatsPeriod.thisWeek());
    expect(l['CL-L-14']!.args['blocked'], 1);
    expect(l['CL-L-14']!.args['waiting'], 2);
  });

  test('T6.4.09: a 12-level tree; integrity flags open the checklist on the item', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'checklists': [
        {'id': 'L', 'title': 'Deep', 'sort_key': 'a', 'created_at': '2026-09-01T08:00:00.000Z'},
      ],
      'checklist_items': [
        for (var d = 0; d < 12; d++)
          _item('d$d', 'L', parent: d == 0 ? null : 'd${d - 1}', status: d == 0 ? 'completed' : 'todo'),
        _item('p', 'L'),
        _item('p1', 'L', parent: 'p', status: 'completed'),
      ],
    });
    final r = await h.compute(MetricScope.checklist, scopeId: 'L', period: const StatsPeriod.thisWeek());
    final shape = r['CL-L-16']!;
    expect(shape.value.valueOrNull, 12);
    final flags = r['CL-L-17']!.chart! as ListData;
    expect(flags.rows, hasLength(2));
    final ref = flags.rows.firstWhere((row) => row.ref?.extra == 'd0').ref!;
    expect(ref.kind, DrillKind.item);
    expect(ref.id, 'L');
    expect((r['CL-L-29']!.chart! as BarData).categories, hasLength(12));
  });

  test('T6.4.10: due dates resolve in the item zone or as floating', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'checklists': [
        {'id': 'L', 'title': 'Due', 'sort_key': 'a', 'created_at': '2026-09-01T08:00:00.000Z'},
      ],
      'checklist_items': [
        // Due 09:00 New York (13:00 UTC), done 12:30 UTC → on time.
        {
          ..._item('ny', 'L', status: 'completed'),
          'due_local': '2026-09-08T09:00',
          'time_zone': 'America/New_York',
          'completed_at': '2026-09-08T12:30:00.000Z',
        },
        // Floating 09:00 in the viewer's zone (UTC), done 12:30 → late.
        {
          ..._item('fl', 'L', status: 'completed'),
          'due_local': '2026-09-08T09:00',
          'completed_at': '2026-09-08T12:30:00.000Z',
        },
        {..._item('open', 'L'), 'due_local': '2026-09-09T09:00'},
      ],
      'activity_events': [
        _status('s1', 'ny', 'L', '2026-09-08T12:30:00.000Z', 'todo', 'completed'),
        _status('s2', 'fl', 'L', '2026-09-08T12:30:00.000Z', 'todo', 'completed'),
      ],
    });
    final r = await h.compute(MetricScope.checklist, scopeId: 'L', period: const StatsPeriod.thisWeek());
    expect(r['CL-L-19']!.args['openOverdue'], 1);
    // 1 of 2 on time (below the rate rule, so the value is hidden but the numbers are carried).
    expect(r['CL-L-19']!.value, isA<Insufficient<double>>());
  });

  test('T6.4.11: seven runs 100/100/80/100/100/100/60 → mean 91.4 %, best 3, current 0', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    const completion = [5, 5, 4, 5, 5, 5, 3];
    await h.seedTables({
      'checklists': [
        {'id': 'R', 'title': 'Morning', 'sort_key': 'a', 'created_at': '2026-08-01T08:00:00.000Z'},
      ],
      'checklist_runs': [
        for (var i = 0; i < 7; i++)
          {
            'id': 'run$i',
            'checklist_id': 'R',
            'occurrence_key': '2026-09-0${i + 1}',
            'started_at': '2026-09-0${i + 1}T06:00:00.000Z',
            'ended_at': '2026-09-0${i + 2}T06:00:00.000Z',
            'total_items': 5,
            'completed_items': completion[i],
            'snapshot': [
              for (var k = 0; k < 5; k++)
                {
                  'itemId': 'r$k',
                  'status': k < completion[i] ? 'completed' : 'todo',
                  if (k < completion[i]) 'completedAt': '2026-09-0${i + 1}T06:${10 + k * 5}:00.000Z',
                },
            ],
          },
      ],
    });
    final r = await h.compute(
      MetricScope.checklist,
      scopeId: 'R',
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-07')!,
    );
    expect(r['CL-L-20']!.value.valueOrNull, closeTo(32 / 35, 1e-9));
    expect(r['CL-L-21']!.value.valueOrNull, 0);
    expect(r['CL-L-21']!.args['best'], 3);
    expect(r['CL-L-22']!.value.valueOrNull, 30);
    expect((r['CL-L-23']!.chart! as BarData).series.first.values.first, 2);
  });

  test('T6.4.13/14: completion calendar streak; forecast hidden without 30 days and 10 completions', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await h.seedTables({
      'checklists': [
        {'id': 'L', 'title': 'Daily', 'sort_key': 'a', 'created_at': '2026-09-01T08:00:00.000Z'},
      ],
      'checklist_items': [
        for (var d = 6; d <= 9; d++) {..._item('i$d', 'L', status: 'completed', created: '2026-09-01T08:00:00.000Z')},
        _item('open', 'L', created: '2026-09-01T08:00:00.000Z'),
      ],
      'activity_events': [
        for (var d = 6; d <= 9; d++) _status('s$d', 'i$d', 'L', '2026-09-0${d}T10:00:00.000Z', 'todo', 'completed'),
      ],
    });
    final s = await h.compute(
      MetricScope.checklists,
      period: PeriodSelection.parsePeriod('custom:2026-09-01..2026-09-10')!,
    );
    expect(s['CL-X-10']!.value.valueOrNull, 4, reason: 'Sep 6–9; today (10th) is open');
    expect(s['CL-X-10']!.chart, isA<CalendarData>());
    final l = await h.compute(MetricScope.checklist, scopeId: 'L', period: const StatsPeriod.thisWeek());
    expect(l['CL-L-28']!.value, isA<Insufficient<double>>());
    expect(l['CL-L-28']!.chart, isNull);
    expect((l['CL-L-11']!.chart! as TimeSeriesData).cone, isNull);
  });

  test('every P1/P2 checklist metric computes on an empty database', () async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    for (final scope in [MetricScope.checklistItem, MetricScope.checklist, MetricScope.checklists]) {
      final r = await h.compute(scope, scopeId: scope == MetricScope.checklists ? null : 'none');
      expect(r.values.where((m) => m.note == 'error'), isEmpty, reason: '$scope');
    }
  });

  testWidgets('T6.4.14: merging two blocked reasons into one cluster', (tester) async {
    final h = StatsHarness.create(now: DateTime.utc(2026, 9, 10, 12));
    addTearDown(h.dispose);
    await tester.runAsync(
      () => h.seedTables({
        'checklists': [
          {'id': 'L', 'title': 'Work', 'sort_key': 'a', 'created_at': '2026-09-01T08:00:00.000Z'},
        ],
        'checklist_items': [_item('a', 'L', status: 'blocked'), _item('b', 'L', status: 'blocked')],
        'activity_events': [
          _status('s1', 'a', 'L', '2026-09-08T09:00:00.000Z', 'todo', 'blocked', note: 'No budget'),
          _status('s2', 'b', 'L', '2026-09-09T09:00:00.000Z', 'todo', 'blocked', note: 'Budget not approved'),
        ],
      }),
    );
    final before = (await tester.runAsync(
      () => h.compute(MetricScope.checklist, scopeId: 'L', period: const StatsPeriod.thisWeek()),
    ))!;
    final reasons = blockerReasonsOf(before['CL-L-26']!.args);
    expect(reasons, hasLength(2));
    await pumpStats(tester, h, Scaffold(body: BlockerClustersSheet(reasons: reasons)));
    for (final r in reasons) {
      await tester.tap(find.byKey(ValueKey('cluster-${r.key}')));
    }
    await tester.enterText(find.byKey(const ValueKey('cluster-name')), 'Budget');
    await tester.pump();
    await tester.tap(find.text('Merge'));
    await tester.pump();
    final stats = (await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return h.read(settingsRepositoryProvider).read('stats');
    }))!;
    expect((stats['blockerClusters'] as Map).values.toSet(), {'Budget'});
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
