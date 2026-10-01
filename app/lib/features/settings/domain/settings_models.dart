import 'package:everslot/features/settings/domain/settings_codec.dart';

// Typed settings namespaces (arch §8.5, T8.3.01). Values live in `user_settings.value` (one synced
// row per namespace); these classes are the app's typed view with defaults. Keys are the JSON
// contract other features read (e.g. `appearance.haptics`, `habits.dayStartMinutes`).

enum ThemePreference { system, light, dark }

enum DensityPreference { comfortable, compact }

/// `appearance` (T8.3.02, T8.3.12).
class AppearanceSettings {
  const AppearanceSettings({
    this.theme = ThemePreference.system,
    this.density = DensityPreference.comfortable,
    this.arabicDigits = false,
    this.reduceMotion = false,
    this.haptics = true,
    this.sounds = false,
    this.highContrastCategories = false,
    this.largeWeekTableText = false,
    this.statusPillLabels = false,
    this.dynamicColor = false,
  });

  static const defaults = AppearanceSettings();

  final ThemePreference theme;
  final DensityPreference density;

  /// Arabic-Indic digits when the UI is in Arabic.
  final bool arabicDigits;

  /// Reduce motion regardless of the OS setting (false = follow the OS). Read as a bool by
  /// `design_system/motion.dart` (`reduceMotionSettingProvider`), T1.3.15 / T8.3.12.
  final bool reduceMotion;

  /// Haptic feedback on snaps, lifts and completions (T1.3.17).
  final bool haptics;

  /// Short UI sounds (check-in completion), off by default.
  final bool sounds;
  final bool highContrastCategories;
  final bool largeWeekTableText;

  /// Always show text labels on status pills.
  final bool statusPillLabels;

  /// Material You colors from the wallpaper (Android 12+, T1.3.08). Category colors never change.
  final bool dynamicColor;

  static final codec = SettingsCodec<AppearanceSettings>(
    namespace: 'appearance',
    version: 1,
    upgrades: {
      // v0 (pre-release builds): booleans instead of enums.
      0: (j) => {
        ...j,
        if (j['darkMode'] is bool && !j.containsKey('theme')) 'theme': j['darkMode'] == true ? 'dark' : 'light',
        if (j['compact'] is bool && !j.containsKey('density'))
          'density': j['compact'] == true ? 'compact' : 'comfortable',
      }..removeWhere((k, _) => k == 'darkMode' || k == 'compact'),
    },
    decoder: (r) => AppearanceSettings(
      theme: r.choice('theme', ThemePreference.values, ThemePreference.system),
      density: r.choice('density', DensityPreference.values, DensityPreference.comfortable),
      arabicDigits: r.boolean('arabicDigits', false),
      reduceMotion: r.boolean('reduceMotion', false),
      haptics: r.boolean('haptics', true),
      sounds: r.boolean('sounds', false),
      highContrastCategories: r.boolean('highContrastCategories', false),
      largeWeekTableText: r.boolean('largeWeekTableText', false),
      statusPillLabels: r.boolean('statusPillLabels', false),
      dynamicColor: r.boolean('dynamicColor', false),
    ),
    encoder: (s) => {
      'theme': s.theme.name,
      'density': s.density.name,
      'arabicDigits': s.arabicDigits,
      'reduceMotion': s.reduceMotion,
      'haptics': s.haptics,
      'sounds': s.sounds,
      'highContrastCategories': s.highContrastCategories,
      'largeWeekTableText': s.largeWeekTableText,
      'statusPillLabels': s.statusPillLabels,
      'dynamicColor': s.dynamicColor,
    },
  );

