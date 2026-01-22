import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/plan_event.dart';
import '../domain/models/roster_match.dart';
import '../data/vespara_mock_data.dart';
import '../data/mock_data_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PLAN PROVIDER
/// State management for THE PLAN section
/// Handles: Events, AI Suggestions, Calendar Sync, Find Me a Date
/// ════════════════════════════════════════════════════════════════════════════

/// State class for Plan
class PlanState {
  final List<PlanEvent> events;
  final List<AiDateSuggestion> aiSuggestions;
  final List<TimeSlot> userAvailability;
  final bool isLoading;
  final bool isLoadingSuggestions;
  final String? error;
  
  // Calendar sync status
  final bool googleCalendarConnected;
  final bool appleCalendarConnected;
  final DateTime? lastSyncTime;

  const PlanState({
    this.events = const [],
    this.aiSuggestions = const [],
    this.userAvailability = const [],
    this.isLoading = false,
    this.isLoadingSuggestions = false,
    this.error,
    this.googleCalendarConnected = false,
    this.appleCalendarConnected = false,
    this.lastSyncTime,
  });

  PlanState copyWith({
    List<PlanEvent>? events,
    List<AiDateSuggestion>? aiSuggestions,
    List<TimeSlot>? userAvailability,
    bool? isLoading,
    bool? isLoadingSuggestions,
    String? error,
    bool? googleCalendarConnected,
    bool? appleCalendarConnected,
    DateTime? lastSyncTime,
  }) {
    return PlanState(
      events: events ?? this.events,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      userAvailability: userAvailability ?? this.userAvailability,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      error: error,
      googleCalendarConnected: googleCalendarConnected ?? this.googleCalendarConnected,
      appleCalendarConnected: appleCalendarConnected ?? this.appleCalendarConnected,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  // Computed getters
  List<PlanEvent> get upcomingEvents => 
      events.where((e) => !e.isPast && !e.isCancelled).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
  
  List<PlanEvent> get todayEvents => 
      events.where((e) => e.isToday && !e.isCancelled).toList();
  
  List<PlanEvent> get thisWeekEvents {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return events.where((e) => 
      e.startTime.isAfter(now) && 
      e.startTime.isBefore(weekEnd) && 
      !e.isCancelled
    ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  List<PlanEvent> get conflictedEvents => 
      events.where((e) => e.isConflicted).toList();
  
  List<PlanEvent> eventsForDate(DateTime date) => 
      events.where((e) => 
        e.startTime.year == date.year &&
        e.startTime.month == date.month &&
        e.startTime.day == date.day &&
        !e.isCancelled
      ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  
  int get confirmedCount => 
      events.where((e) => e.certainty == EventCertainty.locked && !e.isCancelled).length;
  
  int get tentativeCount => 
      events.where((e) => 
        e.certainty != EventCertainty.locked && 
        !e.isCancelled
      ).length;
  
  bool get hasCalendarConnected => 
      googleCalendarConnected || appleCalendarConnected;
}

/// Plan state notifier
class PlanNotifier extends StateNotifier<PlanState> {
  final SupabaseClient? _supabase;
  
  PlanNotifier({SupabaseClient? supabase}) 
      : _supabase = supabase,
        super(const PlanState()) {
    _initialize();
  }

  void _initialize() {
    loadEvents();
    _loadMockAiSuggestions();
  }

  /// Load events from database or mock data
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final userId = _supabase?.auth.currentUser?.id;
      
      if (userId != null && _supabase != null) {
        // Try to load from Supabase
        final response = await _supabase!
            .from('plan_events')
            .select()
            .eq('user_id', userId)
            .order('start_time');
        
        final events = (response as List)
            .map((json) => PlanEvent.fromJson(json))
            .toList();
        
        state = state.copyWith(events: events, isLoading: false);
      } else {
        // Use mock data
        state = state.copyWith(
          events: _getMockEvents(),
          isLoading: false,
        );
      }
    } catch (e) {
      // Fall back to mock data
      state = state.copyWith(
        events: _getMockEvents(),
        isLoading: false,
      );
    }
  }

  /// Create a new event
  Future<void> createEvent(PlanEvent event) async {
    try {
      final userId = _supabase?.auth.currentUser?.id;
      
      if (userId != null && _supabase != null) {
        final response = await _supabase!
            .from('plan_events')
            .insert(event.toJson())
            .select()
            .single();
        
        final newEvent = PlanEvent.fromJson(response);
        state = state.copyWith(
          events: [...state.events, newEvent],
        );
      } else {
        // Mock: just add to local state
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
        await _supabase!
            .from('plan_events')
            .update(event.toJson())
            .eq('id', event.id);
      }
      
      final updatedEvents = state.events.map((e) => 
        e.id == event.id ? event : e
      ).toList();
      
      state = state.copyWith(events: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      if (_supabase != null) {
        await _supabase!
            .from('plan_events')
            .delete()
            .eq('id', eventId);
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
      // For now, simulate AI processing with mock data
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
  Future<void> acceptSuggestion(AiDateSuggestion suggestion, DateTime selectedTime) async {
    final event = PlanEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      userId: _supabase?.auth.currentUser?.id ?? 'mock-user',
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
    final updatedSuggestions = state.aiSuggestions
        .where((s) => s.id != suggestion.id)
        .toList();
    state = state.copyWith(aiSuggestions: updatedSuggestions);
  }

  /// Dismiss an AI suggestion
  void dismissSuggestion(String suggestionId) {
    final updatedSuggestions = state.aiSuggestions
        .where((s) => s.id != suggestionId)
        .toList();
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
    // Get connections from mock data
    final connections = MockDataProvider.rosterMatches
        .where((m) => m.stage == PipelineStage.activeRotation || m.stage == PipelineStage.bench)
        .take(5)
        .toList();
    
    final now = DateTime.now();
    final suggestions = <AiDateSuggestion>[];
    
    for (int i = 0; i < connections.length && i < 3; i++) {
      final match = connections[i];
      
      // Generate suggested times based on "AI analysis"
      final suggestedTimes = <DateTime>[
        preferredDate ?? now.add(Duration(days: i + 1, hours: 19)),
        now.add(Duration(days: i + 2, hours: 20)),
        now.add(Duration(days: i + 4, hours: 18)),
      ];
      
      suggestions.add(AiDateSuggestion(
        id: 'suggestion-${match.id}',
        connection: EventConnection(
          id: match.id,
          name: match.name,
          avatarUrl: match.avatarUrl,
          pipeline: match.pipelineValue,
        ),
        suggestedTimes: suggestedTimes,
        reason: _generateSuggestionReason(match),
        compatibilityScore: match.momentumScore,
        sharedInterest: match.interests.isNotEmpty ? match.interests.first : null,
        isHotMatch: match.momentumScore > 0.7,
      ));
    }
    
    return suggestions;
  }

  String _generateSuggestionReason(RosterMatch match) {
    final reasons = [
      'You\'ve been chatting frequently and both seem available this week',
      'High compatibility score and overlapping availability windows',
      'Momentum is strong - time to take it offline!',
      'Both of you mentioned interest in ${match.interests.isNotEmpty ? match.interests.first : "connecting"}',
      'Your schedules align well for the upcoming weekend',
    ];
    return reasons[match.id.hashCode % reasons.length];
  }

  void _loadMockAiSuggestions() async {
    // Delay to simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    await findMeADate();
  }

  List<PlanEvent> _getMockEvents() {
    final now = DateTime.now();
    final userId = _supabase?.auth.currentUser?.id ?? 'mock-user';
    
    return [
      PlanEvent(
        id: 'plan-1',
        userId: userId,
        title: 'Drinks at The Roosevelt',
        startTime: now.add(const Duration(days: 1, hours: 19)),
        endTime: now.add(const Duration(days: 1, hours: 21)),
        location: 'The Roosevelt Bar',
        connections: [
          const EventConnection(id: 'c1', name: 'Sarah', pipeline: 'active'),
        ],
        certainty: EventCertainty.locked,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PlanEvent(
        id: 'plan-2',
        userId: userId,
        title: 'Coffee catch-up',
        startTime: now.add(const Duration(days: 3, hours: 10)),
        endTime: now.add(const Duration(days: 3, hours: 11, minutes: 30)),
        location: 'Blue Bottle Coffee',
        connections: [
          const EventConnection(id: 'c2', name: 'Mike', pipeline: 'bench'),
        ],
        certainty: EventCertainty.likely,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      PlanEvent(
        id: 'plan-3',
        userId: userId,
        title: 'Dinner date',
        startTime: now.add(const Duration(days: 5, hours: 19, minutes: 30)),
        endTime: now.add(const Duration(days: 5, hours: 22)),
        location: 'Bestia',
        connections: [
          const EventConnection(id: 'c3', name: 'Emma', pipeline: 'active'),
        ],
        certainty: EventCertainty.tentative,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      PlanEvent(
        id: 'plan-4',
        userId: userId,
        title: 'Group hangout',
        startTime: now.add(const Duration(days: 7, hours: 20)),
        endTime: now.add(const Duration(days: 7, hours: 23)),
        location: 'TBD',
        connections: [
          const EventConnection(id: 'c4', name: 'Alex', pipeline: 'active'),
          const EventConnection(id: 'c5', name: 'Jordan', pipeline: 'bench'),
          const EventConnection(id: 'c6', name: 'Taylor', pipeline: 'incoming'),
        ],
        certainty: EventCertainty.exploring,
        createdAt: now,
      ),
      PlanEvent(
        id: 'plan-5',
        userId: userId,
        title: 'Weekend getaway?',
        startTime: now.add(const Duration(days: 14)),
        isAllDay: true,
        connections: [
          const EventConnection(id: 'c3', name: 'Emma', pipeline: 'active'),
        ],
        certainty: EventCertainty.wishful,
        createdAt: now,
      ),
    ];
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
final planConnectionsProvider = FutureProvider<List<EventConnection>>((ref) async {
  // Get from roster matches
  final matches = MockDataProvider.rosterMatches;
  
  return matches.map((m) => EventConnection(
    id: m.id,
    name: m.name,
    avatarUrl: m.avatarUrl,
    pipeline: m.pipelineValue,
  )).toList();
});

/// Get AI suggestions
final aiSuggestionsProvider = Provider<List<AiDateSuggestion>>((ref) {
  return ref.watch(planProvider).aiSuggestions;
});

/// Get events for a specific date
final eventsForDateProvider = Provider.family<List<PlanEvent>, DateTime>((ref, date) {
  return ref.watch(planProvider).eventsForDate(date);
});
