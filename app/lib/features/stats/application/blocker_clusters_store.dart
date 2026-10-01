/// User blocker clusters (T6.4.14): normalized blocked reasons merged and renamed by the user, stored
/// in `user_settings.stats.blockerClusters` (normalized reason → cluster name; synced settings row).
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blockerClustersStoreProvider = Provider<BlockerClustersStore>(
  (ref) => BlockerClustersStore(ref.watch(settingsRepositoryProvider)),
);

class BlockerClustersStore {
  BlockerClustersStore(this._settings);

  final SettingsRepository _settings;

  Future<Map<String, String>> read() async {
    final stats = await _settings.read(SettingsNs.stats);
    final raw = stats['blockerClusters'];
    return {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.value is String) '${e.key}': e.value as String,
    };
  }

  /// Puts every reason of [keys] in the cluster [name] (a blank name removes them from clusters).
  Future<void> assign(Iterable<String> keys, String name) async {
    final current = await read();
    final trimmed = name.trim();
    for (final k in keys) {
      if (trimmed.isEmpty) {
        current.remove(k);
      } else {
        current[k] = trimmed;
      }
    }
    await _settings.update(SettingsNs.stats, {'blockerClusters': current.isEmpty ? null : current});
  }
}
