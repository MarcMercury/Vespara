import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CONNECTION MANAGER - Centralized Connection Health
/// ════════════════════════════════════════════════════════════════════════════
///
/// Manages Supabase connection health, automatic reconnection, and provides
/// a centralized way to monitor connectivity across the app.

enum ConnectionStatus {
  /// Connection is healthy and active
  connected,

  /// Attempting to connect/reconnect
  connecting,

  /// No network connectivity
  disconnected,

  /// Authentication required (token expired)
  authRequired,
}

class ConnectionManager {
  static ConnectionManager? _instance;
  static ConnectionManager get instance => _instance ??= ConnectionManager._();

  ConnectionManager._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Connection state
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _currentStatus = ConnectionStatus.connected;
  DateTime? _lastSuccessfulRequest;
  int _consecutiveFailures = 0;

  // Reconnection
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  final Duration _healthCheckInterval = const Duration(seconds: 30);
  final int _maxConsecutiveFailures = 3;

  /// Current connection status
  ConnectionStatus get status => _currentStatus;

  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Whether we have a healthy connection
  bool get isConnected => _currentStatus == ConnectionStatus.connected;

  /// Whether we're attempting to reconnect
  bool get isReconnecting => _currentStatus == ConnectionStatus.connecting;

  /// Last time a request succeeded
  DateTime? get lastSuccessfulRequest => _lastSuccessfulRequest;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize the connection manager
  void initialize() {
    // Start health checks
    _startHealthChecks();

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        if (data.session == null) {
          _setStatus(ConnectionStatus.authRequired);
        } else {
          _setStatus(ConnectionStatus.connected);
        }
      }
    });

    debugPrint('ConnectionManager: Initialized');
  }

  /// Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    _statusController.close();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Report a successful request
  void reportSuccess() {
    _lastSuccessfulRequest = DateTime.now();
    _consecutiveFailures = 0;

    if (_currentStatus != ConnectionStatus.connected) {
      _setStatus(ConnectionStatus.connected);
      debugPrint('ConnectionManager: Connection restored');
    }
  }

  /// Report a failed request
  void reportFailure(dynamic error) {
    _consecutiveFailures++;

    // Check if it's an auth error
    if (_isAuthError(error)) {
      _setStatus(ConnectionStatus.authRequired);
      return;
    }

    // Check if it's a network error
    if (_isNetworkError(error)) {
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _setStatus(ConnectionStatus.disconnected);
        _startReconnection();
      }
    }
  }

  void _setStatus(ConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      debugPrint('ConnectionManager: Status changed to $status');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  void _startHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  Future<void> _performHealthCheck() async {
    if (_currentStatus == ConnectionStatus.authRequired) {
      return; // Don't health check if auth is needed
    }

    try {
      // Simple query to check connectivity
      await _supabase.from('profiles').select('id').limit(1).maybeSingle();
      reportSuccess();
    } catch (e) {
      debugPrint('ConnectionManager: Health check failed - $e');
      reportFailure(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECONNECTION
  // ═══════════════════════════════════════════════════════════════════════════

  void _startReconnection() {
    if (_reconnectTimer?.isActive ?? false) return;

    _setStatus(ConnectionStatus.connecting);

    // Exponential backoff reconnection
    int attempt = 0;
    const maxAttempts = 10;
    const baseDelay = Duration(seconds: 2);

    void attemptReconnect() {
      attempt++;
      if (attempt > maxAttempts) {
        debugPrint('ConnectionManager: Max reconnect attempts reached');
        _setStatus(ConnectionStatus.disconnected);
        return;
      }

      final delay = Duration(
        milliseconds: (baseDelay.inMilliseconds * (1 << (attempt - 1))).clamp(0, 60000),
      );

      debugPrint('ConnectionManager: Reconnect attempt $attempt in ${delay.inSeconds}s');

      _reconnectTimer = Timer(delay, () async {
        try {
          await _supabase.from('profiles').select('id').limit(1).maybeSingle();
          reportSuccess();
          debugPrint('ConnectionManager: Reconnected successfully');
        } catch (e) {
          attemptReconnect();
        }
      });
    }

    attemptReconnect();
  }

  /// Manually trigger a reconnection attempt
  Future<bool> reconnect() async {
    _setStatus(ConnectionStatus.connecting);
    _consecutiveFailures = 0;

    try {
      await _supabase.from('profiles').select('id').limit(1).maybeSingle();
      reportSuccess();
      return true;
    } catch (e) {
      reportFailure(e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isAuthError(dynamic error) {
    if (error is AuthException) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('jwt') ||
        errorString.contains('token') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401');
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OFFLINE QUEUE
// ═══════════════════════════════════════════════════════════════════════════

/// Queues operations for execution when connection is restored
class OfflineQueue {
  static OfflineQueue? _instance;
  static OfflineQueue get instance => _instance ??= OfflineQueue._();

  OfflineQueue._();

  final List<_QueuedOperation> _queue = [];
  bool _isProcessing = false;

  /// Add an operation to the queue
  void enqueue({
    required String id,
    required Future<void> Function() operation,
    String? description,
    DateTime? expiresAt,
  }) {
    // Remove duplicate if exists
    _queue.removeWhere((op) => op.id == id);

    _queue.add(_QueuedOperation(
      id: id,
      operation: operation,
      description: description,
      enqueuedAt: DateTime.now(),
      expiresAt: expiresAt,
    ));

    debugPrint('OfflineQueue: Enqueued operation $id (${_queue.length} pending)');
  }

  /// Number of pending operations
  int get pendingCount => _queue.length;

  /// Whether there are pending operations
  bool get hasPending => _queue.isNotEmpty;

  /// Process the queue when connection is restored
  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    if (!ConnectionManager.instance.isConnected) return;

    _isProcessing = true;
    debugPrint('OfflineQueue: Processing ${_queue.length} operations');

    final now = DateTime.now();
    final toProcess = List<_QueuedOperation>.from(_queue);

    for (final operation in toProcess) {
      // Skip expired operations
      if (operation.expiresAt != null && now.isAfter(operation.expiresAt!)) {
        _queue.remove(operation);
        debugPrint('OfflineQueue: Skipped expired operation ${operation.id}');
        continue;
      }

      try {
        await operation.operation();
        _queue.remove(operation);
        debugPrint('OfflineQueue: Completed ${operation.id}');
      } catch (e) {
        debugPrint('OfflineQueue: Failed ${operation.id} - $e');
        // Keep in queue for retry unless it's a permanent error
        if (!_isRetryableError(e)) {
          _queue.remove(operation);
        }
      }
    }

    _isProcessing = false;
    debugPrint('OfflineQueue: Processing complete (${_queue.length} remaining)');
  }

  /// Clear all pending operations
  void clear() {
    _queue.clear();
    debugPrint('OfflineQueue: Cleared');
  }

  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }
}

class _QueuedOperation {
  final String id;
  final Future<void> Function() operation;
  final String? description;
  final DateTime enqueuedAt;
  final DateTime? expiresAt;

  _QueuedOperation({
    required this.id,
    required this.operation,
    this.description,
    required this.enqueuedAt,
    this.expiresAt,
  });
}
