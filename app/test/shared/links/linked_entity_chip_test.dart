import 'package:drift/drift.dart' hide isNull;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/shared/links/presentation/linked_entity_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// T2.3.12: a chip linking to another entity shows its live title and status, opens its canonical
/// location and degrades to "Deleted" when the target is gone.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  final now = DateTime.utc(2026, 9, 22, 9);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    await h.db
        .into(h.db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 't1',
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            seriesId: 't1',
            title: 'Book flights',
          ),
        );
    await h.db
        .into(h.db.checklists)
        .insert(
          ChecklistsCompanion.insert(
            id: 'c1',
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            sortKey: 'a0',
            title: const Value('Trip'),
          ),
        );
    await h.db
        .into(h.db.checklistItems)
        .insert(
          ChecklistItemsCompanion.insert(
            id: 'i1',
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            checklistId: 'c1',
            sortKey: 'a0',
            itemText: const Value('Passport'),
            status: const Value('completed'),
          ),
        );
  });

  testWidgets('live title and status; tap opens the canonical location', (tester) async {
    final handle = tester.ensureSemantics();
    await seed(tester);
    final opened = <String>[];
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Wrap(
          children: [
            LinkedEntityChip(entityType: 'task', entityId: 't1', onOpen: opened.add),
            LinkedEntityChip(entityType: 'checklist_item', entityId: 'i1', onOpen: opened.add),
          ],
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Book flights'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Task: Book flights, Active')), findsOneWidget);
    final passport = tester.widget<Text>(find.text('Passport'));
    expect(passport.style?.decoration, TextDecoration.lineThrough, reason: 'completed item');
    expect(find.bySemanticsLabel(RegExp('^List item: Passport, Completed')), findsOneWidget);

    await tester.tap(find.text('Book flights'));
    await tester.tap(find.text('Passport'));
    expect(opened, ['/task/t1', '/lists/c1?item=i1']);

    // Renamed and paused elsewhere (e.g. by sync): the chip follows.
    await tester.runAsync(
      () => (h.db.update(h.db.tasks)..where((t) => t.id.equals('t1'))).write(
        const TasksCompanion(title: Value('Book cheap flights'), status: Value('paused')),
      ),
    );
    await settle(tester);
    expect(find.text('Book cheap flights'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a deleted target shows a disabled "Deleted" chip', (tester) async {
    await seed(tester);
    await tester.runAsync(
      () => (h.db.update(h.db.tasks)..where((t) => t.id.equals('t1'))).write(TasksCompanion(deletedAt: Value(now))),
    );
    await pumpInApp(
      tester,
      h,
      const Scaffold(
        body: LinkedEntityChip(entityType: 'task', entityId: 't1'),
      ),
    );
    await settle(tester);
    expect(find.text('Deleted'), findsOneWidget);
    expect(tester.widget<ActionChip>(find.byType(ActionChip)).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arabic labels', (tester) async {
    final handle = tester.ensureSemantics();
    await seed(tester);
    await pumpInApp(
      tester,
      h,
      const Scaffold(
        body: LinkedEntityChip(entityType: 'checklist', entityId: 'c1'),
      ),
      locale: const Locale('ar'),
    );
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp('^قائمة: Trip')), findsOneWidget);
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
