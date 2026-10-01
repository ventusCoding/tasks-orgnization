import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/status_engine.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Inputs every pure operation needs (no clocks or id generators inside the domain).
class TreeOpContext {
  TreeOpContext({
    required this.checklistId,
    required this.now,
    required this.newId,
    this.settings = ChecklistSettings.defaults,
    this.cause = 'user',
  });

  final String checklistId;
  final DateTime now;
  final String Function() newId;
  final ChecklistSettings settings;
  final String cause;

  TreeChangeBuilder builder() => TreeChangeBuilder(cause: cause);
}

/// A node to insert (import, paste, templates, duplicates across lists).
@immutable
class NodeSpec {
  const NodeSpec({
    required this.text,
    this.note,
    this.status = ItemStatus.todo,
    this.statusNote,
    this.priority = 0,
    this.dueLocal,
    this.sourceItemId,
    this.children = const [],
  });

  final String text;
  final String? note;
  final ItemStatus status;
  final String? statusNote;
  final int priority;
  final LocalDateTime? dueLocal;

  /// When set, the source item's attachment rows are copied by reference.
  final String? sourceItemId;
  final List<NodeSpec> children;

  /// Number of nodes in this subtree (including itself).
  int get size {
    var n = 0;
    final stack = <NodeSpec>[this];
    while (stack.isNotEmpty) {
      final s = stack.removeLast();
      n++;
      stack.addAll(s.children);
    }
    return n;
  }

  NodeSpec withChildren(List<NodeSpec> kids) => NodeSpec(
    text: text,
    note: note,
    status: status,
    statusNote: statusNote,
    priority: priority,
    dueLocal: dueLocal,
    sourceItemId: sourceItemId,
    children: kids,
  );

  /// Structure of a subtree of [tree] (internal clipboard, templates, move across lists).
  static NodeSpec fromTree(ChecklistTree tree, String id, {bool keepStatus = true, bool withSource = true}) {
    NodeSpec build(String nodeId) {
      final i = tree[nodeId]!;
      return NodeSpec(
        text: i.text,
        note: i.note,
        status: keepStatus ? i.status : ItemStatus.todo,
        statusNote: keepStatus ? i.statusNote : null,
        priority: i.priority,
        dueLocal: i.dueLocal,
        sourceItemId: withSource ? nodeId : null,
        children: [for (final c in tree.childIds(nodeId)) build(c)],
      );
    }

    return build(id);
  }
}

/// Sort criteria for [TreeOps.sortChildren] and the view-level sort (T4.2.04 / T4.5.11).
enum ItemSortBy { manual, alphabetical, status, due, priority, recent }

/// Pure structural operations (T4.2.02–T4.2.04): `(tree, args) → TreeChange`.
///
/// New keys are generated between neighbours; other siblings are never renumbered (except by
/// [sortChildren], which rewrites exactly one sibling group).
abstract final class TreeOps {
  // ---------------------------------------------------------------- helpers

  static Map<String, Object?> newItemValues(
    TreeOpContext ctx, {
    required String? parentId,
    required String sortKey,
    String text = '',
    String? note,
    ItemStatus? status,
    String? statusNote,
    int priority = 0,
    LocalDateTime? dueLocal,
    String? checklistId,
  }) {
    final s = status ?? ctx.settings.defaultNewItemStatus;
    return {
      'checklist_id': checklistId ?? ctx.checklistId,
      'parent_id': parentId,
      'sort_key': sortKey,
      'text': ItemText(text).value,
      'note': ItemText.note(note),
      'status': s.name,
      'status_note': StatusEngine.normalizeNote(statusNote),
      'status_changed_at': s == ItemStatus.todo ? null : ctx.now,
      'completed_at': s == ItemStatus.completed ? ctx.now : null,
      'priority': priority,
      'due_local': dueLocal,
    };
  }

  static String? _keyOf(ChecklistTree tree, String? id) => id == null ? null : tree[id]?.sortKey;

  static List<String> _siblingsExcluding(ChecklistTree tree, String? parentId, Set<String> exclude) =>
      tree.childIds(parentId).where((s) => !exclude.contains(s)).toList();

