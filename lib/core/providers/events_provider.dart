import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/events.dart';
import '../domain/models/vespara_event.dart';

// ============================================================================
// EVENTS STATE
// ============================================================================

class EventsState {
  const EventsState({
    this.calendarEvents = const [],
    this.hostedEvents = const [],
    this.invitedEvents = const [],
    this.allEvents = const [],
    this.isLoading = false,
    this.error,
  });
  final List<CalendarEvent> calendarEvents;
  final List<VesparaEvent> hostedEvents;
  final List<VesparaEvent> invitedEvents;
  final List<VesparaEvent> allEvents;
  final bool isLoading;
  final String? error;

  /// Get all events for a specific date
  List<CalendarEvent> eventsForDate(DateTime date) => calendarEvents
      .where(
        (e) =>
            e.startTime.year == date.year &&
            e.startTime.month == date.month &&
            e.startTime.day == date.day,
      )
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  /// Get events for this week
  List<CalendarEvent> get thisWeekEvents {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return calendarEvents
        .where(
          (e) => e.startTime.isAfter(now) && e.startTime.isBefore(weekEnd),
        )
        .toList();
  }

  /// Get events with conflicts
  List<CalendarEvent> get conflictEvents =>
      calendarEvents.where((e) => e.aiConflictDetected).toList();

