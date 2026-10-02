import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/checklists/data/checklist_items_repository.dart';
import 'package:everslot/features/checklists/data/checklists_repository.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/status_engine.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';

/// Builds a change from a fresh tree.
typedef ChangeBuilder = TreeChange Function(ChecklistTree tree, TreeOpContext ctx, Checklist checklist);

/// Application API for checklist item commands (T4.3.01 status service, T4.2 structure ops).
///
/// Every command reads the current rows, computes a pure [TreeChange] and applies it as ONE
/// operation. Commands of one checklist are serialized so consecutive keystrokes (Tab, Tab…)
/// always see the result of the previous one.
class ChecklistService {
  ChecklistService(this._checklists, this._items, this._clock);

  final ChecklistsRepository _checklists;
  final ChecklistItemsRepository _items;
  final Clock _clock;
  final Map<String, Future<void>> _locks = {};

  DateTime get now => _clock.nowUtc();

  Future<T> _serialized<T>(String checklistId, Future<T> Function() body) async {
    final previous = _locks[checklistId] ?? Future<void>.value();
    final result = previous.then((_) => body());
    _locks[checklistId] = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<({ChecklistTree tree, Checklist checklist})?> load(String checklistId) async {
    final c = await _checklists.byId(checklistId);
    if (c == null) return null;
    return (tree: ChecklistTree.build(await _items.items(checklistId)), checklist: c);
  }

  TreeOpContext context(Checklist c, {String cause = 'user'}) =>
      TreeOpContext(checklistId: c.id, now: now, newId: Ids.v7, settings: c.settings, cause: cause);

  /// Runs [build] on a fresh tree and applies the result. Returns null when nothing changed.
  Future<({OpRecord record, TreeChange change})?> run(
    String checklistId,
    ChangeBuilder build, {
    String cause = 'user',
  }) => _serialized(checklistId, () async {
    final loaded = await load(checklistId);
    if (loaded == null) return null;
    final change = build(loaded.tree, context(loaded.checklist, cause: cause), loaded.checklist);
    if (change.isEmpty) return null;
    return (record: await _items.apply(change), change: change);
  });

  /// The live original of a mirror row (T4.5.16), else null: commands on a mirror edit it.
  Future<ChecklistItem?> originalOf(String itemId) async {
    final of = (await _items.byId(itemId))?.mirrorOfId;
    return of == null ? null : _items.liveById(of);
  }

  /// Mirrors [itemId] (T4.5.16) into [targetChecklistId] under [parentId] (null = top). A mirror
  /// of a mirror mirrors the same original. Returns the new row id, or null when not allowed.
  Future<({OpRecord record, String id})?> createMirror(
    String itemId, {
    required String targetChecklistId,
    String? parentId,
  }) async {
    final source = await _items.liveById(itemId);
    if (source == null) return null;
    final original = source.isMirror ? await _items.liveById(source.mirrorOfId!) : source;
    if (original == null) return null;
    final result = await run(targetChecklistId, (tree, ctx, _) => TreeOps.appendMirror(tree, ctx, parentId, original));
    if (result == null) return null;
    return (record: result.record, id: result.change.writes.first.id);
  }

  /// Turns a mirror row into a plain item with its original's current content.
  Future<OpRecord?> unlinkMirror(String checklistId, String itemId) async {
    final original = await originalOf(itemId);
    return (await run(checklistId, (tree, ctx, _) => TreeOps.unlinkMirror(tree, ctx, itemId, original)))?.record;
  }

  /// Status transition from any entry point (tap, sheet, swipe, kanban, smart views, bulk…).
  /// Mirror rows change their original, in its own list (one undo step for the whole command).
  Future<OpRecord?> changeStatus(
    String checklistId,
    Iterable<String> ids,
    ItemStatus to, {
    String? note,
    bool setNote = true,
    DateTime? followUpAt,
    bool keepFollowUp = false,
    bool? completeOpenDescendants,
    String cause = 'user',
  }) async {
    final targets = <String, List<String>>{checklistId: []};
    for (final id in ids) {
      final original = await originalOf(id);
      if (original == null) {
        targets[checklistId]!.add(id);
      } else {
        (targets[original.checklistId] ??= []).add(original.id);
      }
    }
    final records = <OpRecord>[];
    for (final e in targets.entries) {
      if (e.value.isEmpty) continue;
      final result = await run(
        e.key,
        (tree, ctx, c) => StatusEngine.apply(
          tree,
          c.settings,
          ids: e.value,
          to: to,
          now: ctx.now,
          note: note,
          setNote: setNote,
          followUpAt: followUpAt,
          keepFollowUp: keepFollowUp,
          completeOpenDescendants: completeOpenDescendants,
          cause: cause,
        ),
        cause: cause,
      );
      if (result != null) records.add(result.record);
    }
    if (records.isEmpty) return null;
    return records.length == 1 ? records.single : mergeRecords(records);
  }

  Future<int> openDescendantCount(String checklistId, String itemId) async {
    final original = await originalOf(itemId);
    if (original != null) return openDescendantCount(original.checklistId, original.id);
    final loaded = await load(checklistId);
    if (loaded == null || !loaded.tree.contains(itemId)) return 0;
    return StatusEngine.openDescendantCount(loaded.tree, itemId);
  }

  /// Discards a card created from the board that is still completely empty (no title, body,
  /// item text or attachments) when its screen closes (T4.1.09). Returns true when deleted.
  Future<bool> discardIfEmpty(String checklistId) => _serialized(checklistId, () async {
    final c = await _checklists.byId(checklistId);
    if (c == null || c.isDeleted || c.title.trim().isNotEmpty || c.hasBody || c.isTemplate) return false;
    final items = await _items.items(checklistId);
    if (items.any((i) => i.text.trim().isNotEmpty || i.hasNote)) return false;
    if (await _items.attachmentCount(checklistId) > 0) return false;
    await _checklists.delete(checklistId);
    return true;
  });

  /// Plain field edits (note, due, priority, follow-up…).
  /// Mirror rows edit their original.
  Future<OpRecord?> setFields(String checklistId, String itemId, Map<String, Object?> fields) async {
    final original = await originalOf(itemId);
    if (original != null) return setFields(original.checklistId, original.id, fields);
    return (await run(checklistId, (tree, ctx, _) => TreeOps.setFields(tree, ctx, itemId, fields)))?.record;
  }

  /// Appends top-level items to [checklistId] (quick add, share into Everslot — T8.1.10 / T8.2.07),
  /// one operation. Blank lines are ignored.
  Future<OpRecord?> appendItems(String checklistId, Iterable<String> texts, {String cause = 'user'}) async {
    final nodes = [
      for (final t in texts)
        if (t.trim().isNotEmpty) NodeSpec(text: t.trim()),
    ];
    if (nodes.isEmpty) return null;
    return (await run(checklistId, (tree, ctx, _) => TreeOps.insertNodes(tree, ctx, nodes), cause: cause))?.record;
  }

  /// Text of one row (editing sessions log one `updated` event: pass [logEvent] on the first write).
  /// Mirror rows edit their original's text.
  Future<OpRecord?> setText(String checklistId, String itemId, String text, {required bool logEvent}) async {
    final original = await originalOf(itemId);
    if (original != null) return setText(original.checklistId, original.id, text, logEvent: logEvent);
    return _setText(checklistId, itemId, text, logEvent: logEvent);
  }

  Future<OpRecord?> _setText(String checklistId, String itemId, String text, {required bool logEvent}) =>
      _serialized(checklistId, () async {
        final item = await _items.byId(itemId);
        final value = ItemText(text).value;
        if (item == null || item.text == value) return null;
        return _items.apply(
          TreeChange(
            writes: [
              RowWrite.update('checklist_items', itemId, {'text': value}),
            ],
            events: [
              if (logEvent)
                EventSpec(
                  entityType: 'checklist_item',
                  entityId: itemId,
                  parentId: checklistId,
                  eventType: 'updated',
                  payload: const {
                    'fields': ['text'],
                  },
                ),
            ],
          ),
        );
      });
}

/// Merges successive records of one editing session into a single undo step (earliest `before`
/// per column wins).
OpRecord mergeRecords(List<OpRecord> records) {
  final changes = <String, RowChange>{};
  for (final r in records) {
    for (final c in r.changes) {
      final key = '${c.table}|${c.id}';
      final existing = changes[key];
      if (existing == null) {
        changes[key] = c;
      } else if (existing.kind == RowChangeKind.insert) {
        changes[key] = RowChange(
          table: c.table,
          id: c.id,
          kind: RowChangeKind.insert,
          before: null,
          after: {...existing.after, ...c.after},
        );
      } else {
        changes[key] = RowChange(
          table: c.table,
          id: c.id,
          kind: RowChangeKind.update,
          before: {...?c.before, ...?existing.before},
          after: {...existing.after, ...c.after},
        );
      }
    }
  }
  return OpRecord(opId: records.first.opId, changes: changes.values.toList(), cause: records.first.cause);
}
