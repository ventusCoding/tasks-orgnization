import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/presentation/task_exceptions_sheet.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Exceptions manager of a task series (T2.1.19).
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));

  /// Daily 08:00 series with a cancelled, a moved and an excluded occurrence.
  Future<String> seed(WidgetTester tester) async => (await tester.runAsync(() async {
    final id = await h.createTask(
      title: 'Stretch',
      start: '2026-09-20T08:00',
      duration: 15,
      rule: RecurrenceRule(exdates: const ['2026-09-26T08:00']),
    );
    await h.occurrences.cancel(id, '2026-09-22T08:00');
    await h.tasks.editOccurrence(id, '2026-09-23T08:00', start: ldt('2026-09-23T10:00'));
    return id;
  }))!;

  Future<void> openSheet(WidgetTester tester, String id) async {
    await pumpOpener(tester, h, (context) => showTaskExceptionsSheet(context, taskId: id));
    await openAndSettle(tester);
  }

  testWidgets('lists cancelled, moved and excluded occurrences; Restore brings one back', (tester) async {
    final id = await seed(tester);
    await openSheet(tester, id);
    expect(key('recur-exception-2026-09-22T08:00'), findsOneWidget);
    expect(key('recur-exception-2026-09-23T08:00'), findsOneWidget);
    expect(key('recur-exception-2026-09-26T08:00'), findsOneWidget);

    await tester.tap(key('recur-exception-restore-2026-09-22T08:00'));
    await settle(tester);
    expect(key('recur-exception-2026-09-22T08:00'), findsNothing);
    final records = (await tester.runAsync(() => h.records(id)))!;
    expect(records.map((r) => r.occurrenceKey), ['2026-09-23T08:00'], reason: 'the override record is removed');
  });

  testWidgets('Restore all brings everything back in one undoable operation', (tester) async {
    final id = await seed(tester);
    await openSheet(tester, id);
    await tester.tap(key('recur-exceptions-restore-all'));
    await pumpFor(tester);
    await tester.tap(find.text('Restore all').last);
    await settle(tester);
    expect(key('recur-exceptions-empty'), findsOneWidget);
    final state = (await tester.runAsync(() async => (await h.records(id), await h.task(id))))!;
    expect(state.$1, isEmpty);
    expect(state.$2!.recurrence!.exdates, isEmpty);
    final items = (await tester.runAsync(() => h.items(ld('2026-09-21'), 7)))!;
    expect(items.map((i) => i.startLocal.time.toString()).toSet(), {'08:00'});
    expect(items, hasLength(7));

    // One undo reverts the whole restore.
    await tester.runAsync(() => h.read(undoStackProvider).undo());
    final after = (await tester.runAsync(() async => (await h.records(id), await h.task(id))))!;
    expect(after.$1.map((r) => r.occurrenceKey).toSet(), {'2026-09-22T08:00', '2026-09-23T08:00'});
    expect(after.$2!.recurrence!.exdates, ['2026-09-26T08:00']);
  });

  testWidgets('Arabic RTL at text scale 2.0 lays out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final id = await seed(tester);
    await pumpOpener(tester, h, (context) => showTaskExceptionsSheet(context, taskId: id), locale: const Locale('ar'));
    await openAndSettle(tester);
    expect(key('recur-exception-2026-09-22T08:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
