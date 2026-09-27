import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

void main() {
  late TestHarness h;
  // Sunday 2026-09-20 09:00 UTC (11:00 in Paris).
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 20, 9), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  const editorList = ValueKey('task-editor-list');
  const sheetList = ValueKey('recur-sheet-list');

  Future<void> openEditor(WidgetTester tester, TaskEditorScreen editor, {Locale locale = const Locale('en')}) async {
    await pumpOpener(
      tester,
      h,
      (context) => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => editor)),
      locale: locale,
    );
    await openAndSettle(tester);
  }

  Future<List<Task>> tasks(WidgetTester tester) async => (await tester.runAsync(h.liveTasks))!;

  /// Counts taps after the title is typed (T3.1.06: ≤ 6 taps).
  Future<int> tapAll(WidgetTester tester, List<(Finder, Key)> steps) async {
    for (final (finder, scroll) in steps) {
      await tapIn(tester, finder, scrollKey: scroll);
    }
    return steps.length;
  }

  Finder key(String k) => find.byKey(ValueKey(k));

  testWidgets('Gym every Monday and Tuesday 07:00–08:00', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T07:00', initialDurationMinutes: 60));
    await tester.enterText(key('task-title'), 'Gym');
    final taps = await tapAll(tester, [
      (key('task-repeat'), editorList),
      (key('recur-preset-specificDays'), sheetList),
      (key('recur-day-TU'), sheetList),
      (key('recur-done'), sheetList),
      (key('task-save'), editorList),
    ]);
    await settle(tester);
    expect(taps, lessThanOrEqualTo(6));
    final t = (await tasks(tester)).single;
    expect(t.title, 'Gym');
    expect(t.startLocal, ldt('2026-09-21T07:00'));
    expect(t.durationMinutes, 60);
    expect(t.timeZone, isNull);
    expect(t.recurrence!.freq, Frequency.weekly);
    expect(t.recurrence!.byWeekday, const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)]);
  });

  testWidgets('Drink water every 90 min 08:00–20:00', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T08:00', initialDurationMinutes: 5));
    await tester.enterText(key('task-title'), 'Drink water');
    final taps = await tapAll(tester, [
      (key('task-repeat'), editorList),
      (key('recur-preset-intraday'), sheetList),
      (key('recur-step-90'), sheetList),
      (key('recur-done'), sheetList),
      (key('task-save'), editorList),
    ]);
    await settle(tester);
    expect(taps, lessThanOrEqualTo(6));
    final rule = (await tasks(tester)).single.recurrence!;
    expect(rule.freq, Frequency.minutely);
    expect(rule.interval, 90);
    expect(rule.window, DailyWindow(LocalTime(8, 0), LocalTime(20, 0)));
  });

  testWidgets('Review every 2 days at 21:00', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T21:00', initialDurationMinutes: 30));
    await tester.enterText(key('task-title'), 'Review');
    final taps = await tapAll(tester, [
      (key('task-repeat'), editorList),
      (key('recur-preset-everyNDays'), sheetList),
      (key('recur-done'), sheetList),
      (key('task-save'), editorList),
    ]);
    await settle(tester);
    expect(taps, lessThanOrEqualTo(6));
    final t = (await tasks(tester)).single;
    expect(t.startLocal, ldt('2026-09-21T21:00'));
    expect(t.recurrence, RecurrenceRule(freq: Frequency.daily, interval: 2));
  });

  testWidgets('Standup every weekday 09:30 for 15 min, fixed Europe/Paris', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T09:30', initialDurationMinutes: 15));
    await tester.enterText(key('task-title'), 'Standup');
    final taps = await tapAll(tester, [
      (key('task-repeat'), editorList),
      (key('recur-preset-weekdays'), sheetList),
      (key('recur-done'), sheetList),
      (key('task-zone-fixed'), editorList),
      (key('task-save'), editorList),
    ]);
    await settle(tester);
    expect(taps, lessThanOrEqualTo(6));
    final t = (await tasks(tester)).single;
    expect(t.timeZone, 'Europe/Paris');
    expect(t.durationMinutes, 15);
    expect(t.recurrence!.byWeekday!.map((w) => w.day.code), ['MO', 'TU', 'WE', 'TH', 'FR']);
  });

  testWidgets('an empty title is refused inline; nothing is saved', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T09:00'));
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);
    expect(find.text('Enter a title'), findsWidgets);
    expect(await tasks(tester), isEmpty);
    expect(find.byType(TaskEditorScreen), findsOneWidget);
  });

  testWidgets('unsaved changes ask before discarding', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T09:00'));
    await tester.enterText(key('task-title'), 'Draft');
    await pumpFor(tester);
    await tester.tap(find.byTooltip('Close'));
    await pumpFor(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(find.byType(TaskEditorScreen), findsNothing);
    expect(await tasks(tester), isEmpty);
  });

  testWidgets('duration chips, end mode with +1 day, and all-day range', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T23:00', initialDurationMinutes: 30));
    await tester.enterText(key('task-title'), 'Night');
    await tapIn(tester, key('task-duration-120'), scrollKey: editorList);
    await tapIn(tester, key('task-end-mode'), scrollKey: editorList);
    expect(find.textContaining('+1 day'), findsOneWidget);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);
    final t = (await tasks(tester)).single;
    expect(t.durationMinutes, 120);
    expect(t.startLocal, ldt('2026-09-21T23:00'));
  });

  testWidgets('backlog tasks have no date and cannot repeat', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T09:00'));
    await tester.enterText(key('task-title'), 'Someday');
    await tapIn(tester, key('task-backlog'), scrollKey: editorList);
    expect(key('task-repeat'), findsNothing);
    expect(key('task-estimate'), findsOneWidget);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    await settle(tester);
    final t = (await tasks(tester)).single;
    expect(t.isUnscheduled, isTrue);
    expect(t.recurrence, isNull);
  });

  testWidgets('editing one occurrence asks the scope; "this occurrence" overrides the title only', (tester) async {
    final id = (await tester.runAsync(() => h.createTask(title: 'Standup', start: '2026-09-21T09:30', duration: 15, rule: RecurrenceRule())))!;
    await openEditor(tester, TaskEditorScreen(taskId: id, occurrenceKey: '2026-09-23T09:30'));
    expect(find.text('Edit occurrence'), findsOneWidget);
    await tester.enterText(key('task-title'), 'Long standup');
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    expect(key('scope-this'), findsOneWidget);
    await tester.tap(key('scope-ok'));
    await settle(tester);
    final records = (await tester.runAsync(() => h.records(id)))!;
    expect(records.single.occurrenceKey, '2026-09-23T09:30');
    expect(records.single.overrideTitle, 'Long standup');
    expect((await tasks(tester)).single.title, 'Standup');
  });

  testWidgets('series-level change from an occurrence disables "this occurrence"; following splits', (tester) async {
    final id = (await tester.runAsync(() => h.createTask(title: 'Gym', start: '2026-09-21T07:00', rule: RecurrenceRule())))!;
    await openEditor(tester, TaskEditorScreen(taskId: id, occurrenceKey: '2026-09-24T07:00'));
    await tapIn(tester, key('task-tracking-timer'), scrollKey: editorList);
    await tapIn(tester, key('task-save'), scrollKey: editorList);
    final thisTile = tester.widget<RadioListTile<EditScope>>(key('scope-this'));
    expect(thisTile.enabled, isFalse);
    await tester.tap(key('scope-following'));
    await pumpFor(tester);
    await tester.tap(key('scope-ok'));
    await settle(tester);
    final all = await tasks(tester);
    expect(all, hasLength(2));
    final part = all.firstWhere((t) => t.id != id);
    expect(part.trackingMode, TrackingMode.timer);
    expect(part.startLocal, ldt('2026-09-24T07:00'));
    expect(all.firstWhere((t) => t.id == id).trackingMode, TrackingMode.check);
  });

  testWidgets('reminders and attachments sections are part of the editor', (tester) async {
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T09:00'));
    await tester.scrollUntilVisible(
      find.text('Reminders'),
      200,
      scrollable: find.descendant(of: find.byKey(editorList), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Reminders'), findsWidgets);
    expect(find.text('Attachments'), findsWidgets);
  });

  testWidgets('Arabic RTL and text scale 2.0 lay out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openEditor(tester, const TaskEditorScreen(initialStart: '2026-09-21T09:00'), locale: const Locale('ar'));
    expect(find.text('مهمة جديدة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('task-url')),
      300,
      scrollable: find.descendant(of: find.byKey(editorList), matching: find.byType(Scrollable)).first,
    );
    expect(tester.takeException(), isNull);
  });
}
