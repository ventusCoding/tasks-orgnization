import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/planner/domain/quick_parse.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

/// T8.1.17: natural-language quick add — fixture-driven (EN + FR), ≥ 95 % of the phrases must parse
/// to the expected structure.
void main() {
  final fixture =
      jsonDecode(File('test/features/planner/fixtures/quick_parse.json').readAsStringSync()) as Map<String, Object?>;
  final now = LocalDateTime.parse(fixture['now']! as String);
  final cases = (fixture['cases']! as List).cast<Map<String, Object?>>();

  String two(int v) => v.toString().padLeft(2, '0');

  Map<String, Object?> actual(QuickParse p) {
    final r = p.rule;
    return {
      'title': p.title,
      'date': p.date?.toString(),
      'time': p.time == null ? null : '${two(p.time!.hour)}:${two(p.time!.minute)}',
      'duration': p.durationMinutes,
      'allDay': p.allDay,
      'rule': r == null
          ? null
          : {
              'freq': r.freq.name,
              'interval': r.interval,
              if (r.byWeekday case final days? when days.isNotEmpty)
                'byWeekday': [for (final d in days) '${d.n ?? ''}${d.day.code}'],
              if (r.byMonthDay.isNotEmpty) 'byMonthDay': r.byMonthDay,
              if (r.count != null) 'count': r.count,
              if (r.until != null) 'until': r.until!.date.toString(),
            },
      'category': p.category,
      'priority': p.priority?.name,
    };
  }

  Map<String, Object?> expected(Map<String, Object?> c) => {
    for (final k in ['title', 'date', 'time', 'duration', 'allDay', 'rule', 'category', 'priority']) k: c[k],
  };

  test('fixture: at least 95 % of ${cases.length} phrases parse as expected', () {
    expect(cases.length, greaterThanOrEqualTo(200));
    final failures = <String>[];
    for (final c in cases) {
      final got = jsonEncode(actual(QuickParser.parse(c['in']! as String, now: now)));
      final want = jsonEncode(expected(c));
      if (got != want) failures.add('${c['in']}\n  want $want\n  got  $got');
    }
    final rate = 1 - failures.length / cases.length;
    if (failures.isNotEmpty) printOnFailure(failures.join('\n'));
    // ignore: avoid_print
    print('quick parse: ${(rate * 100).toStringAsFixed(1)} % (${failures.length} misses)\n${failures.join('\n')}');
    expect(rate, greaterThanOrEqualTo(0.95));
  });

  test('spans cover the recognized parts in order, for live highlighting', () {
    const input = 'Gym tomorrow 7pm for 1h every Mon and Wed #health !high';
    final p = QuickParser.parse(input, now: now);
    expect(
      [for (final s in p.spans) '${s.kind.name}:${input.substring(s.start, s.end)}'],
      [
        'date:tomorrow',
        'time:7pm',
        'duration:for 1h',
        'recurrence:every Mon and Wed',
        'category:#health',
        'priority:!high',
      ],
    );
    expect(p.recognizedAnything, isTrue);
    expect(p.start, LocalDateTime.parse('2026-09-23T19:00'));
  });

  test('plain titles stay untouched', () {
    for (final t in ['Buy milk', 'Read Sun Tzu', 'Fix the mon-key bug', 'Sea trip with Mar', 'Plan B', 'Call mom!']) {
      final p = QuickParser.parse(t, now: now);
      expect(p.title, t, reason: t);
      expect(p.recognizedAnything, isFalse, reason: t);
    }
  });

  test('a week starting on Sunday shifts "next week"', () {
    final p = QuickParser.parse('Plan next week', now: now, weekStart: Weekday.sunday);
    expect(p.date, LocalDate(2026, 9, 27));
    expect(p.rule, isNull);
  });
}
