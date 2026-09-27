import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/goals/presentation/goal_card.dart';
import 'package:everslot/features/goals/presentation/goal_editor.dart';
import 'package:everslot/features/goals/presentation/goals_screen.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/quit/rewards_section.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../habits/support/habit_fixtures.dart';

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

  Future<BuildHabit> createHabit(WidgetTester tester, {HabitTarget goal = const HabitTarget.check()}) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: 'Push-ups',
      startDate: d(2026, 9, 1),
      sortKey: '',
      goal: goal,
      schedule: buildHabit().schedule,
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(habit));
    return habit;
  }

  Future<List<Goal>> goals(WidgetTester tester) async => (await tester.runAsync(() => h.read(goalsRepositoryProvider).all()))!;

  Widget host(Widget child) => Scaffold(body: SingleChildScrollView(child: child));

  testWidgets('editor: yes/no habits offer only fitting measures; saving validates (T5.4.02)', (tester) async {
    final habit = await createHabit(tester);
    await pumpInApp(tester, h, host(HabitGoalsSection(habitId: habit.id)));
    await settle(tester);
    await tester.tap(find.byTooltip(en.goalsAdd));
    await settle(tester);
    expect(find.widgetWithText(ChoiceChip, en.goalsMetricTotalValue), findsNothing);
    expect(find.widgetWithText(ChoiceChip, en.goalsMetricCompletions), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.actionSave));
    await settle(tester);
    expect(find.text(en.goalsErrTarget), findsOneWidget, reason: 'localized validation');

    await tester.enterText(find.widgetWithText(TextField, en.goalsTarget), '20');
    await tester.tap(find.widgetWithText(FilledButton, en.actionSave));
    await settle(tester);
    final saved = (await goals(tester)).single;
    expect((saved.metric, saved.target, saved.period, saved.scopeId), (GoalMetric.completions, 20.0, GoalPeriod.month, habit.id));
    expect(find.text('${en.habitsDays(20)} · ${en.goalsMetricCompletions}'), findsOneWidget, reason: 'the card');
    await disposeTree(tester);
  });

  testWidgets('editor suggests a round target above the current pace', (tester) async {
    final habit = await createHabit(tester, goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: HabitUnits.reps));
    await tester.runAsync(() async {
      final checkIn = h.read(checkInServiceProvider);
      for (var day = 1; day <= 22; day++) {
        await checkIn.addProgress(habit, '2026-09-${day.toString().padLeft(2, '0')}', 20);
      }
    });
    await pumpInApp(tester, h, host(Builder(builder: (c) => TextButton(onPressed: () => showGoalEditor(c, habitId: habit.id), child: const Text('open')))));
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    // 440 so far + 15.7/day over 8 days ≈ 566 → a round target above it.
    final chip = find.widgetWithText(ActionChip, en.goalsUseSuggestion('800 reps'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump();
    expect(find.widgetWithText(TextField, '800'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('reaching a goal records achieved_at once and confirms (T5.4.04)', (tester) async {
    final habit = await createHabit(tester);
    await tester.runAsync(() async {
      await h.read(goalsRepositoryProvider).create(Goal(
        id: Ids.v7(),
        scopeType: GoalScopeType.habit,
        scopeId: habit.id,
        metric: GoalMetric.completions,
        target: 3,
        period: GoalPeriod.month,
        title: 'Three days',
      ));
      final checkIn = h.read(checkInServiceProvider);
      for (final day in ['2026-09-18', '2026-09-19', '2026-09-20']) {
        await checkIn.markDone(habit, day);
      }
    });
    await pumpInApp(tester, h, host(HabitGoalsSection(habitId: habit.id)));
    await settle(tester, rounds: 10);
    final goal = (await goals(tester)).single;
    expect(goal.achievedAt, DateTime.utc(2026, 9, 20), reason: 'the start of the day it was reached');
    expect(find.text(en.goalsCelebrate('Three days')), findsOneWidget);
    expect(find.text(en.goalsStatusAchieved), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('Goals screen groups goals and shows the empty state', (tester) async {
    await pumpInApp(tester, h, const GoalsScreen());
    await settle(tester);
    expect(find.text(en.goalsEmpty), findsOneWidget);
    await disposeTree(tester);

    final habit = await createHabit(tester);
    await tester.runAsync(() => h.read(goalsRepositoryProvider).create(Goal(
      id: Ids.v7(),
      scopeType: GoalScopeType.habit,
      scopeId: habit.id,
      metric: GoalMetric.streakDays,
      target: 30,
      period: GoalPeriod.allTime,
    )));
    await pumpInApp(tester, h, const GoalsScreen());
    await settle(tester);
    expect(find.text(en.goalsActive), findsOneWidget);
    expect(find.text('Push-ups'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('savings rewards: add, affordable, claim (T5.3.15)', (tester) async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: 'Stop smoking',
      startDate: d(2026, 9, 1),
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 1),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 20,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
      unit: HabitUnits.cigarettes,
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(tracker));
    await pumpInApp(tester, h, host(QuitRewardsSection(habitId: tracker.id)));
    await settle(tester);
    expect(find.text(en.quitRewardsEmpty), findsOneWidget);
    await tester.tap(find.byTooltip(en.quitRewardAdd));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, en.quitRewardName), 'Headphones');
    await tester.enterText(find.widgetWithText(TextField, en.quitRewardPrice), '50');
    await tester.tap(find.widgetWithText(FilledButton, en.actionSave));
    await settle(tester);
    final reward = (await goals(tester)).single;
    expect((reward.metric, reward.reward, reward.target, reward.period), (GoalMetric.moneySaved, 'Headphones', 50.0, GoalPeriod.allTime));
    // ≈ 214 € saved: affordable.
    expect(find.textContaining(en.quitRewardReady), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.quitRewardClaim));
    await settle(tester);
    expect((await goals(tester)).single.isAchieved, isTrue);
    expect(find.textContaining('Claimed'), findsOneWidget);
    await disposeTree(tester);
  });
}
