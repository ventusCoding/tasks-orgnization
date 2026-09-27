import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:meta/meta.dart';

/// What the Now / Next card shows (T8.1.03).
@immutable
class NowNext {
  const NowNext({this.current, this.overlapping = 0, this.next});

  static const none = NowNext();

  /// The occurrence in progress now (the one that started last when several overlap).
  final PlannerItem? current;

  /// How many other occurrences are in progress at the same time ("+1 overlapping").
  final int overlapping;

  /// The next occurrence that has not started yet.
  final PlannerItem? next;

  bool get isEmpty => current == null && next == null;

  /// Elapsed share of [current] at [nowUtc] (0…1).
  double progressAt(DateTime nowUtc) {
    final c = current;
    if (c == null) return 0;
    final total = c.endUtc.difference(c.startUtc).inMilliseconds;
    if (total <= 0) return 1;
    return (nowUtc.difference(c.startUtc).inMilliseconds / total).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is NowNext && other.current == current && other.overlapping == overlapping && other.next == next;

  @override
  int get hashCode => Object.hash(current, overlapping, next);

  @override
  String toString() => 'NowNext(current: $current +$overlapping, next: $next)';
}

bool _isOpen(PlannerItem i) => i.status == OccurrenceStatus.scheduled || i.status == OccurrenceStatus.inProgress;

/// Selects the current and next occurrences at [nowUtc] (pure, T8.1.03).
///
/// - All-day and backlog items are never "now" or "next".
/// - Current = an open occurrence with `start ≤ now < end` (an item ending exactly now is over),
///   or a timer running now (`inProgress`) whatever its planned window. Among several, the one
///   that started last wins and the others are counted as [NowNext.overlapping].
/// - Next = the earliest open occurrence starting after now (ties: priority, then title).
NowNext selectNowNext(Iterable<PlannerItem> items, DateTime nowUtc) {
  final running = <PlannerItem>[];
  PlannerItem? next;
  for (final i in items) {
    if (i.allDay || i.isBacklog || !_isOpen(i)) continue;
    final inWindow = !nowUtc.isBefore(i.startUtc) && nowUtc.isBefore(i.endUtc);
    if (inWindow || i.status == OccurrenceStatus.inProgress) {
      running.add(i);
      continue;
    }
    if (i.startUtc.isAfter(nowUtc) && (next == null || _earlier(i, next))) next = i;
  }
  if (running.isEmpty) return NowNext(next: next);
  running.sort((a, b) {
    // Started last first; a running timer beats a merely scheduled overlap at equal starts.
    final c = b.startUtc.compareTo(a.startUtc);
    if (c != 0) return c;
    if (a.status != b.status) return a.status == OccurrenceStatus.inProgress ? -1 : 1;
    final p = b.priority.compareTo(a.priority);
    return p != 0 ? p : a.key.compareTo(b.key);
  });
  return NowNext(current: running.first, overlapping: running.length - 1, next: next);
}

bool _earlier(PlannerItem a, PlannerItem b) {
  final c = a.startUtc.compareTo(b.startUtc);
  if (c != 0) return c < 0;
  final p = b.priority.compareTo(a.priority);
  if (p != 0) return p < 0;
  final t = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return t != 0 ? t < 0 : a.key.compareTo(b.key) < 0;
}
