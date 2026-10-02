import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/smart_suggestions.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smart reminder suggestions (T7.5.19) on fixture histories.
void main() {
  int m(int h, int min) => h * 60 + min;

  NotificationRule rule(NotificationTrigger trigger) => NotificationRule(
    id: 'r',
    targetType: RuleTargetType.habit,
    targetId: 'pushups',
    section: NotificationSection.habits,
    spec: NotificationRuleSpec(trigger: trigger),
  );

  final at9 = rule(RelativeTrigger(anchor: TriggerAnchor.periodStart, dayOffset: 0, atTime: LocalTime(9, 0)));
  final steady = [m(7, 40), m(7, 50), m(7, 45), m(7, 42), m(7, 48), m(7, 46)];

  test('circular mean wraps around midnight', () {
    final mean = SmartSuggestions.circularMean([m(23, 50), m(0, 10)])!;
    expect(mean.$1, 0);
    expect(mean.$2, greaterThan(0.99));
    expect(SmartSuggestions.circularMean([m(6, 0), m(18, 0)])!.$2, lessThan(0.01), reason: 'opposite times cancel');
    expect(SmartSuggestions.circularMean(const []), isNull);
  });

  test('a steady 07:45 habit with a 09:00 reminder → move it to 07:30', () {
    final s = SmartSuggestions.suggest(rule: at9, targetKey: 'habit:pushups', minutes: steady)!;
    expect((s.usual, s.current, s.proposed, s.samples), (LocalTime(7, 45), LocalTime(9, 0), LocalTime(7, 30), 6));
    expect(s.concentration, greaterThan(0.99));
  });

  test('no suggestion when the reminder already fits, data is thin, or times are scattered', () {
    final fits = rule(RelativeTrigger(anchor: TriggerAnchor.periodStart, dayOffset: 0, atTime: LocalTime(7, 25)));
    expect(
      SmartSuggestions.suggest(rule: fits, targetKey: 'k', minutes: steady),
      isNull,
      reason: 'within 15 min',
    );
    expect(SmartSuggestions.suggest(rule: at9, targetKey: 'k', minutes: steady.take(4).toList()), isNull);
    final scattered = [m(6, 0), m(10, 0), m(14, 0), m(18, 0), m(22, 0), m(2, 0)];
    expect(SmartSuggestions.suggest(rule: at9, targetKey: 'k', minutes: scattered), isNull);
    final offset = rule(const RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -10));
    expect(
      SmartSuggestions.suggest(rule: offset, targetKey: 'k', minutes: steady),
      isNull,
      reason: 'no fixed time',
    );
  });

  test('daily schedules with one time are adjustable too, and keep their other fields', () {
    const daily = ScheduleTrigger(
      recurrence: {
        'v': 1,
        'type': 'fixed',
        'freq': 'daily',
        'interval': 1,
        'times': ['21:00'],
      },
    );
    expect(SmartSuggestions.adjustableTime(daily), LocalTime(21, 0));
    final moved = SmartSuggestions.withTime(daily, LocalTime(20, 15)) as ScheduleTrigger;
    expect(moved.recurrence['times'], ['20:15']);
    expect(moved.recurrence['freq'], 'daily');
    const twice = ScheduleTrigger(
      recurrence: {
        'v': 1,
        'type': 'fixed',
        'freq': 'daily',
        'interval': 1,
        'times': ['08:00', '20:00'],
      },
    );
    expect(SmartSuggestions.adjustableTime(twice), isNull);
    final relative = SmartSuggestions.withTime(at9.spec.trigger, LocalTime(7, 30)) as RelativeTrigger;
    expect((relative.anchor, relative.dayOffset, relative.atTime), (TriggerAnchor.periodStart, 0, LocalTime(7, 30)));
  });
}
