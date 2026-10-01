import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/shared/activity/application/activity_providers.dart';
import 'package:everslot/shared/shortcuts/presentation/global_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// Undo/redo command stack (T2.3.06).
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<List<String>> categoryNames() async => [
    for (final c in await h.read(categoriesRepositoryProvider).all()) c.name,
  ];

  test('undo reverts a command, redo re-applies it', () async {
    final stack = h.read(undoStackProvider);
    final repo = h.read(categoriesRepositoryProvider);
    stack.push('Create Work', await repo.create(name: 'Work', color: 1));
    expect(await categoryNames(), ['Work']);
    expect(stack.undoLabel, 'Create Work');

    expect(await stack.undo(), isTrue);
    expect(await categoryNames(), isEmpty);
    expect(stack.canUndo, isFalse);
    expect(stack.redoLabel, 'Create Work');

    expect(await stack.redo(), isTrue);
    expect(await categoryNames(), ['Work']);
    expect(stack.canRedo, isFalse);
    expect(await stack.redo(), isFalse);
  });

  test('a new command clears the redo history; empty records are ignored', () async {
    final stack = h.read(undoStackProvider);
    final repo = h.read(categoriesRepositoryProvider);
    stack.push('A', await repo.create(name: 'A', color: 1));
    await stack.undo();
    expect(stack.canRedo, isTrue);
    stack.push('B', await repo.create(name: 'B', color: 1));
    expect(stack.canRedo, isFalse);
    final nothing = await h.read(syncWriterProvider).run((tx) async {});
    stack.push('Nothing', nothing);
    expect(stack.undoLabel, 'B');
  });

  test('depth is capped at 50 commands', () async {
    final stack = h.read(undoStackProvider);
    final writer = h.read(syncWriterProvider);
    for (var i = 0; i < 55; i++) {
      stack.push('c$i', await writer.run((tx) => tx.insert('tags', Ids.v7(), {'name': 't$i', 'sort_key': 'a$i'})));
    }
    var undone = 0;
    while (await stack.undo()) {
      undone++;
    }
    expect(undone, 50);
    // The 5 oldest commands stay applied.
    final live = await (h.db.select(h.db.tags)..where((t) => t.deletedAt.isNull())).get();
    expect(live.map((t) => t.name).toSet(), {'t0', 't1', 't2', 't3', 't4'});
  });

  test('undoing a multi-row delete restores every row of that operation only', () async {
    final stack = h.read(undoStackProvider);
    final repo = h.read(categoriesRepositoryProvider);
    final work = await repo.add(name: 'Work', color: 1);
    final home = await repo.add(name: 'Home', color: 2);
    final writer = h.read(syncWriterProvider);
    final taskIds = <String>[];
    for (var i = 0; i < 3; i++) {
      final id = Ids.v7();
      taskIds.add(id);
      await writer.run((tx) => tx.insert('tasks', id, {'series_id': id, 'title': 'T$i', 'category_id': work.id}));
    }
    // An unrelated earlier delete must stay deleted.
    await repo.delete(home.id);

    stack.push('Delete Work', await repo.delete(work.id));
    await stack.undo();

    expect(await categoryNames(), ['Work']);
    final tasks = await h.db.select(h.db.tasks).get();
    expect({for (final t in tasks) t.id: t.categoryId}, {for (final id in taskIds) id: work.id});
  });

  test("undo tombstones the operation's activity events; redo brings them back", () async {
    final stack = h.read(undoStackProvider);
    final writer = h.read(syncWriterProvider);
    final record = await writer.run(
      (tx) => tx.activity.statusChanged('checklist_item', 'i1', from: 'todo', to: 'waiting'),
    );
    stack.push('Status', record);
    final activity = h.read(activityRepositoryProvider);
    expect(await activity.forEntity('checklist_item', 'i1'), hasLength(1));
    await stack.undo();
    expect(await activity.forEntity('checklist_item', 'i1'), isEmpty);
    // Append-only: the row still exists, only deleted_at changed.
    expect(await h.db.select(h.db.activityEvents).get(), hasLength(1));
    await stack.redo();
    expect(await activity.forEntity('checklist_item', 'i1'), hasLength(1));
  });

  test('undoing a drag restores the original start and duration', () async {
    final stack = h.read(undoStackProvider);
    final writer = h.read(syncWriterProvider);
    final id = Ids.v7();
    await writer.run(
      (tx) => tx.insert('tasks', id, {
        'series_id': id,
        'title': 'Gym',
        'start_local': '2026-09-22T08:00',
        'duration_minutes': 60,
      }),
    );
    final drag = await writer.run((tx) async {
      await tx.update('tasks', id, {'start_local': '2026-09-22T10:30', 'duration_minutes': 45});
      await tx.activity.rescheduled(
        'task',
        id,
        occurrenceKey: '2026-09-22T08:00',
        fromStart: '2026-09-22T08:00',
        toStart: '2026-09-22T10:30',
        fromDuration: 60,
        toDuration: 45,
        source: 'drag',
      );
    });
    stack.push('Move Gym', drag);
    await stack.undo();
    final row = await (h.db.select(h.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.startLocal, '2026-09-22T08:00');
    expect(row.durationMinutes, 60);
    // The undo itself is one synced operation with cause "undo".
    final outbox = await h.db.select(h.db.syncOutbox).get();
    final undoOps = outbox.where((o) => o.opId != drag.opId).map((o) => o.opId).toSet();
    expect(undoOps, isNotEmpty);
  });

  test('the stack is cleared when the account changes', () async {
    final stack = h.read(undoStackProvider);
    stack.push('A', await h.read(categoriesRepositoryProvider).create(name: 'A', color: 1));
    expect(stack.canUndo, isTrue);
    h.read(sessionProvider.notifier).set(const AppSession(userId: 'user-2', mode: SessionMode.localOnly));
    h.read(currentUserIdProvider);
    expect(h.read(undoStackProvider).canUndo, isFalse);
  });

  group('keyboard undo/redo', () {
    Future<void> press(WidgetTester tester, List<LogicalKeyboardKey> keys) async {
      for (final k in keys) {
        await tester.sendKeyDownEvent(k);
      }
      for (final k in keys.reversed) {
        await tester.sendKeyUpEvent(k);
      }
    }

    /// Lets the database work finish and the previous snackbar animate out.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('Ctrl+Z undoes with a Redo action, Ctrl+Shift+Z redoes', (tester) async {
      final stack = h.read(undoStackProvider);
      await tester.runAsync(() async {
        stack.push('Create Work', await h.read(categoriesRepositoryProvider).create(name: 'Work', color: 1));
      });
      await pumpInApp(tester, h, const GlobalShortcuts(child: Scaffold(body: Text('home'))));
      await tester.pump();

      await press(tester, [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyZ]);
      await settle(tester);
      expect(find.text('Undone: Create Work'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Redo'), findsOneWidget);
      expect(await tester.runAsync(categoryNames), isEmpty);

      await press(tester, [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyZ]);
      await settle(tester);
      expect(find.text('Redone: Create Work'), findsOneWidget);
      expect(await tester.runAsync(categoryNames), ['Work']);

      await press(tester, [LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyY]);
      await settle(tester);
      expect(find.text('Nothing to redo'), findsOneWidget);
    });

    testWidgets('search shortcut calls back', (tester) async {
      var searched = 0;
      await pumpInApp(
        tester,
        h,
        GlobalShortcuts(
          onSearch: () => searched++,
          child: const Scaffold(body: Text('home')),
        ),
      );
      await tester.pump();
      await press(tester, [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyF]);
      await tester.pump();
      expect(searched, 1);
    });
  });
}
