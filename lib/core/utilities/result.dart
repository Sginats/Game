/// A simple Result type for error handling without exceptions.
class Result<T> {
  final T? value;
  final String? error;

  const Result.success(this.value) : error = null;
  const Result.failure(this.error) : value = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
