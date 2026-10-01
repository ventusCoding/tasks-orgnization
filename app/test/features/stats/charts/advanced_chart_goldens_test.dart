// Golden matrix of the P1/P2 chart kit (T6.2.13–T6.2.26): light/dark × LTR/RTL × text scale 1.0/2.0,
// one gallery image per variant with the fixture data of chart_samples.dart.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget gallery({required bool dark, required bool rtl, required double scale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: ChartPrefs(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final s in advancedChartSamples())
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ChartFrame(title: s.title, data: s.data, chartHeight: 160, onExplain: () {}),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}_${scale == 1 ? '1x' : '2x'}';
        testWidgets('P1/P2 charts golden $name', (tester) async {
          tester.view.physicalSize = Size(420, scale == 1 ? 5600 : 7600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(gallery(dark: dark, rtl: rtl, scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(find.byType(ListView), matchesGoldenFile('goldens/advanced_charts_$name.png'));
        });
      }
    }
  }
}
