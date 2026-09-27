// Labels on checklists (T4.1.12) and board search & filters (T4.1.13): FTS search over titles,
// bodies and items (diacritics ignored), label filtering from the drawer, label chips on cards and
// the AND-combined filter chips.
import 'package:drift/drift.dart' show Batch, Value;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/lists_board_screen.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  group('search (FTS)', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    test('titles, bodies and items match; items carry their breadcrumb path', () async {
      final repo = h.read(checklistsRepositoryProvider);
      final trip = (await repo.create(
        title: 'Trip',
        items: const [
          NodeSpec(
            text: 'Documents',
            children: [NodeSpec(text: 'Passport renewal')],
          ),
        ],
      )).id;
      final shop = (await repo.create(title: 'Groceries', body: 'Weekly market run')).id;

      final byTitle = await repo.search('trip');
      expect(byTitle.checklistIds, {trip});
      expect((await repo.search('market')).checklistIds, {shop}, reason: 'bodies are indexed');

      final byItem = await repo.search('passp');
      expect(byItem.checklistIds, {trip}, reason: 'prefix match');
      expect(byItem.items.single.text, 'Passport renewal');
      expect(byItem.items.single.path, ['Documents']);
      expect(byItem.items.single.checklistTitle, 'Trip');
    });

    test('matching ignores French and Arabic diacritics and Arabic letter variants', () async {
      final repo = h.read(checklistsRepositoryProvider);
      final fr = (await repo.create(title: 'Café crème à Noël')).id;
      final ar = (await repo.create(
        title: 'مدرسة',
        items: const [NodeSpec(text: 'شراء الأقلام')],
      )).id;
      expect((await repo.search('cafe creme noel')).checklistIds, {fr});
      expect((await repo.search('CAFÉ')).checklistIds, {fr});
      expect((await repo.search('مَدْرَسَة')).checklistIds, {ar}, reason: 'harakat in the query are ignored');
      expect((await repo.search('مدرسه')).checklistIds, {ar}, reason: 'ة and ه match');
      expect((await repo.search('الاقلام')).items.map((i) => i.text), ['شراء الأقلام'], reason: 'أ and ا match');
    });

    test('deleted lists and templates are not found', () async {
      final repo = h.read(checklistsRepositoryProvider);
      final gone = (await repo.create(title: 'Packing old')).id;
      await repo.create(title: 'Packing template', isTemplate: true);
      final live = (await repo.create(title: 'Packing')).id;
      await repo.delete(gone);
      expect((await repo.search('packing')).checklistIds, {live});
    });

    test('20 000 indexed items answer quickly', () async {
      final repo = h.read(checklistsRepositoryProvider);
      final id = (await repo.create(title: 'Huge')).id;
      final db = h.db;
      final now = DateTime.utc(2026, 9, 22);
      String? key;
      await db.batch((Batch b) {
        for (var i = 0; i < 20000; i++) {
          key = FractionalIndex.between(key, null);
          b.insert(
            db.checklistItems,
            ChecklistItemsCompanion.insert(
              id: 'item-$i',
              userId: 'user-1',
              checklistId: id,
              sortKey: key!,
              itemText: Value(i % 1000 == 0 ? 'needle $i' : 'hay $i'),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
      await repo.search('warmup');
      final watch = Stopwatch()..start();
      final result = await repo.search('needle');
      watch.stop();
      expect(result.items, hasLength(20));
      // Target on devices (release) is < 100 ms; debug test runs on a loaded CI host get headroom.
      expect(watch.elapsedMilliseconds, lessThan(400), reason: '${watch.elapsedMilliseconds} ms');
    });
  });

  test('labels are entity tags of type checklist: the tagged ids stream filters by label', () async {
    final h = TestHarness.create();
    addTearDown(h.dispose);
    final repo = h.read(checklistsRepositoryProvider);
    final a = (await repo.create(title: 'A')).id;
    await repo.create(title: 'B');
    final tags = h.read(tagsRepositoryProvider);
    final work = (await tags.create(name: 'Work')).id;
    await tags.setTags(checklistTagType, a, {work});
    expect(await tags.watchEntityIds(work, entityType: checklistTagType).first, {a});
    final byEntity = await tags.watchByEntity(checklistTagType).first;
    expect(byEntity[a]!.map((t) => t.name), ['Work']);
  });

  group('board', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// The shared app-bar actions keep an inbox badge provider (with a refresh timer) alive:
    /// release it before the test ends.
    Future<void> closeBoard(WidgetTester tester) async {
      await pumpInApp(tester, h, const SizedBox());
      await settle(tester);
      h.container.invalidate(inboxUnreadCountProvider);
      await tester.pump(const Duration(milliseconds: 10));
    }

    Future<Map<String, String>> seed(WidgetTester tester) async {
      final ids = <String, String>{};
      await tester.runAsync(() async {
        final repo = h.read(checklistsRepositoryProvider);
        ids['work'] = (await repo.create(
          title: 'Quarterly report',
          items: [NodeSpec(text: 'Draft slides', dueLocal: LocalDate(2026, 9, 30).atTime(LocalTime(9, 0)))],
        )).id;
        ids['home'] = (await repo.create(
          title: 'Groceries',
          items: const [NodeSpec(text: 'Milk')],
        )).id;
        final tags = h.read(tagsRepositoryProvider);
        final work = (await tags.create(name: 'Work')).id;
        ids['tag'] = work;
        await tags.setTags(checklistTagType, ids['work']!, {work});
      });
      return ids;
    }

    testWidgets('cards show their labels; the drawer counts lists and filters the board', (tester) async {
      await seed(tester);
      await pumpInApp(tester, h, const ListsBoardScreen());
      await settle(tester);
      expect(find.text('Quarterly report'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget, reason: 'label chip on the card');

      await tester.tap(find.byTooltip('Open navigation menu'));
      await settle(tester);
      expect(find.bySemanticsLabel('Work, 1 list'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Work, 1 list'));
      await settle(tester);
      expect(find.text('Quarterly report'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
      expect(find.bySemanticsLabel('Showing lists labelled Work'), findsOneWidget);

      // Clearing the active label chip shows every list again.
      await tester.tap(find.byTooltip('Remove tag Work'));
      await settle(tester);
      expect(find.text('Groceries'), findsOneWidget);
      await closeBoard(tester);
    });

    testWidgets('search shows item hits with their path; filter chips combine with AND', (tester) async {
      await seed(tester);
      await pumpInApp(tester, h, const ListsBoardScreen());
      await settle(tester);
      // The board's own search (the global app-bar actions may offer one too).
      await tester.tap(find.byTooltip('Search').first);
      await settle(tester);

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 200));
      await settle(tester);
      expect(find.text('Milk'), findsWidgets);
      expect(find.text('Quarterly report'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 200));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'With due dates'));
      await settle(tester);
      expect(find.text('Quarterly report'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);

      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Pinned'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(FilterChip, 'Pinned'));
      await settle(tester);
      expect(find.text('Quarterly report'), findsNothing, reason: 'due AND pinned: nothing matches');
      await closeBoard(tester);
    });
  });
}
