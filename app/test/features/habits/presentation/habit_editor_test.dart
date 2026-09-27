import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
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

  Future<void> seedSections(WidgetTester tester) => tester.runAsync(
    () => h.read(habitSectionsRepositoryProvider).seedDefaults({
      DefaultSections.morning: 'Morning',
      DefaultSections.afternoon: 'Afternoon',
      DefaultSections.evening: 'Evening',
      DefaultSections.anytime: 'Anytime',
    }),
  );

  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200, scrollable: scrollable());
    await tester.tap(f);
    await tester.pump();
  }

  Future<BuildHabit> saveAndRead(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, en.actionSave));
    await settle(tester);
    final habits = await tester.runAsync(() => h.read(habitsRepositoryProvider).all());
    return habits!.single as BuildHabit;
  }

  group('goal types (T5.1.07)', () {
    testWidgets('duration: "Read 20 min" stores minutes', (tester) async {
      await seedSections(tester);
      await pumpInApp(tester, h, const HabitEditorScreen());
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, en.habitsFieldName), 'Read');
      await tapVisible(tester, find.text(en.habitsGoalTypeDuration));
      final target = find.widgetWithText(TextField, en.habitsFieldTarget);
      await tester.scrollUntilVisible(target, 200, scrollable: scrollable());
      await tester.enterText(target, '20');
      await tester.pump();
      final habit = await saveAndRead(tester);
      expect(habit.goal, const HabitTarget(type: HabitGoalType.duration, target: 20, unit: HabitUnits.minutes));
      // New habits land in the default "Anytime" section.
      expect(habit.sectionId, Ids.habitSection('user-1', DefaultSections.anytime));
      await disposeTree(tester);
    });

    testWidgets('numeric: "Run 5 km" with a catalog unit', (tester) async {
      await pumpInApp(tester, h, const HabitEditorScreen());
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, en.habitsFieldName), 'Run');
      await tapVisible(tester, find.text(en.habitsGoalTypeNumeric));
      final target = find.widgetWithText(TextField, en.habitsFieldTarget);
      await tester.scrollUntilVisible(target, 200, scrollable: scrollable());
      await tester.enterText(target, '5');
      await tester.pump();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, en.habitsUnitKm));
      final habit = await saveAndRead(tester);
      expect(habit.goal, const HabitTarget(type: HabitGoalType.numeric, target: 5, unit: HabitUnits.km));
      await disposeTree(tester);
    });

    testWidgets('yes/no goal needs no target', (tester) async {
      await pumpInApp(tester, h, const HabitEditorScreen());
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, en.habitsFieldName), 'Journal');
      await tapVisible(tester, find.text(en.habitsGoalTypeCheck));
      expect(find.widgetWithText(TextField, en.habitsFieldTarget), findsNothing);
      final habit = await saveAndRead(tester);
      expect(habit.goal, const HabitTarget.check());
      await disposeTree(tester);
    });

    testWidgets('an "at most 0" limit suggests a quit tracker (T5.1.10)', (tester) async {
      await pumpInApp(tester, h, const HabitEditorScreen());
      await settle(tester);
      await tapVisible(tester, find.text(en.habitsOpAtMost));
      final target = find.widgetWithText(TextField, en.habitsFieldTarget);
      await tester.scrollUntilVisible(target, 200, scrollable: scrollable());
      await tester.enterText(target, '0');
      await tester.pump();
      expect(find.text(en.habitsLimitZeroHint), findsOneWidget);
      expect(find.text(en.habitsCreateQuitInstead), findsOneWidget);
      await disposeTree(tester);
    });
  });

  group('schedule presets round-trip (T5.1.08)', () {
    final cases = <String, SchedulePreset>{
      en.habitsPresetWeekdays: const SchedulePreset(SchedulePresetKind.weekdays),
      en.habitsPresetEveryNDays: const SchedulePreset(SchedulePresetKind.everyNDays, n: 3),
      en.habitsPresetTimesPerWeek: const SchedulePreset(SchedulePresetKind.timesPerWeek, n: 3),
      en.habitsPresetSpecificTimes: SchedulePreset(
        SchedulePresetKind.specificTimes,
        times: [LocalTime(8, 0), LocalTime(20, 0)],
      ),
      en.habitsPresetInterval: SchedulePreset(
        SchedulePresetKind.interval,
        everyMinutes: 60,
        windowStart: LocalTime(9, 0),
        windowEnd: LocalTime(18, 0),
      ),
      en.habitsPresetMonthlyDay: const SchedulePreset(SchedulePresetKind.monthlyDay, monthDay: 15),
    };
    for (final c in cases.entries) {
      testWidgets('reopening a "${c.key}" habit shows that preset, not Custom', (tester) async {
        final id = Ids.v7();
        await tester.runAsync(
          () => h
              .read(habitsRepositoryProvider)
              .create(
                buildHabit(
                  id: id,
                  name: 'Habit',
                  start: d(2026, 9, 1),
                  schedule: c.value.toRule(weekStart: Weekday.monday),
                ).copyWith(sortKey: ''),
              ),
        );
        await pumpInApp(tester, h, HabitEditorScreen(habitId: id));
        await settle(tester);
        final chip = find.widgetWithText(ChoiceChip, c.key);
        await tester.scrollUntilVisible(chip, 200, scrollable: scrollable());
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
        expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, en.habitsPresetCustom)).selected, isFalse);
        // Saving without changes keeps the rule (and adds no revision).
        await tester.tap(find.widgetWithText(TextButton, en.actionSave));
        await settle(tester);
        final saved = await tester.runAsync(() => h.read(habitsRepositoryProvider).byId(id));
        expect((saved! as BuildHabit).schedule, c.value.toRule(weekStart: Weekday.monday));
        final revisions = await tester.runAsync(() => h.read(habitsRepositoryProvider).revisionsFor(id));
        expect(revisions, hasLength(1));
        await disposeTree(tester);
      });
    }

    testWidgets('"Custom…" opens the shared recurrence picker in habit mode', (tester) async {
      await pumpInApp(tester, h, const HabitEditorScreen());
      await settle(tester);
      // The unit picker has a "Custom…" chip too: the schedule one comes last.
      await tester.scrollUntilVisible(find.text(en.habitsPresetMonthlyWeekday), 200, scrollable: scrollable());
      final custom = find.widgetWithText(ChoiceChip, en.habitsPresetCustom).last;
      await tester.ensureVisible(custom);
      await tester.pump();
      await tester.tap(custom);
      await settle(tester);
      expect(find.text(en.recurPickerTitle), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('choosing "N× a week" previews quota periods', (tester) async {
      await pumpInApp(tester, h, const HabitEditorScreen());
      await settle(tester);
      await tapVisible(tester, find.widgetWithText(ChoiceChip, en.habitsPresetTimesPerWeek));
      await settle(tester);
      expect(find.text(en.habitsTimesPerWeek(3)), findsWidgets);
      final preview = find.text(en.habitsPreviewTitle);
      await tester.scrollUntilVisible(preview, 200, scrollable: scrollable());
      expect(preview, findsOneWidget);
      await disposeTree(tester);
    });
  });

  testWidgets('section picker moves the habit to Morning (T5.1.11)', (tester) async {
    await seedSections(tester);
    await pumpInApp(tester, h, const HabitEditorScreen());
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, en.habitsFieldName), 'Stretch');
    await tapVisible(tester, find.text(en.habitsFieldSection));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Morning'));
    await settle(tester);
    await tapVisible(tester, find.text(en.habitsGoalTypeCheck));
    final habit = await saveAndRead(tester);
    expect(habit.sectionId, Ids.habitSection('user-1', DefaultSections.morning));
    await disposeTree(tester);
  });

  testWidgets('advanced options: skip policy and streak freezes are saved (T5.1.12)', (tester) async {
    await pumpInApp(tester, h, const HabitEditorScreen());
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, en.habitsFieldName), 'Gym');
    await tapVisible(tester, find.text(en.habitsGoalTypeCheck));
    await tapVisible(tester, find.text(en.habitsAdvancedTitle));
    await settle(tester);
    await tapVisible(tester, find.text(en.habitsSkipBreaks));
    final freezes = find.ancestor(of: find.text(en.habitsFreezes), matching: find.byType(Row));
    await tester.tap(find.descendant(of: freezes, matching: find.byIcon(Icons.add)));
    await tester.pump();
    final habit = await saveAndRead(tester);
    expect(habit.skipPolicy, SkipPolicy.breaks);
    expect(habit.freezesPerMonth, 1);
    await disposeTree(tester);
  });

  testWidgets('Arabic editor renders RTL without exceptions', (tester) async {
    await pumpInApp(tester, h, const HabitEditorScreen(), locale: const Locale('ar'));
    await settle(tester);
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(ar.habitsEditorNewTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(ListView).first)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await disposeTree(tester);
  });
}
