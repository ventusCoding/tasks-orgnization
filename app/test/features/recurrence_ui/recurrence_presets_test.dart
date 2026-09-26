import 'package:everslot/features/recurrence_ui/domain/recurrence_exception.dart';
import 'package:everslot/features/recurrence_ui/domain/recurrence_presets.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tuesday 2026-09-22 09:00 (4th Tuesday, not the last one: the 29th is the 5th).
  final tuesday = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 9), null, durationMinutes: 30);
  // Tuesday 2026-09-29 09:00 (5th and last Tuesday).
  final lastTuesday = RecurrenceAnchor(LocalDateTime.of(2026, 9, 29, 9), null, durationMinutes: 30);
  final allDay = RecurrenceAnchor.allDayOn(LocalDate(2026, 9, 22), null);

  group('modes', () {
    test('habit mode never offers "does not repeat" and offers quota', () {
      final presets = RecurrencePresets.available(RecurrencePickerMode.habit, tuesday);
      expect(presets, isNot(contains(RecurrencePreset.none)));
      expect(presets, contains(RecurrencePreset.quota));
      expect(presets, contains(RecurrencePreset.afterCompletion));
    });

    test('task mode: after completion but no quota preset', () {
      final presets = RecurrencePresets.available(RecurrencePickerMode.task, tuesday);
      expect(presets.first, RecurrencePreset.none);
      expect(presets, isNot(contains(RecurrencePreset.quota)));
      expect(presets, contains(RecurrencePreset.afterCompletion));
      expect(presets.last, RecurrencePreset.custom);
      expect(RecurrencePickerMode.task.ruleTypes, contains(RuleType.quota));
    });

    test('checklist resets and reminders: calendar rules only', () {
      for (final mode in [RecurrencePickerMode.checklistReset, RecurrencePickerMode.reminder]) {
        final presets = RecurrencePresets.available(mode, tuesday);
        expect(presets, contains(RecurrencePreset.none));
        expect(presets, isNot(contains(RecurrencePreset.quota)));
        expect(presets, isNot(contains(RecurrencePreset.afterCompletion)));
        expect(mode.ruleTypes, [RuleType.fixed]);
      }
    });

    test('all-day anchors hide intraday presets', () {
      final presets = RecurrencePresets.available(RecurrencePickerMode.task, allDay);
      expect(presets, isNot(contains(RecurrencePreset.intraday)));
      expect(presets, isNot(contains(RecurrencePreset.timesPerDay)));
    });

    test('Nth-weekday presets follow the anchor position in the month', () {
      expect(RecurrencePresets.nthWeekdayOfMonth(LocalDate(2026, 9, 22)), 4);
      expect(RecurrencePresets.isLastWeekdayOfMonth(LocalDate(2026, 9, 22)), isFalse);
      final a = RecurrencePresets.available(RecurrencePickerMode.task, tuesday);
      expect(a, contains(RecurrencePreset.monthlyOnNthWeekday));
      expect(a, isNot(contains(RecurrencePreset.monthlyOnLastWeekday)));
      final b = RecurrencePresets.available(RecurrencePickerMode.task, lastTuesday);
      expect(b, isNot(contains(RecurrencePreset.monthlyOnNthWeekday)), reason: '5th Tuesday → only "last"');
      expect(b, contains(RecurrencePreset.monthlyOnLastWeekday));
    });
  });

  group('build', () {
    final params = PresetParams.initial(tuesday);

    RecurrenceRule build(RecurrencePreset p, [PresetParams? custom, RecurrenceAnchor? anchor]) =>
        RecurrencePresets.build(p, anchor ?? tuesday, custom ?? params)!;

    test('every preset builds a valid rule synchronized with the anchor', () {
      for (final p in RecurrencePresets.available(RecurrencePickerMode.habit, tuesday)) {
        if (p == RecurrencePreset.custom) continue;
        final rule = build(p);
        expect(rule.validate(anchor: tuesday).isValid, isTrue, reason: '$p → $rule');
      }
      expect(RecurrencePresets.build(RecurrencePreset.none, tuesday, params), isNull);
      expect(RecurrencePresets.build(RecurrencePreset.custom, tuesday, params), isNull);
    });

    test('anchor-derived presets use the RFC minimal form', () {
      expect(build(RecurrencePreset.weekly).toJson(), {'v': 1, 'type': 'fixed', 'freq': 'weekly', 'interval': 1});
      expect(build(RecurrencePreset.monthlyOnDay).byMonthDay, isEmpty);
      expect(build(RecurrencePreset.yearly).byMonth, isEmpty);
    });

    test('explicit presets', () {
      expect(build(RecurrencePreset.weekdays).byWeekday, [for (final d in RecurrencePresets.workWeek) WeekdayRule(d)]);
      expect(build(RecurrencePreset.monthlyOnNthWeekday).byWeekday, [const WeekdayRule(Weekday.tuesday, 4)]);
      expect(build(RecurrencePreset.monthlyOnLastWeekday, null, lastTuesday).byWeekday, [
        const WeekdayRule(Weekday.tuesday, -1),
      ]);
      expect(build(RecurrencePreset.lastDayOfMonth).byMonthDay, [-1]);
      final days = build(RecurrencePreset.specificDays, params.copyWith(days: {Weekday.tuesday, Weekday.monday}));
      expect(days.byWeekday, [const WeekdayRule(Weekday.monday), const WeekdayRule(Weekday.tuesday)]);
      expect(build(RecurrencePreset.everyNDays, params.copyWith(everyDays: 3)).interval, 3);
    });

    test('intraday: 90 min → minutely 90, 2 h → hourly 2, with the default 08:00–20:00 window', () {
      final ninety = build(RecurrencePreset.intraday, params.copyWith(stepMinutes: 90));
      expect(ninety.freq, Frequency.minutely);
      expect(ninety.interval, 90);
      expect(ninety.window, PresetParams.defaultWindow);
      final twoHours = build(RecurrencePreset.intraday, params.copyWith(stepMinutes: 120, window: null));
      expect(twoHours.freq, Frequency.hourly);
      expect(twoHours.interval, 2);
      expect(twoHours.window, isNull);
    });

    test('times per day are sorted and deduplicated; defaults to start + 12 h', () {
      expect(params.times, [LocalTime(9, 0), LocalTime(21, 0)]);
      final rule = build(
        RecurrencePreset.timesPerDay,
        params.copyWith(times: [LocalTime(20, 0), LocalTime(8, 0), LocalTime(20, 0)]),
      );
      expect(rule.times, [LocalTime(8, 0), LocalTime(20, 0)]);
    });

    test('quota and after completion', () {
      final q = build(RecurrencePreset.quota, params.copyWith(quotaTimes: 20, quotaPer: PeriodUnit.month));
      expect(q.type, RuleType.quota);
      expect(q.quota, const Quota(20, PeriodUnit.month));
      final a = build(
        RecurrencePreset.afterCompletion,
        params.copyWith(afterAmount: 3, afterUnit: RecurrenceUnit.hour),
      );
      expect(a.afterCompletion, const AfterCompletion(3, RecurrenceUnit.hour));
    });
  });

  group('detect', () {
    RecurrencePreset detect(RecurrenceRule? rule, [RecurrenceAnchor? anchor, RecurrencePickerMode? mode]) =>
        RecurrencePresets.detect(rule, anchor ?? tuesday, mode: mode ?? RecurrencePickerMode.habit);

    test('round trip: detect(build(p)) == p for every preset', () {
      // (Specific days = {the anchor's day} is the same rule as *weekly*.)
      final params = PresetParams.initial(tuesday).copyWith(days: {Weekday.monday, Weekday.thursday});
      for (final anchor in [tuesday, lastTuesday]) {
        for (final p in RecurrencePresets.available(RecurrencePickerMode.habit, anchor)) {
          if (p == RecurrencePreset.custom) continue;
          final rule = RecurrencePresets.build(p, anchor, params);
          expect(detect(rule, anchor), p, reason: '$p → $rule');
        }
      }
    });

    test('bounds, exceptions and week start do not change the preset', () {
      final rule = RecurrenceRule(
        freq: Frequency.daily,
        count: 10,
        exdates: const ['2026-09-25T09:00'],
        wkst: Weekday.sunday,
      );
      expect(detect(rule), RecurrencePreset.daily);
      expect(
        detect(RecurrenceRule(freq: Frequency.daily, until: LocalDateTime.of(2026, 12, 31, 23, 59))),
        RecurrencePreset.daily,
      );
    });

    test('explicit forms equal to the anchor are recognized', () {
      expect(
        detect(RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.tuesday)])),
        RecurrencePreset.weekly,
      );
      expect(detect(RecurrenceRule(freq: Frequency.monthly, byMonthDay: const [22])), RecurrencePreset.monthlyOnDay);
      expect(
        detect(RecurrenceRule(freq: Frequency.yearly, byMonth: const [9], byMonthDay: const [22])),
        RecurrencePreset.yearly,
      );
    });

    test('anything else is custom', () {
      expect(detect(RecurrenceRule(freq: Frequency.weekly, interval: 2)), RecurrencePreset.custom);
      expect(detect(RecurrenceRule(freq: Frequency.monthly, byMonthDay: const [1, 15])), RecurrencePreset.custom);
      expect(
        detect(RecurrenceRule(freq: Frequency.monthly, byWeekday: const [WeekdayRule(Weekday.friday, -1)])),
        RecurrencePreset.custom,
        reason: 'last Friday while the anchor is a Tuesday',
      );
      expect(
        detect(
          RecurrenceRule(
            freq: Frequency.monthly,
            byWeekday: [for (final d in RecurrencePresets.workWeek) WeekdayRule(d)],
            bySetPos: const [-1],
          ),
        ),
        RecurrencePreset.custom,
      );
      expect(
        detect(
          RecurrenceRule(
            freq: Frequency.minutely,
            interval: 45,
            window: DailyWindow(LocalTime(9, 0), LocalTime(18, 0)),
            byWeekday: [for (final d in RecurrencePresets.workWeek) WeekdayRule(d)],
          ),
        ),
        RecurrencePreset.custom,
      );
      expect(
        detect(RecurrenceRule(freq: Frequency.daily, monthDayOverflow: MonthOverflow.clamp)),
        RecurrencePreset.custom,
      );
    });

    test('empty weekday set stays on "specific days" (invalid until a day is picked)', () {
      expect(detect(RecurrenceRule(freq: Frequency.weekly, byWeekday: const [])), RecurrencePreset.specificDays);
    });

    test('mode-restricted types fall back to custom', () {
      final quota = RecurrenceRule.forQuota(3, PeriodUnit.week);
      expect(detect(quota, tuesday, RecurrencePickerMode.habit), RecurrencePreset.quota);
      expect(detect(quota, tuesday, RecurrencePickerMode.task), RecurrencePreset.custom);
      final after = RecurrenceRule.forAfterCompletion(2, RecurrenceUnit.day);
      expect(detect(after, tuesday, RecurrencePickerMode.reminder), RecurrencePreset.custom);
      expect(detect(null), RecurrencePreset.none);
    });
  });

  group('params', () {
    test('initial params read the current rule', () {
      final p = PresetParams.initial(
        tuesday,
        RecurrenceRule(freq: Frequency.minutely, interval: 45, window: DailyWindow(LocalTime(9, 0), LocalTime(18, 0))),
      );
      expect(p.stepMinutes, 45);
      expect(p.window, DailyWindow(LocalTime(9, 0), LocalTime(18, 0)));
      expect(PresetParams.initial(tuesday, RecurrenceRule(freq: Frequency.hourly, interval: 3)).stepMinutes, 180);
      expect(PresetParams.initial(tuesday, RecurrenceRule(freq: Frequency.daily, interval: 4)).everyDays, 4);
      expect(
        PresetParams.initial(tuesday, RecurrenceRule.forQuota(5, PeriodUnit.month, minGapDays: 1)),
        PresetParams.initial(tuesday).copyWith(quotaTimes: 5, quotaPer: PeriodUnit.month, quotaMinGapDays: 1),
      );
      final days = PresetParams.initial(
        tuesday,
        RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.friday)]),
      ).days;
      expect(days, {Weekday.friday});
    });
  });

  group('ends', () {
    final rule = RecurrenceRule(freq: Frequency.daily);

    test('apply and read back', () {
      final onDate = RecurrenceEnds.onDate(LocalDate(2026, 12, 31));
      expect(onDate.applyTo(rule).until, LocalDateTime.of(2026, 12, 31, 23, 59));
      expect(RecurrenceEnds.of(onDate.applyTo(rule)), onDate);
      expect(const RecurrenceEnds.after(5).applyTo(rule).count, 5);
      expect(const RecurrenceEnds.never().applyTo(rule.copyWith(count: 3)).count, isNull);
      expect(RecurrenceEnds.of(null).kind, RecurrenceEndKind.never);
      final completions = rule.copyWith(countMode: CountMode.completions);
      expect(const RecurrenceEnds.after(4).applyTo(completions).countMode, CountMode.completions);
    });

    test('switching kinds clears the other bound (count and until are exclusive)', () {
      final withCount = const RecurrenceEnds.after(3).applyTo(rule);
      final switched = RecurrenceEnds.onDate(LocalDate(2027, 1, 1)).applyTo(withCount);
      expect(switched.count, isNull);
      expect(switched.validate().isValid, isTrue);
    });
  });

  group('exception entries', () {
    test('sort by original start and expose date keys', () {
      final entries = [
        const RecurrenceExceptionEntry(key: '2026-09-24T09:00', kind: RecurrenceExceptionKind.cancelled),
        const RecurrenceExceptionEntry(key: '2026-09-22', kind: RecurrenceExceptionKind.excluded),
        RecurrenceExceptionEntry(
          key: '2026-09-23T09:00',
          kind: RecurrenceExceptionKind.moved,
          movedTo: LocalDateTime.of(2026, 9, 23, 11),
        ),
      ]..sort(RecurrenceExceptionEntry.compare);
      expect([for (final e in entries) e.key], ['2026-09-22', '2026-09-23T09:00', '2026-09-24T09:00']);
      expect(entries.first.isDateKey, isTrue);
      expect(entries.first.originalStart, LocalDateTime.of(2026, 9, 22));
      expect(
        const RecurrenceExceptionEntry(key: 'week:2026-09-21#1', kind: RecurrenceExceptionKind.moved).originalStart,
        isNull,
      );
    });
  });
}
