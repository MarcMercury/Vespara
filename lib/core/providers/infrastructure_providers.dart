import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connection_manager.dart';
import '../services/ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// INFRASTRUCTURE PROVIDERS
/// ════════════════════════════════════════════════════════════════════════════
///
/// Centralized providers for infrastructure services

// ═══════════════════════════════════════════════════════════════════════════
// CONNECTION MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

/// Connection manager singleton
final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  return ConnectionManager.instance;
});

/// Current connection status stream
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.statusStream;
});

/// Offline queue singleton
final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return OfflineQueue.instance;
});

/// Pending offline operations count
final pendingOperationsProvider = Provider<int>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return queue.pendingCount;
});

/// Whether we're currently connected
final isConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(connectionStatusProvider);
  return status.maybeWhen(
    data: (s) => s == ConnectionStatus.connected,
    orElse: () => true, // Assume connected until proven otherwise
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// AI SERVICE
// ═══════════════════════════════════════════════════════════════════════════

/// AI service singleton
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService.instance;
});

/// Remaining AI token budget
final aiTokenBudgetProvider = Provider<int>((ref) {
  final service = ref.watch(aiServiceProvider);
  return service.remainingBudget;
});

/// Total tokens used this session
final aiTokensUsedProvider = Provider<int>((ref) {
  final service = ref.watch(aiServiceProvider);
  return service.totalTokensUsed;
});

// ═══════════════════════════════════════════════════════════════════════════
// HELPER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Combined system health check
final systemHealthProvider = Provider<SystemHealth>((ref) {
  final connectionStatus = ref.watch(connectionStatusProvider);
  final pendingOps = ref.watch(pendingOperationsProvider);
  final tokenBudget = ref.watch(aiTokenBudgetProvider);

  final isConnected = connectionStatus.maybeWhen(
    data: (s) => s == ConnectionStatus.connected,
    orElse: () => true,
  );

  return SystemHealth(
    isConnected: isConnected,
    pendingOperations: pendingOps,
    aiTokensRemaining: tokenBudget,
    connectionStatus: connectionStatus.valueOrNull ?? ConnectionStatus.connected,
  );
});

/// System health data class
class SystemHealth {
  final bool isConnected;
  final int pendingOperations;
  final int aiTokensRemaining;
  final ConnectionStatus connectionStatus;

  const SystemHealth({
    required this.isConnected,
    required this.pendingOperations,
    required this.aiTokensRemaining,
    required this.connectionStatus,
  });

  bool get isHealthy => isConnected && pendingOperations == 0;
  bool get hasWarnings => !isConnected || pendingOperations > 0 || aiTokensRemaining < 10000;

  String get statusMessage {
    if (!isConnected) return 'No connection';
    if (pendingOperations > 0) return '$pendingOperations pending sync';
    if (aiTokensRemaining < 10000) return 'Low AI budget';
    return 'All systems operational';
  }
}
