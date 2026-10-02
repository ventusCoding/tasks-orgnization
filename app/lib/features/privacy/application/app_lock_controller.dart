import 'dart:async';

import 'package:everslot/core/database/database_encryption.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart' show SettingsNs;
import 'package:everslot/features/privacy/data/authenticator.dart';
import 'package:everslot/features/privacy/data/privacy_window.dart';
import 'package:everslot/features/privacy/domain/app_lock.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticatorProvider = Provider<Authenticator>((ref) => LocalAuthAuthenticator());

final privacyWindowProvider = Provider<PrivacyWindow>((ref) => PrivacyWindow());

/// Local database encryption (T8.3.15).
final databaseEncryptionProvider = Provider<DatabaseEncryption>((ref) => DatabaseEncryption());

/// (wanted, encrypted now): the switch shows the wish, the subtitle whether a restart is pending.
final databaseEncryptionStateProvider = FutureProvider.autoDispose<({bool wanted, bool encrypted})>((ref) async {
  final e = ref.watch(databaseEncryptionProvider);
  return (wanted: await e.wanted(), encrypted: await e.isEncrypted());
});

/// Whether the privacy settings namespace has loaded (until then the lock state is unknown).
final _privacyLoadedProvider = Provider<bool>((ref) => ref.watch(settingsProvider(SettingsNs.privacy)).hasValue);

/// App lock (T8.3.09): locks on cold start and after the configured time in the background;
/// covers the content in the app switcher. Survives app kill (a cold start always locks).
final appLockProvider = NotifierProvider<AppLockController, AppLockState>(AppLockController.new);

class AppLockController extends Notifier<AppLockState> {
  /// The system prompt (e.g. Android's device-credential screen) can background the app; its
  /// return must not lock again right after a successful unlock.
  var _ignoreNextReturn = false;

  PrivacySettings get _settings => ref.read(privacySettingsProvider);

  @override
  AppLockState build() {
    final lifecycle = ref.read(lifecycleProvider);
    final states = lifecycle.states.listen(_onState);
    final returns = lifecycle.onReturn.listen(_onReturn);
    ref.onDispose(() {
      unawaited(states.cancel());
      unawaited(returns.cancel());
    });
    ref
      ..listen<bool>(_privacyLoadedProvider, (_, loaded) {
        if (loaded && !state.ready) _becomeReady();
      })
      ..listen<PrivacySettings>(privacySettingsProvider, (previous, next) {
        if (!next.appLockEnabled && state.locked) state = state.copyWith(locked: false);
        if (previous?.appSwitcherPrivacy != next.appSwitcherPrivacy ||
            previous?.appLockEnabled != next.appLockEnabled) {
          unawaited(_applyWindow(next));
        }
      });
    if (ref.read(_privacyLoadedProvider)) {
      final s = _settings;
      unawaited(_applyWindow(s));
      return AppLockState(ready: true, locked: s.appLockEnabled);
    }
    return const AppLockState();
  }

  void _becomeReady() {
    final s = _settings;
    state = state.copyWith(ready: true, locked: s.appLockEnabled);
    unawaited(_applyWindow(s));
  }

  Future<void> _applyWindow(PrivacySettings s) =>
      ref.read(privacyWindowProvider).setSecure(secure: s.appSwitcherPrivacy || s.appLockEnabled);

  void _onState(AppLifecycleState s) {
    final hide = _settings.appSwitcherPrivacy || _settings.appLockEnabled;
    switch (s) {
      case AppLifecycleState.inactive || AppLifecycleState.hidden || AppLifecycleState.paused:
        if (hide && !state.authenticating && !state.obscured) state = state.copyWith(obscured: true);
      case AppLifecycleState.resumed:
        if (state.obscured) state = state.copyWith(obscured: false);
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onReturn(Duration away) {
    if (_ignoreNextReturn) {
      _ignoreNextReturn = false;
      return;
    }
    if (state.authenticating || state.locked) return;
    final s = _settings;
    if (AppLockPolicy.lockOnReturn(enabled: s.appLockEnabled, timeoutSeconds: s.appLockTimeoutSeconds, away: away)) {
      state = state.copyWith(locked: true);
    }
  }

  /// Shows the system prompt; unlocks on success. Failure or cancel keeps the content hidden.
  Future<bool> unlock(AppLocalizations l10n) async {
    if (state.authenticating) return false;
    state = state.copyWith(authenticating: true);
    final ok = await ref.read(authenticatorProvider).authenticate(l10n.appLockReason);
    _ignoreNextReturn = ok && !ref.read(lifecycleProvider).isForeground;
    state = state.copyWith(authenticating: false, locked: !ok && state.locked, obscured: false);
    return ok;
  }
}
