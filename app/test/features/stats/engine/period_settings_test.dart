// Period model wiring in the app (T6.1.05): the `stats` settings namespace (default period, compare
// mode, week-start override), period keys, and the day boundaries each scope context uses.
import 'package:everslot/features/stats/application/catalog/habit_catalog.dart';
import 'package:everslot/features/stats/application/catalog/planner_catalog.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_request.dart';
import 'package:everslot/features/stats/domain/stats_settings.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../support/stats_harness.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

StatsJob job(
  MetricScope scope, {
  required DateTime now,
  StatsPeriod period = const StatsPeriod.thisWeek(),
  String zone = 'UTC',
  StatsSettings settings = const StatsSettings(),
  Weekday weekStart = Weekday.monday,
  int dayStartMinutes = 0,
}) => StatsJob(
  request: StatsRequest(scope, selection: PeriodSelection(period)),
  env: StatsEnvironment(
    now: now,
    zoneId: zone,
    zones: zone == 'UTC' ? const {} : {zone: tz.getLocation(zone)},
    weekStart: weekStart,
    dayStartMinutes: dayStartMinutes,
    settings: settings,
  ),
  metricIds: const [],
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('stats settings namespace (arch §8.5)', () {
    test('parses default period, compare mode, week-start override and clamps numbers', () {
      final s = StatsSettings.fromMaps(
        stats: {
          'defaultPeriod': 'rolling:30',
          'compareWithPrevious': false,
          'weekStartOverride': 7,
          'graceMinutes': 999,
          'staleThresholdDays': 21,
          'deepWorkMinBlockMinutes': 90,
        },
        planner: {
          'workHours': {'start': '08:30', 'end': '16:00'},
          'workDays': [1, 2, 3, 4],
          'missedGraceMinutes': 30,
        },
      );
      expect(s.defaultPeriod, 'rolling:30');
      expect(s.compareWithPrevious, isFalse);
      expect(s.weekStartOverride, Weekday.sunday);
      expect(s.graceMinutes, 240);
      expect(s.staleDays, 21);
      expect(s.deepWorkMinutes, 90);
      expect((s.workStartMinute, s.workEndMinute), (510, 960));
      expect(s.workDays, {1, 2, 3, 4});
      expect(s.missedGraceMinutes, 30);
    });

    test('invalid values fall back to defaults', () {
      final s = StatsSettings.fromMaps(
        stats: {'defaultPeriod': 3, 'weekStartOverride': 9, 'compareWithPrevious': 'yes'},
        planner: {
          'workHours': {'start': '18:00', 'end': '09:00'},
          'workDays': <int>[],
        },
      );
      expect(s.defaultPeriod, 'thisWeek');
      expect(s.weekStartOverride, isNull);
      expect(s.compareWithPrevious, isTrue);
      expect((s.workStartMinute, s.workEndMinute), (540, 1020));
      expect(s.workDays, {1, 2, 3, 4, 5});
    });
  });

  group('period keys', () {
    test('every period round-trips through its key', () {
      final periods = <StatsPeriod>[
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
        const StatsPeriod.allTime(),
        const StatsPeriod.rolling(28),
        StatsPeriod.custom(d('2026-01-05'), d('2026-02-01')),
      ];
      for (final p in periods) {
        expect(PeriodSelection.parsePeriod(p.key)?.key, p.key, reason: p.key);
      }
      expect(PeriodSelection.parsePeriod('week')?.key, 'thisWeek');
      expect(PeriodSelection.parsePeriod('rolling:0'), isNull);
      expect(PeriodSelection.parsePeriod('custom:2026-01-01'), isNull);
      expect(PeriodSelection.parsePeriod('nonsense'), isNull);
    });

    test('selection keys include compare mode and granularity', () {
      const a = PeriodSelection(StatsPeriod.thisMonth());
      final b = a.copyWith(granularity: Granularity.week);
      expect(a == b, isFalse);
      expect(b.copyWith(clearGranularity: true), a);
      expect(a.copyWith(compare: false).key, isNot(a.key));
    });
  });

  group('scope contexts', () {
    test('thisWeek honours the week-start override (MO / SA / SU)', () {
      final now = DateTime.utc(2026, 9, 23, 12); // Wednesday
      for (final (override, start) in [
        (null, '2026-09-21'),
        (Weekday.saturday, '2026-09-19'),
        (Weekday.sunday, '2026-09-20'),
      ]) {
        final c = PlannerContext(
          job(MetricScope.planner, now: now, settings: StatsSettings(weekStartOverride: override)),
          LocationZoneResolver(const {}),
        );
        expect(c.range.start, d(start), reason: '$override');
        expect(c.range.days, 7);
      }
    });

    test('the profile week start applies when there is no override', () {
      final c = PlannerContext(
        job(MetricScope.planner, now: DateTime.utc(2026, 9, 23, 12), weekStart: Weekday.sunday),
        LocationZoneResolver(const {}),
      );
      expect(c.range.start, d('2026-09-20'));
    });

    test('lastMonth on 2026-03-31 is February 2026; to-date comparison while in progress', () {
      final c = PlannerContext(
        job(MetricScope.planner, now: DateTime.utc(2026, 3, 31, 10), period: const StatsPeriod.lastMonth()),
        LocationZoneResolver(const {}),
      );
      expect((c.range.start, c.range.end), (d('2026-02-01'), d('2026-02-28')));
      final w = PlannerContext(
        job(MetricScope.planner, now: DateTime.utc(2026, 9, 23, 10)),
        LocationZoneResolver(const {}),
      );
      // Mon–Wed vs Mon–Wed.
      expect((w.previous.start, w.previous.end), (d('2026-09-14'), d('2026-09-16')));
    });

    test('habit day start 04:00: an event at 01:30 belongs to the previous date; planner uses midnight', () {
      final now = DateTime.utc(2026, 9, 23, 1, 30);
      final habit = HabitContext(job(MetricScope.habit, now: now, dayStartMinutes: 240), LocationZoneResolver(const {}));
      final planner = PlannerContext(job(MetricScope.planner, now: now, dayStartMinutes: 240), LocationZoneResolver(const {}));
      expect(habit.today, d('2026-09-22'));
      expect(planner.today, d('2026-09-23'));
    });

    test('rolling 7 days across a DST change contains exactly 7 local dates (Europe/Paris)', () {
      final c = PlannerContext(
        job(
          MetricScope.planner,
          now: DateTime.utc(2026, 3, 31, 10),
          period: const StatsPeriod.rolling(7),
          zone: 'Europe/Paris',
        ),
        LocationZoneResolver({'Europe/Paris': tz.getLocation('Europe/Paris')}),
      );
      expect(c.range.days, 7);
      expect(c.range.start, d('2026-03-25'));
      final instants = c.instants(c.range);
      // One 23-hour day (29 March) inside the window.
      expect(instants.duration, const Duration(hours: 7 * 24 - 1));
    });
  });

  group('providers', () {
    test('the batch environment reads the week-start override and the default period', () async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9));
      addTearDown(h.dispose);
      await h.seedSettings({
        'stats': {'weekStartOverride': 6, 'defaultPeriod': 'thisMonth', 'compareWithPrevious': false},
      });
      await h.settle();
      final env = h.read(statsComputeServiceProvider).environment();
      expect(env.weekStart, Weekday.saturday);
      final selection = h.read(statsUiStateProvider.notifier).selectionFor('planner', h.read(statsSettingsProvider));
      expect(selection.period.key, 'thisMonth');
      expect(selection.compare, isFalse);
    });

    test('a remembered period wins over the default', () async {
      final h = StatsHarness.create();
      addTearDown(h.dispose);
      await h.settle();
      final ui = h.read(statsUiStateProvider.notifier)..setPeriod('habits', const StatsPeriod.rolling(90));
      expect(ui.selectionFor('habits', h.read(statsSettingsProvider)).period.key, 'rolling:90');
      expect(ui.selectionFor('planner', h.read(statsSettingsProvider)).period.key, 'thisWeek');
    });
  });
}
