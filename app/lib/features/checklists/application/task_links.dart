import 'package:everslot/core/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
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

  /// *Schedule as task* for one item (T3.1.21): an unscheduled task titled like the item and linked
  /// to it (`tasks.linked_item_id`). Returns the new task id.
  Future<String> scheduleItem(ChecklistItem item, {required String fallbackTitle}) async {
    final text = item.text.trim().split('\n').first.trim();
    final result = await _ref
        .read(plannerServiceProvider)
        .scheduleChecklistItem(item.id, title: text.isEmpty ? fallbackTitle : text);
    return result.taskId;
  }

  // Bidirectional completion prompts (T3.1.21) ------------------------------------------------

  /// After an occurrence of [taskId] was marked done: its linked item when it is still open
  /// (the caller offers to complete it), else null.
  Future<ChecklistItem?> itemToCompleteAfterTask(String taskId) async {
    final task = await _ref.read(plannerServiceProvider).task(taskId);
    final itemId = task?.linkedItemId;
    if (itemId == null) return null;
    final item = await _ref.read(checklistItemsRepositoryProvider).liveById(itemId);
    return item != null && item.status.isOpen ? item : null;
  }

  /// After item [itemId] was completed: open occurrences of the one-off tasks scheduling it (the
  /// caller offers to mark them done). Recurring and unscheduled tasks are never offered.
  Future<List<PlannerItem>> tasksToCompleteAfterItem(String itemId) async {
    final planner = _ref.read(plannerServiceProvider);
    final result = <PlannerItem>[];
    for (final t in await planner.tasksForItem(itemId)) {
      final start = t.startLocal;
      if (t.isRecurring || start == null) continue;
      for (final o in await planner.openItemsOfDay(start.date)) {
        if (o.taskId == t.id && o.isOpen) result.add(o);
      }
    }
    return result;
  }

  /// Completes [item] (accepted prompt): one status change, cause `linked`.
  Future<void> completeItem(ChecklistItem item) async => _ref
      .read(checklistServiceProvider)
      .changeStatus(item.checklistId, [item.id], ItemStatus.completed, setNote: false, cause: 'linked');

  /// Marks the offered occurrences done (accepted prompt).
  Future<void> completeTasks(List<PlannerItem> items) async {
    final planner = _ref.read(plannerServiceProvider);
    for (final i in items) {
      await planner.setStatus(i, OccurrenceStatus.done);
    }
  }
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
