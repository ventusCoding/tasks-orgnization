import 'package:drift/drift.dart' show Variable;
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Manual time entries from the occurrence sheet (T3.2.18): add, overlap warning, delete.
void main() {
  late TestHarness h;
  // Tuesday 2026-09-22 12:00 UTC: the 09:00–09:30 session is in the past.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 12)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<int> liveEntries(WidgetTester tester, String taskId) async => (await tester.runAsync(() async {
    final row = await h.db
        .customSelect(
          'SELECT COUNT(*) AS c FROM time_entries WHERE deleted_at IS NULL AND task_id = ?',
          variables: [Variable<String>(taskId)],
        )
        .getSingle();
    return row.read<int>('c');
  }))!;

  /// Accepts both time pickers at their initial values (the planned slot).
  Future<void> addPlannedSession(WidgetTester tester) async {
    await tester.ensureVisible(key('entry-add'));
    await pumpFor(tester, const Duration(milliseconds: 200));
    await tester.tap(key('entry-add'));
    await pumpFor(tester);
    await tester.tap(find.byKey(const ValueKey('time-apply')));
    await pumpFor(tester);
    await tester.tap(find.byKey(const ValueKey('time-apply')));
    await settle(tester);
  }

  testWidgets('add a forgotten session, warn on overlap, delete it', (tester) async {
    final (id, item) = (await tester.runAsync(() async {
      final id = await h.createTask(
        title: 'Deep work',
        start: '2026-09-22T09:00',
        duration: 30,
        mode: TrackingMode.timer,
      );
      final items = await h.items(ld('2026-09-22'), 1);
      return (id, items.single);
    }))!;
    await pumpOpener(tester, h, (context) => showOccurrenceSheet(context, item));
    await openAndSettle(tester);

    await addPlannedSession(tester);
    expect(await liveEntries(tester, id), 1);
    expect(find.textContaining('Tracked: 30'), findsOneWidget);

    // The same slot again overlaps the first session: saved, with a warning.
    await addPlannedSession(tester);
    expect(await liveEntries(tester, id), 2);
    expect(find.text('Overlaps another session'), findsOneWidget);

    final delete = find.byTooltip('Delete session').first;
    await tester.ensureVisible(delete);
    await pumpFor(tester, const Duration(milliseconds: 200));
    await tester.tap(delete);
    await settle(tester);
    expect(await liveEntries(tester, id), 1);
  });
}
