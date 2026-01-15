import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/roster_match.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ROSTER REPOSITORY
/// Handles all CRM/Roster data operations with real-time subscriptions
/// ════════════════════════════════════════════════════════════════════════════

class RosterRepository {
  final SupabaseClient _supabase;

  RosterRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // REAL-TIME STREAMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Real-time stream of all matches for the current user
  /// Used by Tile 3 (The Roster) Kanban board
  Stream<List<RosterMatch>> watchMatches() {
    if (_userId == null) return Stream.value([]);

    return _supabase
        .from('roster_matches')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('momentum_score', ascending: false)
        .map((data) => data.map((json) => RosterMatch.fromJson(json)).toList());
  }

  /// Stream of matches filtered by pipeline stage
  Stream<List<RosterMatch>> watchMatchesByStage(String stage) {
    if (_userId == null) return Stream.value([]);

    return _supabase
        .from('roster_matches')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .map((data) => data
            .where((json) => json['pipeline_stage'] == stage || json['stage'] == stage)
            .map((json) => RosterMatch.fromJson(json))
            .toList());
  }

  /// Stream of nearby matches (for Tonight Mode)
  Stream<List<RosterMatch>> watchNearbyMatches() {
    if (_userId == null) return Stream.value([]);

    return _supabase
        .from('roster_matches')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .map((data) => data
            .where((json) => json['is_nearby'] == true)
            .map((json) => RosterMatch.fromJson(json))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch all matches (non-realtime)
  Future<List<RosterMatch>> fetchMatches() async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('roster_matches')
        .select()
        .eq('user_id', _userId!)
        .order('momentum_score', ascending: false);

    return (response as List)
        .map((json) => RosterMatch.fromJson(json))
        .toList();
  }

  /// Get a single match by ID
  Future<RosterMatch?> getMatch(String matchId) async {
    final response = await _supabase
        .from('roster_matches')
        .select()
        .eq('id', matchId)
        .maybeSingle();

    if (response == null) return null;
    return RosterMatch.fromJson(response);
  }

  /// Create a new match
  Future<RosterMatch> createMatch({
    required String name,
    String? nickname,
    String? avatarUrl,
    String? source,
    String? sourceUsername,
    String stage = 'incoming',
    String? notes,
    List<String>? interests,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': _userId,
      'name': name,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'source': source,
      'source_username': sourceUsername,
      'stage': stage,
      'pipeline_stage': stage,
      'notes': notes,
      'interests': interests ?? [],
      'momentum_score': 0.5,
    };

    final response = await _supabase
        .from('roster_matches')
        .insert(data)
        .select()
        .single();

    return RosterMatch.fromJson(response);
  }

  /// Update match status/stage (for Kanban drag-and-drop)
  /// This is the critical function for Tile 3 interactions
  Future<bool> updateMatchStatus(String matchId, String newStatus) async {
    if (_userId == null) return false;

    try {
      // Use the database function for atomic update
      final result = await _supabase.rpc('update_match_stage', params: {
        'p_match_id': matchId,
        'p_new_stage': newStatus,
        'p_user_id': _userId,
      });

      return result == true;
    } catch (e) {
      // Fallback to direct update
      await _supabase
          .from('roster_matches')
          .update({
            'stage': newStatus,
            'pipeline_stage': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
            'last_interaction': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId)
          .eq('user_id', _userId!);
      return true;
    }
  }

  /// Update match momentum score
  Future<void> updateMomentum(String matchId, double score) async {
    await _supabase
        .from('roster_matches')
        .update({
          'momentum_score': score,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);
  }

  /// Update match details
  Future<void> updateMatch(String matchId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    
    await _supabase
        .from('roster_matches')
        .update(data)
        .eq('id', matchId);
  }

  /// Archive a match (move to Shredder)
  Future<void> archiveMatch(String matchId, {String? reason}) async {
    await _supabase
        .from('roster_matches')
        .update({
          'is_archived': true,
          'archived_at': DateTime.now().toIso8601String(),
          'archive_reason': reason,
          'pipeline_stage': 'archived',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);
  }

  /// Delete a match permanently
  Future<void> deleteMatch(String matchId) async {
    await _supabase
        .from('roster_matches')
        .delete()
        .eq('id', matchId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS & AGGREGATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get stale matches (for The Shredder - Tile 5)
  Future<List<RosterMatch>> getStaleMatches({int staleDays = 14}) async {
    if (_userId == null) return [];

    final staleDate = DateTime.now().subtract(Duration(days: staleDays));

    final response = await _supabase
        .from('roster_matches')
        .select()
        .eq('user_id', _userId!)
        .eq('is_archived', false)
        .lt('last_interaction', staleDate.toIso8601String())
        .order('last_interaction', ascending: true);

    return (response as List)
        .map((json) => RosterMatch.fromJson(json))
        .toList();
  }

  /// Get match counts by pipeline stage
  Future<Map<String, int>> getMatchCountsByStage() async {
    if (_userId == null) return {};

    final response = await _supabase
        .from('roster_matches')
        .select('pipeline_stage')
        .eq('user_id', _userId!)
        .eq('is_archived', false);

    final counts = <String, int>{};
    for (final row in response as List) {
      final stage = row['pipeline_stage'] as String? ?? 'incoming';
      counts[stage] = (counts[stage] ?? 0) + 1;
    }
    return counts;
  }
}

/// Provider for RosterRepository
final rosterRepositoryProvider = Provider<RosterRepository>((ref) {
  return RosterRepository(Supabase.instance.client);
});

/// Real-time stream of all matches
final matchesStreamProvider = StreamProvider<List<RosterMatch>>((ref) {
  return ref.watch(rosterRepositoryProvider).watchMatches();
});

/// Matches grouped by pipeline stage (derived from stream)
final pipelineMatchesStreamProvider = Provider<Map<PipelineStage, List<RosterMatch>>>((ref) {
  final matches = ref.watch(matchesStreamProvider).valueOrNull ?? [];

  return {
    PipelineStage.incoming: matches.where((m) => 
        m.stage == PipelineStage.incoming || _stageMatches(m, 'incoming')).toList(),
    PipelineStage.bench: matches.where((m) => 
        m.stage == PipelineStage.bench || _stageMatches(m, 'bench')).toList(),
    PipelineStage.activeRotation: matches.where((m) => 
        m.stage == PipelineStage.activeRotation || _stageMatches(m, 'active')).toList(),
    PipelineStage.legacy: matches.where((m) => 
        m.stage == PipelineStage.legacy || _stageMatches(m, 'legacy')).toList(),
  };
});

bool _stageMatches(RosterMatch match, String stageName) {
  // Helper to match stage by name from database
  return match.stage.name.toLowerCase() == stageName.toLowerCase();
}

/// Stale matches stream for The Shredder
final staleMatchesStreamProvider = FutureProvider<List<RosterMatch>>((ref) async {
  return ref.watch(rosterRepositoryProvider).getStaleMatches();
});
