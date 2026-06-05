/// A discriminated union for operations that can succeed or fail.
///
/// Pattern-match on [Ok] or [Err] to handle both outcomes explicitly.
sealed class Result<T> {
  const Result();

  R fold<R>({required R Function(T value) onOk, required R Function(String message, Object? error) onErr}) {
    return switch (this) {
      Ok(:final value) => onOk(value),
      Err(:final message, :final error) => onErr(message, error),
    };
  }

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get okValue => this is Ok<T> ? (this as Ok<T>).value : null;
  String? get errMessage => this is Err<T> ? (this as Err<T>).message : null;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

class Err<T> extends Result<T> {
  final String message;
  final Object? error;
  const Err(this.message, [this.error]);

  @override
  String toString() => 'Err($message)';
}
