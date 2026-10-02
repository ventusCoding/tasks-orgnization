import 'package:everslot/features/search/domain/search_models.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

/// T8.1.14–15 domain: highlighting, snippets, grouping, filters, recents.
void main() {
  SearchResult r(
    SearchKind kind,
    String id, {
    bool closed = false,
    String? category,
    Set<String> tags = const {},
    LocalDate? day,
  }) => SearchResult(
    kind: kind,
    id: id,
    title: id,
    score: 1,
    closed: closed,
    categoryId: category,
    tagIds: tags,
    day: day,
  );

  group('highlightRanges', () {
    test('prefix match per word, case and accents ignored both ways', () {
      const text = 'Réunion with Élodie about reports';
      String marked(String q) => [for (final (s, e) in highlightRanges(text, q)) text.substring(s, e)].join('|');
      expect(marked('reun'), 'Réunion');
      expect(marked('élo REP'), 'Élodie|reports');
      expect(marked('union'), '', reason: 'prefix, not infix');
      expect(highlightRanges(text, '   '), isEmpty);
    });

    test('Arabic letter variants and harakat', () {
      const text = 'مكتبة أحمد';
      expect([for (final (s, e) in highlightRanges(text, 'احمد')) text.substring(s, e)], ['أحمد']);
      expect([for (final (s, e) in highlightRanges(text, 'مَكتبه')) text.substring(s, e)], ['مكتبة']);
    });
  });

  test('snippetSpans splits marked fragments', () {
    expect(snippetSpans('…buy \u0002oat\u0003 milk and \u0002oat\u0003s'), [
      ('…buy ', false),
      ('oat', true),
      (' milk and ', false),
      ('oat', true),
      ('s', false),
    ]);
    expect(snippetSpans('plain'), [('plain', false)]);
    expect(snippetSpans('\u0002open'), [('open', true)]);
  });

  test('groupResults keeps ranking inside each kind, kinds in fixed order', () {
    final groups = groupResults([
      r(SearchKind.habit, 'h1'),
      r(SearchKind.task, 't1'),
      r(SearchKind.habit, 'h2'),
      r(SearchKind.inbox, 'n1'),
    ]);
    expect(
      [for (final (k, rows) in groups) '${k.name}:${rows.map((x) => x.id).join(',')}'],
      ['task:t1', 'habit:h1,h2', 'inbox:n1'],
    );
  });

  test('filters: kinds, status, category, tag and inclusive date range', () {
    final day = LocalDate(2026, 9, 22);
    final x = r(SearchKind.item, 'x', closed: true, category: 'c', tags: {'t'}, day: day);
    expect(const SearchFilters().isEmpty, isTrue);
    expect(const SearchFilters().matches(x), isTrue);
    expect(const SearchFilters(kinds: {SearchKind.task}).matches(x), isFalse);
    expect(const SearchFilters(kinds: {SearchKind.task, SearchKind.item}).matches(x), isTrue);
    expect(const SearchFilters(status: SearchStatus.open).matches(x), isFalse);
    expect(const SearchFilters(status: SearchStatus.closed).matches(x), isTrue);
    expect(const SearchFilters(categoryId: 'c', tagId: 't').matches(x), isTrue);
    expect(const SearchFilters(tagId: 'u').matches(x), isFalse);
    expect(SearchFilters(from: day, to: day).matches(x), isTrue);
    expect(SearchFilters(from: day.plusDays(1)).matches(x), isFalse);
    expect(SearchFilters(to: day.plusDays(-1)).matches(x), isFalse);
    expect(SearchFilters(from: day).matches(r(SearchKind.task, 'undated')), isFalse);
    final f = SearchFilters(status: SearchStatus.open, categoryId: 'c', tagId: 't', from: day, to: day);
    expect(f.copyWith(clearStatus: true, clearCategory: true, clearTag: true, clearDates: true).isEmpty, isTrue);
    expect(f, f.copyWith());
    expect(f.hashCode, f.copyWith().hashCode);
  });

  test('addRecent: newest first, case-insensitive dedupe, capped, blanks ignored', () {
    var recents = <String>[];
    for (final q in ['milk', 'Dentist', 'MILK', '  ', 'tax']) {
      recents = addRecent(recents, q, max: 3);
    }
    expect(recents, ['tax', 'MILK', 'Dentist']);
    expect(SearchKind.tryParse('checklist_item'), SearchKind.item);
    expect(SearchKind.tryParse('nope'), isNull);
  });
}
