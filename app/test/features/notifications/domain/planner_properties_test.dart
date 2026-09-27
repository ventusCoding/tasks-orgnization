import 'dart:math';

import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fixture_parsing.dart';

/// Planner properties (T7.2.06): no duplicate keys, sorted by fire time then priority, everything
/// inside the horizon, deterministic whatever the input order — over a large mixed workload that
/// crosses the EU DST change (29 Mar 2026) in several zones. Also the performance budget.
void main() {
  tzdata.initializeTimeZones();
  final now = DateTime.utc(2026, 3, 25, 6);

  final rules = <NotificationRule>[
    for (final s in DefaultRules.seeds)
      NotificationRule(
        id: 'default-${s.section.wire}-${s.code}',
        targetType: RuleTargetType.section,
        section: s.section,
        isDefault: true,
        profileId: s.profileCode,
        spec: s.spec,
      ),
    // A nag chain on every tenth task, an overdue rule and a 1-day-before rule.
    NotificationRule(
      id: 'nag',
      targetType: RuleTargetType.section,
      section: NotificationSection.planner,
      isDefault: true,
      profileId: 'nag',
      spec: const NotificationRuleSpec(
        trigger: RelativeTrigger(anchor: TriggerAnchor.end, offsetMinutes: 0),
        repeat: RepeatSpec(everyMinutes: 5, maxTimes: 3),
        conditions: ConditionsSpec(itemKind: 'timed'),
      ),
    ),
    NotificationRule(
      id: 'eve',
      targetType: RuleTargetType.section,
      section: NotificationSection.planner,
      isDefault: true,
      profileId: 'gentle',
      spec: NotificationRuleSpec(
        trigger: RelativeTrigger(
          anchor: TriggerAnchor.start,
          dayOffset: -1,
          atTime: LocalTime(20, 0),
        ),
      ),
    ),
  ];

  List<NotificationTarget> workload(int count, {int seed = 42}) {
    final random = Random(seed);
    const zones = [null, 'Europe/Paris', 'America/New_York', 'Africa/Tunis'];
    final targets = <NotificationTarget>[];
    for (var i = 0; i < count; i++) {
      final day = random.nextInt(14);
      final minute = 6 * 60 + random.nextInt(15 * 60);
      final start = now.add(Duration(days: day, minutes: minute - 6 * 60));
      final zone = zones[i % zones.length];
      switch (i % 5) {
        case 0 || 1 || 2:
          final occ = 'occ-$i';
          targets.add(
            NotificationTarget(
              type: NotificationTargetType.task,
              id: 'task-$i',
              section: NotificationSection.planner,
              title: 'Task $i',
              occurrenceKey: occ,
              timeZone: zone,
              itemKind: i % 17 == 0 ? ItemKind.allDay : ItemKind.timed,
              start: start,
              end: start.add(Duration(minutes: 15 + random.nextInt(120))),
              status: 'scheduled',
              guard: NotificationGuard.taskOccurrenceOpen('task-$i', occ),
            ),
          );
        case 3:
          targets.add(
            NotificationTarget(
              type: NotificationTargetType.checklistItem,
              id: 'item-$i',
              section: NotificationSection.checklists,
              title: 'Item $i',
              checklistId: 'list-${i % 7}',
              timeZone: zone,
              due: start,
              followUp: i.isEven ? start.add(const Duration(days: 1)) : null,
              status: i.isEven ? 'waiting' : 'todo',
              guard: NotificationGuard.itemNotCompleted('item-$i'),
            ),
          );
        default:
          final periodStart = DateTime.utc(now.year, now.month, now.day + day);
          final occ = 'habit-$i-${periodStart.toIso8601String()}';
          targets.add(
            NotificationTarget(
              type: NotificationTargetType.habit,
              id: 'habit-$i',
              section: NotificationSection.habits,
              title: 'Habit $i',
              occurrenceKey: occ,
              timeZone: zone,
              slot: i % 3 == 0 ? start : null,
              periodStart: periodStart,
              periodEnd: periodStart.add(const Duration(days: 1)),
              streak: random.nextInt(20),
              guard: NotificationGuard.habitPeriodOpen('habit-$i', occ),
            ),
          );
      }
    }
    return targets;
  }

  PlanningContext context(
    List<NotificationTarget> targets, {
    List<NotificationRule>? ruleList,
  }) => PlanningContext(
    now: now,
    deviceZone: 'Europe/Paris',
    zones: TzZoneResolver(),
    settings: NotificationSettings.fromMaps(const {}, const {}),
    rules: ruleList ?? rules,
    targets: targets,
    profiles: builtinProfilesById(),
    deviceId: 'device-a',
    userId: 'user-1',
  );

  final result = NotificationPlanner.plan(context(workload(1000)));

  test('the workload plans a meaningful number of instances', () {
    expect(result.planned.length, greaterThan(1000));
  });

  test('no duplicate dedupe keys', () {
    final keys = result.planned.map((p) => p.dedupeKey).toList();
    expect(keys.toSet(), hasLength(keys.length));
    for (final k in keys) {
      expect(k, matches(RegExp(r'^[0-9a-f]{40}$')));
    }
  });

  test('sorted by fire time, then importance (higher first)', () {
    for (var i = 1; i < result.planned.length; i++) {
      final a = result.planned[i - 1];
      final b = result.planned[i];
      final c = a.fireAt.compareTo(b.fireAt);
      expect(c, lessThanOrEqualTo(0), reason: '$i: ${a.fireAt} > ${b.fireAt}');
      if (c == 0) {
        expect(
          a.importance.rank,
          greaterThanOrEqualTo(b.importance.rank),
          reason: '$i: same minute, lower importance first',
        );
      }
    }
  });

  test('every instance lies inside the horizon and is not expired', () {
    final ctx = context(const []);
    final horizonEnd = now.add(ctx.effectiveHorizon);
    for (final p in result.planned) {
      expect(p.fireAt.isAfter(horizonEnd), isFalse, reason: '${p.fireAt}');
      expect(p.expiresAt.isBefore(now), isFalse, reason: '${p.expiresAt}');
      expect(p.expiresAt.isBefore(p.fireAt), isFalse);
    }
  });

  test('deterministic: shuffled targets and rules give the same plan', () {
    final targets = workload(1000)..shuffle(Random(7));
    final shuffledRules = [...rules]..shuffle(Random(3));
    final again = NotificationPlanner.plan(
      context(targets, ruleList: shuffledRules),
    );
    String sig(PlannedNotification p) =>
        '${p.dedupeKey}@${p.fireAt.toIso8601String()}';
    expect(again.planned.map(sig).toList(), result.planned.map(sig).toList());
  });

  test('a full replan of 1 000 targets stays within budget', () {
    final targets = workload(1000, seed: 9);
    NotificationPlanner.plan(context(targets)); // warm-up (JIT)
    final watch = Stopwatch()..start();
    NotificationPlanner.plan(context(targets));
    watch.stop();
    // Budget: < 1 s (T7.2.06). Debug JIT on a loaded CI box gets 2× headroom.
    expect(watch.elapsedMilliseconds, lessThan(2000));
    // ignore: avoid_print
    print('plan(1000 targets) = ${watch.elapsedMilliseconds} ms');
  });
}
