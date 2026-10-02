import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
import 'package:everslot/features/planner/application/timer_surface_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart' show TrackingMode;
import 'package:everslot/features/planner/domain/timer_surface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../../today/today_test_support.dart';

class FakeSurface implements TimerSurfacePort {
  final log = <String>[];

  @override
  Future<void> show(TimerSurface surface) async => log.add('show ${surface.title} +${surface.others}');

  @override
  Future<void> clear() async => log.add('clear');
}

/// T8.2.10: running timer on the lock screen — state mapping and lifecycle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime.utc(2026, 9, 22, 9);

  test('surface: the latest timer leads, others are counted, nothing → null', () {
    expect(TimerSurface.of(const []), isNull);
    final s = TimerSurface.of([
      RunningTimerInfo(taskId: 'a', occurrenceKey: 'k1', title: 'Write', startedAt: t0),
      RunningTimerInfo(
        taskId: 'b',
        occurrenceKey: 'k2',
        title: 'Call',
        startedAt: t0.add(const Duration(minutes: 5)),
        plannedEnd: t0.add(const Duration(hours: 1)),
      ),
    ])!;
    expect((s.taskId, s.title, s.others), ('b', 'Call', 1));
    expect(s.isOver(t0.add(const Duration(minutes: 59))), isFalse);
    expect(s.isOver(t0.add(const Duration(hours: 1))), isTrue);
    expect(s.dedupeKey, 'timer|b|k2');
  });

  group('Android notification', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: t0));
    tearDown(() => h.dispose());

    test('ongoing, silent, chronometer from the session start, Stop / Done routed to the task', () {
      final surface = NotificationTimerSurface(
        InMemoryLocalNotificationsPort(),
        h.read(plannerL10nProvider),
        (_) => '10:00',
        'user-1',
      );
      final s = TimerSurface(
        taskId: 't',
        occurrenceKey: '2026-09-22T09:00',
        title: 'Deep work',
        startedAt: t0,
        plannedEnd: t0.add(const Duration(hours: 1)),
        others: 1,
      );
      final r = surface.request(s, t0.add(const Duration(minutes: 10)), endLabel: '10:00');
      expect((r.sticky, r.silent, r.chronometerFrom), (true, true, t0));
      expect(r.title, 'Deep work (+1)');
      expect(r.body, 'Planned until 10:00');
      expect(r.actions.map((a) => a.id), [NotificationActionIds.stop, NotificationActionIds.done]);
      final p = NotificationPayload.tryDecode(r.payload)!;
      expect(
        (p.targetType, p.targetId, p.occurrenceKey, p.userId),
        (NotificationTargetType.task, 't', '2026-09-22T09:00', 'user-1'),
      );
      expect(surface.request(s, t0.add(const Duration(hours: 2))).body, 'Over the planned time');
    });

    test('hide notification content: generic title, no times (T8.3.10)', () {
      final l10n = h.read(plannerL10nProvider);
      final surface = NotificationTimerSurface(
        InMemoryLocalNotificationsPort(),
        l10n,
        (_) => '10:00',
        'user-1',
        hideContent: () => true,
      );
      final s = TimerSurface(
        taskId: 't',
        occurrenceKey: '2026-09-22T09:00',
        title: 'Therapy session',
        startedAt: t0,
        plannedEnd: t0.add(const Duration(hours: 1)),
      );
      final r = surface.request(s, t0.add(const Duration(minutes: 10)), endLabel: '10:00');
      expect(r.title, 'Reminder from Everslot');
      expect(r.body, isNull);
      expect(r.chronometerFrom, t0, reason: 'the running time stays visible');
      expect(LiveActivityTimerSurface.data(s, l10n, hideContent: true)['title'], 'Reminder from Everslot');
    });

    test('Live Activity data carries the stop link and instants in seconds', () {
      final data = LiveActivityTimerSurface.data(
        TimerSurface(taskId: 't', occurrenceKey: '2026-09-22T09:00', title: 'Run', startedAt: t0),
        h.read(plannerL10nProvider),
      );
      expect(data['startedAt'], t0.millisecondsSinceEpoch / 1000);
      expect(data['plannedEnd'], 0);
      expect(data['stopLink'], 'everslot://do/timer-stop?task=t&occ=2026-09-22T09%3A00');
    });
  });

  test('service: start shows, a title change updates, stop clears', () async {
    final h = TestHarness.create(now: t0);
    addTearDown(h.dispose);
    final fake = FakeSurface();
    final service = TimerSurfaceService(h.container.read, fake);
    final taskId = await h.task('Deep work', start: at(2026, 9, 22, 9), mode: TrackingMode.timer);
    await h.read(occurrencesRepositoryProvider).start(taskId, '2026-09-22T09:00');
    final running = await until(h.container, runningTimersProvider, (v) => (v.value ?? const []).isNotEmpty);
    await service.update(running.value!);
    await service.update(running.value!); // unchanged → no second show
    await h.read(occurrencesRepositoryProvider).stop(taskId, '2026-09-22T09:00');
    final stopped = await until(h.container, runningTimersProvider, (v) => v.value?.isEmpty ?? false);
    await service.update(stopped.value!);
    expect(fake.log, ['show Deep work +0', 'clear']);
  });
}
