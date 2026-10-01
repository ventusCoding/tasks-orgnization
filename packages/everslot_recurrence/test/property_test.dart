import 'dart:math';

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

const List<String?> _zones = [
  'UTC',
  'Europe/Paris',
  'America/New_York',
  'Australia/Lord_Howe',
  'Pacific/Chatham',
  'Asia/Tehran',
  'Africa/Tunis',
  null,
];

/// A random rule/anchor/range scenario (seeded, reproducible).
final class Scenario {
  new(this.seed, this.rule, this.anchor, this.evalZone, this.from, this.to);

  final int seed;
  final RecurrenceRule rule;
  final RecurrenceAnchor anchor;
  final String? evalZone;
  final LocalDateTime from;
  final LocalDateTime to;

  @override
  String toString() => 'seed $seed: $rule @ $anchor eval=$evalZone [$from, $to)';
}

T _pick<T>(Random r, List<T> values) => values[r.nextInt(values.length)];

List<T> _subset<T>(Random r, List<T> values, {int min = 1, int max = 3}) {
  final count = min + r.nextInt(max - min + 1);
  return (values.toList()..shuffle(r)).take(count).toList();
}

Scenario randomScenario(int seed, {bool allowAllDay = true}) {
  final r = Random(seed);
  final freq = _pick(r, Frequency.values);
  final start = LocalDateTime.of(
    2020 + r.nextInt(8),
    1 + r.nextInt(12),
    1 + r.nextInt(28),
    r.nextInt(24),
    _pick(r, [0, 15, 30, 45, 7]),
  );
  final zone = _pick(r, _zones);
  final allDay = allowAllDay && !freq.isSubDaily && r.nextInt(8) == 0;
  var rule = RecurrenceRule(
    freq: freq,
    interval: switch (freq) {
      Frequency.minutely => _pick(r, [15, 30, 45, 60, 90, 120, 7]),
      Frequency.hourly => 1 + r.nextInt(5),
      _ => 1 + r.nextInt(3),
    },
    wkst: _pick(r, [Weekday.monday, Weekday.sunday, Weekday.saturday]),
  );
  final monthly = freq == Frequency.monthly || freq == Frequency.yearly;
  switch (r.nextInt(6)) {
    case 0:
      rule = rule.copyWith(
        byWeekday: [
          for (final w in _subset(r, Weekday.values, max: 4))
            WeekdayRule(w, monthly && r.nextBool() ? _pick(r, [1, 2, -1, 3, -2]) : null),
        ],
      );
    case 1:
      if (freq != Frequency.weekly) {
        rule = rule.copyWith(byMonthDay: _subset(r, [1, 2, 15, 28, 29, 30, 31, -1, -2]));
      }
    case 2:
      rule = rule.copyWith(byMonth: _subset(r, List.generate(12, (i) => i + 1), max: 5));
    case 3:
      if (monthly) {
        rule = rule.copyWith(
          byWeekday: [for (final w in Weekday.values.take(5)) WeekdayRule(w)],
          bySetPos: [
            _pick(r, [1, -1, 2, -2]),
          ],
        );
      }
    case 4:
      if (!freq.isSubDaily) {
        rule = rule.copyWith(
          times: [
            for (final h in _subset(r, [6, 8, 12, 18, 23])) LocalTime(h, _pick(r, [0, 30])),
          ],
        );
      } else {
        rule = rule.copyWith(
          window: DailyWindow(
            LocalTime(6 + r.nextInt(6), 0),
            r.nextBool() ? LocalTime(18 + r.nextInt(5), 30) : LocalTime.endOfDay,
            anchor: _pick(r, WindowAnchor.values),
          ),
        );
      }
    default:
      break;
  }
  if (r.nextInt(4) == 0) {
    rule = rule.copyWith(monthDayOverflow: MonthOverflow.clamp);
  }
  final span = switch (freq) {
    Frequency.minutely => 2,
    Frequency.hourly => 6,
    Frequency.daily => 60,
    Frequency.weekly => 200,
    Frequency.monthly => 900,
    Frequency.yearly => 3000,
  };
  switch (r.nextInt(3)) {
    case 0:
      rule = rule.copyWith(count: 1 + r.nextInt(25));
    case 1:
      rule = rule.copyWith(until: start.plusDays(r.nextInt(span * 2)).plusMinutes(r.nextInt(1440)));
    default:
      break;
  }
  if (r.nextInt(3) == 0) {
    rule = rule.copyWith(
      rdates: [
        for (var i = 0; i < 2; i++) start.plusDays(r.nextInt(span) - span ~/ 4).plusMinutes(r.nextInt(600)).toIso(),
      ],
    );
  }
  final from = start.plusDays(r.nextInt(span) - span ~/ 3).plusMinutes(r.nextInt(1440));
  final to = from.plusDays(1 + r.nextInt(span)).plusMinutes(r.nextInt(1440));
  final anchor = allDay ? RecurrenceAnchor.allDayOn(start.date, zone) : RecurrenceAnchor(start, zone);
  return Scenario(seed, rule, anchor, zone == null ? _pick(r, ['Europe/Paris', 'Asia/Tokyo', 'UTC']) : null, from, to);
}

