import 'package:everslot/features/settings/domain/settings_codec.dart';

// Typed settings namespaces (arch §8.5, T8.3.01). Values live in `user_settings.value` (one synced
// row per namespace); these classes are the app's typed view with defaults. Keys are the JSON
// contract other features read (e.g. `appearance.haptics`, `habits.dayStartMinutes`).

enum ThemePreference { system, light, dark }

enum DensityPreference { comfortable, compact }

/// Reduce motion: follow the OS, or force on/off (T8.3.12).
enum MotionPreference { system, on, off }

/// `appearance` (T8.3.02, T8.3.12).
class AppearanceSettings {
  const AppearanceSettings({
    this.theme = ThemePreference.system,
    this.density = DensityPreference.comfortable,
    this.arabicDigits = false,
    this.reduceMotion = MotionPreference.system,
    this.haptics = true,
    this.sounds = false,
    this.highContrastCategories = false,
    this.largeWeekTableText = false,
    this.statusPillLabels = false,
  });

  static const defaults = AppearanceSettings();

  final ThemePreference theme;
  final DensityPreference density;

  /// Arabic-Indic digits when the UI is in Arabic.
  final bool arabicDigits;
  final MotionPreference reduceMotion;

  /// Haptic feedback on snaps, lifts and completions (T1.3.17).
  final bool haptics;

  /// Short UI sounds (check-in completion), off by default.
  final bool sounds;
  final bool highContrastCategories;
  final bool largeWeekTableText;

  /// Always show text labels on status pills.
  final bool statusPillLabels;

  static final codec = SettingsCodec<AppearanceSettings>(
    namespace: 'appearance',
    version: 1,
    upgrades: {
      // v0 (pre-release builds): booleans instead of enums.
      0: (j) => {
        ...j,
        if (j['darkMode'] is bool && !j.containsKey('theme')) 'theme': j['darkMode'] == true ? 'dark' : 'light',
        if (j['compact'] is bool && !j.containsKey('density')) 'density': j['compact'] == true ? 'compact' : 'comfortable',
        if (j['reduceMotion'] is bool) 'reduceMotion': j['reduceMotion'] == true ? 'on' : 'system',
      }..removeWhere((k, _) => k == 'darkMode' || k == 'compact'),
    },
    decoder: (r) => AppearanceSettings(
      theme: r.choice('theme', ThemePreference.values, ThemePreference.system),
      density: r.choice('density', DensityPreference.values, DensityPreference.comfortable),
      arabicDigits: r.boolean('arabicDigits', false),
      reduceMotion: r.choice('reduceMotion', MotionPreference.values, MotionPreference.system),
      haptics: r.boolean('haptics', true),
      sounds: r.boolean('sounds', false),
      highContrastCategories: r.boolean('highContrastCategories', false),
      largeWeekTableText: r.boolean('largeWeekTableText', false),
      statusPillLabels: r.boolean('statusPillLabels', false),
    ),
    encoder: (s) => {
      'theme': s.theme.name,
      'density': s.density.name,
      'arabicDigits': s.arabicDigits,
      'reduceMotion': s.reduceMotion.name,
      'haptics': s.haptics,
      'sounds': s.sounds,
      'highContrastCategories': s.highContrastCategories,
      'largeWeekTableText': s.largeWeekTableText,
      'statusPillLabels': s.statusPillLabels,
    },
  );

  AppearanceSettings copyWith({
    ThemePreference? theme,
    DensityPreference? density,
    bool? arabicDigits,
    MotionPreference? reduceMotion,
    bool? haptics,
    bool? sounds,
    bool? highContrastCategories,
    bool? largeWeekTableText,
    bool? statusPillLabels,
  }) => AppearanceSettings(
    theme: theme ?? this.theme,
    density: density ?? this.density,
    arabicDigits: arabicDigits ?? this.arabicDigits,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    haptics: haptics ?? this.haptics,
    sounds: sounds ?? this.sounds,
    highContrastCategories: highContrastCategories ?? this.highContrastCategories,
    largeWeekTableText: largeWeekTableText ?? this.largeWeekTableText,
    statusPillLabels: statusPillLabels ?? this.statusPillLabels,
  );

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.theme == theme &&
      other.density == density &&
      other.arabicDigits == arabicDigits &&
      other.reduceMotion == reduceMotion &&
      other.haptics == haptics &&
      other.sounds == sounds &&
      other.highContrastCategories == highContrastCategories &&
      other.largeWeekTableText == largeWeekTableText &&
      other.statusPillLabels == statusPillLabels;

