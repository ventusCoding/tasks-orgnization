import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/notes_journal_screen.dart';
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

  Future<BuildHabit> create(WidgetTester tester, String name) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, 1),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: buildHabit().schedule,
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(habit));
    return habit;
  }

  testWidgets('notes journal: every note and mood, filters by habit and mood, jump to the day (T5.2.15)', (tester) async {
    final run = await create(tester, 'Run');
    final read = await create(tester, 'Read');
    await tester.runAsync(() async {
      final checkIn = h.read(checkInServiceProvider);
      await checkIn.markDone(run, '2026-09-20');
      await checkIn.setNoteAndMood(run, '2026-09-20', note: 'Felt strong', mood: 5);
      await checkIn.markDone(read, '2026-09-21');
      await checkIn.setNoteAndMood(read, '2026-09-21', note: 'Hard to focus', mood: 2);
    });
    await pumpInApp(tester, h, const NotesJournalScreen());
    await settle(tester);
    expect(find.text('Felt strong'), findsOneWidget);
    expect(find.text('Hard to focus'), findsOneWidget);
    expect(find.bySemanticsLabel(en.habitsMoodTrend), findsOneWidget, reason: 'mood sparkline');

    // The filter row scrolls horizontally (and builds lazily): scroll it to each chip first.
    Future<void> tapChip(Finder chip, {bool backwards = false}) async {
      final row = find
          .descendant(
            of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(chip, backwards ? -150 : 150, scrollable: row);
      await tester.ensureVisible(chip); // fully on screen, not just built
      await tester.pump();
      await tester.tap(chip);
      await settle(tester);
    }

    await tapChip(find.widgetWithText(ChoiceChip, 'Run'));
    expect(find.text('Hard to focus'), findsNothing);

    await tapChip(find.widgetWithText(ChoiceChip, en.habitsFilterAll), backwards: true);
    await tapChip(find.widgetWithText(ChoiceChip, '${MoodSelector.emojis[1]} ${en.moodLabel(2)}'));
    expect(find.text('Felt strong'), findsNothing);
    expect(find.text('Hard to focus'), findsOneWidget);

    await tester.tap(find.text('Hard to focus'));
    await settle(tester);
    expect(find.text(AppFormat('en').dayLong(d(2026, 9, 21))), findsWidgets, reason: 'day editor of that day');
    await disposeTree(tester);
  });

  testWidgets('empty journal', (tester) async {
    await pumpInApp(tester, h, const NotesJournalScreen());
    await settle(tester);
    expect(find.text(en.habitsJournalEmpty), findsOneWidget);
    await disposeTree(tester);
  });
}
