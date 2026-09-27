import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/habits/presentation/quit/live_counter.dart';
import 'package:everslot/features/habits/presentation/quit_dashboard_screen.dart';
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

  Future<QuitHabit> createTracker(
    WidgetTester tester, {
    String name = 'Stop smoking',
    QuitMode mode = QuitMode.abstain,
    double? dailyLimit,
  }) async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, 21),
      sortKey: '',
      mode: mode,
      quitStartedAt: DateTime.utc(2026, 9, 21, 21),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 15,
      dailyLimit: dailyLimit,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
      unit: HabitUnits.cigarettes,
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(tracker));
    return tracker;
  }

  Future<List<HabitLogEntry>> logsOf(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(id)))!;

  Finder scrollable() => find.byType(Scrollable).first;

  group('quit editor (T5.3.01, T5.3.02)', () {
    testWidgets('presets prefill the name and unit in French; a pack price gives the unit cost', (tester) async {
      final fr = lookupAppLocalizations(const Locale('fr'));
      await pumpInApp(tester, h, const HabitEditorScreen(kind: 'quit'), locale: const Locale('fr'));
      await settle(tester);
      expect(find.text(fr.quitNameCigarettes), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, fr.quitPresetAlcohol));
      await tester.pump();
      expect(find.text(fr.quitNameAlcohol), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, fr.quitPresetCigarettes));
      await tester.pump();
      expect(find.text(fr.quitNameCigarettes), findsOneWidget);

      final baseline = find.widgetWithText(TextField, fr.quitBaseline);
      await tester.scrollUntilVisible(baseline, 200, scrollable: scrollable());
      await tester.enterText(baseline, '15');
      final price = find.widgetWithText(TextField, fr.quitPackPrice);
      await tester.scrollUntilVisible(price, 200, scrollable: scrollable());
      await tester.enterText(price, '10');
      final perPack = find.widgetWithText(TextField, fr.quitUnitsPerPack);
      await tester.scrollUntilVisible(perPack, 200, scrollable: scrollable());
      await tester.enterText(perPack, '20');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, fr.actionSave));
      await settle(tester);

      final saved = (await tester.runAsync(() => h.read(habitsRepositoryProvider).all()))!.single as QuitHabit;
      expect(saved.name, fr.quitNameCigarettes);
      expect(saved.substance, QuitSubstance.cigarettes);
      expect(saved.baselinePerDay, 15);
      expect(saved.unitCost, Decimal.parse('0.5'));
      expect(saved.quitStartedAt, DateTime.utc(2026, 9, 22, 10));
      await disposeTree(tester);
    });
  });

  group('relapse logging (T5.3.06)', () {
    for (final newAttempt in [false, true]) {
      testWidgets(newAttempt ? 'a new attempt writes a restart' : 'a slip keeps the quit date', (tester) async {
        final tracker = await createTracker(tester);
        await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
        await settle(tester);
        await tester.tap(find.text(en.quitLogRelapse));
        await settle(tester);
        expect(find.text(en.quitRelapseTitle), findsOneWidget);
        final sheet = find.byType(SingleChildScrollView).last;
        if (newAttempt) {
          final option = find.textContaining('Start a new quit attempt');
          await tester.scrollUntilVisible(option, 200, scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first);
          await tester.tap(option);
          await tester.pump();
        }
        final save = find.widgetWithText(FilledButton, en.actionSave);
        await tester.scrollUntilVisible(save, 200, scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first);
        await tester.tap(save);
        await settle(tester);
        final kinds = (await logsOf(tester, tracker.id)).map((l) => l.kind).toList();
        expect(kinds, newAttempt ? [HabitLogKind.relapse, HabitLogKind.restart] : [HabitLogKind.relapse]);
        final saved = (await tester.runAsync(() => h.read(habitsRepositoryProvider).byId(tracker.id)))! as QuitHabit;
        expect(saved.quitStartedAt, tracker.quitStartedAt, reason: 'the first quit date never changes');
        await disposeTree(tester);
      });
    }
  });

  testWidgets('reduce mode: +1 logs a use and updates "x of limit" live (T5.3.07)', (tester) async {
    final tracker = await createTracker(tester, name: 'Fewer cigarettes', mode: QuitMode.reduce, dailyLimit: 5);
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, en.quitAddUse));
    await settle(tester);
    final log = (await logsOf(tester, tracker.id)).single;
    expect((log.kind, log.value), (HabitLogKind.use, 1.0));
    expect(find.text(en.quitTodayUse('1', '5 cigarettes')), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('craving: one tap logs it, "Add details" edits the same row (T5.3.08)', (tester) async {
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
    await settle(tester);
    await tester.tap(find.text(en.quitLogCraving));
    await settle(tester);
    final first = (await logsOf(tester, tracker.id)).single;
    expect((first.kind, first.intensity), (HabitLogKind.craving, 5));
    await tester.tap(find.text(en.quitCravingDetails));
    await settle(tester);
    expect(find.text(en.quitCravingTitle), findsOneWidget);
    final yes = find.text(en.quitYes);
    final sheet = find.byType(SingleChildScrollView).last;
    await tester.scrollUntilVisible(yes, 200, scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first);
    await tester.tap(yes);
    await tester.pump();
    final save = find.widgetWithText(FilledButton, en.actionSave);
    await tester.scrollUntilVisible(save, 200, scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first);
    await tester.tap(save);
    await settle(tester);
    final edited = (await logsOf(tester, tracker.id)).single;
    expect(edited.id, first.id);
    expect(edited.resisted, isTrue);
    await disposeTree(tester);
  });

  testWidgets('quit strip shows every tracker on one ticker (T5.3.10)', (tester) async {
    await createTracker(tester, name: 'Stop smoking');
    await createTracker(tester, name: 'No sugar');
    await pumpInApp(tester, h, const Scaffold(body: Column(children: [QuitStrip()])));
    await settle(tester);
    expect(find.text('Stop smoking'), findsOneWidget);
    expect(find.text('No sugar'), findsOneWidget);
    expect(find.byType(LiveCounter), findsNWidgets(2));
    expect(find.text(en.quitAllClocks), findsOneWidget);
    await disposeTree(tester);
  });

  group('live counter (T5.3.04)', () {
    test('counter parts never go negative and split d/h/m/s', () {
      final p = counterParts(const Duration(days: 2, hours: 3, minutes: 4, seconds: 5));
      expect((p.days, p.hours, p.minutes, p.seconds), (2, 3, 4, 5));
      final z = counterParts(const Duration(seconds: -30));
      expect((z.days, z.hours, z.minutes, z.seconds), (0, 0, 0, 0));
    });

    test('Arabic-Indic digits', () {
      expect(localizeDigits('12:05', arabicIndic: true), '١٢:٠٥');
      expect(localizeDigits('12:05', arabicIndic: false), '12:05');
    });
  });
}
