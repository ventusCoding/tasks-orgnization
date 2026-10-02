import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:meta/meta.dart';

/// One table feeding the global search index (T2.3.11). Expressions are SQL over the row.
@immutable
class SearchSource {
  const SearchSource({
    required this.table,
    required this.entityType,
    required this.title,
    required this.body,
    this.parent = 'NULL',
  });

  final String table;
  final String entityType;

  /// Column shown and indexed as the title (original text, not normalized).
  final String title;
  final String body;
  final String parent;
}

/// Local-only FTS5 index `search_index(entity_type, entity_id, parent_id, title, body)` over
/// tasks, checklists, checklist items, habits and habit-log notes (arch §6.5). SQLite triggers keep
/// it current — rows arriving from sync are indexed too; tombstoned rows leave it. Tokenizer
/// `unicode61 remove_diacritics 2` (French accents); Arabic letter variants (alef forms, ya/alef
/// maqsura, ta marbuta) and tatweel are normalized in both indexed text and queries.
abstract final class SearchIndexSchema {
  static const sources = <SearchSource>[
    SearchSource(table: 'tasks', entityType: 'task', title: 'title', body: 'notes'),
    SearchSource(table: 'checklists', entityType: 'checklist', title: 'title', body: 'body'),
    SearchSource(
      table: 'checklist_items',
      entityType: 'checklist_item',
      title: 'text',
      body: 'note',
      parent: 'checklist_id',
    ),
    SearchSource(table: 'habits', entityType: 'habit', title: 'name', body: 'description'),
    SearchSource(table: 'habit_logs', entityType: 'habit_log', title: 'note', body: 'NULL', parent: 'habit_id'),
    // Inbox entries (T8.1.14, schema v5).
    SearchSource(table: 'notifications', entityType: 'notification', title: 'title', body: 'body'),
  ];

  static const _columns = 'entity_type, entity_id, parent_id, title, body';

  /// SQL mirror of [normalize].
  static String normalizeSql(String expr) =>
      "replace(replace(replace(replace(replace(replace(coalesce($expr,''),"
      "'أ','ا'),'إ','ا'),'آ','ا'),'ى','ي'),'ة','ه'),'ـ','')";

  static String _col(String prefix, String expr) => expr == 'NULL' ? expr : '$prefix$expr';

  /// The virtual table and its triggers (created with the database).
  static List<String> get statements => [
    '''
CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
        entity_type UNINDEXED, entity_id UNINDEXED, parent_id UNINDEXED, title, body,
        tokenize = 'unicode61 remove_diacritics 2')''',
    for (final s in sources) ..._triggers(s),
  ];

  static List<String> _triggers(SearchSource s) {
    final ins =
        'INSERT INTO search_index($_columns) '
        "SELECT '${s.entityType}', NEW.id, ${_col('NEW.', s.parent)}, ${normalizeSql(_col('NEW.', s.title))}, "
        '${normalizeSql(_col('NEW.', s.body))} WHERE NEW.deleted_at IS NULL;';
    final del = "DELETE FROM search_index WHERE entity_type = '${s.entityType}' AND entity_id = OLD.id;";
    return [
      'CREATE TRIGGER IF NOT EXISTS trg_${s.table}_fts_ai AFTER INSERT ON ${s.table} BEGIN $ins END;',
      'CREATE TRIGGER IF NOT EXISTS trg_${s.table}_fts_au AFTER UPDATE ON ${s.table} BEGIN $del $ins END;',
      'CREATE TRIGGER IF NOT EXISTS trg_${s.table}_fts_ad AFTER DELETE ON ${s.table} BEGIN $del END;',
    ];
  }

  /// Rebuilds the whole index from the live rows (after migrations or a normalization change).
  static List<String> get rebuildStatements => ['DELETE FROM search_index', for (final s in sources) _rebuildFrom(s)];

  static String _rebuildFrom(SearchSource s) =>
      'INSERT INTO search_index($_columns) '
      "SELECT '${s.entityType}', id, ${s.parent}, ${normalizeSql(s.title)}, ${normalizeSql(s.body)} "
      'FROM ${s.table} WHERE deleted_at IS NULL';

  /// Arabic harakat, tanween, dagger alef and Quranic marks: the tokenizer keeps them, so queries
  /// drop them (content is almost always typed without them).
  static final _harakat = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭ]');

  /// Arabic letter-variant normalization (mirrors [normalizeSql]).
  static String normalize(String input) => input
      .replaceAll(_harakat, '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ـ', '');

  /// FTS5 MATCH expression: every word must match as a prefix ("pass" finds "Passport"); a
  /// `"quoted phrase"` must match as consecutive words (T8.1.16; an unclosed quote runs to the end).
  /// Null when the query has no words.
  static String? matchExpression(String query) {
    final parts = <String>[];
    final segments = normalize(query).split('"');
    for (var i = 0; i < segments.length; i++) {
      final words = segments[i].split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
      if (words.isEmpty) continue;
      if (i.isOdd) {
        parts.add('"${words.join(' ')}"');
      } else {
        parts.addAll(words.map((t) => '"$t"*'));
      }
    }
    return parts.isEmpty ? null : parts.join(' ');
  }
}

