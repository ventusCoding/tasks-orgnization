// Stats data loaders over Drift (T6.1.12): rows → isolate-sendable records, tombstone rules, scope
// headers, and query plans (no full scans of the large tables).
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/data/stats_data_source.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PlannerOccurrenceStatus, TrackingMode;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, LocalDateTime;
import 'package:flutter_test/flutter_test.dart';

import '../support/stats_harness.dart';

const _rule = '{"v":1,"freq":"DAILY","interval":1}';

Map<String, Object?> tables() => {
  'categories': [
    {'id': 'c1', 'name': 'Work', 'color': 0xFF3366CC, 'sort_key': 'a'},
    {'id': 'c2', 'name': 'Sleep', 'color': 0xFF222222, 'sort_key': 'b', 'counts_as_unavailable': true},
  ],
  'tags': [
    {'id': 'g1', 'name': 'deep', 'sort_key': 'a'},
  ],
  'entity_tags': [
    {'id': 'et1', 'tag_id': 'g1', 'entity_type': 'task', 'entity_id': 't1'},
    {'id': 'et2', 'tag_id': 'g1', 'entity_type': 'checklist', 'entity_id': 'l1'},
  ],
  'tasks': [
    {
      'id': 't1',
      'series_id': 's1',
      'title': 'Run',
      'recurrence': _rule,
      'start_local': '2026-09-01T07:00',
      'duration_minutes': 30,
      'time_zone': 'Europe/Paris',
      'category_id': 'c1',
      'priority': 2,
      'tracking_mode': 'event',
    },
    {'id': 't2', 'series_id': 't2', 'title': 'Call', 'start_local': '2026-09-25', 'is_all_day': true},
    {'id': 't3', 'series_id': 't3', 'title': 'Backlog'},
    {'id': 't4', 'series_id': 't4', 'title': 'Gone', 'start_local': '2026-09-02T09:00', 'deleted_at': '2026-09-03T00:00:00Z'},
    {'id': 't5', 'series_id': 't5', 'title': 'Template', 'start_local': '2026-09-02T09:00', 'is_template': true},
    {'id': 't6', 'series_id': 't6', 'title': 'Later', 'start_local': '2026-12-01T09:00'},
  ],
  'task_occurrences': [
    {
      'id': 'o1',
      'task_id': 't1',
      'occurrence_key': '2026-09-01T07:00',
      'status': 'done',
      'completed_at': '2026-09-01T05:40:00Z',
      'actual_start_at': '2026-09-01T05:05:00Z',
      'actual_end_at': '2026-09-01T05:40:00Z',
      'completion_percent': 100,
      'rating': 4,
    },
    {'id': 'o2', 'task_id': 't1', 'occurrence_key': '2026-09-02T07:00', 'status': 'skipped', 'skip_reason': 'rain'},
    {'id': 'o3', 'task_id': 't1', 'occurrence_key': '2026-09-03T07:00', 'is_cancelled': true},
    {'id': 'o4', 'task_id': 't1', 'occurrence_key': '2026-09-04T07:00', 'status': 'in_progress', 'override_start_local': '2026-09-04T08:15'},
    {'id': 'o5', 'task_id': 't1', 'occurrence_key': '2026-09-05T07:00', 'status': 'done', 'deleted_at': '2026-09-06T00:00:00Z'},
  ],
  'time_entries': [
    {'id': 'e1', 'task_id': 't1', 'occurrence_key': '2026-09-01T07:00', 'started_at': '2026-09-01T05:05:00Z', 'ended_at': '2026-09-01T05:40:00Z'},
    {'id': 'e2', 'task_id': 't1', 'occurrence_key': '2026-09-04T07:00', 'started_at': '2026-09-04T06:15:00Z'},
  ],
  'activity_events': [
    {'id': 'a1', 'entity_type': 'task', 'entity_id': 't1', 'event_type': 'rescheduled', 'occurred_at': '2026-09-03T20:00:00Z', 'payload': '{"from":"2026-09-04T07:00","to":"2026-09-04T08:15"}'},
    {'id': 'a2', 'entity_type': 'task', 'entity_id': 't1', 'event_type': 'completed', 'occurred_at': '2026-09-01T05:40:00Z', 'payload': '{}'},
    {'id': 'a3', 'entity_type': 'task', 'entity_id': 't1', 'event_type': 'rescheduled', 'occurred_at': '2026-09-02T20:00:00Z', 'payload': '{}', 'deleted_at': '2026-09-02T21:00:00Z'},
    {'id': 'a4', 'entity_type': 'checklist_item', 'entity_id': 'i1', 'parent_id': 'l1', 'event_type': 'status_changed', 'occurred_at': '2026-09-10T10:00:00Z', 'payload': '{"from":"todo","to":"ongoing"}'},
    {'id': 'a5', 'entity_type': 'checklist_item', 'entity_id': 'i9', 'parent_id': 'l2', 'event_type': 'created', 'occurred_at': '2026-09-11T10:00:00Z', 'payload': 'not json'},
    // i8 was created in l1, then moved to l2.
    {'id': 'a6', 'entity_type': 'checklist_item', 'entity_id': 'i8', 'parent_id': 'l1', 'event_type': 'created', 'occurred_at': '2026-09-05T10:00:00Z', 'payload': '{"to":"todo"}'},
    {'id': 'a7', 'entity_type': 'checklist_item', 'entity_id': 'i8', 'parent_id': 'l2', 'event_type': 'moved', 'occurred_at': '2026-09-06T10:00:00Z', 'payload': '{"fromChecklistId":"l1","toChecklistId":"l2"}'},
  ],
  'checklists': [
    {
      'id': 'l1',
      'title': 'Move',
      'sort_key': 'a',
      'color': 0xFF00AA00,
      'reset_rule': _rule,
      'settings': '{"v":1,"requireReasonFor":["blocked","waiting"],"staleAfterDays":10}',
      'due_local': '2026-10-01T18:00',
      'time_zone': 'Africa/Tunis',
    },
    {'id': 'l2', 'title': 'Books', 'sort_key': 'b'},
    {'id': 'l3', 'title': 'Old', 'sort_key': 'c', 'deleted_at': '2026-09-01T00:00:00Z'},
  ],
  'checklist_items': [
    {'id': 'i1', 'checklist_id': 'l1', 'sort_key': 'a', 'text': 'Pack', 'status': 'ongoing', 'created_at': '2026-09-09T10:00:00Z'},
    {'id': 'i2', 'checklist_id': 'l1', 'parent_id': 'i1', 'sort_key': 'b', 'text': 'Books', 'status': 'completed', 'completed_at': '2026-09-12T10:00:00Z', 'created_at': '2026-09-08T10:00:00Z'},
    {'id': 'i3', 'checklist_id': 'l1', 'sort_key': 'c', 'text': 'Dropped', 'deleted_at': '2026-09-13T10:00:00Z', 'created_at': '2026-09-07T10:00:00Z'},
    {'id': 'i8', 'checklist_id': 'l2', 'sort_key': 'b', 'text': 'Moved', 'created_at': '2026-09-05T10:00:00Z'},
    {'id': 'i9', 'checklist_id': 'l2', 'sort_key': 'a', 'text': 'Dune', 'status': 'blocked', 'status_note': 'lent', 'created_at': '2026-09-11T10:00:00Z'},
  ],
  'checklist_runs': [
    {
      'id': 'r1',
      'checklist_id': 'l1',
      'occurrence_key': '2026-09-01',
      'started_at': '2026-09-01T00:00:00Z',
      'ended_at': '2026-09-02T00:00:00Z',
      'total_items': 2,
      'completed_items': 1,
      'snapshot': '[{"itemId":"i1","status":"todo"},{"itemId":"i2","status":"completed","completedAt":"2026-09-01T09:00:00Z"},{"bad":1}]',
    },
  ],
  'attachments': [
    {'id': 'f1', 'owner_type': 'checklist_item', 'owner_id': 'i1', 'sort_key': 'a', 'storage_path': 'p', 'file_name': 'a.jpg', 'mime_type': 'image/jpeg', 'byte_size': 2048},
    {'id': 'f2', 'owner_type': 'task', 'owner_id': 't1', 'sort_key': 'a', 'storage_path': 'p', 'file_name': 'b.pdf', 'mime_type': 'application/pdf', 'byte_size': 10},
  ],
  'habits': [
    {
      'id': 'h1',
      'kind': 'build',
      'name': 'Water',
      'sort_key': 'a',
      'goal_type': 'count',
      'target_value': 8,
      'schedule': _rule,
      'start_date': '2026-08-01',
      'time_zone': 'Europe/Paris',
      'freezes_per_month': 2,
      'settings': '{"v":1,"slotRollup":{"minSlots":2},"requireExplicitLog":true,"earlyToleranceMinutes":15}',
    },
    {
      'id': 'h2',
      'kind': 'quit',
      'name': 'Smoking',
      'sort_key': 'b',
      'start_date': '2026-07-15',
      'quit_mode': 'quit',
      'quit_started_at': '2026-07-15T08:00:00Z',
      'baseline_per_day': 12,
      'unit_cost': 0.5,
      'currency': 'TND',
    },
    {'id': 'h3', 'kind': 'build', 'name': 'Deleted', 'sort_key': 'c', 'start_date': '2026-01-01', 'deleted_at': '2026-02-01T00:00:00Z'},
  ],
  'habit_logs': [
    {'id': 'hl1', 'habit_id': 'h1', 'kind': 'progress', 'value': 3, 'logged_at': '2026-09-20T08:00:00Z', 'local_date': '2026-09-20', 'occurrence_key': '2026-09-20'},
    {'id': 'hl2', 'habit_id': 'h2', 'kind': 'craving', 'logged_at': '2026-09-21T12:00:00Z', 'local_date': '2026-09-21', 'intensity': 7, 'resisted': true, 'trigger': 'coffee', 'duration_seconds': 180},
    {'id': 'hl3', 'habit_id': 'h1', 'kind': 'done', 'logged_at': '2026-09-19T08:00:00Z', 'local_date': '2026-09-19', 'deleted_at': '2026-09-19T09:00:00Z'},
  ],
  'habit_pauses': [
    {'id': 'p1', 'habit_id': 'h1', 'start_date': '2026-09-10', 'end_date': '2026-09-12', 'reason': 'trip'},
    {'id': 'p2', 'habit_id': 'h1', 'start_date': 'garbage'},
  ],
  'habit_revisions': [
    {'id': 'v1', 'habit_id': 'h1', 'effective_from': '2026-09-01', 'goal_type': 'count', 'target_value': 6},
  ],
  'notifications': [
    {'id': 'n1', 'dedupe_key': 'd1', 'source_type': 'habit', 'source_id': 'h1', 'category': 'reminder', 'title': 'Water', 'fire_at': '2026-09-20T07:00:00Z', 'acted_at': '2026-09-20T07:05:00Z', 'action': 'done'},
    {'id': 'n2', 'dedupe_key': 'd2', 'source_type': 'task', 'source_id': 't1', 'category': 'reminder', 'title': 'Run', 'fire_at': '2026-09-20T06:00:00Z'},
  ],
};

