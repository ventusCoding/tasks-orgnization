import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/search_index.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Global search (T8.1.14): FTS hits from [SearchIndex] enriched with what results show and filter
/// on — breadcrumbs, links, category, tags, open/closed and the row's day. Rows of archived parents
/// stay findable; tombstoned ones never are (the index drops them).
class GlobalSearchQueries {
  GlobalSearchQueries(this._db, this._index, this._dayOf);

  final AppDatabase _db;
  final SearchIndex _index;

  /// Local day of an instant (device zone).
  final LocalDate Function(DateTime utc) _dayOf;

  /// Ranked, enriched results for [query]; [kinds] narrows the index query itself.
  Future<List<SearchResult>> search(String query, {Set<SearchKind>? kinds, int limit = 200}) async {
    final matches = await _index.search(
      query,
      entityTypes: kinds == null || kinds.isEmpty ? null : {for (final k in kinds) k.json},
      limit: limit,
    );
    if (matches.isEmpty) return const [];
    final byType = <String, List<String>>{};
    for (final m in matches) {
      (byType[m.entityType] ??= []).add(m.entityId);
    }
    final meta = <String, _Meta>{};
    Future<void> load(String type, String sql, _Meta Function(QueryRow r) read) async {
      final ids = byType[type];
      if (ids == null) return;
      for (final r in await _db.customSelect('$sql (${_in(ids.length)})', variables: _vars(ids)).get()) {
        meta['$type|${r.read<String>('id')}'] = read(r);
      }
    }

    await load(
      'task',
      'SELECT id, category_id, status, start_local FROM tasks WHERE id IN',
      (r) => _Meta(
        categoryId: r.readNullable<String>('category_id'),
        closed: r.read<String>('status') == 'archived',
        day: LocalDateTime.tryParse(r.readNullable<String>('start_local') ?? '')?.date,
      ),
    );
    await load(
      'checklist',
      'SELECT id, category_id, archived_at FROM checklists WHERE id IN',
      (r) => _Meta(
        categoryId: r.readNullable<String>('category_id'),
        closed: r.readNullable<String>('archived_at') != null,
      ),
    );
    await load(
      'checklist_item',
      'SELECT i.id, c.title AS list, c.category_id, i.status, i.due_local FROM checklist_items i '
          'LEFT JOIN checklists c ON c.id = i.checklist_id WHERE i.id IN',
      (r) => _Meta(
        categoryId: r.readNullable<String>('category_id'),
        closed: const {'completed', 'cancelled'}.contains(r.read<String>('status')),
        day: _date(r.readNullable<String>('due_local')),
        breadcrumb: [r.readNullable<String>('list') ?? ''],
      ),
    );
    await load(
      'habit',
      'SELECT id, kind, category_id, archived_at FROM habits WHERE id IN',
      (r) => _Meta(
        categoryId: r.readNullable<String>('category_id'),
        closed: r.readNullable<String>('archived_at') != null,
        quit: r.read<String>('kind') == 'quit',
        link: r.read<String>('kind') == 'quit' ? AppLinks.quit(r.read<String>('id')) : null,
      ),
    );
    await load(
      'habit_log',
      'SELECT l.id, l.habit_id, h.kind, h.name, h.category_id, l.local_date FROM habit_logs l '
          'LEFT JOIN habits h ON h.id = l.habit_id WHERE l.id IN',
      (r) => _Meta(
        quit: r.readNullable<String>('kind') == 'quit',
        link: r.readNullable<String>('kind') == 'quit' ? AppLinks.quit(r.read<String>('habit_id')) : null,
        categoryId: r.readNullable<String>('category_id'),
        day: LocalDate.tryParse(r.read<String>('local_date')),
        breadcrumb: [r.readNullable<String>('name') ?? ''],
      ),
    );
    await load(
      'notification',
      'SELECT id, fire_at, read_at, payload, source_type, source_id FROM notifications WHERE id IN',
      (r) {
        final fired = DateTime.tryParse(r.read<String>('fire_at'))?.toUtc();
        final payload = _json(r.read<String>('payload'));
        final sourceType = r.readNullable<String>('source_type');
        final sourceId = r.readNullable<String>('source_id');
        return _Meta(
          closed: r.readNullable<String>('read_at') != null,
          day: fired == null ? null : _dayOf(fired),
          link:
              payload['link'] as String? ??
              (sourceType == null || sourceId == null ? null : AppLinks.forEntity(sourceType, sourceId)) ??
              AppLinks.inbox(),
        );
      },
    );
    final ancestors = await _ancestors(byType['checklist_item'] ?? const []);
    final tags = await _tags(matches);
    return [
      for (final m in matches)
        if (SearchKind.tryParse(m.entityType) case final kind?)
          () {
            final x = meta['${m.entityType}|${m.entityId}'] ?? const _Meta();
            return SearchResult(
              kind: kind,
              id: m.entityId,
              parentId: m.parentId,
              title: m.title,
              score: m.score,
              snippet: m.snippet,
              breadcrumb: [...x.breadcrumb, ...?ancestors[m.entityId]],
              link: x.link ?? AppLinks.forEntity(m.entityType, m.entityId, parentId: m.parentId),
              categoryId: x.categoryId,
              tagIds: tags['${m.entityType}|${m.entityId}'] ?? const {},
              closed: x.closed,
              day: x.day ?? (m.updatedAt == null ? null : _dayOf(m.updatedAt!)),
              quit: x.quit,
            );
          }(),
    ];
  }

