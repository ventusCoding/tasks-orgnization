import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Kinds of searchable rows (T8.1.14); [json] is the search index `entity_type`.
enum SearchKind {
  task('task'),
  checklist('checklist'),
  item('checklist_item'),
  habit('habit'),
  log('habit_log'),
  inbox('notification');

  SearchKind(this.json);

  final String json;

  static SearchKind? tryParse(String? v) => values.where((k) => k.json == v).firstOrNull;
}

/// Open (active, to do, unread) vs closed (completed, archived, read) — T8.1.15.
enum SearchStatus { open, closed }

/// Search filter chips (T8.1.15): kinds, status, category, tag and a date range (inclusive).
@immutable
class SearchFilters {
  const SearchFilters({
    this.kinds = const {},
    this.status,
    this.categoryId,
    this.tagId,
    this.from,
    this.to,
    this.itemStatus,
    this.recurring,
  });

  /// Id that matches no category / tag (an unknown name in the query syntax).
  static const noMatch = '\u0000';

  /// Empty = every kind.
  final Set<SearchKind> kinds;
  final SearchStatus? status;
  final String? categoryId;
  final String? tagId;
  final LocalDate? from;
  final LocalDate? to;

  /// Exact row status (`waiting`, `blocked`… — query syntax `status:`).
  final String? itemStatus;

  /// Only repeating tasks / habits (`is:recurring`).
  final bool? recurring;

  bool get isEmpty =>
      kinds.isEmpty &&
      status == null &&
      categoryId == null &&
      tagId == null &&
      from == null &&
      to == null &&
      itemStatus == null &&
      recurring == null;

  bool matches(SearchResult r) {
    if (kinds.isNotEmpty && !kinds.contains(r.kind)) return false;
    if (status != null && (r.closed ? SearchStatus.closed : SearchStatus.open) != status) return false;
    if (categoryId != null && r.categoryId != categoryId) return false;
    if (tagId != null && !r.tagIds.contains(tagId)) return false;
    if (itemStatus != null && r.rawStatus != itemStatus) return false;
    if (recurring != null && r.recurring != recurring) return false;
    if (from != null || to != null) {
      final day = r.day;
      if (day == null) return false;
      if (from != null && day.isBefore(from!)) return false;
      if (to != null && day.isAfter(to!)) return false;
    }
    return true;
  }

  SearchFilters copyWith({
    Set<SearchKind>? kinds,
    SearchStatus? status,
    String? categoryId,
    String? tagId,
    LocalDate? from,
    LocalDate? to,
    String? itemStatus,
    bool? recurring,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearTag = false,
    bool clearDates = false,
  }) => SearchFilters(
    kinds: kinds ?? this.kinds,
    status: clearStatus ? null : (status ?? this.status),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    tagId: clearTag ? null : (tagId ?? this.tagId),
    from: clearDates ? null : (from ?? this.from),
    to: clearDates ? null : (to ?? this.to),
    itemStatus: itemStatus ?? this.itemStatus,
    recurring: recurring ?? this.recurring,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      _sameSet(other.kinds, kinds) &&
      other.status == status &&
      other.categoryId == categoryId &&
      other.tagId == tagId &&
      other.from == from &&
      other.to == to &&
      other.itemStatus == itemStatus &&
      other.recurring == recurring;

  @override
  int get hashCode =>
      Object.hash(Object.hashAllUnordered(kinds), status, categoryId, tagId, from, to, itemStatus, recurring);

  static bool _sameSet<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);
}

/// One enriched search hit (T8.1.14): the index match plus what the result row shows and filters on.
@immutable
class SearchResult {
  const SearchResult({
    required this.kind,
    required this.id,
    required this.title,
    required this.score,
    this.parentId,
    this.snippet,
    this.breadcrumb = const [],
    this.link,
    this.categoryId,
    this.tagIds = const {},
    this.closed = false,
    this.day,
    this.quit = false,
    this.rawStatus,
    this.recurring = false,
  });

