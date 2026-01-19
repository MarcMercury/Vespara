import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/events.dart';
import '../domain/models/vespara_event.dart';
import '../data/vespara_mock_data.dart';

// ============================================================================
// EVENTS STATE
// ============================================================================

class EventsState {
  final List<CalendarEvent> calendarEvents;
  final List<VesparaEvent> hostedEvents;
  final List<VesparaEvent> invitedEvents;
  final bool isLoading;
  final String? error;

  const EventsState({
    this.calendarEvents = const [],
    this.hostedEvents = const [],
    this.invitedEvents = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get all events for a specific date
  List<CalendarEvent> eventsForDate(DateTime date) {
    return calendarEvents.where((e) =>
      e.startTime.year == date.year &&
      e.startTime.month == date.month &&
      e.startTime.day == date.day
    ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get events for this week
  List<CalendarEvent> get thisWeekEvents {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return calendarEvents.where((e) =>
      e.startTime.isAfter(now) && e.startTime.isBefore(weekEnd)
    ).toList();
  }

  /// Get events with conflicts
  List<CalendarEvent> get conflictEvents {
    return calendarEvents.where((e) => e.aiConflictDetected).toList();
  }

  EventsState copyWith({
    List<CalendarEvent>? calendarEvents,
    List<VesparaEvent>? hostedEvents,
    List<VesparaEvent>? invitedEvents,
    bool? isLoading,
    String? error,
  }) {
    return EventsState(
      calendarEvents: calendarEvents ?? this.calendarEvents,
      hostedEvents: hostedEvents ?? this.hostedEvents,
      invitedEvents: invitedEvents ?? this.invitedEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// EVENTS NOTIFIER
// ============================================================================

class EventsNotifier extends StateNotifier<EventsState> {
  final SupabaseClient _supabase;
  final String _currentUserId;
  final bool _isDemoMode;

  EventsNotifier(this._supabase, this._currentUserId, this._isDemoMode) 
      : super(const EventsState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadCalendarEvents();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS (The Planner)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all calendar events for the current user
  Future<void> loadCalendarEvents() async {
    state = state.copyWith(isLoading: true, error: null);

    // In demo mode, use mock data
    if (_isDemoMode || _currentUserId.isEmpty) {
      state = state.copyWith(
        calendarEvents: MockDataProvider.calendarEvents,
        isLoading: false,
      );
      return;
    }

    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', _currentUserId)
          .order('start_time', ascending: true);

      final events = (response as List<dynamic>)
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        calendarEvents: events,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
      // Fallback to mock data on error
      state = state.copyWith(
        calendarEvents: MockDataProvider.calendarEvents,
        isLoading: false,
        error: 'Failed to load events',
      );
    }
  }

  /// Create a new calendar event
  Future<CalendarEvent?> createCalendarEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? matchId,
    String? matchName,
    String? description,
    String? location,
    double? locationLat,
    double? locationLng,
    EventStatus status = EventStatus.tentative,
    List<int> reminderMinutes = const [60, 1440],
  }) async {
    final eventId = const Uuid().v4();
    final now = DateTime.now();

    final newEvent = CalendarEvent(
      id: eventId,
      userId: _currentUserId.isEmpty ? 'demo-user' : _currentUserId,
      matchId: matchId,
      matchName: matchName,
      title: title,
      description: description,
      location: location,
      locationLat: locationLat,
      locationLng: locationLng,
      startTime: startTime,
      endTime: endTime,
      status: status,
      reminderMinutes: reminderMinutes,
      createdAt: now,
    );

    // Optimistically add to state
    state = state.copyWith(
      calendarEvents: [...state.calendarEvents, newEvent],
    );

    // In demo mode, just keep in memory
    if (_isDemoMode || _currentUserId.isEmpty) {
      return newEvent;
    }

    try {
      final response = await _supabase
          .from('calendar_events')
          .insert({
            'id': eventId,
            'user_id': _currentUserId,
            'match_id': matchId,
            'match_name': matchName,
            'title': title,
            'description': description,
            'location': location,
            'location_lat': locationLat,
            'location_lng': locationLng,
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'status': status.value,
            'reminder_minutes': reminderMinutes,
            'created_at': now.toIso8601String(),
          })
          .select()
          .single();

      return CalendarEvent.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      // Keep the optimistic update even if DB fails in demo mode
      return newEvent;
    }
  }

  /// Update an existing calendar event
  Future<bool> updateCalendarEvent({
    required String eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? matchId,
    String? matchName,
    String? description,
    String? location,
    EventStatus? status,
  }) async {
    // Update locally first
    final updated = state.calendarEvents.map((e) {
      if (e.id == eventId) {
        return CalendarEvent(
          id: e.id,
          userId: e.userId,
          matchId: matchId ?? e.matchId,
          matchName: matchName ?? e.matchName,
          title: title ?? e.title,
          description: description ?? e.description,
          location: location ?? e.location,
          locationLat: e.locationLat,
          locationLng: e.locationLng,
          startTime: startTime ?? e.startTime,
          endTime: endTime ?? e.endTime,
          isAllDay: e.isAllDay,
          externalCalendarId: e.externalCalendarId,
          externalCalendarSource: e.externalCalendarSource,
          aiConflictDetected: e.aiConflictDetected,
          aiConflictReason: e.aiConflictReason,
          aiSuggestions: e.aiSuggestions,
          status: status ?? e.status,
          reminderMinutes: e.reminderMinutes,
          createdAt: e.createdAt,
        );
      }
      return e;
    }).toList();

    state = state.copyWith(calendarEvents: updated);

    if (_isDemoMode || _currentUserId.isEmpty) {
      return true;
    }

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (startTime != null) updateData['start_time'] = startTime.toIso8601String();
      if (endTime != null) updateData['end_time'] = endTime.toIso8601String();
      if (matchId != null) updateData['match_id'] = matchId;
      if (matchName != null) updateData['match_name'] = matchName;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (status != null) updateData['status'] = status.value;

      await _supabase
          .from('calendar_events')
          .update(updateData)
          .eq('id', eventId)
          .eq('user_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
      return false;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteCalendarEvent(String eventId) async {
    // Remove from state first
    state = state.copyWith(
      calendarEvents: state.calendarEvents.where((e) => e.id != eventId).toList(),
    );

    if (_isDemoMode || _currentUserId.isEmpty) {
      return true;
    }

    try {
      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId)
          .eq('user_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VESPARA EVENTS (Full Event Hosting)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load hosted events
  Future<void> loadHostedEvents() async {
    if (_isDemoMode || _currentUserId.isEmpty) {
      return;
    }

    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('host_id', _currentUserId)
          .order('event_date', ascending: true);

      // Convert to VesparaEvent format
      final events = (response as List<dynamic>).map((json) {
        final map = json as Map<String, dynamic>;
        return VesparaEvent(
          id: map['id'] as String,
          hostId: map['host_id'] as String,
          hostName: map['host_name'] as String? ?? 'You',
          title: map['title'] as String,
          description: map['description'] as String?,
          startTime: DateTime.parse(map['event_date'] as String),
          venueName: map['location_name'] as String?,
          maxSpots: map['max_attendees'] as int?,
          visibility: (map['is_private'] as bool? ?? true) 
              ? EventVisibility.private 
              : EventVisibility.public,
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();

      state = state.copyWith(hostedEvents: events);
    } catch (e) {
      debugPrint('Error loading hosted events: $e');
    }
  }

  /// Create a new Vespara event (full-featured event)
  Future<VesparaEvent?> createVesparaEvent(VesparaEvent event) async {
    // Add to state optimistically
    state = state.copyWith(
      hostedEvents: [...state.hostedEvents, event],
    );

    if (_isDemoMode || _currentUserId.isEmpty) {
      return event;
    }

    try {
      final response = await _supabase
          .from('events')
          .insert({
            'id': event.id,
            'host_id': _currentUserId,
            'title': event.title,
            'description': event.description,
            'event_date': event.startTime.toIso8601String(),
            'location_name': event.venueName ?? event.venueAddress,
            'max_attendees': event.maxSpots,
            'is_private': event.visibility == EventVisibility.private,
            'status': 'upcoming',
            'created_at': event.createdAt.toIso8601String(),
          })
          .select()
          .single();

      debugPrint('Event created successfully: ${response['id']}');
      return event;
    } catch (e) {
      debugPrint('Error creating Vespara event: $e');
      // Keep optimistic update in demo mode
      return event;
    }
  }

  /// Quick schedule - create a simple date event
  Future<CalendarEvent?> scheduleQuickDate({
    required String type,
    required DateTime dateTime,
    String? matchName,
    String? location,
  }) async {
    final endTime = dateTime.add(const Duration(hours: 2));
    
    return createCalendarEvent(
      title: type,
      startTime: dateTime,
      endTime: endTime,
      matchName: matchName ?? 'Someone Special',
      location: location ?? 'TBD',
      status: EventStatus.tentative,
    );
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Demo mode provider - import from app_providers if needed
final eventsDemoModeProvider = StateProvider<bool>((ref) => true);

/// Main events provider
final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id ?? '';
  final isDemoMode = ref.watch(eventsDemoModeProvider);
  return EventsNotifier(supabase, userId, isDemoMode);
});

/// Calendar events for a specific date
final eventsForDateProvider = Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
  return ref.watch(eventsProvider).eventsForDate(date);
});

/// This week's events
final thisWeekEventsProvider = Provider<List<CalendarEvent>>((ref) {
  return ref.watch(eventsProvider).thisWeekEvents;
});

/// Events with conflicts
final conflictEventsProvider = Provider<List<CalendarEvent>>((ref) {
  return ref.watch(eventsProvider).conflictEvents;
});

/// All calendar events
final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  return ref.watch(eventsProvider).calendarEvents;
});
