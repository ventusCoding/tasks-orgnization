import 'dart:async';
import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:everslot/core/errors/global_error_handlers.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

class _Reporter implements ErrorReporter {
  final reports = <({Object error, bool fatal, String? reason})>[];
  bool throwOnReport = false;

  @override
  void report(
    Object error,
    StackTrace stack, {
    required bool fatal,
    String? reason,
  }) {
    if (throwOnReport) throw StateError('reporter down');
    reports.add((error: error, fatal: fatal, reason: reason));
  }
}

/// T1.3.05: logging (ring buffer, scrubbing) and the global error handlers.
void main() {
  late FlutterExceptionHandler? oldFlutterHandler;
  late ErrorCallback? oldPlatformHandler;

  setUp(() {
    oldFlutterHandler = FlutterError.onError;
    oldPlatformHandler = PlatformDispatcher.instance.onError;
    AppLog.init();
    AppLog.clear();
    AppLog.externalSink = null;
  });

  tearDown(() {
    FlutterError.onError = oldFlutterHandler;
    PlatformDispatcher.instance.onError = oldPlatformHandler;
    AppLog.externalSink = null;
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('LogSafe (no PII in logs)', () {
    test('ids are shortened', () {
      expect(LogSafe.id('0199a000-0000-7000-8000-000000000001'), '0199a000…');
      expect(LogSafe.id('short'), 'short');
      expect(LogSafe.id(null), '-');
      expect(LogSafe.id(''), '-');
    });

    test('e-mail addresses, JWTs, bearer tokens and API keys are removed', () {
      final scrubbed = LogSafe.scrub(
        'signed in as anwer.baccar2@gmail.com with '
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U '
        'Authorization: Bearer abc.DEF-123_xyz key sb_secret_AbCdEf123456 sb_publishable_ZyX987',
      );
      expect(scrubbed, isNot(contains('gmail')));
      expect(scrubbed, isNot(contains('eyJ')));
      expect(scrubbed, isNot(contains('abc.DEF')));
      expect(scrubbed, isNot(contains('AbCdEf')));
      expect(scrubbed, contains('<email>'));
      expect(scrubbed, contains('<jwt>'));
      expect(scrubbed, contains('Bearer <token>'));
      expect(scrubbed, contains('<key>'));
    });

    test('secret URL parameters and long token-like strings are removed; ordinary text is kept', () {
      expect(
        LogSafe.scrub(
          'everslot://auth-callback?code=pkce123&state=xyz&other=1',
        ),
        'everslot://auth-callback?code=<redacted>&state=<redacted>&other=1',
      );
      expect(
        LogSafe.scrub('refresh_token=abc123&access_token=def456'),
        'refresh_token=<redacted>&access_token=<redacted>',
      );
      expect(LogSafe.scrub('a' * 48), '<token>');
      expect(
        LogSafe.scrub(
          'sync failed code=23505 for row 0199a000-0000-7000-8000-000000000001',
        ),
        'sync failed code=23505 for row 0199a000-0000-7000-8000-000000000001',
      );
    });
  });

  group('AppLog', () {
    test(
      'records go to the ring buffer, scrubbed, error text included',
      () async {
        final log = AppLog.get('t1');
        log.info('user anwer@example.com opened settings');
        log.warning('failed', Exception('SocketException for user@site.org'));
        await flush();
        final recent = AppLog.recent;
        expect(recent, hasLength(2));
        expect(recent[0].message, 'user <email> opened settings');
        expect(recent[1].error.toString(), isNot(contains('user@site.org')));
        expect(recent[1].error.toString(), contains('SocketException'));
        expect(recent.every((r) => r.loggerName == 't1'), isTrue);
      },
    );

    test('the buffer keeps the newest ${AppLog.bufferSize} records', () async {
      final log = AppLog.get('flood');
      for (var i = 0; i < AppLog.bufferSize + 25; i++) {
        log.info('line $i');
      }
      await flush();
      expect(AppLog.recent, hasLength(AppLog.bufferSize));
      expect(AppLog.recent.first.message, 'line 25');
      expect(AppLog.recent.last.message, 'line ${AppLog.bufferSize + 24}');
    });

    test('init twice does not duplicate records', () async {
      AppLog.init();
      AppLog.init();
      AppLog.get('dup').info('once');
      await flush();
      expect(AppLog.recent.where((r) => r.message == 'once'), hasLength(1));
    });

    test(
      'the external sink (crash breadcrumbs) receives scrubbed records',
      () async {
        final seen = <LogRecord>[];
        AppLog.externalSink = seen.add;
        AppLog.get('sink').info('mail me at a@b.co');
        await flush();
        expect(seen.single.message, 'mail me at <email>');
      },
    );
  });

  group('GlobalErrorHandlers', () {
    test(
      'a framework error is logged once and reported (release) as non-fatal',
      () async {
        final reporter = _Reporter();
        final handlers = GlobalErrorHandlers(
          reporter: reporter,
          releaseMode: true,
        );
        final error = StateError('render failed');
        handlers.handleFlutterError(
          FlutterErrorDetails(
            exception: error,
            stack: StackTrace.current,
            library: 'widgets',
          ),
        );
        await flush();
        expect(
          AppLog.recent.where((r) => r.level == Level.SEVERE),
          hasLength(1),
        );
        expect(AppLog.recent.single.message, contains('StateError'));
        expect(reporter.reports.single.fatal, isFalse);
        expect(reporter.reports.single.error, same(error));
      },
    );

    test('an uncaught async error is logged once, reported as fatal and marked handled (no crash)', () async {
      final reporter = _Reporter();
      final handlers = GlobalErrorHandlers(
        reporter: reporter,
        releaseMode: true,
      );
      final handled = handlers.handlePlatformError(
        Exception('async boom'),
        StackTrace.current,
      );
      await flush();
      expect(
        handled,
        isTrue,
        reason: 'returning true stops the engine from crashing the app',
      );
      expect(AppLog.recent.where((r) => r.level == Level.SEVERE), hasLength(1));
      expect(reporter.reports.single.fatal, isTrue);
    });

    test('the same error seen by two hooks is recorded once', () async {
      final reporter = _Reporter();
      final handlers = GlobalErrorHandlers(
        reporter: reporter,
        releaseMode: true,
      );
      final error = ArgumentError('same object');
      final stack = StackTrace.current;
      handlers.handlePlatformError(error, stack);
      handlers.handleZoneError(error, stack);
      handlers.handleFlutterError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      await flush();
      expect(handlers.handledCount, 1);
      expect(reporter.reports, hasLength(1));
      expect(AppLog.recent.where((r) => r.level == Level.SEVERE), hasLength(1));
    });

    test('debug and profile builds log but do not report', () async {
      final reporter = _Reporter();
      final handlers = GlobalErrorHandlers(
        reporter: reporter,
        releaseMode: false,
      );
      handlers.handlePlatformError(Exception('dev only'), StackTrace.current);
      await flush();
      expect(reporter.reports, isEmpty);
      expect(AppLog.recent.where((r) => r.level == Level.SEVERE), hasLength(1));
    });

    test('a failing reporter never propagates', () async {
      final reporter = _Reporter()..throwOnReport = true;
      final handlers = GlobalErrorHandlers(
        reporter: reporter,
        releaseMode: true,
      );
      expect(
        () => handlers.handlePlatformError(Exception('x'), StackTrace.current),
        returnsNormally,
      );
      await flush();
      expect(
        AppLog.recent.any(
          (r) =>
              r.level == Level.WARNING && r.message.contains('reporter failed'),
        ),
        isTrue,
      );
    });

    test('PII in the error text is scrubbed in the log', () async {
      final handlers = GlobalErrorHandlers(releaseMode: false);
      handlers.handlePlatformError(
        Exception('cannot send to secret@example.com'),
        StackTrace.current,
      );
      await flush();
      final record = AppLog.recent.singleWhere((r) => r.level == Level.SEVERE);
      expect(
        '${record.message} ${record.error}',
        isNot(contains('secret@example.com')),
      );
    });

    test('install() points FlutterError.onError and PlatformDispatcher.onError at the handlers', () async {
      final handlers = GlobalErrorHandlers(releaseMode: false)..install();
      expect(FlutterError.onError, isNotNull);
      final handled = PlatformDispatcher.instance.onError!(
        StateError('via dispatcher'),
        StackTrace.current,
      );
      expect(handled, isTrue);
      expect(handlers.handledCount, 1);
    });

    test('an uncaught error inside a guarded zone (the bootstrap zone) is handled once, without crashing', () async {
      final reporter = _Reporter();
      final handlers = GlobalErrorHandlers(
        reporter: reporter,
        releaseMode: true,
      );
      final done = Completer<void>();
      runZonedGuarded(() {
        Future<void>.delayed(
          Duration.zero,
          () => throw StateError('late failure'),
        );
        Future<void>.delayed(const Duration(milliseconds: 20), done.complete);
      }, handlers.handleZoneError);
      await done.future;
      expect(handlers.handledCount, 1);
      expect(reporter.reports.single.fatal, isTrue);
    });
  });
}
