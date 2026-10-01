import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/presentation/task_detail_screen.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Tags on tasks (T3.1.17): inline create in the new-task editor, saved with the task in one
/// operation (deterministic `entity_tags` ids), chips in the details view.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));
  const editorList = ValueKey('task-editor-list');

  testWidgets('create a tag inline, save: one link with the deterministic id, one undo', (tester) async {
    await pumpOpener(
      tester,
      h,
      (context) =>
          Navigator.of(context)
              .push<void>(MaterialPageRoute(builder: (_) => const TaskEditorScreen(initialStart: '2026-09-22T09:00'))),
    );
    await openAndSettle(tester);
    await tester.enterText(key('task-title'), 'Report');
    await tapIn(tester, key('task-tags-add'), scrollKey: editorList);
    await tester.enterText(find.widgetWithText(TextField, 'Search or create a tag'), 'work');
    await pumpFor(tester);
    await tester.tap(find.text('Create tag “work”'));
    await settle(tester);
    await tester.tap(find.text('Done').last);
    await settle(tester);
    expect(find.text('work'), findsWidgets);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);

    final (taskId, tagId, links) = (await tester.runAsync(() async {
      final task = (await h.liveTasks()).single;
      final tag = (await h.read(tagsRepositoryProvider).all()).single;
      final rows = await h.db
          .customSelect(
            "SELECT id FROM entity_tags WHERE deleted_at IS NULL AND entity_type = 'task' AND entity_id = ?",
            variables: [Variable<String>(task.id)],
          )
          .get();
      return (task.id, tag.id, [for (final r in rows) r.read<String>('id')]);
    }))!;
    expect(links, [Ids.entityTag(tagId, 'task', taskId)]);

    // The task and its tag link are one operation: one undo removes both.
    await tester.runAsync(() => h.read(undoStackProvider).undo());
    final after = (await tester.runAsync(() async {
      final rows = await h.db.customSelect('SELECT id FROM entity_tags WHERE deleted_at IS NULL').get();
      return (await h.liveTasks(), rows.length);
    }))!;
    expect(after.$1, isEmpty);
    expect(after.$2, 0);
  });

  testWidgets('details show the task tags', (tester) async {
    final id = (await tester.runAsync(() async {
      final id = await h.createTask(title: 'Report', start: '2026-09-22T09:00');
      final tags = h.read(tagsRepositoryProvider);
      final tag = await tags.create(name: 'urgent');
      await tags.attach(tag.id, 'task', id);
      return id;
    }))!;
    await pumpOpener(
      tester,
      h,
      (context) => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id))),
    );
    await openAndSettle(tester);
    expect(find.text('urgent'), findsOneWidget);
  });
}
