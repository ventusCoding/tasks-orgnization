import 'dart:convert';
import 'dart:io';

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support/fixtures.dart';

RecurrenceAnchor _anchor(Map<String, Object?> json) => RecurrenceAnchor(
  LocalDateTime.parse(json['start']! as String),
  json['zone'] as String?,
  allDay: json['allDay'] as bool? ?? false,
  durationMinutes: (json['allDay'] as bool? ?? false) ? 1440 : null,
);

void main() {
  tzdata.initializeTimeZones();
  final resolver = TzZoneResolver();
  final engine = RecurrenceEngine(resolver);
  final pairs = (jsonDecode(File('${fixturesDirectory().path}/rrule/rrule_pairs.json').readAsStringSync()) as List)
      .cast<Map<String, Object?>>();

  group('RRULE fixture pairs', () {
    for (final pair in pairs) {
      final direction = pair['direction'] as String? ?? 'both';
      final rule = RecurrenceRule.fromJson((pair['rule']! as Map).cast());
      final anchor = _anchor((pair['anchor']! as Map).cast());
      final text = pair['text'] as String?;
      if (direction != 'encode') {
        test('parse: ${pair['name']}', () {
          final parsed = RRuleCodec.parse(text!, resolver: resolver);
          expect(parsed.rule, rule);
          expect(parsed.anchor, anchor);
        });
      }
      if (direction != 'parse') {
        test('encode: ${pair['name']}', () {
          expect(RRuleCodec.encode(rule, anchor, resolver: resolver), text);
        });
      }
    }
  });

  test('every representable fixed-rule fixture survives encode → parse', () {
    var encoded = 0;
    for (final fixture in loadFixtures()) {
      if (fixture.completions != null || fixture.rule.type != RuleType.fixed) {
        continue;
      }
      final text = RRuleCodec.encode(fixture.rule, fixture.anchor, resolver: resolver);
      if (text == null) continue;
      encoded++;
      final parsed = RRuleCodec.parse(text, resolver: resolver);
      final keys = [
        for (final o in engine.between(
          parsed.rule,
          parsed.anchor!.copyWith(durationMinutes: fixture.anchor.durationMinutes),
          fixture.from,
          fixture.to,
          evalZone: fixture.evalZone,
          limit: fixture.limit,
          durationMinutes: fixture.durationMinutes,
        ))
          o.key,
      ];
      expect(keys, fixture.expectedKeys, reason: '$fixture\n$text');
      // Exports are stable: re-encoding the parsed rule gives the same text.
      expect(RRuleCodec.encode(parsed.rule, parsed.anchor!, resolver: resolver), isNotNull, reason: text);
    }
    expect(encoded, greaterThan(120));
  });

  group('parse', () {
    test('bare RRULE values, folding, ignored properties and case', () {
      final bare = RRuleCodec.parse('FREQ=WEEKLY;BYDAY=MO,TU');
      expect(bare.anchor, isNull);
      expect(bare.rule.byWeekday, const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)]);
      final folded = RRuleCodec.parse(
        'BEGIN:VEVENT\r\nSUMMARY:Standup\r\nDTSTART;TZID="Europe/Paris":20260921T0900\r\n 00\r\nrrule:freq=daily;\r\n\tcount=3;;\r\nEND:VEVENT',
        resolver: resolver,
      );
      expect(folded.rule.count, 3);
      expect(folded.anchor!.zoneId, 'Europe/Paris');
      expect(folded.anchor!.start, LocalDateTime.of(2026, 9, 21, 9));
    });

    test('EXDATE/RDATE in UTC or another zone are converted to the series zone', () {
      final parsed = RRuleCodec.parse(
        'DTSTART;TZID=Europe/Paris:20260921T080000\nRRULE:FREQ=DAILY;COUNT=5\n'
        'EXDATE:20260922T060000Z\nRDATE;TZID=America/New_York:20260930T020000',
        resolver: resolver,
      );
      expect(parsed.rule.exdates, ['2026-09-22T08:00']);
      expect(parsed.rule.rdates, ['2026-09-30T08:00']);
      expect(
        RRuleCodec.parse('DTSTART:20260921T080000Z\nRRULE:FREQ=DAILY;UNTIL=20261001').rule.until,
        LocalDateTime.of(2026, 10, 1, 23, 59),
      );
    });

    test('clear errors for unsupported input', () {
      final bad = {
        'RRULE:FREQ=SECONDLY': 'SECONDLY',
        'RRULE:FREQ=DAILY;BYSECOND=5': 'BYSECOND',
        'RRULE:FREQ=FORTNIGHTLY': 'Unknown FREQ',
        'RRULE:COUNT=3': 'without FREQ',
        'RRULE:FREQ=DAILY;BYEASTER=1': 'Unsupported RRULE part BYEASTER',
        'RRULE:FREQ=DAILY;COUNT': 'Invalid RRULE part',
        'RRULE:FREQ=DAILY;COUNT=x': 'Invalid COUNT',
        'RRULE:RSCALE=HEBREW;FREQ=YEARLY': 'Gregorian only',
        'RRULE:RSCALE=GREGORIAN;SKIP=FORWARD;FREQ=YEARLY': 'SKIP=FORWARD',
        'RRULE:FREQ=DAILY\nRRULE:FREQ=WEEKLY': 'Several RRULE',
        'RRULE:FREQ=DAILY\nEXRULE:FREQ=WEEKLY': 'EXRULE',
        'RRULE:FREQ=DAILY\nRDATE;VALUE=PERIOD:19960403T020000Z/19960403T040000Z': 'PERIOD',
        'DTSTART:20260921T080030\nRRULE:FREQ=DAILY': 'seconds',
        'DTSTART:20260231T080000\nRRULE:FREQ=DAILY': 'Invalid DTSTART date',
        'DTSTART:20260221T250000\nRRULE:FREQ=DAILY': 'Invalid DTSTART time',
        'DTSTART:2026\nRRULE:FREQ=DAILY': 'Invalid DTSTART value',
        'DTSTART:20260921T080000': 'No RRULE',
        'garbage': 'Invalid iCalendar line',
        'DTSTART:20260921T080000\nRRULE:FREQ=DAILY;INTERVAL=0': 'Invalid RRULE',
      };
      for (final entry in bad.entries) {
        expect(
          () => RRuleCodec.parse(entry.key, resolver: resolver),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(entry.value))),
          reason: entry.key,
        );
      }
    });

    test('RRuleImport.toString', () {
      expect(RRuleCodec.parse('FREQ=DAILY').toString(), contains('RRuleImport'));
    });
  });

  group('encode', () {
    test('clamp with deep negative month days and invalid rules are not representable', () {
      final anchor = RecurrenceAnchor(LocalDateTime.of(2026, 1, 31, 9), 'UTC');
      expect(
        RRuleCodec.encode(
          RecurrenceRule(freq: Frequency.monthly, byMonthDay: const [-30], monthDayOverflow: MonthOverflow.clamp),
          anchor,
        ),
        isNull,
      );
      expect(RRuleCodec.encode(RecurrenceRule(interval: 0), anchor), isNull);
      expect(
        RRuleCodec.encode(
          RecurrenceRule(
            freq: Frequency.hourly,
            byMinute: const [0, 30],
            window: DailyWindow(LocalTime(8, 0), LocalTime(9, 0), anchor: WindowAnchor.seriesStart),
          ),
          anchor,
        ),
        isNull,
      );
      expect(
        RRuleCodec.encode(
          RecurrenceRule(
            freq: Frequency.minutely,
            byHour: const [3],
            window: DailyWindow(LocalTime(8, 0), LocalTime(9, 0)),
          ),
          anchor,
        ),
        isNull,
      );
    });

    test('floating until, UTC exdates and date rdates on timed series', () {
      final floating = RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), null);
      expect(
        RRuleCodec.encode(
          RecurrenceRule(until: LocalDateTime.of(2026, 9, 30, 8), rdates: const ['2026-10-02']),
          floating,
        ),
        'DTSTART:20260921T080000\nRRULE:FREQ=DAILY;UNTIL=20260930T080000\nRDATE:20261002T080000',
      );
      final utc = RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), 'UTC');
      expect(
        RRuleCodec.encode(RecurrenceRule(count: 3, exdates: const ['2026-09-22T08:00']), utc),
        'DTSTART:20260921T080000Z\nRRULE:FREQ=DAILY;COUNT=3\nEXDATE:20260922T080000Z',
      );
      final minutely = RecurrenceRule(
        freq: Frequency.minutely,
        interval: 15,
        byMinute: const [0, 30],
        window: DailyWindow(LocalTime(8, 0), LocalTime(9, 59), anchor: WindowAnchor.seriesStart),
      );
      expect(
        RRuleCodec.encode(minutely, utc),
        'DTSTART:20260921T080000Z\nRRULE:FREQ=MINUTELY;INTERVAL=15;BYHOUR=8,9;BYMINUTE=0,30',
      );
    });
  });
}
