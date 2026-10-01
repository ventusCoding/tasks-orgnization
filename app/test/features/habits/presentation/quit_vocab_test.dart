import 'package:everslot/features/habits/application/habit_defaults.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/application/vocab_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:everslot/features/habits/presentation/quit/vocab_manage_screen.dart';
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

  Future<List<VocabEntry>> entries({bool archived = false}) =>
      h.read(habitVocabRepositoryProvider).watchAll(includeArchived: archived).first;

  VocabEntry named(List<VocabEntry> list, String name) => list.firstWhere((e) => e.name == name);

  QuitHabit tracker() => QuitHabit(
    id: 'q1',
    name: 'Stop smoking',
    startDate: d(2026, 9, 1),
    sortKey: 'a0',
    mode: QuitMode.abstain,
    quitStartedAt: DateTime.utc(2026, 9, 1, 8),
    substance: QuitSubstance.cigarettes,
    baselinePerDay: 10,
  );

  group('libraries (T5.3.14)', () {
    test('renaming updates past logs, archiving hides, reordering and restyling persist', () async {
      await h.read(habitDefaultsProvider).ensure(en);
      final quit = h.read(quitServiceProvider);
      await h.read(habitsRepositoryProvider).create(tracker());
      final stress = named(await entries(), en.quitTriggerStress);
      await quit.logCraving(tracker(), input: CravingInput(trigger: stress.id));

      final service = h.read(habitVocabServiceProvider);
      await service.rename(stress.id, 'Work stress');
      final craving = (await h.read(habitLogsRepositoryProvider).forHabit('q1')).single;
      expect(vocabLabel(await entries(), craving.trigger), 'Work stress', reason: 'history shows the new name');

      final coffee = named(await entries(), en.quitTriggerCoffee);
      await service.setArchived(coffee.id, archived: true);
      expect((await entries()).map((e) => e.id), isNot(contains(coffee.id)));
      expect((await entries(archived: true)).map((e) => e.id), contains(coffee.id));

      final triggers = [
        for (final e in await entries())
          if (e.kind == VocabKind.trigger) e,
      ];
      await service.reorder(triggers.last.id, triggers, 0);
      final reordered = [
        for (final e in await entries())
          if (e.kind == VocabKind.trigger) e,
      ];
      expect(reordered.first.id, triggers.last.id);

      await service.setIcon(stress.id, 'bolt');
      await service.setColor(stress.id, 0xFF3B82F6);
      final styled = named(await entries(), 'Work stress');
      expect((styled.icon, styled.color), ('bolt', 0xFF3B82F6));
    });
  });

  testWidgets('the picker lists the most-used entries first', (tester) async {
    await tester.runAsync(() async {
      await h.read(habitDefaultsProvider).ensure(en);
      await h.read(habitsRepositoryProvider).create(tracker());
      final boredom = named(await entries(), en.quitTriggerBoredom);
      for (var i = 0; i < 2; i++) {
        await h.read(quitServiceProvider).logCraving(tracker(), input: CravingInput(trigger: boredom.id));
      }
    });
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: VocabPicker(kind: VocabKind.trigger, value: null, onChanged: (_) {}, label: en.quitTrigger),
      ),
    );
    await settle(tester);
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect((chips.first.label as Text).data, en.quitTriggerBoredom);
    await disposeTree(tester);
  });

  testWidgets('manage screen: kinds, usage, add and archive', (tester) async {
    await tester.runAsync(() => h.read(habitDefaultsProvider).ensure(en));
    await pumpInApp(tester, h, const VocabManageScreen());
    await settle(tester);
    expect(find.text(en.quitTriggerStress), findsOneWidget);
    expect(find.text(en.quitVocabUses(0)), findsWidgets);

    final tile = find.widgetWithText(ListTile, en.quitTriggerStress);
    await tester.tap(find.descendant(of: tile, matching: find.byTooltip(en.actionMore)));
    await settle(tester);
    await tester.tap(find.text(en.actionArchive));
    await settle(tester);
    final body = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text(en.habitsArchived), 200, scrollable: body);
    expect(find.text(en.habitsArchived), findsOneWidget);

    await tester.tap(find.text(en.quitVocabAdd));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Deadlines');
    await tester.tap(find.widgetWithText(FilledButton, en.actionSave));
    await settle(tester);
    expect((await tester.runAsync(entries))!.any((e) => e.name == 'Deadlines' && e.kind == VocabKind.trigger), isTrue);
    await tester.scrollUntilVisible(find.text('Deadlines'), 200, scrollable: body);
    expect(find.text('Deadlines'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, en.quitVocabPlaces));
    await settle(tester);
    expect(find.text(en.quitPlaceHome), findsOneWidget);
    await disposeTree(tester);
  });
}
