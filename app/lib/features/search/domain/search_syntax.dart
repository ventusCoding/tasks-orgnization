import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Power-search keys (T8.1.16).
enum QueryKey { status, tag, category, due, flag, type }

/// One recognized `key:value` token; [start]/[end] index the raw input (for chips that remove it).
@immutable
class QueryToken {
  const QueryToken({required this.key, required this.value, required this.raw, required this.start, required this.end});

  final QueryKey key;

  /// Canonical value: an item status / `open` / `closed`, a tag or category name as typed, a due
  /// spec (`today`, `tomorrow`, `overdue`, `<7d`, `>2w`, `2026-09-30`, `<2026-09-30`), a flag
  /// (`recurring`, `open`, `done`, `archived`) or a [SearchKind] name.
  final String value;

  /// The token as typed.
  final String raw;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is QueryToken &&
      other.key == key &&
      other.value == value &&
      other.raw == raw &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(key, value, raw, start, end);

  @override
  String toString() => 'QueryToken(${key.name}:$value @$start-$end)';
}

enum QueryErrorCode {
  /// `foo:bar` where `foo` is not a key.
  unknownKey,

  /// A known key with a value it does not understand.
  badValue,

  /// A `"` without its closing quote (the rest is still searched as a phrase).
  unclosedQuote,
}

@immutable
class QueryError {
  const QueryError(this.code, {required this.start, required this.end, this.key, this.value});

  final QueryErrorCode code;
  final int start;
  final int end;

  /// The key as typed (unknown key) or its canonical name (bad value).
  final String? key;
  final String? value;

  @override
  bool operator ==(Object other) =>
      other is QueryError &&
      other.code == code &&
      other.start == start &&
      other.end == end &&
      other.key == key &&
      other.value == value;

  @override
  int get hashCode => Object.hash(code, start, end, key, value);

  @override
  String toString() => 'QueryError(${code.name} $key:$value @$start-$end)';
}

/// The parsed search box (T8.1.16): free words and phrases for the full-text index, filter tokens
/// and errors. Keywords are accepted in English and French, with or without accents.
@immutable
class ParsedQuery {
  const ParsedQuery({this.terms = const [], this.phrases = const [], this.tokens = const [], this.errors = const []});

  final List<String> terms;
  final List<String> phrases;
  final List<QueryToken> tokens;
  final List<QueryError> errors;

  /// Text for the index: free words plus quoted phrases.
  String get text => [...terms, for (final p in phrases) '"$p"'].join(' ');

  bool get hasFilters => tokens.isNotEmpty;

  /// [base] (the filter chips) with the parsed tokens applied on top. Names resolve through
  /// [tagIdOf] / [categoryIdOf]; an unknown name matches nothing.
  SearchFilters applyTo(
    SearchFilters base, {
    required LocalDate today,
    String? Function(String name)? tagIdOf,
    String? Function(String name)? categoryIdOf,
  }) {
    var f = base;
    final kinds = <SearchKind>{};
    for (final t in tokens) {
      switch (t.key) {
        case QueryKey.type:
          kinds.add(SearchKind.values.byName(t.value));
        case QueryKey.status:
          f = switch (t.value) {
            'open' => f.copyWith(status: SearchStatus.open),
            'closed' => f.copyWith(status: SearchStatus.closed),
            final s => f.copyWith(itemStatus: s),
          };
        case QueryKey.flag:
          f = switch (t.value) {
            'recurring' => f.copyWith(recurring: true),
            'open' => f.copyWith(status: SearchStatus.open),
            _ => f.copyWith(status: SearchStatus.closed),
          };
        case QueryKey.tag:
          f = f.copyWith(tagId: tagIdOf?.call(t.value) ?? SearchFilters.noMatch);
        case QueryKey.category:
          f = f.copyWith(categoryId: categoryIdOf?.call(t.value) ?? SearchFilters.noMatch);
        case QueryKey.due:
          final (from, to) = dueRange(t.value, today)!;
          f = f.copyWith(from: from, to: to, clearDates: from == null && to == null);
          if (t.value == 'overdue') f = f.copyWith(status: SearchStatus.open);
      }
    }
    return kinds.isEmpty ? f : f.copyWith(kinds: kinds);
  }

