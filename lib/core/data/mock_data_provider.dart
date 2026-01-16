import 'dart:math';
import '../domain/models/roster_match.dart';
import '../domain/models/conversation.dart';
import '../domain/models/analytics.dart';
import '../domain/models/tags_game.dart';
import '../domain/models/user_profile.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// MOCK DATA PROVIDER
/// Provides realistic demo data for all 8 modules to enable testing
/// ════════════════════════════════════════════════════════════════════════════

class MockDataProvider {
  static final _random = Random();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // USER PROFILE
  // ═══════════════════════════════════════════════════════════════════════════
  
  static UserProfile get currentUserProfile => UserProfile(
    id: 'demo-user-001',
    email: 'demo@vespara.app',
    displayName: 'Demo User',
    avatarUrl: null,
    bio: 'Exploring life, one connection at a time.',
    trustScore: 87.5,
    vouchCount: 4,
    isVerified: true,
    verifications: ['email', 'phone'],
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now(),
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ROSTER MATCHES - Demo contacts for The Roster CRM
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final List<Map<String, dynamic>> _mockMatchNames = [
    {'name': 'Sophia Martinez', 'nickname': 'Sophie', 'source': 'Hinge', 'interests': ['Wine', 'Travel', 'Art']},
    {'name': 'Emma Thompson', 'nickname': null, 'source': 'Bumble', 'interests': ['Fitness', 'Music', 'Dogs']},
    {'name': 'Olivia Chen', 'nickname': 'Liv', 'source': 'Coffee Shop', 'interests': ['Coffee', 'Books', 'Yoga']},
    {'name': 'Ava Williams', 'nickname': null, 'source': 'Tinder', 'interests': ['Movies', 'Cooking', 'Hiking']},
    {'name': 'Isabella Johnson', 'nickname': 'Izzy', 'source': 'Feeld', 'interests': ['Dance', 'Meditation', 'Photography']},
    {'name': 'Mia Davis', 'nickname': null, 'source': 'Friend Intro', 'interests': ['Sports', 'Gaming', 'Tech']},
    {'name': 'Charlotte Brown', 'nickname': 'Charlie', 'source': 'Hinge', 'interests': ['Fashion', 'Brunch', 'Concerts']},
    {'name': 'Amelia Wilson', 'nickname': 'Amy', 'source': 'Work Event', 'interests': ['Startups', 'Wine', 'Running']},
    {'name': 'Harper Moore', 'nickname': null, 'source': 'Bumble', 'interests': ['Art', 'Museums', 'Cats']},
    {'name': 'Evelyn Taylor', 'nickname': 'Eve', 'source': 'Tinder', 'interests': ['Music', 'Festivals', 'Beach']},
    {'name': 'Abigail Anderson', 'nickname': 'Abby', 'source': 'Coffee Shop', 'interests': ['Books', 'Writing', 'Tea']},
    {'name': 'Emily Thomas', 'nickname': 'Em', 'source': 'Hinge', 'interests': ['Travel', 'Languages', 'Food']},
  ];
  
  static List<RosterMatch> get rosterMatches {
    final stages = [
      PipelineStage.incoming,
      PipelineStage.incoming,
      PipelineStage.bench,
      PipelineStage.bench,
      PipelineStage.bench,
      PipelineStage.activeRotation,
      PipelineStage.activeRotation,
      PipelineStage.activeRotation,
      PipelineStage.activeRotation,
      PipelineStage.legacy,
      PipelineStage.legacy,
      PipelineStage.legacy,
    ];
    
    return List.generate(_mockMatchNames.length, (index) {
      final data = _mockMatchNames[index];
      final daysAgo = _random.nextInt(30) + 1;
      final lastContact = DateTime.now().subtract(Duration(days: daysAgo));
      final momentum = (100 - daysAgo * 2.5).clamp(10.0, 95.0) / 100;
      
      return RosterMatch(
        id: 'match-${index + 1}',
        userId: 'demo-user-001',
        name: data['name'] as String,
        nickname: data['nickname'] as String?,
        avatarUrl: null,
        source: data['source'] as String,
        sourceUsername: '@${(data['name'] as String).split(' ')[0].toLowerCase()}',
        stage: stages[index],
        momentumScore: momentum,
        notes: 'Met at ${data['source']}. Great conversation about ${(data['interests'] as List)[0]}.',
        interests: List<String>.from(data['interests'] as List),
        lastContactDate: lastContact,
        nextAction: _getNextAction(stages[index], daysAgo),
        isArchived: false,
        archivedAt: null,
        archiveReason: null,
        createdAt: DateTime.now().subtract(Duration(days: daysAgo + 14)),
        updatedAt: lastContact,
      );
    });
  }
  
  static String _getNextAction(PipelineStage stage, int daysAgo) {
    switch (stage) {
      case PipelineStage.incoming:
        return 'Send opener message';
      case PipelineStage.bench:
        if (daysAgo > 7) return 'Re-engage with question';
        return 'Schedule coffee date';
      case PipelineStage.activeRotation:
        if (daysAgo > 5) return 'Plan next date';
        return 'Continue building connection';
      case PipelineStage.legacy:
        return 'Consider archiving or rekindling';
    }
  }
  
  /// Focus Batch for The Scope - 5 curated matches
  static List<RosterMatch> get focusBatch {
    final batch = rosterMatches
        .where((m) => m.stage == PipelineStage.incoming || m.stage == PipelineStage.bench)
        .take(5)
        .toList();
    return batch.isEmpty ? rosterMatches.take(5).toList() : batch;
  }
  
  /// Stale matches for The Shredder - matches with no contact 14+ days
  static List<RosterMatch> get staleMatches {
    return rosterMatches.where((m) {
      final daysSince = DateTime.now().difference(m.lastContactDate ?? m.updatedAt).inDays;
      return daysSince >= 14;
    }).toList();
  }
  
  /// Nearby matches for Tonight Mode
  static List<RosterMatch> get nearbyMatches {
    return rosterMatches
        .where((m) => m.stage == PipelineStage.activeRotation)
        .take(3)
        .toList();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATIONS - Demo messages for The Wire
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final List<Map<String, dynamic>> _mockConversations = [
    {'lastMessage': 'That sounds like a plan! See you Saturday? 😊', 'daysAgo': 1, 'unread': 2},
    {'lastMessage': 'I love that place! The cocktails are amazing.', 'daysAgo': 2, 'unread': 0},
    {'lastMessage': 'Haha exactly! You totally get it.', 'daysAgo': 3, 'unread': 1},
    {'lastMessage': 'What are you up to this weekend?', 'daysAgo': 5, 'unread': 0},
    {'lastMessage': 'That concert was incredible! Thanks for inviting me.', 'daysAgo': 7, 'unread': 0},
    {'lastMessage': 'Hey! How was your trip?', 'daysAgo': 10, 'unread': 0},
    {'lastMessage': 'We should definitely do that again sometime.', 'daysAgo': 14, 'unread': 0},
    {'lastMessage': 'Sounds good, let me know!', 'daysAgo': 18, 'unread': 0},
  ];
  
  static List<Conversation> get conversations {
    final matches = rosterMatches.take(_mockConversations.length).toList();
    
    return List.generate(_mockConversations.length, (index) {
      final data = _mockConversations[index];
      final match = matches[index];
      final daysAgo = data['daysAgo'] as int;
      final lastMessageAt = DateTime.now().subtract(Duration(days: daysAgo));
      final momentum = (100 - daysAgo * 5).clamp(10.0, 95.0) / 100;
      
      return Conversation(
        id: 'convo-${index + 1}',
        matchId: match.id,
        matchName: match.displayName,
        matchAvatarUrl: match.avatarUrl,
        lastMessage: data['lastMessage'] as String,
        lastMessageAt: lastMessageAt,
        unreadCount: data['unread'] as int,
        momentumScore: momentum,
        isStale: daysAgo >= 7,
        createdAt: DateTime.now().subtract(Duration(days: daysAgo + 7)),
      );
    });
  }
  
  /// Stale conversations for resuscitation
  static List<Conversation> get staleConversations {
    return conversations.where((c) => c.isStale).toList();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS - Demo stats for The Mirror
  // ═══════════════════════════════════════════════════════════════════════════
  
  static UserAnalytics get userAnalytics => UserAnalytics(
    userId: 'demo-user-001',
    ghostRate: 23.5,
    flakeRate: 15.0,
    swipeRatio: 35.0,
    responseRate: 78.0,
    totalMatches: rosterMatches.length,
    activeConversations: conversations.where((c) => !c.isStale).length,
    datesScheduled: 3,
    messagesSent: 156,
    messagesReceived: 142,
    firstMessagesSent: 8,
    conversationsStarted: 12,
    weeklyActivity: [12, 8, 15, 22, 18, 25, 10],
    peakActivityTime: '8pm - 10pm',
    lastUpdated: DateTime.now(),
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GAMES - Demo games for The Ludus (TAGS)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<GameCategory> getGamesForConsentLevel(ConsentLevel level) {
    return GameCategory.values.where((game) {
      return game.minimumConsentLevel.value <= level.value;
    }).toList();
  }
  
  static final List<GameCard> pleasureDeckCards = [
    // Green level cards
    GameCard(
      id: 'card-1',
      isTruth: true,
      content: 'What\'s the most spontaneous thing you\'ve ever done on a date?',
      intensity: 1,
      level: ConsentLevel.green,
    ),
    GameCard(
      id: 'card-2',
      isTruth: false,
      content: 'Give a 30-second compliment to the person on your left.',
      intensity: 1,
      level: ConsentLevel.green,
    ),
    GameCard(
      id: 'card-3',
      isTruth: true,
      content: 'What\'s your biggest turn-on that most people wouldn\'t guess?',
      intensity: 2,
      level: ConsentLevel.green,
    ),
    GameCard(
      id: 'card-4',
      isTruth: false,
      content: 'Show the group the last photo in your camera roll.',
      intensity: 2,
      level: ConsentLevel.green,
    ),
    GameCard(
      id: 'card-5',
      isTruth: true,
      content: 'What\'s a fantasy you\'ve never told anyone about?',
      intensity: 3,
      level: ConsentLevel.green,
    ),
    // Yellow level cards
    GameCard(
      id: 'card-6',
      isTruth: false,
      content: 'Give a 60-second shoulder massage to someone of your choice.',
      intensity: 3,
      level: ConsentLevel.yellow,
    ),
    GameCard(
      id: 'card-7',
      isTruth: true,
      content: 'Describe in detail your ideal romantic evening.',
      intensity: 4,
      level: ConsentLevel.yellow,
    ),
    GameCard(
      id: 'card-8',
      isTruth: false,
      content: 'Whisper something flirtatious to someone in the room.',
      intensity: 4,
      level: ConsentLevel.yellow,
    ),
    // Red level cards
    GameCard(
      id: 'card-9',
      isTruth: true,
      content: 'What\'s your most secret desire?',
      intensity: 5,
      level: ConsentLevel.red,
    ),
    GameCard(
      id: 'card-10',
      isTruth: false,
      content: 'Draw a card from the Kama Sutra deck and demonstrate the position (clothed).',
      intensity: 5,
      level: ConsentLevel.red,
    ),
  ];
  
  static List<GameCard> getCardsForLevel(ConsentLevel level) {
    return pleasureDeckCards.where((card) {
      return card.level.value <= level.value;
    }).toList();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VOUCH CHAIN - Demo vouches for The Core
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final List<Map<String, dynamic>> vouches = [
    {'name': 'Alex Rivera', 'message': 'Known for 3 years. Genuine and respectful.', 'date': '2025-11-15'},
    {'name': 'Jordan Lee', 'message': 'Great communicator. Always honest.', 'date': '2025-10-22'},
    {'name': 'Sam Chen', 'message': 'Trustworthy. Would vouch again!', 'date': '2025-09-08'},
    {'name': 'Casey Morgan', 'message': 'A true friend. Highly recommend.', 'date': '2025-08-14'},
  ];
  
  static String get vouchLink => 'vespara.app/vouch/demo-user-001';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STRATEGIST - AI Advice
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final List<String> strategistAdvice = [
    'Your response rate is strong at 78%. Focus on converting conversations to dates.',
    'You have 3 stale matches. Consider using Ghost Protocol or re-engaging.',
    'Tonight Mode could help you meet someone spontaneously. Try enabling it!',
    'Your optimization score is 82%. Reply faster to boost it further.',
    'You\'re most active 8-10pm. That\'s prime time for meaningful chats.',
  ];
  
  static String get randomAdvice {
    return strategistAdvice[_random.nextInt(strategistAdvice.length)];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GHOST PROTOCOL - Closure messages
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String generateClosureMessage(String name, String tone) {
    switch (tone) {
      case 'kind':
        return 'Hey $name, I\'ve really enjoyed getting to know you. Life has gotten pretty hectic lately, and I\'ve realized I\'m not in a place where I can give this the attention it deserves. I genuinely wish you all the best. 💜';
      case 'honest':
        return 'Hi $name, I want to be upfront with you. After some reflection, I don\'t think we\'re quite the right match. I appreciate the time we\'ve spent chatting and wish you well.';
      case 'brief':
        return 'Hey $name, I\'ve enjoyed our conversations but I think it\'s best we part ways. Wishing you the best!';
      default:
        return 'Thank you for your time, $name. I wish you all the best.';
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RESUSCITATOR - Conversation revival messages
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String generateResuscitatorMessage(String name, List<String> interests) {
    final interest = interests.isNotEmpty ? interests.first : 'travel';
    final messages = [
      'Hey $name! 👋 I was just thinking about our conversation about $interest. Did you end up trying that thing you mentioned?',
      'Hi $name! I saw something today that reminded me of you. How have you been?',
      'Hey! Random thought - I was at a great new ${interest.toLowerCase()} spot and thought you\'d love it. Wanna check it out sometime?',
      '$name! It\'s been a minute. I\'d love to catch up if you\'re free this week?',
    ];
    return messages[_random.nextInt(messages.length)];
  }
}
