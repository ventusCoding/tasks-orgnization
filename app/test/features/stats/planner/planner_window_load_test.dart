// Window-bounded planner loading (T6.1.23): the Planner section loads only the occurrence records and
// sessions of its resolution window. The facts it resolves must be exactly those of a full load —
// including occurrences moved into or out of the window, their sessions, one-off tasks and
// after-completion series (which keep their whole history).
import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/planner_resolution.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';
const _afterCompletion = '{"v":1,"type":"after_completion","afterCompletion":{"amount":3,"unit":"day"}}';
final _now = DateTime.utc(2026, 9, 23, 12);

Map<String, Object?> _task(String id, String start, {String? recurrence}) => {
  'id': id,
  'series_id': id,
  'title': 'Task $id',
  'created_at': '2025-01-01T08:00:00.000Z',
  'start_local': start,
  'duration_minutes': 30,
  'time_zone': 'UTC',
  'tracking_mode': 'timer',
  'recurrence': ?recurrence,
};

Map<String, Object?> _occ(String task, String key, {String status = 'done', String? moveTo}) => {
  'id': 'occ-$task-$key',
  'task_id': task,
  'occurrence_key': key,
  'status': status,
  'completed_at': status == 'done' ? '${key.substring(0, 10)}T12:00:00.000Z' : null,
  'status_changed_at': '${key.substring(0, 10)}T12:00:00.000Z',
  'override_start_local': ?moveTo,
};

Map<String, Object?> _entry(String id, String task, String? key, String start) => {
  'id': id,
  'task_id': task,
  'occurrence_key': key,
  'started_at': '${start}T09:00:00.000Z',
  'ended_at': '${start}T09:20:00.000Z',
};

/// A daily series from Jan 2025 with records far before, inside and after the window, two moves
/// across the window edge, a one-off task and an after-completion series.
Map<String, Object?> _tables() => {
  'tasks': [
    _task('w', '2025-01-02T09:00', recurrence: _daily),
    _task('one', '2025-03-03T10:00'),
    _task('ac', '2025-01-01T08:00', recurrence: _afterCompletion),
  ],
  'task_occurrences': [
    _occ('w', '2025-01-02T09:00'),
    _occ('w', '2025-06-02T09:00'),
    _occ('w', '2026-09-21T09:00'),
    _occ('w', '2026-09-17T09:00', status: 'skipped'),
    // Moved from far before the window into it, and from inside the window to far after it.
    _occ('w', '2025-02-03T09:00', moveTo: '2026-09-22T15:00'),
    _occ('w', '2026-09-14T09:00', moveTo: '2027-03-01T09:00'),
    // The one-off task was planned in March 2025 and its record says it moved into the window.
    _occ('one', '2025-03-03T10:00', moveTo: '2026-09-22T10:00'),
    _occ('ac', '2025-01-01T08:00'),
    _occ('ac', '2025-06-10T08:00'),
  ],
  'time_entries': [
    _entry('e1', 'w', '2025-01-02T09:00', '2025-01-02'),
    _entry('e2', 'w', '2026-09-21T09:00', '2026-09-21'),
    _entry('e3', 'w', '2025-02-03T09:00', '2026-09-22'),
    _entry('e4', 'one', null, '2026-09-22'),
    _entry('e5', 'ac', '2025-06-10T08:00', '2025-06-10'),
  ],
  'activity_events': [
    {
      'id': 'ev1',
      'entity_type': 'task',
      'entity_id': 'w',
      'event_type': 'rescheduled',
      'occurred_at': '2026-09-01T08:00:00.000Z',
      'payload': '{"occurrenceKey":"2025-02-03T09:00","fromStart":"2025-02-03T09:00","toStart":"2026-09-22T15:00"}',
    },
  ],
};

String _describe(PlannerOccurrenceFact f) => [
  f.taskId,
  f.occurrenceKey,
  f.plannedStart,
  f.plannedEnd,
  f.status,
  f.doneAt,
  [for (final s in f.sessions) '${s.start}-${s.end}'].join(','),
  f.moves.length,
].join('|');

