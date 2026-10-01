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

  /// Status transition from any entry point (tap, sheet, swipe, kanban, smart views, bulk…).
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
  }) async => (await run(
    checklistId,
    (tree, ctx, c) => StatusEngine.apply(
      tree,
      c.settings,
      ids: ids,
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
  ))?.record;

  Future<int> openDescendantCount(String checklistId, String itemId) async {
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
  Future<OpRecord?> setFields(String checklistId, String itemId, Map<String, Object?> fields) async =>
      (await run(checklistId, (tree, ctx, _) => TreeOps.setFields(tree, ctx, itemId, fields)))?.record;

  /// Text of one row (editing sessions log one `updated` event: pass [logEvent] on the first write).
  Future<OpRecord?> setText(String checklistId, String itemId, String text, {required bool logEvent}) =>
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
