import 'dart:convert';

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

const _weekdays = [
  WeekdayRule(Weekday.monday),
  WeekdayRule(Weekday.tuesday),
  WeekdayRule(Weekday.wednesday),
  WeekdayRule(Weekday.thursday),
  WeekdayRule(Weekday.friday),
];

/// The arch §8.1 example (comments removed).
const _archExample =
    '{"v":1,"type":"fixed","freq":"weekly","interval":1,"byWeekday":[{"day":"MO"},{"day":"TU"}],'
    '"byMonthDay":[],"byMonth":[],"byYearDay":[],"byWeekNo":[],"bySetPos":[],"times":["08:00","20:00"],'
    '"window":{"start":"08:00","end":"20:00","anchor":"window_start"},"wkst":"MO","until":"2026-12-31T23:59",'
    '"count":null,"countMode":"occurrences","monthDayOverflow":"skip","exdates":["2026-10-01T08:00"],'
    '"rdates":["2026-10-03T09:00"],"afterCompletion":{"amount":2,"unit":"day"},'
    '"quota":{"times":3,"per":"week","minGapDays":0}}';

/// The prose examples of arch §8.1 in canonical form.
const _archProseExamples = [
  '{"v":1,"type":"fixed","freq":"weekly","interval":1,"byWeekday":[{"day":"MO"},{"day":"TU"}]}',
  '{"v":1,"type":"fixed","freq":"daily","interval":2}',
  '{"v":1,"type":"fixed","freq":"hourly","interval":1}',
  '{"v":1,"type":"fixed","freq":"minutely","interval":45,"byWeekday":[{"day":"MO"},{"day":"TU"},'
      '{"day":"WE"},{"day":"TH"},{"day":"FR"}],"window":{"start":"09:00","end":"18:00","anchor":"window_start"}}',
  '{"v":1,"type":"fixed","freq":"monthly","interval":1,"byWeekday":[{"day":"MO"},{"day":"TU"},{"day":"WE"},'
      '{"day":"TH"},{"day":"FR"}],"bySetPos":[-1]}',
  '{"v":1,"type":"quota","quota":{"times":3,"per":"week","minGapDays":0}}',
  '{"v":1,"type":"after_completion","afterCompletion":{"amount":2,"unit":"day"}}',
];

