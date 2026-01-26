import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/analytics.dart';
import '../domain/models/conversation.dart';
import '../domain/models/roster_match.dart';
import '../domain/models/tags_game.dart';

/// Supabase Service for all database operations
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static User? get currentUser => _client.auth.currentUser;

  // ============================================
  // AUTH
  // ============================================

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async =>
      _client.auth.signUp(
        email: email,
        password: password,
      );

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async =>
      _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ============================================
  // PROFILE
  // ============================================

  static Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();

    return response;
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    await _client.from('profiles').update(data).eq('id', currentUser!.id);
  }

  // ============================================
  // ROSTER MATCHES
  // ============================================

  static Future<List<RosterMatch>> getMatches() async {
    if (currentUser == null) return [];

    final response = await _client
        .from('roster_matches')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('is_archived', false)
        .order('momentum_score', ascending: false);

    return (response as List).map((m) => RosterMatch.fromJson(m)).toList();
  }

  static Future<List<RosterMatch>> getMatchesByPipeline(String pipeline) async {
    if (currentUser == null) return [];

    final response = await _client
        .from('roster_matches')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('pipeline', pipeline)
        .eq('is_archived', false)
        .order('momentum_score', ascending: false);

    return (response as List).map((m) => RosterMatch.fromJson(m)).toList();
  }

  static Future<List<RosterMatch>> getStaleMatches(
      {int daysSinceContact = 7}) async {
    if (currentUser == null) return [];

    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysSinceContact))
        .toIso8601String();

    final response = await _client
        .from('roster_matches')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('is_archived', false)
        .lt('last_contact_date', cutoffDate)
        .order('last_contact_date', ascending: true);

    return (response as List).map((m) => RosterMatch.fromJson(m)).toList();
  }

  static Future<RosterMatch> createMatch(RosterMatch match) async {
    final response = await _client
        .from('roster_matches')
        .insert(match.toJson()..['user_id'] = currentUser!.id)
        .select()
        .single();

    return RosterMatch.fromJson(response);
  }

  static Future<void> updateMatch(String id, Map<String, dynamic> data) async {
    await _client
        .from('roster_matches')
        .update(data)
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  static Future<void> updateMatchPipeline(String id, String pipeline) async {
    await _client
        .from('roster_matches')
        .update({'pipeline': pipeline})
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  static Future<void> archiveMatch(String id, {String? reason}) async {
    await _client
        .from('roster_matches')
        .update({
          'is_archived': true,
          'archived_at': DateTime.now().toIso8601String(),
          'archive_reason': reason,
        })
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  // ============================================
  // CONVERSATIONS
  // ============================================

  static Future<List<Conversation>> getConversations() async {
    if (currentUser == null) return [];

    final response = await _client
        .from('conversations')
        .select('''
          *,
          roster_matches (name, avatar_url)
        ''')
        .eq('user_id', currentUser!.id)
        .order('momentum_score', ascending: false);

    return (response as List).map((c) => Conversation.fromJson(c)).toList();
  }

  static Future<List<Conversation>> getStaleConversations() async {
    if (currentUser == null) return [];

    final response = await _client
        .from('conversations')
        .select('''
          *,
          roster_matches (name, avatar_url)
        ''')
        .eq('user_id', currentUser!.id)
        .eq('is_stale', true)
        .order('stale_since', ascending: true);

    return (response as List).map((c) => Conversation.fromJson(c)).toList();
  }

  // ============================================
  // TAGS GAMES
  // ============================================

  static Future<List<TagsGame>> getGames({String? category}) async {
    var query = _client.from('tags_games').select();

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('play_count', ascending: false);

    return (response as List).map((g) => TagsGame.fromJson(g)).toList();
  }

  static Future<void> incrementPlayCount(String gameId) async {
    await _client.rpc('increment_play_count', params: {'game_id': gameId});
  }

  static Future<String> createGameSession({
    required String gameId,
    required String consentLevel,
    String? matchId,
  }) async {
    final response = await _client
        .from('game_sessions')
        .insert({
          'game_id': gameId,
          'host_id': currentUser!.id,
          'match_id': matchId,
          'consent_level': consentLevel,
        })
        .select('id')
        .single();

    return response['id'];
  }

  // ============================================
  // ANALYTICS
  // ============================================

  static Future<UserAnalytics?> getAnalytics() async {
    if (currentUser == null) return null;

    final response = await _client
        .from('user_analytics')
        .select()
        .eq('user_id', currentUser!.id)
        .single();

    return UserAnalytics.fromJson(response);
  }

  static Future<void> updateAnalytics(Map<String, dynamic> data) async {
    await _client
        .from('user_analytics')
        .update(data)
        .eq('user_id', currentUser!.id);
  }

  // ============================================
  // VOUCH CHAIN
  // ============================================

  static Future<int> getVouchCount() async {
    if (currentUser == null) return 0;

    final response = await _client
        .from('vouches')
        .select('id')
        .eq('vouchee_id', currentUser!.id);

    return (response as List).length;
  }

  static Future<List<Map<String, dynamic>>> getVouches() async {
    if (currentUser == null) return [];

    final response = await _client.from('vouches').select('''
          *,
          voucher:voucher_id (display_name, avatar_url)
        ''').eq('vouchee_id', currentUser!.id);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // SHREDDER ARCHIVE
  // ============================================

  static Future<void> recordShredder({
    required String matchName,
    required String? matchSource,
    required String? closureMessage,
    required bool messageSent,
    required String tone,
  }) async {
    await _client.from('shredder_archive').insert({
      'user_id': currentUser!.id,
      'match_name': matchName,
      'match_source': matchSource,
      'closure_message': closureMessage,
      'message_sent': messageSent,
      'tone': tone,
    });
  }

  // ============================================
  // EDGE FUNCTIONS
  // ============================================

  static Future<String> callStrategist({
    required String matchName,
    required String matchContext,
    required String userQuestion,
    String? conversationHistory,
  }) async {
    final response = await _client.functions.invoke(
      'strategist',
      body: {
        'matchName': matchName,
        'matchContext': matchContext,
        'userQuestion': userQuestion,
        'conversationHistory': conversationHistory,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Strategist error');
    }

    return response.data['advice'];
  }

  static Future<String> callGhostProtocol({
    required String matchName,
    required String tone,
    required int duration,
    String? context,
  }) async {
    final response = await _client.functions.invoke(
      'ghost-protocol',
      body: {
        'matchName': matchName,
        'tone': tone,
        'duration': duration,
        'context': context,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Ghost Protocol error');
    }

    return response.data['message'];
  }

  static Future<String> callResuscitator({
    required String matchName,
    required String lastMessages,
    String? matchInterests,
    required int daysSinceContact,
  }) async {
    final response = await _client.functions.invoke(
      'resuscitator',
      body: {
        'matchName': matchName,
        'lastMessages': lastMessages,
        'matchInterests': matchInterests,
        'daysSinceContact': daysSinceContact,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Resuscitator error');
    }

    return response.data['message'];
  }

  static Future<Map<String, dynamic>> generateVouchLink() async {
    final response = await _client.functions.invoke(
      'vouch-chain',
      queryParameters: {'action': 'generate'},
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Vouch link error');
    }

    return response.data;
  }

  static Future<void> redeemVouchLink(String code) async {
    final response = await _client.functions.invoke(
      'vouch-chain',
      queryParameters: {'action': 'redeem'},
      body: {'code': code},
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Vouch redeem error');
    }
  }

  static Future<void> tonightCheckIn({
    required double lat,
    required double lng,
    String? venueName,
    String? venueType,
  }) async {
    final response = await _client.functions.invoke(
      'tonight-mode',
      queryParameters: {'action': 'checkin'},
      body: {
        'lat': lat,
        'lng': lng,
        'venueName': venueName,
        'venueType': venueType,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Check-in error');
    }
  }

  static Future<void> tonightCheckOut() async {
    await _client.functions.invoke(
      'tonight-mode',
      queryParameters: {'action': 'checkout'},
    );
  }

  static Future<List<Map<String, dynamic>>> tonightNearby({
    required double lat,
    required double lng,
    double radiusKm = 1.0,
  }) async {
    final response = await _client.functions.invoke(
      'tonight-mode',
      queryParameters: {'action': 'nearby'},
      body: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Nearby error');
    }

    return List<Map<String, dynamic>>.from(response.data['nearby'] ?? []);
  }
}
