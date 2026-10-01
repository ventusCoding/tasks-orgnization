import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:everslot/features/organization/presentation/tags_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('create a tag from the empty state and see it listed', (tester) async {
    await pumpInApp(tester, h, const TagsScreen());
    await settle(tester);
    expect(find.text('No tags yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '#errands');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(find.text('errands'), findsOneWidget);
    expect(find.text('Not used'), findsOneWidget);
  });

  testWidgets('duplicate names show a localized error', (tester) async {
    await tester.runAsync(() => h.read(tagsRepositoryProvider).create(name: 'Work'));
    await pumpInApp(tester, h, const TagsScreen());
    await settle(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'work');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(find.text('A tag with this name already exists.'), findsOneWidget);
  });

  testWidgets('merge two tags, then undo', (tester) async {
    final repo = h.read(tagsRepositoryProvider);
    await tester.runAsync(() async {
      await repo.create(name: 'job');
      await repo.create(name: 'work');
    });
    await pumpInApp(tester, h, const TagsScreen());
    await settle(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge into…'));
    await tester.pumpAndSettle();
    expect(find.text('Merge “job” into'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('work')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await settle(tester);

    expect(find.text('job'), findsNothing);
    expect(find.text('Merged into “work”'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('job'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
  });

  testWidgets('delete a tag with undo', (tester) async {
    await tester.runAsync(() => h.read(tagsRepositoryProvider).create(name: 'someday'));
    await pumpInApp(tester, h, const TagsScreen());
    await settle(tester);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text("This tag isn't used yet."), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(find.text('someday'), findsNothing);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('someday'), findsOneWidget);
  });

  testWidgets('entity chips: add an existing tag and create one inline', (tester) async {
    final taskId = Ids.v7();
    await tester.runAsync(() async {
      await h
          .read(syncWriterProvider)
          .run((tx) => tx.insert('tasks', taskId, {'series_id': taskId, 'title': 'Report'}));
      await h.read(tagsRepositoryProvider).create(name: 'work');
    });
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: EntityTagChips(entityType: 'task', entityId: taskId, editable: true),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Add tag'));
    await settle(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'work'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'urgent');
    await tester.pump();
    await tester.tap(find.text('Create tag “urgent”'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await settle(tester);

    expect(find.widgetWithText(InputChip, 'work'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'urgent'), findsOneWidget);
    final linked = await tester.runAsync(() => h.read(tagsRepositoryProvider).tagsForEntity('task', taskId));
    expect([for (final t in linked!) t.name], ['work', 'urgent']);

    // Removing a chip detaches the tag (with undo).
    await tester.tap(find.byTooltip('Remove tag work'));
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'work'), findsNothing);
    expect(find.text('Tags updated'), findsOneWidget);
  });

  testWidgets('tags screen in Arabic is right-to-left and localized', (tester) async {
    await tester.runAsync(() => h.read(tagsRepositoryProvider).create(name: 'عمل'));
    await pumpInApp(tester, h, const TagsScreen(), locale: const Locale('ar'));
    await settle(tester);
    expect(find.text('الوسوم'), findsOneWidget);
    expect(find.text('غير مستخدم'), findsOneWidget);
    final context = tester.element(find.text('عمل'));
    expect(Directionality.of(context), TextDirection.rtl);
    // The leading avatar sits on the right in RTL.
    final tile = tester.getRect(find.byType(ListTile));
    final avatar = tester.getRect(find.byType(CircleAvatar));
    expect(avatar.center.dx, greaterThan(tile.center.dx));
  });
}
