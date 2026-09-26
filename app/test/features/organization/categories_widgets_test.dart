import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// Category management screen and picker (T2.3.01).
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<String> category(String name, {int color = 0xFF3B82F6}) async {
    late String id;
    await h.read(syncWriterProvider).run((tx) async {
      id = Ids.v7();
      final count = (await h.read(categoriesRepositoryProvider).all()).length;
      await tx.insert('categories', id, {
        'name': name,
        'color': color,
        'icon': 'work',
        'sort_key': 'a$count',
      });
    });
    return id;
  }

  Future<String> task(String categoryId) async {
    final id = Ids.v7();
    await h
        .read(syncWriterProvider)
        .run(
          (tx) => tx.insert('tasks', id, {
            'series_id': id,
            'title': 'Report',
            'category_id': categoryId,
          }),
        );
    return id;
  }

  Future<Map<String, int>> usage() =>
      h.read(categoriesRepositoryProvider).watchUsageCounts().first;

  Future<void> openMenu(
    WidgetTester tester,
    String categoryName,
    String action,
  ) async {
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, categoryName),
        matching: find.byTooltip('More'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  testWidgets('create a category and see it listed with its usage', (
    tester,
  ) async {
    await pumpInApp(tester, h, const CategoriesScreen());
    await settle(tester);
    expect(find.text('No categories yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Deep   work ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(find.text('Deep work'), findsOneWidget);
    expect(find.text('Not used'), findsOneWidget);
  });

  testWidgets('a duplicate rename shows a localized error', (tester) async {
    await tester.runAsync(() async {
      await category('Work');
      await category('Home');
    });
    await pumpInApp(tester, h, const CategoriesScreen());
    await settle(tester);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'WORK');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(
      find.text('A category with this name already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('archive, then undo', (tester) async {
    await tester.runAsync(() => category('Old'));
    await pumpInApp(tester, h, const CategoriesScreen());
    await settle(tester);

    await openMenu(tester, 'Old', 'Archive');
    await settle(tester);
    expect(find.text('Archived · Not used'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await settle(tester);
    expect(find.text('Not used'), findsOneWidget);
  });

  testWidgets('deleting a used category moves its items to another one', (
    tester,
  ) async {
    late String work;
    late String home;
    late String t1;
    await tester.runAsync(() async {
      work = await category('Work');
      home = await category('Home');
      t1 = await task(work);
      await task(work);
    });
    await pumpInApp(tester, h, const CategoriesScreen());
    await settle(tester);
    expect(find.text('2 items'), findsOneWidget);

    await openMenu(tester, 'Work', 'Delete');
    expect(
      find.text('2 items use “Work”. What should happen to them?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Move them to another category'));
    await tester.pumpAndSettle();
    // The picker excludes the deleted category and has no "No category" entry.
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Work')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('No category')),
      findsNothing,
    );
    await tester.tap(find.descendant(of: sheet, matching: find.text('Home')));
    await settle(tester);

    expect(find.text('Work'), findsNothing);
    expect(await tester.runAsync(usage), {home: 2});
    final row = await tester.runAsync(
      () =>
          (h.db.select(h.db.tasks)..where((t) => t.id.equals(t1))).getSingle(),
    );
    expect(row!.categoryId, home);
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
  });

  testWidgets('deleting a used category can clear it from its items', (
    tester,
  ) async {
    late String work;
    await tester.runAsync(() async {
      work = await category('Work');
      await task(work);
    });
    await pumpInApp(tester, h, const CategoriesScreen());
    await settle(tester);

    await openMenu(tester, 'Work', 'Delete');
    expect(
      find.text('1 item uses “Work”. What should happen to them?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Remove the category from them'));
    await settle(tester);
    expect(find.text('No categories yet'), findsOneWidget);
    expect(await tester.runAsync(usage), isEmpty);
  });

  testWidgets('deleting an unused category only asks for confirmation', (
    tester,
  ) async {
    await tester.runAsync(() => category('Spare'));
    await pumpInApp(tester, h, const CategoriesScreen());
    await settle(tester);
    await openMenu(tester, 'Spare', 'Delete');
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(find.text('No categories yet'), findsOneWidget);
  });

  group('picker', () {
    testWidgets('searches, hides archived and returns "" for no category', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await category('Work');
        await category('Workout');
        final old = await category('Archived one');
        await h
            .read(categoriesRepositoryProvider)
            .setArchived(old, archived: true);
      });
      String? result = 'unset';
      await pumpInApp(
        tester,
        h,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await pickCategory(context, ref),
              child: const Text('pick'),
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('pick'));
      await settle(tester);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Archived one')),
        findsNothing,
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        'out',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: sheet, matching: find.text('Workout')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Work')),
        findsNothing,
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        '',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('No category'));
      await tester.pumpAndSettle();
      expect(result, '');
    });

    testWidgets('creates a category inline and returns its id', (tester) async {
      String? result;
      await pumpInApp(
        tester,
        h,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await pickCategory(context, ref),
              child: const Text('pick'),
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('pick'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Gym');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create category “Gym”'));
      await settle(tester);
      final all = await tester.runAsync(
        () => h.read(categoriesRepositoryProvider).all(),
      );
      expect(all!.single.name, 'Gym');
      expect(result, all.single.id);
    });
  });

  testWidgets('Arabic: localized, right-to-left, plural usage', (tester) async {
    await tester.runAsync(() async {
      final work = await category('العمل');
      await task(work);
      await task(work);
    });
    await pumpInApp(
      tester,
      h,
      const CategoriesScreen(),
      locale: const Locale('ar'),
    );
    await settle(tester);
    expect(find.text('الفئات'), findsOneWidget);
    expect(find.text('عنصران'), findsOneWidget);
    final title = tester.getRect(find.text('العمل'));
    final avatar = tester.getRect(find.byType(CircleAvatar));
    expect(
      avatar.left,
      greaterThan(title.right - 1),
      reason: 'leading avatar is on the right',
    );
  });
}
