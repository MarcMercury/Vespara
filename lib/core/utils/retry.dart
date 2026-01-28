import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'result.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// RETRY UTILITIES - Resilient Network Operations
/// ════════════════════════════════════════════════════════════════════════════
///
/// Provides retry logic with exponential backoff for transient failures.
/// Use this for all network operations to improve reliability.

/// Configuration for retry behavior
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
    this.isRetryable,
    this.onRetry,
  });

  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Jitter factor (0.0 to 1.0) to randomize delays
  final double jitterFactor;

  /// Custom function to determine if an error is retryable
  final bool Function(dynamic error)? isRetryable;

  /// Callback when a retry occurs
  final void Function(int attempt, Duration delay, dynamic error)? onRetry;

  /// Default config for API calls
  static const api = RetryConfig(
    maxDelay: Duration(seconds: 10),
  );

  /// Config for critical operations (more retries)
  static const critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 60),
  );

  /// Config for quick operations (fewer retries)
  static const quick = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 2),
  );

  /// No retries - immediate failure
  static const none = RetryConfig(maxAttempts: 1);
}

/// Executes an operation with retry logic
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  RetryConfig config = RetryConfig.api,
}) async {
  int attempt = 0;
  Duration delay = config.initialDelay;

  while (true) {
    attempt++;
    try {
      return await operation();
    } catch (error) {
      // Check if we should retry
      final shouldRetry =
          attempt < config.maxAttempts && _isRetryableError(error, config);

      if (!shouldRetry) {
        // Log final failure
        debugPrint('Retry: Final failure after $attempt attempts - $error');
        rethrow;
      }

      // Calculate delay with jitter
      final jitter = config.jitterFactor > 0
          ? (delay.inMilliseconds *
              config.jitterFactor *
              (0.5 - _random.nextDouble() * 2))
          : 0;
      final actualDelay = Duration(
        milliseconds: (delay.inMilliseconds + jitter)
            .clamp(0, config.maxDelay.inMilliseconds)
            .toInt(),
      );

      // Notify retry callback
      config.onRetry?.call(attempt, actualDelay, error);
      debugPrint(
          'Retry: Attempt $attempt failed, retrying in ${actualDelay.inMilliseconds}ms - $error',);

      // Wait before retry
      await Future.delayed(actualDelay);

      // Increase delay for next attempt
      delay = Duration(
        milliseconds: (delay.inMilliseconds * config.backoffMultiplier)
            .clamp(0, config.maxDelay.inMilliseconds)
            .toInt(),
      );
    }
  }
}

/// Executes an operation with retry logic and returns a Result
Future<Result<T>> withRetryResult<T>(
  Future<T> Function() operation, {
  RetryConfig config = RetryConfig.api,
  AppError Function(dynamic error, StackTrace? stackTrace)? errorTransformer,
}) async {
  try {
    final result = await withRetry(operation, config: config);
    return Success(result);
  } catch (error, stackTrace) {
    if (errorTransformer != null) {
      return Failure(errorTransformer(error, stackTrace));
    }
    return Failure(_defaultErrorTransformer(error, stackTrace));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CIRCUIT BREAKER
// ═══════════════════════════════════════════════════════════════════════════

/// Circuit breaker states
enum CircuitState { closed, open, halfOpen }

/// Circuit breaker to prevent cascading failures
class CircuitBreaker {
  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.halfOpenTimeout = const Duration(seconds: 5),
  });
  final String name;
  final int failureThreshold;
  final Duration resetTimeout;
  final Duration halfOpenTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _openedAt;

  /// Current state of the circuit
  CircuitState get state {
    if (_state == CircuitState.open) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= resetTimeout) {
        _state = CircuitState.halfOpen;
      }
    }
    return _state;
  }

  /// Whether the circuit allows requests
  bool get allowRequest {
    switch (state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        return false;
      case CircuitState.halfOpen:
        return true;
    }
  }

  /// Execute an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (!allowRequest) {
      throw CircuitOpenException(name);
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
      _openedAt = DateTime.now();
      debugPrint(
          'CircuitBreaker[$name]: OPENED after $failureThreshold failures',);
    }
  }

  /// Manually reset the circuit
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _openedAt = null;
    debugPrint('CircuitBreaker[$name]: Manually reset');
  }
}

class CircuitOpenException implements Exception {
  const CircuitOpenException(this.circuitName);
  final String circuitName;

  @override
  String toString() => 'Circuit breaker [$circuitName] is open';
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

final _random = Random();

bool _isRetryableError(dynamic error, RetryConfig config) {
  // Use custom check if provided
  if (config.isRetryable != null) {
    return config.isRetryable!(error);
  }

  // Default retryable errors
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  if (error is HttpException) return true;

  // Check for Supabase/PostgrestException codes
  final errorString = error.toString().toLowerCase();
  if (errorString.contains('socket') ||
      errorString.contains('timeout') ||
      errorString.contains('connection') ||
      errorString.contains('network') ||
      errorString.contains('503') ||
      errorString.contains('502') ||
      errorString.contains('504')) {
    return true;
  }

  return false;
}

AppError _defaultErrorTransformer(dynamic error, StackTrace? stackTrace) {
  final errorString = error.toString().toLowerCase();

  // Network errors
  if (error is SocketException ||
      errorString.contains('socket') ||
      errorString.contains('network')) {
    return AppError.network(originalError: error, stackTrace: stackTrace);
  }

  // Timeout
  if (error is TimeoutException || errorString.contains('timeout')) {
    return AppError.timeout(originalError: error);
  }

  // Auth errors
  if (errorString.contains('jwt') ||
      errorString.contains('token') ||
      errorString.contains('unauthorized') ||
      errorString.contains('401')) {
    return AppError.authentication(originalError: error);
  }

  // Rate limiting
  if (errorString.contains('429') || errorString.contains('rate limit')) {
    return AppError.rateLimited();
  }

  // Not found
  if (errorString.contains('404') || errorString.contains('not found')) {
    return AppError.notFound();
  }

  // Server errors
  if (errorString.contains('500') ||
      errorString.contains('502') ||
      errorString.contains('503') ||
      errorString.contains('server')) {
    return AppError.server(originalError: error);
  }

  // Forbidden
  if (errorString.contains('403') || errorString.contains('forbidden')) {
    return AppError.forbidden();
  }

  return AppError.unknown(originalError: error, stackTrace: stackTrace);
}
