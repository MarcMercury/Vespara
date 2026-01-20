import 'dart:math';
import '../domain/models/discoverable_profile.dart';
import '../domain/models/match.dart';
import '../domain/models/chat.dart';
import '../domain/models/events.dart';
import '../domain/models/analytics.dart';
import '../domain/models/tags_game.dart';
import '../domain/models/user_profile.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// VESPARA DATING APP - MOCK DATA PROVIDER
/// Realistic demo data for all 8 modules
/// ════════════════════════════════════════════════════════════════════════════

class MockDataProvider {
  static final _random = Random();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CURRENT USER PROFILE (Module 1: Mirror)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static UserProfile get currentUserProfile => UserProfile(
    id: 'demo-user-001',
    email: 'demo@vespara.app',
    displayName: 'Alex',
    avatarUrl: null,
    headline: 'Curious soul exploring connection',
    bio: 'Wine lover, jazz enthusiast, amateur chef. Looking for genuine chemistry and adult adventures. Open-minded and always up for new experiences.',
    age: 32,
    occupation: 'Creative Director',
    location: 'Downtown',
    photos: [],
    relationshipTypes: ['casual', 'exploring', 'ethical non-monogamy'],
    loveLanguages: ['touch', 'quality time', 'words of affirmation'],
    kinks: ['sensory play', 'role play', 'spontaneity'],
    boundaries: ['no unsolicited pics', 'safe words respected', 'clear communication'],
    trustScore: 87.5,
    vouchCount: 4,
    isVerified: true,
    verifications: ['email', 'phone', 'photo'],
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now(),
    preferences: {
      'age_min': 25,
      'age_max': 45,
      'distance_km': 50,
      'relationship_types': ['casual', 'exploring', 'ethicalNonMonogamy'],
      'looking_for': ['connection', 'chemistry', 'adventure'],
    },
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY PROFILES (Module 2: Discover)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final List<Map<String, dynamic>> _profileData = [
    {
      'name': 'Sophia', 'age': 29, 'location': 'Downtown', 'distance': 2.3,
      'headline': 'Wine enthusiast with a taste for adventure',
      'bio': 'Marketing director by day, salsa dancer by night. Looking for someone who can keep up with my energy and match my wit.',
      'occupation': 'Marketing Director', 'company': 'Tech Startup',
      'photos': ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400'],
      'relationship_types': ['casual', 'exploring'],
      'love_languages': ['touch', 'time'],
      'prompts': [
        {'question': 'My ideal first date', 'answer': 'Cocktails at a speakeasy followed by spontaneous dancing'},
        {'question': 'I\'m looking for', 'answer': 'Chemistry that makes me forget my phone exists'},
      ],
      'compatibility': 0.92, 'is_strict': true, 'is_wildcard': false,
    },
    {
      'name': 'Emma', 'age': 32, 'location': 'Midtown', 'distance': 4.1,
      'headline': 'Yoga teacher with a wild side',
      'bio': 'Flexibility isn\'t just physical. Open-minded, curious, and always down for deep conversations and deeper connections.',
      'occupation': 'Yoga Instructor', 'company': 'Self-employed',
      'photos': ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400'],
      'relationship_types': ['ethicalNonMonogamy', 'exploring'],
      'love_languages': ['touch', 'words'],
      'prompts': [
        {'question': 'A boundary I have', 'answer': 'I need honesty, even when it\'s uncomfortable'},
        {'question': 'What turns me on', 'answer': 'Intelligence, presence, and someone who can hold space'},
      ],
      'compatibility': 0.88, 'is_strict': true, 'is_wildcard': false,
    },
    {
      'name': 'Olivia', 'age': 27, 'location': 'Arts District', 'distance': 5.5,
      'headline': 'Artist with a passion for the provocative',
      'bio': 'I paint, I create, I explore. My art is sensual, my energy is magnetic. Looking for muses and adventures.',
      'occupation': 'Artist', 'company': 'Gallery Represented',
      'photos': ['https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400'],
      'relationship_types': ['casual', 'polyamory'],
      'love_languages': ['acts', 'touch'],
      'prompts': [
        {'question': 'My love language', 'answer': 'Acts of spontaneity'},
        {'question': 'Fantasy I want to explore', 'answer': 'Being painted... while painting someone else'},
      ],
      'compatibility': 0.85, 'is_strict': true, 'is_wildcard': false,
    },
    {
      'name': 'Ava', 'age': 34, 'location': 'Financial District', 'distance': 3.2,
      'headline': 'CFO who knows how to let loose',
      'bio': 'Boardroom professional, bedroom adventurer. I work hard and play harder. Looking for quality connections, not quantity.',
      'occupation': 'CFO', 'company': 'Fortune 500',
      'photos': ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400'],
      'relationship_types': ['casual', 'exploring'],
      'love_languages': ['time', 'gifts'],
      'prompts': [
        {'question': 'My ideal evening', 'answer': 'Five-star dinner, rooftop drinks, and whatever happens next'},
        {'question': 'I\'m attracted to', 'answer': 'Confidence, ambition, and someone who doesn\'t need me but wants me'},
      ],
      'compatibility': 0.79, 'is_strict': true, 'is_wildcard': false,
    },
    {
      'name': 'Isabella', 'age': 28, 'location': 'Beach Town', 'distance': 12.0,
      'headline': 'Free spirit, wild heart',
      'bio': 'Surfer, photographer, energy healer. I believe in cosmic connections and carnal pleasures. Let\'s get weird together.',
      'occupation': 'Photographer', 'company': 'Freelance',
      'photos': ['https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400'],
      'relationship_types': ['polyamory', 'exploring'],
      'love_languages': ['touch', 'words'],
      'prompts': [
        {'question': 'Kink I\'m curious about', 'answer': 'Tantra and conscious connection'},
        {'question': 'My boundaries', 'answer': 'Respect, consent, and good hygiene'},
      ],
      'compatibility': 0.65, 'is_strict': false, 'is_wildcard': true,
      'wildcard_reason': 'Outside your distance, but high compatibility on intimacy preferences',
    },
    {
      'name': 'Mia', 'age': 31, 'location': 'University District', 'distance': 6.7,
      'headline': 'Professor with a secret side',
      'bio': 'PhD in Psychology, minor in mischief. I study human behavior... and enjoy testing hypotheses.',
      'occupation': 'Professor', 'company': 'State University',
      'photos': ['https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400'],
      'relationship_types': ['exploring', 'casual'],
      'love_languages': ['words', 'touch'],
      'prompts': [
        {'question': 'Turn on', 'answer': 'When someone can match my banter and beat me at my own game'},
        {'question': 'What I\'m exploring', 'answer': 'Power dynamics, in a fun and consensual way'},
      ],
      'compatibility': 0.82, 'is_strict': true, 'is_wildcard': false,
    },
    {
      'name': 'Charlotte', 'age': 26, 'location': 'Suburban', 'distance': 18.0,
      'headline': 'Sweet on the outside, spicy on the inside',
      'bio': 'Elementary school teacher with a secret: I\'m much more interesting after 5pm. Looking for adults who know how to play.',
      'occupation': 'Teacher', 'company': 'Public School',
      'photos': ['https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400'],
      'relationship_types': ['casual', 'monogamy'],
      'love_languages': ['acts', 'time'],
      'prompts': [
        {'question': 'Best kept secret', 'answer': 'My toy collection... for crafts, obviously 😏'},
        {'question': 'Looking for', 'answer': 'Someone patient who can unwrap all my layers'},
      ],
      'compatibility': 0.58, 'is_strict': false, 'is_wildcard': true,
      'wildcard_reason': 'AI thinks you\'d vibe based on communication style matches',
    },
    {
      'name': 'Amelia', 'age': 30, 'location': 'Tech Hub', 'distance': 1.8,
      'headline': 'Engineer by logic, lover by instinct',
      'bio': 'I solve problems by day and create chemistry by night. Sapiosexual with a soft spot for good hands.',
      'occupation': 'Software Engineer', 'company': 'FAANG',
      'photos': ['https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400'],
      'relationship_types': ['ethicalNonMonogamy', 'exploring'],
      'love_languages': ['touch', 'time'],
      'prompts': [
        {'question': 'Ideal connection', 'answer': 'Start with the mind, end up tangled in sheets'},
        {'question': 'Non-negotiable', 'answer': 'Emotional intelligence and physical chemistry'},
      ],
      'compatibility': 0.91, 'is_strict': true, 'is_wildcard': false,
    },
  ];
  
  static List<DiscoverableProfile> get discoverProfiles {
    return _profileData.map((data) {
      return DiscoverableProfile(
        id: 'profile-${_profileData.indexOf(data) + 1}',
        displayName: data['name'] as String,
        headline: data['headline'] as String?,
        age: data['age'] as int,
        bio: data['bio'] as String?,
        photos: List<String>.from(data['photos'] as List),
        location: data['location'] as String?,
        distanceKm: (data['distance'] as num).toDouble(),
        occupation: data['occupation'] as String?,
        company: data['company'] as String?,
        relationshipTypes: List<String>.from(data['relationship_types'] as List),
        loveLanguages: List<String>.from(data['love_languages'] as List),
        prompts: (data['prompts'] as List).map((p) => ProfilePrompt(
          question: p['question'] as String,
          answer: p['answer'] as String,
        )).toList(),
        compatibilityScore: (data['compatibility'] as num).toDouble(),
        isStrictMatch: data['is_strict'] as bool,
        isWildcard: data['is_wildcard'] as bool? ?? false,
        wildcardReason: data['wildcard_reason'] as String?,
        vouchCount: _random.nextInt(8),
        isVerified: _random.nextBool(),
      );
    }).toList();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHES (Module 3: Nest)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<Match> get matches {
    final matchData = [
      {'name': 'Sophia', 'age': 29, 'priority': 'priority', 'days_ago': 2, 'last_msg': 'That sounds amazing! When are you free?', 'unread': 1},
      {'name': 'Emma', 'age': 32, 'priority': 'priority', 'days_ago': 1, 'last_msg': 'I had such a great time last night 😊', 'unread': 0},
      {'name': 'Ava', 'age': 34, 'priority': 'inWaiting', 'days_ago': 4, 'last_msg': 'Let me check my calendar and get back to you', 'unread': 0},
      {'name': 'Mia', 'age': 31, 'priority': 'inWaiting', 'days_ago': 5, 'last_msg': 'Haha that\'s hilarious', 'unread': 0},
      {'name': 'Olivia', 'age': 27, 'priority': 'new_', 'days_ago': 0, 'last_msg': null, 'unread': 0},
      {'name': 'Amelia', 'age': 30, 'priority': 'new_', 'days_ago': 0, 'last_msg': null, 'unread': 0},
      {'name': 'Grace', 'age': 28, 'priority': 'onWayOut', 'days_ago': 12, 'last_msg': 'Yeah maybe sometime', 'unread': 0},
      {'name': 'Luna', 'age': 26, 'priority': 'legacy', 'days_ago': 45, 'last_msg': 'It was fun while it lasted', 'unread': 0},
    ];
    
    return matchData.asMap().entries.map((entry) {
      final i = entry.key;
      final data = entry.value;
      final matchedAt = DateTime.now().subtract(Duration(days: (data['days_ago'] as int) + 7));
      final lastMsgAt = data['last_msg'] != null 
          ? DateTime.now().subtract(Duration(days: data['days_ago'] as int))
          : null;
      
      return Match(
        id: 'match-${i + 1}',
        matchedUserId: 'user-${i + 100}',
        matchedUserName: data['name'] as String,
        matchedUserAge: data['age'] as int,
        matchedAt: matchedAt,
        compatibilityScore: 0.7 + _random.nextDouble() * 0.25,
        isSuperMatch: i < 2,
        conversationId: 'conv-${i + 1}',
        lastMessage: data['last_msg'] as String?,
        lastMessageAt: lastMsgAt,
        unreadCount: data['unread'] as int,
        priority: MatchPriority.fromString(data['priority'] as String),
        sharedInterests: ['Wine', 'Travel', 'Music'].take(_random.nextInt(3) + 1).toList(),
        suggestedTopics: ['Ask about her weekend plans', 'Discuss that restaurant she mentioned'],
        suggestedDateIdeas: ['Wine tasting at new spot downtown', 'Jazz night at Blue Note'],
      );
    }).toList();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATIONS & MESSAGES (Module 4: The Wire)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<ChatConversation> get conversations {
    return matches.where((m) => m.lastMessage != null).map((match) {
      return ChatConversation(
        id: match.conversationId!,
        matchId: match.id,
        otherUserId: match.matchedUserId,
        otherUserName: match.matchedUserName,
        lastMessage: match.lastMessage,
        lastMessageAt: match.lastMessageAt,
        unreadCount: match.unreadCount,
        momentumScore: match.compatibilityScore,
        isStale: match.daysSinceLastMessage > 3,
      );
    }).toList();
  }
  
  static List<ChatMessage> getMessagesForConversation(String conversationId) {
    // Demo conversation with Sophia
    if (conversationId == 'conv-1') {
      return [
        ChatMessage(
          id: 'msg-1',
          conversationId: conversationId,
          senderId: 'user-100',
          isFromMe: false,
          content: 'Hey! I noticed we matched 😊',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        ChatMessage(
          id: 'msg-2',
          conversationId: conversationId,
          senderId: 'demo-user-001',
          isFromMe: true,
          content: 'Hi Sophia! Your profile caught my eye. That speakeasy date idea sounds amazing.',
          createdAt: DateTime.now().subtract(const Duration(days: 7, hours: -1)),
        ),
        ChatMessage(
          id: 'msg-3',
          conversationId: conversationId,
          senderId: 'user-100',
          isFromMe: false,
          content: 'Right?! There\'s this hidden gem in the Arts District I\'ve been dying to try',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
        ChatMessage(
          id: 'msg-4',
          conversationId: conversationId,
          senderId: 'demo-user-001',
          isFromMe: true,
          content: 'I love discovering hidden spots. What\'s the vibe like?',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ChatMessage(
          id: 'msg-5',
          conversationId: conversationId,
          senderId: 'user-100',
          isFromMe: false,
          content: 'Very intimate, dim lighting, jazz on vinyl. The kind of place where conversations go... interesting places 😏',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        ChatMessage(
          id: 'msg-6',
          conversationId: conversationId,
          senderId: 'demo-user-001',
          isFromMe: true,
          content: 'Sold. When are you free to explore?',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        ChatMessage(
          id: 'msg-7',
          conversationId: conversationId,
          senderId: 'user-100',
          isFromMe: false,
          content: 'That sounds amazing! When are you free?',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }
    return [];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS (Module 5: The Planner)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<CalendarEvent> get calendarEvents {
    final now = DateTime.now();
    return [
      CalendarEvent(
        id: 'event-1',
        userId: 'demo-user-001',
        matchId: 'match-1',
        matchName: 'Sophia',
        title: 'Speakeasy Date with Sophia',
        description: 'Hidden gem in Arts District - cocktails and jazz',
        location: 'The Velvet Room, Arts District',
        startTime: now.add(const Duration(days: 3, hours: 20)),
        endTime: now.add(const Duration(days: 3, hours: 23)),
        status: EventStatus.confirmed,
        aiConflictDetected: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CalendarEvent(
        id: 'event-2',
        userId: 'demo-user-001',
        matchId: 'match-2',
        matchName: 'Emma',
        title: 'Yoga & Brunch with Emma',
        description: 'Morning flow followed by that new brunch spot',
        location: 'Soul Yoga Studio',
        startTime: now.add(const Duration(days: 5, hours: 10)),
        endTime: now.add(const Duration(days: 5, hours: 14)),
        status: EventStatus.tentative,
        aiConflictDetected: true,
        aiConflictReason: 'You mentioned hiking with Ava on Saturday - same day',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      CalendarEvent(
        id: 'event-3',
        userId: 'demo-user-001',
        title: 'Work dinner',
        startTime: now.add(const Duration(days: 2, hours: 19)),
        endTime: now.add(const Duration(days: 2, hours: 22)),
        externalCalendarSource: 'google',
        status: EventStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP EVENTS (Module 6: Group Stuff)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<GroupEvent> get groupEvents {
    final now = DateTime.now();
    return [
      GroupEvent(
        id: 'group-1',
        hostId: 'demo-user-001',
        hostName: 'You',
        title: 'Wine & Paint Night',
        description: 'Bring your creativity and your thirst. We\'ll provide the canvas and the bottles. 21+ only, flirty vibes encouraged.',
        eventType: 'party',
        venueName: 'Loft Gallery',
        venueAddress: '123 Art Street',
        startTime: now.add(const Duration(days: 10, hours: 19)),
        endTime: now.add(const Duration(days: 10, hours: 23)),
        maxAttendees: 12,
        currentAttendees: 5,
        isPrivate: true,
        contentRating: 'flirty',
        invites: [
          EventInvite(id: 'inv-1', eventId: 'group-1', userId: 'user-100', userName: 'Sophia', invitedById: 'demo-user-001', status: InviteStatus.accepted, createdAt: now),
          EventInvite(id: 'inv-2', eventId: 'group-1', userId: 'user-101', userName: 'Emma', invitedById: 'demo-user-001', status: InviteStatus.accepted, createdAt: now),
          EventInvite(id: 'inv-3', eventId: 'group-1', userId: 'user-102', userName: 'Olivia', invitedById: 'demo-user-001', status: InviteStatus.pending, createdAt: now),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      GroupEvent(
        id: 'group-2',
        hostId: 'user-100',
        hostName: 'Sophia',
        title: 'Rooftop Vibes',
        description: 'Summer night on the rooftop. Music, drinks, connections. Come as you are, leave with stories.',
        eventType: 'social',
        venueName: 'Sky Lounge',
        startTime: now.add(const Duration(days: 14, hours: 21)),
        maxAttendees: 20,
        currentAttendees: 8,
        contentRating: 'social',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SHRED SUGGESTIONS (Module 7: The Shredder)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<Map<String, dynamic>> get shredSuggestions {
    return [
      {
        'name': 'Grace',
        'daysSinceMatch': 45,
        'daysSinceLastMessage': 12,
        'messageCount': 8,
        'responseRate': 0.25,
        'urgency': 'high',
        'reason': 'Grace hasn\'t responded in 12 days despite 3 messages from you. The conversation died after she mentioned being "super busy" - classic fadeaway. Move on.',
      },
      {
        'name': 'Luna',
        'daysSinceMatch': 67,
        'daysSinceLastMessage': 9,
        'messageCount': 14,
        'responseRate': 0.35,
        'urgency': 'medium',
        'reason': 'Luna\'s responses averaged 2 words. You\'re carrying this conversation. She\'s either not interested or terrible at texting - either way, not worth your energy.',
      },
      {
        'name': 'Madison',
        'daysSinceMatch': 89,
        'daysSinceLastMessage': 23,
        'messageCount': 4,
        'responseRate': 0.50,
        'urgency': 'low',
        'reason': 'You matched 3 months ago and never really got momentum. Sometimes the spark just isn\'t there. Archive and move forward.',
      },
    ];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TAGS GAMES (Module 8: TAG)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<TagsGame> get tagsGames => [
    TagsGame(
      id: 'game-1',
      title: 'First Date Icebreakers',
      description: 'Perfect for breaking the tension on a first date. Fun, flirty, and not too personal.',
      category: GameCategory.icebreakers,
      currentConsentLevel: ConsentLevel.green,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-2',
      title: 'Truth or Dare: Spicy Edition',
      description: 'The classic game with an adult twist. Set your comfort level before playing.',
      category: GameCategory.truthOrDare,
      currentConsentLevel: ConsentLevel.yellow,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-3',
      title: 'Fantasy Exploration',
      description: 'A safe space to explore desires and fantasies together. Requires trust and open communication.',
      category: GameCategory.sensoryPlay,
      currentConsentLevel: ConsentLevel.red,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-4',
      title: 'Group Party Games',
      description: 'Perfect for play parties and group hangouts. Keeps the energy high and the laughter flowing.',
      category: GameCategory.theOtherRoom,
      currentConsentLevel: ConsentLevel.yellow,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-5',
      title: 'Path of Pleasure',
      description: 'Comparative ranking game of desires. Discover what you both really want.',
      category: GameCategory.pathOfPleasure,
      currentConsentLevel: ConsentLevel.yellow,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-6',
      title: 'Coin Toss Decisions',
      description: 'Let fate decide your next move. Physical board mechanics digitized.',
      category: GameCategory.coinTossBoard,
      currentConsentLevel: ConsentLevel.green,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-7',
      title: 'Kama Sutra Tonight',
      description: 'Ancient wisdom for modern intimacy. Explore new positions together.',
      category: GameCategory.kamaSutra,
      currentConsentLevel: ConsentLevel.red,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
    TagsGame(
      id: 'game-8',
      title: 'Lane of Lust',
      description: 'Timeline-style game where you rank desires by intensity. First to 10 cards wins!',
      category: GameCategory.laneOfLust,
      currentConsentLevel: ConsentLevel.yellow,
      participantIds: [],
      createdAt: DateTime.now(),
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS (Module 1: Mirror - Analytics Section)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static UserAnalytics get analytics => UserAnalytics(
    userId: 'demo-user-001',
    matchRate: 34.8, // 54 matches / 155 right swipes
    totalMatches: 54,
    activeConversations: 6,
    activeDays: 90,
    firstMessagesSent: 48, // You messaged first
    messagesSent: 387,
    messagesReceived: 312,
    responseRate: 0.785, // 78.5%
    conversationsStarted: 48,
    datesScheduled: 12,
    ghostRate: 0.185, // 18.5% - You got ghosted
    flakeRate: 0.083, // 8.3% - Dates that cancelled
    weeklyActivity: [0.4, 0.6, 0.8, 0.9, 0.7, 0.3, 0.2],
    peakActivityTime: '7pm - 10pm',
    lastUpdated: DateTime.now(),
    // AI insights
    aiPersonalitySummary: 'Direct communicator with strong opener game. You invest in quality connections but sometimes spread attention too thin. You have a tendency to over-text early and then fade when things get real.',
    aiDatingStyle: '"Strategic Explorer" - You collect matches like trophies but struggle to commit',
    aiImprovementTips: [
      'Your response time has increased by 23% this month - faster replies boost match retention',
      'Matches who you super-liked converted to dates 3x more often - use them strategically',
      'Your evening messages (7-9pm) get 40% more responses than late night ones',
      'Stop triple texting - it comes across as desperate',
    ],
  );
}