  /// Keys for [n] rows placed right after [afterId] (null = first) among [parentId]'s children.
  static List<String> _keysAfter(
    ChecklistTree tree,
    String? parentId,
    String? afterId,
    int n, {
    Set<String> exclude = const {},
  }) {
    final siblings = _siblingsExcluding(tree, parentId, exclude);
    if (afterId == null) return SortKeys.nBetween(null, siblings.isEmpty ? null : _keyOf(tree, siblings.first), n);
    final i = siblings.indexOf(afterId);
    final next = i >= 0 && i + 1 < siblings.length ? siblings[i + 1] : null;
    return SortKeys.nBetween(_keyOf(tree, afterId), _keyOf(tree, next), n);
  }

  static List<String> _keysAtEnd(ChecklistTree tree, String? parentId, int n, {Set<String> exclude = const {}}) {
    final siblings = _siblingsExcluding(tree, parentId, exclude);
    return SortKeys.nBetween(siblings.isEmpty ? null : _keyOf(tree, siblings.last), null, n);
  }

  static EventSpec _event(TreeOpContext ctx, String id, String type, [Map<String, Object?> payload = const {}]) =>
      EventSpec(
        entityType: 'checklist_item',
        entityId: id,
        parentId: ctx.checklistId,
        eventType: type,
        payload: payload,
      );

  /// Groups a DFS-ordered id list into runs of adjacent siblings.
  static List<List<String>> _runs(ChecklistTree tree, List<String> tops) {
    final runs = <List<String>>[];
    for (final id in tops) {
      if (runs.isNotEmpty) {
        final last = runs.last.last;
        if (tree.parentOf(last) == tree.parentOf(id) && tree.nextSibling(last) == id) {
          runs.last.add(id);
          continue;
        }
      }
      runs.add([id]);
    }
    return runs;
  }

  static TreeChange _insertNew(
    ChecklistTree tree,
    TreeOpContext ctx, {
    required String? parentId,
    required String sortKey,
    String text = '',
  }) {
    final b = ctx.builder();
    final id = ctx.newId();
    b
      ..insert(id, newItemValues(ctx, parentId: parentId, sortKey: sortKey, text: text))
      ..event(_event(ctx, id, 'created'))
      ..focus = FocusHint(id, cursor: 0);
    StatusEngine.reopenForNewChild(tree, ctx.settings, parentId, now: ctx.now, into: b);
    return b.build();
  }

  // ---------------------------------------------------------------- inserts

  /// A live mirror of [original] (T4.5.16) appended under [parentId]: its own text/status are a
  /// snapshot of the original (shown only once the original is gone). Empty when [parentId] is a
  /// mirror or lies inside the original's subtree.
  static TreeChange appendMirror(ChecklistTree tree, TreeOpContext ctx, String? parentId, ChecklistItem original) {
    if (parentId != null) {
      final parent = tree[parentId];
      if (parent == null || parent.isMirror) return TreeChange.none;
      if (parentId == original.id || tree.ancestors(parentId).contains(original.id)) return TreeChange.none;
    }
    final b = ctx.builder();
    final id = ctx.newId();
    b
      ..insert(id, {
        ...newItemValues(
          ctx,
          parentId: parentId,
          sortKey: _keysAtEnd(tree, parentId, 1).single,
          text: original.text,
          status: original.status,
          statusNote: original.statusNote,
        ),
        'mirror_of_id': original.id,
      })
      ..event(_event(ctx, id, 'created', {'mirrorOf': original.id}));
    return b.build();
  }

  /// Turns mirror [id] into an ordinary item holding [original]'s current content (T4.5.16).
  static TreeChange unlinkMirror(ChecklistTree tree, TreeOpContext ctx, String id, ChecklistItem? original) {
    final item = tree[id];
    if (item == null || !item.isMirror) return TreeChange.none;
    final b = ctx.builder()
      ..update(id, {
        'mirror_of_id': null,
        if (original != null) ...{
          'text': original.text,
          'note': original.note,
          'status': original.status.name,
          'status_note': original.statusNote,
          'status_changed_at': original.statusChangedAt,
          'completed_at': original.completedAt,
          'priority': original.priority,
          'due_local': original.dueLocal,
          'time_zone': original.timeZone,
        },
      });
    return b.build();
  }

