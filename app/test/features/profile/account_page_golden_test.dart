// Goldens of Settings › Account (T1.5.13): signed-in account with two sign-in methods, light LTR
// and dark RTL (AR), plus text scale 2.0.
@Tags(['golden'])
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/theme.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/profile/presentation/account_page.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/support/cloud_sync_harness.dart';
import '../auth/support/widget_helpers.dart';

void main() {
  const variants = [
    (dark: false, rtl: false, scale: 1.0),
    (dark: true, rtl: true, scale: 1.0),
    (dark: false, rtl: false, scale: 2.0),
  ];
  for (final v in variants) {
    final name = 'account_${v.dark ? 'dark' : 'light'}_${v.rtl ? 'rtl' : 'ltr'}_${v.scale == 1 ? '1x' : '2x'}';
    testWidgets('golden $name', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final d = (await tester.runAsync(CloudDevice.create))!;
      d.repo.identityList = const [
        AuthIdentity(provider: 'email', identityId: 'eid', email: 'u1@x.io'),
        AuthIdentity(provider: 'google', identityId: 'gid', email: 'u1@gmail.com'),
      ];
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: d.h.container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: v.dark ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(v.rtl ? 'ar' : 'en'),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(v.scale), disableAnimations: true),
                child: const AccountPage(),
              ),
            ),
          ),
        ),
      );
      await settle(tester, rounds: 8);
      expect(tester.takeException(), isNull);
      expect(d.h.read(sessionProvider)!.isCloud, isTrue);
      await expectLater(find.byType(AccountPage), matchesGoldenFile('goldens/$name.png'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(d.dispose);
    });
  }
}
