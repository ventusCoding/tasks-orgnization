import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/item_details_sheet.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/habit_detail_screen.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../habits/support/habit_fixtures.dart';

/// T2.3.10: tag chips appear (and are editable) on checklist items and habits, like on tasks and
/// checklists.
void main() {
  late TestHarness h;
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

  testWidgets('item details: the item tags are listed and the picker adds one', (tester) async {
    late String list;
    late String item;
    await tester.runAsync(() async {
      list =
          (await h
                  .read(checklistsRepositoryProvider)
                  .create(
                    title: 'Trip',
                    items: const [NodeSpec(text: 'Passport')],
                  ))
              .id;
      item = (await h.read(checklistItemsRepositoryProvider).items(list)).single.id;
      final tags = h.read(tagsRepositoryProvider);
      final travel = await tags.create(name: 'travel');
      await tags.create(name: 'urgent');
      await tags.attach(travel.id, 'checklist_item', item);
    });
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showItemDetails(context, checklistId: list, itemId: item),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.widgetWithText(TagChip, 'travel'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Add tag'));
    await tester.tap(find.widgetWithText(ActionChip, 'Add tag'));
    await settle(tester);
    await tester.tap(find.text('urgent').last);
    await tester.pump();
    await tester.tap(find.text('Done').last);
    await settle(tester);
    final linked = await tester.runAsync(() => h.read(tagsRepositoryProvider).tagsForEntity('checklist_item', item));
    expect(linked!.map((t) => t.name), unorderedEquals(['travel', 'urgent']));
    await disposeTree(tester);
  });

  testWidgets('habit detail: tags shown under the header, editable unless archived', (tester) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: 'Read',
      startDate: d(2026, 9, 15),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: buildHabit().schedule,
    );
    await tester.runAsync(() async {
      await h.read(habitsRepositoryProvider).create(habit);
      final tags = h.read(tagsRepositoryProvider);
      await tags.attach((await tags.create(name: 'evening')).id, 'habit', habit.id);
    });
    await pumpInApp(tester, h, HabitDetailScreen(habitId: habit.id));
    await settle(tester);
    expect(find.widgetWithText(TagChip, 'evening'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Add tag'), findsOneWidget);
    await disposeTree(tester);
  });
}
