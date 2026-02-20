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
  // KULT EVENTS (Full Event Hosting - legacy vespara_events table)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all Kult events (hosted + invited + co-hosted)
  Future<void> loadAllVesparaEvents() async {
    state = state.copyWith(isLoading: true);

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
      // Load events where user is host (with RSVPs and cohosts)
      final hostedResponse = await _supabase
          .from('vespara_events')
          .select('''
            *,
            rsvps:vespara_event_rsvps(id, user_id, status, response_message, created_at, responded_at,
              profile:profiles!vespara_event_rsvps_user_id_fkey(id, display_name, avatar_url)
            ),
            cohosts:event_cohosts(id, user_id, status, can_edit, can_invite, can_manage_rsvps,
              profile:profiles!event_cohosts_user_id_fkey(id, display_name, avatar_url)
            )
          ''')
          .eq('host_id', _currentUserId)
          .eq('is_cancelled', false)
          .order('start_time', ascending: true);

      // Load events where user has an RSVP
      final rsvpResponse = await _supabase
          .from('vespara_event_rsvps')
          .select('''
            status,
            event:vespara_events(
              *,
              rsvps:vespara_event_rsvps(id, user_id, status, response_message, created_at, responded_at,
                profile:profiles!vespara_event_rsvps_user_id_fkey(id, display_name, avatar_url)
              ),
              cohosts:event_cohosts(id, user_id, status, can_edit, can_invite, can_manage_rsvps,
                profile:profiles!event_cohosts_user_id_fkey(id, display_name, avatar_url)
              )
            )
          ''')
          .eq('user_id', _currentUserId);

      // Load events where user is co-host
      final cohostResponse = await _supabase
          .from('event_cohosts')
          .select('''
            status,
            event:vespara_events(
              *,
              rsvps:vespara_event_rsvps(id, user_id, status, response_message, created_at, responded_at,
                profile:profiles!vespara_event_rsvps_user_id_fkey(id, display_name, avatar_url)
              ),
              cohosts:event_cohosts(id, user_id, status, can_edit, can_invite, can_manage_rsvps,
                profile:profiles!event_cohosts_user_id_fkey(id, display_name, avatar_url)
              )
            )
          ''')
          .eq('user_id', _currentUserId)
          .eq('status', 'accepted');

      final seenIds = <String>{};
      final hostedEvents = <VesparaEvent>[];
      final invitedEvents = <VesparaEvent>[];

      // Parse hosted events
      for (final json in hostedResponse as List<dynamic>) {
        final event = _vesparaEventFromJson(
          json as Map<String, dynamic>,
          isHost: true,
        );
        if (seenIds.add(event.id)) {
          hostedEvents.add(event);
        }
      }

      // Parse co-hosted events
      for (final json in cohostResponse as List<dynamic>) {
        final eventData = json['event'] as Map<String, dynamic>?;
        if (eventData != null) {
          final event = _vesparaEventFromJson(eventData, isCoHost: true);
          if (seenIds.add(event.id)) {
            hostedEvents.add(event);
          }
        }
      }

      // Parse invited events
      for (final json in rsvpResponse as List<dynamic>) {
        final eventData = json['event'] as Map<String, dynamic>?;
        if (eventData != null) {
          final inviteStatus = json['status'] as String? ?? 'invited';
          final event = _vesparaEventFromJson(
            eventData,
            inviteStatus: inviteStatus,
          );
          if (seenIds.add(event.id)) {
            invitedEvents.add(event);
          }
        }
      }

      final allEvents = [...hostedEvents, ...invitedEvents];
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      state = state.copyWith(
        hostedEvents: hostedEvents,
        invitedEvents: invitedEvents,
        allEvents: allEvents,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading Kult events: $e');
      state = state.copyWith(
        allEvents: [],
        hostedEvents: [],
        invitedEvents: [],
        isLoading: false,
        error: 'Failed to load events: $e',
      );
    }
  }

  /// Create a new Kult event (full-featured event)
  Future<VesparaEvent?> createVesparaEvent(VesparaEvent event) async {
    debugPrint('Creating event: ${event.title}');

    final eventId =
        event.id.startsWith('event-') || event.id.startsWith('draft-')
            ? const Uuid().v4()
            : event.id;

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
          .from('vespara_events')
          .insert({
            'id': eventId,
            'host_id': _currentUserId,
            'title': event.title,
            'description': event.description,
            'title_style': event.titleStyle.name,
            'cover_image_url': event.coverImageUrl,
            'cover_theme': event.coverTheme,
            'cover_effect': event.coverEffect,
            'start_time': event.startTime.toIso8601String(),
            'end_time': event.endTime?.toIso8601String(),
            'venue_name': event.venueName,
            'venue_address': event.venueAddress,
            'venue_lat': event.venueLat,
            'venue_lng': event.venueLng,
            'is_virtual': event.isVirtual,
            'virtual_link': event.virtualLink,
            'max_spots': event.maxSpots,
            'cost_per_person': event.costPerPerson,
            'cost_currency': event.costCurrency,
            'requires_approval': event.requiresApproval,
            'collect_guest_info': event.collectGuestInfo,
            'send_reminders': event.sendReminders,
            'visibility': event.visibility.name,
            'content_rating': event.contentRating,
            'age_restriction': event.ageRestriction,
            'links': event.links
                .map((l) => {
                      'id': l.id,
                      'type': l.type.name,
                      'label': l.label,
                      'url': l.url,
                    })
                .toList(),
            'is_draft': event.isDraft,
            'host_nickname': event.hostNickname,
            'created_at': event.createdAt.toIso8601String(),
          })
          .select()
          .single();

      debugPrint('Event created in legacy table vespara_events: ${response['id']}');

      // Add cohosts if any
      for (final coHost in event.coHosts) {
        try {
          await _supabase.from('event_cohosts').insert({
            'event_id': eventId,
            'user_id': coHost.userId,
            'status': 'pending',
            'can_edit': true,
            'can_invite': true,
            'can_manage_rsvps': true,
          });
        } catch (e) {
          debugPrint('Error adding cohost ${coHost.name}: $e');
        }
      }

      return newEvent;
    } catch (e) {
      debugPrint('Error creating Kult event: $e');
      // Keep optimistic update even if DB fails
      return newEvent;
    }
  }

  /// Update an existing Kult event
  Future<bool> updateVesparaEvent(VesparaEvent event) async {
    // Update locally first
    final updatedHosted = state.hostedEvents
        .map((e) => e.id == event.id ? event : e)
        .toList();
    final updatedAll = state.allEvents
        .map((e) => e.id == event.id ? event : e)
        .toList();

    state = state.copyWith(
      hostedEvents: updatedHosted,
      allEvents: updatedAll,
    );

    if (_currentUserId.isEmpty) return true;

    try {
      await _supabase
          .from('vespara_events')
          .update({
            'title': event.title,
            'description': event.description,
            'title_style': event.titleStyle.name,
            'cover_image_url': event.coverImageUrl,
            'cover_theme': event.coverTheme,
            'cover_effect': event.coverEffect,
            'start_time': event.startTime.toIso8601String(),
            'end_time': event.endTime?.toIso8601String(),
            'venue_name': event.venueName,
            'venue_address': event.venueAddress,
            'venue_lat': event.venueLat,
            'venue_lng': event.venueLng,
            'is_virtual': event.isVirtual,
            'virtual_link': event.virtualLink,
            'max_spots': event.maxSpots,
            'cost_per_person': event.costPerPerson,
            'cost_currency': event.costCurrency,
            'requires_approval': event.requiresApproval,
            'collect_guest_info': event.collectGuestInfo,
            'send_reminders': event.sendReminders,
            'visibility': event.visibility.name,
            'content_rating': event.contentRating,
            'age_restriction': event.ageRestriction,
            'links': event.links
                .map((l) => {
                      'id': l.id,
                      'type': l.type.name,
                      'label': l.label,
                      'url': l.url,
                    })
                .toList(),
            'is_draft': event.isDraft,
            'host_nickname': event.hostNickname,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', event.id);

      return true;
    } catch (e) {
      debugPrint('Error updating Kult event: $e');
      return false;
    }
  }

  /// Delete a Kult event
  Future<bool> deleteVesparaEvent(String eventId) async {
    state = state.copyWith(
      hostedEvents: state.hostedEvents.where((e) => e.id != eventId).toList(),
      allEvents: state.allEvents.where((e) => e.id != eventId).toList(),
    );

    if (_currentUserId.isEmpty) return true;

    try {
      // Cascading deletes handle cohosts, rsvps, invite links
      await _supabase
          .from('vespara_events')
          .delete()
          .eq('id', eventId)
          .eq('host_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error deleting Kult event: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CO-HOST MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  /// Invite a user as a co-host
  Future<bool> inviteCoHost({
    required String eventId,
    required String userId,
    bool canEdit = true,
    bool canInvite = true,
    bool canManageRsvps = true,
  }) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase.from('event_cohosts').insert({
        'event_id': eventId,
        'user_id': userId,
        'status': 'pending',
        'can_edit': canEdit,
        'can_invite': canInvite,
        'can_manage_rsvps': canManageRsvps,
      });
      debugPrint('Co-host invite sent to $userId');
      return true;
    } catch (e) {
      debugPrint('Error inviting co-host: $e');
      return false;
    }
  }

  /// Respond to a co-host invitation
  Future<bool> respondToCoHostInvite({
    required String eventId,
    required String status, // 'accepted', 'declined'
  }) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase
          .from('event_cohosts')
          .update({'status': status})
          .eq('event_id', eventId)
          .eq('user_id', _currentUserId);
      return true;
    } catch (e) {
      debugPrint('Error responding to co-host invite: $e');
      return false;
    }
  }

  /// Remove a co-host (host only)
  Future<bool> removeCoHost({
    required String eventId,
    required String userId,
  }) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase
          .from('event_cohosts')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      // Update local state
      final updatedAll = state.allEvents.map((e) {
        if (e.id == eventId) {
          return e.copyWith(
            coHosts: e.coHosts.where((c) => c.userId != userId).toList(),
          );
        }
        return e;
      }).toList();
      state = state.copyWith(allEvents: updatedAll);
      return true;
    } catch (e) {
      debugPrint('Error removing co-host: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RSVP & INVITATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// RSVP to an event (going / maybe / not_going) — with capacity + waitlist
  Future<String> rsvpToEvent({
    required String eventId,
    required String status, // 'going', 'maybe', 'not_going'
    String? message,
    String? guestInfo,
  }) async {
    if (_currentUserId.isEmpty) return 'no_user';

    // If going, check capacity
    if (status == 'going') {
      final event = state.allEvents.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );
      if (event.maxSpots != null) {
        final goingCount =
            event.rsvps.where((r) => r.status == 'going').length;
        if (goingCount >= event.maxSpots!) {
          // Auto-waitlist if full
          status = 'waitlist';
        }
      }
    }

    try {
      await _supabase.from('vespara_event_rsvps').upsert(
        {
          'event_id': eventId,
          'user_id': _currentUserId,
          'status': status,
          'message': message,
          'guest_info': guestInfo,
          'responded_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'event_id,user_id',
      );
      await loadAllVesparaEvents(); // Refresh
      return status; // Return actual status (may be 'waitlist')
    } catch (e) {
      debugPrint('Error RSVPing to event: $e');
      return 'error';
    }
  }

  /// Approve a guest from waitlist or pending (host/cohost)
  Future<bool> approveGuest({
    required String eventId,
    required String userId,
  }) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase
          .from('vespara_event_rsvps')
          .update({
            'status': 'going',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('user_id', userId);
      await loadAllVesparaEvents();
      return true;
    } catch (e) {
      debugPrint('Error approving guest: $e');
      return false;
    }
  }

  /// Remove a guest from event (host/cohost)
  Future<bool> removeGuest({
    required String eventId,
    required String userId,
  }) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase
          .from('vespara_event_rsvps')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      await loadAllVesparaEvents();
      return true;
    } catch (e) {
      debugPrint('Error removing guest: $e');
      return false;
    }
  }

  /// Send event invite (creates an RSVP row with status 'invited')
  Future<bool> sendEventInvite({
    required String eventId,
    required String userId,
  }) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase.from('vespara_event_rsvps').upsert(
        {
          'event_id': eventId,
          'user_id': userId,
          'status': 'invited',
          'invited_by': _currentUserId,
        },
        onConflict: 'event_id,user_id',
      );
      return true;
    } catch (e) {
      debugPrint('Error sending invite: $e');
      return false;
    }
  }

  /// Send invites to multiple users at once
  Future<int> sendBulkInvites({
    required String eventId,
    required List<String> userIds,
  }) async {
    if (_currentUserId.isEmpty) return 0;
    int sent = 0;
    for (final userId in userIds) {
      final ok = await sendEventInvite(eventId: eventId, userId: userId);
      if (ok) sent++;
    }
    debugPrint('Sent $sent / ${userIds.length} invites');
    return sent;
  }

  /// Respond to an event invitation
  Future<bool> respondToInvite({
    required String eventId,
    required String status, // 'going', 'maybe', 'not_going'
    String? message,
  }) async {
    final result = await rsvpToEvent(
      eventId: eventId,
      status: status,
      message: message,
    );
    return result != 'error';
  }

  /// Create a shareable invite link
  Future<String?> createInviteLink({
    required String eventId,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    if (_currentUserId.isEmpty) return null;
    try {
      final response = await _supabase
          .from('event_invitation_links')
          .insert({
            'event_id': eventId,
            'created_by': _currentUserId,
            'max_uses': maxUses,
            'expires_at': expiresAt?.toIso8601String(),
          })
          .select('invite_code')
          .single();
      return response['invite_code'] as String?;
    } catch (e) {
      debugPrint('Error creating invite link: $e');
      return null;
    }
  }

  /// Accept an invite code (uses the DB function)
  Future<bool> acceptInviteCode(String inviteCode) async {
    if (_currentUserId.isEmpty) return false;
    try {
      await _supabase.rpc('accept_event_invite', params: {
        'p_invite_code': inviteCode,
      });
      await loadAllVesparaEvents();
      return true;
    } catch (e) {
      debugPrint('Error accepting invite code: $e');
      return false;
    }
  }

  /// Get RSVP summary for an event (uses DB function)
  Future<Map<String, dynamic>?> getEventRsvpSummary(String eventId) async {
    try {
      final response = await _supabase.rpc('get_event_rsvp_summary', params: {
        'p_event_id': eventId,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting RSVP summary: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USER SEARCH FOR INVITES
  // ══════════════════════════════════════════════════════════════════════════

  /// Search users by name for invite/co-host picker
  Future<List<Map<String, dynamic>>> searchUsersForInvite(String query) async {
    if (query.isEmpty || _currentUserId.isEmpty) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url')
          .or('display_name.ilike.%$query%')
          .neq('id', _currentUserId)
          .limit(20);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get current user's matches for quick invite
  Future<List<Map<String, dynamic>>> getMatchesForInvite() async {
    if (_currentUserId.isEmpty) return [];
    try {
      final response = await _supabase
          .from('matches')
          .select(
            'id, user1_id, user2_id, user1:profiles!matches_user1_id_fkey(id, display_name, avatar_url), user2:profiles!matches_user2_id_fkey(id, display_name, avatar_url)',
          )
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId')
          .eq('status', 'matched')
          .limit(50);

      final matches = <Map<String, dynamic>>[];
      for (final m in response as List) {
        final isUser1 = m['user1_id'] == _currentUserId;
        final other = isUser1 ? m['user2'] : m['user1'];
        if (other != null) {
          matches.add(other as Map<String, dynamic>);
        }
      }
      return matches;
    } catch (e) {
      debugPrint('Error getting matches for invite: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY
  // ══════════════════════════════════════════════════════════════════════════

  /// Check if an event has reached its RSVP capacity
  bool isEventFull(String eventId) {
    final event = state.allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );
    if (event.maxSpots == null) return false;
    final goingCount = event.rsvps.where((r) => r.status == 'going').length;
    return goingCount >= event.maxSpots!;
  }

  /// Get remaining spots for an event
  int? getRemainingSpots(String eventId) {
    final event = state.allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );
    if (event.maxSpots == null) return null;
    final goingCount = event.rsvps.where((r) => r.status == 'going').length;
    return event.maxSpots! - goingCount;
  }

  /// Update RSVP status (convenience)
  Future<void> updateRSVP(String eventId, String status) async {
    await rsvpToEvent(eventId: eventId, status: status);
  }

  /// Cancel an event (host only)
  Future<void> cancelEvent(String eventId) async {
    final eventExists = state.allEvents.any((e) => e.id == eventId);
    if (!eventExists) throw Exception('Event not found');

    state = state.copyWith(
      hostedEvents: state.hostedEvents.where((e) => e.id != eventId).toList(),
      allEvents: state.allEvents.where((e) => e.id != eventId).toList(),
    );

    if (_currentUserId.isEmpty) return;

    try {
      await _supabase
          .from('vespara_events')
          .update({
            'is_cancelled': true,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId)
          .eq('host_id', _currentUserId);
    } catch (e) {
      debugPrint('Error cancelling event: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  VesparaEvent _vesparaEventFromJson(
    Map<String, dynamic> json, {
    bool isHost = false,
    bool isCoHost = false,
    String? inviteStatus,
  }) {
    // Parse co-hosts from joined data
    final coHostsList = <EventCoHost>[];
    if (json['event_cohosts'] != null) {
      for (final c in json['event_cohosts'] as List) {
        final profile = c['profiles'] as Map<String, dynamic>?;
        coHostsList.add(EventCoHost(
          id: c['id']?.toString() ?? '',
          userId: c['user_id'] as String? ?? '',
          name: profile?['display_name'] as String? ?? 'Co-host',
          avatarUrl: profile?['avatar_url'] as String?,
          role: c['status'] as String? ?? 'pending',
        ));
      }
    }

    // Parse RSVPs from joined data
    final rsvpList = <EventRsvp>[];
    if (json['vespara_event_rsvps'] != null) {
      for (final r in json['vespara_event_rsvps'] as List) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        rsvpList.add(EventRsvp(
          id: r['id']?.toString() ?? '',
          eventId: json['id'] as String? ?? '',
          userId: r['user_id'] as String? ?? '',
          userName: profile?['display_name'] as String? ?? 'Guest',
          userAvatarUrl: profile?['avatar_url'] as String?,
          status: r['status'] as String? ?? 'invited',
          message: r['message'] as String?,
          createdAt: r['created_at'] != null
              ? DateTime.parse(r['created_at'] as String)
              : DateTime.now(),
          respondedAt: r['responded_at'] != null
              ? DateTime.parse(r['responded_at'] as String)
              : null,
        ));
      }
    }

    // If this is an invited event, ensure the current user's RSVP is present
    if (inviteStatus != null &&
        !rsvpList.any((r) => r.userId == _currentUserId)) {
      rsvpList.add(EventRsvp(
        id: 'rsvp-${json['id']}',
        eventId: json['id'] as String? ?? '',
        userId: _currentUserId,
        userName: 'You',
        status: inviteStatus,
        createdAt: DateTime.now(),
      ));
    }

    // Parse links from JSONB
    final linksList = <EventLink>[];
    if (json['links'] != null) {
      for (final l in json['links'] as List) {
        final linkMap = l as Map<String, dynamic>;
        linksList.add(EventLink(
          id: linkMap['id'] as String? ?? const Uuid().v4(),
          type: EventLinkType.values.firstWhere(
            (t) => t.name == (linkMap['type'] as String? ?? 'other'),
            orElse: () => EventLinkType.custom,
          ),
          label: linkMap['label'] as String? ?? '',
          url: linkMap['url'] as String? ?? '',
        ));
      }
    }

    // Parse title style
    final titleStyleStr = json['title_style'] as String?;
    final titleStyle = EventTitleStyle.values.firstWhere(
      (s) => s.name == titleStyleStr,
      orElse: () => EventTitleStyle.classic,
    );

    // Parse visibility
    final visStr = json['visibility'] as String?;
    EventVisibility visibility;
    if (visStr == 'private') {
      visibility = EventVisibility.private;
    } else if (visStr == 'friends') {
      visibility = EventVisibility.friends;
    } else {
      visibility = EventVisibility.public;
    }

    // Host profile from join
    String hostName = isHost ? 'You' : 'Host';
    String? hostAvatarUrl;
    if (json['host_profile'] != null) {
      final hp = json['host_profile'] as Map<String, dynamic>;
      hostName = hp['display_name'] as String? ?? hostName;
      hostAvatarUrl = hp['avatar_url'] as String?;
    }

    return VesparaEvent(
      id: json['id'] as String? ?? '',
      hostId: json['host_id'] as String? ?? '',
      hostName: hostName,
      hostAvatarUrl: hostAvatarUrl,
      title: json['title'] as String? ?? 'Untitled Event',
      description: json['description'] as String?,
      titleStyle: titleStyle,
      coverImageUrl: json['cover_image_url'] as String?,
      coverTheme: json['cover_theme'] as String?,
      coverEffect: json['cover_effect'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      venueLat: (json['venue_lat'] as num?)?.toDouble(),
      venueLng: (json['venue_lng'] as num?)?.toDouble(),
      isVirtual: json['is_virtual'] as bool? ?? false,
      virtualLink: json['virtual_link'] as String?,
      maxSpots: json['max_spots'] as int?,
      currentAttendees:
          rsvpList.where((r) => r.status == 'going').length,
      costPerPerson: (json['cost_per_person'] as num?)?.toDouble(),
      costCurrency: json['cost_currency'] as String? ?? 'USD',
      visibility: visibility,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      collectGuestInfo: json['collect_guest_info'] as bool? ?? false,
      sendReminders: json['send_reminders'] as bool? ?? true,
      ageRestriction: json['age_restriction'] as int? ?? 18,
      contentRating: json['content_rating'] as String? ?? 'PG',
      isDraft: json['is_draft'] as bool? ?? false,
      hostNickname: json['host_nickname'] as String?,
      coHosts: coHostsList,
      rsvps: rsvpList,
      links: linksList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
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
  final userId = supabase.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return EventsNotifier(supabase, '');
  }
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
