import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/chat.dart';
import '../domain/models/match.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// MATCH STATE PROVIDER
/// Global state management for matches, likes, and cross-module interactions
/// Handles: Discover -> Nest flow, Match -> Wire flow, Nest -> Planner flow
/// NOW CONNECTED TO SUPABASE for persistence!
/// ════════════════════════════════════════════════════════════════════════════

/// State class holding all match-related data
class MatchState {
  const MatchState({
    this.matches = const [],
    this.likedProfiles = const {},
    this.superLikedProfiles = const {},
    this.passedProfiles = const {},
    this.conversations = const {},
    this.newMatchCount = 0,
    this.isLoading = false,
    this.hasLoadedFromDb = false,
  });
  final List<Match> matches;
  final Set<String> likedProfiles; // Profiles the user has liked
  final Set<String> superLikedProfiles; // Profiles the user has super-liked
  final Set<String> passedProfiles; // Profiles the user has passed on
  final Map<String, ChatConversation>
      conversations; // Active conversations by match ID
  final int newMatchCount;
  final bool isLoading;
  final bool hasLoadedFromDb;

  MatchState copyWith({
    List<Match>? matches,
    Set<String>? likedProfiles,
    Set<String>? superLikedProfiles,
    Set<String>? passedProfiles,
    Map<String, ChatConversation>? conversations,
    int? newMatchCount,
    bool? isLoading,
    bool? hasLoadedFromDb,
  }) =>
      MatchState(
        matches: matches ?? this.matches,
        likedProfiles: likedProfiles ?? this.likedProfiles,
        superLikedProfiles: superLikedProfiles ?? this.superLikedProfiles,
        passedProfiles: passedProfiles ?? this.passedProfiles,
        conversations: conversations ?? this.conversations,
        newMatchCount: newMatchCount ?? this.newMatchCount,
        isLoading: isLoading ?? this.isLoading,
        hasLoadedFromDb: hasLoadedFromDb ?? this.hasLoadedFromDb,
      );

  /// Get matches by priority
  List<Match> getMatchesByPriority(MatchPriority priority) =>
      matches.where((m) => m.priority == priority && !m.isArchived).toList();

  /// Get new matches count
  int get newMatches => getMatchesByPriority(MatchPriority.new_).length;
}

