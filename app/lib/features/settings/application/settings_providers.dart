import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/settings/domain/settings_codec.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _log = AppLog.get('settings');

T _typed<T>(Ref ref, SettingsCodec<T> codec, T fallback) {
  final raw = ref.watch(settingsProvider(codec.namespace)).value;
  if (raw == null || raw.isEmpty) return fallback;
  return codec.decode(raw, onWarning: _log.warning);
}

/// Typed, live settings namespaces (T8.3.01). Defaults until the row exists.
final appearanceSettingsProvider = Provider<AppearanceSettings>(
  (ref) => _typed(ref, AppearanceSettings.codec, AppearanceSettings.defaults),
);

final regionalSettingsProvider = Provider<RegionalSettings>(
  (ref) => _typed(ref, RegionalSettings.codec, RegionalSettings.defaults),
);

final habitsDefaultsProvider = Provider<HabitsDefaults>(
  (ref) => _typed(ref, HabitsDefaults.codec, HabitsDefaults.defaults),
);

final checklistsDefaultsProvider = Provider<ChecklistsDefaults>(
  (ref) => _typed(ref, ChecklistsDefaults.codec, ChecklistsDefaults.defaults),
);

final statsDefaultsProvider = Provider<StatsDefaults>(
  (ref) => _typed(ref, StatsDefaults.codec, StatsDefaults.defaults),
);

final privacySettingsProvider = Provider<PrivacySettings>(
  (ref) => _typed(ref, PrivacySettings.codec, PrivacySettings.defaults),
);

final settingsWriterProvider = Provider<SettingsWriter>((ref) {
  final writer = SettingsWriter(ref.watch(settingsRepositoryProvider));
  ref.onDispose(() => unawaited(writer.flush()));
  return writer;
});

/// Settings writes (T8.3.01): typed updates write only the keys that changed (unknown keys are
/// kept by the repository); rapid edits of one namespace (sliders, steppers) are debounced into a
/// single outbox patch.
class SettingsWriter {
  SettingsWriter(this._repo, {this.debounce = const Duration(milliseconds: 400)});

  final SettingsRepository _repo;
  final Duration debounce;
  final _pending = <String, Map<String, Object?>>{};
  final _timers = <String, Timer>{};
  final _waiters = <String, Completer<void>>{};

  /// Applies [change] to the current typed value of [codec]'s namespace and writes the diff.
  Future<void> update<T>(SettingsCodec<T> codec, T Function(T current) change) async {
    await _flushNamespace(codec.namespace);
    final raw = await _repo.read(codec.namespace);
    final before = codec.decode(raw, onWarning: _log.warning);
    final after = change(before);
    // `encode` keeps every existing key, so the diff only holds changed/added keys.
    final patch = SettingsCodec.diff(Map<String, Object?>.from(raw), codec.encode(after, raw));
    if (patch.isEmpty) return;
    await _repo.update(codec.namespace, patch);
  }

  /// Merges [patch] into [namespace] after [debounce] (per-field edits); completes when written.
  Future<void> patch(String namespace, Map<String, Object?> patch) {
    _pending.putIfAbsent(namespace, () => {}).addAll(patch);
    _timers[namespace]?.cancel();
    _timers[namespace] = Timer(debounce, () => unawaited(_flushNamespace(namespace)));
    return (_waiters[namespace] ??= Completer<void>()).future;
  }

  Future<void> _flushNamespace(String namespace) async {
    _timers.remove(namespace)?.cancel();
    final patch = _pending.remove(namespace);
    final waiter = _waiters.remove(namespace);
    if (patch == null || patch.isEmpty) {
      waiter?.complete();
      return;
    }
    try {
      await _repo.update(namespace, patch);
      waiter?.complete();
    } on Object catch (e, st) {
      _log.warning('settings write failed ($namespace)', e, st);
      waiter?.completeError(e, st);
    }
  }

  /// Writes every pending patch now.
  Future<void> flush() async {
    for (final ns in [..._pending.keys]) {
      await _flushNamespace(ns);
    }
  }
}
