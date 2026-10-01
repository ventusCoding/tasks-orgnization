import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Which occurrence the Now / Next focus view shows (T3.7.01) — pure, wall-clock based.

/// The focused occurrence, what follows it and the remaining candidates.
@immutable
class FocusSelection {
  const FocusSelection({this.current, this.next, this.upcoming = const []});

  /// Nothing is happening or pinned.
  static const empty = FocusSelection();

  /// Shown large: the running item, else the one covering [now] (or the pinned one).
  final PlannerItem? current;

  /// The next item to start after [current] (or after now).
  final PlannerItem? next;

  /// Every open timed item still to start, earliest first (the *Next* button walks them).
  final List<PlannerItem> upcoming;
}

/// Open, timed, not backlog: items that can be focused.
bool isFocusable(PlannerItem item) => !item.allDay && !item.isBacklog && item.durationMinutes > 0 && item.isOpen;

/// Picks the focus of [items] at wall-clock [now]:
///
/// 1. a [pinnedKey] item (the user pressed *Next*), when it is still open;
/// 2. an item whose timer is running / status is in progress — the latest started;
/// 3. an item covering [now] — the latest started, then the higher priority;
/// 4. nothing.
///
/// `missed` items are past their end and never current; [FocusSelection.next] is the earliest open
/// item starting after the current one (or after [now]).
FocusSelection selectFocus(Iterable<PlannerItem> items, LocalDateTime now, {String? pinnedKey}) {
  final candidates = [
    for (final i in items)
      if (isFocusable(i)) i,
  ]..sort(_byStart);

  PlannerItem? current;
  if (pinnedKey != null) {
    for (final i in candidates) {
      if (i.key == pinnedKey) current = i;
    }
  }
  current ??= _latest(candidates.where((i) => i.status == OccurrenceStatus.inProgress));
  current ??= _latest(
    candidates.where(
      (i) => !i.startLocal.isAfter(now) && i.endLocal.isAfter(now) && i.status != OccurrenceStatus.missed,
    ),
  );

  final after = current == null ? now : (current.startLocal.isAfter(now) ? current.startLocal : now);
  final upcoming = [
    for (final i in candidates)
      if (i.startLocal.isAfter(after) && i.key != current?.key) i,
  ];
  return FocusSelection(current: current, next: upcoming.isEmpty ? null : upcoming.first, upcoming: upcoming);
}

int _byStart(PlannerItem a, PlannerItem b) {
  final s = a.startLocal.compareTo(b.startLocal);
  if (s != 0) return s;
  final p = b.priority.compareTo(a.priority);
  return p != 0 ? p : a.title.compareTo(b.title);
}

/// The item that started last (ties: higher priority).
PlannerItem? _latest(Iterable<PlannerItem> items) {
  PlannerItem? best;
  for (final i in items) {
    if (best == null) {
      best = i;
      continue;
    }
    final c = i.startLocal.compareTo(best.startLocal);
    if (c > 0 || (c == 0 && i.priority > best.priority)) best = i;
  }
  return best;
}

/// Time left until [end] (negative once the planned end has passed) as a duration.
Duration timeLeft(DateTime endUtc, DateTime nowUtc) => endUtc.difference(nowUtc);

/// Fraction of the planned window that is still ahead: 1 before the start, 0 at the end (never
/// negative, so overtime keeps an empty ring).
double remainingFraction(DateTime startUtc, DateTime endUtc, DateTime nowUtc) {
  final total = endUtc.difference(startUtc).inMilliseconds;
  if (total <= 0) return 0;
  return (endUtc.difference(nowUtc).inMilliseconds / total).clamp(0.0, 1.0);
}
