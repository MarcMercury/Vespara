import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// RATE LIMITER
/// Client-side rate limiting with server-side verification
/// 
/// PHASE 6: Prevents API abuse at scale
/// ════════════════════════════════════════════════════════════════════════════

/// Rate limit configuration for different actions
enum RateLimitAction {
  apiCall(limit: 100, windowMinutes: 60),
  search(limit: 30, windowMinutes: 60),
  message(limit: 50, windowMinutes: 60),
  matchAction(limit: 100, windowMinutes: 60),
  tonightModeToggle(limit: 10, windowMinutes: 60),
  feedRefresh(limit: 5, windowMinutes: 60);

  final int limit;
  final int windowMinutes;

  const RateLimitAction({required this.limit, required this.windowMinutes});
}

class RateLimiter {
  final SupabaseClient _supabase;
  
  // Local cache for rate limits (reduces DB calls)
  final Map<String, _LocalRateLimit> _localLimits = {};

  RateLimiter(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Check if action is allowed (client-side check first, then server)
  Future<bool> checkLimit(RateLimitAction action) async {
    if (_userId == null) return true; // Allow if not authenticated
    
    final key = '${_userId}_${action.name}';
    
    // Client-side check first (fast path)
    final localLimit = _localLimits[key];
    if (localLimit != null && localLimit.isValid) {
      if (localLimit.count >= action.limit) {
        return false; // Rate limited
      }
      localLimit.count++;
      return true;
    }
    
    // Server-side check (authoritative)
    try {
      final result = await _supabase.rpc('check_rate_limit', params: {
        'p_user_id': _userId,
        'p_action_type': action.name,
        'p_limit': action.limit,
        'p_window_minutes': action.windowMinutes,
      });
      
      final allowed = result == true;
      
      // Update local cache
      _localLimits[key] = _LocalRateLimit(
        count: allowed ? 1 : action.limit,
        windowEnd: DateTime.now().add(Duration(minutes: action.windowMinutes)),
      );
      
      return allowed;
    } catch (e) {
      // If rate limit check fails, allow the action (fail open)
      return true;
    }
  }

  /// Get remaining requests for an action
  Future<int> getRemainingRequests(RateLimitAction action) async {
    if (_userId == null) return action.limit;
    
    final key = '${_userId}_${action.name}';
    final localLimit = _localLimits[key];
    
    if (localLimit != null && localLimit.isValid) {
      return (action.limit - localLimit.count).clamp(0, action.limit);
    }
    
    return action.limit;
  }

  /// Reset local rate limit cache
  void resetCache() {
    _localLimits.clear();
  }
}

class _LocalRateLimit {
  int count;
  final DateTime windowEnd;

  _LocalRateLimit({required this.count, required this.windowEnd});

  bool get isValid => DateTime.now().isBefore(windowEnd);
}

/// Rate limit exception
class RateLimitException implements Exception {
  final RateLimitAction action;
  final int retryAfterSeconds;

  RateLimitException(this.action, this.retryAfterSeconds);

  @override
  String toString() =>
      'Rate limit exceeded for ${action.name}. Retry after $retryAfterSeconds seconds.';
}
