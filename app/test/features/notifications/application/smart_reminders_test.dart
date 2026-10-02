import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/application/smart_reminders.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// Smart reminders (T7.5.19): suggestions from real check-ins, apply / dismiss, weekly auto-adjust.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late BuildHabit habit;

  setUp(() async {
    // 07:45 in Paris = 05:45 UTC (summer time).
    h = TestHarness.create(now: DateTime.utc(2026, 9, 14, 5, 45), zone: 'Europe/Paris');
    await seedNotificationDefaults(h.read);
    habit = BuildHabit(
      id: Ids.v7(),
      name: 'Push-ups',
      startDate: LocalDate(2026, 9, 1),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: const SchedulePreset.daily().toRule(weekStart: Weekday.monday),
    );
    await h.read(habitsRepositoryProvider).create(habit);
    await h.read(notificationRulesRepositoryProvider).create([
      RuleDraft(
        targetType: RuleTargetType.habit,
        targetId: habit.id,
        section: NotificationSection.habits,
        spec: NotificationRuleSpec(
          trigger: RelativeTrigger(anchor: TriggerAnchor.periodStart, dayOffset: 0, atTime: LocalTime(9, 0)),
        ),
      ),
    ]);
    // Six check-ins around 07:45, then "now" is the next week.
    for (var d = 0; d < 6; d++) {
      h.clock.set(DateTime.utc(2026, 9, 14 + d, 5, 40 + d));
      await h.read(checkInServiceProvider).markDone(habit, '2026-09-${14 + d}');
    }
    h.clock.set(DateTime.utc(2026, 9, 21, 10));
  });
  tearDown(() => h.dispose());

  test('suggests 07:30 from the check-ins; apply moves the rule; dismiss hides it', () async {
    final service = h.read(smartRemindersProvider);
    final s = (await service.suggestions()).single;
    expect(
      (s.targetKey, s.current, s.proposed, s.samples),
      ('habit:${habit.id}', LocalTime(9, 0), LocalTime(7, 30), 6),
    );
    await service.apply(s);
    final rule = (await h.read(notificationRulesRepositoryProvider).forTarget(RuleTargetType.habit, habit.id)).single;
    expect((rule.spec.trigger as RelativeTrigger).atTime, LocalTime(7, 30));
    expect(await service.suggestions(), isEmpty, reason: 'it fits now');
  });

  test('dismissed suggestions stay hidden', () async {
    final service = h.read(smartRemindersProvider);
    await service.dismiss((await service.suggestions()).single);
    expect(await service.suggestions(), isEmpty);
  });

  test('auto-adjust is opt-in, weekly, and leaves an inbox summary', () async {
    final service = h.read(smartRemindersProvider);
    expect(await service.autoAdjustIfDue(), isEmpty, reason: 'off by default');
    final sub = h.container.listen(notificationSettingsProvider, (_, _) {});
    addTearDown(sub.close);
    await h.read(notificationSettingsWriterProvider)({'smartAdjust': true});
    while (!h.read(notificationSettingsProvider).smartAdjust) {
      await pumpEventQueue();
    }
    final applied = await service.autoAdjustIfDue();
    expect(applied, hasLength(1));
    final notices = await h.read(inboxRepositoryProvider).statsRows(from: DateTime.utc(2026, 9, 20));
    final summary = notices.singleWhere((r) => r.sourceId == 'smart_adjust');
    expect(summary.title, '1 reminder moved to fit your habits');
    expect(summary.body, contains('09:00 → 07:30'));
    expect(await service.autoAdjustIfDue(), isEmpty, reason: 'once a week');
  });
}
