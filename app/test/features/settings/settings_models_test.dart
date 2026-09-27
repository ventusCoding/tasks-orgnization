import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/settings/domain/settings_codec.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fixture(String namespace) {
  final all = jsonDecode(File('test/features/settings/fixtures/settings_v0.json').readAsStringSync()) as Map;
  return Map<String, dynamic>.from(all[namespace] as Map);
}

/// Round-trip through JSON (what the database stores).
Map<String, dynamic> _stored(Map<String, Object?> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

void main() {
  group('defaults (empty namespace)', () {
    test('every namespace decodes {} to its defaults without warnings', () {
      final warnings = <String>[];
      expect(AppearanceSettings.codec.decode({}, onWarning: warnings.add), AppearanceSettings.defaults);
      expect(RegionalSettings.codec.decode({}, onWarning: warnings.add), RegionalSettings.defaults);
      expect(HabitsDefaults.codec.decode({}, onWarning: warnings.add), HabitsDefaults.defaults);
      expect(ChecklistsDefaults.codec.decode({}, onWarning: warnings.add), ChecklistsDefaults.defaults);
      expect(StatsDefaults.codec.decode({}, onWarning: warnings.add), StatsDefaults.defaults);
      expect(PrivacySettings.codec.decode({}, onWarning: warnings.add), PrivacySettings.defaults);
      expect(warnings, isEmpty);
    });

    test('defaults match the contracts other features rely on', () {
      expect(AppearanceSettings.defaults.haptics, isTrue, reason: 'planner reads appearance.haptics != false');
      expect(AppearanceSettings.defaults.sounds, isFalse);
      expect(HabitsDefaults.defaults.dayStartMinutes, 0);
      expect(RegionalSettings.defaults.currency, 'EUR');
      expect(PrivacySettings.defaults.hideNotificationContent, isFalse);
      expect(ChecklistsDefaults.defaults.requireReasonFor, {'waiting', 'blocked'});
    });
  });

  group('round-trip', () {
    test('non-default values survive encode → JSON → decode for every namespace', () {
      const appearance = AppearanceSettings(
        theme: ThemePreference.dark,
        density: DensityPreference.compact,
        arabicDigits: true,
        reduceMotion: true,
        haptics: false,
        sounds: true,
        highContrastCategories: true,
        largeWeekTableText: true,
        statusPillLabels: true,
      );
      expect(AppearanceSettings.codec.decode(_stored(AppearanceSettings.codec.encode(appearance))), appearance);
      const regional = RegionalSettings(currency: 'TND', homeZoneAuto: true);
      expect(RegionalSettings.codec.decode(_stored(RegionalSettings.codec.encode(regional))), regional);
      const habits = HabitsDefaults(dayStartMinutes: 240, defaultSkipPolicy: SkipPolicy.breaks, defaultFreezesPerMonth: 2);
      expect(HabitsDefaults.codec.decode(_stored(HabitsDefaults.codec.encode(habits))), habits);
      const lists = ChecklistsDefaults(
        requireReasonFor: {'blocked', 'ongoing'},
        autoCompleteParents: false,
        progressMode: ProgressModePreference.children,
        showCompleted: false,
        sortCompletedToBottom: true,
      );
      expect(ChecklistsDefaults.codec.decode(_stored(ChecklistsDefaults.codec.encode(lists))), lists);
      const stats = StatsDefaults(defaultPeriod: StatsPeriod.quarter, compareWithPrevious: false, weekStartOverride: 7);
      expect(StatsDefaults.codec.decode(_stored(StatsDefaults.codec.encode(stats))), stats);
      const privacy = PrivacySettings(
        crashReporting: false,
        appLockEnabled: true,
        appLockTimeoutSeconds: 60,
        appSwitcherPrivacy: true,
        hideNotificationContent: true,
      );
      expect(PrivacySettings.codec.decode(_stored(PrivacySettings.codec.encode(privacy))), privacy);
    });

    test('the stored JSON carries the version and the contract key names', () {
      final json = PrivacySettings.codec.encode(const PrivacySettings(hideNotificationContent: true));
      expect(json['v'], 1);
      expect(json['hideNotificationContent'], isTrue, reason: 'read by the notification planner');
      final habits = HabitsDefaults.codec.encode(const HabitsDefaults(dayStartMinutes: 240));
      expect(habits['dayStartMinutes'], 240, reason: 'read by userPreferencesProvider');
    });
  });

  group('upgrade from the v0 fixture', () {
    test('appearance booleans become enums; unknown keys are kept', () {
      final raw = _fixture('appearance');
      final s = AppearanceSettings.codec.decode(raw);
      expect(s.theme, ThemePreference.dark);
      expect(s.density, DensityPreference.compact);
      expect(s.reduceMotion, isTrue, reason: 'bool, as design_system/motion.dart reads it');
      expect(s.haptics, isFalse);
      final stored = AppearanceSettings.codec.encode(s, raw);
      expect(stored['futureKey'], {'x': 1});
      expect(stored['v'], 1);
    });

    test('privacy: arch spellings are renamed (hideContentInNotifications, appLock{})', () {
      final s = PrivacySettings.codec.decode(_fixture('privacy'));
      expect(s.hideNotificationContent, isTrue);
      expect(s.appLockEnabled, isTrue);
      expect(s.appLockTimeoutSeconds, 300);
      expect(s.crashReporting, isFalse);
    });

    test('habits: "dayStartsAt": "04:30" becomes dayStartMinutes = 270', () {
      final raw = _fixture('habits');
      expect(HabitsDefaults.codec.decode(raw).dayStartMinutes, 270);
      expect(HabitsDefaults.codec.encode(HabitsDefaults.codec.decode(raw), raw)['matrixTapCycle'], ['done', 'skip']);
    });

    test('other namespaces read v0 as-is', () {
      expect(RegionalSettings.codec.decode(_fixture('regional')).currency, 'TND');
      final lists = ChecklistsDefaults.codec.decode(_fixture('checklists'));
      expect(lists.requireReasonFor, {'blocked'});
      expect(lists.progressMode, ProgressModePreference.children);
      final stats = StatsDefaults.codec.decode(_fixture('stats'));
      expect(stats.defaultPeriod, StatsPeriod.month);
      expect(stats.weekStartOverride, 6);
    });
  });

  group('corrupted / foreign data', () {
    test('wrong types and unknown enum values fall back to defaults with warnings', () {
      final warnings = <String>[];
      final s = AppearanceSettings.codec.decode(
        {'v': 1, 'theme': 'neon', 'density': 3, 'haptics': 'yes', 'arabicDigits': true},
        onWarning: warnings.add,
      );
      expect(s.theme, ThemePreference.system);
      expect(s.density, DensityPreference.comfortable);
      expect(s.haptics, isTrue);
      expect(s.arabicDigits, isTrue);
      expect(warnings, hasLength(3));
      expect(warnings.first, contains('appearance.theme'));
    });

    test('out-of-range numbers are clamped or dropped', () {
      expect(HabitsDefaults.codec.decode({'v': 1, 'dayStartMinutes': 5000}).dayStartMinutes, 1439);
      expect(HabitsDefaults.codec.decode({'v': 1, 'defaultFreezesPerMonth': -3}).defaultFreezesPerMonth, 0);
      expect(StatsDefaults.codec.decode({'v': 1, 'weekStartOverride': 9}).weekStartOverride, isNull);
      expect(RegionalSettings.codec.decode({'v': 1, 'currency': 'euro'}).currency, 'EUR');
    });

    test('a newer version is read best-effort and never downgraded on write', () {
      final warnings = <String>[];
      final raw = {'v': 3, 'theme': 'dark', 'newThing': true};
      final s = AppearanceSettings.codec.decode(raw, onWarning: warnings.add);
      expect(s.theme, ThemePreference.dark);
      expect(warnings.single, contains('newer'));
      final stored = AppearanceSettings.codec.encode(s.copyWith(haptics: false), raw);
      expect(stored['v'], 3);
      expect(stored['newThing'], isTrue);
    });
  });

  test('diff yields only the changed keys', () {
    final before = {'v': 1, 'theme': 'light', 'haptics': true, 'x': [1, 2]};
    final after = {'v': 1, 'theme': 'dark', 'haptics': true, 'x': [1, 2]};
    expect(SettingsCodec.diff(before, after), {'theme': 'dark'});
    expect(SettingsCodec.diff(before, before), isEmpty);
  });
}
