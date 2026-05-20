/// Typed exception hierarchy for domain-level failures.
///
/// Each subclass carries a [userMessage] safe to display in a toast or snackbar,
/// and an optional [debugMessage] for log context.
sealed class AppException implements Exception {
  final String userMessage;
  final String? debugMessage;
  final Object? cause;

  const AppException(this.userMessage, {this.debugMessage, this.cause});

  @override
  String toString() =>
      '${runtimeType.toString()}: $userMessage${debugMessage != null ? ' ($debugMessage)' : ''}';
}

/// Data-layer failure: DB / filesystem / network.
final class DataException extends AppException {
  const DataException(super.userMessage, {super.debugMessage, super.cause});
}

/// Business rule violation (e.g. duplicate name, invalid state).
final class DomainException extends AppException {
  const DomainException(super.userMessage, {super.debugMessage, super.cause});
}

/// User-facing operation failed but app state is safe.
final class UserFacingException extends AppException {
  const UserFacingException(super.userMessage, {super.debugMessage, super.cause});
}
