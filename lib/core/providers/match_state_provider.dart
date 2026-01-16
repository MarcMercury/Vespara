import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/match.dart';
import '../domain/models/chat.dart';
import '../data/vespara_mock_data.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// MATCH STATE PROVIDER
/// Global state management for matches, likes, and cross-module interactions
/// Handles: Discover -> Nest flow, Match -> Wire flow, Nest -> Planner flow
/// ════════════════════════════════════════════════════════════════════════════

/// State class holding all match-related data
class MatchState {
  final List<Match> matches;
  final Set<String> likedProfiles; // Profiles the user has liked
  final Set<String> superLikedProfiles; // Profiles the user has super-liked
  final Set<String> passedProfiles; // Profiles the user has passed on
  final Map<String, ChatConversation> conversations; // Active conversations by match ID
  final int newMatchCount;

  const MatchState({
    this.matches = const [],
    this.likedProfiles = const {},
    this.superLikedProfiles = const {},
    this.passedProfiles = const {},
    this.conversations = const {},
    this.newMatchCount = 0,
  });

  MatchState copyWith({
    List<Match>? matches,
    Set<String>? likedProfiles,
    Set<String>? superLikedProfiles,
    Set<String>? passedProfiles,
    Map<String, ChatConversation>? conversations,
    int? newMatchCount,
  }) {
    return MatchState(
      matches: matches ?? this.matches,
      likedProfiles: likedProfiles ?? this.likedProfiles,
      superLikedProfiles: superLikedProfiles ?? this.superLikedProfiles,
      passedProfiles: passedProfiles ?? this.passedProfiles,
      conversations: conversations ?? this.conversations,
      newMatchCount: newMatchCount ?? this.newMatchCount,
    );
  }

  /// Get matches by priority
  List<Match> getMatchesByPriority(MatchPriority priority) {
    return matches.where((m) => m.priority == priority && !m.isArchived).toList();
  }

  /// Get new matches count
  int get newMatches => getMatchesByPriority(MatchPriority.new_).length;
}

/// Match state notifier for handling all match-related actions
class MatchStateNotifier extends StateNotifier<MatchState> {
  MatchStateNotifier() : super(MatchState(
    matches: MockDataProvider.matches,
    conversations: {
      for (var c in MockDataProvider.conversations) c.matchId: c
    },
  ));

  /// Like a profile from Discover
  /// If mutual like, creates a match in the "New" category
  void likeProfile(String profileId, String profileName, String? avatarUrl) {
    // Add to liked set
    final newLiked = {...state.likedProfiles, profileId};
    
    // Simulate mutual match (50% chance for demo, or always match super-likes)
    final isMutualMatch = state.superLikedProfiles.contains(profileId) || 
                          (DateTime.now().millisecond % 2 == 0);
    
    if (isMutualMatch) {
      // Create a new match
      final newMatch = Match(
        id: 'match-${DateTime.now().millisecondsSinceEpoch}',
        matchedUserId: profileId,
        matchedUserName: profileName,
        matchedUserAvatar: avatarUrl,
        matchedAt: DateTime.now(),
        priority: MatchPriority.new_,
        compatibilityScore: 0.7 + (DateTime.now().millisecond % 30) / 100,
        conversationId: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Create conversation for the match
      final newConversation = ChatConversation(
        id: newMatch.conversationId!,
        matchId: newMatch.id,
        otherUserId: profileId,
        otherUserName: profileName,
        otherUserAvatar: avatarUrl,
        lastMessage: null,
        lastMessageAt: null,
        unreadCount: 0,
        momentumScore: 0.5,
      );
      
      state = state.copyWith(
        likedProfiles: newLiked,
        matches: [...state.matches, newMatch],
        conversations: {...state.conversations, newMatch.id: newConversation},
        newMatchCount: state.newMatchCount + 1,
      );
    } else {
      state = state.copyWith(likedProfiles: newLiked);
    }
  }

  /// Super-like a profile (always creates a match for demo)
  void superLikeProfile(String profileId, String profileName, String? avatarUrl) {
    final newSuperLiked = {...state.superLikedProfiles, profileId};
    
    // Super-likes always result in a match for demo purposes
    final newMatch = Match(
      id: 'match-${DateTime.now().millisecondsSinceEpoch}',
      matchedUserId: profileId,
      matchedUserName: profileName,
      matchedUserAvatar: avatarUrl,
      matchedAt: DateTime.now(),
      priority: MatchPriority.new_,
      compatibilityScore: 0.85 + (DateTime.now().millisecond % 15) / 100,
      conversationId: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      isSuperMatch: true,
    );
    
    final newConversation = ChatConversation(
      id: newMatch.conversationId!,
      matchId: newMatch.id,
      otherUserId: profileId,
      otherUserName: profileName,
      otherUserAvatar: avatarUrl,
      lastMessage: '✨ Super Like match!',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
      momentumScore: 0.8,
    );
    
    state = state.copyWith(
      superLikedProfiles: newSuperLiked,
      matches: [...state.matches, newMatch],
      conversations: {...state.conversations, newMatch.id: newConversation},
      newMatchCount: state.newMatchCount + 1,
    );
  }

  /// Pass on a profile
  void passProfile(String profileId) {
    state = state.copyWith(
      passedProfiles: {...state.passedProfiles, profileId},
    );
  }

  /// Update match priority (move between Nest categories)
  void updateMatchPriority(String matchId, MatchPriority newPriority) {
    final updatedMatches = state.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(priority: newPriority);
      }
      return m;
    }).toList();
    
    state = state.copyWith(matches: updatedMatches);
  }

  /// Archive a match
  void archiveMatch(String matchId) {
    final updatedMatches = state.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(isArchived: true);
      }
      return m;
    }).toList();
    
    state = state.copyWith(matches: updatedMatches);
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
        unreadCount: 0,
        momentumScore: (existingConversation.momentumScore + 0.1).clamp(0.0, 1.0),
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
  ChatConversation? getConversation(String matchId) {
    return state.conversations[matchId];
  }

  /// Check if profile was already swiped
  bool hasSwipedProfile(String profileId) {
    return state.likedProfiles.contains(profileId) ||
           state.superLikedProfiles.contains(profileId) ||
           state.passedProfiles.contains(profileId);
  }
}

/// Global match state provider
final matchStateProvider = StateNotifierProvider<MatchStateNotifier, MatchState>((ref) {
  return MatchStateNotifier();
});

/// Provider for matches by priority
final matchesByPriorityProvider = Provider.family<List<Match>, MatchPriority>((ref, priority) {
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
    ..sort((a, b) => (b.lastMessageAt ?? DateTime(1970)).compareTo(a.lastMessageAt ?? DateTime(1970)));
});
