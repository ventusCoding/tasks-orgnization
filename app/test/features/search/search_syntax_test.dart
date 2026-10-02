import 'package:everslot/core/database/search_index.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:everslot/features/search/domain/search_syntax.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

/// T8.1.16: power-search syntax — tokens, phrases, EN/FR keywords, errors, filter mapping.
void main() {
  final today = LocalDate(2026, 9, 22);
  List<String> tokens(String q) => [for (final t in SearchSyntax.parse(q).tokens) '${t.key.name}:${t.value}'];
  List<String> errors(String q) => [for (final e in SearchSyntax.parse(q).errors) '${e.code.name}:${e.key}:${e.value}'];

  test('the spec example', () {
    final p = SearchSyntax.parse('status:waiting tag:work due:<7d cat:health is:recurring "exact phrase" invoice');
    expect(
      [for (final t in p.tokens) '${t.key.name}:${t.value}'],
      ['status:waiting', 'tag:work', 'due:<7d', 'category:health', 'flag:recurring'],
    );
    expect(p.phrases, ['exact phrase']);
    expect(p.terms, ['invoice']);
    expect(p.text, 'invoice "exact phrase"');
    expect(p.errors, isEmpty);
  });

  test('token positions cover the raw text (chips remove them)', () {
    const q = 'milk tag:"deep work" due:today';
    final p = SearchSyntax.parse(q);
    expect([for (final t in p.tokens) q.substring(t.start, t.end)], ['tag:"deep work"', 'due:today']);
    expect(p.tokens.first.value, 'deep work');
    expect(p.tokens.first.raw, 'tag:"deep work"');
  });

  group('French keywords and values (accents optional)', () {
    test('keys', () {
      expect(tokens('statut:attente étiquette:travail catégorie:santé échéance:demain est:récurrent type:tâche'), [
        'status:waiting',
        'tag:travail',
        'category:santé',
        'due:tomorrow',
        'flag:recurring',
        'type:task',
      ]);
      expect(tokens('etat:bloque etiquette:x echeance:retard est:archive dans:liste'), [
        'status:blocked',
        'tag:x',
        'due:overdue',
        'flag:archived',
        'type:checklist',
      ]);
    });

    test('values', () {
      expect(tokens('statut:enattente statut:"en cours" statut:terminé statut:annulé statut:afaire'), [
        'status:waiting',
        'status:ongoing',
        'status:completed',
        'status:cancelled',
        'status:todo',
      ]);
      expect(tokens('échéance:<7j échéance:>2s échéance:3j échéance:aujourd’hui'), [
        'due:<7d',
        'due:>2w',
        'due:<3d',
        'due:today',
      ]);
    });
  });

  test('case-insensitive keys and values', () {
    expect(tokens('STATUS:Waiting Is:Recurring TYPE:Habits'), ['status:waiting', 'flag:recurring', 'type:habit']);
  });

  group('errors', () {
    test('unknown key and bad values keep the rest usable', () {
      final p = SearchSyntax.parse('foo:bar status:sleepy due:someday type:planet is:pink invoice');
      expect(errors('foo:bar status:sleepy due:someday type:planet is:pink invoice'), [
        'unknownKey:foo:bar',
        'badValue:status:sleepy',
        'badValue:due:someday',
        'badValue:type:planet',
        'badValue:flag:pink',
      ]);
      expect(p.terms, ['invoice']);
      expect(p.tokens, isEmpty);
    });

    test('impossible dates are rejected', () {
      expect(errors('due:2026-02-30'), ['badValue:due:2026-02-30']);
      expect(tokens('due:2026-10-15 due:<2026-10-15 due:>2026-10-15'), [
        'due:2026-10-15',
        'due:<2026-10-15',
        'due:>2026-10-15',
      ]);
    });

    test('unclosed quotes search the rest as a phrase', () {
      final p = SearchSyntax.parse('report "quarterly numb');
      expect(p.phrases, ['quarterly numb']);
      expect(p.errors.single.code, QueryErrorCode.unclosedQuote);
      expect(SearchSyntax.parse('tag:"deep').tokens.single.value, 'deep');
      expect(errors('tag:"deep'), ['unclosedQuote:null:null']);
    });

    test('times, URLs and trailing colons stay plain words', () {
      final p = SearchSyntax.parse('meet 10:30 https://x.io Note: ""');
      expect(p.terms, ['meet', '10:30', 'Note:']);
      expect(p.errors.single.key, 'https', reason: 'a letters-only prefix reads as a key');
      expect(SearchSyntax.parse('').text, '');
    });
  });

  group('filters', () {
    SearchResult row({
      String? status,
      bool recurring = false,
      bool closed = false,
      LocalDate? day,
      SearchKind kind = SearchKind.item,
    }) => SearchResult(
      kind: kind,
      id: 'x',
      title: 'x',
      score: 1,
      rawStatus: status,
      recurring: recurring,
      closed: closed,
      day: day,
    );

    test('status, flags, types', () {
      final f = SearchSyntax.parse('status:waiting is:recurring type:item type:task')
          .applyTo(const SearchFilters(), today: today);
      expect(f.itemStatus, 'waiting');
      expect(f.recurring, isTrue);
      expect(f.kinds, {SearchKind.item, SearchKind.task});
      expect(f.matches(row(status: 'waiting', recurring: true)), isTrue);
      expect(f.matches(row(status: 'blocked', recurring: true)), isFalse);
      expect(f.matches(row(status: 'waiting')), isFalse);
      final open = SearchSyntax.parse('is:open').applyTo(const SearchFilters(), today: today);
      expect(open.status, SearchStatus.open);
      expect(SearchSyntax.parse('is:done').applyTo(const SearchFilters(), today: today).status, SearchStatus.closed);
      expect(
        SearchSyntax.parse('status:closed').applyTo(const SearchFilters(), today: today).status,
        SearchStatus.closed,
      );
    });

    test('due ranges', () {
      (LocalDate?, LocalDate?) range(String q) {
        final f = SearchSyntax.parse(q).applyTo(const SearchFilters(), today: today);
        return (f.from, f.to);
      }

      expect(range('due:today'), (today, today));
      expect(range('due:tomorrow'), (today.plusDays(1), today.plusDays(1)));
      expect(range('due:<7d'), (today, today.plusDays(7)));
      expect(range('due:>2w'), (today.plusDays(14), null));
      expect(range('due:overdue'), (null, today.plusDays(-1)));
      expect(SearchSyntax.parse('due:overdue').applyTo(const SearchFilters(), today: today).status, SearchStatus.open);
      expect(range('due:<2026-10-01'), (null, LocalDate(2026, 10, 1)));
      expect(range('due:2026-10-01'), (LocalDate(2026, 10, 1), LocalDate(2026, 10, 1)));
      expect(ParsedQuery.dueRange('nonsense', today), isNull);
    });

    test('names resolve through lookups; unknown names match nothing', () {
      final p = SearchSyntax.parse('tag:work cat:health');
      final f = p.applyTo(
        const SearchFilters(),
        today: today,
        tagIdOf: (n) => n == 'work' ? 't1' : null,
        categoryIdOf: (_) => null,
      );
      expect(f.tagId, 't1');
      expect(f.categoryId, SearchFilters.noMatch);
      expect(
        SearchSyntax.parse('milk').applyTo(const SearchFilters(status: SearchStatus.open), today: today).status,
        SearchStatus.open,
      );
    });
  });

  test('the index understands phrases', () {
    expect(SearchIndexSchema.matchExpression('invoice "exact phrase"'), '"invoice"* "exact phrase"');
    expect(SearchIndexSchema.matchExpression('"open'), '"open"');
    expect(SearchIndexSchema.matchExpression('""'), isNull);
  });
}
