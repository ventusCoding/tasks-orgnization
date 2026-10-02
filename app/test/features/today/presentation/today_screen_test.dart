import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/habit_providers.dart' show habitLogsRepositoryProvider;
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/application/today_overview_provider.dart';
import 'package:everslot/features/today/domain/today_layout.dart';
import 'package:everslot/features/today/presentation/today_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../today_test_support.dart';

/// Today screen (T8.1.02–08, 11–13).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  final today = LocalDate(2026, 9, 22);

  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10)));
  tearDown(() => h.dispose());

  Future<void> seedDay() async {
    await h.task('Standup', start: at(2026, 9, 22, 9, 30), duration: 60);
    await h.task('Review', start: at(2026, 9, 22, 14));
    await h.task('Holiday', start: at(2026, 9, 22), allDay: true);
    await h.task('Forgotten', start: at(2026, 9, 20, 9));
    await h.habit('Read', start: LocalDate(2026, 9, 1));
    await h.habit(
      'Push-ups',
      start: LocalDate(2026, 9, 1),
      goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'),
    );
    await h.quitTracker('Smoking', quitAt: DateTime.utc(2026, 9, 20, 8), start: LocalDate(2026, 9, 20));
    final groceries = await h.checklist('Groceries', items: ['Milk', 'Eggs'], pinned: true);
    await h.setItemFields(groceries, await h.itemId(groceries, 'Eggs'), {'due_local': at(2026, 9, 22, 18)});
  }

  Future<void> open(WidgetTester tester, {double textScale = 1, Locale locale = const Locale('en')}) async {
    await pumpToday(tester, h, const TodayScreen(), textScale: textScale, locale: locale, size: const Size(400, 4000));
    await settle(tester, rounds: 10);
  }

  Future<List<PlannerItem>> agenda() async =>
      (await until(h.container, todayOverviewProvider, (o) => o.agenda != null)).agenda!;

  testWidgets('empty day: only the agenda stays, with its primary action', (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('today-block-agenda')), findsOneWidget);
    expect(find.text('Nothing planned today'), findsOneWidget);
    expect(find.text('Plan a task'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-block-habits')), findsNothing, reason: 'empty blocks hide');
  });

  testWidgets('full day: now/next, agenda, overdue, habits, quit and lists blocks', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester);
    expect(find.text('Good morning'), findsOneWidget);
    for (final id in ['now_next', 'agenda', 'overdue', 'habits', 'quit', 'checklists']) {
      expect(find.byKey(ValueKey('today-block-$id')), findsOneWidget, reason: id);
    }
    expect(find.textContaining('left'), findsWidgets, reason: 'Standup runs now (09:30–10:30)');
    expect(find.textContaining('Review'), findsWidgets);
    expect(find.text('0/3 tasks'), findsOneWidget, reason: 'header: Holiday, Standup, Review');
    expect(find.text('0/2 habits'), findsOneWidget);
  });

  testWidgets('agenda: tick the all-day task done, swipe a timed one to skip; header follows', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester);
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: find.text('Holiday'), matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      ),
    );
    await settle(tester);
    final rows = await tester.runAsync(agenda);
    expect(rows!.firstWhere((i) => i.title == 'Holiday').status, OccurrenceStatus.done);
    final review = find.ancestor(of: find.text('Review').last, matching: find.byType(Dismissible));
    await tester.drag(review, const Offset(-500, 0));
    await settle(tester);
    final after = await tester.runAsync(agenda);
    expect(after!.firstWhere((i) => i.title == 'Review').status, OccurrenceStatus.skipped);
    expect(find.text('Done (2)'), findsOneWidget);
    expect(find.text('1/3 tasks'), findsOneWidget);
  });

  testWidgets('overdue: roll over to today moves the task, and one undo restores it', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('overdue-rollover')));
    await settle(tester);
    final rows = await tester.runAsync(agenda);
    expect(rows!.firstWhere((i) => i.title == 'Forgotten').startLocal, at(2026, 9, 22, 9));
    await tester.runAsync(() => h.read(undoStackProvider).undo());
    await settle(tester);
    final restored = await tester.runAsync(
      () => until(h.container, todayOverviewProvider, (o) => o.overdue?.any((i) => i.title == 'Forgotten') ?? false),
    );
    expect(restored!.overdue!.single.startLocal, at(2026, 9, 20, 9));
  });

  testWidgets('habits: one-tap check-in and +1 for counts', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('habit-check-habit-Read')));
    await tester.tap(find.byKey(const ValueKey('habit-plus-habit-Push-ups')));
    await settle(tester);
    final logs = await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit('habit-Read'));
    expect(logs!.single.kind.name, 'done');
    final reps = await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit('habit-Push-ups'));
    expect(reps!.single.value, 1);
    await tester.pump(const Duration(seconds: 5)); // snackbars
  });

  testWidgets('lists: pinned progress and completing a due item', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester);
    expect(find.text('0 of 2'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: find.text('Eggs'), matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      ),
    );
    await settle(tester);
    final items = await tester.runAsync(
      () => h
          .read(todayChecklistQueriesProvider)
          .watch(dueBefore: today.plusDays(1), followUpBefore: DateTime.utc(2026, 9, 23))
          .first,
    );
    expect(items!.where((i) => i.text == 'Eggs'), isEmpty, reason: 'completed items leave the due list');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('customize: hiding a block removes it; reset brings it back', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester);
    await tester.runAsync(
      () => h.read(todayLayoutWriterProvider)(TodayLayout.defaults.withHidden(TodayBlockId.habits, hidden: true)),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('today-block-habits')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('today-customize')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('today-reset')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('today-reset')));
    await settle(tester);
    expect(h.read(todayLayoutProvider).isHidden(TodayBlockId.habits), isFalse);
  });

  testWidgets('Arabic at text scale 2: no layout errors', (tester) async {
    await tester.runAsync(seedDay);
    await open(tester, textScale: 2, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    expect(find.text('صباح الخير'), findsOneWidget);
  });

  test('progress header counts match the overview', () async {
    await seedDay();
    final p = await until(h.container, todayProgressProvider, (p) => p.tasksPlanned == 3 && p.habitsDue == 2);
    expect((p.tasksDone, p.tasksPlanned, p.habitsDone, p.habitsDue, p.itemsCompleted), (0, 3, 0, 2, 0));
    final rows = (await until(h.container, todayOverviewProvider, (o) => o.agenda != null)).agenda!;
    await h.read(plannerServiceProvider).markDone(rows.firstWhere((i) => i.title == 'Review'));
    final after = await until(h.container, todayProgressProvider, (p) => p.tasksDone == 1);
    expect(after.ratio, closeTo(1 / 5, 1e-9));
  });
}
