import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Due chip states (T4.3.10).
enum DueState { overdue, today, tomorrow, later }

/// Escalation of waiting/blocked pills by age (T4.3.11).
enum AgeLevel { normal, warn, alert }

/// Pure due / follow-up / staleness rules (T4.3.10, T4.3.11).
abstract final class ItemTimeRules {
  /// Classifies a due value against "now" expressed in the same wall-clock frame (the item's
  /// zone, or the device zone for floating values). 00:00 means date-only.
  static DueState classifyDue(LocalDateTime due, LocalDateTime nowLocal) {
    final dateOnly = due.hour == 0 && due.minute == 0;
    final today = nowLocal.date;
    if (dateOnly ? due.date.isBefore(today) : due.isBefore(nowLocal)) return DueState.overdue;
    if (due.date == today) return DueState.today;
    if (due.date == today.plusDays(1)) return DueState.tomorrow;
    return DueState.later;
  }

  static bool isDateOnly(LocalDateTime due) => due.hour == 0 && due.minute == 0;

  static bool followUpOverdue(DateTime? followUpAt, DateTime now) => followUpAt != null && !followUpAt.isAfter(now);

  /// Open item unchanged for at least [staleAfterDays].
  static bool isStale(ChecklistItem item, DateTime now, int staleAfterDays) {
    if (!item.status.isOpen) return false;
    final since = item.updatedAt ?? item.statusChangedAt ?? item.createdAt;
    if (since == null) return false;
    return now.difference(since).inDays >= staleAfterDays;
  }

  /// Waiting/blocked pills escalate after [warnDays] and [alertDays].
  static AgeLevel escalation(ChecklistItem item, DateTime now, {int warnDays = 3, int alertDays = 7}) =>
      escalationFor(item.status, item.statusSince, now, warnDays: warnDays, alertDays: alertDays);

  static AgeLevel escalationFor(ItemStatus status, DateTime? since, DateTime now, {int warnDays = 3, int alertDays = 7}) {
    if (status != ItemStatus.waiting && status != ItemStatus.blocked) return AgeLevel.normal;
    if (since == null) return AgeLevel.normal;
    final days = now.difference(since).inDays;
    if (days >= alertDays) return AgeLevel.alert;
    if (days >= warnDays) return AgeLevel.warn;
    return AgeLevel.normal;
  }

  /// Compact age since the current status ("4 d", "2 h"): `(value, unit)` with unit m/h/d.
  static (int, String) age(DateTime since, DateTime now) {
    final d = now.difference(since);
    if (d.inDays >= 1) return (d.inDays, 'd');
    if (d.inHours >= 1) return (d.inHours, 'h');
    return (d.inMinutes < 0 ? 0 : d.inMinutes, 'm');
  }
}

/// A `status_changed` / `status_note_changed` event reduced to what the history needs.
@immutable
class StatusEvent {
  const StatusEvent({
    required this.at,
    required this.to,
    this.from,
    this.note,
    this.cause,
    this.deviceId,
    this.type = 'status_changed',
    this.followUpAt,
  });

  final DateTime at;
  final ItemStatus? from;
  final ItemStatus to;
  final String? note;
  final String? cause;
  final String? deviceId;
  final String type;
  final DateTime? followUpAt;
}

/// One period spent in a status.
@immutable
class StatusInterval {
  const StatusInterval({required this.status, required this.start, this.end, this.note});

  final ItemStatus status;
  final DateTime start;

  /// Null = current (open) interval.
  final DateTime? end;
  final String? note;

  Duration duration(DateTime now) => (end ?? now).difference(start);
}

/// Status history computations (T4.3.05).
abstract final class StatusHistory {
  /// Intervals from creation to now. [events] may be unsorted; note-only changes don't split.
  static List<StatusInterval> intervals(
    List<StatusEvent> events, {
    required DateTime createdAt,
    required ItemStatus currentStatus,
  }) {
    final changes = events.where((e) => e.type == 'status_changed').toList()..sort((a, b) => a.at.compareTo(b.at));
    final out = <StatusInterval>[];
    var status = changes.isEmpty ? currentStatus : (changes.first.from ?? ItemStatus.todo);
    var start = createdAt;
    String? note;
    for (final c in changes) {
      final at = c.at.isBefore(start) ? start : c.at;
      if (at.isAfter(start)) out.add(StatusInterval(status: status, start: start, end: at, note: note));
      status = c.to;
      start = at;
      note = c.note;
    }
    out.add(StatusInterval(status: status, start: start, note: note));
    return out;
  }

  /// Total time per status, including the open current interval up to [now].
  static Map<ItemStatus, Duration> totals(List<StatusInterval> intervals, DateTime now) {
    final out = <ItemStatus, Duration>{};
    for (final i in intervals) {
      out[i.status] = (out[i.status] ?? Duration.zero) + i.duration(now);
    }
    return out;
  }

  /// Most recent distinct reason notes for [status] (quick chips in the reason sheet, T4.3.02).
  static List<String> recentReasons(List<StatusEvent> events, ItemStatus status, {int limit = 6}) {
    final sorted = events.where((e) => e.to == status && (e.note?.trim().isNotEmpty ?? false)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final seen = <String>{};
    final out = <String>[];
    for (final e in sorted.take(20)) {
      final n = e.note!.trim();
      if (seen.add(n.toLowerCase())) out.add(n);
      if (out.length >= limit) break;
    }
    return out;
  }
}
