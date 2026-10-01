import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot/features/planner/presentation/task_detail_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Task details with history (T3.1.09) and the delete/undo UX (T3.1.10).
void main() {
  late TestHarness h;
  // Monday 2026-09-21 08:00 UTC = 10:00 in Paris.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 8), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  const detailList = ValueKey('detail-list');
  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> openDetail(WidgetTester tester, TaskDetailScreen screen, {Locale locale = const Locale('en')}) async {
    await pumpOpener(
      tester,
      h,
      (context) => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen)),
      locale: locale,
    );
    await openAndSettle(tester);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final scrollable = find.descendant(of: find.byKey(detailList), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    await pumpFor(tester, const Duration(milliseconds: 200));
  }

  testWidgets('recurring task: schedule summary, zone mode, next 5 occurrences and history', (tester) async {
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Standup', start: '2026-09-21T09:30', duration: 15, rule: RecurrenceRule()),
    ))!;
    await openDetail(tester, TaskDetailScreen(taskId: id));
    expect(find.text('Standup'), findsWidgets);
    expect(key('detail-schedule'), findsOneWidget);
    expect(find.textContaining('Floating'), findsWidgets);
    // 10:00 in Paris: today's 09:30 is past, the next five start tomorrow.
    await scrollTo(tester, key('next-2026-09-26T09:30'));
    expect(key('next-2026-09-21T09:30'), findsNothing);
    for (final day in [22, 23, 24, 25, 26]) {
      expect(key('next-2026-09-${day}T09:30'), findsOneWidget);
    }
    await scrollTo(tester, find.text('Created'));
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('reschedule entries show both times in the viewer zone', (tester) async {
    final id = (await tester.runAsync(() async {
      final id = await h.createTask(title: 'NY sync', start: '2026-09-22T10:00', zone: 'America/New_York');
      await h.tasks.rescheduleTask(id, start: ldt('2026-09-22T11:00'), source: 'menu');
      return id;
    }))!;
    await openDetail(tester, TaskDetailScreen(taskId: id));
    final entry = find.textContaining('Rescheduled from');
    await scrollTo(tester, entry);
    final text = tester.widget<Text>(entry).data!;
    // 10:00 → 11:00 in New York = 16:00 → 17:00 in Paris.
    expect(text, contains('16:00'));
    expect(text, contains('17:00'));
    expect(text, isNot(contains('10:00')));
  });

  testWidgets('history pages 50 events at a time', (tester) async {
    final id = (await tester.runAsync(() async {
      final id = await h.createTask(title: 'Busy', start: '2026-09-22T10:00');
      await h.writer.run((tx) async {
        for (var i = 0; i < 59; i++) {
          await tx.logEvent(
            entityType: 'task',
            entityId: id,
            eventType: 'updated',
            payload: const {
              'fields': ['title'],
            },
          );
        }
      });
      return id;
    }))!;
    await openDetail(tester, TaskDetailScreen(taskId: id));
    await scrollTo(tester, key('history-more'));
    expect(find.textContaining('Edited', skipOffstage: false), findsNWidgets(50));
    await tester.tap(key('history-more'));
    await settle(tester);
    expect(key('history-more'), findsNothing);
    await scrollTo(tester, find.text('Created'));
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('deleting a one-off asks, pops, and Undo brings it back', (tester) async {
    final id = (await tester.runAsync(() => h.createTask(title: 'Dentist', start: '2026-09-23T14:00')))!;
    await openDetail(tester, TaskDetailScreen(taskId: id));
    await tester.tap(key('detail-menu'));
    await pumpFor(tester);
    await tester.tap(find.text('Delete'));
    await pumpFor(tester);
    expect(find.text('Delete this task?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect(find.byType(TaskDetailScreen), findsNothing);
    expect(await tester.runAsync(() => h.task(id)), isNull);
    expect(find.text('Task deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await tester.runAsync(() => h.task(id)))!.title, 'Dentist');
  });

  testWidgets('opened for one occurrence it shows the occurrence panel on top', (tester) async {
    final id = (await tester.runAsync(
      () => h.createTask(title: 'Walk', start: '2026-09-21T18:00', duration: 30, rule: RecurrenceRule()),
    ))!;
    await openDetail(tester, TaskDetailScreen(taskId: id, occurrenceKey: '2026-09-23T18:00'));
    expect(find.byType(OccurrencePanel), findsOneWidget);
    expect(key('occurrence-action-done'), findsOneWidget);
    expect(find.textContaining('18:00'), findsWidgets);
  });

  testWidgets('Arabic RTL and text scale 2.0 lay out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final id = (await tester.runAsync(
      () => h.createTask(
        title: 'Standup',
        start: '2026-09-21T09:30',
        duration: 15,
        rule: RecurrenceRule(),
        zone: 'Asia/Tokyo',
      ),
    ))!;
    await openDetail(
      tester,
      TaskDetailScreen(taskId: id, occurrenceKey: '2026-09-22T09:30'),
      locale: const Locale('ar'),
    );
    await scrollTo(tester, find.byType(OccurrencePanel));
    await tester.drag(find.byKey(detailList), const Offset(0, -1500));
    await pumpFor(tester);
    expect(tester.takeException(), isNull);
  });
}
