import 'package:flutter/services.dart';

/// Android window controls for the alarm profile (T7.2.24), via `MainActivity`'s
/// `app.everslot/alarm` channel. Everything degrades to "not available" off Android.
abstract final class AlarmWindow {
  static const _channel = MethodChannel('app.everslot/alarm');

  /// Android 14+: the user allows full-screen notifications (always true below 14).
  static Future<bool> canUseFullScreenIntent() async {
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent') ?? false;
    } on Object {
      return false;
    }
  }

  /// Shows the app above the lock screen and turns the screen on while an alarm rings; turned
  /// off again when the alarm screen closes (the app is never shown over the lock screen otherwise).
  static Future<void> showOnLockScreen(bool on) async {
    try {
      await _channel.invokeMethod<void>('showOnLockScreen', on);
    } on Object {
      // not Android / not available
    }
  }
}
