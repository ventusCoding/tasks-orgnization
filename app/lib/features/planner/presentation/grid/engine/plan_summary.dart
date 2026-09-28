import 'package:collection/collection.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:meta/meta.dart';

// Week summary footer (T3.4.17) and day summary header (T3.5.12): pure aggregates of the plan of a
// range, defined like the Insights metric registry ([6.3]) for the same range:
// - planned = Σ planned minutes of timed, non-cancelled occurrences by planned start date
//   (capacity report PL-X-09/-10);
// - done / total = check & timer occurrences of the range that are done / not cancelled (PL-X-01
//   completion rate of a settled plan);
// - tracked = Σ tracked time; top categories by planned minutes (PL-X-12);
// - free = openings inside work hours (T3.7.04 finder).

@immutable
class PlanSummary {
  const PlanSummary({
    required this.plannedMinutes,
    required this.trackedMinutes,
    required this.done,
    required this.total,
    this.freeMinutes,
    this.topCategories = const [],
  });

  /// Aggregates [items] whose planned start falls in [range]. With [work], also the free minutes
  /// inside work hours (DST-aware through [elapsed]).
  factory PlanSummary.of(
    Iterable<PlannerItem> items,
    DayRange range, {
    FreeSlotOptions? work,
    ElapsedMinutes elapsed = wallMinutes,
    int topCount = 3,
  }) {
    var planned = 0;
    var trackedSeconds = 0;
    var done = 0;
    var total = 0;
    final byCategory = <String?, int>{};
    final inRange = <PlannerItem>[];
    for (final i in items) {
      if (i.isBacklog || !range.contains(i.startLocal.date)) continue;
      inRange.add(i);
      trackedSeconds += i.trackedSeconds ?? 0;
      if (i.status == OccurrenceStatus.cancelled) continue;
      if (!i.allDay) {
        planned += i.durationMinutes;
        byCategory[i.categoryId] = (byCategory[i.categoryId] ?? 0) + i.durationMinutes;
      }
      if (i.trackingMode != TrackingMode.event) {
        total++;
        if (i.status == OccurrenceStatus.done) done++;
      }
    }
    final top = byCategory.entries.sorted((a, b) => b.value.compareTo(a.value)).take(topCount);
    int? free;
    if (work != null) {
      final days = [for (var d = 0; d < range.days; d++) range.start.plusDays(d)];
      // Items starting before the range can still block its first morning.
      free = freeIntervals(
        items: items,
        days: days,
        options: FreeSlotOptions(window: work.window, workDays: work.workDays, minGapMinutes: 1),
        elapsed: elapsed,
      ).fold<int>(0, (sum, o) => sum + o.minutes);
    }
    return PlanSummary(
      plannedMinutes: planned,
      trackedMinutes: trackedSeconds ~/ 60,
      done: done,
      total: total,
      freeMinutes: free,
      topCategories: [for (final e in top) (e.key, e.value)],
    );
  }

  final int plannedMinutes;
  final int trackedMinutes;
  final int done;
  final int total;

  /// Free minutes inside work hours (null when not computed).
  final int? freeMinutes;

  /// (category id or null = uncategorized, planned minutes), largest first.
  final List<(String?, int)> topCategories;

  /// done ÷ total, null without countable items.
  double? get completion => total == 0 ? null : done / total;

  @override
  bool operator ==(Object other) =>
      other is PlanSummary &&
      other.plannedMinutes == plannedMinutes &&
      other.trackedMinutes == trackedMinutes &&
      other.done == done &&
      other.total == total &&
      other.freeMinutes == freeMinutes &&
      const ListEquality<(String?, int)>().equals(other.topCategories, topCategories);

  @override
  int get hashCode => Object.hash(plannedMinutes, trackedMinutes, done, total, freeMinutes, Object.hashAll(topCategories));

  @override
  String toString() => 'PlanSummary(planned $plannedMinutes, tracked $trackedMinutes, $done/$total, free $freeMinutes)';
}
