import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/goals/presentation/badge_gallery.dart';
import 'package:everslot/features/goals/presentation/badge_share_card.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/goals/application/achievement_service.dart';
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

  testWidgets('gallery: earned badges with habit and date, locked ones with progress (T5.4.09)', (tester) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: 'Meditate',
      startDate: d(2026, 9, 1),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: buildHabit().schedule,
    );
    await tester.runAsync(() async {
      await h.read(habitsRepositoryProvider).create(habit);
      final checkIn = h.read(checkInServiceProvider);
      for (var day = 7; day <= 21; day++) {
        await checkIn.markDone(habit, '2026-09-${day.toString().padLeft(2, '0')}');
      }
      await h.read(achievementServiceProvider).evaluate();
    });
    await pumpInApp(tester, h, const BadgeGalleryScreen());
    await settle(tester);
    expect(find.text(en.goalsBadgeStreak(7)), findsOneWidget);
    expect(find.textContaining('Meditate · '), findsWidgets, reason: 'habit name and date');
    final locked = find.text(en.goalsBadgeStreak(30));
    await tester.scrollUntilVisible(locked, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(en.goalsBadgeProgress('15', '30')), findsOneWidget, reason: 'progress hint');

    await tester.scrollUntilVisible(find.text(en.goalsBadgeStreak(7)), -200, scrollable: find.byType(Scrollable).first);
    final share = find.descendant(
      of: find.widgetWithText(ListTile, en.goalsBadgeStreak(7)),
      matching: find.byTooltip(en.goalsBadgeShare),
    );
    await tester.tap(share);
    await settle(tester);
    expect(find.byType(BadgeShareCard), findsOneWidget);
    expect(find.descendant(of: find.byType(BadgeShareCard), matching: find.text('Meditate')), findsNothing, reason: 'habit name off by default');
    await tester.tap(find.text(en.goalsBadgeShareHabit));
    await tester.pump();
    expect(find.descendant(of: find.byType(BadgeShareCard), matching: find.text('Meditate')), findsOneWidget);
    await disposeTree(tester);
  });
}