  AppearanceSettings copyWith({
    ThemePreference? theme,
    DensityPreference? density,
    bool? arabicDigits,
    bool? reduceMotion,
    bool? haptics,
    bool? sounds,
    bool? highContrastCategories,
    bool? largeWeekTableText,
    bool? statusPillLabels,
    bool? dynamicColor,
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
    dynamicColor: dynamicColor ?? this.dynamicColor,
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
      other.statusPillLabels == statusPillLabels &&
      other.dynamicColor == dynamicColor;

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
    dynamicColor,
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

/// `planner` defaults edited in Settings › Plan (T8.3.05). Same keys and value spellings as the
/// planner's `PlannerSettings` / `WorkSettings` (arch §8.5); other planner keys are preserved.
class PlannerDefaults {
  const PlannerDefaults({
    this.defaultTaskDurationMinutes = 30,
    this.defaultTrackingMode = 'check',
    this.missedGraceMinutes = 15,
    this.rollOverIncomplete = 'off',
    this.askActualTimeOnDone = 'if_off_schedule',
    this.workStartMinute = 540,
    this.workEndMinute = 1020,
    this.workDays = const {1, 2, 3, 4, 5},
  });

  static const defaults = PlannerDefaults();

  static const trackingModes = ['check', 'event', 'timer'];
  static const rollOverPolicies = ['off', 'ask', 'auto'];
  static const askActualTimeChoices = ['never', 'if_off_schedule', 'always'];
  static const graceChoices = [0, 5, 10, 15, 30, 60];

  final int defaultTaskDurationMinutes;
  final String defaultTrackingMode;
  final int missedGraceMinutes;
  final String rollOverIncomplete;
  final String askActualTimeOnDone;

  /// Work hours, minutes after midnight (`workHours: {start: "09:00", end: "17:00"}`).
  final int workStartMinute;
  final int workEndMinute;

  /// ISO weekdays (`workDays`).
  final Set<int> workDays;

  static String hhmm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  static int? parseHhmm(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
    if (m == null) return null;
    final minutes = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    return minutes > 1440 ? null : minutes;
  }

  static final codec = SettingsCodec<PlannerDefaults>(
    namespace: 'planner',
    version: 1,
    decoder: (r) {
      final hours = r.object('workHours');
      var start = parseHhmm(hours['start']) ?? 540;
      var end = parseHhmm(hours['end']) ?? 1020;
      if (start >= end) {
        start = 540;
        end = 1020;
      }
      final days = r.json['workDays'];
      final parsedDays = days is List
          ? {
              for (final d in days)
                if (d is num && d >= 1 && d <= 7) d.toInt(),
            }
          : <int>{};
      return PlannerDefaults(
        defaultTaskDurationMinutes: r.integer('defaultTaskDurationMinutes', 30, min: 1, max: 1440),
        defaultTrackingMode: r.string('defaultTrackingMode', 'check', allowed: trackingModes.toSet()),
        missedGraceMinutes: r.integer('missedGraceMinutes', 15, min: 0, max: 1440),
        rollOverIncomplete: r.string('rollOverIncomplete', 'off', allowed: rollOverPolicies.toSet()),
        askActualTimeOnDone: r.string('askActualTimeOnDone', 'if_off_schedule', allowed: askActualTimeChoices.toSet()),
        workStartMinute: start,
        workEndMinute: end,
        workDays: parsedDays.isEmpty ? const {1, 2, 3, 4, 5} : parsedDays,
      );
    },
    encoder: (s) => {
      'defaultTaskDurationMinutes': s.defaultTaskDurationMinutes,
      'defaultTrackingMode': s.defaultTrackingMode,
      'missedGraceMinutes': s.missedGraceMinutes,
      'rollOverIncomplete': s.rollOverIncomplete,
      'askActualTimeOnDone': s.askActualTimeOnDone,
      'workHours': {'start': hhmm(s.workStartMinute), 'end': hhmm(s.workEndMinute)},
      'workDays': [
        for (var d = 1; d <= 7; d++)
          if (s.workDays.contains(d)) d,
      ],
    },
  );

  PlannerDefaults copyWith({
    int? defaultTaskDurationMinutes,
    String? defaultTrackingMode,
    int? missedGraceMinutes,
    String? rollOverIncomplete,
    String? askActualTimeOnDone,
    int? workStartMinute,
    int? workEndMinute,
    Set<int>? workDays,
  }) => PlannerDefaults(
    defaultTaskDurationMinutes: defaultTaskDurationMinutes ?? this.defaultTaskDurationMinutes,
    defaultTrackingMode: defaultTrackingMode ?? this.defaultTrackingMode,
    missedGraceMinutes: missedGraceMinutes ?? this.missedGraceMinutes,
    rollOverIncomplete: rollOverIncomplete ?? this.rollOverIncomplete,
    askActualTimeOnDone: askActualTimeOnDone ?? this.askActualTimeOnDone,
    workStartMinute: workStartMinute ?? this.workStartMinute,
    workEndMinute: workEndMinute ?? this.workEndMinute,
    workDays: workDays ?? this.workDays,
  );

  @override
  bool operator ==(Object other) =>
      other is PlannerDefaults &&
      other.defaultTaskDurationMinutes == defaultTaskDurationMinutes &&
      other.defaultTrackingMode == defaultTrackingMode &&
      other.missedGraceMinutes == missedGraceMinutes &&
      other.rollOverIncomplete == rollOverIncomplete &&
      other.askActualTimeOnDone == askActualTimeOnDone &&
      other.workStartMinute == workStartMinute &&
      other.workEndMinute == workEndMinute &&
      other.workDays.length == workDays.length &&
      other.workDays.containsAll(workDays);

  @override
  int get hashCode => Object.hash(
    defaultTaskDurationMinutes,
    defaultTrackingMode,
    missedGraceMinutes,
    rollOverIncomplete,
    askActualTimeOnDone,
    workStartMinute,
    workEndMinute,
    Object.hashAllUnordered(workDays),
  );
}

/// Skips are neutral, or they break the streak (`habits.skip_policy`).
enum SkipPolicy { neutral, breaks }

/// `habits` defaults (T8.3.03 day start, T8.3.05).
class HabitsDefaults {
  const HabitsDefaults({
    this.dayStartMinutes = 0,
    this.defaultSkipPolicy = SkipPolicy.neutral,
    this.defaultFreezesPerMonth = 0,
  });

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
      'requireReasonFor': [
        for (final st in const ['ongoing', 'waiting', 'blocked', 'completed'])
          if (s.requireReasonFor.contains(st)) st,
      ],
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

/// `stats` defaults (T8.3.05; read by the stats engine [6.1] as `StatsSettings`).
class StatsDefaults {
  const StatsDefaults({this.defaultPeriod = 'thisWeek', this.compareWithPrevious = true, this.weekStartOverride});

  static const defaults = StatsDefaults();

  /// Periods offered in Settings › Insights (`StatsPeriod.parsePeriod` keys of the stats feature;
  /// any other stored key — `rolling:90`, `custom:…` — is kept as is).
  static const periodChoices = [
    'thisWeek',
    'lastWeek',
    'thisMonth',
    'lastMonth',
    'thisQuarter',
    'thisYear',
    'rolling:7',
    'rolling:30',
  ];

  /// Stats period key (`thisWeek`, `thisMonth`, `rolling:30`…).
  final String defaultPeriod;
  final bool compareWithPrevious;

  /// ISO weekday for week-based stats (null = the profile's week start).
  final int? weekStartOverride;

  static final codec = SettingsCodec<StatsDefaults>(
    namespace: 'stats',
    version: 1,
    decoder: (r) {
      final period = r.string('defaultPeriod', 'thisWeek');
      return StatsDefaults(
        defaultPeriod: period.trim().isEmpty ? 'thisWeek' : period,
        compareWithPrevious: r.boolean('compareWithPrevious', true),
        weekStartOverride: r.optionalInt('weekStartOverride', min: 1, max: 7),
      );
    },
    encoder: (s) => {
      'defaultPeriod': s.defaultPeriod,
      'compareWithPrevious': s.compareWithPrevious,
      'weekStartOverride': s.weekStartOverride,
    },
  );

  StatsDefaults copyWith({String? defaultPeriod, bool? compareWithPrevious, Object? weekStartOverride = _unset}) =>
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
