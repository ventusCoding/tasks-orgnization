import 'package:everslot/features/planner/domain/occurrence_resolver.dart' show QuotaPeriodKey;
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show PeriodUnit;
import 'package:meta/meta.dart';

/// Progress of one quota task in one period ("Run · 1/3 this week", T3.2.16).
@immutable
class QuotaSummary {
  const QuotaSummary({
    required this.taskId,
    required this.title,
    required this.periodKey,
    required this.unit,
    required this.done,
    required this.target,
  });

  final String taskId;
  final String title;

  /// `week:2026-09-21`.
  final String periodKey;
  final PeriodUnit unit;
  final int done;
  final int target;

  /// Every slot of the period is done: "done for this week".
  bool get complete => done >= target;

  @override
  bool operator ==(Object other) =>
      other is QuotaSummary &&
      other.taskId == taskId &&
      other.title == title &&
      other.periodKey == periodKey &&
      other.unit == unit &&
      other.done == done &&
      other.target == target;

  @override
  int get hashCode => Object.hash(taskId, title, periodKey, unit, done, target);

  @override
  String toString() => 'QuotaSummary($title $periodKey $done/$target)';
}

/// Groups the quota slots of [items] by task and period (first-seen order). The resolver emits
/// every slot of a period — placed or not, open or done — so the target is the slot count and
/// completing any slot counts toward the period.
List<QuotaSummary> quotaSummaries(Iterable<PlannerItem> items) {
  final groups = <String, List<PlannerItem>>{};
  for (final i in items) {
    final period = i.quotaPeriodKey;
    if (!i.isQuotaSlot || period == null) continue;
    (groups['${i.taskId}|$period'] ??= []).add(i);
  }
  return [
    for (final slots in groups.values)
      if (QuotaPeriodKey.parse(slots.first.quotaPeriodKey!) case final period?)
        QuotaSummary(
          taskId: slots.first.taskId,
          title: slots.first.title,
          periodKey: period.key,
          unit: period.unit,
          done: slots.where((s) => s.status == OccurrenceStatus.done).length,
          target: {for (final s in slots) s.occurrenceKey}.length,
        ),
  ];
}
