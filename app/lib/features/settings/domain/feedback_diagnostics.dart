import 'package:meta/meta.dart';

/// What "Send feedback" may attach (T8.3.17): technical facts only — no content, no account or
/// device names, no ids beyond the device id. Shown to the user verbatim before sending.
@immutable
class FeedbackDiagnostics {
  const FeedbackDiagnostics({
    required this.appVersion,
    required this.platform,
    required this.deviceId,
    this.osVersion,
    this.model,
    this.locale,
    this.flavor,
    this.cloudSync = false,
    this.syncPhase,
    this.pendingChanges = 0,
    this.failedChanges = 0,
    this.lastSyncAt,
    this.syncErrorCode,
    this.errorCodes = const [],
  });

  final String appVersion;
  final String platform;
  final String deviceId;
  final String? osVersion;
  final String? model;
  final String? locale;
  final String? flavor;
  final bool cloudSync;
  final String? syncPhase;
  final int pendingChanges;
  final int failedChanges;
  final DateTime? lastSyncAt;
  final String? syncErrorCode;

  /// Recent error codes (`logger/ExceptionType`), newest last, without messages.
  final List<String> errorCodes;

  static final _typeName = RegExp('^([A-Z][A-Za-z0-9_]{0,60}(?:Exception|Error|Failure))(?![A-Za-z0-9_])');
  static final _loggerName = RegExp(r'^[a-z0-9_.]{1,60}$');

  /// `logger/Type` for an error logged by [logger]: the exception type taken from the start of its
  /// text (`FormatException: …` → `FormatException`); anything else is dropped.
  static String? errorCode(String logger, Object? error) {
    if (!_loggerName.hasMatch(logger)) return null;
    final text = error?.toString() ?? '';
    // Dart errors print a phrase, not their type.
    for (final (prefix, type) in const [
      ('Bad state', 'StateError'),
      ('Invalid argument', 'ArgumentError'),
      ('Null check operator', 'TypeError'),
      ('Concurrent modification', 'ConcurrentModificationError'),
      ('Unsupported operation', 'UnsupportedError'),
    ]) {
      if (text.startsWith(prefix)) return '$logger/$type';
    }
    // Only a type name (`FormatException`, `PostgrestException`…) — never the first word of a message.
    final type = _typeName.firstMatch(text)?.group(1);
    return type == null ? logger : '$logger/$type';
  }

  /// A short, safe token (sync error codes, versions): letters, digits and `._-+` only.
  static String? token(String? value) {
    if (value == null) return null;
    final v = value.trim();
    return RegExp(r'^[A-Za-z0-9._+\- ]{1,64}$').hasMatch(v) ? v : null;
  }

  String toText() => [
    'App: $appVersion${flavor == null ? '' : ' ($flavor)'}',
    'Platform: $platform${osVersion == null ? '' : ' $osVersion'}',
    if (model != null) 'Device model: $model',
    if (locale != null) 'Locale: $locale',
    'Device id: $deviceId',
    if (cloudSync)
      'Sync: ${syncPhase ?? 'unknown'}, pending $pendingChanges, failed $failedChanges'
    else
      'Sync: local only',
    if (lastSyncAt != null) 'Last sync: ${lastSyncAt!.toUtc().toIso8601String()}',
    if (syncErrorCode != null) 'Sync error: $syncErrorCode',
    if (errorCodes.isNotEmpty) 'Recent errors: ${errorCodes.join(', ')}',
  ].join('\n');
}