void main() {
  group('JSON codec', () {
    test('arch §8.1 examples round-trip byte-identically', () {
      for (final source in [_archExample, ..._archProseExamples]) {
        expect(RecurrenceRule.decode(source).encode(), source);
      }
    });

    test('every fixture rule round-trips byte-identically', () {
      for (final fixture in loadFixtures()) {
        expect(fixture.rule.encode(), jsonEncode(fixture.ruleJson), reason: fixture.toString());
      }
    });

    test('decodes every field', () {
      final rule = RecurrenceRule.decode(_archExample);
      expect(rule.type, RuleType.fixed);
      expect(rule.freq, Frequency.weekly);
      expect(rule.byWeekday, const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)]);
      expect(rule.times, [LocalTime(8, 0), LocalTime(20, 0)]);
      expect(rule.window, DailyWindow(LocalTime(8, 0), LocalTime(20, 0)));
      expect(rule.until, LocalDateTime.of(2026, 12, 31, 23, 59));
      expect(rule.count, isNull);
      expect(rule.exdates, ['2026-10-01T08:00']);
      expect(rule.afterCompletion, const AfterCompletion(2, RecurrenceUnit.day));
      expect(rule.quota, const Quota(3, PeriodUnit.week));
      expect(rule.toString(), contains('"freq":"weekly"'));
    });

    test('unknown keys are preserved on re-encode', () {
      final rule = RecurrenceRule.decode('{"v":1,"type":"fixed","freq":"daily","interval":1,"color":"red","x":{"a":1}}');
      expect(rule.extra, {
        'color': 'red',
        'x': {'a': 1},
      });
      expect(rule.encode(), '{"v":1,"type":"fixed","freq":"daily","interval":1,"color":"red","x":{"a":1}}');
      expect(rule.copyWith(interval: 3).encode(), contains('"color":"red"'));
    });

    test('canonical encoding omits defaults and emits non-defaults', () {
      final rule = RecurrenceRule(
        freq: Frequency.monthly,
        byMonthDay: const [31],
        wkst: Weekday.sunday,
        count: 3,
        countMode: CountMode.completions,
        monthDayOverflow: MonthOverflow.clamp,
        byHour: const [9],
        byMinute: const [30],
        byYearDay: const [1],
        byWeekNo: const [1],
      );
      expect(
        rule.encode(),
        '{"v":1,"type":"fixed","freq":"monthly","interval":1,"byMonthDay":[31],"byYearDay":[1],"byWeekNo":[1],'
        '"byHour":[9],"byMinute":[30],"wkst":"SU","count":3,"countMode":"completions","monthDayOverflow":"clamp"}',
      );
      expect(RecurrenceRule.fromJson(rule.toJson()), rule);
      expect(RecurrenceRule.forQuota(2, PeriodUnit.day).encode(), '{"v":1,"type":"quota","quota":{"times":2,"per":"day","minGapDays":0}}');
      expect(
        RecurrenceRule.forAfterCompletion(3, RecurrenceUnit.hour).encode(),
        '{"v":1,"type":"after_completion","afterCompletion":{"amount":3,"unit":"hour"}}',
      );
    });

    test('accepts lenient inputs', () {
      final rule = RecurrenceRule.fromJson({
        'freq': 'daily',
        'interval': 2.0,
        'until': '2026-12-31',
        'byWeekday': [
          {'day': 'MO', 'n': null},
        ],
        'window': {'start': '08:00', 'end': '24:00'},
      });
      expect(rule.type, RuleType.fixed);
      expect(rule.interval, 2);
      expect(rule.until, LocalDateTime.of(2026, 12, 31, 23, 59));
      expect(rule.window!.end.isEndOfDay, isTrue);
      expect(rule.window!.anchor, WindowAnchor.windowStart);
      expect(rule.window!.toJson()['end'], '24:00');
      expect(RecurrenceRule.fromJson(const {'v': 1, 'quota': {'times': 1, 'per': 'week'}}).quota!.minGapDays, 0);
      expect(RecurrenceRule.fromJson({'window': <Object?, Object?>{'start': '01:00', 'end': '02:00'}}).window, isNotNull);
    });

    test('rejects malformed JSON with FormatException', () {
      final bad = <Map<String, Object?>>[
        {'v': 2},
        {'v': 0},
        {'v': 'one'},
        {'type': 'weird'},
        {'freq': 'secondly'},
        {'interval': 'x'},
        {'interval': 1.5},
        {'byMonthDay': 3},
        {'byMonthDay': ['x']},
        {'times': ['25:00']},
        {'times': [8]},
        {'times': 'x'},
        {'window': 'x'},
        {'window': {'start': '24:00', 'end': '24:00'}},
        {'window': {'start': '08:00', 'end': '20:00', 'anchor': 'noon'}},
        {'wkst': 'XX'},
        {'wkst': 1},
        {'until': 'yesterday'},
        {'countMode': 'forever'},
        {'monthDayOverflow': 'wrap'},
        {'exdates': [1]},
        {'byWeekday': 'MO'},
        {'byWeekday': [{'day': 'XX'}]},
        {'byWeekday': [{'day': 1}]},
        {'afterCompletion': {'amount': 1, 'unit': 'fortnight'}},
        {'quota': {'times': 1, 'per': 'decade'}},
      ];
      for (final json in bad) {
        expect(() => RecurrenceRule.fromJson(json), throwsFormatException, reason: '$json');
      }
      expect(() => RecurrenceRule.decode('{'), throwsFormatException);
      expect(() => RecurrenceRule.decode('[1]'), throwsFormatException);
    });

    test('older versions go through the migration table', () {
      expect(() => RecurrenceRule.fromJson(const {'v': 0}), throwsFormatException);
      expect(RecurrenceRule.migrations, isEmpty);
    });
  });

  group('value semantics', () {
    test('equality ignores encoding details and copyWith replaces fields', () {
      final a = RecurrenceRule.decode('{"v":1,"type":"fixed","freq":"daily","interval":1,"byMonth":[]}');
      final b = RecurrenceRule();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.encode(), isNot(b.encode()));

      final full = RecurrenceRule(
        until: LocalDateTime.of(2026, 1, 1),
        count: 3,
        byWeekday: _weekdays,
        window: DailyWindow(LocalTime(8, 0), LocalTime(9, 0)),
        afterCompletion: const AfterCompletion(1, RecurrenceUnit.day),
        quota: const Quota(1, PeriodUnit.week),
      );
      final cleared = full.copyWith(
        until: null,
        count: null,
        byWeekday: null,
        window: null,
        afterCompletion: null,
        quota: null,
      );
      expect(cleared, RecurrenceRule());
      expect(full.copyWith(), full);
      final changed = full.copyWith(
        type: RuleType.quota,
        freq: Frequency.yearly,
        interval: 2,
        byMonthDay: [1],
        byMonth: [2],
        byYearDay: [3],
        byWeekNo: [4],
        bySetPos: [5],
        byHour: [6],
        byMinute: [7],
        times: [LocalTime(1, 0)],
        wkst: Weekday.friday,
        countMode: CountMode.completions,
        monthDayOverflow: MonthOverflow.clamp,
        exdates: ['2026-01-01'],
        rdates: ['2026-01-02'],
        extra: {'k': true},
      );
      expect(changed == full, isFalse);
      expect(changed.bySetPos, [5]);
      expect(() => changed.byMonth.add(1), throwsUnsupportedError);
    });

    test('parts', () {
      expect(WeekdayRule.parseRRule('-1FR'), const WeekdayRule(Weekday.friday, -1));
      expect(WeekdayRule.parseRRule('+2tu'), const WeekdayRule(Weekday.tuesday, 2));
      expect(WeekdayRule.parseRRule('SU').toRRule(), 'SU');
      expect(() => WeekdayRule.parseRRule('5XX'), throwsFormatException);
      expect(const WeekdayRule(Weekday.monday, 2).toString(), '2MO');
      expect(const WeekdayRule(Weekday.monday).hashCode, const WeekdayRule(Weekday.monday).hashCode);
      final window = DailyWindow(LocalTime(8, 0), LocalTime.endOfDay);
      expect(window.containsMinuteOfDay(1439), isTrue);
      expect(window.containsMinuteOfDay(479), isFalse);
      expect(window.copyWith(anchor: WindowAnchor.seriesStart).anchor, WindowAnchor.seriesStart);
      expect(window.copyWith(start: LocalTime(9, 0), end: LocalTime(10, 0)).toString(), contains('09:00'));
      expect(window.hashCode, DailyWindow(LocalTime(8, 0), LocalTime.endOfDay).hashCode);
      expect(const AfterCompletion(2, RecurrenceUnit.week).toString(), 'AfterCompletion(2 week)');
      expect(const AfterCompletion(2, RecurrenceUnit.week).hashCode, const AfterCompletion(2, RecurrenceUnit.week).hashCode);
      expect(const Quota(3, PeriodUnit.week).toString(), contains('3 per week'));
      expect(const Quota(3, PeriodUnit.week).hashCode, const Quota(3, PeriodUnit.week).hashCode);
      expect(RecurrenceUnit.day.isDayBased && !RecurrenceUnit.hour.isDayBased, isTrue);
      expect(Frequency.hourly.rrule, 'HOURLY');
      expect(Frequency.daily.json, 'daily');
    });

    test('Quota.respectsMinGap', () {
      const quota = Quota(3, PeriodUnit.week, minGapDays: 1);
      final monday = LocalDate(2026, 9, 21);
      expect(quota.respectsMinGap([monday, monday.plusDays(2), monday.plusDays(4)]), isTrue);
      expect(quota.respectsMinGap([monday, monday.plusDays(1)]), isFalse);
      expect(quota.respectsMinGap([monday, monday]), isFalse);
      expect(const Quota(3, PeriodUnit.week).respectsMinGap([monday, monday]), isTrue);
    });

    test('anchor', () {
      final anchor = RecurrenceAnchor.allDayOn(LocalDate(2026, 9, 21), null, days: 2);
      expect(anchor.allDay && anchor.isFloating, isTrue);
      expect(anchor.effectiveDurationMinutes, 2880);
      expect(anchor.toString(), contains('floating'));
      final timed = RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), 'UTC', durationMinutes: 30);
      expect(timed.effectiveDurationMinutes, 30);
      expect(timed.toString(), contains('30min'));
      expect(timed.copyWith(zoneId: null, durationMinutes: null).isFloating, isTrue);
      expect(timed.copyWith(start: LocalDateTime.of(2026, 1, 1), allDay: true).allDay, isTrue);
      expect(timed, RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), 'UTC', durationMinutes: 30));
      expect(timed.hashCode, timed.copyWith().hashCode);
      expect(RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), 'UTC').effectiveDurationMinutes, 0);
    });
  });

  group('validator', () {
    List<RuleIssueCode> codes(RecurrenceRule rule, {RecurrenceAnchor? anchor, int max = 1440}) =>
        rule.validate(anchor: anchor, maxOccurrencesPerDay: max).codes;
    final anchor = RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), 'UTC');

    final table = <String, (RecurrenceRule, List<RuleIssueCode>)>{
      'valid weekly': (RecurrenceRule(freq: Frequency.weekly, byWeekday: _weekdays), []),
      'interval 0': (RecurrenceRule(interval: 0), [RuleIssueCode.intervalInvalid]),
      'count 0': (RecurrenceRule(count: 0), [RuleIssueCode.countInvalid]),
      'count and until': (
        RecurrenceRule(count: 3, until: LocalDateTime.of(2027, 1, 1)),
        [RuleIssueCode.countAndUntil],
      ),
      'until before start': (RecurrenceRule(until: LocalDateTime.of(2026, 1, 1)), [RuleIssueCode.untilBeforeStart]),
      'empty weekday set': (RecurrenceRule(freq: Frequency.weekly, byWeekday: const []), [RuleIssueCode.emptyWeekdaySet]),
      'ordinal on weekly': (
        RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday, 2)]),
        [RuleIssueCode.ordinalOnWeekly],
      ),
      'ordinal on yearly with byWeekNo': (
        RecurrenceRule(freq: Frequency.yearly, byWeekNo: const [1], byWeekday: const [WeekdayRule(Weekday.monday, 1)]),
        [RuleIssueCode.ordinalOnWeekly],
      ),
      'window end before start': (
        RecurrenceRule(freq: Frequency.minutely, window: DailyWindow(LocalTime(20, 0), LocalTime(8, 0))),
        [RuleIssueCode.windowEndBeforeStart],
      ),
      'window on a daily rule': (
        RecurrenceRule(window: DailyWindow(LocalTime(8, 0), LocalTime(9, 0))),
        [RuleIssueCode.unsupportedCombo],
      ),
      'times on a minutely rule': (
        RecurrenceRule(freq: Frequency.minutely, times: [LocalTime(8, 0)]),
        [RuleIssueCode.unsupportedCombo],
      ),
      'times with byHour': (RecurrenceRule(times: [LocalTime(8, 0)], byHour: const [9]), [RuleIssueCode.unsupportedCombo]),
      'byWeekNo on monthly': (RecurrenceRule(freq: Frequency.monthly, byWeekNo: const [1]), [RuleIssueCode.unsupportedCombo]),
      'byYearDay on daily': (RecurrenceRule(byYearDay: const [1]), [RuleIssueCode.unsupportedCombo]),
      'byMonthDay on weekly': (RecurrenceRule(freq: Frequency.weekly, byMonthDay: const [1]), [RuleIssueCode.unsupportedCombo]),
      'bySetPos alone': (RecurrenceRule(freq: Frequency.monthly, bySetPos: const [1]), [RuleIssueCode.unsupportedCombo]),
      'values out of range': (
        RecurrenceRule(
          byMonthDay: const [0, 32],
          byMonth: const [13],
          byHour: const [24],
          byMinute: const [60],
          freq: Frequency.yearly,
          byYearDay: const [367],
          bySetPos: const [0],
        ),
        [RuleIssueCode.valueOutOfRange],
      ),
      'weekday ordinal 0': (
        RecurrenceRule(freq: Frequency.monthly, byWeekday: const [WeekdayRule(Weekday.monday, 0)]),
        [RuleIssueCode.valueOutOfRange],
      ),
      'invalid exdate': (RecurrenceRule(exdates: const ['soon'], rdates: const ['2026-13-01']), [RuleIssueCode.invalidDate]),
      'quota missing': (RecurrenceRule(type: RuleType.quota), [RuleIssueCode.missingField]),
      'quota impossible (8 per week, min gap 1)': (
        RecurrenceRule.forQuota(8, PeriodUnit.week, minGapDays: 1),
        [RuleIssueCode.quotaImpossible],
      ),
      'quota impossible (4 per week, weekdays, min gap 1)': (
        RecurrenceRule.forQuota(4, PeriodUnit.week, minGapDays: 1, byWeekday: _weekdays),
        [RuleIssueCode.quotaImpossible],
      ),
      'quota 3 per week on weekdays, min gap 1 is fine': (
        RecurrenceRule.forQuota(3, PeriodUnit.week, minGapDays: 1, byWeekday: _weekdays),
        [],
      ),
      'quota 15 per month with min gap 1': (
        RecurrenceRule.forQuota(15, PeriodUnit.month, minGapDays: 1),
        [RuleIssueCode.quotaImpossible],
      ),
      'quota 14 per month with min gap 1 is fine': (RecurrenceRule.forQuota(14, PeriodUnit.month, minGapDays: 1), []),
      'quota 2 per day with min gap': (
        RecurrenceRule.forQuota(2, PeriodUnit.day, minGapDays: 1),
        [RuleIssueCode.quotaImpossible],
      ),
      'quota 200 per year with min gap 1': (
        RecurrenceRule.forQuota(200, PeriodUnit.year, minGapDays: 1),
        [RuleIssueCode.quotaImpossible],
      ),
      'quota 8 per week without gap is fine': (RecurrenceRule.forQuota(8, PeriodUnit.week), []),
      'quota with empty weekdays': (
        RecurrenceRule.forQuota(1, PeriodUnit.week, byWeekday: const [], minGapDays: 1),
        [RuleIssueCode.emptyWeekdaySet],
      ),
      'quota times 0': (RecurrenceRule.forQuota(0, PeriodUnit.week), [RuleIssueCode.valueOutOfRange]),
      'after completion missing': (RecurrenceRule(type: RuleType.afterCompletion), [RuleIssueCode.missingField]),
      'after completion amount 0': (
        RecurrenceRule.forAfterCompletion(0, RecurrenceUnit.day),
        [RuleIssueCode.valueOutOfRange],
      ),
      'every minute is not too frequent': (RecurrenceRule(freq: Frequency.minutely), []),
    };
    for (final entry in table.entries) {
      test(entry.key, () {
        expect(codes(entry.value.$1, anchor: anchor), entry.value.$2);
      });
    }

    test('tooFrequent uses the configured density limit', () {
      expect(codes(RecurrenceRule(freq: Frequency.minutely, interval: 5), max: 288), isEmpty);
      expect(codes(RecurrenceRule(freq: Frequency.minutely, interval: 4), max: 288), [RuleIssueCode.tooFrequent]);
      expect(
        codes(
          RecurrenceRule(freq: Frequency.minutely, interval: 5, window: DailyWindow(LocalTime(8, 0), LocalTime(9, 0))),
          max: 12,
        ),
        [RuleIssueCode.tooFrequent],
      );
      expect(
        codes(
          RecurrenceRule(
            freq: Frequency.hourly,
            byMinute: const [0, 15, 30, 45],
            window: DailyWindow(LocalTime(8, 0), LocalTime(9, 59), anchor: WindowAnchor.seriesStart),
          ),
          max: 7,
        ),
        [RuleIssueCode.tooFrequent],
      );
      expect(codes(RecurrenceRule(times: [LocalTime(8, 0), LocalTime(9, 0)]), max: 1), [RuleIssueCode.tooFrequent]);
      expect(codes(RecurrenceRule(byHour: const [8, 9], byMinute: const [0, 30]), max: 3), [RuleIssueCode.tooFrequent]);
      expect(
        codes(RecurrenceRule(freq: Frequency.minutely, window: DailyWindow(LocalTime(9, 0), LocalTime(8, 0)))),
        [RuleIssueCode.windowEndBeforeStart],
      );
    });

    test('warnings and result helpers', () {
      final result = RecurrenceRule(freq: Frequency.hourly).validate(
        anchor: RecurrenceAnchor.allDayOn(LocalDate(2026, 9, 21), null),
      );
      expect(result.isValid, isTrue);
      expect(result.warnings.single.code, RuleIssueCode.unsupportedCombo);
      expect(result.errors, isEmpty);
      expect(result.has(RuleIssueCode.unsupportedCombo), isTrue);
      expect(result.toString(), contains('unsupportedCombo'));
      final issue = RecurrenceRule(interval: 0).validate().issues.single;
      expect(issue.field, 'interval');
      expect(issue.params, {'value': 0});
      expect(issue.toString(), 'RuleIssue(intervalInvalid @interval {value: 0})');
      expect(issue, RuleIssue(RuleIssueCode.intervalInvalid, field: 'interval'));
      expect(issue.hashCode, RuleIssue(RuleIssueCode.intervalInvalid, field: 'interval').hashCode);
      expect(const RuleValidator().validate(RecurrenceRule()).isValid, isTrue);
    });
  });
}