  static TreeChange insertAfter(ChecklistTree tree, TreeOpContext ctx, String anchorId, {String text = ''}) {
    final parent = tree.parentOf(anchorId);
    return _insertNew(tree, ctx, parentId: parent, sortKey: _keysAfter(tree, parent, anchorId, 1).single, text: text);
  }

  static TreeChange insertBefore(ChecklistTree tree, TreeOpContext ctx, String anchorId, {String text = ''}) {
    final parent = tree.parentOf(anchorId);
    final prev = tree.previousSibling(anchorId);
    return _insertNew(
      tree,
      ctx,
      parentId: parent,
      sortKey: SortKeys.between(_keyOf(tree, prev), tree[anchorId]!.sortKey),
      text: text,
    );
  }

  static TreeChange insertFirstChild(ChecklistTree tree, TreeOpContext ctx, String? parentId, {String text = ''}) =>
      _insertNew(tree, ctx, parentId: parentId, sortKey: _keysAfter(tree, parentId, null, 1).single, text: text);

  /// Appends a row at the end of [parentId]'s children (the "Add item" row; null = top level).
  static TreeChange appendChild(ChecklistTree tree, TreeOpContext ctx, String? parentId, {String text = ''}) =>
      _insertNew(tree, ctx, parentId: parentId, sortKey: _keysAtEnd(tree, parentId, 1).single, text: text);

  /// Enter (T4.2.02): splits at [cursor]; the new row is the first child when the row is expanded
  /// with children, otherwise the next sibling. At offset 0 of a non-empty row an empty row is
  /// inserted above and the caret stays.
  static TreeChange enter(
    ChecklistTree tree,
    TreeOpContext ctx,
    String id, {
    required String text,
    required int cursor,
    required bool expanded,
  }) {
    final c = cursor.clamp(0, text.length);
    if (c == 0 && text.isNotEmpty) {
      return insertBefore(tree, ctx, id).copyWith(focus: FocusHint(id, cursor: 0));
    }
    final before = text.substring(0, c);
    final after = text.substring(c);
    final TreeChange inserted;
    if (tree.hasChildren(id) && expanded) {
      inserted = insertFirstChild(tree, ctx, id, text: after);
    } else {
      inserted = insertAfter(tree, ctx, id, text: after);
    }
    final b = ctx.builder();
    final stored = ItemText(before).value;
    if (stored != tree[id]!.text) b.update(id, {'text': stored});
    return b.build().merge(inserted);
  }

  /// Backspace at the start of a row (T4.2.09): deletes an empty childless row, otherwise merges
  /// it into [previousVisibleId] (text appended, children re-parented, attachments re-owned).
  /// Never crosses the focus root.
  static TreeChange backspaceAtStart(
    ChecklistTree tree,
    TreeOpContext ctx,
    String id, {
    required String text,
    required String? previousVisibleId,
    String? focusRootId,
  }) {
    final target = previousVisibleId;
    if (target == null || target == focusRootId || !tree.contains(target)) return TreeChange.none;
    if (text.isEmpty && !tree.hasChildren(id)) {
      return deleteSubtrees(tree, ctx, [id]).copyWith(focus: FocusHint(target));
    }
    final b = ctx.builder();
    final targetText = tree[target]!.text;
    b.update(target, {'text': ItemText(targetText + text).value});
    final kids = tree.childIds(id);
    if (kids.isNotEmpty) {
      final List<String> keys;
      if (tree.parentOf(id) == target) {
        keys = SortKeys.nBetween(
          _keyOf(tree, tree.previousSibling(id)),
          _keyOf(tree, tree.nextSibling(id)),
          kids.length,
        );
      } else {
        keys = _keysAtEnd(tree, target, kids.length);
      }
      for (var i = 0; i < kids.length; i++) {
        b.update(kids[i], {'parent_id': target, 'sort_key': keys[i]});
      }
    }
    b
      ..reownedAttachments.add((fromItemId: id, toItemId: target))
      ..update(id, {'deleted_at': ctx.now})
      ..deletedItemIds.add(id)
      ..event(
        _event(ctx, target, 'updated', {
          'fields': ['text'],
          'mergedFrom': id,
        }),
      )
      ..event(_event(ctx, id, 'deleted', {'mergedInto': target}))
      ..focus = FocusHint(target, cursor: targetText.length);
    return b.build();
  }

