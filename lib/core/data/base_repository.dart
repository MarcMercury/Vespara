import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/result.dart';
import '../utils/retry.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// BASE REPOSITORY - Foundation for Data Access
/// ════════════════════════════════════════════════════════════════════════════
///
/// Abstract base class providing:
/// - Unified error handling with Result type
/// - Retry logic for transient failures
/// - Connection state awareness
/// - Consistent patterns for all repositories

abstract class BaseRepository {
  final SupabaseClient supabase;

  BaseRepository(this.supabase);

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current user ID (null if not authenticated)
  String? get userId => supabase.auth.currentUser?.id;

  /// Current user (null if not authenticated)
  User? get currentUser => supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => userId != null;

  /// Require authentication - throws if not logged in
  String requireUserId() {
    final id = userId;
    if (id == null) {
      throw AppError.authentication(message: 'You must be logged in to perform this action');
    }
    return id;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFE CALL WRAPPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Execute an operation with retry logic and return a Result
  Future<Result<T>> safeCall<T>(
    Future<T> Function() operation, {
    RetryConfig retryConfig = RetryConfig.api,
    String? operationName,
  }) async {
    return withRetryResult(
      operation,
      config: retryConfig,
      errorTransformer: (error, stackTrace) => _transformError(error, stackTrace, operationName),
    );
  }

  /// Execute an operation without retry (for writes that shouldn't be repeated)
  Future<Result<T>> safeCallNoRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (error, stackTrace) {
      return Failure(_transformError(error, stackTrace, operationName));
    }
  }

  /// Execute a critical operation with more retries
  Future<Result<T>> safeCriticalCall<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    return safeCall(
      operation,
      retryConfig: RetryConfig.critical,
      operationName: operationName,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a safe stream that handles errors and reconnection
  Stream<Result<T>> safeStream<T>(
    Stream<T> Function() streamFactory, {
    Duration reconnectDelay = const Duration(seconds: 5),
    int maxReconnects = 10,
  }) async* {
    int reconnectAttempts = 0;

    while (reconnectAttempts < maxReconnects) {
      try {
        await for (final data in streamFactory()) {
          yield Success(data);
          reconnectAttempts = 0; // Reset on successful data
        }
      } catch (error, stackTrace) {
        final appError = _transformError(error, stackTrace, 'stream');
        yield Failure(appError);

        if (!appError.isRetryable) {
          break;
        }

        reconnectAttempts++;
        debugPrint('Stream: Reconnect attempt $reconnectAttempts after ${reconnectDelay.inSeconds}s');
        await Future.delayed(reconnectDelay);
      }
    }
  }

  /// Watch a Supabase table with automatic reconnection
  Stream<Result<List<T>>> watchTable<T>({
    required String table,
    required List<String> primaryKey,
    required T Function(Map<String, dynamic> json) fromJson,
    PostgrestTransformBuilder<List<Map<String, dynamic>>> Function(SupabaseQueryBuilder query)? queryBuilder,
  }) {
    return safeStream(() {
      final query = supabase.from(table);
      final stream = query.stream(primaryKey: primaryKey);

      return stream.map((rows) => rows.map(fromJson).toList());
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON QUERY PATTERNS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch a single record by ID
  Future<Result<T>> fetchById<T>({
    required String table,
    required String id,
    required T Function(Map<String, dynamic> json) fromJson,
    String idColumn = 'id',
    String selectColumns = '*',
  }) async {
    return safeCall(() async {
      final response = await supabase
          .from(table)
          .select(selectColumns)
          .eq(idColumn, id)
          .single();

      return fromJson(response);
    }, operationName: 'fetchById($table)');
  }

  /// Fetch a list of records
  Future<Result<List<T>>> fetchList<T>({
    required String table,
    required T Function(Map<String, dynamic> json) fromJson,
    String selectColumns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    return safeCall(() async {
      var query = supabase.from(table).select(selectColumns);

      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      return (response as List).map((json) => fromJson(json as Map<String, dynamic>)).toList();
    }, operationName: 'fetchList($table)');
  }

  /// Insert a record
  Future<Result<T>> insert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    return safeCallNoRetry(() async {
      final response = await supabase.from(table).insert(data).select().single();

      return fromJson(response);
    }, operationName: 'insert($table)');
  }

  /// Update a record
  Future<Result<T>> update<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) fromJson,
    String idColumn = 'id',
  }) async {
    return safeCallNoRetry(() async {
      final response = await supabase.from(table).update(data).eq(idColumn, id).select().single();

      return fromJson(response);
    }, operationName: 'update($table)');
  }

  /// Delete a record
  Future<Result<void>> delete({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async {
    return safeCallNoRetry(() async {
      await supabase.from(table).delete().eq(idColumn, id);
    }, operationName: 'delete($table)');
  }

  /// Upsert a record
  Future<Result<T>> upsert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> json) fromJson,
    String? onConflict,
  }) async {
    return safeCallNoRetry(() async {
      final response = await supabase
          .from(table)
          .upsert(data, onConflict: onConflict)
          .select()
          .single();

      return fromJson(response);
    }, operationName: 'upsert($table)');
  }

  /// Call an RPC function
  Future<Result<T>> rpc<T>({
    required String functionName,
    Map<String, dynamic>? params,
    required T Function(dynamic response) transform,
  }) async {
    return safeCall(() async {
      final response = await supabase.rpc(functionName, params: params);
      return transform(response);
    }, operationName: 'rpc($functionName)');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR TRANSFORMATION
  // ═══════════════════════════════════════════════════════════════════════════

  AppError _transformError(dynamic error, StackTrace? stackTrace, String? operationName) {
    final context = operationName != null ? {'operation': operationName} : null;

    // PostgrestException (Supabase database errors)
    if (error is PostgrestException) {
      return _transformPostgrestError(error, context);
    }

    // AuthException (Supabase auth errors)
    if (error is AuthException) {
      return AppError.authentication(
        message: error.message,
        code: error.statusCode,
        originalError: error,
      );
    }

    // FunctionException (Edge function errors)
    if (error is FunctionException) {
      return AppError.server(
        message: error.reasonPhrase ?? 'Edge function error',
        statusCode: error.status,
        originalError: error,
      );
    }

    // Generic transformation
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') || errorString.contains('network')) {
      return AppError.network(originalError: error, stackTrace: stackTrace);
    }

    if (errorString.contains('timeout')) {
      return AppError.timeout(originalError: error);
    }

    return AppError.unknown(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  AppError _transformPostgrestError(PostgrestException error, Map<String, dynamic>? context) {
    final code = error.code;
    final message = error.message;

    // Auth errors
    if (code == '42501' || code == 'PGRST301') {
      return AppError.forbidden(message: 'Permission denied');
    }

    // Not found
    if (code == 'PGRST116') {
      return AppError.notFound(message: message, code: code);
    }

    // Unique violation
    if (code == '23505') {
      return AppError.validation(
        message: 'This record already exists',
        code: code,
        context: context,
      );
    }

    // Foreign key violation
    if (code == '23503') {
      return AppError.validation(
        message: 'Referenced record does not exist',
        code: code,
        context: context,
      );
    }

    // Check constraint violation
    if (code == '23514') {
      return AppError.validation(
        message: message,
        code: code,
        context: context,
      );
    }

    return AppError.server(
      message: message,
      originalError: error,
    );
  }
}
