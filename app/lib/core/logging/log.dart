import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// App logging (T1.3.05): console in debug, ring buffer for the debug menu, optional sink
/// (Crashlytics breadcrumbs) in release. Never log user content — ids only.
abstract final class AppLog {
  static final ListQueue<LogRecord> _buffer = ListQueue<LogRecord>();
  static const _bufferSize = 500;
  static void Function(LogRecord record)? externalSink;

  static void init({Level level = Level.INFO}) {
    Logger.root.level = kDebugMode ? Level.ALL : level;
    Logger.root.onRecord.listen((record) {
      _buffer.addLast(record);
      while (_buffer.length > _bufferSize) {
        _buffer.removeFirst();
      }
      if (kDebugMode) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName}: ${record.message}'
          '${record.error != null ? ' — ${record.error}' : ''}',
        );
      }
      externalSink?.call(record);
    });
  }

  static List<LogRecord> get recent => List.unmodifiable(_buffer);

  static Logger get(String name) => Logger(name);
}