void main() {
  tzdata.initializeTimeZones();
  final resolver = TzZoneResolver();
  final engine = RecurrenceEngine(resolver);
  const iterations = 1000;

  test('between: sorted, unique, within range, respects until/count/exdates', () {
    for (var seed = 0; seed < iterations; seed++) {
      final s = randomScenario(seed);
      // Exclude some occurrences to check exdates.
      final first = engine.between(s.rule, s.anchor, s.from, s.to, evalZone: s.evalZone, limit: 6).toList();
      final exdates = [for (var i = 0; i < first.length; i += 2) first[i].key];
      final rule = s.rule.copyWith(exdates: exdates);
      final occurrences = engine.between(rule, s.anchor, s.from, s.to, evalZone: s.evalZone).toList();
      final keys = [for (final o in occurrences) o.key];
      for (var i = 1; i < keys.length; i++) {
        expect(keys[i].compareTo(keys[i - 1]), greaterThan(0), reason: '$s: not strictly sorted at $i ($keys)');
      }
      for (final k in exdates) {
        expect(keys, isNot(contains(k)), reason: '$s: exdate $k returned');
      }
      final rdates = {for (final r in rule.rdates) r.substring(0, s.anchor.allDay ? 10 : r.length)};
      final viewZone = engine.viewZoneFor(s.anchor, s.evalZone);
      final fromUtc = resolver.resolve(s.from, viewZone).utc;
      final toUtc = resolver.resolve(s.to, viewZone).utc;
      for (final o in occurrences) {
        if (s.anchor.allDay) {
          expect(o.startLocal.isBefore(s.to) && o.startLocal.plusDays(1).isAfter(s.from), isTrue, reason: '$s: $o');
        } else {
          expect(!o.startUtc.isBefore(fromUtc) && o.startUtc.isBefore(toUtc), isTrue, reason: '$s: $o out of range');
        }
        final isRdate = rdates.contains(o.key);
        if (!isRdate) {
          expect(
            o.startLocal.isBefore(s.anchor.allDay ? s.anchor.start.date.atStartOfDay : s.anchor.start),
            isFalse,
            reason: '$s: $o before anchor',
          );
          final until = rule.until;
          if (until != null) {
            expect(o.startLocal.isAfter(until), isFalse, reason: '$s: $o after until');
          }
        }
        expect(engine.occurs(rule, s.anchor, o.key), isTrue, reason: '$s: occurs(${o.key})');
      }
      final count = rule.count;
      if (count != null) {
        final all = engine
            .between(rule, s.anchor, LocalDateTime.of(1990, 1, 1), LocalDateTime.of(2100, 1, 1), evalZone: s.evalZone)
            .where((o) => !rdates.contains(o.key));
        expect(all.length, lessThanOrEqualTo(count), reason: '$s: count exceeded');
      }
      expect(engine.countBetween(rule, s.anchor, s.from, s.to, evalZone: s.evalZone), keys.length);
    }
  });

  test('nextAfter equals the first element of between; previousBefore the last', () {
    for (var seed = 0; seed < iterations; seed++) {
      final s = randomScenario(seed, allowAllDay: false);
      final viewZone = engine.viewZoneFor(s.anchor, s.evalZone);
      final x = resolver.resolve(s.from, viewZone).utc;
      final firstOfRange = engine.between(
        s.rule,
        s.anchor,
        s.from,
        s.from.plusDays(4000),
        evalZone: s.evalZone,
        limit: 1,
      );
      final next = engine.nextAfter(s.rule, s.anchor, x, evalZone: s.evalZone, inclusive: true);
      if (firstOfRange.isNotEmpty) {
        expect(next?.key, firstOfRange.first.key, reason: '$s: nextAfter');
      }
      final before = engine
          .between(s.rule, s.anchor, LocalDateTime.of(1990, 1, 1), s.from, evalZone: s.evalZone)
          .toList();
      final previous = engine.previousBefore(s.rule, s.anchor, x, evalZone: s.evalZone);
      expect(previous?.key, before.isEmpty ? null : before.last.key, reason: '$s: previousBefore');
    }
  });

  test('series split: union of both series equals the original set', () {
    final wall = RecurrenceEngine(const FixedOffsetZoneResolver());
    final splitter = SeriesSplitter(wall);
    var checked = 0;
    for (var seed = 0; seed < iterations; seed++) {
      final s = randomScenario(seed);
      final from = LocalDateTime.of(2015, 1, 1);
      final to = s.anchor.start.plusDays(switch (s.rule.freq) {
        Frequency.minutely => 3,
        Frequency.hourly => 12,
        Frequency.daily => 120,
        Frequency.weekly => 500,
        Frequency.monthly => 1500,
        Frequency.yearly => 6000,
      });
      List<String> keysOf(RecurrenceRule rule, RecurrenceAnchor anchor) => [
        for (final o in wall.between(rule, anchor, from, to)) o.key,
      ];
      final original = keysOf(s.rule, s.anchor);
      final plan = wall.planFor(s.rule, s.anchor);
      final generated = [
        for (final o in original)
          if (plan.ruleMinutes(o.startLocalMinute(s.anchor), o.startLocalMinute(s.anchor)).isNotEmpty) o,
      ];
      if (generated.length < 2) continue;
      final splitKey = generated[Random(seed).nextInt(generated.length)];
      final split = splitter.split(s.rule, s.anchor, splitKey);
      final truncated = split.truncatedRule;
      final union = <String>{
        if (truncated != null) ...keysOf(truncated, s.anchor),
        ...keysOf(split.newRule, split.newAnchor),
      }.toList()..sort();
      expect(union, original, reason: '$s split at $splitKey → $split');
      if (s.rule.count != null) {
        final counted = (truncated?.count ?? 0) + (split.newRule.count ?? 0);
        if (truncated?.until == null) {
          expect(counted, s.rule.count, reason: '$s: count kept');
        }
      }
      checked++;
    }
    expect(checked, greaterThan(iterations ~/ 3));
  });
}

extension on String {
  int startLocalMinute(RecurrenceAnchor anchor) =>
      (anchor.allDay ? LocalDate.parse(this).atStartOfDay : LocalDateTime.parse(this)).epochMinute;
}
