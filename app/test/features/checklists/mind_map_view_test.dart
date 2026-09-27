// Mind map view (T4.5.14): live map of the outline — shared collapse state, focused branch dims
// the others, tapping a node reveals it in the outline; goldens light/dark × LTR/RTL.
@Tags(['golden'])
library;

import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/mind_map_view.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'status_gallery_support.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: galleryNow));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

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
                          NodeSpec(text: 'Passport', status: ItemStatus.completed),
                          NodeSpec(text: 'Visa', status: ItemStatus.waiting),
                        ],
                      ),
                      NodeSpec(
                        text: 'Clothes',
                        children: [NodeSpec(text: 'Socks')],
                      ),
                    ],
                  ))
              .id;
    });
    return id;
  }

  String idOf(String id, String text) {
    final t = h.read(checklistTreeProvider(id))!;
    return t.order.firstWhere((i) => t[i]!.text == text);
  }

  double opacityOf(WidgetTester tester, String label) {
    final node = find.bySemanticsLabel(RegExp('^$label'));
    return tester.widget<Opacity>(find.ancestor(of: node, matching: find.byType(Opacity)).first).opacity;
  }

  testWidgets('the view switcher shows the map; collapse, focus dimming and tap to outline', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    final id = await seed(tester);
    await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
    await settle(tester);
    final editor = h.read(checklistEditorProvider(id).notifier);
    await tester.runAsync(() => editor.setViewType(ChecklistViewType.mindMap));
    await settle(tester);
    expect(find.byType(MindMapView), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Trip')), findsOneWidget, reason: 'the list root node');
    expect(find.bySemanticsLabel(RegExp('^Visa, Waiting')), findsOneWidget);

    // Collapsing a node hides its subtree (and the outline shares the state).
    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^Documents')),
      const CustomSemanticsAction(label: 'Collapse'),
    );
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp('^Visa')), findsNothing);
    expect(h.read(collapsedNodesProvider(id)).value, contains(idOf(id, 'Documents')));
    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^Documents')),
      const CustomSemanticsAction(label: 'Expand'),
    );
    await settle(tester);

    // A focused branch dims the others.
    await tester.runAsync(() => editor.zoomTo(idOf(id, 'Clothes')));
    await settle(tester);
    expect(opacityOf(tester, 'Socks'), 1);
    expect(opacityOf(tester, 'Visa'), lessThan(1));
    await tester.runAsync(() => editor.zoomTo(null));
    await settle(tester);

    // Tapping a node shows it in the outline.
    await tester.tap(find.bySemanticsLabel(RegExp('^Visa')));
    await settle(tester);
    expect(find.byType(MindMapView), findsNothing);
    expect(h.read(checklistEditorProvider(id)).viewType, ChecklistViewType.outline);
    expect(find.text('Visa'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });

  for (final (dark, rtl) in [(false, false), (false, true), (true, false), (true, true)]) {
    final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}';
    testWidgets('mind map golden $name', (tester) async {
      tester.view.physicalSize = const Size(760, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final id = await seed(tester);
      await pumpGallery(
        tester,
        h,
        Scaffold(
          body: MindMapView(checklistId: id, onOpenItem: (_) {}),
        ),
        dark: dark,
        rtl: rtl,
      );
      await expectLater(find.byType(MindMapView), matchesGoldenFile('goldens/mind_map_$name.png'));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
