// Tree accessibility (T4.2.18): rows announce text, level, position, collapse state, sub-items and
// the status in words; screen-reader users restructure with custom actions instead of dragging.
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show render;

final _now = DateTime.utc(2026, 9, 22, 9);

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: _now));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Documents › (Passport, Visa waiting for 4 days: embassy), Clothes.
  Future<String> seed(WidgetTester tester) async {
    late String id;
    await tester.runAsync(() async {
      id =
          (await h
                  .read(checklistsRepositoryProvider)
                  .create(
                    title: 'Trip',
                    items: const [
                      NodeSpec(
                        text: 'Documents',
                        children: [
                          NodeSpec(text: 'Passport'),
                          NodeSpec(text: 'Visa'),
                        ],
                      ),
                      NodeSpec(text: 'Clothes'),
                    ],
                  ))
              .id;
      final visa = (await h.read(checklistItemsRepositoryProvider).items(id)).firstWhere((i) => i.text == 'Visa').id;
      h.clock.set(_now.subtract(const Duration(days: 4)));
      await h.read(checklistServiceProvider).changeStatus(id, [visa], ItemStatus.waiting, note: 'embassy');
      h.clock.set(_now);
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

  List<String> actionsOf(WidgetTester tester, Pattern label) {
    final node = find.semantics.byLabel(label).evaluate().single;
    return [
      for (final id in node.getSemanticsData().customSemanticsActionIds ?? const <int>[])
        CustomSemanticsAction.getAction(id)!.label!,
    ];
  }

  testWidgets('rows announce level, position, sub-items, collapse state and the status in words', (tester) async {
    final handle = tester.ensureSemantics();
    final id = await seed(tester);
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
    await settle(tester);

    expect(find.semantics.byLabel('Visa, level 2, item 2 of 2, Waiting for 4 days: embassy'), findsOne);
    expect(find.semantics.byLabel('Passport, level 2, item 1 of 2'), findsOne);
    expect(find.semantics.byLabel('Documents, level 1, item 1 of 2, 2 sub-items'), findsOne);
    expect(find.semantics.byLabel('Clothes, level 1, item 2 of 2'), findsOne);

    // Collapsing from the screen reader: the parent then says so and its children leave the tree.
    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^Documents, level 1')),
      const CustomSemanticsAction(label: 'Collapse'),
    );
    await settle(tester);
    // A collapsed parent also reads its roll-up (progress and what waits below).
    expect(
      find.semantics.byLabel(
        RegExp(r'^Documents, level 1, item 1 of 2, collapsed, 2 sub-items\n0/2\n.*1 waiting', dotAll: true),
      ),
      findsOne,
    );
    expect(find.semantics.byLabel(RegExp('^Passport')), findsNothing);
    expect(actionsOf(tester, RegExp('^Documents, level 1')), contains('Expand'));

    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });

  testWidgets('custom actions restructure the tree without dragging', (tester) async {
    final handle = tester.ensureSemantics();
    final id = await seed(tester);
    await openEdit(tester, id);

    expect(
      actionsOf(tester, RegExp('^Clothes, level 1')),
      containsAll(['Indent', 'Outdent', 'Move up', 'Move down', 'Change status', 'Focus', 'Details']),
    );

    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^Clothes, level 1')),
      const CustomSemanticsAction(label: 'Indent'),
    );
    await settle(tester);
    expect(await outline(tester, id), 'Documents\n  Passport\n  Visa\n  Clothes');

    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^Visa, level 2')),
      const CustomSemanticsAction(label: 'Move up'),
    );
    await settle(tester);
    expect(await outline(tester, id), 'Documents\n  Visa\n  Passport\n  Clothes');

    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^Clothes, level 2')),
      const CustomSemanticsAction(label: 'Outdent'),
    );
    await settle(tester);
    expect(await outline(tester, id), 'Documents\n  Visa\n  Passport\nClothes');

    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });

  testWidgets('preview rows offer status, focus and details actions', (tester) async {
    final handle = tester.ensureSemantics();
    final id = await seed(tester);
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
    await settle(tester);
    final actions = actionsOf(tester, RegExp('^Clothes, level 1'));
    expect(actions, containsAll(['Change status', 'Focus', 'Details']));
    expect(actions, contains('Indent'), reason: 'unsorted, unfiltered lists stay restructurable');
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });
}
