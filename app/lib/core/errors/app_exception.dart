/// Typed application errors (T1.3.05). Mapped to localized messages at the presentation edge.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field, super.cause});

  final String? field;
}

class ConflictException extends AppException {
  const ConflictException(super.message, {super.cause});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

class UnsupportedVersionException extends AppException {
  const UnsupportedVersionException(super.message, {super.cause});
}

class NotConfiguredException extends AppException {
  const NotConfiguredException(super.message, {super.cause});
}

class UnknownAppException extends AppException {
  const UnknownAppException(super.message, {super.cause});
}