/// Match state notifier for handling all match-related actions
/// Now persists to Supabase!
class MatchStateNotifier extends StateNotifier<MatchState> {
  MatchStateNotifier()
      : super(
          const MatchState(),
        ) {
    // Load data from database on initialization
    _loadFromDatabase();
  }

  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Load matches and swipes from database
  Future<void> _loadFromDatabase() async {
    if (_currentUserId == null) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Load existing swipes to populate liked/passed sets
      final swipesResponse = await _supabase
          .from('swipes')
          .select('swiped_id, direction')
          .eq('swiper_id', _currentUserId!);
      
      final liked = <String>{};
      final superLiked = <String>{};
      final passed = <String>{};
      
      for (final swipe in swipesResponse as List) {
        final swipedId = swipe['swiped_id'] as String;
        final direction = swipe['direction'] as String;
        
        if (direction == 'right') {
          liked.add(swipedId);
        } else if (direction == 'super') {
          superLiked.add(swipedId);
        } else if (direction == 'left') {
          passed.add(swipedId);
        }
      }
      
      // Load matches where this user is involved
      final matchesResponse = await _supabase
          .from('matches')
          .select('''
            *,
            user_a:profiles!matches_user_a_id_fkey(id, display_name, avatar_url),
            user_b:profiles!matches_user_b_id_fkey(id, display_name, avatar_url)
          ''')
          .or('user_a_id.eq.$_currentUserId,user_b_id.eq.$_currentUserId');
      
      final matches = <Match>[];
      final conversations = <String, ChatConversation>{};
      int newCount = 0;
      
      for (final matchData in matchesResponse as List) {
        final isUserA = matchData['user_a_id'] == _currentUserId;
        final otherUser = isUserA ? matchData['user_b'] : matchData['user_a'];
        final myPriority = isUserA 
            ? matchData['user_a_priority'] as String? 
            : matchData['user_b_priority'] as String?;
        final isArchived = isUserA 
            ? matchData['user_a_archived'] as bool? ?? false
            : matchData['user_b_archived'] as bool? ?? false;
        
        final priority = _priorityFromString(myPriority ?? 'new');
        if (priority == MatchPriority.new_) newCount++;
        
        final match = Match(
          id: matchData['id'] as String,
          matchedUserId: otherUser['id'] as String,
          matchedUserName: otherUser['display_name'] as String?,
          matchedUserAvatar: otherUser['avatar_url'] as String?,
          matchedAt: DateTime.parse(matchData['matched_at'] as String),
          compatibilityScore: (matchData['compatibility_score'] as num?)?.toDouble() ?? 0.75,
          conversationId: matchData['conversation_id'] as String?,
          isSuperMatch: matchData['is_super_match'] as bool? ?? false,
          priority: priority,
          isArchived: isArchived,
        );
        
        matches.add(match);
      }
      
      state = state.copyWith(
        matches: matches,
        likedProfiles: liked,
        superLikedProfiles: superLiked,
        passedProfiles: passed,
        conversations: conversations,
        newMatchCount: newCount,
        isLoading: false,
        hasLoadedFromDb: true,
      );
      
      debugPrint('MatchState: Loaded ${matches.length} matches, ${liked.length + superLiked.length} likes, ${passed.length} passes from DB');
    } catch (e) {
      debugPrint('MatchState: Error loading from database: $e');
      state = state.copyWith(isLoading: false, hasLoadedFromDb: true);
    }
  }

  /// Refresh data from database
  Future<void> refresh() => _loadFromDatabase();

  MatchPriority _priorityFromString(String priority) {
    switch (priority) {
      case 'priority':
        return MatchPriority.priority;
      case 'new':
        return MatchPriority.new_;
      case 'inWaiting':
        return MatchPriority.inWaiting;
      case 'onWayOut':
        return MatchPriority.onWayOut;
      case 'legacy':
        return MatchPriority.legacy;
      default:
        return MatchPriority.new_;
    }
  }

  String _priorityToString(MatchPriority priority) {
    switch (priority) {
      case MatchPriority.priority:
        return 'priority';
      case MatchPriority.new_:
        return 'new';
      case MatchPriority.inWaiting:
        return 'inWaiting';
      case MatchPriority.onWayOut:
        return 'onWayOut';
      case MatchPriority.legacy:
        return 'legacy';
    }
  }

  /// Like a profile from Discover - NOW WRITES TO DATABASE
  Future<void> likeProfile(String profileId, String profileName, String? avatarUrl) async {
    if (_currentUserId == null) return;
    
    // Optimistically add to liked set
    final newLiked = {...state.likedProfiles, profileId};
    state = state.copyWith(likedProfiles: newLiked);
    
    try {
      // Insert swipe into database - the trigger will check for mutual match
      await _supabase.from('swipes').upsert({
        'swiper_id': _currentUserId,
        'swiped_id': profileId,
        'direction': 'right',
        'is_from_strict': true,
      });
      
      debugPrint('MatchState: Recorded right swipe on $profileName');
      
      // Check if this created a match by refreshing from database
      await _loadFromDatabase();
    } catch (e) {
      debugPrint('MatchState: Error recording swipe: $e');
      // Revert optimistic update on error
      state = state.copyWith(
        likedProfiles: {...state.likedProfiles}..remove(profileId),
      );
    }
  }

  /// Super-like a profile - NOW WRITES TO DATABASE
  Future<void> superLikeProfile(String profileId, String profileName, String? avatarUrl) async {
    if (_currentUserId == null) return;
    
    // Optimistically add to super-liked set
    final newSuperLiked = {...state.superLikedProfiles, profileId};
    state = state.copyWith(superLikedProfiles: newSuperLiked);
    
    try {
      // Insert super swipe into database
      await _supabase.from('swipes').upsert({
        'swiper_id': _currentUserId,
        'swiped_id': profileId,
        'direction': 'super',
        'is_from_strict': true,
      });
      
      debugPrint('MatchState: Recorded SUPER swipe on $profileName');
      
      // Check if this created a match by refreshing from database
      await _loadFromDatabase();
    } catch (e) {
      debugPrint('MatchState: Error recording super swipe: $e');
      // Revert optimistic update
      state = state.copyWith(
        superLikedProfiles: {...state.superLikedProfiles}..remove(profileId),
      );
    }
  }

  /// Pass on a profile - NOW WRITES TO DATABASE
  Future<void> passProfile(String profileId) async {
    if (_currentUserId == null) return;
    
    // Optimistically add to passed set
    state = state.copyWith(
      passedProfiles: {...state.passedProfiles, profileId},
    );
    
    try {
      // Record the pass in database
      await _supabase.from('swipes').upsert({
        'swiper_id': _currentUserId,
        'swiped_id': profileId,
        'direction': 'left',
        'is_from_strict': true,
      });
      
      debugPrint('MatchState: Recorded left swipe (pass)');
    } catch (e) {
      debugPrint('MatchState: Error recording pass: $e');
      // Revert on error
      state = state.copyWith(
        passedProfiles: {...state.passedProfiles}..remove(profileId),
      );
    }
  }

  /// Update match priority (move between Nest categories)
  Future<void> updateMatchPriority(String matchId, MatchPriority newPriority) async {
    final updatedMatches = state.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(priority: newPriority);
      }
      return m;
    }).toList();

    state = state.copyWith(matches: updatedMatches);

    // Persist to database
    if (_currentUserId != null) {
      try {
        final isUserA = state.matches.any((m) => m.id == matchId);
        // Determine which column to update based on user position in match
        final matchData = await _supabase
            .from('matches')
            .select('user_a_id')
            .eq('id', matchId)
            .maybeSingle();
        if (matchData != null) {
          final column = matchData['user_a_id'] == _currentUserId
              ? 'user_a_priority'
              : 'user_b_priority';
          await _supabase.from('matches').update({
            column: _priorityToString(newPriority),
          }).eq('id', matchId);
        }
      } catch (e) {
        debugPrint('MatchState: Error persisting priority: $e');
      }
    }
  }

  /// Archive a match
  Future<void> archiveMatch(String matchId) async {
    final updatedMatches = state.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(isArchived: true);
      }
      return m;
    }).toList();

    state = state.copyWith(matches: updatedMatches);

    // Persist to database
    if (_currentUserId != null) {
      try {
        final matchData = await _supabase
            .from('matches')
            .select('user_a_id')
            .eq('id', matchId)
            .maybeSingle();
        if (matchData != null) {
          final column = matchData['user_a_id'] == _currentUserId
              ? 'user_a_archived'
              : 'user_b_archived';
          await _supabase.from('matches').update({
            column: true,
          }).eq('id', matchId);
        }
      } catch (e) {
        debugPrint('MatchState: Error persisting archive: $e');
      }
    }
  }

  /// Send a message to a match (creates/updates conversation)
  void sendMessage(String matchId, String message) {
    final existingConversation = state.conversations[matchId];
    if (existingConversation != null) {
      final updatedConversation = ChatConversation(
        id: existingConversation.id,
        matchId: matchId,
        otherUserId: existingConversation.otherUserId,
        otherUserName: existingConversation.otherUserName,
        otherUserAvatar: existingConversation.otherUserAvatar,
        lastMessage: message,
        lastMessageAt: DateTime.now(),
        lastMessageBy: 'me',
        momentumScore:
            (existingConversation.momentumScore + 0.1).clamp(0.0, 1.0),
      );

      state = state.copyWith(
        conversations: {...state.conversations, matchId: updatedConversation},
      );
    }
  }

  /// Clear new match notification count
  void clearNewMatchCount() {
    state = state.copyWith(newMatchCount: 0);
  }

  /// Get conversation for a match
  ChatConversation? getConversation(String matchId) =>
      state.conversations[matchId];

  /// Check if profile was already swiped
  bool hasSwipedProfile(String profileId) =>
      state.likedProfiles.contains(profileId) ||
      state.superLikedProfiles.contains(profileId) ||
      state.passedProfiles.contains(profileId);
}

/// Global match state provider
final matchStateProvider =
    StateNotifierProvider<MatchStateNotifier, MatchState>(
        (ref) => MatchStateNotifier(),);

/// Provider for matches by priority
final matchesByPriorityProvider =
    Provider.family<List<Match>, MatchPriority>((ref, priority) {
  final state = ref.watch(matchStateProvider);
  return state.getMatchesByPriority(priority);
});

/// Provider for new match count
final newMatchCountProvider = Provider<int>((ref) {
  final state = ref.watch(matchStateProvider);
  return state.newMatchCount;
});

/// Provider for all conversations
final allConversationsProvider = Provider<List<ChatConversation>>((ref) {
  final state = ref.watch(matchStateProvider);
  return state.conversations.values.toList()
    ..sort((a, b) => (b.lastMessageAt ?? DateTime(1970))
        .compareTo(a.lastMessageAt ?? DateTime(1970)),);
});
