// Split panes (T4.5.17): two lists side by side, both editable; dragging a row into the other pane
// moves it (with its subtree) to the end of that list.
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/split_checklists_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show render;

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<String> outline(WidgetTester tester, String id) async {
    late List<ChecklistItem> items;
    await tester.runAsync(() async => items = await h.read(checklistItemsRepositoryProvider).items(id));
    return render(ChecklistTree.build(items));
  }

  Finder field(String text) =>
      find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '${RowTextController.sentinel}$text');
  Finder row(Finder inner) => find.ancestor(of: inner, matching: find.byType(ItemRow));

  testWidgets('both panes are editable and a row dragged across moves to the other list', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late String trip;
    late String camping;
    await tester.runAsync(() async {
      final repo = h.read(checklistsRepositoryProvider);
      trip = (await repo.create(
        title: 'Trip',
        items: const [
          NodeSpec(
            text: 'Documents',
            children: [NodeSpec(text: 'Passport')],
          ),
          NodeSpec(text: 'Clothes'),
        ],
      )).id;
      camping = (await repo.create(
        title: 'Camping',
        items: const [NodeSpec(text: 'Tent')],
      )).id;
    });
    await pumpInApp(tester, h, SplitChecklistsScreen(leftId: trip, rightId: camping));
    await settle(tester);
    expect(find.text('Clothes'), findsOneWidget);
    expect(find.text('Tent'), findsOneWidget);

    // Switch both panes to Edit.
    while (find.byTooltip('Edit').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Edit').first);
      await settle(tester);
    }
    expect(field('Clothes'), findsOneWidget);
    expect(field('Tent'), findsOneWidget);

    // Editing in the second pane.
    await tester.enterText(field('Tent'), '${RowTextController.sentinel}Big tent');
    await tester.pump(const Duration(milliseconds: 450));
    await settle(tester);
    expect(await outline(tester, camping), 'Big tent');

    // Drag "Documents" (with Passport) from the first pane into the second one.
    final handle = find.descendant(of: row(field('Documents')), matching: find.byIcon(Icons.drag_indicator));
    final start = tester.getCenter(handle);
    final target = tester.getCenter(row(field('Big tent'))) + const Offset(0, 40);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(Offset(start.dx + 50, start.dy));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await settle(tester);

    expect(await outline(tester, trip), 'Clothes');
    expect(await outline(tester, camping), 'Big tent\nDocuments\n  Passport');
    expect(find.byType(SnackBar), findsOneWidget, reason: 'undoable move');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
