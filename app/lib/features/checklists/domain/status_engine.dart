import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';

/// Pure status transitions with parent auto-complete / reopen cascades (T4.3.01, T4.3.07).
///
/// Every transition writes `status`, `status_note`, `status_changed_at`, `completed_at` (set iff
/// completed) and `follow_up_at` (kept for waiting/blocked), plus a `status_changed` activity
/// event `{from, to, note, followUpAt}` — cascaded ones carry `cause = cascade | auto_rollup`.
class StatusEngine {
  StatusEngine._(this.tree, this.settings, this.now, this.builder);

  final ChecklistTree tree;
  final ChecklistSettings settings;
  final DateTime now;
  final TreeChangeBuilder builder;
  final Map<String, ItemStatus> _work = {};
  final Set<String> _changed = {};

  ItemStatus _cur(String id) => _work[id] ?? tree[id]!.status;

  static String? normalizeNote(String? note) {
    if (note == null) return null;
    final t = note.trim();
    return t.isEmpty ? null : t;
  }

  /// Applies `to` to [ids] (plus cascades) and returns ONE change.
  ///
  /// - [note]: the reason / outcome note stored in `status_note` (blank clears it).
  /// - [followUpAt]: check-back instant for waiting/blocked; [keepFollowUp] keeps an existing one
  ///   when leaving waiting/blocked.
  /// - [completeOpenDescendants]: also complete open descendants (answer to "Also complete N
  ///   open sub-items?" or `completeChildrenWithParent = always`).
  static TreeChange apply(
    ChecklistTree tree,
    ChecklistSettings settings, {
    required Iterable<String> ids,
    required ItemStatus to,
    required DateTime now,
    String? note,
    bool setNote = true,
    DateTime? followUpAt,
    bool keepFollowUp = false,
    bool? completeOpenDescendants,
    String cause = 'user',
    TreeChangeBuilder? into,
  }) {
    final engine = StatusEngine._(tree, settings, now, into ?? TreeChangeBuilder(cause: cause));
    engine._apply(
      ids: ids,
      to: to,
      note: note,
      setNote: setNote,
      followUpAt: followUpAt,
      keepFollowUp: keepFollowUp,
      completeOpenDescendants: completeOpenDescendants ?? settings.completeChildrenWithParent == CascadeChoice.always,
      cause: cause,
    );
    return engine.builder.build();
  }

  /// Number of open (not completed/cancelled) descendants — drives the cascade question.
  static int openDescendantCount(ChecklistTree tree, String id) =>
      tree.descendants(id).where((d) => tree[d]!.status.isOpen).length;

  /// Adding a child under completed ancestors reopens them (T4.3.07) when auto-complete is on.
  static void reopenForNewChild(
    ChecklistTree tree,
    ChecklistSettings settings,
    String? parentId, {
    required DateTime now,
    required TreeChangeBuilder into,
  }) {
    if (!settings.autoCompleteParent || parentId == null || !tree.contains(parentId)) return;
    final engine = StatusEngine._(tree, settings, now, into);
    String? p = parentId;
    while (p != null && engine._cur(p) == ItemStatus.completed) {
      engine._set(p, ItemStatus.todo, note: null, eventCause: 'cascade');
      p = tree.parentOf(p);
    }
  }