  // ---------------------------------------------------------------- structure

  /// Indent: each run of adjacent selected siblings becomes the last children of the previous
  /// sibling of the run. No previous sibling → nothing (caller plays a "denied" haptic).
  static TreeChange indent(ChecklistTree tree, TreeOpContext ctx, Iterable<String> ids) {
    final tops = tree.topMost(ids);
    final b = ctx.builder();
    var moved = false;
    for (final run in _runs(tree, tops)) {
      final prev = tree.previousSibling(run.first);
      if (prev == null) continue;
      final keys = _keysAtEnd(tree, prev, run.length);
      for (var i = 0; i < run.length; i++) {
        b
          ..update(run[i], {'parent_id': prev, 'sort_key': keys[i]})
          ..event(_event(ctx, run[i], 'moved', {'fromParentId': tree.parentOf(run[i]), 'toParentId': prev}));
      }
      moved = true;
      if (run.any((r) => tree[r]!.status.isOpen)) {
        StatusEngine.reopenForNewChild(tree, ctx.settings, prev, now: ctx.now, into: b);
      }
    }
    if (!moved) return TreeChange.none;
    b.focus = FocusHint(tops.first);
    return b.build();
  }

  /// Outdent (Workflowy semantics): rows become the next siblings of their parent; following
  /// siblings stay under the old parent. No-op at root level or directly under the focus root.
  static TreeChange outdent(ChecklistTree tree, TreeOpContext ctx, Iterable<String> ids, {String? focusRootId}) {
    final tops = tree.topMost(ids);
    final byParent = <String, List<String>>{};
    for (final id in tops) {
      final p = tree.parentOf(id);
      if (p == null || p == focusRootId) continue;
      (byParent[p] ??= []).add(id);
    }
    if (byParent.isEmpty) return TreeChange.none;
    final b = ctx.builder();
    for (final e in byParent.entries) {
      final p = e.key;
      final grand = tree.parentOf(p);
      final keys = SortKeys.nBetween(tree[p]!.sortKey, _keyOf(tree, tree.nextSibling(p)), e.value.length);
      for (var i = 0; i < e.value.length; i++) {
        b
          ..update(e.value[i], {'parent_id': grand, 'sort_key': keys[i]})
          ..event(_event(ctx, e.value[i], 'moved', {'fromParentId': p, 'toParentId': grand}));
      }
    }
    b.focus = FocusHint(tops.first);
    return b.build();
  }

  /// Moves a run of adjacent siblings one position up.
  static TreeChange moveUp(ChecklistTree tree, TreeOpContext ctx, Iterable<String> ids) {
    final tops = tree.topMost(ids);
    if (tops.isEmpty) return TreeChange.none;
    final run = _runs(tree, tops).first;
    final prev = tree.previousSibling(run.first);
    if (prev == null) return TreeChange.none;
    final keys = SortKeys.nBetween(_keyOf(tree, tree.previousSibling(prev)), tree[prev]!.sortKey, run.length);
    final b = ctx.builder();
    for (var i = 0; i < run.length; i++) {
      b.update(run[i], {'sort_key': keys[i]});
    }
    b.focus = FocusHint(run.first);
    return b.build();
  }

  /// Moves a run of adjacent siblings one position down.
  static TreeChange moveDown(ChecklistTree tree, TreeOpContext ctx, Iterable<String> ids) {
    final tops = tree.topMost(ids);
    if (tops.isEmpty) return TreeChange.none;
    final run = _runs(tree, tops).first;
    final next = tree.nextSibling(run.last);
    if (next == null) return TreeChange.none;
    final keys = SortKeys.nBetween(tree[next]!.sortKey, _keyOf(tree, tree.nextSibling(next)), run.length);
    final b = ctx.builder();
    for (var i = 0; i < run.length; i++) {
      b.update(run[i], {'sort_key': keys[i]});
    }
    b.focus = FocusHint(run.first);
    return b.build();
  }

