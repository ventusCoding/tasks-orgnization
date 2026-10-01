import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_celebrations.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_view_settings.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/celebration_overlay.dart';
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

  Future<BuildHabit> create(String name, {LocalDateLike start = const LocalDateLike(1)}) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, start.day),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: buildHabit().schedule,
    );
    await h.read(habitsRepositoryProvider).create(habit);
    return habit;
  }

  /// Done on Sept [from]…[to].
  Future<void> doneOn(BuildHabit habit, int from, int to) async {
    final checkIn = h.read(checkInServiceProvider);
    for (var day = from; day <= to; day++) {
      await checkIn.markDone(habit, '2026-09-${day.toString().padLeft(2, '0')}');
    }
  }

  HabitCheckInEvent event(BuildHabit habit, String key) =>
      HabitCheckInEvent(habitId: habit.id, key: key, kind: HabitLogKind.done, source: 'manual', at: h.clock.nowUtc());

  group('celebration detection (T5.2.13)', () {
    test('a streak landing on a milestone celebrates once per session', () async {
      final habit = await create('Meditate', start: const LocalDateLike(16));
      await doneOn(habit, 16, 22);
      final service = h.read(celebrationServiceProvider);
      final first = await service.onCheckIn(event(habit, '2026-09-22'));
      expect(first.map((c) => (c.kind, c.count)), [(CelebrationKind.streak, 7), (CelebrationKind.perfectDay, 0)]);
      expect(
        await service.onCheckIn(event(habit, '2026-09-22')),
        isEmpty,
        reason: 'undo + redo does not celebrate twice',
      );
    });

    test('no streak celebration between milestones; clearing is never celebrated', () async {
      final habit = await create('Meditate', start: const LocalDateLike(15));
      await doneOn(habit, 15, 22);
      final service = h.read(celebrationServiceProvider);
      final earned = await service.onCheckIn(event(habit, '2026-09-22'));
      expect(earned.where((c) => c.kind == CelebrationKind.streak), isEmpty, reason: '8 days is not a milestone');
      final cleared = HabitCheckInEvent(
        habitId: habit.id,
        key: '2026-09-22',
        kind: null,
        source: 'manual',
        at: h.clock.nowUtc(),
      );
      expect(await service.onCheckIn(cleared), isEmpty);
    });

    test('perfect day: every due habit done; excused habits are not due', () async {
      final a = await create('Meditate');
      final b = await create('Read');
      final checkIn = h.read(checkInServiceProvider);
      await checkIn.markDone(a, '2026-09-22');
      final service = h.read(celebrationServiceProvider);
      expect(
        (await service.onCheckIn(event(a, '2026-09-22'))).where((c) => c.kind == CelebrationKind.perfectDay),
        isEmpty,
      );
      await checkIn.excuse(b, '2026-09-22');
      final earned = await service.onCheckIn(event(a, '2026-09-22'));
      expect(earned.map((c) => c.kind), [CelebrationKind.perfectDay]);
    });
  });

  group('overlay & hold-to-complete', () {
    Future<BuildHabit> seedSixDays(WidgetTester tester) async {
      final habit = (await tester.runAsync(() => create('Meditate', start: const LocalDateLike(16))))!;
      await tester.runAsync(() => doneOn(habit, 16, 21));
      return habit;
    }

    Future<void> pumpToday(WidgetTester tester) async {
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: CelebrationOverlay(child: TodayList(date: d(2026, 9, 22))),
        ),
      );
      await settle(tester);
    }

    Finder ring() => find.descendant(of: find.byType(HabitRow), matching: find.byType(InkResponse)).last;

    testWidgets('the 7th check-in shows the streak and perfect-day cards, then they dismiss themselves', (
      tester,
    ) async {
      await seedSixDays(tester);
      await pumpToday(tester);
      await tester.tap(ring());
      await settle(tester, rounds: 10);
      expect(find.text(en.habitsCelebrateStreak('Meditate', 7)), findsOneWidget);
      expect(find.text(en.habitsCelebratePerfectDay), findsOneWidget);
      expect(
        find.text(en.goalsBadgeUnlocked(en.goalsBadgeStreak(7))),
        findsOneWidget,
        reason: 'badge unlocked (T5.4.08)',
      );
      final scale = tester.widget<TweenAnimationBuilder<double>>(find.byType(TweenAnimationBuilder<double>).first);
      expect(scale.duration, isNot(Duration.zero), reason: 'cards scale in when motion is allowed');
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text(en.habitsCelebratePerfectDay), findsNothing);
      await disposeTree(tester);
    });

    testWidgets('with reduce motion the card appears without animation', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await seedSixDays(tester);
      await pumpToday(tester);
      await tester.tap(ring());
      await settle(tester, rounds: 10);
      expect(find.text(en.habitsCelebratePerfectDay), findsOneWidget);
      final scale = tester.widget<TweenAnimationBuilder<double>>(find.byType(TweenAnimationBuilder<double>).first);
      expect(scale.duration, Duration.zero);
      await disposeTree(tester);
    });

    testWidgets('hold to complete: a tap does nothing, holding fills the ring and checks in', (tester) async {
      final habit = (await tester.runAsync(() => create('Meditate')))!;
      await tester.runAsync(() => h.read(habitViewSettingsServiceProvider).update(holdToComplete: true));
      await pumpToday(tester);
      final holdRing = find.byType(HoldToCompleteRing);
      expect(holdRing, findsOneWidget);
      await tester.tap(holdRing);
      await settle(tester);
      expect(await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(habit.id)), isEmpty);

      final gesture = await tester.startGesture(tester.getCenter(holdRing));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await settle(tester);
      final logs = (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(habit.id)))!;
      expect(logs.single.kind, HabitLogKind.done);
      await disposeTree(tester);
    });

    testWidgets('hold to complete with reduce motion: a long press completes at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final habit = (await tester.runAsync(() => create('Meditate')))!;
      await tester.runAsync(() => h.read(habitViewSettingsServiceProvider).update(holdToComplete: true));
      await pumpToday(tester);
      await tester.longPress(find.byType(HoldToCompleteRing));
      await settle(tester);
      final logs = (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(habit.id)))!;
      expect(logs.single.kind, HabitLogKind.done);
      await disposeTree(tester);
    });
  });
}

/// A day of September 2026 (fixture helper).
class LocalDateLike {
  const LocalDateLike(this.day);

  final int day;
}