  @override
  int get hashCode => Object.hash(
    theme,
    density,
    arabicDigits,
    reduceMotion,
    haptics,
    sounds,
    highContrastCategories,
    largeWeekTableText,
    statusPillLabels,
  );
}

/// `regional` (T8.3.03). Week start, clock, zone and language live on the profile.
class RegionalSettings {
  const RegionalSettings({this.currency = 'EUR', this.homeZoneAuto = false});

  static const defaults = RegionalSettings();

  /// ISO 4217 code for quit-tracker savings.
  final String currency;

  /// The home zone follows the device automatically (no "make it home?" question).
  final bool homeZoneAuto;

  static final codec = SettingsCodec<RegionalSettings>(
    namespace: 'regional',
    version: 1,
    decoder: (r) {
      final currency = r.string('currency', 'EUR');
      return RegionalSettings(
        currency: RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : 'EUR',
        homeZoneAuto: r.boolean('homeZoneAuto', false),
      );
    },
    encoder: (s) => {'currency': s.currency, 'homeZoneAuto': s.homeZoneAuto},
  );

  RegionalSettings copyWith({String? currency, bool? homeZoneAuto}) =>
      RegionalSettings(currency: currency ?? this.currency, homeZoneAuto: homeZoneAuto ?? this.homeZoneAuto);

  @override
  bool operator ==(Object other) =>
      other is RegionalSettings && other.currency == currency && other.homeZoneAuto == homeZoneAuto;

  @override
  int get hashCode => Object.hash(currency, homeZoneAuto);
}

/// Skips are neutral, or they break the streak (`habits.skip_policy`).
enum SkipPolicy { neutral, breaks }

/// `habits` defaults (T8.3.03 day start, T8.3.05).
class HabitsDefaults {
  const HabitsDefaults({this.dayStartMinutes = 0, this.defaultSkipPolicy = SkipPolicy.neutral, this.defaultFreezesPerMonth = 0});

  static const defaults = HabitsDefaults();

  /// Habit "day starts at", minutes after midnight (arch §9.1).
  final int dayStartMinutes;
  final SkipPolicy defaultSkipPolicy;

  /// Streak freezes per month for new habits (0–31).
  final int defaultFreezesPerMonth;

  static final codec = SettingsCodec<HabitsDefaults>(
    namespace: 'habits',
    version: 1,
    upgrades: {
      // v0 used the arch §8.5 spelling `dayStartsAt: "04:00"`.
      0: (j) {
        final raw = j['dayStartsAt'];
        final m = raw is String ? RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw) : null;
        return {
          ...j,
          if (m != null && !j.containsKey('dayStartMinutes'))
            'dayStartMinutes': int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!),
        }..remove('dayStartsAt');
      },
    },
    decoder: (r) => HabitsDefaults(
      dayStartMinutes: r.integer('dayStartMinutes', 0, min: 0, max: 1439),
      defaultSkipPolicy: r.choice('defaultSkipPolicy', SkipPolicy.values, SkipPolicy.neutral),
      defaultFreezesPerMonth: r.integer('defaultFreezesPerMonth', 0, min: 0, max: 31),
    ),
    encoder: (s) => {
      'dayStartMinutes': s.dayStartMinutes,
      'defaultSkipPolicy': s.defaultSkipPolicy.name,
      'defaultFreezesPerMonth': s.defaultFreezesPerMonth,
    },
  );

  HabitsDefaults copyWith({int? dayStartMinutes, SkipPolicy? defaultSkipPolicy, int? defaultFreezesPerMonth}) =>
      HabitsDefaults(
        dayStartMinutes: dayStartMinutes ?? this.dayStartMinutes,
        defaultSkipPolicy: defaultSkipPolicy ?? this.defaultSkipPolicy,
        defaultFreezesPerMonth: defaultFreezesPerMonth ?? this.defaultFreezesPerMonth,
      );

  @override
  bool operator ==(Object other) =>
      other is HabitsDefaults &&
      other.dayStartMinutes == dayStartMinutes &&
      other.defaultSkipPolicy == defaultSkipPolicy &&
      other.defaultFreezesPerMonth == defaultFreezesPerMonth;

  @override
  int get hashCode => Object.hash(dayStartMinutes, defaultSkipPolicy, defaultFreezesPerMonth);
}

