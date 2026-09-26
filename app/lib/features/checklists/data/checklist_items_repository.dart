import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/attachments/application/providers.dart'
    show Attachment, AttachmentOwnerType, AttachmentTx;
import 'package:everslot/features/checklists/data/checklist_cascades.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Item rows of checklists (T4.1.02/T4.1.04). [apply] is the ONLY write path for item changes
/// coming from the tree engine and the status service: one [TreeChange] = one Drift transaction =
/// one operation group (rows + outbox + activity events + attachment/tag cascades).
class ChecklistItemsRepository {
  ChecklistItemsRepository(this._db, this._writer, this._userId, {ChecklistCascades? cascades})
    : _cascades = cascades;

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;
  final ChecklistCascades? _cascades;

  static ChecklistItem map(ChecklistItemRow r) => ChecklistItem(
    id: r.id,
    checklistId: r.checklistId,
    parentId: r.parentId,
    sortKey: r.sortKey,
    text: r.itemText,
    note: r.note,
    status: ItemStatus.parse(r.status),
    statusNote: r.statusNote,
    statusChangedAt: r.statusChangedAt,
    completedAt: r.completedAt,
    followUpAt: r.followUpAt,
    dueLocal: r.dueLocal == null ? null : LocalDateTime.tryParse(r.dueLocal!),
    timeZone: r.timeZone,
    waitingOn: r.waitingOn,
    priority: r.priority,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  SimpleSelectStatement<$ChecklistItemsTable, ChecklistItemRow> _live(String checklistId) =>
      _db.select(_db.checklistItems)
        ..where((i) => i.deletedAt.isNull() & i.userId.equals(_userId()) & i.checklistId.equals(checklistId))
        ..orderBy([
          (i) => OrderingTerm.asc(i.parentId),
          (i) => OrderingTerm.asc(i.sortKey),
          (i) => OrderingTerm.asc(i.id),
        ]);

  /// All live rows of a checklist ordered by `parent_id, sort_key, id`.
  Stream<List<ChecklistItem>> watchItems(String checklistId) =>
      _live(checklistId).watch().map((rows) => rows.map(map).toList(growable: false));

  Future<List<ChecklistItem>> items(String checklistId) async =>
      (await _live(checklistId).get()).map(map).toList(growable: false);

  Future<ChecklistItem?> byId(String id) async {
    final r = await (_db.select(_db.checklistItems)..where((i) => i.id.equals(id))).getSingleOrNull();
    return r == null ? null : map(r);
  }

  /// Ids of an item and all its live descendants (WITH RECURSIVE, depth-bounded).
  Future<List<String>> subtreeIds(String itemId) async {
    final rows = await _db
        .customSelect(
          'WITH RECURSIVE sub(id, depth) AS ('
          ' SELECT id, 0 FROM checklist_items WHERE id = ? AND deleted_at IS NULL'
          ' UNION ALL'
          ' SELECT c.id, sub.depth + 1 FROM checklist_items c JOIN sub ON c.parent_id = sub.id'
          ' WHERE c.deleted_at IS NULL AND sub.depth < 10000'
          ') SELECT id FROM sub',
          variables: [Variable<String>(itemId)],
          readsFrom: {_db.checklistItems},
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }

  /// Item ids of a checklist that own at least one live attachment.
  Stream<Map<String, int>> watchAttachmentCounts(String checklistId) => _db
      .customSelect(
        'SELECT a.owner_id AS id, COUNT(*) AS n FROM attachments a '
        'JOIN checklist_items i ON i.id = a.owner_id '
        "WHERE a.owner_type = 'checklist_item' AND a.deleted_at IS NULL AND i.checklist_id = ? "
        'AND i.deleted_at IS NULL GROUP BY a.owner_id',
        variables: [Variable<String>(checklistId)],
        readsFrom: {_db.attachments, _db.checklistItems},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('id'): r.read<int>('n')});

  /// Every live attachment of a checklist: checklist-level ones and those of its live items
  /// (attachments gallery T4.4.07, gallery view T4.5.04).
  Stream<List<Attachment>> watchChecklistAttachments(String checklistId) => _db
      .customSelect(
        'SELECT a.* FROM attachments a WHERE a.deleted_at IS NULL AND ('
        "(a.owner_type = 'checklist' AND a.owner_id = ?1) OR "
        "(a.owner_type = 'checklist_item' AND a.owner_id IN "
        '(SELECT id FROM checklist_items WHERE checklist_id = ?1 AND deleted_at IS NULL))) '
        'ORDER BY a.owner_type, a.owner_id, a.sort_key, a.id',
        variables: [Variable<String>(checklistId)],
        readsFrom: {_db.attachments, _db.checklistItems},
      )
      .watch()
      .map((rows) => [for (final r in rows) _db.attachments.map(r.data)].map(AttachmentTx.fromRow).toList());

  /// Live attachments of a checklist and of its live items (empty-card detection).
  Future<int> attachmentCount(String checklistId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM attachments a WHERE a.deleted_at IS NULL AND ('
          "(a.owner_type = 'checklist' AND a.owner_id = ?1) OR "
          "(a.owner_type = 'checklist_item' AND a.owner_id IN "
          '(SELECT id FROM checklist_items WHERE checklist_id = ?1 AND deleted_at IS NULL)))',
          variables: [Variable<String>(checklistId)],
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Attachment file names per item (listed in Markdown exports, T4.4.08).
  Future<Map<String, List<String>>> attachmentNames(String checklistId) async {
    final rows = await _db
        .customSelect(
          'SELECT a.owner_id AS id, a.file_name AS name FROM attachments a JOIN checklist_items i ON i.id = a.owner_id '
          "WHERE a.owner_type = 'checklist_item' AND a.deleted_at IS NULL AND i.checklist_id = ? AND i.deleted_at IS NULL "
          'ORDER BY a.sort_key, a.id',
          variables: [Variable<String>(checklistId)],
        )
        .get();
    final out = <String, List<String>>{};
    for (final r in rows) {
      (out[r.read<String>('id')] ??= []).add(r.read<String>('name'));
    }
    return out;
  }

  static StatusEvent? _statusEvent(ActivityEventRow r) {
    Map<String, Object?> p;
    try {
      p = Map<String, Object?>.from(jsonDecode(r.payload) as Map);
    } on Object {
      return null;
    }
    final to = p['to'] as String? ?? p['status'] as String?;
    if (to == null) return null;
    return StatusEvent(
      at: r.occurredAt,
      from: p['from'] == null ? null : ItemStatus.parse(p['from'] as String?),
      to: ItemStatus.parse(to),
      note: p['note'] as String?,
      cause: p['cause'] as String?,
      deviceId: r.originDeviceId,
      type: r.eventType,
      followUpAt: p['followUpAt'] is String ? DateTime.tryParse(p['followUpAt']! as String) : null,
    );
  }

  /// Status history of one item (T4.3.05), oldest first.
  Stream<List<StatusEvent>> watchStatusEvents(String itemId) => (_db.select(_db.activityEvents)
        ..where(
          (e) =>
              e.deletedAt.isNull() &
              e.entityType.equals('checklist_item') &
              e.entityId.equals(itemId) &
              e.eventType.isIn(const ['status_changed', 'status_note_changed']),
        )
        ..orderBy([(e) => OrderingTerm.asc(e.occurredAt), (e) => OrderingTerm.asc(e.id)]))
      .watch()
      .map((rows) => rows.map(_statusEvent).whereType<StatusEvent>().toList());

  /// Other activity of one item (edits, moves…) for the history timeline.
  Stream<List<ActivityEventRow>> watchItemEvents(String itemId) => (_db.select(_db.activityEvents)
        ..where((e) => e.deletedAt.isNull() & e.entityType.equals('checklist_item') & e.entityId.equals(itemId))
        ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
        ..limit(100))
      .watch();

  /// Last 20 status events for [status] across items (quick reason chips, T4.3.02).
  Future<List<StatusEvent>> recentStatusEvents(ItemStatus status) async {
    final rows = await (_db.select(_db.activityEvents)
          ..where(
            (e) =>
                e.deletedAt.isNull() &
                e.userId.equals(_userId()) &
                e.entityType.equals('checklist_item') &
                e.eventType.isIn(const ['status_changed', 'status_note_changed']),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
          ..limit(200))
        .get();
    return rows.map(_statusEvent).whereType<StatusEvent>().where((e) => e.to == status).take(20).toList();
  }

  /// Applies a pure change as ONE operation (T4.1.04).
  Future<OpRecord> apply(TreeChange change) => _writer.run(
    (tx) => applyInTx(tx, change, cascades: _cascades),
    cause: change.cause,
    scheduledAt: change.scheduledAt,
  );

  /// Same as [apply] inside an existing operation (checklist-level commands).
  static Future<void> applyInTx(WriteTx tx, TreeChange change, {ChecklistCascades? cascades}) async {
    for (final w in change.writes) {
      if (w.isInsert) {
        await tx.insert(w.table, w.id, w.values);
      } else if (await tx.exists(w.table, w.id)) {
        await tx.update(w.table, w.id, w.values);
      }
    }
    for (final r in change.reownedAttachments) {
      await AttachmentTx.reown(
        tx,
        fromType: AttachmentOwnerType.checklistItem,
        fromId: r.fromItemId,
        toType: AttachmentOwnerType.checklistItem,
        toId: r.toItemId,
      );
    }
    for (final e in change.promotedAttachments.entries) {
      await AttachmentTx.reown(
        tx,
        fromType: AttachmentOwnerType.checklistItem,
        fromId: e.key,
        toType: AttachmentOwnerType.checklist,
        toId: e.value,
      );
    }
    if (change.copiedItemIds.isNotEmpty) {
      await AttachmentTx.copyForOwners(tx, fromType: AttachmentOwnerType.checklistItem, ownerIdMap: change.copiedItemIds);
      await copyEntityTags(tx, 'checklist_item', change.copiedItemIds);
      await cascades?.itemsCopied(tx, change.copiedItemIds);
    }
    if (change.deletedItemIds.isNotEmpty) {
      await AttachmentTx.softDeleteForOwners(tx, AttachmentOwnerType.checklistItem, change.deletedItemIds);
      await deleteEntityTags(tx, 'checklist_item', change.deletedItemIds);
      await cascades?.itemsDeleted(tx, change.deletedItemIds);
    }
    for (final e in change.events) {
      await insertEvent(tx, e);
    }
  }

  /// Activity event with a per-event cause (cascades inside a user operation).
  static Future<void> insertEvent(WriteTx tx, EventSpec e) => tx.insert('activity_events', Ids.v7(), {
    'entity_type': e.entityType,
    'entity_id': e.entityId,
    'parent_id': e.parentId,
    'event_type': e.eventType,
    'payload': {...e.payload, 'opId': tx.opId, 'cause': e.cause ?? tx.cause},
    'occurred_at': tx.now,
  });

  static Future<List<Map<String, Object?>>> _tagRows(WriteTx tx, String entityType, Iterable<String> ids) async {
    final list = ids.toList();
    final out = <Map<String, Object?>>[];
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(i, i + 500 > list.length ? list.length : i + 500);
      final rows = await tx.db
          .customSelect(
            'SELECT id, tag_id, entity_id FROM entity_tags WHERE deleted_at IS NULL AND entity_type = ? '
            'AND entity_id IN (${List.filled(chunk.length, '?').join(', ')})',
            variables: [Variable<String>(entityType), for (final id in chunk) Variable<String>(id)],
          )
          .get();
      out.addAll(rows.map((r) => r.data));
    }
    return out;
  }

  static Future<void> copyEntityTags(WriteTx tx, String entityType, Map<String, String> idMap) async {
    for (final r in await _tagRows(tx, entityType, idMap.keys)) {
      final tagId = r['tag_id']! as String;
      final newEntity = idMap[r['entity_id']]!;
      await tx.upsert('entity_tags', Ids.entityTag(tagId, entityType, newEntity), {
        'tag_id': tagId,
        'entity_type': entityType,
        'entity_id': newEntity,
        'deleted_at': null,
      });
    }
  }

  static Future<void> deleteEntityTags(WriteTx tx, String entityType, Iterable<String> ids) async {
    for (final r in await _tagRows(tx, entityType, ids)) {
      await tx.softDelete('entity_tags', r['id']! as String);
    }
  }
}
