import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_view_settings.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/habits_screen.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
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

  Future<BuildHabit> create(
    WidgetTester tester,
    String name, {
    String? categoryId,
    SchedulePreset preset = const SchedulePreset.daily(),
  }) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, 1),
      sortKey: '',
      categoryId: categoryId,
      goal: const HabitTarget.check(),
      schedule: preset.toRule(weekStart: Weekday.monday),
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(habit));
    return habit;
  }

  Future<void> setView(
    WidgetTester tester, {
    HabitGroupBy? groupBy,
    bool? hideNotDue,
    bool? showStreaks,
    bool? compact,
  }) => tester.runAsync(
    () => h
        .read(habitViewSettingsServiceProvider)
        .update(groupBy: groupBy, hideNotDue: hideNotDue, showStreakChips: showStreaks, compact: compact),
  );

  Future<void> pumpToday(WidgetTester tester) async {
    await pumpInApp(tester, h, Scaffold(body: TodayList(date: d(2026, 9, 22))));
    await settle(tester);
  }

  testWidgets('group by category or not at all (T5.2.12)', (tester) async {
    await tester.runAsync(
      () => h.read(categoriesRepositoryProvider).seedDefaults({'work': 'Work', 'health': 'Health'}),
    );
    await create(tester, 'Stretch', categoryId: Ids.defaultCategory('user-1', 'health'));
    await create(tester, 'Inbox zero', categoryId: Ids.defaultCategory('user-1', 'work'));
    await create(tester, 'Journal');
    await setView(tester, groupBy: HabitGroupBy.category);
    await pumpToday(tester);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text(en.habitsNoCategory), findsOneWidget);

    await setView(tester, groupBy: HabitGroupBy.none);
    await settle(tester);
    expect(find.text(en.habitsAllHabits), findsOneWidget);
    expect(find.text('Health'), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('hide not-due habits, hide streak chips, compact rows (T5.2.12)', (tester) async {
    final daily = await create(tester, 'Meditate');
    await create(tester, 'Gym', preset: const SchedulePreset(SchedulePresetKind.specificDays, days: [Weekday.sunday]));
    await tester.runAsync(() async {
      final checkIn = h.read(checkInServiceProvider);
      await checkIn.markDone(daily, '2026-09-20');
      await checkIn.markDone(daily, '2026-09-21');
    });
    await pumpToday(tester);
    expect(find.text(en.habitsGroupNotDue(1)), findsOneWidget);
    expect(find.byType(StreakChip), findsOneWidget);
    expect(tester.widget<HabitRow>(find.byType(HabitRow)).compact, isFalse);

    await setView(tester, hideNotDue: true, showStreaks: false, compact: true);
    await settle(tester);
    expect(find.text(en.habitsGroupNotDue(1)), findsNothing);
    expect(find.byType(StreakChip), findsNothing);
    expect(tester.widget<HabitRow>(find.byType(HabitRow)).compact, isTrue);
    await disposeTree(tester);
  });

  testWidgets('view options sheet writes the synced settings (T5.2.12)', (tester) async {
    await create(tester, 'Meditate');
    await pumpInApp(tester, h, const HabitsScreen());
    await settle(tester);
    await tester.tap(find.byTooltip(en.actionMore));
    await settle(tester);
    await tester.tap(find.text(en.habitsViewOptions));
    await settle(tester);
    await tester.tap(find.text(en.habitsGroupByNone));
    await settle(tester);
    await tester.tap(find.text(en.habitsTapCycleDoneSkip));
    await settle(tester);
    final stored = await tester.runAsync(() => h.read(settingsRepositoryProvider).read(SettingsNs.habits));
    expect(stored!['groupBy'], 'none');
    expect(stored['matrixTapCycle'], 'done_skip_clear');
    await disposeTree(tester);
  });

  testWidgets('reorder mode: dragging a handle saves the new order (T5.2.12)', (tester) async {
    await create(tester, 'Meditate');
    await create(tester, 'Read');
    await pumpInApp(tester, h, const HabitsScreen());
    await settle(tester);
    await tester.tap(find.byTooltip(en.actionMore));
    await settle(tester);
    await tester.tap(find.text(en.habitsReorder));
    await settle(tester);
    expect(find.text(en.habitsReorderHint), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(find.bySemanticsLabel(en.habitsDragHandle('Read'))));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    final ordered = (await tester.runAsync(() => h.read(habitsRepositoryProvider).watchAll().first))!;
    expect(ordered.map((h) => h.name), ['Read', 'Meditate']);

    await tester.tap(find.text(en.habitsReorderDone));
    await settle(tester);
    expect(find.text(en.habitsReorderHint), findsNothing);
    expect(h.read(currentUserIdProvider), 'user-1');
    await disposeTree(tester);
  });
}
