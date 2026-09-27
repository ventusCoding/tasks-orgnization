import 'package:everslot/features/today/domain/day_window.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Whether an item's due value falls on or before the logical day of [window] (T8.1.08).
///
/// Date-only values (00:00) compare dates; timed values are resolved in the item's zone (the
/// device zone when floating) and compared with the end of the day window.
bool isDueByEndOf(TodayChecklistItem item, DayWindow window, ZoneResolver zones) {
  final due = item.dueLocal;
  if (due == null) return false;
  if (due.hour == 0 && due.minute == 0) return !due.date.isAfter(window.date);
  final instant = zones.resolve(due, item.timeZone ?? window.zone).utc;
  return instant.isBefore(window.endUtc);
}

/// Whether a due item is already late at [nowUtc] (date-only values are late the day after).
bool isOverdueAt(TodayChecklistItem item, DayWindow window, ZoneResolver zones, DateTime nowUtc) {
  final due = item.dueLocal;
  if (due == null) return false;
  if (due.hour == 0 && due.minute == 0) return due.date.isBefore(window.date);
  return zones.resolve(due, item.timeZone ?? window.zone).utc.isBefore(nowUtc);
}

/// Splits prefiltered rows into items due today (or overdue) and follow-ups to check (waiting /
/// blocked items whose follow-up is today or past). An item appears once (due wins).
({List<TodayChecklistItem> due, List<TodayChecklistItem> followUps}) partitionChecklistItems(
  Iterable<TodayChecklistItem> rows,
  DayWindow window,
  ZoneResolver zones,
) {
  final due = <TodayChecklistItem>[];
  final followUps = <TodayChecklistItem>[];
  for (final r in rows) {
    if (!r.status.isOpen) continue;
    if (isDueByEndOf(r, window, zones)) {
      due.add(r);
      continue;
    }
    final f = r.followUpAt;
    if (r.status.keepsFollowUp && f != null && f.isBefore(window.endUtc)) followUps.add(r);
  }
  followUps.sort((a, b) => a.followUpAt!.compareTo(b.followUpAt!));
  return (due: due, followUps: followUps);
}