/// One search result.
@immutable
class SearchMatch {
  const SearchMatch({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.score,
    this.parentId,
    this.updatedAt,
    this.snippet,
  });

  final String entityType;
  final String entityId;

  /// Checklist of an item, habit of a log entry.
  final String? parentId;

  /// Original (not normalized) title.
  final String title;
  final DateTime? updatedAt;

  /// Relevance (higher first): bm25 boosted by recency.
  final double score;

  /// Body fragment around the match, matched terms wrapped in [snippetStart] / [snippetEnd]
  /// (FTS5 `snippet()`); null when only the title matched.
  final String? snippet;

  static const snippetStart = '\u0002';
  static const snippetEnd = '\u0003';

  @override
  bool operator ==(Object other) =>
      other is SearchMatch &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.parentId == parentId &&
      other.title == title &&
      other.updatedAt == updatedAt &&
      other.score == score &&
      other.snippet == snippet;

  @override
  int get hashCode => Object.hash(entityType, entityId, parentId, title, updatedAt, score, snippet);

  @override
  String toString() => 'SearchMatch($entityType $entityId "$title" ${score.toStringAsFixed(3)})';
}

/// Queries over the global search index (T2.3.11); the search UI is [8.1].
class SearchIndex {
  SearchIndex(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Recency boost: up to +[recencyWeight] × relevance for an item edited now, halving every
  /// [recencyHalfLife].
  static const recencyWeight = 0.5;
  static const recencyHalfLife = Duration(days: 30);

  static String _perType(String column) {
    final cases = [
      for (final s in SearchIndexSchema.sources)
        "WHEN '${s.entityType}' THEN (SELECT ${column == 'title' ? s.title : column} FROM ${s.table} WHERE id = s.entity_id)",
    ].join(' ');
    return 'CASE s.entity_type $cases END';
  }

  /// Ranked hits for [query] (bm25 with titles weighted 4× over bodies, then a recency boost).
  /// [entityTypes] narrows the kinds of rows.
  Future<List<SearchMatch>> search(String query, {Set<String>? entityTypes, int limit = 50}) async {
    final match = SearchIndexSchema.matchExpression(query);
    if (match == null || limit <= 0) return const [];
    final types = entityTypes?.toList();
    final candidates = math.min(limit * 4, 400);
    final rows = await _db
        .customSelect(
          'SELECT s.entity_type AS et, s.entity_id AS eid, s.parent_id AS pid, '
          'bm25(search_index, 0.0, 0.0, 0.0, 4.0, 1.0) AS rank, '
          "snippet(search_index, 4, char(2), char(3), '…', 12) AS snip, "
          '${_perType('title')} AS title, ${_perType('updated_at')} AS updated '
          'FROM search_index s WHERE search_index MATCH ? '
          '${types == null ? '' : 'AND s.entity_type IN (${List.filled(types.length, '?').join(', ')}) '}'
          'ORDER BY rank LIMIT ?',
          variables: [
            Variable<String>(match),
            for (final t in types ?? const <String>[]) Variable<String>(t),
            Variable<int>(candidates),
          ],
        )
        .get();
    final now = _clock.nowUtc();
    final hits = [
      for (final r in rows)
        () {
          final updated = DateTime.tryParse(r.readNullable<String>('updated') ?? '')?.toUtc();
          final relevance = -r.read<double>('rank');
          final age = updated == null ? null : now.difference(updated);
          final boost = age == null
              ? 0.0
              : recencyWeight * math.pow(0.5, math.max(0, age.inMinutes) / recencyHalfLife.inMinutes);
          return SearchMatch(
            entityType: r.read<String>('et'),
            entityId: r.read<String>('eid'),
            parentId: r.readNullable<String>('pid'),
            title: r.readNullable<String>('title') ?? '',
            updatedAt: updated,
            score: relevance * (1 + boost),
            snippet: switch (r.readNullable<String>('snip')) {
              final s? when s.contains(SearchMatch.snippetStart) => s,
              _ => null,
            },
          );
        }(),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return hits.take(limit).toList();
  }

  /// Rebuilds the index from the live rows (one transaction).
  Future<void> rebuild() => _db.transaction(() async {
    for (final statement in SearchIndexSchema.rebuildStatements) {
      await _db.customStatement(statement);
    }
  });

  /// Number of indexed rows.
  Future<int> count() async =>
      (await _db.customSelect('SELECT COUNT(*) AS n FROM search_index').getSingle()).read<int>('n');
}
