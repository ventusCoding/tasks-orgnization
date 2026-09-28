// Goldens of the settings root and Appearance page (T8.3.01, T8.3.02): light/dark × LTR/RTL (AR),
// plus text scale 2.0.
@Tags(['golden'])
library;

import 'package:everslot/design_system/theme.dart';
import 'package:everslot/features/settings/presentation/pages/appearance_page.dart';
import 'package:everslot/features/settings/presentation/settings_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

Future<void> _pump(WidgetTester tester, TestHarness h, Widget child, {required bool dark, required bool rtl, required double scale}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: Locale(rtl ? 'ar' : 'en'),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  const variants = [
    (dark: false, rtl: false, scale: 1.0),
    (dark: false, rtl: true, scale: 1.0),
    (dark: true, rtl: true, scale: 1.0),
    (dark: false, rtl: false, scale: 2.0),
  ];
  final screens = <String, Widget Function()>{
    'settings_root': SettingsScreen.new,
    'appearance': AppearancePage.new,
  };
  for (final s in screens.entries) {
    for (final v in variants) {
      final name = '${s.key}_${v.dark ? 'dark' : 'light'}_${v.rtl ? 'rtl' : 'ltr'}_${v.scale == 1 ? '1x' : '2x'}';
      testWidgets('golden $name', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final h = TestHarness.create();
        await _pump(tester, h, s.value(), dark: v.dark, rtl: v.rtl, scale: v.scale);
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(h.dispose);
      });
    }
  }
}
