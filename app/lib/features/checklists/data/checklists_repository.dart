import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/search_index.dart' show SearchIndexSchema;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/attachments/application/providers.dart'
    show Attachment, AttachmentOwnerType, AttachmentTx;
import 'package:everslot/features/checklists/data/checklist_cascades.dart';
import 'package:everslot/features/checklists/data/checklist_items_repository.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Result of commands that create a checklist.
typedef CreatedChecklist = ({String id, OpRecord record});

/// Checklists / note cards (T4.1.02, T4.1.04): board queries, header writes, cascading deletes
/// with `restore(opId)`, duplicates, templates.
class ChecklistsRepository {
  ChecklistsRepository(this._db, this._writer, this._userId, {this._cascades});

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;
  final ChecklistCascades? _cascades;

  static Map<String, Object?>? _json(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final d = jsonDecode(s);
      return d is Map ? Map<String, Object?>.from(d) : null;
    } on Object {
      return null;
    }
  }

  static Checklist map(ChecklistRow r) => Checklist(
    id: r.id,
    title: r.title,
    body: r.body,
    color: r.color,
    categoryId: r.categoryId,
    isPinned: r.isPinned,
    sortKey: r.sortKey,
    archivedAt: r.archivedAt,
    coverAttachmentId: r.coverAttachmentId,
    dueLocal: r.dueLocal == null ? null : LocalDateTime.tryParse(r.dueLocal!),
    timeZone: r.timeZone,
    resetRule: _json(r.resetRule),
    resetMode: ResetMode.parse(r.resetMode),
    lastResetKey: r.lastResetKey,
    settings: ChecklistSettings.fromJson(_json(r.settings) ?? const {}),
    isTemplate: r.isTemplate,
    templateId: r.templateId,
    notifyMode: r.notifyMode,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
  );

  // ------------------------------------------------------------------ reads

  /// Board cards: live, non-template, archived or not; ordered by `(sort_key, id)`.
  Stream<List<Checklist>> watchBoard({bool archived = false, bool templates = false}) {
    final q = _db.select(_db.checklists)
      ..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()) & c.isTemplate.equals(templates))
      ..orderBy([(c) => OrderingTerm.asc(c.sortKey), (c) => OrderingTerm.asc(c.id)]);
    if (!templates) q.where((c) => archived ? c.archivedAt.isNotNull() : c.archivedAt.isNull());
    return q.watch().map((rows) => rows.map(map).toList());
  }

  /// One checklist, including tombstones (the screen offers Trash for deleted ones).
  Stream<Checklist?> watchChecklist(String id) =>
      (_db.select(_db.checklists)..where((c) => c.id.equals(id) & c.userId.equals(_userId()))).watchSingleOrNull().map(
        (r) => r == null ? null : map(r),
      );

  Future<Checklist?> byId(String id) async {
    final r = await (_db.select(_db.checklists)..where((c) => c.id.equals(id))).getSingleOrNull();
    return r == null ? null : map(r);
  }

  /// Live, non-archived, non-template lists of the user (notification targets).
  Future<List<Checklist>> notifiableLists() async =>
      (await (_db.select(_db.checklists)..where(
                (c) =>
                    c.deletedAt.isNull() &
                    c.userId.equals(_userId()) &
                    c.archivedAt.isNull() &
                    c.isTemplate.equals(false),
              ))
              .get())
          .map(map)
          .toList();

  /// Live, non-template checklists that have a reset rule (reset service).
  Future<List<Checklist>> recurring() async =>
      (await (_db.select(_db.checklists)..where(
                (c) =>
                    c.deletedAt.isNull() &
                    c.userId.equals(_userId()) &
                    c.resetRule.isNotNull() &
                    c.isTemplate.equals(false),
              ))
              .get())
          .map(map)
          .toList();

  static String _in(int n) => List.filled(n, '?').join(', ');

  /// Card summaries of [ids] in two aggregate queries (no N+1, T4.1.08): leaf/all status counts
  /// and the first rows at depth ≤ 2 in outline order.
  Stream<Map<String, CardSummary>> watchCardSummaries(List<String> ids, {required DateTime now, int maxRows = 6}) {
    if (ids.isEmpty) return Stream.value(const {});
    final vars = [for (final id in ids) Variable<String>(id)];
    final counts = _db.customSelect(
      'SELECT i.checklist_id AS cid, i.status AS status, COUNT(*) AS n_all, '
      'SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM checklist_items k WHERE k.parent_id = i.id AND k.deleted_at IS NULL) '
      'THEN 1 ELSE 0 END) AS n_leaf, '
      "SUM(CASE WHEN i.status IN ('todo','ongoing','waiting','blocked') AND i.updated_at < "
      r"strftime('%Y-%m-%dT%H:%M:%fZ', ?, '-' || COALESCE(json_extract(c.settings, '$.staleAfterDays'), 14) || ' days') "
      'THEN 1 ELSE 0 END) AS n_stale, '
      "SUM(CASE WHEN i.due_local IS NOT NULL AND i.status IN ('todo','ongoing','waiting','blocked') "
      'THEN 1 ELSE 0 END) AS n_due '
      'FROM checklist_items i JOIN checklists c ON c.id = i.checklist_id '
      // Mirrors (T4.5.16) are not counted: stats count originals only.
      'WHERE i.deleted_at IS NULL AND i.mirror_of_id IS NULL AND i.checklist_id IN (${_in(ids.length)}) '
      'GROUP BY i.checklist_id, i.status',
      variables: [Variable<String>(now.toUtc().toIso8601String()), ...vars],
      readsFrom: {_db.checklistItems, _db.checklists},
    );
    final rows = _db.customSelect(
      'WITH RECURSIVE t(cid, id, txt, status, depth, path) AS ('
      ' SELECT checklist_id, id, text, status, 0, sort_key || char(1) || id FROM checklist_items'
      ' WHERE parent_id IS NULL AND deleted_at IS NULL AND checklist_id IN (${_in(ids.length)})'
      ' UNION ALL'
      ' SELECT c.checklist_id, c.id, c.text, c.status, t.depth + 1, t.path || char(2) || c.sort_key || char(1) || c.id'
      ' FROM checklist_items c JOIN t ON c.parent_id = t.id WHERE c.deleted_at IS NULL AND t.depth < 2'
      ') SELECT cid, id, txt, status, depth FROM ('
      ' SELECT *, ROW_NUMBER() OVER (PARTITION BY cid ORDER BY path) AS rn FROM t'
      ') WHERE rn <= ? ORDER BY cid, rn',
      variables: [...vars, Variable<int>(maxRows)],
      readsFrom: {_db.checklistItems},
    );
    return counts.watch().asyncMap((countRows) async {
      final previews = await rows.get();
      final byChecklist = <String, List<CardRow>>{};
      for (final r in previews) {
        (byChecklist[r.read<String>('cid')] ??= []).add(
          CardRow(
            id: r.read<String>('id'),
            text: r.read<String>('txt'),
            status: ItemStatus.parse(r.read<String>('status')),
            depth: r.read<int>('depth'),
          ),
        );
      }
      final agg = <String, Map<String, (int, int, int, int)>>{};
      for (final r in countRows) {
        (agg[r.read<String>('cid')] ??= {})[r.read<String>('status')] = (
          r.read<int>('n_all'),
          r.read<int>('n_leaf'),
          r.read<int>('n_stale'),
          r.read<int>('n_due'),
        );
      }
      final out = <String, CardSummary>{};
      for (final id in ids) {
        final a = agg[id] ?? const {};
        int leaf(ItemStatus s) => a[s.name]?.$2 ?? 0;
        int all(ItemStatus s) => a[s.name]?.$1 ?? 0;
        final total = a.values.fold<int>(0, (x, e) => x + e.$1);
        final shown = byChecklist[id] ?? const <CardRow>[];
        out[id] = CardSummary(
          rollup: Rollup(
            leafCountable: ItemStatus.values.where((s) => s.isCountable).fold(0, (x, s) => x + leaf(s)),
            leafCompleted: leaf(ItemStatus.completed),
            todo: leaf(ItemStatus.todo),
            ongoing: leaf(ItemStatus.ongoing),
            waiting: leaf(ItemStatus.waiting),
            blocked: leaf(ItemStatus.blocked),
            completed: leaf(ItemStatus.completed),
            cancelled: leaf(ItemStatus.cancelled),
            blockedBelow: all(ItemStatus.blocked),
            waitingBelow: all(ItemStatus.waiting),
            descendants: total,
          ),
          rows: shown,
          moreCount: total - shown.length,
          itemCount: total,
          staleCount: a.values.fold(0, (x, e) => x + e.$3),
          dueCount: a.values.fold(0, (x, e) => x + e.$4),
        );
      }
      return out;
    });
  }

  /// Card thumbnails (T4.1.08 / T4.4.05 / T4.1.17): cover, else first checklist-level image,
  /// else the first item image in outline-ish order.
  Stream<Map<String, Attachment>> watchCardThumbnails(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const {});
    final vars = [for (final id in ids) Variable<String>(id)];
    return _db
        .customSelect(
          'SELECT cid, aid FROM ('
          ' SELECT u.cid, u.aid, ROW_NUMBER() OVER (PARTITION BY u.cid ORDER BY u.pri, u.k, u.aid) AS rn FROM ('
          '  SELECT a.owner_id AS cid, a.id AS aid, CASE WHEN c.cover_attachment_id = a.id THEN 0 ELSE 1 END AS pri,'
          '   a.sort_key AS k FROM attachments a JOIN checklists c ON c.id = a.owner_id'
          "   WHERE a.owner_type = 'checklist' AND a.deleted_at IS NULL AND a.mime_type LIKE 'image/%'"
          '   AND a.owner_id IN (${_in(ids.length)})'
          '  UNION ALL'
          '  SELECT i.checklist_id, a.id, CASE WHEN c.cover_attachment_id = a.id THEN 0 ELSE 2 END,'
          '   i.sort_key || a.sort_key FROM attachments a JOIN checklist_items i ON i.id = a.owner_id'
          '   JOIN checklists c ON c.id = i.checklist_id'
          "   WHERE a.owner_type = 'checklist_item' AND a.deleted_at IS NULL AND i.deleted_at IS NULL"
          "   AND a.mime_type LIKE 'image/%' AND i.checklist_id IN (${_in(ids.length)})"
          ' ) u'
          ') WHERE rn = 1',
          variables: [...vars, ...vars],
          readsFrom: {_db.attachments, _db.checklistItems, _db.checklists},
        )
        .watch()
        .asyncMap((rows) async {
          if (rows.isEmpty) return const <String, Attachment>{};
          final byAid = {for (final r in rows) r.read<String>('aid'): r.read<String>('cid')};
          final atts = await (_db.select(_db.attachments)..where((a) => a.id.isIn(byAid.keys))).get();
          return {
            for (final a in atts)
              byAid[a.id]!: Attachment(
                id: a.id,
                ownerType: a.ownerType,
                ownerId: a.ownerId,
                bucket: a.bucket,
                storagePath: a.storagePath,
                thumbPath: a.thumbPath,
                fileName: a.fileName,
                mimeType: a.mimeType,
                byteSize: a.byteSize,
                width: a.width,
                height: a.height,
                sha256: a.sha256,
                caption: a.caption,
                sortKey: a.sortKey,
                uploadedAt: a.uploadedAt,
              ),
          };
        });
  }

  /// Live items of active lists; mirrors (T4.5.16) are left out so nothing is listed or counted
  /// twice.
  static const _activeListFilter =
      'i.deleted_at IS NULL AND i.mirror_of_id IS NULL AND c.deleted_at IS NULL AND c.archived_at IS NULL '
      'AND c.is_template = 0';

  /// Chip counts across all non-archived lists (T4.5.01).
  Stream<SmartCounts> watchSmartCounts({required DateTime now}) => _db
      .customSelect(
        "SELECT SUM(CASE WHEN i.status = 'waiting' THEN 1 ELSE 0 END) AS w, "
        "SUM(CASE WHEN i.status = 'blocked' THEN 1 ELSE 0 END) AS b, "
        "SUM(CASE WHEN i.status = 'ongoing' THEN 1 ELSE 0 END) AS o, "
        "SUM(CASE WHEN i.follow_up_at IS NOT NULL AND i.follow_up_at <= ? AND i.status IN ('todo','ongoing','waiting','blocked') "
        'THEN 1 ELSE 0 END) AS f '
        'FROM checklist_items i JOIN checklists c ON c.id = i.checklist_id '
        'WHERE $_activeListFilter AND i.user_id = ?',
        variables: [Variable<String>(now.toUtc().toIso8601String()), Variable<String>(_userId())],
        readsFrom: {_db.checklistItems, _db.checklists},
      )
      .watchSingle()
      .map(
        (r) => SmartCounts(
          waiting: r.read<int?>('w') ?? 0,
          blocked: r.read<int?>('b') ?? 0,
          ongoing: r.read<int?>('o') ?? 0,
          followUps: r.read<int?>('f') ?? 0,
        ),
      );

  /// Items of a smart view with checklist title and breadcrumb path (T4.5.01).
  Stream<List<SmartItem>> watchSmartItems(SmartKind kind, {required DateTime now}) {
    final status = kind.status;
    final where = status != null
        ? 'i.status = ?'
        : "i.follow_up_at IS NOT NULL AND i.follow_up_at <= ? AND i.status IN ('todo','ongoing','waiting','blocked')";
    final firstVar = status != null ? Variable<String>(status.name) : Variable<String>(now.toUtc().toIso8601String());
    return _db
        .customSelect(
          'SELECT i.id AS id, c.title AS ctitle, c.color AS ccolor FROM checklist_items i '
          'JOIN checklists c ON c.id = i.checklist_id WHERE $_activeListFilter AND i.user_id = ? AND $where',
          variables: [Variable<String>(_userId()), firstVar],
          readsFrom: {_db.checklistItems, _db.checklists},
        )
        .watch()
        .asyncMap((rows) async {
          if (rows.isEmpty) return const <SmartItem>[];
          final ids = [for (final r in rows) r.read<String>('id')];
          final items = {
            for (final r in await (_db.select(_db.checklistItems)..where((i) => i.id.isIn(ids))).get())
              r.id: ChecklistItemsRepository.map(r),
          };
          final paths = await _paths(ids);
          return [
            for (final r in rows)
              if (items[r.read<String>('id')] != null)
                SmartItem(
                  item: items[r.read<String>('id')]!,
                  checklistTitle: r.read<String>('ctitle'),
                  checklistColor: r.read<int?>('ccolor'),
                  path: paths[r.read<String>('id')] ?? const [],
                ),
          ];
        });
  }

  /// Every live item of the active (not archived, not template) lists with its list and
  /// breadcrumb — the flat all-items table (T4.5.15). At most [limit] items, list order then
  /// outline-ish order.
  Stream<List<SmartItem>> watchAllItems({int limit = 20000}) => _db
      .customSelect(
        'SELECT i.id AS id, c.title AS ctitle, c.color AS ccolor FROM checklist_items i '
        'JOIN checklists c ON c.id = i.checklist_id WHERE $_activeListFilter AND i.user_id = ? '
        'ORDER BY c.sort_key, c.id, i.sort_key, i.id LIMIT ?',
        variables: [Variable<String>(_userId()), Variable<int>(limit)],
        readsFrom: {_db.checklistItems, _db.checklists},
      )
      .watch()
      .asyncMap((rows) async {
        if (rows.isEmpty) return const <SmartItem>[];
        final ids = [for (final r in rows) r.read<String>('id')];
        final items = <String, ChecklistItem>{};
        for (var k = 0; k < ids.length; k += 900) {
          final chunk = ids.sublist(k, k + 900 > ids.length ? ids.length : k + 900);
          for (final r in await (_db.select(_db.checklistItems)..where((i) => i.id.isIn(chunk))).get()) {
            items[r.id] = ChecklistItemsRepository.map(r);
          }
        }
        final paths = await _paths(ids);
        return [
          for (final r in rows)
            if (items[r.read<String>('id')] != null)
              SmartItem(
                item: items[r.read<String>('id')]!,
                checklistTitle: r.read<String>('ctitle'),
                checklistColor: r.read<int?>('ccolor'),
                path: paths[r.read<String>('id')] ?? const [],
              ),
        ];
      });

  /// Live attachment counts of every item in the active lists (all-items table).
  Stream<Map<String, int>> watchAllItemAttachmentCounts() => _db
      .customSelect(
        'SELECT a.owner_id AS id, COUNT(*) AS n FROM attachments a '
        'JOIN checklist_items i ON i.id = a.owner_id JOIN checklists c ON c.id = i.checklist_id '
        "WHERE a.owner_type = 'checklist_item' AND a.deleted_at IS NULL AND $_activeListFilter "
        'AND i.user_id = ? GROUP BY a.owner_id',
        variables: [Variable<String>(_userId())],
        readsFrom: {_db.attachments, _db.checklistItems, _db.checklists},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('id'): r.read<int>('n')});

  /// Breadcrumb texts (root first) for items, via one recursive query.
  Future<Map<String, List<String>>> _paths(List<String> ids) async {
    final out = <String, List<(int, String)>>{};
    for (var i = 0; i < ids.length; i += 400) {
      final chunk = ids.sublist(i, i + 400 > ids.length ? ids.length : i + 400);
      final rows = await _db
          .customSelect(
            'WITH RECURSIVE anc(item_id, id, parent_id, txt, lvl) AS ('
            ' SELECT i.id, p.id, p.parent_id, p.text, 1 FROM checklist_items i JOIN checklist_items p ON p.id = i.parent_id'
            ' WHERE i.id IN (${_in(chunk.length)})'
            ' UNION ALL'
            ' SELECT anc.item_id, p.id, p.parent_id, p.text, anc.lvl + 1 FROM anc JOIN checklist_items p ON p.id = anc.parent_id'
            ' WHERE anc.lvl < 200'
            ') SELECT item_id, txt, lvl FROM anc',
            variables: [for (final id in chunk) Variable<String>(id)],
          )
          .get();
      for (final r in rows) {
        (out[r.read<String>('item_id')] ??= []).add((r.read<int>('lvl'), r.read<String>('txt')));
      }
    }
    return {
      for (final e in out.entries) e.key: [for (final p in (e.value..sort((a, b) => b.$1.compareTo(a.$1)))) p.$2],
    };
  }

  /// Board search over titles, bodies and item texts through the FTS index (T4.1.13, T2.3.11).
  /// Matching ignores case, French diacritics, Arabic letter variants and harakat.
  Future<BoardSearchResult> search(String query) async {
    final match = SearchIndexSchema.matchExpression(query);
    if (match == null) return const BoardSearchResult();
    final rows = await _db
        .customSelect(
          'SELECT s.entity_type AS et, s.entity_id AS eid, s.parent_id AS pid FROM search_index s '
          "WHERE search_index MATCH ? AND s.entity_type IN ('checklist', 'checklist_item') LIMIT 1000",
          variables: [Variable<String>(match)],
        )
        .get();
    final live = {
      for (final c in await (_db.select(
        _db.checklists,
      )..where((c) => c.deletedAt.isNull() & c.userId.equals(_userId()) & c.isTemplate.equals(false))).get())
        c.id: c,
    };
    final checklistIds = <String>{};
    final itemIds = <String>[];
    for (final r in rows) {
      final et = r.read<String>('et');
      final eid = r.read<String>('eid');
      final pid = r.readNullable<String>('pid');
      if (et == 'checklist' && live.containsKey(eid)) checklistIds.add(eid);
      if (et == 'checklist_item' && pid != null && live.containsKey(pid)) {
        checklistIds.add(pid);
        itemIds.add(eid);
      }
    }
    if (itemIds.isEmpty) return BoardSearchResult(checklistIds: checklistIds);
    final items = await (_db.select(_db.checklistItems)..where((i) => i.id.isIn(itemIds) & i.deletedAt.isNull())).get();
    final paths = await _paths([for (final i in items) i.id]);
    return BoardSearchResult(
      checklistIds: checklistIds,
      items: [
        for (final i in items)
          SearchHit(
            itemId: i.id,
            checklistId: i.checklistId,
            text: i.itemText,
            checklistTitle: live[i.checklistId]?.title ?? '',
            path: paths[i.id] ?? const [],
          ),
      ],
    );
  }

  /// Keys of the first card of a board section (new cards go on top).
  Future<String?> _firstKey({required bool pinned}) async {
    final row =
        await (_db.select(_db.checklists)
              ..where(
                (c) =>
                    c.deletedAt.isNull() &
                    c.userId.equals(_userId()) &
                    c.archivedAt.isNull() &
                    c.isTemplate.equals(false) &
                    c.isPinned.equals(pinned),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.sortKey)])
              ..limit(1))
            .getSingleOrNull();
    return row?.sortKey;
  }

  /// Sort key placing a new card at the top of the unpinned section.
  Future<String> topSortKey() async => SortKeys.between(null, await _firstKey(pinned: false));

  // ------------------------------------------------------------------ writes

  /// Creates a card at the top of its section (T4.1.04 / T4.1.09).
  Future<CreatedChecklist> create({
    String title = '',
    String? body,
    int? color,
    String? categoryId,
    bool isPinned = false,
    ChecklistSettings settings = ChecklistSettings.defaults,
    bool isTemplate = false,
    String? templateId,
    List<NodeSpec> items = const [],
    DateTime? now,
    String? id,
  }) async {
    final newId = id ?? Ids.v7();
    final key = SortKeys.between(null, isTemplate ? null : await _firstKey(pinned: isPinned));
    final record = await _writer.run((tx) async {
      await tx.insert('checklists', newId, {
        'title': ChecklistTitle(title).value,
        'body': ItemText.body(body),
        'color': color,
        'category_id': categoryId,
        'is_pinned': isPinned,
        'sort_key': key,
        'settings': settings.toJson(),
        'is_template': isTemplate,
        'template_id': templateId,
      });
      await tx.logEvent(entityType: 'checklist', entityId: newId, eventType: 'created');
      if (items.isNotEmpty) {
        final change = TreeOps.insertNodes(
          ChecklistTree.empty,
          TreeOpContext(checklistId: newId, now: now ?? tx.now, newId: Ids.v7, settings: settings, cause: tx.cause),
          items,
        );
        await ChecklistItemsRepository.applyInTx(tx, change, cascades: _cascades);
      }
    });
    return (id: newId, record: record);
  }

  Future<OpRecord> update(
    String id, {
    String? title,
    String? body,
    bool clearBody = false,
    int? color,
    bool clearColor = false,
    String? categoryId,
    bool clearCategory = false,
    ChecklistSettings? settings,
    String? coverAttachmentId,
    bool clearCover = false,
  }) => _writer.run((tx) async {
    final changed = await tx.update('checklists', id, {
      if (title != null) 'title': ChecklistTitle(title).value,
      if (body != null || clearBody) 'body': clearBody ? null : ItemText.body(body),
      if (color != null || clearColor) 'color': clearColor ? null : color,
      if (categoryId != null || clearCategory) 'category_id': clearCategory ? null : categoryId,
      if (settings != null) 'settings': settings.toJson(),
      if (coverAttachmentId != null || clearCover) 'cover_attachment_id': clearCover ? null : coverAttachmentId,
    });
    if (changed) {
      await tx.logEvent(
        entityType: 'checklist',
        entityId: id,
        eventType: 'updated',
        payload: {
          'fields': [
            if (title != null) 'title',
            if (body != null || clearBody) 'body',
            if (color != null || clearColor) 'color',
            if (categoryId != null || clearCategory) 'category',
            if (settings != null) 'settings',
            if (coverAttachmentId != null || clearCover) 'cover',
          ],
        },
      );
    }
  });

  Future<OpRecord> setPinned(String id, {required bool pinned}) =>
      _writer.run((tx) => tx.update('checklists', id, {'is_pinned': pinned}));

  Future<OpRecord> setArchived(String id, {required bool archived}) => _writer.run((tx) async {
    await tx.update('checklists', id, {'archived_at': archived ? tx.now : null});
    await tx.logEvent(entityType: 'checklist', entityId: id, eventType: archived ? 'archived' : 'unarchived');
  });

  /// Reorders a card between two neighbours of its section (T4.1.10).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run((tx) => tx.update('checklists', id, {'sort_key': SortKeys.between(afterKey, beforeKey)}));

  /// Tombstones the checklist, its items, their attachments and tags under one `opId` (T4.1.04).
  Future<OpRecord> delete(String id) => _writer.run((tx) async {
    final itemIds = [
      for (final r
          in await tx.db
              .customSelect(
                'SELECT id FROM checklist_items WHERE checklist_id = ? AND deleted_at IS NULL',
                variables: [Variable<String>(id)],
              )
              .get())
        r.read<String>('id'),
    ];
    for (final itemId in itemIds) {
      await tx.softDelete('checklist_items', itemId);
    }
    // Mirrors of these items in other lists become plain copies (T4.5.16).
    await ChecklistItemsRepository.detachMirrors(tx, itemIds);
    await AttachmentTx.softDeleteForOwners(tx, AttachmentOwnerType.checklistItem, itemIds);
    await AttachmentTx.softDeleteForOwners(tx, AttachmentOwnerType.checklist, [id]);
    await ChecklistItemsRepository.deleteEntityTags(tx, 'checklist_item', itemIds);
    await ChecklistItemsRepository.deleteEntityTags(tx, 'checklist', [id]);
    await _cascades?.itemsDeleted(tx, itemIds);
    await _cascades?.checklistDeleted(tx, id);
    await tx.softDelete('checklists', id);
    await tx.logEvent(
      entityType: 'checklist',
      entityId: id,
      eventType: 'deleted',
      payload: {'deletedAt': tx.now.toUtc().toIso8601String(), 'count': itemIds.length},
    );
  });

  /// Restores exactly what the delete operation [opId] tombstoned (and nothing deleted earlier).
  Future<OpRecord?> restore(String opId) async {
    final event = await _db
        .customSelect(
          "SELECT entity_id, payload FROM activity_events WHERE entity_type = 'checklist' AND event_type = 'deleted' "
          r"AND json_extract(payload, '$.opId') = ? LIMIT 1",
          variables: [Variable<String>(opId)],
        )
        .getSingleOrNull();
    if (event == null) return null;
    final id = event.read<String>('entity_id');
    final deletedAt = _json(event.read<String>('payload'))?['deletedAt'] as String?;
    if (deletedAt == null) return null;
    return _writer.run((tx) async {
      Future<List<String>> ids(String sql) async => [
        for (final r
            in await tx.db.customSelect(sql, variables: [Variable<String>(id), Variable<String>(deletedAt)]).get())
          r.read<String>('id'),
      ];
      final items = await ids('SELECT id FROM checklist_items WHERE checklist_id = ? AND deleted_at = ?');
      for (final i in items) {
        await tx.restore('checklist_items', i);
      }
      final atts = await ids(
        'SELECT a.id FROM attachments a WHERE a.deleted_at = ?2 AND ('
        "(a.owner_type = 'checklist' AND a.owner_id = ?1) OR "
        "(a.owner_type = 'checklist_item' AND a.owner_id IN (SELECT id FROM checklist_items WHERE checklist_id = ?1)))",
      );
      for (final a in atts) {
        await tx.restore('attachments', a);
      }
      final tags = await ids(
        'SELECT t.id FROM entity_tags t WHERE t.deleted_at = ?2 AND ('
        "(t.entity_type = 'checklist' AND t.entity_id = ?1) OR "
        "(t.entity_type = 'checklist_item' AND t.entity_id IN (SELECT id FROM checklist_items WHERE checklist_id = ?1)))",
      );
      for (final t in tags) {
        await tx.restore('entity_tags', t);
      }
      await tx.restore('checklists', id);
      await tx.logEvent(entityType: 'checklist', entityId: id, eventType: 'restored', payload: {'fromOpId': opId});
    });
  }

  /// Deep copy (T4.1.14): new checklist + items (fresh ids, same order) + attachment rows by
  /// reference + tags, as one op group.
  Future<CreatedChecklist> duplicate(
    String sourceId, {
    required String title,
    bool resetStatuses = false,
    bool asTemplate = false,
    bool fromTemplate = false,
  }) async {
    final src = await byId(sourceId);
    if (src == null) throw StateError('checklist $sourceId not found');
    final newId = Ids.v7();
    final key = SortKeys.between(null, asTemplate ? null : await _firstKey(pinned: src.isPinned && !fromTemplate));
    final record = await _writer.run((tx) async {
      await tx.insert('checklists', newId, {
        'title': ChecklistTitle(title).value,
        'body': src.body,
        'color': src.color,
        'category_id': src.categoryId,
        'is_pinned': !asTemplate && !fromTemplate && src.isPinned,
        'sort_key': key,
        'settings': src.settings.toJson(),
        'reset_rule': src.resetRule,
        'reset_mode': src.resetMode?.dbValue,
        'is_template': asTemplate,
        'template_id': fromTemplate ? sourceId : (asTemplate ? null : src.templateId),
      });
      final rows = await tx.db
          .customSelect(
            'SELECT * FROM checklist_items WHERE checklist_id = ? AND deleted_at IS NULL',
            variables: [Variable<String>(sourceId)],
          )
          .get();
      final idMap = {for (final r in rows) r.data['id']! as String: Ids.v7()};
      for (final r in rows) {
        final d = r.data;
        final keep = !resetStatuses;
        final parent = d['parent_id'] as String?;
        await tx.insert('checklist_items', idMap[d['id']]!, {
          'checklist_id': newId,
          'parent_id': parent == null ? null : idMap[parent],
          'sort_key': d['sort_key'],
          'text': d['text'],
          'note': d['note'],
          'status': keep ? d['status'] : ItemStatus.todo.name,
          'status_note': keep ? d['status_note'] : null,
          'status_changed_at': keep ? d['status_changed_at'] : null,
          'completed_at': keep ? d['completed_at'] : null,
          'follow_up_at': keep ? d['follow_up_at'] : null,
          'due_local': d['due_local'],
          'time_zone': d['time_zone'],
          'priority': d['priority'],
          'estimate_minutes': d['estimate_minutes'],
        });
      }
      await AttachmentTx.copyForOwners(tx, fromType: AttachmentOwnerType.checklistItem, ownerIdMap: idMap);
      await AttachmentTx.copyForOwners(tx, fromType: AttachmentOwnerType.checklist, ownerIdMap: {sourceId: newId});
      await ChecklistItemsRepository.copyEntityTags(tx, 'checklist_item', idMap);
      await ChecklistItemsRepository.copyEntityTags(tx, 'checklist', {sourceId: newId});
      await _cascades?.itemsCopied(tx, idMap);
      await _cascades?.checklistCopied(tx, fromId: sourceId, toId: newId);
      await tx.logEvent(
        entityType: 'checklist',
        entityId: newId,
        eventType: 'created',
        payload: {if (fromTemplate) 'fromTemplateId': sourceId else 'duplicatedFrom': sourceId, 'count': rows.length},
      );
    });
    return (id: newId, record: record);
  }

  /// Reset configuration (T4.5.06). [lastResetKey] marks past occurrences as done.
  Future<OpRecord> setResetRule(String id, {Map<String, Object?>? rule, ResetMode? mode, String? lastResetKey}) =>
      _writer.run(
        (tx) => tx.update('checklists', id, {
          'reset_rule': rule,
          'reset_mode': rule == null ? null : (mode ?? ResetMode.completedToTodo).dbValue,
          'last_reset_key': rule == null ? null : lastResetKey,
        }),
      );

  Future<OpRecord> applyChange(TreeChange change) => _writer.run(
    (tx) => ChecklistItemsRepository.applyInTx(tx, change, cascades: _cascades),
    cause: change.cause,
    scheduledAt: change.scheduledAt,
  );

  /// Whether a run row already exists (resets are idempotent across devices).
  Future<bool> runExists(String runId) async =>
      await (_db.select(_db.checklistRuns)..where((r) => r.id.equals(runId))).getSingleOrNull() != null;

  Stream<List<ChecklistRun>> watchRuns(String checklistId) =>
      (_db.select(_db.checklistRuns)
            ..where((r) => r.deletedAt.isNull() & r.checklistId.equals(checklistId))
            ..orderBy([(r) => OrderingTerm.desc(r.endedAt)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                ChecklistRun(
                  id: r.id,
                  checklistId: r.checklistId,
                  occurrenceKey: r.occurrenceKey,
                  startedAt: r.startedAt,
                  endedAt: r.endedAt,
                  totalItems: r.totalItems,
                  completedItems: r.completedItems,
                  snapshot: [
                    if (r.snapshot != null)
                      for (final e in (jsonDecode(r.snapshot!) as List).whereType<Map<Object?, Object?>>())
                        RunSnapshotEntry.fromJson(Map<String, Object?>.from(e)),
                  ],
                ),
            ],
          );
}
