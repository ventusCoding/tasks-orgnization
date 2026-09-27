// Flat all-items table (T4.5.15): items of every active list with list, path, status, age, due,
// follow-up, priority and files; sortable, filterable, with a cross-list bulk status change.
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_table.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/items_table_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show t0;

SmartItem _row(
  String text, {
  String list = 'L',
  ItemStatus status = ItemStatus.todo,
  LocalDateTime? due,
  int priority = 0,
  List<String> path = const [],
}) => SmartItem(
  item: ChecklistItem(
    id: text,
    checklistId: list,
    sortKey: text,
    text: text,
    status: status,
    dueLocal: due,
    priority: priority,
    createdAt: t0,
  ),
  checklistTitle: list,
  path: path,
);

void main() {
  group('query (pure)', () {
    final rows = [
      _row('pay rent', list: 'Home', status: ItemStatus.blocked, priority: 1),
      _row('Book hotel', list: 'Trip', status: ItemStatus.waiting, due: LocalDateTime.of(2026, 10, 1)),
      _row('call bank', list: 'Home', due: LocalDateTime.of(2026, 9, 25), priority: 3),
      _row('Passport', list: 'Trip', status: ItemStatus.completed, path: ['Documents']),
    ];
    List<String> texts(List<SmartItem> r) => [for (final x in r) x.item.text];

    test('sorts by any column; undated rows stay last in both directions', () {
      expect(texts(const ItemTableQuery(sortBy: ItemTableColumn.text).apply(rows)), [
        'Book hotel',
        'call bank',
        'Passport',
        'pay rent',
      ]);
      expect(texts(const ItemTableQuery(sortBy: ItemTableColumn.status).apply(rows)).take(2), [
        'pay rent',
        'Book hotel',
      ]);
      expect(texts(const ItemTableQuery(sortBy: ItemTableColumn.due).apply(rows)).take(2), ['call bank', 'Book hotel']);
      expect(texts(const ItemTableQuery(sortBy: ItemTableColumn.due, descending: true).apply(rows)).take(2), [
        'Book hotel',
        'call bank',
      ]);
      expect(texts(const ItemTableQuery(sortBy: ItemTableColumn.priority).apply(rows)).first, 'call bank');
    });

    test('header taps toggle the direction of the same column, reset it for another', () {
      const q = ItemTableQuery(sortBy: ItemTableColumn.due);
      expect(q.sortedBy(ItemTableColumn.due).descending, isTrue);
      expect(
        q.sortedBy(ItemTableColumn.due).sortedBy(ItemTableColumn.text),
        const ItemTableQuery(sortBy: ItemTableColumn.text),
      );
    });

    test('filters by status set and by text in the item, its list or its path', () {
      expect(texts(const ItemTableQuery(statuses: {ItemStatus.blocked, ItemStatus.waiting}).apply(rows)), [
        'pay rent',
        'Book hotel',
      ]);
      expect(texts(const ItemTableQuery(text: 'trip').apply(rows)), ['Book hotel', 'Passport']);
      expect(texts(const ItemTableQuery(text: 'documents').apply(rows)), ['Passport']);
    });
  });

  group('data and screen', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    Future<({String home, String trip})> seed() async {
      final repo = h.read(checklistsRepositoryProvider);
      final home = (await repo.create(
        title: 'Home',
        items: const [
          NodeSpec(text: 'Pay rent', status: ItemStatus.blocked),
          NodeSpec(text: 'Fix tap'),
        ],
      )).id;
      final trip = (await repo.create(
        title: 'Trip',
        items: const [
          NodeSpec(
            text: 'Documents',
            children: [NodeSpec(text: 'Passport')],
          ),
        ],
      )).id;
      final archived = (await repo.create(
        title: 'Old',
        items: const [NodeSpec(text: 'Ancient')],
      )).id;
      await repo.setArchived(archived, archived: true);
      await repo.create(
        title: 'Template',
        isTemplate: true,
        items: const [NodeSpec(text: 'Blueprint')],
      );
      final passport = (await h.read(checklistItemsRepositoryProvider).items(trip))
          .firstWhere((i) => i.text == 'Passport');
      await h.read(attachmentsRepositoryProvider).insertAll([
        NewAttachment(
          id: Ids.v7(),
          ownerType: AttachmentOwnerType.checklistItem,
          ownerId: passport.id,
          storagePath: 'user-1/p.jpg',
          fileName: 'p.jpg',
          mimeType: 'image/jpeg',
          byteSize: 10,
        ),
      ]);
      return (home: home, trip: trip);
    }

    test('the DAO lists items of active lists only, with their path and file counts', () async {
      await seed();
      final repo = h.read(checklistsRepositoryProvider);
      final rows = await repo.watchAllItems().first;
      expect(rows.map((r) => r.item.text).toSet(), {'Pay rent', 'Fix tap', 'Documents', 'Passport'});
      final passport = rows.firstWhere((r) => r.item.text == 'Passport');
      expect(passport.path, ['Documents']);
      expect(passport.checklistTitle, 'Trip');
      expect((await repo.watchAllItemAttachmentCounts().first)[passport.item.id], 1);
    });

    testWidgets('sort by a header, filter by status, then change the status of rows from two lists', (tester) async {
      tester.view.physicalSize = const Size(1700, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late ({String home, String trip}) s;
      await tester.runAsync(() async => s = await seed());
      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await pumpInApp(tester, h, const ItemsTableScreen());
      await settle();
      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.text('Ancient'), findsNothing);
      expect(find.text('Documents › '), findsNothing);
      expect(find.text('Documents'), findsWidgets, reason: 'item and path cells');

      // Sort by item text: "Documents" first.
      await tester.tap(find.bySemanticsLabel('Sort by Item'));
      await settle();
      final firstRowY = tester.getTopLeft(find.text('Fix tap')).dy;
      expect(tester.getTopLeft(find.text('Passport')).dy, greaterThan(firstRowY));

      // Only blocked rows.
      await tester.tap(find.widgetWithText(FilterChip, 'Blocked'));
      await settle();
      expect(find.text('Fix tap'), findsNothing);
      await tester.tap(find.widgetWithText(FilterChip, 'Blocked'));
      await settle();

      await tester.tap(find.bySemanticsLabel('Select Fix tap'));
      await tester.tap(find.bySemanticsLabel('Select Passport'));
      await settle();
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Change status'));
      await settle();
      await tester.tap(find.text('Completed').last);
      await settle();
      expect(find.text('2 items updated'), findsOneWidget);

      late List<ChecklistItem> home;
      late List<ChecklistItem> trip;
      await tester.runAsync(() async {
        home = await h.read(checklistItemsRepositoryProvider).items(s.home);
        trip = await h.read(checklistItemsRepositoryProvider).items(s.trip);
      });
      expect(home.firstWhere((i) => i.text == 'Fix tap').status, ItemStatus.completed);
      expect(trip.firstWhere((i) => i.text == 'Passport').status, ItemStatus.completed);
      expect(home.firstWhere((i) => i.text == 'Pay rent').status, ItemStatus.blocked);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
  });
}
