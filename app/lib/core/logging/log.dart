import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// "No PII in logs" helpers (T1.3.05): log ids, never content.
abstract final class LogSafe {
  /// Shortened id for log lines: `0199a000-0000-…` → `0199a000…`.
  static String id(String? id, {int keep = 8}) {
    if (id == null || id.isEmpty) return '-';
    return id.length <= keep ? id : '${id.substring(0, keep)}…';
  }

  static final _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );
  static final _jwt = RegExp(
    r'eyJ[A-Za-z0-9_\-]{5,}\.[A-Za-z0-9_\-]{5,}\.[A-Za-z0-9_\-]*',
  );
  static final _bearer = RegExp(
    r'bearer\s+[A-Za-z0-9._~+/\-]+=*',
    caseSensitive: false,
  );
  static final _apiKey = RegExp(r'sb_(?:publishable|secret)_[A-Za-z0-9_\-]+');
  static final _secretParam = RegExp(
    r'(access_token|refresh_token|id_token|token|apikey|api_key|otp|password|secret|nonce)=([^&\s"]+)',
    caseSensitive: false,
  );

  /// `code` and `key` are only secrets inside a URL query (`?code=…`), not in prose (`code=23505`).
  static final _urlSecretParam = RegExp(
    r'([?&](?:code|key|state))=([^&\s"]+)',
    caseSensitive: false,
  );
  static final _longToken = RegExp(r'\b[A-Za-z0-9_\-]{40,}\b');

  /// Removes e-mail addresses, JWTs, bearer tokens, API keys, secret query parameters and long
  /// token-like strings from [text]. Applied to every message that reaches the log buffer, the console
  /// and the crash-reporting sink, so a careless `log.info('signed in $email')` cannot leak.
  static String scrub(String text) => text
      .replaceAll(_jwt, '<jwt>')
      .replaceAll(_bearer, 'Bearer <token>')
      .replaceAll(_apiKey, '<key>')
      .replaceAllMapped(_secretParam, (m) => '${m[1]}=<redacted>')
      .replaceAllMapped(_urlSecretParam, (m) => '${m[1]}=<redacted>')
      .replaceAll(_email, '<email>')
      .replaceAll(_longToken, '<token>');
}

/// App logging (T1.3.05): console in debug, ring buffer for the debug menu, optional sink
/// (Crashlytics breadcrumbs) in release. Never log user content — ids only ([LogSafe]); messages
/// are scrubbed of e-mail addresses and tokens on the way in.
abstract final class AppLog {
  static final ListQueue<LogRecord> _buffer = ListQueue<LogRecord>();
  static const bufferSize = 500;
  static void Function(LogRecord record)? externalSink;
  static StreamSubscription<LogRecord>? _subscription;

  /// Starts listening to the root logger. Safe to call again (bootstrap retry, tests): the previous
  /// listener is replaced, never duplicated.
  static void init({Level level = Level.INFO}) {
    unawaited(_subscription?.cancel());
    Logger.root.level = kDebugMode ? Level.ALL : level;
    _subscription = Logger.root.onRecord.listen(_onRecord);
  }

  static void _onRecord(LogRecord raw) {
    final record = _scrubbed(raw);
    _buffer.addLast(record);
    while (_buffer.length > bufferSize) {
      _buffer.removeFirst();
    }
    if (kDebugMode) {
      debugPrint(
        '[${record.level.name}] ${record.loggerName}: ${record.message}'
        '${record.error != null ? ' — ${record.error}' : ''}',
      );
    }
    externalSink?.call(record);
  }

  static LogRecord _scrubbed(LogRecord r) => LogRecord(
    r.level,
    LogSafe.scrub(r.message),
    r.loggerName,
    // The error object is kept as text: its `toString()` may contain user content.
    r.error == null ? null : LogSafe.scrub(r.error.toString()),
    r.stackTrace,
  );

  /// Most recent records, oldest first (up to [bufferSize]).
  static List<LogRecord> get recent => List.unmodifiable(_buffer);

  /// Empties the buffer (debug menu, tests).
  static void clear() => _buffer.clear();

  static Logger get(String name) => Logger(name);
}
