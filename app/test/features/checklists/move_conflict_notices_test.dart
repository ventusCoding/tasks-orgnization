import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/features/checklists/application/move_conflicts.dart';
import 'package:everslot/features/checklists/presentation/move_conflict_notices.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// The reject→revert path seen by the user (T4.1.05): notice + undo entry turned into a marker.
void main() {
  testWidgets('a rejected move shows the notice and neutralizes its undo entry', (tester) async {
    final rejections = StreamController<SyncRejection>.broadcast();
    addTearDown(rejections.close);
    final h = TestHarness.create(overrides: [checklistMoveConflictsProvider.overrideWith((ref) => rejections.stream)]);
    addTearDown(h.dispose);
    final record = await tester.runAsync(
      () => h
          .read(syncWriterProvider)
          .run((tx) => tx.insert('categories', 'c1', {'name': 'Work', 'color': 1, 'sort_key': 'a0'})),
    );
    final stack = h.read(undoStackProvider)..push('Move', record!);

    await pumpInApp(tester, h, const Scaffold(body: MoveConflictNotices(child: SizedBox.expand())));
    rejections.add(
      SyncRejection(
        opId: record.opId,
        rows: const {
          'checklist_items': {'Y'},
        },
        messages: const ['checklist_cycle: item Y would become its own ancestor'],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('A move conflicted with a change on another device and was undone.'), findsOneWidget);
    expect(stack.undoLabel, 'Move undone after a sync conflict');
    // Undoing the marker writes nothing (the row stays as the server left it).
    expect(await tester.runAsync(stack.undo), isTrue);
    final rows = await tester.runAsync(() => h.db.customSelect('SELECT deleted_at FROM categories').get());
    expect(rows!.single.data['deleted_at'], isNull);

    await tester.pump(const Duration(seconds: 6));
  });
}
