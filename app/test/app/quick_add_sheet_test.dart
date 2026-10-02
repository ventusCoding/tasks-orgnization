import 'package:everslot/app/quick_add_sheet.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../features/today/today_test_support.dart';
import '../support/test_app.dart';

/// Universal quick add (T8.1.10).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10, 10)));
  tearDown(() => h.dispose());

  Future<void> open(WidgetTester tester, {QuickAddContext initial = const QuickAddContext()}) async {
    await pumpToday(
      tester,
      h,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showQuickAdd(context, initial: initial),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('task: next half hour by default; Add & new keeps the sheet for rapid entry', (tester) async {
    await open(tester);
    expect(find.text('10:30'), findsOneWidget, reason: 'next half-hour slot');
    await tester.enterText(find.byKey(const ValueKey('quick-title')), 'Call mum');
    await tester.tap(find.byKey(const ValueKey('quick-add-new')));
    await settle(tester);
    expect(find.byKey(const ValueKey('quick-title')), findsOneWidget, reason: 'sheet stays open');
    await tester.enterText(find.byKey(const ValueKey('quick-title')), 'Pay rent');
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    await settle(tester);
    expect(find.byKey(const ValueKey('quick-title')), findsNothing);
    final tasks = await tester.runAsync(
      () => h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 22), at(2026, 9, 23)),
    );
    expect(tasks!.map((t) => t.title).toSet(), {'Call mum', 'Pay rent'});
    expect(tasks.first.startLocal, LocalDateTime.of(2026, 9, 22, 10, 30));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('natural language: preview before saving, then a recurring task with category and priority', (
    tester,
  ) async {
    final health = await tester.runAsync(
      () async => (await h.read(categoriesRepositoryProvider).add(name: 'Health', color: 1)).id,
    );
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('quick-title')),
      'Gym tomorrow 7pm for 1h every Mon and Wed #health !high',
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('quick-parsed')), findsOneWidget);
    expect(find.text('Sep 23, 2026 19:00'), findsOneWidget);
    expect(find.text('Every Monday and Wednesday at 19:00'), findsOneWidget);
    expect(find.text('#health'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    await settle(tester);
    final tasks = await tester.runAsync(
      () => h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 23), at(2026, 9, 24)),
    );
    final gym = tasks!.single;
    expect(gym.title, 'Gym');
    expect(gym.startLocal, LocalDateTime.of(2026, 9, 23, 19));
    expect(gym.durationMinutes, 60);
    expect(gym.recurrence!.freq, Frequency.weekly);
    expect(gym.recurrence!.byWeekday!.map((d) => d.day), [Weekday.monday, Weekday.wednesday]);
    expect(gym.categoryId, health);
    expect(gym.priority, 3);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('natural language can be switched off; unknown categories are flagged', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('quick-title')), 'Read tomorrow #books');
    await settle(tester);
    expect(find.text('No category “books”'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quick-smart')));
    await settle(tester);
    expect(find.byKey(const ValueKey('quick-parsed')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    await settle(tester);
    final tasks = await tester.runAsync(
      () => h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 22), at(2026, 9, 23)),
    );
    expect(tasks!.single.title, 'Read tomorrow #books', reason: 'taken literally');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a planner slot pre-fills date, time and duration', (tester) async {
    await open(tester, initial: QuickAddContext(start: LocalDateTime.of(2026, 9, 24, 15), durationMinutes: 90));
    expect(find.text('15:00'), findsOneWidget);
    expect(find.textContaining('1 h 30'), findsOneWidget);
  });

  testWidgets('list, list item and habit', (tester) async {
    final list = await tester.runAsync(() => h.checklist('Groceries'));
    await open(
      tester,
      initial: QuickAddContext(type: QuickAddType.item, checklistId: list),
    );
    await tester.enterText(find.byKey(const ValueKey('quick-title')), 'Milk');
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    await settle(tester);
    final items = await tester.runAsync(() => h.read(checklistItemsRepositoryProvider).items(list!));
    expect(items!.single.text, 'Milk');

    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('quick-type-habit')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('quick-title')), 'Stretch');
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    await settle(tester);
    final habits = await tester.runAsync(() => h.read(habitsRepositoryProvider).all());
    expect(habits!.single.name, 'Stretch');

    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('quick-type-list')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('quick-title')), 'Trip');
    await tester.tap(find.byKey(const ValueKey('quick-add')));
    await settle(tester);
    final lists = await tester.runAsync(() => h.read(boardChecklistsProvider.future));
    expect(lists!.map((c) => c.title), containsAll(['Groceries', 'Trip']));
    await tester.pump(const Duration(seconds: 5));
  });
}