  void _apply({
    required Iterable<String> ids,
    required ItemStatus to,
    required String? note,
    required bool setNote,
    required DateTime? followUpAt,
    required bool keepFollowUp,
    required bool completeOpenDescendants,
    required String cause,
  }) {
    final targets = ids.where(tree.contains).toSet().toList()
      ..sort((a, b) => tree.indexOf(a).compareTo(tree.indexOf(b)));
    final normalized = normalizeNote(note);
    for (final id in targets) {
      final item = tree[id]!;
      final from = _cur(id);
      if (from == to) {
        final noteChanged = setNote && normalized != item.statusNote;
        final followChanged = followUpAt != null && followUpAt != item.followUpAt && to.keepsFollowUp;
        if (!noteChanged && !followChanged) continue;
        builder
          ..update(id, {if (noteChanged) 'status_note': normalized, if (followChanged) 'follow_up_at': followUpAt})
          ..event(
            EventSpec(
              entityType: 'checklist_item',
              entityId: id,
              parentId: item.checklistId,
              eventType: 'status_note_changed',
              payload: {
                'status': to.name,
                'note': normalized,
                if (followUpAt != null) 'followUpAt': followUpAt.toUtc().toIso8601String(),
              },
            ),
          );
        continue;
      }
      _set(
        id,
        to,
        note: setNote ? normalized : item.statusNote,
        followUpAt: followUpAt,
        keepFollowUp: keepFollowUp,
        eventCause: null,
      );
    }
    if (to == ItemStatus.completed && completeOpenDescendants) {
      for (final id in targets) {
        for (final d in tree.descendants(id)) {
          if (_cur(d).isOpen) _set(d, ItemStatus.completed, note: null, eventCause: 'cascade');
        }
      }
    }
    if (settings.autoCompleteParent) {
      final explicit = targets.toSet();
      final starts = _changed.toList()..sort((a, b) => tree.indexOf(b).compareTo(tree.indexOf(a)));
      for (final id in starts) {
        var p = tree.parentOf(id);
        while (p != null && !explicit.contains(p)) {
          final countable = tree.childIds(p).where((k) => _cur(k).isCountable).toList();
          if (countable.isEmpty) break;
          final allDone = countable.every((k) => _cur(k) == ItemStatus.completed);
          final ps = _cur(p);
          if (allDone && ps != ItemStatus.completed) {
            _set(p, ItemStatus.completed, note: null, eventCause: 'auto_rollup');
          } else if (!allDone && ps == ItemStatus.completed) {
            _set(p, ItemStatus.todo, note: null, eventCause: 'cascade');
          } else {
            break;
          }
          p = tree.parentOf(p);
        }
      }
    }
  }

  void _set(
    String id,
    ItemStatus to, {
    required String? note,
    DateTime? followUpAt,
    bool keepFollowUp = false,
    required String? eventCause,
  }) {
    final item = tree[id]!;
    final from = _cur(id);
    if (from == to) return;
    _work[id] = to;
    _changed.add(id);
    final DateTime? followUp;
    if (to.keepsFollowUp) {
      followUp = followUpAt ?? item.followUpAt;
    } else {
      followUp = keepFollowUp ? item.followUpAt : null;
    }
    builder
      ..update(id, {
        'status': to.name,
        'status_note': note,
        'status_changed_at': now,
        'completed_at': to == ItemStatus.completed ? now : null,
        'follow_up_at': followUp,
      })
      ..event(
        EventSpec(
          entityType: 'checklist_item',
          entityId: id,
          parentId: item.checklistId,
          eventType: 'status_changed',
          payload: {'from': from.name, 'to': to.name, 'note': note, 'followUpAt': followUp?.toUtc().toIso8601String()},
          cause: eventCause,
        ),
      );
  }
}

/// Keep-style list commands (T4.3.09) — each one op group with `cause = bulk`.
abstract final class ListCommands {
  /// Completed → todo; other statuses unchanged.
  static TreeChange uncheckAll(ChecklistTree tree, ChecklistSettings settings, {required DateTime now}) {
    final ids = tree.order.where((id) => tree[id]!.status == ItemStatus.completed).toList();
    if (ids.isEmpty) return TreeChange.none;
    return StatusEngine.apply(
      tree,
      settings.copyWith(autoCompleteParent: false),
      ids: ids,
      to: ItemStatus.todo,
      now: now,
      cause: 'bulk',
    );
  }

  static int uncheckAllCount(ChecklistTree tree) =>
      tree.order.where((id) => tree[id]!.status == ItemStatus.completed).length;

  /// Everything to todo; reason notes and follow-ups cleared.
  static TreeChange resetAll(ChecklistTree tree, {required DateTime now}) {
    final b = TreeChangeBuilder(cause: 'bulk');
    for (final id in tree.order) {
      final item = tree[id]!;
      if (item.status == ItemStatus.todo) {
        if (item.statusNote != null || item.followUpAt != null) {
          b.update(id, {'status_note': null, 'follow_up_at': null});
        }
        continue;
      }
      b
        ..update(id, {
          'status': ItemStatus.todo.name,
          'status_note': null,
          'status_changed_at': now,
          'completed_at': null,
          'follow_up_at': null,
        })
        ..event(
          EventSpec(
            entityType: 'checklist_item',
            entityId: id,
            parentId: item.checklistId,
            eventType: 'status_changed',
            payload: {'from': item.status.name, 'to': ItemStatus.todo.name, 'note': null, 'followUpAt': null},
          ),
        );
    }
    return b.build();
  }

  /// Completed leaves and fully completed subtrees (top-most roots only).
  static List<String> completedSubtrees(ChecklistTree tree) {
    bool fully(String id) =>
        tree[id]!.status == ItemStatus.completed &&
        tree.descendants(id).every((d) => tree[d]!.status == ItemStatus.completed);
    return tree.topMost(tree.order.where(fully));
  }
}
