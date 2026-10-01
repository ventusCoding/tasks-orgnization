import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Field edits of a backlog task (T3.7.03); null = unchanged, `clear*` = set to null.
@immutable
class BacklogEdit {
  const BacklogEdit({
    this.title,
    this.estimateMinutes,
    this.priority,
    this.deadline,
    this.categoryId,
    this.clearEstimate = false,
    this.clearDeadline = false,
    this.clearCategory = false,
  });

  final String? title;
  final int? estimateMinutes;
  final int? priority;
  final LocalDateTime? deadline;
  final String? categoryId;
  final bool clearEstimate;
  final bool clearDeadline;
  final bool clearCategory;

  Task applyTo(Task t) => t.copyWith(
    title: title,
    estimateMinutes: clearEstimate ? null : (estimateMinutes ?? t.estimateMinutes),
    priority: priority,
    deadlineLocal: clearDeadline ? null : (deadline ?? t.deadlineLocal),
    categoryId: clearCategory ? null : (categoryId ?? t.categoryId),
  );
}

/// Planner mutations the views need beyond the CONTRACT's [PlannerActions] (tile menu *Delete* /
/// *Duplicate*, manual order of untimed items and the backlog, unscheduling, timers). Thin wrappers
/// over planner-core's application API; every call is one undoable operation.
///
/// TODO(integration): fold into planner-core's `PlannerActions` when the contract grows.
abstract interface class PlannerViewActions {
  /// Deletes the task ([EditScope.thisOccurrence] cancels one occurrence of a series).
  Future<void> delete(PlannerItem item, {EditScope scope = EditScope.allOccurrences});

  /// Copies the task (one occurrence of a series becomes a one-off). Returns the new task id.
  Future<String?> duplicate(PlannerItem item);

  /// Pastes a copied item as a one-off task starting at [start] (Ctrl/Cmd + V, T3.1.19).
  /// Returns the new task id.
  Future<String?> paste(PlannerItem item, LocalDateTime start);

  /// Manual order between two neighbours' `manual_sort_key`s (backlog, untimed items of a day).
  Future<void> reorder(PlannerItem item, {String? afterKey, String? beforeKey});

  /// Moves a one-off task back to the backlog (throws for recurring tasks); [source] is logged on
  /// the `unscheduled` event (`backlog` from the drawer).
  Future<void> unschedule(PlannerItem item, {String source = 'menu'});

  Future<void> startTimer(PlannerItem item);

  Future<void> pauseTimer(PlannerItem item);

  Future<void> stopTimer(PlannerItem item);

  /// Creates an unscheduled (backlog) task (T3.7.03). Returns the new task id.
  Future<String?> createBacklog(String title);

  /// Edits a backlog task's estimate, priority, deadline, category or title (T3.7.03).
  Future<void> editBacklog(PlannerItem item, BacklogEdit edit);
}

class _ServicePlannerViewActions implements PlannerViewActions {
  _ServicePlannerViewActions(this._ref);

  final Ref _ref;

  PlannerService get _service => _ref.read(plannerServiceProvider);

  void _push(String label, OpRecord record) => _ref.read(undoStackProvider).push(label, record);

  @override
  Future<void> delete(PlannerItem item, {EditScope scope = EditScope.allOccurrences}) async {
    await _service.delete(item, scope: item.isRecurring && !item.isBacklog ? scope : EditScope.allOccurrences);
  }

  @override
  Future<String?> duplicate(PlannerItem item) async {
    final result = await _ref
        .read(tasksRepositoryProvider)
        .duplicate(
          item.taskId,
          asOneOff: item.isRecurring,
          occurrenceKey: item.isRecurring && !item.isBacklog ? item.occurrenceKey : null,
        );
    _push(_ref.read(plannerL10nProvider).tasksCreated, result.record);
    return result.newTaskId;
  }

  @override
  Future<String?> paste(PlannerItem item, LocalDateTime start) async => (await _service.pasteAt(item, start)).newTaskId;

  @override
  Future<void> reorder(PlannerItem item, {String? afterKey, String? beforeKey}) async {
    final record = await _ref
        .read(tasksRepositoryProvider)
        .moveInBacklog(item.taskId, afterKey: afterKey, beforeKey: beforeKey);
    _push(_ref.read(plannerL10nProvider).tasksMoved, record);
  }

  @override
  Future<void> unschedule(PlannerItem item, {String source = 'menu'}) async {
    final record = await _ref.read(tasksRepositoryProvider).unschedule(item.taskId, source: source);
    _push(_ref.read(plannerL10nProvider).tasksMoved, record);
  }

  @override
  Future<void> startTimer(PlannerItem item) => _service.startTimer(item);

  @override
  Future<void> pauseTimer(PlannerItem item) => _service.pauseTimer(item);

  @override
  Future<void> stopTimer(PlannerItem item) => _service.stopTimer(item);

  @override
  Future<String?> createBacklog(String title) async => (await _service.createTask(
    Task(id: '', seriesId: '', title: title),
    source: 'backlog',
  )).taskId;

  @override
  Future<void> editBacklog(PlannerItem item, BacklogEdit edit) async {
    final task = await _service.task(item.taskId);
    if (task == null) return;
    await _service.updateTask(edit.applyTo(task), source: 'backlog');
  }
}

/// Extra planner mutations for views (see [PlannerViewActions]).
final plannerViewActionsProvider = Provider<PlannerViewActions>(_ServicePlannerViewActions.new);