/// Checklist progress counts leaves or direct children.
enum ProgressModePreference { leaves, children }

/// `checklists` defaults for new lists (T8.3.05; per-list overrides live in `checklists.settings`).
class ChecklistsDefaults {
  const ChecklistsDefaults({
    this.requireReasonFor = const {'waiting', 'blocked'},
    this.autoCompleteParents = true,
    this.progressMode = ProgressModePreference.leaves,
    this.showCompleted = true,
    this.sortCompletedToBottom = false,
  });

  static const defaults = ChecklistsDefaults();
  static const reasonStatuses = {'ongoing', 'waiting', 'blocked', 'completed'};

  final Set<String> requireReasonFor;
  final bool autoCompleteParents;
  final ProgressModePreference progressMode;
  final bool showCompleted;
  final bool sortCompletedToBottom;

  static final codec = SettingsCodec<ChecklistsDefaults>(
    namespace: 'checklists',
    version: 1,
    decoder: (r) => ChecklistsDefaults(
      requireReasonFor: r.stringSet('requireReasonFor', const {'waiting', 'blocked'}, allowed: reasonStatuses),
      autoCompleteParents: r.boolean('autoCompleteParents', true),
      progressMode: r.choice('progressMode', ProgressModePreference.values, ProgressModePreference.leaves),
      showCompleted: r.boolean('showCompleted', true),
      sortCompletedToBottom: r.boolean('sortCompletedToBottom', false),
    ),
    encoder: (s) => {
      'requireReasonFor': [for (final st in const ['ongoing', 'waiting', 'blocked', 'completed']) if (s.requireReasonFor.contains(st)) st],
      'autoCompleteParents': s.autoCompleteParents,
      'progressMode': s.progressMode.name,
      'showCompleted': s.showCompleted,
      'sortCompletedToBottom': s.sortCompletedToBottom,
    },
  );

  ChecklistsDefaults copyWith({
    Set<String>? requireReasonFor,
    bool? autoCompleteParents,
    ProgressModePreference? progressMode,
    bool? showCompleted,
    bool? sortCompletedToBottom,
  }) => ChecklistsDefaults(
    requireReasonFor: requireReasonFor ?? this.requireReasonFor,
    autoCompleteParents: autoCompleteParents ?? this.autoCompleteParents,
    progressMode: progressMode ?? this.progressMode,
    showCompleted: showCompleted ?? this.showCompleted,
    sortCompletedToBottom: sortCompletedToBottom ?? this.sortCompletedToBottom,
  );

  @override
  bool operator ==(Object other) =>
      other is ChecklistsDefaults &&
      other.requireReasonFor.length == requireReasonFor.length &&
      other.requireReasonFor.containsAll(requireReasonFor) &&
      other.autoCompleteParents == autoCompleteParents &&
      other.progressMode == progressMode &&
      other.showCompleted == showCompleted &&
      other.sortCompletedToBottom == sortCompletedToBottom;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(requireReasonFor),
    autoCompleteParents,
    progressMode,
    showCompleted,
    sortCompletedToBottom,
  );
}

enum StatsPeriod { week, month, quarter, year }

/// `stats` defaults (T8.3.05; read by the stats engine [6.1]).
class StatsDefaults {
  const StatsDefaults({this.defaultPeriod = StatsPeriod.week, this.compareWithPrevious = true, this.weekStartOverride});

  static const defaults = StatsDefaults();

  final StatsPeriod defaultPeriod;
  final bool compareWithPrevious;

  /// ISO weekday for week-based stats (null = the profile's week start).
  final int? weekStartOverride;

  static final codec = SettingsCodec<StatsDefaults>(
    namespace: 'stats',
    version: 1,
    decoder: (r) => StatsDefaults(
      defaultPeriod: r.choice('defaultPeriod', StatsPeriod.values, StatsPeriod.week),
      compareWithPrevious: r.boolean('compareWithPrevious', true),
      weekStartOverride: r.optionalInt('weekStartOverride', min: 1, max: 7),
    ),
    encoder: (s) => {
      'defaultPeriod': s.defaultPeriod.name,
      'compareWithPrevious': s.compareWithPrevious,
      'weekStartOverride': s.weekStartOverride,
    },
  );

