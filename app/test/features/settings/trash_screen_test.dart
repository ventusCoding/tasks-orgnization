import 'package:everslot/core/providers.dart';
import 'package:everslot/features/settings/presentation/trash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';
import 'support/settings_app.dart';

void main() {
  Future<void> seed(TestHarness h) async {
    final w = h.read(syncWriterProvider);
    await w.run((tx) async {
      await tx.insert('checklists', 'L', {'title': 'Groceries', 'sort_key': 'a0'});
      await tx.insert('checklist_items', 'A', {'checklist_id': 'L', 'sort_key': 'a0', 'text': 'Fruit'});
      await tx.insert('checklist_items', 'A1', {'checklist_id': 'L', 'parent_id': 'A', 'sort_key': 'a0', 'text': 'Apples'});
      await tx.insert('tasks', 'T', {'series_id': 'T', 'title': 'Call mom'});
    });
    h.clock.advance(const Duration(hours: 2));
    await w.run((tx) async {
      await tx.softDelete('checklist_items', 'A1');
      await tx.softDelete('checklist_items', 'A');
    });
    h.clock.advance(const Duration(hours: 1));
    await w.run((tx) => tx.softDelete('tasks', 'T'));
  }

  Future<void> openMenu(WidgetTester tester, String id, String item) async {
    await tester.tap(find.byKey(ValueKey('trash-menu-$id')));
    await pumpUi(tester);
    await tester.tap(find.byKey(ValueKey(item)));
    await pumpUi(tester);
  }

  testWidgets('lists deletions newest first; restore and delete forever (T8.3.06)', (tester) async {
    final h = TestHarness.create();
    await tester.runAsync(() => seed(h));
    await pumpInApp(tester, h, const TrashScreen());
    await settle(tester);
    expect(find.text('Call mom'), findsOneWidget);
    expect(find.text('Fruit'), findsOneWidget);
    expect(find.textContaining('List item · Groceries'), findsOneWidget);
    expect(find.textContaining('+1 related item'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('trash-T'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('trash-A'))).dy),
    );

    await openMenu(tester, 'A', 'trash-restore');
    await settle(tester);
    expect(find.text('Restored'), findsOneWidget);
    expect(find.text('Fruit'), findsNothing);

    await openMenu(tester, 'T', 'trash-delete');
    expect(find.text('Delete "Call mom" forever?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete forever')));
    await settle(tester);
    expect(find.text('The trash is empty'), findsOneWidget);
    final left = await tester.runAsync(() => h.db.customSelect("SELECT COUNT(*) AS n FROM tasks WHERE id = 'T'").getSingle());
    expect(left!.data['n'], 0);
    await finish(tester, h);
  });

  testWidgets('empty trash asks first, then purges everything', (tester) async {
    final h = TestHarness.create();
    await tester.runAsync(() => seed(h));
    await pumpInApp(tester, h, const TrashScreen());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('trash-empty')));
    await pumpUi(tester);
    expect(find.textContaining('2 items will be deleted forever'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete forever')));
    await settle(tester);
    expect(find.text('The trash is empty'), findsOneWidget);
    await finish(tester, h);
  });

  testWidgets('Arabic layout', (tester) async {
    final h = TestHarness.create();
    await tester.runAsync(() => seed(h));
    await pumpInApp(tester, h, const TrashScreen(), locale: const Locale('ar'));
    await settle(tester);
    expect(find.text('المهملات'), findsWidgets);
    expect(find.textContaining('عنصر قائمة'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester, h);
  });
}
