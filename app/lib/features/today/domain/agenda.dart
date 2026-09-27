import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/tracking_policy.dart';
import 'package:everslot/features/today/domain/day_window.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Stable Today order: all-day first, then start, priority (high first), title, key.
int compareAgenda(PlannerItem a, PlannerItem b) {
  if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
  var c = a.allDay ? a.startLocal.compareTo(b.startLocal) : a.startUtc.compareTo(b.startUtc);
  if (c != 0) return c;
  c = b.priority.compareTo(a.priority);
  if (c != 0) return c;
  c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return c != 0 ? c : a.key.compareTo(b.key);
}

/// Whether [item] belongs to the logical day of [window]: all-day items covering its date,
/// timed items overlapping its instants (zero-length items starting inside it).
bool isInDay(PlannerItem item, DayWindow window) {
  if (item.allDay) {
    final start = item.startLocal.date;
    final end = item.endLocal.date; // exclusive for all-day spans
    final date = window.date;
    return !start.isAfter(date) && (end.isAfter(date) || start == date);
  }
  if (item.durationMinutes == 0 || !item.endUtc.isAfter(item.startUtc)) return window.contains(item.startUtc);
  return item.startUtc.isBefore(window.endUtc) && item.endUtc.isAfter(window.startUtc);
}

/// Splits resolved occurrences into the day's agenda and the timed occurrences that start after
/// the day window (the Now/Next card looks ahead). Cancelled and backlog items are dropped.
({List<PlannerItem> agenda, List<PlannerItem> upcoming}) splitAgenda(Iterable<PlannerItem> items, DayWindow window) {
  final agenda = <PlannerItem>[];
  final upcoming = <PlannerItem>[];
  for (final i in items) {
    if (i.isBacklog || i.status == OccurrenceStatus.cancelled) continue;
    if (isInDay(i, window)) {
      agenda.add(i);
    } else if (!i.allDay && !i.startUtc.isBefore(window.endUtc)) {
      upcoming.add(i);
    }
  }
  agenda.sort(compareAgenda);
  upcoming.sort(compareAgenda);
  return (agenda: agenda, upcoming: upcoming);
}

/// The agenda block's sections (T8.1.04): open all-day items first, then open timed items, and the
/// resolved ones (done / skipped) collapsed into a "Done (n)" group.
@immutable
class AgendaGroups {
  const AgendaGroups({this.allDay = const [], this.timed = const [], this.completed = const []});

  final List<PlannerItem> allDay;
  final List<PlannerItem> timed;
  final List<PlannerItem> completed;

  bool get isEmpty => allDay.isEmpty && timed.isEmpty && completed.isEmpty;
  int get openCount => allDay.length + timed.length;
}

AgendaGroups groupAgenda(Iterable<PlannerItem> agenda) {
  final allDay = <PlannerItem>[];
  final timed = <PlannerItem>[];
  final completed = <PlannerItem>[];
  for (final i in agenda) {
    if (i.status == OccurrenceStatus.done || i.status == OccurrenceStatus.skipped) {
      completed.add(i);
    } else if (i.allDay) {
      allDay.add(i);
    } else {
      timed.add(i);
    }
  }
  return AgendaGroups(allDay: allDay, timed: timed, completed: completed);
}

/// Whether the item gets a checkbox / done action (events never do, T3.2.13).
bool hasCheckbox(PlannerItem item) => TrackingPolicy.of(item.trackingMode).hasCheckbox;

/// Unresolved past occurrences for the overdue block (T8.1.05): check/timer occurrences of the
/// [lookbackDays] days before [today] that are still open (missed, scheduled or in progress).
/// Recurring occurrences are included unless [includeRecurring] is false; unplaced quota slots
/// never are. Oldest first.
List<PlannerItem> selectOverdue(
  Iterable<PlannerItem> items, {
  required LocalDate today,
  required int lookbackDays,
  bool includeRecurring = true,
}) {
  if (lookbackDays <= 0) return const [];
  final first = today.minusDays(lookbackDays);
  final out = <PlannerItem>[
    for (final i in items)
      if (!i.isBacklog &&
          i.isOpen &&
          !i.isQuotaSlot &&
          TrackingPolicy.of(i.trackingMode).canBeMissed &&
          (includeRecurring || !i.isRecurring) &&
          i.startLocal.date.isBefore(today) &&
          !i.startLocal.date.isBefore(first))
        i,
  ]..sort((a, b) {
    final c = a.startLocal.compareTo(b.startLocal);
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return out;
}