  /// Whether [ids] may move under [newParentId] (cycle-safe check).
  static bool canMoveUnder(ChecklistTree tree, Iterable<String> ids, String? newParentId) {
    if (newParentId == null) return true;
    if (!tree.contains(newParentId)) return false;
    for (final id in ids) {
      if (id == newParentId || tree.isDescendant(newParentId, id)) return false;
    }
    return true;
  }

  /// Moves subtrees under [newParentId], right after sibling [afterId] (null = first).
  /// Returns [TreeChange.none] when the target is inside a moved subtree.
  static TreeChange moveTo(
    ChecklistTree tree,
    TreeOpContext ctx,
    Iterable<String> ids, {
    required String? newParentId,
    String? afterId,
  }) {
    final tops = tree.topMost(ids);
    if (tops.isEmpty || !canMoveUnder(tree, tops, newParentId)) return TreeChange.none;
    final exclude = tops.toSet();
    final anchor = afterId != null && exclude.contains(afterId) ? null : afterId;
    final keys = _keysAfter(tree, newParentId, anchor, tops.length, exclude: exclude);
    final b = ctx.builder();
    var any = false;
    for (var i = 0; i < tops.length; i++) {
      final id = tops[i];
      final from = tree.parentOf(id);
      final changes = <String, Object?>{'sort_key': keys[i]};
      if (from != newParentId || tree[id]!.parentId != newParentId) changes['parent_id'] = newParentId;
      b.update(id, changes);
      any = true;
      if (from != newParentId) {
        b.event(_event(ctx, id, 'moved', {'fromParentId': from, 'toParentId': newParentId}));
      }
    }
    if (!any) return TreeChange.none;
    if (tops.any((t) => tree[t]!.status.isOpen)) {
      StatusEngine.reopenForNewChild(tree, ctx.settings, newParentId, now: ctx.now, into: b);
    }
    b.focus = FocusHint(tops.first);
    return b.build();
  }

  // ---------------------------------------------------------------- subtrees

  /// Tombstones subtrees (items + their attachments and tags, T4.2.03) under one op group.
  static TreeChange deleteSubtrees(ChecklistTree tree, TreeOpContext ctx, Iterable<String> ids) {
    final tops = tree.topMost(ids);
    if (tops.isEmpty) return TreeChange.none;
    final b = ctx.builder();
    for (final top in tops) {
      final all = [top, ...tree.descendants(top)];
      for (final id in all) {
        b.update(id, {'deleted_at': ctx.now});
        b.deletedItemIds.add(id);
      }
      b.event(_event(ctx, top, 'deleted', {'count': all.length}));
    }
    return b.build();
  }

  /// Deep copies with fresh ids, inserted right after each original (T4.2.03).
  static TreeChange duplicateSubtrees(
    ChecklistTree tree,
    TreeOpContext ctx,
    Iterable<String> ids, {
    bool resetStatuses = false,
  }) {
    final tops = tree.topMost(ids);
    if (tops.isEmpty) return TreeChange.none;
    final b = ctx.builder();
    String? firstCopy;
    for (final top in tops) {
      final map = <String, String>{};
      final parent = tree.parentOf(top);
      final rootKey = SortKeys.between(tree[top]!.sortKey, _keyOf(tree, tree.nextSibling(top)));
      for (final id in [top, ...tree.descendants(top)]) {
        final src = tree[id]!;
        final copyId = ctx.newId();
        map[id] = copyId;
        final keep = !resetStatuses;
        b.insert(copyId, {
          'checklist_id': ctx.checklistId,
          'parent_id': id == top ? parent : map[tree.parentOf(id)],
          'sort_key': id == top ? rootKey : src.sortKey,
          'text': src.text,
          'note': src.note,
          'status': keep ? src.status.name : ItemStatus.todo.name,
          'status_note': keep ? src.statusNote : null,
          'status_changed_at': keep ? src.statusChangedAt : null,
          'completed_at': keep ? src.completedAt : null,
          'follow_up_at': keep ? src.followUpAt : null,
          'priority': src.priority,
          'estimate_minutes': src.estimateMinutes,
          'mirror_of_id': src.mirrorOfId,
          'due_local': src.dueLocal,
          'time_zone': src.timeZone,
          'waiting_on': keep ? src.waitingOn : null,
        });
      }
      b
        ..copiedItemIds.addAll(map)
        ..event(_event(ctx, map[top]!, 'created', {'duplicatedFrom': top, 'count': map.length}));
      firstCopy ??= map[top];
    }
    b.focus = FocusHint(firstCopy!);
    return b.build();
  }

