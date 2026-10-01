import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// A checklist item as shown in the focus view (tickable rows, T3.7.01) and the routine player
/// (steps, T3.7.07).
@immutable
class ChecklistStep {
  const ChecklistStep({required this.id, required this.text, required this.done, this.depth = 0, this.estimateMinutes});

  final String id;
  final String text;
  final bool done;

  /// Nesting level (0 = top-level).
  final int depth;

  /// Step duration. TODO(integration): `checklist_items.estimate_minutes` (T3.7.07) — until that
  /// column exists it is null and the routine splits the task duration equally.
  final int? estimateMinutes;

  @override
  bool operator ==(Object other) =>
      other is ChecklistStep &&
      other.id == id &&
      other.text == text &&
      other.done == done &&
      other.depth == depth &&
      other.estimateMinutes == estimateMinutes;

  @override
  int get hashCode => Object.hash(id, text, done, depth, estimateMinutes);
}

/// Which items of a checklist to read: [rootOnly] keeps top-level items (routine steps), otherwise
/// the whole tree in display order.
typedef StepsQuery = ({String checklistId, bool rootOnly});

/// Steps of a task's linked checklist (cancelled items skipped); null while loading.
final checklistStepsProvider = Provider.autoDispose.family<List<ChecklistStep>?, StepsQuery>((ref, q) {
  final tree = ref.watch(checklistTreeProvider(q.checklistId));
  if (tree == null) return null;
  return [
    for (final item in q.rootOnly ? tree.children(null) : tree.items)
      if (item.status != ItemStatus.cancelled && item.text.trim().isNotEmpty)
        ChecklistStep(id: item.id, text: item.text, done: item.status.isDone, depth: tree.depthOf(item.id)),
  ];
});

/// Mutations of checklist steps from planner views (through the checklists application API).
abstract interface class ChecklistStepActions {
  /// Completes or re-opens one item.
  Future<void> setDone(String checklistId, String itemId, {required bool done});

  /// Completes several items in one operation (routine summary).
  Future<void> completeMany(String checklistId, Iterable<String> itemIds);
}

class _ServiceChecklistStepActions implements ChecklistStepActions {
  _ServiceChecklistStepActions(this._ref);

  final Ref _ref;

  ChecklistService get _service => _ref.read(checklistServiceProvider);

  @override
  Future<void> setDone(String checklistId, String itemId, {required bool done}) async {
    await _service.changeStatus(checklistId, [itemId], done ? ItemStatus.completed : ItemStatus.todo);
  }

  @override
  Future<void> completeMany(String checklistId, Iterable<String> itemIds) async {
    final ids = itemIds.toList();
    if (ids.isEmpty) return;
    await _service.changeStatus(checklistId, ids, ItemStatus.completed);
  }
}

final checklistStepActionsProvider = Provider<ChecklistStepActions>(_ServiceChecklistStepActions.new);