class _SelectRecorder extends QueryInterceptor {
  final statements = <(String, List<Object?>)>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor executor, String statement, List<Object?> args) {
    statements.add((statement, args));
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late StatsHarness h;
  late StatsDataSource source;

  setUp(() async {
    h = StatsHarness.create(now: DateTime.utc(2026, 9, 22, 9));
    await h.seedTables(tables());
    source = h.read(statsDataSourceProvider);
  });
  tearDown(() => h.dispose());

  group('planner facts', () {
    test('section: tasks up to the bound plus the backlog, no tombstones or templates', () async {
      final input = await source.loadPlanner(to: LocalDate(2026, 10, 31));
      expect(input.tasks.map((t) => t.id), unorderedEquals(['t1', 't2', 't3']));
      final t1 = input.tasks.firstWhere((t) => t.id == 't1');
      expect(t1.seriesId, 's1');
      expect(t1.startLocal, LocalDateTime.parse('2026-09-01T07:00'));
      expect(t1.recurrence, _rule);
      expect(t1.trackingMode, TrackingMode.event);
      expect((t1.priority, t1.durationMinutes, t1.timeZone, t1.categoryId), (2, 30, 'Europe/Paris', 'c1'));
      final t2 = input.tasks.firstWhere((t) => t.id == 't2');
      expect(t2.startLocal, LocalDateTime.parse('2026-09-25T00:00'));
      expect(t2.oneOffKey, '2026-09-25');
      expect(input.tasks.firstWhere((t) => t.id == 't3').isUnscheduled, isTrue);
      final all = await source.loadPlanner();
      expect(all.tasks.map((t) => t.id), contains('t6'));
    });

    test('occurrences, time entries and task events are mapped', () async {
      final input = await source.loadPlanner(seriesId: 's1');
      expect(input.tasks.single.id, 't1');
      final byKey = {for (final o in input.occurrences) o.key: o};
      expect(byKey.keys, unorderedEquals(['2026-09-01T07:00', '2026-09-02T07:00', '2026-09-03T07:00', '2026-09-04T07:00']));
      final done = byKey['2026-09-01T07:00']!;
      expect(done.status, PlannerOccurrenceStatus.done);
      expect(done.completedAt, DateTime.utc(2026, 9, 1, 5, 40));
      expect((done.completionPercent, done.rating), (100, 4));
      expect(byKey['2026-09-02T07:00']!.skipReason, 'rain');
      expect(byKey['2026-09-03T07:00']!.cancelled, isTrue);
      expect(byKey['2026-09-04T07:00']!.status, PlannerOccurrenceStatus.inProgress);
      expect(byKey['2026-09-04T07:00']!.overrideStartLocal, LocalDateTime.parse('2026-09-04T08:15'));
      expect(input.timeEntries, hasLength(2));
      expect(input.timeEntries.where((e) => e.endedAt == null), hasLength(1));
      // Only reschedule/created/updated events of live rows.
      expect(input.events.map((e) => e.eventType), ['rescheduled']);
      expect(input.events.single.payloadString('to'), '2026-09-04T08:15');
      expect(input.categories.map((c) => (c.id, c.unavailable)), unorderedEquals([('c1', false), ('c2', true)]));
      expect(input.tagLinks.single.entityId, 't1');
    });

    test('one task and the first planned date', () async {
      final input = await source.loadPlanner(taskId: 't2');
      expect(input.tasks.single.title, 'Call');
      expect(input.occurrences, isEmpty);
      expect(await source.firstPlannerDate(), LocalDate(2026, 9, 1));
      expect(await source.firstPlannerDate(seriesId: 't6'), LocalDate(2026, 12, 1));
    });
  });

  group('checklist facts', () {
    test('one list keeps deleted items for history and decodes settings, runs and attachments', () async {
      final input = await source.loadChecklists(checklistId: 'l1');
      // i8 moved to l2 but keeps its l1 history.
      expect(input.items.map((i) => i.id), unorderedEquals(['i1', 'i2', 'i3', 'i8']));
      final i3 = input.items.firstWhere((i) => i.id == 'i3');
      expect(i3.deletedAt, DateTime.utc(2026, 9, 13, 10));
      expect(input.items.firstWhere((i) => i.id == 'i2').parentId, 'i1');
      expect(input.items.firstWhere((i) => i.id == 'i1').text, 'Pack');
      final l1 = input.checklists.firstWhere((l) => l.id == 'l1');
      expect(l1.isResettable, isTrue);
      expect(l1.requireReasonFor, {'blocked', 'waiting'});
      expect(l1.staleAfterDays, 10);
      expect(l1.dueLocal, LocalDateTime.parse('2026-10-01T18:00'));
      expect(input.checklists.map((l) => l.id), isNot(contains('l3')));
      expect(input.events.map((e) => e.entityId), unorderedEquals(['i1', 'i8', 'i8']));
      final run = input.runs.single;
      expect(run.snapshot.map((s) => (s.itemId, s.status)), [('i1', 'todo'), ('i2', 'completed')]);
      expect(run.snapshot.last.completedAt, DateTime.utc(2026, 9, 1, 9));
      expect(input.attachments.single.byteSize, 2048);
      expect(input.tagLinks.single.entityId, 'l1');
    });

    test('an item loads its list; the section loads every list and tolerates bad payloads', () async {
      final item = await source.loadChecklists(itemId: 'i9');
      expect(item.items.map((i) => i.id), unorderedEquals(['i8', 'i9']));
      expect(item.items.firstWhere((i) => i.id == 'i9').statusNote, 'lent');
      final all = await source.loadChecklists();
      expect(all.items, hasLength(5));
      expect(all.events.map((e) => e.entityId), unorderedEquals(['i1', 'i8', 'i8', 'i9']));
      expect(all.events.firstWhere((e) => e.entityId == 'i9').payload, isEmpty);
      expect(await source.firstChecklistInstant(), DateTime.utc(2026, 9, 5, 10));
      expect(await source.firstChecklistInstant(checklistId: 'l2'), DateTime.utc(2026, 9, 5, 10));
    });
  });

  group('habit facts', () {
    test('habits, logs, pauses and revisions; settings JSON read defensively', () async {
      final input = await source.loadHabits();
      expect(input.habits.map((x) => x.id), unorderedEquals(['h1', 'h2']));
      final h1 = input.habits.firstWhere((x) => x.id == 'h1');
      expect((h1.goalType, h1.targetValue, h1.freezesPerMonth), ('count', 8.0, 2));
      expect((h1.slotMinDone, h1.requireExplicitLog, h1.earlyToleranceMinutes), (2, true, 15));
      expect(h1.startDate, LocalDate(2026, 8, 1));
      final h2 = input.habits.firstWhere((x) => x.id == 'h2');
      expect(h2.isQuit, isTrue);
      expect((h2.baselinePerDay, h2.unitCost, h2.currency), (12.0, 0.5, 'TND'));
      expect(h2.quitStartedAt, DateTime.utc(2026, 7, 15, 8));
      expect(h2.earlyToleranceMinutes, 30);
      expect(input.logs.map((l) => l.id), unorderedEquals(['hl1', 'hl2']));
      final craving = input.logs.firstWhere((l) => l.id == 'hl2');
      expect((craving.kind, craving.intensity, craving.resisted, craving.trigger, craving.durationSeconds), ('craving', 7, true, 'coffee', 180));
      expect(craving.localDate, LocalDate(2026, 9, 21));
      expect(input.pauses.single.start, LocalDate(2026, 9, 10));
      expect(input.pauses.single.end, LocalDate(2026, 9, 12));
      expect(input.revisions.single.targetValue, 6);
      expect(input.notifications, isEmpty);
      expect(await source.firstHabitDate(), LocalDate(2026, 7, 15));
      expect(await source.firstHabitDate(habitId: 'h1'), LocalDate(2026, 8, 1));
    });

    test('one habit with its reminder notifications', () async {
      final input = await source.loadHabits(habitId: 'h1', withNotifications: true);
      expect(input.habits.single.id, 'h1');
      expect(input.logs.single.id, 'hl1');
      expect(input.notifications.single.action, 'done');
      expect(input.notifications.single.actedAt, DateTime.utc(2026, 9, 20, 7, 5));
    });
  });

  group('scope headers and pickers', () {
    test('entity of each scope', () async {
      expect((await source.entityOf('task', 't1'))?.parentId, 's1');
      expect((await source.entityOf('series', 's1'))?.name, 'Run');
      expect((await source.entityOf('checklist', 'l1'))?.color, 0xFF00AA00);
      expect((await source.entityOf('item', 'i2'))?.parentId, 'l1');
      expect((await source.entityOf('habit', 'h1'))?.isQuit, isFalse);
      expect((await source.entityOf('quit', 'h2'))?.isQuit, isTrue);
      expect(await source.entityOf('habit', 'nope'), isNull);
      expect(await source.entityOf('planner', 'x'), isNull);
    });

    test('quit trackers, filter options and the pending outbox', () async {
      expect((await source.watchQuitTrackers().first).map((e) => e.id), ['h2']);
      expect((await source.categoryOptions()).map((c) => c.name), unorderedEquals(['Work', 'Sleep']));
      expect((await source.tagOptions()).single.name, 'deep');
      expect(await source.pendingOutbox(), 0);
    });
  });

  test('query plans: the large tables are searched through indexes, never scanned', () async {
    final recorder = _SelectRecorder();
    final traced = StatsHarness.create(now: DateTime.utc(2026, 9, 22, 9), interceptor: recorder);
    addTearDown(traced.dispose);
    await traced.seedTables(tables());
    final s = traced.read(statsDataSourceProvider);
    recorder.statements.clear();
    await s.loadPlanner(to: LocalDate(2026, 10, 31));
    await s.loadPlanner(seriesId: 's1');
    await s.loadPlanner(taskId: 't1');
    await s.loadChecklists(checklistId: 'l1');
    await s.loadHabits(habitId: 'h1', withNotifications: true, notificationsSince: DateTime.utc(2026, 9));
    await s.loadHabits();
    const large = ['tasks', 'task_occurrences', 'time_entries', 'activity_events', 'checklist_items', 'habit_logs', 'notifications'];
    final scans = <String>[];
    final plans = <String>{};
    for (final (sql, args) in [...recorder.statements]) {
      final rows = await traced.db.customSelect('EXPLAIN QUERY PLAN $sql', variables: [for (final a in args) Variable(a)]).get();
      for (final r in rows) {
        final detail = r.read<String>('detail');
        plans.add(detail);
        for (final t in large) {
          if (RegExp('^SCAN $t\\b').hasMatch(detail)) scans.add('$detail  ←  $sql');
        }
      }
    }
    expect(scans, isEmpty, reason: scans.join('\n'));
    expect(plans.any((p) => p.contains('idx_tasks_start')), isTrue);
    expect(plans.any((p) => p.contains('idx_tasks_series')), isTrue);
    expect(plans.any((p) => p.contains('idx_occ_task_key')), isTrue);
    expect(plans.any((p) => p.contains('idx_activity_entity')), isTrue);
    expect(plans.any((p) => p.contains('idx_habit_logs_habit_date')), isTrue);
    expect(plans.any((p) => p.contains('idx_items_checklist')), isTrue);
  });
}
