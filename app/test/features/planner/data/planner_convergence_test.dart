@Tags(['sync'])
library;

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../../shared/support/fake_sync_server.dart';

/// Two-client convergence of planner writes (T3.2.04 acceptance, T3.1.02 deterministic ids).
void main() {
  late FakeSyncServer server;
  late SyncDevice a;
  late SyncDevice b;

  TestWidgetsFlutterBinding.ensureInitialized(); // lifecycle / device-zone providers
  setUpAll(tzdata.initializeTimeZones);
  setUp(() {
    server = FakeSyncServer();
    a = SyncDevice(server, 'device-a');
    b = SyncDevice(server, 'device-b');
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  Future<void> syncAll() async {
    await a.sync();
    await b.sync();
    await a.sync();
  }

  Future<String> createDaily(SyncDevice d) async {
    final result = await d
        .read(tasksRepositoryProvider)
        .create(
          Task(
            id: '',
            seriesId: '',
            title: 'Stretch',
            startLocal: LocalDateTime.parse('2026-09-20T08:00'),
            durationMinutes: 15,
            recurrence: RecurrenceRule(),
          ),
        );
    return result.taskId;
  }

  const key = '2026-09-22T08:00';

  test('the same occurrence marked done offline on two devices converges to one row', () async {
    final taskId = await createDaily(a);
    await syncAll();
    expect(await b.read(plannerQueriesProvider).task(taskId), isNotNull);

    // Both offline: A marks done, B marks done and rates it.
    await a.read(occurrencesRepositoryProvider).markDone(taskId, key);
    await b.read(occurrencesRepositoryProvider).markDone(taskId, key);
    await b.read(occurrencesRepositoryProvider).rate(taskId, key, 4);
    await syncAll();

    final rows = server.rows('task_occurrences');
    expect(rows, hasLength(1));
    expect(rows.keys.single, Ids.taskOccurrence(taskId, key));
    final onA = (await a.read(plannerQueriesProvider).records([taskId])).single;
    final onB = (await b.read(plannerQueriesProvider).records([taskId])).single;
    expect(onA.id, onB.id);
    expect(onA.status, OccurrenceStatus.done);
    expect(onB.status, OccurrenceStatus.done);
    expect(onA.rating, 4);
    expect(onB.rating, 4);
  });

  test('conflicting outcomes converge to the same state on both devices (per-field LWW)', () async {
    final taskId = await createDaily(a);
    await syncAll();
    await a.read(occurrencesRepositoryProvider).skip(taskId, key, reason: 'sick');
    await b.read(occurrencesRepositoryProvider).markDone(taskId, key);
    await syncAll();

    final onA = (await a.read(plannerQueriesProvider).records([taskId])).single;
    final onB = (await b.read(plannerQueriesProvider).records([taskId])).single;
    expect(server.rows('task_occurrences'), hasLength(1));
    expect(onA.status, onB.status);
    expect(onA.skipReason, onB.skipReason);
    expect(onA.completedAt, onB.completedAt);
  });

  test('a series split on one device and an outcome on the other converge', () async {
    final taskId = await createDaily(a);
    await syncAll();
    await b.read(occurrencesRepositoryProvider).markDone(taskId, key);
    await a.read(tasksRepositoryProvider).rescheduleTask(taskId, start: LocalDateTime.parse('2026-09-20T09:00'));
    await syncAll();
    final tasksA = await a.read(plannerQueriesProvider).seriesTasks(taskId);
    final tasksB = await b.read(plannerQueriesProvider).seriesTasks(taskId);
    expect(tasksA.map((t) => (t.id, t.startLocal)), tasksB.map((t) => (t.id, t.startLocal)));
    expect(
      (await a.read(plannerQueriesProvider).records([taskId])).map((r) => (r.id, r.status)),
      (await b.read(plannerQueriesProvider).records([taskId])).map((r) => (r.id, r.status)),
    );
  });
}
