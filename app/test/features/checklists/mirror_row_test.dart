import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/mirror_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// A mirror row (T4.5.16) renders its original's text and children; tapping a child edits the
/// original.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester, {int rounds = 8}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('mirror row: original text, children preview, edit-through toggle', (tester) async {
    late String home;
    late String today;
    late String groceries;
    await tester.runAsync(() async {
      final repo = h.read(checklistsRepositoryProvider);
      home = (await repo.create(
        title: 'Home',
        items: const [
          NodeSpec(
            text: 'Groceries',
            children: [
              NodeSpec(text: 'Milk'),
              NodeSpec(text: 'Eggs'),
            ],
          ),
        ],
      )).id;
      today = (await repo.create(
        title: 'Today',
        items: const [NodeSpec(text: 'Plan')],
      )).id;
      groceries = (await h.read(checklistItemsRepositoryProvider).items(home))
          .firstWhere((i) => i.text == 'Groceries')
          .id;
      await h.read(checklistServiceProvider).createMirror(groceries, targetChecklistId: today);
    });

    await pumpInApp(tester, h, ChecklistScreen(checklistId: today, preview: true));
    await settle(tester);

    expect(find.byType(MirrorPreview), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Mirror · Home'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Eggs'), findsOneWidget);

    await tester.tap(find.text('Milk'));
    await settle(tester);
    final milk = (await tester.runAsync(() => h.read(checklistItemsRepositoryProvider).items(home)))!
        .firstWhere((i) => i.text == 'Milk');
    expect(milk.status, ItemStatus.completed);
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: find.byKey(ValueKey('mirror-child-${milk.id}')), matching: find.byType(Icon)),
          )
          .icon,
      Icons.check_box,
    );
    await tester.pump(const Duration(seconds: 6));
  });
}
