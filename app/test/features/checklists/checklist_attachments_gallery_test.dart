// Checklist attachments gallery (T4.4.07): every attachment of a list (list-level + live items),
// grouped by item with breadcrumbs, filterable by type; the viewer offers "Go to item".
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_views.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  /// List "Trip": Documents › Passport, Tickets (deleted later); another list "Other".
  Future<({String list, String documents, String passport, String tickets, String other})> seed() async {
    final repo = h.read(checklistsRepositoryProvider);
    final list = (await repo.create(
      title: 'Trip',
      items: const [
        NodeSpec(
          text: 'Documents',
          children: [NodeSpec(text: 'Passport')],
        ),
        NodeSpec(text: 'Tickets'),
      ],
    )).id;
    final other = (await repo.create(
      title: 'Other',
      items: const [NodeSpec(text: 'Elsewhere')],
    )).id;
    final items = await h.read(checklistItemsRepositoryProvider).items(list);
    String idOf(String text) => items.firstWhere((i) => i.text == text).id;
    final otherItem = (await h.read(checklistItemsRepositoryProvider).items(other)).single.id;
    NewAttachment att(String type, String owner, String name, String mime) => NewAttachment(
      id: Ids.v7(),
      ownerType: type,
      ownerId: owner,
      storagePath: 'user-1/$name',
      fileName: name,
      mimeType: mime,
      byteSize: 1000,
    );
    await h.read(attachmentsRepositoryProvider).insertAll([
      att(AttachmentOwnerType.checklist, list, 'plan.pdf', 'application/pdf'),
      att(AttachmentOwnerType.checklistItem, idOf('Documents'), 'scan.jpg', 'image/jpeg'),
      att(AttachmentOwnerType.checklistItem, idOf('Passport'), 'passport.png', 'image/png'),
      att(AttachmentOwnerType.checklistItem, idOf('Passport'), 'form.zip', 'application/zip'),
      att(AttachmentOwnerType.checklistItem, idOf('Tickets'), 'ticket.pdf', 'application/pdf'),
      att(AttachmentOwnerType.checklistItem, otherItem, 'elsewhere.jpg', 'image/jpeg'),
    ]);
    return (
      list: list,
      documents: idOf('Documents'),
      passport: idOf('Passport'),
      tickets: idOf('Tickets'),
      other: other,
    );
  }

  Future<void> deleteItem(String list, String id) =>
      h.read(checklistServiceProvider).run(list, (tree, c, _) => TreeOps.deleteSubtrees(tree, c, [id]));

  test('the query joins list-level and live item attachments of this list only', () async {
    final s = await seed();
    final repo = h.read(checklistItemsRepositoryProvider);
    expect((await repo.watchChecklistAttachments(s.list).first).map((a) => a.fileName).toSet(), {
      'plan.pdf',
      'scan.jpg',
      'passport.png',
      'form.zip',
      'ticket.pdf',
    });
    await deleteItem(s.list, s.tickets);
    final live = await repo.watchChecklistAttachments(s.list).first;
    expect(live.map((a) => a.fileName), isNot(contains('ticket.pdf')), reason: 'deleted items drop out');
    expect(live.map((a) => a.fileName), isNot(contains('elsewhere.jpg')));
  });

  group('screen', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<List<String?>> open(WidgetTester tester, String list) async {
      tester.view.physicalSize = const Size(480, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final wentTo = <String?>[];
      await pumpInApp(
        tester,
        h,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChecklistAttachmentsScreen(checklistId: list, onGoToItem: wentTo.add),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      return wentTo;
    }

    testWidgets('groups by item with breadcrumbs and filters by type', (tester) async {
      late String list;
      await tester.runAsync(() async => list = (await seed()).list);
      await open(tester, list);

      expect(find.text('On the list'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Documents › Passport'), findsOneWidget);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.bySemanticsLabel('form.zip'), findsOneWidget);

      await tester.tap(find.text('Images'));
      await settle(tester);
      expect(find.text('On the list'), findsNothing, reason: 'the list-level PDF is filtered out');
      expect(find.text('Tickets'), findsNothing);
      expect(find.bySemanticsLabel('passport.png'), findsOneWidget);
      expect(find.bySemanticsLabel('form.zip'), findsNothing);

      await tester.tap(find.text('PDFs'));
      await settle(tester);
      expect(find.text('On the list'), findsOneWidget);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('Documents › Passport'), findsNothing);

      await tester.tap(find.text('Other'));
      await settle(tester);
      expect(find.bySemanticsLabel('form.zip'), findsOneWidget);
      expect(find.bySemanticsLabel('scan.jpg'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      // Runs the database's zero-delay stream-close timer.
      await tester.pump(const Duration(milliseconds: 10));
    });

    testWidgets('the viewer offers Go to item, which closes the gallery and opens the owner', (tester) async {
      late ({String list, String documents, String passport, String tickets, String other}) s;
      await tester.runAsync(() async => s = await seed());
      final wentTo = await open(tester, s.list);

      await tester.tap(find.bySemanticsLabel('passport.png'));
      await settle(tester);
      await tester.tap(find.byTooltip('Go to item'));
      await settle(tester);
      expect(wentTo, [s.passport]);
      expect(find.byType(ChecklistAttachmentsScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      // Runs the database's zero-delay stream-close timer.
      await tester.pump(const Duration(milliseconds: 10));
    });
  });
}