  /// Get upcoming VesparaEvents
  List<VesparaEvent> get upcomingEvents {
    final now = DateTime.now();
    return allEvents
        .where((e) => e.startTime.isAfter(now) && !e.isDraft)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get past VesparaEvents
  List<VesparaEvent> get pastEvents {
    final now = DateTime.now();
    return allEvents.where((e) => e.startTime.isBefore(now)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  EventsState copyWith({
    List<CalendarEvent>? calendarEvents,
    List<VesparaEvent>? hostedEvents,
    List<VesparaEvent>? invitedEvents,
    List<VesparaEvent>? allEvents,
    bool? isLoading,
    String? error,
  }) =>
      EventsState(
        calendarEvents: calendarEvents ?? this.calendarEvents,
        hostedEvents: hostedEvents ?? this.hostedEvents,
        invitedEvents: invitedEvents ?? this.invitedEvents,
        allEvents: allEvents ?? this.allEvents,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ============================================================================
// EVENTS NOTIFIER
// ============================================================================

class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier(this._supabase, this._currentUserId)
      : super(const EventsState()) {
    _initialize();
  }
  final SupabaseClient _supabase;
  final String _currentUserId;

  Future<void> _initialize() async {
    await Future.wait([
      loadCalendarEvents(),
      loadAllVesparaEvents(),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VESPARA EVENTS (Full Event Hosting - group_events table)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all Vespara events (hosted + invited)
  Future<void> loadAllVesparaEvents() async {
    state = state.copyWith(isLoading: true);

    // If no user, return empty
    if (_currentUserId.isEmpty) {
      state = state.copyWith(
        allEvents: [],
        hostedEvents: [],
        invitedEvents: [],
        isLoading: false,
      );
      return;
    }

    try {
      // Load events where user is host
      final hostedResponse = await _supabase
          .from('group_events')
          .select()
          .eq('host_id', _currentUserId)
          .order('start_time', ascending: true);

      // Load events where user is invited
      final invitedResponse = await _supabase
          .from('event_invites')
          .select('event_id, status, group_events(*)')
          .eq('user_id', _currentUserId);

      final hostedEvents = (hostedResponse as List<dynamic>)
          .map((json) =>
              _vesparaEventFromJson(json as Map<String, dynamic>, isHost: true),)
          .toList();

      final invitedEvents = (invitedResponse as List<dynamic>)
          .where((json) => json['group_events'] != null)
          .map((json) {
        final eventData = json['group_events'] as Map<String, dynamic>;
        final status = json['status'] as String? ?? 'invited';
        return _vesparaEventFromJson(eventData, inviteStatus: status);
      }).toList();

      final allEvents = [...hostedEvents, ...invitedEvents];
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      state = state.copyWith(
        hostedEvents: hostedEvents,
        invitedEvents: invitedEvents,
        allEvents: allEvents,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading Vespara events: $e');
      // Return empty on error - no mock data fallback
      state = state.copyWith(
        allEvents: [],
        hostedEvents: [],
        invitedEvents: [],
        isLoading: false,
        error: 'Failed to load events: $e',
      );
    }
  }

  /// Create a new Vespara event (full-featured event)
  Future<VesparaEvent?> createVesparaEvent(VesparaEvent event) async {
    debugPrint('Creating event: ${event.title}');

    // Generate proper ID if needed
    final eventId =
        event.id.startsWith('event-') ? const Uuid().v4() : event.id;

    final newEvent = event.copyWith(
      id: eventId,
      hostId: _currentUserId.isEmpty ? 'current-user' : _currentUserId,
    );

    // Add to state optimistically
    state = state.copyWith(
      hostedEvents: [...state.hostedEvents, newEvent],
      allEvents: [...state.allEvents, newEvent],
    );

    debugPrint(
        'Event added to state. Total hosted: ${state.hostedEvents.length}',);

    if (_currentUserId.isEmpty) {
      debugPrint('No user - event saved locally only');
      return newEvent;
    }

    try {
      final response = await _supabase
          .from('group_events')
          .insert({
            'id': eventId,
            'host_id': _currentUserId,
            'title': event.title,
            'description': event.description,
            'cover_image_url': event.coverImageUrl,
            'event_type': _mapContentRatingToType(event.contentRating),
            'venue_name': event.venueName,
            'venue_address': event.venueAddress,
            'venue_lat': event.venueLat,
            'venue_lng': event.venueLng,
            'is_virtual': event.isVirtual,
            'virtual_link': event.virtualLink,
            'start_time': event.startTime.toIso8601String(),
            'end_time': event.endTime?.toIso8601String(),
            'max_attendees': event.maxSpots,
            'is_private': event.visibility == EventVisibility.private,
            'requires_approval': event.requiresApproval,
            'age_restriction': event.ageRestriction,
            'content_rating': event.contentRating,
            'created_at': event.createdAt.toIso8601String(),
          })
          .select()
          .single();

      debugPrint('Event created in database: ${response['id']}');
      return newEvent;
    } catch (e) {
      debugPrint('Error creating Vespara event: $e');
      // Keep optimistic update even if DB fails
      return newEvent;
    }
  }

  /// Update an existing Vespara event
  Future<bool> updateVesparaEvent(VesparaEvent event) async {
    // Update locally first
    final updatedHosted = state.hostedEvents
        .map(
          (e) => e.id == event.id ? event : e,
        )
        .toList();

    final updatedAll = state.allEvents
        .map(
          (e) => e.id == event.id ? event : e,
        )
        .toList();

    state = state.copyWith(
      hostedEvents: updatedHosted,
      allEvents: updatedAll,
    );

    if (_currentUserId.isEmpty) {
      return true;
    }

    try {
      await _supabase
          .from('group_events')
          .update({
            'title': event.title,
            'description': event.description,
            'cover_image_url': event.coverImageUrl,
            'venue_name': event.venueName,
            'venue_address': event.venueAddress,
            'start_time': event.startTime.toIso8601String(),
            'end_time': event.endTime?.toIso8601String(),
            'max_attendees': event.maxSpots,
            'is_private': event.visibility == EventVisibility.private,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', event.id)
          .eq('host_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error updating Vespara event: $e');
      return false;
    }
  }

  /// Delete a Vespara event
  Future<bool> deleteVesparaEvent(String eventId) async {
    state = state.copyWith(
      hostedEvents: state.hostedEvents.where((e) => e.id != eventId).toList(),
      allEvents: state.allEvents.where((e) => e.id != eventId).toList(),
    );

    if (_currentUserId.isEmpty) {
      return true;
    }

    try {
      await _supabase
          .from('group_events')
          .delete()
          .eq('id', eventId)
          .eq('host_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error deleting Vespara event: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RSVP & INVITATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Send invite to a user for an event
  Future<bool> sendEventInvite({
    required String eventId,
    required String userId,
  }) async {
    if (_currentUserId.isEmpty) {
      debugPrint('No user - cannot send invite');
      return false;
    }

    try {
      await _supabase.from('event_invites').insert({
        'id': const Uuid().v4(),
        'event_id': eventId,
        'user_id': userId,
        'invited_by': _currentUserId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error sending invite: $e');
      return false;
    }
  }

  /// Respond to an event invitation
  Future<bool> respondToInvite({
    required String eventId,
    required String status, // 'accepted', 'declined', 'maybe'
    String? message,
  }) async {
    // Update local state
    final updatedInvited = state.invitedEvents.map((e) {
      if (e.id == eventId) {
        final updatedRsvps = e.rsvps.map((r) {
          if (r.userId == _currentUserId || r.userId == 'current-user') {
            return EventRsvp(
              id: r.id,
              eventId: r.eventId,
              userId: r.userId,
              userName: r.userName,
              userAvatarUrl: r.userAvatarUrl,
              status: status == 'accepted' ? 'going' : status,
              message: message,
              createdAt: r.createdAt,
              respondedAt: DateTime.now(),
            );
          }
          return r;
        }).toList();
        return e.copyWith(rsvps: updatedRsvps);
      }
      return e;
    }).toList();

    state = state.copyWith(invitedEvents: updatedInvited);

    if (_currentUserId.isEmpty) {
      return true;
    }

    try {
      await _supabase
          .from('event_invites')
          .update({
            'status': status,
            'response_message': message,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('user_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error responding to invite: $e');
      return false;
    }
  }

  /// Check if an event has reached its RSVP capacity
  bool isEventFull(String eventId) {
    final event = state.allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );
    
    // Unlimited spots = never full
    if (event.maxSpots == null) return false;
    
    // Count "going" RSVPs
    final goingCount = event.rsvps.where((r) => r.status == 'going').length;
    return goingCount >= event.maxSpots!;
  }

  /// Get remaining spots for an event
  int? getRemainingSpots(String eventId) {
    final event = state.allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );
    
    if (event.maxSpots == null) return null; // Unlimited
    
    final goingCount = event.rsvps.where((r) => r.status == 'going').length;
    return event.maxSpots! - goingCount;
  }

  /// RSVP to an event (with capacity check)
  Future<bool> rsvpToEvent({
    required String eventId,
    required String status, // 'going', 'maybe', 'not_going'
    String? message,
  }) async {
    // Check capacity if trying to go
    if (status == 'going') {
      final event = state.allEvents.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );
      
      if (event.maxSpots != null) {
        final goingCount = event.rsvps.where((r) => r.status == 'going').length;
        if (goingCount >= event.maxSpots!) {
          debugPrint('Event is full - cannot RSVP');
          return false;
        }
      }
    }
    
    // Update via the invite system
    return respondToInvite(
      eventId: eventId,
      status: status == 'going' ? 'accepted' : status,
      message: message,
    );
  }

  /// Update RSVP status (convenience method)
  Future<void> updateRSVP(String eventId, String status) async {
    await rsvpToEvent(eventId: eventId, status: status);
  }

  /// Cancel an event (host only)
  Future<void> cancelEvent(String eventId) async {
    // Verify event exists
    final eventExists = state.allEvents.any((e) => e.id == eventId);
    if (!eventExists) {
      throw Exception('Event not found');
    }

    // Remove from local state immediately (optimistic update)
    final updatedHosted = state.hostedEvents
        .where((e) => e.id != eventId)
        .toList();
    final updatedAll = state.allEvents
        .where((e) => e.id != eventId)
        .toList();

    state = state.copyWith(
      hostedEvents: updatedHosted,
      allEvents: updatedAll,
    );

    if (_currentUserId.isEmpty) return;

    try {
      // Update in database
      await _supabase
          .from('group_events')
          .update({
            'is_cancelled': true,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId)
          .eq('host_id', _currentUserId);

      // Notify all invitees (the edge function would handle this)
      // For now, we update invite statuses
      await _supabase
          .from('event_invites')
          .update({'status': 'cancelled'})
          .eq('event_id', eventId);
    } catch (e) {
      debugPrint('Error cancelling event: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  String _mapContentRatingToType(String rating) {
    switch (rating.toLowerCase()) {
      case 'pg':
        return 'social';
      case 'flirty':
        return 'social';
      case 'spicy':
        return 'intimate';
      case 'explicit':
        return 'intimate';
      default:
        return 'social';
    }
  }

  VesparaEvent _vesparaEventFromJson(
    Map<String, dynamic> json, {
    bool isHost = false,
    String? inviteStatus,
  }) {
    final rsvps = <EventRsvp>[];
    if (inviteStatus != null) {
      rsvps.add(
        EventRsvp(
          id: 'rsvp-${json['id']}',
          eventId: json['id'] as String,
          userId: _currentUserId.isEmpty ? 'current-user' : _currentUserId,
          userName: 'You',
          status: inviteStatus,
          createdAt: DateTime.now(),
        ),
      );
    }

    return VesparaEvent(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      hostName: isHost ? 'You' : 'Host',
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      venueLat: json['venue_lat'] as double?,
      venueLng: json['venue_lng'] as double?,
      isVirtual: json['is_virtual'] as bool? ?? false,
      virtualLink: json['virtual_link'] as String?,
      maxSpots: json['max_attendees'] as int?,
      currentAttendees: json['current_attendees'] as int? ?? 0,
      visibility: (json['is_private'] as bool? ?? true)
          ? EventVisibility.private
          : EventVisibility.public,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      ageRestriction: json['age_restriction'] as int? ?? 18,
      contentRating: json['content_rating'] as String? ?? 'PG',
      rsvps: rsvps,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Get events - returns empty list, data should come from database
  List<VesparaEvent> _getVesparaEvents() {
    // Return empty list - no mock data
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS (The Planner)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all calendar events for the current user
  Future<void> loadCalendarEvents() async {
    state = state.copyWith(isLoading: true);

    // Return empty if no user
    if (_currentUserId.isEmpty) {
      state = state.copyWith(
        calendarEvents: [],
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
      // Return empty on error
      state = state.copyWith(
        calendarEvents: [],
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

    // If no user, just keep in memory
    if (_currentUserId.isEmpty) {
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

      return CalendarEvent.fromJson(response);
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

    if (_currentUserId.isEmpty) {
      return true;
    }

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (startTime != null) {
        updateData['start_time'] = startTime.toIso8601String();
      }
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
      calendarEvents:
          state.calendarEvents.where((e) => e.id != eventId).toList(),
    );

    if (_currentUserId.isEmpty) {
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
  // QUICK SCHEDULING
  // ══════════════════════════════════════════════════════════════════════════

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
    );
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Main events provider
final eventsProvider =
    StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id ?? '';
  return EventsNotifier(supabase, userId);
});

/// Calendar events for a specific date
final eventsForDateProvider = Provider.family<List<CalendarEvent>, DateTime>(
    (ref, date) => ref.watch(eventsProvider).eventsForDate(date),);

/// This week's events
final thisWeekEventsProvider = Provider<List<CalendarEvent>>(
    (ref) => ref.watch(eventsProvider).thisWeekEvents,);

/// Events with conflicts
final conflictEventsProvider = Provider<List<CalendarEvent>>(
    (ref) => ref.watch(eventsProvider).conflictEvents,);

/// All calendar events
final calendarEventsProvider = Provider<List<CalendarEvent>>(
    (ref) => ref.watch(eventsProvider).calendarEvents,);

/// All VesparaEvents (hosted + invited)
final allVesparaEventsProvider =
    Provider<List<VesparaEvent>>((ref) => ref.watch(eventsProvider).allEvents);

/// Hosted events only
final hostedEventsProvider = Provider<List<VesparaEvent>>(
    (ref) => ref.watch(eventsProvider).hostedEvents,);

/// Invited events only
final invitedEventsProvider = Provider<List<VesparaEvent>>(
    (ref) => ref.watch(eventsProvider).invitedEvents,);

/// Upcoming VesparaEvents
final upcomingVesparaEventsProvider = Provider<List<VesparaEvent>>(
    (ref) => ref.watch(eventsProvider).upcomingEvents,);

/// Past VesparaEvents
final pastVesparaEventsProvider =
    Provider<List<VesparaEvent>>((ref) => ref.watch(eventsProvider).pastEvents);
