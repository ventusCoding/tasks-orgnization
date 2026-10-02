import 'dart:io';

import 'package:flutter/services.dart';

/// Android `FLAG_SECURE`: blank app-switcher snapshot and no screenshots (T8.3.09). iOS covers
/// the content with an overlay while inactive instead.
class PrivacyWindow {
  static const _channel = MethodChannel('app.everslot/privacy');

  Future<void> setSecure({required bool secure}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on Object {
      // Older builds without the channel.
    }
  }
}
