import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/habits/presentation/habits_screen.dart';
import 'package:everslot/features/habits/presentation/manage_habits_screen.dart';
import 'package:everslot/features/habits/presentation/templates_sheet.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  final en = lookupAppLocalizations(const Locale('en'));
  setUp(
    () => h = TestHarness.create(
      now: DateTime.utc(2026, 9, 22, 10),
      overrides: [inboxUnreadCountProvider.overrideWith((ref) => Stream.value(0))],
    ),
  );
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<String> create(
    WidgetTester tester, {
    String name = 'Meditate',
    HabitTarget goal = const HabitTarget.check(),
  }) async {
    final id = Ids.v7();
    await tester.runAsync(
      () => h
          .read(habitsRepositoryProvider)
          .create(
            BuildHabit(
              id: id,
              name: name,
              startDate: d(2026, 9, 1),
              sortKey: '',
              goal: goal,
              schedule: buildHabit().schedule,
            ),
          ),
    );
    return id;
  }

  testWidgets('changing the goal asks "apply from"; all history leaves one revision (T5.1.13)', (tester) async {
    final id = await create(
      tester,
      name: 'Push-ups',
      goal: const HabitTarget(type: HabitGoalType.count, target: 10, unit: HabitUnits.reps),
    );
    await pumpInApp(tester, h, HabitEditorScreen(habitId: id));
    await settle(tester);
    final target = find.widgetWithText(TextField, en.habitsFieldTarget);
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(target, '20');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, en.actionSave));
    await settle(tester);
    expect(find.text(en.habitsApplyTitle), findsOneWidget);
    expect(find.text(en.habitsApplyAllWarn), findsOneWidget);
    await tester.tap(find.text(en.habitsApplyAll));
    await settle(tester);
    final revisions = (await tester.runAsync(() => h.read(habitsRepositoryProvider).revisionsFor(id)))!;
    expect(revisions.map((r) => (r.effectiveFrom, r.targetValue)), [(d(2026, 9, 1), 20)]);
    await disposeTree(tester);
  });

  testWidgets('vacation mode: pause every habit for a week, banner, resume (T5.1.14)', (tester) async {
    await create(tester);
    await pumpInApp(tester, h, const HabitsScreen());
    await settle(tester);
    await tester.tap(find.byTooltip(en.actionMore));
    await settle(tester);
    await tester.tap(find.text(en.habitsVacationTitle).last);
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, en.habitsReasonOptional), 'Holidays');
    await tester.tap(find.widgetWithText(FilledButton, en.habitsPauseAction));
    await settle(tester);
    final pauses = (await tester.runAsync(() => h.read(habitPausesRepositoryProvider).watchAll().first))!;
    final pause = pauses.single;
    expect((pause.isGlobal, pause.start, pause.end, pause.reason), (true, d(2026, 9, 22), d(2026, 9, 28), 'Holidays'));
    final banner = find.text(en.habitsVacationUntil('Sep 28, 2026'));
    expect(banner, findsOneWidget);
    // Paused habits are neutral: nothing is due today.
    expect(find.text(en.habitsGroupNotDue(1)), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(MaterialBanner), matching: find.text(en.habitsResume)));
    await settle(tester);
    expect(banner, findsNothing);
    expect(await tester.runAsync(() => h.read(habitPausesRepositoryProvider).watchAll().first), isEmpty);
    await disposeTree(tester);
  });

  testWidgets('manage habits: archiving hides the habit from Today and lists it as archived (T5.1.15)', (tester) async {
    final id = await create(tester);
    await pumpInApp(tester, h, const ManageHabitsScreen());
    await settle(tester);
    await tester.tap(find.byTooltip(en.actionMore));
    await settle(tester);
    await tester.tap(find.text(en.actionArchive));
    await settle(tester);
    expect(find.text(en.habitsArchived), findsWidgets);
    final habit = (await tester.runAsync(() => h.read(habitsRepositoryProvider).byId(id)))!;
    expect(habit.isArchived, isTrue);
    final active = (await tester.runAsync(() => h.read(habitsRepositoryProvider).watchAll().first))!;
    expect(active, isEmpty, reason: 'archived habits leave Today (and reminders)');
    await disposeTree(tester);
  });

  testWidgets('templates prefill the editor: "15 push-ups" saves count ≥ 15 reps (T5.1.16)', (tester) async {
    await pumpInApp(tester, h, const HabitsScreen());
    await settle(tester);
    await tester.tap(find.byTooltip(en.habitsAdd));
    await settle(tester);
    await tester.tap(find.text(en.habitsFromTemplate));
    await settle(tester);
    await tester.tap(find.text(en.habitsTplPushUps));
    await settle(tester);
    expect(find.text(en.habitsEditorNewTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, en.actionSave));
    await settle(tester);
    final habit = (await tester.runAsync(() => h.read(habitsRepositoryProvider).all()))!.single as BuildHabit;
    expect(habit.name, en.habitsTplPushUps);
    expect(habit.goal, const HabitTarget(type: HabitGoalType.count, target: 15, unit: HabitUnits.reps));
    await disposeTree(tester);
  });

  test('every template has a name and a description in EN, FR and AR (T5.1.16)', () {
    for (final lang in ['en', 'fr', 'ar']) {
      final l = lookupAppLocalizations(Locale(lang));
      for (final t in HabitTemplate.all) {
        expect(l.templateName(t.key), isNot(t.key), reason: '$lang ${t.key}');
        expect(l.templateDescription(t.key), isNotEmpty, reason: '$lang ${t.key}');
      }
    }
  });
}
