// Goldens of the badge share card (T5.4.09) — light/English and dark/Arabic (RTL).
// Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:everslot/features/goals/presentation/badge_share_card.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget card({required Brightness brightness, Locale locale = const Locale('en')}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    home: const Scaffold(
      body: Center(
        child: BadgeShareCard(code: AchievementCode.streak30, habitName: 'Meditate', dateText: 'Sep 22, 2026'),
      ),
    ),
  );

  testWidgets('light, English', (tester) async {
    await tester.pumpWidget(card(brightness: Brightness.light));
    await tester.pump();
    await expectLater(find.byType(BadgeShareCard), matchesGoldenFile('goldens/badge_share_card_light_en.png'));
  });

  testWidgets('dark, Arabic', (tester) async {
    await tester.pumpWidget(card(brightness: Brightness.dark, locale: const Locale('ar')));
    await tester.pump();
    await expectLater(find.byType(BadgeShareCard), matchesGoldenFile('goldens/badge_share_card_dark_ar.png'));
  });
}
