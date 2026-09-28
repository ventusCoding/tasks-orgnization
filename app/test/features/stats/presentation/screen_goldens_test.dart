// Goldens of the Insights scope screens on real computed data (fake clock, fixture tables):
// light LTR, dark RTL and text scale 2.0 per screen.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'screen_cases.dart';

void main() {
  for (final screen in screenCases) {
    for (final (variant, dark, rtl, scale) in [
      ('light_ltr', false, false, 1.0),
      ('dark_rtl', true, true, 1.0),
      ('light_ltr_2x', false, false, 2.0),
    ]) {
      testWidgets('${screen.name} golden $variant', (tester) async {
        final h = await screen.harness();
        addTearDown(h.dispose);
        await h.settle();
        tester.view.physicalSize = Size(420, scale == 1 ? screen.height : screen.height * 1.6);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: h.container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              locale: Locale(rtl ? 'ar' : 'en'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
                  child: screen.build(),
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        }
        await tester.pump(const Duration(milliseconds: 400));
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/screen_${screen.name}_$variant.png'));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 61));
      });
    }
  }
}
