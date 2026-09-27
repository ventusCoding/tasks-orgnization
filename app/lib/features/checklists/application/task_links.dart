import 'package:everslot/core/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// A planner task linked to a checklist or offered for linking (T4.5.12).
@immutable
class LinkedTask {
  const LinkedTask({required this.id, required this.title, this.linkedChecklistId});

  final String id;
  final String title;
  final String? linkedChecklistId;

  @override
  bool operator ==(Object other) =>
      other is LinkedTask && other.id == id && other.title == title && other.linkedChecklistId == linkedChecklistId;

  @override
  int get hashCode => Object.hash(id, title, linkedChecklistId);
}

/// Checklist ↔ planner task links through the planner's application API (T4.5.12). The link is
/// stored only on `tasks.linked_checklist_id`; nothing is duplicated on the checklist.
class ChecklistTaskLinks {
  ChecklistTaskLinks(this._ref);

  final Ref _ref;

  /// *Schedule as task*: an unscheduled (backlog) task titled like the list and linked to it.
  /// Returns the new task id (the caller opens the task editor to schedule it).
  Future<String> scheduleAsTask(Checklist checklist, {required String fallbackTitle}) async {
    final title = checklist.title.trim().isEmpty ? fallbackTitle : checklist.title.trim();
    final result = await _ref
        .read(plannerServiceProvider)
        .createTask(
          Task(id: '', seriesId: '', title: title, linkedChecklistId: checklist.id),
          source: 'checklist',
        );
    return result.taskId;
  }

  /// *Link to existing task…* (replaces the task's previous link, if any).
  Future<void> link(String taskId, String checklistId) =>
      _ref.read(plannerServiceProvider).linkChecklist(taskId, checklistId);

  Future<void> unlink(String taskId) => _ref.read(plannerServiceProvider).linkChecklist(taskId, null);
}

final checklistTaskLinksProvider = Provider<ChecklistTaskLinks>(ChecklistTaskLinks.new);

/// Days of upcoming occurrences scanned for tasks (with the backlog).
const linkedTaskHorizonDays = 60;

/// Backlog tasks plus tasks with an occurrence in the next [linkedTaskHorizonDays] days, one entry
/// per task (in planner order).
///
/// TODO(integration): replace with a planner query by `linked_checklist_id` / a task search once
/// the planner exposes one — tasks whose only occurrences are further away are not listed yet.
final plannerTasksForLinksProvider = Provider.autoDispose<List<LinkedTask>>((ref) {
  final backlog = ref.watch(backlogItemsProvider).value ?? const <PlannerItem>[];
  final now = ref.read(clockProvider).nowUtc();
  final zone = ref.watch(deviceZoneProvider);
  final today = ref.read(zoneResolverProvider).toLocal(now, zone).date;
  final upcoming = ref.watch(plannerItemsProvider(DayRange(today, linkedTaskHorizonDays))).value ?? const [];
  final seen = <String>{};
  return [
    for (final item in [...backlog, ...upcoming])
      if (seen.add(item.taskId))
        LinkedTask(id: item.taskId, title: item.title, linkedChecklistId: item.linkedChecklistId),
  ];
});

/// Tasks linked to [checklistId] (header chips).
final linkedTasksProvider = Provider.autoDispose.family<List<LinkedTask>, String>(
  (ref, checklistId) => [
    for (final t in ref.watch(plannerTasksForLinksProvider))
      if (t.linkedChecklistId == checklistId) t,
  ],
);