void main() {
  late StatsHarness h;

  setUp(() async {
    h = StatsHarness.create(now: _now);
    await h.seedTables(_tables());
  });
  tearDown(() => h.dispose());

  List<String> facts(PlannerInput input, LocalDate from, LocalDate to) => [
    for (final f in PlannerResolver(
      input,
      resolver: LocationZoneResolver(const {}),
      viewerZone: 'UTC',
      now: _now,
    ).resolve(from: from, to: to).facts)
      _describe(f),
  ];

  test('bounded and full loads resolve the same window facts', () async {
    final source = h.read(statsDataSourceProvider);
    final full = await source.loadPlanner();
    for (final (from, to) in [
      (LocalDate(2026, 9, 7), LocalDate(2026, 10, 25)),
      (LocalDate(2026, 8, 25), LocalDate(2026, 9, 30)),
      (LocalDate(2024, 12, 25), LocalDate(2027, 1, 28)),
    ]) {
      final bounded = await source.loadPlanner(from: from, to: to);
      expect(bounded.occurrences.length, lessThanOrEqualTo(full.occurrences.length));
      expect(facts(bounded, from, to), facts(full, from, to), reason: '$from…$to');
    }
    final window = facts(full, LocalDate(2026, 9, 7), LocalDate(2026, 10, 25));
    expect(window.where((f) => f.startsWith('w|2025-02-03T09:00')), hasLength(1), reason: 'moved in');
    expect(window.where((f) => f.startsWith('w|2026-09-14T09:00')), isEmpty, reason: 'moved out');
    expect(window.where((f) => f.startsWith('one|')), hasLength(1));
    // The narrow window really skips history (2 old `w` records and the old session).
    final narrow = await source.loadPlanner(from: LocalDate(2026, 9, 7), to: LocalDate(2026, 10, 25));
    expect(narrow.occurrences.length, full.occurrences.length - 2);
    expect(narrow.timeEntries.map((e) => e.startedAt.toIso8601String()), isNot(contains('2025-01-02T09:00:00.000Z')));
    // The moved-in occurrence brings its session along, under its original key.
    expect(narrow.timeEntries.where((e) => e.occurrenceKey == '2025-02-03T09:00'), hasLength(1));
  });

  test('the Planner section uses the window of its period and comparison', () async {
    final env = h.read(statsComputeServiceProvider).environment();
    final (from, to) = StatsComputeService.plannerWindow(
      const StatsRequest(MetricScope.planner, selection: PeriodSelection(StatsPeriod.thisWeek(), compare: true)),
      env,
    );
    // This week (Mon 21 → Sun 27) and the previous one, a week before and four weeks after.
    expect(from, LocalDate(2026, 9, 7));
    expect(to, LocalDate(2026, 10, 25));
    // Every Planner section metric gives the same results as with the full history.
    final bounded = await h.compute(MetricScope.planner, period: const StatsPeriod.thisWeek());
    final service = h.read(statsComputeServiceProvider);
    final request = StatsRequest(
      MetricScope.planner,
      selection: const PeriodSelection(StatsPeriod.thisWeek(), compare: true),
      metricIds: plannerLayout.metricIds,
    );
    final job = await service.buildJob(request, service.metricIdsOf(request));
    final fullJob = StatsJob(
      request: job.request,
      env: job.env,
      metricIds: job.metricIds,
      planner: await h.read(statsDataSourceProvider).loadPlanner(),
      firstDataDate: job.firstDataDate,
    );
    final full = await service.executor.run(fullJob);
    for (final id in service.metricIdsOf(request)) {
      expect(bounded[id]?.value, full[id]?.value, reason: id);
      expect(bounded[id]?.chart?.toTable().rows.length, full[id]?.chart?.toTable().rows.length, reason: id);
    }
  });
}
