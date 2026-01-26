/// ════════════════════════════════════════════════════════════════════════════
/// RESULT TYPE - Functional Error Handling
/// ════════════════════════════════════════════════════════════════════════════
///
/// A sealed type for representing success/failure outcomes without exceptions.
/// Use this throughout the app to make error handling explicit and type-safe.
///
/// Example:
/// ```dart
/// final result = await repository.getUser(id);
/// switch (result) {
///   case Success(:final data): showUser(data);
///   case Failure(:final error): showError(error);
/// }
/// ```
library;

sealed class Result<T> {
  const Result();

  /// Returns true if this is a Success
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure
  bool get isFailure => this is Failure<T>;

  /// Gets the data if Success, or null if Failure
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Gets the error if Failure, or null if Success
  AppError? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  /// Maps the success value to a new type
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success(:final data) => Success(transform(data)),
        Failure(:final error) => Failure(error),
      };

  /// Maps the success value with an async function
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async =>
      switch (this) {
        Success(:final data) => Success(await transform(data)),
        Failure(:final error) => Failure(error),
      };

  /// Executes the appropriate callback based on result type
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) =>
      switch (this) {
        Success(:final data) => success(data),
        Failure(:final error) => failure(error),
      };

  /// Like when(), but with optional handlers that default to returning null
  R? whenOrNull<R>({
    R Function(T data)? success,
    R Function(AppError error)? failure,
  }) =>
      switch (this) {
        Success(:final data) => success?.call(data),
        Failure(:final error) => failure?.call(error),
      };

  /// Gets data or throws the error
  T getOrThrow() => switch (this) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      };

  /// Gets data or returns a default value
  T getOrElse(T defaultValue) => switch (this) {
        Success(:final data) => data,
        Failure() => defaultValue,
      };

  /// Gets data or computes a default from the error
  T getOrElseCompute(T Function(AppError error) compute) => switch (this) {
        Success(:final data) => data,
        Failure(:final error) => compute(error),
      };
}

/// Success case containing the result data
class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failure case containing the error
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppError error;

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// APP ERROR
// ═══════════════════════════════════════════════════════════════════════════

/// Unified error type for the entire application
class AppError implements Exception {
  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
    this.statusCode,
    this.isRetryable = false,
    this.context,
  });

  /// Network connectivity error
  factory AppError.network({
    String message =
        'Unable to connect. Please check your internet connection.',
    dynamic originalError,
    StackTrace? stackTrace,
  }) =>
      AppError(
        message: message,
        type: ErrorType.network,
        originalError: originalError,
        stackTrace: stackTrace,
        isRetryable: true,
      );

  /// Authentication error (token expired, unauthorized)
  factory AppError.authentication({
    String message = 'Your session has expired. Please log in again.',
    String? code,
    dynamic originalError,
  }) =>
      AppError(
        message: message,
        type: ErrorType.authentication,
        code: code,
        originalError: originalError,
      );

  /// Validation error (invalid input)
  factory AppError.validation({
    required String message,
    String? code,
    Map<String, dynamic>? context,
  }) =>
      AppError(
        message: message,
        type: ErrorType.validation,
        code: code,
        context: context,
      );

  /// Server error (500s)
  factory AppError.server({
    String message = 'Something went wrong on our end. Please try again.',
    int? statusCode,
    dynamic originalError,
  }) =>
      AppError(
        message: message,
        type: ErrorType.serverError,
        statusCode: statusCode,
        originalError: originalError,
        isRetryable: true,
      );

  /// Not found error (404)
  factory AppError.notFound({
    String message = 'The requested resource was not found.',
    String? code,
  }) =>
      AppError(
        message: message,
        type: ErrorType.notFound,
        code: code,
      );

  /// Rate limited (429)
  factory AppError.rateLimited({
    String message = 'Too many requests. Please wait a moment.',
    Duration? retryAfter,
  }) =>
      AppError(
        message: message,
        type: ErrorType.rateLimited,
        isRetryable: true,
        context:
            retryAfter != null ? {'retryAfter': retryAfter.inSeconds} : null,
      );

  /// Permission denied
  factory AppError.forbidden({
    String message = 'You don\'t have permission to perform this action.',
  }) =>
      AppError(
        message: message,
        type: ErrorType.forbidden,
      );

  /// Timeout
  factory AppError.timeout({
    String message = 'The request timed out. Please try again.',
    dynamic originalError,
  }) =>
      AppError(
        message: message,
        type: ErrorType.timeout,
        originalError: originalError,
        isRetryable: true,
      );

  /// Unknown/unexpected error
  factory AppError.unknown({
    String message = 'An unexpected error occurred.',
    dynamic originalError,
    StackTrace? stackTrace,
  }) =>
      AppError(
        message: message,
        type: ErrorType.unknown,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Human-readable error message
  final String message;

  /// Error category for handling decisions
  final ErrorType type;

  /// Error code for specific identification
  final String? code;

  /// Original exception (for debugging)
  final dynamic originalError;

  /// Stack trace (for debugging)
  final StackTrace? stackTrace;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Whether this error is recoverable by retry
  final bool isRetryable;

  /// Context data for debugging
  final Map<String, dynamic>? context;

  @override
  String toString() => 'AppError(type: $type, message: $message, code: $code)';
}

/// Error categories
enum ErrorType {
  /// Network/connectivity issues
  network,

  /// Auth token expired or invalid
  authentication,

  /// Invalid user input
  validation,

  /// Server-side error (5xx)
  serverError,

  /// Resource not found (404)
  notFound,

  /// Rate limited (429)
  rateLimited,

  /// Permission denied (403)
  forbidden,

  /// Request timeout
  timeout,

  /// Conflict (409) - e.g., duplicate entry
  conflict,

  /// Service unavailable (503)
  serviceUnavailable,

  /// Unknown/unhandled error
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════

extension ResultListExtension<T> on Iterable<Result<T>> {
  /// Combines a list of Results into a single Result containing a list
  /// If any result is a Failure, returns the first Failure
  Result<List<T>> combine() {
    final successes = <T>[];
    for (final result in this) {
      switch (result) {
        case Success(:final data):
          successes.add(data);
        case Failure(:final error):
          return Failure(error);
      }
    }
    return Success(successes);
  }
}

extension FutureResultExtension<T> on Future<Result<T>> {
  /// Maps the success value of a Future<Result<T>>
  Future<Result<R>> mapResult<R>(R Function(T data) transform) async =>
      (await this).map(transform);

  /// Executes when callback on Future<Result<T>>
  Future<R> whenResult<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) async =>
      (await this).when(success: success, failure: failure);
}
