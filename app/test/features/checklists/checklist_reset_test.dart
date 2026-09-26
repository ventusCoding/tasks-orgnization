import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/reset_service.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/reset.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 9), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  const routine = [
    NodeSpec(text: 'Stretch', status: ItemStatus.completed),
    NodeSpec(text: 'Water', status: ItemStatus.waiting, statusNote: 'filter'),
    NodeSpec(text: 'Journal'),
  ];

  group('reset service', () {
    test('daily reset: one run per period, statuses per mode, order kept, idempotent', () async {
      final lists = h.read(checklistsRepositoryProvider);
      final items = h.read(checklistItemsRepositoryProvider);
      final service = h.read(checklistResetServiceProvider);
      final id = (await lists.create(title: 'Morning', items: routine)).id;
      final before = await items.items(id);
      final schedule = ResetSchedule.preset(
        ResetPreset.daily,
        anchorStart: LocalDate(2026, 9, 1).atTime(LocalTime(5, 0)),
        zone: 'Europe/Paris',
      );
      await service.configure(id, schedule);
      // Configuring marks past occurrences as done: nothing resets immediately.
      expect(await service.runDue(), 0);

      h.clock.advance(const Duration(days: 1));
      expect(await service.runDue(), 1);
      expect(await service.runDue(), 0, reason: 'the same period never resets twice');

      final after = {for (final i in await items.items(id)) i.text: i};
      expect(after['Stretch']!.status, ItemStatus.todo);
      expect(after['Stretch']!.completedAt, isNull);
      expect(after['Water']!.status, ItemStatus.waiting, reason: 'completed_to_todo keeps other statuses');
      expect({for (final i in before) i.id: i.sortKey}, {for (final i in after.values) i.id: i.sortKey});

      final runs = await lists.watchRuns(id).first;
      expect(runs, hasLength(1));
      expect(runs.single.totalItems, 3);
      expect(runs.single.completedItems, 1);
      expect(runs.single.snapshot.firstWhere((e) => e.itemId == after['Stretch']!.id).status, ItemStatus.completed);
      final c = await lists.byId(id);
      expect(c!.lastResetKey, runs.single.occurrenceKey);

      // Several missed periods: only the latest one resets.
      h.clock.advance(const Duration(days: 3));
      expect(await service.runDue(), 1);
      expect(await lists.watchRuns(id).first, hasLength(2));
    });

    test('reset now records a manual run and resets everything in all_to_todo mode', () async {
      final lists = h.read(checklistsRepositoryProvider);
      final service = h.read(checklistResetServiceProvider);
      final id = (await lists.create(title: 'Weekly review', items: routine)).id;
      await service.configure(
        id,
        ResetSchedule.preset(ResetPreset.weekly, anchorStart: LocalDate(2026, 9, 20).atTime(LocalTime(18, 0))),
        mode: ResetMode.allToTodo,
      );
      await service.resetNow(id);
      final all = await h.read(checklistItemsRepositoryProvider).items(id);
      expect(all.every((i) => i.status == ItemStatus.todo && i.statusNote == null), isTrue);
      final runs = await lists.watchRuns(id).first;
      expect(runs.single.occurrenceKey, startsWith('manual:'));
    });
  });

  testWidgets('Repeat… uses the shared recurrence picker (checklist-reset mode)', (tester) async {
    late String id;
    await tester.runAsync(() async {
      id = (await h.read(checklistsRepositoryProvider).create(title: 'Morning', items: routine)).id;
    });
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
    }

    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
    await settle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Repeat…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeat…'));
    await settle();
    expect(find.text('List settings'), findsOneWidget);

    final sheetScroll = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text("Doesn't repeat"), 200, scrollable: sheetScroll);
    await tester.tap(find.text("Doesn't repeat"));
    await settle();
    final daily = find.byKey(ValueKey('recur-preset-${RecurrencePreset.daily.name}'));
    await tester.scrollUntilVisible(daily, 120, scrollable: find.byType(Scrollable).last);
    await tester.tap(daily);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recur-done')));
    await settle();

    late Checklist? c;
    await tester.runAsync(() async => c = await h.read(checklistsRepositoryProvider).byId(id));
    final schedule = ResetSchedule.fromJson(c!.resetRule);
    expect(schedule, isNotNull);
    expect(schedule!.rule.freq, Frequency.daily);
    expect(c!.resetMode, ResetMode.completedToTodo);
    expect(c!.lastResetKey, isNotNull);
  });
}
