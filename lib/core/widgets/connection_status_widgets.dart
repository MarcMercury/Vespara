import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/infrastructure_providers.dart';
import '../services/connection_manager.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CONNECTION STATUS WIDGETS
/// ════════════════════════════════════════════════════════════════════════════
///
/// UI components for displaying connection and system health status

// ═══════════════════════════════════════════════════════════════════════════
// CONNECTION BANNER
// ═══════════════════════════════════════════════════════════════════════════

/// Banner that appears when connection is lost
class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);

    return status.when(
      data: (connectionStatus) {
        if (connectionStatus == ConnectionStatus.connected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Material(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _getBannerColor(connectionStatus),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(
                      _getBannerIcon(connectionStatus),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getBannerMessage(connectionStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (connectionStatus == ConnectionStatus.disconnected)
                      TextButton(
                        onPressed: () {
                          ConnectionManager.instance.reconnect();
                        },
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getBannerColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.red;
      case ConnectionStatus.authRequired:
        return Colors.purple;
    }
  }

  IconData _getBannerIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.connecting:
        return Icons.cloud_sync;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ConnectionStatus.authRequired:
        return Icons.lock_outline;
    }
  }

  String _getBannerMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'No connection. Changes will sync when back online.';
      case ConnectionStatus.authRequired:
        return 'Session expired. Please sign in again.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OFFLINE INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

/// Small indicator showing pending sync operations
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOps = ref.watch(pendingOperationsProvider);

    if (pendingOps == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$pendingOps pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM HEALTH INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

/// Compact system health indicator for app bars
class SystemHealthIndicator extends ConsumerWidget {
  final bool showDetails;

  const SystemHealthIndicator({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(systemHealthProvider);

    return GestureDetector(
      onTap: showDetails
          ? () => _showHealthDetails(context, health)
          : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: health.isHealthy
                    ? Colors.green
                    : health.hasWarnings
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 8),
              Text(
                health.statusMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHealthDetails(BuildContext context, SystemHealth health) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _HealthRow(
              icon: health.isConnected ? Icons.cloud_done : Icons.cloud_off,
              label: 'Connection',
              value: health.connectionStatus.name,
              color: health.isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            _HealthRow(
              icon: Icons.sync,
              label: 'Pending Operations',
              value: health.pendingOperations.toString(),
              color: health.pendingOperations == 0 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            _HealthRow(
              icon: Icons.auto_awesome,
              label: 'AI Budget',
              value: '${health.aiTokensRemaining} tokens',
              color: health.aiTokensRemaining > 10000 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HealthRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RETRY WRAPPER
// ═══════════════════════════════════════════════════════════════════════════

/// Widget that shows error state with retry button
class RetryableContent extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final Widget? icon;

  const RetryableContent({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that wraps AsyncValue with proper loading/error states
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: loading ?? () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        if (error != null) {
          return error!(e, st);
        }

        if (onRetry != null) {
          return RetryableContent(
            errorMessage: e.toString(),
            onRetry: onRetry!,
          );
        }

        return Center(
          child: Text('Error: $e'),
        );
      },
    );
  }
}
