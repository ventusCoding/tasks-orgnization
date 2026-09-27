import 'dart:convert';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/planner/application/planner_notifications.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';

/// Planner ↔ notifications integration (features/notifications/README.md §2, §3, §5).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late InMemoryLocalNotificationsPort port;

  // Tuesday 2026-09-22 06:00 UTC = 08:00 in Paris.
  setUp(() async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6), zone: 'Europe/Paris');
    port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
    await seedNotificationDefaults(h.read);
  });
  tearDown(() => h.dispose());

  PlannerNotificationSource source() =>
      h.read(notificationTargetSourcesProvider).whereType<PlannerNotificationSource>().single;
  Future<void> replan() => h.read(notificationPipelineProvider).run('test');

  test('the source and the handler are registered statically', () {
    expect(source().section, 'planner');
    expect(
      findActionHandler(h.read(notificationActionHandlersProvider), 'done', NotificationTargetType.task),
      isA<PlannerNotificationActions>(),
    );
  });

  test('targets: one per occurrence in the window with anchors, guard, variables and actions', () async {
    final gym = await h.createTask(title: 'Gym', start: '2026-09-21T10:00', duration: 60, rule: RecurrenceRule());
    final ny = await h.createTask(title: 'NY call', start: '2026-09-22T09:00', duration: 30, zone: 'America/New_York');
    await h.createTask(title: 'Later', start: '2026-10-30T09:00');
    final targets = await source().targetsBetween(DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 23, 6));
    final gymToday = targets.firstWhere((t) => t.id == gym && t.occurrenceKey == '2026-09-22T10:00');
    expect(gymToday.type, NotificationTargetType.task);
    expect(gymToday.section, NotificationSection.planner);
    expect(gymToday.title, 'Gym');
    expect(gymToday.start, DateTime.utc(2026, 9, 22, 8), reason: 'floating 10:00 in Paris');
    expect(gymToday.end, DateTime.utc(2026, 9, 22, 9));
    expect(gymToday.itemKind, ItemKind.timed);
    expect(gymToday.timeZone, isNull);
    expect(gymToday.status, 'scheduled');
    expect(gymToday.isOpen, isTrue);
    expect(gymToday.guard, NotificationGuard.taskOccurrenceOpen(gym, '2026-09-22T10:00'));
    expect(gymToday.defaultActions, ['done', 'snooze', 'skip']);
    expect(targets.where((t) => t.id == gym).map((t) => t.occurrenceKey), ['2026-09-22T10:00']);
    final call = targets.firstWhere((t) => t.id == ny);
    expect(call.start, DateTime.utc(2026, 9, 22, 13), reason: 'fixed 09:00 in New York');
    expect(call.timeZone, 'America/New_York');
    expect(targets.map((t) => t.title), isNot(contains('Later')));
  });

  test('done/skipped occurrences are returned closed; cancelled ones too', () async {
    final id = await h.createTask(title: 'Walk', start: '2026-09-21T18:00', duration: 30, rule: RecurrenceRule());
    await h.occurrences.markDone(id, '2026-09-22T18:00');
    await h.occurrences.cancel(id, '2026-09-23T18:00');
    final targets = await source().targetsBetween(DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 24, 6));
    final byKey = {for (final t in targets.where((t) => t.id == id)) t.occurrenceKey: t};
    expect(byKey['2026-09-22T18:00']!.isOpen, isFalse);
    expect(byKey['2026-09-22T18:00']!.status, 'done');
    expect(byKey['2026-09-23T18:00'], isNull, reason: 'cancelled occurrences are not resolved');
  });

  test('seeded defaults schedule 10 min before and at start with planner actions', () async {
    final id = await h.createTask(title: 'Standup', start: '2026-09-22T09:30', duration: 15);
    await replan();
    final scheduled = port.scheduled.values.toList()..sort((a, b) => a.fireAt!.compareTo(b.fireAt!));
    expect(scheduled.map((r) => r.fireAt), [DateTime.utc(2026, 9, 22, 7, 20), DateTime.utc(2026, 9, 22, 7, 30)]);
    expect(scheduled.first.actions.map((a) => a.id), ['start', 'snooze', 'skip']);
    expect(scheduled.last.actions.map((a) => a.id), ['done', 'snooze', 'skip']);
    final payload = jsonDecode(scheduled.last.payload) as Map<String, Object?>;
    expect(payload['link'], '/task/$id?occ=2026-09-22T09%3A30');
  });

  test('Done from the notification writes through the planner (cause=notification); guard closes', () async {
    final id = await h.createTask(title: 'Standup', start: '2026-09-22T09:30', duration: 15);
    await replan();
    final atStart = port.scheduled.values.firstWhere((r) => r.fireAt == DateTime.utc(2026, 9, 22, 7, 30));
    h.clock.set(DateTime.utc(2026, 9, 22, 7, 31));
    final dispatcher = h.read(notificationActionDispatcherProvider);
    final response = OsResponse(id: atStart.id, actionId: 'done', payload: atStart.payload);
    await dispatcher.handleResponse(response);
    expect((await dispatcher.handleResponse(response)).duplicate, isTrue);
    final record = (await h.records(id)).single;
    expect(record.id, Ids.taskOccurrence(id, '2026-09-22T09:30'));
    expect(record.status, OccurrenceStatus.done);
    final event = (await h.events(type: 'completed')).single;
    expect(event.payload['source'], 'notification');
    expect(event.payload['cause'], 'notification');
    final target = NotificationTarget(
      type: NotificationTargetType.task,
      id: id,
      section: NotificationSection.planner,
      title: '',
      occurrenceKey: '2026-09-22T09:30',
    );
    expect(await source().guardOpen(target), isFalse);
  });

  test('handler: skip, start (timer), stop, idempotency and gone targets', () async {
    final handler = findActionHandler(h.read(notificationActionHandlersProvider), 'done', NotificationTargetType.task)!;
    final walk = await h.createTask(title: 'Walk', start: '2026-09-22T12:00', duration: 30, rule: RecurrenceRule());
    final work = await h.createTask(title: 'Deep work', start: '2026-09-22T09:00', mode: TrackingMode.timer);
    NotificationActionContext ctx(String action, String id, String? key) => NotificationActionContext(
      actionId: action,
      payload: NotificationPayload(
        dedupeKey: 'test|$action|$id|$key',
        targetType: NotificationTargetType.task,
        targetId: id,
        occurrenceKey: key,
      ),
      origin: ActionOrigin.systemBackground,
      now: h.clock.nowUtc(),
      read: h.read,
    );

    expect((await handler.handle(ctx('skip', walk, '2026-09-22T12:00'))).success, isTrue);
    expect((await h.records(walk)).single.status, OccurrenceStatus.skipped);
    expect((await handler.handle(ctx('skip', walk, '2026-09-22T12:00'))).success, isTrue, reason: 'idempotent');
    expect(await h.events(type: 'skipped'), hasLength(1));

    // One-off timer task: the key is derived from its start when the payload has none.
    final started = await handler.handle(ctx('start', work, null));
    expect(started.success, isTrue);
    expect(started.markActed, isFalse, reason: 'starting keeps the end reminders armed');
    expect((await h.records(work)).single.status, OccurrenceStatus.inProgress);
    await handler.handle(ctx('start', work, null));
    expect(await h.read(plannerQueriesProvider).watchRunningEntries().first, hasLength(1));
    h.clock.advance(const Duration(minutes: 40));
    await handler.handle(ctx('stop', work, null));
    final done = (await h.records(work)).single;
    expect(done.status, OccurrenceStatus.done);
    expect(done.trackedSeconds, 40 * 60);

    final closed = await handler.handle(ctx('start', walk, '2026-09-22T12:00'));
    expect(closed.success, isFalse);
    expect(closed.message, 'Already done or skipped');

    await h.tasks.delete(walk);
    final gone = await handler.handle(ctx('done', walk, '2026-09-23T12:00'));
    expect(gone.success, isFalse);
    expect(gone.message, 'This task no longer exists');
  });

  test('guard: paused series and deleted tasks are closed; open occurrences stay open', () async {
    final id = await h.createTask(title: 'Read', start: '2026-09-21T21:00', duration: 30, rule: RecurrenceRule());
    NotificationTarget t(String key) => NotificationTarget(
      type: NotificationTargetType.task,
      id: id,
      section: NotificationSection.planner,
      title: '',
      occurrenceKey: key,
    );
    expect(await source().guardOpen(t('2026-09-22T21:00')), isTrue);
    await h.tasks.pauseSeries(id);
    expect(await source().guardOpen(t('2026-09-22T21:00')), isFalse);
    await h.tasks.resumeSeries(id);
    expect(await source().guardOpen(t('2026-09-22T21:00')), isTrue);
    await h.tasks.delete(id);
    expect(await source().guardOpen(t('2026-09-22T21:00')), isFalse);
  });
}
