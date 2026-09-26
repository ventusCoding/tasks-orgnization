import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart' show NotificationActionIds;
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// A recent status change of an item (from `status_changed` activity events).
@immutable
class ItemStatusChange {
  const ItemStatusChange({required this.itemId, required this.to, required this.at, this.from});

  final String itemId;
  final ItemStatus? from;
  final ItemStatus to;
  final DateTime at;
}

/// Per-list counters shared by the list target and its items (`open_items`, `done`, `total`,
/// `progress` template variables).
@immutable
class _ListStats {
  const _ListStats({required this.open, required this.done, required this.total, required this.complete});

  final int open;
  final int done;
  final int total;
  final bool complete;

  int get percent => total == 0 ? 0 : (done * 100 / total).round();
}

/// Pure projection of checklists and their items into notification targets (arch §6.13,
/// `features/notifications/README.md` §2): `due` anchors (date-only values anchor at the local
/// start of the day with `ItemKind.dateOnly`), `followUp` anchors of open items, status and its
/// age, inheritance data (list, category, ancestors nearest first), guards and template
/// variables. Status-change, children-complete and child-overdue events feed event triggers.
abstract final class ChecklistNotificationTargets {
  /// Actions offered when neither the rule nor its profile sets any.
  static const itemActions = [NotificationActionIds.done, NotificationActionIds.snooze];
  static const followUpActions = [
    NotificationActionIds.markOngoing,
    NotificationActionIds.done,
    NotificationActionIds.snooze,
  ];
  static const listActions = [NotificationActionIds.open, NotificationActionIds.snooze];

  /// Builds every target of [lists] (live, not archived, not templates) and their live [items].
  ///
  /// Open items are all returned (status, stale and schedule rules may apply to any of them);
  /// closed items only when an anchor falls in `[fromUtc, toUtc]` or their status changed
  /// recently, so replans cancel their reminders.
  static List<NotificationTarget> build({
    required List<Checklist> lists,
    required List<ChecklistItem> items,
    required ZoneResolver zones,
    required String deviceZone,
    required DateTime fromUtc,
    required DateTime toUtc,
    List<ItemStatusChange> statusChanges = const [],
    String untitled = '',
  }) {
    final byList = <String, List<ChecklistItem>>{};
    for (final i in items) {
      (byList[i.checklistId] ??= []).add(i);
    }
    final changes = <String, List<ItemStatusChange>>{};
    for (final c in statusChanges) {
      (changes[c.itemId] ??= []).add(c);
    }
    final eventsSince = fromUtc.subtract(const Duration(days: 1));
    final out = <NotificationTarget>[];
    for (final list in lists) {
      final tree = ChecklistTree.build(byList[list.id] ?? const []);
      final rollups = RollupCalculator.compute(tree);
      final root = RollupCalculator.root(tree, rollups);
      final mode = list.settings.progressMode;
      final stats = _ListStats(
        open: tree.items.where((i) => i.status.isOpen).length,
        done: root.done(mode),
        total: root.total(mode),
        complete: root.isComplete(mode),
      );
      final title = list.title.trim().isEmpty ? untitled : list.title.trim();
      final listVars = <String, Object?>{
        'checklist_title': title,
        'open_items': stats.open,
        'done': stats.done,
        'total': stats.total,
        'progress': stats.percent,
      };
      out.add(_listTarget(list, tree, stats, title, listVars, zones, deviceZone, eventsSince));
      for (final id in tree.order) {
        final item = tree[id]!;
        final target = _itemTarget(
          item,
          list,
          tree,
          listVars,
          zones,
          deviceZone,
          changes[id] ?? const [],
          eventsSince,
          untitled: title,
        );
        if (target.isOpen || _relevantClosed(target, item, fromUtc, toUtc, eventsSince)) out.add(target);
      }
    }
    return out;
  }

  static bool _relevantClosed(
    NotificationTarget t,
    ChecklistItem item,
    DateTime from,
    DateTime to,
    DateTime eventsSince,
  ) {
    bool inRange(DateTime? a) => a != null && !a.isBefore(from) && !a.isAfter(to);
    final changed = item.statusChangedAt;
    return inRange(t.due) || inRange(t.followUp) || (changed != null && !changed.isBefore(eventsSince));
  }

  /// `due` of a wall-clock value: resolved in its zone (or the device zone when floating);
  /// date-only values (00:00) anchor at the local start of the day.
  static DateTime? dueInstant(LocalDateTime? due, String? zone, ZoneResolver zones, String deviceZone) {
    if (due == null) return null;
    try {
      return zones.resolve(due, zone ?? deviceZone).utc;
    } on Object {
      return null;
    }
  }

  /// Whether every countable item of a list is completed (a list with no countable item is not).
  static bool listComplete(Checklist list, List<ChecklistItem> items) {
    final tree = ChecklistTree.build(items);
    final root = RollupCalculator.root(tree, RollupCalculator.compute(tree));
    return root.isComplete(list.settings.progressMode);
  }

  static ItemKind kindOf(LocalDateTime? due) => due == null
      ? ItemKind.any
      : (ItemTimeRules.isDateOnly(due) ? ItemKind.dateOnly : ItemKind.timed);

