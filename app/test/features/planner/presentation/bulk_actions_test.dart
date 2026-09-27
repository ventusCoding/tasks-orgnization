import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart' show tagsRepositoryProvider;
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/bulk_actions_sheet.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Bulk actions sheet (T3.1.18): one operation per action, one undo, occurrence vs series.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));

  /// One-off A at 09:00, one-off B at 11:00, and the 22nd occurrence of a daily series.
  Future<(String, String, String, List<PlannerItem>)> seed(WidgetTester tester) async => (await tester.runAsync(() async {
    final a = await h.createTask(title: 'A', start: '2026-09-22T09:00');
    final b = await h.createTask(title: 'B', start: '2026-09-22T11:00');
    final daily = await h.createTask(title: 'Daily', start: '2026-09-20T07:00', duration: 15, rule: RecurrenceRule());
    final items = await h.items(ld('2026-09-22'), 1);
    return (a, b, daily, items);
  }))!;

  Future<void> openSheet(WidgetTester tester, List<PlannerItem> items) async {
    await pumpOpener(tester, h, (context) => showBulkActionsSheet(context, items));
    await openAndSettle(tester);
  }

  testWidgets('move one day later: every item in one operation, undone at once', (tester) async {
    final (a, b, daily, items) = await seed(tester);
    await openSheet(tester, items);
    expect(find.text('3 items selected'), findsOneWidget);
    expect(key('bulk-scope'), findsOneWidget, reason: 'a recurring item is selected');
    await tester.tap(key('bulk-move-1d'));
    await settle(tester);
    expect(find.byType(BulkActionsSheet), findsNothing);
    final moved = (await tester.runAsync(() async => (await h.task(a), await h.task(b), await h.records(daily))))!;
    expect(moved.$1!.startLocal, ldt('2026-09-23T09:00'));
    expect(moved.$2!.startLocal, ldt('2026-09-23T11:00'));
    expect(moved.$3.single.occurrenceKey, '2026-09-22T07:00');
    expect(moved.$3.single.overrideStartLocal, ldt('2026-09-23T07:00'), reason: 'only that occurrence moves');

    await tester.runAsync(() => h.read(undoStackProvider).undo());
    final undone = (await tester.runAsync(() async => (await h.task(a), await h.task(b), await h.records(daily))))!;
    expect(undone.$1!.startLocal, ldt('2026-09-22T09:00'));
    expect(undone.$2!.startLocal, ldt('2026-09-22T11:00'));
    expect(undone.$3, isEmpty);
  });

  testWidgets('whole series: the tracking mode applies to the series', (tester) async {
    final (_, _, daily, items) = await seed(tester);
    await openSheet(tester, items.where((i) => i.taskId == daily).toList());
    await tester.tap(find.text('Whole series'));
    await pumpFor(tester);
    await tester.tap(key('bulk-tracking'));
    await pumpFor(tester);
    await tester.tap(key('bulk-tracking-timer'));
    await settle(tester);
    expect((await tester.runAsync(() => h.task(daily)))!.trackingMode, TrackingMode.timer);
  });

  testWidgets('add tags to every task; delete asks first', (tester) async {
    final (a, b, _, items) = await seed(tester);
    final tag = (await tester.runAsync(() => h.read(tagsRepositoryProvider).create(name: 'focus')))!.id;
    final oneOffs = items.where((i) => !i.isRecurring).toList();
    await openSheet(tester, oneOffs);
    await tester.tap(key('bulk-tags'));
    await settle(tester);
    await tester.tap(find.text('focus'));
    await pumpFor(tester);
    await tester.tap(find.text('Done').last);
    await settle(tester);
    final tagged = (await tester.runAsync(() async => [
      for (final id in [a, b]) (await h.read(tagsRepositoryProvider).tagsForEntity('task', id)).map((t) => t.id).toList(),
    ]))!;
    expect(tagged, [
      [tag],
      [tag],
    ]);

    await openSheet(tester, oneOffs);
    await tester.tap(key('bulk-delete'));
    await pumpFor(tester);
    expect(find.text('Delete 2 items?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect(await tester.runAsync(() => h.task(a)), isNull);
    expect(await tester.runAsync(() => h.task(b)), isNull);
  });
}
