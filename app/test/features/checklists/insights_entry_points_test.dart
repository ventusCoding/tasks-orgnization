// Checklist Insights entry points (T4.5.13): the list menu, the item details sheet and the header's
// "N done this week" summary open `/insights/checklist/<id>` and `/insights/item/<id>`.
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

// Tuesday 22 September 2026; the default week starts on Monday the 21st.
final _now = DateTime.utc(2026, 9, 22, 9);

void main() {
  test('completedSince counts completed items from the given instant', () {
    ChecklistItem item(String id, ItemStatus s, DateTime? at) =>
        ChecklistItem(id: id, checklistId: 'c', sortKey: id, text: id, status: s, completedAt: at, createdAt: _now);
    final items = [
      item('a', ItemStatus.completed, DateTime.utc(2026, 9, 21)),
      item('b', ItemStatus.completed, DateTime.utc(2026, 9, 20, 23)),
      item('c', ItemStatus.todo, null),
      item('d', ItemStatus.completed, _now),
    ];
    expect(ItemTimeRules.completedSince(items, DateTime.utc(2026, 9, 21)), 2);
  });

  group('navigation', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: _now));
    tearDown(() => h.dispose());

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Trip: Passport (done this week), Visa (done last week), Tickets (open).
    Future<(String, String)> seed(WidgetTester tester) async {
      late String id;
      late String passport;
      await tester.runAsync(() async {
        id =
            (await h
                    .read(checklistsRepositoryProvider)
                    .create(
                      title: 'Trip',
                      items: const [
                        NodeSpec(text: 'Passport'),
                        NodeSpec(text: 'Visa'),
                        NodeSpec(text: 'Tickets'),
                      ],
                    ))
                .id;
        final items = await h.read(checklistItemsRepositoryProvider).items(id);
        String idOf(String t) => items.firstWhere((i) => i.text == t).id;
        passport = idOf('Passport');
        final service = h.read(checklistServiceProvider);
        h.clock.set(DateTime.utc(2026, 9, 17, 10));
        await service.changeStatus(id, [idOf('Visa')], ItemStatus.completed);
        h.clock.set(_now);
        await service.changeStatus(id, [passport], ItemStatus.completed);
      });
      return (id, passport);
    }

    Future<void> pumpRouter(WidgetTester tester, String id) async {
      final router = GoRouter(
        initialLocation: '/lists/$id',
        routes: [
          GoRoute(
            path: '/lists/:id',
            builder: (_, s) => ChecklistScreen(checklistId: s.pathParameters['id']!, preview: true),
          ),
          GoRoute(
            path: '/insights/:scope/:id',
            builder: (_, s) => Scaffold(body: Text('insights ${s.pathParameters['scope']} ${s.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: const [Locale('en')],
            localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('the header summary counts this week and opens the list Insights', (tester) async {
      final (id, _) = await seed(tester);
      await pumpRouter(tester, id);
      expect(find.text('1 done this week'), findsOneWidget, reason: 'last week\'s completion is not counted');
      await tester.tap(find.text('1 done this week'));
      await settle(tester);
      expect(find.text('insights checklist $id'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the list menu opens the list Insights', (tester) async {
      final (id, _) = await seed(tester);
      await pumpRouter(tester, id);
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byTooltip('More')));
      await settle(tester);
      await tester.ensureVisible(find.text('Insights'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Insights'));
      await settle(tester);
      expect(find.text('insights checklist $id'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the item details sheet opens the item Insights (route scope "item")', (tester) async {
      final handle = tester.ensureSemantics();
      final (id, passport) = await seed(tester);
      await pumpRouter(tester, id);
      tester.semantics.customAction(
        find.semantics.byLabel(RegExp('^Tickets, level 1')),
        const CustomSemanticsAction(label: 'Details'),
      );
      await settle(tester);
      await tester.ensureVisible(find.widgetWithText(ActionChip, 'Insights'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(ActionChip, 'Insights'));
      await settle(tester);
      expect(find.textContaining('insights item '), findsOneWidget);
      expect(find.textContaining(passport), findsNothing, reason: 'the tapped item, not another one');
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });
  });
}
