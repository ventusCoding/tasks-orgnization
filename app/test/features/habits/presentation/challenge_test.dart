import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/challenge.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/presentation/challenge_views.dart';
import 'package:everslot/features/habits/presentation/habit_detail_screen.dart';
import 'package:everslot/features/habits/presentation/habits_screen.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('challenge outcome (T5.4.05)', () {
    final service = periodService();
    final now = DateTime.utc(2026, 9, 22, 10);

    BuildHabit challenge({ChallengeSettings settings = const ChallengeSettings(), LocalDate? end}) => buildHabit(
      start: d(2026, 9, 1),
      end: end ?? d(2026, 9, 10),
      settings: HabitSettings.defaults.copyWith(challenge: settings),
    );

    HabitLogEntry log(HabitLogKind kind, int day) => HabitLogEntry(
      id: '$kind-$day',
      habitId: 'h1',
      kind: kind,
      loggedAt: DateTime.utc(2026, 9, day, 12),
      localDate: d(2026, 9, day),
      occurrenceKey: d(2026, 9, day).toIso(),
    );

    ChallengeOutcome outcome(BuildHabit habit, List<HabitLogEntry> logs) {
      final s = computeSnapshot(service, habit, const [], logs, const [], now);
      return challengeOutcome(habit, s.evaluation!, today: s.today)!;
    }

    test('every day: all ten days done succeeds; one missed day fails', () {
      final all = [for (var day = 1; day <= 10; day++) log(HabitLogKind.done, day)];
      final won = outcome(challenge(), all);
      expect((won.finished, won.success, won.doneDays, won.dueDays, won.totalDays), (true, true, 10, 10, 10));
      final lost = outcome(challenge(), all.sublist(1));
      expect((lost.success, lost.doneDays, lost.dueDays), (false, 9, 10));
    });

    test('at least 80 %: 8 of 10 succeeds; excused days are not due', () {
      const rule = ChallengeSettings(rule: ChallengeRule.minRatio, minRatio: 0.8);
      final eight = [for (var day = 1; day <= 8; day++) log(HabitLogKind.done, day)];
      expect(outcome(challenge(settings: rule), eight).success, isTrue);
      final seven = [for (var day = 1; day <= 7; day++) log(HabitLogKind.done, day)];
      expect(outcome(challenge(settings: rule), seven).success, isFalse);
      final excused = [...seven, log(HabitLogKind.excuse, 8), log(HabitLogKind.excuse, 9)];
      final o = outcome(challenge(settings: rule), excused);
      expect((o.dueDays, o.success), (8, true), reason: '7 of 8 due days = 87.5 % once two days are excused');
    });

    test('a running challenge counts its days and leaves today open', () {
      final o = outcome(challenge(end: d(2026, 9, 30)), [for (var day = 1; day <= 21; day++) log(HabitLogKind.done, day)]);
      expect((o.finished, o.dayNumber, o.daysLeft, o.doneDays, o.dueDays), (false, 22, 8, 21, 21));
    });
  });

  group('screens', () {
    late TestHarness h;
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

    Future<BuildHabit> create(WidgetTester tester, {required LocalDate end}) async {
      final habit = BuildHabit(
        id: Ids.v7(),
        name: '30 days of push-ups',
        startDate: d(2026, 9, 1),
        endDate: end,
        sortKey: '',
        goal: const HabitTarget.check(),
        schedule: buildHabit().schedule,
        settings: HabitSettings.defaults.copyWith(challenge: const ChallengeSettings()),
      );
      await tester.runAsync(() => h.read(habitsRepositoryProvider).create(habit));
      return habit;
    }

    testWidgets('a finished challenge shows its result once; Keep going clears the end date', (tester) async {
      final habit = await create(tester, end: d(2026, 9, 10));
      await tester.runAsync(() async {
        final checkIn = h.read(checkInServiceProvider);
        for (var day = 1; day <= 10; day++) {
          await checkIn.markDone(habit, '2026-09-${day.toString().padLeft(2, '0')}');
        }
      });
      await pumpInApp(tester, h, const HabitsScreen());
      await settle(tester, rounds: 12);
      expect(find.text(en.habitsChallengeSuccessTitle), findsOneWidget);
      expect(find.text(en.habitsChallengeProgress(10, 10)), findsOneWidget);
      await tester.tap(find.text(en.habitsChallengeKeepGoing));
      await settle(tester);
      final saved = (await tester.runAsync(() => h.read(habitsRepositoryProvider).byId(habit.id)))! as BuildHabit;
      expect((saved.endDate, saved.settings.challenge), (null, null));
      await disposeTree(tester);

      await pumpInApp(tester, h, const HabitsScreen());
      await settle(tester, rounds: 12);
      expect(find.text(en.habitsChallengeSuccessTitle), findsNothing, reason: 'shown once per device');
      await disposeTree(tester);
    });

    testWidgets('the detail screen shows the running challenge', (tester) async {
      final habit = await create(tester, end: d(2026, 9, 30));
      await pumpInApp(tester, h, HabitDetailScreen(habitId: habit.id));
      await settle(tester);
      expect(find.byType(ChallengeCard), findsOneWidget);
      expect(find.text(en.habitsChallengeDay(22, 30)), findsOneWidget);
      expect(find.text(en.habitsChallengeDaysLeft(8)), findsOneWidget);
      await disposeTree(tester);
    });
  });
}
