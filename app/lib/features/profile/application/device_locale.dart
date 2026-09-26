import 'dart:ui';

import 'package:everslot/features/profile/domain/first_run_defaults.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The OS locale (overridden in tests).
final deviceLocaleProvider = Provider<Locale>((ref) => PlatformDispatcher.instance.locale);

/// The OS "24-hour time" switch (overridden in tests).
final device24hProvider = Provider<bool>((ref) => PlatformDispatcher.instance.alwaysUse24HourFormat);

/// Locale-derived defaults for a first run (T1.5.05).
final firstRunWeekStartProvider = Provider<int>((ref) {
  final locale = ref.watch(deviceLocaleProvider);
  return FirstRunDefaults.weekStartFor(locale.languageCode, locale.countryCode);
});

final firstRunUse24hProvider = Provider<bool>((ref) {
  final locale = ref.watch(deviceLocaleProvider);
  return FirstRunDefaults.prefers24h(locale.languageCode, locale.countryCode, ref.watch(device24hProvider));
});
