import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

LocalDateTime dt(String s) => LocalDateTime.parse(s);
LocalDate d(String s) => LocalDate.parse(s);

void main() {
  tzdata.initializeTimeZones();
  final resolver = TzZoneResolver();
  final engine = RecurrenceEngine(resolver);
  final paris = RecurrenceAnchor(dt('2026-09-21T08:00'), 'Europe/Paris');
  final daily = RecurrenceRule();

  List<String> keys(Iterable<Occurrence> occurrences) => [for (final o in occurrences) o.key];

  group('between', () {
    test('is lazy, ordered and capped', () {
      final capped = RecurrenceEngine(resolver, maxOccurrencesPerCall: 5);
      final result = capped.between(daily, paris, dt('2026-09-21T00:00'), dt('2026-10-21T00:00'));
      expect(result.take(5).length, 5);
      expect(result.toList, throwsA(isA<RecurrenceLimitExceeded>()));
      expect(RecurrenceLimitExceeded(5).toString(), contains('more than 5'));
      expect(capped.between(daily, paris, dt('2026-09-21T00:00'), dt('2026-10-21T00:00'), limit: 7).length, 7);
      expect(capped.between(daily, paris, dt('2026-09-21T00:00'), dt('2026-10-21T00:00'), limit: 0), isEmpty);
      expect(capped.countBetween(daily, paris, dt('2026-09-21T00:00'), dt('2026-10-21T00:00')), 30);
    });

    test('rejects rules that cannot be expanded', () {
      expect(
        () => engine.between(RecurrenceRule(interval: 0), paris, dt('2026-09-21T00:00'), dt('2026-09-22T00:00')),
        throwsA(isA<InvalidRuleException>().having((e) => e.toString(), 'message', contains('intervalInvalid'))),
      );
      expect(
        () => engine.nextDue(RecurrenceRule.forAfterCompletion(0, RecurrenceUnit.day), paris, null),
        throwsA(isA<InvalidRuleException>()),
      );
      expect(() => engine.nextDue(daily, paris, null), throwsArgumentError);
      expect(() => engine.periods(daily, paris, d('2026-01-01'), d('2026-02-01')), throwsArgumentError);
    });

    test('an empty or reversed range yields nothing', () {
      expect(engine.between(daily, paris, dt('2026-09-25T00:00'), dt('2026-09-25T00:00')), isEmpty);
      expect(engine.between(daily, paris, dt('2026-09-26T00:00'), dt('2026-09-25T00:00')), isEmpty);
      final allDay = RecurrenceAnchor.allDayOn(d('2026-09-21'), null);
      expect(engine.between(daily, allDay, dt('2026-09-26T00:00'), dt('2026-09-25T00:00')), isEmpty);
    });

    test('occurrence fields', () {
      final o = engine.between(daily, paris.copyWith(durationMinutes: 90), dt('2026-09-21T00:00'), dt('2026-09-22T00:00')).single;
      expect(o.key, '2026-09-21T08:00');
      expect(o.startUtc, DateTime.utc(2026, 9, 21, 6));
      expect(o.endUtc, DateTime.utc(2026, 9, 21, 7, 30));
      expect(o.duration, const Duration(minutes: 90));
      expect(o.date, d('2026-09-21'));
      expect(o.zoneId, 'Europe/Paris');
      expect(o.isAllDay, isFalse);
      expect(o.resolutionKind, ResolutionKind.exact);
      expect(o.toString(), contains('2026-09-21T08:00'));
      expect(o, engine.occurrenceForKey(daily, paris.copyWith(durationMinutes: 90), '2026-09-21T08:00'));
      expect(o.hashCode, isA<int>());
    });

    test('floating rules follow the evaluation zone after travel', () {
      final floating = RecurrenceAnchor(dt('2026-09-21T08:00'), null);
      final tokyo = engine.between(daily, floating, dt('2026-09-22T00:00'), dt('2026-09-23T00:00'), evalZone: 'Asia/Tokyo');
      final ny = engine.between(daily, floating, dt('2026-09-22T00:00'), dt('2026-09-23T00:00'), evalZone: 'America/New_York');
      expect(tokyo.single.startUtc, DateTime.utc(2026, 9, 21, 23));
      expect(ny.single.startUtc, DateTime.utc(2026, 9, 22, 12));
      expect(engine.between(daily, floating, dt('2026-09-22T00:00'), dt('2026-09-23T00:00')).single.zoneId, 'UTC');
    });

    test('long occurrences overlapping the range start are returned', () {
      final night = RecurrenceAnchor(dt('2026-09-21T22:00'), 'UTC', durationMinutes: 600);
      expect(keys(engine.between(daily, night, dt('2026-09-23T00:00'), dt('2026-09-23T12:00'))), ['2026-09-22T22:00']);
      expect(
        keys(engine.between(daily, night, dt('2026-09-23T00:00'), dt('2026-09-23T12:00'), durationMinutes: 0)),
        isEmpty,
      );
    });

    test('betweenInstants for every rule type', () {
      expect(
        keys(engine.betweenInstants(daily, paris, DateTime.utc(2026, 9, 22), DateTime.utc(2026, 9, 24))),
        ['2026-09-22T08:00', '2026-09-23T08:00'],
      );
      final quota = RecurrenceRule.forQuota(2, PeriodUnit.day);
      expect(
        keys(engine.betweenInstants(quota, paris, DateTime.utc(2026, 9, 22), DateTime.utc(2026, 9, 23))),
        ['day:2026-09-22#1', 'day:2026-09-22#2'],
      );
      final after = RecurrenceRule.forAfterCompletion(1, RecurrenceUnit.day);
      expect(
        keys(engine.betweenInstants(after, paris, DateTime.utc(2026, 9, 21), DateTime.utc(2026, 9, 22))),
        ['2026-09-21T08:00'],
      );
      expect(
        keys(engine.betweenInstants(after, paris.copyWith(durationMinutes: 60), DateTime.utc(2026, 9, 21, 6, 30), DateTime.utc(2026, 9, 22))),
        ['2026-09-21T08:00'],
      );
    });

    test('after-completion between yields the first due only', () {
      final after = RecurrenceRule.forAfterCompletion(1, RecurrenceUnit.day);
      expect(keys(engine.between(after, paris, dt('2026-09-01T00:00'), dt('2026-10-01T00:00'))), ['2026-09-21T08:00']);
      expect(engine.between(after, paris, dt('2026-09-22T00:00'), dt('2026-10-01T00:00')), isEmpty);
      final allDay = RecurrenceAnchor.allDayOn(d('2026-09-21'), 'UTC');
      expect(keys(engine.between(after, allDay, dt('2026-09-21T12:00'), dt('2026-09-22T00:00'))), ['2026-09-21']);
    });

    test('all-day occurrences span whole days in their zone', () {
      final allDay = RecurrenceAnchor.allDayOn(d('2026-03-28'), 'Europe/Paris');
      final o = engine.between(daily, allDay, dt('2026-03-29T00:00'), dt('2026-03-30T00:00')).single;
      expect(o.key, '2026-03-29');
      expect(o.isAllDay, isTrue);
      expect(o.startUtc, DateTime.utc(2026, 3, 28, 23));
      expect(o.endUtc, DateTime.utc(2026, 3, 29, 22));
    });
  });

  group('nextAfter / previousBefore', () {
    test('basic navigation', () {
      final next = engine.nextAfter(daily, paris, DateTime.utc(2026, 9, 25, 6));
      expect(next!.key, '2026-09-26T08:00');
      expect(engine.nextAfter(daily, paris, DateTime.utc(2026, 9, 25, 6), inclusive: true)!.key, '2026-09-25T08:00');
      expect(engine.nextAfter(daily, paris, DateTime.utc(2020))!.key, '2026-09-21T08:00');
      expect(engine.previousBefore(daily, paris, DateTime.utc(2026, 9, 25, 6))!.key, '2026-09-24T08:00');
      expect(engine.previousBefore(daily, paris, DateTime.utc(2026, 9, 25, 6), inclusive: true)!.key, '2026-09-25T08:00');
      expect(engine.previousBefore(daily, paris, DateTime.utc(2026, 9, 21, 6)), isNull);
    });

    test('bounded series', () {
      final counted = RecurrenceRule(freq: Frequency.weekly, count: 3);
      expect(engine.nextAfter(counted, paris, DateTime.utc(2026, 10, 6)), isNull);
      expect(engine.previousBefore(counted, paris, DateTime.utc(2030))!.key, '2026-10-05T08:00');
      final until = RecurrenceRule(until: dt('2026-09-23T08:00'));
      expect(engine.nextAfter(until, paris, DateTime.utc(2026, 9, 23, 7)), isNull);
      final withRdate = RecurrenceRule(count: 1, rdates: const ['2026-01-05T09:00']);
      expect(engine.previousBefore(withRdate, paris, DateTime.utc(2026, 9, 1))!.key, '2026-01-05T09:00');
    });

    test('rare and impossible rules', () {
      final leap = RecurrenceRule(freq: Frequency.yearly);
      final feb29 = RecurrenceAnchor(dt('2096-02-29T09:00'), 'UTC');
      expect(engine.nextAfter(leap, feb29, DateTime.utc(2096, 3))!.key, '2104-02-29T09:00');
      expect(engine.previousBefore(leap, feb29, DateTime.utc(2104))!.key, '2096-02-29T09:00');
      final never = RecurrenceRule(freq: Frequency.monthly, byMonth: const [2], byMonthDay: const [30]);
      final short = RecurrenceEngine(resolver, maxSearchYears: 20);
      expect(short.nextAfter(never, paris, DateTime.utc(2026)), isNull);
      expect(short.previousBefore(never, paris, DateTime.utc(2040)), isNull);
      final neverMinutely = RecurrenceRule(freq: Frequency.minutely, interval: 30, byMonth: const [2], byMonthDay: const [30]);
      expect(short.nextAfter(neverMinutely, paris, DateTime.utc(2026)), isNull);
    });

    test('quota and after-completion rules', () {
      final quota = RecurrenceRule.forQuota(1, PeriodUnit.week);
      final monday = RecurrenceAnchor(dt('2026-09-21T09:00'), 'UTC');
      expect(engine.nextAfter(quota, monday, DateTime.utc(2026, 9, 22))!.key, 'week:2026-09-28#1');
      expect(engine.previousBefore(quota, monday, DateTime.utc(2026, 10, 6))!.key, 'week:2026-10-05#1');
      final after = RecurrenceRule.forAfterCompletion(2, RecurrenceUnit.day);
      expect(engine.nextAfter(after, monday, DateTime.utc(2026))!.key, '2026-09-21T09:00');
      expect(engine.nextAfter(after, monday, DateTime.utc(2027)), isNull);
      expect(engine.previousBefore(after, monday, DateTime.utc(2027))!.key, '2026-09-21T09:00');
      expect(engine.previousBefore(after, monday, DateTime.utc(2025)), isNull);
    });
  });

  group('occurs', () {
    final rule = RecurrenceRule(
      freq: Frequency.weekly,
      byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.wednesday)],
      exdates: const ['2026-09-23T08:00'],
      rdates: const ['2026-09-26T10:00'],
    );

    test('fixed rules', () {
      expect(engine.occurs(rule, paris, '2026-09-21T08:00'), isTrue);
      expect(engine.occurs(rule, paris, '2026-09-23T08:00'), isFalse);
      expect(engine.occurs(rule, paris, '2026-09-26T10:00'), isTrue);
      expect(engine.occurs(rule, paris, '2026-09-22T08:00'), isFalse);
      expect(engine.occurs(rule, paris, '2026-09-21'), isFalse);
      expect(engine.occurs(rule, paris, '2026-09-21 08:00'), isFalse);
      expect(engine.occurs(rule, paris, 'garbage'), isFalse);
      final allDay = RecurrenceAnchor.allDayOn(d('2026-09-21'), null);
      expect(engine.occurs(rule, allDay, '2026-09-28'), isTrue);
      expect(engine.occurs(rule, allDay, '2026-09-28T00:00'), isFalse);
      expect(engine.occurs(rule, allDay, '2026-09-29'), isFalse);
    });

    test('quota keys', () {
      final quota = RecurrenceRule.forQuota(3, PeriodUnit.week);
      final thursday = RecurrenceAnchor(dt('2026-09-24T09:00'), 'UTC');
      expect(engine.occurs(quota, thursday, 'week:2026-09-21#2'), isTrue);
      expect(engine.occurs(quota, thursday, 'week:2026-09-21#3'), isFalse);
      expect(engine.occurs(quota, thursday, 'week:2026-09-28#3'), isTrue);
      expect(engine.occurs(quota, thursday, 'week:2026-09-28'), isFalse);
      expect(engine.occurs(quota, thursday, 'week:2026-09-28#x'), isFalse);
      expect(engine.occurs(quota, thursday, 'fortnight:2026-09-28#1'), isFalse);
      expect(engine.occurs(quota, thursday, 'week2026#1'), isFalse);
      final monthly = RecurrenceRule.forQuota(2, PeriodUnit.month);
      expect(engine.occurs(monthly, thursday, 'month:2026-10#2'), isTrue);
      final yearly = RecurrenceRule.forQuota(2, PeriodUnit.year);
      expect(engine.occurs(yearly, thursday, 'year:2027#1'), isTrue);
    });

    test('after-completion keys', () {
      final after = RecurrenceRule.forAfterCompletion(2, RecurrenceUnit.day);
      expect(engine.occurs(after, paris, '2026-09-21T08:00'), isTrue);
      expect(engine.occurs(after, paris, '2026-09-23T08:00'), isFalse);
      final allDay = RecurrenceAnchor.allDayOn(d('2026-09-21'), null);
      expect(engine.occurs(after, allDay, '2026-09-21'), isTrue);
    });
  });

  group('quota periods', () {
    final quota = RecurrenceRule.forQuota(3, PeriodUnit.week);
    final thursday = RecurrenceAnchor(dt('2026-09-24T09:00'), 'Europe/Paris');

    test('first partial week is pro-rated (arch example)', () {
      final periods = engine.periods(quota, thursday, d('2026-09-01'), d('2026-10-04'));
      expect(periods.first.key, 'week:2026-09-21');
      expect(periods.first.target, closeTo(3 * 4 / 7, 1e-12));
      expect(periods.first.requiredCount, 2);
      expect(periods.first.isPartial, isTrue);
      expect(periods.first.activeStart, d('2026-09-24'));
      expect(periods[1].target, 3);
      expect(periods[1].requiredCount, 3);
      expect(periods[1].isPartial, isFalse);
      expect(periods[1].completionKey(2), 'week:2026-09-28#2');
      expect(periods.first.toString(), contains('1.714'));
      expect(periods.first, engine.periods(quota, thursday, d('2026-09-21'), d('2026-09-21')).single);
      expect(periods.first.hashCode, isA<int>());
    });

    test('week start shifts keys', () {
      expect(engine.periods(quota, thursday, d('2026-09-24'), d('2026-09-30'), weekStart: Weekday.saturday).first.key,
          'week:2026-09-19');
      expect(engine.periods(quota, thursday, d('2026-09-24'), d('2026-09-30'), weekStart: Weekday.sunday).first.key,
          'week:2026-09-20');
      final sundayRule = RecurrenceRule.forQuota(3, PeriodUnit.week).copyWith(wkst: Weekday.sunday);
      expect(engine.periods(sundayRule, thursday, d('2026-09-24'), d('2026-09-30')).first.key, 'week:2026-09-20');
    });

    test('month periods of 28 to 31 days', () {
      final monthly = RecurrenceRule.forQuota(20, PeriodUnit.month);
      final start = RecurrenceAnchor(dt('2026-01-01T09:00'), 'UTC');
      final periods = engine.periods(monthly, start, d('2026-01-01'), d('2026-04-30'));
      expect([for (final p in periods) p.key], ['month:2026-01', 'month:2026-02', 'month:2026-03', 'month:2026-04']);
      expect([for (final p in periods) p.periodDays], [31, 28, 31, 30]);
      expect(engine.periods(monthly, start, d('2028-02-01'), d('2028-02-01')).single.periodDays, 29);
    });

    test('excluded days and until reduce the target', () {
      final monday = RecurrenceAnchor(dt('2026-09-21T09:00'), 'UTC');
      final excused = engine.periods(
        quota,
        monday,
        d('2026-09-21'),
        d('2026-09-27'),
        isExcluded: (day) => day.weekday == Weekday.saturday || day.weekday == Weekday.sunday,
      );
      expect(excused.single.eligibleDays, 5);
      expect(excused.single.target, closeTo(15 / 7, 1e-12));
      final ending = quota.copyWith(until: dt('2026-09-23T23:59'));
      final last = engine.periods(ending, monday, d('2026-09-21'), d('2026-12-31'));
      expect(last.single.activeEnd, d('2026-09-23'));
      expect(last.single.requiredCount, 2);
      final weekdaysOnly = RecurrenceRule.forQuota(
        5,
        PeriodUnit.week,
        byWeekday: [for (final w in Weekday.values.take(5)) WeekdayRule(w)],
      );
      final p = engine.periods(weekdaysOnly, monday, d('2026-09-21'), d('2026-09-27')).single;
      expect(p.periodDays, 5);
      expect(p.requiredCount, 5);
      final noEligible = RecurrenceRule.forQuota(1, PeriodUnit.week, byWeekday: const []);
      expect(engine.periods(noEligible, monday, d('2026-09-21'), d('2026-09-27')).single.target, 0);
    });

    test('day and year periods', () {
      final perDay = RecurrenceRule.forQuota(2, PeriodUnit.day);
      final start = RecurrenceAnchor(dt('2026-09-21T09:00'), 'UTC');
      expect(engine.periods(perDay, start, d('2026-09-21'), d('2026-09-22')).map((p) => p.key), [
        'day:2026-09-21',
        'day:2026-09-22',
      ]);
      final perYear = RecurrenceRule.forQuota(100, PeriodUnit.year);
      final july = RecurrenceAnchor(dt('2026-07-01T09:00'), 'UTC');
      final year = engine.periods(perYear, july, d('2026-01-01'), d('2026-12-31')).single;
      expect(year.key, 'year:2026');
      expect(year.requiredCount, (100 * 184 / 365).ceil());
    });

    test('quota slots are all-day for all-day anchors', () {
      final allDay = RecurrenceAnchor.allDayOn(d('2026-09-21'), null);
      final slots = engine.between(RecurrenceRule.forQuota(1, PeriodUnit.week), allDay, dt('2026-09-21T00:00'),
          dt('2026-09-28T00:00'));
      expect(slots.single.key, 'week:2026-09-21#1');
      expect(slots.single.isAllDay, isTrue);
      expect(engine.between(RecurrenceRule.forQuota(1, PeriodUnit.week), allDay, dt('2026-09-21T00:00'),
          dt('2026-09-21T00:00')), isEmpty);
    });
  });

  group('nextDue', () {
    final start = RecurrenceAnchor(dt('2026-01-31T09:00'), 'Europe/Paris');
    DateTime at(String local) => resolver.resolve(dt(local), 'Europe/Paris').utc;

    test('each unit', () {
      String? due(int amount, RecurrenceUnit unit, String completion) =>
          engine.nextDue(RecurrenceRule.forAfterCompletion(amount, unit), start, at(completion))?.key;
      expect(due(30, RecurrenceUnit.minute, '2026-02-01T10:45'), '2026-02-01T11:15');
      expect(due(3, RecurrenceUnit.hour, '2026-02-01T22:30'), '2026-02-02T01:30');
      expect(due(2, RecurrenceUnit.day, '2026-02-01T22:30'), '2026-02-03T09:00');
      expect(due(1, RecurrenceUnit.week, '2026-02-01T07:00'), '2026-02-08T09:00');
      expect(due(1, RecurrenceUnit.month, '2026-01-31T12:00'), '2026-02-28T09:00');
      expect(due(1, RecurrenceUnit.year, '2028-02-29T12:00'), '2029-02-28T09:00');
      expect(engine.nextDue(RecurrenceRule.forAfterCompletion(1, RecurrenceUnit.day), start, null)!.key,
          '2026-01-31T09:00');
    });

    test('late completion shifts, early completion brings forward, until stops', () {
      final rule = RecurrenceRule.forAfterCompletion(2, RecurrenceUnit.day, until: dt('2026-02-10T23:59'));
      expect(engine.nextDue(rule, start, at('2026-02-05T20:00'))!.key, '2026-02-07T09:00');
      expect(engine.nextDue(rule, start, at('2026-02-01T06:00'))!.key, '2026-02-03T09:00');
      expect(engine.nextDue(rule, start, at('2026-02-09T06:00')), isNull);
      final allDay = RecurrenceAnchor.allDayOn(d('2026-01-31'), null);
      expect(engine.nextDue(rule, allDay, DateTime.utc(2026, 2, 1, 23))!.key, '2026-02-03');
    });
  });

  test('plans are cached per rule and anchor', () {
    final rule = RecurrenceRule(freq: Frequency.weekly);
    expect(identical(engine.planFor(rule, paris), engine.planFor(rule, paris)), isTrue);
    final other = paris.copyWith(start: dt('2026-09-22T08:00'));
    expect(identical(engine.planFor(rule, paris), engine.planFor(rule, other)), isFalse);
    expect(engine.zoneFor(RecurrenceAnchor(dt('2026-01-01T00:00'), null), null), 'UTC');
    expect(engine.viewZoneFor(paris, null), 'Europe/Paris');
  });
}
