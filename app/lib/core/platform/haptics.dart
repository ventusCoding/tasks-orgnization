import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feedback moments of the app (T1.3.17). Features name the moment; [Haptics] picks the pattern.
enum HapticEvent {
  /// A value snapped or was picked (slot snap, picker step, chip toggle).
  selection,

  /// An item was lifted to be dragged.
  lift,

  /// A small confirmation (drop, reorder, minor change).
  light,

  /// Something was completed (task done, check-in, checklist item completed).
  success,

  /// Attention needed (limit reached, undo available for a destructive action).
  warning,

  /// The action was refused (can't indent here, locked item).
  denied,
}

/// Short UI sounds (off by default, `appearance.sounds`).
enum UiSound { click }

/// Platform output of [Haptics]; replaced in tests (or by a fake platform channel).
abstract interface class HapticsOutput {
  Future<void> haptic(HapticEvent event);

  Future<void> sound(UiSound sound);
}

/// Flutter's `HapticFeedback` / `SystemSound` (the OS applies its own "touch feedback" / system
/// haptics setting on top of ours).
class SystemHapticsOutput implements HapticsOutput {
  const SystemHapticsOutput();

  @override
  Future<void> haptic(HapticEvent event) => switch (event) {
    HapticEvent.selection => HapticFeedback.selectionClick(),
    HapticEvent.lift => HapticFeedback.mediumImpact(),
    HapticEvent.light => HapticFeedback.lightImpact(),
    HapticEvent.success => HapticFeedback.successNotification(),
    HapticEvent.warning => HapticFeedback.warningNotification(),
    HapticEvent.denied => HapticFeedback.errorNotification(),
  };

  @override
  Future<void> sound(UiSound sound) => switch (sound) {
    UiSound.click => SystemSound.play(SystemSoundType.click),
  };
}

/// Central haptics & sound service (T1.3.17): respects the user's `appearance.haptics` (default on)
/// and `appearance.sounds` (default off) settings, read at the moment of the event. Platform
/// failures (no vibrator, missing plugin) are ignored — feedback is never essential.
class Haptics {
  Haptics({required HapticsOutput output, required bool Function() hapticsEnabled, required bool Function() soundsEnabled})
    : _output = output,
      _hapticsEnabled = hapticsEnabled,
      _soundsEnabled = soundsEnabled;

  final HapticsOutput _output;
  final bool Function() _hapticsEnabled;
  final bool Function() _soundsEnabled;

  static final _log = AppLog.get('haptics');

  bool get hapticsEnabled => _hapticsEnabled();

  bool get soundsEnabled => _soundsEnabled();

  /// Plays the haptic of [event] when haptics are on; [sound] also plays a UI sound when sounds are on.
  Future<void> play(HapticEvent event, {UiSound? sound}) async {
    if (_hapticsEnabled()) await _guard(() => _output.haptic(event));
    if (sound != null && _soundsEnabled()) await _guard(() => _output.sound(sound));
  }

  Future<void> selection() => play(HapticEvent.selection);

  Future<void> lift() => play(HapticEvent.lift);

  Future<void> light() => play(HapticEvent.light);

  /// Completion feedback, with the (opt-in) completion sound.
  Future<void> success() => play(HapticEvent.success, sound: UiSound.click);

  Future<void> warning() => play(HapticEvent.warning);

  Future<void> denied() => play(HapticEvent.denied);

  static Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (e) {
      _log.fine('feedback unavailable: $e');
    }
  }
}

/// `appearance.haptics` (default on) — for features that drive their own haptics.
final hapticsEnabledProvider = Provider<bool>(
  (ref) => (ref.watch(settingsProvider(SettingsNs.appearance)).value ?? const {})['haptics'] != false,
);

/// `appearance.sounds` (default off).
final uiSoundsEnabledProvider = Provider<bool>(
  (ref) => (ref.watch(settingsProvider(SettingsNs.appearance)).value ?? const {})['sounds'] == true,
);

final hapticsOutputProvider = Provider<HapticsOutput>((ref) => const SystemHapticsOutput());

/// The app's [Haptics] (stable instance; preferences are read at each event).
final hapticsProvider = Provider<Haptics>((ref) {
  // Keep the settings row subscribed so the first event already sees the stored preference.
  ref
    ..listen(hapticsEnabledProvider, (_, _) {})
    ..listen(uiSoundsEnabledProvider, (_, _) {});
  return Haptics(
    output: ref.watch(hapticsOutputProvider),
    hapticsEnabled: () => ref.read(hapticsEnabledProvider),
    soundsEnabled: () => ref.read(uiSoundsEnabledProvider),
  );
});
