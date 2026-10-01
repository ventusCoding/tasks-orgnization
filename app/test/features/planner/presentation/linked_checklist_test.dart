import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/task_detail_screen.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Linked checklist (T3.1.16): progress provider, link / new / unlink in the editor, progress
/// in the details view.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));
  const editorList = ValueKey('task-editor-list');

  /// "Trip": Documents (Visa ✓, Passport), Socks ✓, Hat (cancelled) → leaves 2/3 done.
  Future<String> seedChecklist() async {
    final created = await h
        .read(checklistsRepositoryProvider)
        .create(
          title: 'Trip',
          items: const [
            NodeSpec(
              text: 'Documents',
              children: [
                NodeSpec(text: 'Visa'),
                NodeSpec(text: 'Passport'),
              ],
            ),
            NodeSpec(text: 'Socks'),
            NodeSpec(text: 'Hat'),
          ],
        );
    final items = await h.read(checklistItemsRepositoryProvider).items(created.id);
    String id(String text) => items.firstWhere((i) => i.text == text).id;
    final service = h.read(checklistServiceProvider);
    await service.changeStatus(created.id, [id('Visa'), id('Socks')], ItemStatus.completed);
    await service.changeStatus(created.id, [id('Hat')], ItemStatus.cancelled);
    return created.id;
  }

  Future<List<Task>> tasks(WidgetTester tester) async => (await tester.runAsync(h.liveTasks))!;

  test('progress counts leaf items, excluding cancelled ones', () async {
    final id = await seedChecklist();
    final info = await h.read(plannerQueriesProvider).watchChecklist(id).first;
    expect(info!.title, 'Trip');
    expect(info.completed, 2);
    expect(info.total, 3);
    expect(info.progress, closeTo(2 / 3, 1e-9));
    expect(await h.read(plannerQueriesProvider).watchChecklists().first, hasLength(1));
  });

  testWidgets('link an existing checklist, then unlink it', (tester) async {
    final checklist = (await tester.runAsync(seedChecklist))!;
    await pumpOpener(
      tester,
      h,
      (context) =>
          Navigator.of(context)
              .push<void>(MaterialPageRoute(builder: (_) => const TaskEditorScreen(initialStart: '2026-09-22T09:00'))),
    );
    await openAndSettle(tester);
    await tester.enterText(key('task-title'), 'Pack');
    await tapIn(tester, key('task-checklist'), scrollKey: editorList);
    await tester.tap(key('checklist-$checklist'));
    await settle(tester);
    expect(find.textContaining('2/3 done'), findsOneWidget);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);
    final task = (await tasks(tester)).single;
    expect(task.linkedChecklistId, checklist);
  });

  testWidgets('New checklist creates one named after the task and links it', (tester) async {
    await pumpOpener(
      tester,
      h,
      (context) =>
          Navigator.of(context)
              .push<void>(MaterialPageRoute(builder: (_) => const TaskEditorScreen(initialStart: '2026-09-22T09:00'))),
    );
    await openAndSettle(tester);
    await tester.enterText(key('task-title'), 'Groceries');
    await tapIn(tester, key('task-checklist'), scrollKey: editorList);
    await tester.tap(key('checklist-new'));
    await settle(tester);
    expect(find.text('Checklist name'), findsOneWidget);
    await tester.tap(find.text('Save').last);
    await settle(tester);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);
    final task = (await tasks(tester)).single;
    final lists = (await tester.runAsync(() => h.read(plannerQueriesProvider).watchChecklists().first))!;
    expect(lists.single.title, 'Groceries');
    expect(task.linkedChecklistId, lists.single.id);

    // Unlink from the editor of the saved task (saving closed the first editor).
    expect(find.byType(TaskEditorScreen), findsNothing);
    await pumpOpener(
      tester,
      h,
      (context) =>
          Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TaskEditorScreen(taskId: task.id))),
    );
    await openAndSettle(tester);
    // Let the "created" snackbar (with its Undo button) expire first.
    await pumpFor(tester, const Duration(seconds: 6));
    final scrollable = find.descendant(of: find.byKey(editorList), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(key('task-checklist'), 150, scrollable: scrollable);
    await tester.ensureVisible(find.byTooltip('Unlink'));
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Unlink'));
    await pumpFor(tester);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);
    expect((await tasks(tester)).single.linkedChecklistId, isNull);
  });

  testWidgets('details show the linked checklist progress', (tester) async {
    final id = (await tester.runAsync(() async {
      final checklist = await seedChecklist();
      final result = await h.tasks.create(
        Task(
          id: '',
          seriesId: '',
          title: 'Pack',
          startLocal: ldt('2026-09-22T09:00'),
          durationMinutes: 30,
          linkedChecklistId: checklist,
        ),
      );
      return result.taskId;
    }))!;
    await pumpOpener(
      tester,
      h,
      (context) => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id))),
    );
    await openAndSettle(tester);
    final scrollable = find
        .descendant(of: find.byKey(const ValueKey('detail-list')), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(key('detail-checklist'), 150, scrollable: scrollable);
    expect(find.descendant(of: key('detail-checklist'), matching: find.text('Trip')), findsOneWidget);
    expect(find.descendant(of: key('detail-checklist'), matching: find.text('2/3 done')), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.descendant(of: key('detail-checklist'), matching: find.byType(LinearProgressIndicator)),
    );
    expect(bar.value, closeTo(2 / 3, 1e-9));
  });
}
