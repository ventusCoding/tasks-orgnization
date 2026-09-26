import 'package:everslot/app/router.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/theme.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget: theme, localization (EN/FR/AR + RTL) and router.
class EverslotApp extends ConsumerWidget {
  const EverslotApp({super.key});

  static const supportedLocales = [Locale('en'), Locale('fr'), Locale('ar')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final appearance = ref.watch(settingsProvider(SettingsNs.appearance)).value ?? const {};
    final themeMode = switch (appearance['theme']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final density = appearance['density'] == 'compact' ? AppDensity.compact : AppDensity.comfortable;
    final locale = prefs.localeCode == null ? null : Locale(prefs.localeCode!);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(density: density),
      darkTheme: AppTheme.dark(density: density),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // material_ui's list includes the cupertino_ui Cupertino delegate (needed for Arabic).
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final wrapped = MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: prefs.use24h),
          child: child ?? const SizedBox.shrink(),
        );
        // Legacy packages (fl_chart, …) still read `package:flutter/material.dart` themes.
        // ignore: deprecated_member_use
        return MaterialUiCompatibilityBridge(child: wrapped);
      },
    );
  }
}
