@Tags(['sync'])
library;

import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/core/undo/undo_stack.dart';
import 'package:everslot/features/checklists/application/move_conflicts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/sync/support/fake_sync_server.dart';

/// Tree-aware sync conflicts (T4.1.05): two offline devices move X under Y and Y under X; the
/// server accepts the first group and rejects the second (`checklist_cycle`), the loser refetches
/// and both converge to the structure pushed first, nothing lost or duplicated.
void main() {
  late FakeSyncServer server;
  final devices = <SimDevice>[];

  SimDevice device(String id) {
    final d = SimDevice(server, userId: 'u1', deviceId: id);
    devices.add(d);
    return d;
  }

  /// Server-side cycle guard of `app.checklist_items` (DL002 in the migration).
  String? cycleCheck(FakeSyncServer s, String user, String table, String id) {
    if (table != 'checklist_items') return null;
    final seen = <String>{id};
    var parent = s.row(table, id)?.values['parent_id'] as String?;
    while (parent != null) {
      if (!seen.add(parent)) return 'checklist_cycle: item $id would become its own ancestor';
      parent = s.row(table, parent)?.values['parent_id'] as String?;
    }
    return null;
  }

  setUp(() {
    server = FakeSyncServer()..integrityCheck = cycleCheck;
  });

  tearDown(() async {
    for (final d in devices) {
      await d.dispose();
    }
    devices.clear();
  });

  // `parent_id: null` is explicit: the real server returns every column on refetch, the fake one
  // only the fields it was sent.
  Future<void> seed(SimDevice d) => d.writer.run((tx) async {
    await tx.insert('checklists', 'L', {'title': 'Trip', 'sort_key': 'a0'});
    await tx.insert('checklist_items', 'X', {'checklist_id': 'L', 'parent_id': null, 'text': 'X', 'sort_key': 'a0'});
    await tx.insert('checklist_items', 'Y', {'checklist_id': 'L', 'parent_id': null, 'text': 'Y', 'sort_key': 'a1'});
  });

  test('cross-move X↔Y converges to the structure pushed first', () async {
    final a = device('A');
    final b = device('B');
    await seed(a);
    await a.sync.syncNow();
    await b.sync.syncNow();

    final undoB = UndoStack(b.writer);
    final rejections = <SyncRejection>[];
    final sub = b.sync.rejections.listen(rejections.add);
    addTearDown(sub.cancel);

    // Offline on both: A moves X under Y, B moves Y under X.
    await a.writer.run((tx) => tx.update('checklist_items', 'X', {'parent_id': 'Y'}));
    b.clock.advance(const Duration(seconds: 1));
    final moveB = await b.writer.run((tx) => tx.update('checklist_items', 'Y', {'parent_id': 'X'}));
    undoB.push('Move', moveB);

    await a.sync.syncNow();
    await b.sync.syncNow();
    await a.sync.syncNow();
    await pumpEventQueue();

    expect(await b.outbox(), isEmpty, reason: 'the rejected group is dropped');
    for (final d in [a, b]) {
      final rows = await d.rows('checklist_items', ['parent_id', 'deleted_at']);
      expect(rows.keys, unorderedEquals(['X', 'Y']), reason: 'device ${d.deviceId}');
      expect(rows['X']!['parent_id'], 'Y', reason: 'device ${d.deviceId}');
      expect(rows['Y']!['parent_id'], isNull, reason: 'device ${d.deviceId}');
      expect(rows.values.every((r) => r['deleted_at'] == null), isTrue);
    }

    final rejection = rejections.single;
    expect(rejection.opId, moveB.opId);
    expect(rejection.rows['checklist_items'], {'Y'});
    expect(isChecklistMoveConflict(rejection), isTrue);

    // The loser's undo entry becomes a no-op marker: undoing it must not write stale values.
    expect(undoB.neutralize(rejection.opId, 'Move conflicted'), isTrue);
    expect(undoB.undoLabel, 'Move conflicted');
    expect(await undoB.undo(), isTrue);
    expect(await b.outbox(), isEmpty);
    expect((await b.rows('checklist_items', ['parent_id']))['X']!['parent_id'], 'Y');
  });

  test('other integrity rejections are not move conflicts', () {
    const r = SyncRejection(
      opId: 'g',
      rows: {
        'categories': {'c'},
      },
      messages: ['DL001 parent in another checklist'],
    );
    expect(isChecklistMoveConflict(r), isFalse);
  });
}
