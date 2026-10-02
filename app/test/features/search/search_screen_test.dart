import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/application/habit_providers.dart' show habitLogsRepositoryProvider;
import 'package:everslot/features/search/application/search_providers.dart';
import 'package:everslot/features/search/data/search_recents_store.dart';
import 'package:everslot/features/search/presentation/search_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';

/// Search screen (T8.1.14–15): debounce, grouping + see all, highlighting, recents, filters and
/// inline actions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10)));
  tearDown(() => h.dispose());

  Future<void> open(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(420, 2400) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SearchScreen())],
      errorBuilder: (_, s) => Scaffold(body: Text('opened ${s.uri}')),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        ),
      ),
    );
    await settle(tester);
  }

  /// Filter chips scroll horizontally: bring [key] into view, then tap it.
  Future<void> tapChip(WidgetTester tester, String key) async {
    final chip = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      chip,
      150,
      scrollable: find.descendant(of: find.byKey(const ValueKey('search-filters')), matching: find.byType(Scrollable)),
    );
    await tester.ensureVisible(chip);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(chip);
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(const ValueKey('search-field')), query);
    await tester.pump(SearchScreen.debounce);
    await settle(tester);
  }

  testWidgets('debounced: nothing runs before 150 ms, then results group by kind', (tester) async {
    await tester.runAsync(() async {
      await h.task('Dentist appointment', start: at(2026, 9, 25, 10));
      await h.checklist('Dentist questions', items: ['Ask about the dentist bill']);
      await h.habit('Floss for the dentist', start: LocalDate(2026, 9, 1));
    });
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('search-field')), 'dent');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    expect(find.byKey(const ValueKey('search-results')), findsNothing, reason: 'still debouncing');
    await tester.pump(const Duration(milliseconds: 60));
    await settle(tester);
    for (final k in ['task', 'checklist', 'item', 'habit']) {
      expect(find.byKey(ValueKey('search-group-$k')), findsOneWidget, reason: k);
    }
    // The breadcrumb names the list of the item.
    expect(find.text('Dentist questions'), findsNWidgets(2));
  });

  testWidgets('matches are highlighted in titles', (tester) async {
    await tester.runAsync(() => h.task('Réunion budget', start: at(2026, 9, 25, 10)));
    await open(tester);
    await type(tester, 'reunion');
    final rich = tester.widget<Text>(find.descendant(of: find.byType(ListTile), matching: find.byType(Text)).first);
    final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.first.text, 'Réunion');
    expect(spans.first.style?.fontWeight, FontWeight.w700);
    expect(spans.last.text, ' budget');
    expect(spans.last.style, isNull);
  });

  testWidgets('a crowded group shows "see all", which narrows to that kind', (tester) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 6; i++) {
        await h.task('Invoice $i', start: at(2026, 9, 25, 8 + i));
      }
      await h.checklist('Invoices to file');
    });
    await open(tester);
    await type(tester, 'invoice');
    expect(find.byKey(const ValueKey('search-see-all-task')), findsOneWidget);
    expect(find.textContaining('Invoice '), findsNWidgets(SearchScreen.perGroup));
    await tester.tap(find.byKey(const ValueKey('search-see-all-task')));
    await settle(tester);
    expect(find.textContaining('Invoice '), findsNWidgets(6));
    expect(find.byKey(const ValueKey('search-group-checklist')), findsNothing);
    expect(tester.widget<FilterChip>(find.byKey(const ValueKey('search-kind-task'))).selected, isTrue);
    await tapChip(tester, 'search-clear-filters');
    expect(find.byKey(const ValueKey('search-group-checklist')), findsOneWidget);
  });

  testWidgets('opening a result follows its link and remembers the query (local only)', (tester) async {
    final list = await tester.runAsync(() => h.checklist('Packing', items: ['Sunscreen']));
    await open(tester);
    expect(find.text('Tasks, lists, items, habits, notes and inbox'), findsOneWidget, reason: 'no recents yet');
    await type(tester, 'sunscr');
    await tester.tap(find.text('Sunscreen'));
    await settle(tester);
    final item = await tester.runAsync(() => h.itemId(list!, 'Sunscreen'));
    expect(find.text('opened /lists/$list?item=$item'), findsOneWidget);
    final stored = await tester.runAsync(() => SearchRecentsStore(h.db).load());
    expect(stored, ['sunscr']);

    // A fresh screen lists it; tapping reruns the search; removing forgets it.
    h.container.invalidate(searchRecentsProvider);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('search-recent-0')));
    await settle(tester);
    expect(find.text('Sunscreen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('search-clear')));
    await settle(tester);
    await tester.tap(find.byTooltip('Remove from recent searches'));
    await settle(tester);
    expect(await tester.runAsync(() => SearchRecentsStore(h.db).load()), isEmpty);
  });

  testWidgets('inline complete + status filter', (tester) async {
    final list = await tester.runAsync(() => h.checklist('Garage', items: ['Paint shelf', 'Paint door']));
    await open(tester);
    await type(tester, 'paint');
    final shelf = (await tester.runAsync(() => h.itemId(list!, 'Paint shelf')))!;
    await tester.tap(find.byKey(ValueKey('search-complete-$shelf')));
    await settle(tester);
    final items = await tester.runAsync(() => h.read(checklistItemsRepositoryProvider).items(list!));
    expect(items!.firstWhere((i) => i.id == shelf).status, ItemStatus.completed);
    expect(find.byKey(ValueKey('search-complete-$shelf')), findsNothing, reason: 'closed rows lose the action');

    await tapChip(tester, 'search-status');
    await tester.tap(find.text('Open').last);
    await settle(tester);
    expect(find.text('Paint shelf'), findsNothing);
    expect(find.text('Paint door'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // snackbar
  });

  testWidgets('inline habit check-in', (tester) async {
    await tester.runAsync(() => h.habit('Stretch', start: LocalDate(2026, 9, 1)));
    await open(tester);
    await type(tester, 'stretch');
    await tester.tap(find.byKey(const ValueKey('search-checkin-habit-Stretch')));
    await settle(tester);
    final logs = await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit('habit-Stretch'));
    expect(logs!.single.kind.name, 'done');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no results; Arabic layout has no errors', (tester) async {
    await open(tester, locale: const Locale('ar'));
    await type(tester, 'zzz');
    expect(find.text('لا نتائج لـ «zzz»'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
