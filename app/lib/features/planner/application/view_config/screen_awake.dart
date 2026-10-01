import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a focus view or the routine player is open (`options.keepScreenOn`,
/// T3.7.01 / T3.7.07). Behind an interface so widget tests run without the platform plugin.
abstract interface class ScreenAwake {
  Future<void> keepOn({required bool on});
}

/// `wakelock_plus` (iOS idle timer / Android FLAG_KEEP_SCREEN_ON); best effort.
class PluginScreenAwake implements ScreenAwake {
  const PluginScreenAwake();

  @override
  Future<void> keepOn({required bool on}) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } on Object {
      // Unsupported platform or plugin missing: the screen just follows the system timeout.
    }
  }
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => const PluginScreenAwake());
