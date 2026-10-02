import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show LogSource;
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/integrations/application/health_sync_service.dart';
import 'package:everslot/features/integrations/data/health_source.dart';
import 'package:everslot/features/integrations/domain/health_aggregation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

class FakeHealth implements HealthSource {
  bool available = true;
  double steps = 0;
  List<HealthSample> water = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> requestAccess(Set<HealthMetric> metrics) async => true;

  @override
  Future<double?> stepsTotal(DateTime from, DateTime to) async => steps;

  @override
  Future<List<HealthSample>> samples(HealthMetric metric, DateTime from, DateTime to) async =>
      metric == HealthMetric.water ? water : const [];
}

/// T8.2.14: health auto-logging — aggregation, de-duplication and the daily auto log.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime.utc(2026, 9, 22);
  final dayEnd = DateTime.utc(2026, 9, 23);
  DateTime t(int h, [int m = 0, int d = 22]) => DateTime.utc(2026, 9, d, h, m);

  group('HealthAggregation', () {
    test('overlapping sessions from two sources count once; clipped to the day', () {
      final total = HealthAggregation.dayTotal(
        HealthMetric.workout,
        [
          HealthSample(start: t(7), end: t(8)), // phone
          HealthSample(start: t(7, 10), end: t(8, 5)), // watch, overlapping
          HealthSample(start: t(23, 30), end: t(0, 30, 23)), // crosses midnight
        ],
        dayStart: day,
        dayEnd: dayEnd,
      );
      expect(total, 65 + 30);
    });

    test('sleep counts the night ending that day', () {
      final total = HealthAggregation.dayTotal(
        HealthMetric.sleep,
        [
          HealthSample(start: t(23, 0, 21), end: t(6, 30)),
          HealthSample(start: t(14), end: t(14, 30)), // nap
          HealthSample(start: t(22, 0), end: t(23, 0)), // next night: counts for tomorrow
        ],
        dayStart: day,
        dayEnd: dayEnd,
      );
      expect(total, 8);
    });

    test('water: duplicates count once; units follow the habit goal', () {
      final total = HealthAggregation.dayTotal(
        HealthMetric.water,
        [
          HealthSample(id: 'a', start: t(9), end: t(9), value: 0.25),
          HealthSample(id: 'a', start: t(9), end: t(9), value: 0.25),
          HealthSample(id: 'b', start: t(12), end: t(12), value: 0.5),
          HealthSample(id: 'c', start: t(1, 0, 21), end: t(1, 0, 21), value: 1),
        ],
        dayStart: day,
        dayEnd: dayEnd,
      );
      expect(total, 0.75);
      expect(HealthAggregation.inUnit(HealthMetric.water, total, 'ml'), 750);
      expect(HealthAggregation.inUnit(HealthMetric.sleep, 7.5, 'min'), 450);
      expect(HealthAggregation.inUnit(HealthMetric.workout, 90, 'h'), 1.5);
      expect(
        HealthAggregation.dayTotal(HealthMetric.steps, const [], dayStart: day, dayEnd: dayEnd, stepsTotal: 9876),
        9876,
      );
    });

    test('settings keep the link through JSON', () {
      const s = HabitSettings(healthMetric: HealthMetric.steps);
      expect(HabitSettings.fromJson(s.toJson()).healthMetric, HealthMetric.steps);
      expect(HabitSettings.fromJson(HabitSettings.defaults.toJson()).healthMetric, isNull);
    });
  });

  group('HealthSyncService', () {
    late TestHarness h;
    late FakeHealth health;
    setUp(() {
      health = FakeHealth();
      h = TestHarness.create(
        now: DateTime.utc(2026, 9, 22, 18),
        overrides: [healthSourceProvider.overrideWithValue(health)],
      );
    });
    tearDown(() => h.dispose());

    Future<void> stepsHabit() => h
        .read(habitServiceProvider)
        .create(
          BuildHabit(
            id: 'walk',
            name: '10 000 steps',
            startDate: LocalDate(2026, 9, 1),
            sortKey: '',
            goal: const HabitTarget(type: HabitGoalType.count, target: 10000, unit: 'steps'),
            schedule: RecurrenceRule(),
            settings: const HabitSettings(healthMetric: HealthMetric.steps),
          ),
        );

    Future<List<double?>> autoValues() async => [
      for (final l in await h.read(habitLogsRepositoryProvider).forHabit('walk'))
        if (l.source == LogSource.auto) l.value,
    ];

    test('one auto log per day, updated in place, idempotent', () async {
      await stepsHabit();
      health.steps = 6400;
      final service = h.read(healthSyncServiceProvider);
      expect(await service.sync(), 2, reason: 'yesterday and today');
      expect(await service.sync(), 0, reason: 'nothing changed');
      health.steps = 10200;
      expect(await service.sync(), 2);
      expect(await autoValues(), [10200, 10200]);
    });

    test('the 10 000 steps habit completes from health data alone', () async {
      await stepsHabit();
      health.steps = 10500;
      await h.read(healthSyncServiceProvider).sync();
      final logs = await h.read(habitLogsRepositoryProvider).forHabit('walk');
      final today = logs.where((l) => l.localDate == LocalDate(2026, 9, 22)).single;
      expect((today.value, today.source), (10500, LogSource.auto));
    });

    test('a deleted auto log stays deleted (the user overrode it)', () async {
      await stepsHabit();
      health.steps = 3000;
      final service = h.read(healthSyncServiceProvider);
      await service.sync();
      final todayLog = (await h.read(habitLogsRepositoryProvider).forHabit('walk'))
          .firstWhere((l) => l.localDate == LocalDate(2026, 9, 22));
      await h.read(habitLogsRepositoryProvider).write((tx) => HabitLogsRepository.deleteInTx(tx, todayLog.id));
      health.steps = 4000;
      await service.sync();
      final today = (await h.read(habitLogsRepositoryProvider).forHabit('walk'))
          .where((l) => l.localDate == LocalDate(2026, 9, 22));
      expect(today, isEmpty);
    });

    test('nothing happens without health data or linked habits', () async {
      expect(await h.read(healthSyncServiceProvider).sync(), 0);
      await stepsHabit();
      health.available = false;
      expect(await h.read(healthSyncServiceProvider).sync(), 0);
    });
  });
}