  final SearchKind kind;
  final String id;

  /// Checklist of an item, habit of a log entry.
  final String? parentId;
  final String title;

  /// Body fragment with marked matches (see [snippetSpans]).
  final String? snippet;

  /// Where the row lives: list title then ancestor items for an item, habit name for a log entry.
  final List<String> breadcrumb;

  /// Router path the result opens.
  final String? link;
  final String? categoryId;
  final Set<String> tagIds;
  final bool closed;

  /// Day the row is about (task start, item due, log day, inbox fire day; else last edit).
  final LocalDate? day;
  final double score;

  /// A quit tracker (or one of its log entries) rather than a build habit.
  final bool quit;

  /// The row's own status value (item status, task status).
  final String? rawStatus;

  /// A repeating task, or a habit.
  final bool recurring;

  @override
  bool operator ==(Object other) =>
      other is SearchResult &&
      other.kind == kind &&
      other.id == id &&
      other.parentId == parentId &&
      other.title == title &&
      other.snippet == snippet &&
      _sameList(other.breadcrumb, breadcrumb) &&
      other.link == link &&
      other.categoryId == categoryId &&
      SearchFilters._sameSet(other.tagIds, tagIds) &&
      other.closed == closed &&
      other.day == day &&
      other.score == score &&
      other.quit == quit &&
      other.rawStatus == rawStatus &&
      other.recurring == recurring;

  @override
  int get hashCode => Object.hash(
    kind,
    id,
    parentId,
    title,
    snippet,
    Object.hashAll(breadcrumb),
    link,
    categoryId,
    Object.hashAllUnordered(tagIds),
    closed,
    day,
    score,
    quit,
    rawStatus,
    recurring,
  );

  @override
  String toString() => 'SearchResult(${kind.name} $id "$title")';

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Results grouped by kind in [SearchKind] order, each group keeping its ranking.
List<(SearchKind, List<SearchResult>)> groupResults(Iterable<SearchResult> results) {
  final groups = <SearchKind, List<SearchResult>>{};
  for (final r in results) {
    (groups[r.kind] ??= []).add(r);
  }
  return [
    for (final k in SearchKind.values)
      if (groups[k] case final g?) (k, g),
  ];
}

/// Word ranges of [text] matched by [query] (prefix match per query word; case, French accents and
/// Arabic letter variants ignored), merged and sorted — for highlighting titles.
List<(int, int)> highlightRanges(String text, String query) {
  final tokens = [
    for (final w in _word.allMatches(query))
      if (Collation.key(w[0]!) case final k when k.isNotEmpty) k,
  ];
  if (tokens.isEmpty) return const [];
  return [
    for (final m in _word.allMatches(text))
      if (tokens.any(Collation.key(m[0]!).startsWith)) (m.start, m.end),
  ];
}

final _word = RegExp(r'[\p{L}\p{N}\p{M}]+', unicode: true);

/// Splits an FTS snippet into `(text, isMatch)` spans.
List<(String, bool)> snippetSpans(String snippet, {String start = '\u0002', String end = '\u0003'}) {
  final out = <(String, bool)>[];
  var rest = snippet;
  while (rest.isNotEmpty) {
    final s = rest.indexOf(start);
    if (s < 0) {
      out.add((rest, false));
      break;
    }
    if (s > 0) out.add((rest.substring(0, s), false));
    final e = rest.indexOf(end, s + start.length);
    final stop = e < 0 ? rest.length : e;
    out.add((rest.substring(s + start.length, stop), true));
    rest = e < 0 ? '' : rest.substring(e + end.length);
  }
  return out;
}

/// Recent searches (T8.1.15): newest first, case-insensitive dedupe, at most [max].
List<String> addRecent(List<String> recents, String query, {int max = 10}) {
  final q = query.trim();
  if (q.isEmpty) return recents;
  return [q, ...recents.where((r) => r.toLowerCase() != q.toLowerCase())].take(max).toList();
}
