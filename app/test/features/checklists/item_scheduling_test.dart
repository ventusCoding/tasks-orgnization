// Schedule a checklist item as a task (T3.1.21): the link lives on `tasks.linked_item_id`; completing
// either side offers to complete the other (bidirectional prompt logic, real data layer).
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/task_links.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  final today = LocalDate(2026, 9, 22); // harness clock: 22 Sep 2026 09:00 UTC

  Future<ChecklistItem> newItem(String text) async {
    final list = await h
        .read(checklistsRepositoryProvider)
        .create(
          title: 'Home',
          items: [NodeSpec(text: text)],
        );
    final items = await h.read(checklistItemsRepositoryProvider).items(list.id);
    return items.single;
  }

  Future<T> until<T>(ProviderListenable<T> provider, bool Function(T value) ok) async {
    final sub = h.container.listen(provider, (_, _) {});
    try {
      for (var i = 0; i < 400; i++) {
        final v = h.read(provider);
        if (ok(v)) return v;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('condition never met');
    } finally {
      sub.close();
    }
  }

  Future<Task> schedule(String taskId, LocalDateTime start, {RecurrenceRule? recurrence}) async {
    final planner = h.read(plannerServiceProvider);
    final task = (await planner.task(taskId))!;
    await planner.updateTask(task.copyWith(startLocal: start, durationMinutes: 30, recurrence: recurrence));
    return (await planner.task(taskId))!;
  }

  Future<PlannerItem> occurrenceOf(String taskId, LocalDate day) async =>
      (await h.read(plannerServiceProvider).openItemsOfDay(day)).firstWhere((i) => i.taskId == taskId);

  test('Schedule as task creates an unscheduled task titled like the item and linked to it', () async {
    final item = await newItem('Fix the tap\nwith the new washer');
    final links = h.read(checklistTaskLinksProvider);
    final taskId = await links.scheduleItem(item, fallbackTitle: 'Untitled');
    final task = (await h.read(plannerServiceProvider).task(taskId))!;
    expect(task.title, 'Fix the tap', reason: 'first line of the item');
    expect(task.linkedItemId, item.id);
    expect(task.isUnscheduled, isTrue);
    final byItem = await until(itemTasksProvider, (v) => v.value?.containsKey(item.id) ?? false);
    expect(byItem.value![item.id]!.id, taskId);
  });

  test('task done → offer the open item; accepting completes it; no offer once completed', () async {
    final item = await newItem('Call the plumber');
    final links = h.read(checklistTaskLinksProvider);
    final taskId = await links.scheduleItem(item, fallbackTitle: 'Untitled');
    await schedule(taskId, today.atTime(LocalTime(14, 0)));
    await h.read(plannerServiceProvider).setStatus(await occurrenceOf(taskId, today), OccurrenceStatus.done);

    final offered = await links.itemToCompleteAfterTask(taskId);
    expect(offered?.id, item.id);
    await links.completeItem(offered!);
    final stored = await h.read(checklistItemsRepositoryProvider).liveById(item.id);
    expect(stored!.status, ItemStatus.completed);
    expect(await links.itemToCompleteAfterTask(taskId), isNull, reason: 'already completed');
  });

  test('tasks without a linked item never offer', () async {
    final planner = h.read(plannerServiceProvider);
    final plain = (await planner.createTask(
      const Task(id: '', seriesId: '', title: 'Plain'),
      source: 'test',
    )).taskId;
    expect(await h.read(checklistTaskLinksProvider).itemToCompleteAfterTask(plain), isNull);
  });

  test('item completed → offer the open one-off occurrence; accepting marks it done', () async {
    final item = await newItem('Book the garage');
    final links = h.read(checklistTaskLinksProvider);
    final taskId = await links.scheduleItem(item, fallbackTitle: 'Untitled');
    expect(await links.tasksToCompleteAfterItem(item.id), isEmpty, reason: 'unscheduled tasks are not offered');

    await schedule(taskId, today.atTime(LocalTime(16, 0)));
    final offered = await links.tasksToCompleteAfterItem(item.id);
    expect(offered.single.taskId, taskId);
    await links.completeTasks(offered);
    expect(await links.tasksToCompleteAfterItem(item.id), isEmpty, reason: 'the occurrence is done now');
    expect(await h.read(plannerServiceProvider).openItemsOfDay(today), isEmpty);
  });

  test('recurring tasks are never offered from the item side', () async {
    final item = await newItem('Water plants');
    final links = h.read(checklistTaskLinksProvider);
    final taskId = await links.scheduleItem(item, fallbackTitle: 'Untitled');
    await schedule(taskId, today.atTime(LocalTime(8, 0)), recurrence: RecurrenceRule());
    expect(await links.tasksToCompleteAfterItem(item.id), isEmpty);
  });
}