  static NotificationTarget _listTarget(
    Checklist list,
    ChecklistTree tree,
    _ListStats stats,
    String title,
    Map<String, Object?> vars,
    ZoneResolver zones,
    String deviceZone,
    DateTime eventsSince,
  ) {
    DateTime? lastActivity = list.updatedAt;
    DateTime? completedAt;
    for (final i in tree.items) {
      final u = i.updatedAt;
      if (u != null && (lastActivity == null || u.isAfter(lastActivity))) lastActivity = u;
      final c = i.completedAt;
      if (c != null && (completedAt == null || c.isAfter(completedAt))) completedAt = c;
    }
    return NotificationTarget(
      type: NotificationTargetType.checklist,
      id: list.id,
      section: NotificationSection.checklists,
      title: title,
      categoryId: list.categoryId,
      notifyMode: NotifyMode.parse(list.notifyMode),
      itemKind: kindOf(list.dueLocal),
      timeZone: list.timeZone,
      due: dueInstant(list.dueLocal, list.timeZone, zones, deviceZone),
      status: stats.complete ? ItemStatus.completed.name : null,
      lastActivityAt: lastActivity,
      // A list whose countable items are all completed has nothing left to remind about.
      isOpen: !stats.complete,
      variables: vars,
      defaultActions: listActions,
      events: [
        if (stats.complete && completedAt != null && !completedAt.isBefore(eventsSince))
          NotificationEvent(kind: 'children_complete', at: completedAt),
      ],
    );
  }

  static NotificationTarget _itemTarget(
    ChecklistItem item,
    Checklist list,
    ChecklistTree tree,
    Map<String, Object?> listVars,
    ZoneResolver zones,
    String deviceZone,
    List<ItemStatusChange> changes,
    DateTime eventsSince, {
    required String untitled,
  }) {
    final ancestors = tree.ancestors(item.id);
    final waiting = item.status == ItemStatus.waiting || item.status == ItemStatus.blocked;
    final followUp = item.status.isOpen ? item.followUpAt : null;
    final events = <NotificationEvent>[
      for (final c in changes)
        if (!c.at.isBefore(eventsSince))
          NotificationEvent(
            kind: 'status_change',
            at: c.at,
            data: {'from': ?c.from?.name, 'to': c.to.name},
          ),
      ..._childEvents(item, tree, zones, deviceZone, eventsSince),
    ];
    final text = item.text.trim();
    return NotificationTarget(
      type: NotificationTargetType.checklistItem,
      id: item.id,
      section: NotificationSection.checklists,
      title: text.isEmpty ? untitled : text,
      checklistId: list.id,
      parentItemId: tree.parentOf(item.id),
      ancestorItemIds: ancestors.reversed.toList(),
      categoryId: list.categoryId,
      notifyMode: NotifyMode.parse(item.notifyMode),
      itemKind: kindOf(item.dueLocal),
      timeZone: item.timeZone,
      due: dueInstant(item.dueLocal, item.timeZone, zones, deviceZone),
      followUp: followUp,
      status: item.status.name,
      statusChangedAt: item.statusSince,
      lastActivityAt: item.updatedAt ?? item.statusSince,
      isOpen: item.status.isOpen,
      // Follow-ups of waiting/blocked items become obsolete when the item moves on; other
      // reminders last until the item is completed (or cancelled).
      guard: waiting && followUp != null
          ? NotificationGuard.checklistItemStatusIn(item.id, const ['waiting', 'blocked'])
          : NotificationGuard.itemNotCompleted(item.id),
      variables: {
        ...listVars,
        'item_text': item.text,
        'parent_path': [for (final a in ancestors) tree[a]!.text].join(' › '),
        'status_note': item.statusNote,
      },
      defaultActions: waiting ? followUpActions : itemActions,
      events: events,
    );
  }

  /// `children_complete` (every countable child completed) and `child_overdue` (an open child
  /// past its due) events of a parent item.
  static Iterable<NotificationEvent> _childEvents(
    ChecklistItem parent,
    ChecklistTree tree,
    ZoneResolver zones,
    String deviceZone,
    DateTime eventsSince,
  ) sync* {
    final kids = tree.children(parent.id);
    if (kids.isEmpty) return;
    final countable = kids.where((k) => k.status.isCountable).toList();
    if (countable.isNotEmpty && countable.every((k) => k.status == ItemStatus.completed)) {
      DateTime? at;
      for (final k in countable) {
        final c = k.completedAt;
        if (c != null && (at == null || c.isAfter(at))) at = c;
      }
      if (at != null && !at.isBefore(eventsSince)) yield NotificationEvent(kind: 'children_complete', at: at);
    }
    for (final k in kids) {
      final due = k.dueLocal;
      if (!k.status.isOpen || due == null) continue;
      // A date-only due becomes overdue when its day ends.
      final overdue = ItemTimeRules.isDateOnly(due) ? due.date.plusDays(1).atStartOfDay : due;
      final at = dueInstant(overdue, k.timeZone, zones, deviceZone);
      if (at != null && !at.isBefore(eventsSince)) {
        yield NotificationEvent(kind: 'child_overdue', at: at, data: {'childId': k.id});
      }
    }
  }
}
