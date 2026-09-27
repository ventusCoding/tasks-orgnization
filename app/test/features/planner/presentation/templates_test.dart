import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Task templates (T3.1.20): "From template…" in the editor, and deleting a template.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));
  const editorList = ValueKey('task-editor-list');

  Future<String> seedTemplate(WidgetTester tester) async => (await tester.runAsync(() async {
    final result = await h.planner.saveAsTemplate(
      const Task(
        id: '',
        seriesId: '',
        title: 'Weekly review',
        durationMinutes: 50,
        priority: 3,
        trackingMode: TrackingMode.timer,
        notes: 'Inbox zero',
      ),
    );
    return result.taskId;
  }))!;

  Future<void> openNewEditor(WidgetTester tester) async {
    await pumpOpener(
      tester,
      h,
      (context) => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const TaskEditorScreen(initialStart: '2026-09-25T16:00')),
      ),
    );
    await openAndSettle(tester);
  }

  testWidgets('a new task from a template keeps the editor date and the template fields', (tester) async {
    final template = await seedTemplate(tester);
    await openNewEditor(tester);
    await tester.tap(key('task-editor-menu'));
    await pumpFor(tester);
    await tester.tap(find.text('From template…'));
    await settle(tester);
    await tester.tap(key('template-$template'));
    await settle(tester);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);

    final created = (await tester.runAsync(h.liveTasks))!.where((t) => !t.isTemplate).single;
    expect(created.id, isNot(template));
    expect(created.title, 'Weekly review');
    expect(created.startLocal, ldt('2026-09-25T16:00'));
    expect(created.durationMinutes, 50);
    expect(created.priority, 3);
    expect(created.trackingMode, TrackingMode.timer);
    expect(created.notes, 'Inbox zero');
    final kept = (await tester.runAsync(() => h.task(template)))!;
    expect(kept.isTemplate, isTrue, reason: 'the template itself is unchanged');
  });

  testWidgets('templates can be deleted from the list', (tester) async {
    final template = await seedTemplate(tester);
    await openNewEditor(tester);
    await tester.tap(key('task-editor-menu'));
    await pumpFor(tester);
    await tester.tap(find.text('From template…'));
    await settle(tester);
    await tester.tap(find.descendant(of: key('template-$template'), matching: find.byIcon(Icons.delete_outline)));
    await settle(tester);
    expect(key('templates-empty'), findsOneWidget);
    expect(await tester.runAsync(() => h.task(template)), isNull);
  });
}