  StatsDefaults copyWith({StatsPeriod? defaultPeriod, bool? compareWithPrevious, Object? weekStartOverride = _unset}) =>
      StatsDefaults(
        defaultPeriod: defaultPeriod ?? this.defaultPeriod,
        compareWithPrevious: compareWithPrevious ?? this.compareWithPrevious,
        weekStartOverride: weekStartOverride == _unset ? this.weekStartOverride : weekStartOverride as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is StatsDefaults &&
      other.defaultPeriod == defaultPeriod &&
      other.compareWithPrevious == compareWithPrevious &&
      other.weekStartOverride == weekStartOverride;

  @override
  int get hashCode => Object.hash(defaultPeriod, compareWithPrevious, weekStartOverride);
}

const Object _unset = Object();

/// `privacy` (T8.3.09, T8.3.10, arch §6.15 crash-reporting opt-out).
class PrivacySettings {
  const PrivacySettings({
    this.crashReporting = true,
    this.appLockEnabled = false,
    this.appLockTimeoutSeconds = 0,
    this.appSwitcherPrivacy = false,
    this.hideNotificationContent = false,
  });

  static const defaults = PrivacySettings();

  /// Lock timeouts offered in Settings (0 = immediately).
  static const lockTimeouts = [0, 60, 300, 900];

  final bool crashReporting;
  final bool appLockEnabled;

  /// Seconds in the background before the lock engages again.
  final int appLockTimeoutSeconds;

  /// Hide the content in the app switcher / recents.
  final bool appSwitcherPrivacy;

  /// System notifications show generic text (read by the notification planner).
  final bool hideNotificationContent;

  static final codec = SettingsCodec<PrivacySettings>(
    namespace: 'privacy',
    version: 1,
    upgrades: {
      // v0 used the arch §8.5 spellings.
      0: (j) {
        final lock = j['appLock'];
        return {
          ...j,
          if (j['hideContentInNotifications'] is bool && !j.containsKey('hideNotificationContent'))
            'hideNotificationContent': j['hideContentInNotifications'],
          if (lock is Map) ...{
            'appLockEnabled': lock['enabled'] == true,
            if (lock['timeoutSeconds'] is num) 'appLockTimeoutSeconds': lock['timeoutSeconds'],
          },
        }
          ..remove('hideContentInNotifications')
          ..remove('appLock');
      },
    },
    decoder: (r) => PrivacySettings(
      crashReporting: r.boolean('crashReporting', true),
      appLockEnabled: r.boolean('appLockEnabled', false),
      appLockTimeoutSeconds: r.integer('appLockTimeoutSeconds', 0, min: 0, max: 86400),
      appSwitcherPrivacy: r.boolean('appSwitcherPrivacy', false),
      hideNotificationContent: r.boolean('hideNotificationContent', false),
    ),
    encoder: (s) => {
      'crashReporting': s.crashReporting,
      'appLockEnabled': s.appLockEnabled,
      'appLockTimeoutSeconds': s.appLockTimeoutSeconds,
      'appSwitcherPrivacy': s.appSwitcherPrivacy,
      'hideNotificationContent': s.hideNotificationContent,
    },
  );

  PrivacySettings copyWith({
    bool? crashReporting,
    bool? appLockEnabled,
    int? appLockTimeoutSeconds,
    bool? appSwitcherPrivacy,
    bool? hideNotificationContent,
  }) => PrivacySettings(
    crashReporting: crashReporting ?? this.crashReporting,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    appLockTimeoutSeconds: appLockTimeoutSeconds ?? this.appLockTimeoutSeconds,
    appSwitcherPrivacy: appSwitcherPrivacy ?? this.appSwitcherPrivacy,
    hideNotificationContent: hideNotificationContent ?? this.hideNotificationContent,
  );

  @override
  bool operator ==(Object other) =>
      other is PrivacySettings &&
      other.crashReporting == crashReporting &&
      other.appLockEnabled == appLockEnabled &&
      other.appLockTimeoutSeconds == appLockTimeoutSeconds &&
      other.appSwitcherPrivacy == appSwitcherPrivacy &&
      other.hideNotificationContent == hideNotificationContent;

  @override
  int get hashCode =>
      Object.hash(crashReporting, appLockEnabled, appLockTimeoutSeconds, appSwitcherPrivacy, hideNotificationContent);
}
