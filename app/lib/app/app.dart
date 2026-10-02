import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:everslot/app/router.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/motion.dart';
import 'package:everslot/design_system/theme.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:everslot/features/auth/presentation/session_banner_host.dart';
import 'package:everslot/features/checklists/presentation/move_conflict_notices.dart';
import 'package:everslot/features/privacy/presentation/app_lock_gate.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot/shared/shortcuts/presentation/global_shortcuts.dart';
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
    final isDevFlavor = ref.watch(envProvider).isDev;
    final useDynamicColor = appearance['dynamicColor'] == true;

    // Android 12+ wallpaper colors when enabled (T1.3.08); null schemes elsewhere.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.light(density: density, scheme: useDynamicColor ? lightDynamic?.harmonized() : null),
        darkTheme: AppTheme.dark(density: density, scheme: useDynamicColor ? darkDynamic?.harmonized() : null),
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
          Widget wrapped = MediaQuery(
            data: media.copyWith(alwaysUse24HourFormat: prefs.use24h),
            // Session / time-zone banners above every screen (T1.5.06, T1.5.14); the in-app
            // "Reduce motion" setting joins the OS one (T1.3.15).
            child: SessionBannerHost(
              onOpen: router.go,
              child: ReduceMotionScope(
                // Keyboard shortcuts: undo/redo, search… (T1.3.19, T2.3.06).
                child: GlobalShortcuts(
                  onSearch: () => unawaited(router.push<void>(AppLinks.search())),
                  // Checklist move conflicts from sync (T4.1.05).
                  // App lock and app-switcher cover over everything (T8.3.09).
                  child: AppLockGate(child: MoveConflictNotices(child: child ?? const SizedBox.shrink())),
                ),
              ),
            ),
          );
          // Dev-flavor corner marker (T1.1.10), like the debug banner: painted only, not localized.
          if (isDevFlavor) {
            wrapped = Banner(
              message: 'DEV',
              location: BannerLocation.topEnd,
              color: BrandColors.devBanner,
              child: wrapped,
            );
          }
          // Legacy packages (fl_chart, …) still read `package:flutter/material.dart` themes.
          // ignore: deprecated_member_use
          return MaterialUiCompatibilityBridge(child: wrapped);
        },
      ),
    );
  }
}
