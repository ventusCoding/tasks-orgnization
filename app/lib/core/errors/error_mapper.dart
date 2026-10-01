import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:everslot/core/errors/app_exception.dart' as app;
import 'package:everslot/core/sync/sync_api.dart' show SyncApiException;
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Turns anything thrown by Supabase, Drift/SQLite, `dart:io` or a platform channel into an
/// [app.AppException] (T1.3.05). The result's `message` is developer-facing and never carries user
/// content (row values, e-mail addresses, tokens): only codes and generic descriptions. The original
/// error stays reachable as `cause`.
app.AppException toAppException(Object error) {
  return switch (error) {
    final app.AppException e => e,
    // ── Supabase ──────────────────────────────────────────────────────────────
    final sb.AuthRetryableFetchException e => app.NetworkException('auth network error', cause: e),
    final sb.AuthWeakPasswordException e => app.ValidationException('weak password', field: 'password', cause: e),
    final sb.AuthException e => _fromAuth(e),
    final sb.PostgrestException e => _fromPostgrest(e),
    final sb.FunctionException e => _fromHttpStatus(e.status, 'edge function ${e.status}', e),
    final sb.StorageException e => _fromStorage(e),
    final SyncApiException e => _fromSyncApi(e),
    // ── Drift / SQLite ────────────────────────────────────────────────────────
    final DriftWrappedException e =>
      e.cause == null ? app.StorageException('database error', cause: e) : toAppException(e.cause!),
    final SqliteException e => _fromSqlite(e),
    // ── dart:io, dart:async, package:http, platform channels ─────────────────
    final SocketException e => app.NetworkException('socket error', cause: e),
    final HandshakeException e => app.NetworkException('TLS handshake failed', cause: e),
    final TlsException e => app.NetworkException('TLS error', cause: e),
    final HttpException e => app.NetworkException('http error', cause: e),
    final WebSocketException e => app.NetworkException('websocket error', cause: e),
    final http.ClientException e => app.NetworkException('http client error', cause: e),
    final TimeoutException e => app.NetworkException('timeout', cause: e),
    final FileSystemException e => _fromFileSystem(e),
    final PlatformException e => _fromPlatform(e),
    _ => app.UnknownAppException(error.runtimeType.toString(), cause: error),
  };
}

/// Whether [error] is a "no network / server unreachable" condition (status `offline`, retry later).
bool isOfflineError(Object error) {
  if (toAppException(error) is app.NetworkException) return true;
  // Wrapped errors (`Exception('… SocketException …')`) keep their type only in text.
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('Network is unreachable') ||
      text.contains('TimeoutException');
}

app.AppException _fromAuth(sb.AuthException e) {
  final code = e.code ?? '';
  final status = e.statusCode ?? '';
  if (code.contains('rate_limit') || status == '429') {
    return app.NetworkException('auth rate limited ($code)', cause: e);
  }
  if (status.startsWith('5')) {
    return app.NetworkException('auth server error ($status)', cause: e);
  }
  if (code == 'validation_failed' || code == 'email_address_invalid') {
    return app.ValidationException('auth validation ($code)', cause: e);
  }
  if (code == 'email_exists' || code == 'user_already_exists' || code == 'identity_already_exists') {
    return app.ConflictException('auth conflict ($code)', cause: e);
  }
  if (code == 'provider_disabled' || code == 'anonymous_provider_disabled' || code == 'email_provider_disabled') {
    return app.NotConfiguredException('auth provider disabled ($code)', cause: e);
  }
  return app.AuthException('auth error (${code.isEmpty ? status : code})', cause: e);
}

app.AppException _fromPostgrest(sb.PostgrestException e) {
  final code = e.code ?? '';
  switch (code) {
    case '23505' || '23503' || '40001' || '40P01':
      return app.ConflictException('postgres $code', cause: e);
    case '23502' || '23514' || '22P02' || '22001' || '22003' || '22007':
      return app.ValidationException('postgres $code', cause: e);
    case '42501':
      return app.PermissionException('postgres $code (row-level security or grant)', cause: e);
    case '28000' || '28P01' || 'PGRST301' || 'PGRST303':
      return app.AuthException('postgres $code', cause: e);
    case 'PGRST116':
      return app.NotFoundException('postgrest $code', cause: e);
    case '57014':
      return app.NetworkException('postgres $code (statement timeout)', cause: e);
    case '42P01' || '42883' || 'PGRST202' || 'PGRST205':
      // The function/table isn't there: the server side is older than this build.
      return app.UnsupportedVersionException('postgrest $code (missing object)', cause: e);
  }
  if (code.startsWith('53')) {
    return app.NetworkException('postgres $code (server resources)', cause: e);
  }
  final status = int.tryParse(code);
  if (status != null) return _fromHttpStatus(status, 'postgrest $status', e);
  return app.UnknownAppException('postgrest ${code.isEmpty ? 'error' : code}', cause: e);
}

