import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

LocalDateTime dt(String s) => LocalDateTime.parse(s);

void main() {
  tzdata.initializeTimeZones();
  final engine = RecurrenceEngine(TzZoneResolver());

  group('OverrideMerger', () {
    final merger = OverrideMerger(engine);
    final rule = RecurrenceRule(
      freq: Frequency.weekly,
      byWeekday: const [WeekdayRule(Weekday.tuesday)],
    );
    final anchor = RecurrenceAnchor(
      dt('2026-09-22T10:00'),
      'Europe/Paris',
      durationMinutes: 60,
    );

    List<String> view(List<MergedOccurrence<String>> merged) => [
      for (final m in merged) '${m.key}@${m.startLocal}${m.isMoved ? '*' : ''}',
    ];

    test('moving Tuesday to next Monday shows it on Monday only', () {
      final overrides = [
        OccurrenceOverride<String>(
          '2026-09-22T10:00',
          newStartLocal: dt('2026-09-28T09:00'),
        ),
      ];
      final firstWeek = merger.merge(
        rule,
        anchor,
        dt('2026-09-21T00:00'),
        dt('2026-09-28T00:00'),
        overrides,
      );
      expect(firstWeek, isEmpty);
      final secondWeek = merger.merge(
        rule,
        anchor,
        dt('2026-09-28T00:00'),
        dt('2026-10-05T00:00'),
        overrides,
      );
      expect(view(secondWeek), [
        '2026-09-22T10:00@2026-09-28T09:00*',
        '2026-09-29T10:00@2026-09-29T10:00',
      ]);
      expect(secondWeek.first.hasOverride, isTrue);
      expect(secondWeek.first.original.startLocal, dt('2026-09-22T10:00'));
      expect(secondWeek.first.startUtc, DateTime.utc(2026, 9, 28, 7));
      expect(secondWeek[1].hasOverride, isFalse);
      expect(secondWeek[1].isAllDay, isFalse);
    });

    test(
      'cancelling removes it; editing duration changes only that occurrence',
      () {
        final overrides = [
          const OccurrenceOverride<String>('2026-09-29T10:00', cancelled: true),
          const OccurrenceOverride<String>(
            '2026-10-06T10:00',
            newDurationMinutes: 180,
            payload: 'long',
          ),
        ];
        final merged = merger.merge(
          rule,
          anchor,
          dt('2026-09-28T00:00'),
          dt('2026-10-14T00:00'),
          overrides,
        );
        expect(
          [for (final m in merged) m.key],
          ['2026-10-06T10:00', '2026-10-13T10:00'],
        );
        expect(merged.first.durationMinutes, 180);
        expect(merged.first.payload, 'long');
        expect(
          merged.first.endUtc.difference(merged.first.startUtc),
          const Duration(hours: 3),
        );
        expect(merged.first.isMoved, isFalse);
        expect(merged.last.durationMinutes, 60);
      },
    );

    test('edited long duration overlapping the range start is included', () {
      final overrides = [
        const OccurrenceOverride<String>(
          '2026-09-22T10:00',
          newDurationMinutes: 24 * 60,
        ),
      ];
      final merged = merger.merge(
        rule,
        anchor,
        dt('2026-09-23T00:00'),
        dt('2026-09-24T00:00'),
        overrides,
      );
      expect([for (final m in merged) m.key], ['2026-09-22T10:00']);
    });

    test('moved out of the range, stale and no-op overrides', () {
      final overrides = [
        OccurrenceOverride<String>(
          '2026-09-29T10:00',
          newStartLocal: dt('2026-11-01T10:00'),
        ),
        OccurrenceOverride<String>(
          '2026-09-30T10:00',
          newStartLocal: dt('2026-09-30T12:00'),
        ),
        const OccurrenceOverride<String>('2026-10-20T10:00'),
        const OccurrenceOverride<String>('2026-10-27T10:00', cancelled: true),
      ];
      final merged = merger.merge(
        rule,
        anchor,
        dt('2026-09-28T00:00'),
        dt('2026-10-05T00:00'),
        overrides,
      );
      expect(merged, isEmpty);
    });

    test('ordering by effective start and all-day series', () {
      final overrides = [
        OccurrenceOverride<String>(
          '2026-10-06T10:00',
          newStartLocal: dt('2026-09-30T08:00'),
        ),
      ];
      final merged = merger.merge(
        rule,
        anchor,
        dt('2026-09-28T00:00'),
        dt('2026-10-12T00:00'),
        overrides,
      );
      expect(
        [for (final m in merged) m.key],
        ['2026-09-29T10:00', '2026-10-06T10:00'],
      );

      final allDay = RecurrenceAnchor.allDayOn(LocalDate(2026, 9, 22), null);
      final moved = merger.merge(
        rule,
        allDay,
        dt('2026-09-28T00:00'),
        dt('2026-10-05T00:00'),
        [
          OccurrenceOverride<int>(
            '2026-09-22',
            newStartLocal: dt('2026-10-01T00:00'),
          ),
        ],
      );
      expect(
        [for (final m in moved) '${m.key}@${m.startLocal.date}'],
        ['2026-09-29@2026-09-29', '2026-09-22@2026-10-01'],
      );
      expect(moved.last.isAllDay, isTrue);
    });

    test('value types', () {
      final a = OccurrenceOverride<String>(
        'k',
        newStartLocal: dt('2026-01-01T00:00'),
        newDurationMinutes: 5,
      );
      expect(
        a,
        OccurrenceOverride<String>(
          'k',
          newStartLocal: dt('2026-01-01T00:00'),
          newDurationMinutes: 5,
        ),
      );
      expect(
        a.hashCode,
        OccurrenceOverride<String>(
          'k',
          newStartLocal: dt('2026-01-01T00:00'),
          newDurationMinutes: 5,
        ).hashCode,
      );
      expect(a.toString(), 'OccurrenceOverride(k, → 2026-01-01T00:00, 5min)');
      expect(
        const OccurrenceOverride<String>('k', cancelled: true).toString(),
        'OccurrenceOverride(k, cancelled)',
      );
      final merged = merger.merge(
        rule,
        anchor,
        dt('2026-09-21T00:00'),
        dt('2026-09-23T00:00'),
        [
          const OccurrenceOverride<String>(
            '2026-09-22T10:00',
            payload: 'p',
            newDurationMinutes: 60,
          ),
        ],
      ).single;
      final same = merger.merge(
        rule,
        anchor,
        dt('2026-09-21T00:00'),
        dt('2026-09-23T00:00'),
        [
          const OccurrenceOverride<String>(
            '2026-09-22T10:00',
            payload: 'p',
            newDurationMinutes: 60,
          ),
        ],
      ).single;
      expect(merged, same);
      expect(merged.hashCode, same.hashCode);
      expect(merged.toString(), contains('overridden'));
    });
  });

  group('SeriesSplitter', () {
    final splitter = SeriesSplitter(engine);
    final anchor = RecurrenceAnchor(dt('2026-09-21T08:00'), 'Europe/Paris');

    List<String> keysOf(RecurrenceRule? rule, RecurrenceAnchor a) =>
        rule == null
        ? const []
        : [
            for (final o in engine.between(
              rule,
              a,
              dt('2026-01-01T00:00'),
              dt('2028-01-01T00:00'),
            ))
              o.key,
          ];

    test('until-based split', () {
      final rule = RecurrenceRule(
        exdates: const ['2026-09-22T08:00', '2026-09-30T08:00'],
        rdates: const ['2026-10-10T12:00'],
      );
      final split = splitter.split(rule, anchor, '2026-09-25T08:00');
      expect(split.truncatedRule!.until, dt('2026-09-24T08:00'));
      expect(split.truncatedRule!.exdates, ['2026-09-22T08:00']);
      expect(split.newRule.exdates, ['2026-09-30T08:00']);
      expect(split.newRule.rdates, ['2026-10-10T12:00']);
      expect(split.newAnchor.start, dt('2026-09-25T08:00'));
      expect(split.toString(), contains('SeriesSplit'));
    });

    test('count-based split keeps the total count', () {
      final rule = RecurrenceRule(
        freq: Frequency.weekly,
        count: 10,
        exdates: const ['2026-09-28T08:00'],
      );
      final split = splitter.split(rule, anchor, '2026-10-12T08:00');
      expect(split.truncatedRule!.count, 3);
      expect(split.newRule.count, 7);
      expect([
        ...keysOf(split.truncatedRule, anchor),
        ...keysOf(split.newRule, split.newAnchor),
      ], keysOf(rule, anchor));
    });

    test('splitting at the first occurrence leaves no truncated series', () {
      final split = splitter.split(
        RecurrenceRule(count: 5),
        anchor,
        '2026-09-21T08:00',
      );
      expect(split.truncatedRule, isNull);
      expect(split.newRule.count, 5);
      final withEarlierRdate = RecurrenceRule(
        count: 5,
        rdates: const ['2026-09-01T09:00'],
      );
      final kept = splitter.split(withEarlierRdate, anchor, '2026-09-21T08:00');
      expect(keysOf(kept.truncatedRule, anchor), ['2026-09-01T09:00']);
    });

    test('anchor-derived defaults are made explicit', () {
      final monthlyClamp = RecurrenceRule(
        freq: Frequency.monthly,
        monthDayOverflow: MonthOverflow.clamp,
      );
      final jan31 = RecurrenceAnchor(dt('2026-01-31T09:00'), 'UTC');
      final split = splitter.split(monthlyClamp, jan31, '2026-02-28T09:00');
      expect(split.newRule.byMonthDay, [31]);
      expect(keysOf(split.newRule, split.newAnchor).take(2), [
        '2026-02-28T09:00',
        '2026-03-31T09:00',
      ]);

      final yearlyClamp = RecurrenceRule(
        freq: Frequency.yearly,
        monthDayOverflow: MonthOverflow.clamp,
      );
      final feb29 = RecurrenceAnchor(dt('2024-02-29T09:00'), 'UTC');
      final yearly = splitter.split(yearlyClamp, feb29, '2025-02-28T09:00');
      expect(yearly.newRule.byMonth, [2]);
      expect(yearly.newRule.byMonthDay, [29]);

      final weeklyWithRdate = RecurrenceRule(
        freq: Frequency.weekly,
        rdates: const ['2026-09-23T08:00'],
      );
      expect(
        () => splitter.split(weeklyWithRdate, anchor, '2026-09-23T08:00'),
        throwsArgumentError,
      );
    });

    test('rejects invalid splits', () {
      expect(
        () => splitter.split(RecurrenceRule(), anchor, 'nope'),
        throwsArgumentError,
      );
      expect(
        () => splitter.split(RecurrenceRule(), anchor, '2026-09-21T09:00'),
        throwsArgumentError,
      );
      expect(
        () => splitter.split(
          RecurrenceRule.forQuota(1, PeriodUnit.week),
          anchor,
          'week:2026-09-21#1',
        ),
        throwsArgumentError,
      );
    });

    test('all-day series', () {
      final allDay = RecurrenceAnchor.allDayOn(LocalDate(2026, 9, 21), null);
      final rule = RecurrenceRule(exdates: const ['2026-09-23']);
      final split = splitter.split(rule, allDay, '2026-09-24');
      // The previous rule occurrence (exdated, still generated) bounds the old series.
      expect(split.truncatedRule!.until, dt('2026-09-23T00:00'));
      expect(split.newAnchor.allDay, isTrue);
      expect(split.truncatedRule!.exdates, ['2026-09-23']);
    });
  });
}
