import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_card.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/lists_board_screen.dart';
import 'package:everslot/features/checklists/presentation/smart_list_screen.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

const _trip = [
  NodeSpec(
    text: 'Documents',
    children: [
      NodeSpec(text: 'Passport'),
      NodeSpec(text: 'Tickets', status: ItemStatus.waiting, statusNote: 'agency'),
    ],
  ),
  NodeSpec(text: 'Clothes'),
  NodeSpec(text: 'Snacks'),
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
    await tester.runAsync(
      () async => id = (await h.read(checklistsRepositoryProvider).create(title: title, items: items)).id,
    );
    return id;
  }

  Future<ChecklistTree> treeOf(WidgetTester tester, String id) async {
    late ChecklistTree t;
    await tester.runAsync(
      () async => t = ChecklistTree.build(await h.read(checklistItemsRepositoryProvider).items(id)),
    );
    return t;
  }

  Future<List<Checklist>> board(WidgetTester tester) async {
    late List<Checklist> out;
    await tester.runAsync(() async => out = await h.read(checklistsRepositoryProvider).watchBoard().first);
    return out;
  }

  String render(ChecklistTree t) => t.order.map((id) => '${'  ' * t.depthOf(id)}${t[id]!.text}').join('\n');

  Finder field(String text) =>
      find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '${RowTextController.sentinel}$text');
  Finder row(Finder inner) => find.ancestor(of: inner, matching: find.byType(ItemRow));

  /// The shared app-bar actions keep an inbox badge provider (with a refresh timer) alive:
  /// dispose it before the test ends.
  Future<void> closeBoard(WidgetTester tester) async {
    await pumpInApp(tester, h, const SizedBox());
    await settle(tester);
    h.container.invalidate(inboxUnreadCountProvider);
    // Runs the database's zero-delay stream-close timer (a bare pump() only flushes microtasks).
    await tester.pump(const Duration(milliseconds: 10));
  }

  void wide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('board (T4.1.07–T4.1.10)', () {
    testWidgets('empty state creates a list; the card shows title, rows and progress', (tester) async {
      await pumpInApp(tester, h, const ListsBoardScreen());
      await settle(tester);
      expect(find.text('No lists yet'), findsOneWidget);

      await tester.tap(find.text('Create your first list'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'Groceries');
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pageBack();
      await settle(tester);
      expect(find.widgetWithText(ChecklistCard, 'Groceries'), findsOneWidget);

      await seed(tester);
      await settle(tester);
      final card = find.widgetWithText(ChecklistCard, 'Trip');
      expect(card, findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('Passport')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('0/4')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('1 waiting')), findsOneWidget);
      await closeBoard(tester);
    });

    testWidgets('grid/list toggle is saved in the synced board config', (tester) async {
      await seed(tester);
      await pumpInApp(tester, h, const ListsBoardScreen());
      await settle(tester);
      await tester.tap(find.byTooltip('List view'));
      await settle(tester);
      late BoardConfig config;
      await tester.runAsync(() async => config = await h.read(boardConfigStoreProvider).watch().first);
      expect(config.layout, BoardLayout.list);
      expect(find.byTooltip('Grid view'), findsOneWidget);
      await closeBoard(tester);
    });

    testWidgets('pin moves a card to Pinned; archive hides it with undo', (tester) async {
      await seed(
        tester,
        title: 'Alpha',
        items: const [NodeSpec(text: 'a')],
      );
      await seed(
        tester,
        title: 'Beta',
        items: const [NodeSpec(text: 'b')],
      );
      await pumpInApp(tester, h, const ListsBoardScreen());
      await settle(tester);
      expect(find.text('Pinned'), findsNothing);

      await tester.tap(
        find.descendant(of: find.widgetWithText(ChecklistCard, 'Alpha'), matching: find.byTooltip('List actions')),
      );
      await settle(tester);
      await tester.tap(find.text('Pin'));
      await settle(tester);
      expect(find.text('Pinned'), findsOneWidget);
      expect((await board(tester)).firstWhere((c) => c.title == 'Alpha').isPinned, isTrue);

      await tester.tap(
        find.descendant(of: find.widgetWithText(ChecklistCard, 'Beta'), matching: find.byTooltip('List actions')),
      );
      await settle(tester);
      await tester.tap(find.text('Archive'));
      await settle(tester);
      expect(find.widgetWithText(ChecklistCard, 'Beta'), findsNothing);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.widgetWithText(ChecklistCard, 'Beta'), findsOneWidget);
      await closeBoard(tester);
    });

    testWidgets('long-press drag reorders cards within their section', (tester) async {
      await seed(
        tester,
        title: 'Alpha',
        items: const [NodeSpec(text: 'a')],
      );
      await seed(
        tester,
        title: 'Beta',
        items: const [NodeSpec(text: 'b')],
      );
      await seed(
        tester,
        title: 'Gamma',
        items: const [NodeSpec(text: 'c')],
      );
      await pumpInApp(tester, h, const ListsBoardScreen());
      await tester.tap(find.byTooltip('List view'));
      await settle(tester);
      expect((await board(tester)).map((c) => c.title), ['Gamma', 'Beta', 'Alpha']);

      final from = tester.getCenter(find.widgetWithText(ChecklistCard, 'Alpha'));
      final to = tester.getCenter(find.widgetWithText(ChecklistCard, 'Gamma'));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(to + const Offset(0, 2));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await settle(tester);
      expect((await board(tester)).map((c) => c.title), ['Alpha', 'Gamma', 'Beta']);
      await closeBoard(tester);
    });

    testWidgets('smart chips count waiting items and open the smart list', (tester) async {
      await seed(tester);
      await pumpInApp(tester, h, const ListsBoardScreen());
      await settle(tester);
      await tester.tap(find.text('Waiting · 1'));
      await settle(tester);
      expect(find.byType(SmartListScreen), findsOneWidget);
      expect(find.text('Tickets'), findsOneWidget);
      await closeBoard(tester);
    });
  });

  group('outline drag & drop (T4.2.11)', () {
    testWidgets('drag a row up keeps its depth; a horizontal offset reparents it', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
      await settle(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      Future<void> dragHandle(String text, Finder over, {double dx = 0}) async {
        final handle = find.descendant(of: row(field(text)), matching: find.byIcon(Icons.drag_indicator));
        final start = tester.getCenter(handle);
        final targetTop = tester.getTopLeft(over).dy + 4;
        final gesture = await tester.startGesture(start);
        await tester.pump(const Duration(milliseconds: 700));
        await gesture.moveTo(Offset(start.dx, targetTop));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(Offset(start.dx + dx, targetTop + 1));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await settle(tester);
      }

      await dragHandle('Snacks', row(field('Clothes')));
      expect(render(await treeOf(tester, id)), 'Documents\n  Passport\n  Tickets\nSnacks\nClothes');

      // Dropping under "Tickets" with a rightward offset nests it one level deeper.
      await dragHandle('Clothes', row(field('Snacks')), dx: 40);
      expect(render(await treeOf(tester, id)), 'Documents\n  Passport\n  Tickets\n    Clothes\nSnacks');
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('views (T4.5.02–T4.5.04)', () {
    testWidgets('kanban shows status columns; dropping a card runs the transition', (tester) async {
      wide(tester);
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.tap(find.byTooltip('Outline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kanban').last);
      await settle(tester);
      for (final label in ['To do', 'In progress', 'Waiting', 'Blocked', 'Completed']) {
        expect(find.text(label), findsWidgets);
      }
      // Leaves only by default: "Documents" (a parent) only appears as the breadcrumb of its two
      // children, never as a card.
      expect(find.text('Documents'), findsNWidgets(2));
      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Clothes'), findsOneWidget);

      final from = tester.getCenter(find.text('Clothes'));
      final completedHeader = find.text('Completed').last;
      final to = tester.getCenter(completedHeader) + const Offset(0, 120);
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await settle(tester);
      final t = await treeOf(tester, id);
      expect(t.items.firstWhere((i) => i.text == 'Clothes').status, ItemStatus.completed);

      // The choice is remembered per checklist.
      await pumpInApp(tester, h, const SizedBox());
      await settle(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
      await settle(tester);
      expect(find.text('Leaves only'), findsOneWidget);
    });

    testWidgets('gallery view: only items with images by default', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.tap(find.byTooltip('Outline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gallery').last);
      await settle(tester);
      expect(find.text('No items with images'), findsOneWidget);
      await tester.tap(find.text('Only items with images'));
      await settle(tester);
      expect(find.text('Clothes'), findsOneWidget);
    });
  });

  group('selection (T4.2.16)', () {
    testWidgets('select rows, then change their status in one step', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await settle(tester);
      await tester.tap(find.text('Clothes'));
      await tester.tap(find.text('Snacks'));
      await settle(tester);
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.byTooltip('Change status'));
      await settle(tester);
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Completed')));
      await settle(tester);
      final t = await treeOf(tester, id);
      expect(t.items.where((i) => i.status == ItemStatus.completed).map((i) => i.text).toSet(), {'Clothes', 'Snacks'});
      // One undo step for the whole bulk change.
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect((await treeOf(tester, id)).items.where((i) => i.status == ItemStatus.completed), isEmpty);
      expect(find.byType(StatusControl), findsNothing, reason: 'still selecting: checkboxes instead');
    });
  });
}
