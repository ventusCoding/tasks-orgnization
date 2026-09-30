/// What went wrong, in user terms (T1.3.05). Each kind has one localized message
/// (`errorNetwork`, `errorAuth`, …) resolved at the presentation edge — see `ErrorState.messageFor`.
enum AppErrorKind {
  network,
  auth,
  validation,
  conflict,
  storage,
  permission,
  notFound,
  unsupportedVersion,
  notConfigured,
  unknown,
}

/// Typed application errors (T1.3.05). Mapped to localized messages at the presentation edge.
///
/// [message] is developer-facing (English, no user content — ids only); users see the
/// localized text of [kind]. Use `toAppException` (`error_mapper.dart`) to turn Supabase, Drift and
/// platform exceptions into one of these.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  AppErrorKind get kind;

  /// Whether trying again later can help (offline, flaky network).
  bool get isRetryable => kind == AppErrorKind.network;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.network;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.auth;
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field, super.cause});

  final String? field;

  @override
  AppErrorKind get kind => AppErrorKind.validation;
}

class ConflictException extends AppException {
  const ConflictException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.conflict;
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.storage;
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.permission;
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.notFound;
}

class UnsupportedVersionException extends AppException {
  const UnsupportedVersionException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.unsupportedVersion;
}

class NotConfiguredException extends AppException {
  const NotConfiguredException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.notConfigured;
}

class UnknownAppException extends AppException {
  const UnknownAppException(super.message, {super.cause});

  @override
  AppErrorKind get kind => AppErrorKind.unknown;
}
