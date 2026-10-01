import 'package:everslot/core/errors/error_mapper.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Where uncaught errors go in release builds (Crashlytics; `startup/crash_reporter.dart`).
abstract interface class ErrorReporter {
  void report(Object error, StackTrace stack, {required bool fatal, String? reason});
}

/// Global error routing (T1.3.05): `FlutterError.onError` (framework errors), `PlatformDispatcher.onError`
/// (uncaught async errors) and the bootstrap zone all end up in [record], which
///
///  * logs the error once (even when two hooks see the same object),
///  * reports it to [reporter] in release builds only, and
///  * swallows it — an uncaught error never takes the UI down.
class GlobalErrorHandlers {
  GlobalErrorHandlers({this.reporter, Logger? log, bool? releaseMode})
    : log = log ?? AppLog.get('errors'),
      releaseMode = releaseMode ?? kReleaseMode;

  /// Crash-reporting sink; set once Firebase is ready (release builds).
  ErrorReporter? reporter;
  final Logger log;

  /// Only release builds report (debug/profile print to the console and the log buffer).
  final bool releaseMode;

  Object? _lastError;

  /// Number of distinct errors handled since [install] (diagnostics, tests).
  int handledCount = 0;

  /// Points the framework and platform hooks here.
  void install() {
    FlutterError.onError = handleFlutterError;
    PlatformDispatcher.instance.onError = handlePlatformError;
  }

  void handleFlutterError(FlutterErrorDetails details) {
    // The console dump (red text with the widget chain) helps while developing.
    if (!releaseMode) FlutterError.presentError(details);
    record(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: false,
      reason: details.library == null ? 'flutter framework' : 'flutter: ${details.library}',
    );
  }

  /// `PlatformDispatcher.onError`: returning `true` marks the error as handled.
  bool handlePlatformError(Object error, StackTrace stack) {
    record(error, stack, fatal: true, reason: 'uncaught async error');
    return true;
  }

  /// `runZonedGuarded` handler of the bootstrap zone.
  void handleZoneError(Object error, StackTrace stack) =>
      record(error, stack, fatal: true, reason: 'uncaught zone error');

  void record(Object error, StackTrace stack, {required bool fatal, String? reason}) {
    if (identical(error, _lastError)) return;
    _lastError = error;
    handledCount++;
    final kind = toAppException(error).kind.name;
    log.severe('${reason ?? 'error'} [$kind] ${error.runtimeType}', error, stack);
    if (!releaseMode) return;
    try {
      reporter?.report(error, stack, fatal: fatal, reason: reason);
    } on Object catch (e) {
      log.warning('error reporter failed: ${e.runtimeType}');
    }
  }
}
