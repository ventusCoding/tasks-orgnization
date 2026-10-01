import 'package:everslot/features/settings/presentation/settings_page_screen.dart';
import 'package:everslot/features/settings/presentation/settings_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// Advances route/sheet animations by a bounded number of frames (never `pumpAndSettle`: an
/// endless progress indicator would never settle and hang the test).
Future<void> pumpUi(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Drags the first scrollable by [step] until [finder] is built (lazy lists), then brings it
/// fully on screen.
Future<void> dragUntilFound(WidgetTester tester, Finder finder, Offset step, {int maxSteps = 40}) async {
  for (var i = 0; i < maxSteps && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, step);
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 50));
}

/// Pumps the settings routes (`/settings`, `/settings/:page`) with stub destinations for the
/// routes owned elsewhere; returns the router to inspect/drive navigation.
Future<GoRouter> pumpSettingsApp(
  WidgetTester tester,
  TestHarness h, {
  String initial = '/settings',
  Locale locale = const Locale('en'),
}) async {
  Widget stub(String name) => Scaffold(appBar: AppBar(), body: Text('stub:$name'));
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'trash', builder: (_, _) => stub('trash')),
          GoRoute(path: 'categories', builder: (_, _) => stub('categories')),
          GoRoute(path: 'tags', builder: (_, _) => stub('tags')),
          GoRoute(
            path: ':page',
            builder: (_, s) => SettingsPageScreen(page: s.pathParameters['page']!),
          ),
        ],
      ),
      GoRoute(path: '/auth/sign-in', builder: (_, _) => stub('sign-in')),
      GoRoute(path: '/dev', builder: (_, _) => stub('dev')),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      ),
    ),
  );
  return router;
}
