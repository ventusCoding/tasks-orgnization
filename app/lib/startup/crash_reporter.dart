import 'dart:async';

import 'package:everslot/core/errors/global_error_handlers.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Crashlytics sink of the global error handlers (T1.3.05, T1.2.15). Only registered in release
/// builds with Firebase configured. Reporting is opt-out (Settings › Privacy › crash reports,
/// arch §6.15): [enabled] follows `privacy.crashReporting`.
///
/// Error texts are scrubbed (e-mail addresses, tokens) before they leave the device; only the
/// exception type, the scrubbed text and the stack trace are sent.
class CrashlyticsErrorReporter implements ErrorReporter {
  CrashlyticsErrorReporter._();

  static final instance = CrashlyticsErrorReporter._();

  bool _enabled = true;

  bool get enabled => _enabled;

  /// Turns Crashlytics collection on/off at run time (the setting, applied at startup and on change).
  set enabled(bool value) {
    _enabled = value;
    unawaited(_apply(value));
  }

  static Future<void> _apply(bool value) async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
    } on Object {
      // Firebase not initialised (local-only builds, tests): nothing to toggle.
    }
  }

  @override
  void report(
    Object error,
    StackTrace stack, {
    required bool fatal,
    String? reason,
  }) {
    if (!_enabled) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        '${error.runtimeType}: ${LogSafe.scrub(error.toString())}',
        stack,
        fatal: fatal,
        reason: reason,
      ),
    );
  }

  /// Log breadcrumbs (scrubbed by [AppLog]) for INFO and above.
  static void breadcrumb(String line) {
    try {
      unawaited(FirebaseCrashlytics.instance.log(line));
    } on Object {
      // ignore
    }
  }
}
