import 'dart:ui';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ensures the current user has a profile (first-run essentials T1.5.05: zone, week start,
/// 12/24 h, locale) and the default categories (T2.3.02). Idempotent.
Future<void> ensureProfileAndDefaults(ProviderContainer container) async {
  final db = container.read(appDatabaseProvider);
  final userId = container.read(currentUserIdProvider);
  if (userId.isEmpty) return;
  // Cloud accounts: the server creates the profile (auth trigger) and other devices may already
  // have edited it or seeded the defaults — wait for the first pull, otherwise this device's
  // fresh defaults (newer clocks) would overwrite them. The auth binding calls this again once
  // the first sync succeeded (T1.5.05).
  if (container.read(sessionProvider)?.isCloud ?? false) {
    final state = await (db.select(db.syncState)..where((s) => s.userId.equals(userId))).getSingleOrNull();
    if (state?.lastPullAt == null) return;
  }
  final writer = container.read(syncWriterProvider);
  final existing = await (db.select(db.profiles)..where((p) => p.id.equals(userId))).getSingleOrNull();
  final systemLocale = PlatformDispatcher.instance.locale;
  if (existing == null) {
    final zone = container.read(deviceZoneProvider);
    await writer.run((tx) => tx.insert('profiles', userId, {
      'home_time_zone': zone,
      'current_time_zone': zone,
      'week_start': _weekStartFor(systemLocale),
      'time_format': PlatformDispatcher.instance.alwaysUse24HourFormat || _prefers24h(systemLocale)
          ? 'h24'
          : 'h12',
    }), cause: 'auto');
  }
  final l10n = lookupAppLocalizations(
    const [Locale('en'), Locale('fr'), Locale('ar')].firstWhere(
      (l) => l.languageCode == systemLocale.languageCode,
      orElse: () => const Locale('en'),
    ),
  );
  await container.read(categoriesRepositoryProvider).seedDefaults({
    'work': l10n.categoryDefaultWork,
    'personal': l10n.categoryDefaultPersonal,
    'health': l10n.categoryDefaultHealth,
    'study': l10n.categoryDefaultStudy,
    'home': l10n.categoryDefaultHome,
    'social': l10n.categoryDefaultSocial,
  });
}

/// ISO week start from CLDR conventions (1 = Monday, 6 = Saturday, 7 = Sunday).
int _weekStartFor(Locale locale) {
  const sundayCountries = {'US', 'CA', 'JP', 'BR', 'MX', 'IL', 'PH', 'KR', 'IN', 'ZA'};
  const saturdayCountries = {'EG', 'SA', 'AE', 'KW', 'QA', 'BH', 'OM', 'JO', 'SY', 'IQ', 'LY', 'DZ', 'AF', 'IR'};
  final country = locale.countryCode ?? '';
  if (sundayCountries.contains(country)) return 7;
  if (saturdayCountries.contains(country)) return 6;
  return 1;
}

bool _prefers24h(Locale locale) {
  final pattern = DateFormat.jm(locale.toLanguageTag()).pattern ?? '';
  return !pattern.contains('a');
}
