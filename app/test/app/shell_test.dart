import 'package:everslot/app/router.dart';
import 'package:everslot/app/shell_scaffold.dart';
import 'package:everslot/core/preferences/last_tab.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// T1.3.06 / T1.3.12: the 5-tab shell — per-tab stacks, Android back through the tab history,
/// last tab restored, bar/rail per breakpoint (RTL mirrored), badges, contextual + with quick add,
/// bottom bar hidden while scrolling down.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());

  GoRouter router({String initial = '/today'}) => GoRouter(
    initialLocation: initial,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell),
        branches: [
          for (final path in LastTab.paths)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (_, _) => _Tab(path),
                  routes: [
                    GoRoute(
                      path: 'detail',
                      builder: (_, _) => Scaffold(body: Text('$path detail')),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/task-new',
        builder: (_, _) => const Scaffold(body: Text('task editor')),
      ),
    ],
  );

  Future<GoRouter> pump(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    String locale = 'en',
    String initial = '/today',
    List<int> badges = const [0, 0, 0, 0, 0],
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final r = router(initial: initial);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(parent: h.container, overrides: [tabBadgesProvider.overrideWithValue(badges)]),
        child: MaterialApp.router(
          routerConfig: r,
          theme: AppTheme.light(),
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return r;
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(h.dispose);
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('each tab keeps its own stack; re-tapping a tab returns to its root', (tester) async {
    final r = await pump(tester);
    r.go('/today/detail');
    await tester.pumpAndSettle();
    expect(find.text('/today detail'), findsOneWidget);
    await tab(tester, 'Lists');
    expect(find.text('tab /lists'), findsOneWidget);
    await tab(tester, 'Today');
    expect(find.text('/today detail'), findsOneWidget, reason: 'the Today stack was kept');
    await tab(tester, 'Today');
    expect(find.text('tab /today'), findsOneWidget, reason: 're-tap pops to the root');
    await done(tester);
  });

  testWidgets('Android back walks the tab history, then leaves the app', (tester) async {
    await pump(tester);
    await tab(tester, 'Lists');
    await tab(tester, 'Habits');
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('tab /lists'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('tab /today'), findsOneWidget);
    // History empty: the pop is no longer intercepted (the system closes the app).
    final shell = tester.widget<PopScope<Object?>>(find.byWidgetPredicate((w) => w is PopScope).first);
    expect(shell.canPop, isTrue);
    await done(tester);
  });

  testWidgets('the selected tab is saved and used as the next initial location', (tester) async {
    await pump(tester);
    await tab(tester, 'Habits');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(await tester.runAsync(() => LastTab.load(h.db)), 3);
    LastTab.initial = 3;
    addTearDown(() => LastTab.initial = 0);
    expect(LastTab.initialLocation, '/habits');
    await done(tester);
  });

  test('the app router starts on the remembered tab', () async {
    LastTab.initial = 2;
    addTearDown(() => LastTab.initial = 0);
    final r = h.read(routerProvider);
    expect(r.routeInformationProvider.value.uri.path, '/lists');
    await h.dispose();
  });

  testWidgets('bottom bar on phones, rail from 600 dp, extended rail from 840 dp; RTL mirrors', (tester) async {
    await pump(tester, size: const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await pump(tester, size: const Size(700, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);
    expect(tester.getCenter(find.byType(NavigationRail)).dx, lessThan(350));

    await pump(tester, size: const Size(1100, 900), locale: 'ar');
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    expect(tester.getCenter(find.byType(NavigationRail)).dx, greaterThan(550), reason: 'rail on the right in RTL');
    await done(tester);
  });

  testWidgets('tab badges show counts with a spoken label', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, badges: const [0, 0, 0, 3, 0]);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('3')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('3 to do')), findsWidgets);
    handle.dispose();
    await done(tester);
  });

  testWidgets('contextual +: task editor on Today/Plan, none on Insights; long-press opens quick add', (tester) async {
    await pump(tester);
    expect(find.byTooltip('New task'), findsOneWidget);
    await tester.tap(find.byTooltip('New task'));
    await tester.pumpAndSettle();
    expect(find.text('task editor'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('task editor'), findsNothing, reason: 'back closes the editor');

    await tester.longPress(find.byKey(const ValueKey('shell-fab')));
    await tester.pumpAndSettle();
    for (final k in ['task', 'list', 'habit', 'quit']) {
      expect(find.byKey(ValueKey('quick-add-$k')), findsOneWidget);
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tab(tester, 'Insights');
    expect(find.byKey(const ValueKey('shell-fab')), findsNothing);
    await done(tester);
  });

  testWidgets('the bottom bar hides while scrolling down and returns when scrolling up', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await done(tester);
  });
}

class _Tab extends StatelessWidget {
  const _Tab(this.path);

  final String path;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      children: [
        Text('tab $path'),
        for (var i = 0; i < 60; i++) ListTile(title: Text('row $i')),
      ],
    ),
  );
}
