import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:meta/meta.dart';

/// Derived progress and status summary of a node (T4.3.06). Never stored.
@immutable
class Rollup {
  const Rollup({
    this.leafCountable = 0,
    this.leafCompleted = 0,
    this.childCountable = 0,
    this.childCompleted = 0,
    this.todo = 0,
    this.ongoing = 0,
    this.waiting = 0,
    this.blocked = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.blockedBelow = 0,
    this.waitingBelow = 0,
    this.descendants = 0,
    this.oldestOpenSince,
  });

  static const zero = Rollup();

  /// Countable (non-cancelled) leaves below (or the node itself when it is a leaf).
  final int leafCountable;
  final int leafCompleted;

  /// Countable / completed direct children ("children" progress mode).
  final int childCountable;
  final int childCompleted;

  /// Leaf status counts.
  final int todo;
  final int ongoing;
  final int waiting;
  final int blocked;
  final int completed;
  final int cancelled;

  /// Blocked / waiting descendants at any level ("2 blocked below").
  final int blockedBelow;
  final int waitingBelow;
  final int descendants;

  /// Earliest `status_changed_at`/`created_at` among open items in the subtree.
  final DateTime? oldestOpenSince;

  int total(ProgressMode mode) => mode == ProgressMode.leaves || childCountable == 0 ? leafCountable : childCountable;
  int done(ProgressMode mode) => mode == ProgressMode.leaves || childCountable == 0 ? leafCompleted : childCompleted;

  double progress(ProgressMode mode) {
    final t = total(mode);
    return t == 0 ? 0 : done(mode) / t;
  }

  bool isComplete(ProgressMode mode) => total(mode) > 0 && done(mode) == total(mode);

  int countOf(ItemStatus s) => switch (s) {
    ItemStatus.todo => todo,
    ItemStatus.ongoing => ongoing,
    ItemStatus.waiting => waiting,
    ItemStatus.blocked => blocked,
    ItemStatus.completed => completed,
    ItemStatus.cancelled => cancelled,
  };

  @override
  bool operator ==(Object other) =>
      other is Rollup &&
      other.leafCountable == leafCountable &&
      other.leafCompleted == leafCompleted &&
      other.childCountable == childCountable &&
      other.childCompleted == childCompleted &&
      other.todo == todo &&
      other.ongoing == ongoing &&
      other.waiting == waiting &&
      other.blocked == blocked &&
      other.completed == completed &&
      other.cancelled == cancelled &&
      other.blockedBelow == blockedBelow &&
      other.waitingBelow == waitingBelow &&
      other.descendants == descendants &&
      other.oldestOpenSince == oldestOpenSince;

  @override
  int get hashCode => Object.hash(
    leafCountable,
    leafCompleted,
    childCountable,
    childCompleted,
    todo,
    ongoing,
    waiting,
    blocked,
    completed,
    cancelled,
    blockedBelow,
    waitingBelow,
    descendants,
    oldestOpenSince,
  );

  @override
  String toString() => 'Rollup($leafCompleted/$leafCountable c=$childCompleted/$childCountable b=$blockedBelow w=$waitingBelow)';
}

/// Pure roll-up computation over a [ChecklistTree] (T4.3.06): full O(n) pass, plus an
/// incremental path-to-root update for single changes.
abstract final class RollupCalculator {
  static Rollup _leaf(ChecklistItem i) {
    final s = i.status;
    return Rollup(
      leafCountable: s.isCountable ? 1 : 0,
      leafCompleted: s == ItemStatus.completed ? 1 : 0,
      todo: s == ItemStatus.todo ? 1 : 0,
      ongoing: s == ItemStatus.ongoing ? 1 : 0,
      waiting: s == ItemStatus.waiting ? 1 : 0,
      blocked: s == ItemStatus.blocked ? 1 : 0,
      completed: s == ItemStatus.completed ? 1 : 0,
      cancelled: s == ItemStatus.cancelled ? 1 : 0,
      oldestOpenSince: s.isOpen ? i.statusSince : null,
    );
  }

  static DateTime? _min(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  /// Combines children rollups ([kids] in the same order as [kidItems]).
  static Rollup combine(List<ChecklistItem> kidItems, List<Rollup> kids) {
    var lc = 0, ld = 0, cc = 0, cd = 0, todo = 0, ongoing = 0, waiting = 0, blocked = 0, completed = 0;
    var cancelled = 0, bb = 0, wb = 0, desc = 0;
    DateTime? oldest;
    for (var i = 0; i < kids.length; i++) {
      final r = kids[i];
      final item = kidItems[i];
      lc += r.leafCountable;
      ld += r.leafCompleted;
      if (item.status.isCountable) cc++;
      if (item.status == ItemStatus.completed) cd++;
      todo += r.todo;
      ongoing += r.ongoing;
      waiting += r.waiting;
      blocked += r.blocked;
      completed += r.completed;
      cancelled += r.cancelled;
      bb += r.blockedBelow + (item.status == ItemStatus.blocked ? 1 : 0);
      wb += r.waitingBelow + (item.status == ItemStatus.waiting ? 1 : 0);
      desc += r.descendants + 1;
      oldest = _min(oldest, r.oldestOpenSince);
      if (item.status.isOpen) oldest = _min(oldest, item.statusSince);
    }
    return Rollup(
      leafCountable: lc,
      leafCompleted: ld,
      childCountable: cc,
      childCompleted: cd,
      todo: todo,
      ongoing: ongoing,
      waiting: waiting,
      blocked: blocked,
      completed: completed,
      cancelled: cancelled,
      blockedBelow: bb,
      waitingBelow: wb,
      descendants: desc,
      oldestOpenSince: oldest,
    );
  }

  static Rollup _node(ChecklistTree tree, String id, Map<String, Rollup> known) {
    final kids = tree.childIds(id);
    if (kids.isEmpty) return _leaf(tree[id]!);
    return combine([for (final k in kids) tree[k]!], [for (final k in kids) known[k] ?? Rollup.zero]);
  }

  /// Full computation (reverse DFS order = children before parents).
  static Map<String, Rollup> compute(ChecklistTree tree) {
    final out = <String, Rollup>{};
    for (var i = tree.order.length - 1; i >= 0; i--) {
      final id = tree.order[i];
      out[id] = _node(tree, id, out);
    }
    return out;
  }

  /// Roll-up of the whole checklist (or the focus root's children).
  static Rollup root(ChecklistTree tree, Map<String, Rollup> rollups, {String? focusRootId}) {
    final kids = tree.childIds(focusRootId);
    return combine([for (final k in kids) tree[k]!], [for (final k in kids) rollups[k] ?? Rollup.zero]);
  }

  /// Incremental update after [changedId] changed in [tree]: recomputes the node and its
  /// ancestors only (mutates [rollups]).
  static void recomputePath(ChecklistTree tree, Map<String, Rollup> rollups, String changedId) {
    if (!tree.contains(changedId)) return;
    rollups[changedId] = _node(tree, changedId, rollups);
    for (final a in tree.ancestors(changedId).reversed) {
      rollups[a] = _node(tree, a, rollups);
    }
  }
}
