import 'package:everslot/features/planner/domain/planner_item.dart' show TrackingMode;
import 'package:meta/meta.dart';

/// Target of a bulk action (T3.1.18): one occurrence, or the whole series when [series].
@immutable
class BulkTarget {
  const BulkTarget(this.taskId, {this.occurrenceKey, this.series = false});

  final String taskId;
  final String? occurrenceKey;
  final bool series;
}

/// Bulk change (T3.1.18).
@immutable
sealed class BulkChange {
  const BulkChange();
}

final class BulkMove extends BulkChange {
  const BulkMove({this.days = 0, this.minutes = 0});

  final int days;
  final int minutes;
}

final class BulkSetCategory extends BulkChange {
  const BulkSetCategory(this.categoryId);

  final String? categoryId;
}

final class BulkSetPriority extends BulkChange {
  const BulkSetPriority(this.priority);

  final int priority;
}

final class BulkSetTrackingMode extends BulkChange {
  const BulkSetTrackingMode(this.mode);

  final TrackingMode mode;
}

final class BulkDuplicate extends BulkChange {
  const BulkDuplicate();
}

final class BulkDelete extends BulkChange {
  const BulkDelete();
}

/// Adds tags to every targeted task (series level; tags are written by the caller's
/// `onTask` hook inside the same transaction).
final class BulkAddTags extends BulkChange {
  const BulkAddTags(this.tagIds);

  final Set<String> tagIds;
}
