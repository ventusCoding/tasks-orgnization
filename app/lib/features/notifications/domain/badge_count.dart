import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// App-icon badge policies (`notifications.badgePolicy`, T7.3.06).
abstract final class BadgePolicy {
  static const off = 'off';

  /// Unread inbox rows (the bell's count).
  static const unread = 'unread';

  /// Open items that are overdue or due today.
  static const due = 'due';
}

/// Badge number for a policy (T7.3.06) — pure, so the main and the background isolate agree.
abstract final class BadgeCount {
  static int compute(
    String policy, {
    required int unread,
    required Iterable<NotificationTarget> targets,
    required DateTime now,
    required String zone,
    required ZoneResolver zones,
  }) => switch (policy) {
    BadgePolicy.off => 0,
    BadgePolicy.due => dueCount(targets, now: now, zone: zone, zones: zones),
    _ => unread < 0 ? 0 : unread,
  };

  /// Open tasks and items whose due moment (due, else end, else start) has passed (overdue) or
  /// falls today in the device zone, plus habits whose current period is still open; one per
  /// target occurrence. Digests and quit trackers don't count; past habit periods neither.
  static int dueCount(
    Iterable<NotificationTarget> targets, {
    required DateTime now,
    required String zone,
    required ZoneResolver zones,
  }) {
    final today = zones.toLocal(now, zone).date;
    final seen = <String>{};
    for (final t in targets) {
      if (!t.isOpen || t.type == NotificationTargetType.digest) continue;
      if (t.section == NotificationSection.quit) continue;
      if (t.type == NotificationTargetType.habit) {
        final start = t.periodStart;
        final end = t.periodEnd;
        if (start != null && end != null && !start.isAfter(now) && end.isAfter(now)) {
          seen.add('${t.targetKey}|${t.occurrenceKey ?? ''}');
        }
        continue;
      }
      final at = t.due ?? t.end ?? t.start;
      if (at == null) continue;
      final overdue = !at.isAfter(now);
      final dueDate = zones.toLocal(t.due ?? t.start ?? at, zone).date;
      if (overdue || dueDate == today) {
        seen.add('${t.targetKey}|${t.occurrenceKey ?? ''}');
      }
    }
    return seen.length;
  }
}