app.AppException _fromStorage(sb.StorageException e) {
  final status = int.tryParse(e.statusCode ?? '');
  if (status == null) return app.StorageException('storage error', cause: e);
  final mapped = _fromHttpStatus(status, 'storage $status', e);
  return mapped is app.UnknownAppException ? app.StorageException('storage $status', cause: e) : mapped;
}

app.AppException _fromSyncApi(SyncApiException e) => switch (e.code) {
  SyncApiException.unsupportedClient => app.UnsupportedVersionException('sync: app build refused', cause: e),
  SyncApiException.deviceRevoked || SyncApiException.notAuthenticated => app.AuthException('sync: ${e.code}', cause: e),
  SyncApiException.tooManyChanges ||
  SyncApiException.invalidRequest => app.ValidationException('sync: ${e.code}', cause: e),
  _ =>
    e.status == null
        ? app.UnknownAppException('sync: ${e.code}', cause: e)
        : _fromHttpStatus(e.status!, 'sync ${e.code}', e),
};

app.AppException _fromHttpStatus(int status, String what, Object cause) {
  if (status == 0) {
    return app.NetworkException('$what (request not sent)', cause: cause);
  }
  return switch (status) {
    401 => app.AuthException(what, cause: cause),
    403 => app.PermissionException(what, cause: cause),
    404 => app.NotFoundException(what, cause: cause),
    409 => app.ConflictException(what, cause: cause),
    400 || 413 || 422 => app.ValidationException(what, cause: cause),
    426 => app.UnsupportedVersionException(what, cause: cause),
    408 || 429 => app.NetworkException(what, cause: cause),
    >= 500 && < 600 => app.NetworkException(what, cause: cause),
    _ => app.UnknownAppException(what, cause: cause),
  };
}

// SQLite primary result codes (https://sqlite.org/rescode.html).
const _sqliteBusy = 5;
const _sqliteLocked = 6;
const _sqliteConstraint = 19;
const _sqliteConstraintPrimaryKey = 1555;
const _sqliteConstraintUnique = 2067;

app.AppException _fromSqlite(SqliteException e) {
  final primary = e.resultCode;
  if (primary == _sqliteConstraint) {
    return e.extendedResultCode == _sqliteConstraintUnique || e.extendedResultCode == _sqliteConstraintPrimaryKey
        ? app.ConflictException('sqlite unique constraint', cause: e)
        : app.ValidationException('sqlite constraint ${e.extendedResultCode}', cause: e);
  }
  return switch (primary) {
    _sqliteBusy || _sqliteLocked => app.StorageException('sqlite busy', cause: e),
    _ => app.StorageException('sqlite error $primary', cause: e),
  };
}

app.AppException _fromFileSystem(FileSystemException e) {
  final errno = e.osError?.errorCode;
  if (errno == 13 || errno == 1) {
    return app.PermissionException('file permission denied', cause: e);
  }
  if (errno == 2) return app.NotFoundException('file not found', cause: e);
  return app.StorageException('file error${errno == null ? '' : ' $errno'}', cause: e);
}

app.AppException _fromPlatform(PlatformException e) {
  final code = e.code.toLowerCase();
  if (code.contains('permission') || code.contains('denied') || code == 'not_authorized') {
    return app.PermissionException('platform: ${e.code}', cause: e);
  }
  if (code.contains('network') || code.contains('offline') || code.contains('timeout')) {
    return app.NetworkException('platform: ${e.code}', cause: e);
  }
  if (code.contains('not_found') || code.contains('notfound')) {
    return app.NotFoundException('platform: ${e.code}', cause: e);
  }
  return app.UnknownAppException('platform: ${e.code}', cause: e);
}
