import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:meta/meta.dart';

/// View-level item filtering applied before layout (T3.3.22 / T3.4.10).
@immutable
class ItemFilter {
  const ItemFilter({
    this.showCompleted = true,
    this.showCancelled = false,
    this.categories = const {},
    this.priorities = const {},
    this.statuses = const {},
    this.trackingModes = const {},
    this.text,
    this.taskIds,
  });

  static const none = ItemFilter(showCancelled: true);

  final bool showCompleted;
  final bool showCancelled;

  /// Category ids ('' = no category). Empty = all.
  final Set<String> categories;
  final Set<int> priorities;
  final Set<OccurrenceStatus> statuses;
  final Set<TrackingMode> trackingModes;
  final String? text;

  /// Tasks allowed by tag filters (resolved by the view from entity tags); null = no constraint.
  final Set<String>? taskIds;

  bool get isActive =>
      categories.isNotEmpty ||
      priorities.isNotEmpty ||
      statuses.isNotEmpty ||
      trackingModes.isNotEmpty ||
      taskIds != null ||
      (text != null && text!.trim().isNotEmpty);

  bool accepts(PlannerItem item) {
    if (!showCompleted && item.status == OccurrenceStatus.done) return false;
    if (!showCancelled && item.status == OccurrenceStatus.cancelled) return false;
    if (categories.isNotEmpty && !categories.contains(item.categoryId ?? '')) return false;
    if (priorities.isNotEmpty && !priorities.contains(item.priority)) return false;
    if (statuses.isNotEmpty && !statuses.contains(item.status)) return false;
    if (trackingModes.isNotEmpty && !trackingModes.contains(item.trackingMode)) return false;
    if (taskIds != null && !taskIds!.contains(item.taskId)) return false;
    final q = text?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      final hay = '${item.title} ${item.notes ?? ''} ${item.location ?? ''}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  ItemFilter withTaskIds(Set<String>? ids) => ItemFilter(
    showCompleted: showCompleted,
    showCancelled: showCancelled,
    categories: categories,
    priorities: priorities,
    statuses: statuses,
    trackingModes: trackingModes,
    text: text,
    taskIds: ids,
  );

  List<PlannerItem> apply(List<PlannerItem> items) {
    if (showCompleted && showCancelled && !isActive) return items;
    return [for (final i in items) if (accepts(i)) i];
  }

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.showCompleted == showCompleted &&
      other.showCancelled == showCancelled &&
      _setEq(other.categories, categories) &&
      _setEq(other.priorities, priorities) &&
      _setEq(other.statuses, statuses) &&
      _setEq(other.trackingModes, trackingModes) &&
      (other.taskIds == null) == (taskIds == null) &&
      (taskIds == null || _setEq(other.taskIds!, taskIds!)) &&
      other.text == text;

  @override
  int get hashCode => Object.hash(
    showCompleted,
    showCancelled,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(priorities),
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(trackingModes),
    text,
    taskIds == null ? null : Object.hashAllUnordered(taskIds!),
  );
}

bool _setEq<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);
