import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/plan_event.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PLAN PROVIDER
/// State management for THE PLAN section
/// Handles: Events, AI Suggestions, Calendar Sync, Find Me a Date
/// ════════════════════════════════════════════════════════════════════════════

/// State class for Plan
class PlanState {
  const PlanState({
    this.events = const [],
    this.experienceEvents = const [],
    this.aiSuggestions = const [],
    this.userAvailability = const [],
    this.isLoading = false,
    this.isLoadingSuggestions = false,
    this.error,
    this.googleCalendarConnected = false,
    this.appleCalendarConnected = false,
    this.lastSyncTime,
  });
  final List<PlanEvent> events;
  final List<PlanEvent>
      experienceEvents; // Events from Experience page (auto-synced)
  final List<AiDateSuggestion> aiSuggestions;
  final List<TimeSlot> userAvailability;
  final bool isLoading;
  final bool isLoadingSuggestions;
  final String? error;

  // Calendar sync status
  final bool googleCalendarConnected;
  final bool appleCalendarConnected;
  final DateTime? lastSyncTime;

  /// All events combined (user-created + experience events)
  List<PlanEvent> get allEvents {
    final combined = [...events, ...experienceEvents];
    combined.sort((a, b) => a.startTime.compareTo(b.startTime));
    return combined;
  }

  PlanState copyWith({
    List<PlanEvent>? events,
    List<PlanEvent>? experienceEvents,
    List<AiDateSuggestion>? aiSuggestions,
    List<TimeSlot>? userAvailability,
    bool? isLoading,
    bool? isLoadingSuggestions,
    String? error,
    bool? googleCalendarConnected,
    bool? appleCalendarConnected,
    DateTime? lastSyncTime,
  }) =>
      PlanState(
        events: events ?? this.events,
        experienceEvents: experienceEvents ?? this.experienceEvents,
        aiSuggestions: aiSuggestions ?? this.aiSuggestions,
        userAvailability: userAvailability ?? this.userAvailability,
        isLoading: isLoading ?? this.isLoading,
        isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
        error: error,
        googleCalendarConnected:
            googleCalendarConnected ?? this.googleCalendarConnected,
        appleCalendarConnected:
            appleCalendarConnected ?? this.appleCalendarConnected,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      );

  // Computed getters - now use allEvents to include Experience events
  List<PlanEvent> get upcomingEvents =>
      allEvents.where((e) => !e.isPast && !e.isCancelled).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<PlanEvent> get todayEvents =>
      allEvents.where((e) => e.isToday && !e.isCancelled).toList();

  List<PlanEvent> get thisWeekEvents {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return allEvents
        .where(
          (e) =>
              e.startTime.isAfter(now) &&
              e.startTime.isBefore(weekEnd) &&
              !e.isCancelled,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<PlanEvent> get conflictedEvents =>
      allEvents.where((e) => e.isConflicted).toList();

  List<PlanEvent> eventsForDate(DateTime date) => allEvents
      .where(
        (e) =>
            e.startTime.year == date.year &&
            e.startTime.month == date.month &&
            e.startTime.day == date.day &&
            !e.isCancelled,
      )
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  int get confirmedCount => allEvents
      .where((e) => e.certainty == EventCertainty.locked && !e.isCancelled)
      .length;

  int get tentativeCount => allEvents
      .where(
        (e) => e.certainty != EventCertainty.locked && !e.isCancelled,
      )
      .length;

  // Experience events counts
  int get experienceEventCount => experienceEvents.length;

  List<PlanEvent> get goingExperiences =>
      experienceEvents.where((e) => !e.isCancelled && !e.isPast).toList();

  bool get hasCalendarConnected =>
      googleCalendarConnected || appleCalendarConnected;
}

/// Plan state notifier
class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier({SupabaseClient? supabase})
      : _supabase = supabase,
        super(const PlanState()) {
    _initialize();
  }
  final SupabaseClient? _supabase;

  void _initialize() {
    loadEvents();
    loadExperienceEvents();
  }

  /// Load events from database
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true);

