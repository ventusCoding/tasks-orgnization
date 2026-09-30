import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:everslot/core/errors/app_exception.dart' as app;
import 'package:everslot/core/errors/error_mapper.dart';
import 'package:everslot/core/sync/sync_api.dart' show SyncApiException;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// T1.3.05: exception mappers (Supabase / Drift / platform → AppException).
void main() {
  app.AppErrorKind kindOf(Object e) => toAppException(e).kind;

  group('AppException', () {
    test(
      'every subclass has a distinct kind; only network errors are retryable',
      () {
        const all = <app.AppException>[
          app.NetworkException('x'),
          app.AuthException('x'),
          app.ValidationException('x', field: 'title'),
          app.ConflictException('x'),
          app.StorageException('x'),
          app.PermissionException('x'),
          app.NotFoundException('x'),
          app.UnsupportedVersionException('x'),
          app.NotConfiguredException('x'),
          app.UnknownAppException('x'),
        ];
        expect(all.map((e) => e.kind).toSet(), app.AppErrorKind.values.toSet());
        expect(
          all.where((e) => e.isRetryable).single,
          isA<app.NetworkException>(),
        );
        expect(
          const app.ValidationException('bad', field: 'title').toString(),
          'ValidationException: bad',
        );
      },
    );

    test('an AppException maps to itself', () {
      const e = app.ConflictException('same');
      expect(identical(toAppException(e), e), isTrue);
    });
  });

  group('Supabase Auth', () {
    test(
      'network / rate limit / server errors are retryable network errors',
      () {
        expect(
          kindOf(sb.AuthRetryableFetchException()),
          app.AppErrorKind.network,
        );
        expect(
          kindOf(
            const sb.AuthApiException(
              'slow down',
              statusCode: '429',
              code: 'over_request_rate_limit',
            ),
          ),
          app.AppErrorKind.network,
        );
        expect(
          kindOf(const sb.AuthApiException('oops', statusCode: '503')),
          app.AppErrorKind.network,
        );
      },
    );

    test('credentials, sessions and tokens', () {
      expect(
        kindOf(
          const sb.AuthApiException(
            'bad',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        app.AppErrorKind.auth,
      );
      expect(kindOf(sb.AuthSessionMissingException()), app.AppErrorKind.auth);
      expect(
        kindOf(
          const sb.AuthApiException(
            'gone',
            statusCode: '400',
            code: 'refresh_token_not_found',
          ),
        ),
        app.AppErrorKind.auth,
      );
    });

    test('validation, conflicts and disabled providers', () {
      expect(
        kindOf(
          const sb.AuthApiException(
            'x',
            statusCode: '422',
            code: 'validation_failed',
          ),
        ),
        app.AppErrorKind.validation,
      );
      expect(
        kindOf(
          const sb.AuthApiException(
            'x',
            statusCode: '422',
            code: 'email_exists',
          ),
        ),
        app.AppErrorKind.conflict,
      );
      expect(
        kindOf(
          const sb.AuthApiException(
            'x',
            statusCode: '400',
            code: 'provider_disabled',
          ),
        ),
        app.AppErrorKind.notConfigured,
      );
      expect(
        kindOf(
          sb.AuthWeakPasswordException(
            message: 'weak',
            statusCode: '422',
            reasons: const [],
          ),
        ),
        app.AppErrorKind.validation,
      );
    });
  });

  group('PostgREST', () {
    app.AppErrorKind pg(String code) => kindOf(
      sb.PostgrestException(
        message: 'Key (email)=(a@b.co) already exists',
        code: code,
      ),
    );

    test('SQLSTATE and PostgREST codes', () {
      expect(pg('23505'), app.AppErrorKind.conflict);
      expect(pg('23503'), app.AppErrorKind.conflict);
      expect(pg('40001'), app.AppErrorKind.conflict);
      expect(pg('23502'), app.AppErrorKind.validation);
      expect(pg('23514'), app.AppErrorKind.validation);
      expect(pg('22P02'), app.AppErrorKind.validation);
      expect(pg('42501'), app.AppErrorKind.permission);
      expect(pg('PGRST301'), app.AppErrorKind.auth);
      expect(pg('28000'), app.AppErrorKind.auth);
      expect(pg('PGRST116'), app.AppErrorKind.notFound);
      expect(pg('57014'), app.AppErrorKind.network);
      expect(pg('53300'), app.AppErrorKind.network);
      expect(pg('PGRST202'), app.AppErrorKind.unsupportedVersion);
      expect(pg('XX999'), app.AppErrorKind.unknown);
    });

    test('bare HTTP status codes', () {
      expect(pg('401'), app.AppErrorKind.auth);
      expect(pg('403'), app.AppErrorKind.permission);
      expect(pg('404'), app.AppErrorKind.notFound);
      expect(pg('409'), app.AppErrorKind.conflict);
      expect(pg('426'), app.AppErrorKind.unsupportedVersion);
      expect(pg('429'), app.AppErrorKind.network);
      expect(pg('502'), app.AppErrorKind.network);
    });

    test('the developer message never contains row values', () {
      final mapped = toAppException(
        const sb.PostgrestException(
          message: 'Key (email)=(secret@example.com) already exists',
          code: '23505',
        ),
      );
      expect(mapped.message, isNot(contains('secret@example.com')));
      expect(
        mapped.cause,
        isA<sb.PostgrestException>(),
        reason: 'the original stays available as the cause',
      );
    });
  });

  group('Edge Functions, Storage and the sync API', () {
    test('functions', () {
      expect(
        kindOf(const sb.FunctionException(status: 401)),
        app.AppErrorKind.auth,
      );
      expect(
        kindOf(const sb.FunctionException(status: 403)),
        app.AppErrorKind.permission,
      );
      expect(
        kindOf(const sb.FunctionException(status: 404)),
        app.AppErrorKind.notFound,
      );
      expect(
        kindOf(const sb.FunctionException(status: 422)),
        app.AppErrorKind.validation,
      );
      expect(
        kindOf(const sb.FunctionException(status: 500)),
        app.AppErrorKind.network,
      );
      expect(
        kindOf(const sb.FunctionsFetchException(details: 'offline')),
        app.AppErrorKind.network,
      );
    });

    test('storage', () {
      expect(
        kindOf(const sb.StorageException('nope', statusCode: '404')),
        app.AppErrorKind.notFound,
      );
      expect(
        kindOf(const sb.StorageException('rls', statusCode: '403')),
        app.AppErrorKind.permission,
      );
      expect(
        kindOf(const sb.StorageException('big', statusCode: '413')),
        app.AppErrorKind.validation,
      );
      expect(
        kindOf(const sb.StorageException('dup', statusCode: '409')),
        app.AppErrorKind.conflict,
      );
      expect(
        kindOf(const sb.StorageException('down', statusCode: '503')),
        app.AppErrorKind.network,
      );
      expect(
        kindOf(const sb.StorageException('???')),
        app.AppErrorKind.storage,
      );
      expect(
        kindOf(const sb.StorageException('teapot', statusCode: '418')),
        app.AppErrorKind.storage,
      );
    });

    test('sync API codes', () {
      expect(
        kindOf(
          const SyncApiException(
            SyncApiException.unsupportedClient,
            status: 426,
          ),
        ),
        app.AppErrorKind.unsupportedVersion,
      );
      expect(
        kindOf(
          const SyncApiException(SyncApiException.deviceRevoked, status: 403),
        ),
        app.AppErrorKind.auth,
      );
      expect(
        kindOf(const SyncApiException(SyncApiException.notAuthenticated)),
        app.AppErrorKind.auth,
      );
      expect(
        kindOf(
          const SyncApiException(SyncApiException.tooManyChanges, status: 413),
        ),
        app.AppErrorKind.validation,
      );
      expect(
        kindOf(const SyncApiException('something_new', status: 503)),
        app.AppErrorKind.network,
      );
      expect(
        kindOf(const SyncApiException('something_new')),
        app.AppErrorKind.unknown,
      );
    });
  });

  group('Drift / SQLite', () {
    SqliteException sqlite(int code) =>
        SqliteException(extendedResultCode: code, message: 'boom');

    test('unique and primary-key violations are conflicts, other constraints are validation errors', () {
      expect(kindOf(sqlite(2067)), app.AppErrorKind.conflict);
      expect(kindOf(sqlite(1555)), app.AppErrorKind.conflict);
      expect(
        kindOf(sqlite(787)),
        app.AppErrorKind.validation,
        reason: 'foreign key',
      );
      expect(
        kindOf(sqlite(1299)),
        app.AppErrorKind.validation,
        reason: 'not null',
      );
    });

    test('disk, IO, corruption and locking problems are storage errors', () {
      for (final code in [13, 10, 11, 14, 5, 6, 8]) {
        expect(
          kindOf(sqlite(code)),
          app.AppErrorKind.storage,
          reason: 'code $code',
        );
      }
    });

    test('DriftWrappedException unwraps its cause', () {
      expect(
        kindOf(DriftWrappedException(message: 'm', cause: sqlite(2067))),
        app.AppErrorKind.conflict,
      );
      expect(
        kindOf(DriftWrappedException(message: 'm', cause: sqlite(13))),
        app.AppErrorKind.storage,
      );
      expect(
        kindOf(DriftWrappedException(message: 'm')),
        app.AppErrorKind.storage,
      );
    });
  });

  group('dart:io, dart:async, http and platform channels', () {
    test('connectivity problems', () {
      expect(
        kindOf(const SocketException('Failed host lookup')),
        app.AppErrorKind.network,
      );
      expect(
        kindOf(const HandshakeException('bad cert')),
        app.AppErrorKind.network,
      );
      expect(kindOf(const HttpException('closed')), app.AppErrorKind.network);
      expect(kindOf(TimeoutException('slow')), app.AppErrorKind.network);
      expect(
        kindOf(http.ClientException('Connection reset')),
        app.AppErrorKind.network,
      );
      expect(
        kindOf(PlatformException(code: 'network_error')),
        app.AppErrorKind.network,
      );
    });

    test('files and permissions', () {
      expect(
        kindOf(
          const FileSystemException(
            'x',
            '/p',
            OSError('No space left on device', 28),
          ),
        ),
        app.AppErrorKind.storage,
      );
      expect(
        kindOf(
          const FileSystemException(
            'x',
            '/p',
            OSError('Permission denied', 13),
          ),
        ),
        app.AppErrorKind.permission,
      );
      expect(
        kindOf(
          const FileSystemException('x', '/p', OSError('No such file', 2)),
        ),
        app.AppErrorKind.notFound,
      );
      expect(
        kindOf(PlatformException(code: 'PERMISSION_DENIED')),
        app.AppErrorKind.permission,
      );
      expect(
        kindOf(PlatformException(code: 'camera_access_denied')),
        app.AppErrorKind.permission,
      );
    });

    test('anything else is unknown and keeps the original as the cause', () {
      final original = StateError('nope');
      final mapped = toAppException(original);
      expect(mapped, isA<app.UnknownAppException>());
      expect(mapped.cause, same(original));
      expect(
        mapped.message,
        'StateError',
        reason: 'only the type name, never the text',
      );
      expect(
        kindOf(PlatformException(code: 'weird')),
        app.AppErrorKind.unknown,
      );
    });
  });

  test('isOfflineError recognises typed and text-only network failures', () {
    expect(isOfflineError(const SocketException('x')), isTrue);
    expect(isOfflineError(sb.AuthRetryableFetchException()), isTrue);
    expect(
      isOfflineError(
        Exception('ClientException: Failed host lookup: x.supabase.co'),
      ),
      isTrue,
    );
    expect(isOfflineError(StateError('boom')), isFalse);
    expect(
      isOfflineError(const sb.PostgrestException(message: 'x', code: '23505')),
      isFalse,
    );
  });
}
