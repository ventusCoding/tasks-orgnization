import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Occurrence sheet (T3.2.05): primary actions per tracking mode, skip reasons, actual-time
/// capture (T3.2.14), delete scopes and live updates after each write.
void main() {
  late TestHarness h;
  // Monday 2026-09-21 08:00 UTC.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 8)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<PlannerItem> itemOf(WidgetTester tester, String taskId) async {
    final items = (await tester.runAsync(() => h.items(ld('2026-09-21'), 1)))!;
    return items.firstWhere((i) => i.taskId == taskId);
  }

  Future<void> openSheet(WidgetTester tester, PlannerItem item, {Locale locale = const Locale('en')}) async {
    await pumpOpener(tester, h, (context) => showOccurrenceSheet(context, item), locale: locale);
    await openAndSettle(tester);
  }

  Future<TaskOccurrenceRecord?> recordOf(WidgetTester tester, String taskId) async =>
      (await tester.runAsync(() => h.records(taskId)))!.firstOrNull;

  Future<void> tapKey(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await pumpFor(tester, const Duration(milliseconds: 100));
    await tester.tap(key(k));
    await settle(tester);
  }

  testWidgets('check task: title, time, status; Done marks it done and the sheet updates live', (tester) async {
    final id = (await tester.runAsync(() => h.createTask(title: 'Gym', start: '2026-09-21T07:00')))!;
    await openSheet(tester, await itemOf(tester, id));
    expect(key('occurrence-title'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.textContaining('07:00'), findsWidgets);
    expect(find.descendant(of: key('occurrence-status'), matching: find.text('Scheduled')), findsOneWidget);
    expect(key('occurrence-action-done'), findsOneWidget);
    expect(key('occurrence-action-skip'), findsOneWidget);
    expect(key('occurrence-action-start'), findsNothing);

    // Planned end = now: no actual-time question.
    await tapKey(tester, 'occurrence-action-done');
    final record = await recordOf(tester, id);
    expect(record!.status, OccurrenceStatus.done);
    expect(record.completedAt, h.clock.nowUtc());
    expect(find.descendant(of: key('occurrence-status'), matching: find.text('Done')), findsOneWidget);
    expect(key('occurrence-action-reopen'), findsOneWidget);
    expect(find.text('Marked as done'), findsOneWidget);
  });

  testWidgets('skip asks a reason and shows it', (tester) async {
    final id = (await tester.runAsync(() => h.createTask(title: 'Run', start: '2026-09-21T07:00')))!;
    await openSheet(tester, await itemOf(tester, id));
    await tapKey(tester, 'occurrence-action-skip');
    expect(key('skip-sick'), findsOneWidget);
    await tester.tap(key('skip-sick'));
    await pumpFor(tester);
    await tester.tap(key('skip-ok'));
    await settle(tester);
    final record = await recordOf(tester, id);
    expect(record!.status, OccurrenceStatus.skipped);
    expect(record.skipReason, 'sick');
    expect(find.descendant(of: key('occurrence-status'), matching: find.text('Skipped')), findsOneWidget);
    expect(find.textContaining('Sick'), findsWidgets);
  });

  testWidgets('done long after the planned end asks for the actual time', (tester) async {
    final id = (await tester.runAsync(() => h.createTask(title: 'Read', start: '2026-09-21T05:00', duration: 30)))!;
    await openSheet(tester, await itemOf(tester, id));
    await tapKey(tester, 'occurrence-action-done');
    expect(key('actual-as-planned'), findsOneWidget);
    await tester.tap(key('actual-as-planned'));
    await settle(tester);
    final record = await recordOf(tester, id);
    expect(record!.status, OccurrenceStatus.done);
    expect(record.actualStartAt, DateTime.utc(2026, 9, 21, 5));
    expect(record.actualEndAt, DateTime.utc(2026, 9, 21, 5, 30));
  });

  testWidgets('timer task: Start runs a timer, Stop completes it with the tracked time', (tester) async {
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Deep work', start: '2026-09-21T08:00', mode: TrackingMode.timer),
    ))!;
    await openSheet(tester, await itemOf(tester, id));
    // Timer tasks can still be ticked off without timing them.
    expect(key('occurrence-action-start'), findsOneWidget);
    expect(key('occurrence-action-done'), findsOneWidget);
    await tapKey(tester, 'occurrence-action-start');
    final running = (await tester.runAsync(() => h.read(plannerQueriesProvider).watchRunningEntries().first))!;
    expect(running, hasLength(1));
    expect(find.descendant(of: key('occurrence-status'), matching: find.text('In progress')), findsOneWidget);
    expect(key('occurrence-action-stop'), findsOneWidget);

    h.clock.advance(const Duration(minutes: 25));
    await tapKey(tester, 'occurrence-action-stop');
    final record = await recordOf(tester, id);
    expect(record!.status, OccurrenceStatus.done);
    expect(record.trackedSeconds, 25 * 60);
    expect(await tester.runAsync(() => h.read(plannerQueriesProvider).watchRunningEntries().first), isEmpty);
  });

  testWidgets('event task: no checkbox actions, only skip', (tester) async {
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Concert', start: '2026-09-21T19:00', mode: TrackingMode.event),
    ))!;
    await openSheet(tester, await itemOf(tester, id));
    expect(key('occurrence-action-skip'), findsOneWidget);
    expect(key('occurrence-action-done'), findsNothing);
    expect(key('occurrence-action-start'), findsNothing);
    expect(key('occurrence-actual'), findsNothing);
  });

  testWidgets('deleting one occurrence of a series asks the scope and closes the sheet', (tester) async {
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Standup', start: '2026-09-20T09:30', duration: 15, rule: RecurrenceRule()),
    ))!;
    await openSheet(tester, await itemOf(tester, id));
    await tapKey(tester, 'occurrence-delete');
    expect(key('scope-this'), findsOneWidget);
    await tester.tap(key('scope-this'));
    await pumpFor(tester);
    await tester.tap(key('scope-ok'));
    await settle(tester);
    final record = await recordOf(tester, id);
    expect(record!.occurrenceKey, '2026-09-21T09:30');
    expect(record.isCancelled, isTrue);
    expect(find.byType(OccurrenceSheet), findsNothing);
    expect(await tester.runAsync(() => h.items(ld('2026-09-22'), 1)), hasLength(1));
  });

  testWidgets('reschedule moves this occurrence only', (tester) async {
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Walk', start: '2026-09-20T18:00', duration: 30, rule: RecurrenceRule()),
    ))!;
    await openSheet(tester, await itemOf(tester, id));
    await tapKey(tester, 'occurrence-reschedule');
    await tester.tap(key('postpone-tomorrowSameTime'));
    await settle(tester);
    final record = await recordOf(tester, id);
    expect(record!.occurrenceKey, '2026-09-21T18:00');
    expect(record.overrideStartLocal, isNotNull);
    expect(record.overrideStartLocal!.date, ld('2026-09-22'));
  });

  testWidgets('Arabic RTL and text scale 2.0 lay out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Deep work', start: '2026-09-21T17:00', mode: TrackingMode.timer, zone: 'Asia/Tokyo'),
    ))!;
    await openSheet(tester, await itemOf(tester, id), locale: const Locale('ar'));
    expect(key('occurrence-title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
