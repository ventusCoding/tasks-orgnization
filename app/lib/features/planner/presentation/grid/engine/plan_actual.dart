import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Plan vs actual (T3.7.06) — pure: tracked blocks in wall-clock time matched with planned
// occurrences, and the variance of each plan.

/// How reality differed from a planned occurrence (or a block without a plan).
enum Variance { onPlan, startedLate, overran, notDone, unplanned }

/// One tracked interval (a time entry) in the display zone's wall clock.
@immutable
class ActualBlock {
  const ActualBlock({
    required this.entryId,
    required this.taskId,
    required this.start,
    required this.end,
    this.occurrenceKey,
    this.running = false,
  });

  final String entryId;
  final String taskId;
  final String? occurrenceKey;
  final LocalDateTime start;

  /// End (now for a running entry).
  final LocalDateTime end;
  final bool running;

  int get minutes => start.minutesUntil(end);

  @override
  String toString() => 'Actual($taskId $occurrenceKey $start → $end)';
}

/// Tracked blocks of [planned]: entries of its task and occurrence (entries without an occurrence
/// key belong to one-off tasks).
List<ActualBlock> blocksOf(PlannerItem planned, Iterable<ActualBlock> blocks) => [
  for (final b in blocks)
    if (b.taskId == planned.taskId && (b.occurrenceKey == null || b.occurrenceKey == planned.occurrenceKey)) b,
];

/// Blocks that belong to no planned occurrence of [planned] (work that wasn't on the plan).
List<ActualBlock> unplannedBlocks(Iterable<ActualBlock> blocks, Iterable<PlannerItem> planned) {
  final keys = {for (final p in planned) '${p.taskId}|${p.occurrenceKey}'};
  final oneOffTasks = {
    for (final p in planned)
      if (!p.isRecurring) p.taskId,
  };
  return [
    for (final b in blocks)
      if (!keys.contains('${b.taskId}|${b.occurrenceKey}') &&
          !(b.occurrenceKey == null && oneOffTasks.contains(b.taskId)))
        b,
  ];
}

/// Variance of a planned occurrence given its tracked [blocks] at [now] (wall clock):
/// - `startedLate`: the first block starts more than [tolerance] minutes after the planned start;
/// - `overran`: the last block ends, or the tracked total exceeds the plan, by more than
///   [tolerance] minutes;
/// - `notDone`: the planned end has passed with nothing tracked and the item isn't done / skipped
///   / cancelled;
/// - `onPlan` otherwise (several can apply: late and overran).
Set<Variance> classifyVariance(PlannerItem planned, List<ActualBlock> blocks, LocalDateTime now, {int tolerance = 5}) {
  final out = <Variance>{};
  if (blocks.isEmpty) {
    final finished =
        planned.isDone || planned.status == OccurrenceStatus.skipped || planned.status == OccurrenceStatus.cancelled;
    if (!planned.allDay && !finished && !planned.endLocal.isAfter(now)) out.add(Variance.notDone);
    return out.isEmpty ? {Variance.onPlan} : out;
  }
  final sorted = [...blocks]..sort((a, b) => a.start.compareTo(b.start));
  if (planned.startLocal.minutesUntil(sorted.first.start) > tolerance) out.add(Variance.startedLate);
  final lastEnd = sorted.map((b) => b.end).reduce((a, b) => a.isAfter(b) ? a : b);
  final total = sorted.fold<int>(0, (a, b) => a + b.minutes);
  if (planned.endLocal.minutesUntil(lastEnd) > tolerance || total - planned.durationMinutes > tolerance) {
    out.add(Variance.overran);
  }
  return out.isEmpty ? {Variance.onPlan} : out;
}
