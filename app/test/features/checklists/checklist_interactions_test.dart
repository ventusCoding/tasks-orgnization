import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter/services.dart';
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

  Future<String> seed(
    WidgetTester tester, {
    List<NodeSpec> items = _trip,
    ChecklistSettings settings = ChecklistSettings.defaults,
  }) async {
    late String id;
    await tester.runAsync(() async {
      id = (await h.read(checklistsRepositoryProvider).create(title: 'Trip', items: items, settings: settings)).id;
    });
    return id;
  }

  Future<ChecklistTree> treeOf(WidgetTester tester, String id) async {
    late ChecklistTree t;
    await tester.runAsync(() async => t = ChecklistTree.build(await h.read(checklistItemsRepositoryProvider).items(id)));
    return t;
  }

  String render(ChecklistTree t) => t.order.map((id) => '${'  ' * t.depthOf(id)}${t[id]!.text}').join('\n');

  Finder field(String text) =>
      find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '${RowTextController.sentinel}$text');
  Finder row(Finder inner) => find.ancestor(of: inner, matching: find.byType(ItemRow));
  Finder statusOf(Finder r) => find.descendant(of: r, matching: find.byType(StatusControl));

  Future<void> openEdit(WidgetTester tester, String id, {Locale locale = const Locale('en')}) async {
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id), locale: locale);
    await settle(tester);
    await tester.tap(find.byTooltip(locale.languageCode == 'ar' ? 'تحرير' : 'Edit'));
    await settle(tester);
  }

  group('keyboard flow (T4.2.09)', () {
    testWidgets('Enter adds the next row; Tab indents; Shift+Tab outdents', (tester) async {
      final id = await seed(tester);
      await openEdit(tester, id);

      await tester.tap(field('Clothes'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      var t = await treeOf(tester, id);
      expect(render(t), 'Documents\n  Passport\n  Tickets\nClothes\n\nSnacks');

      // The new (focused) row gets text, then Tab makes it a child of "Clothes".
      await tester.enterText(field(''), 'Socks');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      t = await treeOf(tester, id);
      expect(render(t), 'Documents\n  Passport\n  Tickets\nClothes\n  Socks\nSnacks');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await settle(tester);
      t = await treeOf(tester, id);
      expect(render(t), 'Documents\n  Passport\n  Tickets\nClothes\nSocks\nSnacks');
    });

    testWidgets('Backspace at the start of a row merges it into the previous one', (tester) async {
      final id = await seed(tester);
      await openEdit(tester, id);
      await tester.tap(field('Tickets'));
      await tester.pump();
      final controller = tester.widget<EditableText>(field('Tickets')).controller;
      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'Tickets', selection: TextSelection.collapsed(offset: 0)),
      );
      await settle(tester);
      final t = await treeOf(tester, id);
      expect(render(t), 'Documents\n  PassportTickets\nClothes\nSnacks');
    });

    testWidgets('undo and redo from the app bar', (tester) async {
      final id = await seed(tester);
      await openEdit(tester, id);
      await tester.tap(field('Clothes'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      expect(render(await treeOf(tester, id)), contains('  Clothes'));
      // Both the app bar and the keyboard toolbar offer undo/redo.
      await tester.tap(find.byTooltip('Undo').first);
      await settle(tester);
      expect(render(await treeOf(tester, id)), 'Documents\n  Passport\n  Tickets\nClothes\nSnacks');
      await tester.tap(find.byTooltip('Redo').first);
      await settle(tester);
      expect(render(await treeOf(tester, id)), contains('  Clothes'));
    });
  });

  group('swipes (T4.2.10)', () {
    testWidgets('edit mode: swipe toward the end indents, back outdents', (tester) async {
      final id = await seed(tester);
      await openEdit(tester, id);
      await tester.drag(statusOf(row(field('Clothes'))), const Offset(90, 0));
      await settle(tester);
      expect(render(await treeOf(tester, id)), contains('  Clothes'));
      await tester.drag(statusOf(row(field('Clothes'))), const Offset(-90, 0));
      await settle(tester);
      expect(render(await treeOf(tester, id)), 'Documents\n  Passport\n  Tickets\nClothes\nSnacks');
    });

    testWidgets('RTL mirrors the direction (swipe left indents in Arabic)', (tester) async {
      final id = await seed(tester);
      await openEdit(tester, id, locale: const Locale('ar'));
      await tester.drag(statusOf(row(field('Clothes'))), const Offset(-90, 0));
      await settle(tester);
      expect(render(await treeOf(tester, id)), contains('  Clothes'));
    });

    testWidgets('preview: swipe right completes with an undo snackbar', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.drag(statusOf(row(find.text('Snacks'))), const Offset(90, 0));
      await settle(tester);
      var t = await treeOf(tester, id);
      expect(t.items.firstWhere((i) => i.text == 'Snacks').status, ItemStatus.completed);
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      t = await treeOf(tester, id);
      expect(t.items.firstWhere((i) => i.text == 'Snacks').status, ItemStatus.todo);
    });
  });

  group('collapse, focus and view state', () {
    testWidgets('chevron collapses a parent; Expand all restores; state survives reopening (T4.2.06, T4.2.12)',
        (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      expect(find.text('Passport'), findsOneWidget);
      await tester.tap(find.descendant(of: row(find.text('Documents')), matching: find.byIcon(Icons.expand_more)));
      await settle(tester);
      expect(find.text('Passport'), findsNothing);
      // Collapsed parents show their progress.
      expect(find.descendant(of: row(find.text('Documents')), matching: find.text('0/2')), findsOneWidget);

      // Reopen: still collapsed and still in preview.
      await pumpInApp(tester, h, const SizedBox());
      await settle(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id));
      await settle(tester);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Passport'), findsNothing);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expand all'));
      await settle(tester);
      expect(find.text('Passport'), findsOneWidget);
    });

    testWidgets('row menu Focus zooms into an item; back zooms out (T4.2.13)', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      // Preview swipe toward the start opens the row menu.
      await tester.drag(statusOf(row(find.text('Documents'))), const Offset(-90, 0));
      await settle(tester);
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Focus')));
      await settle(tester);
      expect(find.text('Clothes'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Trip'), findsOneWidget);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await settle(tester);
      expect(find.text('Clothes'), findsOneWidget);
    });
  });

  group('details & statuses', () {
    testWidgets('details sheet saves text and note as one undoable step (T4.2.15)', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.tap(find.text('Snacks'));
      await settle(tester);
      expect(find.text('Item details'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Text'), 'Healthy snacks');
      await tester.enterText(find.widgetWithText(TextField, 'Note'), 'nuts, fruit');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      var item = (await treeOf(tester, id)).items.firstWhere((i) => i.text.contains('snacks'));
      expect(item.text, 'Healthy snacks');
      expect(item.note, 'nuts, fruit');

      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await tester.tap(find.byTooltip('Undo'));
      await settle(tester);
      item = (await treeOf(tester, id)).items.firstWhere((i) => i.id == item.id);
      expect(item.text, 'Snacks');
      expect(item.note, isNull);
    });

    testWidgets('a required reason blocks Save; follow-up quick pick is stored (T4.3.02)', (tester) async {
      final id = await seed(tester, settings: const ChecklistSettings(requireReasonFor: {ItemStatus.blocked}));
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.longPress(statusOf(row(find.text('Clothes'))));
      await settle(tester);
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Blocked')));
      await settle(tester);
      expect(find.text('Skip'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(find.text('A reason is required'), findsOneWidget);
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'no size');
      await tester.tap(find.text('Tomorrow 09:00'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      final clothes = (await treeOf(tester, id)).items.firstWhere((i) => i.text == 'Clothes');
      expect(clothes.status, ItemStatus.blocked);
      expect(clothes.statusNote, 'no size');
      expect(clothes.followUpAt, DateTime.utc(2026, 9, 23, 9));

      // History shows the transition in the details sheet (T4.3.05).
      await tester.tap(find.text('Clothes'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('To do → Blocked'),
        200,
        scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first,
      );
      expect(find.text('To do → Blocked'), findsOneWidget);
    });

    testWidgets('completing a parent with open sub-items asks first (T4.3.07)', (tester) async {
      final id = await seed(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      await tester.tap(statusOf(row(find.text('Documents'))));
      await settle(tester);
      expect(find.text('Also complete 2 open sub-items?'), findsOneWidget);
      await tester.tap(find.text('Complete all'));
      await settle(tester);
      final t = await treeOf(tester, id);
      expect(t.items.where((i) => i.status == ItemStatus.completed).map((i) => i.text).toSet(), {
        'Documents',
        'Passport',
        'Tickets',
      });
    });
  });
}
