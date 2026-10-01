import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Noise guard (T7.1.04): fires/day over a window from the SAME planner path as scheduling.
void main() {
  tzdata.initializeTimeZones();
  final now = DateTime.utc(2026, 9, 22, 0, 30);
  const target = NotificationTarget(
    type: NotificationTargetType.checklistItem,
    id: 'water',
    section: NotificationSection.checklists,
    title: 'Water',
    notifyMode: NotifyMode.custom,
  );

  NotificationRule schedule(Map<String, Object?> recurrence, {RepeatSpec? repeat}) => NotificationRule(
    id: 'r',
    targetType: RuleTargetType.checklistItem,
    targetId: 'water',
    section: NotificationSection.checklists,
    spec: NotificationRuleSpec(
      trigger: ScheduleTrigger(recurrence: {'v': 1, 'type': 'fixed', 'interval': 1, ...recurrence}),
      repeat: repeat,
    ),
  );

  NoiseEstimate estimate(
    NotificationRule rule, {
    Duration window = const Duration(days: 1),
    List<DateTime> others = const [],
  }) {
    final ctx = PlanningContext(
      now: now,
      deviceZone: 'UTC',
      zones: TzZoneResolver(),
      settings: NotificationSettings.defaults,
      rules: [rule],
      targets: const [target],
      horizon: window,
      applyCaps: false,
    );
    return NoiseEstimate.fromPlan(NotificationPlanner.planRule(ctx, rule, target), window, others: others, from: now);
  }

  test('a daily reminder is quiet', () {
    final noise = estimate(
      schedule({
        'freq': 'daily',
        'times': ['09:00'],
      }),
      window: const Duration(days: 7),
    );
    expect(noise.firesPerDay, closeTo(1, 0.01));
    expect(noise.level, NoiseLevel.ok);
  });

  test('hourly reminders stay below the warning threshold (≈ 24/day)', () {
    final noise = estimate(schedule({'freq': 'hourly'}));
    expect(noise.firesPerDay, inInclusiveRange(23, 24));
    expect(noise.level, NoiseLevel.ok);
  });

  test('every 15 min warns (> 48/day) without blocking', () {
    final noise = estimate(schedule({'freq': 'minutely', 'interval': 15}));
    expect(noise.firesPerDay, greaterThan(NoiseEstimate.warnAbove));
    expect(noise.level, NoiseLevel.warn);
  });

  test('every 10 min asks for confirmation (> 96/day)', () {
    final noise = estimate(schedule({'freq': 'minutely', 'interval': 10}));
    expect(noise.firesPerDay, greaterThan(NoiseEstimate.confirmAbove));
    expect(noise.level, NoiseLevel.confirm);
  });

  test('every minute is at the hard cap and still allowed after confirmation', () {
    final noise = estimate(schedule({'freq': 'minutely'}));
    expect(noise.firesPerDay, NoiseEstimate.hardCap);
    expect(noise.level, NoiseLevel.confirm);
  });

  test('every minute with a nag chain exceeds the hard cap and is blocked', () {
    final noise = estimate(schedule({'freq': 'minutely'}, repeat: const RepeatSpec(everyMinutes: 1, maxTimes: 2)));
    expect(noise.firesPerDay, greaterThan(NoiseEstimate.hardCap));
    expect(noise.level, NoiseLevel.blocked);
  });

  test('same-minute clusters with the current plan are counted', () {
    final rule = schedule({
      'freq': 'daily',
      'times': ['09:00'],
    });
    final noise = estimate(
      rule,
      window: const Duration(days: 2),
      others: [DateTime.utc(2026, 9, 22, 9, 0, 20), DateTime.utc(2026, 9, 23, 12)],
    );
    expect(noise.sameMinuteClusters, 1);
  });

  test('a daily estimate is computed quickly', () {
    final watch = Stopwatch()..start();
    estimate(
      schedule({
        'freq': 'daily',
        'times': ['09:00', '21:00'],
      }),
      window: const Duration(days: 7),
    );
    expect(watch.elapsedMilliseconds, lessThan(100));
  });
}
