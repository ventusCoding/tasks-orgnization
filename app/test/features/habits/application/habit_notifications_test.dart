import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_notifications.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness h;
  // Tuesday 2026-09-22, 06:00 UTC = 08:00 in Paris.
  setUp(() async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6), zone: 'Europe/Paris');
    await seedNotificationDefaults(h.read);
  });
  tearDown(() => h.dispose());

  Future<BuildHabit> createBuild({
    String name = 'Meditate',
    HabitTarget goal = const HabitTarget.check(),
    SchedulePreset preset = const SchedulePreset.daily(),
  }) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, 1),
      sortKey: '',
      goal: goal,
      schedule: preset.toRule(weekStart: Weekday.monday),
    );
    await h.read(habitsRepositoryProvider).create(habit);
    return habit;
  }

  Future<QuitHabit> createQuit({QuitMode mode = QuitMode.abstain}) async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: 'Stop smoking',
      startDate: d(2026, 9, 21),
      sortKey: '',
      mode: mode,
      quitStartedAt: DateTime.utc(2026, 9, 21, 20),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 24,
      dailyLimit: mode == QuitMode.reduce ? 5 : null,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
      unit: HabitUnits.cigarettes,
    );
    await h.read(habitsRepositoryProvider).create(tracker);
    return tracker;
  }

  HabitsNotificationSource habitsSource() =>
      h.read(notificationTargetSourcesProvider).whereType<HabitsNotificationSource>().single;
  QuitNotificationSource quitSource() =>
      h.read(notificationTargetSourcesProvider).whereType<QuitNotificationSource>().single;

  NotificationActionContext ctx(String action, String id, {String? key, String? input}) => NotificationActionContext(
    actionId: action,
    payload: NotificationPayload(
      dedupeKey: 'k-$id-$key-$action',
      targetType: NotificationTargetType.habit,
      targetId: id,
      occurrenceKey: key,
    ),
    origin: ActionOrigin.systemBackground,
    now: h.clock.nowUtc(),
    input: input,
    read: h.container.read,
  );

  HabitNotificationActions handler() =>
      h.read(notificationActionHandlersProvider).whereType<HabitNotificationActions>().single;

  test('sources and the handler are registered statically (background isolate sees them)', () {
    expect(habitsSource().section, 'habits');
    expect(quitSource().section, 'quit');
    for (final action in ['done', 'skip', 'log_value', 'log_craving']) {
      expect(
        findActionHandler(h.read(notificationActionHandlersProvider), action, NotificationTargetType.habit),
        isA<HabitNotificationActions>(),
      );
    }
  });

  group('habit targets', () {
    test('one target per due day with guard, streak, variables and default actions', () async {
      final habit = await createBuild(
        name: 'Push-ups',
        goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: HabitUnits.reps),
      );
      final targets = await habitsSource().targetsBetween(DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 24, 6));
      expect(targets.map((t) => t.occurrenceKey), ['2026-09-22', '2026-09-23', '2026-09-24']);
      final today = targets.first;
      expect(today.type, NotificationTargetType.habit);
      expect(today.section, NotificationSection.habits);
      expect(today.title, 'Push-ups');
      expect(today.isOpen, isTrue);
      expect(today.status, 'pending');
      expect(today.slot, isNull, reason: "untimed habits use the rules' date-only time");
      expect(today.periodStart, DateTime.utc(2026, 9, 21, 22), reason: 'midnight in Paris');
      expect(
        today.guard,
        NotificationGuard.habitPeriodOpen(habit.id, '2026-09-22', goalType: 'count', target: 15, op: 'gte'),
      );
      expect(today.variables['target'], '15');
      expect(today.variables['unit'], 'reps');
      expect(today.variables['logged_today'], '0');
      expect(today.defaultActions, ['log_value', 'done', 'skip']);
      expect(today.deepLink, '/habits/${habit.id}');
    });

    test('done, skipped and paused periods come back closed', () async {
      final habit = await createBuild();
      final checkIn = h.read(checkInServiceProvider);
      await checkIn.markDone(habit, '2026-09-22');
      await checkIn.skip(habit, '2026-09-23');
      await h.read(habitServiceProvider).pause(habitId: habit.id, start: d(2026, 9, 24), end: d(2026, 9, 24));
      final targets = await habitsSource().targetsBetween(DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 25, 6));
      final byKey = {for (final t in targets) t.occurrenceKey: t};
      expect((byKey['2026-09-22']!.isOpen, byKey['2026-09-22']!.status), (false, 'done'));
      expect((byKey['2026-09-23']!.isOpen, byKey['2026-09-23']!.status), (false, 'skipped'));
      expect((byKey['2026-09-24']!.isOpen, byKey['2026-09-24']!.status), (false, 'paused'));
      expect(byKey['2026-09-25']!.isOpen, isTrue);
      expect(await habitsSource().guardOpen(byKey['2026-09-22']!), isFalse);
      expect(await habitsSource().guardOpen(byKey['2026-09-25']!), isTrue);
    });

    test('slot habits get one timed target per slot at the slot time (Paris)', () async {
      await createBuild(
        name: 'Medication',
        preset: SchedulePreset(SchedulePresetKind.specificTimes, times: [LocalTime(8, 0), LocalTime(20, 0)]),
      );
      final targets = await habitsSource().targetsBetween(DateTime.utc(2026, 9, 22, 5), DateTime.utc(2026, 9, 22, 21));
      expect(targets.map((t) => t.occurrenceKey), ['2026-09-22T08:00', '2026-09-22T20:00']);
      expect(targets.map((t) => t.slot), [DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 22, 18)]);
      expect(targets.first.itemKind, ItemKind.timed);
    });

    test('quota habits notify on eligible days with their progress', () async {
      await createBuild(name: 'Gym', preset: const SchedulePreset(SchedulePresetKind.timesPerWeek, n: 3));
      final targets = await habitsSource().targetsBetween(DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 27, 6));
      expect(targets.map((t) => t.occurrenceKey), [for (var day = 22; day <= 27; day++) '2026-09-$day']);
      final quota = targets.first.quota!;
      expect((quota.done, quota.target, quota.eligibleDaysLeft), (0, 3, 6));
      expect(targets.last.quota!.behind, isTrue, reason: '3 still needed with 1 eligible day left');
      expect(targets.first.guard!.params.containsKey('target'), isFalse, reason: 'quota totals are not per day');
    });
  });

  test('seeded defaults schedule the untimed reminder at 09:00 local with habit actions', () async {
    await createBuild();
    await h.read(notificationPipelineProvider).run('test');
    final port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
    final today = port.scheduled.values.where((r) => r.fireAt == DateTime.utc(2026, 9, 22, 7)).toList();
    expect(today, isNotEmpty, reason: '09:00 in Paris');
    expect(today.first.actions.map((a) => a.id), containsAll(['done', 'skip']));
  });

  group('actions', () {
    test('done checks in with source = notification; repeats converge; guard closes', () async {
      final habit = await createBuild();
      final done = await handler().handle(ctx('done', habit.id, key: '2026-09-22'));
      expect(done.success, isTrue);
      await handler().handle(ctx('done', habit.id, key: '2026-09-22'));
      final logs = await h.read(habitLogsRepositoryProvider).forHabit(habit.id);
      expect(logs.single.kind, HabitLogKind.done);
      expect(logs.single.source, 'notification');
    });

    test(
      'log value: typed numbers (incl. Arabic-Indic, decimal comma), empty = one increment, invalid fails',
      () async {
        final habit = await createBuild(
          name: 'Water',
          goal: const HabitTarget(type: HabitGoalType.count, target: 8, unit: HabitUnits.glasses),
        );
        expect((await handler().handle(ctx('log_value', habit.id, key: '2026-09-22', input: '2'))).success, isTrue);
        expect((await handler().handle(ctx('log_value', habit.id, key: '2026-09-22', input: ''))).success, isTrue);
        final invalid = await handler().handle(ctx('log_value', habit.id, key: '2026-09-22', input: '12a'));
        expect(invalid.success, isFalse);
        expect(invalid.message, "“12a” isn't a number — open the app to log it.");
        final values = [
          for (final l in await h.read(habitLogsRepositoryProvider).forHabit(habit.id)) (l.kind, l.value, l.source),
        ];
        expect(values, [(HabitLogKind.progress, 2.0, 'notification'), (HabitLogKind.progress, 1.0, 'notification')]);
      },
    );

    test('skip, future guards and gone habits', () async {
      final habit = await createBuild();
      expect((await handler().handle(ctx('skip', habit.id, key: '2026-09-23'))).success, isTrue);
      final future = await handler().handle(ctx('done', habit.id, key: '2026-09-25'));
      expect(future.success, isFalse, reason: 'no check-in for future days');
      await h.read(habitsRepositoryProvider).delete(habit.id);
      final gone = await handler().handle(ctx('done', habit.id, key: '2026-09-22'));
      expect((gone.success, gone.message), (false, 'This habit no longer exists.'));
    });

    test('quit: craving with a typed intensity, "I resisted" marks it, invalid intensity fails', () async {
      final tracker = await createQuit();
      expect((await handler().handle(ctx('log_craving', tracker.id, input: '٧'))).success, isTrue);
      final invalid = await handler().handle(ctx('log_craving', tracker.id, input: '11'));
      expect((invalid.success, invalid.message), (false, 'Intensity is a number from 1 to 10.'));
      h.clock.advance(const Duration(minutes: 5));
      expect((await handler().handle(ctx('done', tracker.id))).success, isTrue);
      final craving = (await h.read(habitLogsRepositoryProvider).forHabit(tracker.id)).single;
      expect(
        (craving.kind, craving.intensity, craving.resisted, craving.source),
        (HabitLogKind.craving, 7, true, 'notification'),
      );
    });

    test('quit: +1 logs a use in reduce mode; abstain trackers open the kind relapse flow', () async {
      final reduce = await createQuit(mode: QuitMode.reduce);
      expect((await handler().handle(ctx('log_value', reduce.id))).success, isTrue);
      final use = (await h.read(habitLogsRepositoryProvider).forHabit(reduce.id)).single;
      expect((use.kind, use.value), (HabitLogKind.use, 1.0));
      final abstain = await createQuit();
      final open = await handler().handle(ctx('log_value', abstain.id));
      expect(open.openLink, '/quit/${abstain.id}');
      expect(open.markActed, isFalse);
    });
  });

  group('quit targets', () {
    test('milestones project from the current abstinence start; a relapse makes them obsolete', () async {
      final tracker = await createQuit();
      var target = (await quitSource().targetsBetween(
        DateTime.utc(2026, 9, 22, 6),
        DateTime.utc(2026, 9, 29, 6),
      )).single;
      expect(target.section, NotificationSection.quit);
      expect(target.occurrenceKey, isNull);
      expect(target.milestoneBaseline, DateTime.utc(2026, 9, 21, 20));
      expect(target.guard, NotificationGuard.quitNoRelapseSince(tracker.id, DateTime.utc(2026, 9, 21, 20)));
      // 24/day × 0.50 € = 12 €/day: 10 € is reached 20 h after the quit (16:00 UTC on Sept 22).
      final money = target.milestones.where((m) => m.metric == 'money_saved').toList();
      expect(money.first.threshold, 10);
      expect(money.first.at, DateTime.utc(2026, 9, 22, 16));
      expect(money.first.label, '€10.00 saved');
      expect(target.variables['money_saved'], '€5.00');
      expect(await quitSource().guardOpen(target), isTrue);

      await h.read(quitServiceProvider).logRelapse(tracker);
      expect(await quitSource().guardOpen(target), isFalse);
      target = (await quitSource().targetsBetween(DateTime.utc(2026, 9, 22, 6), DateTime.utc(2026, 9, 29, 6))).single;
      expect(target.milestoneBaseline, DateTime.utc(2026, 9, 22, 6));
    });
  });
}
