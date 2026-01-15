import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// STRATEGIST REPOSITORY
/// Handles Tonight Mode, location services, and AI strategist operations
/// 
/// PHASE 6: Geohash sharding for scalability (1M+ users)
/// - Uses geohash_5 (~5km cells) for realtime subscriptions
/// - Prevents global broadcast DDoS
/// ════════════════════════════════════════════════════════════════════════════

/// Geohash calculator for client-side sharding
class GeohashUtils {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  
  /// Calculate geohash from lat/lng at given precision
  /// Precision: 4 = ~39km, 5 = ~5km, 6 = ~1.2km
  static String encode(double latitude, double longitude, {int precision = 5}) {
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    bool isLng = true;
    int bit = 0;
    int ch = 0;
    String geohash = '';
    
    while (geohash.length < precision) {
      if (isLng) {
        final mid = (lngMin + lngMax) / 2;
        if (longitude >= mid) {
          ch |= (16 >> bit);
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= (16 >> bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      
      isLng = !isLng;
      bit++;
      
      if (bit == 5) {
        geohash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    
    return geohash;
  }
  
  /// Get neighboring geohashes for broader search
  static List<String> getNeighbors(String geohash) {
    // For simplicity, return the geohash and its 8 neighbors
    // In production, implement proper neighbor calculation
    return [geohash];
  }
}

class StrategistRepository {
  final SupabaseClient _supabase;
  RealtimeChannel? _tonightModeChannel;
  String? _currentGeohash;

  StrategistRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // TONIGHT MODE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Toggle Tonight Mode with location update
  Future<bool> toggleTonightMode(bool enabled) async {
    if (_userId == null) return false;

    if (enabled) {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) return false;

      // Use database function to update atomically
      try {
        final result = await _supabase.rpc('toggle_tonight_mode', params: {
          'p_user_id': _userId,
          'p_enabled': true,
          'p_lat': position.latitude,
          'p_lng': position.longitude,
        });
        return result == true;
      } catch (e) {
        // Fallback to direct update
        await _supabase
            .from('profiles')
            .update({
              'current_status': 'tonight_mode',
              'location_updated_at': DateTime.now().toIso8601String(),
              'is_visible': true,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _userId!);
        return true;
      }
    } else {
      // Disable Tonight Mode
      await _supabase
          .from('profiles')
          .update({
            'current_status': 'active',
            'is_visible': true,
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _userId!);
      return true;
    }
  }

  /// Get current device location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Update user location (for continuous tracking)
  Future<void> updateLocation() async {
    if (_userId == null) return;

    final position = await _getCurrentLocation();
    if (position == null) return;

    await _supabase.rpc('toggle_tonight_mode', params: {
      'p_user_id': _userId,
      'p_enabled': true,
      'p_lat': position.latitude,
      'p_lng': position.longitude,
    }).catchError((_) {
      // Silently fail if function doesn't exist
      return null;
    });
  }

  /// Get nearby users in Tonight Mode
  /// PHASE 6: Uses geohash sharding instead of global query
  Future<List<Map<String, dynamic>>> getNearbyUsers({double radiusKm = 10}) async {
    if (_userId == null) return [];

    try {
      // First try the database function (uses PostGIS)
      final response = await _supabase.rpc('get_nearby_users', params: {
        'user_id': _userId,
        'radius_km': radiusKm,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      // Fallback: Use geohash-based query (more scalable)
      if (_currentGeohash == null) return [];
      
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, geohash_5')
          .eq('geohash_5', _currentGeohash!)
          .eq('current_status', 'tonight_mode')
          .eq('is_visible', true)
          .neq('id', _userId!)
          .order('last_active_at', ascending: false)
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    }
  }
  
  /// Subscribe to nearby Tonight Mode users via geohash channel
  /// PHASE 6: Geohash sharding prevents global broadcast DDoS
  Stream<List<Map<String, dynamic>>> watchNearbyUsers() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    _subscribeToGeohashChannel(controller);
    
    // Also emit initial data
    getNearbyUsers().then((users) {
      if (!controller.isClosed) {
        controller.add(users);
      }
    });
    
    return controller.stream;
  }
  
  Future<void> _subscribeToGeohashChannel(
    StreamController<List<Map<String, dynamic>>> controller,
  ) async {
    // Get current position and calculate geohash
    final position = await _getCurrentLocation();
    if (position == null) return;
    
    _currentGeohash = GeohashUtils.encode(
      position.latitude, 
      position.longitude,
      precision: 5, // ~5km cells
    );
    
    // Unsubscribe from previous channel
    await _tonightModeChannel?.unsubscribe();
    
    // Subscribe to geohash-specific channel
    // Only users in the same ~5km cell will receive updates
    _tonightModeChannel = _supabase
        .channel('tonight_mode:$_currentGeohash')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'geohash_5',
            value: _currentGeohash,
          ),
          callback: (payload) async {
            // Refresh nearby users when someone in our cell updates
            final users = await getNearbyUsers();
            if (!controller.isClosed) {
              controller.add(users);
            }
          },
        )
        .subscribe();
  }
  
  /// Cleanup realtime subscription
  Future<void> dispose() async {
    await _tonightModeChannel?.unsubscribe();
    _tonightModeChannel = null;
  }

  /// Check if Tonight Mode is enabled
  Future<bool> isTonightModeEnabled() async {
    if (_userId == null) return false;

    final response = await _supabase
        .from('profiles')
        .select('current_status')
        .eq('id', _userId!)
        .maybeSingle();

    return response?['current_status'] == 'tonight_mode';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI STRATEGIST
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send message to Strategist AI
  Future<String> askStrategist(String message) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'strategist',
      body: {
        'message': message,
        'userId': _userId,
      },
    );

    if (response.data != null && response.data['response'] != null) {
      return response.data['response'] as String;
    }

    throw Exception('Failed to get response from Strategist');
  }

  /// Get strategist chat history
  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('strategist_logs')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get optimization suggestions
  Future<Map<String, dynamic>> getOptimizationSuggestions() async {
    if (_userId == null) return {};

    final response = await _supabase.functions.invoke(
      'strategist',
      body: {
        'action': 'optimize',
        'userId': _userId,
      },
    );

    return response.data as Map<String, dynamic>? ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user optimization score
  Future<double> getOptimizationScore() async {
    if (_userId == null) return 0.0;

    final response = await _supabase
        .from('user_analytics')
        .select('optimization_score')
        .eq('user_id', _userId!)
        .maybeSingle();

    return (response?['optimization_score'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get ghost rate
  Future<double> getGhostRate() async {
    if (_userId == null) return 0.0;

    try {
      final result = await _supabase.rpc('calculate_ghost_rate', params: {
        'p_user_id': _userId,
      });
      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      final response = await _supabase
          .from('profiles')
          .select('ghost_rate')
          .eq('id', _userId!)
          .maybeSingle();
      return (response?['ghost_rate'] as num?)?.toDouble() ?? 0.0;
    }
  }
}

/// Provider for StrategistRepository
final strategistRepositoryProvider = Provider<StrategistRepository>((ref) {
  return StrategistRepository(Supabase.instance.client);
});

/// Tonight Mode state provider with persistence
final tonightModeStateProvider = StateNotifierProvider<TonightModeNotifier, bool>((ref) {
  return TonightModeNotifier(ref);
});

class TonightModeNotifier extends StateNotifier<bool> {
  final Ref _ref;

  TonightModeNotifier(this._ref) : super(false) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final isEnabled = await _ref.read(strategistRepositoryProvider).isTonightModeEnabled();
    state = isEnabled;
  }

  Future<bool> toggle() async {
    final newState = !state;
    final success = await _ref.read(strategistRepositoryProvider).toggleTonightMode(newState);
    if (success) {
      state = newState;
    }
    return success;
  }

  Future<void> enable() async {
    final success = await _ref.read(strategistRepositoryProvider).toggleTonightMode(true);
    if (success) state = true;
  }

  Future<void> disable() async {
    final success = await _ref.read(strategistRepositoryProvider).toggleTonightMode(false);
    if (success) state = false;
  }
}

/// Optimization score provider
final optimizationScoreProvider = FutureProvider<double>((ref) async {
  return ref.watch(strategistRepositoryProvider).getOptimizationScore();
});

/// Ghost rate provider
final ghostRateProvider = FutureProvider<double>((ref) async {
  return ref.watch(strategistRepositoryProvider).getGhostRate();
});

/// Nearby users provider (only active when Tonight Mode is ON)
final nearbyUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final isTonightMode = ref.watch(tonightModeStateProvider);
  if (!isTonightMode) return [];
  return ref.watch(strategistRepositoryProvider).getNearbyUsers();
});
