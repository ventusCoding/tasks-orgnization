import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/smart_list_screen.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

const _trip = [
  NodeSpec(
    text: 'Documents',
    children: [
      NodeSpec(text: 'Passport'),
      NodeSpec(text: 'Tickets'),
    ],
  ),
  NodeSpec(text: 'Clothes'),
];

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<String> seed(WidgetTester tester, {String title = 'Trip', List<NodeSpec> items = _trip}) async {
    late String id;
    await tester.runAsync(() async {
      id = (await h.read(checklistsRepositoryProvider).create(title: title, items: items)).id;
    });
    return id;
  }

  Future<List<ChecklistItem>> items(WidgetTester tester, String id) async {
    late List<ChecklistItem> out;
    await tester.runAsync(() async => out = await h.read(checklistItemsRepositoryProvider).items(id));
    return out;
  }

  Finder field(String text) =>
      find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '${RowTextController.sentinel}$text');

  Finder rowOf(String text) => find.ancestor(of: find.text(text), matching: find.byType(ItemRow));

  testWidgets('edit mode renders nested rows; Add item appends a focused row whose text is saved', (tester) async {
    final id = await seed(tester);
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
    await settle(tester);
    // Existing lists open in their default mode (preview); switch to Edit.
    expect(find.text('Documents'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);

    expect(field('Documents'), findsOneWidget);
    expect(field('Passport'), findsOneWidget);
    expect(field('Clothes'), findsOneWidget);

    await tester.tap(find.text('Add item'));
    await settle(tester);
    final empty = field('');
    expect(empty, findsOneWidget);
    await tester.enterText(empty, 'Sunscreen');
    await tester.pump(const Duration(milliseconds: 450));
    await settle(tester);

    final all = await items(tester, id);
    expect(all.map((i) => i.text), contains('Sunscreen'));
    final sunscreen = all.firstWhere((i) => i.text == 'Sunscreen');
    expect(sunscreen.parentId, isNull);
  });

  testWidgets('preview: tap completes, long-press marks waiting with a reason', (tester) async {
    final id = await seed(tester);
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
    await settle(tester);

    await tester.tap(find.descendant(of: rowOf('Clothes'), matching: find.byType(StatusControl)));
    await settle(tester);
    var all = await items(tester, id);
    expect(all.firstWhere((i) => i.text == 'Clothes').status, ItemStatus.completed);

    await tester.longPress(find.descendant(of: rowOf('Passport'), matching: find.byType(StatusControl)));
    await settle(tester);
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Waiting')));
    await settle(tester);
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'supplier reply');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    all = await items(tester, id);
    final passport = all.firstWhere((i) => i.text == 'Passport');
    expect(passport.status, ItemStatus.waiting);
    expect(passport.statusNote, 'supplier reply');
    expect(find.text('supplier reply'), findsOneWidget);
    expect(find.textContaining('Waiting ·'), findsWidgets);
  });

  testWidgets('focus mode from the route shows breadcrumbs; back zooms out', (tester) async {
    final id = await seed(tester);
    final documents = (await items(tester, id)).firstWhere((i) => i.text == 'Documents').id;
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, focusItemId: documents, preview: true));
    await settle(tester);

    expect(find.widgetWithText(TextButton, 'Trip'), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Clothes'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Trip'));
    await settle(tester);
    expect(find.text('Clothes'), findsOneWidget);
  });

  testWidgets('unknown and deleted lists get friendly pages; archive/templates ids resolve', (tester) async {
    await pumpInApp(tester, h, const ChecklistScreen(checklistId: 'missing'));
    await settle(tester);
    expect(find.text("This list doesn't exist"), findsOneWidget);

    final id = await seed(tester);
    await tester.runAsync(() => h.read(checklistsRepositoryProvider).delete(id));
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
    await settle(tester);
    expect(find.text('This list is in the trash'), findsOneWidget);

    await pumpInApp(tester, h, const ChecklistScreen(checklistId: 'archive'));
    await settle(tester);
    expect(find.text('No archived lists'), findsOneWidget);
  });

  testWidgets('a new card left empty writes nothing; typing a title creates it', (tester) async {
    h.read(pendingCardProvider.notifier).set(const PendingCard(id: 'new-card'));
    await pumpInApp(tester, h, const ChecklistScreen(checklistId: 'new-card'));
    await settle(tester);
    await pumpInApp(tester, h, const SizedBox());
    await settle(tester);
    late Checklist? c;
    await tester.runAsync(() async => c = await h.read(checklistsRepositoryProvider).byId('new-card'));
    expect(c, isNull);

    h.read(pendingCardProvider.notifier).set(const PendingCard(id: 'new-card-2'));
    await pumpInApp(tester, h, const ChecklistScreen(checklistId: 'new-card-2'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Groceries');
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
    await tester.runAsync(() async => c = await h.read(checklistsRepositoryProvider).byId('new-card-2'));
    expect(c?.title, 'Groceries');
  });

  testWidgets('smart list shows waiting items with breadcrumbs and changes status', (tester) async {
    await seed(
      tester,
      items: const [
        NodeSpec(
          text: 'Documents',
          children: [NodeSpec(text: 'Visa', status: ItemStatus.waiting, statusNote: 'embassy')],
        ),
      ],
    );
    await pumpInApp(tester, h, const SmartListScreen(kind: 'waiting'));
    await settle(tester);
    expect(find.text('Visa'), findsOneWidget);
    expect(find.text('Trip › Documents'), findsOneWidget);
    expect(find.text('embassy'), findsOneWidget);

    await tester.tap(find.byType(StatusControl));
    await settle(tester);
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Completed')));
    await settle(tester);
    expect(find.text('Visa'), findsNothing);
    expect(find.text('Nothing here — nice.'), findsOneWidget);

    await pumpInApp(tester, h, const SmartListScreen(kind: 'nope'));
    await settle(tester);
    expect(find.text('Unknown smart list'), findsOneWidget);
  });
}