    try {
      final userId = _supabase?.auth.currentUser?.id;

      if (userId != null && _supabase != null) {
        // Try to load from Supabase
        final response = await _supabase
            .from('plan_events')
            .select()
            .eq('user_id', userId)
            .order('start_time');

        final events =
            (response as List).map((json) => PlanEvent.fromJson(json)).toList();

        state = state.copyWith(events: events, isLoading: false);
      } else {
        // No user - return empty
        state = state.copyWith(
          events: [],
          isLoading: false,
        );
      }
    } catch (e) {
      // Return empty on error
      state = state.copyWith(
        events: [],
        isLoading: false,
      );
    }
  }

  /// Load Experience events (from Partiful-style events page)
  /// These auto-sync to show what the user has already committed to
  Future<void> loadExperienceEvents() async {
    try {
      final userId = _supabase?.auth.currentUser?.id;

      if (userId != null && _supabase != null) {
        // Load events where user is going or hosting
        final response = await _supabase.from('vespara_events').select('''
              *,
              rsvps:vespara_event_rsvps(user_id, status)
            ''').or('host_id.eq.$userId').order('start_time');

        final experienceEvents = <PlanEvent>[];

        for (final eventJson in response as List) {
          final rsvps = eventJson['rsvps'] as List? ?? [];
          final userRsvp = rsvps.firstWhere(
            (r) => r['user_id'] == userId,
            orElse: () => null,
          );

          // Include if hosting or RSVP'd as going
          final isHosting = eventJson['host_id'] == userId;
          final isGoing = userRsvp != null && userRsvp['status'] == 'going';

          if (isHosting || isGoing) {
            experienceEvents
                .add(_convertVesparaEventToPlanEvent(eventJson, isHosting));
          }
        }

        state = state.copyWith(experienceEvents: experienceEvents);
      } else {
        // No user - return empty
        state = state.copyWith(
          experienceEvents: [],
        );
      }
    } catch (e) {
      // Return empty on error
      state = state.copyWith(
        experienceEvents: [],
      );
    }
  }

  /// Convert a VesparaEvent JSON to PlanEvent
  PlanEvent _convertVesparaEventToPlanEvent(
          Map<String, dynamic> json, bool isHosting,) =>
      PlanEvent(
        id: 'exp-${json['id']}',
        userId: _supabase?.auth.currentUser?.id ?? '',
        title: json['title'] as String,
        description: json['description'] as String?,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String)
            : null,
        location:
            json['venue_name'] as String? ?? json['venue_address'] as String?,
        certainty: EventCertainty.locked, // User has committed to this
        isFromExperience: true,
        experienceHostName: isHosting ? 'You' : (json['host_name'] as String?),
        isHosting: isHosting,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Create a new event
  Future<void> createEvent(PlanEvent event) async {
    try {
      final userId = _supabase?.auth.currentUser?.id;

      if (userId != null && _supabase != null) {
        final response = await _supabase
            .from('plan_events')
            .insert(event.toJson())
            .select()
            .single();

        final newEvent = PlanEvent.fromJson(response);
        state = state.copyWith(
          events: [...state.events, newEvent],
        );
      } else {
        // No user: add to local state only
        state = state.copyWith(
          events: [...state.events, event],
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create event: $e');
    }
  }

  /// Update an event
  Future<void> updateEvent(PlanEvent event) async {
    try {
      final userId = _supabase?.auth.currentUser?.id;

      if (userId != null && _supabase != null) {
        await _supabase
            .from('plan_events')
            .update(event.toJson())
            .eq('id', event.id);
      }

      final updatedEvents = state.events
          .map(
            (e) => e.id == event.id ? event : e,
          )
          .toList();

      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      if (_supabase != null) {
        await _supabase.from('plan_events').delete().eq('id', eventId);
      }

      final updatedEvents = state.events.where((e) => e.id != eventId).toList();
      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete event: $e');
    }
  }

  /// Update event certainty
  Future<void> updateCertainty(String eventId, EventCertainty certainty) async {
    final event = state.events.firstWhere((e) => e.id == eventId);
    await updateEvent(event.copyWith(certainty: certainty));
  }

  /// Find Me a Date - AI-powered date matching
  Future<List<AiDateSuggestion>> findMeADate({
    DateTime? preferredDate,
    List<String>? preferredConnectionIds,
  }) async {
    state = state.copyWith(isLoadingSuggestions: true);

    try {
      // In production, this would call an AI endpoint
      await Future.delayed(const Duration(seconds: 1));

      final suggestions = await _generateAiSuggestions(
        preferredDate: preferredDate,
        preferredConnectionIds: preferredConnectionIds,
      );

      state = state.copyWith(
        aiSuggestions: suggestions,
        isLoadingSuggestions: false,
      );

      return suggestions;
    } catch (e) {
      state = state.copyWith(
        isLoadingSuggestions: false,
        error: 'Failed to generate suggestions: $e',
      );
      return [];
    }
  }

  /// Accept an AI suggestion and create the event
  Future<void> acceptSuggestion(
      AiDateSuggestion suggestion, DateTime selectedTime,) async {
    final event = PlanEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      userId: _supabase?.auth.currentUser?.id ?? '',
      title: 'Date with ${suggestion.connection.name}',
      startTime: selectedTime,
      endTime: selectedTime.add(const Duration(hours: 2)),
      connections: [suggestion.connection],
      certainty: EventCertainty.exploring,
      isAiSuggested: true,
      aiSuggestionReason: suggestion.reason,
      aiMatchScore: suggestion.compatibilityScore,
      createdAt: DateTime.now(),
    );

    await createEvent(event);

    // Remove the accepted suggestion
    final updatedSuggestions =
        state.aiSuggestions.where((s) => s.id != suggestion.id).toList();
    state = state.copyWith(aiSuggestions: updatedSuggestions);
  }

  /// Dismiss an AI suggestion
  void dismissSuggestion(String suggestionId) {
    final updatedSuggestions =
        state.aiSuggestions.where((s) => s.id != suggestionId).toList();
    state = state.copyWith(aiSuggestions: updatedSuggestions);
  }

  /// Connect Google Calendar
  Future<void> connectGoogleCalendar() async {
    // In production, this would initiate OAuth flow
    state = state.copyWith(googleCalendarConnected: true);
  }

  /// Connect Apple Calendar
  Future<void> connectAppleCalendar() async {
    // In production, this would initiate OAuth flow
    state = state.copyWith(appleCalendarConnected: true);
  }

  /// Disconnect Google Calendar
  Future<void> disconnectGoogleCalendar() async {
    state = state.copyWith(googleCalendarConnected: false);
  }

  /// Disconnect Apple Calendar
  Future<void> disconnectAppleCalendar() async {
    state = state.copyWith(appleCalendarConnected: false);
  }

  /// Sync calendars
  Future<void> syncCalendars() async {
    state = state.copyWith(isLoading: true);

    // In production, this would fetch from external calendar APIs
    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(
      isLoading: false,
      lastSyncTime: DateTime.now(),
    );
  }

  /// Generate AI suggestions based on connections and availability
  Future<List<AiDateSuggestion>> _generateAiSuggestions({
    DateTime? preferredDate,
    List<String>? preferredConnectionIds,
  }) async {
    final userId = _supabase?.auth.currentUser?.id;
    if (userId == null || _supabase == null) return [];

    try {
      // Query matches where current user is user_a or user_b
      final matchesAsA = await _supabase!
          .from('matches')
          .select('''
            id,
            user_b_id,
            compatibility_score,
            matched_at,
            matched_user:profiles!matches_user_b_id_fkey (
              id,
              display_name,
              avatar_url,
              availability_general
            )
          ''')
          .eq('user_a_id', userId)
          .eq('user_a_archived', false);

      final matchesAsB = await _supabase!
          .from('matches')
          .select('''
            id,
            user_a_id,
            compatibility_score,
            matched_at,
            matched_user:profiles!matches_user_a_id_fkey (
              id,
              display_name,
              avatar_url,
              availability_general
            )
          ''')
          .eq('user_b_id', userId)
          .eq('user_b_archived', false);

      final suggestions = <AiDateSuggestion>[];
      final now = DateTime.now();

      // Process all matches
      for (final match in [...matchesAsA as List, ...matchesAsB as List]) {
        final matchedUser = match['matched_user'] as Map<String, dynamic>?;
        if (matchedUser == null) continue;

        final matchedUserId = matchedUser['id'] as String;
        
        // Skip if not in preferred list ( (from matches table)
final planConnectionsProvider =
    FutureProvider<List<EventConnection>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Query matches where current user is user_a or user_b
    final matchesAsA = await supabase
        .from('matches')
        .select('''
          user_b_id,
          matched_user:profiles!matches_user_b_id_fkey (
            id,
            display_name,
            avatar_url
          )
        ''')
        .eq('user_a_id', userId)
        .eq('user_a_archived', false);

    final matchesAsB = await supabase
        .from('matches')
        .select('''
          user_a_id,
          matched_user:profiles!matches_user_a_id_fkey (
            id,
            display_name,
            avatar_url
          )
        ''')
        .eq('user_b_id', userId)
        .eq('user_b_archived', false);

    final connections = <EventConnection>[];
    
    for (final match in [...matchesAsA as List, ...matchesAsB as List]) {
      final matchedUser = match['matched_user'] as Map<String, dynamic>?;
      if (matchedUser == null) continue;
      
      connections.add(EventConnection(
        id: matchedUser['id'] as String,
        name: matchedUser['display_name'] as String? ?? 'Someone',
        avatarUrl: matchedUser['avatar_url'] as String?,
      ));
    }

    return connections;
  } catch (_) {
    return [];
  }

        final connection = EventConnection(
          id: matchedUserId,
          name: matchedUser['display_name'] as String? ?? 'Someone',
          avatarUrl: matchedUser['avatar_url'] as String?,
        );

        final compatScore = (match['compatibility_score'] as num?)?.toDouble() ?? 0.5;
        
        // Generate suggested times (next 7 days, evenings and weekends)
        final suggestedTimes = <DateTime>[];
        for (int i = 1; i <= 7; i++) {
          final day = now.add(Duration(days: i));
          if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
            // Weekend - suggest afternoon and evening
            suggestedTimes.add(DateTime(day.year, day.month, day.day, 14, 0));
            suggestedTimes.add(DateTime(day.year, day.month, day.day, 19, 0));
          } else {
            // Weekday - suggest evening only
            suggestedTimes.add(DateTime(day.year, day.month, day.day, 19, 0));
          }
        }

        // Filter by preferred date if specified
        final filteredTimes = preferredDate != null
            ? suggestedTimes.where((t) => 
                t.year == preferredDate.year && 
                t.month == preferredDate.month && 
                t.day == preferredDate.day).toList()
            : suggestedTimes.take(5).toList();

        if (filteredTimes.isEmpty) continue;

        suggestions.add(AiDateSuggestion(
          id: match['id'] as String,
          connection: connection,
          suggestedTimes: filteredTimes,
          reason: _generateSuggestionReason(matchedUserId, []),
          compatibilityScore: compatScore,
          isHotMatch: compatScore > 0.75,
        ));
      }

      // Sort by compatibility score
      suggestions.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      return suggestions.take(5).toList();
    } catch (e) {
      // Return empty on error
      return [];
    }
  }

  String _generateSuggestionReason(String matchId, List<String> interests) {
    final reasons = [
      'You\'ve been chatting frequently and both seem available this week',
      'High compatibility score and overlapping availability windows',
      'Momentum is strong - time to take it offline!',
      'Both of you mentioned interest in ${interests.isNotEmpty ? interests.first : "connecting"}',
      'Your schedules align well for the upcoming weekend',
    ];
    return reasons[matchId.hashCode % reasons.length];
  }

  Future<void> _loadAiSuggestions() async {
    // Delay to simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    await findMeADate();
  }

  List<PlanEvent> _getEmptyEvents() {
    // Return empty list - no mock data
    return [];
  }

  /// Empty experience events - to be loaded from database
  List<PlanEvent> _getExperienceEvents() {
    // Return empty list - no mock data
    return [];
  }
}

/// Providers
final planProvider = StateNotifierProvider<PlanNotifier, PlanState>((ref) {
  try {
    final supabase = Supabase.instance.client;
    return PlanNotifier(supabase: supabase);
  } catch (_) {
    return PlanNotifier();
  }
});

/// Get connections available for planning
final planConnectionsProvider =
    FutureProvider<List<EventConnection>>((ref) async {
  // TODO: Fetch real matches from database
  // For now return empty list until real data is available
  return [];
});

/// Get AI suggestions
final aiSuggestionsProvider = Provider<List<AiDateSuggestion>>(
    (ref) => ref.watch(planProvider).aiSuggestions,);

/// Get events for a specific date
final eventsForDateProvider = Provider.family<List<PlanEvent>, DateTime>(
    (ref, date) => ref.watch(planProvider).eventsForDate(date),);
