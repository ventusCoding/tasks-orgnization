import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

final t0 = DateTime.utc(2026, 9, 22, 9);

/// Builds items from an indented outline: each line `  text[:status]`, 2 spaces per level.
/// Ids are the texts (must be unique).
List<ChecklistItem> outline(String spec, {String checklistId = 'c1'}) {
  final items = <ChecklistItem>[];
  final stack = <(int, String)>[];
  final keysByParent = <String?, String?>{};
  for (final raw in spec.split('\n')) {
    if (raw.trim().isEmpty) continue;
    final depth = (raw.length - raw.trimLeft().length) ~/ 2;
    var text = raw.trim();
    var status = ItemStatus.todo;
    final colon = text.lastIndexOf(':');
    if (colon > 0) {
      status = ItemStatus.parse(text.substring(colon + 1));
      text = text.substring(0, colon);
    }
    while (stack.isNotEmpty && stack.last.$1 >= depth) {
      stack.removeLast();
    }
    final parent = stack.isEmpty ? null : stack.last.$2;
    final key = FractionalIndex.between(keysByParent[parent], null);
    keysByParent[parent] = key;
    items.add(
      ChecklistItem(
        id: text,
        checklistId: checklistId,
        parentId: parent,
        sortKey: key,
        text: text,
        status: status,
        completedAt: status == ItemStatus.completed ? t0 : null,
        createdAt: t0,
      ),
    );
    stack.add((depth, text));
  }
  return items;
}

ChecklistTree tree(String spec) => ChecklistTree.build(outline(spec));

/// Renders a tree back to the outline format (ids + statuses) for readable assertions.
String render(ChecklistTree t, {bool statuses = false}) {
  final out = StringBuffer();
  for (final id in t.order) {
    final i = t[id]!;
    out.writeln(
      '${'  ' * t.depthOf(id)}${i.text}${statuses && i.status != ItemStatus.todo ? ':${i.status.name}' : ''}',
    );
  }
  return out.toString().trimRight();
}

int _idCounter = 0;
TreeOpContext ctx({ChecklistSettings settings = ChecklistSettings.defaults, String cause = 'user'}) =>
    TreeOpContext(checklistId: 'c1', now: t0, newId: () => 'n${_idCounter++}', settings: settings, cause: cause);

Object? _get(Map<String, Object?> v, String k, Object? fallback) => v.containsKey(k) ? v[k] : fallback;

/// Applies a pure change to a list of items (mirror of the repository, for pure property tests).
List<ChecklistItem> applyChange(List<ChecklistItem> items, TreeChange change) {
  final byId = {for (final i in items) i.id: i};
  for (final w in change.writes.where((w) => w.table == 'checklist_items')) {
    final v = w.values;
    if (w.isInsert) {
      byId[w.id] = ChecklistItem(
        id: w.id,
        checklistId: v['checklist_id']! as String,
        parentId: v['parent_id'] as String?,
        sortKey: v['sort_key']! as String,
        text: v['text'] as String? ?? '',
        note: v['note'] as String?,
        status: ItemStatus.parse(v['status'] as String?),
        statusNote: v['status_note'] as String?,
        statusChangedAt: v['status_changed_at'] as DateTime?,
        completedAt: v['completed_at'] as DateTime?,
        followUpAt: v['follow_up_at'] as DateTime?,
        dueLocal: v['due_local'] as LocalDateTime?,
        priority: v['priority'] as int? ?? 0,
        createdAt: t0,
      );
      continue;
    }
    final cur = byId[w.id];
    if (cur == null) continue;
    if (v['deleted_at'] != null) {
      byId.remove(w.id);
      continue;
    }
    byId[w.id] = ChecklistItem(
      id: cur.id,
      checklistId: _get(v, 'checklist_id', cur.checklistId)! as String,
      parentId: _get(v, 'parent_id', cur.parentId) as String?,
      sortKey: _get(v, 'sort_key', cur.sortKey)! as String,
      text: _get(v, 'text', cur.text)! as String,
      note: _get(v, 'note', cur.note) as String?,
      status: v.containsKey('status') ? ItemStatus.parse(v['status'] as String?) : cur.status,
      statusNote: _get(v, 'status_note', cur.statusNote) as String?,
      statusChangedAt: _get(v, 'status_changed_at', cur.statusChangedAt) as DateTime?,
      completedAt: _get(v, 'completed_at', cur.completedAt) as DateTime?,
      followUpAt: _get(v, 'follow_up_at', cur.followUpAt) as DateTime?,
      dueLocal: _get(v, 'due_local', cur.dueLocal) as LocalDateTime?,
      priority: _get(v, 'priority', cur.priority)! as int,
      createdAt: cur.createdAt,
    );
  }
  return byId.values.toList();
}

/// Tree invariants: acyclic, every live item reachable, strict sibling order.
void checkInvariants(List<ChecklistItem> items) {
  final t = ChecklistTree.build(items);
  if (t.length != items.length) throw StateError('unreachable items');
  if (t.cycleBreaks.isNotEmpty) throw StateError('cycle: ${t.cycleBreaks}');
  if (t.orphans.isNotEmpty) throw StateError('orphans: ${t.orphans}');
  for (final parent in [null, ...t.order]) {
    final kids = t.childIds(parent);
    for (var i = 1; i < kids.length; i++) {
      if (t[kids[i - 1]]!.sortKey.compareTo(t[kids[i]]!.sortKey) >= 0) {
        throw StateError('sibling order not strict under $parent');
      }
    }
  }
}
