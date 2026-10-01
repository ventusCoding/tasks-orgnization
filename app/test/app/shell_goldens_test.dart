@Tags(['golden'])
library;

import 'package:everslot/app/shell_scaffold.dart';
import 'package:everslot/core/preferences/last_tab.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fonts.dart';
import '../support/test_app.dart';

/// T1.3.12: the shell at the three breakpoints (bar, rail, extended rail), plus dark RTL.
void main() {
  setUpAll(loadAppFonts);

  const variants = [
    (name: 'compact_light_ltr', size: Size(400, 760), dark: false, rtl: false),
    (name: 'medium_light_ltr', size: Size(720, 600), dark: false, rtl: false),
    (name: 'expanded_light_ltr', size: Size(1000, 600), dark: false, rtl: false),
    (name: 'compact_dark_rtl', size: Size(400, 760), dark: true, rtl: true),
  ];
  for (final v in variants) {
    testWidgets('golden shell_${v.name}', (tester) async {
      final h = TestHarness.create();
      tester.view
        ..physicalSize = v.size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/habits',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => ShellScaffold(shell: shell),
            branches: [
              for (final path in LastTab.paths)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (context, _) => Scaffold(
                        appBar: AppBar(title: Text(path)),
                        body: const EmptyState(icon: Icons.inbox_outlined, title: 'Content'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            parent: h.container,
            overrides: [tabBadgesProvider.overrideWithValue(const [0, 0, 0, 4, 0])],
          ),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: v.dark ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(v.rtl ? 'ar' : 'en'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/shell_${v.name}.png'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(h.dispose);
    });
  }
}