  /// Inserts node specs (import, paste, templates) under [parentId] after [afterId]
  /// (null = at the end when [atEnd], else first). One op group.
  static TreeChange insertNodes(
    ChecklistTree tree,
    TreeOpContext ctx,
    List<NodeSpec> nodes, {
    String? parentId,
    String? afterId,
    bool atEnd = true,
    String? checklistId,
  }) {
    if (nodes.isEmpty) return TreeChange.none;
    final b = ctx.builder();
    final topKeys = afterId == null && atEnd
        ? _keysAtEnd(tree, parentId, nodes.length)
        : _keysAfter(tree, parentId, afterId, nodes.length);
    final stack = <(NodeSpec, String?, String)>[];
    for (var i = nodes.length - 1; i >= 0; i--) {
      stack.add((nodes[i], parentId, topKeys[i]));
    }
    String? first;
    while (stack.isNotEmpty) {
      final (node, parent, key) = stack.removeLast();
      final id = ctx.newId();
      first ??= id;
      b.insert(
        id,
        newItemValues(
          ctx,
          parentId: parent,
          sortKey: key,
          text: node.text,
          note: node.note,
          status: node.status,
          statusNote: node.statusNote,
          priority: node.priority,
          dueLocal: node.dueLocal,
          checklistId: checklistId,
        ),
      );
      if (node.sourceItemId != null) b.copiedItemIds[node.sourceItemId!] = id;
      final keys = SortKeys.spread(node.children.length);
      for (var i = node.children.length - 1; i >= 0; i--) {
        stack.add((node.children[i], id, keys[i]));
      }
    }
    final total = nodes.fold<int>(0, (a, n) => a + n.size);
    b.event(
      EventSpec(
        entityType: 'checklist',
        entityId: checklistId ?? ctx.checklistId,
        eventType: 'items_added',
        payload: {'count': total},
      ),
    );
    if (nodes.any((n) => n.status.isOpen)) {
      StatusEngine.reopenForNewChild(tree, ctx.settings, parentId, now: ctx.now, into: b);
    }
    b.focus = FocusHint(first!);
    return b.build();
  }

  /// Moves subtrees to another checklist (T4.1.15): `checklist_id` on every descendant,
  /// `parent_id` / `sort_key` on the roots, `moved` events with from/to checklist.
  static TreeChange moveToChecklist(
    ChecklistTree tree,
    TreeOpContext ctx,
    Iterable<String> ids, {
    required String targetChecklistId,
    String? targetParentId,
    String? afterKey,
    String? beforeKey,
  }) {
    final tops = tree.topMost(ids);
    if (tops.isEmpty) return TreeChange.none;
    final keys = SortKeys.nBetween(afterKey, beforeKey, tops.length);
    final b = ctx.builder();
    for (var i = 0; i < tops.length; i++) {
      final top = tops[i];
      b
        ..update(top, {'checklist_id': targetChecklistId, 'parent_id': targetParentId, 'sort_key': keys[i]})
        ..event(
          EventSpec(
            entityType: 'checklist_item',
            entityId: top,
            parentId: targetChecklistId,
            eventType: 'moved',
            payload: {
              'fromChecklistId': ctx.checklistId,
              'toChecklistId': targetChecklistId,
              'fromParentId': tree.parentOf(top),
              'toParentId': targetParentId,
            },
          ),
        );
      for (final d in tree.descendants(top)) {
        b.update(d, {'checklist_id': targetChecklistId});
      }
    }
    return b.build();
  }

