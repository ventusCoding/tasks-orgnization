import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// How the Today list groups habits (T5.2.12).
enum HabitGroupBy {
  section,
  category,
  none;

  static HabitGroupBy parse(Object? value) => values.firstWhere((g) => g.name == value, orElse: () => section);
}

/// Habits-tab view settings (`user_settings.habits`, arch §8.5): the week-matrix tap cycle and
/// toggle gesture (T5.2.06) and the Today list's grouping, density, streak chips and not-due
/// visibility (T5.2.12). Synced across devices; unknown keys are preserved.
@immutable
class HabitViewSettings {
  const HabitViewSettings({
    this.tapCycle = TapCycle.doneNotDoneClear,
    this.toggleWithShortPress = true,
    this.showStreakChips = true,
    this.compact = false,
    this.hideNotDue = false,
    this.groupBy = HabitGroupBy.section,
    this.holdToComplete = false,
  });

  factory HabitViewSettings.fromMap(Map<String, dynamic> m) => HabitViewSettings(
    tapCycle: TapCycle.parse(m['matrixTapCycle']),
    toggleWithShortPress: m.get<bool>('toggleWithShortPress', true),
    showStreakChips: m.get<bool>('showStreakChips', true),
    compact: m['density'] == 'compact',
    hideNotDue: m.get<bool>('hideNotDue', false),
    groupBy: HabitGroupBy.parse(m['groupBy']),
    holdToComplete: m.get<bool>('holdToComplete', false),
  );

  final TapCycle tapCycle;
  final bool toggleWithShortPress;
  final bool showStreakChips;

  /// Compact vs comfortable rows (`density`).
  final bool compact;
  final bool hideNotDue;
  final HabitGroupBy groupBy;

  /// Yes/no rings need a press-and-hold (with a fill animation) instead of a tap (T5.2.03, T5.2.13).
  final bool holdToComplete;

  @override
  bool operator ==(Object other) =>
      other is HabitViewSettings &&
      other.tapCycle == tapCycle &&
      other.toggleWithShortPress == toggleWithShortPress &&
      other.showStreakChips == showStreakChips &&
      other.compact == compact &&
      other.hideNotDue == hideNotDue &&
      other.groupBy == groupBy &&
      other.holdToComplete == holdToComplete;

  @override
  int get hashCode =>
      Object.hash(tapCycle, toggleWithShortPress, showStreakChips, compact, hideNotDue, groupBy, holdToComplete);
}

final habitViewSettingsProvider = Provider<HabitViewSettings>(
  (ref) => HabitViewSettings.fromMap(ref.watch(settingsProvider(SettingsNs.habits)).value ?? const {}),
);

/// Writes the view settings (one synced `user_settings` row; other keys are kept).
class HabitViewSettingsService {
  HabitViewSettingsService(this._settings);

  final SettingsRepository _settings;

  Future<void> update({
    TapCycle? tapCycle,
    bool? toggleWithShortPress,
    bool? showStreakChips,
    bool? compact,
    bool? hideNotDue,
    HabitGroupBy? groupBy,
    bool? holdToComplete,
  }) => _settings.update(SettingsNs.habits, {
    'matrixTapCycle': ?tapCycle?.json,
    'toggleWithShortPress': ?toggleWithShortPress,
    'showStreakChips': ?showStreakChips,
    if (compact != null) 'density': compact ? 'compact' : 'comfortable',
    'hideNotDue': ?hideNotDue,
    'groupBy': ?groupBy?.name,
    'holdToComplete': ?holdToComplete,
  });
}

final habitViewSettingsServiceProvider = Provider<HabitViewSettingsService>(
  (ref) => HabitViewSettingsService(ref.watch(settingsRepositoryProvider)),
);
