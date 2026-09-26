import 'package:everslot/design_system/theme.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// Pumps a screen with one "open" button running [onOpen] (to show sheets and dialogs), with
/// the app theme (light/dark) and locale.
Future<void> pumpOpener(
  WidgetTester tester,
  TestHarness h,
  Future<void> Function(BuildContext context) onOpen, {
  Locale locale = const Locale('en'),
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const ValueKey('open'),
                onPressed: () => onOpen(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Taps the opener and settles.
Future<void> open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view inside the first scrollable of [scrollKey] and taps it.
Future<void> tapInList(WidgetTester tester, Finder finder, {Key? scrollKey}) async {
  final scrollable = scrollKey == null
      ? find.byType(Scrollable).last
      : find.descendant(of: find.byKey(scrollKey), matching: find.byType(Scrollable)).first;
  if (finder.evaluate().isEmpty) {
    // The target may be above the viewport: restart from the top, then scroll down to it.
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(finder, 120, scrollable: scrollable);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