  /// Inclusive day range of a canonical due spec (null bounds are open); null when invalid.
  static (LocalDate?, LocalDate?)? dueRange(String spec, LocalDate today) {
    switch (spec) {
      case 'today':
        return (today, today);
      case 'tomorrow':
        return (today.plusDays(1), today.plusDays(1));
      case 'overdue':
        return (null, today.plusDays(-1));
    }
    final rel = RegExp(r'^([<>])(\d+)([dw])$').firstMatch(spec);
    if (rel != null) {
      final days = int.parse(rel[2]!) * (rel[3] == 'w' ? 7 : 1);
      return rel[1] == '<' ? (today, today.plusDays(days)) : (today.plusDays(days), null);
    }
    final abs = RegExp(r'^([<>]?)(\d{4}-\d{2}-\d{2})$').firstMatch(spec);
    final date = abs == null ? null : LocalDate.tryParse(abs[2]!);
    if (date == null) return null;
    return switch (abs![1]) {
      '<' => (null, date),
      '>' => (date, null),
      _ => (date, date),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ParsedQuery &&
      _eq(other.terms, terms) &&
      _eq(other.phrases, phrases) &&
      _eq(other.tokens, tokens) &&
      _eq(other.errors, errors);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(terms), Object.hashAll(phrases), Object.hashAll(tokens), Object.hashAll(errors));

  static bool _eq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Parser for the power-search syntax (T8.1.16):
/// `status:waiting tag:work due:<7d cat:health is:recurring type:item "exact phrase"`.
abstract final class SearchSyntax {
  /// Accepted key spellings (folded: lower case, no accents) → key.
  static const keys = <String, QueryKey>{
    'status': QueryKey.status,
    'statut': QueryKey.status,
    'etat': QueryKey.status,
    'tag': QueryKey.tag,
    'etiquette': QueryKey.tag,
    'cat': QueryKey.category,
    'category': QueryKey.category,
    'categorie': QueryKey.category,
    'due': QueryKey.due,
    'date': QueryKey.due,
    'echeance': QueryKey.due,
    'pour': QueryKey.due,
    'is': QueryKey.flag,
    'est': QueryKey.flag,
    'type': QueryKey.type,
    'in': QueryKey.type,
    'dans': QueryKey.type,
  };

  static const _status = <String, String>{
    'todo': 'todo',
    'afaire': 'todo',
    'ongoing': 'ongoing',
    'encours': 'ongoing',
    'waiting': 'waiting',
    'attente': 'waiting',
    'enattente': 'waiting',
    'blocked': 'blocked',
    'bloque': 'blocked',
    'completed': 'completed',
    'complete': 'completed',
    'done': 'completed',
    'fait': 'completed',
    'termine': 'completed',
    'cancelled': 'cancelled',
    'canceled': 'cancelled',
    'annule': 'cancelled',
    'open': 'open',
    'ouvert': 'open',
    'closed': 'closed',
    'ferme': 'closed',
  };

  static const _flags = <String, String>{
    'recurring': 'recurring',
    'repeating': 'recurring',
    'recurrent': 'recurring',
    'recurrente': 'recurring',
    'open': 'open',
    'ouvert': 'open',
    'done': 'done',
    'fait': 'done',
    'termine': 'done',
    'archived': 'archived',
    'archive': 'archived',
  };

  static const _types = <String, SearchKind>{
    'task': SearchKind.task,
    'tasks': SearchKind.task,
    'tache': SearchKind.task,
    'taches': SearchKind.task,
    'list': SearchKind.checklist,
    'lists': SearchKind.checklist,
    'liste': SearchKind.checklist,
    'listes': SearchKind.checklist,
    'item': SearchKind.item,
    'items': SearchKind.item,
    'element': SearchKind.item,
    'elements': SearchKind.item,
    'habit': SearchKind.habit,
    'habits': SearchKind.habit,
    'habitude': SearchKind.habit,
    'habitudes': SearchKind.habit,
    'note': SearchKind.log,
    'notes': SearchKind.log,
    'inbox': SearchKind.inbox,
    'notification': SearchKind.inbox,
    'notifications': SearchKind.inbox,
  };

  static const _dueWords = <String, String>{
    'today': 'today',
    'aujourdhui': 'today',
    'auj': 'today',
    'tomorrow': 'tomorrow',
    'demain': 'tomorrow',
    'overdue': 'overdue',
    'late': 'overdue',
    'enretard': 'overdue',
    'retard': 'overdue',
  };

  static String _fold(String s) => Collation.key(s).replaceAll(RegExp(r"[\s'’_-]"), '');

  static final _keyShape = RegExp(r'^[\p{L}]+$', unicode: true);

  static ParsedQuery parse(String input) {
    final terms = <String>[];
    final phrases = <String>[];
    final tokens = <QueryToken>[];
    final errors = <QueryError>[];
    var i = 0;
    while (i < input.length) {
      if (_isSpace(input.codeUnitAt(i))) {
        i++;
        continue;
      }
      final start = i;
      if (input[i] == '"') {
        final close = input.indexOf('"', i + 1);
        final phrase = input.substring(i + 1, close < 0 ? input.length : close).trim();
        if (close < 0) errors.add(QueryError(QueryErrorCode.unclosedQuote, start: start, end: input.length));
        if (phrase.isNotEmpty) phrases.add(phrase);
        i = close < 0 ? input.length : close + 1;
        continue;
      }
      // A word, possibly `key:value` with a quoted value.
      var j = i;
      while (j < input.length && !_isSpace(input.codeUnitAt(j)) && input[j] != '"') {
        j++;
      }
      final word = input.substring(i, j);
      final colon = word.indexOf(':');
      final keyRaw = colon > 0 ? word.substring(0, colon) : '';
      if (colon <= 0 || !_keyShape.hasMatch(keyRaw)) {
        terms.add(word);
        i = j;
        continue;
      }
      var value = word.substring(colon + 1);
      var end = j;
      if (value.isEmpty && j < input.length && input[j] == '"') {
        final close = input.indexOf('"', j + 1);
        value = input.substring(j + 1, close < 0 ? input.length : close).trim();
        end = close < 0 ? input.length : close + 1;
        if (close < 0) errors.add(QueryError(QueryErrorCode.unclosedQuote, start: j, end: input.length));
      }
      i = end;
      final key = keys[_fold(keyRaw)];
      if (value.isEmpty) {
        // `Note:` with nothing after is just a word.
        terms.add(word);
        continue;
      }
      if (key == null) {
        errors.add(QueryError(QueryErrorCode.unknownKey, start: start, end: end, key: keyRaw, value: value));
        continue;
      }
      final canonical = _value(key, value);
      if (canonical == null) {
        errors.add(QueryError(QueryErrorCode.badValue, start: start, end: end, key: key.name, value: value));
        continue;
      }
      tokens.add(QueryToken(key: key, value: canonical, raw: input.substring(start, end), start: start, end: end));
    }
    return ParsedQuery(terms: terms, phrases: phrases, tokens: tokens, errors: errors);
  }

  static String? _value(QueryKey key, String value) {
    final folded = _fold(value);
    switch (key) {
      case QueryKey.status:
        return _status[folded];
      case QueryKey.flag:
        return _flags[folded];
      case QueryKey.type:
        return _types[folded]?.name;
      case QueryKey.tag || QueryKey.category:
        return value;
      case QueryKey.due:
        if (_dueWords[folded] case final w?) return w;
        // `<7d`, `>2w`, `7j` (jours), `2s` (semaines); a bare count means "within".
        final rel = RegExp(r'^([<>]?)(\d{1,4})([dwjs])$').firstMatch(folded);
        if (rel != null) {
          final unit = rel[3] == 'w' || rel[3] == 's' ? 'w' : 'd';
          return '${rel[1]!.isEmpty ? '<' : rel[1]}${int.parse(rel[2]!)}$unit';
        }
        final abs = RegExp(r'^([<>]?)(\d{4}-\d{2}-\d{2})$').firstMatch(value.trim());
        if (abs != null && LocalDate.tryParse(abs[2]!) != null) return abs[0];
        return null;
    }
  }

  static bool _isSpace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0xA0;
}
