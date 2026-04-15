import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Centralized cache for Supabase Edge Function responses.
///
/// Reduces invocations by:
///  - Caching responses with a configurable TTL
///  - Deduplicating in-flight requests (same key returns same Future)
///  - Providing a simple invalidation API
class EdgeFunctionCache {
  EdgeFunctionCache._();
  static final EdgeFunctionCache instance = EdgeFunctionCache._();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  /// Execute [fetcher] with caching. Identical [cacheKey] calls within [ttl]
  /// return the cached result. Concurrent calls with the same key are
  /// deduplicated (only one edge function invocation fires).
  Future<T> cached<T>({
    required String cacheKey,
    required Future<T> Function() fetcher,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    // Check cache
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      debugPrint('EdgeFunctionCache: HIT  $cacheKey');
      return entry.value as T;
    }

    // Deduplicate in-flight requests
    if (_inFlight.containsKey(cacheKey)) {
      debugPrint('EdgeFunctionCache: DEDUP $cacheKey');
      return await _inFlight[cacheKey] as T;
    }

    debugPrint('EdgeFunctionCache: MISS $cacheKey');
    final future = fetcher();
    _inFlight[cacheKey] = future;

    try {
      final result = await future;
      _cache[cacheKey] = _CacheEntry(value: result, ttl: ttl);
      return result;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  /// Invalidate a single cache entry
  void invalidate(String cacheKey) {
    _cache.remove(cacheKey);
  }

  /// Invalidate all entries matching a prefix (e.g. 'tonight-mode')
  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear entire cache (call on sign-out)
  void clearAll() {
    _cache.clear();
    debugPrint('EdgeFunctionCache: cleared all');
  }

  /// Build a deterministic cache key from function name + params
  static String key(String functionName, [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) return functionName;
    final sorted = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return '$functionName:${jsonEncode(sorted)}';
  }
}

class _CacheEntry {
  _CacheEntry({required this.value, required Duration ttl})
      : expiresAt = DateTime.now().add(ttl);

  final dynamic value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
