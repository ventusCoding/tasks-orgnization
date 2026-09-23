import 'dart:convert';
import 'dart:io';

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

/// Golden strings live in `fixtures/recurrence/describe/describer_golden.json`.
/// Regenerate after a reviewed wording change with
/// `UPDATE_GOLDENS=1 fvm dart test test/describer_test.dart`.
void main() {
  const describer = RecurrenceDescriber();
  final file = File(
    '${fixturesDirectory().path}/describe/describer_golden.json',
  );
  final cases = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, Object?>>();
  final update = Platform.environment['UPDATE_GOLDENS'] == '1';

  String run(Map<String, Object?> json, String locale) {
    final anchorJson = (json['anchor']! as Map).cast<String, Object?>();
    final options =
        (json['options'] as Map?)?.cast<String, Object?>() ?? const {};
    return describer.describe(
      RecurrenceRule.fromJson((json['rule']! as Map).cast()),
      RecurrenceAnchor(
        LocalDateTime.parse(anchorJson['start']! as String),
        anchorJson['zone'] as String?,
        allDay: anchorJson['allDay'] as bool? ?? false,
      ),
      locale: locale,
      use24h: options['use24h'] as bool? ?? true,
      weekStart: Weekday.fromCode(options['weekStart'] as String? ?? 'MO'),
    );
  }

  if (update) {
    test('update goldens', () {
      for (final c in cases) {
        c['expected'] = {
          for (final locale in RecurrenceDescriber.supportedLocales)
            locale: run(c, locale),
        };
      }
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(cases)}\n',
      );
    });
    return;
  }

  test('at least 40 rules are described in 3 locales', () {
    expect(cases.length, greaterThanOrEqualTo(40));
    for (final c in cases) {
      expect(
        (c['expected']! as Map).keys,
        containsAll(RecurrenceDescriber.supportedLocales),
        reason: '${c['name']}',
      );
    }
  });

  for (final c in cases) {
    for (final locale in RecurrenceDescriber.supportedLocales) {
      test('${c['name']} [$locale]', () {
        expect(run(c, locale), (c['expected']! as Map)[locale]);
      });
    }
  }

  group('plural rules', () {
    test('Arabic categories', () {
      expect(
        [
          for (final n in [
            0,
            1,
            2,
            3,
            10,
            11,
            99,
            100,
            101,
            102,
            103,
            111,
            200,
          ])
            pluralCategory('ar', n).name,
        ],
        [
          'zero',
          'one',
          'two',
          'few',
          'few',
          'many',
          'many',
          'other',
          'other',
          'other',
          'few',
          'many',
          'other',
        ],
      );
    });

    test('French and English categories', () {
      expect(pluralCategory('fr', 0), PluralCategory.one);
      expect(pluralCategory('fr', 1), PluralCategory.one);
      expect(pluralCategory('fr', 2), PluralCategory.other);
      expect(pluralCategory('fr_FR', 1000000), PluralCategory.many);
      expect(pluralCategory('en', 1), PluralCategory.one);
      expect(pluralCategory('en', 0), PluralCategory.other);
      expect(pluralCategory('de', 1), PluralCategory.one);
    });

    test('selectPlural falls back to other', () {
      expect(selectPlural('ar', 5, {'other': '{n} x'}), '5 x');
      expect(selectPlural('en', 1, {'one': 'one', 'other': 'many'}), 'one');
    });
  });

  test('unknown locales fall back to English; region subtags are accepted', () {
    final rule = RecurrenceRule(freq: Frequency.weekly);
    final anchor = RecurrenceAnchor(
      LocalDateTime.parse('2026-09-21T08:00'),
      null,
    );
    expect(
      describer.describe(rule, anchor, locale: 'de'),
      'Every Monday at 08:00',
    );
    expect(
      describer.describe(rule, anchor, locale: 'fr-CA'),
      'Tous les lundis à 08:00',
    );
    expect(
      describer.describe(rule, anchor, locale: 'ar_TN'),
      'أسبوعيًا يوم الاثنين في الساعة 08:00',
    );
  });

  test('12-hour clock covers midnight and noon', () {
    final rule = RecurrenceRule(times: [LocalTime(0, 0), LocalTime(12, 5)]);
    final anchor = RecurrenceAnchor(
      LocalDateTime.parse('2026-09-21T00:00'),
      null,
    );
    expect(
      describer.describe(rule, anchor, use24h: false),
      'Every day at 12:00 AM and 12:05 PM',
    );
    expect(
      describer.describe(rule, anchor, locale: 'ar', use24h: false),
      'كل يوم في الساعة 12:00 ص و12:05 م',
    );
  });
}
