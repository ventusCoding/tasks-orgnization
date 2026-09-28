// Import UX (T4.5.08): multi-line paste into a row (preview, split or keep), the import dialog, a
// file as a new list, and converting a note body to items — each undoable.
import 'dart:convert';

import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/import_export_ui.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show render;

void main() {
  late TestHarness h;
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<String> seed(
    WidgetTester tester, {
    String? body,
    List<NodeSpec> items = const [NodeSpec(text: 'Charger')],
  }) async {
    late String id;
    await tester.runAsync(() async {
      id = (await h.read(checklistsRepositoryProvider).create(title: 'Packing', body: body, items: items)).id;
    });
    return id;
  }

  Future<String> outline(WidgetTester tester, String id) async {
    late List<ChecklistItem> items;
    await tester.runAsync(() async => items = await h.read(checklistItemsRepositoryProvider).items(id));
    return render(ChecklistTree.build(items));
  }

  Future<void> openEdit(WidgetTester tester, String id) async {
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
    await settle(tester);
    if (find.byTooltip('Edit').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
    }
  }

  /// App-bar buttons (the keyboard toolbar of a focused row has its own Undo / More).
  Finder appBar(String tooltip) => find.descendant(of: find.byType(AppBar), matching: find.byTooltip(tooltip));

  /// Opens the list menu and picks [label] (the menu scrolls on small screens).
  Future<void> menu(WidgetTester tester, String label) async {
    await tester.tap(appBar('More'));
    await settle(tester);
    await tester.ensureVisible(find.text(label));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text(label));
    await settle(tester);
  }

  Future<void> undo(WidgetTester tester) async {
    await tester.tap(appBar('Undo'));
    await settle(tester);
  }

  Finder field(String text) =>
      find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '${RowTextController.sentinel}$text');

  testWidgets('pasting several lines into a row previews the tree and splits it, undoably', (tester) async {
    h = TestHarness.create();
    final id = await seed(tester);
    await openEdit(tester, id);

    await tester.enterText(field('Charger'), '${RowTextController.sentinel}Charger\nSocks\n  Wool socks');
    await settle(tester);
    expect(find.text('2 items'), findsOneWidget, reason: 'dialog title');
    expect(find.descendant(of: find.byType(ImportPreview), matching: find.text('Wool socks')), findsOneWidget);
    await tester.tap(find.text('Split into 2 items (keep nesting)'));
    await settle(tester);
    expect(await outline(tester, id), 'Charger\nSocks\n  Wool socks');

    await undo(tester);
    expect(await outline(tester, id), 'Charger');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Keep as one item" leaves the structure alone', (tester) async {
    h = TestHarness.create();
    final id = await seed(tester);
    await openEdit(tester, id);
    await tester.enterText(field('Charger'), '${RowTextController.sentinel}Charger\nSocks\nHat');
    await settle(tester);
    await tester.tap(find.text('Keep as one item'));
    await settle(tester);
    late List<ChecklistItem> items;
    await tester.runAsync(() async => items = await h.read(checklistItemsRepositoryProvider).items(id));
    expect(items, hasLength(1));
    expect(items.single.text, startsWith('Charger'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the import dialog appends pasted Markdown with nesting, undoably', (tester) async {
    h = TestHarness.create();
    final id = await seed(tester);
    await openEdit(tester, id);
    await menu(tester, 'Import items…');
    await tester.enterText(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)),
      '- Tent\n  - Pegs',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await settle(tester);
    expect(await outline(tester, id), 'Charger\nTent\n  Pegs');

    await undo(tester);
    expect(await outline(tester, id), 'Charger');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a picked file becomes a new list (preview first); the snackbar undoes it', (tester) async {
    h = TestHarness.create(
      overrides: [
        importFileReaderProvider.overrideWithValue(
          () async => (name: 'Camping.md', bytes: utf8.encode('# Camping\n- Tent\n  - Pegs\n- Stove')),
        ),
      ],
    );
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: TextButton(onPressed: () => importFileAsNewList(context, ref), child: const Text('go')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
    expect(find.descendant(of: find.byType(ImportPreview), matching: find.text('Pegs')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await settle(tester);
    expect(find.byType(ChecklistScreen), findsOneWidget, reason: 'the new list opens');

    late List<Checklist> board;
    await tester.runAsync(() async => board = await h.read(checklistsRepositoryProvider).watchBoard().first);
    expect(board.single.title, 'Camping');
    expect(await outline(tester, board.single.id), 'Tent\n  Pegs\nStove');

    await tester.tap(find.text('Undo'));
    await settle(tester);
    await tester.runAsync(() async => board = await h.read(checklistsRepositoryProvider).watchBoard().first);
    expect(board, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a note body converts to items (indentation = nesting), undoably', (tester) async {
    h = TestHarness.create();
    final id = await seed(tester, body: 'Milk\nEggs\n  Free range', items: const []);
    await openEdit(tester, id);
    await menu(tester, 'Convert note to items');
    expect(await outline(tester, id), 'Milk\nEggs\n  Free range');
    late Checklist? list;
    await tester.runAsync(() async => list = await h.read(checklistsRepositoryProvider).byId(id));
    expect(list!.body, isNull, reason: 'the body moved into items');

    await undo(tester);
    expect(await outline(tester, id), '');
    await tester.runAsync(() async => list = await h.read(checklistsRepositoryProvider).byId(id));
    expect(list!.body, 'Milk\nEggs\n  Free range');
    await tester.pumpWidget(const SizedBox());
  });
}
