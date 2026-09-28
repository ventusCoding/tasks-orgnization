import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/habit_detail_screen.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
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
      now: DateTime.utc(2026, 9, 22, 18),
      overrides: [inboxUnreadCountProvider.overrideWith((ref) => Stream.value(0))],
    ),
  );
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester, {int rounds = 8}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<BuildHabit> seed(WidgetTester tester) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: 'Push-ups',
      startDate: d(2026, 9, 15),
      sortKey: '',
      goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'),
      schedule: buildHabit().schedule,
    );
    await tester.runAsync(() async {
      await h.read(habitsRepositoryProvider).create(habit);
      final checkIn = h.read(checkInServiceProvider);
      for (var day = 15; day <= 21; day++) {
        await checkIn.addProgress(habit, '2026-09-$day', 20);
      }
      await checkIn.addProgress(habit, '2026-09-22', 40);
    });
    return habit;
  }

  testWidgets('a new best day shows "New record!" on the detail screen and the Today row (T5.4.10)', (tester) async {
    final habit = await seed(tester);
    await pumpInApp(tester, h, HabitDetailScreen(habitId: habit.id));
    await settle(tester);
    expect(find.text(en.habitsRecordNew), findsWidgets);
    expect(find.text(en.habitsRecordBestDay('40 reps')), findsOneWidget);
    await disposeTree(tester);

    await pumpInApp(tester, h, Scaffold(body: TodayList(date: d(2026, 9, 22))));
    await settle(tester);
    expect(find.text(en.habitsRecordNew), findsOneWidget, reason: 'record pill on the row');
    await disposeTree(tester);
  });
}
