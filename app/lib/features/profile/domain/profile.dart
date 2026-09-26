/// 12- or 24-hour clock (`profiles.time_format`).
enum TimeFormat {
  h12,
  h24;

  static TimeFormat fromJson(Object? value) => value == 'h12' ? TimeFormat.h12 : TimeFormat.h24;
}

const Object _unset = Object();

/// The user profile (arch §7.3 `profiles`, T1.5.04): identity and the regional essentials the
/// whole app depends on. `id` is the user id.
class Profile {
  const Profile({
    required this.id,
    this.displayName,
    this.avatarPath,
    this.homeTimeZone = 'UTC',
    this.currentTimeZone,
    this.locale,
    this.weekStart = 1,
    this.timeFormat = TimeFormat.h24,
    this.onboardingCompletedAt,
  });

  final String id;
  final String? displayName;

  /// Storage path of the avatar attachment (square crop), if any.
  final String? avatarPath;

  /// IANA zone used for wall-clock values by default.
  final String homeTimeZone;

  /// Last device zone reported (T1.5.06).
  final String? currentTimeZone;

  /// Language override (`en` | `fr` | `ar`), null = follow the system.
  final String? locale;

  /// ISO weekday the week starts on (1 = Monday … 7 = Sunday).
  final int weekStart;
  final TimeFormat timeFormat;

  /// First-run essentials / onboarding finished (T1.5.05, T8.3.11).
  final DateTime? onboardingCompletedAt;

  bool get use24h => timeFormat == TimeFormat.h24;
  bool get onboardingDone => onboardingCompletedAt != null;

  Profile copyWith({
    Object? displayName = _unset,
    Object? avatarPath = _unset,
    String? homeTimeZone,
    Object? currentTimeZone = _unset,
    Object? locale = _unset,
    int? weekStart,
    TimeFormat? timeFormat,
    Object? onboardingCompletedAt = _unset,
  }) => Profile(
    id: id,
    displayName: displayName == _unset ? this.displayName : displayName as String?,
    avatarPath: avatarPath == _unset ? this.avatarPath : avatarPath as String?,
    homeTimeZone: homeTimeZone ?? this.homeTimeZone,
    currentTimeZone: currentTimeZone == _unset ? this.currentTimeZone : currentTimeZone as String?,
    locale: locale == _unset ? this.locale : locale as String?,
    weekStart: weekStart ?? this.weekStart,
    timeFormat: timeFormat ?? this.timeFormat,
    onboardingCompletedAt: onboardingCompletedAt == _unset
        ? this.onboardingCompletedAt
        : onboardingCompletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.displayName == displayName &&
      other.avatarPath == avatarPath &&
      other.homeTimeZone == homeTimeZone &&
      other.currentTimeZone == currentTimeZone &&
      other.locale == locale &&
      other.weekStart == weekStart &&
      other.timeFormat == timeFormat &&
      other.onboardingCompletedAt == onboardingCompletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    avatarPath,
    homeTimeZone,
    currentTimeZone,
    locale,
    weekStart,
    timeFormat,
    onboardingCompletedAt,
  );

  @override
  String toString() => 'Profile($id, home: $homeTimeZone, week: $weekStart, ${timeFormat.name})';
}

/// Supported interface languages (T8.3.02).
const supportedLanguageCodes = ['en', 'fr', 'ar'];

/// Validation shared by the repository and the editors.
abstract final class ProfileRules {
  static const maxDisplayNameLength = 100;

  static bool isValidWeekStart(int day) => day >= 1 && day <= 7;

  static bool isValidLocale(String? code) => code == null || supportedLanguageCodes.contains(code);

  /// Trims, collapses whitespace and caps the length; empty → null.
  static String? normalizeDisplayName(String? name) {
    if (name == null) return null;
    final v = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v.isEmpty) return null;
    return v.length > maxDisplayNameLength ? v.substring(0, maxDisplayNameLength) : v;
  }
}
