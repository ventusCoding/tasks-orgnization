import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fixture_parsing.dart';

/// Repeating-trigger optimization (T7.2.10): unconditional daily/weekly reminders occupy one OS
/// slot; anything irregular stays one-shot.
void main() {
  tzdata.initializeTimeZones();
  final zones = TzZoneResolver();
  const paris = 'Europe/Paris';
  // Horizon 14 days across the EU fall-back (25 Oct 2026).
  final now = DateTime.utc(2026, 10, 20, 12);

  Map<String, Object?> daily([String time = '07:00']) => {
    'v': 1,
    'type': 'fixed',
    'freq': 'daily',
    'interval': 1,
    'times': [time],
  };

  NotificationRule scheduleRule(
    Map<String, Object?> recurrence, {
    String id = 'water',
    String targetType = 'checklist_item',
    String targetId = 'i',
    String section = 'checklists',
    Map<String, Object?> conditions = const {},
  }) => ruleFromJson({
    'id': id,
    'targetType': targetType,
    'targetId': targetId,
    'section': section,
    'isDefault': false,
    'spec': {
      'v': 1,
      'trigger': {'type': 'schedule', 'recurrence': recurrence},
      if (conditions.isNotEmpty) 'conditions': conditions,
    },
  });

  NotificationTarget item({String? zone, NotificationGuard? guard}) =>
      NotificationTarget(
        type: NotificationTargetType.checklistItem,
        id: 'i',
        section: NotificationSection.checklists,
        title: 'Water the plants',
        checklistId: 'L',
        notifyMode: NotifyMode.custom,
        timeZone: zone,
        status: 'todo',
        guard: guard ?? NotificationGuard.itemNotCompleted('i'),
      );

  PlanResult plan(
    List<NotificationRule> rules,
    List<NotificationTarget> targets, {
    Map<String, dynamic> settings = const {},
    DateTime? at,
  }) => NotificationPlanner.plan(
    PlanningContext(
      now: at ?? now,
      deviceZone: paris,
      zones: zones,
      settings: NotificationSettings.fromMaps(settings, const {}),
      rules: rules,
      targets: targets,
      profiles: builtinProfilesById(),
      deviceId: 'device-a',
      userId: 'user-1',
    ),
  );

  List<DesiredItem> desired(
    PlanResult result, {
    bool android = false,
    DateTime? at,
  }) {
    final t = at ?? now;
    return ScheduleComputation.desired(
      result.planned,
      budget: android ? ScheduleBudget.android : ScheduleBudget.ios,
      sentinelTitle: 'Open',
      mergedTitle: (n) => '$n',
      repeating: RepeatingOptions(
        zones: zones,
        zone: paris,
        now: t,
        horizonEnd: t.add(const Duration(days: 14)),
        honorsStartDate: android,
      ),
    );
  }

  group('isSimpleRepeating', () {
    test('unbounded daily and weekly fixed-time rules qualify', () {
      expect(NotificationPlanner.isSimpleRepeating(daily()), isTrue);
      expect(
        NotificationPlanner.isSimpleRepeating({
          ...daily(),
          'freq': 'weekly',
          'byWeekday': ['MO', 'WE'],
        }),
        isTrue,
      );
      expect(
        NotificationPlanner.isSimpleRepeating({
          ...daily(),
          'times': ['08:00', '20:00'],
        }),
        isTrue,
      );
    });

    test('bounded, sparse or irregular rules do not', () {
      for (final r in <Map<String, Object?>>[
        {...daily(), 'interval': 2},
        {...daily(), 'until': '2026-12-01T00:00'},
        {...daily(), 'count': 10},
        {
          ...daily(),
          'exdates': ['2026-10-22'],
        },
        {...daily(), 'freq': 'monthly'},
        {
          ...daily(),
          'freq': 'weekly',
          'byWeekday': [
            {'day': 'MO', 'n': 1},
          ],
        },
        {'v': 1, 'type': 'fixed', 'freq': 'daily', 'interval': 1},
      ]) {
        expect(NotificationPlanner.isSimpleRepeating(r), isFalse, reason: '$r');
      }
    });
  });

  group('planner marks repeatable instances', () {
    test('a daily reminder on an item in the device zone', () {
      final result = plan([scheduleRule(daily())], [item()]);
      expect(result.planned, hasLength(14));
      expect(result.planned.every((p) => p.repeatable), isTrue);
    });

    test(
      'never for per-occurrence guards, other zones, nags or policy shifts',
      () {
        final habit = plan(
          [
            scheduleRule(
              daily(),
              targetType: 'habit',
              targetId: 'h',
              section: 'habits',
            ),
          ],
          [
            NotificationTarget(
              type: NotificationTargetType.habit,
              id: 'h',
              section: NotificationSection.habits,
              title: 'Drink water',
              notifyMode: NotifyMode.custom,
              guard: NotificationGuard.habitPeriodOpen('h', 'p'),
            ),
          ],
        );
        expect(habit.planned, isNotEmpty);
        expect(habit.planned.any((p) => p.repeatable), isFalse);

        final newYork = plan(
          [scheduleRule(daily())],
          [item(zone: 'America/New_York')],
        );
        expect(newYork.planned.any((p) => p.repeatable), isFalse);
        final sameZone = plan([scheduleRule(daily())], [item(zone: paris)]);
        expect(sameZone.planned.every((p) => p.repeatable), isTrue);

        // Quiet hours 06:00–08:00 on weekends defer those instances: only they lose it.
        final quiet = plan(
          [scheduleRule(daily())],
          [item()],
          settings: {
            'quietHours': [
              {
                'days': [6, 7],
                'from': '06:00',
                'to': '08:00',
                'mode': 'defer',
              },
            ],
          },
        );
        final deferred = quiet.planned.where((p) => !p.repeatable).toList();
        expect(deferred, isNotEmpty);
        for (final p in deferred) {
          final local = zones.toLocal(p.fireAt, paris);
          expect(local.date.weekday.iso, greaterThanOrEqualTo(6));
        }
      },
    );
  });

  group('sequence detection', () {
    test('a daily 07:00 reminder occupies one iOS slot, across DST', () {
      final items = desired(plan([scheduleRule(daily())], [item()]));
      final os = items.where((d) => d.os).toList();
      expect(os, hasLength(1));
      expect(os.single.kind, ScheduleKind.repeating);
      expect(os.single.repeat, RepeatMatch.daily);
      expect(os.single.members, hasLength(14));
      // Members stay tracked for the inbox / banners; none is lost.
      expect(items.where((d) => d.kind == ScheduleKind.tracked), hasLength(14));
      expect(
        ScheduleComputation.coverageUntil(
          items,
          horizonEnd: now.add(const Duration(days: 14)),
        ),
        now.add(const Duration(days: 14)),
      );
    });

    test('weekly rules give one trigger per weekday', () {
      final items = desired(
        plan(
          [
            scheduleRule({
              ...daily('18:30'),
              'freq': 'weekly',
              'byWeekday': ['MO', 'WE'],
            }),
          ],
          [item()],
        ),
      );
      final os = items.where((d) => d.os).toList();
      expect(os, hasLength(2));
      expect(os.every((d) => d.repeat == RepeatMatch.weekly), isTrue);
      expect(os.map((d) => d.members.length).toSet(), {2});
      expect(os.map((d) => d.key).toSet(), hasLength(2));
    });

    test('two times a day make two daily triggers', () {
      final items = desired(
        plan(
          [
            scheduleRule({
              ...daily(),
              'times': ['08:00', '20:00'],
            }),
          ],
          [item()],
        ),
      );
      expect(items.where((d) => d.os).map((d) => d.repeat).toList(), [
        RepeatMatch.daily,
        RepeatMatch.daily,
      ]);
    });

    test('a gap keeps the affected days as one-shots', () {
      // Weekend quiet hours defer Sat/Sun: weekdays repeat weekly, weekends stay one-shots.
      final items = desired(
        plan(
          [scheduleRule(daily())],
          [item()],
          settings: {
            'quietHours': [
              {
                'days': [6, 7],
                'from': '06:00',
                'to': '08:00',
                'mode': 'defer',
              },
            ],
          },
        ),
      );
      final repeating = items
          .where((d) => d.kind == ScheduleKind.repeating)
          .toList();
      expect(repeating, hasLength(5));
      expect(repeating.every((d) => d.repeat == RepeatMatch.weekly), isTrue);
      final oneShots = items
          .where((d) => d.kind == ScheduleKind.oneShot)
          .toList();
      expect(oneShots, hasLength(4)); // two weekends, deferred to 08:00
    });

    test(
      'iOS needs the first match after now; Android honours a later start',
      () {
        // Starts the day after tomorrow: the iOS trigger would fire tomorrow already.
        final later = plan(
          [
            scheduleRule({...daily(), 'start': '2026-10-22'}),
          ],
          [item()],
        );
        final ios = desired(later);
        // No daily trigger; weekly ones except for Wednesday, whose next match (21 Oct) comes
        // before the start — its instances stay one-shots.
        final weekly = ios
            .where((d) => d.kind == ScheduleKind.repeating)
            .toList();
        expect(weekly.every((d) => d.repeat == RepeatMatch.weekly), isTrue);
        expect(weekly, hasLength(6));
        final oneShots = ios
            .where((d) => d.kind == ScheduleKind.oneShot)
            .toList();
        expect(oneShots, hasLength(1)); // 28 Oct (4 Nov is past the horizon)
        for (final d in oneShots) {
          expect(
            zones.toLocal(d.fireAt, paris).date.weekday,
            Weekday.wednesday,
          );
        }
        expect(
          desired(
            later,
            android: true,
          ).where((d) => d.kind == ScheduleKind.repeating),
          hasLength(1),
        );
      },
    );

    test(
      'nothing repeats without the options or with per-instance content',
      () {
        final result = plan([scheduleRule(daily())], [item()]);
        final plain = ScheduleComputation.desired(
          result.planned,
          budget: ScheduleBudget.ios,
          sentinelTitle: 'Open',
          mergedTitle: (n) => '$n',
        );
        expect(plain.where((d) => d.kind == ScheduleKind.repeating), isEmpty);

        final dated = plan(
          [
            ruleFromJson({
              'id': 'water',
              'targetType': 'checklist_item',
              'targetId': 'i',
              'section': 'checklists',
              'spec': {
                'v': 1,
                'trigger': {'type': 'schedule', 'recurrence': daily()},
                'content': {'title': '{title}', 'body': '{date}'},
              },
            }),
          ],
          [item()],
        );
        expect(
          desired(dated).where((d) => d.kind == ScheduleKind.repeating),
          isEmpty,
        );
      },
    );
  });

  group('diff', () {
    ScheduleEntry stored(DesiredItem d, DateTime at) => ScheduleEntry(
      dedupeKey: d.key,
      platformId: PlatformIds.hash(d.key),
      fireAt: d.fireAt,
      targetKey: d.targetKey,
      kind: d.kind,
      os: d.os,
      hash: d.hash,
      scheduledAt: at,
      repeating: d.kind == ScheduleKind.repeating,
    );

    test('the next day keeps the trigger without platform calls', () {
      final today = desired(plan([scheduleRule(daily())], [item()]));
      final current = [for (final d in today) stored(d, now)];
      final tomorrow = now.add(const Duration(days: 1));
      final next = desired(
        plan([scheduleRule(daily())], [item()], at: tomorrow),
        at: tomorrow,
      );
      final diff = ScheduleComputation.diff(current, next, tomorrow);
      expect(diff.platformCalls, 0);
      expect(diff.cancel, isEmpty);
    });

    test('a removed rule cancels its trigger even after the first firing', () {
      final today = desired(plan([scheduleRule(daily())], [item()]));
      final current = [for (final d in today) stored(d, now)];
      final later = now.add(const Duration(days: 3));
      final diff = ScheduleComputation.diff(current, const [], later);
      expect(diff.cancel.map((e) => e.kind), contains(ScheduleKind.repeating));
    });
  });
}
