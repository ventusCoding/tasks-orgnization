import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/habit_fixtures.dart';

void main() {
  group('validation (T5.1.03)', () {
    Matcher code(HabitValidationCode c) => throwsA(isA<HabitValidationException>().having((e) => e.code, 'code', c));

    test('name, goal, unit, dates and schedule rules', () {
      expect(() => buildHabit(name: '  ').validate(), code(HabitValidationCode.nameEmpty));
      expect(() => buildHabit(name: 'x' * 81).validate(), code(HabitValidationCode.nameTooLong));
      buildHabit(name: 'x' * 80).validate();
      expect(
        () => buildHabit(goal: const HabitTarget(type: HabitGoalType.count)).validate(),
        code(HabitValidationCode.targetRequired),
      );
      expect(
        () => buildHabit(
          goal: const HabitTarget(type: HabitGoalType.count, target: 0, op: TargetOp.lte),
        ).validate(),
        code(HabitValidationCode.targetRequired),
        reason: 'a limit of 0 is a quit tracker, not a habit (server CHECK)',
      );
      expect(
        () => buildHabit(goal: const HabitTarget(type: HabitGoalType.duration, target: 1441)).validate(),
        code(HabitValidationCode.durationOutOfRange),
      );
      expect(
        () => buildHabit(
          goal: const HabitTarget(type: HabitGoalType.check, op: TargetOp.lte),
        ).validate(),
        code(HabitValidationCode.limitNeedsMeasurable),
      );
      expect(
        () => buildHabit(
          goal: HabitTarget(type: HabitGoalType.count, target: 3, unit: 'u' * 21),
        ).validate(),
        code(HabitValidationCode.unitInvalid),
      );
      expect(
        () => buildHabit(start: d(2026, 9, 10), end: d(2026, 9, 9)).validate(),
        code(HabitValidationCode.endBeforeStart),
      );
      expect(
        () => buildHabit(schedule: RecurrenceRule(interval: 0)).validate(),
        code(HabitValidationCode.scheduleInvalid),
      );
      buildHabit(
        goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'),
      ).validate();
    });

    test('quit trackers: limit, costs and currency', () {
      QuitHabit quit({QuitMode mode = QuitMode.abstain, double? limit, String? currency, Decimal? cost}) => QuitHabit(
        id: 'q',
        name: 'Stop smoking',
        startDate: d(2026, 9, 1),
        sortKey: 'a0',
        mode: mode,
        quitStartedAt: DateTime.utc(2026, 9, 1, 20),
        dailyLimit: limit,
        currency: currency,
        unitCost: cost,
      );
      expect(() => quit(mode: QuitMode.reduce).validate(), throwsA(isA<HabitValidationException>()));
      quit(mode: QuitMode.reduce, limit: 0).validate();
      expect(() => quit(currency: 'eur').validate(), throwsA(isA<HabitValidationException>()));
      expect(() => quit(cost: Decimal.parse('-1')).validate(), throwsA(isA<HabitValidationException>()));
      quit(currency: 'EUR', cost: Decimal.parse('0.5')).validate();
    });
  });

  group('revisions', () {
    test('effectiveFor picks the latest revision on or before the date', () {
      final revs = [
        revision('r1', d(2026, 9, 1), schedule: RecurrenceRule()),
        revision('r3', d(2026, 9, 20), goalType: HabitGoalType.count, target: 20),
        revision('r2', d(2026, 9, 10), goalType: HabitGoalType.count, target: 15),
      ];
      expect(HabitRevision.effectiveFor(revs, d(2026, 8, 31)), isNull);
      expect(HabitRevision.effectiveFor(revs, d(2026, 9, 1))?.id, 'r1');
      expect(HabitRevision.effectiveFor(revs, d(2026, 9, 15))?.id, 'r2');
      expect(HabitRevision.effectiveFor(revs, d(2026, 9, 20))?.id, 'r3');
      final habit = buildHabit(
        goal: const HabitTarget(type: HabitGoalType.count, target: 10, unit: 'reps'),
      );
      expect(HabitRules.on(habit, revs, d(2026, 9, 12)).goal.target, 15);
      expect(HabitRules.on(habit, const [], d(2026, 9, 12)).goal.target, 10);
    });
  });

  group('settings JSON (HabitSettings v1)', () {
    test('round-trips and keeps unknown keys', () {
      final json = {
        'v': 1,
        'slotRollup': {'mode': 'min', 'minSlots': 6},
        'earlyToleranceMinutes': 45,
        'requireExplicitLog': true,
        'incrementStep': 5,
        'quickValues': [5, 10],
        'askNoteAfterCheckIn': true,
        'challenge': {'successRule': 'min_ratio', 'minRatio': 0.8},
        'futureKey': {'x': 1},
      };
      final s = HabitSettings.fromJson(jsonDecode(jsonEncode(json)));
      expect(s.slotRollup, SlotRollupMode.minSlots);
      expect(s.minSlots, 6);
      expect(s.earlyToleranceMinutes, 45);
      expect(s.requireExplicitLog, isTrue);
      expect(s.quickValues, [5.0, 10.0]);
      expect(s.challenge?.rule, ChallengeRule.minRatio);
      expect(s.extra['futureKey'], {'x': 1});
      expect(HabitSettings.fromJson(jsonDecode(jsonEncode(s.toJson()))), s);
      expect(HabitSettings.fromJson('garbage'), HabitSettings.defaults);
      expect(HabitSettings.fromJson(const {'earlyToleranceMinutes': 999}).earlyToleranceMinutes, 120);
    });
  });

  group('schedule presets ↔ rules (T5.1.08)', () {
    final presets = <SchedulePreset>[
      const SchedulePreset.daily(),
      const SchedulePreset(SchedulePresetKind.weekdays),
      const SchedulePreset(SchedulePresetKind.weekends),
      const SchedulePreset(SchedulePresetKind.specificDays, days: [Weekday.monday, Weekday.tuesday]),
      const SchedulePreset(SchedulePresetKind.everyNDays, n: 2),
      const SchedulePreset(SchedulePresetKind.timesPerWeek, n: 3),
      const SchedulePreset(SchedulePresetKind.timesPerMonth, n: 10),
      const SchedulePreset(SchedulePresetKind.timesPerDay, n: 8),
      SchedulePreset(SchedulePresetKind.specificTimes, times: [LocalTime(8, 0), LocalTime(14, 0), LocalTime(20, 0)]),
      SchedulePreset(
        SchedulePresetKind.interval,
        everyMinutes: 60,
        windowStart: LocalTime(9, 0),
        windowEnd: LocalTime(18, 0),
      ),
      SchedulePreset(
        SchedulePresetKind.interval,
        everyMinutes: 45,
        windowStart: LocalTime(9, 0),
        windowEnd: LocalTime(18, 0),
        days: const [Weekday.monday, Weekday.friday],
      ),
      const SchedulePreset(SchedulePresetKind.monthlyDay, monthDay: 15),
      const SchedulePreset(SchedulePresetKind.monthlyDay, monthDay: -1),
      const SchedulePreset(SchedulePresetKind.monthlyWeekday, ordinal: 2, weekday: Weekday.tuesday),
      const SchedulePreset(SchedulePresetKind.monthlyWeekday, ordinal: -1, weekday: Weekday.friday),
      const SchedulePreset(SchedulePresetKind.afterCompletion, n: 3),
    ];

    for (final p in presets) {
      test('${p.kind.name} round-trips through the rule and its JSON', () {
        final goal = p.adaptGoal(const HabitTarget.check());
        final rule = p.toRule();
        expect(rule.validate().isValid, isTrue, reason: '$rule');
        expect(SchedulePreset.fromRule(rule, goal: goal), p);
        final decoded = RecurrenceRule.fromJson(jsonDecode(jsonEncode(rule.toJson())) as Map<String, Object?>);
        expect(SchedulePreset.fromRule(decoded, goal: goal), p);
      });
    }

    test('anything else is Custom and keeps the rule', () {
      final rule = RecurrenceRule(freq: Frequency.yearly, byMonth: const [3], byMonthDay: const [21]);
      final preset = SchedulePreset.fromRule(rule);
      expect(preset.kind, SchedulePresetKind.custom);
      expect(preset.toRule(), rule);
    });

    test('N times per day turns a yes/no goal into count ≥ N "times" and back', () {
      const p = SchedulePreset(SchedulePresetKind.timesPerDay, n: 8);
      final goal = p.adaptGoal(const HabitTarget.check());
      expect(goal, const HabitTarget(type: HabitGoalType.count, target: 8, unit: 'times'));
      expect(const SchedulePreset.daily().adaptGoal(goal), const HabitTarget.check());
      const reps = HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps');
      expect(const SchedulePreset.daily().adaptGoal(reps), reps);
    });
  });

  group('catalogs', () {
    test('every template yields a valid habit (T5.1.16)', () {
      for (final t in HabitTemplate.all) {
        final habit = t.toHabit(id: t.key, name: t.key, startDate: d(2026, 9, 1), sortKey: 'a0');
        habit.validate();
        expect(SchedulePreset.fromRule(habit.schedule, goal: habit.goal).kind, t.schedule.kind, reason: t.key);
        if (t.isChallenge) {
          expect(habit.endDate, d(2026, 9, 1).plusDays(t.challengeDays! - 1));
          expect(habit.isChallenge, isTrue);
        }
      }
      expect(HabitTemplate.byKey('pushUps')!.goal.target, 15);
    });

    test('quit presets: unit cost from a pack price', () {
      expect(QuitPreset.of(QuitSubstance.cigarettes).unitsPerPack, 20);
      expect(QuitPreset.of(QuitSubstance.cigarettes).lifeMinutesPerUnit, 20);
      expect(QuitPreset.of(QuitSubstance.alcohol).lifeMinutesPerUnit, isNull, reason: 'health content: smoking only');
      expect(QuitPreset.unitCostFromPack(Decimal.parse('10'), 20), Decimal.parse('0.5'));
      expect(QuitPreset.unitCostFromPack(Decimal.parse('11.30'), 20), Decimal.parse('0.565'));
      expect(QuitPreset.unitCostFromPack(null, 20), isNull);
      expect({for (final p in QuitPreset.all) p.key}.length, QuitPreset.all.length);
    });

    test('default sections and vocab keys', () {
      expect(DefaultSections.all.map((s) => s.$1), ['morning', 'afternoon', 'evening', 'anytime']);
      final morning = HabitSection(
        id: 's',
        name: 'Morning',
        sortKey: 'a0',
        startTime: LocalTime(4, 0),
        endTime: LocalTime(12, 0),
      );
      expect(morning.containsTime(LocalTime(7, 30)), isTrue);
      expect(morning.containsTime(LocalTime(12, 0)), isFalse);
      final night = HabitSection(
        id: 'n',
        name: 'Night',
        sortKey: 'a1',
        startTime: LocalTime(22, 0),
        endTime: LocalTime(2, 0),
      );
      expect(night.containsTime(LocalTime(23, 0)), isTrue);
      expect(night.containsTime(LocalTime(1, 0)), isTrue);
      expect(night.containsTime(LocalTime(3, 0)), isFalse);
      expect(DefaultVocab.keysFor(VocabKind.trigger), contains('stress'));
    });
  });
}
