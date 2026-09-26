import 'package:everslot/shared/filters/data/entity_filter_sql.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final full = EntityFilter(
    categoryIds: const {'c1', EntityFilter.noCategory},
    tagIds: const {'t1'},
    priorities: const {3, 4},
    statuses: const {'waiting'},
    text: '  report ',
    dateFrom: LocalDate(2026, 9, 1),
    dateTo: LocalDate(2026, 9, 30),
    hasAttachments: true,
    recurring: false,
  );

  group('EntityFilter', () {
    test('empty filter matches everything', () {
      expect(EntityFilter.empty.isEmpty, isTrue);
      expect(EntityFilter.empty.matches(const FilterSubject()), isTrue);
      expect(EntityFilterSql.where(EntityFilter.empty, FilterColumns.tasks()).sql, '1');
    });

    test('counts active criteria (date range counts once, blank text is inactive)', () {
      expect(full.activeCount, 8);
      expect(const EntityFilter(text: '   ').activeCount, 0);
      expect(EntityFilter(dateTo: LocalDate(2026, 1, 1)).activeCount, 1);
    });

    test('JSON round-trip keeps every criterion (arch §8.3 filters object)', () {
      final json = full.toJson();
      expect(json['categories'], ['c1', 'none']..sort());
      expect(json['text'], 'report');
      expect(EntityFilter.fromJson(json), full);
      expect(EntityFilter.fromJson(const {'categories': [], 'text': null}), EntityFilter.empty);
    });

    test('malformed JSON degrades to no filter', () {
      expect(EntityFilter.fromJson('x'), EntityFilter.empty);
      final f = EntityFilter.fromJson(const {
        'categories': 'c1',
        'priorities': [9, 2, 'x'],
        'dateFrom': 'not a date',
        'recurring': 'yes',
      });
      expect(f, const EntityFilter(priorities: {2}));
    });

    test('copyWith can clear optional criteria', () {
      final cleared = full.copyWith(
        clearText: true,
        clearDates: true,
        clearHasAttachments: true,
        clearRecurring: true,
      );
      expect(cleared.effectiveText, isNull);
      expect(cleared.hasDateRange, isFalse);
      expect(cleared.hasAttachments, isNull);
      expect(cleared.recurring, isNull);
      expect(cleared.categoryIds, full.categoryIds);
    });

    test('equality ignores set order and text padding', () {
      expect(
        const EntityFilter(tagIds: {'a', 'b'}, text: 'x '),
        const EntityFilter(tagIds: {'b', 'a'}, text: 'x'),
      );
      expect(
        const EntityFilter(tagIds: {'a', 'b'}).hashCode,
        const EntityFilter(tagIds: {'b', 'a'}).hashCode,
      );
    });
  });

  group('predicate', () {
    test('criteria are ANDed, values ORed', () {
      final subject = FilterSubject(
        categoryId: 'c1',
        tagIds: const {'t1', 't9'},
        priority: 4,
        status: 'waiting',
        texts: const ['Quarterly REPORT', null],
        date: LocalDate(2026, 9, 15),
        hasAttachments: true,
      );
      expect(full.matches(subject), isTrue);
      expect(full.copyWith(priorities: {1}).matches(subject), isFalse);
      expect(full.copyWith(statuses: {'todo', 'waiting'}).matches(subject), isTrue);
    });

    test('noCategory matches uncategorized entities', () {
      const f = EntityFilter(categoryIds: {EntityFilter.noCategory});
      expect(f.matches(const FilterSubject()), isTrue);
      expect(f.matches(const FilterSubject(categoryId: 'c1')), isFalse);
    });

    test('missing fields never match a set criterion', () {
      expect(const EntityFilter(priorities: {0}).matches(const FilterSubject()), isFalse);
      expect(const EntityFilter(statuses: {'todo'}).matches(const FilterSubject()), isFalse);
      expect(
        EntityFilter(dateFrom: LocalDate(2026, 1, 1)).matches(const FilterSubject()),
        isFalse,
      );
      expect(const EntityFilter(text: 'a').matches(const FilterSubject()), isFalse);
    });

    test('date range bounds are inclusive', () {
      final f = EntityFilter(dateFrom: LocalDate(2026, 9, 1), dateTo: LocalDate(2026, 9, 30));
      expect(f.matches(FilterSubject(date: LocalDate(2026, 9, 1))), isTrue);
      expect(f.matches(FilterSubject(date: LocalDate(2026, 9, 30))), isTrue);
      expect(f.matches(FilterSubject(date: LocalDate(2026, 10, 1))), isFalse);
    });

    test('text folding: ASCII case-insensitive, Arabic letter variants normalized', () {
      expect(FilterText.fold('RePoRt'), 'report');
      // Only ASCII letters are lower-cased, exactly like SQLite's built-in lower().
      expect(FilterText.fold('ÉTÉ'), 'ÉtÉ');
      expect(FilterText.fold('أحمد'), FilterText.fold('احمد'));
      expect(FilterText.fold('مدرسة'), 'مدرسه');
      expect(FilterText.fold('كتـاب'), 'كتاب');
      expect(const EntityFilter(text: 'احمد').matches(const FilterSubject(texts: ['إلى أحمد'])), isTrue);
    });
  });

  group('SQL builder', () {
    test('binds every value as a parameter', () {
      final where = EntityFilterSql.where(full, FilterColumns.tasks('t'));
      expect(where.sql, isNot(contains('report')));
      expect(where.args, containsAll(<Object>['c1', 't1', 3, 4, 'waiting', 'report', '2026-09-01']));
      expect('?'.allMatches(where.sql).length, where.args.length);
    });

    test('fields an entity lacks behave like NULL', () {
      final items = FilterColumns.checklistItems('i');
      expect(
        EntityFilterSql.where(const EntityFilter(categoryIds: {'c1'}), items).sql,
        contains('NULL IN'),
      );
      expect(
        EntityFilterSql.where(const EntityFilter(recurring: false), items).sql,
        contains('NULL IS NULL'),
      );
    });
  });
}