  /// Ancestor item texts per item, root first.
  Future<Map<String, List<String>>> _ancestors(List<String> itemIds) async {
    if (itemIds.isEmpty) return const {};
    final rows = await _db
        .customSelect(
          'WITH RECURSIVE anc(item_id, parent_id, txt, lvl) AS ('
          ' SELECT i.id, i.parent_id, NULL, 0 FROM checklist_items i WHERE i.id IN (${_in(itemIds.length)})'
          ' UNION ALL'
          ' SELECT anc.item_id, p.parent_id, p.text, anc.lvl + 1 FROM anc JOIN checklist_items p ON p.id = anc.parent_id'
          ' WHERE anc.lvl < 200'
          ') SELECT item_id, txt, lvl FROM anc WHERE lvl > 0 ORDER BY item_id, lvl DESC',
          variables: _vars(itemIds),
        )
        .get();
    final out = <String, List<String>>{};
    for (final r in rows) {
      (out[r.read<String>('item_id')] ??= []).add(r.readNullable<String>('txt') ?? '');
    }
    return out;
  }

  Future<Map<String, Set<String>>> _tags(List<SearchMatch> matches) async {
    final ids = {for (final m in matches) m.entityId}.toList();
    final rows = await _db
        .customSelect(
          'SELECT entity_type, entity_id, tag_id FROM entity_tags '
          'WHERE deleted_at IS NULL AND entity_id IN (${_in(ids.length)})',
          variables: _vars(ids),
        )
        .get();
    final out = <String, Set<String>>{};
    for (final r in rows) {
      (out['${r.read<String>('entity_type')}|${r.read<String>('entity_id')}'] ??= {}).add(r.read<String>('tag_id'));
    }
    return out;
  }

  static String _in(int n) => List.filled(n, '?').join(', ');
  static List<Variable<String>> _vars(List<String> ids) => [for (final id in ids) Variable<String>(id)];

  static LocalDate? _date(String? local) =>
      local == null ? null : (LocalDateTime.tryParse(local)?.date ?? LocalDate.tryParse(local));

  static Map<String, Object?> _json(String raw) {
    try {
      return switch (jsonDecode(raw)) {
        final Map<String, Object?> m => m,
        _ => const {},
      };
    } on FormatException {
      return const {};
    }
  }
}

class _Meta {
  const _Meta({
    this.categoryId,
    this.closed = false,
    this.day,
    this.breadcrumb = const [],
    this.link,
    this.quit = false,
  });

  final String? categoryId;
  final bool closed;
  final LocalDate? day;
  final List<String> breadcrumb;
  final String? link;
  final bool quit;
}
