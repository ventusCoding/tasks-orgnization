/// First-run essentials (T1.5.05): locale-aware defaults for week start and clock format.
///
/// Week start follows CLDR `weekData/firstDay` (supplemental data, v47); a bare language uses
/// its likely region (`en` → US, `fr` → FR, `ar` → EG).
abstract final class FirstRunDefaults {
  static const _sunday = {
    'AG', 'AS', 'BD', 'BR', 'BS', 'BT', 'BW', 'BZ', 'CA', 'CO', 'DM', 'DO', 'ET', 'GT', 'GU', 'HK',
    'HN', 'ID', 'IL', 'IN', 'JM', 'JP', 'KE', 'KH', 'KR', 'LA', 'MH', 'MM', 'MO', 'MT', 'MX', 'MZ',
    'NI', 'NP', 'PA', 'PE', 'PH', 'PK', 'PR', 'PT', 'PY', 'SA', 'SG', 'SV', 'TH', 'TT', 'TW', 'UM',
    'US', 'VE', 'VI', 'WS', 'YE', 'ZA', 'ZW',
  };
  static const _saturday = {
    'AE', 'AF', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'IR', 'JO', 'KW', 'LY', 'OM', 'QA', 'SD', 'SY',
  };
  static const _friday = {'MV'};

  /// Likely region of the languages Everslot ships (CLDR likely subtags).
  static const likelyRegion = {'en': 'US', 'fr': 'FR', 'ar': 'EG'};

  /// Regions whose CLDR short time pattern uses a 12-hour clock (`h:mm a`); others use 24 h.
  static const _twelveHour = {
    'US', 'CA', 'AU', 'NZ', 'PH', 'IN', 'PK', 'BD', 'EG', 'SA', 'AE', 'KW', 'QA', 'BH', 'OM',
    'JO', 'LB', 'SY', 'IQ', 'YE', 'SD', 'LY', 'MX', 'CO', 'SV', 'HN', 'NI', 'KR', 'TW', 'HK', 'MY',
  };

  static String _region(String languageCode, String? countryCode) {
    final region = (countryCode ?? '').toUpperCase();
    if (region.isNotEmpty) return region;
    return likelyRegion[languageCode.toLowerCase()] ?? '001';
  }

  /// ISO weekday (1 = Monday, 5 = Friday, 6 = Saturday, 7 = Sunday).
  static int weekStartFor(String languageCode, [String? countryCode]) {
    final region = _region(languageCode, countryCode);
    if (_sunday.contains(region)) return 7;
    if (_saturday.contains(region)) return 6;
    if (_friday.contains(region)) return 5;
    return 1;
  }

  /// Whether the locale's conventional clock is 24-hour ([deviceSetting] — the OS "24-hour time"
  /// switch — wins when known).
  static bool prefers24h(String languageCode, [String? countryCode, bool? deviceSetting]) {
    if (deviceSetting ?? false) return true;
    return !_twelveHour.contains(_region(languageCode, countryCode));
  }

  /// Interface language for a system locale (falls back to English).
  static String languageFor(String languageCode) {
    final code = languageCode.toLowerCase();
    return const ['en', 'fr', 'ar'].contains(code) ? code : 'en';
  }
}