  /// Promote (T4.2.04): the item's children become the roots of [newChecklistId]; the item's
  /// attachments become checklist-level; the row is tombstoned unless [keepOriginal].
  static TreeChange promote(
    ChecklistTree tree,
    TreeOpContext ctx,
    String id, {
    required String newChecklistId,
    bool keepOriginal = false,
  }) {
    final b = ctx.builder();
    for (final kid in tree.childIds(id)) {
      b.update(kid, {'checklist_id': newChecklistId, 'parent_id': null});
      for (final d in tree.descendants(kid)) {
        b.update(d, {'checklist_id': newChecklistId});
      }
    }
    b.promotedAttachments[id] = newChecklistId;
    if (!keepOriginal) {
      b
        ..update(id, {'deleted_at': ctx.now})
        ..deletedItemIds.add(id);
    }
    b.event(_event(ctx, id, 'promoted', {'toChecklistId': newChecklistId}));
    return b.build();
  }

  /// Rewrites one sibling group's keys, evenly spaced, in the requested order (T4.2.04).
  static TreeChange sortChildren(
    ChecklistTree tree,
    TreeOpContext ctx,
    String? parentId,
    ItemSortBy by, {
    bool descending = false,
  }) {
    final kids = tree.childIds(parentId);
    if (kids.length < 2 || by == ItemSortBy.manual) return TreeChange.none;
    final sorted = ItemComparators.sort(kids.map((k) => tree[k]!).toList(), by, descending: descending);
    final keys = SortKeys.spread(sorted.length);
    final b = ctx.builder();
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].sortKey != keys[i]) b.update(sorted[i].id, {'sort_key': keys[i]});
    }
    b.event(
      EventSpec(
        entityType: 'checklist',
        entityId: ctx.checklistId,
        eventType: 'sorted',
        payload: {'parentId': parentId, 'by': by.name, 'descending': descending},
      ),
    );
    return b.build();
  }

  /// Plain field edits (note, priority, due…) with one `updated` event.
  static TreeChange setFields(ChecklistTree tree, TreeOpContext ctx, String id, Map<String, Object?> fields) {
    final item = tree[id];
    if (item == null || fields.isEmpty) return TreeChange.none;
    final b = ctx.builder()
      ..update(id, fields)
      ..event(_event(ctx, id, 'updated', {'fields': fields.keys.toList()}));
    return b.build();
  }
}

/// Stable comparators for view-level sorting and [TreeOps.sortChildren].
abstract final class ItemComparators {
  static List<ChecklistItem> sort(List<ChecklistItem> items, ItemSortBy by, {bool descending = false}) {
    if (by == ItemSortBy.manual) return items;
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    int cmp((int, ChecklistItem) a, (int, ChecklistItem) b) {
      // Items without a due date / change date stay last in both directions.
      final missing = _missingRank(a.$2, by).compareTo(_missingRank(b.$2, by));
      if (missing != 0) return missing;
      final c = compare(a.$2, b.$2, by);
      final r = descending ? -c : c;
      return r != 0 ? r : a.$1.compareTo(b.$1);
    }

    indexed.sort(cmp);
    return [for (final e in indexed) e.$2];
  }

  static int compare(ChecklistItem a, ChecklistItem b, ItemSortBy by) => switch (by) {
    ItemSortBy.manual => 0,
    ItemSortBy.alphabetical => Collation.compare(a.text, b.text),
    ItemSortBy.status => a.status.urgencyRank.compareTo(b.status.urgencyRank),
    ItemSortBy.due => _nullsLast(a.dueLocal, b.dueLocal, (x, y) => x.compareTo(y)),
    ItemSortBy.priority => b.priority.compareTo(a.priority),
    ItemSortBy.recent => _nullsLast(
      a.statusChangedAt ?? a.updatedAt,
      b.statusChangedAt ?? b.updatedAt,
      (x, y) => y.compareTo(x),
    ),
  };

  static int _missingRank(ChecklistItem i, ItemSortBy by) => switch (by) {
    ItemSortBy.due => i.dueLocal == null ? 1 : 0,
    ItemSortBy.recent => (i.statusChangedAt ?? i.updatedAt) == null ? 1 : 0,
    _ => 0,
  };

  static int _nullsLast<T>(T? a, T? b, int Function(T, T) f) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return f(a, b);
  }
}
