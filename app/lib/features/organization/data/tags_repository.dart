import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/organization/domain/tag.dart';

/// Tags & entity tags (T2.3.10). Reads Drift streams, writes through [SyncWriter].
///
/// Links use deterministic ids `Ids.entityTag(tagId, entityType, entityId)`, so tagging the same
/// entity on two offline devices converges to one row; un-tagging soft-deletes the link and
/// re-tagging restores it.
class TagsRepository {
  TagsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static Tag _map(TagRow r) =>
      Tag(id: r.id, name: r.name, color: r.color, sortKey: r.sortKey);

  SimpleSelectStatement<$TagsTable, TagRow> _liveTags() => _db.select(_db.tags)
    ..where((t) => t.deletedAt.isNull() & t.userId.equals(_userId()))
    ..orderBy([
      (t) => OrderingTerm.asc(t.sortKey),
      (t) => OrderingTerm.asc(t.id),
    ]);

  // ------------------------------------------------------------------------------- reads --

  Stream<List<Tag>> watchAll() =>
      _liveTags().watch().map((rows) => rows.map(_map).toList());

  Future<List<Tag>> all() async => (await _liveTags().get()).map(_map).toList();

  /// Case-insensitive lookup by name (query syntax `tag:work`, inline create).
  Future<Tag?> findByName(String name) async {
    final key = TagNames.key(name);
    for (final t in await all()) {
      if (TagNames.key(t.name) == key) return t;
    }
    return null;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _linkedTags({
    String? entityType,
    String? entityId,
  }) {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.entityTags, _db.entityTags.tagId.equalsExp(_db.tags.id)),
    ]);
    var where =
        _db.entityTags.deletedAt.isNull() &
        _db.tags.deletedAt.isNull() &
        _db.tags.userId.equals(_userId());
    if (entityType != null)
      where = where & _db.entityTags.entityType.equals(entityType);
    if (entityId != null)
      where = where & _db.entityTags.entityId.equals(entityId);
    query
      ..where(where)
      ..orderBy([
        OrderingTerm.asc(_db.tags.sortKey),
        OrderingTerm.asc(_db.tags.id),
      ]);
    return query;
  }

  /// Live tags of one entity, in tag order.
  Stream<List<Tag>> watchForEntity(String entityType, String entityId) =>
      _linkedTags(entityType: entityType, entityId: entityId).watch().map((
        rows,
      ) {
        final seen = <String>{};
        return [
          for (final r in rows)
            if (seen.add(r.readTable(_db.tags).id)) _map(r.readTable(_db.tags)),
        ];
      });

  Future<List<Tag>> tagsForEntity(String entityType, String entityId) =>
      watchForEntity(entityType, entityId).first;

  /// Tags of every entity of [entityType] (entity id → tags), for boards and lists.
  Stream<Map<String, List<Tag>>> watchByEntity(String entityType) =>
      _linkedTags(entityType: entityType).watch().map((rows) {
        final result = <String, List<Tag>>{};
        for (final r in rows) {
          final entityId = r.readTable(_db.entityTags).entityId;
          final tag = _map(r.readTable(_db.tags));
          final list = result.putIfAbsent(entityId, () => []);
          if (!list.any((t) => t.id == tag.id)) list.add(tag);
        }
        return result;
      });

  /// Ids of live entities carrying [tagId] (optionally of one type).
  Stream<Set<String>> watchEntityIds(String tagId, {String? entityType}) {
    final q = _db.select(_db.entityTags)
      ..where(
        (e) =>
            e.tagId.equals(tagId) &
            e.deletedAt.isNull() &
            (entityType == null
                ? const Constant(true)
                : e.entityType.equals(entityType)),
      );
    return q.watch().map((rows) => {for (final r in rows) r.entityId});
  }

  /// Number of live (non-deleted) entities per tag id.
  Stream<Map<String, int>> watchUsageCounts() => _db
      .customSelect(
        '''
SELECT et.tag_id AS tag_id, COUNT(*) AS c FROM entity_tags et
WHERE et.deleted_at IS NULL AND et.user_id = ?
  AND CASE et.entity_type
    WHEN 'task' THEN EXISTS (SELECT 1 FROM tasks x WHERE x.id = et.entity_id AND x.deleted_at IS NULL)
    WHEN 'checklist' THEN EXISTS (SELECT 1 FROM checklists x WHERE x.id = et.entity_id AND x.deleted_at IS NULL)
    WHEN 'checklist_item' THEN EXISTS (SELECT 1 FROM checklist_items x WHERE x.id = et.entity_id AND x.deleted_at IS NULL)
    WHEN 'habit' THEN EXISTS (SELECT 1 FROM habits x WHERE x.id = et.entity_id AND x.deleted_at IS NULL)
    ELSE 0 END
GROUP BY et.tag_id''',
        variables: [Variable<String>(_userId())],
        readsFrom: {
          _db.entityTags,
          _db.tasks,
          _db.checklists,
          _db.checklistItems,
          _db.habits,
        },
      )
      .watch()
      .map(
        (rows) => {
          for (final r in rows) r.read<String>('tag_id'): r.read<int>('c'),
        },
      );

  // ------------------------------------------------------------------------------ writes --

  /// Creates a tag at the end of the list. Throws [ValidationException] with
  /// [TagNames.errorInvalid] / [TagNames.errorDuplicate].
  Future<({String id, OpRecord record})> create({
    required String name,
    int? color,
  }) async {
    final normalized = _validName(name);
    final existing = await all();
    _ensureUnique(existing, normalized);
    final id = Ids.v7();
    final record = await _writer.run(
      (tx) => tx.insert('tags', id, {
        'name': normalized,
        'color': color,
        'sort_key': FractionalIndex.between(
          existing.isEmpty ? null : existing.last.sortKey,
          null,
        ),
      }),
    );
    return (id: id, record: record);
  }

  /// Renames and/or recolors a tag in one operation.
  Future<OpRecord> update(
    String id, {
    String? name,
    int? color,
    bool clearColor = false,
  }) async {
    String? normalized;
    if (name != null) {
      normalized = _validName(name);
      _ensureUnique(await all(), normalized, exceptId: id);
    }
    return _writer.run(
      (tx) => tx.update('tags', id, {
        'name': ?normalized,
        if (color != null || clearColor) 'color': clearColor ? null : color,
      }),
    );
  }

  /// Moves [id] between two neighbours (fractional order).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run(
        (tx) => tx.update('tags', id, {
          'sort_key': FractionalIndex.between(afterKey, beforeKey),
        }),
      );

  /// Deletes a tag and all of its links in one operation (undoable).
  Future<OpRecord> delete(String id) => _writer.run((tx) async {
    final links = await _liveLinks(tagId: id);
    for (final link in links) {
      await tx.softDelete('entity_tags', link.id);
    }
    await tx.softDelete('tags', id);
    await tx.logEvent(
      entityType: 'tag',
      entityId: id,
      eventType: 'deleted',
      payload: {'links': links.length},
    );
  });

  /// Moves every link of [sourceId] to [targetId] and deletes the source tag — one operation, so
  /// a single undo restores both tags and all links exactly.
  Future<OpRecord> merge({required String sourceId, required String targetId}) {
    if (sourceId == targetId) {
      throw const ValidationException(
        'Cannot merge a tag into itself',
        field: 'target',
      );
    }
    return _writer.run((tx) async {
      final target = await tx.readRaw('tags', targetId);
      if (target == null || target['deleted_at'] != null) {
        throw NotFoundException('tags/$targetId not found');
      }
      final links = await _liveLinks(tagId: sourceId);
      for (final link in links) {
        await _link(tx, targetId, link.entityType, link.entityId);
        await tx.softDelete('entity_tags', link.id);
      }
      await tx.softDelete('tags', sourceId);
      await tx.logEvent(
        entityType: 'tag',
        entityId: targetId,
        eventType: 'merged',
        payload: {'from': sourceId, 'links': links.length},
      );
    });
  }

  /// Tags one entity (idempotent).
  Future<OpRecord> attach(String tagId, String entityType, String entityId) =>
      _writer.run((tx) async {
        _checkType(entityType);
        if (await _link(tx, tagId, entityType, entityId)) {
          await _logTagsChanged(tx, entityType, entityId, added: [tagId]);
        }
      });

  /// Removes one tag from an entity (idempotent).
  Future<OpRecord> detach(String tagId, String entityType, String entityId) =>
      _writer.run((tx) async {
        final id = Ids.entityTag(tagId, entityType, entityId);
        final row = await tx.readRaw('entity_tags', id);
        if (row == null || row['deleted_at'] != null) return;
        await tx.softDelete('entity_tags', id);
        await _logTagsChanged(tx, entityType, entityId, removed: [tagId]);
      });

  /// Makes the tags of an entity exactly [tagIds] (one operation).
  Future<OpRecord> setTags(
    String entityType,
    String entityId,
    Set<String> tagIds,
  ) => _writer.run((tx) => writeTags(tx, entityType, entityId, tagIds));

  /// Same as [setTags] inside an operation another repository already runs (e.g. saving an
  /// editor: row + tags + activity event in one transaction).
  Future<void> writeTags(
    WriteTx tx,
    String entityType,
    String entityId,
    Set<String> tagIds,
  ) async {
    _checkType(entityType);
    final links = await _liveLinks(entityType: entityType, entityId: entityId);
    final live = {for (final l in links) l.tagId};
    final added = <String>[];
    final removed = <String>[];
    for (final tagId in tagIds) {
      if (live.contains(tagId)) continue;
      if (await _link(tx, tagId, entityType, entityId)) added.add(tagId);
    }
    for (final link in links) {
      if (tagIds.contains(link.tagId)) continue;
      await tx.softDelete('entity_tags', link.id);
      removed.add(link.tagId);
    }
    if (added.isNotEmpty || removed.isNotEmpty) {
      await _logTagsChanged(
        tx,
        entityType,
        entityId,
        added: added,
        removed: removed,
      );
    }
  }

  // ----------------------------------------------------------------------------- helpers --

  /// Creates or restores the deterministic link row. Returns false when it was already live.
  Future<bool> _link(
    WriteTx tx,
    String tagId,
    String entityType,
    String entityId,
  ) async {
    final id = Ids.entityTag(tagId, entityType, entityId);
    final existing = await tx.readRaw('entity_tags', id);
    if (existing == null) {
      await tx.insert('entity_tags', id, {
        'tag_id': tagId,
        'entity_type': entityType,
        'entity_id': entityId,
      });
      return true;
    }
    return tx.update('entity_tags', id, {'deleted_at': null});
  }

  Future<void> _logTagsChanged(
    WriteTx tx,
    String entityType,
    String entityId, {
    List<String> added = const [],
    List<String> removed = const [],
  }) => tx.logEvent(
    entityType: entityType,
    entityId: entityId,
    eventType: 'updated',
    payload: {
      'fields': const ['tags'],
      if (added.isNotEmpty) 'addedTags': added,
      if (removed.isNotEmpty) 'removedTags': removed,
    },
  );

  Future<List<({String id, String tagId, String entityType, String entityId})>>
  _liveLinks({String? tagId, String? entityType, String? entityId}) async {
    final q = _db.select(_db.entityTags)
      ..where((e) {
        Expression<bool> w = e.deletedAt.isNull() & e.userId.equals(_userId());
        if (tagId != null) w = w & e.tagId.equals(tagId);
        if (entityType != null) w = w & e.entityType.equals(entityType);
        if (entityId != null) w = w & e.entityId.equals(entityId);
        return w;
      })
      ..orderBy([(e) => OrderingTerm.asc(e.id)]);
    return [
      for (final r in await q.get())
        (
          id: r.id,
          tagId: r.tagId,
          entityType: r.entityType,
          entityId: r.entityId,
        ),
    ];
  }

  static String _validName(String name) {
    final normalized = TagNames.normalize(name);
    if (!TagNames.isValid(normalized)) {
      throw const ValidationException(TagNames.errorInvalid, field: 'name');
    }
    return normalized;
  }

  static void _ensureUnique(
    List<Tag> existing,
    String normalized, {
    String? exceptId,
  }) {
    final key = normalized.toLowerCase();
    if (existing.any((t) => t.id != exceptId && TagNames.key(t.name) == key)) {
      throw const ValidationException(TagNames.errorDuplicate, field: 'name');
    }
  }

  static void _checkType(String entityType) {
    if (!TaggableType.isValid(entityType)) {
      throw ArgumentError.value(entityType, 'entityType', 'not taggable');
    }
  }
}
