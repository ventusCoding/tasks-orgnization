/// Persistence of the per-scope card customization (T6.1.22): `user_settings.stats.layouts`, a synced
/// namespace, so a customized layout shows up on the user's other devices after sync.
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key of a scope in `stats.layouts` (its enum name, also the remembered-period key).
String layoutKeyOf(MetricScope scope) => scope.name;

final statsLayoutStoreProvider = Provider<StatsLayoutStore>(
  (ref) => StatsLayoutStore(ref.watch(settingsRepositoryProvider)),
);

/// The customization of [scope], live (defaults until the settings row exists).
final statsLayoutPrefsProvider = Provider.family<LayoutPrefs, MetricScope>(
  (ref, scope) => LayoutPrefs.fromJson(ref.watch(statsSettingsProvider).layouts[layoutKeyOf(scope)]),
);

class StatsLayoutStore {
  StatsLayoutStore(this._settings);

  final SettingsRepository _settings;

  /// Stored customization of [scope] (defaults when none).
  Future<LayoutPrefs> read(MetricScope scope) async {
    final stats = await _settings.read(SettingsNs.stats);
    final entry = (stats['layouts'] is Map ? stats['layouts'] as Map : const <String, Object?>{})[layoutKeyOf(scope)];
    return entry is Map ? LayoutPrefs.fromJson(Map<String, Object?>.from(entry)) : LayoutPrefs.none;
  }

  /// Saves [prefs] for [scope]; a default customization removes the entry (and the whole `layouts`
  /// key when it was the last one), leaving other scopes untouched.
  Future<void> save(MetricScope scope, LayoutPrefs prefs) async {
    final stats = await _settings.read(SettingsNs.stats);
    final layouts = <String, Object?>{
      if (stats['layouts'] is Map)
        for (final e in (stats['layouts'] as Map).entries) '${e.key}': e.value,
    };
    if (prefs.isDefault) {
      layouts.remove(layoutKeyOf(scope));
    } else {
      layouts[layoutKeyOf(scope)] = prefs.toJson();
    }
    await _settings.update(SettingsNs.stats, {'layouts': layouts.isEmpty ? null : layouts});
  }

  /// "Reset to default": drops the customization of [scope].
  Future<void> reset(MetricScope scope) => save(scope, LayoutPrefs.none);
}
