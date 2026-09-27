import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/habits/presentation/habits_screen.dart';
import 'package:everslot/features/habits/presentation/quit_dashboard_screen.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10)));
  tearDown(() => h.dispose());

  /// Lets Drift streams deliver without waiting on timers (live counters never settle).
  Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Unmounts the screen and releases app-bar providers that keep timers (inbox badge refresh).
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    h.container.invalidate(inboxUnreadCountProvider);
    await tester.pump();
  }

  Future<void> seedHabits(WidgetTester tester) => tester.runAsync(() async {
    final repo = h.read(habitsRepositoryProvider);
    await h.read(habitSectionsRepositoryProvider).seedDefaults(const {
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'anytime': 'Anytime',
    });
    await repo.create(buildHabit(id: Ids.v7(), name: 'Meditate', start: d(2026, 9, 1)).copyWith(sortKey: ''));
    await repo.create(
      buildHabit(
        id: Ids.v7(),
        name: 'Push-ups',
        start: d(2026, 9, 1),
        goal: const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'),
      ).copyWith(sortKey: ''),
    );
  });

  testWidgets('Today list shows due habits; one tap marks a yes/no habit done', (tester) async {
    await seedHabits(tester);
    await pumpInApp(tester, h, const HabitsScreen());
    await settle(tester);
    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.text('0 / 15 reps'), findsOneWidget);

    final ring = find.descendant(of: find.widgetWithText(HabitRow, 'Meditate'), matching: find.byType(ProgressRing));
    await tester.tap(ring);
    await settle(tester);
    expect(find.text('“Meditate” done'), findsOneWidget);
    final logs = await tester.runAsync(() => h.read(habitLogsRepositoryProvider).watchInRange(d(2026, 9, 22), d(2026, 9, 22)).first);
    expect(logs!.single.kind, HabitLogKind.done);

    // The stepper adds one increment per tap.
    final plus = find.descendant(of: find.widgetWithText(HabitRow, 'Push-ups'), matching: find.byIcon(Icons.add));
    await tester.tap(plus);
    await settle(tester);
    expect(find.text('1 / 15 reps'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('switching views keeps working and the Arabic layout renders', (tester) async {
    await seedHabits(tester);
    await pumpInApp(tester, h, const HabitsScreen(), locale: const Locale('ar'));
    await settle(tester);
    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('اليوم'), findsWidgets);
    await tester.tap(find.text('الأسبوع'));
    await settle(tester);
    expect(find.text('Push-ups'), findsOneWidget);
    await tester.tap(find.text('الشهر'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await disposeTree(tester);
  });

  testWidgets('creating “15 push-ups every day” needs only the name and the target', (tester) async {
    await tester.runAsync(
      () => h.read(habitSectionsRepositoryProvider).seedDefaults(const {'anytime': 'Anytime'}),
    );
    await pumpInApp(tester, h, const HabitEditorScreen());
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Push-ups');
    final target = find.widgetWithText(TextField, 'Target');
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(target, '15');
    await tester.pump();
    final preview = find.textContaining('At least 15 reps');
    await tester.scrollUntilVisible(preview, 200, scrollable: find.byType(Scrollable).first);
    expect(preview, findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await settle(tester);
    final habits = await tester.runAsync(() => h.read(habitsRepositoryProvider).all());
    final habit = habits!.single as BuildHabit;
    expect(habit.name, 'Push-ups');
    expect(habit.goal, const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'));
    expect(habit.schedule, RecurrenceRule());
  });

  testWidgets('editor validation messages are localized', (tester) async {
    await pumpInApp(tester, h, const HabitEditorScreen(), locale: const Locale('fr'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Enregistrer'));
    await settle(tester);
    expect(find.text('Saisissez un nom'), findsOneWidget);
  });

  testWidgets('quit dashboard shows the live counter, money saved and the population-estimate label', (tester) async {
    final id = Ids.v7();
    await tester.runAsync(
      () => h.read(habitsRepositoryProvider).create(
        QuitHabit(
          id: id,
          name: 'Stop smoking',
          startDate: d(2026, 9, 21),
          sortKey: '',
          mode: QuitMode.abstain,
          quitStartedAt: DateTime.utc(2026, 9, 21, 21),
          substance: QuitSubstance.cigarettes,
          baselinePerDay: 24,
          unitCost: Decimal.parse('0.5'),
          currency: 'EUR',
          lifeMinutesPerUnit: 20,
          unit: 'cigarettes',
        ),
      ),
    );
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: id));
    await settle(tester);
    expect(find.text('Clean for'), findsOneWidget);
    expect(find.text('Money saved'), findsOneWidget);
    // 13 h × 24/day = 13 cigarettes × 0.50 €.
    expect(find.text('€6.50'), findsOneWidget);
    expect(find.text('population estimate'), findsOneWidget);
    expect(find.text('Log craving'), findsOneWidget);
    await tester.tap(find.text('Log craving'));
    await settle(tester);
    final logs = await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(id));
    expect(logs!.single.kind, HabitLogKind.craving);
    expect(logs.single.intensity, 5);
  });
}
