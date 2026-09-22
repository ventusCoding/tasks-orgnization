import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Resolved per-user preferences used everywhere (profile + settings + device zone).
class UserPreferences {
  const UserPreferences({
    required this.weekStart,
    required this.use24h,
    required this.dayStartMinutes,
    required this.homeTimeZone,
    required this.currentTimeZone,
    required this.localeCode,
    required this.currency,
    required this.useArabicDigits,
  });

  static const defaults = UserPreferences(
    weekStart: Weekday.monday,
    use24h: true,
    dayStartMinutes: 0,
    homeTimeZone: 'UTC',
    currentTimeZone: 'UTC',
    localeCode: null,
    currency: 'EUR',
    useArabicDigits: false,
  );

  final Weekday weekStart;
  final bool use24h;

  /// Habit "day starts at" (arch §9.1), minutes after midnight.
  final int dayStartMinutes;
  final String homeTimeZone;

  /// Zone the device is in now — used for floating times.
  final String currentTimeZone;

  /// Explicit language override ('en' | 'fr' | 'ar') or null = system.
  final String? localeCode;
  final String currency;
  final bool useArabicDigits;

  UserPreferences copyWith({
    Weekday? weekStart,
    bool? use24h,
    int? dayStartMinutes,
    String? homeTimeZone,
    String? currentTimeZone,
    String? localeCode,
    bool clearLocale = false,
    String? currency,
    bool? useArabicDigits,
  }) => UserPreferences(
    weekStart: weekStart ?? this.weekStart,
    use24h: use24h ?? this.use24h,
    dayStartMinutes: dayStartMinutes ?? this.dayStartMinutes,
    homeTimeZone: homeTimeZone ?? this.homeTimeZone,
    currentTimeZone: currentTimeZone ?? this.currentTimeZone,
    localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    currency: currency ?? this.currency,
    useArabicDigits: useArabicDigits ?? this.useArabicDigits,
  );
}
